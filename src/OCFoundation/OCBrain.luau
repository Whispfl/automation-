--!nonstrict
-- Pure recommendation engine. It never invokes remotes, purchases, or movement.
local OCBrain = {}
local FarmingPolicy = require(script.Parent.FarmingPolicy)
local ProgressionGraph = require(script.Parent.ProgressionGraph)
local TravelPlanner = require(script.Parent.TravelPlanner)
local PetPolicy = require(script.Parent.PetPolicy)
OCBrain.__index = OCBrain

local function countEntries(map)
	if type(map) ~= "table" then return nil end
	local count = 0
	for _ in pairs(map) do count += 1 end
	return count
end

local function reserveFor(config, currency)
	local fields = { Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" }
	return fields[currency] and config.RESOURCE_SETTINGS[fields[currency]] or 0
end

function OCBrain.new(config)
	return setmetatable({ Config = config, Previous = nil, SelectedAt = 0 }, OCBrain)
end

function OCBrain:Reset()
	self.Previous = nil
	self.SelectedAt = 0
	self.FarmingMemory = { Mode = nil, StartedAt = 0, LastTest = {} }
end

function OCBrain:AnalyzePets(snapshot, context)
	return PetPolicy.Analyze(self.Config, snapshot, context)
end

function OCBrain:PlanEquipmentStep(team, context, state)
	local settings, inv = self.Config.PET_SETTINGS, context.Inventory
	if settings.AUTO_EQUIP and inv and team.Status == "ESTIMATE" and team.Gain > 1e-6 then
		local before, desired = PetPolicy.Counts(inv.Team), PetPolicy.Counts(team.ProposedIds)
		-- One verified improvement at a time; never clear the entire team.
		local adds = {} for id in pairs(desired) do table.insert(adds, id) end table.sort(adds)
		for _, addId in ipairs(adds) do
			local amount = desired[addId]
			if amount <= (before[addId] or 0) then continue end
			if table.find(settings.PROTECTED_PET_IDS, addId) then continue end
			local removes = { false }
			if #inv.Team >= context.MaxEquipped then
				removes = {}
				for id, count in pairs(before) do
					local pet = inv.ById[id]
					if count > (desired[id] or 0) and not PetPolicy.Protected(self.Config, pet, (context.Pets or {})[pet.Name]) then table.insert(removes, id) end
				end
				table.sort(removes)
			end
			for _, removeId in ipairs(removes) do
				local needed = removeId and 2 or 1
				if state.EquipCommands + needed > settings.MAXIMUM_SESSION_EQUIP_COMMANDS then continue end
				local ids = table.clone(inv.Team)
				if removeId then table.remove(ids, table.find(ids, removeId)) end
				table.insert(ids, addId)
				local score = context.ScoreTeam(ids)
				if PetPolicy.Finite(score) and score > team.CurrentScore + 1e-6 then
					return { Kind = "TEAM", AddId = addId, RemoveId = removeId or nil, BeforeIds = table.clone(inv.Team),
						AfterIds = ids, TeamIndex = inv.TeamIndex, BeforeScore = team.CurrentScore, AfterScore = score, OwnsLocation = state.Location ~= nil }
				end
			end
		end
	end
	return nil
end

function OCBrain:PlanPets(report, context, state)
	local settings, hatch = self.Config.PET_SETTINGS, self.Config.HATCH_SETTINGS
	if not settings.ENABLE_PET_INTELLIGENCE or not self.Config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS then return { Kind = "WAIT", OwnsLocation = false } end
	if state.Pending then return { Kind = "OBSERVE", OwnsLocation = state.Location ~= nil, Reason = "Awaiting actual inventory/equipment acknowledgement" } end
	if state.Fault then return { Kind = "WAIT", OwnsLocation = state.Location ~= nil, Reason = state.Fault } end
	if state.EquipmentContinuation then return state.EquipmentContinuation end
	if state.Attempt and state.Attempt.Ended then return { Kind = "WAIT", OwnsLocation = false, Reason = "One-time equipment authorization consumed: " .. tostring(state.Attempt.Status) } end
	if self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST then return { Kind = "WAIT", OwnsLocation = false, Reason = "Pickup-only mode excludes pet actions" } end
	local team, inv = report.Team, context.Inventory
	if settings.EQUIP_OWNED_TEAM_ONCE then
		if state.Attempt then
			if state.Attempt.Ended then return { Kind = "WAIT", OwnsLocation = false, Reason = "One-time owned-team attempt ended: " .. tostring(state.Attempt.Status) } end
			if not settings.AUTO_EQUIP then return { Kind = "WAIT", OwnsLocation = false, Reason = "Equipment authorization withdrawn" } end
			return state.Attempt.Steps[state.Attempt.Step] or { Kind = "WAIT", OwnsLocation = false, Reason = "No remaining equipment step" }
		end
		if not settings.AUTO_EQUIP or not inv or team.Status ~= "ESTIMATE" then return { Kind = "WAIT", OwnsLocation = false, Reason = "One-time equipment requires ready native team analysis and authorization" } end
		if team.Gain <= 1e-6 then return { Kind = "TEAM_ATTEMPT_END", OwnsLocation = false, Reason = "No valid owned-team improvement; no equipment change" } end
		-- Freeze a complete serial plan BEFORE any command. Insufficient command budget,
		-- protected membership or a non-improving intermediate swap cannot leave a partial team.
		local projected = table.clone(context) projected.Inventory = table.clone(inv) projected.Inventory.Team = table.clone(inv.Team)
		local steps, commands = {}, state.EquipCommands
		while not PetPolicy.SameTeam(projected.Inventory.Team, team.ProposedIds) do
			local current = context.ScoreTeam(projected.Inventory.Team)
			if not PetPolicy.Finite(current) then return { Kind = "TEAM_ATTEMPT_END", OwnsLocation = false, Reason = "Native intermediate score UNKNOWN; no commands" } end
			local step = self:PlanEquipmentStep({ Status = "ESTIMATE", Gain = team.ProjectedScore - current, CurrentScore = current, ProposedIds = team.ProposedIds }, projected, { EquipCommands = commands })
			if not step then return { Kind = "TEAM_ATTEMPT_END", OwnsLocation = false, Reason = "Complete team plan blocked by command budget/protection or unsupported intermediate improvement; no commands" } end
			step.OwnsLocation = false table.insert(steps, step)
			commands += step.RemoveId and 2 or 1 projected.Inventory.Team = step.AfterIds
		end
		return { Kind = "TEAM_ATTEMPT_START", OwnsLocation = false, Steps = steps, Team = team, RequiredCommands = commands - state.EquipCommands }
	end
	local equipment = self:PlanEquipmentStep(team, context, state)
	if state.HatchOnce then
		local reason = PetPolicy.HatchIsolation(self.Config)
		if reason then return { Kind = "WAIT", OwnsLocation = false, Reason = reason } end
	end
	if equipment then return equipment end
	if settings.AUTO_HATCH and not state.SessionEnded then
		local blockers = {}
		for _, egg in ipairs(report.Eggs) do
			if state.Location and PetPolicy.SelectionMode(self.Config) ~= "AUTO" and egg.Name ~= state.Location.EggName then continue end
			if not PetPolicy.EggSelected(self.Config, egg.Name) then continue end
			local blocker = PetPolicy.EggBlocker(egg)
			if blocker then table.insert(blockers, egg.Name .. ": " .. blocker) continue end
			if not PetPolicy.EggSelected(self.Config, egg.Name) or egg.Status ~= "ESTIMATE" or not egg.Eligible or not egg.Affordable
				or not egg.Cost or not table.find(hatch.ALLOWED_CURRENCIES, egg.Cost.Currency) or egg.Cost.Amount > hatch.MAXIMUM_EGG_COST
				or (egg.ExpectedIncrement <= 1e-6 and egg.ClientTargetProbability <= 0 and not egg.OwnerCommonFunctionalTestEligible) then continue end
			local remainingCost = hatch.MAXIMUM_SESSION_COST - state.RequestCost
			local remaining = hatch.MAXIMUM_SESSION_HATCHES - state.RequestedHatches
			local free = PetPolicy.Finite(context.StorageCapacity) and PetPolicy.Finite(context.StorageUsed) and context.StorageCapacity - context.StorageUsed or 0
			if type(context.DigitalStorage) ~= "boolean" or context.InventoryFull ~= false or not context.AutoDeleteKnown or context.AutoDeleteActive then
				return { Kind = "WAIT", OwnsLocation = state.Location ~= nil, Reason = context.AutoDeleteActive and "NATIVE_AUTO_DELETE_ACTIVE: disable native auto-delete manually before this test; OC will not change it"
					or not context.AutoDeleteKnown and "UNKNOWN_AUTO_DELETE_SETTINGS: no request" or "CAPACITY_UNAVAILABLE_OR_FULL: native storage guard prevents hatch" }
			end
			if context.DigitalStorage then free = 1 end -- Bytes are not pet slots; use native available-space guard, one egg per request.
			local capacity = PetPolicy.Finite(context.MaxHatches) and context.MaxHatches or 0
			local count = math.floor(math.min(remaining, hatch.MAXIMUM_BATCH_HATCHES, capacity, free,
				egg.Spendable / egg.Cost.Amount, remainingCost / egg.Cost.Amount))
			if count < 1 or not PetPolicy.Finite(egg.DurationSeconds) or egg.DurationSeconds <= 0 then
				table.insert(blockers, egg.Name .. ": remaining request budget/capacity or native hatch duration unavailable") continue
			end
			local model
			for _, nativeEgg in ipairs(context.Eggs or {}) do if nativeEgg.Name == egg.Name then model = nativeEgg.Model break end end
			return { Kind = "HATCH", EggName = egg.Name, Model = model, Count = count, OwnsLocation = true,
				DecisionSource = "BRAIN", SelectionMode = PetPolicy.SelectionMode(self.Config), Currency = context.Currency,
				Reason = report.SelectionExplanation or (egg.InRange and "Authorized bounded useful hatch" or "Selected useful native egg requires controlled arrival or manual approach") }
		end
		return { Kind = "WAIT", OwnsLocation = false,
			Reason = #blockers > 0 and table.concat(blockers, "; ") or report.SelectionExplanation or "No useful eligible native egg; no fallback hatch" }
	end
	return { Kind = "WAIT", OwnsLocation = state.Location ~= nil and not state.SessionEnded,
		Reason = state.SessionEnded and "Bounded hatch authorization ended; request ledger retained; no retry" or "Pet action authorization disabled" }
end

function OCBrain:PlanProgression(snapshot, plan, context)
	return TravelPlanner.Decide(self.Config, snapshot, plan, context)
end

local function finite(value)
	return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

-- Read-only analysis of the selected world. No invented income, goals, spending or activity switches.
function OCBrain:ProgressionEconomics(snapshot, plan, context)
	local settings = self.Config.WORLD_SETTINGS
	if not settings.ENABLE_WORLD_PROGRESSION or not settings.ENABLE_ECONOMIC_DIAGNOSTICS then return nil end
	local goal = plan and plan.Objective and plan.Objective.Metadata and plan.Objective.Metadata.Progression
	local node = snapshot.ProgressionGraph and snapshot.ProgressionGraph.Next
	if not goal or not goal.Node or not node or node.Id ~= goal.Node.Id or node.Kind ~= "WORLD"
		or (node.State ~= "FUNDING" and node.State ~= "READY") then return nil end
	local cost = node.Cost
	if type(cost) ~= "table" or type(cost.Currency) ~= "string" then return nil end
	local balance = (snapshot.Balances or {})[cost.Currency]
	if cost.Type ~= "Currency" or not finite(cost.Amount) or not finite(balance) then return nil end
	local result = { GoalId = plan.Objective.Id, World = node.Name, Currency = cost.Currency, Cost = cost.Amount,
		Balance = balance, Reserve = reserveFor(self.Config, cost.Currency), ObservedAt = context.Now,
		Status = "UNMEASURED", HorizonHours = settings.FUNDING_HORIZON_HOURS, Recommendations = {} }
	result.Deficit = math.max(0, result.Cost + result.Reserve - balance)
	local area, rate = context.Current, context.Rate
	local permitted = area and area.World == "The Overworld" and table.find({ "The Void", "Zen" }, area.Name)
		and table.find(self.Config.ISLAND_SETTINGS.SELECTED_ISLANDS, area.Name)
		and snapshot.UnlockedWorlds and snapshot.UnlockedWorlds[area.World] ~= nil
		and snapshot.UnlockedIslands and snapshot.UnlockedIslands[area.Name] ~= nil
	if permitted then result.Island = area.Key end
	local perMinute = rate and rate.PerMinute and rate.PerMinute[cost.Currency]
	if permitted and rate and rate.Ready and finite(rate.Seconds) and rate.Seconds >= self.Config.FARMING_SETTINGS.MINIMUM_RATE_SAMPLE_SECONDS
		and finite(rate.LastAt) and finite(context.Now) and rate.LastAt <= context.Now
		and context.Now - rate.LastAt <= self.Config.FARMING_SETTINGS.RATE_WINDOW_SECONDS and finite(perMinute) then
		result.PerMinute, result.SampleSeconds = perMinute, rate.Seconds
		result.SampleAgeSeconds = context.Now - rate.LastAt
	end
	if result.Deficit == 0 then result.Status = "FUNDED"
	elseif result.PerMinute and result.PerMinute > 0 then
		local minutes = result.Deficit / result.PerMinute
		if finite(minutes) then
			result.ETAMinutes, result.ETAHours, result.ETADays = minutes, minutes / 60, minutes / 1440
			result.Status = result.ETAHours > settings.FUNDING_HORIZON_HOURS and "BOTTLENECK" or "MEASURED"
		end
	elseif result.PerMinute == 0 then result.Status = "NO_OBSERVED_INCOME" end
	local multiplier = area and area.Multipliers and area.Multipliers[cost.Currency]
	if permitted and finite(multiplier) then result.NativePickupMultiplier = multiplier end
	result.Assumption = "Short stationary LocalData balance sample extrapolated at unchanged earning rate; external credits may contribute; ETA is not guaranteed"
	-- Native gum/flavor definitions change bubble storage/power, not the inspected pickup multiplier.
	local suggestions = {}
	for _, upgrade in ipairs((snapshot.AvailableProgression or {}).Upgrades or {}) do
		local price = upgrade.Cost
		local currentBase = upgrade.Kind == "Gum" and (snapshot.Bubble or {}).BaseCapacity or (snapshot.Bubble or {}).BaseOutput
		if (upgrade.Kind == "Gum" or upgrade.Kind == "Flavors") and upgrade.AccessKnown and upgrade.Accessible
			and upgrade.OwnershipKnown and not upgrade.Owned and price and price.Type == "Currency"
			and price.Currency == cost.Currency and finite(price.Amount) and finite(upgrade.BaseStat)
			and finite(currentBase) and upgrade.BaseStat > currentBase then
			table.insert(suggestions, upgrade)
		end
	end
	table.sort(suggestions, function(a, b) return a.Cost.Amount == b.Cost.Amount and a.Name < b.Name or a.Cost.Amount < b.Cost.Amount end)
	local seen = {}
	for _, upgrade in ipairs(suggestions) do
		if not seen[upgrade.Kind] then
			seen[upgrade.Kind] = true
			table.insert(result.Recommendations, string.format("Accessible %s %s: native cost %.0f %s, base %s %.0f; bubble-only candidate, pickup ROI unverified; no purchase",
				upgrade.Kind, upgrade.Name, upgrade.Cost.Amount, upgrade.Cost.Currency, upgrade.Kind == "Gum" and "storage" or "power", upgrade.BaseStat))
		end
	end
	local bestSell
	for _, island in ipairs(snapshot.ProgressionGraph.Islands or {}) do
		local sell = island.Facilities and island.Facilities.Sell
		if sell and sell.Currency == cost.Currency and finite(sell.Multiplier) and sell.Multiplier > 0
			and island.Discovered and snapshot.UnlockedWorlds[island.World] ~= nil
			and (not bestSell or sell.Multiplier > bestSell.Multiplier) then
			bestSell = { Island = island.Id, Multiplier = sell.Multiplier, Path = sell.Path }
		end
	end
	result.BestObservedIslandSell = bestSell
	if bestSell then table.insert(result.Recommendations, string.format("Observed accessible sell station %s: native %.2fx %s; net bubble/sell yield and travel cost unmeasured; selling remains separately authorized", bestSell.Island, bestSell.Multiplier, cost.Currency)) end
	result.EquippedPets = countEntries(snapshot.Inventory and snapshot.Inventory.EquippedIds)
	table.insert(result.Recommendations, "StatsUtil.GetCurrencyMultiplier uses equipped-pet currency stats and native modifiers; pet/hatching analysis deferred to Phase 4; Mastery execution/ROI deferred to Phase 5. Missing Mastery levels remain unknown")
	return result
end

function OCBrain:PlanFarming(snapshot, plan, context)
	self.FarmingMemory = self.FarmingMemory or { Mode = nil, StartedAt = 0, LastTest = {} }
	local scope = context.Current and context.Current.Key
	if scope ~= self.FarmingMemory.Scope then
		self.FarmingMemory = { Mode = nil, StartedAt = 0, LastTest = {}, Scope = scope,
			TargetCurrency = self.FarmingMemory.TargetCurrency, TargetIsland = self.FarmingMemory.TargetIsland }
	end
	local result = FarmingPolicy.Decide(self.Config, snapshot, plan, context, self.FarmingMemory)
	if result.Kind == "FARM" and result.Mode ~= self.FarmingMemory.Mode then
		self.FarmingMemory.Mode, self.FarmingMemory.StartedAt = result.Mode, context.Now
		self.FarmingMemory.LastTest[result.Mode] = context.Now
	end
	return result
end

function OCBrain:Classify(snapshot)
	if not snapshot.Ready then return "UNDETERMINED", "No real player profile is available." end
	local worlds = countEntries(snapshot.UnlockedWorlds)
	local islands = countEntries(snapshot.UnlockedIslands)
	local inventory = snapshot.Inventory or {}
	local pets = countEntries(inventory.Pets)
	local levels = snapshot.Upgrades and snapshot.Upgrades.MasteryLevels
	if worlds == nil or islands == nil or pets == nil or type(levels) ~= "table" then
		return "UNDETERMINED", "Unlock, pet, or Mastery data is missing or disabled."
	end
	local masteryTotal = 0
	for _, level in pairs(levels) do if type(level) == "number" then masteryTotal += level end end
	local stage
	if worlds <= 1 and islands == 0 and pets == 0 and masteryTotal == 0 then stage = "BRAND_NEW"
	elseif worlds <= 1 and islands < 2 then stage = "EARLY_GAME"
	elseif worlds <= 1 then stage = "DEVELOPING"
	elseif worlds == 2 then stage = "MID_GAME"
	else stage = "ADVANCED" end
	return stage, string.format("%d unlocked worlds, %d discovered areas, %d pet records, %d Mastery levels. Full endgame completion is not inferred.",
		worlds, islands, pets, masteryTotal)
end

function OCBrain:Plan(snapshot, token)
	if token and token:CheckCancelled() then return nil end
	local stage, evidence = self:Classify(snapshot)
	local candidates = {}
	local config = self.Config
	local function add(id, title, reason, priority, family, prerequisites, metadata)
		table.insert(candidates, { Id = id, Title = title, Reason = reason, Priority = priority,
			Family = family, Prerequisites = prerequisites or {}, Metadata = metadata or {},
			RecommendationOnly = true, SnapshotRevision = snapshot.Revision })
	end
	if not config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS then
		add("RECOMMENDATIONS_DISABLED", "Recommendations are disabled", "Enable GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS to select goals.", 1000, "RESOLVE_BLOCKERS")
	elseif not snapshot.Ready then
		add("WAIT_FOR_ACCOUNT", "Load the game's real player profile", "Account analysis needs LocalData:IsReady() and LocalData:Get().",
			1000, "RESOLVE_BLOCKERS", { "Game server supplies PlayerDataLoaded", "LocalData finishes loading" })
	else
		local inventory = snapshot.Inventory or {}
		local bubble = snapshot.Bubble or {}
		local progression = snapshot.AvailableProgression or {}
		local balances = snapshot.Balances or {}
		if config.WORLD_SETTINGS.ENABLE_WORLD_PROGRESSION then
			local graph = snapshot.ProgressionGraph or { Blocker = "Native progression graph unavailable" }
			local goal = ProgressionGraph.Goal(config, graph)
			if goal then
				add(goal.Id, goal.Title, goal.Reason, 900, "WORLD_UNLOCKS", goal.State == "BLOCKED" and { goal.Reason } or {},
					{ Progression = goal, Cost = goal.Cost })
			end
		end
		local function spendable(currency)
			if balances[currency] == nil then return nil end
			return math.max(0, balances[currency] - reserveFor(config, currency))
		end
		if config.BRAIN_SETTINGS.ENABLE_INVENTORY_RECOMMENDATIONS then
			if inventory.StorageUsed and inventory.StorageCapacity and inventory.StorageUsed >= inventory.StorageCapacity then
				add("REVIEW_INVENTORY", "Resolve full pet inventory", "Storage is full according to the game's own storage helpers; preserve pets and review storage upgrades.",
					950, "RESOLVE_BLOCKERS", { "Free storage through an approved non-destructive action" })
			end
			if inventory.UnresolvedEquippedIds and #inventory.UnresolvedEquippedIds > 0 then
				add("WAIT_FOR_PET_SYNC", "Wait for a consistent pet inventory", "Some equipped IDs are absent from the received pet records; avoid planning a team change from this snapshot.",
					960, "RESOLVE_BLOCKERS", { "LocalData resolves the equipped pet IDs" })
			end
		end
		if config.BRAIN_SETTINGS.ENABLE_EARNING_RECOMMENDATIONS and inventory.Pets and inventory.EquippedIds then
			local total = countEntries(inventory.Pets)
			if total > 0 and #inventory.EquippedIds == 0 then
				add("EQUIP_EXISTING_PETS", "Equip pets you already own", "The active team is empty even though the inventory contains pets.",
					850, "EARNING_POWER", { "Select owned pets for the active team" })
			elseif inventory.MaxEquipped and #inventory.EquippedIds < math.min(inventory.MaxEquipped, total) then
				add("FILL_EQUIP_SLOTS", "Use available pet equip slots", "Owned pet records and free equip slots are available; team changes are recommendations only.",
					720, "EARNING_POWER", { "Choose suitable owned pets" })
			end
		end
		for _, requirement in ipairs(snapshot.TaskRequirements or {}) do
			if not config.BRAIN_SETTINGS.ENABLE_EARNING_RECOMMENDATIONS then continue end
			if requirement.Type ~= "Collect" and not config.BUBBLE_SETTINGS.ENABLE_BUBBLE_RECOMMENDATIONS then continue end
			local resource = requirement.Currency or (requirement.Type == "Sell" and "bubble selling" or "bubbles")
			add("TASK:" .. requirement.QuestId .. ":" .. tostring(requirement.TaskIndex), "Progress " .. requirement.QuestId .. " (" .. resource .. ")",
				string.format("Received native task: %.0f/%.0f %s. No task is accepted or claimed by OC.", requirement.Current, requirement.Required, resource),
				700, "EARNING_POWER", {}, { Requirement = requirement })
		end
		if config.BRAIN_SETTINGS.ENABLE_EARNING_RECOMMENDATIONS and config.BUBBLE_SETTINGS.ENABLE_BUBBLE_RECOMMENDATIONS then
			local smallCapacity = bubble.Capacity and bubble.PowerPerBlow and bubble.PowerPerBlow > 0
				and bubble.Capacity / bubble.PowerPerBlow < config.BRAIN_SETTINGS.MINIMUM_BLOWS_PER_FILL
			for _, upgrade in ipairs(progression.Upgrades or {}) do
				if token and token:CheckCancelled() then return nil end
				local current = upgrade.Kind == "Gum" and bubble.BaseCapacity or bubble.BaseOutput
				if upgrade.Accessible and upgrade.OwnershipKnown and current and current > 0 and upgrade.BaseStat then
					local gain = upgrade.BaseStat / current - 1
					if gain >= config.BRAIN_SETTINGS.MINIMUM_UPGRADE_GAIN_RATIO then
						if upgrade.Owned then
							add("EQUIP_UPGRADE:" .. upgrade.Name, "Equip " .. upgrade.Name,
								"This owned upgrade has a higher base stat than the equipped upgrade; effective stats will refresh after a real change.",
								750, "EARNING_POWER", {}, { Upgrade = upgrade.Name, Kind = upgrade.Kind })
						else
							local cost = upgrade.Cost
							local funds = spendable(cost.Currency)
							if funds and type(cost.Amount) == "number" and cost.Amount >= 0 then
								local withinBudget = cost.Amount <= funds * config.RESOURCE_SETTINGS.MAXIMUM_UPGRADE_BALANCE_FRACTION
								local efficiency = math.min(30, gain / math.max(1, cost.Amount) * 100)
								local priority = (withinBudget and 620 or 350) + efficiency
								if upgrade.Kind == "Gum" and smallCapacity then priority += 90 end
								add("BUY_UPGRADE:" .. upgrade.Name,
									(withinBudget and "Consider " or "Save for ") .. upgrade.Name,
									string.format("Base %s improvement %.0f%%; cost %.0f %s. Farming policy separately checks observed income and projected payback before purchasing.",
										upgrade.Kind == "Gum" and "capacity" or "flavor output", gain * 100, cost.Amount, cost.Currency),
									priority, "EARNING_POWER", withinBudget and {} or { "Meet the configured upgrade affordability budget" },
									{ Cost = cost, Upgrade = upgrade.Name, Kind = upgrade.Kind })
								end
						end
					end
				end
			end
		end
		if not config.WORLD_SETTINGS.ENABLE_WORLD_PROGRESSION and config.BRAIN_SETTINGS.ENABLE_WORLD_RECOMMENDATIONS and snapshot.UnlockedWorlds and snapshot.UnlockedIslands then
			for _, world in ipairs(progression.Worlds or {}) do
				if not world.Unlocked and world.Selected and world.Gate then
					local gate = world.Gate
					if not gate.OriginWorld or snapshot.UnlockedWorlds[gate.OriginWorld] == nil then continue end
					if gate.RequiredIsland and snapshot.UnlockedIslands[gate.RequiredIsland] == nil then
						add("DISCOVER:" .. gate.RequiredIsland, "Discover " .. gate.RequiredIsland,
							"The live gate to " .. world.Name .. " is located on this undiscovered island.",
							500, "WORLD_UNLOCKS", { "Reach the island through available game travel" }, { World = world.Name })
					elseif type(world.Cost) == "table" and world.Cost.Type == "Currency" then
						local funds = spendable(world.Cost.Currency)
						if funds and type(world.Cost.Amount) == "number" then
							local affordable = funds >= world.Cost.Amount
							add("UNLOCK_WORLD:" .. world.Name, (affordable and "Unlock " or "Save for ") .. world.Name,
								string.format("Current definition requires %.0f %s; the gate's island prerequisite is discovered.", world.Cost.Amount, world.Cost.Currency),
								affordable and 780 or 450, "WORLD_UNLOCKS",
								affordable and { "Use the verified world gate" } or { "Earn the remaining currency while keeping configured reserves" },
								{ Cost = world.Cost, World = world.Name, Gate = gate.Path })
						end
					end
					break
				end
			end
			for _, island in ipairs(progression.Islands or {}) do
				local selectedWorlds = config.BRAIN_SETTINGS.SELECTED_WORLDS
				if (#selectedWorlds == 0 or table.find(selectedWorlds, island.World)) and snapshot.UnlockedWorlds[island.World] ~= nil and not island.Unlocked then
					add("EXPLORE:" .. island.Name, "Discover " .. island.Name,
						"This scene-present island is the next undiscovered area in its world's height order; route execution is a later phase.",
						400, "WORLD_UNLOCKS", { "Verify and use a reachable game route" }, { World = island.World, Height = island.Height })
					break
				end
			end
		end
		if config.BRAIN_SETTINGS.ENABLE_MASTERY_RECOMMENDATIONS then
			for index, branch in ipairs(progression.Mastery or {}) do
				local cost = branch.NextCost
				if branch.Current ~= nil and type(cost) == "table" and cost.Type == "Currency" then
					local funds = spendable(cost.Currency)
					if funds and type(cost.Amount) == "number" then
						add("MASTERY:" .. branch.Name, "Review " .. branch.Name .. " Mastery level " .. tostring(branch.Current + 1),
							string.format("Next verified tier costs %.0f %s. Mastery purchasing remains a later-phase task.", cost.Amount, cost.Currency),
							(funds >= cost.Amount and 550 or 300) - index, "MASTERY",
							{ "Verify access to the Mastery facility", "Confirm the tier's benefit fits the selected goal" }, { Cost = cost })
					end
				end
			end
		end
		if #candidates == 0 then
			add("REVIEW_AVAILABLE_PROGRESSION", "Review available progression", "No supported recommendation can be established from the enabled readers and current definitions.",
				0, "RESOLVE_BLOCKERS", { "Review missing fields or approve another implementation phase" })
		end
	end
	local priorities = {}
	for index, family in ipairs(config.GENERAL_SETTINGS.PRIORITIES) do priorities[family] = index end
	table.sort(candidates, function(a, b)
		if a.Priority ~= b.Priority then return a.Priority > b.Priority end
		local left, right = priorities[a.Family] or 999, priorities[b.Family] or 999
		if left ~= right then return left < right end
		return a.Id < b.Id
	end)
	local selected = candidates[1]
	if self.Previous and os.clock() - self.SelectedAt < config.GENERAL_SETTINGS.MINIMUM_OBJECTIVE_HOLD_SECONDS then
		for _, candidate in ipairs(candidates) do
			if candidate.Id == self.Previous.Id and selected.Priority < candidate.Priority + config.GENERAL_SETTINGS.OBJECTIVE_SWITCH_PRIORITY_MARGIN then
				selected = candidate break
			end
		end
	end
	if not self.Previous or selected.Id ~= self.Previous.Id then self.SelectedAt = os.clock() end
	self.Previous = selected
	local nextObjective
	for _, candidate in ipairs(candidates) do
		if candidate.Id ~= selected.Id then nextObjective = candidate break end
	end
	local major = snapshot.ProgressionGraph and snapshot.ProgressionGraph.Next
	local reservation = major and major.Kind == "WORLD" and (major.State == "READY" or major.State == "FUNDING") and major.Cost or nil
	return { Progression = stage, ProgressionEvidence = evidence, Objective = selected,
		Graph = snapshot.ProgressionGraph, MajorUnlockReservation = reservation,
		NextObjective = nextObjective,
		Candidates = candidates, SnapshotRevision = snapshot.Revision,
		Reservations = reservation and { reservation } or (selected.Metadata.Cost and { selected.Metadata.Cost } or {}),
		ReservationPolicy = "Farming policy and native upgrade adapter enforce spending reserves before currency purchases." }
end

-- Scoped local additions arbitrate through the same Brain and foreground scheduler.
-- Managers expose eligibility/state; they create no competing gameplay loops.
function OCBrain:TravelDiagnosticBlocker()
	local config, pets, hatch = self.Config, self.Config.PET_SETTINGS, self.Config.HATCH_SETTINGS
	if (config.EGG_TRAVEL_SETTINGS.MODE or "NORMAL") ~= "TRAVEL_ONLY" or not config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL then
		return "TRAVEL_ONLY diagnostic mode/selected egg travel is disabled"
	end
	if not pets.ENABLE_PET_INTELLIGENCE or not config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS then
		return "TRAVEL_ONLY requires read-only pet intelligence and Brain recommendations"
	end
	if pets.AUTO_HATCH or pets.AUTO_EQUIP or pets.EQUIP_OWNED_TEAM_ONCE or hatch.HATCH_ONE_EGG_ONCE
		or hatch.MAXIMUM_EGG_COST ~= 0 or hatch.MAXIMUM_SESSION_COST ~= 0 or hatch.ENABLE_BACKGROUND_PICKUPS
		or config.WORLD_SETTINGS.MAXIMUM_WORLD_UNLOCK_COST ~= 0
		or config.OWNER_ONE_HATCH_TEST_SETTINGS and config.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_HATCH_TEST_ALLOWANCE then
		return "TRAVEL_ONLY requires hatch/equipment/allowance OFF and zero hatch/world purchase budgets"
	end
	for category, keys in pairs({
		WORLD_SETTINGS = { "ENABLE_WORLD_PROGRESSION", "AUTO_DISCOVER_ISLANDS", "AUTO_UNLOCK_WORLDS", "AUTO_TRAVEL_FOR_PROGRESSION", "AUTO_FARM_UNLOCK_REQUIREMENTS" },
		FARMING_SETTINGS = { "AUTO_RESOURCE_FARM", "AUTO_FARM_FALLBACK" },
		ISLAND_SETTINGS = { "AUTO_TRAVEL_BEST_ISLAND", "AUTO_EXPLORE_UNLOCKED_ISLANDS" },
		PICKUP_SETTINGS = { "BULK_COLLECT_PICKUPS", "STATIONARY_ISOLATED_TEST" },
		BUBBLE_SETTINGS = { "AUTO_BLOW_BUBBLES", "AUTO_SELL_BUBBLES", "AUTO_BUY_GUM", "AUTO_BUY_FLAVORS", "ENABLE_SIMULTANEOUS_BLOWING" },
		UPGRADE_SETTINGS = { "ENABLE_SMART_UPGRADES", "ENABLE_CAPACITY_UPGRADES", "ENABLE_FLAVOR_UPGRADES", "AUTO_EQUIP_OWNED_UPGRADES" },
		PET_SETTINGS = { "AUTO_DELETE_PETS", "AUTO_CRAFT_SHINY", "AUTO_FUSE_PETS" },
		FALL_EVENT_SETTINGS = { "ENABLE_FALL_EVENT", "AUTO_REBIRTH", "AUTO_BUY_REBIRTH_UPGRADES", "AUTO_USE_FALL_ELIXIRS", "AUTO_BUY_AUTUMN_SHOP_ITEMS" },
		PLAYTIME_SETTINGS = { "AUTO_CLAIM_PLAYTIME" }, MYSTERY_BOX_SETTINGS = { "AUTO_OPEN_MYSTERY_BOXES" },
		ANTIAFK_SETTINGS = { "ENABLE_ANTI_AFK" },
	}) do
		for _, key in ipairs(keys) do if config[category][key] then return "TRAVEL_ONLY requires " .. category .. "." .. key .. " OFF" end end
	end
	local mode = PetPolicy.SelectionMode(config)
	if mode ~= "AUTO" and mode ~= "MANUAL" then return "TRAVEL_ONLY egg selection mode unavailable" end
	if mode == "MANUAL" and #hatch.SELECTED_EGGS ~= 1 then return "TRAVEL_ONLY MANUAL requires one exact native egg name" end
	return nil
end

function OCBrain:PlanEggTravelDiagnostic(snapshot, context, definitions, worlds, retainedIntent)
	local blocker = self:TravelDiagnosticBlocker()
	if blocker then return { Kind = "WAIT", OwnsLocation = false, Reason = blocker } end
	if not snapshot or not snapshot.Ready or type(snapshot.UnlockedWorlds) ~= "table" or type(snapshot.UnlockedIslands) ~= "table"
		or type(context) ~= "table" or type(definitions) ~= "table" or type(worlds) ~= "table" then
		return { Kind = "WAIT", OwnsLocation = false, Reason = "TRAVEL_ONLY requires fresh LocalData access and native egg/world definitions" }
	end
	local candidates, reasons, selectedMode = {}, {}, PetPolicy.SelectionMode(self.Config)
	if retainedIntent and (retainedIntent.Scope ~= "TRAVEL_ONLY" or retainedIntent.DecisionSource ~= "BRAIN_TRAVEL_DIAGNOSTIC"
		or retainedIntent.SelectionMode ~= selectedMode or type(retainedIntent.EggName) ~= "string" or not retainedIntent.Model) then
		return { Kind = "WAIT", OwnsLocation = false, Reason = "Acquired diagnostic selection scope/mode/identity changed; no retarget" }
	end
	for _, egg in ipairs(context.EggLocations or context.EggAvailability or context.Eggs or {}) do
		if retainedIntent and (egg.Name ~= retainedIntent.EggName or egg.Model ~= retainedIntent.Model) then continue end
		if not PetPolicy.EggSelected(self.Config, egg.Name) then continue end
		local definition = definitions[egg.Name]
		local world = type(definition) == "table" and definition.World
		local worldDefinition = world and worlds[world]
		local island = egg.Island or type(definition) == "table" and definition.Island
		local reason
		if egg.IdentityReason then reason = egg.IdentityReason
		elseif egg.Loaded ~= true or not egg.Model then reason = "original native model not loaded"
		elseif type(definition) ~= "table" or definition.Event or definition.ProductId or definition.IsAdminEgg or egg.Name == "Infinity Egg" then
			reason = "unsupported event/premium/special or unknown native definition"
		elseif type(world) ~= "string" or type(worldDefinition) ~= "table" or worldDefinition.Removed or worldDefinition.Event then
			reason = "native permanent world unavailable/removed"
		elseif egg.Accessible ~= true or snapshot.UnlockedWorlds[world] == nil or island and snapshot.UnlockedIslands[island] == nil then
			reason = "actual world/island access locked or unknown"
		else
			local cost = egg.Cost or definition.Cost
			local ordinary = type(cost) == "table" and cost.Type == "Currency" and type(cost.Currency) == "string"
				and PetPolicy.Finite(cost.Amount)
			table.insert(candidates, { Egg = egg, World = world, Island = island, OrdinaryCost = ordinary == true,
				Distance = PetPolicy.Finite(egg.Distance) and egg.Distance or math.huge })
		end
		if reason and #reasons < math.min(2, self.Config.HATCH_SETTINGS.MAXIMUM_PLAN_CANDIDATES) then table.insert(reasons, tostring(egg.Name) .. ": " .. reason) end
	end
	table.sort(candidates, function(a, b)
		if a.OrdinaryCost ~= b.OrdinaryCost then return a.OrdinaryCost end
		if a.Distance ~= b.Distance then return a.Distance < b.Distance end
		return a.Egg.Name < b.Egg.Name
	end)
	local candidate = candidates[1]
	if not candidate then
		if #reasons == 0 then
			local names = {} for name in pairs(context.EggLocationDiagnostics or {}) do
				if PetPolicy.EggSelected(self.Config, name) then table.insert(names, name) end
			end table.sort(names)
			for _, name in ipairs(names) do
				if #reasons >= math.min(2, self.Config.HATCH_SETTINGS.MAXIMUM_PLAN_CANDIDATES) then break end
				table.insert(reasons, name .. ": " .. tostring(context.EggLocationDiagnostics[name].Reason))
			end
		end
		return { Kind = "WAIT", OwnsLocation = false, Reason = #reasons > 0 and "TRAVEL_ONLY no eligible destination | " .. table.concat(reasons, "; ")
			or "TRAVEL_ONLY no eligible loaded native egg; no catalog-only or random travel" }
	end
	local egg = candidate.Egg
	return { Kind = "EGG_TRAVEL", Scope = "TRAVEL_ONLY", DecisionSource = "BRAIN_TRAVEL_DIAGNOSTIC", SelectionMode = selectedMode,
		EggName = egg.Name, Model = egg.Model, IdentityId = egg.IdentityId, IdentityEvidence = egg.IdentityEvidence,
		LocationVerified = egg.LocationVerified, LocationEvidence = egg.LocationEvidence,
		World = candidate.World, Island = candidate.Island, OwnsLocation = true,
		DefinitionReference = "ReplicatedStorage.Shared.Data.Eggs[" .. egg.Name .. "]",
		AccessSource = "Received LocalData.WorldsUnlocked/AreasUnlocked + actual loaded original egg model",
		GeometrySource = "Verified original Root + native world/island scene correspondence; floor/full-avatar clearance; physical arrival and hatch interaction observed separately",
		EconomicSelection = "DIAGNOSTIC_PHYSICAL_TARGET; optimal economic choice not claimed",
		Reason = string.format("TRAVEL_ONLY %s selected %s @ %s/%s | actual loaded permanent egg/access; %s; %s | observed distance=%s; economic ROI/affordability/reserves do not authorize or block this zero-spend diagnostic; hatch/equipment/pickups OFF; native path, geometry and stable range still required",
			selectedMode, egg.Name, candidate.World, tostring(candidate.Island or "surface"), candidate.OrdinaryCost and "ordinary native currency cost observed; diagnostic physical selection, no optimal ROI claim" or "price unavailable/unsupported for spending; diagnostic physical selection, no optimal ROI claim",
			retainedIntent and "retained acquired exact original model; character movement/new proximity does not select another egg" or "closest source-associated physical original after native spatial/access checks; distance is travel policy, not hatch identity proof",
			candidate.Distance < math.huge and tostring(candidate.Distance) or "UNKNOWN") }
end

function OCBrain:SelectLocalFeature(controller, plan, petOwns, petDecision)
	if (self.Config.EGG_TRAVEL_SETTINGS.MODE or "NORMAL") == "TRAVEL_ONLY" then
		local blocker = self:TravelDiagnosticBlocker()
		if blocker then controller.EggTravel.Reason = blocker controller.EggTravel:DiagnosticTrace("PREFLIGHT_BLOCKED", nil, blocker) return "PHASE4_WAIT", { Kind = "WAIT", Reason = blocker, OwnsLocation = false } end
		local snapshot, context = controller.Pets:Fresh()
		local retained = controller.EggTravel.Lease and controller.EggTravel.BrainIntent
		local goalId = plan and plan.Objective and plan.Objective.Id or "TRAVEL_ONLY_DIAGNOSTIC"
		if retained and (retained.GoalId ~= goalId or retained.Generation ~= controller.Generation
			or retained.SelectionRevision ~= self.Config.EGG_TRAVEL_SETTINGS.SELECTION_REVISION) then
			controller.EggTravel:Release("Acquired diagnostic goal/generation/revision changed; no stale travel", true)
			return "PHASE4_WAIT", { Kind = "WAIT", Reason = "Acquired diagnostic goal/generation/revision changed", OwnsLocation = false }
		end
		local intent = self:PlanEggTravelDiagnostic(snapshot, context, controller.Knowledge:Get("Eggs"), controller.Knowledge:Get("Worlds"), retained)
		if intent.Kind ~= "EGG_TRAVEL" then
			controller.EggTravel.Reason = intent.Reason
			local names = {} for name in pairs(context and context.EggLocationDiagnostics or {}) do
				if PetPolicy.EggSelected(self.Config, name) then table.insert(names, name) end
			end table.sort(names)
			if names[1] then controller.EggTravel:ReportInstanceDiagnostics({ [names[1]] = context.EggLocationDiagnostics[names[1]] }) end
			controller.EggTravel:DiagnosticTrace("PREFLIGHT_BLOCKED", nil, intent.Reason) return "PHASE4_WAIT", intent
		end
		intent.Generation, intent.AccountId = controller.Generation, controller.Reader.Player and controller.Reader.Player.UserId
		intent.SelectionRevision = self.Config.EGG_TRAVEL_SETTINGS.SELECTION_REVISION
		intent.GoalId = goalId
		local owns, decision = controller.EggTravel:Select(plan, intent)
		return owns and "EGG_TRAVEL" or "PHASE4_WAIT", decision
	end
	if petDecision and self.Config.PET_SETTINGS.AUTO_HATCH then
		-- A sent hatch/verified equipment transaction keeps its foreground authority.
		-- Observing presentation/result cannot be preempted by travel or rewards.
		if petDecision.Kind == "OBSERVE" or petDecision.Kind == "TEAM" or petDecision.Kind == "TEAM_ADD" then return nil end
		if petDecision.Kind == "HATCH" and self.Config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL then
			local owns, decision = controller.EggTravel:Select(plan, petDecision)
			if owns then return "EGG_TRAVEL", decision end
			if decision and decision.Kind == "HANDOFF" then return nil end
			return "PHASE4_WAIT", decision -- Never fall through to a stale hatch or farming destination.
		end
		if petDecision.Kind == "WAIT" then
			if controller.EggTravel:OwnsLocation() and not petDecision.OwnsLocation then
				controller.EggTravel:Release(petDecision.Reason or "Hatch intent ended; no return travel", false)
			end
			return "PHASE4_WAIT", petDecision
		end
		if petOwns then return nil end
	end
	for _, entry in ipairs({ { "REWARDS", controller.Rewards }, { "EGG_TRAVEL", controller.EggTravel },
		{ "ANTI_AFK", controller.AntiAFK } }) do
		local owns, decision = entry[2]:Select(plan)
		if owns then return entry[1], decision end
	end
	return nil
end

return OCBrain

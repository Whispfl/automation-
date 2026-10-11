--!nonstrict
-- Pure recommendation engine. It never invokes remotes, purchases, or movement.
local OCBrain = {}
local FarmingPolicy = require(script.Parent.FarmingPolicy)
local ProgressionGraph = require(script.Parent.ProgressionGraph)
local TravelPlanner = require(script.Parent.TravelPlanner)
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

function OCBrain:PlanProgression(snapshot, plan, context)
	return TravelPlanner.Decide(self.Config, snapshot, plan, context)
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

return OCBrain

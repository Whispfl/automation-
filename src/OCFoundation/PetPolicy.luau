--!nonstrict
-- Pure Phase 4 analysis. Native helper projections are estimates, never account writes.
local PetPolicy = {}

function PetPolicy.Finite(value)
	return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

function PetPolicy.Counts(ids)
	local result = {}
	for _, id in ipairs(ids or {}) do result[id] = (result[id] or 0) + 1 end
	return result
end

function PetPolicy.SameTeam(a, b)
	if type(a) ~= "table" or type(b) ~= "table" or #a ~= #b then return false end
	local x, y = PetPolicy.Counts(a), PetPolicy.Counts(b)
	for id, count in pairs(x) do if y[id] ~= count then return false end end
	return true
end

function PetPolicy.Inventory(raw)
	if type(raw) ~= "table" or type(raw.Pets) ~= "table" or type(raw.Teams) ~= "table" then return nil, "Inventory/teams unavailable" end
	local team = raw.Teams[raw.TeamEquipped]
	if type(team) ~= "table" or type(team.Pets) ~= "table" then return nil, "Active team unavailable" end
	local teamLength = 0
	for index, id in pairs(team.Pets) do
		if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or type(id) ~= "string" then return nil, "Invalid equipped ID array" end
		teamLength += 1
	end
	for index = 1, teamLength do if team.Pets[index] == nil then return nil, "Sparse equipped ID array" end end
	local result = { ById = {}, Records = 0, Quantity = 0, Team = table.clone(team.Pets), TeamIndex = raw.TeamEquipped }
	for _, pet in pairs(raw.Pets) do
		if type(pet) ~= "table" or type(pet.Id) ~= "string" or type(pet.Name) ~= "string"
			or pet.Amount ~= nil and type(pet.Amount) ~= "number" or not PetPolicy.Finite(pet.Amount or 1) or (pet.Amount or 1) < 1 or (pet.Amount or 1) % 1 ~= 0
			or result.ById[pet.Id] then return nil, "Invalid, duplicate or unknown pet record" end
		result.ById[pet.Id] = pet result.Records += 1 result.Quantity += pet.Amount or 1
	end
	for id, count in pairs(PetPolicy.Counts(result.Team)) do
		if not result.ById[id] or count > (result.ById[id].Amount or 1) then return nil, "Equipped multiplicity is inconsistent with inventory" end
	end
	return result
end

function PetPolicy.Protection(config, pet, definition)
	local p = config.PET_SETTINGS
	if table.find(p.PROTECTED_PET_IDS, pet.Id) then return "explicitly protected ID (no equipment changes)" end
	if pet.Locked then return "native Locked flag" end
	if table.find(p.FAVORITE_PET_IDS, pet.Id) then return "owner-designated favorite ID" end
	if pet.Favorite or pet.Favorited then return "received favorite marker; native pet-favorite contract unverified" end
	if table.find(p.SELECTED_PETS, pet.Name) then return "selected target name" end
	if table.find(p.VALUABLE_PET_IDS, pet.Id) then return "owner-designated valuable ID" end
	if pet.Super or pet.Shiny or pet.Mythic or pet.XL then return "valuable variant" end
	if definition and (definition.Rarity == "Secret" or definition.Rarity == "Infinity") then return "valuable native rarity" end
	return nil
end

function PetPolicy.Protected(config, pet, definition)
	return PetPolicy.Protection(config, pet, definition) ~= nil
end

function PetPolicy.Equal(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do if not PetPolicy.Equal(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end

function PetPolicy.Describe(config, context, ids)
	local rows, inv = {}, context.Inventory
	for slot, id in ipairs(ids or {}) do
		local pet = inv.ById[id]
		local def = (context.Pets or {})[pet.Name]
		local variants = {} for _, key in ipairs({ "Super", "XL", "Shiny", "Mythic" }) do if pet[key] then table.insert(variants, key) end end
		local stats = context.PetStats and context.PetStats(pet, ids)
		local value = context.PetScore and context.PetScore(pet, ids)
		local without = table.clone(ids) table.remove(without, slot)
		local whole, remainder = context.ScoreTeam(ids), context.ScoreTeam(without)
		table.insert(rows, { Slot = slot, Id = id, Name = pet.Name, Variant = #variants > 0 and table.concat(variants, " ") or "Normal",
			OwnedQuantity = pet.Amount or 1, EquippedCopies = PetPolicy.Counts(ids)[id], XP = pet.XP, Enchants = pet.Enchants,
			Rarity = def and def.Rarity or "UNKNOWN", NativeStats = stats, NativeRoleStat = value,
			RemovalMarginal = PetPolicy.Finite(whole) and PetPolicy.Finite(remainder) and whole - remainder or nil,
			Protection = PetPolicy.Protection(config, pet, def) })
	end
	return rows
end

function PetPolicy.TeamText(team, details)
	if team.Status ~= "ESTIMATE" then return "Team UNKNOWN: " .. tostring(team.Reason) end
	local function lineup(rows)
		local out = {} for _, r in ipairs(rows) do table.insert(out, r.Variant .. " " .. r.Name .. " [" .. r.Id .. "]") end
		return table.concat(out, ", ")
	end
	local header = string.format("%s | team=%s | equipped=%d/native limit=%d | %d records/%d pets | native estimate %.3f -> %.3f | bounded search %d%s",
		tostring(team.Currency), tostring(team.TeamIndex), team.EquippedCount, team.MaxEquipped, team.RecordCount, team.Quantity,
		team.CurrentScore, team.ProjectedScore, team.Evaluations, team.SearchBoundReached and " (limit reached)" or " (local optimum)")
	if not details then return header .. " | proposed: " .. lineup(team.ProposedPets) .. " | details: OC:PrintPetTeam(); earnings impact unmeasured" end
	local lines = { header, "Current: " .. lineup(team.CurrentPets), "Proposed: " .. lineup(team.ProposedPets) }
	for _, group in ipairs({ { "CURRENT", team.CurrentPets }, { "PROPOSED", team.ProposedPets } }) do
		for _, r in ipairs(group[2]) do table.insert(lines, string.format("%s slot %d | %s %s [%s] | owned=%d; team copies=%d | %s stat=%s; removal marginal=%s | XP=%s | protection=%s",
			group[1], r.Slot, r.Variant, r.Name, r.Id, r.OwnedQuantity, r.EquippedCopies, tostring(team.Currency),
			tostring(r.NativeRoleStat or "UNKNOWN"), tostring(r.RemovalMarginal or "UNKNOWN"), tostring(r.XP or "UNKNOWN"), r.Protection or "none")) end
	end
	for index, step in ipairs(team.Improvements) do table.insert(lines, string.format("Search improvement %d | %s replaces %s | native FULL-team %.3f -> %.3f (+%.3f); variants, enchants and account modifiers evaluated together",
		index, step.AddId, step.RemoveId or "free slot", step.BeforeScore, step.AfterScore, step.AfterScore - step.BeforeScore)) end
	for _, reason in ipairs(team.Unknowns) do table.insert(lines, "UNCERTAINTY | " .. reason) end
	table.insert(lines, "Stack copies reuse the actual base ID; no new inventory IDs. Per-pet marginals can overlap through enchants; they are not additive earnings rates.")
	return table.concat(lines, "\n")
end

function PetPolicy.Currency(config, plan)
	if config.PET_SETTINGS.OBJECTIVE_CURRENCY ~= "AUTO" then return config.PET_SETTINGS.OBJECTIVE_CURRENCY end
	local metadata = plan and plan.Objective and plan.Objective.Metadata or {}
	local currency = metadata.Requirement and metadata.Requirement.Currency or metadata.Cost and metadata.Cost.Currency
	if currency == "Coins" or currency == "Gems" or currency == "Tickets" or currency == "Pearls" or currency == "Seashells" then return currency end
	if metadata.Requirement and (metadata.Requirement.Type == "Bubbles" or metadata.Requirement.Type == "Sell") then return "Bubbles" end
	return nil -- No invented currency objective.
end

function PetPolicy.Reserve(config, snapshot, currency)
	local field = ({ Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" })[currency]
	if not field then return nil, "Currency reserve policy unavailable" end
	local reserve = config.RESOURCE_SETTINGS[field]
	if config.HATCH_SETTINGS.PRESERVE_PROGRESSION_RESERVE then
		local graph = snapshot.ProgressionGraph
		if not graph or graph.Blocker or type(graph.Worlds) ~= "table" or #graph.Worlds == 0 then return nil, "Native progression reserve unavailable" end
		for _, world in ipairs(graph.Worlds) do
			if world.Unlocked then continue end
			local cost = world.Cost
			if not cost or cost.Type ~= "Currency" or not PetPolicy.Finite(cost.Amount) then return nil, "Next world cost unknown; hatch reserve unresolved" end
			if cost.Currency == currency then reserve += cost.Amount end
			break
		end
	end
	return reserve
end

-- Bounded native full-team greedy improvement. Cross-pet enchants are evaluated by
-- the game's helper; this is explicitly a heuristic rather than an exhaustive optimum.
function PetPolicy.Team(config, context)
	local inv = context.Inventory
	local report = { Currency = context.Currency, Status = "UNKNOWN", Evidence = "Native full-team stat projection; greedy local search", Evaluations = 0,
		MaxEquipped = context.MaxEquipped, Improvements = {}, Unknowns = { "Server-only modifiers and actual earning-rate impact unverified; native helper totals are client estimates",
			"Bounded greedy local search is not a guaranteed global optimum with interacting enchants", "No native pet-favorite contract found; use FAVORITE_PET_IDS / PROTECTED_PET_IDS" } }
	if not inv or not context.Currency or not context.ScoreTeam or not PetPolicy.Finite(context.MaxEquipped)
		or context.MaxEquipped < 1 or context.MaxEquipped % 1 ~= 0 or #inv.Team > context.MaxEquipped then
		report.Reason = context.Error or "Account, objective or native stat/capacity helper unavailable" return report
	end
	report.RecordCount, report.Quantity, report.EquippedCount = inv.Records, inv.Quantity, #inv.Team
	report.TeamIndex, report.BeforeIds = inv.TeamIndex, table.clone(inv.Team)
	local function score(ids)
		report.Evaluations += 1
		local value = context.ScoreTeam(ids)
		return PetPolicy.Finite(value) and value or nil
	end
	local current = score(inv.Team)
	if not current then report.Reason = "Native team score failed; no guessed fallback" return report end
	report.CurrentScore, report.ProjectedScore, report.ProposedIds = current, current, table.clone(inv.Team)
	local candidates = {}
	for id, pet in pairs(inv.ById) do
		-- Super equip constraints are a separate native capacity: preserve existing
		-- Supers but never add or replace them in this initial executor.
		local definition = (context.Pets or {})[pet.Name]
		if not definition or not definition.Rarity then table.insert(report.Unknowns, pet.Name .. " [" .. id .. "]: definition/rarity UNKNOWN; preserved") continue end
		if pet.Super then continue end
		if table.find(config.PET_SETTINGS.PROTECTED_PET_IDS, id) then continue end
		local value = context.PetScore and context.PetScore(pet)
		if PetPolicy.Finite(value) then table.insert(candidates, { Id = id, Score = value })
		else table.insert(report.Unknowns, pet.Name .. " [" .. id .. "]: native pet stat failed; excluded") end
	end
	table.sort(candidates, function(a, b) return a.Score == b.Score and a.Id < b.Id or a.Score > b.Score end)
	local limit = config.PET_SETTINGS.MAXIMUM_TEAM_EVALUATIONS
	local exhausted = false
	while report.Evaluations < limit do
		local best, bestScore, improvement = nil, report.ProjectedScore, nil
		local counts = PetPolicy.Counts(report.ProposedIds)
		for _, candidate in ipairs(candidates) do
			if (counts[candidate.Id] or 0) >= (inv.ById[candidate.Id].Amount or 1) then continue end
			for slot = 1, #report.ProposedIds + (#report.ProposedIds < context.MaxEquipped and 1 or 0) do
				if report.Evaluations >= limit then exhausted = true break end
				local old = inv.ById[report.ProposedIds[slot]]
				if old and (old.Super or PetPolicy.Protected(config, old, (context.Pets or {})[old.Name]) or not (context.Pets or {})[old.Name] or not context.Pets[old.Name].Rarity) then continue end
				local ids = table.clone(report.ProposedIds) ids[slot] = candidate.Id
				local value = score(ids)
				if value and value > bestScore + 1e-6 then
					best, bestScore = ids, value
					improvement = { AddId = candidate.Id, RemoveId = old and old.Id, BeforeScore = report.ProjectedScore, AfterScore = value }
				elseif not value then report.ProjectionFailures = (report.ProjectionFailures or 0) + 1 end
			end
			if exhausted then break end
		end
		if not best then break end
		table.insert(report.Improvements, improvement)
		report.ProposedIds, report.ProjectedScore = best, bestScore
		if exhausted then break end
	end
	report.Status = "ESTIMATE" report.SearchBoundReached = exhausted or report.Evaluations >= limit
	report.Gain = report.ProjectedScore - current
	report.Reason = report.Gain > 0 and "A stronger owned team is available before hatching" or "No owned improvement found within bounded native projections"
	if report.SearchBoundReached then table.insert(report.Unknowns, "Search limit reached; stronger combinations may remain unevaluated") end
	if report.ProjectionFailures then table.insert(report.Unknowns, tostring(report.ProjectionFailures) .. " candidate full-team helper failures; results incomplete") end
	report.CurrentPets, report.ProposedPets = PetPolicy.Describe(config, context, report.BeforeIds), PetPolicy.Describe(config, context, report.ProposedIds)
	return report
end

function PetPolicy.HatchIsolation(config)
	local p, h = config.PET_SETTINGS, config.HATCH_SETTINGS
	if not p.ENABLE_PET_INTELLIGENCE or not p.AUTO_HATCH or p.AUTO_EQUIP or p.EQUIP_OWNED_TEAM_ONCE
		or p.OBJECTIVE_CURRENCY ~= "Coins" or not h.HATCH_ONE_EGG_ONCE then return "Single hatch requires explicit isolated Coins hatch authorization; equipment OFF" end
	if #h.SELECTED_EGGS ~= 1 or #h.ALLOWED_CURRENCIES ~= 1 or h.ALLOWED_CURRENCIES[1] ~= "Coins"
		or h.MAXIMUM_SESSION_HATCHES ~= 1 or h.MAXIMUM_BATCH_HATCHES ~= 1 or h.MAXIMUM_EGG_COST <= 0 or h.MAXIMUM_SESSION_COST <= 0
		or h.ENABLE_BACKGROUND_PICKUPS or not h.PRESERVE_PROGRESSION_RESERVE then return "Single hatch requires one egg, one request, positive explicit Coins ceilings, protected reserve and no background pickups" end
	for category, keys in pairs({
		WORLD_SETTINGS = { "ENABLE_WORLD_PROGRESSION", "AUTO_DISCOVER_ISLANDS", "AUTO_UNLOCK_WORLDS", "AUTO_TRAVEL_FOR_PROGRESSION", "AUTO_FARM_UNLOCK_REQUIREMENTS" },
		FARMING_SETTINGS = { "AUTO_RESOURCE_FARM", "AUTO_FARM_FALLBACK" },
		ISLAND_SETTINGS = { "AUTO_TRAVEL_BEST_ISLAND", "AUTO_EXPLORE_UNLOCKED_ISLANDS" },
		PICKUP_SETTINGS = { "BULK_COLLECT_PICKUPS", "STATIONARY_ISOLATED_TEST" },
		BUBBLE_SETTINGS = { "AUTO_BLOW_BUBBLES", "AUTO_SELL_BUBBLES", "AUTO_BUY_GUM", "AUTO_BUY_FLAVORS", "ENABLE_SIMULTANEOUS_BLOWING" },
		UPGRADE_SETTINGS = { "ENABLE_SMART_UPGRADES", "ENABLE_CAPACITY_UPGRADES", "ENABLE_FLAVOR_UPGRADES", "AUTO_EQUIP_OWNED_UPGRADES" },
		PET_SETTINGS = { "AUTO_DELETE_PETS", "AUTO_CRAFT_SHINY", "AUTO_FUSE_PETS" },
		FALL_EVENT_SETTINGS = { "ENABLE_FALL_EVENT", "AUTO_REBIRTH", "AUTO_BUY_REBIRTH_UPGRADES", "AUTO_USE_FALL_ELIXIRS", "AUTO_BUY_AUTUMN_SHOP_ITEMS" },
	}) do
		for _, key in ipairs(keys) do if config[category][key] then return "Single hatch requires " .. category .. "." .. key .. " OFF" end end
	end
	return nil
end

function PetPolicy.WorldAccess(profile, world)
	local map = type(profile) == "table" and profile.WorldsUnlocked
	local known = type(map) == "table"
	local present = known and map[world] ~= nil
	local rawValue
	if known then rawValue = map[world] end
	return { Name = world, Status = not known and "UNKNOWN" or present and "UNLOCKED" or "LOCKED",
		MapKnown = known, EntryPresent = present == true, RawValue = rawValue,
		Evidence = "Received LocalData.WorldsUnlocked; native gate/map access checks entry presence (ClientScript:2140, WorldMap:99); rejoin persistence unverified" }
end

function PetPolicy.FundEgg(config, snapshot, r)
	local h = config.HATCH_SETTINGS
	r.SpendingStatus = not config.PET_SETTINGS.AUTO_HATCH and "DISABLED_AUTO_HATCH" or (h.MAXIMUM_EGG_COST <= 0 or h.MAXIMUM_SESSION_COST <= 0) and "DISABLED_ZERO_BUDGET"
		or not table.find(h.SELECTED_EGGS, r.Name) and "NOT_SELECTED" or "AUTHORIZED_CONFIG"
	local cost = r.Cost
	if cost and cost.Type == "Currency" and PetPolicy.Finite(cost.Amount) and cost.Amount > 0 then
		r.Balance = snapshot.Balances and snapshot.Balances[cost.Currency]
		r.Reserve, r.ReserveReason = PetPolicy.Reserve(config, snapshot, cost.Currency)
		if PetPolicy.Finite(r.Balance) then r.FundsAffordable = r.Balance >= cost.Amount end
		if r.Reserve ~= nil and PetPolicy.Finite(r.Balance) then
			r.Spendable = math.max(0, r.Balance - r.Reserve)
			r.ReserveAllows = r.Spendable >= cost.Amount
		end
		r.Affordable = r.FundsAffordable == true and r.ReserveAllows == true
		r.FundingStatus = r.FundsAffordable == nil and "UNKNOWN_BALANCE" or not r.FundsAffordable and "INSUFFICIENT_FUNDS"
			or r.Reserve == nil and "UNKNOWN_RESERVE" or not r.ReserveAllows and "PROTECTED_RESERVE" or "AFFORDABLE"
		if r.SpendingStatus == "AUTHORIZED_CONFIG" then
			r.SpendingStatus = not table.find(h.ALLOWED_CURRENCIES, cost.Currency) and "CURRENCY_NOT_AUTHORIZED"
				or cost.Amount > h.MAXIMUM_EGG_COST and "EGG_COST_CEILING" or cost.Amount > h.MAXIMUM_SESSION_COST and "SESSION_COST_CEILING" or "AUTHORIZED_CONFIG"
		end
	else r.FundingStatus = "UNKNOWN_NATIVE_COST" end
	return r
end

function PetPolicy.Egg(config, snapshot, context, team, egg)
	local h = config.HATCH_SETTINGS
	local r = { Name = egg.Name, Status = "UNKNOWN", Eligible = egg.Accessible == true, InRange = egg.InRange == true,
		Loaded = egg.Loaded, AccessStatus = egg.AccessStatus or "UNKNOWN_ACCESS", World = egg.World, Island = egg.Island,
		Distance = egg.Distance, Range = egg.Range, ModelPath = egg.ModelPath, Position = egg.Position,
		Cost = egg.Cost, Reason = egg.Reason, ProbabilityEvidence = "CLIENT_UI_POOL_ESTIMATE",
		EffectiveServerOdds = "UNKNOWN", VariantOdds = "UNKNOWN", PityGuarantee = "UNKNOWN", TotalTimeSeconds = "UNKNOWN",
		TravelTimeSeconds = "UNKNOWN", VerificationTimeSeconds = "UNKNOWN", StorageUnit = context.StorageUnit,
		DurationSeconds = egg.Duration, NativeBatchCapacity = context.MaxHatches, Outcomes = {} }
	PetPolicy.FundEgg(config, snapshot, r)
	local cost = egg.Cost
	-- Funding/configuration/access are separate from the supported pool estimate.
	-- Never substitute the hypothetical improved owned team for the actual team.
	if egg.Loaded == false then r.Reason = egg.Reason return r end
	if not cost or cost.Type ~= "Currency" or not PetPolicy.Finite(cost.Amount) or cost.Amount <= 0 then r.Reason = "Native currency cost unavailable/unsupported" return r end
	if team.Status ~= "ESTIMATE" or not context.ScoreNewPet or type(egg.Pool) ~= "table" then r.Reason = "Insufficient native team/pool evidence" return r end
	local total = 0
	for _, entry in ipairs(egg.Pool) do
		if not PetPolicy.Finite(entry.Chance) then r.Reason = "Unknown pool weight" return r end
		total += entry.Chance
	end
	if total <= 0 then r.Reason = "Empty native pool" return r end
	local expected, improveChance, targetChance = 0, 0, 0
	for _, entry in ipairs(egg.Pool) do
		local item = entry.Item
		if entry.Chance == 0 then continue end
		if not item or item.Type ~= "Pet" or not (context.Pets or {})[item.Name] then r.Reason = "Unsupported pool outcome" return r end
		local value = context.ScoreNewPet(item.Name, team.BeforeIds)
		if not PetPolicy.Finite(value) then r.Reason = "Native pet contribution unavailable" return r end
		local probability = entry.Chance / total -- Inspected native weighted sampler; NOT verified server RNG.
		local gain = math.max(0, value - team.CurrentScore)
		expected += gain * probability
		if gain > 1e-6 then improveChance += probability end
		if table.find(config.PET_SETTINGS.SELECTED_PETS, item.Name) then targetChance += probability end
		table.insert(r.Outcomes, { Name = item.Name, ClientPoolProbability = probability, IncrementalGain = gain })
	end
	r.Status, r.ExpectedIncrement, r.ClientImprovementProbability, r.ClientTargetProbability = "ESTIMATE", expected, improveChance, targetChance
	r.BaselineScore, r.ExpectedIncrementPerCost = team.CurrentScore, expected / cost.Amount
	if PetPolicy.Finite(egg.Duration) and egg.Duration > 0 and PetPolicy.Finite(context.MaxHatches) and context.MaxHatches >= 1 then
		local batch = math.min(h.MAXIMUM_BATCH_HATCHES, context.MaxHatches, context.DigitalStorage and 1 or math.huge)
		r.EffectiveCycleSeconds = math.max(egg.Duration, h.MINIMUM_REQUEST_INTERVAL_SECONDS)
		r.ExpectedIncrementPerSecond = expected * batch / r.EffectiveCycleSeconds
		if improveChance > 0 then r.EstimatedSecondsToUsefulBasePet = r.EffectiveCycleSeconds / (batch * improveChance) end
	end
	r.Reason = expected > 1e-6 and "Useful base-pet estimate against ACTUAL equipped team" or "NO_USEFUL_IMPROVEMENT in evaluated base-pet pool"
	return r
end

function PetPolicy.EggBlocker(egg)
	if not egg.Eligible then return egg.AccessStatus .. ": " .. tostring(egg.Reason) end
	if egg.Status ~= "ESTIMATE" then return "INSUFFICIENT_EVIDENCE: " .. tostring(egg.Reason) end
	if egg.ExpectedIncrement <= 1e-6 then return "NO_USEFUL_IMPROVEMENT in evaluated base-pet pool" end
	if egg.FundingStatus ~= "AFFORDABLE" then return egg.FundingStatus .. (egg.ReserveReason and ": " .. egg.ReserveReason or "") end
	if egg.SpendingStatus ~= "AUTHORIZED_CONFIG" then return egg.SpendingStatus end
	return nil
end

function PetPolicy.Analyze(config, snapshot, context)
	local report = { Team = PetPolicy.Team(config, context), Eggs = {}, CoinsAvailability = {}, Currency = context.Currency,
		AccountRevision = snapshot.Revision, Coverage = context.EggCoverage, MinigameParadise = context.MinigameParadise }
	for _, egg in ipairs(context.EggAvailability or context.Eggs or {}) do
		if egg.Cost and egg.Cost.Type == "Currency" and egg.Cost.Currency == "Coins" or egg.Cost == nil and egg.DefinitionCurrency == "Coins" then
			table.insert(report.CoinsAvailability, PetPolicy.FundEgg(config, snapshot, { Name = egg.Name, Cost = egg.Cost,
				Loaded = egg.Loaded, Eligible = egg.Accessible == true, AccessStatus = egg.AccessStatus or "UNKNOWN_ACCESS", World = egg.World, Island = egg.Island }))
		end
	end
	table.sort(report.CoinsAvailability, function(a, b) return a.Name < b.Name end)
	for _, egg in ipairs(context.Eggs or {}) do table.insert(report.Eggs, PetPolicy.Egg(config, snapshot, context, report.Team, egg)) end
	table.sort(report.Eggs, function(a, b)
		local ac, bc = a.Cost and a.Cost.Currency or "UNKNOWN", b.Cost and b.Cost.Currency or "UNKNOWN"
		if ac ~= bc then
			local x, y = table.find(config.HATCH_SETTINGS.ALLOWED_CURRENCIES, ac), table.find(config.HATCH_SETTINGS.ALLOWED_CURRENCIES, bc)
			if (x ~= nil) ~= (y ~= nil) then return x ~= nil end
			return ac < bc -- Separate currency groups; never compare their numeric EV/cost.
		end
		local x = a.Status == "ESTIMATE" and a.Eligible and a.Affordable and a.ExpectedIncrementPerCost or -1
		local y = b.Status == "ESTIMATE" and b.Eligible and b.Affordable and b.ExpectedIncrementPerCost or -1
		if x == y then return a.Name < b.Name end
		return x > y
	end)
	for _, egg in ipairs(report.Eggs) do
		if egg.Status == "ESTIMATE" and egg.Eligible and egg.Affordable and table.find(config.HATCH_SETTINGS.ALLOWED_CURRENCIES, egg.Cost.Currency)
			and egg.ExpectedIncrement > 1e-6 then report.RecommendedEgg = egg break end
	end
	local egg = report.RecommendedEgg
	if egg then
		report.HatchTestPlan = { EggName = egg.Name, Currency = egg.Cost.Currency, NativePrice = egg.Cost.Amount,
			RequiredEggBudget = egg.Cost.Amount, RequiredSessionBudget = egg.Cost.Amount, HatchCount = 1,
			World = egg.World, Island = egg.Island, ModelPath = egg.ModelPath, Position = egg.Position, Distance = egg.Distance,
			Range = egg.Range, InRange = egg.InRange, Reserve = egg.Reserve, RequiredBalance = egg.Reserve + egg.Cost.Amount,
			SpendingPermission = config.PET_SETTINGS.AUTO_HATCH and "CONFIG_ENABLED; execution guards still required" or "OFF; owner authorization required",
			PriceEvidence = "StatsUtil:GetEggCost(player, detached current LocalData, egg); native client price; rechecked before any authorized request; server acceptance unverified" }
	end
	report.Comparison = "Cost efficiency within native currency only; no invented conversion. Client base odds/XP=0 estimates; final server/variant/Secret/Infinity odds and pity UNKNOWN; total travel/verification time UNKNOWN"
	return report
end

function PetPolicy.EggPlanText(config, report, details)
	local h, coverage = config.HATCH_SETTINGS, report.Coverage or {}
	local lines = { string.format("%s | actual equipped native score=%s | loaded=%s; pool analyses=%s/%s limit; native definitions=%s (%s permanent); limited loaded-model coverage | AUTO_HATCH=%s; egg/session budgets=%s/%s | recommendation=%s",
		tostring(report.Currency), tostring(report.Team.CurrentScore or "UNKNOWN"), tostring(coverage.LoadedModels or "UNKNOWN"), tostring(coverage.Evaluated or #report.Eggs),
		tostring(coverage.Limit or h.MAXIMUM_EGGS_ANALYZED), tostring(coverage.Definitions or "UNKNOWN"), tostring(coverage.PermanentDefinitions or "UNKNOWN"),
		tostring(config.PET_SETTINGS.AUTO_HATCH), tostring(h.MAXIMUM_EGG_COST), tostring(h.MAXIMUM_SESSION_COST), report.RecommendedEgg and report.RecommendedEgg.Name or "NONE within evaluated accessible affordable estimates") }
	local world = report.MinigameParadise or {}
	local entry = not world.MapKnown and "UNKNOWN" or not world.EntryPresent and "ABSENT" or tostring(world.RawValue)
	table.insert(lines, "Minigame Paradise=" .. (world.Status or "UNKNOWN") .. " | LocalData.WorldsUnlocked entry=" .. entry .. "; native access uses entry presence; saved persistence unverified")
	local available, blocked = {}, {}
	for _, egg in ipairs(report.CoinsAvailability or {}) do
		local text = string.format("%s (%s Coins; %s; %s)", egg.Name, tostring(egg.Cost and egg.Cost.Amount or "UNKNOWN"), egg.AccessStatus, egg.FundingStatus)
		table.insert(egg.Loaded == true and egg.Eligible and egg.Affordable and available or blocked, text)
	end
	table.insert(lines, "Available affordable Coins eggs (loaded native models, after reserves): " .. (#available > 0 and table.concat(available, ", ") or "NONE confirmed"))
	if #blocked > 0 then table.insert(lines, "Other loaded Coins candidates: " .. table.concat(blocked, ", ")) end
	if coverage.UnloadedCoinsDefinitions and #coverage.UnloadedCoinsDefinitions > 0 then
		table.insert(lines, "Coins definitions without a loaded native model (availability unverified): " .. table.concat(coverage.UnloadedCoinsDefinitions, ", "))
	end
	local testPlan = report.HatchTestPlan
	if testPlan then
		local position = testPlan.Position
		local coordinates = position and string.format("%.1f,%.1f,%.1f", position.X, position.Y, position.Z) or "UNKNOWN"
		table.insert(lines, string.format("One-hatch proposal: stand beside %s @ %s/%s | native model=%s; root=%s; distance=%s studs; native range=%s; in range=%s | native price=%s %s; required egg/session test budget=%s/%s %s; reserve=%s; required balance=%s | spending=%s; proposal does not modify Config",
			testPlan.EggName, tostring(testPlan.World or "UNKNOWN"), tostring(testPlan.Island or "ground/unknown"), tostring(testPlan.ModelPath or "UNKNOWN"), coordinates,
			PetPolicy.Finite(testPlan.Distance) and string.format("%.1f", testPlan.Distance) or "UNKNOWN", tostring(testPlan.Range or "UNKNOWN"), tostring(testPlan.InRange),
			testPlan.NativePrice, testPlan.Currency, testPlan.RequiredEggBudget, testPlan.RequiredSessionBudget, testPlan.Currency, testPlan.Reserve, testPlan.RequiredBalance, testPlan.SpendingPermission))
	end
	local display, seen = {}, {}
	-- Always explain the explicitly selected candidate, even when rejected/missing.
	for _, name in ipairs(h.SELECTED_EGGS) do for _, egg in ipairs(report.Eggs) do if egg.Name == name and not seen[name] then table.insert(display, egg) seen[name] = true end end end
	if report.RecommendedEgg and not seen[report.RecommendedEgg.Name] then table.insert(display, report.RecommendedEgg) seen[report.RecommendedEgg.Name] = true end
	for _, egg in ipairs(report.Eggs) do if not seen[egg.Name] then table.insert(display, egg) seen[egg.Name] = true end end
	for index, egg in ipairs(display) do
		if not details and index > h.MAXIMUM_PLAN_CANDIDATES then break end
		local useful = {}
		for _, outcome in ipairs(egg.Outcomes) do
			if details or outcome.IncrementalGain > 1e-6 then
				table.insert(useful, string.format("%s %.4g%% (+%.4g)", outcome.Name, outcome.ClientPoolProbability * 100, outcome.IncrementalGain))
			end
		end
		local cost = egg.Cost
		table.insert(lines, string.format("%s @ %s/%s | cost=%s %s | access=%s; funds=%s; reserve=%s; spendable=%s; funding=%s; config=%s | EV=%s native score/egg; useful odds=%s%%; cycle=%ss | %s | %s",
			egg.Name, tostring(egg.World or "UNKNOWN"), tostring(egg.Island or "ground/unknown"), tostring(cost and cost.Amount or "UNKNOWN"), tostring(cost and cost.Currency or "UNKNOWN"),
			egg.AccessStatus, tostring(egg.Balance or "UNKNOWN"), tostring(egg.Reserve or "UNKNOWN"), tostring(egg.Spendable or "UNKNOWN"), egg.FundingStatus, egg.SpendingStatus,
			egg.Status == "ESTIMATE" and string.format("%.5g", egg.ExpectedIncrement) or "UNKNOWN",
			egg.Status == "ESTIMATE" and string.format("%.5g", egg.ClientImprovementProbability * 100) or "UNKNOWN", tostring(egg.EffectiveCycleSeconds or "UNKNOWN"),
			#useful > 0 and "useful base outcomes: " .. table.concat(useful, ", ") or "no useful supported base outcomes", PetPolicy.EggBlocker(egg) or "Useful affordable estimate; eligible for explicitly bounded request"))
	end
	table.insert(lines, report.Comparison)
	return table.concat(lines, "\n")
end

return PetPolicy

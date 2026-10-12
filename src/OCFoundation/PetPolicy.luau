--!nonstrict
-- Pure Phase 4 analysis. Native helper projections are estimates, never account writes.
local OwnerHatchTestAllowance = require(script.Parent.OwnerHatchTestAllowance)
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
	local header = string.format("%s | team=%s | equipped=%d/native limit=%d | %d records/%d pets | native estimate %.3f -> %.3f | search=%s; unique native evaluations=%d/%s; cache hits=%s; duplicate/self skips=%s/%s; rounds=%s | global optimum UNKNOWN",
		tostring(team.Currency), tostring(team.TeamIndex), team.EquippedCount, team.MaxEquipped, team.RecordCount, team.Quantity,
		team.CurrentScore, team.ProjectedScore, tostring(team.SearchStatus or "UNKNOWN"), team.Evaluations, tostring(team.EvaluationLimit or "UNKNOWN"),
		tostring(team.CacheHits or 0), tostring(team.DuplicateSwapsSkipped or 0), tostring(team.SelfSwapsSkipped or 0), tostring(team.SearchRounds or 0))
	if not details then return header .. " | proposed: " .. lineup(team.ProposedPets) .. " | details: OC:PrintPetTeam(); earnings impact unmeasured" end
	local lines = { header, "Current: " .. lineup(team.CurrentPets), "Proposed: " .. lineup(team.ProposedPets) }
	for _, group in ipairs({ { "CURRENT", team.CurrentPets }, { "PROPOSED", team.ProposedPets } }) do
		for _, r in ipairs(group[2]) do table.insert(lines, string.format("%s slot %d | %s %s [%s] | owned=%d; team copies=%d | %s stat=%s; removal marginal=%s | XP=%s | protection=%s",
			group[1], r.Slot, r.Variant, r.Name, r.Id, r.OwnedQuantity, r.EquippedCopies, tostring(team.Currency),
			tostring(r.NativeRoleStat or "UNKNOWN"), tostring(r.RemovalMarginal or "UNKNOWN"), tostring(r.XP or "UNKNOWN"), r.Protection or "none")) end
	end
	local seed = team.Seed
	if seed then table.insert(lines, string.format("Owned rank seed | %s; native FULL-team %s -> %s | hint uses quantities/protected slots; native validation, not an additive/global optimum assertion",
		seed.Status, tostring(seed.BeforeScore), tostring(seed.Score or "UNKNOWN"))) end
	table.insert(lines, string.format("Search evidence | complete=%s; native failures=%s; owned stat failures=%s; unknown records=%s; unsupported Super units=%s; denied new probes=%s; memo is exact ordered IDs within this detached analysis",
		tostring(team.SearchComplete == true), tostring(team.ProjectionFailures or 0), tostring(team.OwnedCandidateFailures or 0),
		tostring(team.UnsupportedOwnedRecords or 0), tostring(team.UnsupportedOwnedSupers or 0), tostring(team.BudgetDenied or 0)))
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

function PetPolicy.SelectionMode(config)
	return config.HATCH_SETTINGS.EGG_SELECTION_MODE or "MANUAL"
end

function PetPolicy.EggSelected(config, name)
	return PetPolicy.SelectionMode(config) == "AUTO" or table.find(config.HATCH_SETTINGS.SELECTED_EGGS, name) ~= nil
end

function PetPolicy.Reserve(config, snapshot, currency)
	local field = ({ Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" })[currency]
	if not field then return nil, "Currency reserve policy unavailable" end
	local reserve = config.RESOURCE_SETTINGS[field]
	if not PetPolicy.Finite(reserve) then return nil, "Configured currency reserve unknown" end
	if config.HATCH_SETTINGS.PRESERVE_PROGRESSION_RESERVE then
		local graph = snapshot.ProgressionGraph
		if not graph or graph.Blocker or type(graph.Worlds) ~= "table" or #graph.Worlds == 0 then return nil, "Native progression reserve unavailable" end
		for _, world in ipairs(graph.Worlds) do
			if world.Unlocked then continue end
			local cost = world.Cost
			if not cost or cost.Type ~= "Currency" or type(cost.Currency) ~= "string" or cost.Currency == "" or not PetPolicy.Finite(cost.Amount) then return nil, "Next world cost unknown; hatch reserve unresolved" end
			if cost.Currency == currency then reserve += cost.Amount end
			break
		end
	end
	if not PetPolicy.Finite(reserve) then return nil, "Combined currency reserve invalid" end
	return reserve
end

-- Bounded native full-team greedy improvement. Cross-pet enchants are evaluated by
-- the game's helper; this is explicitly a heuristic rather than an exhaustive optimum.
function PetPolicy.Team(config, context)
	local inv = context.Inventory
	local report = { Currency = context.Currency, Status = "UNKNOWN", Evidence = "Native full-team stat projection; validated feasible rank seed and bounded local search", Evaluations = 0,
		EvaluationLimit = config.PET_SETTINGS.MAXIMUM_TEAM_EVALUATIONS, EvaluationRequests = 0, CacheHits = 0,
		DuplicateSwapsSkipped = 0, SelfSwapsSkipped = 0, SearchRounds = 0, BudgetDenied = 0, SearchStatus = "UNKNOWN_INPUTS",
		MaxEquipped = context.MaxEquipped, Improvements = {}, Unknowns = { "Server-only modifiers and actual earning-rate impact unverified; native helper totals are client estimates",
			"Bounded greedy local search is not a guaranteed global optimum with interacting enchants", "No native pet-favorite contract found; use FAVORITE_PET_IDS / PROTECTED_PET_IDS" } }
	if not inv or not context.Currency or not context.ScoreTeam or not PetPolicy.Finite(context.MaxEquipped)
		or context.MaxEquipped < 1 or context.MaxEquipped % 1 ~= 0 or #inv.Team > context.MaxEquipped then
		report.Reason = context.Error or "Account, objective or native stat/capacity helper unavailable" return report
	end
	report.RecordCount, report.Quantity, report.EquippedCount = inv.Records, inv.Quantity, #inv.Team
	report.TeamIndex, report.BeforeIds = inv.TeamIndex, table.clone(inv.Team)
	local limit, memo, exhausted = config.PET_SETTINGS.MAXIMUM_TEAM_EVALUATIONS, {}, false
	local function score(ids)
		report.EvaluationRequests += 1
		-- Do not coalesce permutations: preserve exact ordered calls to the native
		-- helper. Length prefixes also avoid delimiter/ID collisions.
		local pieces = {}
		for _, id in ipairs(ids) do table.insert(pieces, tostring(#id) .. ":" .. id) end
		local key = table.concat(pieces, "|")
		local cached = memo[key]
		if cached then report.CacheHits += 1 return cached.Value, cached.Failed and "FAILED" or "OK" end
		if report.Evaluations >= limit then
			exhausted = true report.BudgetDenied += 1 return nil, "BUDGET"
		end
		report.Evaluations += 1
		local ok, value = pcall(context.ScoreTeam, ids)
		if not ok or not PetPolicy.Finite(value) then
			memo[key] = { Failed = true }
			report.ProjectionFailures = (report.ProjectionFailures or 0) + 1
			return nil, "FAILED" -- Failed native probes are retained, never converted to zero.
		end
		memo[key] = { Value = value }
		return value, "OK"
	end
	local current = score(inv.Team)
	if not current then report.Reason = "Native team score failed; no guessed fallback" report.SearchStatus = "UNKNOWN_CURRENT_SCORE" return report end
	report.CurrentScore, report.ProjectedScore, report.ProposedIds = current, current, table.clone(inv.Team)
	local candidates = {}
	local equippedCounts = PetPolicy.Counts(inv.Team)
	for id, pet in pairs(inv.ById) do
		-- Super equip constraints are a separate native capacity: preserve existing
		-- Supers but never add or replace them in this initial executor.
		local definition = (context.Pets or {})[pet.Name]
		if not definition or not definition.Rarity then
			report.UnsupportedOwnedRecords = (report.UnsupportedOwnedRecords or 0) + 1
			table.insert(report.Unknowns, pet.Name .. " [" .. id .. "]: definition/rarity UNKNOWN; preserved; paid owned benchmark unavailable") continue
		end
		if pet.Super then
			if (pet.Amount or 1) > (equippedCounts[id] or 0) then
				report.UnsupportedOwnedSupers = (report.UnsupportedOwnedSupers or 0) + (pet.Amount or 1) - (equippedCounts[id] or 0)
				table.insert(report.Unknowns, "Unequipped owned Super units need native cap/coupled-team benchmarking before paid hatch ROI")
			end
			continue
		end
		if table.find(config.PET_SETTINGS.PROTECTED_PET_IDS, id) then continue end
		local ok, value = pcall(function() return context.PetScore and context.PetScore(pet) end)
		if ok and PetPolicy.Finite(value) then table.insert(candidates, { Id = id, Score = value })
		else
			report.OwnedCandidateFailures = (report.OwnedCandidateFailures or 0) + 1
			table.insert(report.Unknowns, pet.Name .. " [" .. id .. "]: native pet stat failed; excluded")
		end
	end
	table.sort(candidates, function(a, b) return a.Score == b.Score and a.Id < b.Id or a.Score > b.Score end)
	report.CandidateRecords = #candidates
	-- Fill only the mutable slots with owned ranked units. This avoids spending
	-- seven full best-swap passes replacing a weak seven-pet lineup one unit at a
	-- time. Rankings are a seed hint; coupled effects still require native scoring
	-- and the complete local-neighborhood check below.
	local fixed, seedCounts = {}, {}
	for slot, id in ipairs(inv.Team) do
		local pet, definition = inv.ById[id], (context.Pets or {})[inv.ById[id].Name]
		if pet.Super or PetPolicy.Protected(config, pet, definition) or not definition or not definition.Rarity then
			fixed[slot] = id seedCounts[id] = (seedCounts[id] or 0) + 1
		end
	end
	local seed, candidateIndex = {}, 1
	for slot = 1, context.MaxEquipped do
		local id = fixed[slot]
		if not id then
			while candidateIndex <= #candidates do
				local candidate = candidates[candidateIndex]
				if (seedCounts[candidate.Id] or 0) < (inv.ById[candidate.Id].Amount or 1) then id = candidate.Id break end
				candidateIndex += 1
			end
			if id then seedCounts[id] = (seedCounts[id] or 0) + 1 end
		end
		if id then table.insert(seed, id) end
	end
	report.Seed = { Status = "SAME_MEMBERSHIP", BeforeScore = current, Score = current }
	if not PetPolicy.SameTeam(seed, inv.Team) then
		local value, status = score(seed)
		report.Seed.Score = value
		if status == "BUDGET" then report.Seed.Status = "BUDGET_CUTOFF"
		elseif not value then report.Seed.Status = "NATIVE_PROJECTION_FAILED"
		elseif value > current + 1e-6 then
			report.Seed.Status = "NATIVE_VALIDATED_IMPROVEMENT"
			report.ProposedIds, report.ProjectedScore = seed, value
		else report.Seed.Status = "NOT_BETTER_THAN_CURRENT" end
	end
	local converged = false
	while not exhausted do
		report.SearchRounds += 1
		local best, bestScore, improvement = nil, report.ProjectedScore, nil
		local counts = PetPolicy.Counts(report.ProposedIds)
		for _, candidate in ipairs(candidates) do
			if (counts[candidate.Id] or 0) >= (inv.ById[candidate.Id].Amount or 1) then continue end
			local removedIds = {}
			for slot = 1, #report.ProposedIds + (#report.ProposedIds < context.MaxEquipped and 1 or 0) do
				local old = inv.ById[report.ProposedIds[slot]]
				if old and old.Id == candidate.Id then report.SelfSwapsSkipped += 1 continue end
				if old and (old.Super or PetPolicy.Protected(config, old, (context.Pets or {})[old.Name]) or not (context.Pets or {})[old.Name] or not context.Pets[old.Name].Rarity) then continue end
				-- Native per-pet sums retain stack multiplicity; TeamUp folds distinct
				-- IDs in inventory order. Replacing another identical base-ID copy has
				-- the same membership/effects, not a new owned alternative.
				if old and removedIds[old.Id] then report.DuplicateSwapsSkipped += 1 continue end
				if old then removedIds[old.Id] = true end
				local ids = table.clone(report.ProposedIds) ids[slot] = candidate.Id
				local value, status = score(ids)
				if status == "BUDGET" then break end
				if value and value > bestScore + 1e-6 then
					best, bestScore = ids, value
					improvement = { AddId = candidate.Id, RemoveId = old and old.Id, BeforeScore = report.ProjectedScore, AfterScore = value }
				end
			end
			if exhausted then break end
		end
		if not best then converged = not exhausted break end
		table.insert(report.Improvements, improvement)
		report.ProposedIds, report.ProjectedScore = best, bestScore
		if exhausted then break end
	end
	report.Status = "ESTIMATE" report.SearchBoundReached = exhausted
	report.NeighborhoodConverged = converged
	report.Gain = report.ProjectedScore - current
	report.Reason = report.Gain > 0 and "A stronger owned team is available before hatching" or "No owned improvement found within bounded native projections"
	if report.SearchBoundReached then table.insert(report.Unknowns, "Search limit reached; stronger combinations may remain unevaluated") end
	if report.ProjectionFailures then table.insert(report.Unknowns, tostring(report.ProjectionFailures) .. " candidate full-team helper failures; results incomplete") end
	report.CurrentPets, report.ProposedPets = PetPolicy.Describe(config, context, report.BeforeIds), PetPolicy.Describe(config, context, report.ProposedIds)
	-- This feasible owned lineup is the spending benchmark, even when equipment
	-- changes are disabled. A weak manually equipped team creates no paid benefit.
	report.OwnedBaselineIds, report.OwnedBaselineScore = table.clone(report.ProposedIds), report.ProjectedScore
	report.BaselineIncomplete = report.SearchBoundReached or (report.ProjectionFailures or 0) > 0 or (report.OwnedCandidateFailures or 0) > 0
		or (report.UnsupportedOwnedRecords or 0) > 0 or (report.UnsupportedOwnedSupers or 0) > 0
	report.InputsComplete = (report.ProjectionFailures or 0) == 0 and (report.OwnedCandidateFailures or 0) == 0
		and (report.UnsupportedOwnedRecords or 0) == 0 and (report.UnsupportedOwnedSupers or 0) == 0
	report.SearchComplete = converged and not report.BaselineIncomplete
	report.SearchStatus = exhausted and "BUDGET_CUTOFF" or not report.InputsComplete and "UNKNOWN_OWNED_INPUTS"
		or converged and "CONVERGED_BOUNDED_HEURISTIC" or "INCOMPLETE_SEARCH"
	report.BaselineStatus = (report.UnsupportedOwnedSupers or 0) > 0 and "UNSUPPORTED_OWNED_SUPER_CONFIGURATION"
		or report.BaselineIncomplete and "INCOMPLETE_OWNED_TEAM_BASELINE" or "BOUNDED_FEASIBLE_OWNED_ESTIMATE"
	report.Optimality = "BOUNDED_FEASIBLE_OWNED_HEURISTIC; global optimum UNKNOWN"
	return report
end

function PetPolicy.HatchIsolation(config)
	local p, h = config.PET_SETTINGS, config.HATCH_SETTINGS
	if not p.ENABLE_PET_INTELLIGENCE or not p.AUTO_HATCH or p.AUTO_EQUIP or p.EQUIP_OWNED_TEAM_ONCE
		or p.OBJECTIVE_CURRENCY ~= "Coins" or not h.HATCH_ONE_EGG_ONCE then return "Single hatch requires explicit isolated Coins hatch authorization; equipment OFF" end
	local mode = PetPolicy.SelectionMode(config)
	if mode ~= "AUTO" and mode ~= "MANUAL" then return "Single hatch requires AUTO or MANUAL egg selection" end
	if mode == "MANUAL" and #h.SELECTED_EGGS ~= 1 or #h.ALLOWED_CURRENCIES ~= 1 or h.ALLOWED_CURRENCIES[1] ~= "Coins"
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

function PetPolicy.FundEgg(config, snapshot, r, accountId)
	local h = config.HATCH_SETTINGS
	r.SpendingStatus = not config.PET_SETTINGS.AUTO_HATCH and "DISABLED_AUTO_HATCH" or (h.MAXIMUM_EGG_COST <= 0 or h.MAXIMUM_SESSION_COST <= 0) and "DISABLED_ZERO_BUDGET"
		or not PetPolicy.EggSelected(config, r.Name) and "NOT_SELECTED" or "AUTHORIZED_CONFIG"
	local cost = r.Cost
	if cost and cost.Type == "Currency" and PetPolicy.Finite(cost.Amount) and cost.Amount > 0 then
		r.Balance = snapshot.Balances and snapshot.Balances[cost.Currency]
		r.Reserve, r.ReserveReason = PetPolicy.Reserve(config, snapshot, cost.Currency)
		r.NormalReserve = r.Reserve
		if config.OWNER_ONE_HATCH_TEST_SETTINGS and config.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_HATCH_TEST_ALLOWANCE then
			local allowance = OwnerHatchTestAllowance.EffectiveFunds(config, snapshot, cost.Currency, r.Name, r.Balance, accountId)
			r.OwnerTestAllowance = allowance
			if r.NormalReserve ~= nil and allowance.Eligible and cost.Amount <= config.OWNER_ONE_HATCH_TEST_SETTINGS.MAXIMUM_EGG_COST then
				r.Reserve, r.ReserveReason = allowance.EffectiveReserve, nil
			else r.OwnerTestBlocker = r.NormalReserve == nil and r.ReserveReason or allowance.Reason or "OWNER_TEST_EGG_CEILING" end
		end
		if PetPolicy.Finite(r.Balance) then r.FundsAffordable = r.Balance >= cost.Amount end
		if r.Reserve ~= nil and PetPolicy.Finite(r.Balance) then
			r.Spendable = math.max(0, r.Balance - r.Reserve)
			r.ReserveAllows = r.Spendable >= cost.Amount
		end
		r.Affordable = r.FundsAffordable == true and r.ReserveAllows == true
		r.FundingStatus = r.FundsAffordable == nil and "UNKNOWN_BALANCE" or not r.FundsAffordable and "INSUFFICIENT_FUNDS"
			or r.Reserve == nil and "UNKNOWN_RESERVE" or not r.ReserveAllows and "PROTECTED_RESERVE" or "AFFORDABLE"
		if r.OwnerTestBlocker then r.Affordable = false r.FundingStatus = "OWNER_TEST_ALLOWANCE_BLOCKED: " .. r.OwnerTestBlocker end
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
		Cost = egg.Cost, Reason = egg.Reason, ProbabilityEvidence = "CLIENT_POOL_WEIGHT_ESTIMATE; conditional normalized native sampler model",
		EffectiveServerOdds = "UNKNOWN", VariantOdds = "UNKNOWN", PityGuarantee = "UNKNOWN", TotalTimeSeconds = "UNKNOWN",
		TravelTimeSeconds = "UNKNOWN", VerificationTimeSeconds = "UNKNOWN", StorageUnit = context.StorageUnit,
		DurationSeconds = egg.Duration, NativeBatchCapacity = context.MaxHatches, Outcomes = {},
		SelectionMode = PetPolicy.SelectionMode(config), OrdinaryLuck = egg.Luck,
		SecretLuck = "UNKNOWN_EFFECTIVE", InfinityLuck = "UNKNOWN_EFFECTIVE", BatchExpectedIncrement = "UNKNOWN",
		BatchEvidence = "Single outcome marginal only; duplicate saturation/interacting teams prevent linear batch utility; replan from actual received inventory" }
	PetPolicy.FundEgg(config, snapshot, r, context.AccountId)
	local cost = egg.Cost
	-- Funding/configuration/access are separate from the supported pool estimate.
	if egg.Loaded == false then r.Reason = egg.Reason return r end
	if not cost or cost.Type ~= "Currency" or not PetPolicy.Finite(cost.Amount) or cost.Amount <= 0 then r.Reason = "Native currency cost unavailable/unsupported" return r end
	if team.Status ~= "ESTIMATE" or not context.ScoreNewPet or type(egg.Pool) ~= "table"
		or type(team.ProposedIds) ~= "table" or not PetPolicy.Finite(team.ProjectedScore) then r.Reason = "Insufficient native owned-team/pool evidence" return r end
	-- Keep the received equipped score for disclosure, but benchmark a purchase
	-- against the strongest feasible owned lineup found by the existing search.
	-- Proposed IDs obey quantities/protections/Super preservation; this is an
	-- analysis projection and never equipment authorization or a global optimum.
	r.BaselineIds, r.BaselineScore = table.clone(team.ProposedIds), team.ProjectedScore
	r.CurrentEquippedScore, r.OwnedImprovementAvailable = team.CurrentScore, team.Gain
	r.BaselineEvidence = "BOUNDED_FEASIBLE_OWNED_TEAM; native full-team estimate, global optimum UNKNOWN"
	r.BaselineSearchBoundReached = team.SearchBoundReached
	r.BaselineIncomplete, r.BaselineStatus = team.BaselineIncomplete, team.BaselineStatus
	r.BaselineProjectionFailures = (team.ProjectionFailures or 0) + (team.OwnedCandidateFailures or 0)
	r.OutcomeProjectionEvidence = "One base XP0 acquisition, best supported single replacement/addition from the owned benchmark; unseen coupled combinations UNKNOWN"
	local total, poolLength = 0, 0
	for index in pairs(egg.Pool) do
		if type(index) ~= "number" or index < 1 or index % 1 ~= 0 then r.Reason = "Unknown non-array native pool" return r end
		poolLength += 1
	end
	for index = 1, poolLength do if egg.Pool[index] == nil then r.Reason = "Incomplete native pool array" return r end end
	for _, entry in ipairs(egg.Pool) do
		if type(entry) ~= "table" or not PetPolicy.Finite(entry.Chance) then r.Reason = "Unknown pool weight" return r end
		total += entry.Chance
	end
	if not PetPolicy.Finite(total) or total <= 0 then r.Reason = "Empty or invalid native pool weight total" return r end
	r.PoolTotalWeight = total
	local expected, improveChance, targetChance = 0, 0, 0
	local projections = {}
	for _, entry in ipairs(egg.Pool) do
		local item = entry.Item
		if entry.Chance == 0 then continue end
		if type(item) ~= "table" or item.Type ~= "Pet" or type(item.Name) ~= "string" or not (context.Pets or {})[item.Name] then r.Reason = "Unsupported pool outcome" return r end
		local value = projections[item.Name]
		if value == nil then value = context.ScoreNewPet(item.Name, r.BaselineIds) projections[item.Name] = value end
		if not PetPolicy.Finite(value) then r.Reason = "Native pet contribution unavailable" return r end
		local probability = entry.Chance / total -- Inspected native weighted sampler; NOT verified server RNG.
		local gain = math.max(0, value - r.BaselineScore)
		expected += gain * probability
		if gain > 1e-6 then improveChance += probability end
		if table.find(config.PET_SETTINGS.SELECTED_PETS, item.Name) then targetChance += probability end
		table.insert(r.Outcomes, { Name = item.Name, ClientPoolProbability = probability, IncrementalGain = gain,
			ProjectedScore = value, BaselineScore = r.BaselineScore })
	end
	if not PetPolicy.Finite(expected) then r.Reason = "Invalid expected native contribution" return r end
	r.Status, r.ExpectedIncrement, r.ClientImprovementProbability, r.ClientTargetProbability = "ESTIMATE", expected, improveChance, targetChance
	r.ExpectedIncrementPerCost = expected / cost.Amount
	local capacity = PetPolicy.Finite(context.MaxHatches) and context.MaxHatches >= 1 and context.MaxHatches % 1 == 0 and context.MaxHatches or 0
	local free = PetPolicy.Finite(context.StorageCapacity) and PetPolicy.Finite(context.StorageUsed) and math.max(0, math.floor(context.StorageCapacity - context.StorageUsed)) or 0
	r.CapacityStatus = type(context.DigitalStorage) ~= "boolean" and "UNKNOWN_STORAGE_MODE"
		or context.InventoryFull ~= false and "CAPACITY_UNAVAILABLE_OR_FULL"
		or not context.AutoDeleteKnown and "UNKNOWN_AUTO_DELETE_SETTINGS"
		or context.AutoDeleteActive and "NATIVE_AUTO_DELETE_ACTIVE"
		or capacity < 1 and "UNKNOWN_NATIVE_HATCH_CAPACITY"
		or not context.DigitalStorage and (not PetPolicy.Finite(context.StorageCapacity) or not PetPolicy.Finite(context.StorageUsed)) and "UNKNOWN_STORAGE_CAPACITY"
		or not context.DigitalStorage and free < 1 and "NO_FREE_PET_QUANTITY" or "AVAILABLE"
	if context.DigitalStorage then free = 1 end -- Native available-space check, never convert JSON bytes to pet slots.
	local batch = r.CapacityStatus == "AVAILABLE" and math.floor(math.min(h.MAXIMUM_BATCH_HATCHES, capacity, free, egg.Opened == false and 1 or math.huge)) or 0
	-- One first-test draw or authorized batch may be smaller than native capacity.
	if r.Spendable ~= nil then batch = math.min(batch, math.floor(r.Spendable / cost.Amount)) else batch = 0 end
	if config.PET_SETTINGS.AUTO_HATCH then
		batch = math.min(batch, h.MAXIMUM_SESSION_HATCHES, math.floor(h.MAXIMUM_SESSION_COST / cost.Amount))
	end
	r.EffectiveBatchCapacity = math.max(0, batch)
	if PetPolicy.Finite(egg.Duration) and egg.Duration > 0 and PetPolicy.Finite(context.MaxHatches) and context.MaxHatches >= 1 then
		r.EffectiveCycleSeconds = math.max(egg.Duration, h.MINIMUM_REQUEST_INTERVAL_SECONDS)
		-- Time efficiency describes one acquisition per cycle. Multiplying its team
		-- marginal by a batch overvalues duplicates once useful equip slots fill.
		r.ExpectedIncrementPerSecond = expected / r.EffectiveCycleSeconds
		r.TimeEfficiencyEvidence = "Single-draw native gain/cycle; excludes unknown travel, verification and server cadence"
		r.PotentialDrawsPerSecond = r.EffectiveBatchCapacity / r.EffectiveCycleSeconds
		if improveChance > 0 and r.EffectiveBatchCapacity >= 1 then
			local probability = 1 - (1 - improveChance) ^ r.EffectiveBatchCapacity
			if probability > 0 then
				r.ClientFirstUsefulBatchProbability = probability
				r.EstimatedSecondsToUsefulBasePet = r.EffectiveCycleSeconds / probability
				r.FirstUsefulTimeEvidence = "CONDITIONAL independent stationary client base draws; not measured time or verified server odds"
			end
		end
	end
	r.Reason = expected > 1e-6 and "Useful base-pet estimate against feasible OWNED-team benchmark; optimality/server odds UNKNOWN" or "NO_USEFUL_IMPROVEMENT against feasible owned-team benchmark"
	return r
end

function PetPolicy.EggBlocker(egg)
	if egg.Loaded ~= true then return "NOT_LOADED: actual native egg model required" end
	if not egg.Eligible then return egg.AccessStatus .. ": " .. tostring(egg.Reason) end
	if egg.Status ~= "ESTIMATE" then return "INSUFFICIENT_EVIDENCE: " .. tostring(egg.Reason) end
	if egg.BaselineIncomplete or egg.BaselineSearchBoundReached or (egg.BaselineProjectionFailures or 0) > 0 then
		return tostring(egg.BaselineStatus or "INCOMPLETE_OWNED_TEAM_BASELINE") .. ": incomplete search, unscored owned record/Super or native projection; no paid hatch before owned alternatives are evaluated"
	end
	if egg.ExpectedIncrement <= 1e-6 then return "NO_USEFUL_IMPROVEMENT in evaluated base-pet pool" end
	if egg.FundingStatus ~= "AFFORDABLE" then return egg.FundingStatus .. (egg.ReserveReason and ": " .. egg.ReserveReason or "") end
	if egg.SpendingStatus ~= "AUTHORIZED_CONFIG" then return egg.SpendingStatus end
	if egg.CapacityStatus ~= "AVAILABLE" or (egg.EffectiveBatchCapacity or 0) < 1 then return egg.CapacityStatus or "UNKNOWN_NATIVE_HATCH_CAPACITY" end
	if not PetPolicy.Finite(egg.DurationSeconds) or egg.DurationSeconds <= 0 then return "UNKNOWN_NATIVE_HATCH_DURATION" end
	return nil
end

function PetPolicy.Analyze(config, snapshot, context)
	local report = { Team = PetPolicy.Team(config, context), Eggs = {}, CoinsAvailability = {}, Currency = context.Currency,
		AccountRevision = snapshot.Revision, Coverage = context.EggCoverage, MinigameParadise = context.MinigameParadise,
		SelectionMode = PetPolicy.SelectionMode(config) }
	for _, egg in ipairs(context.EggAvailability or context.Eggs or {}) do
		if egg.Cost and egg.Cost.Type == "Currency" and egg.Cost.Currency == "Coins" or egg.Cost == nil and egg.DefinitionCurrency == "Coins" then
			table.insert(report.CoinsAvailability, PetPolicy.FundEgg(config, snapshot, { Name = egg.Name, Cost = egg.Cost,
				Loaded = egg.Loaded, Eligible = egg.Accessible == true, AccessStatus = egg.AccessStatus or "UNKNOWN_ACCESS", World = egg.World, Island = egg.Island }, context.AccountId))
		end
	end
	table.sort(report.CoinsAvailability, function(a, b) return a.Name < b.Name end)
	for _, egg in ipairs(context.Eggs or {}) do table.insert(report.Eggs, PetPolicy.Egg(config, snapshot, context, report.Team, egg)) end
	local function recommendable(egg)
		return egg.Loaded == true and egg.Status == "ESTIMATE" and egg.Eligible and egg.Affordable
			and egg.Cost and table.find(config.HATCH_SETTINGS.ALLOWED_CURRENCIES, egg.Cost.Currency) ~= nil
			and egg.ExpectedIncrement > 1e-6 and egg.CapacityStatus == "AVAILABLE"
			and PetPolicy.Finite(egg.DurationSeconds) and egg.DurationSeconds > 0
			and (PetPolicy.EggSelected(config, egg.Name) or report.SelectionMode == "MANUAL" and #config.HATCH_SETTINGS.SELECTED_EGGS == 0)
	end
	local function tier(egg)
		return PetPolicy.EggBlocker(egg) == nil and 2 or recommendable(egg) and 1 or 0
	end
	table.sort(report.Eggs, function(a, b)
		local at, bt = tier(a), tier(b)
		if at ~= bt then return at > bt end
		local ac, bc = a.Cost and a.Cost.Currency or "UNKNOWN", b.Cost and b.Cost.Currency or "UNKNOWN"
		if ac ~= bc then
			local x, y = table.find(config.HATCH_SETTINGS.ALLOWED_CURRENCIES, ac), table.find(config.HATCH_SETTINGS.ALLOWED_CURRENCIES, bc)
			if (x ~= nil) ~= (y ~= nil) then return x ~= nil end
			if x and y then return x < y end -- Owner's currency order, never an exchange rate.
			return ac < bc -- Separate currency groups; never compare their numeric EV/cost.
		end
		local x, y = at > 0 and a.ExpectedIncrementPerCost or -1, bt > 0 and b.ExpectedIncrementPerCost or -1
		if x == y then
			local ax, bx = a.ExpectedIncrementPerSecond or -1, b.ExpectedIncrementPerSecond or -1
			if ax ~= bx then return ax > bx end
			return a.Name < b.Name -- Deterministic tie; no random or event preference.
		end
		return x > y
	end)
	for _, egg in ipairs(report.Eggs) do
		if not report.RecommendedEgg and recommendable(egg) then report.RecommendedEgg = egg end
		if not report.ActionEgg and PetPolicy.EggBlocker(egg) == nil then report.ActionEgg = egg end
	end
	local selected = report.ActionEgg or report.RecommendedEgg
	if selected then
		report.SelectionExplanation = string.format("%s %s %s | owned benchmark %.5g -> expected single-draw +%.5g %s native score | %.5g gain/%s; %.5g single-draw gain/s | cost %.5g %s; reserve %.5g; native capacity %s; cycle %ss | action=%s; client base-pool estimate; global optimum/server odds/travel time UNKNOWN",
			report.SelectionMode, report.ActionEgg and "selected" or "advisory recommendation", selected.Name, selected.BaselineScore, selected.ExpectedIncrement, tostring(context.Currency),
			selected.ExpectedIncrementPerCost, selected.Cost.Currency, selected.ExpectedIncrementPerSecond or 0, selected.Cost.Amount, selected.Cost.Currency,
			selected.Reserve, tostring(selected.NativeBatchCapacity), tostring(selected.EffectiveCycleSeconds or "UNKNOWN"), PetPolicy.EggBlocker(selected) or "CONFIG_READY; Brain/dispatch guards required")
	else
		local blockers = {}
		for _, candidate in ipairs(report.Eggs) do
			if PetPolicy.EggSelected(config, candidate.Name) then table.insert(blockers, candidate.Name .. ": " .. tostring(PetPolicy.EggBlocker(candidate) or "No feasible useful estimate")) end
			if #blockers >= config.HATCH_SETTINGS.MAXIMUM_PLAN_CANDIDATES then break end
		end
		report.SelectionExplanation = #blockers > 0 and table.concat(blockers, "; ") or "No useful eligible loaded native egg for selection; WAIT, no random fallback"
	end
	local egg = report.RecommendedEgg
	if egg then
		report.HatchTestPlan = { EggName = egg.Name, Currency = egg.Cost.Currency, NativePrice = egg.Cost.Amount,
			RequiredEggBudget = egg.Cost.Amount, RequiredSessionBudget = egg.Cost.Amount, HatchCount = 1,
			World = egg.World, Island = egg.Island, ModelPath = egg.ModelPath, Position = egg.Position, Distance = egg.Distance,
			Range = egg.Range, InRange = egg.InRange, Reserve = egg.Reserve, RequiredBalance = egg.Reserve + egg.Cost.Amount,
			BaselineStatus = egg.BaselineStatus,
			SpendingPermission = not config.PET_SETTINGS.AUTO_HATCH and "OFF; owner authorization required"
				or PetPolicy.EggBlocker(egg) and "BLOCKED: " .. PetPolicy.EggBlocker(egg) or "CONFIG_READY; execution guards still required",
			PriceEvidence = "StatsUtil:GetEggCost(player, detached current LocalData, egg); native client price; rechecked before any authorized request; server acceptance unverified" }
	end
	report.Comparison = "Owned-team benchmark is a feasible bounded native search, global optimum UNKNOWN. Rank gain/cost then single-draw gain/time within currency; configured currency order is not a conversion. Client base odds/XP=0 estimates; final server/variant/Secret/Infinity odds, pity and batch team EV UNKNOWN; total travel/verification time UNKNOWN"
	return report
end

function PetPolicy.EggPlanText(config, report, details)
	local h, coverage = config.HATCH_SETTINGS, report.Coverage or {}
	if (config.EGG_TRAVEL_SETTINGS.MODE or "NORMAL") == "TRAVEL_ONLY" and not details then
		return string.format("TRAVEL_ONLY | physical original locations=%s; unique hatch models=%s (separate verification) | owned native benchmark=%s; comparisons=%s; global optimum UNKNOWN | hatch/equipment/pickups OFF; spending=0; target selection/physical arrival pending",
			tostring(coverage.PhysicalLocations or "UNKNOWN"), tostring(coverage.LoadedModels or "UNKNOWN"), tostring(report.Team.ProjectedScore or "UNKNOWN"), tostring(report.Team.Evaluations or "UNKNOWN"))
	end
	local lines = { string.format("%s | actual equipped native score=%s; feasible owned benchmark=%s (bounded heuristic) | loaded=%s; pool analyses=%s/%s limit; native definitions=%s (%s permanent); limited loaded-model coverage | mode=%s; AUTO_HATCH=%s; egg/session budgets=%s/%s | recommendation=%s",
		tostring(report.Currency), tostring(report.Team.CurrentScore or "UNKNOWN"), tostring(report.Team.ProjectedScore or "UNKNOWN"), tostring(coverage.LoadedModels or "UNKNOWN"), tostring(coverage.Evaluated or #report.Eggs),
		tostring(coverage.Limit or h.MAXIMUM_EGGS_ANALYZED), tostring(coverage.Definitions or "UNKNOWN"), tostring(coverage.PermanentDefinitions or "UNKNOWN"),
			tostring(report.SelectionMode), tostring(config.PET_SETTINGS.AUTO_HATCH), tostring(h.MAXIMUM_EGG_COST), tostring(h.MAXIMUM_SESSION_COST), report.RecommendedEgg and report.RecommendedEgg.Name or "NONE within evaluated accessible affordable estimates") }
	table.insert(lines, "Owned benchmark status=" .. tostring(report.Team.BaselineStatus or "UNKNOWN")
		.. "; search=" .. tostring(report.Team.SearchStatus or "UNKNOWN") .. "; unique native comparisons=" .. tostring(report.Team.Evaluations or 0)
		.. "; cache hits=" .. tostring(report.Team.CacheHits or 0)
		.. (report.Team.BaselineIncomplete and "; paid hatching blocked by incomplete search/input; see team diagnostics" or "; feasible completed bounded benchmark; global optimum UNKNOWN"))
	local allowance = config.OWNER_ONE_HATCH_TEST_SETTINGS
	table.insert(lines, "Funding policy=" .. (allowance and allowance.OWNER_ONE_HATCH_TEST_ALLOWANCE and "EXPLICIT OWNER ONE-HATCH TEST; named egg, capped held-world funds only" or "NORMAL; full native next-world reserve preserved; owner test allowance OFF"))
	table.insert(lines, report.SelectionExplanation or "Egg selection UNKNOWN")
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
		if egg.OwnerTestAllowance then
			local funds = egg.OwnerTestAllowance
			table.insert(lines, "OWNER_ONE_HATCH_TEST | " .. egg.Name .. "; normal reserve=" .. tostring(egg.NormalReserve or "UNKNOWN")
				.. "; held world funds=" .. tostring(funds.HeldWorldReserve or "UNKNOWN") .. "; additional allowance=" .. tostring(funds.AdditionalSpendable or 0)
				.. "; eligibility=" .. tostring(funds.Eligible) .. "; " .. tostring(funds.Reason or "one request only; normal settings unchanged"))
		end
		local useful = {}
		for _, outcome in ipairs(egg.Outcomes) do
			if details or outcome.IncrementalGain > 1e-6 then
				table.insert(useful, string.format("%s %.4g%% (+%.4g)", outcome.Name, outcome.ClientPoolProbability * 100, outcome.IncrementalGain))
			end
		end
		local cost = egg.Cost
		table.insert(lines, string.format("%s @ %s/%s | cost=%s %s | access=%s; funds=%s; reserve=%s; spendable=%s; funding=%s; config=%s | owned benchmark=%s; EV=%s native score/egg; client useful base-pool probability=%s%%; cycle=%ss; feasible batch=%s | %s | %s",
			egg.Name, tostring(egg.World or "UNKNOWN"), tostring(egg.Island or "ground/unknown"), tostring(cost and cost.Amount or "UNKNOWN"), tostring(cost and cost.Currency or "UNKNOWN"),
			egg.AccessStatus, tostring(egg.Balance or "UNKNOWN"), tostring(egg.Reserve or "UNKNOWN"), tostring(egg.Spendable or "UNKNOWN"), egg.FundingStatus, egg.SpendingStatus,
			tostring(egg.BaselineScore or "UNKNOWN"), egg.Status == "ESTIMATE" and string.format("%.5g", egg.ExpectedIncrement) or "UNKNOWN",
			egg.Status == "ESTIMATE" and string.format("%.5g", egg.ClientImprovementProbability * 100) or "UNKNOWN", tostring(egg.EffectiveCycleSeconds or "UNKNOWN"), tostring(egg.EffectiveBatchCapacity or "UNKNOWN"),
			#useful > 0 and "useful base outcomes: " .. table.concat(useful, ", ") or "no useful supported base outcomes", PetPolicy.EggBlocker(egg) or "Useful affordable estimate; eligible for explicitly bounded request"))
	end
	table.insert(lines, report.Comparison)
	return table.concat(lines, "\n")
end

return PetPolicy

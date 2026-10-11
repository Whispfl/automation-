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

function PetPolicy.Egg(config, snapshot, context, team, egg)
	local r = { Name = egg.Name, Status = "UNKNOWN", Eligible = egg.Accessible == true, InRange = egg.InRange == true,
		Distance = egg.Distance, Cost = egg.Cost, Reason = egg.Reason, ProbabilityEvidence = "CLIENT_UI_POOL_ESTIMATE",
		EffectiveServerOdds = "UNKNOWN", VariantOdds = "UNKNOWN", PityGuarantee = "UNKNOWN", TotalTimeSeconds = "UNKNOWN",
		TravelTimeSeconds = "UNKNOWN", VerificationTimeSeconds = "UNKNOWN", StorageUnit = context.StorageUnit }
	local cost = egg.Cost
	if not r.Eligible or not cost or cost.Type ~= "Currency" or not PetPolicy.Finite(cost.Amount) or cost.Amount <= 0 then return r end
	local reserve, reason = PetPolicy.Reserve(config, snapshot, cost.Currency)
	r.Reserve = reserve
	local balance = snapshot.Balances and snapshot.Balances[cost.Currency]
	if not reserve or not PetPolicy.Finite(balance) then r.Reason = reason or "Balance unknown" return r end
	r.Spendable = math.max(0, balance - reserve) r.Affordable = r.Spendable >= cost.Amount
	r.DurationSeconds, r.NativeBatchCapacity = egg.Duration, context.MaxHatches
	if team.Status ~= "ESTIMATE" or not context.ScoreNewPet or type(egg.Pool) ~= "table" then r.Reason = "Native team/pool estimate unavailable" return r end
	local total = 0
	for _, entry in ipairs(egg.Pool) do
		if not PetPolicy.Finite(entry.Chance) then r.Reason = "Unknown pool weight" return r end
		total += entry.Chance
	end
	if total <= 0 then r.Reason = "Empty native pool" return r end
	local expected, improveChance, targetChance, outcomes = 0, 0, 0, {}
	for _, entry in ipairs(egg.Pool) do
		local item = entry.Item
		if entry.Chance == 0 then continue end
		if not item or item.Type ~= "Pet" or not (context.Pets or {})[item.Name] then r.Reason = "Unsupported pool outcome" return r end
		local value = context.ScoreNewPet(item.Name, team.ProposedIds)
		if not PetPolicy.Finite(value) then r.Reason = "Native pet contribution unavailable" return r end
		local probability = entry.Chance / total -- Inspected native weighted sampler; NOT verified server RNG.
		local gain = math.max(0, value - team.ProjectedScore)
		expected += gain * probability
		if gain > 1e-6 then improveChance += probability end
		if table.find(config.PET_SETTINGS.SELECTED_PETS, item.Name) then targetChance += probability end
		table.insert(outcomes, { Name = item.Name, ClientPoolProbability = probability, IncrementalGain = gain })
	end
	r.Status, r.ExpectedIncrement, r.ClientImprovementProbability, r.ClientTargetProbability = "ESTIMATE", expected, improveChance, targetChance
	r.ExpectedIncrementPerCost, r.Outcomes = expected / cost.Amount, outcomes
	if PetPolicy.Finite(egg.Duration) and egg.Duration > 0 and PetPolicy.Finite(context.MaxHatches) and context.MaxHatches >= 1 then
		local batch = math.min(config.HATCH_SETTINGS.MAXIMUM_BATCH_HATCHES, context.MaxHatches, context.DigitalStorage and 1 or math.huge)
		r.EffectiveCycleSeconds = math.max(egg.Duration, config.HATCH_SETTINGS.MINIMUM_REQUEST_INTERVAL_SECONDS)
		r.ExpectedIncrementPerSecond = expected * batch / r.EffectiveCycleSeconds
		if improveChance > 0 then r.EstimatedSecondsToUsefulBasePet = r.EffectiveCycleSeconds / (batch * improveChance) end
	end
	r.Reason = "Base-pet incremental estimate after owned-team improvement; variants, additional Secret/Infinity odds and server pity unknown; travel/verification overhead unmeasured"
	return r
end

function PetPolicy.Analyze(config, snapshot, context)
	local report = { Team = PetPolicy.Team(config, context), Eggs = {}, Currency = context.Currency, AccountRevision = snapshot.Revision }
	for _, egg in ipairs(context.Eggs or {}) do table.insert(report.Eggs, PetPolicy.Egg(config, snapshot, context, report.Team, egg)) end
	table.sort(report.Eggs, function(a, b)
		local x = a.Status == "ESTIMATE" and a.Eligible and a.Affordable and a.ExpectedIncrementPerCost or -1
		local y = b.Status == "ESTIMATE" and b.Eligible and b.Affordable and b.ExpectedIncrementPerCost or -1
		if x == y then
			local p, q = a.ExpectedIncrementPerSecond or -1, b.ExpectedIncrementPerSecond or -1
			return p == q and a.Name < b.Name or p > q
		end
		return x > y
	end)
	for _, egg in ipairs(report.Eggs) do
		if egg.Status == "ESTIMATE" and egg.Eligible and egg.Affordable and table.find(config.HATCH_SETTINGS.ALLOWED_CURRENCIES, egg.Cost.Currency)
			and (egg.ExpectedIncrement > 1e-6 or egg.ClientTargetProbability > 0) then report.RecommendedEgg = egg break end
	end
	report.Comparison = "Cost efficiency is within native currency units only; currencies have no invented conversion; total travel/verification time UNKNOWN"
	return report
end

return PetPolicy

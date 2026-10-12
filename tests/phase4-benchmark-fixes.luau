do
-- Synthetic owned projections: the observed live shape is reproduced, not the
-- owner's inventory or a live earning-rate/server-optimality claim.
local before = tests
local Policy = requireOC("PetPolicy")
local function fixture(records, ids, cap, limit)
	local cfg = config({ PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, OBJECTIVE_CURRENCY = "Coins",
		MAXIMUM_TEAM_EVALUATIONS = limit or 1000 } })
	local raw = { Pets = records, Teams = { { Pets = ids } }, TeamEquipped = 1 }
	local ctx = { Currency = "Coins", Inventory = Policy.Inventory(raw), MaxEquipped = cap, Pets = {}, Calls = {} }
	for _, pet in ipairs(records) do ctx.Pets[pet.Name] = { Rarity = "Common" } end
	ctx.PetScore = function(pet) return pet.TestContribution + 1 end
	ctx.ScoreTeam = function(team)
		local value = 4
		for _, id in ipairs(team) do value += ctx.Inventory.ById[id].TestContribution end
		local key = table.concat(team, ",") ctx.Calls[key] = (ctx.Calls[key] or 0) + 1
		return value
	end
	return cfg, ctx, raw
end

test("Phase 4 benchmark 24 records 59 units seven slots converges within the unchanged 1000 cap", function()
	local records = { { Id = "weak", Name = "Weak", Amount = 7, TestContribution = 0 },
		{ Id = "best", Name = "Best", Amount = 6, TestContribution = 250 },
		{ Id = "next", Name = "Next", TestContribution = 248 } }
	for index = 4, 24 do table.insert(records, { Id = "pet" .. index, Name = "Pet" .. index,
		Amount = index == 4 and 5 or 2, TestContribution = 200 - index }) end
	local ids = {} for _ = 1, 7 do table.insert(ids, "weak") end
	local cfg, ctx, raw = fixture(records, ids, 7)
	local team = Policy.Team(cfg, ctx)
	assert(team.RecordCount == 24 and team.Quantity == 59 and team.CurrentScore == 4 and team.ProjectedScore == 1752)
	assert(team.Evaluations < 1000 and not team.SearchBoundReached and team.SearchComplete and not team.BaselineIncomplete)
	assert(team.SearchStatus == "CONVERGED_BOUNDED_HEURISTIC" and team.Seed.Status == "NATIVE_VALIDATED_IMPROVEMENT")
	assert(Policy.Counts(team.ProposedIds).best == 6 and Policy.Counts(team.ProposedIds).next == 1 and team.DuplicateSwapsSkipped > 0)
	assert(Policy.SameTeam(raw.Teams[1].Pets, ids) and team.Optimality:find("global optimum UNKNOWN", 1, true))
	-- The prior per-slot steepest loop expends at least 7 full 24-record rounds
	-- even while replacing identical Weak copies. Reproduce its cutoff directly.
	local evaluations, proposed, projected = 1, table.clone(ids), ctx.ScoreTeam(ids)
	local ordered = table.clone(records) table.sort(ordered, function(a, b) return a.TestContribution > b.TestContribution end)
	local cut = false
	while evaluations < 1000 do
		local best, bestScore = nil, projected
		local counts = Policy.Counts(proposed)
		for _, pet in ipairs(ordered) do
			if (counts[pet.Id] or 0) >= (pet.Amount or 1) then continue end
			for slot = 1, #proposed do
				if evaluations >= 1000 then cut = true break end
				local candidate = table.clone(proposed) candidate[slot] = pet.Id
				evaluations += 1 local score = ctx.ScoreTeam(candidate)
				if score > bestScore then best, bestScore = candidate, score end
			end
			if cut then break end
		end
		if best then proposed, projected = best, bestScore else break end
		if cut then break end
	end
	assert(cut and evaluations == 1000, "Fixture must reproduce the actual old budget failure shape")
	print(string.format("[OC TEST] Synthetic 24/59/7 benchmark | old cutoff=%d; new unique=%d; duplicate skips=%d; rounds=%d; score=%.0f -> %.0f",
		evaluations, team.Evaluations, team.DuplicateSwapsSkipped, team.SearchRounds, team.CurrentScore, team.ProjectedScore))
	local text = Policy.TeamText(team, true)
	assert(text:find("unique native evaluations", 1, true) and text:find("duplicate/self skips", 1, true) and text:find("global optimum UNKNOWN", 1, true))
end)

test("Phase 4 benchmark rank seed is rejected when native coupled team utility is stronger", function()
	local cfg, ctx = fixture({ { Id = "normal", Name = "Normal", Amount = 2, TestContribution = 10 },
		{ Id = "teamA", Name = "TeamA", Enchants = { { Id = "team-up", Level = 5 } }, TestContribution = 8 },
		{ Id = "teamB", Name = "TeamB", Enchants = { { Id = "team-up", Level = 5 } }, TestContribution = 8 } }, { "teamA", "teamB" }, 2)
	ctx.ScoreTeam = function(ids)
		local counts, coupled, score = Policy.Counts(ids), 0, 0
		for id in pairs(counts) do if ctx.Inventory.ById[id].Enchants then coupled += 1 end end
		for _, id in ipairs(ids) do local pet = ctx.Inventory.ById[id] score += pet.TestContribution * (pet.Enchants and (1 + coupled * 0.25) or 1) end
		return score
	end
	local team = Policy.Team(cfg, ctx)
	assert(team.CurrentScore == 24 and team.ProjectedScore == 24 and Policy.SameTeam(team.ProposedIds, { "teamA", "teamB" }))
	assert(team.Seed.Score == 20 and team.Seed.Status == "NOT_BETTER_THAN_CURRENT" and team.SearchComplete)
	assert(team.Optimality:find("global optimum UNKNOWN", 1, true))
end)

test("Phase 4 benchmark memo retains ordered team identities and revisited native projections", function()
	local cfg, ctx = fixture({ { Id = "A", Name = "A", Amount = 2, TestContribution = 20 },
		{ Id = "B", Name = "B", Amount = 2, TestContribution = 19 }, { Id = "C", Name = "C", Amount = 2, TestContribution = 18 } }, { "B", "C" }, 2)
	local values = { ["A,A"] = 1, ["B,C"] = 10, ["A,C"] = 12, ["B,A"] = 11, ["B,B"] = 9,
		["C,C"] = 8, ["A,B"] = 13, ["C,B"] = 14, ["C,A"] = 7 }
	ctx.ScoreTeam = function(ids) local key = table.concat(ids, ",") ctx.Calls[key] = (ctx.Calls[key] or 0) + 1 return values[key] end
	local team = Policy.Team(cfg, ctx)
	assert(team.ProjectedScore == 14 and Policy.Equal(team.ProposedIds, { "C", "B" }) and team.CacheHits > 0 and team.SearchComplete)
	assert(ctx.Calls["B,A"] == 1 and ctx.Calls["A,B"] == 1, "Different ordered proposals must never share a score cache entry")
	assert(team.EvaluationRequests == team.Evaluations + team.CacheHits)
end)

test("Phase 4 benchmark memo stores failed probes and never replaces them with zero", function()
	for _, throws in ipairs({ false, true }) do
		local cfg, ctx = fixture({ { Id = "A", Name = "A", TestContribution = 10 },
			{ Id = "B", Name = "B", TestContribution = 9 }, { Id = "C", Name = "C", TestContribution = 8 } }, { "A", "C" }, 2)
		local failures = 0
		ctx.ScoreTeam = function(ids)
			local key = table.concat(ids, ",")
			if key == "A,B" then failures += 1 if throws then error("Synthetic unavailable native projection") end return nil end
			return key == "A,C" and 10 or 9
		end
		local team = Policy.Team(cfg, ctx)
		assert(failures == 1 and team.CacheHits >= 1 and team.ProjectionFailures == 1)
		assert(team.BaselineIncomplete and team.SearchStatus == "UNKNOWN_OWNED_INPUTS" and not team.SearchComplete and not team.SearchBoundReached)
		assert(team.Seed.Status == "NATIVE_PROJECTION_FAILED" and team.ProjectedScore == 10)
	end
end)

test("Phase 4 benchmark actual uncached budget denial differs from complete search at its exact limit", function()
	local cfg, ctx = fixture({ { Id = "weak", Name = "Weak", TestContribution = 1 },
		{ Id = "best", Name = "Best", TestContribution = 10 } }, { "weak" }, 1, 1)
	local team = Policy.Team(cfg, ctx)
	assert(team.Evaluations == 1 and team.BudgetDenied == 1 and team.SearchBoundReached and team.SearchStatus == "BUDGET_CUTOFF")
	assert(team.BaselineIncomplete and not team.SearchComplete)
	local singleCfg, single = fixture({ { Id = "only", Name = "Only", TestContribution = 1 } }, { "only" }, 1, 1)
	team = Policy.Team(singleCfg, single)
	assert(team.Evaluations == 1 and team.SearchComplete and not team.SearchBoundReached and team.BudgetDenied == 0)
end)

test("Phase 4 benchmark seed preserves protected variants quantities and fixed Super copies", function()
	local cfg, ctx, raw = fixture({ { Id = "fixed", Name = "SameName", Shiny = true, XL = true, XP = 100, TestContribution = 3 },
		{ Id = "super", Name = "Super", Super = true, TestContribution = 2 },
		{ Id = "best", Name = "SameName", Amount = 2, Mythic = true, TestContribution = 20 },
		{ Id = "forbidden", Name = "Forbidden", TestContribution = 100 } }, { "fixed", "super" }, 4)
	cfg.PET_SETTINGS.PROTECTED_PET_IDS = { "forbidden" }
	local team = Policy.Team(cfg, ctx) local counts = Policy.Counts(team.ProposedIds)
	assert(counts.fixed == 1 and counts.super == 1 and counts.best == 2 and not counts.forbidden and team.SearchComplete)
	assert(#raw.Teams[1].Pets == 2 and team.ProposedPets[1].Variant:find("Shiny", 1, true))
	ctx.Inventory.ById.super.Amount = 2 team = Policy.Team(cfg, ctx)
	assert(team.UnsupportedOwnedSupers == 1 and team.BaselineIncomplete and team.BaselineStatus == "UNSUPPORTED_OWNED_SUPER_CONFIGURATION")
	ctx.Pets.SameName = nil team = Policy.Team(cfg, ctx)
	assert(team.UnsupportedOwnedRecords == 2 and team.BaselineIncomplete and not team.SearchComplete)
end)

test("Phase 4 benchmark known candidate stat failures remain unknown with the efficient seed", function()
	local cfg, ctx = fixture({ { Id = "weak", Name = "Weak", TestContribution = 1 },
		{ Id = "unknown", Name = "Unknown", TestContribution = 50 } }, { "weak" }, 1)
	ctx.PetScore = function(pet) if pet.Id == "unknown" then return nil end return 2 end
	local team = Policy.Team(cfg, ctx)
	assert(team.OwnedCandidateFailures == 1 and team.BaselineIncomplete and not team.SearchBoundReached and team.SearchStatus == "UNKNOWN_OWNED_INPUTS")
	assert(team.ProjectedScore == team.CurrentScore and not team.SearchComplete)
end)

print("[OC TEST] " .. tostring(tests - before) .. " Phase 4 benchmark efficiency safeguards passed (offline)")
end

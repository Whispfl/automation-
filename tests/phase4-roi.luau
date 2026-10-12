do
-- Synthetic projections verify selection safeguards; no live player or server RNG.
local before = tests
local Policy = requireOC("PetPolicy")
local function fixture(mode)
	local cfg = config({ PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, OBJECTIVE_CURRENCY = "Coins", AUTO_HATCH = true },
		HATCH_SETTINGS = { EGG_SELECTION_MODE = mode or "AUTO", SELECTED_EGGS = {}, ALLOWED_CURRENCIES = { "Coins" },
			MAXIMUM_EGG_COST = 100, MAXIMUM_SESSION_COST = 100, MAXIMUM_SESSION_HATCHES = 2, MAXIMUM_BATCH_HATCHES = 2 },
		RESOURCE_SETTINGS = { COIN_RESERVE = 50 } })
	local raw = { Pets = { { Id = "weak", Name = "Weak", XP = 0 }, { Id = "strong", Name = "Strong", Amount = 2, XP = 0 } },
		Teams = { { Pets = { "weak" } } }, TeamEquipped = 1 }
	local ranks = { Weak = 2, Strong = 5, New = 9, Better = 13 }
	local ctx = { Currency = "Coins", Inventory = Policy.Inventory(raw), Pets = {}, MaxEquipped = 2, MaxHatches = 3,
		StorageCapacity = 100, StorageUsed = 3, DigitalStorage = false, InventoryFull = false, AutoDeleteKnown = true,
		AutoDeleteActive = false, StorageUnit = "PET_QUANTITY", Eggs = {} }
	for name in pairs(ranks) do ctx.Pets[name] = { Rarity = "Common" } end
	ctx.ScoreTeam = function(ids)
		local value = 1
		for _, id in ipairs(ids) do local pet = ctx.Inventory.ById[id] if not pet then return nil end value += ranks[pet.Name] - 1 end
		return value
	end
	ctx.PetScore = function(pet) return ranks[pet.Name] end
	ctx.ScoreNewPet = function(name, ids)
		ctx.LastProjectionIds = table.clone(ids)
		local best = ctx.ScoreTeam(ids)
		for slot = 1, #ids + (#ids < ctx.MaxEquipped and 1 or 0) do
			local old = ctx.Inventory.ById[ids[slot]]
			if old and (old.Super or Policy.Protected(cfg, old, ctx.Pets[old.Name])) then continue end
			best = math.max(best, ctx.ScoreTeam(ids) - (old and ranks[old.Name] - 1 or 0) + ranks[name] - 1)
		end
		return best
	end
	local snapshot = { Revision = 3, Balances = { Coins = 1000, Gems = 1000 }, ProgressionGraph = {
		Worlds = { { Unlocked = true }, { Unlocked = false, Cost = { Type = "Currency", Currency = "Coins", Amount = 100 } } } } }
	local function egg(name, price, pet, chance)
		return { Name = name or "Useful Egg", Loaded = true, Accessible = true, AccessStatus = "ACCESSIBLE", InRange = false,
			World = "The Overworld", Island = "The Void", Cost = { Type = "Currency", Currency = "Coins", Amount = price or 10 },
			Duration = 2, Luck = 2, Opened = true, Pool = {
				{ Chance = 1, Item = { Type = "Pet", Name = "Weak" } },
				{ Chance = chance or 3, Item = { Type = "Pet", Name = pet or "New" } } } }
	end
	ctx.Eggs = { egg() }
	return cfg, snapshot, ctx, raw, ranks, egg
end

test("Phase 4 hatch ROI uses feasible owned quantities instead of manually weak equipped team", function()
	local cfg, snapshot, ctx, raw = fixture()
	local report = Policy.Analyze(cfg, snapshot, ctx) local egg = report.Eggs[1]
	assert(report.Team.CurrentScore == 2 and report.Team.ProjectedScore == 9)
	assert(egg.BaselineScore == 9 and egg.ExpectedIncrement == 3 and egg.ClientImprovementProbability == 0.75)
	assert(Policy.SameTeam(egg.BaselineIds, { "strong", "strong" }) and Policy.SameTeam(ctx.LastProjectionIds, egg.BaselineIds))
	assert(raw.Teams[1].Pets[1] == "weak" and #raw.Pets == 2)
	raw.Teams[1].Pets = { "strong", "strong" } ctx.Inventory = Policy.Inventory(raw)
	local equipped = Policy.Analyze(cfg, snapshot, ctx).Eggs[1]
	assert(equipped.CurrentEquippedScore == 9 and equipped.BaselineScore == egg.BaselineScore and equipped.ExpectedIncrement == egg.ExpectedIncrement)
	assert(egg.BaselineEvidence:find("global optimum UNKNOWN", 1, true))
end)

test("Phase 4 owned benchmark never invents additional stack units", function()
	local cfg, snapshot, ctx, raw = fixture()
	raw.Pets[2].Amount = 1 ctx.Inventory = Policy.Inventory(raw)
	local report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.Team.ProjectedScore == 6 and Policy.Counts(report.Team.ProposedIds).strong == 1)
	assert(report.Eggs[1].BaselineScore == 6 and report.Eggs[1].ExpectedIncrement == 5.25)
end)

test("Phase 4 truncated or failed owned projections retain advisory uncertainty and block paid hatches", function()
	local cfg, snapshot, ctx = fixture()
	cfg.PET_SETTINGS.MAXIMUM_TEAM_EVALUATIONS = 1
	local report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.Team.SearchBoundReached and report.Eggs[1].BaselineIncomplete and report.RecommendedEgg and not report.ActionEgg)
	assert(Policy.EggBlocker(report.Eggs[1]):find("INCOMPLETE_OWNED_TEAM_BASELINE", 1, true))
	assert(report.SelectionExplanation:find("advisory recommendation", 1, true))
	cfg.PET_SETTINGS.MAXIMUM_TEAM_EVALUATIONS = 300
	ctx.PetScore = function(pet) if pet.Name == "Strong" then return nil end return 2 end
	report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.Team.OwnedCandidateFailures == 1 and report.Eggs[1].BaselineProjectionFailures == 1 and not report.ActionEgg)
	ctx.PetScore = function(pet) return pet.Name == "Strong" and 5 or 2 end
	local original = ctx.ScoreTeam
	ctx.ScoreTeam = function(ids) if Policy.Counts(ids).strong then return nil end return original(ids) end
	-- A single-outcome score is deliberately available; it cannot excuse missing
	-- evidence for stronger owned alternatives.
	ctx.ScoreNewPet = function() return 20 end
	report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.Team.ProjectionFailures > 0 and report.Eggs[1].BaselineIncomplete and not report.ActionEgg)
end)

test("Phase 4 saturated owned duplicates yield no useful egg and never choose a random fallback", function()
	local cfg, snapshot, ctx, raw, _, egg = fixture()
	table.insert(raw.Pets, { Id = "new", Name = "New", Amount = 2, XP = 0 }) ctx.Inventory = Policy.Inventory(raw)
	ctx.Eggs = { egg("Cheapest Egg", 1), egg("Named Event Egg", 50) }
	local report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.Team.ProjectedScore == 17 and not report.ActionEgg and not report.RecommendedEgg)
	for _, candidate in ipairs(report.Eggs) do assert(candidate.ExpectedIncrement == 0 and Policy.EggBlocker(candidate):find("NO_USEFUL_IMPROVEMENT", 1, true)) end
	assert(report.SelectionExplanation:find("NO_USEFUL_IMPROVEMENT", 1, true))
end)

test("Phase 4 benchmark retains protected equipped units and never adds unverified Super copies", function()
	local cfg, snapshot, ctx, raw = fixture()
	for _, flag in ipairs({ "Locked", "Shiny", "Mythic", "XL", "Super", "ID" }) do
		for _, key in ipairs({ "Locked", "Shiny", "Mythic", "XL", "Super" }) do raw.Pets[1][key] = flag == key end
		cfg.PET_SETTINGS.PROTECTED_PET_IDS = flag == "ID" and { "weak" } or {}
		ctx.Inventory = Policy.Inventory(raw)
		local report = Policy.Analyze(cfg, snapshot, ctx)
		assert(Policy.Counts(report.Team.ProposedIds).weak == 1 and report.Team.ProjectedScore == 6)
		assert(report.Eggs[1].BaselineScore == 6 and report.Eggs[1].ExpectedIncrement == 3)
	end
	raw.Pets[1].Super = true raw.Pets[2].Super = true cfg.PET_SETTINGS.PROTECTED_PET_IDS = {}
	ctx.Inventory = Policy.Inventory(raw) local team = Policy.Team(cfg, ctx)
	assert(#team.ProposedIds == 1 and team.ProposedIds[1] == "weak")
end)

test("Phase 4 AUTO ranks useful native gain per currency cost then single-draw time", function()
	local cfg, snapshot, ctx, _, _, egg = fixture()
	ctx.Eggs = { egg("Nostalgia Egg", 50), egg("Better Egg", 30, "Better"), egg("Useful Egg", 10) }
	local report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.ActionEgg.Name == "Useful Egg" and report.RecommendedEgg.Name == "Useful Egg")
	assert(report.ActionEgg.ExpectedIncrementPerCost == 0.3 and not report.ActionEgg.InRange)
	assert(report.SelectionExplanation:find("AUTO selected Useful Egg", 1, true))
	ctx.Eggs = { egg("Slow Egg", 10), egg("Fast Egg", 10) } ctx.Eggs[1].Duration = 10
	assert(Policy.Analyze(cfg, snapshot, ctx).ActionEgg.Name == "Fast Egg")
end)

test("Phase 4 MANUAL keeps selection explicit and never spends on a better unselected egg", function()
	local cfg, snapshot, ctx, _, _, egg = fixture("MANUAL")
	cfg.HATCH_SETTINGS.SELECTED_EGGS = { "Owner Egg" }
	ctx.Eggs = { egg("Better Egg", 1, "Better"), egg("Owner Egg", 10) }
	local report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.ActionEgg.Name == "Owner Egg" and report.RecommendedEgg.Name == "Owner Egg")
	for _, candidate in ipairs(report.Eggs) do if candidate.Name == "Better Egg" then assert(candidate.SpendingStatus == "NOT_SELECTED") end end
	ctx.Eggs[2].Accessible = false ctx.Eggs[2].AccessStatus = "LOCKED_OR_UNKNOWN_UNLOCK"
	assert(not Policy.Analyze(cfg, snapshot, ctx).ActionEgg)
	cfg.HATCH_SETTINGS.SELECTED_EGGS = {} assert(not Policy.Analyze(cfg, snapshot, ctx).ActionEgg)
end)

test("Phase 4 unloaded locked unknown and zero-useful models cannot become AUTO spending candidates", function()
	local cfg, snapshot, ctx, _, _, egg = fixture()
	local unloaded, locked, unknown, useless = egg("Missing Egg", 1), egg("Locked Egg", 1), egg("Unknown Egg", 1), egg("Useless Egg", 1, "Weak")
	unloaded.Loaded = false locked.Accessible = false locked.AccessStatus = "LOCKED_OR_UNKNOWN_UNLOCK" unknown.Pool[2].Chance = nil
	ctx.Eggs = { unloaded, locked, unknown, useless }
	local report = Policy.Analyze(cfg, snapshot, ctx) assert(not report.ActionEgg and not report.RecommendedEgg)
	for _, candidate in ipairs(report.Eggs) do assert(Policy.EggBlocker(candidate) ~= nil) end
end)

test("Phase 4 protected progression reserve blocks hatch selection and cannot be overridden by ROI", function()
	local cfg, snapshot, ctx = fixture()
	snapshot.Balances.Coins = 159
	local report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.Eggs[1].FundingStatus == "PROTECTED_RESERVE" and report.Eggs[1].Reserve == 150 and not report.ActionEgg)
	snapshot.ProgressionGraph.Worlds[2].Cost.Amount = nil
	report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.Eggs[1].FundingStatus == "UNKNOWN_RESERVE" and not report.ActionEgg)
	snapshot.ProgressionGraph.Worlds[2].Cost.Amount = 100 snapshot.ProgressionGraph.Worlds[2].Cost.Currency = nil
	assert(Policy.Analyze(cfg, snapshot, ctx).Eggs[1].FundingStatus == "UNKNOWN_RESERVE")
end)

test("Phase 4 native capacity duration digital units and authorized ceilings affect eligibility", function()
	local cfg, snapshot, ctx = fixture()
	ctx.StorageUsed = 100 assert(not Policy.Analyze(cfg, snapshot, ctx).ActionEgg) ctx.StorageUsed = 3
	ctx.DigitalStorage, ctx.StorageUsed, ctx.StorageCapacity = true, 999999, 1000000
	local report = Policy.Analyze(cfg, snapshot, ctx) assert(report.ActionEgg.EffectiveBatchCapacity == 1)
	ctx.MaxHatches = nil assert(not Policy.Analyze(cfg, snapshot, ctx).ActionEgg) ctx.MaxHatches = 3
	ctx.Eggs[1].Duration = nil assert(not Policy.Analyze(cfg, snapshot, ctx).ActionEgg) ctx.Eggs[1].Duration = 2
	ctx.AutoDeleteActive = true assert(not Policy.Analyze(cfg, snapshot, ctx).ActionEgg) ctx.AutoDeleteActive = false
	cfg.HATCH_SETTINGS.MAXIMUM_EGG_COST = 9 assert(not Policy.Analyze(cfg, snapshot, ctx).ActionEgg)
end)

test("Phase 4 odds remain conditional and first-useful batch time does not divide by b times q", function()
	local cfg, snapshot, ctx = fixture()
	local r = Policy.Analyze(cfg, snapshot, ctx).Eggs[1]
	assert(r.ExpectedIncrementPerSecond == 0.6 and r.BatchExpectedIncrement == "UNKNOWN")
	assert(r.EffectiveBatchCapacity == 2 and r.ClientFirstUsefulBatchProbability == 0.9375)
	assert(math.abs(r.EstimatedSecondsToUsefulBasePet - 5 / 0.9375) < 1e-9)
	assert(r.EffectiveServerOdds == "UNKNOWN" and r.VariantOdds == "UNKNOWN" and r.PityGuarantee == "UNKNOWN")
	assert(r.TotalTimeSeconds == "UNKNOWN" and r.TravelTimeSeconds == "UNKNOWN" and r.VerificationTimeSeconds == "UNKNOWN")
	ctx.Eggs[1].Pool[2].Chance = math.huge assert(Policy.Analyze(cfg, snapshot, ctx).Eggs[1].Status == "UNKNOWN")
end)

test("Phase 4 AUTO single hatch preserves isolated action guards without a mandatory egg name", function()
	local cfg = config({ PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, OBJECTIVE_CURRENCY = "Coins", AUTO_HATCH = true },
		HATCH_SETTINGS = { EGG_SELECTION_MODE = "AUTO", SELECTED_EGGS = {}, HATCH_ONE_EGG_ONCE = true,
			MAXIMUM_EGG_COST = 100, MAXIMUM_SESSION_COST = 100, MAXIMUM_SESSION_HATCHES = 1, MAXIMUM_BATCH_HATCHES = 1, ENABLE_BACKGROUND_PICKUPS = false },
		WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false, AUTO_UNLOCK_WORLDS = false, AUTO_TRAVEL_FOR_PROGRESSION = false, AUTO_FARM_UNLOCK_REQUIREMENTS = false },
		FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false },
		ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
		PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false, STATIONARY_ISOLATED_TEST = false },
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
		UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false, ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false },
		EGG_TRAVEL_SETTINGS = { ENABLE_SELECTED_EGG_TRAVEL = true, ENABLE_DIRECT_POSITIONING = true, ENABLE_NATIVE_ISLAND_TRAVEL = true } })
	assert(Policy.HatchIsolation(cfg) == nil)
	cfg.HATCH_SETTINGS.EGG_SELECTION_MODE = "MANUAL" assert(Policy.HatchIsolation(cfg) ~= nil)
	cfg.HATCH_SETTINGS.SELECTED_EGGS = { "Owner Egg" } assert(Policy.HatchIsolation(cfg) == nil)
	cfg.PET_SETTINGS.AUTO_EQUIP = true assert(Policy.HatchIsolation(cfg) ~= nil)
	cfg.PET_SETTINGS.AUTO_EQUIP = false cfg.HATCH_SETTINGS.ENABLE_BACKGROUND_PICKUPS = true assert(Policy.HatchIsolation(cfg) ~= nil)
end)

test("Unknown owned definitions cannot make known eggs falsely profitable", function()
	local cfg, snapshot, ctx = fixture()
	ctx.Pets.Strong = nil
	local report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.Team.BaselineIncomplete and not report.ActionEgg)
	assert(Policy.EggBlocker(report.Eggs[1]):find("INCOMPLETE_OWNED_TEAM_BASELINE"))
end)

test("Unequipped owned Super quantity requires supported baseline before paid hatch", function()
	local cfg, snapshot, ctx = fixture()
	local pet = ctx.Inventory.ById.strong
	pet.Super = true
	local report = Policy.Analyze(cfg, snapshot, ctx)
	assert(report.Team.UnsupportedOwnedSupers == 2 and not report.ActionEgg)
	assert(Policy.EggBlocker(report.Eggs[1]):find("UNSUPPORTED_OWNED_SUPER_CONFIGURATION"))
end)

print("[OC TEST] " .. tostring(tests - before) .. " Phase 4 ROI/selection safeguards passed (offline)")
end

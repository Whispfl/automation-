do
-- Detached synthetic native contracts. These tests establish serial OC behavior,
-- not accepted game actions, server odds or live earning-rate improvement.
local before = tests
local Policy, Manager = requireOC("PetPolicy"), requireOC("PetManager")
local token = { CheckCancelled = function() return false end }
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copy(entry) end
	return result
end

local function fixture(equip)
	local s = stationaryFixture({ PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = true,
		AUTO_EQUIP = equip == true, OBJECTIVE_CURRENCY = "Coins" },
		HATCH_SETTINGS = { SELECTED_EGGS = { "Test Egg" }, MAXIMUM_EGG_COST = 10, MAXIMUM_SESSION_COST = 30,
			MAXIMUM_BATCH_HATCHES = 1, MAXIMUM_SESSION_HATCHES = 3 },
		PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = false },
		FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false }, RESOURCE_SETTINGS = { COIN_RESERVE = 50 } })
	s.Profile.Coins = 10000
	s.Profile.Pets = { { Id = "weak", Name = "Weak", XP = 0 }, { Id = "strong", Name = "Strong", XP = 0, Amount = 2 } }
	s.Profile.Teams, s.Profile.TeamEquipped = { { Pets = { "strong", "strong" } } }, 1
	s.Profile.AutoDelete, s.Profile.EggsOpened = {}, { ["Test Egg"] = 0 }
	s.Ranks, s.Capacity, s.Commands, s.Hatching, s.NativeAuto = { Weak = 2, Strong = 5, New = 9 }, 2, {}, false, nil
	local d = s.Dependencies
	d.Pets = { Weak = { Rarity = "Common" }, Strong = { Rarity = "Rare" }, New = { Rarity = "Epic" } }
	d.Worlds = { ["The Overworld"] = { Order = 1, Islands = {} } }
	d.Eggs = { ["Test Egg"] = { World = "The Overworld", Island = "The Void", Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } } }
	d.HatchPresentation, d.Time = { IsHatching = function() return s.Hatching end }, { now = function() return os.clock() end }
	d.WorldUtil = { GetPlayerWorld = function() return "The Overworld" end }
	d.ProximityPrompt = { Visible = 0 }
	d.StatsUtil.GetEggCost = function() return { Type = "Currency", Currency = "Coins", Amount = 10 } end
	d.StatsUtil.HasDigitalStorage = function() return false end
	d.StatsUtil.GetMaxPetStorage = function() return 100 end
	d.StatsUtil.GetUsedPetStorage = function(_, facts) local n = 0 for _, p in ipairs(facts.Pets) do n += p.Amount or 1 end return n end
	d.StatsUtil.GetMaxEggHatches = function() return 1 end
	d.StatsUtil.IsInventoryFull = function() return false end
	d.Remote = { FireServer = function(_, command, id, count) table.insert(s.Commands, { Command = command, Id = id, Count = count }) end }
	local auto = { IsA = function(_, kind) return kind == "BindableFunction" end, Invoke = function()
		s.AutoCalls = (s.AutoCalls or 0) + 1
		if s.OnAutoGuard then s.OnAutoGuard(s.AutoCalls) end
		return s.NativeAuto
	end }
	s.Controller.Reader.Player = { Name = "SyntheticPhase4Owner", UserId = 123,
		FindFirstChild = function() return { FindFirstChild = function() return { FindFirstChild = function() return auto end } end } end,
		GetAttribute = function() return nil end }
	s.Controller.Reader.GetSnapshot = function() return { Ready = true, Revision = 1, Balances = { Coins = s.Profile.Coins }, AvailableProgression = {} } end
	s.Controller.Reader.Config = s.Controller.Config
	s.EggPart = { Position = s.Root.Position + Vector3.new(2,0,0), IsA = function(_, kind) return kind == "BasePart" end }
	s.Egg = { Name = "Test Egg", Parent = true, IsDescendantOf = function() return true end,
		FindFirstChild = function(_, name) return name == "Root" and s.EggPart or {} end,
		GetAttribute = function(_, name) if name == "Unlocked" then return true end end }
	s.Controller.Farming, s.Controller.Knowledge = s.Coordinator, s.Coordinator.Knowledge
	registerNativeEggFixture(s.Controller.Knowledge, s.Egg, s)
	s.Controller.Knowledge.EggModels = function() return { s.Egg } end
	s.Manager = Manager.new(s.Controller) s.Controller.Pets = s.Manager
	function s.Manager:Fresh()
		local snap = s.Controller.Reader:GetSnapshot()
		snap.ProgressionGraph = { Worlds = { { Name = "The Overworld", Unlocked = true } } }
		local facts = copy(s.Profile)
		local ctx = { Currency = "Coins", Inventory = Policy.Inventory(facts), AccountFacts = facts, Pets = d.Pets,
			MaxEquipped = s.Capacity, MaxHatches = 1, StorageUsed = d.StatsUtil:GetUsedPetStorage(facts), StorageCapacity = 100,
			DigitalStorage = false, InventoryFull = false, AutoDeleteKnown = true, AutoDeleteActive = false,
			StorageUnit = "PET_QUANTITY", MinigameParadise = Policy.WorldAccess(facts, "Minigame Paradise") }
		ctx.ScoreTeam = function(ids, pets)
			local by = {} for _, pet in ipairs(pets or facts.Pets) do by[pet.Id] = pet end
			local total = 1
			for _, id in ipairs(ids) do
				local pet = by[id] if not pet then return nil end
				total += s.Ranks[pet.Name] - 1 + (pet.Shiny and 20 or 0) + (pet.XP or 0)
			end
			return total
		end
		ctx.PetStats = function(pet) return { Coins = s.Ranks[pet.Name] + (pet.Shiny and 20 or 0) + (pet.XP or 0) } end
		ctx.PetScore = function(pet) return ctx.PetStats(pet).Coins end
		ctx.ScoreNewPet = function(name, ids)
			local pets = copy(facts.Pets) table.insert(pets, { Id = "synthetic", Name = name })
			local best = ctx.ScoreTeam(ids)
			for slot = 1, #ids + (#ids < s.Capacity and 1 or 0) do
				local old = ctx.Inventory.ById[ids[slot]]
				if old and Policy.Protected(s.Controller.Config, old, d.Pets[old.Name]) then continue end
				local after = table.clone(ids) after[slot] = "synthetic" best = math.max(best, ctx.ScoreTeam(after, pets))
			end
			return best
		end
		ctx.Eggs = { { Name = "Test Egg", Model = s.Egg, World = "The Overworld", Island = "The Void", InRange = true,
			NativeRangeEligible = true, Loaded = true, Accessible = true, AccessStatus = "ACCESSIBLE", Opened = true, Unlocked = true,
			Cost = d.StatsUtil:GetEggCost(), Duration = 2, Range = 16, Distance = 2,
			Pool = { { Chance = 1, Item = { Type = "Pet", Name = "Weak" } }, { Chance = 3, Item = { Type = "Pet", Name = "New" } } } } }
		ctx.EggAvailability = ctx.Eggs
		return snap, ctx
	end
	function s:Decision() local snap, ctx = self.Manager:Fresh() return self.Controller.Brain:PlanPets(self.Controller.Brain:AnalyzePets(snap,ctx),ctx,self.Manager:State()) end
	function s:Dispatch(decision)
		local intent = decision or self:Decision()
		if intent.Kind == "WAIT" then return false, intent.Reason end
		return self.Coordinator.Mechanics:PetAction(self.Manager, intent, token)
	end
	function s:Receive(pet) self.Profile.Pets[#self.Profile.Pets+1] = pet self.Profile.EggsOpened["Test Egg"] += 1 self.Profile.Coins -= 10 self.Manager:Observe() end
	return s
end

test("Phase4 hatch usefulness freezes the stronger unused owned benchmark before dispatch", function()
	simulated(function()
		local s = fixture(false) s.Profile.Teams[1].Pets = { "weak" }
		assert(s:Dispatch())
		local baseline = s.Manager.Hatch.Pending.UsefulnessBaseline
		assert(baseline.Score == 9 and Policy.SameTeam(baseline.Ids, { "strong", "strong" }))
		s:Receive({ Id = "received", Name = "Weak" })
		local r = s.Manager.Hatch.LastResult
		assert(r.UsefulnessBaselineScore == 9 and r.Changes[1].ActualIncrement == 0 and r.UsefulReceivedCopies == 0)
		assert(#s.Commands == 1 and s.Manager.EquipCommands == 0) s:Close()
	end)
end)

test("Phase4 received variants use actual native records with unrelated later inventory excluded", function()
	simulated(function()
		local s = fixture(false) assert(s:Dispatch())
		s.Profile.Pets[3] = { Id = "external", Name = "New", Amount = 5 }
		s:Receive({ Id = "received", Name = "Weak", Shiny = true, XP = 3 })
		local r = s.Manager.Hatch.LastResult local received
		for _, change in ipairs(r.Changes) do if change.Id == "received" then received = change end end
		assert(received and received.Variant == "Shiny" and received.ActualIncrement == 20)
		assert(r.UsefulnessBaselineScore == 9 and #r.UsefulnessBaselineIds == 2 and #s.Commands == 1) s:Close()
	end)
end)

test("Phase4 extra copy of an already best owned stack has zero marginal hatch usefulness", function()
	simulated(function()
		local s = fixture(false) s.Profile.Pets[3] = { Id = "best", Name = "New", Amount = 2 }
		s.Profile.Teams[1].Pets = { "best", "best" }
		-- Exercise the received-result ledger independently of new dispatch policy.
		local snap, ctx = s.Manager:Fresh() local team = Policy.Team(s.Controller.Config,ctx)
		local baseline = { Ids = team.ProposedIds, Score = team.ProjectedScore, Currency = "Coins", MaxEquipped = 2,
			Pets = copy(ctx.AccountFacts.Pets), ById = copy(ctx.Inventory.ById), Definitions = ctx.Pets,
			Config = { PET_SETTINGS = copy(s.Controller.Config.PET_SETTINGS) }, ScoreTeam = ctx.ScoreTeam }
		s.Manager.Hatch.Pending = { Before = copy(ctx.Inventory.ById), Pool = { New = true }, Count = 1, Counter = 0,
			EggName = "Test Egg", Currency = "Coins", BeforeBalance = 10000, BeforeBalances = { Coins = 10000 },
			TeamBefore = table.clone(ctx.Inventory.Team), TeamIndex = 1, Deadline = 15, UsefulnessBaseline = baseline }
		s.Profile.Pets[3].Amount = 3 s.Profile.EggsOpened["Test Egg"] = 1 s.Manager:Observe()
		local change = s.Manager.Hatch.LastResult.Changes[1]
		assert(change.ExistingStack and change.Quantity == 1 and change.ActualIncrement == 0 and change.Usefulness == "NO_CURRENT_TEAM_IMPROVEMENT") s:Close()
	end)
end)

test("Phase4 useful hatch equipment waits for presentation and verifies each replacement command", function()
	simulated(function()
		local s = fixture(true) assert(s:Dispatch()) s:Receive({ Id = "received", Name = "New" })
		assert(s.Manager.Hatch.LastResult.UsefulReceivedCopies == 1 and s:Decision().Kind == "TEAM")
		s.Hatching = true assert(not s:Dispatch() and #s.Commands == 1)
		s.Hatching = false assert(s:Dispatch() and s.Commands[2].Command == "UnequipPet")
		assert(not s:Dispatch() and #s.Commands == 2)
		table.remove(s.Profile.Teams[1].Pets,1) s.Manager:Observe()
		assert(s:Decision().Kind == "TEAM_ADD" and s:Dispatch() and s.Commands[3].Command == "EquipPet")
		table.insert(s.Profile.Teams[1].Pets,"received") s.Manager:Observe()
		assert(not s.Manager.PendingEquip and not s.Manager.Transaction and s.Manager.LastEquipment.Status == "EQUIPPED_IDS_OBSERVED")
		assert(Policy.SameTeam(s.Profile.Teams[1].Pets,{"strong","received"})) s:Close()
	end)
end)

test("Phase4 equipment OFF still permits separately bounded serial confirmed hatch continuation", function()
	simulated(function(clock)
		local s = fixture(false) assert(s:Dispatch())
		assert(not s:Dispatch() and #s.Commands == 1)
		s:Receive({ Id = "received", Name = "Weak" })
		assert(s.Manager.Hatch.VerifiedHatches == 1 and s.Manager.Hatch.LastResult.Continuation == "FRESH_BOUNDED_HATCH_REPLAN_REQUIRED")
		clock.Time = 6 assert(s:Dispatch() and #s.Commands == 2 and s.Manager.Hatch.RequestCost == 20)
		assert(s.Manager.EquipCommands == 0 and not s:Dispatch()) s:Close()
	end)
end)

test("Phase4 uncertain counter overlap or external team change blocks all continuation", function()
	simulated(function()
		for _, mode in ipairs({ "counter", "team" }) do
			local s = fixture(true) assert(s:Dispatch())
			if mode == "counter" then s.Profile.EggsOpened["Test Egg"] = 1 else s.Profile.Teams[1].Pets = { "weak" } end
			s:Receive({ Id = "received", Name = "New" })
			assert(s.Manager.Hatch.LastResult.Status == "INVENTORY_GAIN_OBSERVED" and s.Manager.Fault and s.Manager.Hatch.LastResult.Continuation == "BLOCKED_UNCERTAIN")
			assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.EquipCommands == 0) s:Close()
		end
	end)
end)

test("Phase4 final hatch dispatch requires the separately verified selected arrival lease", function()
	simulated(function()
		local s = fixture(false) s.Controller.Config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL = true
		local calls = 0 s.Controller.EggTravel = { HatchEligible = function() calls += 1 return false,"Synthetic manual departure invalidates arrival lease" end }
		local sent, reason = s:Dispatch()
		assert(not sent and reason:find("manual departure") and calls == 1 and #s.Commands == 0 and s.Manager.Hatch.RequestCost == 0) s:Close()
	end)
end)

test("Phase4 account replacement cannot confirm another account or enable equipment continuation", function()
	simulated(function(clock)
		local s = fixture(true) assert(s:Dispatch()) s.Controller.Reader.Player.UserId = 456
		s:Receive({ Id = "received", Name = "New" })
		assert(s.Manager.Fault and s.Manager.Hatch.Pending and s.Manager.Hatch.VerifiedHatches == 0)
		clock.Time = 16 s.Manager:Observe()
		assert(s.Manager.Hatch.LastResult.Status == "UNCONFIRMED" and not s:Dispatch() and #s.Commands == 1) s:Close()
	end)
end)

test("Phase4 final forced nearest scan observes a newly loaded unlocked egg before any paid request", function()
	simulated(function()
		local s = fixture(false)
		local closerRoot = { Position = s.Root.Position + Vector3.new(1, 0, 0), IsA = function(_, kind) return kind == "BasePart" end }
		local closer = { Name = "Closer Native Egg", Parent = true, IsDescendantOf = function() return true end,
			FindFirstChild = function(_, name) return name == "Root" and closerRoot or nil end,
			GetAttribute = function(_, name) if name == "Unlocked" then return true end end }
		s.Dependencies.Eggs[closer.Name] = { World = "The Overworld", Island = "The Void" }
		registerNativeEggFixture(s.Controller.Knowledge, closer)
		local forced = 0
		s.Controller.Knowledge.EggModels = function(_, force)
			if force then forced += 1 return { s.Egg, closer } end
			return { s.Egg }
		end
		local sent, reason = s:Dispatch()
		assert(not sent and reason:find("nearest selection", 1, true) and forced >= 1,
			string.format("Expected a fresh native nearest-range rejection; sent=%s reason=%s scans=%d", tostring(sent), tostring(reason), forced))
		assert(#s.Commands == 0 and s.Manager.Hatch.RequestedHatches == 0 and s.Manager.Hatch.RequestCost == 0)
		s:Close()
	end)
end)

test("Phase4 AUTO currency changes inside the last native guard block hatch and equipment dispatch", function()
	simulated(function()
		for _, action in ipairs({ "HATCH", "TEAM" }) do
			local s = fixture(action == "TEAM")
			if action == "TEAM" then assert(s:Dispatch()) s:Receive({ Id = "received", Name = "New" }) end
			s.Controller.Config.PET_SETTINGS.OBJECTIVE_CURRENCY = "AUTO"
			s.Controller.Plan = { Objective = { Metadata = { Cost = { Currency = "Coins" } } } }
			s.AutoCalls = 0
			s.OnAutoGuard = function(call)
				if call == 2 then s.Controller.Plan.Objective.Metadata.Cost.Currency = "Gems" end
			end
			local beforeCommands, beforeCost = #s.Commands, s.Manager.Hatch.RequestCost
			local sent, reason = s:Dispatch()
			assert(not sent and s.AutoCalls == 2 and reason:find("changed", 1, true))
			assert(#s.Commands == beforeCommands and s.Manager.Hatch.RequestCost == beforeCost and s.Manager.EquipCommands == 0)
			s:Close()
		end
	end)
end)

print("[OC TEST] Phase4 received hatch / serial equipment integration: " .. tostring(tests-before) .. " cases passed; owner gameplay acceptance remains pending.")
end

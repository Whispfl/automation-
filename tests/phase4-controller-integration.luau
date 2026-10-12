do
-- Actual Brain, knowledge, pet/hatch managers, travel and scheduler are exercised
-- together over the existing stationary synthetic account. No live game proof.
local before = tests
local Pets, Travel = requireOC("PetManager"), requireOC("EggTravelManager")
local token = { CheckCancelled = function() return false end }

local function pipelineFixture()
	local s = stationaryFixture({
		PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = true, AUTO_EQUIP = false, OBJECTIVE_CURRENCY = "Coins" },
		HATCH_SETTINGS = { EGG_SELECTION_MODE = "AUTO", SELECTED_EGGS = {}, HATCH_ONE_EGG_ONCE = true,
			MAXIMUM_EGG_COST = 10, MAXIMUM_SESSION_COST = 10, MAXIMUM_SESSION_HATCHES = 1, MAXIMUM_BATCH_HATCHES = 1,
			ENABLE_BACKGROUND_PICKUPS = false, PRESERVE_PROGRESSION_RESERVE = true },
		RESOURCE_SETTINGS = { COIN_RESERVE = 50 },
		FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false },
		PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = false, BULK_COLLECT_PICKUPS = false },
		BUBBLE_SETTINGS = { ENABLE_SIMULTANEOUS_BLOWING = false },
		UPGRADE_SETTINGS = { ENABLE_CAPACITY_UPGRADES = false, ENABLE_FLAVOR_UPGRADES = false },
		EGG_TRAVEL_SETTINGS = { ENABLE_SELECTED_EGG_TRAVEL = true, ENABLE_DIRECT_POSITIONING = false,
			ENABLE_NATIVE_ISLAND_TRAVEL = false, STABILITY_SECONDS = 1, ARRIVAL_TIMEOUT_SECONDS = 3 } })
	s.Profile.Coins = 1000
	s.Profile.Pets = { { Id = "weak", Name = "Weak", XP = 0 }, { Id = "owned", Name = "Owned", XP = 0 } }
	s.Profile.Teams, s.Profile.TeamEquipped = { { Pets = { "weak" } } }, 1
	s.Profile.EggsOpened, s.Profile.AutoDelete = { ["Pipeline Egg"] = 0 }, {}
	s.Commands, s.Hatching, s.Opened = {}, false, true
	s.Character = {}
	s.Root.Parent, s.Root.Size = s.Character, Vector3.new(2, 2, 1)
	s.Humanoid = { HipHeight = 2, MoveDirection = Vector3.new(0, 0, 0) }
	s.Coordinator.Tracker.Root = function() return s.Root, s.Humanoid end
	local d, ranks = s.Dependencies, { Weak = 2, Owned = 5, New = 9 }
	s.Ranks = ranks
	d.Pets = { Weak = { Rarity = "Common" }, Owned = { Rarity = "Rare" }, New = { Rarity = "Epic" } }
	d.Eggs = { ["Pipeline Egg"] = { World = "The Overworld", Island = "The Void", Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } } }
	d.Worlds = { ["The Overworld"] = { Order = 1, Islands = { { Name = "The Void", Height = 9500 } } },
		["Native Next World"] = { Order = 2, Islands = {}, UnlockCost = { Type = "Currency", Currency = "Coins", Amount = 100 } } }
	d.StatsUtil.GetMaxPetsEquipped = function() return 1 end
	d.StatsUtil.GetMaxEggHatches = function() return 1 end
	d.StatsUtil.GetMaxPetStorage = function() return 100 end
	d.StatsUtil.GetUsedPetStorage = function(_, facts) local amount = 0 for _, pet in pairs(facts.Pets) do amount += pet.Amount or 1 end return amount end
	d.StatsUtil.HasDigitalStorage = function() return false end
	d.StatsUtil.IsInventoryFull = function(self, facts) return self:GetUsedPetStorage(facts) >= self:GetMaxPetStorage(facts) end
	d.StatsUtil.GetCurrencyMultiplier = function(_, facts)
		local byId, score = {}, 1
		for _, pet in pairs(facts.Pets) do byId[pet.Id] = pet end
		for _, id in ipairs(facts.Teams[facts.TeamEquipped].Pets) do score += ranks[byId[id].Name] - 1 end
		return score
	end
	d.PetUtil = { GetStats = function(_, pet) return { Coins = ranks[pet.Name], Gems = ranks[pet.Name], Bubbles = ranks[pet.Name] } end }
	d.StatsUtil.GetEggCost = function() return { Type = "Currency", Currency = "Coins", Amount = 10 } end
	d.StatsUtil.GetLuckMultiplier = function() return 1 end
	d.StatsUtil.GetHatchDuration = function() return 2 end
	d.GetEggPool = function() return { { Chance = 1, Item = { Type = "Pet", Name = "New" } } } end
	d.WorldUtil = { GetPlayerWorld = function() return "The Overworld" end }
	d.ProximityPrompt = { Visible = 0 }
	d.Time, d.HatchPresentation = { now = function() return os.clock() end }, { IsHatching = function() return s.Hatching end }
	d.Remote = { FireServer = function(_, command, name, count) table.insert(s.Commands, { Command = command, Name = name, Count = count }) end }
	local auto = { IsA = function(_, kind) return kind == "BindableFunction" end, Invoke = function() return nil end }
	s.Controller.Reader.Player = { Name = "SyntheticPipelineOwner", UserId = 123, Character = s.Character,
		FindFirstChild = function() return { FindFirstChild = function() return { FindFirstChild = function() return auto end } end } end,
		GetAttribute = function() return nil end }
	s.Controller.Reader.Config = s.Controller.Config
	s.Controller.Reader.GetSnapshot = function()
		return { Ready = true, Revision = 1, Balances = { Coins = s.Profile.Coins, Gems = s.Profile.Gems }, AvailableProgression = {} }
	end
	local function part(position)
		return { Parent = true, Position = position, IsA = function(_, kind) return kind == "BasePart" end,
			IsDescendantOf = function(self) return self.Parent ~= nil end }
	end
	s.EggRoot = part(s.Root.Position + Vector3.new(2, 0, 0))
	s.Prompt = part(s.EggRoot.Position)
	s.NativePrompt = { Parent = s.Prompt, Enabled = true, RequiresLineOfSight = false, MaxActivationDistance = 6.5 }
	s.Prompt.FindFirstChildOfClass = function() return s.NativePrompt end
	s.Egg = { Name = "Pipeline Egg", Parent = true, IsDescendantOf = function(self) return self.Parent ~= nil end,
		GetFullName = function() return "Workspace.Worlds.The Overworld.Islands.The Void.Pipeline Egg" end,
		FindFirstChild = function(_, name) if name == "Root" then return s.EggRoot elseif name == "Prompt" then return s.Prompt end return {} end,
		GetAttribute = function(_, name) if name == "Unlocked" then return s.Opened elseif name == "Island" then return "The Void" end end }
	local c = s.Controller
	c.Farming, c.Knowledge = s.Coordinator, s.Coordinator.Knowledge
	c.Knowledge.EggModels = function() return { s.Egg } end
	c.Plan = { Objective = { Id = "PHASE4_NATIVE_TEST", Metadata = {} } }
	c.Pets, c.EggTravel = Pets.new(c), Travel.new(c)
	c.Scheduler = Scheduler.new(c.Config.TASK_SETTINGS) c.Scheduler:Resume()
	c.Farming.Mechanics.LocalFeatureGuard = function() return true end
	c.Farming.Mechanics.PetLocationOwnerProvider = function() return c.Pets.Hatch.Location ~= nil or c.EggTravel:OwnsLocation() end
	c.Rewards = { Select = function() error("Isolated Phase 4 must not select rewards") end }
	c.AntiAFK = { Select = function() error("Isolated Phase 4 must not select idle input") end }
	function s:Arbitrate()
		local owns, decision = c.Pets:Select(c.Plan)
		local owner, localDecision = c.Brain:SelectLocalFeature(c, c.Plan, owns, decision)
		return owner, localDecision, owns, decision
	end
	function s:Execute(definition)
		assert(c.Scheduler:Submit(definition))
		-- Resume this scheduler's actual deferred foreground task. The shared
		-- offline queue may retain canceled background fixture threads; draining
		-- unrelated fixtures is neither production task scheduling nor this test.
		local active = c.Scheduler.Active
		assert(active and active.Definition == definition and active.Thread)
		local removed = false
		for index, thread in ipairs(queue) do
			if thread == active.Thread then table.remove(queue, index) removed = true break end
		end
		assert(removed, "Foreground execution must come from the real scheduler defer queue")
		local ok, reason = coroutine.resume(active.Thread)
		assert(ok, reason)
		assert(c.Scheduler.Active == nil, "One foreground task must return before another task is selected")
	end
	function s:Arrive()
		local owner, decision = self:Arbitrate() assert(owner == "EGG_TRAVEL")
		self:Execute(c.EggTravel:Definition(decision, c.Generation))
		assert(c.EggTravel.Lease and c.EggTravel.Lease.Status == "ARRIVED")
		local afterOwner, _, owns, intent = self:Arbitrate()
		assert(afterOwner == nil and owns and intent.Kind == "HATCH" and intent.Model == self.Egg)
		return intent
	end
	local close = s.Close
	function s:Close() c.Scheduler:Destroy() close(self) end
	return s
end

test("Actual AUTO pipeline selects, arrives, dispatches one hatch and releases only after result plus idle presentation", function()
	simulated(function()
		local s = pipelineFixture() local c = s.Controller
		local intent = s:Arrive()
		assert(#c.Config.HATCH_SETTINGS.SELECTED_EGGS == 0 and #s.Teleports == 0 and #s.Calls == 0 and s.Blows == 0)
		assert(c.Pets.Report.Eggs[1].BaselineScore == 5 and c.Pets.Report.Team.CurrentScore == 2)
		s:Execute(c.Pets:Definition(intent, c.Generation))
		assert(#s.Commands == 1 and s.Commands[1].Command == "HatchEgg" and s.Commands[1].Name == "Pipeline Egg" and s.Commands[1].Count == 1)
		assert(c.Pets.Hatch.Pending and c.Pets.Hatch.RequestedHatches == 1 and c.Pets.EquipCommands == 0)
		local owner, _, owns, pending = s:Arbitrate()
		assert(owner == nil and owns and pending.Kind == "OBSERVE" and c.EggTravel:OwnsLocation())
		s.Hatching = true
		table.insert(s.Profile.Pets, { Id = "received", Name = "New", XP = 0 })
		s.Profile.EggsOpened["Pipeline Egg"] += 1 s.Profile.Coins -= 10
		c.Pets:Observe()
		assert(c.Pets.Hatch.LastResult.Status == "INVENTORY_GAIN_OBSERVED" and c.Pets.Hatch.VerifiedHatches == 1)
		assert(c.Pets.Hatch.LastResult.Changes[1].ActualIncrement == 4)
		owner, _, owns, pending = s:Arbitrate()
		assert(owner == nil and owns and pending.Kind == "OBSERVE" and c.EggTravel:OwnsLocation() and c.Pets.Hatch.Location)
		s.Hatching = false
		owner = s:Arbitrate()
		assert(owner == "PHASE4_WAIT" and not c.EggTravel:OwnsLocation() and c.Pets.Hatch.Location == nil)
		assert(#s.Commands == 1 and c.Pets.EquipCommands == 0 and #s.Teleports == 0 and #s.Calls == 0)
		s:Close()
	end)
end)

test("Actual native world reserve blocks the AUTO pipeline before a travel task exists", function()
	simulated(function()
		local s = pipelineFixture() s.Profile.Coins = 155
		local owner, _, owns, decision = s:Arbitrate()
		assert(owner == "PHASE4_WAIT" and not owns and decision.Kind == "WAIT" and decision.Reason:find("PROTECTED_RESERVE", 1, true))
		assert(s.Controller.Pets.Report.Eggs[1].Reserve == 150 and s.Controller.Pets.Report.Eggs[1].Spendable == 5)
		assert(s.Controller.EggTravel.Lease == nil and s.Controller.Pets.Hatch.Location == nil)
		assert(#s.Commands == 0 and #s.Teleports == 0 and #s.Calls == 0 and s.Blows == 0)
		s:Close()
	end)
end)

test("Actual Brain handoff respects manual departure and never spends or snaps to its old egg", function()
	simulated(function()
		local s = pipelineFixture() local intent = s:Arrive()
		s.Root.Position += Vector3.new(100, 0, 0)
		s.Controller.EggTravel:Observe()
		local owner, _, _, decision = s:Arbitrate()
		assert(owner == "PHASE4_WAIT" and #s.Commands == 0 and #s.Teleports == 0)
		local dispatched = s.Coordinator.Mechanics:PetAction(s.Controller.Pets, intent, token)
		assert(not dispatched and #s.Commands == 0 and not s.Controller.EggTravel:OwnsLocation())
		assert(decision.Kind == "HATCH" or decision.Kind == "WAIT")
		s:Close()
	end)
end)

test("Actual unopened pipeline uses its native Prompt even when the egg Root is farther away", function()
	simulated(function()
		local s = pipelineFixture() s.Opened = false s.Profile.EggsOpened = {}
		s.EggRoot.Position = s.Root.Position + Vector3.new(20, 0, 0)
		s.Prompt.Position = s.Root.Position + Vector3.new(2, 0, 0)
		local intent = s:Arrive()
		assert(s.Controller.EggTravel.Lease.RangeOrigin == s.Prompt and s.Controller.EggTravel.Lease.Distance <= 6.5)
		s:Execute(s.Controller.Pets:Definition(intent, 1))
		assert(#s.Commands == 1 and s.Commands[1].Command == "HatchEgg" and s.Commands[1].Count == 1,
			"Stable native initial Prompt arrival must not be rejected by an opened-egg Root distance check")
		s:Close()
	end)
end)

test("Continuing AUTO reranks only after confirmed inventory and idle presentation before acquiring a new egg lease", function()
	simulated(function()
		local s = pipelineFixture() local c, d = s.Controller, s.Dependencies
		c.Config.HATCH_SETTINGS.HATCH_ONE_EGG_ONCE = false c.Pets.Hatch.Once = false
		c.Config.HATCH_SETTINGS.MAXIMUM_SESSION_HATCHES = 3 c.Config.HATCH_SETTINGS.MAXIMUM_SESSION_COST = 30
		c.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true
		local first = s:Arrive() local originalLease = c.EggTravel.Lease
		s:Execute(c.Pets:Definition(first, 1))
		assert(#s.Commands == 1 and c.Pets.Hatch.Pending and c.Pets.Hatch.RequestedHatches == 1)

		-- A newly loaded native egg now offers a stronger outcome. AUTO is allowed
		-- to discover it but cannot preempt the outstanding hatch transaction.
		s.Ranks.Better = 13 d.Pets.Better = { Rarity = "Epic" }
		d.Eggs["Better Pipeline Egg"] = { World = "The Overworld", Island = "The Void",
			Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } }
		local alternativeRoot = { Parent = true, Position = s.Root.Position + Vector3.new(200, 0, 0),
			IsA = function(_, kind) return kind == "BasePart" end, IsDescendantOf = function(self) return self.Parent ~= nil end }
		local alternative = { Name = "Better Pipeline Egg", Parent = true,
			IsDescendantOf = function(self) return self.Parent ~= nil end,
			GetFullName = function() return "Workspace.Worlds.The Overworld.Islands.The Void.Better Pipeline Egg" end,
			FindFirstChild = function(_, name)
				if name == "Root" or name == "Prompt" then return alternativeRoot end return {}
			end,
			GetAttribute = function(_, name) if name == "Unlocked" then return true elseif name == "Island" then return "The Void" end end }
		s.Profile.EggsOpened[alternative.Name] = 0
		c.Knowledge.EggModels = function() return { s.Egg, alternative } end
		d.GetEggPool = function(name)
			return { { Chance = 1, Item = { Type = "Pet", Name = name == alternative.Name and "Better" or "New" } } }
		end
		local owner, _, owns, decision = s:Arbitrate()
		assert(owner == nil and owns and decision.Kind == "OBSERVE" and c.EggTravel.Lease == originalLease)
		assert(not s.Coordinator.Mechanics:PetAction(c.Pets, first, token) and #s.Commands == 1)
		assert(c.Pets.Hatch.Location.EggName == first.EggName and #s.Teleports == 0)

		-- A received result alone still cannot hand location to another task while
		-- native presentation is active, even though session budget remains.
		s.Hatching = true
		table.insert(s.Profile.Pets, { Id = "received", Name = "New", XP = 0 })
		s.Profile.EggsOpened[first.EggName] += 1 s.Profile.Coins -= 10
		c.Pets:Observe()
		assert(c.Pets.Hatch.Pending == nil and c.Pets.Hatch.VerifiedHatches == 1 and not c.Pets.Hatch:Ended())
		owner, _, owns, decision = s:Arbitrate()
		assert(owner == nil and owns and decision.Kind == "OBSERVE" and c.EggTravel.Lease == originalLease,
			"Confirmed inventory cannot release the previous arrival during native presentation")
		assert(c.Pets.Hatch.Location.EggName == first.EggName and #s.Commands == 1 and #s.Teleports == 0)

		s.Hatching = false
		owner, _, owns, decision = s:Arbitrate()
		assert(owner == "PHASE4_WAIT" and owns and decision.Kind == "HATCH" and decision.EggName == alternative.Name)
		assert(c.EggTravel.Lease == nil and c.EggTravel.Blocked[originalLease.SelectionKey],
			"Reranking releases the stale arrival before selecting movement for another original model")
		assert(not s.Coordinator.Mechanics:PetAction(c.Pets, first, token) and #s.Commands == 1,
			"The previous paid decision cannot dispatch after the actual owned inventory changes")
		owner, _, owns, decision = s:Arbitrate()
		assert(owner == "EGG_TRAVEL" and owns and decision.EggName == alternative.Name)
		assert(c.EggTravel.Lease.Model == alternative and c.EggTravel.Lease.Status == "PLANNED")
		assert(c.EggTravel.Lease.SelectionKey == "AUTO:" .. alternative.Name .. ":0")
		assert(c.Pets.Hatch.RequestedHatches == 1 and c.Pets.Hatch.RequestCost == 10 and #s.Commands == 1 and #s.Teleports == 0)
		assert(#c.Config.HATCH_SETTINGS.SELECTED_EGGS == 0)
		s:Close()
	end)
end)

print("[OC TEST] " .. (tests - before) .. " actual Phase 4 Brain/pet/travel/scheduler pipeline tests passed; native acceptance remains owner pending")
end

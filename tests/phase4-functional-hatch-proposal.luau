
-- Approved functional exception behavior. Isolated offline mocks; no live actions.
local proposalBefore = tests
local proposalScenarios = 0
local function functional(s)
	s.Controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST = true
	return s
end
local function functionalScenario(callback)
	proposalScenarios += 1
	scenario(callback)
end
local function loadSpottedCompetitor(s, distance)
	local receiver = s.Controller.Knowledge.NativeEggFixtureReceiver
	local model = table.remove(receiver._chunks.coldA, 1)
	assert(model.Name == "Spotted Egg")
	model.Parent = receiver._folder
	model.Root.Position = s.Root.Position + Vector3.new(distance, 0, 0)
	model.Prompt.Position = model.Root.Position
	table.insert(receiver._chunks.loaded, model)
end

test("Approved functional exception preserves positive/zero-EV estimates and permits exactly one explicit receipt test", function()
	functionalScenario(function(clock)
		local s = functional(strongMockTeam(mixedNativeQueue(true)))
		completeNativeObservation(s, clock)
		local decision, context = s:Decision()
		local snapshot = s.Manager:Fresh()
		local report = s.Controller.Brain:AnalyzePets(snapshot, context)
		local egg = report.Eggs[1]
		assert(report.Team.ProjectedScore == 1752 and egg.ExpectedIncrement == 0)
		assert(egg.OwnerCommonFunctionalTestRequested and egg.OwnerCommonFunctionalTestEligible and Policy.EggBlocker(egg) == nil)
		assert(decision.Kind == "HATCH" and decision.EggName == "Common Egg" and decision.Model == s.Egg and decision.Count == 1)
		assert(s:Dispatch() and #s.Commands == 1 and s.Manager.Hatch.RequestCost == 10)
		assert(s.Manager.Hatch.Pending.UsefulnessBaseline.Score == 1752 and s.Manager.Hatch.Pending.OwnerAllowance.RequestedPrice == 10)
		assert(not s:Dispatch() and #s.Commands == 1)
		s.Profile.Pets[8] = { Id = "mock-functional-received", Name = "New", Amount = 1 }
		s.Profile.EggsOpened["Common Egg"], s.Profile.Coins = 3, 490
		s.Manager:Observe()
		local result = s.Manager.Hatch.LastResult
		assert(result.Status == "INVENTORY_GAIN_OBSERVED" and result.Quantity == 1 and result.UsefulReceivedCopies == 0)
		assert(result.Changes[1].ActualIncrement == 0 and result.Changes[1].Usefulness == "NO_CURRENT_TEAM_IMPROVEMENT")
		assert(result.Continuation == "SINGLE_HATCH_ENDED_EQUIPMENT_OFF" and s.Manager.Hatch:Ended())
		assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.EquipCommands == 0)
		assert(#s.Teleports == 0 and #s.Calls == 0 and s.Blows == 0) s:Close()
	end)
	functionalScenario(function(clock)
		local s = mixedNativeQueue(true)
		completeNativeObservation(s, clock)
		local ordinaryDecision, ordinaryContext = s:Decision()
		local ordinary = s.Controller.Brain:AnalyzePets(s.Manager:Fresh(), ordinaryContext).Eggs[1]
		assert(ordinary.ExpectedIncrement > 1e-6 and ordinaryDecision.Kind == "HATCH")
		functional(s)
		local decision, context = s:Decision()
		local egg = s.Controller.Brain:AnalyzePets(s.Manager:Fresh(), context).Eggs[1]
		assert(egg.OwnerCommonFunctionalTestEligible and egg.ExpectedIncrement == ordinary.ExpectedIncrement)
		assert(egg.ClientImprovementProbability == ordinary.ClientImprovementProbability and egg.BaselineScore == ordinary.BaselineScore)
		assert(decision.Kind == "HATCH" and decision.Model == s.Egg and decision.Count == 1)
		assert(s:Dispatch() and #s.Commands == 1 and s.Manager.Hatch.RequestCost == 10)
		s.Profile.Pets[2] = { Id = "mock-functional-useful-received", Name = "New", Amount = 1 }
		s.Profile.EggsOpened["Common Egg"], s.Profile.Coins = 3, 490
		s.Manager:Observe()
		assert(s.Manager.Hatch.LastResult.Status == "INVENTORY_GAIN_OBSERVED" and s.Manager.Hatch.LastResult.UsefulReceivedCopies == 1)
		assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.EquipCommands == 0)
		assert(#s.Teleports == 0 and #s.Calls == 0 and s.Blows == 0) s:Close()
	end)
end)

test("Approved functional exception flagOFF retains zero-EV economic WAIT and configured target cannot bypass it", function()
	functionalScenario(function(clock)
		local s = strongMockTeam(mixedNativeQueue(true))
		completeNativeObservation(s, clock)
		s.Controller.Config.PET_SETTINGS.SELECTED_PETS = { "New" }
		local decision, context = s:Decision()
		local snapshot = s.Manager:Fresh()
		local egg = s.Controller.Brain:AnalyzePets(snapshot, context).Eggs[1]
		assert(not egg.OwnerCommonFunctionalTestRequested and not egg.OwnerCommonFunctionalTestEligible and egg.ExpectedIncrement == 0)
		assert(egg.ClientTargetProbability == 1 and decision.Kind == "WAIT" and decision.Reason:find("NO_USEFUL_IMPROVEMENT", 1, true))
		assert(not s:Dispatch() and not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:NoActions() s:Close()
	end)
end)

test("Approved functional exception rejects invalid authorization scope ceilings counts currency and isolation", function()
	local cases = {
		function(s) s.Controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS.AUTHORIZED_ACCOUNT_ID = 0 end,
		function(s) s.Controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS.AUTHORIZED_ACCOUNT_ID = 456 end,
		function(s) s.Controller.Reader.Player.UserId = 456 end,
		function(s) s.Controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_HATCH_TEST_ALLOWANCE = false end,
		function(s) s.Controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS.MAXIMUM_COIN_ALLOWANCE = 11 end,
		function(s) s.Controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS.MAXIMUM_EGG_COST = 11 end,
		function(s) s.Controller.Config.HATCH_SETTINGS.MAXIMUM_EGG_COST = 11 end,
		function(s) s.Controller.Config.HATCH_SETTINGS.MAXIMUM_SESSION_COST = 11 end,
		function(s) s.Controller.Config.HATCH_SETTINGS.MAXIMUM_SESSION_HATCHES = 2 end,
		function(s) s.Controller.Config.HATCH_SETTINGS.MAXIMUM_BATCH_HATCHES = 2 end,
		function(s) s.Controller.Config.HATCH_SETTINGS.SELECTED_EGGS = { "Spotted Egg" } end,
		function(s) s.Controller.Config.HATCH_SETTINGS.SELECTED_EGGS = { "Common Egg", "Spotted Egg" } end,
		function(s) s.Controller.Config.HATCH_SETTINGS.SELECTED_EGGS = {} end,
		function(s) s.Controller.Config.HATCH_SETTINGS.ALLOWED_CURRENCIES = { "Gems" } end,
		function(s) s.Controller.Config.PET_SETTINGS.AUTO_EQUIP = true end,
		function(s) s.Controller.Config.FARMING_SETTINGS.AUTO_RESOURCE_FARM = true end,
		function(s) s.Controller.Config.EGG_TRAVEL_SETTINGS.MODE = "TRAVEL_ONLY" end,
		function(s) s.Controller.Config.HATCH_SETTINGS.ENABLE_BACKGROUND_PICKUPS = true end,
		function(s) s.Controller.Config.HATCH_SETTINGS.PRESERVE_PROGRESSION_RESERVE = false end,
		function(s) s.Controller.Config.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME = true end,
		function(s) s.Controller.Config.HATCH_SETTINGS.EGG_SELECTION_MODE = "AUTO" end,
		function(s) s.Controller.Config.HATCH_SETTINGS.HATCH_ONE_EGG_ONCE = false end,
	}
	for _, mutate in ipairs(cases) do
		functionalScenario(function(clock)
			local s = functional(strongMockTeam(mixedNativeQueue(true)))
			completeNativeObservation(s, clock) mutate(s)
			assert(not s:Dispatch() and not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:NoActions() s:Close()
		end)
	end
end)

test("Approved functional exception cannot authorize another positive egg or widen ordinary economic policy", function()
	functionalScenario(function()
		local s = functional(fixture(true))
		s.Controller.Config.HATCH_SETTINGS.SELECTED_EGGS = { "Spotted Egg" }
		local other = s:AddEgg("Spotted Egg", 1)
		local decision, context = s:Decision()
		local snapshot = s.Manager:Fresh()
		local report = s.Controller.Brain:AnalyzePets(snapshot, context)
		local egg = report.Eggs[1]
		assert(egg.Name == "Spotted Egg" and egg.ExpectedIncrement > 0 and egg.Eligible)
		assert(egg.OwnerCommonFunctionalTestRequested and not egg.OwnerCommonFunctionalTestEligible)
		assert(Policy.EggBlocker(egg):find("OWNER_COMMON_FUNCTIONAL_TEST_SCOPE_BLOCKED", 1, true) and decision.Kind == "WAIT")
		local command = s.Manager:Prepare({ Kind = "HATCH", EggName = "Spotted Egg", Model = other, Count = 1 }, s.Token)
		assert(command == nil and not s:Dispatch() and not s.Controller.HatchTestAllowance:GetStatus().Consumed)
		s:NoActions() s:Close()
	end)
end)

test("Approved functional exception requires complete scored owned baseline and supported full pool", function()
	for index, mutate in ipairs({ function(s)
			s.Controller.Config.PET_SETTINGS.MAXIMUM_TEAM_EVALUATIONS = 1
			s.Profile.Pets[8] = { Id = "mock-unequipped-to-score", Name = "New", Amount = 1 }
		end,
		function(s) s.Dependencies.PetUtil.GetStats = function() return nil end end,
		function(s) s.Dependencies.Pets.MockStrong1 = nil end,
		function(s) s.Dependencies.GetEggPool = function() return {} end end,
		function(s) s.Dependencies.GetEggPool = function() return { { Chance = 1, Item = { Type = "Pet", Name = "Missing" } } } end end,
		function(s) s.Dependencies.StatsUtil.GetCurrencyMultiplier = function() return nil end end }) do
		functionalScenario(function(clock)
			local s = functional(strongMockTeam(mixedNativeQueue(true)))
			completeNativeObservation(s, clock) mutate(s)
			assert(not s:Dispatch() and not s.Controller.HatchTestAllowance:GetStatus().Consumed, "Unknown baseline/pool fixture " .. index) s:NoActions() s:Close()
		end)
	end
end)

test("Approved functional exception preserves registration assets exactidentity allname nearest and range prerequisites", function()
	for index, mutate in ipairs({ function(s) s.Controller.Knowledge.NativeEggFixtureAssets["Common Egg"] = nil end,
		function(s) s.Controller.Knowledge.NativeEggFixtureReceiver._loaded.loaded = nil end,
		function(s) s.Egg.Parent = nil end,
		function(s) s.Other.Root.Position = s.Root.Position + Vector3.new(2.01, 0, 0) end,
		function(s) loadSpottedCompetitor(s, 1) end,
		function(s) s.Egg.Root.Position = s.Root.Position + Vector3.new(100, 0, 0) end,
		function(s) s.Dependencies.ProximityPrompt.Visible = 1 end,
		function(s) s.Opened = false end }) do
		functionalScenario(function(clock)
			local s = functional(strongMockTeam(mixedNativeQueue(true)))
			completeNativeObservation(s, clock) mutate(s)
			assert(not s:Dispatch() and not s.Controller.HatchTestAllowance:GetStatus().Consumed, "Identity/range fixture " .. index) s:NoActions() s:Close()
		end)
	end
end)

test("Approved functional exception retains price funds autodelete nativecapacity cooldown and idle vetoes", function()
	for _, mutate in ipairs({ function(s) s.Cost = 11 end,
		function(s) s.Dependencies.StatsUtil.GetEggCost = function() return nil end end,
		function(s) s.Profile.Coins = 59 end,
		function(s) s.Storage = 1926 end,
		function(s) s.Dependencies.StatsUtil.HasDigitalStorage = function() return nil end end,
		function(s) s.Profile.AutoDelete = nil end,
		function(s) s.Profile.AutoDelete = { New = false } end,
		function(s) s.Profile.AutoDelete = { New = true } end,
		function(s) s.Profile.AutoDelete = { New = { Shiny = false } } end,
		function(s) s.NextAt = 101 end,
		function(s) s.Hatching = true end,
		function(s) s.NativeAuto = "Common Egg" end }) do
		functionalScenario(function(clock)
			local s = functional(strongMockTeam(mixedNativeQueue(true)))
			completeNativeObservation(s, clock) mutate(s)
			assert(not s:Dispatch() and not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:NoActions() s:Close()
		end)
	end
end)

test("Approved functional exception rechecks functionalscope price account nativeguards after yielding guards", function()
	for _, mutate in ipairs({ function(s) s.Controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST = false end,
		function(s) s.Controller.Config.HATCH_SETTINGS.MAXIMUM_SESSION_COST = 11 end,
		function(s) s.Controller.Reader.Player.UserId = 456 end,
		function(s) s.Cost = 11 end,
		function(s) s.Dependencies.StatsUtil.GetEggCost = function() return nil end end,
		function(s) s.Profile.AutoDelete.New = true end,
		function(s) s.Storage = 1926 end,
		function(s) s.NextAt = 101 end,
		function(s) s.Hatching = true end,
		function(s) s.NativeAuto = "Common Egg" end,
		function(s) loadSpottedCompetitor(s, 1) end,
		function(s) s.Egg.Parent = nil end,
		function(s) s.Other.Root.Position = s.Root.Position + Vector3.new(1, 0, 0) end,
		function(s) s.Cancelled = true end,
		function(s) s.Controller.State = "STOPPED" end }) do
		functionalScenario(function(clock)
			local s = functional(strongMockTeam(mixedNativeQueue(true)))
			completeNativeObservation(s, clock)
			assert(s:Decision().Kind == "HATCH")
			s.OnGuard = function(call) if call == 2 then mutate(s) end end
			assert(not s:Dispatch() and not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:NoActions() s:Close()
		end)
	end
end)

test("Approved functional exception final range callback cannot mutate facts or permission into a zeroEV dispatch", function()
	for _, mutate in ipairs({ function(s) s.Profile.AutoDelete.New = true end,
		function(s) s.Controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST = false end,
		function(s) s.Controller.Reader.Player.UserId = 456 end,
		function(s) s.Cancelled = true end }) do
		functionalScenario(function(clock)
			local s = functional(strongMockTeam(mixedNativeQueue(true)))
			completeNativeObservation(s, clock)
			local knowledge, original, count = s.Controller.Knowledge, s.Controller.Knowledge.NativeEggRangeEligible, 0
			knowledge.NativeEggRangeEligible = function(self, ...)
				local returned = table.pack(original(self, ...))
				count += 1
				-- Prepare's last forced eligibility observation occurs after native idle,
				-- capacity and cost guards; mutation is only an offline race fixture.
				if s.GuardCalls >= 2 then mutate(s) end
				return table.unpack(returned, 1, returned.n)
			end
			assert(not s:Dispatch() and count > 0 and not s.Controller.HatchTestAllowance:GetStatus().Consumed)
			s:NoActions() s:Close()
		end)
	end
end)

test("Approved functional exception uncertain request consumes singleVM opportunity with no second request or equipment", function()
	functionalScenario(function(clock)
		local s = functional(strongMockTeam(mixedNativeQueue(true)))
		completeNativeObservation(s, clock) s.RemoteFailure = true
		assert(s:Dispatch() and #s.Commands == 1)
		assert(s.Controller.HatchTestAllowance:GetStatus().Record.State == "INVOCATION_UNCERTAIN")
		assert(not s:Dispatch() and #s.Commands == 1)
		clock.Time = s.Manager.Hatch.Pending.Deadline + 0.1 s.Manager:Observe()
		assert(s.Manager.Hatch.LastResult.Status == "UNCONFIRMED")
		s.Controller.HatchTestAllowance = Allowance.new(s.Controller)
		s.Manager = Pets.new(s.Controller) s.Controller.Pets = s.Manager
		assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.Hatch.RequestedHatches == 0)
		assert(s.Manager.EquipCommands == 0 and #s.Teleports == 0 and #s.Calls == 0 and s.Blows == 0) s:Close()
	end)
end)

test("Approved functional exception spent opportunity remains blocked even when next weak fixture would have useful Common outcome", function()
	functionalScenario(function(clock)
		local s = functional(strongMockTeam(mixedNativeQueue(true)))
		completeNativeObservation(s, clock) assert(s:Dispatch())
		local nextFixture = fixture(true)
		nextFixture.Controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST = true
		assert(not nextFixture:Dispatch() and nextFixture.Controller.HatchTestAllowance:GetStatus().Consumed)
		nextFixture:NoActions() assert(#s.Commands == 1) nextFixture:Close() s:Close()
	end)
end)

print("[OC FUNCTIONAL EXCEPTION] TARGET_TEST_COUNT " .. tostring(tests - proposalBefore) .. "; SCENARIO_COUNT " .. tostring(proposalScenarios))

-- Synthetic end-to-end account transitions. These are never live purchase/save evidence.
do
local before = tests
local function integratedFixture(currency)
	local scene = progressionFixture({ WORLD_SETTINGS = { AUTO_DISCOVER_ISLANDS = true,
		AUTO_FARM_UNLOCK_REQUIREMENTS = true, AUTO_UNLOCK_WORLDS = false,
		AUTO_TRAVEL_FOR_PROGRESSION = false, MAXIMUM_WORLD_UNLOCK_COST = 0 },
		ISLAND_SETTINGS = { AUTO_SELECT_BEST_ISLAND = true, AUTO_TRAVEL_BEST_ISLAND = true } })
	scene.Profile.Coins, scene.Profile.Gems = 0, 0
	-- Inspected live amount in a synthetic definition; Gems is a deliberately hypothetical test contract.
	scene.Definitions["Minigame Paradise"].UnlockCost.Currency = currency or "Coins"
	scene.Definitions["Minigame Paradise"].UnlockCost.Amount = 1000000000
	local world = scene.WorldRoot["The Overworld"]
	scene.Areas = {}
	for _, name in ipairs({ "The Void", "Zen" }) do
		local area = { Name = name, World = "The Overworld", Key = "The Overworld/" .. name,
			Spawn = world.Islands[name].Island.Portal.Spawn, Currencies = { Coins = true, Gems = true },
			ActualUnlocked = true, Unlocked = true }
		scene.Areas[name] = area scene.Coordinator.Tracker.Areas[area.Key] = area
	end
	function scene:SetArea(name)
		self.Area = self.Areas[name] self.Coordinator.Tracker.Current = self.Area
		self.Coordinator.Tracker.ArrivedAt = os.clock() - 10
	end
	scene:SetArea("Zen")
	scene.OnTeleport = function(path)
		for name, area in pairs(scene.Areas) do
			if path == area.Spawn:GetFullName() then scene.Root.Position = area.Spawn.Position scene:SetArea(name) end
		end
	end
	-- Supply synthetic loaded-island observations; real Brain, policy, adapters, collector and manager execute.
	scene.Coordinator.Context = function(owner, plan)
		for name, area in pairs(scene.Areas) do area.ActualUnlocked = scene.Profile.AreasUnlocked[name] ~= nil end
		local currencyNeeded = Policy.Target(owner.Config, scene:Snapshot(), plan, {})
		return { Now = os.clock(), ArrivedAt = owner.Tracker.ArrivedAt, Current = owner.Tracker.Current,
			Islands = { scene.Areas["The Void"], scene.Areas.Zen }, SceneReady = true, CanInteract = true,
			CanTravel = true, CanBlow = false, Rates = {}, Sells = {},
			Cluster = currencyNeeded and owner.Tracker:Cluster(currencyNeeded) or nil }
	end
	function scene:FundingDecision()
		local plan = self:Plan()
		assert(not self.Manager:Select(plan), "Only a verified FUNDING goal hands off to Phase 2")
		return self.Coordinator:Select(plan)
	end
	function scene:ExecuteFarm(decision, token)
		local definition = self.Coordinator:Definition(decision, self.Controller.Generation)
		assert(definition.Id == "OC_GAMEPLAY" and definition.Owner ~= "WORLD_PROGRESSION")
		return definition.Execute(token or { CheckCancelled = function() return false end })
	end
	return scene
end

test("Integrated fresh account discovers five flags then funds the actual billion-Coin goal via native Void travel", function()
	simulated(function(clock)
		local scene = integratedFixture()
		scene.Profile.AreasUnlocked = {}
		local oldContact = firetouchinterest
		local contacts = 0
		firetouchinterest = function(_, hitbox, phase)
			contacts += 1
			if phase == 1 then scene.Profile.AreasUnlocked[hitbox.Parent.Parent.Name] = true end
		end
		for index, island in ipairs(scene.Definitions["The Overworld"].Islands) do
			local hitbox = progressionNode("UnlockHitbox", scene.WorldRoot["The Overworld"].Islands[island.Name].Island, "Part")
			hitbox.Anchored, hitbox.CanTouch, hitbox.Position = true, true, Vector3.new(0, island.Height, 0)
			if index > 1 then clock.Time += 10 end
			local plan = scene:Plan() local owns, decision = scene.Manager:Select(plan)
			assert(owns and decision.Kind == "DISCOVER_ISLAND" and decision.Node.Name == island.Name)
			assert(scene.Manager:Definition(decision, 1).Execute({ CheckCancelled = function() return false end }).Verified)
		end
		firetouchinterest = oldContact
		assert(contacts == 10 and #scene.Calls == 0 and #scene.Teleports == 0)
		local decision = scene:FundingDecision()
		assert(scene.Controller.Plan.Objective.Id == "PROGRESSION:WORLD:Minigame Paradise")
		assert(decision.Kind == "TRAVEL" and decision.Currency == "Coins" and decision.Deficit == 1000000000)
		assert(decision.Island.Name == "The Void" and scene:ExecuteFarm(decision).Verified)
		clock.Time += 10
		for index = 1, 40 do scene:Add("integrated-" .. index, "Coins", 500) end
		scene.OnDispatch = function() scene.Profile.Coins += 10 end
		decision = scene:FundingDecision()
		assert(decision.Kind == "FARM" and scene:ExecuteFarm(decision).Verified)
		assert(#scene.Calls == 32 and #scene.Removed == 32 and #scene.Teleports == 1 and scene.Blows == 0 and #scene.Unlocks == 0)
		assert(scene.Profile.Coins == 320 and scene.Coordinator.Stationary.LastResult.Gains.Coins == 320)
		clock.Time += 10 scene:Add("newly-spawned", "Coins", 500)
		assert(scene:ExecuteFarm(scene:FundingDecision()).Verified and #scene.Calls > 32)
		scene:Close()
	end)
end)

test("Observed affordability stops new requests in the active batch and disabled spending becomes WAIT", function()
	simulated(function()
		local scene = integratedFixture() scene:SetArea("The Void")
		for _, island in ipairs(scene.Definitions["The Overworld"].Islands) do scene.Profile.AreasUnlocked[island.Name] = true end
		scene.Profile.Coins = 999999990
		for index = 1, 32 do scene:Add("threshold-" .. index, "Coins") end
		scene.OnDispatch = function() scene.Profile.Coins += 10 end
		assert(scene:ExecuteFarm(scene:FundingDecision()).Verified)
		assert(#scene.Calls == 1, "No new request after real balance satisfies the active goal")
		local owns, decision = scene.Manager:Select(scene:Plan())
		assert(owns and decision.Kind == "WAIT" and decision.Reason:find("AUTO_UNLOCK_WORLDS=false", 1, true))
		assert(scene.Controller.Plan.Objective.Metadata.Cost == nil)
		assert(scene.Coordinator:Select(scene.Controller.Plan).Kind == "WAIT")
		assert(#scene.Teleports == 0 and #scene.Unlocks == 0 and scene.Blows == 0)
		scene:Close()
	end)
end)

test("Affordable balance arriving before selected funding travel prevents unnecessary teleport", function()
	simulated(function()
		local scene = integratedFixture()
		for _, island in ipairs(scene.Definitions["The Overworld"].Islands) do scene.Profile.AreasUnlocked[island.Name] = true end
		local decision = scene:FundingDecision() assert(decision.Kind == "TRAVEL")
		scene.Profile.Coins = 1000000000
		local result = scene:ExecuteFarm(decision)
		assert(not result.Verified and #scene.Teleports == 0 and #scene.Calls == 0)
		scene:Close()
	end)
end)

test("Gems funding chooses unlocked Zen and an unchanged goal retains location until received funds suffice", function()
	simulated(function(clock)
		local scene = integratedFixture("Gems")
		scene.Definitions["Minigame Paradise"].UnlockCost.Amount = 1000 -- Hypothetical currency contract, not a live Gems world.
		for _, island in ipairs(scene.Definitions["The Overworld"].Islands) do scene.Profile.AreasUnlocked[island.Name] = true end
		scene:SetArea("The Void")
		local decision = scene:FundingDecision()
		assert(decision.Kind == "TRAVEL" and decision.Currency == "Gems" and decision.Island.Name == "Zen")
		assert(scene:ExecuteFarm(decision).Verified) clock.Time += 10
		scene.Profile.Gems = 990
		for index = 1, 32 do scene:Add("gems-" .. index, "Gems") end
		scene.OnDispatch = function() scene.Profile.Gems += 10 end
		decision = scene:FundingDecision() assert(decision.Kind == "FARM" and decision.PreferredIsland == "The Overworld/Zen")
		assert(scene:ExecuteFarm(decision).Verified and #scene.Calls == 1 and #scene.Teleports == 1)
		local owns, wait = scene.Manager:Select(scene:Plan())
		assert(owns and wait.Kind == "WAIT" and #scene.Unlocks == 0 and scene.Blows == 0)
		scene:Close()
	end)
end)

test("Unavailable preferred farming island uses only the permitted unlocked matching-pool fallback", function()
	local scene = integratedFixture() scene.Controller.Config.WORLD_SETTINGS.AUTO_DISCOVER_ISLANDS = false
	scene.Profile.AreasUnlocked["The Void"] = nil
	local decision = scene:FundingDecision()
	assert(decision.Kind == "INSPECT" and decision.PreferredIsland == "The Overworld/Zen")
	assert(decision.Limitation:find("The Void unavailable/locked", 1, true) and #scene.Teleports == 0)
	scene.Areas.Zen.Currencies.Coins = nil
	decision = scene:FundingDecision()
	assert(decision.Kind == "WAIT" and decision.Reason:find("no matching currency", 1, true))
	scene:Close()
end)

test("Partial and completed received discoveries skip attempts and disabling shortage funding prevents handoff", function()
	local scene = integratedFixture()
	scene.Profile.AreasUnlocked = { ["Floating Island"] = true, ["Outer Space"] = true }
	assert(scene:Plan().Objective.Metadata.Progression.Node.Name == "Twilight")
	for _, island in ipairs(scene.Definitions["The Overworld"].Islands) do scene.Profile.AreasUnlocked[island.Name] = true end
	scene.Controller.Config.WORLD_SETTINGS.AUTO_FARM_UNLOCK_REQUIREMENTS = false
	local plan = scene:Plan() local owns, decision = scene.Manager:Select(plan)
	assert(owns and decision.Kind == "WAIT" and plan.Objective.Metadata.Cost == nil)
	assert(scene.Coordinator:Select(plan).Kind == "WAIT" and #scene.Teleports == 0 and #scene.Calls == 0)
	scene:Close()
end)

test("Pause Resume Stop retain dispatched ID records and cancel new integrated funding work", function()
	simulated(function(clock)
		local scene = integratedFixture() scene:SetArea("The Void")
		for _, island in ipairs(scene.Definitions["The Overworld"].Islands) do scene.Profile.AreasUnlocked[island.Name] = true end
		for index = 1, 40 do scene:Add("controls-" .. index, "Coins") end
		local paused = false
		scene.OnDispatch = function() scene.Profile.Coins += 10 end
		clock.Tick = function() paused = true scene.Controller.State = "PAUSED" end
		local decision = scene:FundingDecision()
		assert(scene:ExecuteFarm(decision, { CheckCancelled = function() return paused end }) == nil and #scene.Calls == 1)
		local first = scene.Calls[1].Id
		scene.Coordinator:Halt() scene.Manager:Halt()
		assert(scene.Coordinator.Stationary.PerId[first].Dispatched)
		clock.Tick = nil clock.Time += 10 scene.Controller.State, scene.Controller.Generation = "RUNNING", 2
		assert(scene:ExecuteFarm(scene:FundingDecision()).Verified and #scene.Calls == 33)
		for index = 2, #scene.Calls do assert(scene.Calls[index].Id ~= first) end
		clock.Time += 10 local stoppedDecision = scene:FundingDecision()
		scene.Controller.State = "STOPPED"
		local definition = scene.Coordinator:Definition(stoppedDecision, 2)
		assert(not definition.CanRun() and definition.Execute({ CheckCancelled = function() return true end }) == nil)
		assert(#scene.Calls == 33 and #scene.Unlocks == 0 and scene.Blows == 0)
		scene:Close()
	end)
end)

test("Billion-Coin world purchase needs explicit switch ceiling funds range and correct unlock acknowledgement", function()
	simulated(function()
		local scene = integratedFixture()
		for _, island in ipairs(scene.Definitions["The Overworld"].Islands) do scene.Profile.AreasUnlocked[island.Name] = true end
		scene.Profile.Coins = 1000000100 scene:AtGate("Minigame Paradise") scene:Plan()
		local mechanics, token = scene.Coordinator.Mechanics, { CheckCancelled = function() return false end }
		assert(not mechanics:UnlockWorld("Minigame Paradise", token) and #scene.Unlocks == 0)
		scene.Controller.Config.WORLD_SETTINGS.AUTO_UNLOCK_WORLDS = true
		assert(not mechanics:UnlockWorld("Minigame Paradise", token) and #scene.Unlocks == 0)
		scene.Controller.Config.WORLD_SETTINGS.MAXIMUM_WORLD_UNLOCK_COST = 1000000000
		scene.Profile.Coins = 999999999
		assert(not mechanics:UnlockWorld("Minigame Paradise", token) and #scene.Unlocks == 0)
		scene.Profile.Coins = 1000000100 scene.Root.Position += Vector3.new(0, 11, 0)
		assert(not mechanics:UnlockWorld("Minigame Paradise", token) and #scene.Unlocks == 0)
		scene:AtGate("Minigame Paradise")
		scene.OnUnlock = function(name) scene.Profile.Coins -= 1000000000 scene.Profile.WorldsUnlocked[name] = true end
		local ok, _, evidence = mechanics:UnlockWorld("Minigame Paradise", token)
		assert(ok and evidence.Verified and evidence.ObservedDeduction == 1000000000 and #scene.Unlocks == 1)
		assert(scene:Plan().Objective.Id ~= "PROGRESSION:WORLD:Minigame Paradise")
		assert(table.concat(scene.Logs, "\n"):find("WORLD][VERIFIED", 1, true))
		scene:Close()
	end)
end)

test("Billion-Coin payment and gate visuals without WorldsUnlocked never verify or select a later world", function()
	simulated(function()
		local scene = integratedFixture()
		for _, island in ipairs(scene.Definitions["The Overworld"].Islands) do scene.Profile.AreasUnlocked[island.Name] = true end
		scene.Controller.Config.WORLD_SETTINGS.AUTO_UNLOCK_WORLDS = true
		scene.Controller.Config.WORLD_SETTINGS.MAXIMUM_WORLD_UNLOCK_COST = 1000000000
		scene.Profile.Coins = 1000000100 scene:AtGate("Minigame Paradise") scene:Plan()
		scene.OnUnlock = function() scene.Profile.Coins -= 1000000000 scene.Gates["Minigame Paradise"].VisualAnimationFinished = true end
		local ok, _, evidence = scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end })
		assert(not ok and not evidence.Verified and #scene.Unlocks == 1 and not scene.Profile.WorldsUnlocked["Minigame Paradise"])
		assert(scene:Plan().Objective.Id == "PROGRESSION:WORLD:Minigame Paradise")
		assert(not table.concat(scene.Logs, "\n"):find("WORLD][VERIFIED", 1, true))
		scene:Close()
	end)
end)

test("Delayed received funding credit during request pacing stops dispatch while preserving batch balance logging", function()
	simulated(function(clock)
		local scene = integratedFixture() scene:SetArea("The Void")
		for _, island in ipairs(scene.Definitions["The Overworld"].Islands) do scene.Profile.AreasUnlocked[island.Name] = true end
		scene.Profile.Coins = 999999990
		for index = 1, 32 do scene:Add("delayed-" .. index, "Coins") end
		clock.Tick = function() if #scene.Calls > 0 then scene.Profile.Coins = 1000000000 end end
		assert(scene:ExecuteFarm(scene:FundingDecision()).Verified and #scene.Calls == 1)
		local result = scene.Coordinator.Stationary.LastResult
		assert(result.Before.Coins == 999999990 and result.After.Coins == 1000000000 and result.Gains.Coins == 10)
		scene:Close()
	end)
end)

test("Lost balance evidence or a changed Brain objective during a batch cannot keep funding", function()
	for _, mutation in ipairs({ function(scene) scene.Profile.Coins = nil end,
		function(scene) scene.Controller.Plan = { Objective = { Id = "new-blocker", Metadata = {} } } end }) do
		simulated(function(clock)
			local scene = integratedFixture() scene:SetArea("The Void")
			for _, island in ipairs(scene.Definitions["The Overworld"].Islands) do scene.Profile.AreasUnlocked[island.Name] = true end
			for index = 1, 32 do scene:Add("stale-" .. index, "Coins") end
			clock.Tick = function() if #scene.Calls > 0 then mutation(scene) end end
			scene:ExecuteFarm(scene:FundingDecision())
			assert(#scene.Calls == 1 and #scene.Teleports == 0 and #scene.Unlocks == 0)
			scene:Close()
		end)
	end
end)

print("[OC TEST] " .. tostring(tests-before) .. " integrated progression regressions passed; total=" .. tostring(tests) .. "; synthetic balances/flags only")
end

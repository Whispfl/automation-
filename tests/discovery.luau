-- Synthetic runtime capability, contacts and account updates ONLY. Never live saved-discovery proof.
do
local before = tests
local function discoveryFixture(overrides)
	local values = { WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = true, AUTO_DISCOVER_ISLANDS = true,
		AUTO_UNLOCK_WORLDS = false, MAXIMUM_WORLD_UNLOCK_COST = 0, AUTO_TRAVEL_FOR_PROGRESSION = false,
		SELECTED_WORLDS = { "The Overworld" } } }
	for category, entries in pairs(overrides or {}) do values[category] = values[category] or {} for key, value in pairs(entries) do values[category][key] = value end end
	local scene = progressionFixture(values)
	scene.Profile.AreasUnlocked, scene.Profile.Coins, scene.Profile.Gems = {}, 0, 0
	scene.Contacts = {}
	scene.Root.CanTouch = true
	local world = scene.WorldRoot:FindFirstChild("The Overworld")
	scene.Hitboxes = {}
	for _, island in ipairs(scene.Definitions["The Overworld"].Islands) do
		local model = world.Islands[island.Name].Island
		local hitbox = progressionNode("UnlockHitbox", model, "Part")
		hitbox.CanTouch, hitbox.Anchored, hitbox.Position = true, true, Vector3.new(0, island.Height, 0)
		scene.Hitboxes[island.Name] = hitbox
	end
	local oldContact, oldClose = firetouchinterest, scene.Close
	firetouchinterest = function(root, hitbox, phase)
		table.insert(scene.Contacts, { Root = root, Hitbox = hitbox, Phase = phase, At = os.clock() })
		if scene.OnContact then scene.OnContact(root, hitbox, phase) end
	end
	function scene:Decision() local plan = self:Plan() local _, decision = self.Manager:Select(plan) return decision end
	function scene:Execute(token)
		local decision = self:Decision()
		local definition = self.Manager:Definition(decision, self.Controller.Generation)
		return definition and definition.Execute(token or { CheckCancelled = function() return false end })
	end
	function scene:Close() self.Manager:Halt() firetouchinterest = oldContact oldClose(self) end
	return scene
end

test("Discovery is opt-in and validates bounded contact confirmation pacing and retries", function()
	assert(not Defaults.WORLD_SETTINGS.AUTO_DISCOVER_ISLANDS)
	for _, values in ipairs({ { ISLAND_DISCOVERY_CONTACT_SECONDS = 0 }, { ISLAND_DISCOVERY_CONTACT_SECONDS = 1 },
		{ ISLAND_DISCOVERY_CONFIRMATION_TIMEOUT_SECONDS = 0 }, { ISLAND_DISCOVERY_CONFIRMATION_TIMEOUT_SECONDS = 31 },
		{ ISLAND_DISCOVERY_INTERVAL_SECONDS = 0 }, { ISLAND_DISCOVERY_RETRY_COOLDOWN_SECONDS = 0 }, { MAXIMUM_ISLAND_DISCOVERY_ATTEMPTS = 0 } }) do
		assert(not pcall(function() requireOC("OCController").new(Resolver.Resolve(Defaults, { WORLD_SETTINGS = values })) end))
	end
end)

test("Missing or nonfunction runtime contact yields honest WAIT without movement fallback", function()
	local scene = discoveryFixture()
	for _, unavailable in ipairs({ false, {} }) do
		firetouchinterest = unavailable
		local decision = scene:Decision()
		assert(decision.Kind == "WAIT" and decision.Reason:find("unavailable", 1, true))
		assert(not scene.Manager:GetStatus().DiscoveryCapability.Available and #scene.Contacts == 0)
	end
	scene:Close()
end)

test("Fresh zero balance account selects Floating Island without inventing currency or bubble needs", function()
	local scene = discoveryFixture()
	local decision = scene:Decision()
	assert(decision.Kind == "DISCOVER_ISLAND" and decision.Node.Name == "Floating Island")
	assert(scene.Profile.Coins == 0 and scene.Profile.Gems == 0 and scene.Blows == 0 and #scene.Teleports == 0)
	assert(scene.Manager:Definition(decision, 1).Id == "OC_GAMEPLAY")
	assert(scene.Manager:GetStatus().DiscoveryCapability.SavedPersistence == "OWNER_REJOIN_TEST_REQUIRED")
	scene:Close()
end)

test("Discovery order follows native indices even if scene heights and gate affordability differ", function()
	local scene = discoveryFixture({ WORLD_SETTINGS = { SELECTED_WORLDS = {} } })
	scene.Profile.Coins, scene.Profile.AreasUnlocked.Zen = 5000, true
	for _, item in ipairs(scene.Observations.Islands) do if item.Name == "Floating Island" then item.Height = 50000 end end
	local decision = scene:Decision()
	assert(decision.Node.Name == "Floating Island" and decision.Kind == "DISCOVER_ISLAND")
	scene.Profile.AreasUnlocked["Floating Island"] = true
	assert(scene:Decision().Node.Name == "Outer Space")
	scene:Close()
end)

test("Five islands acknowledge sequentially with global pacing and unchanged position balances and bubbles", function()
	simulated(function(clock)
		local scene = discoveryFixture()
		local initial = scene.Root.Position
		scene.OnContact = function(_, hitbox, phase) if phase == 1 then scene.Profile.AreasUnlocked[hitbox.Parent.Parent.Name] = true end end -- Synthetic server update ONLY.
		for index, name in ipairs({ "Floating Island", "Outer Space", "Twilight", "The Void", "Zen" }) do
			if index > 1 then clock.Time += 10 end
			assert(scene:Decision().Node.Name == name)
			local result = scene:Execute()
			assert(result.Verified and result.Evidence.AccountAcknowledged and not result.Evidence.SavedPersistenceVerified)
			assert(scene.Contacts[index*2-1].Phase == 0 and scene.Contacts[index*2].Phase == 1)
			assert(scene.Contacts[index*2].At-scene.Contacts[index*2-1].At >= 0.099)
		end
		assert(#scene.Contacts == 10 and scene.Root.Position == initial and scene.Profile.Coins == 0 and scene.Profile.Gems == 0)
		assert(scene.Blows == 0 and #scene.Calls == 0 and #scene.Teleports == 0 and #scene.Unlocks == 0)
		assert(scene:Decision() == nil and not scene.Coordinator.Mechanics.PendingIslandContact)
		scene:Close()
	end)
end)

test("Successful contact calls without the correct LocalData flag remain unconfirmed and backed off", function()
	simulated(function(clock)
		local scene = discoveryFixture()
		local result = scene:Execute()
		assert(not result.Verified and result.Evidence.BeginSucceeded and result.Evidence.EndSucceeded and not result.Evidence.AccountAcknowledged)
		assert(result.Reason:find("not proof", 1, true) and #scene.Contacts == 2)
		assert(scene:Decision().Kind == "WAIT")
		assert(not scene.Profile.AreasUnlocked["Floating Island"])
		scene:Close()
	end)
end)

test("Wrong island acknowledgement cannot substitute for the attempted island", function()
	simulated(function()
		local scene = discoveryFixture()
		scene.OnContact = function() scene.Profile.AreasUnlocked.Zen = true end
		assert(not scene:Execute().Verified)
		assert(scene:Decision().Node.Name == "Floating Island" and #scene.Contacts == 2)
		scene:Close()
	end)
end)

test("Missing unloaded disabled hitboxes unknown maps locked origins and other worlds block contact", function()
	local scene = discoveryFixture()
	local mechanics = scene.Coordinator.Mechanics
	local node = scene:Decision().Node
	scene.Hitboxes["Floating Island"].CanTouch = false assert(not mechanics:IslandDiscovery(node))
	scene.Hitboxes["Floating Island"].CanTouch = true
	scene.Hitboxes["Floating Island"].Parent = nil assert(not mechanics:IslandDiscovery(node))
	scene.Hitboxes["Floating Island"].Parent = scene.WorldRoot["The Overworld"].Islands["Floating Island"].Island
	scene.Profile.WorldsUnlocked = {} assert(not mechanics:IslandDiscovery(node))
	scene.Profile.WorldsUnlocked = { ["The Overworld"] = true }
	scene.Profile.AreasUnlocked = nil assert(not mechanics:IslandDiscovery(node))
	scene.Profile.AreasUnlocked = {}
	scene.CurrentWorld = "Minigame Paradise" assert(not mechanics:IslandDiscovery(node))
	assert(not mechanics:IslandDiscovery({ Kind = "ISLAND", World = "Minigame Paradise", Name = "Dice Island" }))
	scene.CurrentWorld = nil scene.Root.CanTouch = false assert(not mechanics:IslandDiscovery(node))
	assert(#scene.Contacts == 0)
	scene:Close()
end)

test("Guard blocked and isolated pickup sessions never dispatch experimental discovery", function()
	local scene = discoveryFixture()
	scene.Coordinator.Mechanics.Guard = function() return false, "Trading is active" end
	assert(scene:Decision().Kind == "WAIT" and #scene.Contacts == 0)
	scene.Coordinator.Mechanics.Guard = function() return true end
	scene.Controller.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST = true
	assert(scene:Decision().Kind == "WAIT" and #scene.Contacts == 0)
	scene:Close()
end)

test("Pause between begin and end releases exactly one existing contact and prevents new work", function()
	simulated(function(clock)
		local scene = discoveryFixture()
		local token = { Cancelled = false, CheckCancelled = function(self) return self.Cancelled end }
		clock.Tick = function()
			token.Cancelled = true scene.Controller.State = "PAUSED" scene.Manager:Halt()
		end
		local result = scene:Execute(token)
		assert(not result.Verified and #scene.Contacts == 2 and scene.Contacts[1].Phase == 0 and scene.Contacts[2].Phase == 1)
		assert(not scene.Coordinator.Mechanics.PendingIslandContact)
		scene.Controller.State = "RUNNING" token.Cancelled = false
		assert(scene:Decision().Kind == "WAIT" and #scene.Contacts == 2)
		scene:Close()
	end)
end)

test("Stop during confirmation keeps bounded attempt records and cannot verify cancelled discovery", function()
	simulated(function(clock)
		local scene = discoveryFixture()
		local token = { Cancelled = false, CheckCancelled = function(self) return self.Cancelled end }
		clock.Tick = function() if clock.Time >= 0.2 then token.Cancelled = true scene.Controller.State = "STOPPED" scene.Manager:Halt() end end
		local result = scene:Execute(token)
		assert(not result.Verified and #scene.Contacts == 2 and scene.Manager:GetStatus().IslandDiscoveryAttempts["The Overworld/Floating Island"] == 1)
		scene.Controller.State = "RUNNING" token.Cancelled = false
		assert(scene:Decision().Kind == "WAIT")
		scene.Profile.AreasUnlocked["Floating Island"] = true
		clock.Time += 10
		assert(scene:Decision().Node.Name == "Outer Space" and #scene.Contacts == 2)
		scene:Close()
	end)
end)

test("Failed runtime transport attempts end cleanup once and retain per-island backoff", function()
	simulated(function()
		local scene = discoveryFixture()
		scene.OnContact = function(_, _, phase) if phase == 0 then error("Synthetic runtime unavailable") end end
		local result = scene:Execute()
		assert(not result.Verified and #scene.Contacts == 2 and scene.Contacts[2].Phase == 1)
		assert(scene:Decision().Kind == "WAIT" and not scene.Coordinator.Mechanics.PendingIslandContact)
		scene:Close()
	end)
end)

test("Contact end failure cannot claim balanced contact or account success", function()
	simulated(function()
		local scene = discoveryFixture()
		scene.OnContact = function(_, _, phase) if phase == 1 then error("Synthetic end failure") end end
		local result = scene:Execute()
		assert(not result.Verified and result.Evidence.BeginSucceeded and not result.Evidence.EndSucceeded)
		assert(#scene.Contacts == 2 and not scene.Coordinator.Mechanics.PendingIslandContact)
		scene:Close()
	end)
end)

test("Retry limit survives controls without an unbounded contact loop", function()
	simulated(function(clock)
		local scene = discoveryFixture()
		assert(not scene:Execute().Verified)
		scene.Manager:Halt() clock.Time = 31
		assert(not scene:Execute().Verified)
		scene.Manager:Halt() clock.Time = 70
		local decision = scene:Decision()
		assert(decision.Kind == "WAIT" and decision.Reason:find("attempt limit", 1, true) and #scene.Contacts == 4)
		scene:Close()
	end)
end)

test("Stale goal generation runtime identities and already-discovered flags prevent replay", function()
	local scene = discoveryFixture()
	local decision = scene:Decision()
	local definition = scene.Manager:Definition(decision, 1)
	scene.Controller.Generation = 2 assert(not definition.CanRun() and definition.Execute({ CheckCancelled = function() return false end }) == nil)
	scene.Controller.Generation = 1
	scene.Profile.AreasUnlocked["Floating Island"] = true
	assert(scene.Coordinator.Mechanics:DiscoverIsland(decision.Node, { CheckCancelled = function() return false end }))
	assert(#scene.Contacts == 0)
	scene.Profile.AreasUnlocked = {}
	scene.Controller.Plan = { Objective = { Id = "WAIT", Metadata = {} } }
	assert(not scene.Coordinator.Mechanics:DiscoverIsland(decision.Node, { CheckCancelled = function() return false end }))
	assert(#scene.Contacts == 0)
	scene:Close()
end)

test("Character replacement between guards and dispatch prevents stale contact", function()
	local scene = discoveryFixture()
	local decision = scene:Decision()
	scene.Coordinator.Mechanics.Guard = function()
		scene.Root = { Position = scene.Root.Position, Parent = true, CanTouch = true }
		return true
	end
	local result = scene.Manager:Definition(decision, 1).Execute({ CheckCancelled = function() return false end })
	assert(not result.Verified and #scene.Contacts == 0)
	scene:Close()
end)

test("Visual hitbox disappearance or balance changes are not saved island discovery", function()
	simulated(function()
		local scene = discoveryFixture()
		scene.OnContact = function(_, hitbox, phase) if phase == 1 then hitbox.Parent = nil scene.Profile.Coins = 50 end end
		local result = scene:Execute()
		assert(not result.Verified and not result.Evidence.AccountAcknowledged and not scene.Profile.AreasUnlocked["Floating Island"])
		scene:Close()
	end)
end)

test("Acknowledged islands are skipped even when prior attempts failed and runtime later vanishes", function()
	simulated(function(clock)
		local scene = discoveryFixture()
		assert(not scene:Execute().Verified)
		scene.Profile.AreasUnlocked["Floating Island"] = true
		clock.Time = 31 firetouchinterest = nil
		local decision = scene:Decision()
		assert(decision.Node.Name == "Outer Space" and decision.Kind == "WAIT" and #scene.Contacts == 2)
		scene:Close()
	end)
end)

print("[OC TEST] " .. tostring(tests-before) .. " stationary discovery regressions passed; total=" .. tostring(tests) .. "; saved persistence requires owner live rejoin testing")
end

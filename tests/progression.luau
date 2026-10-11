-- Deterministic synthetic profiles, geometry and server responses ONLY. Never live verification.
local progressionBefore = tests
local Graph = requireOC("ProgressionGraph")
local ProgressionManager = requireOC("WorldProgressionManager")
local function progressionNode(name, parent, class, attributes)
	local node = { Name = name, Parent = parent, ClassName = class or "Model", Children = {}, Attributes = attributes or {} }
	if parent and parent.Children then parent.Children[name] = node parent[name] = node end
	function node:GetAttribute(key) return self.Attributes[key] end
	function node:FindFirstChild(key) return self.Children[key] end
	function node:GetChildren() local list = {} for _, child in pairs(self.Children) do table.insert(list, child) end return list end
	function node:GetFullName() return self.Parent and self.Parent.GetFullName and self.Parent:GetFullName() .. "." .. self.Name or self.Name end
	function node:IsA(kind) return kind == self.ClassName or (kind == "BasePart" and self.ClassName == "Part") end
	function node:IsDescendantOf(target) local current = self.Parent while current do if current == target then return true end current = current.Parent end return false end
	return node
end

local function progressionFixture(overrides)
	local values = { PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = false }, WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = true,
		AUTO_FARM_UNLOCK_REQUIREMENTS = true, AUTO_UNLOCK_WORLDS = true, AUTO_TRAVEL_FOR_PROGRESSION = true,
		MAXIMUM_WORLD_UNLOCK_COST = 5000, MAXIMUM_SESSION_WORLD_UNLOCKS = 2 },
		BRAIN_SETTINGS = { ENABLE_EARNING_RECOMMENDATIONS = false, ENABLE_INVENTORY_RECOMMENDATIONS = false, ENABLE_MASTERY_RECOMMENDATIONS = false } }
	for category, settings in pairs(overrides or {}) do values[category] = values[category] or {} for key, value in pairs(settings) do values[category][key] = value end end
	local scene = stationaryFixture(values)
	scene.Controller.Farming = scene.Coordinator
	-- Small fixture costs deliberately differ from live definitions; no actual account is modified.
	scene.Definitions = {
		["The Overworld"] = { Order = 1, UnlockCost = { Type = "Currency", Currency = "Coins", Amount = 0 }, Islands = {
			{ Name = "Floating Island", Height = 450 }, { Name = "Outer Space", Height = 2500 }, { Name = "Twilight", Height = 6500 },
			{ Name = "The Void", Height = 9500 }, { Name = "Zen", Height = 15000 } } },
		["Minigame Paradise"] = { Order = 2, UnlockCost = { Type = "Currency", Currency = "Coins", Amount = 1000 }, Islands = { { Name = "Dice Island", Height = 2500 }, { Name = "Hyperwave Island", Height = 20000 } } },
		["Seven Seas"] = { Order = 3, UnlockCost = { Type = "Currency", Currency = "Coins", Amount = 2500 }, Islands = {} },
	}
	scene.Dependencies.Worlds = scene.Definitions
	scene.Dependencies.WorldUtil = { GetPlayerWorld = function() return scene.CurrentWorld or "The Overworld" end }
	local worldRoot = progressionNode("Worlds", workspace, "Folder")
	function worldRoot:GetFullName() return "Workspace.Worlds" end
	local gates, observations = {}, { Worlds = {}, Islands = {}, Upgrades = {} }
	for name, definition in pairs(scene.Definitions) do
		local world = progressionNode(name, worldRoot)
		local islands = progressionNode("Islands", world, "Folder")
		local observation = { Name = name, Order = definition.Order, Cost = definition.UnlockCost }
		table.insert(observations.Worlds, observation)
		for _, definitionIsland in ipairs(definition.Islands) do
			local island = progressionNode(definitionIsland.Name, islands, "Folder", { Height = definitionIsland.Height })
			local model = progressionNode("Island", island)
			local portal = progressionNode("Portal", model)
			local spawn = progressionNode("Spawn", portal, "Part") spawn.Position = Vector3.new(0, definitionIsland.Height + 20, 0)
			table.insert(observations.Islands, { Name = definitionIsland.Name, World = name, Height = definitionIsland.Height, TravelPath = spawn:GetFullName() })
			local destination = definitionIsland.Name == "Zen" and "Minigame Paradise" or definitionIsland.Name == "Hyperwave Island" and "Seven Seas" or nil
			if destination then
				local gate = progressionNode("Gate", model, "Model", { World = destination })
				local activation = progressionNode("Activation", gate)
				local root = progressionNode("Root", activation, "Part") root.Position = spawn.Position + Vector3.new(12, 0, 0) root.Size = Vector3.new(0.0015, 12, 11)
				gates[destination] = gate
			end
		end
	end
	for _, observation in ipairs(observations.Worlds) do
		local gate = gates[observation.Name]
		if gate then observation.Gate = { Path = gate:GetFullName(), OriginWorld = observation.Name == "Minigame Paradise" and "The Overworld" or "Minigame Paradise",
			RequiredIsland = observation.Name == "Minigame Paradise" and "Zen" or "Hyperwave Island", ActivationObserved = true } end
	end
	scene.Gates, scene.WorldRoot, scene.Observations = gates, worldRoot, observations
	local oldFind, oldTagged, oldClose = workspace.FindFirstChild, services.CollectionService.GetTagged, scene.Close
	workspace.FindFirstChild = function(_, name) return name == "Worlds" and worldRoot or nil end
	services.CollectionService.GetTagged = function(_, tag) if tag ~= "WorldGate" then return {} end local list = {} for _, gate in pairs(gates) do table.insert(list, gate) end return list end
	scene.Refreshes, scene.Unlocks = 0, {}
	scene.Dependencies.Remote.FireServer = function(_, command, target)
		if command == "UnlockWorld" then table.insert(scene.Unlocks, target) if scene.OnUnlock then scene.OnUnlock(target) end
		elseif command == "Teleport" then table.insert(scene.Teleports, target) if scene.OnTeleport then scene.OnTeleport(target) end
		else error("Unexpected Phase 3 command " .. command) end
	end
	function scene:Snapshot()
		local snapshot = { Ready = true, Revision = self.Refreshes + 1, Balances = { Coins = self.Profile.Coins, Gems = self.Profile.Gems }, Bubble = self.Profile.Bubble,
			UnlockedWorlds = type(self.Profile.WorldsUnlocked) == "table" and table.clone(self.Profile.WorldsUnlocked) or nil,
			UnlockedIslands = type(self.Profile.AreasUnlocked) == "table" and table.clone(self.Profile.AreasUnlocked) or nil,
			AvailableProgression = self.Observations, Inventory = { Pets = {}, EquippedIds = {} }, Upgrades = { MasteryLevels = {} }, TaskRequirements = {} }
		snapshot.ProgressionGraph = Graph.Build(self.Controller.Config, snapshot, self.Definitions, self.Observations)
		return snapshot
	end
	scene.Controller.Reader.GetSnapshot = function() return scene:Snapshot() end
	scene.Controller.Reader.Refresh = function() scene.Refreshes += 1 end
	scene.Manager = ProgressionManager.new(scene.Controller)
	function scene:Plan() self.Controller.Plan = self.Controller.Brain:Plan(self:Snapshot()) return self.Controller.Plan end
	function scene:AtGate(name)
		local root = self.Gates[name].Children.Activation.Children.Root
		self.Root.Position = root.Position self.CurrentWorld = name == "Minigame Paradise" and "The Overworld" or "Minigame Paradise"
	end
	function scene:Close() workspace.FindFirstChild = oldFind services.CollectionService.GetTagged = oldTagged oldClose(self) end
	return scene
end

test("Phase 3 controls default off and reject invalid retry stabilization and spending settings", function()
	assert(not Defaults.WORLD_SETTINGS.ENABLE_WORLD_PROGRESSION and not Defaults.WORLD_SETTINGS.AUTO_UNLOCK_WORLDS
		and not Defaults.WORLD_SETTINGS.AUTO_TRAVEL_FOR_PROGRESSION and Defaults.WORLD_SETTINGS.MAXIMUM_WORLD_UNLOCK_COST == 0)
	for _, override in ipairs({ { MAXIMUM_UNLOCK_ATTEMPTS = 0 }, { MAXIMUM_TRAVEL_ATTEMPTS = 1.5 },
		{ UNLOCK_RETRY_COOLDOWN_SECONDS = 0 }, { TRAVEL_STABILIZATION_SECONDS = 20 }, { MAXIMUM_WORLD_UNLOCK_COST = math.huge } }) do
		assert(not pcall(function() requireOC("OCController").new(Resolver.Resolve(Defaults, { WORLD_SETTINGS = override })) end))
	end
end)

test("Fresh account plans first undiscovered native island without assuming Void Zen Mastery or a bubble minimum", function()
	local scene = progressionFixture() scene.Profile.AreasUnlocked = {}
	local plan = scene:Plan() local node = plan.Objective.Metadata.Progression.Node
	assert(node.Name == "Floating Island" and node.State == "BLOCKED" and not node.Discovered and node.Reached == nil)
	assert(plan.Objective.Metadata.Cost == nil and not plan.Graph.Capabilities.Mastery.Available)
	local owns, decision = scene.Manager:Select(plan)
	assert(owns and decision.Kind == "WAIT" and decision.Reason:find("unverified", 1, true) and not scene.Manager:Definition(decision, 1))
	assert(#scene.Unlocks == 0 and #scene.Teleports == 0) scene:Close()
end)

test("Partial discoveries skip completed islands and expose Mastery only through actual Outer Space discovery", function()
	local scene = progressionFixture() scene.Profile.AreasUnlocked = { ["Floating Island"] = true }
	local plan = scene:Plan() assert(plan.Objective.Metadata.Progression.Node.Name == "Outer Space")
	scene.Profile.AreasUnlocked["Outer Space"] = true
	plan = scene:Plan() assert(plan.Objective.Metadata.Progression.Node.Name == "Twilight" and plan.Graph.Capabilities.Mastery.Available)
	scene:Close()
end)

test("Developed account skips earlier unlocks and completed permanent graph does not replay progression", function()
	local scene = progressionFixture({ WORLD_SETTINGS = { AUTO_UNLOCK_WORLDS = false } })
	for name, definition in pairs(scene.Definitions) do scene.Profile.WorldsUnlocked[name] = true for _, island in ipairs(definition.Islands) do scene.Profile.AreasUnlocked[island.Name] = true end end
	local plan = scene:Plan() assert(plan.Graph.Complete and plan.Graph.Next == nil and not plan.Objective.Metadata.Progression)
	assert(not scene.Manager:Select(plan) and #scene.Unlocks == 0 and #scene.Teleports == 0)
	scene.Profile.WorldsUnlocked["Seven Seas"] = nil scene.Profile.Coins = 3000
	plan = scene:Plan() assert(plan.Objective.Metadata.Progression.Node.Name == "Seven Seas")
	local owns, decision = scene.Manager:Select(plan) assert(owns and decision.Kind == "WAIT" and decision.Reason:find("AUTO_UNLOCK_WORLDS=false", 1, true))
	scene:Close()
end)

test("Native world shortage creates a stationary Coins goal and major reservation without upgrade budget inflation", function()
	local scene = progressionFixture() scene.Profile.Coins = 100
	local plan = scene:Plan() assert(plan.Objective.Metadata.Progression.State == "FUNDING" and plan.MajorUnlockReservation.Amount == 1000)
	local currency, _, deficit = Policy.Target(scene.Controller.Config, scene:Snapshot(), plan, {})
	assert(currency == "Coins" and deficit == 900 and not scene.Manager:Select(plan))
	local settings, _, _, context, memory = goalFixture()
	local decision = Policy.Decide(settings, scene:Snapshot(), plan, context, memory)
	assert(decision.Mode == "PICKUPS" and decision.PreferredIsland == "The Overworld/The Void") scene:Close()
end)

test("Native Gems cost routes to Zen and sufficient world funds stop farming even while spending is disabled", function()
	local scene = progressionFixture({ WORLD_SETTINGS = { AUTO_UNLOCK_WORLDS = false } })
	scene.Definitions["Minigame Paradise"].UnlockCost.Currency = "Gems"
	local plan = scene:Plan() local currency = Policy.Target(scene.Controller.Config, scene:Snapshot(), plan, {}) assert(currency == "Gems")
	local settings, _, _, context, memory = goalFixture()
	assert(Policy.Decide(settings, scene:Snapshot(), plan, context, memory).Island.Name == "Zen")
	scene.Profile.Gems = 1000 plan = scene:Plan()
	assert(Policy.Target(scene.Controller.Config, scene:Snapshot(), plan, {}) == nil)
	local owns, decision = scene.Manager:Select(plan) assert(owns and decision.Kind == "WAIT" and #scene.Unlocks == 0) scene:Close()
end)

test("Unknown access costs balances definitions and ambiguous gates never manufacture a farming requirement", function()
	for _, mutate in ipairs({ function(scene) scene.Profile.AreasUnlocked = nil end, function(scene) scene.Profile.WorldsUnlocked = nil end,
		function(scene) scene.Definitions = nil end, function(scene) scene.Observations.Worlds = {} end,
		function(scene) scene.Profile.Coins = nil end, function(scene) scene.Definitions["Minigame Paradise"].UnlockCost = { Type = "Currency", Currency = "Robux", Amount = 1 } end,
		function(scene) for _, world in ipairs(scene.Observations.Worlds) do if world.Gate then world.Gate.Ambiguous = true end end end }) do
		local scene = progressionFixture() mutate(scene)
		local plan = scene:Plan() assert(plan.Objective.Metadata.Cost == nil)
		local owns, decision = scene.Manager:Select(plan) assert(owns and decision.Kind == "WAIT" and #scene.Unlocks == 0) scene:Close()
	end
end)

test("Retained events excluded and target world includes observed gate-origin dependencies", function()
	local scene = progressionFixture({ WORLD_SETTINGS = { SELECTED_WORLDS = { "Seven Seas" } } })
	scene.Definitions.Seasonal = { Order = 0, Event = true, Islands = {} }
	scene.Definitions.Retired = { Order = 0, Removed = true, Islands = {} }
	local plan = scene:Plan() assert(#plan.Graph.Worlds == 3 and plan.Graph.Next.Name == "Minigame Paradise") scene:Close()
end)

test("Account reader joins cached definitions and scene observations with actual discovery flags", function()
	local scene = progressionFixture() scene.Profile.Coins = 1500
	local reader = Reader.new(scene.Controller.Config)
	reader.Dependencies.Worlds = { Status = "READY", Value = scene.Definitions }
	reader.Dependencies.LocalData = { Status = "READY", Value = { IsReady = function() return true end, Get = function() return scene.Profile end } }
	local snapshot = reader:Read() local graph = snapshot.ProgressionGraph
	assert(graph.Next.Name == "Minigame Paradise" and graph.Next.Gate.RequiredIsland == "Zen" and graph.Next.Cost.Amount == 1000)
	assert(graph.Worlds[1].Islands[5].TravelAvailable and graph.Worlds[1].Islands[5].Reached == nil)
	reader:Destroy() scene:Close()
end)

test("Verified world action requires real gate range and never uses teleport as a pickup route", function()
	local scene = progressionFixture() scene.Profile.Coins = 1500 scene:Plan()
	local mechanics = scene.Coordinator.Mechanics
	local gate = mechanics:WorldGate("Minigame Paradise") assert(gate and not gate.InRange and gate.RequiredIsland == "Zen")
	assert(not mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end }) and #scene.Unlocks == 0)
	scene:AtGate("Minigame Paradise") gate = mechanics:WorldGate("Minigame Paradise") assert(gate.InRange)
	scene.Root.Position += Vector3.new(0, 11, 0) assert(not mechanics:WorldGate("Minigame Paradise").InRange)
	scene.Profile.AreasUnlocked.Zen = nil assert(not mechanics:WorldGate("Minigame Paradise")) scene:Close()
end)

test("World unlock invocation and visual gate changes without LocalData flag are unconfirmed and backed off", function()
	simulated(function()
		local scene = progressionFixture() scene.Profile.Coins = 1500 scene:AtGate("Minigame Paradise") scene:Plan()
		local mechanics = scene.Coordinator.Mechanics
		scene.OnUnlock = function() scene.Gates["Minigame Paradise"].VisualAnimationFinished = true end
		local ok, reason, evidence = mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end })
		assert(not ok and not evidence.Verified and reason:find("unconfirmed", 1, true) and #scene.Unlocks == 1)
		assert(not mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end }) and #scene.Unlocks == 1)
		local owns, decision = scene.Manager:Select(scene.Controller.Plan) assert(owns and decision.Kind == "WAIT") scene:Close()
	end)
end)

test("Received world unlock flag verifies independently of balance timing then refreshes and reevaluates", function()
	simulated(function()
		local scene = progressionFixture() scene.Profile.Coins = 1500 scene:AtGate("Minigame Paradise") scene:Plan()
		scene.OnUnlock = function(name) scene.Profile.WorldsUnlocked[name] = true scene.Profile.Coins -= 1000 end
		local ok, _, evidence = scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end })
		assert(ok and evidence.Verified and evidence.ObservedDeduction == 1000 and scene.Refreshes == 1)
		local plan = scene:Plan() assert(plan.Objective.Id ~= "PROGRESSION:WORLD:Minigame Paradise")
		assert(not scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end }) and #scene.Unlocks == 1)
		assert(table.concat(scene.Logs, "\n"):find("LocalData.WorldsUnlocked: false -> true", 1, true)) scene:Close()
	end)
end)

test("Stale funds cost permissions goals and cancellation block unlock dispatch", function()
	for _, mutate in ipairs({ function(scene) scene.Profile.Coins = 999 end, function(scene) scene.Controller.Config.WORLD_SETTINGS.AUTO_UNLOCK_WORLDS = false end,
		function(scene) scene.Controller.Config.WORLD_SETTINGS.MAXIMUM_WORLD_UNLOCK_COST = 999 end, function(scene) scene.Controller.Plan = nil end,
		function(scene) scene.Controller.State = "PAUSED" end, function(scene) scene.Profile.WorldsUnlocked["Minigame Paradise"] = true end }) do
		local scene = progressionFixture() scene.Profile.Coins = 1500 scene:AtGate("Minigame Paradise") scene:Plan() mutate(scene)
		assert(not scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end }) and #scene.Unlocks == 0) scene:Close()
	end
	local scene = progressionFixture() scene.Profile.Coins = 1500 scene:AtGate("Minigame Paradise") scene:Plan()
	assert(not scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return true end }) and #scene.Unlocks == 0) scene:Close()
end)

test("Currency deduction alone cannot prove unlock and failed transport retains bounded uncertain request ledger", function()
	simulated(function(clock)
		local scene = progressionFixture({ WORLD_SETTINGS = { MAXIMUM_SESSION_WORLD_UNLOCKS = 3 } }) scene.Profile.Coins = 1500 scene:AtGate("Minigame Paradise") scene:Plan()
		scene.OnUnlock = function() scene.Profile.Coins -= 1000 end
		assert(not scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end }))
		clock.Time = 100 scene.Profile.Coins = 1500 scene.OnUnlock = function() error("Synthetic transport failure") end
		assert(not scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end }))
		clock.Time = 200 assert(not scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end }))
		assert(#scene.Unlocks == 2 and scene.Coordinator.Mechanics.UnlockAttempts["Minigame Paradise"] == 2) scene:Close()
	end)
end)

test("Native progression portal requires discovered origin and observed stable arrival, with no repeated travel", function()
	simulated(function(clock)
		local scene = progressionFixture() scene.Profile.Coins = 1500 scene:Plan()
		local spawn = scene.Coordinator.Mechanics:WorldGate("Minigame Paradise").Spawn
		scene.OnTeleport = function(path) assert(path == spawn:GetFullName()) scene.Root.Position = spawn.Position end
		local owns, decision = scene.Manager:Select(scene.Controller.Plan) assert(owns and decision.Kind == "TRAVEL_GATE_ISLAND")
		local definition = scene.Manager:Definition(decision, 1)
		local result = definition.Execute({ CheckCancelled = function() return false end })
		assert(result.Verified and #scene.Teleports == 1 and clock.Time >= 1)
		scene:Plan() owns, decision = scene.Manager:Select(scene.Controller.Plan) assert(owns and decision.Kind == "WAIT" and decision.Reason:find("manual gate approach", 1, true))
		assert(not scene.Manager:Definition(decision, 1)) scene:Close()
	end)
end)

test("Failed progression travel bounded across resumes and already discovered native islands never bypass access", function()
	simulated(function(clock)
		local scene = progressionFixture() scene.Profile.Coins = 1500 scene:Plan()
		local _, decision = scene.Manager:Select(scene.Controller.Plan)
		local result = scene.Manager:Definition(decision, 1).Execute({ CheckCancelled = function() return false end })
		assert(not result.Verified and scene.Manager.TravelFailures["Minigame Paradise"] == 1)
		local owns, wait = scene.Manager:Select(scene.Controller.Plan) assert(owns and wait.Kind == "WAIT" and #scene.Teleports == 1)
		clock.Time = 100 _, decision = scene.Manager:Select(scene.Controller.Plan)
		scene.Manager:Definition(decision, 1).Execute({ CheckCancelled = function() return false end })
		clock.Time = 200 _, wait = scene.Manager:Select(scene.Controller.Plan) assert(wait.Kind == "WAIT" and #scene.Teleports == 2)
		scene.Profile.AreasUnlocked.Zen = nil
		assert(not scene.Coordinator.Mechanics:TravelForProgression("Minigame Paradise", { CheckCancelled = function() return false end }) and #scene.Teleports == 2) scene:Close()
	end)
end)

test("Same scheduler lease cancels progression on Pause and stale generations cannot dispatch after Resume or Stop", function()
	local scene = progressionFixture() scene.Profile.Coins = 1500 scene:AtGate("Minigame Paradise") local plan = scene:Plan()
	local owns, decision = scene.Manager:Select(plan) assert(owns and decision.Kind == "UNLOCK_WORLD")
	local definition = scene.Manager:Definition(decision, 1) assert(definition.Id == "OC_GAMEPLAY" and definition.Owner == "WORLD_PROGRESSION")
	local scheduler = Scheduler.new(scene.Controller.Config.TASK_SETTINGS) scheduler:Resume() scheduler:Submit(definition) scheduler:Pause() flush()
	assert(#scene.Unlocks == 0 and scheduler.Active == nil)
	scene.Controller.Generation = 2 scene.Controller.State = "RUNNING" assert(not definition.CanRun() and definition.Execute({ CheckCancelled = function() return false end }) == nil)
	scene.Controller.State = "STOPPED" assert(not definition.CanRun())
	scheduler:Destroy() scene:Close()
end)

test("Pause during unlock confirmation stops waiting and Resume observes late acknowledgement without resending", function()
	simulated(function(clock)
		local scene = progressionFixture() scene.Profile.Coins = 1500 scene:AtGate("Minigame Paradise") scene:Plan()
		local cancelled = false clock.Tick = function() cancelled = true end
		local ok = scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return cancelled end })
		assert(not ok and #scene.Unlocks == 1 and scene.Coordinator.Mechanics.SessionUnlockRequests == 1)
		scene.Profile.WorldsUnlocked["Minigame Paradise"] = true scene:Plan()
		assert(not scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end }) and #scene.Unlocks == 1) scene:Close()
	end)
end)

test("Phase 3 funding retains approved 32-ID stationary cleanup credit and no background bubbles", function()
	simulated(function()
		local scene = progressionFixture() scene.Profile.Coins = 100 local plan = scene:Plan()
		assert(not scene.Manager:Select(plan))
		for index = 1, 40 do scene:Add("phase3-id-" .. index, index % 2 == 0 and "Coins" or "Gems", 1000) end
		scene.OnDispatch = function() scene.Profile.Coins += 1 scene.Profile.Gems += 1 end
		local position = scene.Root.Position local result = scene:Collect()
		assert(result.Verified and #scene.Calls == 32 and #scene.Removed == 32 and #scene.Teleports == 0 and scene.Blows == 0 and scene.Root.Position == position)
		scene:Close()
	end)
end)

test("Native unlock panel exception is exact and cannot authorize trading prompts other worlds or WorldMap", function()
	local scene = progressionFixture() scene.Profile.Coins = 1500 scene:AtGate("Minigame Paradise") scene:Plan()
	local mechanics = scene.Coordinator.Mechanics mechanics.Guard = Mechanics.Guard
	local player = progressionNode("Player", nil)
	local gui = progressionNode("PlayerGui", player)
	local screen = progressionNode("ScreenGui", gui)
	local unlock = progressionNode("Unlock", screen) local frame = progressionNode("Frame", unlock) local top = progressionNode("Top", frame)
	local label = progressionNode("Label", top) label.Text = "World 2"
	mechanics.Player = player
	scene.Dependencies.IsTradingPlaza = function() return false end
	scene.Dependencies.FishingPlayerRods = { GetRodComponent = function() return nil end }
	local map = false
	scene.Dependencies.GuiFrame = { IsAnyOpen = function() return true end, IsOpen = function(_, name) return name == "Unlock" or (name == "WorldMap" and map) end }
	assert(not mechanics:Guard() and mechanics:Guard("World 2"))
	label.Text = "World 3" assert(not mechanics:Guard("World 2")) label.Text = "World 2"
	map = true assert(not mechanics:Guard("World 2")) map = false
	local prompt = progressionNode("Prompt", screen) assert(not mechanics:Guard("World 2")) screen.Children.Prompt = nil prompt.Parent = nil
	player.Attributes.InRace = true assert(not mechanics:Guard("World 2")) scene:Close()
end)

test("Major native unlock reserve prevents unrelated upgrade spending even when other goal reservations are disabled", function()
	local scene = progressionFixture({ BUBBLE_SETTINGS = { AUTO_BUY_GUM = true }, UPGRADE_SETTINGS = {
		ENABLE_SMART_UPGRADES = true, ENABLE_CAPACITY_UPGRADES = true, ENABLE_GOAL_RESERVATION = false, MAXIMUM_PURCHASE_COST = 1000 } })
	scene.Profile.Coins = 1500 scene.Profile.Gum = {}
	scene.Dependencies.Gum = { SyntheticUpgrade = { Cost = { Type = "Currency", Currency = "Coins", Amount = 200 }, Storage = 1000 } }
	local plan = scene:Plan() assert(plan.MajorUnlockReservation.Amount == 1000)
	local ok, reason = scene.Coordinator.Mechanics:Upgrade({ Name = "SyntheticUpgrade", Kind = "Gum" }, { CheckCancelled = function() return false end })
	assert(not ok and reason:find("reserve", 1, true) and scene.Profile.Coins == 1500 and #scene.Unlocks == 0)
	scene:Close()
end)

test("Pending pickup cleanup and saved sell return remain with the approved Phase 2 path before world travel", function()
	local scene = progressionFixture() scene.Profile.Coins = 1500 local plan = scene:Plan()
	scene.Coordinator.Mechanics.PendingPickupCleanup = { Reason = "Synthetic pending cleanup" }
	assert(not scene.Manager:Select(plan) and #scene.Teleports == 0 and #scene.Unlocks == 0)
	scene.Coordinator.Mechanics.PendingPickupCleanup = nil scene.Coordinator.ReturnKey = scene.Area.Key
	assert(not scene.Manager:Select(plan) and #scene.Teleports == 0) scene:Close()
end)

test("Session unlock ceiling and global native travel cooldown cannot be reset by manager control cleanup", function()
	local scene = progressionFixture({ WORLD_SETTINGS = { MAXIMUM_SESSION_WORLD_UNLOCKS = 1 } }) scene.Profile.Coins = 1500 local plan = scene:Plan()
	scene.Coordinator.Mechanics.LastTravelAt = os.clock()
	local owns, decision = scene.Manager:Select(plan) assert(owns and decision.Kind == "WAIT" and decision.Reason:find("backoff", 1, true))
	scene.Coordinator.Mechanics.SessionUnlockRequests = 1 scene.Manager:Halt()
	owns, decision = scene.Manager:Select(plan) assert(owns and decision.Kind == "WAIT" and decision.Reason:find("lifetime", 1, true))
	assert(#scene.Teleports == 0 and #scene.Unlocks == 0) scene:Close()
end)

test("Server-only native portal destinations reuse existing island-zone arrival evidence without local Spawn", function()
	simulated(function(clock)
		local scene = progressionFixture() scene.Profile.Coins = 1500 scene:Plan()
		local gate = scene.Gates["Minigame Paradise"]
		local portal = gate.Parent.Children.Portal local spawn = portal.Children.Spawn
		portal.Children.Spawn = nil spawn.Parent = nil
		local center = Vector3.new(0, 15020, 0)
		local zoneRoot = progressionNode("PickupZone", gate.Parent, "Part") zoneRoot.Position = center
		scene.Coordinator.Tracker.Areas["The Overworld/Zen"] = { CatalogKnown = true,
			DestinationPath = "Workspace.Worlds.The Overworld.Islands.Zen.Island.Portal.Spawn",
			Zones = { { Root = zoneRoot, Data = { Zone = { Height = center.Y, GetDistanceToPoint = function(_, position) return (position - center).Magnitude end } } } } }
		scene.OnTeleport = function(path) assert(path == "Workspace.Worlds.The Overworld.Islands.Zen.Island.Portal.Spawn") scene.Root.Position = center end
		local owns, decision = scene.Manager:Select(scene.Controller.Plan) assert(owns and decision.Kind == "TRAVEL_GATE_ISLAND")
		local result = scene.Manager:Definition(decision, 1).Execute({ CheckCancelled = function() return false end })
		assert(result.Verified and #scene.Teleports == 1 and clock.Time >= 1 and not scene.Coordinator.Mechanics:WorldGate("Minigame Paradise").Spawn)
		scene:Close()
	end)
end)

test("Missing native arrival geometry blocks progression portal requests even with actual discovery", function()
	local scene = progressionFixture() scene.Profile.Coins = 1500 scene:Plan()
	local portal = scene.Gates["Minigame Paradise"].Parent.Children.Portal portal.Children.Spawn = nil
	local owns, decision = scene.Manager:Select(scene.Controller.Plan)
	assert(owns and decision.Kind == "WAIT" and decision.Reason:find("arrival geometry", 1, true) and #scene.Teleports == 0)
	scene:Close()
end)

print(string.format("[OC TEST] %d Phase 3 progression regressions passed; %d total. Synthetic tests are not live unlock/traversal verification.", tests - progressionBefore, tests))

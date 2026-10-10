-- Synthetic stationary request/credit experiments. Never evidence of live server acceptance.
local stationaryBefore = tests
local function stationaryFixture(overrides)
	local values = { GENERAL_SETTINGS = { AUTO_START = false }, STATUS_UI_SETTINGS = { ENABLE_STATUS_UI = false },
		BRAIN_SETTINGS = { SELECTED_WORLDS = { "The Overworld" } }, FARMING_SETTINGS = { FARMING_STRATEGY = "PICKUP_FIRST" },
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false },
		UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false } }
	for category, settings in pairs(overrides or {}) do values[category] = values[category] or {} for key, value in pairs(settings) do values[category][key] = value end end
	local settings = Resolver.Resolve(Defaults, values)
	local scene = { Registry = {}, Calls = {}, Logs = {}, Blows = 0 }
	scene.Profile = { Coins = 100, Gems = 50, Bubble = { Amount = 0 }, WorldsUnlocked = { ["The Overworld"] = true }, AreasUnlocked = { ["The Void"] = true, Zen = true } }
	scene.Area = { Name = "The Void", World = "The Overworld", Key = "The Overworld/The Void", Unlocked = true, Currencies = { Coins = true, Gems = true } }
	scene.Root = { Position = Vector3.new(0, 9500, 0), Parent = true }
	local dependencies = { Tutorial = { _activePickups = scene.Registry }, StatsUtil = { GetPickupRange = function() return 10 end },
		Remote = { FireServer = function(_, command) assert(command == "BlowBubble") scene.Blows += 1 scene.Profile.Bubble.Amount += 10 end } }
	local reader = { GetLiveProfile = function() return scene.Profile end, ReadBalances = function() return { Coins = scene.Profile.Coins, Gems = scene.Profile.Gems } end,
		GetSnapshot = function() return { Ready = true } end, _dependency = function(_, name) return dependencies[name] end, _stat = function() return 100 end }
	scene.Controller = { Config = settings, Reader = reader, Generation = 1, State = "RUNNING", Log = function(_, tag, message) table.insert(scene.Logs, tag .. " " .. message) end }
	scene.Controller.Brain = Brain.new(settings)
	scene.Coordinator = requireOC("FarmingCoordinator").new(scene.Controller, {})
	local tracker, mechanics = scene.Coordinator.Tracker, scene.Coordinator.Mechanics
	tracker.Root = function() return scene.Root end tracker.Current = scene.Area tracker.Refresh = function() end
	tracker.LastZoneRefresh = 0 tracker.Areas[scene.Area.Key] = scene.Area
	mechanics.Guard = function() return true, nil, scene.Root end
	local previousFind = services.ReplicatedStorage.FindFirstChild
	local remote = { IsA = function(_, kind) return kind == "RemoteEvent" end, FireServer = function(_, id)
		table.insert(scene.Calls, { Id = id, At = os.clock() }) if scene.OnDispatch then scene.OnDispatch(id) end
	end }
	services.ReplicatedStorage.FindFirstChild = function(_, name)
		return name == "Remotes" and { FindFirstChild = function(_, pickupName)
			return pickupName == "Pickups" and { FindFirstChild = function(_, remoteName) return remoteName == "CollectPickup" and remote end } or nil
		end } or nil
	end
	function scene:Add(id, currency, distance)
		local model = { Name = id, Parent = true, Position = scene.Root.Position + Vector3.new(distance or 40, 0, 0),
			IsA = function(_, kind) return kind == "Model" end, IsDescendantOf = function(self) return self.Parent ~= nil end,
			GetPivot = function(self) return { Position = self.Position } end, Destroy = function() error("OC must not destroy pickups") end }
		local record = { Id = id, RegistryKey = id, IdSource = "NATIVE_ACTIVE_REGISTRY", Model = model, Currency = currency or "Coins", Amount = 10,
			Position = model.Position, AreaKey = scene.Area.Key, FirstSeenAt = os.clock() }
		scene.Registry[id], tracker.Models[model] = model, record
		return record
	end
	function scene:Decision(mode)
		return { Kind = "FARM", Mode = mode or "PICKUPS", Currency = "Coins", Cluster = tracker:Cluster("Coins") }
	end
	function scene:Collect(token, mode) return scene.Coordinator:_collection(self:Decision(mode), token or { CheckCancelled = function() return false end }) end
	function scene:Close() services.ReplicatedStorage.FindFirstChild = previousFind self.Coordinator:Destroy() end
	return scene
end

test("Production defaults enforce stationary-only isolation and legacy routing cannot reactivate walking", function()
	local settings = Resolver.Resolve(Defaults)
	assert(settings.PICKUP_SETTINGS.COLLECTION_METHOD == "STATIONARY_EXPERIMENT" and settings.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST)
	assert(not settings.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND and not settings.ISLAND_SETTINGS.AUTO_EXPLORE_UNLOCKED_ISLANDS)
	assert(table.concat(settings.ISLAND_SETTINGS.SELECTED_ISLANDS, ",") == "The Void,Zen")
	assert(not Resolver.Resolve(Defaults, { PICKUP_SETTINGS = { ENABLE_CLUSTER_ROUTING = true } }).PICKUP_SETTINGS.ENABLE_CLUSTER_ROUTING)
	assert(not pcall(function() Resolver.Resolve(Defaults, { PICKUP_SETTINGS = { COLLECTION_METHOD = "MOVEMENT" } }) end))
	local mechanics = Mechanics.new(settings, {}, {}, {})
	assert(not mechanics:Walk(Vector3.new(999, 0, 0))) mechanics:StopMovement()
end)

test("Stationary limits reject NaN infinity flooding budgets and excessive retries", function()
	for key, value in pairs({ STATIONARY_REQUEST_COOLDOWN_SECONDS = 0, STATIONARY_ID_RETRY_SECONDS = 0, STATIONARY_MAXIMUM_REQUESTS = 25,
		STATIONARY_MAXIMUM_ATTEMPTS_PER_ID = 3, STATIONARY_TEST_DURATION_SECONDS = 121, STATIONARY_MAXIMUM_DRIFT_STUDS = math.huge }) do
		assert(not pcall(function() Resolver.Resolve(Defaults, { PICKUP_SETTINGS = { [key] = value } }) end))
	end
	assert(not pcall(function() Resolver.Resolve(Defaults, { PICKUP_SETTINGS = { STATIONARY_REQUEST_COOLDOWN_SECONDS = 0/0 } }) end))
end)

test("Genuine stationary ID is dispatched once without Model or registry mutation", function()
	simulated(function()
		local scene = stationaryFixture() local record = scene:Add("live-one", "Coins", 60)
		local initial = scene.Root.Position local result = scene:Collect()
		assert(not result.Verified and #scene.Calls == 1 and scene.Calls[1].Id == "live-one")
		assert(record.Model.Parent and scene.Registry["live-one"] == record.Model and scene.Root.Position == initial)
		assert(scene.Coordinator.Stationary.LastResult.OutsideNativeRange and scene.Coordinator.Stationary.UncreditedWindows == 1)
		assert(scene.Coordinator:GetStatus().Stationary.MovementFallback == false)
		scene:Close()
	end)
end)

test("Actual matching LocalData credit works without visual disappearance but attribution remains unproven", function()
	simulated(function(clock)
		local scene = stationaryFixture() local record = scene:Add("credited", "Gems", 40)
		clock.Tick = function() if clock.Time >= 0.2 then scene.Profile.Gems = 65 end end
		local result = scene:Collect()
		assert(result.Verified and result.Gains.Gems == 15 and record.Model.Parent and scene.Registry.credited == record.Model)
		assert(scene.Coordinator.Stationary.LastResult.Attribution:find("UNPROVEN", 1, true))
		clock.Time = 20 assert(not scene:Collect().Verified and #scene.Calls == 1, "Observed-credit IDs are not retried")
		scene:Close()
	end)
end)

test("Native Model removal and successful invocation without balances are never credit", function()
	simulated(function()
		local scene = stationaryFixture() local record = scene:Add("removed")
		scene.OnDispatch = function() record.Model.Parent = nil scene.Registry.removed = nil end -- Simulated native removal, never OC destruction.
		assert(not scene:Collect().Verified and scene.Coordinator.Metrics.ConfirmedCycles == 0)
		scene:Close()
	end)
end)

test("Missing matching currency gain cannot be substituted with another currency", function()
	simulated(function()
		local scene = stationaryFixture() scene:Add("coin-id", "Coins")
		scene.OnDispatch = function() scene.Profile.Gems += 15 end
		assert(not scene:Collect().Verified) scene:Close()
	end)
end)

test("Global cooldown and per-ID retry exhaustion prevent repeated remote attempts", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("retry")
		assert(not scene:Collect().Verified and #scene.Calls == 1)
		clock.Time = 2 assert(not scene:Collect().Verified and #scene.Calls == 1)
		clock.Time = 10 assert(not scene:Collect().Verified and #scene.Calls == 1)
		clock.Time = 15 assert(not scene:Collect().Verified and #scene.Calls == 2)
		clock.Time = 40 assert(not scene:Collect().Verified and #scene.Calls == 2)
		assert(scene.Coordinator.Stationary.PerId.retry.Attempts == 2) scene:Close()
	end)
end)

test("New genuine spawned IDs participate continuously without clearing retry history", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("old") scene:Collect()
		clock.Time = 5 local fresh = scene:Add("new", "Gems") scene:Collect()
		assert(#scene.Calls == 2 and scene.Calls[2].Id == "new" and scene.Coordinator.Stationary.PerId.old.Attempts == 1)
		assert(scene.Registry.new == fresh.Model) scene:Close()
	end)
end)

test("Experiment session request cap and time expiry never enable another collection strategy", function()
	for _, settings in ipairs({ { STATIONARY_MAXIMUM_REQUESTS = 1 }, { STATIONARY_TEST_DURATION_SECONDS = 1 } }) do
		simulated(function(clock)
			local scene = stationaryFixture({ PICKUP_SETTINGS = settings }) scene:Add("first") scene:Collect()
			clock.Time = 20 scene:Add("second") assert(not scene:Collect().Verified and #scene.Calls == 1)
			assert(scene.Coordinator.Stationary:LimitReason():find("no movement fallback", 1, true)) scene:Close()
		end)
	end
end)

test("Changed missing unloaded or conflicting registry entries cannot dispatch", function()
	for _, mutate in ipairs({ function(scene, record) scene.Registry[record.Id] = nil end,
		function(_, record) record.Model.Name = "different" end, function(_, record) record.Model.Parent = nil end,
		function(scene, record) scene.Registry[record.Id] = {} end }) do
		simulated(function()
			local scene = stationaryFixture() local record = scene:Add("stale")
			local decision = scene:Decision() mutate(scene, record)
			assert(not scene.Coordinator:_collection(decision, { CheckCancelled = function() return false end }).Verified and #scene.Calls == 0)
			scene:Close()
		end)
	end
end)

test("Classified Chunker-only objects cannot invent a native registry collection ID", function()
	simulated(function()
		local scene = stationaryFixture() local record = scene:Add("chunk-only")
		record.IdSource = "NATIVE_CHUNKER_MODEL" scene.Registry[record.Id] = nil
		assert(not scene:Collect().Verified and #scene.Calls == 0) scene:Close()
	end)
end)

test("Actual LocalData unlocks and hard Void Zen world scope are rechecked at dispatch", function()
	for _, mutate in ipairs({ function(scene) scene.Profile.AreasUnlocked["The Void"] = nil end,
		function(scene) scene.Profile.WorldsUnlocked["The Overworld"] = nil end,
		function(scene) scene.Area.Name = "Floating Island" end, function(scene) scene.Area.World = "Other World" end }) do
		simulated(function()
			local scene = stationaryFixture() local record = scene:Add("scope") local decision = scene:Decision() mutate(scene)
			assert(not scene.Coordinator:_collection(decision, { CheckCancelled = function() return false end }).Verified and #scene.Calls == 0)
			scene:Close()
		end)
	end
end)

test("Zen is an eligible stationary island only after real unlock confirmation", function()
	simulated(function()
		local scene = stationaryFixture() scene.Area.Name, scene.Area.Key = "Zen", "The Overworld/Zen" scene:Add("zen")
		scene:Collect() assert(#scene.Calls == 1) scene:Close()
	end)
end)

test("Outside-range probing is separately disabled without repositioning", function()
	simulated(function()
		local scene = stationaryFixture({ PICKUP_SETTINGS = { STATIONARY_ALLOW_OUTSIDE_NATIVE_RANGE = false } }) scene:Add("far", "Coins", 50)
		assert(not scene:Collect().Verified and #scene.Calls == 0)
		scene:Add("near", "Gems", 5) -- Move neither the player nor any existing Model.
		scene.Coordinator.Tracker.Models[scene.Registry.far] = nil
		scene:Collect() assert(#scene.Calls == 1 and scene.Calls[1].Id == "near") scene:Close()
	end)
end)

test("Unavailable LocalData refuses dispatch and cannot fabricate balances", function()
	simulated(function()
		local scene = stationaryFixture() scene:Add("unknown") scene.Profile.Gems = nil
		assert(not scene:Collect().Verified and #scene.Calls == 0) scene:Close()
	end)
end)

test("Position drift invalidates positive credit and prevents any later requests", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("drift")
		clock.Tick = function() scene.Root.Position = scene.Root.Position + Vector3.new(1, 0, 0) scene.Profile.Coins += 10 end
		assert(not scene:Collect().Verified and scene.Coordinator.Stationary.Invalidated)
		clock.Tick = nil clock.Time = 20 scene:Add("later") assert(not scene:Collect().Verified and #scene.Calls == 1) scene:Close()
	end)
end)

test("Intermediate spending or bubble sale contaminates later positive stationary credit", function()
	for _, sale in ipairs({ false, true }) do
		simulated(function(clock)
			local scene = stationaryFixture() scene:Add("contaminated") scene.Profile.Bubble.Amount = 100
			clock.Tick = function()
				if sale then scene.Profile.Bubble.Amount = 0 scene.Profile.Coins = 125
				elseif clock.Time < 0.2 then scene.Profile.Coins = 90 else scene.Profile.Coins = 125 end
			end
			assert(not scene:Collect().Verified and scene.Coordinator.Stationary.LastResult.Contaminated) scene:Close()
		end)
	end
end)

test("Cancellation after fresh guards prevents a stale stationary remote invocation", function()
	simulated(function()
		local scene = stationaryFixture() scene:Add("cancelled") local cancelled = false
		scene.Coordinator.Mechanics.Guard = function() cancelled = true return true, nil, scene.Root end
		assert(not scene:Collect({ CheckCancelled = function() return cancelled end }).Verified and #scene.Calls == 0)
		scene:Close()
	end)
end)

test("Pause and Stop cancel scheduled stationary windows and preserve attempt budgets", function()
	for _, control in ipairs({ "Pause", "Stop" }) do
		simulated(function(clock)
			local scene = stationaryFixture() scene:Add("scheduled")
			local scheduler = Scheduler.new(scene.Controller.Config.TASK_SETTINGS) scheduler:Resume()
			clock.Tick = function() scheduler[control](scheduler) scene.Controller.State = "PAUSED" scene.Coordinator:Halt(true) end
			scheduler:Submit(scene.Coordinator:Definition(scene:Decision(), 1)) flush()
			assert(#scene.Calls == 1 and scheduler.Active == nil and scene.Coordinator.Stationary.Requests == 1)
			assert(scene.Coordinator.Stationary.LastResult.Cancelled and scene.Coordinator.Metrics.ConfirmedCycles == 0)
			clock.Tick = nil clock.Time = 5 scene.Controller.State = "RUNNING" scene:Add("new")
			scheduler:Submit(scene.Coordinator:Definition(scene:Decision(), 1)) flush() assert(#scene.Calls == 1)
			scheduler:Destroy() scene:Close()
		end)
	end
end)

test("Isolated scheduler execution rejects stale travel sell bubble upgrade and combined tasks", function()
	simulated(function()
		local scene = stationaryFixture() scene:Add("only")
		for _, decision in ipairs({ { Kind = "TRAVEL" }, { Kind = "SELL" }, { Kind = "UPGRADE" }, { Kind = "FARM", Mode = "BUBBLES" }, scene:Decision("COMBINED") }) do
			local result = scene.Coordinator:Definition(decision, 1).Execute({ CheckCancelled = function() return false end }) assert(not result.Verified)
		end
		assert(scene.Coordinator:_background({ CheckCancelled = function() return false end }) == false and #scene.Calls == 0 and scene.Blows == 0)
		scene:Close()
	end)
end)

test("Full bubbles do not schedule selling or travel during isolated stationary observation", function()
	local data, context, plan, memory = policyFixture()
	context.Current = { Key = "The Overworld/The Void", Name = "The Void", World = "The Overworld", Unlocked = true }
	context.Cluster.AreaKey = context.Current.Key data.Bubble.Amount = data.Bubble.Capacity
	local selected = Resolver.Resolve(Defaults, { BRAIN_SETTINGS = { SELECTED_WORLDS = { "The Overworld" } } })
	assert(Policy.Decide(selected, data, plan, context, memory).Mode == "PICKUPS")
	context.Cluster = nil assert(Policy.Decide(selected, data, plan, context, memory).Kind == "INSPECT")
	context.Current.Name = "Floating Island" assert(Policy.Decide(selected, data, plan, context, memory).Kind == "WAIT")
end)

test("Cooperative bubbles share stationary task lease only when isolation is disabled", function()
	simulated(function(clock)
		local scene = stationaryFixture({ PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = false },
			BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = true, ENABLE_SIMULTANEOUS_BLOWING = true } })
		scene:Add("combined") scene.Coordinator.Mechanics.CanBlow = function() return true end
		scene.Coordinator:_beginCombined(scene.Area.Key)
		clock.Tick = function() if clock.Time >= 0.5 then scene.Profile.Coins = 115 end end
		local initial = scene.Root.Position local result = scene:Collect(nil, "COMBINED")
		assert(result.CombinedCreditObserved and scene.Blows > 0 and scene.Profile.Bubble.Amount > 0 and #scene.Calls == 1 and scene.Root.Position == initial)
		assert(scene.Coordinator.Cycle.GrowthAt and scene.Coordinator.Cycle.PickupAt)
		assert(scene.Coordinator:_pickupRates(scene.Area.Key, clock.Time).COMBINED == nil)
		scene:Close()
	end)
end)

test("Stationary snapshot observations cannot double count explicit credit samples", function()
	local metrics = requireOC("ResourceMetrics").new(config().FARMING_SETTINGS)
	metrics:SetMode("STATIONARY", "A", { Coins = 100 }, 0)
	metrics:Observe({ Coins = 120 }, 3) assert(#metrics.Samples == 0)
	metrics:AddSample("STATIONARY", "A", { Coins = 20 }, 3, 3)
	assert(#metrics.Samples == 1 and metrics.Samples[1].Gains.Coins == 20)
end)

test("Actual Brain context selects one stationary scheduled request without automatic travel", function()
	simulated(function()
		local scene = stationaryFixture() scene:Add("brain-id", "Gems")
		scene.OnDispatch = function() scene.Profile.Gems += 15 end
		local decision = scene.Coordinator:Select({ Candidates = {} })
		assert(decision.Kind == "FARM" and decision.Mode == "PICKUPS")
		local scheduler = Scheduler.new(scene.Controller.Config.TASK_SETTINGS) scheduler:Resume()
		scheduler:Submit(scene.Coordinator:Definition(decision, 1)) flush()
		assert(#scene.Calls == 1 and scene.Coordinator.Metrics.ConfirmedCycles == 1 and scheduler.Active == nil)
		scheduler:Destroy() scene:Close()
	end)
end)

test("Invocation errors consume the bounded attempt without fabricating credit", function()
	simulated(function()
		local scene = stationaryFixture() scene:Add("error-id") scene.OnDispatch = function() error("Simulated transport failure") end
		assert(not scene:Collect().Verified and #scene.Calls == 1 and scene.Coordinator.Stationary.Requests == 1)
		assert(not scene.Coordinator.Stationary.LastResult.InvocationSucceeded) scene:Close()
	end)
end)

print(string.format("[OC TEST] %d stationary-only regressions passed; %d total. Actual server credit awaits owner testing.", tests - stationaryBefore, tests))

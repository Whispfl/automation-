-- Synthetic stationary request/credit experiments. Never evidence of live server acceptance.
local stationaryBefore = tests
local function stationaryFixture(overrides)
	local values = { GENERAL_SETTINGS = { AUTO_START = false }, STATUS_UI_SETTINGS = { ENABLE_STATUS_UI = false },
		PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = true },
		ISLAND_SETTINGS = { AUTO_SELECT_BEST_ISLAND = false, AUTO_TRAVEL_BEST_ISLAND = false },
		BRAIN_SETTINGS = { SELECTED_WORLDS = { "The Overworld" } }, FARMING_SETTINGS = { FARMING_STRATEGY = "PICKUP_FIRST" },
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false },
		UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false } }
	for category, settings in pairs(overrides or {}) do values[category] = values[category] or {} for key, value in pairs(settings) do values[category][key] = value end end
	local settings = Resolver.Resolve(Defaults, values)
	local scene = { Registry = {}, Calls = {}, Logs = {}, Blows = 0, Teleports = {}, Removed = {}, Folder = {} }
	scene.Profile = { Coins = 100, Gems = 50, Bubble = { Amount = 0 }, WorldsUnlocked = { ["The Overworld"] = true }, AreasUnlocked = { ["The Void"] = true, Zen = true } }
	scene.Area = { Name = "The Void", World = "The Overworld", Key = "The Overworld/The Void", Unlocked = true, Currencies = { Coins = true, Gems = true } }
	scene.Root = { Position = Vector3.new(0, 9500, 0), Parent = true }
	local dependencies = { Tutorial = { _activePickups = scene.Registry }, StatsUtil = { GetPickupRange = function() return 10 end },
		Remote = { FireServer = function(_, command, destination)
			if command == "Teleport" then table.insert(scene.Teleports, destination) if scene.OnTeleport then scene.OnTeleport(destination) end
			else assert(command == "BlowBubble") scene.Blows += 1 scene.Profile.Bubble.Amount += 10 end
		end } }
	local reader = { GetLiveProfile = function() return scene.Profile end, ReadBalances = function() return { Coins = scene.Profile.Coins, Gems = scene.Profile.Gems } end,
		GetSnapshot = function() return { Ready = true } end, _dependency = function(_, name) return dependencies[name] end, _stat = function() return 100 end }
	scene.Controller = { Config = settings, Reader = reader, Generation = 1, State = "RUNNING", Log = function(_, tag, message) table.insert(scene.Logs, tag .. " " .. message) end }
	scene.Controller.Brain = Brain.new(settings)
	scene.Coordinator = requireOC("FarmingCoordinator").new(scene.Controller, {})
	local tracker, mechanics = scene.Coordinator.Tracker, scene.Coordinator.Mechanics
	scene.Dependencies = dependencies
	scene.Chunker = { _folder = scene.Folder, Members = {}, Hidden = {}, IsValueLoaded = function(self, model) return self.Members[model] == true and not self.Hidden[model] end,
		Remove = function(self, _, model)
			if scene.RemoveError then error("Simulated native Remove failure") end
			self.Members[model] = nil table.insert(scene.Removed, model)
			self.Hidden[model] = nil
			if scene.Registry[model.Name] == model then scene.Registry[model.Name] = nil end
		end }
	scene.Coordinator.Knowledge.NativePickupChunker = scene.Chunker
	tracker.ModelIds = {}
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
		local model = { Name = id, Parent = scene.Folder, Position = scene.Root.Position + Vector3.new(distance or 40, 0, 0),
			IsA = function(_, kind) return kind == "Model" end, IsDescendantOf = function(self) return self.Parent ~= nil end,
			GetPivot = function(self) return { Position = self.Position } end, Destroy = function(self)
				if scene.DestroyError then error("Simulated visual destruction failure") end
				self.Destroyed, self.Parent = true, nil
			end }
		local record = { Id = id, RegistryKey = id, IdSource = "NATIVE_ACTIVE_REGISTRY", Model = model, Currency = currency or "Coins", Amount = 10,
			Position = model.Position, AreaKey = scene.Area.Key, FirstSeenAt = os.clock() }
		scene.Registry[id], tracker.Models[model] = model, record
		scene.Chunker.Members[model] = true
		return record
	end
	function scene:Decision(mode)
		return { Kind = "FARM", Mode = mode or "PICKUPS", Currency = "Coins", Cluster = tracker:Cluster("Coins") }
	end
	function scene:Collect(token, mode) return scene.Coordinator:_collection(self:Decision(mode), token or { CheckCancelled = function() return false end }) end
	function scene:Close() services.ReplicatedStorage.FindFirstChild = previousFind self.Coordinator:Destroy() end
	return scene
end

test("Production defaults enforce stationary-only collection and legacy routing cannot reactivate walking", function()
	local settings = Resolver.Resolve(Defaults)
	assert(settings.PICKUP_SETTINGS.COLLECTION_METHOD == "STATIONARY" and not settings.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST)
	assert(Resolver.Resolve(Defaults, { PICKUP_SETTINGS = { COLLECTION_METHOD = "STATIONARY_EXPERIMENT" } }).PICKUP_SETTINGS.COLLECTION_METHOD == "STATIONARY")
	assert(settings.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND and settings.ISLAND_SETTINGS.PREFERRED_FARMING_ISLAND == "Zen" and not settings.ISLAND_SETTINGS.AUTO_EXPLORE_UNLOCKED_ISLANDS)
	assert(table.concat(settings.ISLAND_SETTINGS.SELECTED_ISLANDS, ",") == "The Void,Zen")
	assert(not Resolver.Resolve(Defaults, { PICKUP_SETTINGS = { ENABLE_CLUSTER_ROUTING = true } }).PICKUP_SETTINGS.ENABLE_CLUSTER_ROUTING)
	assert(not pcall(function() Resolver.Resolve(Defaults, { PICKUP_SETTINGS = { COLLECTION_METHOD = "MOVEMENT" } }) end))
	local mechanics = Mechanics.new(settings, {}, {}, {})
	assert(not mechanics:Walk(Vector3.new(999, 0, 0))) mechanics:StopMovement()
end)

test("Stationary pacing rejects NaN infinity flooding batches and excessive transport retries", function()
	for key, value in pairs({ STATIONARY_REQUEST_COOLDOWN_SECONDS = 0, STATIONARY_ID_RETRY_SECONDS = 0, STATIONARY_MAXIMUM_BATCH_SIZE = 65,
		STATIONARY_MAXIMUM_ATTEMPTS_PER_ID = 3, STATIONARY_BATCH_COOLDOWN_SECONDS = math.huge }) do
		assert(not pcall(function() Resolver.Resolve(Defaults, { PICKUP_SETTINGS = { [key] = value } }) end))
	end
	assert(not pcall(function() Resolver.Resolve(Defaults, { PICKUP_SETTINGS = { STATIONARY_REQUEST_COOLDOWN_SECONDS = 0/0 } }) end))
end)

test("Dispatched genuine ID removes native chunk references and its visual without inventing credit", function()
	simulated(function()
		local scene = stationaryFixture() local record = scene:Add("live-one", "Coins", 60)
		local initial = scene.Root.Position local result = scene:Collect()
		assert(not result.Verified and #scene.Calls == 1 and scene.Calls[1].Id == "live-one")
		assert(record.Model.Destroyed and not scene.Registry["live-one"] and scene.Root.Position == initial)
		assert(not scene.Chunker.Members[record.Model] and #scene.Removed == 1 and not scene.Coordinator.Tracker.Models[record.Model])
		assert(scene.Coordinator.Stationary.LastResult.VisualsCleaned == 1)
		assert(scene.Coordinator.Stationary.LastResult.OutsideNativeRange and scene.Coordinator.Stationary.UncreditedWindows == 1)
		assert(scene.Coordinator:GetStatus().Stationary.MovementFallback == false)
		scene:Close()
	end)
end)

test("Actual matching LocalData credit is verified independently of visual cleanup", function()
	simulated(function(clock)
		local scene = stationaryFixture() local record = scene:Add("credited", "Gems", 40)
		clock.Tick = function() if clock.Time >= 0.2 then scene.Profile.Gems = 65 end end
		local result = scene:Collect()
		assert(result.Verified and result.Gains.Gems == 15 and record.Model.Destroyed and not scene.Registry.credited)
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

test("Repeated scans never redispatch normally invoked IDs even without credit", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("retry")
		assert(not scene:Collect().Verified and #scene.Calls == 1)
		clock.Time = 2 assert(not scene:Collect().Verified and #scene.Calls == 1)
		clock.Time = 10 assert(not scene:Collect().Verified and #scene.Calls == 1)
		clock.Time = 15 assert(not scene:Collect().Verified and #scene.Calls == 1)
		clock.Time = 400 assert(not scene:Collect().Verified and #scene.Calls == 1)
		scene.Coordinator.Stationary:Candidate(nil) -- The Brain reconciles lifecycle state even when the current cluster is empty.
		assert(not scene.Coordinator.Stationary.PerId.retry, "Retired diagnostic records must expire") scene:Close()
	end)
end)

test("New genuine spawned IDs participate continuously without clearing retry history", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("old") scene:Collect()
		clock.Time = 5 local fresh = scene:Add("new", "Gems") scene:Collect()
		assert(#scene.Calls == 2 and scene.Calls[2].Id == "new" and scene.Coordinator.Stationary.PerId.old.Attempts == 1)
		assert(fresh.Model.Destroyed and not scene.Registry.new) scene:Close()
	end)
end)

test("Legacy session quotas and expiry cannot stop continuous farming", function()
	for _, settings in ipairs({ { STATIONARY_MAXIMUM_REQUESTS = 1 }, { STATIONARY_TEST_DURATION_SECONDS = 1 } }) do
		simulated(function(clock)
			local scene = stationaryFixture({ PICKUP_SETTINGS = settings }) scene:Add("first") scene:Collect()
			clock.Time = 3600 scene:Add("second") assert(not scene:Collect().Verified and #scene.Calls == 2)
			clock.Time += 2 assert(not scene.Coordinator.Stationary:LimitReason()) scene:Close()
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

test("Distance is diagnostic only even with legacy native-only overrides", function()
	simulated(function()
		local scene = stationaryFixture({ PICKUP_SETTINGS = { STATIONARY_ALLOW_OUTSIDE_NATIVE_RANGE = false, MAXIMUM_ROUTE_DISTANCE_STUDS = 1 } }) scene:Add("far", "Coins", 10000)
		scene:Add("near", "Gems", 5) -- Move neither the player nor any existing Model.
		local initial = scene.Root.Position scene:Collect()
		assert(#scene.Calls == 2 and scene.Calls[1].Id == "far" and scene.Calls[2].Id == "near" and scene.Root.Position == initial)
		assert(scene.Coordinator.Stationary.LastResult.OutsideNativeCount == 1) scene:Close()
	end)
end)

test("Unavailable LocalData refuses dispatch and cannot fabricate balances", function()
	simulated(function()
		local scene = stationaryFixture() scene:Add("unknown") scene.Profile.Gems = nil
		assert(not scene:Collect().Verified and #scene.Calls == 0) scene:Close()
	end)
end)

test("Position changes never permanently invalidate stationary batches", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("drift")
		clock.Tick = function() scene.Root.Position = scene.Root.Position + Vector3.new(1, 0, 0) scene.Profile.Coins += 10 end
		assert(scene:Collect().Verified and not scene.Coordinator.Stationary.Invalidated)
		clock.Tick = nil clock.Time = 20 scene:Add("later") assert(not scene:Collect().Verified and #scene.Calls == 2) scene:Close()
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

test("Pause and Stop cancel scheduled stationary windows and retain deduplication", function()
	for _, control in ipairs({ "Pause", "Stop" }) do
		simulated(function(clock)
			local scene = stationaryFixture() scene:Add("scheduled") scene:Add("scheduled-later")
			local scheduler = Scheduler.new(scene.Controller.Config.TASK_SETTINGS) scheduler:Resume()
			clock.Tick = function() scheduler[control](scheduler) scene.Controller.State = "PAUSED" scene.Coordinator:Halt(true) end
			scheduler:Submit(scene.Coordinator:Definition(scene:Decision(), 1)) flush()
			assert(#scene.Calls == 1 and scheduler.Active == nil and scene.Coordinator.Stationary.Requests == 1)
			local result = scene.Coordinator.Stationary.LastResult
			assert(result.Cancelled and scene.Coordinator.Metrics.ConfirmedCycles == 0)
			assert(result.BatchSize == 1 and result.Before.Coins == 100 and result.After.Gems == 50 and result.Outcome == "CANCELLED_INCONCLUSIVE")
			assert(result.ProcessingSeconds >= 0 and result.WindowSeconds >= result.ProcessingSeconds)
			clock.Tick = nil clock.Time = 5 scene.Controller.State = "RUNNING" scene:Add("new")
			scheduler:Submit(scene.Coordinator:Definition(scene:Decision(), 1)) flush() assert(#scene.Calls == 1)
			scheduler:Resume() scheduler:Submit(scene.Coordinator:Definition(scene:Decision(), 1)) flush()
			assert(#scene.Calls == 3 and scene.Calls[1].Id == "scheduled", "Resume/Start sends remaining and new IDs without repeating dispatched IDs")
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
	local selected = Resolver.Resolve(Defaults, { BRAIN_SETTINGS = { SELECTED_WORLDS = { "The Overworld" } }, PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = true }, ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false } })
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

test("Rapid bounded batches process all real Coins and Gems IDs across successive tasks", function()
	simulated(function(clock)
		local scene = stationaryFixture()
		for index = 1, 70 do scene:Add(string.format("batch-%03d", index), index % 2 == 0 and "Gems" or "Coins") end
		scene.OnDispatch = function(id)
			local currency = scene.Coordinator.Tracker.Models[scene.Registry[id]].Currency scene.Profile[currency] += 10
		end
		local first = scene:Collect()
		assert(#scene.Calls == 32 and first.Gains.Coins == 160 and first.Gains.Gems == 160)
		local stats = scene.Coordinator.Stationary.LastResult
		assert(stats.ObservedDeltas.Coins == 160 and stats.ObservedDeltas.Gems == 160)
		assert(stats.ProcessingSeconds < 2 and stats.WindowSeconds >= stats.ProcessingSeconds and stats.Outcome == "MATCHING_BALANCE_INCREASE")
		assert(scene.Calls[32].At - scene.Calls[1].At < 2, "Batch must not settle after each ID")
		assert(not scene:Collect().Verified and #scene.Calls == 32, "Completed batches observe their cooldown")
		clock.Time += 1 scene:Collect() assert(#scene.Calls == 64)
		clock.Time += 1 scene:Collect() assert(#scene.Calls == 70)
		local seen = {}
		for index, call in ipairs(scene.Calls) do
			assert(not seen[call.Id]) seen[call.Id] = true
			if index > 1 then assert(call.At - scene.Calls[index - 1].At >= 0.05 - 1e-6) end
		end
		assert(scene.Coordinator.Stationary.Gains.Coins == 350 and scene.Coordinator.Stationary.Gains.Gems == 350)
		clock.Time += 1 scene:Add("new-spawn", "Gems") scene:Collect() assert(#scene.Calls == 71)
		scene:Close()
	end)
end)

test("Failed transport attempts back off per ID without blocking new IDs", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("transport-error")
		scene.OnDispatch = function(id) if id == "transport-error" then error("Transport error") end end
		scene:Collect() assert(#scene.Calls == 1)
		clock.Time = 5 scene:Add("fresh-after-error", "Gems") scene:Collect() assert(#scene.Calls == 2)
		clock.Time = 15 scene:Collect() assert(#scene.Calls == 3 and scene.Calls[3].Id == "transport-error")
		clock.Time = 40 scene:Collect() assert(#scene.Calls == 3)
		assert(scene.Coordinator.Stationary.PerId["transport-error"].Attempts == 2) scene:Close()
	end)
end)

test("Island changes discard only the current window and resume on the other allowed island", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("void-before-change")
		clock.Tick = function() scene.Area.Name, scene.Area.Key = "Floating Island", "The Overworld/Floating Island" scene.Profile.Coins = 110 end
		assert(not scene:Collect().Verified)
		clock.Tick = nil clock.Time += 2 scene:Add("excluded") scene:Collect() assert(#scene.Calls == 1)
		scene.Area.Name, scene.Area.Key = "Zen", "The Overworld/Zen" scene:Add("zen-after-change", "Gems")
		scene:Collect() assert(#scene.Calls == 2 and scene.Calls[2].Id == "zen-after-change") scene:Close()
	end)
end)

test("Movement route eligibility and missing radius diagnostics cannot block genuine stationary IDs", function()
	simulated(function()
		local scene = stationaryFixture() local record = scene:Add("not-a-walking-route") record.RouteEligible = false
		scene.Coordinator.Tracker.ReadRange = function() return nil end
		scene:Collect() assert(#scene.Calls == 1 and scene.Calls[1].Id == record.Id) scene:Close()
	end)
end)

test("Deduplication survives Chunker unload reload and prunes only retired OC state", function()
	simulated(function(clock)
		local scene = stationaryFixture() local record = scene:Add("chunk-cycle") scene:Collect()
		scene.Registry[record.Id] = nil clock.Time = 10 scene.Coordinator.Stationary:Candidate(nil)
		scene.Registry[record.Id] = record.Model clock.Time = 20 scene:Collect() assert(#scene.Calls == 1)
		scene.Registry[record.Id] = nil clock.Time = 100 scene.Coordinator.Stationary:Candidate(nil)
		assert(not scene.Coordinator.Stationary.PerId[record.Id] and record.Model.Destroyed)
		scene:Add("new-after-prune") scene:Collect() assert(#scene.Calls == 2) scene:Close()
	end)
end)

test("Replacement Models with the same genuine ID start a fresh lifecycle without duplicate old requests", function()
	simulated(function(clock)
		local scene = stationaryFixture() local old = scene:Add("replaced-id") scene:Collect()
		clock.Time += 1 local stale = scene:Decision() local replacement = scene:Add("replaced-id", "Gems")
		assert(not scene.Coordinator:_collection(stale, { CheckCancelled = function() return false end }).Verified and #scene.Calls == 1)
		scene:Collect() assert(#scene.Calls == 2 and scene.Calls[2].Id == "replaced-id")
		clock.Time += 1 scene:Collect() assert(#scene.Calls == 2)
		local state = scene.Coordinator.Stationary.PerId["replaced-id"]
		assert(state.Model == replacement.Model and state.Attempts == 1 and old.Model.Destroyed and replacement.Model.Destroyed and not scene.Registry["replaced-id"])
		scene:Close()
	end)
end)

test("A newly spawned genuine ID and Model is collected after the original lifecycle is retired", function()
	simulated(function(clock)
		local scene = stationaryFixture() local record = scene:Add("original-id") scene:Collect()
		clock.Time += 1 local fresh = scene:Add("respawn-id") scene:Collect()
		assert(#scene.Calls == 2 and scene.Calls[2].Id == "respawn-id" and record.Model.Destroyed and fresh.Model.Destroyed)
		scene:Close()
	end)
end)

test("Actual numeric native registry keys are preserved in collection requests", function()
	simulated(function()
		local scene = stationaryFixture() local record = scene:Add("123")
		scene.Registry["123"] = nil scene.Registry[123] = record.Model record.RegistryKey = 123
		scene:Collect() assert(#scene.Calls == 1 and scene.Calls[1].Id == 123 and not scene.Registry[123] and record.Model.Destroyed)
		scene:Close()
	end)
end)

test("Inconclusive no-credit batches log actual zero gains and timing without inventing success", function()
	simulated(function()
		local scene = stationaryFixture() scene:Add("inconclusive") scene:Collect()
		local result = scene.Coordinator.Stationary.LastResult
		assert(result.Outcome == "INCONCLUSIVE_NO_MATCHING_CREDIT" and not result.CreditObserved)
		assert(result.ObservedDeltas.Coins == 0 and result.ObservedDeltas.Gems == 0 and result.BatchSize == 1)
		local found = false
		for _, log in ipairs(scene.Logs) do
			if log:find("STATIONARY_RESULT", 1, true) then
				assert(log:find("Coins gained=0", 1, true) and log:find("Gems gained=0", 1, true) and log:find("processing=", 1, true) and log:find(result.Outcome, 1, true)) found = true
			end
		end
		assert(found) scene:Close()
	end)
end)

test("Manual island changes and Pause start fresh rate windows while preserving ID lifecycle state", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("void-sample") scene:Collect()
		clock.Time = 600 scene.Area.Name, scene.Area.Key = "Zen", "The Overworld/Zen" scene:Add("zen-sample", "Gems")
		scene.OnDispatch = function() scene.Profile.Gems += 10 end scene:Collect()
		local sample = scene.Coordinator.Metrics.Samples[#scene.Coordinator.Metrics.Samples]
		assert(sample.Seconds <= scene.Controller.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS and sample.Gains.Gems == 10)
		scene.Coordinator:Halt(true)
		assert(not scene.Coordinator.Stationary.LastSampleAt and scene.Coordinator.Stationary.PerId["zen-sample"].Dispatched)
		clock.Time = 1200 scene:Add("resumed-sample", "Gems") scene:Collect()
		sample = scene.Coordinator.Metrics.Samples[#scene.Coordinator.Metrics.Samples]
		assert(sample.Seconds <= scene.Controller.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS and #scene.Calls == 3)
		scene:Close()
	end)
end)

test("Failed dispatch retains the visual registry and Chunker until a successful retry", function()
	simulated(function(clock)
		local scene = stationaryFixture() local record = scene:Add("keep-on-error")
		scene.OnDispatch = function() error("Transport failure") end scene:Collect()
		assert(not record.Model.Destroyed and scene.Registry[record.Id] == record.Model and scene.Chunker.Members[record.Model] and #scene.Removed == 0)
		scene.OnDispatch = nil clock.Time = 15 scene:Collect()
		assert(#scene.Calls == 2 and record.Model.Destroyed and not scene.Registry[record.Id] and #scene.Removed == 1) scene:Close()
	end)
end)

test("Native cleanup failure blocks accumulation and retries cleanup without redispatch", function()
	simulated(function(clock)
		local scene = stationaryFixture() local record = scene:Add("cleanup-failure") scene:Add("later-id")
		scene.RemoveError = true scene.OnDispatch = function() scene.Profile.Coins += 10 end
		assert(scene:Collect().Verified and #scene.Calls == 1 and not record.Model.Destroyed)
		assert(scene.Coordinator.Mechanics.PendingPickupCleanup and scene.Registry[record.Id] == record.Model)
		clock.Time = 5 scene:Collect() assert(#scene.Calls == 1)
		scene.RemoveError = false clock.Time = 15 scene:Collect()
		assert(#scene.Calls == 2 and scene.Calls[2].Id == "later-id" and record.Model.Destroyed and not scene.Coordinator.Mechanics.PendingPickupCleanup)
		assert(#scene.Removed == 2) scene:Close()
	end)
end)

test("Post-dispatch registry replacement is preserved and reported instead of erased", function()
	simulated(function()
		local scene = stationaryFixture() local old = scene:Add("replace-during-request") local replacement
		scene.OnDispatch = function() replacement = scene:Add("replace-during-request", "Gems") end scene:Collect()
		assert(#scene.Calls == 1 and scene.Registry[old.Id] == replacement.Model and not replacement.Model.Destroyed)
		assert(not old.Model.Destroyed and #scene.Removed == 0 and scene.Coordinator:GetStatus().CleanupBlocker:find("replacement", 1, true)) scene:Close()
	end)
end)

test("Cleanup retry releases native references even after the chunk unloaded during backoff", function()
	simulated(function(clock)
		local scene = stationaryFixture() local record = scene:Add("unloaded-pending") scene.RemoveError = true scene:Collect()
		scene.Chunker.Hidden[record.Model] = true scene.Registry[record.Id] = nil record.Model.Parent = nil
		scene.RemoveError = false clock.Time = 15
		assert(scene.Coordinator.Mechanics:RetryPickupCleanup({ CheckCancelled = function() return false end }))
		assert(not scene.Chunker.Members[record.Model] and not scene.Chunker.Hidden[record.Model] and record.Model.Destroyed and #scene.Calls == 1) scene:Close()
	end)
end)

test("Cleanup finishes an already-dispatched pickup when cancellation occurs inside invocation", function()
	simulated(function()
		local scene = stationaryFixture() local record = scene:Add("cancel-in-flight") scene:Add("never-requested") local cancelled = false
		scene.OnDispatch = function() cancelled = true end
		local result = scene:Collect({ CheckCancelled = function() return cancelled end })
		assert((not result or not result.Verified) and #scene.Calls == 1 and record.Model.Destroyed and scene.Registry["never-requested"] and #scene.Removed == 1) scene:Close()
	end)
end)

test("Receiver observation delegates native Update unchanged and restores it on capture or Pause", function()
	simulated(function()
		local scene = stationaryFixture() local record = scene:Add("observe-native") local knowledge = scene.Coordinator.Knowledge
		knowledge.NativePickupChunker = nil
		local updated = 0
		local original = function(receiver, argument) assert(receiver == scene.Chunker and argument == "native-position") updated += 1 return "native-result", nil, 7 end
		local class = { Update = original } scene.Dependencies.Chunker = class
		assert(not scene:Collect().Verified and #scene.Calls == 0 and class.Update ~= original and record.Model.Parent)
		local first, second, third = class.Update(scene.Chunker, "native-position")
		assert(first == "native-result" and second == nil and third == 7 and updated == 1 and class.Update == original and knowledge.NativePickupChunker == scene.Chunker)
		scene:Collect() assert(#scene.Calls == 1 and record.Model.Destroyed)
		knowledge.NativePickupChunker = nil scene:Add("pause-observer") knowledge:PickupChunker()
		assert(class.Update ~= original) scene.Coordinator:Halt(true) assert(class.Update == original and not knowledge.ChunkerObserver) scene:Close()
	end)
end)

test("Receiver observation timeout and malformed values cannot disrupt native updates", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("waiting-native") local knowledge = scene.Coordinator.Knowledge knowledge.NativePickupChunker = nil
		local original = function() return "unmodified" end local class = { Update = original } scene.Dependencies.Chunker = class
		knowledge:PickupChunker() scene.Registry.malformed = 5
		table.clear(scene.Chunker.Members)
		assert(class.Update(scene.Chunker) == "unmodified") -- Bad observation input cannot throw into native Update.
		clock.Time = 5 knowledge:PickupChunker() assert(class.Update == original and not knowledge.ChunkerObserver)
		clock.Time = 8 knowledge:PickupChunker() assert(class.Update == original)
		clock.Time = 10 knowledge:PickupChunker() assert(class.Update ~= original)
		scene:Close() assert(class.Update == original)
	end)
end)

test("Many successive batches release native visuals tracker metadata and retired diagnostics", function()
	simulated(function(clock)
		local scene = stationaryFixture()
		for batch = 1, 12 do
			for index = 1, 32 do
				local record = scene:Add(string.format("lifecycle-%02d-%02d", batch, index))
				scene.Coordinator.Tracker.Metadata[record.Id] = { At = clock.Time }
			end
			scene:Collect() clock.Time += 1
			assert(next(scene.Registry) == nil and next(scene.Chunker.Members) == nil and next(scene.Coordinator.Tracker.Models) == nil and next(scene.Coordinator.Tracker.Metadata) == nil)
		end
		assert(#scene.Calls == 384 and #scene.Removed == 384)
		clock.Time += 61 scene.Coordinator.Stationary:Candidate(nil) assert(next(scene.Coordinator.Stationary.PerId) == nil) scene:Close()
	end)
end)

local function travelIsland(scene, name)
	local area = { Name = name, World = "The Overworld", Key = "The Overworld/" .. name, CatalogKnown = true, Unlocked = true,
		DestinationPath = "Workspace.Worlds.The Overworld.Islands." .. name .. ".Island.Portal.Spawn", Currencies = { Coins = true, Gems = true },
		Zones = { { Data = { Zone = { Height = scene.Root.Position.Y, GetDistanceToPoint = function() return 0 end } } } } }
	scene.Coordinator.Tracker.Areas[area.Key] = area
	return area
end
local automaticTravel = { ISLAND_SETTINGS = { AUTO_SELECT_BEST_ISLAND = true, AUTO_TRAVEL_BEST_ISLAND = true, PREFERRED_FARMING_ISLAND = "Zen" } }

test("Startup selects actual unlocked Zen and falls back to Void without unlock requests", function()
	for _, zenUnlocked in ipairs({ true, false }) do
		simulated(function()
			local scene = stationaryFixture(automaticTravel) local zen = travelIsland(scene, "Zen") local void = travelIsland(scene, "The Void")
			scene.Profile.AreasUnlocked.Zen = zenUnlocked and true or nil scene.Coordinator.Tracker.Current = nil
			local decision = scene.Coordinator:Select({ Candidates = {} })
			assert(decision.Kind == "TRAVEL" and decision.Island == (zenUnlocked and zen or void) and #scene.Teleports == 0)
			if zenUnlocked then
				scene.Coordinator.Tracker.Areas[zen.Key] = nil
				decision = scene.Coordinator:Select({ Candidates = {} }) assert(decision.Kind == "TRAVEL" and decision.Island == void)
				scene.Coordinator.Tracker.Areas[zen.Key] = zen
			end
			scene.Profile.AreasUnlocked["The Void"], scene.Profile.AreasUnlocked.Zen = nil, nil
			decision = scene.Coordinator:Select({ Candidates = {} }) assert(decision.Kind == "WAIT" and decision.Reason:find("Neither", 1, true)) scene:Close()
		end)
	end
end)

test("Automatic island travel uses the native path then waits for stable arrival before collecting", function()
	simulated(function(clock)
		local scene = stationaryFixture(automaticTravel) local zen = travelIsland(scene, "Zen") travelIsland(scene, "The Void")
		scene.OnTeleport = function(destination)
			assert(destination == zen.DestinationPath) scene.Area = zen scene.Coordinator.Tracker.Current = zen scene.Coordinator.Tracker.ArrivedAt = clock.Time
		end
		local decision = scene.Coordinator:Select({ Candidates = {} }) assert(decision.Kind == "TRAVEL" and decision.Island == zen)
		local scheduler = Scheduler.new(scene.Controller.Config.TASK_SETTINGS) scheduler:Resume()
		scheduler:Submit(scene.Coordinator:Definition(decision, 1)) flush()
		assert(#scene.Teleports == 1 and scheduler.Active == nil)
		scene:Add("after-arrival") assert(scene.Coordinator:Select({ Candidates = {} }).Kind == "INSPECT")
		scene:Collect() assert(#scene.Calls == 0)
		clock.Time = 4 decision = scene.Coordinator:Select({ Candidates = {} }) assert(decision.Kind == "FARM")
		scheduler:Submit(scene.Coordinator:Definition(decision, 1)) flush() assert(#scene.Calls == 1 and #scene.Teleports == 1)
		local ok = scene.Coordinator.Mechanics:TravelIsland(zen, { CheckCancelled = function() return false end })
		assert(ok and #scene.Teleports == 1, "Already selected native island must not teleport again")
		scheduler:Destroy() scene:Close()
	end)
end)

test("Empty preferred island does not cause fallback switching and selling retains the saved return", function()
	simulated(function(clock)
		local scene = stationaryFixture(automaticTravel) local zen = travelIsland(scene, "Zen") local void = travelIsland(scene, "The Void")
		scene.Area = zen scene.Coordinator.Tracker.Current = zen scene.Coordinator.Tracker.ArrivedAt = 0 clock.Time = 5
		scene.Coordinator.Mechanics:Failure("ISLAND:" .. zen.Key, 100, "No pickups yet")
		assert(scene.Coordinator:Select({ Candidates = {} }).Kind == "INSPECT" and #scene.Teleports == 0)
		scene.Coordinator.ReturnKey = void.Key
		local decision = scene.Coordinator:Select({ Candidates = {} }) assert(decision.Kind == "TRAVEL" and decision.Island == void and decision.Returning)
		scene:Close()
	end)
end)

test("Teleport invocation and unconfirmed arrival use bounded backoff without invalid collection", function()
	for _, fails in ipairs({ true, false }) do
		simulated(function(clock)
			local scene = stationaryFixture(automaticTravel) local zen = travelIsland(scene, "Zen")
			if fails then scene.OnTeleport = function() error("Transport failure") end end
			local token = { CheckCancelled = function() return false end }
			assert(not scene.Coordinator.Mechanics:TravelIsland(zen, token) and #scene.Teleports == 1)
			assert(not scene.Coordinator.Mechanics:TravelIsland(zen, token) and #scene.Teleports == 1)
			clock.Time += scene.Controller.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS
			assert(not scene.Coordinator.Mechanics:TravelIsland(zen, token) and #scene.Teleports == 2)
			assert(#scene.Calls == 0) scene:Close()
		end)
	end
end)

test("Pause Stop locked islands and excluded destinations prevent native island dispatch", function()
	for _, control in ipairs({ "Pause", "Stop" }) do
		simulated(function()
			local scene = stationaryFixture(automaticTravel) local zen = travelIsland(scene, "Zen")
			local scheduler = Scheduler.new(scene.Controller.Config.TASK_SETTINGS) scheduler:Resume() scheduler[control](scheduler)
			scheduler:Submit(scene.Coordinator:Definition({ Kind = "TRAVEL", Island = zen, Reason = "startup" }, 1)) flush()
			assert(#scene.Teleports == 0 and #scene.Calls == 0)
			local token = { CheckCancelled = function() return false end }
			scene.Profile.AreasUnlocked.Zen = nil assert(not scene.Coordinator.Mechanics:TravelIsland(zen, token))
			local excluded = travelIsland(scene, "Floating Island") scene.Profile.AreasUnlocked[excluded.Name] = true
			assert(not scene.Coordinator.Mechanics:TravelIsland(excluded, token) and #scene.Teleports == 0)
			scheduler:Destroy() scene:Close()
		end)
	end
end)

print(string.format("[OC TEST] %d stationary-only regressions passed; %d total. Offline fixtures are not live server verification.", tests - stationaryBefore, tests))

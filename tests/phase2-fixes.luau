-- Synthetic offline regressions only; no Roblox live execution or account proof.
local fixesBefore = tests
local function simulated(callback)
	local savedClock, savedWait, savedSpawn, savedPath = os.clock, task.wait, task.spawn, services.PathfindingService
	local clock = { Time = 0 }
	os.clock = function() return clock.Time end
	task.wait = function(seconds) clock.Time += seconds or 0.1 if clock.Tick then clock.Tick(seconds or 0.1) end end
	task.spawn = function(fn) local thread = coroutine.create(fn) local ok, reason = coroutine.resume(thread) assert(ok, reason) return thread end
	local ok, reason = xpcall(function() callback(clock) end, debug.traceback)
	os.clock, task.wait, task.spawn, services.PathfindingService = savedClock, savedWait, savedSpawn, savedPath
	assert(ok, reason)
end

local function walkingFixture(settings)
	local root = { Position = Vector3.new(0, 3.5, 0), Parent = true }
	local moved = event()
	local humanoid = { MoveToFinished = moved.Event, Target = root.Position, Moves = 0, Stops = 0 }
	function humanoid:MoveTo(point) self.Target = point self.Moves += 1 end
	function humanoid:Move() self.Stops += 1 end
	local mechanics = Mechanics.new(config(settings), {}, { Root = function() return root, humanoid end }, {})
	mechanics.Guard = function() return true, nil, root, humanoid end
	local state = { Paths = 0, Destroyed = 0, Root = root, Humanoid = humanoid, Mechanics = mechanics, Moved = moved, Blocks = {} }
	services.PathfindingService = { CreatePath = function()
		state.Paths += 1 local blocked = event() table.insert(state.Blocks, blocked)
		return { Status = Enum.PathStatus.Success, Blocked = blocked.Event, ComputeAsync = function() end,
			GetWaypoints = function() return { { Position = root.Position }, { Position = Vector3.new(20, 0, 0) } } end,
			Destroy = function() state.Destroyed += 1 end }
	end }
	return state
end

test("Forward progress permits a waypoint taking longer than the old fixed timeout", function()
	simulated(function(clock)
		local scene = walkingFixture()
		clock.Tick = function(dt) scene.Root.Position = Vector3.new(math.min(20, scene.Root.Position.X + dt * 3), 3.5, 0) end
		local success = scene.Mechanics:Walk(Vector3.new(20, 0, 0), { CheckCancelled = function() return false end }, 10)
		assert(success and clock.Time > 3 and scene.Paths == 1 and scene.Humanoid.Moves >= 3)
		assert(scene.Destroyed == 1 and scene.Mechanics.MovementLease == nil)
	end)
end)

test("Stalled movement recomputes once and recovers using actual position", function()
	simulated(function(clock)
		local scene = walkingFixture()
		clock.Tick = function(dt) if scene.Paths == 2 then scene.Root.Position = Vector3.new(math.min(20, scene.Root.Position.X + dt * 16), 3.5, 0) end end
		assert(scene.Mechanics:Walk(Vector3.new(20, 0, 0), { CheckCancelled = function() return false end }, 6))
		assert(scene.Paths == 2 and scene.Destroyed == 2 and scene.Mechanics.LastRoute.Replans == 1)
	end)
end)

test("Unreachable routes exhaust a bounded recovery rather than looping", function()
	simulated(function()
		local scene = walkingFixture()
		local success, reason = scene.Mechanics:Walk(Vector3.new(20, 0, 0), { CheckCancelled = function() return false end }, 10)
		assert(not success and reason:find("without forward progress", 1, true))
		assert(scene.Paths == 2 and scene.Destroyed == 2 and scene.Humanoid.Stops == 2)
	end)
end)

test("MoveToFinished cannot invent arrival and obsolete blocked events are disconnected", function()
	simulated(function(clock)
		local scene = walkingFixture({ PICKUP_SETTINGS = { MAXIMUM_PATH_RECOMPUTES = 0 } })
		clock.Tick = function() scene.Moved:Fire(true) scene.Blocks[1]:Fire(1) end -- Behind current waypoint index 2.
		local success, reason = scene.Mechanics:Walk(Vector3.new(20, 0, 0), { CheckCancelled = function() return false end }, 5)
		assert(not success and reason:find("stalled", 1, true) and scene.Paths == 1)
		scene.Blocks[1]:Fire(2) scene.Moved:Fire(false)
		assert(scene.Mechanics.MovementLease == nil and scene.Destroyed == 1)
	end)
end)

test("Pause and Stop cancel an active route with no later destination movement", function()
	for _, control in ipairs({ "Pause", "Stop" }) do
		simulated(function(clock)
			local scene = walkingFixture()
			local scheduler = Scheduler.new(config().TASK_SETTINGS) scheduler:Resume()
			local afterCancel, destinationCalls = false, 0
			local move = scene.Humanoid.MoveTo
			scene.Humanoid.MoveTo = function(self, point)
				if afterCancel and point.X ~= scene.Root.Position.X then destinationCalls += 1 end move(self, point)
			end
			clock.Tick = function() scheduler[control](scheduler) scene.Mechanics:StopMovement() afterCancel = true end
			scheduler:Submit({ Id = "route", Priority = 10, Execute = function(token) return scene.Mechanics:Walk(Vector3.new(20, 0, 0), token, 10) end })
			flush()
			assert(destinationCalls == 0 and scene.Paths == 1 and scene.Destroyed == 1 and scheduler.Active == nil)
			scheduler:Destroy()
		end)
	end
end)

local function purchaseFixture(effect)
	local profile = { Coins = 100, Gum = {}, AreasUnlocked = { A = true }, Bubble = { Gum = "Old" } }
	local calls = 0
	local definitions = { Gum = { New = { Area = "A", Storage = 200, Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } } },
		Remote = { FireServer = function(_, command, name) calls += 1 assert(command == "GumShopPurchase") effect(profile, name) end } }
	local reader = { GetLiveProfile = function() return profile end, _dependency = function(_, name) return definitions[name] end }
	local mechanics = Mechanics.new(config({ BUBBLE_SETTINGS = { AUTO_BUY_GUM = true }, UPGRADE_SETTINGS = { PURCHASE_CONFIRMATION_TIMEOUT_SECONDS = 1 } }), reader, {}, {})
	mechanics.Guard = function() return true end
	return mechanics, profile, function() return calls end
end

test("Ownership without payment and payment without ownership remain unconfirmed", function()
	for _, effect in ipairs({ function(profile, name) profile.Gum[name] = true end, function(profile) profile.Coins -= 10 end }) do
		simulated(function()
			local mechanics, _, calls = purchaseFixture(effect)
			local success, reason, evidence = mechanics:Upgrade({ Name = "New", Kind = "Gum" }, { CheckCancelled = function() return false end })
			assert(not success and reason:find("Purchase unconfirmed", 1, true) and not evidence.Verified and calls() == 1)
		end)
	end
end)

test("Separate delayed ownership and deduction updates verify one purchase request", function()
	simulated(function(clock)
		local mechanics, profile, calls = purchaseFixture(function() end)
		clock.Tick = function() if clock.Time >= 0.2 then profile.Gum.New = true end if clock.Time >= 0.4 then profile.Coins = 90 end end
		local success, _, evidence = mechanics:Upgrade({ Name = "New", Kind = "Gum" }, { CheckCancelled = function() return false end })
		assert(success and evidence.Verified and evidence.OwnedBefore == false and evidence.ObservedDeduction == 10 and calls() == 1)
	end)
end)

test("Cancellation after guards prevents a stale purchase command", function()
	local mechanics, _, calls = purchaseFixture(function() error("Must not purchase") end)
	local cancelled = false mechanics.Guard = function() cancelled = true return true end
	assert(not mechanics:Upgrade({ Name = "New", Kind = "Gum" }, { CheckCancelled = function() return cancelled end }))
	assert(calls() == 0)
end)

test("Upgrade diagnostics expose disabled toggles, resource reserves, goal cap and payback", function()
	local upgradePolicy = requireOC("UpgradePolicy")
	local data, context, plan = policyFixture()
	local _, rows = upgradePolicy.Evaluate(config(), data, plan, context, "Coins", "BUBBLES", context.Sells[1])
	assert(table.find(rows[1].Reasons, "AUTO_BUY_GUM=false"))
	assert(table.find(rows[1].Reasons, "Measured bubble sale income unavailable; complete a bubble-only trial"))
	plan.Objective.Metadata.Cost = { Type = "Currency", Currency = "Coins", Amount = 10000 }
	context.Rates.BUBBLES = { Ready = true, PerMinute = { Coins = 1000 } }
	context.EffectiveUpgrades = { ["Synthetic test gum"] = { Capacity = 200, Power = 20 } }
	local enabled = config({ BUBBLE_SETTINGS = { AUTO_BUY_GUM = true } })
	local best
	best, rows = upgradePolicy.Evaluate(enabled, data, plan, context, "Coins", "BUBBLES", context.Sells[1])
	assert(best and rows[1].GoalReserve == 50 and rows[1].Budget == 12.5)
	assert(not upgradePolicy.Evaluate(config({ BUBBLE_SETTINGS = { AUTO_BUY_GUM = true }, RESOURCE_SETTINGS = { COIN_RESERVE = 90 } }), data, plan, context, "Coins", "BUBBLES", context.Sells[1]))
	assert(not upgradePolicy.Evaluate(config({ BUBBLE_SETTINGS = { AUTO_BUY_GUM = true }, UPGRADE_SETTINGS = { MAXIMUM_PAYBACK_SECONDS = 0 } }), data, plan, context, "Coins", "BUBBLES", context.Sells[1]))
end)

test("Gum above the urgency threshold can still qualify through measured economics", function()
	local data, context, plan = policyFixture()
	data.Bubble.PowerPerBlow = 5
	context.EffectiveUpgrades = { ["Synthetic test gum"] = { Capacity = 200, Power = 5 } }
	context.Rates.BUBBLES = { Ready = true, PerMinute = { Coins = 10000 } }
	local best, rows = requireOC("UpgradePolicy").Evaluate(config({ BUBBLE_SETTINGS = { AUTO_BUY_GUM = true } }), data, plan, context, "Coins", "BUBBLES", context.Sells[1])
	assert(best and not rows[1].CapacityUrgent and rows[1].BlowsPerFill == 20)
end)

test("Native effective flavor projection cannot treat additive pet power as a base multiplier", function()
	local data, context, plan = policyFixture()
	data.Bubble = { BaseCapacity = 1750, Capacity = 1750, BaseOutput = 65, PowerPerBlow = 184 }
	data.Balances.Coins = 470000
	data.AvailableProgression.Upgrades = { { Name = "Contrast", Kind = "Flavors", BaseStat = 80, Accessible = true, OwnershipKnown = true, Owned = false, Cost = { Type = "Currency", Currency = "Coins", Amount = 35000 } } }
	context.EffectiveUpgrades = { Contrast = { Capacity = 1750, Power = 199 } }
	context.Rates.BUBBLES = { Ready = true, PerMinute = { Coins = 18000 } }
	local best, rows = requireOC("UpgradePolicy").Evaluate(config({ BUBBLE_SETTINGS = { AUTO_BUY_FLAVORS = true } }), data, plan, context, "Coins", "BUBBLES", context.Sells[1])
	assert(not best and rows[1].EffectiveRateGain < 0.1 and rows[1].Payback > 300)
	assert(table.find(rows[1].Reasons, "Conservative estimated payback exceeds MAXIMUM_PAYBACK_SECONDS"))
end)

test("Premium and unapproved purchase currencies cannot become eligible", function()
	local data, context, plan = policyFixture()
	local upgrade = data.AvailableProgression.Upgrades[1]
	for _, currency in ipairs({ "Robux", "Gems", "Tickets", "Pearls" }) do
		upgrade.Cost.Currency = currency data.Balances[currency] = 10000
		local best, rows = requireOC("UpgradePolicy").Evaluate(config({ BUBBLE_SETTINGS = { AUTO_BUY_GUM = true } }), data, plan, context, currency, "BUBBLES", context.Sells[1])
		assert(not best and table.find(rows[1].Reasons, "Purchase currency not explicitly authorized"))
	end
end)

test("Combined rates need actual growth, pickup credit and a complete sale within the window", function()
	local coordinator = requireOC("FarmingCoordinator").new({ Config = config(), Reader = {}, Log = function() end }, {})
	coordinator.Metrics:SetMode("COMBINED", "Synthetic/A", { Coins = 100 }, 0)
	coordinator.Metrics:Observe({ Coins = 200 }, 20)
	assert(coordinator:_pickupRates("Synthetic/A", 20).COMBINED == nil)
	coordinator.CombinedEvidence["Synthetic/A"] = { GrowthAt = 10, PickupAt = 15 }
	assert(coordinator:_pickupRates("Synthetic/A", 20).COMBINED == nil)
	coordinator.CombinedEvidence["Synthetic/A"].SaleAt = 20
	assert(not coordinator:_pickupRates("Synthetic/A", 20).COMBINED, "Incomplete interval cannot publish combined earnings")
	coordinator.Metrics:AddSample("COMBINED", "Synthetic/A", { Coins = 100 }, 20, 20)
	coordinator.CombinedEvidence["Synthetic/A"].ReturnedAt = 20
	assert(coordinator:_pickupRates("Synthetic/A", 20).COMBINED.Ready)
end)

test("Full combined bubbles defer selling only with measured opportunity cost and a bounded delay", function()
	local data, context, plan, memory = policyFixture()
	data.Bubble.Amount = data.Bubble.Capacity memory.Mode = "COMBINED" context.FullSince = 99
	context.Rates = { PICKUPS = { Ready = true, PerMinute = { Coins = 10000 } }, BUBBLES = { Ready = true, PerMinute = { Coins = 100 } } }
	assert(Policy.Decide(config(), data, plan, context, memory).Mode == "COMBINED")
	context.FullSince = 90 assert(Policy.Decide(config(), data, plan, context, memory).Kind == "SELL")
	context.FullSince = 99 context.Rates.PICKUPS.Ready = false assert(Policy.Decide(config(), data, plan, context, memory).Kind == "SELL")
	context.Rates.PICKUPS.Ready = true
	assert(Policy.Decide(config({ PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false } }), data, plan, context, memory).Kind == "SELL")
end)

test("Measured combined income prevents a worse island switch", function()
	local data, context, plan, memory = policyFixture()
	context.Islands[2].Expected.Coins = 1000
	context.Rates = { COMBINED = { Ready = true, PerMinute = { Coins = 100000 } }, BUBBLES = { Ready = true, PerMinute = { Coins = 100 } } }
	assert(Policy.Decide(config(), data, plan, context, memory).Kind ~= "TRAVEL")
end)

test("Current currency defaults no longer imply retained Fall catalogs are active", function()
	assert(not table.find(Defaults.ACCOUNT_SETTINGS.SELECTED_CURRENCIES, "Leaves26"))
	assert(table.find(Defaults.ACCOUNT_SETTINGS.SELECTED_CURRENCIES, "Candycorn26"))
	assert(not Defaults.FALL_EVENT_SETTINGS.ENABLE_FALL_EVENT and not Defaults.BUBBLE_SETTINGS.AUTO_BUY_GUM)
end)

test("Pause and Stop during native travel retain one request and cannot verify cancelled arrival", function()
	for _, control in ipairs({ "Pause", "Stop" }) do simulated(function(clock)
		local scheduler = Scheduler.new(config().TASK_SETTINGS) scheduler:Resume()
		local calls = 0
		local profile = { WorldsUnlocked = { Synthetic = true }, AreasUnlocked = { A = true } }
		local reader = { GetLiveProfile = function() return profile end, _dependency = function() return { FireServer = function() calls += 1 end } end }
		local root = { Position = Vector3.new(0, 0, 0) }
		local destination = { Parent = true, Position = Vector3.new(20, 0, 0), IsA = function() return true end, IsDescendantOf = function() return true end, GetFullName = function() return "Workspace.Worlds.Synthetic.Sell.Root" end }
		local mechanics = Mechanics.new(config(), reader, { Root = function() return root end }, {}) mechanics.Guard = function() return true end
		clock.Tick = function() scheduler[control](scheduler) root.Position = destination.Position end
		local result
		scheduler:Submit({ Id = "travel", Priority = 10, Execute = function(token) result = mechanics:Travel(destination, "Synthetic", "A", token) return result end })
		flush() assert(calls == 1 and result == false and scheduler.Active == nil and mechanics.TravelTimes == nil)
		scheduler:Destroy()
	end) end
end)

test("Cancellation during collection settling prevents verification and further credit waits", function()
	local cancelled, waited = false, false
	local controller = { Config = config(), Reader = { ReadBalances = function() return { Coins = 100 } end, GetSnapshot = function() return {} end, GetLiveProfile = function() return {} end }, Log = function() end }
	local coordinator = requireOC("FarmingCoordinator").new(controller, {})
	local model = { Parent = true }
	coordinator.Tracker.Current = { Key = "Synthetic/A", Name = "A", World = "Synthetic", Unlocked = true, EligibleCount = 1 }
	coordinator.Mechanics.Walk = function() return true end
	coordinator._settle = function() cancelled = true model.Parent = nil end
	coordinator._awaitCredit = function() waited = true return { Coins = 110 } end
	local result = coordinator:_collection({ Mode = "PICKUPS", Cluster = { AreaKey = "Synthetic/A", Position = Vector3.new(0,0,0), Radius = 7.5,
		Records = { { Model = model, Currency = "Coins" } }, SweepId = 1, SweepRemaining = 1, SweepTotal = 1 } }, { CheckCancelled = function() return cancelled end })
	assert(result == nil and not waited and next(coordinator.PickupEvidence) == nil and coordinator.Metrics.ConfirmedCycles == 0)
end)

test("Preserved Brain upgrade filters constrain new policy purchases", function()
	local data, context, plan = policyFixture()
	local best, rows = requireOC("UpgradePolicy").Evaluate(config({ BRAIN_SETTINGS = { SELECTED_UPGRADES = { "Another item" } }, BUBBLE_SETTINGS = { AUTO_BUY_GUM = true } }), data, plan, context, "Coins", "BUBBLES", context.Sells[1])
	assert(not best and table.find(rows[1].Reasons, "Excluded by BRAIN_SETTINGS.SELECTED_UPGRADES"))
end)

test("Unavailable combined pickup targets cannot suppress a useful island switch", function()
	local data, context, plan, memory = policyFixture()
	context.Cluster = nil context.Islands[1].Available = {} context.Islands[2].Expected.Coins = 1000
	context.Rates = { COMBINED = { Ready = true, PerMinute = { Coins = 100000 } }, BUBBLES = { Ready = true, PerMinute = { Coins = 100 } } }
	assert(Policy.Decide(config(), data, plan, context, memory).Kind == "TRAVEL")
end)

test("Full-bubble collection ends at the delay bound without blowing or misclassifying targets", function()
	simulated(function(clock)
		local model, blows, backoffs = { Parent = true }, 0, 0
		local controller = { Config = config(), Reader = { GetSnapshot = function() return {} end, ReadBalances = function() return { Coins = 100 } end,
			GetLiveProfile = function() return { Bubble = { Amount = 100 } } end, _stat = function() return 100 end }, Log = function() end }
		local coordinator = requireOC("FarmingCoordinator").new(controller, {})
		coordinator.Tracker.Current = { Key = "Synthetic/A", Name = "A", World = "Synthetic", Unlocked = true, EligibleCount = 1 }
		coordinator.Tracker.BackOff = function() backoffs += 1 end coordinator.Tracker.Refresh = function() end
		coordinator.Mechanics.Blow = function() blows += 1 end
		coordinator.Mechanics.Walk = function(_, _, _, deadline, tick, finished)
			while not finished() and clock.Time < deadline do tick() task.wait(0.1) end return true
		end
		coordinator._awaitCredit = function() return { Coins = 100 } end
		local result = coordinator:_collection({ Mode = "COMBINED", Cluster = { AreaKey = "Synthetic/A", Position = Vector3.new(0,0,0), Radius = 7.5,
			Records = { { Model = model, Currency = "Coins" } }, SweepId = 1, SweepRemaining = 1, SweepTotal = 1 } }, { CheckCancelled = function() return false end })
		assert(blows == 0 and backoffs == 0 and not result.Verified and clock.Time < 6.2)
	end)
end)

print(string.format("[OC TEST] %d additional Phase 2 regression tests passed; %d total. Live owner verification remains pending.", tests - fixesBefore, tests))

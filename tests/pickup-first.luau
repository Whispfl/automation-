-- Synthetic decision/lease/verification regressions; never live gameplay proof.
local pickupFirstBefore = tests
local function pickupFirstConfig(extra)
	local values = extra or {}
	values.FARMING_SETTINGS = values.FARMING_SETTINGS or {}
	values.FARMING_SETTINGS.FARMING_STRATEGY = "PICKUP_FIRST"
	return config(values)
end

test("Pickup-first prefers cooperative combined work over higher bubble-only rates", function()
	local data, context, plan, memory = policyFixture()
	context.Rates.BUBBLES = { Ready = true, PerMinute = { Coins = 999999 } }
	memory.Mode, memory.StartedAt = "BUBBLES", 99
	local decision = Policy.Decide(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "FARM" and decision.Mode == "COMBINED")
	context.CanBlow, context.BlowBlocker = false, "Bubble Lock"
	decision = Policy.Decide(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Mode == "PICKUPS" and decision.Reason:find("Bubble Lock", 1, true))
end)

test("Background blowing remains available for pickup goals paid in another currency", function()
	local data, context, plan, memory = policyFixture()
	plan.Objective.Metadata.Cost = { Type = "Currency", Currency = "Gems", Amount = 1000 }
	data.Balances.Gems = 0 context.CanTravel = false
	assert(Policy.Decide(pickupFirstConfig(), data, plan, context, memory).Mode == "COMBINED")
end)

test("Excluded current island cannot farm despite dwell, pending sweep or high income", function()
	local data, context, plan, memory = policyFixture()
	context.ArrivedAt, context.ActiveSweepPending = 99, true
	context.Rates.BUBBLES = { Ready = true, PerMinute = { Coins = 999999 } }
	local selected = pickupFirstConfig({ ISLAND_SETTINGS = { SELECTED_ISLANDS = { "B" } } })
	local decision = Policy.Decide(selected, data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Island.Name == "B")
	context.CanTravel = false decision = Policy.Decide(selected, data, plan, context, memory)
	assert(decision.Kind == "INSPECT" and decision.Background and not decision.Cluster)
	context.Islands[2].InBackoff = true
	assert(Policy.Decide(selected, data, plan, context, memory).Kind ~= "FARM")
end)

test("Saved return beats dwell and income while failed origins select an eligible alternative", function()
	local data, context, plan, memory = policyFixture()
	context.ReturnKey = context.Islands[2].Key context.ArrivedAt = 99 context.ActiveSweepPending = true
	context.Rates.COMBINED = { Ready = true, PerMinute = { Coins = 999999 } }
	local decision = Policy.Decide(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Returning and decision.Island.Name == "B")
	context.Islands[2].InBackoff = true
	decision = Policy.Decide(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "INSPECT", "Do not repeatedly issue a backed-off return")
end)

test("Full probes sell before loading or exploration and blocked sales remain explicit", function()
	local data, context, plan, memory = policyFixture()
	data.Bubble.Amount = data.Bubble.Capacity context.FullSince = 1
	context.PickupProbe = { Key = context.Current.Key, Currency = "Coins", ReadyAt = 200 }
	assert(Policy.Decide(pickupFirstConfig(), data, plan, context, memory).Kind == "SELL")
	context.CanInteract = false context.Blocker = "Transition"
	local decision = Policy.Decide(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "WAIT" and decision.Reason:find("Transition", 1, true))
end)

test("Final-mode decision reason cannot cite the replaced bubble score", function()
	local data, context, plan, memory = policyFixture()
	memory.Mode, memory.StartedAt = "PICKUPS", 99
	context.Rates = { PICKUPS = { Ready = true, PerMinute = { Coins = 10 } }, BUBBLES = { Ready = true, PerMinute = { Coins = 999 } } }
	local decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Mode == "PICKUPS" and decision.Reason:find("10.00", 1, true) and not decision.Reason:find("999", 1, true))
end)

test("Observed model latency cannot inflate definition-based island rates", function()
	local data, context, plan, memory = policyFixture()
	context.Islands[2].RespawnSeconds = 0.001
	local first = Policy.Decide(config(), data, plan, context, memory).IslandCandidates[1].PerMinute
	context.Islands[2].RespawnSeconds = 999
	assert(Policy.Decide(config(), data, plan, context, memory).IslandCandidates[1].PerMinute == first)
end)

test("Invalid strategy names are rejected and qualified selected-island names work", function()
	assert(not pcall(config, { FARMING_SETTINGS = { FARMING_STRATEGY = "TYPO" } }))
	local _, context = policyFixture()
	assert(Policy.IsFarmingArea(pickupFirstConfig({ ISLAND_SETTINGS = { SELECTED_ISLANDS = { "Synthetic/A" } } }), context.Current))
end)

local function coordinatorFixture()
	local profile = { Bubble = { Amount = 0 }, Coins = 100 }
	local reader = { ReadBalances = function() return { Coins = profile.Coins } end, GetLiveProfile = function() return profile end,
		GetSnapshot = function() return {} end, _stat = function() return 100 end }
	local logs = {}
	local controller = { Config = pickupFirstConfig(), Reader = reader, Generation = 1, State = "RUNNING",
		Log = function(_, tag, message) table.insert(logs, tag .. " " .. message) end }
	local coordinator = requireOC("FarmingCoordinator").new(controller, {})
	local area = { Key = "Synthetic/A", Name = "A", World = "Synthetic", Unlocked = true, EligibleCount = 1 }
	local root = { Position = Vector3.new(0, 3.5, 0) }
	coordinator.Tracker.Current = area coordinator.Tracker.Root = function() return root end
	coordinator.Tracker.Refresh = function() end coordinator.Tracker.BackOff = function() end
	coordinator.Mechanics.StopMovement = function() end
	return coordinator, profile, area, root, logs
end

test("Stale generation and excluded pickup tasks never reach the executor", function()
	local coordinator, _, area = coordinatorFixture()
	local invoked = 0 coordinator._collection = function() invoked += 1 end
	local decision = { Kind = "FARM", Mode = "COMBINED", Cluster = { AreaKey = area.Key } }
	assert(coordinator:Definition(decision, 0).Execute({ CheckCancelled = function() return false end }) == nil)
	coordinator.Config.ISLAND_SETTINGS.SELECTED_ISLANDS = { "B" }
	local result = coordinator:Definition(decision, 1).Execute({ CheckCancelled = function() return false end })
	assert(not result.Verified and invoked == 0)
end)

test("Actual background growth and pickup credit share one scheduled collection", function()
	simulated(function(clock)
		local coordinator, profile, area, root = coordinatorFixture()
		local model = { Parent = true }
		local record = { Id = "one", Model = model, Currency = "Coins", Position = Vector3.new(20, 3.5, 0) }
		coordinator:_beginCombined(area.Key)
		coordinator.Mechanics.Blow = function() profile.Bubble.Amount += 10 return true end
		coordinator.Mechanics.Walk = function(_, _, _, _, tick)
			tick() task.wait(1) root.Position = record.Position model.Parent = nil profile.Coins += 10 return true
		end
		local result = coordinator:_collection({ Mode = "COMBINED", Cluster = { AreaKey = area.Key, Position = record.Position,
			Records = { record }, Radius = 7.5, SweepId = 1, SweepRemaining = 1, SweepTotal = 1 } }, { CheckCancelled = function() return false end })
		assert(result.CombinedCreditObserved and coordinator.Cycle.Requests > 0 and coordinator.Cycle.GrowthAt and coordinator.Cycle.PickupAt)
		assert(coordinator:_pickupRates(area.Key, clock.Time).COMBINED == nil, "Unsold cycle cannot publish income")
	end)
end)

test("Native-radius arrival settles without demanding an exact pickup pivot", function()
	simulated(function()
		local coordinator, profile, area, root = coordinatorFixture()
		local model = { Parent = true }
		local record = { Model = model, Currency = "Coins", Position = root.Position + Vector3.new(6, 0, 0) }
		coordinator.Mechanics.Walk = function(_, _, _, _, _, finished) assert(finished()) return true end
		coordinator._settle = function() model.Parent = nil profile.Coins += 10 end
		assert(coordinator:_collection({ Mode = "PICKUPS", Cluster = { AreaKey = area.Key, Position = record.Position,
			Records = { record }, Radius = 7.5, SweepId = 1, SweepRemaining = 1, SweepTotal = 1 } }, { CheckCancelled = function() return false end }).Verified)
	end)
end)

test("Sell saves origin and confirmed return closes exactly one end-to-end cycle", function()
	simulated(function(clock)
		local coordinator, profile, area, root = coordinatorFixture()
		coordinator:_beginCombined(area.Key)
		coordinator.Cycle.Requests, coordinator.Cycle.GrowthAt, coordinator.Cycle.PickupAt = 10, 3, 5
		profile.Bubble.Amount = 100 clock.Time = 20 coordinator.FullSince = 10
		local sellArea = { Key = "Synthetic/B", Name = "B", World = "Synthetic", Unlocked = true }
		local station = { Currency = "Coins", World = "Synthetic", Area = "B", Key = "Sell", Multiplier = 2, Distance = 20,
			Root = { Parent = true, Position = root.Position, Size = { Y = 20 } } }
		coordinator.Mechanics.Travel = function() coordinator.Tracker.Current = sellArea profile.Bubble.Amount = 0 profile.Coins += 50 return true end
		local token = { CheckCancelled = function() return false end }
		assert(coordinator:_sell({ Sell = station }, token).Verified)
		assert(coordinator.ReturnKey == area.Key and coordinator.Cycle.SaleAt and coordinator:_pickupRates(area.Key, clock.Time).COMBINED == nil)
		clock.Time = 30
		coordinator.Mechanics.TravelIsland = function() coordinator.Tracker.Current = area return true, nil, 1 end
		local result = coordinator:Definition({ Kind = "TRAVEL", Island = area, Currency = "Coins", Reason = "return" }, 1).Execute(token)
		assert(result.Verified and coordinator.ReturnKey == nil and coordinator.Cycle == nil)
		local rate = coordinator:_pickupRates(area.Key, clock.Time).COMBINED
		assert(rate.Ready and rate.Seconds == 30 and rate.Earned.Coins == 50 and rate.PerMinute.Coins == 100)
		coordinator:_finishCombined()
		assert(coordinator:_pickupRates(area.Key, clock.Time).COMBINED.Earned.Coins == 50)
	end)
end)

test("Pre-existing bubbles and observed spending cannot create complete combined income", function()
	for _, invalid in ipairs({ "partial", "spending" }) do simulated(function(clock)
		local coordinator, profile, area = coordinatorFixture()
		if invalid == "partial" then profile.Bubble.Amount = 20 end
		coordinator:_beginCombined(area.Key)
		coordinator.Cycle.Requests, coordinator.Cycle.GrowthAt, coordinator.Cycle.PickupAt, coordinator.Cycle.SaleAt = 10, 1, 2, 3
		if invalid == "spending" then coordinator.Cycle.Spending = true end
		profile.Coins += 100 clock.Time = 30 coordinator:_finishCombined()
		assert(coordinator:_pickupRates(area.Key, clock.Time).COMBINED == nil)
	end) end
end)

test("Background tick respects cancellation and full threshold without a request", function()
	local coordinator, profile = coordinatorFixture()
	local calls = 0 coordinator.Mechanics.Blow = function() calls += 1 return true end
	coordinator:_background({ CheckCancelled = function() return true end })
	profile.Bubble.Amount = 100 coordinator:_background({ CheckCancelled = function() return false end })
	assert(calls == 0)
end)

test("Pause retains return intent but discards incomplete measurement and route state", function()
	local coordinator = coordinatorFixture()
	coordinator.ReturnKey, coordinator.RouteContinuation, coordinator.Cycle = "Synthetic/A", {}, {}
	coordinator:Halt(true)
	assert(coordinator.ReturnKey == "Synthetic/A" and coordinator.RouteContinuation == nil and coordinator.Cycle == nil)
	coordinator:Halt()
	assert(coordinator.ReturnKey == nil)
end)

test("Progressing slice expiry retains bounded route intent without unreachable backoff", function()
	simulated(function(clock)
		local coordinator, _, area = coordinatorFixture()
		local backoffs = 0 coordinator.Tracker.BackOff = function() backoffs += 1 end
		coordinator.Mechanics.LastRoute = { Progressed = true }
		coordinator.Mechanics.Walk = function() clock.Time += 6 return false, "Slice ended" end
		coordinator._awaitCredit = function() return { Coins = 100 } end
		local decision = { Mode = "PICKUPS", Cluster = { AreaKey = area.Key, Position = Vector3.new(30, 3.5, 0),
			Records = { { Model = { Parent = true }, Currency = "Coins" } }, Radius = 7.5, SweepId = 1, SweepRemaining = 1, SweepTotal = 1 } }
		local token = { CheckCancelled = function() return false end }
		coordinator:_collection(decision, token)
		assert(coordinator.RouteContinuation and backoffs == 0)
		clock.Time = 25 coordinator:_collection(decision, token)
		assert(coordinator.RouteContinuation == nil and backoffs == 1)
	end)
end)

test("Late failed MoveTo events do not reject a progressing newer waypoint", function()
	simulated(function(clock)
		local scene = walkingFixture()
		clock.Tick = function(dt)
			scene.Moved:Fire(false)
			scene.Root.Position = Vector3.new(math.min(20, scene.Root.Position.X + dt * 16), 3.5, 0)
		end
		assert(scene.Mechanics:Walk(Vector3.new(20, 0, 0), { CheckCancelled = function() return false end }, 6))
		assert(scene.Paths == 1 and scene.Destroyed == 1)
	end)
end)

test("Unrelated currency credit cannot verify a sale and saved return survives failure", function()
	simulated(function()
		local coordinator, profile, area, root = coordinatorFixture()
		profile.Bubble.Amount = 100
		local station = { Currency = "Gems", World = "Synthetic", Area = "B", Key = "Sell", Multiplier = 2, Distance = 20,
			Root = { Parent = true, Position = root.Position, Size = { Y = 20 } } }
		coordinator.Mechanics.Travel = function() profile.Bubble.Amount = 0 profile.Coins += 50 return true end
		coordinator._awaitCredit = function() return { Coins = 150, Gems = 0 } end
		local result = coordinator:_sell({ Sell = station }, { CheckCancelled = function() return false end })
		assert(not result.Verified and result.BubbleReduced and coordinator.ReturnKey == area.Key)
	end)
end)

test("Full-bubble timestamp survives mode changes and observer preempts optional probes", function()
	simulated(function(clock)
		local coordinator, profile = coordinatorFixture()
		local cancels = 0
		coordinator.Controller.Scheduler = { CancelActive = function() cancels += 1 end }
		coordinator.Controller._requestPlan = function() end coordinator.Controller._notify = function() end
		coordinator._logPickupScan = function() end
		profile.Bubble.Amount = 100 coordinator.Activity = { Kind = "FARM", Mode = "COMBINED" }
		coordinator:Observe() assert(coordinator.FullSince == 0 and cancels == 0)
		clock.Time = 3 coordinator.Activity = { Kind = "INSPECT", Probe = true }
		coordinator:Observe() assert(coordinator.FullSince == 0 and cancels == 1)
		clock.Time = 7 coordinator.Activity = { Kind = "FARM", Mode = "PICKUPS" }
		coordinator:Observe() assert(coordinator.FullSince == 0 and cancels == 2)
		profile.Bubble.Amount = 0 coordinator:Observe() assert(coordinator.FullSince == nil)
	end)
end)

test("Pickup-first exploration uses combined farming rather than an isolated arrival probe", function()
	local data, context, plan, memory = policyFixture()
	context.IslandProbeHistory["Synthetic/B:Coins"] = nil
	local decision = Policy.Decide(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Exploration and not decision.Probe)
	context.Current, context.ArrivedAt = context.Islands[2], context.Now
	context.IslandProbeHistory["Synthetic/B:Coins"] = context.Now
	decision = Policy.Decide(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "FARM" and decision.Mode == "COMBINED" and not decision.Probe)
end)

print(string.format("[OC TEST] %d pickup-first regressions passed; %d total. Live owner testing remains pending.", tests - pickupFirstBefore, tests))

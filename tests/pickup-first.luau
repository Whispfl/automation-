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
	local decision = Policy.CompareIncome(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "FARM" and decision.Mode == "COMBINED")
	context.CanBlow, context.BlowBlocker = false, "Bubble Lock"
	decision = Policy.CompareIncome(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Mode == "PICKUPS" and decision.Reason:find("Bubble Lock", 1, true))
end)

test("Background blowing remains available for pickup goals paid in another currency", function()
	local data, context, plan, memory = policyFixture()
	plan.Objective.Metadata.Cost = { Type = "Currency", Currency = "Gems", Amount = 1000 }
	data.Balances.Gems = 0 context.CanTravel = false
	assert(Policy.CompareIncome(pickupFirstConfig(), data, plan, context, memory).Mode == "COMBINED")
end)

test("Excluded current island cannot farm despite dwell, pending sweep or high income", function()
	local data, context, plan, memory = policyFixture()
	context.ArrivedAt, context.ActiveSweepPending = 99, true
	context.Rates.BUBBLES = { Ready = true, PerMinute = { Coins = 999999 } }
	local selected = pickupFirstConfig({ ISLAND_SETTINGS = { SELECTED_ISLANDS = { "B" } } })
	local decision = Policy.CompareIncome(selected, data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Island.Name == "B")
	context.CanTravel = false decision = Policy.CompareIncome(selected, data, plan, context, memory)
	assert(decision.Kind == "INSPECT" and decision.Background and not decision.Cluster)
	context.Islands[2].InBackoff = true
	assert(Policy.CompareIncome(selected, data, plan, context, memory).Kind ~= "FARM")
end)

test("Saved return beats dwell and income while failed origins select an eligible alternative", function()
	local data, context, plan, memory = policyFixture()
	context.ReturnKey = context.Islands[2].Key context.ArrivedAt = 99 context.ActiveSweepPending = true
	context.Rates.COMBINED = { Ready = true, PerMinute = { Coins = 999999 } }
	local decision = Policy.CompareIncome(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Returning and decision.Island.Name == "B")
	context.Islands[2].InBackoff = true
	decision = Policy.CompareIncome(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "INSPECT", "Do not repeatedly issue a backed-off return")
end)

test("Full probes sell before loading or exploration and blocked sales remain explicit", function()
	local data, context, plan, memory = policyFixture()
	data.Bubble.Amount = data.Bubble.Capacity context.FullSince = 1
	context.PickupProbe = { Key = context.Current.Key, Currency = "Coins", ReadyAt = 200 }
	assert(Policy.CompareIncome(pickupFirstConfig(), data, plan, context, memory).Kind == "SELL")
	context.CanInteract = false context.Blocker = "Transition"
	local decision = Policy.CompareIncome(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "WAIT" and decision.Reason:find("Transition", 1, true))
end)

test("Final-mode decision reason cannot cite the replaced bubble score", function()
	local data, context, plan, memory = policyFixture()
	memory.Mode, memory.StartedAt = "PICKUPS", 99
	context.Rates = { PICKUPS = { Ready = true, PerMinute = { Coins = 10 } }, BUBBLES = { Ready = true, PerMinute = { Coins = 999 } } }
	local decision = Policy.CompareIncome(config(), data, plan, context, memory)
	assert(decision.Mode == "PICKUPS" and decision.Reason:find("10.00", 1, true) and not decision.Reason:find("999", 1, true))
end)

test("Observed model latency cannot inflate definition-based island rates", function()
	local data, context, plan, memory = policyFixture()
	context.Islands[2].RespawnSeconds = 0.001
	local first = Policy.CompareIncome(config(), data, plan, context, memory).IslandCandidates[1].PerMinute
	context.Islands[2].RespawnSeconds = 999
	assert(Policy.CompareIncome(config(), data, plan, context, memory).IslandCandidates[1].PerMinute == first)
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
	syntheticBubbleTask(coordinator) -- Capability/credit fixtures now explicitly require bubbles instead of assuming background production.
	local area = { Key = "The Overworld/The Void", Name = "The Void", World = "The Overworld", Unlocked = true, EligibleCount = 1 }
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
	local decision = Policy.CompareIncome(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Exploration and not decision.Probe)
	context.Current, context.ArrivedAt = context.Islands[2], context.Now
	context.IslandProbeHistory["Synthetic/B:Coins"] = context.Now
	decision = Policy.CompareIncome(pickupFirstConfig(), data, plan, context, memory)
	assert(decision.Kind == "FARM" and decision.Mode == "COMBINED" and not decision.Probe)
end)

test("Void and Zen restriction requires the selected world and actual unlocked evidence", function()
	local selected = pickupFirstConfig({ BRAIN_SETTINGS = { SELECTED_WORLDS = { "The Overworld" } },
		ISLAND_SETTINGS = { SELECTED_ISLANDS = { "The Void", "Zen" } } })
	for _, name in ipairs({ "The Void", "Zen", "Floating Island", "Outer Space", "The Overworld" }) do
		local area = { Name = name, World = "The Overworld", Key = "The Overworld/" .. name, Unlocked = true }
		assert(Policy.IsFarmingArea(selected, area) == (name == "The Void" or name == "Zen"))
		area.Unlocked = false assert(not Policy.IsFarmingArea(selected, area))
		area.Unlocked, area.World = true, "Other World" assert(not Policy.IsFarmingArea(selected, area))
	end
end)

print(string.format("[OC TEST] %d pickup-first regressions passed; %d total. Live owner testing remains pending.", tests - pickupFirstBefore, tests))

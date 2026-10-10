-- Offline Phase 2 tests. All balances, models and accounts here are synthetic fixtures.
local Metrics = requireOC("ResourceMetrics")
local Policy = requireOC("FarmingPolicy")
local Mechanics = requireOC("GameMechanics")
local farmingTestsBefore = tests

test("Discovered live currencies appear alongside preserved Phase 1 account fields", function()
	local presentation = requireOC("AccountPresentation")
	local data = fixture() data.Balances.SyntheticIslandCurrency = 77
	local text = presentation.Sections(data, config(), 30).Balances
	assert(text:find("SyntheticIslandCurrency: 77", 1, true))
	assert(text:find("Coins: 100", 1, true) and text:find("Gems: unavailable", 1, true))
end)

test("Observed earnings require sample time and preserve distinct currencies", function()
	local metrics = Metrics.new(config().FARMING_SETTINGS)
	metrics:SetMode("PICKUPS", "Synthetic/A", { Coins = 10, Gems = 5 }, 0)
	metrics:Observe({ Coins = 20, Gems = 7 }, 5)
	assert(not metrics:Rates("Synthetic/A", 5).PICKUPS.Ready)
	metrics:Observe({ Coins = 40, Gems = 8 }, 20)
	local measured = metrics:Rates("Synthetic/A", 20).PICKUPS
	assert(measured.Ready and measured.PerMinute.Coins == 90 and measured.PerMinute.Gems == 9)
	assert(next(metrics:Rates("Synthetic/Other", 20)) == nil)
	assert(next(metrics:Rates("Synthetic/A", 500)) == nil, "Expired observations cannot influence current yields")
end)

test("Spending, stopped sessions and missing balances do not fabricate income", function()
	local metrics = Metrics.new(config().FARMING_SETTINGS)
	metrics:SetMode("PICKUPS", "Synthetic/A", { Coins = 100, Gems = 5 }, 0)
	metrics:Observe({ Coins = 50, Gems = 6 }, 5)
	assert(next(metrics:Rates("Synthetic/A", 5)) == nil, "Mixed spending interval must be excluded")
	metrics:Observe({ Coins = 60 }, 10)
	metrics:SetMode(nil, nil, { Coins = 60 }, 10)
	metrics:Observe({ Coins = 1000 }, 100)
	local measured = metrics:Rates("Synthetic/A", 100).PICKUPS
	assert(measured.Earned.Coins == 10 and measured.Earned.Gems == nil)
	assert(next(metrics:ConfirmCycle({ Coins = 100 }, { Coins = 100 }, "Synthetic disappearance")) == nil)
	assert(metrics.ConfirmedCycles == 0 and metrics.UnconfirmedCycles == 1)
	assert(metrics:ConfirmCycle({ Coins = 100 }, { Coins = 110 }, "Synthetic credit").Coins == 10)
end)

local function policyFixture()
	local data = fixture()
	data.Bubble.Amount = 0
	data.Bubble.PowerPerBlow = 20
	local a = { Key = "Synthetic/A", Name = "A", World = "Synthetic", Unlocked = true,
		Currencies = { Coins = true, Gems = true }, Expected = { Coins = 100, Gems = 2 }, Available = { Coins = 3, Gems = 2 } }
	local b = { Key = "Synthetic/B", Name = "B", World = "Synthetic", Unlocked = true,
		Currencies = { Coins = true, Gems = true }, Expected = { Coins = 120, Gems = 5000 }, Available = {}, Spawn = {} }
	local context = { Current = a, Islands = { a, b }, AreaRates = {}, Rates = {}, Sells = {
		{ Currency = "Coins", World = "Synthetic", Area = "A", Multiplier = 2, Distance = 10 } },
		CanInteract = true, CanBlow = true, CanTravel = true, Now = 100, ArrivedAt = 0, WalkSpeed = 16, Cluster = {}, UpgradeBackoff = {} }
	local plan = { Objective = { Title = "Synthetic goal", Metadata = {} }, Candidates = {} }
	local memory = { Mode = nil, StartedAt = 0, LastTest = { PICKUPS = 100, BUBBLES = 100, COMBINED = 100 } }
	return data, context, plan, memory
end

test("Island selection compares only the goal currency and respects locked access", function()
	local data, context, plan, memory = policyFixture()
	plan.Objective.Metadata.Cost = { Type = "Currency", Currency = "Coins", Amount = 1000 }
	context.Islands[2].Expected.Coins = 101
	local decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Currency == "Coins" and decision.Kind == "FARM", "Thousands of gems must not outrank the coin goal")
	context.Islands[2].Expected.Coins = 1000
	context.Islands[2].Unlocked = false
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Kind ~= "TRAVEL", "Locked islands cannot be selected")
	context.Islands[2].Unlocked = true
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Island.Name == "B")
	context.ActiveSweepPending = true
	assert(Policy.Decide(config(), data, plan, context, memory).Kind ~= "TRAVEL", "Finish eligible frozen sweep before starting another island's sweep")
end)

test("Dwell prevents island ping-pong even when a cluster just emptied", function()
	local data, context, plan, memory = policyFixture()
	context.ArrivedAt = 95 context.Islands[1].Available = {} context.Cluster = nil
	context.Islands[2].Expected.Coins = 1000
	local decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Kind ~= "TRAVEL")
	context.ArrivedAt = 0
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Kind == "TRAVEL")
	context.Islands[2].InBackoff = true
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Kind ~= "TRAVEL", "Failed destinations must stay in backoff")
end)

test("Activity uses goal-specific measured rates and probes a different untested mode", function()
	local data, context, plan, memory = policyFixture()
	context.Rates = {
		PICKUPS = { Ready = true, PerMinute = { Coins = 20, Gems = 5000 } },
		BUBBLES = { Ready = true, PerMinute = { Coins = 200 } },
		COMBINED = { Ready = true, PerMinute = { Coins = 150 } },
	}
	local decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Mode == "BUBBLES")
	memory.Mode, memory.StartedAt = "PICKUPS", 0
	memory.LastTest.BUBBLES = nil memory.LastTest.COMBINED = nil
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Mode == "BUBBLES", "Probe must not get stuck reselecting the current mode")
	plan.Objective.Metadata.Cost = { Type = "Currency", Currency = "Gems", Amount = 1000 }
	data.Balances.Gems = 0
	context.CanTravel = false
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Currency == "Gems" and decision.Mode == "PICKUPS", "Coin sales cannot pay a gem goal")
end)

test("Full bubbles sell first and incomplete bubble probes include the sale cycle", function()
	local data, context, plan, memory = policyFixture()
	data.Bubble.Amount = 99
	local decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Kind == "SELL")
	data.Bubble.Amount = 50
	memory.Mode, memory.StartedAt = "BUBBLES", 0
	context.BubbleProbePending = true
	context.Rates = { PICKUPS = { Ready = true, PerMinute = { Coins = 1000 } }, BUBBLES = { Ready = false, PerMinute = {} } }
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Mode == "BUBBLES", "An unfinished fill must not be mislabeled as a complete sale measurement")
end)

test("Disabled farming, collection, simultaneous mode, travel and fallback cannot schedule their actions", function()
	local data, context, plan, memory = policyFixture()
	context.SceneReady = false
	assert(Policy.Decide(config(), data, plan, context, memory).Kind == "WAIT", "Do not start blindly blowing before native zone inspection")
	context.SceneReady = true
	assert(Policy.Decide(config({ FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false } }), data, plan, context, memory).Kind == "WAIT")
	context.Rates.COMBINED = { Ready = true, PerMinute = { Coins = 1000 } }
	local disabled = config({ BUBBLE_SETTINGS = { ENABLE_SIMULTANEOUS_BLOWING = false } })
	assert(Policy.Decide(disabled, data, plan, context, memory).Mode ~= "COMBINED")
	disabled = config({ PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false } })
	assert(Policy.Decide(disabled, data, plan, context, memory).Mode == "BUBBLES")
	disabled = config({ FARMING_SETTINGS = { ENABLE_EFFICIENCY_COMPARISON = false } })
	context.Rates.BUBBLES = { Ready = true, PerMinute = { Coins = 1000000 } }
	assert(Policy.Decide(disabled, data, plan, context, memory).Mode == "COMBINED", "Disabled comparison cannot pick by a measured yield")
	context.Islands[2].Expected.Coins = 1000
	disabled = config({ ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false } })
	assert(Policy.Decide(disabled, data, plan, context, memory).Kind ~= "TRAVEL")
	memory.Mode = "PICKUPS" context.Cluster = nil
	disabled = config({ FARMING_SETTINGS = { AUTO_FARM_FALLBACK = false } })
	assert(Policy.Decide(disabled, data, plan, context, memory).Kind == "WAIT")
end)

test("Upgrade purchases need measured bubble yield, affordability, gain and goal reserves", function()
	local data, context, plan, memory = policyFixture()
	local enabled = config({ BUBBLE_SETTINGS = { AUTO_BUY_GUM = true, ENABLE_SIMULTANEOUS_BLOWING = false } })
	context.EffectiveUpgrades = { ["Synthetic test gum"] = { Capacity = 200, Power = 20 } }
	context.Rates = { PICKUPS = { Ready = true, PerMinute = { Coins = 1 } }, BUBBLES = { Ready = true, PerMinute = { Coins = 1000 } } }
	local decision = Policy.Decide(enabled, data, plan, context, memory)
	assert(decision.Kind == "UPGRADE" and decision.Upgrade.Kind == "Gum")
	plan.Objective.Metadata.Cost = { Type = "Currency", Currency = "Coins", Amount = 90 }
	assert(Policy.Decide(enabled, data, plan, context, memory).Kind ~= "UPGRADE")
	plan.Objective.Metadata.Cost = nil
	context.Rates.BUBBLES.Ready = false
	assert(Policy.Decide(enabled, data, plan, context, memory).Kind ~= "UPGRADE")
	context.Rates.BUBBLES.Ready = true
	assert(Policy.Decide(config(), data, plan, context, memory).Kind ~= "UPGRADE", "Purchases must remain opt-in by default")
end)

test("Native purchase adapter rechecks live funds and verifies received ownership", function()
	local profile = { Coins = 100, Gum = {}, AreasUnlocked = { A = true }, WorldsUnlocked = { Synthetic = true }, Bubble = { Gum = "Old" } }
	local calls = {}
	local dependencies = { Gum = { New = { Area = "A", Storage = 200, Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } } },
		Remote = { FireServer = function(_, command, name)
			table.insert(calls, { command, name }) profile.Gum[name] = true
		end } }
	local reader = { GetLiveProfile = function() return profile end, _dependency = function(_, name) return dependencies[name] end }
	local mechanics = Mechanics.new(config({ BUBBLE_SETTINGS = { AUTO_BUY_GUM = true } }), reader, {}, {})
	mechanics.Guard = function() return true end
	local token = { CheckCancelled = function() return false end }
	local upgrade = { Name = "New", Kind = "Gum", Reserve = 80 }
	assert(not mechanics:Upgrade(upgrade, token) and #calls == 0, "Stale plan cannot overspend the live reserve")
	upgrade.Reserve = 0
	assert(mechanics:Upgrade(upgrade, token) and calls[1][1] == "GumShopPurchase" and #calls == 1)
	local disabled = Mechanics.new(config(), reader, {}, {}) disabled.Guard = function() return true end
	assert(not disabled:Upgrade(upgrade, token) and #calls == 1)
	assert(not disabled:Blow(token) and #calls == 1, "Missing bubble guards must not issue commands")
end)

test("Stopping an idle or disabled system never moves the player", function()
	local invoked = 0
	local mechanics = Mechanics.new(config({ FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false } }), {}, {
		Root = function() invoked += 1 error("Idle cleanup must not acquire movement") end }, {})
	mechanics:StopMovement()
	assert(invoked == 0)
end)

test("Frozen island sweep includes all currencies before newly spawned coins", function()
	local Tracker = requireOC("PickupTracker")
	local root, humanoid = { Position = Vector3.new(0, 0, 0) }, { WalkSpeed = 16, Health = 100 }
	local player = { Character = { FindFirstChild = function() return root end, FindFirstChildOfClass = function() return humanoid end } }
	local reader = { GetLiveProfile = function() return {} end, _dependency = function() return { GetPickupRange = function() return 10 end } end }
	local tracker = Tracker.new(config(), reader, player)
	tracker.Current = { Key = "Synthetic/A" }
	local coinModel, gemModel = { Parent = true }, { Parent = true }
	local coin = { Model = coinModel, Id = "coin", Position = Vector3.new(1, 0, 0), Currency = "Coins", Amount = 10, AreaKey = "Synthetic/A" }
	local gem = { Model = gemModel, Id = "gem", Position = Vector3.new(30, 0, 0), Currency = "Gems", Amount = 5, AreaKey = "Synthetic/A" }
	tracker.Models[coinModel], tracker.Models[gemModel] = coin, gem
	local first = tracker:Cluster("Coins")
	assert(first.SweepTotal == 2 and first.Records[1] == coin)
	tracker.Models[coinModel] = nil tracker.Sweep.Pending[coinModel] = nil coinModel.Parent = nil
	local respawn = { Model = { Parent = true }, Id = "newcoin", Position = Vector3.new(1, 0, 0), Currency = "Coins", Amount = 1000, AreaKey = "Synthetic/A" }
	tracker.Models[respawn.Model] = respawn
	local second = tracker:Cluster("Coins")
	assert(second.SweepId == first.SweepId and second.Records[1] == gem, "New coins cannot starve pending gems")
	tracker:BackOff(second.Records, 30, "Synthetic blocked path")
	assert(tracker.Backoff.gem and tracker.Sweep.Pending[gemModel] == nil)
	local third = tracker:Cluster("Coins")
	assert(third.SweepId ~= first.SweepId and third.Records[1] == respawn)
	tracker:Destroy()
end)

print("[OC TEST] " .. (tests - farmingTestsBefore) .. " Phase 2 offline tests passed; " .. tests .. " total. Phase 2 live verification awaits the owner.")

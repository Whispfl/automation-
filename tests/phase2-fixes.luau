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


print(string.format("[OC TEST] %d additional Phase 2 regression tests passed; %d total. Live owner verification remains pending.", tests - fixesBefore, tests))

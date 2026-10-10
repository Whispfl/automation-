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
	context.IslandProbeHistory = { ["Synthetic/A:Coins"] = 100, ["Synthetic/B:Coins"] = 100, ["Synthetic/A:Gems"] = 100, ["Synthetic/B:Gems"] = 100 }
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
	local enabled = config({ BUBBLE_SETTINGS = { AUTO_BUY_GUM = true, ENABLE_SIMULTANEOUS_BLOWING = false }, UPGRADE_SETTINGS = { MAXIMUM_GOAL_RESERVE_BALANCE_FRACTION = 1 } })
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
			table.insert(calls, { command, name }) profile.Gum[name] = true profile.Coins -= 10
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

test("Unknown yields stay visible and missing local spawns do not suppress supported native destinations", function()
	local data, context, plan, memory = policyFixture()
	local area = context.Islands[2]
	area.Expected = {} area.Spawn = nil area.DestinationPath = "Workspace.Worlds.Synthetic.Islands.B.Island.Portal.Spawn"
	context.Rates.BUBBLES = { Ready = true, PerMinute = { Coins = 18000 } }
	context.IslandProbeHistory["Synthetic/B:Coins"] = nil
	local decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Probe and decision.Island == area, "Measured bubbles cannot permanently suppress unknown pickup trials")
	local found
	for _, candidate in ipairs(decision.IslandCandidates) do if candidate.Area == area then found = candidate end end
	assert(found and found.PerMinute == nil and found.Evidence:find("UNKNOWN", 1, true), "Unknown income cannot become a fabricated estimate")
	area.ZoneCount = 0
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Kind ~= "TRAVEL")
	local reason
	for _, row in ipairs(decision.IslandDiagnostics) do if row.Area == area then reason = row.Reason end end
	assert(reason and reason:find("No live tagged", 1, true))
end)

test("Island discovery diagnostics explain every exclusion and trials respect configuration and dwell", function()
	local data, context, plan, memory = policyFixture()
	context.IslandProbeHistory = {}
	local decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Probe and decision.Kind == "INSPECT", "Current-island loading trial precedes unknown destinations")
	context.PickupProbe = { Key = context.Current.Key, Currency = "Coins", StartedAt = 100 }
	memory.Mode = "BUBBLES" context.Rates.BUBBLES = { Ready = true, PerMinute = { Coins = 18000 } }
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(decision.Mode == "PICKUPS", "Isolated trial must not become combined income or a global-mode hold")
	context.Cluster = nil
	assert(Policy.Decide(config(), data, plan, context, memory).Kind == "INSPECT")
	context.PickupProbe = nil context.Cluster = {}
	local disabled = config({ ISLAND_SETTINGS = { AUTO_EXPLORE_UNLOCKED_ISLANDS = false } })
	assert(not Policy.Decide(disabled, data, plan, context, memory).Probe)
	context.ArrivedAt = 95
	assert(not Policy.Decide(config(), data, plan, context, memory).Probe)
	context.ArrivedAt = 0 context.Islands[2].Unlocked = false
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(#decision.IslandDiagnostics == 2 and #decision.IslandCandidates == 1)
	assert(decision.IslandDiagnostics[2].Reason:find("not discovered", 1, true))
	context.Islands[2].Unlocked = true context.Islands[2].MappingWarning = "Mismatched native reward pool"
	decision = Policy.Decide(config(), data, plan, context, memory)
	assert(#decision.IslandCandidates == 1 and decision.IslandDiagnostics[2].Reason == context.Islands[2].MappingWarning)
end)

test("Tracker keeps distinct Floating Island and Outer Space zones, counts, metadata and discovery membership", function()
	local Tracker = requireOC("PickupTracker")
	local original = workspace.FindFirstChild
	local function node(name, kind, parent)
		local object = { Name = name, ClassName = kind, Parent = parent, Children = {} }
		if parent and parent.Children then parent.Children[name] = object end
		function object:FindFirstChild(child) return self.Children[child] end
		function object:GetChildren() local items = {} for _, child in pairs(self.Children) do table.insert(items, child) end return items end
		function object:GetDescendants() return {} end
		function object:IsA(class) return class == self.ClassName or (class == "BasePart" and self.ClassName == "Part") end
		function object:IsDescendantOf(ancestor) local at = self.Parent while at do if at == ancestor then return true end at = at.Parent end return false end
		function object:GetFullName() return self.Parent and self.Parent.GetFullName and self.Parent:GetFullName() .. "." .. self.Name or self.Name end
		return object
	end
	local worlds = node("Worlds", "Folder", workspace)
	local world = node("The Overworld", "Folder", worlds)
	local islands = node("Islands", "Folder", world)
	local floating = node("Floating Island", "Folder", islands)
	local outer = node("Outer Space", "Folder", islands)
	local floatingModel = node("Island", "Model", floating)
	local outerModel = node("Island", "Model", outer)
	local zoneRoot = node("Pickup", "Folder", floatingModel)
	local spaceRoot = node("Pickups", "Folder", outerModel)
	local rendered = node("Rendered", "Folder", workspace)
	local pickupFolder = node("Pickups", "Folder", rendered)
	workspace.FindFirstChild = function(_, name) return name == "Worlds" and worlds or (name == "Rendered" and rendered or nil) end
	local root = { Position = Vector3.new(0, 423, 0) }
	local player = { Character = { FindFirstChild = function() return root end, FindFirstChildOfClass = function() return { Health = 100 } end } }
	local pool = { { Chance = 100, Item = { Visual = "Coin", Item = { Type = "Currency", Currency = "Coins", Amount = 5 } } } }
	local function zone(height) return { Height = height, GetDistanceToPoint = function() return 0 end, IsPointInside = function() return true end } end
	local zones = { [zoneRoot] = { Area = "Floating Island", Count = 5, Zone = zone(420), Pickups = pool } }
	for index = 1, 4 do
		local point = node(tostring(index), "Part", spaceRoot)
		zones[point] = { Area = "Outer Space", Count = 2, Zone = zone(2660), Pickups = pool }
	end
	local reader = { GetLiveProfile = function() return {} end, RegisterCurrency = function() end,
		_dependency = function(_, name) if name == "GetPickupZones" then return function() return zones end end
			if name == "Worlds" then return { ["The Overworld"] = { Islands = { { Name = "Absent geometry" } } } } end
			if name == "StatsUtil" then return { GetCurrencyMultiplier = function() return 2 end } end end }
	local tracker = Tracker.new(config(), reader, player)
	local snapshot = { UnlockedWorlds = { ["The Overworld"] = true }, UnlockedIslands = { ["Floating Island"] = false, ["Outer Space"] = true },
		AvailableProgression = { Islands = { { Name = "Floating Island", World = "The Overworld" }, { Name = "Outer Space", World = "The Overworld" }, { Name = "Not loaded", World = "The Overworld" } } } }
	tracker:Refresh(snapshot, 100)
	local f, s = tracker.Areas["The Overworld/Floating Island"], tracker.Areas["The Overworld/Outer Space"]
	assert(f and s and f ~= s and f.ConfiguredCount == 5 and s.ConfiguredCount == 8)
	assert(f.Unlocked and f.Discovered and s.Unlocked, "Native membership is non-nil, not truthiness")
	assert(tracker.Current == f and f.Spawn == nil and f.CatalogKnown and f.DestinationPath:find("Floating Island", 1, true))
	assert(f.Expected.Coins == 50 and s.Expected.Coins == 80, "Only actual zone counts/pools/helpers may estimate yield")
	assert(tracker.Areas["The Overworld/Not loaded"].ZoneCount == 0)
	assert(tracker.Areas["The Overworld/Absent geometry"].ZoneCount == 0, "Defined absent scene islands must still have explicit diagnostics")
	local model = node("synthetic-id", "Model", pickupFolder)
	function model:GetPivot() return { Position = Vector3.new(0, 423, 0) } end
	tracker.Metadata[model.Name] = { Root = zoneRoot, Visual = "Coin", At = 100 }
	tracker:Refresh(snapshot, 101)
	assert(tracker.Models[model].AreaKey == f.Key and tracker.Current.EligibleCount == 1)
	snapshot.UnlockedIslands["Outer Space"] = nil
	tracker:Refresh(snapshot, 102)
	assert(not tracker.Areas[s.Key].Unlocked and not tracker.Areas[s.Key].Discovered)
	tracker:Destroy() workspace.FindFirstChild = original
end)

test("Native island path requests require real access and cannot report success without observed arrival", function()
	local profile = { WorldsUnlocked = { Synthetic = true }, AreasUnlocked = { B = true } }
	local requests, cancelled = {}, false
	local reader = { GetLiveProfile = function() return profile end, GetSnapshot = function() return {} end,
		_dependency = function() return { FireServer = function(_, command, path) table.insert(requests, { command, path }) end } end }
	local target = { Key = "Synthetic/B", World = "Synthetic", Name = "B", CatalogKnown = true,
		DestinationPath = "Workspace.Worlds.Synthetic.Islands.B.Island.Portal.Spawn",
		Zones = { { Data = { Zone = { Height = 400, GetDistanceToPoint = function() return 0 end } } } } }
	local tracker = { Current = { Key = target.Key, Zones = target.Zones }, Refresh = function() end,
		Root = function() return { Position = Vector3.new(0, 0, 0) } end }
	local mechanics = Mechanics.new(config(), reader, tracker, {}) mechanics.Guard = function() return true end
	local result, reason
	local token = { CheckCancelled = function() return cancelled end }
	local thread = coroutine.create(function() result, reason = mechanics:TravelIsland(target, token) end)
	assert(coroutine.resume(thread))
	assert(#requests == 1 and requests[1][1] == "Teleport" and requests[1][2] == target.DestinationPath)
	assert(result == nil, "Matching name alone cannot verify arrival at a different island height")
	cancelled = true assert(coroutine.resume(thread))
	assert(result == false and reason == "Cancelled")
	cancelled = false mechanics.LastTravelAt = -math.huge profile.AreasUnlocked.B = nil
	assert(not mechanics:TravelIsland(target, token) and #requests == 1, "Recheck fresh discovery before native request")
	profile.AreasUnlocked.B = true target.CatalogKnown = false
	assert(not mechanics:TravelIsland(target, token) and #requests == 1, "Unknown paths cannot be requested")
end)

test("Pickup trial ends on an actual sample or timeout and bubble sales cannot become pickup earnings", function()
	local Coordinator = requireOC("FarmingCoordinator")
	local data, context = policyFixture()
	local messages = {}
	local profile = { Bubble = { Amount = 0 } }
	local controller = { Config = config(), State = "RUNNING", Brain = Brain.new(config()), Generation = 1,
		Reader = { GetSnapshot = function() return data end, GetLiveProfile = function() return profile end,
			ReadBalances = function() return { Coins = 100 } end, _stat = function() return 100 end },
		Log = function(_, _, message) table.insert(messages, message) end, _requestPlan = function() end, _notify = function() end }
	local coordinator = Coordinator.new(controller, {})
	coordinator.Tracker.Current = context.Current coordinator.Tracker.Current.EligibleCount = 1
	coordinator.Tracker.Refresh = function() end
	local now = os.clock()
	coordinator.PickupProbe = { Key = context.Current.Key, Currency = "Coins", StartedAt = now }
	coordinator.Decision = { Currency = "Coins" }
	coordinator.Metrics.Samples = { { At = now, Seconds = 15, Mode = "PICKUPS", Scope = context.Current.Key, Gains = { Coins = 10 } } }
	coordinator:Observe()
	assert(coordinator.PickupProbe ~= nil, "An elapsed sample alone is not pickup collection proof")
	coordinator.PickupProbe.Attempts = 1 coordinator.PickupProbe.Confirmed = true
	coordinator:Observe()
	assert(coordinator.PickupProbe == nil and coordinator.IslandProbeHistory[context.Current.Key .. ":Coins"])
	assert(messages[#messages]:find("actual sample", 1, true))
	coordinator.Metrics.Samples = {}
	coordinator.PickupProbe = { Key = context.Current.Key, Currency = "Coins", StartedAt = os.clock() - 46 }
	coordinator:Observe()
	assert(coordinator.PickupProbe == nil and messages[#messages]:find("remains unverified", 1, true))
	coordinator.Metrics:SetMode("PICKUPS", context.Current.Key, { Coins = 100 }, os.clock())
	coordinator.PickupProbe = { Key = context.Current.Key, Currency = "Coins", StartedAt = os.clock() }
	coordinator._sell = function() assert(coordinator.Metrics.Active == nil and coordinator.PickupProbe == nil) return { Verified = true } end
	local decision = { Kind = "SELL", Sell = {}, Currency = "Coins" }
	assert(coordinator:Definition(decision, 1).Execute({ CheckCancelled = function() return false end }).Verified)
	coordinator.Metrics:SetMode("BUBBLES", context.Current.Key, { Coins = 100 }, os.clock())
	coordinator._sell = function() assert(coordinator.Metrics.Active.Mode == "BUBBLES") return { Verified = true } end
	assert(coordinator:Definition(decision, 1).Execute({ CheckCancelled = function() return false end }).Verified)
	coordinator:Destroy()
end)


-- Reproduces the verified native Model/folder/prefab contract, using synthetic geometry.
local function pickupScene()
	local Tracker = requireOC("PickupTracker")
	local oldWorkspace, oldStorage = workspace.FindFirstChild, services.ReplicatedStorage.FindFirstChild
	local function node(name, kind, parent)
		local object = { Name = name, ClassName = kind, Parent = parent, Children = {} }
		if parent and parent.Children then table.insert(parent.Children, object) end
		function object:GetChildren() return self.Children end
		function object:FindFirstChild(name) for _, child in ipairs(self.Children) do if child.Name == name then return child end end end
		function object:GetDescendants()
			local result = {} for _, child in ipairs(self.Children) do table.insert(result, child) for _, descendant in ipairs(child:GetDescendants()) do table.insert(result, descendant) end end return result
		end
		function object:IsA(class) return class == self.ClassName or (class == "BasePart" and (self.ClassName == "Part" or self.ClassName == "MeshPart")) end
		function object:IsDescendantOf(ancestor) local at = self.Parent while at do if at == ancestor then return true end at = at.Parent end return false end
		function object:GetFullName() return self.Parent and self.Parent.GetFullName and self.Parent:GetFullName() .. "." .. self.Name or self.Name end
		function object:GetPivot() return { Position = self.Position } end
		return object
	end
	local worlds = node("Worlds", "Folder", workspace)
	local world = node("Synthetic", "Folder", worlds)
	local islands = node("Islands", "Folder", world)
	local a = node("A", "Folder", islands)
	local island = node("Island", "Model", a)
	local zoneRoot = node("Pickup", "Folder", island)
	local rendered = node("Rendered", "Folder", workspace)
	local folder = node("Pickups", "Folder", rendered)
	local stages = node("Stages", "Folder", workspace)
	local assets = node("Assets", "Folder", services.ReplicatedStorage)
	local prefabs = node("Pickups", "Folder", assets)
	workspace.FindFirstChild = function(_, name) return ({ Worlds = worlds, Rendered = rendered, Stages = stages })[name] end
	services.ReplicatedStorage.FindFirstChild = function(_, name) return name == "Assets" and assets or nil end
	local root, humanoid = { Position = Vector3.new(0, 103.5, 0) }, { Health = 100, WalkSpeed = 16 }
	local pool = { { Chance = 100, Item = { Visual = "Gem", Item = { Type = "Currency", Currency = "Gems", Amount = 5 } } } }
	local geometry = { Height = 100, GetDistanceToPoint = function() return 0 end }
	local zones = { [zoneRoot] = { Area = "A", Count = 5, Zone = geometry, Pickups = pool } }
	local reader = { GetLiveProfile = function() return {} end, RegisterCurrency = function() end,
		_dependency = function(_, name)
			if name == "GetPickupZones" then return function() return zones end end
			if name == "Worlds" then return { Synthetic = { Islands = { { Name = "A" }, { Name = "B" } } } } end
			if name == "StatsUtil" then return { GetCurrencyMultiplier = function() return 2 end, GetPickupRange = function() return 7.5 end } end
		end }
	local tracker = Tracker.new(config(), reader, { Character = { FindFirstChild = function() return root end, FindFirstChildOfClass = function() return humanoid end } })
	local snapshot = { UnlockedWorlds = { Synthetic = true }, UnlockedIslands = { A = true, B = true }, AvailableProgression = { Islands = {} } }
	local function meshModel(name, parent, meshId)
		local model = node(name, "Model", parent) model.Position = Vector3.new(1, 102, 0)
		local mesh = node("NativeMesh", "MeshPart", model)
		mesh.MeshId, mesh.TextureID, mesh.Size = meshId or "synthetic-mesh", "synthetic-texture", Vector3.new(2, 2, 2)
		return model
	end
	return { Tracker = tracker, Snapshot = snapshot, Node = node, Zones = zones, ZoneRoot = zoneRoot, Island = island,
		Folder = folder, Prefabs = prefabs, Stages = stages, Pool = pool, Geometry = geometry, Root = root, MeshModel = meshModel,
		Close = function() tracker:Destroy() workspace.FindFirstChild = oldWorkspace services.ReplicatedStorage.FindFirstChild = oldStorage end }
end

test("Cold-start scanning accepts duplicate same-name Gem prefabs and overlapping same-island zones", function()
	local scene = pickupScene()
	for index = 1, 4 do scene.MeshModel("Gem", scene.Prefabs) end
	local existing = scene.MeshModel("existing-native-id", scene.Folder)
	local extra = scene.Node("SecondZone", "Part", scene.Island)
	scene.Zones[extra] = { Area = "A", Count = 1, Zone = scene.Geometry, Pickups = scene.Pool }
	scene.Tracker:Refresh(scene.Snapshot, 100)
	local report, record = scene.Tracker.ScanReport, scene.Tracker.Models[existing]
	assert(report.Models == 1 and report.CurrencyCount == 1 and report.Unidentified == 0)
	assert(record.Currency == "Gems" and record.Source == "LIVE_PREFAB_GEOMETRY" and record.RouteEligible)
	assert(scene.Tracker:Cluster("Coins").Records[1] == record, "All native currencies participate in the frozen sweep")
	scene.Folder.Children = {} existing.Parent = nil scene.Tracker:Refresh(scene.Snapshot, 101)
	assert(scene.Tracker.Models[existing] == nil and scene.Tracker.ScanReport.RenderedObjects == 0)
	local respawn = scene.MeshModel("new-native-id", scene.Folder)
	scene.Tracker:Refresh(scene.Snapshot, 102)
	assert(scene.Tracker.Models[respawn].Currency == "Gems" and scene.Tracker.RespawnObservations == 1)
	scene.Close()
end)

test("Delayed prefabs recover on bounded refresh and distinct ambiguous visuals remain rejected", function()
	local scene = pickupScene()
	local existing = scene.MeshModel("existing-native-id", scene.Folder)
	scene.Tracker:Refresh(scene.Snapshot, 100)
	assert(scene.Tracker.ScanReport.Unidentified == 1)
	scene.MeshModel("Gem", scene.Prefabs)
	scene.Tracker:Refresh(scene.Snapshot, 101)
	assert(scene.Tracker.Models[existing].Currency == nil)
	scene.Tracker:Refresh(scene.Snapshot, 115)
	assert(scene.Tracker.Models[existing].Currency == "Gems")
	scene.MeshModel("Coin", scene.Prefabs)
	table.insert(scene.Pool, { Chance = 100, Item = { Visual = "Coin", Item = { Type = "Currency", Currency = "Coins", Amount = 10 } } })
	scene.Tracker:Refresh(scene.Snapshot, 130)
	assert(scene.Tracker.Models[existing].Currency == nil and scene.Tracker.ScanReport.Rejected["Ambiguous prefab visuals in native pool"] == 1)
	scene.Close()
end)

test("Jump-stage Area labels resolve to real worlds but cannot inflate island farming yields", function()
	local scene = pickupScene()
	local transit = scene.Node("Node", "Part", scene.Stages)
	scene.Zones[transit] = { Area = "A", Count = 90, Zone = { Height = 2000, GetDistanceToPoint = function() return 0 end }, Pickups = scene.Pool }
	scene.MeshModel("Gem", scene.Prefabs)
	local model = scene.MeshModel("transit-id", scene.Folder) model.Position = Vector3.new(0, 2002, 0)
	scene.Tracker:Refresh(scene.Snapshot, 100)
	local area = scene.Tracker.Areas["Synthetic/A"]
	assert(area.ZoneCount == 1 and area.TransitZoneCount == 1 and area.ConfiguredCount == 5 and area.Expected.Gems == 50)
	assert(scene.Tracker.Areas["Live event/A"] == nil)
	assert(scene.Tracker.Models[model].Currency == "Gems" and not scene.Tracker.Models[model].RouteEligible)
	assert(scene.Tracker:Cluster("Gems") == nil)
	scene.Close()
end)

test("Different-area overlap requires metadata and unexpected native classes are diagnosed", function()
	local scene = pickupScene()
	scene.MeshModel("Gem", scene.Prefabs)
	local existing = scene.MeshModel("existing-id", scene.Folder)
	local other = scene.Node("OtherArea", "Part", workspace)
	scene.Zones[other] = { Area = "B", Count = 1, Zone = scene.Geometry, Pickups = scene.Pool }
	scene.Node("Unexpected", "Part", scene.Folder)
	scene.Tracker:Refresh(scene.Snapshot, 100)
	assert(scene.Tracker.ScanReport.Unidentified == 1 and scene.Tracker.ScanReport.Rejected["Unexpected native pickup class Part"] == 1)
	assert(scene.Tracker.ScanReport.Rejected["Overlapping zones from different areas; metadata required"] == 1)
	scene.Tracker.Metadata[existing.Name] = { Root = scene.ZoneRoot, Visual = "Gem", At = 100 }
	scene.Tracker:Refresh(scene.Snapshot, 101)
	assert(scene.Tracker.Models[existing].Currency == "Gems")
	scene.Tracker.Config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING = false
	local at = scene.Tracker.ScanReport.At scene.Tracker:Refresh(scene.Snapshot, 102)
	assert(scene.Tracker.ScanReport.At == at and scene.Tracker:Cluster("Gems") == nil)
	scene.Close()
end)

test("Radius routing uses a midpoint to cover two pickups with one movement", function()
	local scene = pickupScene()
	scene.MeshModel("Gem", scene.Prefabs)
	local first, second = scene.MeshModel("first", scene.Folder), scene.MeshModel("second", scene.Folder)
	first.Position, second.Position = Vector3.new(20, 103.5, -6), Vector3.new(20, 103.5, 6)
	scene.Tracker:Refresh(scene.Snapshot, 100)
	local cluster = scene.Tracker:Cluster("Gems")
	assert(#cluster.Records == 2 and cluster.Position.X == 20 and cluster.Position.Z == 0 and cluster.Radius == 7.5)
	scene.Close()
end)

test("Full bubbles preempt both loading grace and an active isolated pickup trial", function()
	local data, context, plan, memory = policyFixture()
	data.Bubble.Amount = data.Bubble.Capacity
	context.PickupProbe = { Key = context.Current.Key, Currency = "Coins", StartedAt = 103, ReadyAt = 103 }
	local result = Policy.Decide(config(), data, plan, context, memory)
	assert(result.Kind == "SELL", "Full bubbles cannot be held for isolated loading grace")
	context.Now = 104 result = Policy.Decide(config(), data, plan, context, memory)
	assert(result.Kind == "SELL")
	context.PickupProbe = nil
	assert(Policy.Decide(config(), data, plan, context, memory).Kind == "SELL", "Presell already-full bubbles before a new trial")
end)

test("Collection needs disappearance and matching balance credit; combined gains stay unattributed", function()
	local Coordinator = requireOC("FarmingCoordinator")
	local coins, disappear, credit = 100, false, false
	local controller = { Config = config(), Reader = { ReadBalances = function() return { Coins = coins } end, GetSnapshot = function() return {} end, GetLiveProfile = function() return {} end }, Log = function() end }
	local coordinator = Coordinator.new(controller, {})
	local model = { Parent = true }
	coordinator.Tracker.Current = { Key = "Synthetic/A", Name = "A", World = "Synthetic", Unlocked = true, VisibleCount = 1, EligibleCount = 1 }
	coordinator.Tracker.Refresh = function() end coordinator.Tracker.BackOff = function() end
	coordinator.Mechanics.Walk = function() if disappear then model.Parent = nil end if credit then coins += 10 end return true end
	coordinator._settle = function() end coordinator._awaitCredit = function() return { Coins = coins } end
	local decision = { Mode = "PICKUPS", Cluster = { Records = { { Model = model, Currency = "Coins" } }, AreaKey = "Synthetic/A", Position = Vector3.new(0, 0, 0), Radius = 7.5, SweepId = 1, SweepRemaining = 1, SweepTotal = 1 } }
	local token = { CheckCancelled = function() return false end }
	disappear = true assert(not coordinator:_collection(decision, token).Verified)
	model.Parent = true disappear = false credit = true assert(not coordinator:_collection(decision, token).Verified)
	model.Parent = true disappear = true credit = true assert(coordinator:_collection(decision, token).Verified)
	assert(coordinator.PickupEvidence["Synthetic/A:Coins"] and coordinator.Metrics.ConfirmedCycles == 1)
	model.Parent = true decision.Mode = "COMBINED" assert(not coordinator:_collection(decision, token).Verified)
	model.Parent = true decision.Mode = "PICKUPS"
	controller.Reader.GetLiveProfile = function() return { Bubble = { Amount = model.Parent and 100 or 0 } } end
	assert(not coordinator:_collection(decision, token).Verified, "Observed bubble selling cannot verify pickup credit")
	model.Parent = true decision.Mode = "COMBINED"
	assert(not coordinator:_collection(decision, token).CombinedCreditObserved, "Mixed sale credit cannot demonstrate combined pickup contribution")
	coordinator:Destroy()
end)

test("Pathfinding floor waypoints allow the normal HumanoidRootPart height offset", function()
	local root = { Position = Vector3.new(0, 3.5, 0), Parent = true }
	local humanoid = { MoveTo = function(_, point) root.Position = Vector3.new(point.X, 3.5, point.Z) end, Move = function() end }
	local mechanics = Mechanics.new(config(), {}, { Root = function() return root, humanoid end }, {})
	mechanics.Guard = function() return true, nil, root, humanoid end
	local destroyed = false
	local path = { Status = Enum.PathStatus.Success, Blocked = event().Event, ComputeAsync = function() end,
		GetWaypoints = function() return { { Position = Vector3.new(0, 0, 0) }, { Position = Vector3.new(10, 0, 0) } } end,
		Destroy = function() destroyed = true end }
	services.PathfindingService = { CreatePath = function() return path end }
	local oldSpawn = task.spawn
	task.spawn = function(callback) local thread = coroutine.create(callback) assert(coroutine.resume(thread)) return thread end
	local success, reason = mechanics:Walk(Vector3.new(10, 0, 0), { CheckCancelled = function() return false end }, os.clock() + 6)
	task.spawn = oldSpawn services.PathfindingService = nil
	assert(success and destroyed and reason == "Cluster reached")
end)

test("GameKnowledge reuses native definitions without claiming server or action verification", function()
	local Knowledge = requireOC("GameKnowledge")
	local native = { Synthetic = { Islands = {} } }
	local reader = { Dependencies = { Worlds = { Status = "READY", Path = "Shared.Data.Worlds", Value = native } },
		_dependency = function(_, name) return name == "Worlds" and native or nil end }
	local knowledge = Knowledge.new(reader)
	assert(knowledge:Get("Worlds") == native and knowledge:Get("UninspectedFeature") == nil)
	local status = knowledge:GetStatus()
	assert(status.Dependencies.Worlds.Source == "ReplicatedStorage.Shared.Data.Worlds")
	assert(status.Pickup.ServerValidation == "UNAVAILABLE" and status.ServerOnlyRules == "UNAVAILABLE")
	assert(not status.Pickup.IslandWideBatchFound and status.Pickup.Evidence:find("owner verification", 1, true))
	assert(status.Pickup.RenderedClass == "Model" and status.Pickup.AssetSource == "ReplicatedStorage.Assets.Pickups")
	status.Pickup.RenderedClass = "Part"
	assert(knowledge:PickupContract().RenderedClass == "Model", "Status callers cannot overwrite the knowledge contract")
end)



test("Native registry discovers preexisting IDs despite an empty legacy pickup folder", function()
	local scene = pickupScene()
	scene.MeshModel("Gem", scene.Prefabs)
	local chunk = scene.Node("Chunker", "Folder", scene.Folder.Parent)
	local existing = scene.MeshModel("preexisting-native-id", chunk)
	local registry = { [existing.Name] = existing }
	local tutorial = { _activePickups = registry }
	local dependency = scene.Tracker.Reader._dependency
	scene.Tracker.Reader._dependency = function(reader, name) return name == "Tutorial" and tutorial or dependency(reader, name) end
	scene.Tracker:Refresh(scene.Snapshot, 100)
	local report, record = scene.Tracker.ScanReport, scene.Tracker.Models[existing]
	assert(report.LegacyObjects == 0 and report.RegistryEntries == 1 and report.RegistryActiveIds == 1 and report.CandidateIds == 1)
	assert(report.PositionsResolved == 1 and record.IdSource == "NATIVE_ACTIVE_REGISTRY" and record.Currency == "Gems")
	assert(scene.Tracker:Cluster("Gems").Records[1] == record and scene.Tracker:IsActive(record))
	assert(registry[existing.Name] == existing and existing.Parent == chunk, "Reading native state must not alter models or registry")
	existing.Name = "changed-native-id"
	tutorial._activePickups = { [existing.Name] = existing }
	scene.Tracker:Refresh(scene.Snapshot, 101)
	assert(not scene.Tracker:IsActive(record) and scene.Tracker.Models[existing].Id == existing.Name, "Changed IDs invalidate previously frozen target records")
	local replacement = scene.MeshModel("new-native-id", chunk)
	tutorial._activePickups = { [replacement.Name] = replacement }
	scene.Tracker:Refresh(scene.Snapshot, 102)
	assert(scene.Tracker.Models[existing] == nil and not scene.Tracker:IsActive(record))
	assert(scene.Tracker.Models[replacement].Id == "new-native-id", "Replaced live registries and new IDs must be read without replaying spawn events")
	replacement.Parent = nil tutorial._activePickups = {}
	scene.Tracker:Refresh(scene.Snapshot, 103)
	assert(scene.Tracker.ScanReport.RegistryActiveIds == 0 and scene.Tracker:Cluster("Gems") == nil)
	scene.Close()
end)

test("Every same-name native Chunker folder is scanned and registry/models are deduplicated", function()
	local scene = pickupScene()
	scene.MeshModel("Gem", scene.Prefabs)
	local first = scene.Node("Chunker", "Folder", scene.Folder.Parent)
	local second = scene.Node("Chunker", "Folder", scene.Folder.Parent)
	local a = scene.MeshModel("00000000-0000-4000-8000-000000000001", first)
	local b = scene.MeshModel("00000000-0000-4000-8000-000000000002", second)
	local other = scene.MeshModel("00000000-0000-4000-8000-000000000003", second, "unrelated-synthetic-mesh")
	local tutorial = { _activePickups = { [a.Name] = a, [b.Name] = b } }
	local dependency = scene.Tracker.Reader._dependency
	scene.Tracker.Reader._dependency = function(reader, name) return name == "Tutorial" and tutorial or dependency(reader, name) end
	scene.Tracker:Refresh(scene.Snapshot, 100)
	local report = scene.Tracker.ScanReport
	assert(report.ChunkerFolders == 2 and report.ChunkerObjects == 3 and report.RegistryActiveIds == 2)
	assert(report.CandidateIds == 3 and report.CurrencyCount == 2 and report.Unidentified == 1)
	assert(scene.Tracker.Models[other].Currency == nil, "A UUID-shaped name in a generic Chunker is not proof of currency")
	scene.Tracker.Config.PICKUP_SETTINGS.ENABLE_NATIVE_REGISTRY_DISCOVERY = false
	scene.Tracker:Refresh(scene.Snapshot, 101)
	assert(scene.Tracker.ScanReport.RegistryActiveIds == 0 and scene.Tracker.ScanReport.CurrencyCount == 2)
	assert(scene.Tracker.Models[b].IdSource == "NATIVE_CHUNKER_MODEL")
	scene.Tracker.Config.PICKUP_SETTINGS.ENABLE_CHUNKER_DISCOVERY = false
	scene.Tracker:Refresh(scene.Snapshot, 102)
	assert(scene.Tracker.ScanReport.CandidateIds == 0 and scene.Tracker:Cluster("Gems") == nil)
	scene.Close()
end)

test("Spawn metadata counts real observed events without synthesizing positions or IDs", function()
	local scene = pickupScene()
	local remotes = scene.Node("Remotes", "Folder")
	local pickups = scene.Node("Pickups", "Folder", remotes)
	local spawn = scene.Node("SpawnPickups", "RemoteEvent", pickups)
	local signal = event() spawn.OnClientEvent = signal.Event
	local lookup = services.ReplicatedStorage.FindFirstChild
	services.ReplicatedStorage.FindFirstChild = function(storage, name) return name == "Remotes" and remotes or lookup(storage, name) end
	scene.Tracker:Refresh(scene.Snapshot, 100)
	assert(scene.Tracker.ScanReport.SpawnListener and scene.Tracker.ScanReport.NativeSpawnEvents == 0)
	signal:Fire({ { Id = "event-native-id", Visual = "Gem", Root = scene.ZoneRoot }, { Id = 123, Visual = "Gem", Root = scene.ZoneRoot }, { Visual = "Gem" } })
	scene.Tracker:Refresh(scene.Snapshot, 101)
	assert(scene.Tracker.ScanReport.NativeSpawnEvents == 1 and scene.Tracker.ScanReport.NativeSpawnRecords == 2)
	assert(scene.Tracker.ScanReport.MetadataWithoutModel == 2 and scene.Tracker.ScanReport.PositionsResolved == 0)
	assert(scene.Tracker:Cluster("Gems") == nil, "Root/Visual/Id metadata has no exact randomized position; do not guess it")
	local chunk = scene.Node("Chunker", "Folder", scene.Folder.Parent)
	local model = scene.MeshModel("123", chunk)
	scene.Tracker:Refresh(scene.Snapshot, 102)
	assert(scene.Tracker.Models[model].Currency == "Gems" and scene.Tracker.Models[model].Source == "SPAWN_METADATA")
	assert(scene.Tracker.Models[model].Id == "123" and scene.Tracker.Models[model].Position == model.Position)
	local observed = scene.Tracker.NativeSpawnEvents scene.Tracker:Destroy()
	signal:Fire({ { Id = "later-id", Visual = "Gem", Root = scene.ZoneRoot } })
	assert(scene.Tracker.NativeSpawnEvents == observed, "Destroy disconnects read-only spawn observation")
	scene.Close()
end)

test("Malformed or unloaded native registry entries stay unavailable rather than becoming targets", function()
	local scene = pickupScene()
	scene.MeshModel("Gem", scene.Prefabs)
	local chunk = scene.Node("Chunker", "Folder", scene.Folder.Parent)
	local stale = scene.MeshModel("stale-native-id", chunk) stale.Parent = nil
	local mismatched = scene.MeshModel("different-name", chunk)
	local tutorial = { _activePickups = { [stale.Name] = stale, ["wrong-id"] = mismatched, ["invalid"] = {} } }
	local dependency = scene.Tracker.Reader._dependency
	scene.Tracker.Reader._dependency = function(reader, name) return name == "Tutorial" and tutorial or dependency(reader, name) end
	scene.Tracker:Refresh(scene.Snapshot, 100)
	local report = scene.Tracker.ScanReport
	assert(report.RegistryEntries == 3 and report.RegistryActiveIds == 0 and report.UnloadedEntries == 1)
	assert(report.Rejected["Native ID missing or registry key differs from Model.Name"] == 1 and report.Rejected["Native source entry is not a Model"] == 1)
	assert(scene.Tracker:Cluster("Gems") == nil)
	tutorial._activePickups = false scene.Tracker:Refresh(scene.Snapshot, 101)
	assert(not scene.Tracker.ScanReport.RegistryAvailable and scene.Tracker.ScanReport.RegistryStatus:find("absent", 1, true))
	scene.Close()
end)
print("[OC TEST] " .. (tests - farmingTestsBefore) .. " Phase 2 offline tests passed; " .. tests .. " total. Phase 2 live verification awaits the owner.")

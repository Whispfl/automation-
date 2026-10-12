do
local before = tests
local Mechanics = requireOC("GameMechanics")
local Metrics = requireOC("ResourceMetrics")
local Controller = requireOC("OCController")

test("Four local actions default off and malformed controls reject", function()
	assert(not Defaults.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL)
	assert(not Defaults.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME and not Defaults.MYSTERY_BOX_SETTINGS.AUTO_OPEN_MYSTERY_BOXES)
	assert(not Defaults.ANTIAFK_SETTINGS.ENABLE_ANTI_AFK and Defaults.MYSTERY_BOX_SETTINGS.MAXIMUM_SESSION_BOXES == 1)
	for _, bad in ipairs({ { ANTIAFK_SETTINGS = { METHOD = "SPACE_AND_R" } },
		{ MYSTERY_BOX_SETTINGS = { BOX_RESERVE = 0.5 } }, { EGG_TRAVEL_SETTINGS = { STABILITY_SECONDS = 12 } } }) do
		assert(not pcall(function() Controller.new(config(bad)) end))
	end
end)

test("One Brain arbitrates reward then selected location before idle input", function()
	local calls = {}
	local function manager(name, eligible)
		return { Select = function() table.insert(calls, name) return eligible, { Kind = name } end }
	end
	local c = { Rewards = manager("REWARDS", true), EggTravel = manager("EGG_TRAVEL", true), AntiAFK = manager("ANTI_AFK", true) }
	assert(Brain.new(config()):SelectLocalFeature(c, {}) == "REWARDS" and #calls == 1)
	c.Rewards = manager("REWARDS", false) calls = {}
	assert(Brain.new(config()):SelectLocalFeature(c, {}) == "EGG_TRAVEL" and #calls == 2)
end)

test("Selected egg lease prevents ordinary farming native travel", function()
	local c = Controller.new(config({ GENERAL_SETTINGS = { AUTO_START = false }, STATUS_UI_SETTINGS = { ENABLE_STATUS_UI = false },
		DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false } }))
	c.State = "RUNNING" c.EggTravel.Lease = {}
	local sent, reason = c.Farming.Mechanics:Travel({}, "The Overworld", "The Void", { CheckCancelled = function() return false end }, true)
	assert(not sent and reason:find("owns location", 1, true))
	c.EggTravel.Lease = nil c:Destroy()
end)

test("Reward exclusion applies to all metrics entry paths", function()
	local m = Metrics.new(Defaults.FARMING_SETTINGS)
	m:SetMode("PICKUPS", "scope", { Coins = 100 }, 0)
	m.AttributionBlockedProvider = function() return true end
	assert(next(m:Observe({ Coins = 1000 }, 10)) == nil)
	m:AddSample("STATIONARY", "scope", { Coins = 900 }, 10, 10)
	m:SetMode("PICKUPS", "scope", { Coins = 2000 }, 20)
	assert(next(m:ConfirmCycle({ Coins = 100 }, { Coins = 2000 }, "fixture")) == nil)
	assert(#m.Samples == 0 and next(m.Totals) == nil and m.ConfirmedCycles == 0)
	m.AttributionBlockedProvider = function() return false end
	assert(m:Observe({ Coins = 2010 }, 21).Coins == 10)
end)

test("Nonpickup source epoch excludes a stationary reward window", function()
	simulated(function(clock)
		local scene = stationaryFixture() scene:Add("reward-overlap", "Coins", 40)
		scene.Controller.RewardAttributionEpoch = 0
		scene.Controller.RewardAttributionBlocked = function() return scene.Controller.RewardAttributionEpoch > 0 end
		clock.Tick = function() if clock.Time >= 0.2 then scene.Profile.Coins = 999 scene.Controller.RewardAttributionEpoch = 1 end end
		local result = scene:Collect()
		assert(not result.Verified and next(result.Gains) == nil)
		assert(#scene.Coordinator.Metrics.Samples == 0 and scene.Coordinator.Stationary.LastResult.Contaminated)
		scene:Close()
	end)
end)

test("Reward adapter unavailable transport leaves no prepared operation", function()
	local c = { State = "RUNNING", Scheduler = { Active = { Definition = { Owner = "REWARDS" } } } }
	local manager = { Controller = c, Prepare = function() error("Unavailable method must be rejected before Prepare") end }
	c.Rewards = manager
	local m = Mechanics.new(config(), { _dependency = function() return {} end }, {}, {})
	m.LocalFeatureController = c m.LocalFeatureGuard = function() return true end
	assert(not m:RewardAction(manager, { Kind = "PLAYTIME" }, { CheckCancelled = function() return false end }))
end)

test("Native gift hits only the exact retained ordinary gift", function()
	local c = { State = "RUNNING", Generation = 1, Scheduler = { Active = { Definition = { Owner = "REWARDS", Generation = 1 } } } }
	local root, counts = { Position = Vector3.new(0, 0, 0) }, { own = 0, other = 0 }
	local m = Mechanics.new(config({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } }), { _dependency = function() return { IsGiftInRange = true } end }, {}, {})
	m.LocalFeatureController = c m.LocalFeatureGuard = function() return true, nil, root end
	local function record(id)
		return { Name = "Mystery Box", IdentityEpoch = "received-native-1", Revision = 1,
			Model = { Parent = true, GetPivot = function() return { Position = Vector3.new(0, 0, 0) } end },
			Component = { InRange = true, Hit = function() counts[id] += 1 end } }
	end
	m.RewardsContext = function() return { GiftCompletionAvailable = true, GiftIdentityAvailable = true,
		GiftIdentityEpoch = "received-native-1", GiftRevision = 1, GiftRecords = { other = record("other"), own = record("own") } } end
	local pending = { Kind = "MYSTERY_BOX", Attempted = true, GiftId = "own", GiftIdentityEpoch = "received-native-1", BeforeGiftRevision = 0, BeforeGiftIds = {} }
	c.Rewards = { Ledger = { Pending = pending } }
	assert(m:AdvanceMysteryGift(pending, { CheckCancelled = function() return false end }))
	assert(counts.own == 1 and counts.other == 0)
	m.LastOrdinaryGiftHit = -math.huge
	pending.AmbiguousGift = true
	assert(not m:AdvanceMysteryGift(pending, { CheckCancelled = function() return false end }))
	assert(counts.own == 1)
end)

test("Native BasePart gift identity comes from received payload and total registry count", function()
	local previousTypeof = typeof
	local part = { Name = "unique-gift-123", Parent = workspace }
	function part:IsA(kind) return kind == "BasePart" end
	function part:IsDescendantOf(target) return target == workspace end
	local component = { Model = part, InRange = true, Hit = function() end } -- Native component has no Name.
	typeof = function(value) if value == part then return "Instance" end return previousTypeof(value) end
	local physical = { GetActiveObjects = function(_, kind) assert(kind == "Gift") return 1 end,
		GetActiveGifts = function() return { [part] = component } end }
	local reader = { GetLiveProfile = function() return { MasteryUpgrades = {} } end, ReadBalances = function() return {} end,
		GetNativeGiftFacts = function() return { Available = true, Epoch = "received-epoch", Revision = 5,
			Records = { [part.Name] = { Name = "Mystery Box", Revision = 5 } } } end }
	function reader:_dependency(name)
		if name == "PhysicalItem" then return physical elseif name == "PhysicalGift" then return { Hit = function() end }
		elseif name == "IsTradingPlaza" then return function() return false end end
	end
	local m = Mechanics.new(config(), reader, {}, {}) m.LocalFeatureGuard = function() return true end
	local context = m:RewardsContext()
	assert(context.GiftCount == 1 and context.GiftCompletionAvailable and context.GiftIds[part.Name])
	assert(context.GiftRecords[part.Name].Name == "Mystery Box" and context.GiftRecords[part.Name].Model == part)
	assert(context.GiftRecords[part.Name].IdentityEpoch == "received-epoch" and context.GiftRecords[part.Name].Revision == 5)
	physical.GetActiveGifts = function() return {} end -- Unloaded remains in total registry.
	context = m:RewardsContext()
	assert(context.GiftCount == 1 and next(context.GiftIds) == nil and not context.CanClaim)
	reader.GetNativeGiftFacts = function() return { Available = false } end
	assert(not m:RewardsContext().GiftCompletionAvailable)
	typeof = previousTypeof
end)

test("Gift dispatch rejects stale identity epochs and native out-of-range component", function()
	local hits, inRange, epoch, revision = 0, false, "same-reader", 2
	local c = { State = "RUNNING", Generation = 1, Scheduler = { Active = { Definition = { Owner = "REWARDS", Generation = 1 } } } }
	local m = Mechanics.new(config({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } }), { _dependency = function() return { IsGiftInRange = true } end }, {}, {})
	m.LocalFeatureController = c m.LocalFeatureGuard = function() return true, nil, { Position = Vector3.new(0, 0, 0) } end
	m.RewardsContext = function() return { GiftCompletionAvailable = true, GiftIdentityAvailable = true,
		GiftIdentityEpoch = epoch, GiftRevision = revision, GiftRecords = { own = { Name = "Mystery Box", IdentityEpoch = epoch, Revision = revision,
			Model = { Parent = true, GetPivot = function() return { Position = Vector3.new(0, 0, 0) } end },
			Component = { InRange = inRange, Hit = function() hits += 1 end } } } } end
	local pending = { Kind = "MYSTERY_BOX", Attempted = true, GiftId = "own", GiftIdentityEpoch = "same-reader", BeforeGiftRevision = 1, BeforeGiftIds = {} }
	c.Rewards = { Ledger = { Pending = pending } }
	local token = { CheckCancelled = function() return false end }
	assert(not m:AdvanceMysteryGift(pending, token) and hits == 0)
	inRange, epoch = true, "new-reader"
	assert(not m:AdvanceMysteryGift(pending, token) and hits == 0)
	epoch, revision = "same-reader", 1
	assert(not m:AdvanceMysteryGift(pending, token) and hits == 0)
	revision = 2
	assert(m:AdvanceMysteryGift(pending, token) and hits == 1)
end)

test("Playtime transport is tracked and requires a live lease at actual dispatch", function()
	-- Roblox removes cancelled deferred work; this harness retains queue entries.
	for index = #queue, 1, -1 do if coroutine.status(queue[index]) == "dead" then table.remove(queue, index) end end
	local c = { State = "RUNNING", Generation = 1, Scheduler = { Active = { Definition = { Owner = "REWARDS", Generation = 1 } } }, MarkNonPickupReward = function() end }
	local calls, marks, aborts = 0, 0, 0
	local pending = {}
	local manager = { Controller = c, Prepare = function() return "ClaimPlaytime", 2, nil, pending end,
		MarkDispatched = function() marks += 1 return true end, DispatchReturned = function() end,
		AbortPreparation = function() aborts += 1 return true end }
	c.Rewards = manager
	local remote = { InvokeServer = function(_, command, index) assert(command == "ClaimPlaytime" and index == 2) calls += 1 end }
	local m = Mechanics.new(config({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } }), { _dependency = function() return remote end }, {}, {})
	m.LocalFeatureController = c m.LocalFeatureGuard = function() return true end
	assert(m:RewardAction(manager, { Kind = "PLAYTIME" }, { CheckCancelled = function() return false end }))
	flush() assert(calls == 1 and marks == 1 and pending.TransportStarted)
	assert(m:RewardAction(manager, { Kind = "PLAYTIME" }, { CheckCancelled = function() return false end }))
	c.Scheduler.Active = nil flush()
	assert(calls == 1 and marks == 1 and aborts == 1)
	m:CancelRewardTransport()
end)

test("Actual input dispatch needs a current positive scheduler lease", function()
	local manager = { Controller = { Generation = 2, State = "RUNNING", Scheduler = {} } }
	local m = Mechanics.new(config(), {}, {}, {})
	m.LocalFeatureController = manager.Controller manager.Controller.AntiAFK = manager
	m.AntiAFKGuard = function() error("No lease must prevent input guards/dispatch") end
	local sent, reason = m:AntiAFKPulse(manager, { CheckCancelled = function() return false end })
	assert(not sent and reason:find("SUPPRESSED:", 1, true))
	manager.Controller.Scheduler.Active = { Definition = { Owner = "ANTI_AFK", Generation = 1 } }
	assert(not m:AntiAFKPulse(manager, { CheckCancelled = function() return false end }))
end)

test("Stop and repeated initialization release tracked input and RPC work", function()
	local c = Controller.new(config({ GENERAL_SETTINGS = { AUTO_START = false }, STATUS_UI_SETTINGS = { ENABLE_STATUS_UI = false },
		DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false } }))
	local calls = 0
	c.Farming.Mechanics.ReleaseAntiAFKInput = function() calls += 1 return true end
	local transport = coroutine.create(function() coroutine.yield() end) coroutine.resume(transport)
	c.Farming.Mechanics.RewardRPCs = { [transport] = true }
	c:Destroy()
	assert(calls >= 2 and coroutine.status(transport) == "dead" and next(c.Farming.Mechanics.RewardRPCs) == nil)
	assert(c.AntiAFK.Destroyed and c.EggTravel.Destroyed and c.Rewards.Destroyed)
end)

test("Unconfirmed reward barrier relies on reader reconciliation rather than hot tasks", function()
	local c = { Config = Resolver.Resolve(Defaults), Reader = { Player = {} } }
	local manager = requireOC("RewardsManager").new(c)
	assert(manager:Definition({ Kind = "OBSERVE_REWARD", Pending = { Status = "UNCONFIRMED" } }, 1) == nil)
end)
print("[OC TEST] Local feature integration checks passed: " .. tostring(tests - before))
end

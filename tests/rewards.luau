do
-- Synthetic contracts and received account changes; not native/server proof.
local rewardsBefore = tests
local Rewards = requireOC("RewardsManager")
local GiftReader = requireOC("AccountStateReader")
local function withLedger(callback)
	local previous = shared
	shared = {}
	local ok, reason = xpcall(callback, debug.traceback)
	shared = previous
	assert(ok, reason)
end

local function rewardFixture(overrides)
	local settings = Resolver.Resolve(Defaults, overrides or {})
	local scene = { Commands = {}, Logs = {}, Epochs = 0 }
	scene.Context = { UserId = 123, NativeNow = 1000, HasPlaytime = true, IsTradingPlaza = false,
		CanClaim = true, CanOpen = true, OwnedBoxes = 10, GiftCount = 0, MaxGiftCount = 5, GiftIds = {}, GiftRecords = {},
		GiftCompletionAvailable = true, PlaytimeGifts = { { Time = 120 }, { Time = 180 }, { Time = 240 }, { Time = 300 } },
		GiftIdentityAvailable = true, GiftIdentityEpoch = "synthetic-reader-1", GiftRevision = 0,
		Raw = { Coins = 100, Powerups = { ["Mystery Box"] = 10 }, Potions = {}, Pets = {}, PlaytimeRewards = { Start = 0, Claimed = {} } } }
	local context = scene.Context
	context.Balances = { Coins = context.Raw.Coins }
	local reader = { Player = { UserId = 123 }, GetLiveProfile = function() return context.Raw end }
	local controller = { Config = settings, Reader = reader, State = "RUNNING", Generation = 1,
		Log = function(_, tag, message) table.insert(scene.Logs, tag .. " " .. message) end,
		MarkNonPickupReward = function() scene.Epochs += 1 end }
	local mechanics = { RewardsContext = function()
		scene.ContextCalls = (scene.ContextCalls or 0) + 1
		context.Balances = { Coins = context.Raw.Coins }
		return context
	end }
	controller.Farming = { Mechanics = mechanics }
	function mechanics:RewardAction(manager, decision, token)
		local command, first, second, pending = manager:Prepare(decision, token)
		if not command then return false end
		controller:MarkNonPickupReward(pending)
		if not manager:MarkDispatched(pending) then return false end
		table.insert(scene.Commands, { Command = command, First = first, Count = second })
		if scene.OnAction then scene.OnAction(pending) end
		manager:DispatchReturned(pending, not scene.InvocationError, scene.InvocationError or true)
		return true
	end
	scene.Controller, scene.Mechanics = controller, mechanics
	scene.Manager = Rewards.new(controller)
	function scene:Run()
		local owns, decision = self.Manager:Select({})
		if owns then
			local definition = self.Manager:Definition(decision, self.Controller.Generation)
			if not definition then return { Pending = true, ObservationOnly = true } end
			assert(definition.Owner == "REWARDS" and definition.Id == "OC_GAMEPLAY")
			return definition.Execute({ CheckCancelled = function() return false end })
		end
	end
	function scene:Spawn(id)
		context.GiftCount, context.GiftIds = 1, { [id] = true }
		context.GiftRevision += 1
		context.GiftRecords = { [id] = { Id = id, Name = "Mystery Box", IdentityEpoch = context.GiftIdentityEpoch, Revision = context.GiftRevision } }
		self.Manager:Observe()
	end
	function scene:Finish(id)
		context.OwnedBoxes -= 1 context.Raw.Powerups["Mystery Box"] = context.OwnedBoxes
		self:Spawn(id)
		context.GiftCount, context.GiftIds, context.GiftRecords = 0, {}, {}
		context.Raw.Coins += 10
		self.Manager:Observe()
	end
	return scene
end

test("Rewards defaults dispatch nothing and keep the native adapters separate", function()
	withLedger(function()
		local scene = rewardFixture()
		assert(not Defaults.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME and not Defaults.MYSTERY_BOX_SETTINGS.AUTO_OPEN_MYSTERY_BOXES)
		assert(not scene.Manager:Select({}))
		assert(#scene.Commands == 0 and (scene.ContextCalls or 0) == 0)
	end)
end)

test("Playtime uses sparse string indices and treats false stored keys as claimed", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
			scene.Context.Raw.PlaytimeRewards.Claimed = { ["1"] = true, ["3"] = false }
			scene:Run()
			assert(#scene.Commands == 1 and scene.Commands[1].Command == "ClaimPlaytime" and scene.Commands[1].First == 2)
			assert(scene.Manager:GetStatus().ClaimsRequested == 1 and scene.Manager:AttributionBlocked())
		end)
	end)
end)

test("Playtime unlock, clock, future start, Plaza and UI guards fail closed", function()
	withLedger(function()
		for _, mutate in ipairs({ function(c) c.HasPlaytime = false end, function(c) c.NativeNow = nil end,
			function(c) c.Raw.PlaytimeRewards.Start = 2000 end, function(c) c.IsTradingPlaza = true end,
			function(c) c.CanClaim = false end, function(c) c.Raw.PlaytimeRewards.Claimed = nil end }) do
			shared.__OC_LOCAL_REWARD_LEDGER = nil
			local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
			mutate(scene.Context)
			assert(not scene.Manager:Select({}) and #scene.Commands == 0)
		end
	end)
end)

test("A pending playtime claim cannot duplicate after Pause or repeated load", function()
	withLedger(function()
		simulated(function(clock)
			local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
			scene:Run() scene.Controller.State = "PAUSED" scene.Manager:Halt(false)
			clock.Time = 20 scene.Manager:Observe()
			assert(scene.Manager:GetStatus().Pending.Status == "UNCONFIRMED")
			scene.Manager:Destroy() scene.Manager = Rewards.new(scene.Controller)
			scene.Controller.State = "RUNNING" scene:Run()
			assert(#scene.Commands == 1 and scene.Manager:GetStatus().Pending.Index == 1)
		end)
	end)
end)

test("Received playtime key acknowledges while paused and schedules no next operation", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
			scene:Run() scene.Controller.State = "PAUSED" scene.Manager:Halt(false)
			scene.Context.Raw.PlaytimeRewards.Claimed["1"] = true scene.Context.Raw.Coins = 125
			scene.Manager:Observe()
			assert(scene.Manager:GetStatus().Pending == nil and scene.Manager:GetStatus().ClaimsAcknowledged == 1)
			assert(scene.Manager:GetStatus().LastResult.RewardObserved and scene.Epochs == 2)
			assert(#scene.Commands == 1)
		end)
	end)
end)

test("Cycle reset and invocation errors retain uncertain playtime instead of count plus one", function()
	withLedger(function()
		simulated(function(clock)
			local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
			scene.InvocationError = "Synthetic transport error after dispatch" scene:Run()
			scene.Context.Raw.PlaytimeRewards.Start = 100
			scene.Context.Raw.PlaytimeRewards.Claimed["1"] = true
			clock.Time = 30 scene.Manager:Observe() scene:Run()
			assert(scene.Manager:GetStatus().ClaimsAcknowledged == 0 and #scene.Commands == 1)
			assert(scene.Manager:GetStatus().Pending.Status == "UNCONFIRMED")
		end)
	end)
end)

test("Late acknowledgement starts the configured next-claim spacing after settlement", function()
	withLedger(function()
		simulated(function(clock)
			local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
			scene:Run() clock.Time = 14
			scene.Context.Raw.PlaytimeRewards.Claimed["1"] = true scene.Context.Raw.Coins = 125
			scene.Manager:Observe()
			assert(scene.Manager.Ledger.NextClaimAt >= 19)
			assert(not scene.Manager:Select({}) and #scene.Commands == 1)
		end)
	end)
end)

test("Claim acknowledgement without a reward delta is honest and blocks attribution", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
			scene:Run() scene.Context.Raw.PlaytimeRewards.Claimed["1"] = true scene.Manager:Observe()
			assert(scene.Manager:GetStatus().Pending == nil and scene.Manager:AttributionBlocked())
			assert(not scene.Manager:GetStatus().LastResult.RewardObserved)
			scene.Manager:Destroy() scene.Manager = Rewards.new(scene.Controller)
			assert(scene.Manager:AttributionBlocked())
		end)
	end)
end)

test("Already claimed, not due and missing inventory baselines do not invent rewards", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
			scene.Context.NativeNow = 119 assert(not scene.Manager:Select({}))
			scene.Manager.NextCheckAt = 0 scene.Context.NativeNow = 120
			scene.Context.Raw.Powerups = nil scene:Run()
			scene.Context.Raw.PlaytimeRewards.Claimed["1"] = true
			scene.Context.Raw.Powerups = { ["Synthetic New Item"] = 100 }
			scene.Manager:Observe()
			assert(not scene.Manager:GetStatus().LastResult.RewardObserved)
			scene.Manager.NextCheckAt = 0 assert(not scene.Manager:Select({}))
		end)
	end)
end)

test("Ordinary boxes require reserve, allowance, native limit and safe completion capability", function()
	withLedger(function()
		for _, mutate in ipairs({ function(c) c.OwnedBoxes = 0 end, function(c) c.OwnedBoxes = 2 end,
			function(c) c.GiftCount = 1 end, function(c) c.MaxGiftCount = 0 end,
			function(c) c.GiftCompletionAvailable = false end, function(c) c.CanOpen = false end,
			function(c) c.GiftIdentityAvailable = false end, function(c) c.GiftIdentityEpoch = nil end,
			function(c) c.GiftRevision = nil end }) do
			shared.__OC_LOCAL_REWARD_LEDGER = nil
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true, BOX_RESERVE = 2 } })
			mutate(scene.Context) assert(not scene.Manager:Select({}) and #scene.Commands == 0)
		end
	end)
end)

test("The first ordinary operation is one and never trusts a reference batch of ten", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true,
				MAXIMUM_SESSION_BOXES = 10, MAXIMUM_BATCH_BOXES = 3, ENABLE_AUTOMATIC_CONTINUATION = true } })
			scene:Run()
			assert(#scene.Commands == 1 and scene.Commands[1].Command == "UseGift")
			assert(scene.Commands[1].First == "Mystery Box" and scene.Commands[1].Count == 1)
			assert(scene.Manager:GetStatus().BoxesRequested == 1)
		end)
	end)
end)

test("Consumption alone does not confirm a box reward or permit continuation", function()
	withLedger(function()
		simulated(function(clock)
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true,
				MAXIMUM_SESSION_BOXES = 3, ENABLE_AUTOMATIC_CONTINUATION = true } })
			scene:Run() scene.Context.OwnedBoxes = 9 scene.Context.Raw.Powerups["Mystery Box"] = 9
			clock.Time = 25 scene.Manager:Observe() scene:Run()
			local status = scene.Manager:GetStatus()
			assert(status.Pending.ConsumptionAcknowledged and not status.Pending.RewardObserved)
			assert(status.BoxesConsumed == 1 and status.BoxOutcomesObserved == 0 and #scene.Commands == 1)
		end)
	end)
end)

test("Acknowledged box and native gift completion plus observed reward advance only opted-in allowance", function()
	withLedger(function()
		simulated(function(clock)
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true,
				MAXIMUM_SESSION_BOXES = 2, ENABLE_AUTOMATIC_CONTINUATION = true } })
			scene:Run() scene:Finish("ordinary-1")
			local result = scene.Manager:GetStatus()
			assert(not result.Pending and result.BoxesConsumed == 1 and result.BoxOutcomesObserved == 1)
			assert(result.LastResult.RewardObserved and scene.Epochs == 2)
			clock.Time = 6 scene:Run() scene:Finish("ordinary-2") clock.Time = 12
			assert(#scene.Commands == 2 and not scene.Manager:Select({}))
			scene.Manager:Destroy() scene.Manager = Rewards.new(scene.Controller)
			assert(not scene.Manager:Select({}) and scene.Manager:GetStatus().BoxesRequested == 2)
		end)
	end)
end)

test("Default continuation remains off even when an owner increases the numerical allowance", function()
	withLedger(function()
		simulated(function(clock)
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true, MAXIMUM_SESSION_BOXES = 3 } })
			scene:Run() scene:Finish("ordinary-1") clock.Time = 10
			assert(not scene.Manager:Select({}) and #scene.Commands == 1)
		end)
	end)
end)

test("Box uncertainty survives session-key changes, respawn-style guards and repeated loading", function()
	withLedger(function()
		simulated(function(clock)
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } })
			scene.InvocationError = "Synthetic uncertain delivery" scene:Run()
			scene.Controller.State = "PAUSED" scene.Manager:Halt(false)
			scene.Context.CanOpen = false clock.Time = 25 scene.Manager:Observe()
			scene.Manager:Destroy() scene.Controller.Config.MYSTERY_BOX_SETTINGS.SESSION_KEY = "LATER_OWNER_SESSION"
			scene.Controller.State = "RUNNING" scene.Manager = Rewards.new(scene.Controller) scene:Run()
			assert(#scene.Commands == 1 and scene.Manager:GetStatus().Pending ~= nil)
		end)
	end)
end)

test("Multiple or unverified new gifts are not chosen as an ordinary completion target", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } })
			scene:Run() scene.Context.GiftCount = 2
			scene.Context.GiftIds = { first = true, second = true }
			scene.Context.GiftRevision = 1
			scene.Context.GiftRecords = {
				first = { Id = "first", Name = "Mystery Box", Revision = 1, IdentityEpoch = scene.Context.GiftIdentityEpoch },
				second = { Id = "second", Name = "Mystery Box", Revision = 1, IdentityEpoch = scene.Context.GiftIdentityEpoch },
			}
			scene.Manager:Observe()
			assert(scene.Manager.Ledger.Pending.AmbiguousGift and scene.Manager:GetStatus().Pending.GiftId == nil)
		end)
	end)
end)

test("Cancellation before dispatch releases only an unattempted preparation", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } })
			local _, decision = scene.Manager:Select({})
			assert(scene.Manager:Prepare(decision, { CheckCancelled = function() return true end }) == nil)
			local _, _, _, pending = scene.Manager:Prepare(decision, { CheckCancelled = function() return false end })
			scene.Controller.State = "PAUSED" scene.Manager:Halt(false)
			assert(not scene.Manager:MarkDispatched(pending) and scene.Manager:GetStatus().BoxesRequested == 0)
		end)
	end)
end)

test("Fresh changed eligibility and unknown shared ledger schema block stale reward dispatch", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
			local _, decision = scene.Manager:Select({}) scene.Context.Raw.PlaytimeRewards.Claimed["1"] = true
			assert(scene.Manager:Prepare(decision, { CheckCancelled = function() return false end }) == nil)
			shared.__OC_LOCAL_REWARD_LEDGER = { Version = 99, Pending = "Do not erase" }
			scene.Manager = Rewards.new(scene.Controller)
			assert(not scene.Manager:Select({}) and shared.__OC_LOCAL_REWARD_LEDGER.Pending == "Do not erase")
		end)
	end)
end)

test("Pending observations are paced and unconfirmed barriers await received updates", function()
	withLedger(function()
		simulated(function(clock)
			local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
			scene:Run() local before = clock.Time scene:Run()
			assert(clock.Time - before >= 0.5 and #scene.Commands == 1)
			clock.Time = 30 before = clock.Time scene:Run()
			assert(clock.Time == before and #scene.Commands == 1 and scene.Manager:GetStatus().Pending.Status == "UNCONFIRMED")
		end)
	end)
end)

test("An undispatched transport preparation may abort but an attempted operation cannot", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } })
			local _, decision = scene.Manager:Select({})
			local _, _, _, pending = scene.Manager:Prepare(decision, { CheckCancelled = function() return false end })
			assert(scene.Manager:AbortPreparation(pending, "Synthetic transport unavailable") and scene.Manager:GetStatus().BoxesRequested == 0)
			local _, _, _, attempted = scene.Manager:Prepare(decision, { CheckCancelled = function() return false end })
			assert(scene.Manager:MarkDispatched(attempted))
			assert(not scene.Manager:AbortPreparation(attempted) and scene.Manager:GetStatus().BoxesRequested == 1)
		end)
	end)
end)

test("Malformed pending state is preserved without indexing a non-table or dispatching", function()
	withLedger(function()
		local scene = rewardFixture({ PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = true } })
		scene.Manager.Ledger.Pending = true
		local ledger = scene.Manager.Ledger
		scene.Manager = Rewards.new(scene.Controller)
		assert(not scene.Manager:Select({}) and ledger.Pending == true and scene.Manager:AttributionBlocked())
		assert(#scene.Commands == 0)
	end)
end)

local nativeReaderEpoch = 0
local function withGiftReader(callback, overrides)
	local previousHTTP = services.HttpService
	local environment = getfenv(GiftReader.GetNativeGiftFacts)
	local previousTypeof = environment.typeof
	-- Only this synthetic fixture's tagged values stand in for native value types.
	environment.typeof = function(value)
		if type(value) == "table" and value.NativeFixtureInstance then return "Instance" end
		if type(value) == "table" and getmetatable(value) == vectorMeta then return "Vector3" end
		return previousTypeof(value)
	end
	local scene = { Bindings = 0, Disconnects = 0, Notifications = 0, Callbacks = {} }
	services.HttpService = { GenerateGUID = function()
		nativeReaderEpoch += 1 return "synthetic-native-reader-" .. nativeReaderEpoch
	end }
	local signal = { Connect = function(_, listener)
		scene.Bindings += 1 scene.Callbacks[listener] = true
		return { Disconnect = function() scene.Disconnects += 1 scene.Callbacks[listener] = nil end }
	end }
	scene.Remote = { Event = function(name) assert(name == "RenderGifts", "Native Event uses dot syntax") return signal end }
	scene.Reader = GiftReader.new(Resolver.Resolve(Defaults, overrides or { MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } }), { UserId = 123 })
	scene.Reader._queueRefresh = function() scene.Notifications += 1 end
	function scene:ReadyRemote() self.Reader.Dependencies.Remote = { Status = "READY", Value = self.Remote } end
	function scene:Publish(payload) for listener in pairs(self.Callbacks) do listener(payload) end end
	local ok, reason = xpcall(function() callback(scene) end, debug.traceback)
	scene.Reader:Destroy()
	environment.typeof, services.HttpService = previousTypeof, previousHTTP
	assert(ok, reason)
end

test("Gift observer defaults off, waits for Remote and binds one dot-syntax read-only listener", function()
	withGiftReader(function(scene)
		scene:ReadyRemote()
		assert(not scene.Reader:GetNativeGiftFacts().Available and scene.Bindings == 0)
	end, {})
	withGiftReader(function(scene)
		assert(not scene.Reader:GetNativeGiftFacts().Available and scene.Bindings == 0)
		scene:ReadyRemote()
		local first = scene.Reader:GetNativeGiftFacts()
		assert(first.Available and type(first.Epoch) == "string" and first.Revision == 0)
		assert(scene.Reader:GetNativeGiftFacts().Epoch == first.Epoch and scene.Bindings == 1)
	end)
end)

test("Public gift identities are immutable copies and repeated old ID keeps its first revision", function()
	withGiftReader(function(scene)
		scene:ReadyRemote() scene.Reader:GetNativeGiftFacts()
		local payload = { ordinary = { Name = "Mystery Box", Position = Vector3.new(0, 0, 0) } }
		scene:Publish(payload)
		local facts = scene.Reader:GetNativeGiftFacts()
		assert(facts.Revision == 1 and facts.Records.ordinary.Revision == 1 and facts.Records.ordinary.Name == "Mystery Box")
		assert(not pcall(function() facts.Records.ordinary.Name = "Super Mystery Box" end))
		assert(not pcall(function() facts.Records.injected = {} end))
		scene:Publish({ ordinary = { Name = "Mystery Box", Position = Vector3.new(0, 0, 0) } })
		assert(scene.Reader:GetNativeGiftFacts().Revision == 2 and scene.Reader:GetNativeGiftFacts().Records.ordinary.Revision == 1)
		payload.ordinary.Name = "Changed caller table"
		assert(scene.Reader:GetNativeGiftFacts().Records.ordinary.Name == "Mystery Box")
	end)
end)

test("Malformed or conflicting native identity blocks atomically for the reader lifetime", function()
	for _, bad in ipairs({ "wrong payload", { [12] = { Name = "Mystery Box", Position = Vector3.new(0, 0, 0) } },
		{ bad = { Name = "Mystery Box", Position = {} } },
		{ bad = { Name = "Mystery Box", Position = Vector3.new(math.huge, 0, 0) } } }) do
		withGiftReader(function(scene)
			scene:ReadyRemote() scene.Reader:GetNativeGiftFacts() scene:Publish(bad)
			assert(not scene.Reader:GetNativeGiftFacts().Available and next(scene.Reader:GetNativeGiftFacts().Records) == nil)
			scene:Publish({ later = { Name = "Mystery Box", Position = Vector3.new(0, 0, 0) } })
			assert(not scene.Reader:GetNativeGiftFacts().Available and scene.Bindings == 1)
		end)
	end
	withGiftReader(function(scene)
		scene:ReadyRemote() scene.Reader:GetNativeGiftFacts()
		scene:Publish({ same = { Name = "Mystery Box", Position = Vector3.new(0, 0, 0) } })
		scene:Publish({ same = { Name = "Super Mystery Box", Position = Vector3.new(0, 0, 0) } })
		local facts = scene.Reader:GetNativeGiftFacts()
		assert(not facts.Available and facts.Revision == 1 and facts.Records.same.Name == "Mystery Box")
	end)
end)

test("Gift observer disconnects once, ignores later events and new reader has a distinct empty epoch", function()
	local oldEpoch
	withGiftReader(function(scene)
		scene:ReadyRemote() oldEpoch = scene.Reader:GetNativeGiftFacts().Epoch
		scene.Reader:Destroy() scene.Reader:Destroy()
		scene:Publish({ after = { Name = "Mystery Box", Position = Vector3.new(0, 0, 0) } })
		assert(scene.Disconnects == 1 and not scene.Reader:GetNativeGiftFacts().Available)
		assert(next(scene.Reader:GetNativeGiftFacts().Records) == nil)
	end)
	withGiftReader(function(scene)
		scene:ReadyRemote() local facts = scene.Reader:GetNativeGiftFacts()
		assert(facts.Epoch ~= oldEpoch and next(facts.Records) == nil)
	end)
end)

test("Unavailable native event or epoch prevents ordinary identity capability", function()
	withGiftReader(function(scene)
		scene.Remote.Event = nil scene:ReadyRemote()
		assert(not scene.Reader:GetNativeGiftFacts().Available and scene.Bindings == 0)
	end)
	withGiftReader(function(scene)
		services.HttpService.GenerateGUID = function() error("Unavailable native UUID") end
		scene:ReadyRemote()
		assert(not scene.Reader:GetNativeGiftFacts().Available and scene.Bindings == 0)
	end)
end)

test("Native BasePart with no component Name maps ordinary identity only from the public ID event", function()
	withGiftReader(function(scene)
		local Mechanics = requireOC("GameMechanics")
		local reader, raw, hits = scene.Reader, { Powerups = { ["Mystery Box"] = 10 } }, 0
		reader.GetLiveProfile, reader.ReadBalances = function() return raw end, function() return { Coins = 100 } end
		local part = { Name = "native-part-id", ClassName = "Part", NativeFixtureInstance = true, Parent = workspace,
			IsA = function(_, kind) return kind == "Part" or kind == "BasePart" end,
			IsDescendantOf = function(_, ancestor) return ancestor == workspace end,
			GetPivot = function() return { Position = Vector3.new(0, 0, 0) } end }
		local component = { Model = part, InRange = true, Animating = false, HitCount = 0 }
		component.Hit = function(self) assert(self == component) hits += 1 end
		local total, loaded = 1, { [part] = component }
		local physical = { IsGiftInRange = true, GetActiveObjects = function(_, kind) assert(kind == "Gift") return total end,
			GetActiveGifts = function() return loaded end }
		for name, value in pairs({ PhysicalItem = physical, PhysicalGift = { Hit = function() end }, Constants = { MaxSpawnableLimit = 50 },
			Powerups = { ["Mystery Box"] = {} }, ItemUtil = { GetOwnedAmount = function() return 10 end }, IsTradingPlaza = function() return false end }) do
			reader.Dependencies[name] = { Status = "READY", Value = value }
		end
		scene:ReadyRemote()
		local m = Mechanics.new(reader.Config, reader, {}, {})
		local c = { State = "RUNNING", Generation = 1, Scheduler = { Active = { Definition = { Owner = "REWARDS", Generation = 1 } } } }
		m.LocalFeatureController = c m.LocalFeatureGuard = function() return true, nil, { Position = Vector3.new(0, 0, 0) } end
		local before = m:RewardsContext()
		assert(component.Name == nil and not part:IsA("Model") and before.GiftCount == 1 and before.GiftRecords[part.Name] == nil)
		scene:Publish({ [part.Name] = { Name = "Mystery Box", Position = Vector3.new(0, 0, 0) } })
		local mapped = m:RewardsContext()
		assert(mapped.GiftRecords[part.Name].Name == "Mystery Box" and mapped.GiftRecords[part.Name].Model == part)
		assert(mapped.GiftRecords[part.Name].Revision == 1 and mapped.GiftRecords[part.Name].IdentityEpoch == before.GiftIdentityEpoch)
		local pending = { Kind = "MYSTERY_BOX", Attempted = true, GiftId = part.Name, BeforeGiftIds = {},
			GiftIdentityEpoch = before.GiftIdentityEpoch, BeforeGiftRevision = 0 }
		c.Rewards = { Ledger = { Pending = pending } }
		assert(m:AdvanceMysteryGift(pending, { CheckCancelled = function() return false end }) and hits == 1)
		m.LastOrdinaryGiftHit = -math.huge component.InRange = false
		assert(not m:AdvanceMysteryGift(pending, { CheckCancelled = function() return false end }) and hits == 1)
		loaded = {} local unloaded = m:RewardsContext()
		assert(unloaded.GiftCount == 1 and next(unloaded.GiftIds) == nil and not unloaded.CanOpen)
		total = 0 assert(m:RewardsContext().GiftCount == 0)
	end)
end)

test("Delayed public ordinary identity correlates while missing identity never guesses a gift", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } })
			scene:Run() local pending = scene.Manager.Ledger.Pending
			assert(pending.GiftIdentityEpoch == scene.Context.GiftIdentityEpoch and pending.BeforeGiftRevision == 0)
			scene.Context.GiftCount, scene.Context.GiftIds = 1, { ordinary = true }
			scene.Manager:Observe() assert(not pending.GiftId and not pending.GiftIdentityCurrent)
			scene.Context.GiftRevision = 1
			scene.Context.GiftRecords.ordinary = { Id = "ordinary", Name = "Mystery Box", IdentityEpoch = pending.GiftIdentityEpoch, Revision = 1 }
			scene.Manager:Observe() assert(pending.GiftId == "ordinary" and pending.GiftIdentityCurrent)
		end)
	end)
end)

test("Old revision, wrong ID or name and reader-epoch changes cannot authorize pending native input", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } })
			scene.Context.GiftRevision = 5 scene:Run()
			local pending = scene.Manager.Ledger.Pending
			scene.Context.GiftCount, scene.Context.GiftIds, scene.Context.GiftRevision = 1, { ordinary = true }, 6
			local record = { Id = "ordinary", Name = "Mystery Box", IdentityEpoch = pending.GiftIdentityEpoch, Revision = 5 }
			scene.Context.GiftRecords.ordinary = record
			scene.Manager:Observe() assert(not pending.GiftId)
			record.Revision, record.Id = 6, "different-id" scene.Manager:Observe() assert(not pending.GiftId)
			record.Id, record.Name = "ordinary", "Super Mystery Box" scene.Manager:Observe() assert(not pending.GiftId)
			record.Name, record.IdentityEpoch = "Mystery Box", "different-reader" scene.Manager:Observe() assert(not pending.GiftId)
			record.IdentityEpoch = pending.GiftIdentityEpoch scene.Manager:Observe() assert(pending.GiftId == "ordinary")
			scene.Context.GiftIdentityEpoch = "reloaded-reader" scene.Manager:Observe()
			assert(not pending.GiftIdentityCurrent and scene.Manager:GetStatus().Pending ~= nil and #scene.Commands == 1)
		end)
	end)
end)

test("Unloaded gifts remain pending until total registry reaches zero", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } })
			scene:Run() scene:Spawn("ordinary")
			scene.Context.OwnedBoxes, scene.Context.Raw.Powerups["Mystery Box"] = 9, 9 scene.Context.Raw.Coins += 10
			scene.Context.GiftIds, scene.Context.GiftRecords = {}, {} scene.Manager:Observe()
			assert(scene.Manager:GetStatus().Pending and not scene.Manager.Ledger.Pending.GiftFinished)
			scene.Context.GiftCount = 0 scene.Manager:Observe()
			assert(not scene.Manager:GetStatus().Pending and scene.Manager:GetStatus().BoxOutcomesObserved == 1)
		end)
	end)
end)

test("Reload cannot Hit a retained old-epoch gift but can observe previously proved disappearance and receipt", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } })
			scene:Run() scene:Spawn("ordinary") scene.Manager:Destroy()
			scene.Context.GiftIdentityEpoch = "new-reader-epoch"
			scene.Context.GiftRecords.ordinary.IdentityEpoch = scene.Context.GiftIdentityEpoch
			scene.Manager = Rewards.new(scene.Controller)
			local hits = 0 scene.Mechanics.AdvanceMysteryGift = function() hits += 1 return true end
			scene:Run() assert(hits == 0 and #scene.Commands == 1 and scene.Manager:GetStatus().Pending)
			scene.Context.OwnedBoxes, scene.Context.Raw.Powerups["Mystery Box"] = 9, 9 scene.Context.Raw.Coins += 10
			scene.Context.GiftCount, scene.Context.GiftIds, scene.Context.GiftRecords = 0, {}, {} scene.Manager:Observe()
			assert(not scene.Manager:GetStatus().Pending and scene.Manager:GetStatus().BoxOutcomesObserved == 1)
		end)
	end)
end)

test("Observer changes between preparation and dispatch abort without consuming allowance", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } })
			local _, decision = scene.Manager:Select({})
			local _, _, _, pending = scene.Manager:Prepare(decision, { CheckCancelled = function() return false end })
			scene.Context.GiftRevision += 1
			assert(not scene.Manager:MarkDispatched(pending) and scene.Manager:AbortPreparation(pending))
			assert(scene.Manager:GetStatus().BoxesRequested == 0 and #scene.Commands == 0)
		end)
	end)
end)

test("Legacy pending gift without a proved public identity epoch stays preserved and blocked", function()
	withLedger(function()
		simulated(function()
			local scene = rewardFixture({ MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = true } })
			scene:Run() local pending = scene.Manager.Ledger.Pending pending.GiftIdentityEpoch = nil
			scene.Manager = Rewards.new(scene.Controller)
			assert(not scene.Manager:Select({}) and scene.Manager:AttributionBlocked() and #scene.Commands == 1)
			assert(shared.__OC_LOCAL_REWARD_LEDGER.Accounts["123"].Pending == pending)
		end)
	end)
end)

print(string.format("[OC TEST] %d isolated rewards tests passed; no live claims, gifts, inputs or account evidence", tests - rewardsBefore))
end

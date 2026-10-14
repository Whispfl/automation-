-- Synthetic actual-source free-ticket contracts. No real account or live transport.
local Defaults, Resolver = requireOC("OCConfig"), requireOC("ConfigResolver")
local Rewards, Mechanics, Scheduler = requireOC("RewardsManager"), requireOC("GameMechanics"), requireOC("TaskScheduler")
local checks, now = 0, 100
os.clock = function() return now end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copy(entry) end return result
end
local function same(left, right)
	if type(left) ~= type(right) then return false end
	if type(left) ~= "table" then return left == right end
	for key, entry in pairs(left) do if not same(entry, right[key]) then return false end end
	for key in pairs(right) do if left[key] == nil then return false end end
	return true
end
local function audit(name, callback)
	shared = {} now = 100 table.clear(queue)
	callback()
	checks += 1
	print("[OC FREE WHEEL SYNTHETIC] " .. name .. " passed")
end
local enabled = { ENABLE_FREE_WHEEL_TICKET_CLAIM = true, AUTHORIZED_ACCOUNT_ID = 101,
	AUTHORIZED_TEST_ID = "SYNTHETIC_FREE_TICKET_1", OWNER_CONFIRMED_WHEEL_IDLE = true,
	MAXIMUM_ACCOUNT_AGE_SECONDS = 10, CONFIRMATION_TIMEOUT_SECONDS = 15 }
local function fixture(changes, disable)
	local wheel = copy(enabled)
	for key, value in pairs(changes or {}) do wheel[key] = value end
	local config = Resolver.Resolve(Defaults, {
		GENERAL_SETTINGS = { AUTO_START = false, ENABLE_RECOMMENDATIONS = false },
		DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false },
		FREE_WHEEL_TICKET_SETTINGS = disable and {} or wheel,
	})
	local scene = { Config = config, Commands = {}, Logs = {}, Epochs = 0, ContextCalls = 0 }
	local player = { UserId = 101 }
	scene.Context = { Fresh = true, AccountId = 101, NativeNow = 1000, NextWheelSpin = 900, GiftCount = 0,
		TicketCount = 5, AutoClaimSpin = false, Revision = 1, ReadAt = now, QueueState = "UNKNOWN",
		TicketDefinition = { Type = "Powerup", Name = "Spin Ticket" }, NativeInterfaceIds = {
			ItemUtil = "synthetic-item", GetOwnedAmount = "synthetic-item-getter", Powerups = "synthetic-powerups",
			SpinTicket = "synthetic-ticket", Time = "synthetic-time", TimeNow = "synthetic-now",
			Remote = "synthetic-remote", FireServer = "synthetic-fire" },
		InterferenceFacts = { Balances = { Coins = 100, Gems = 50 }, Powerups = { ["Mystery Box"] = 2 },
			Potions = {}, Pets = {}, OtherRewards = { Playtime = { Claimed = {} }, Daily = { Claimed = false } } } }
	local reader = { Player = player, Revision = 1, Snapshot = { Ready = true, Revision = 1, ReadAt = now, Identity = { UserId = 101 } } }
	function reader:GetSnapshot() return self.Snapshot end
	function reader:_dependency(name) if name == "Remote" then return scene.Remote end return nil end
	scene.Reader = reader
	scene.Remote = { FireServer = function(_, ...)
		local arguments = table.pack(...)
		local pending = scene.Manager.Ledger.Pending
		assert(pending and pending.Kind == "FREE_WHEEL_TICKET" and pending.Attempted == true,
			"Attempt must be charged and pending before native dispatch")
		assert(scene.Manager.Ledger.FreeWheelTicket.Tests[pending.TestId].Attempts == 1,
			"One-attempt authorization must already be consumed at transport entry")
		assert(arguments.n == 1 and arguments[1] == "ClaimFreeWheelSpin", "Only exact no-argument native free claim is allowed")
		table.insert(scene.Commands, arguments)
		if scene.OnTransport then scene.OnTransport(pending) end
		if scene.TransportError then error("Synthetic uncertain transport failure") end
	end }
	local controller = { Config = config, Reader = reader, Snapshot = reader.Snapshot, State = "RUNNING", Generation = 1,
		RewardAttributionEpoch = 0, Log = function(_, tag, message) table.insert(scene.Logs, tag .. " " .. message) end }
	controller.Knowledge = { FreeWheelTicketContext = function(_, snapshot, observedNow, settings)
		scene.ContextCalls += 1
		if scene.OnContext then scene.OnContext(scene.ContextCalls) end
		return copy(scene.Context)
	end }
	function controller:MarkNonPickupReward()
		self.RewardAttributionEpoch += 1 scene.Epochs += 1
		if scene.OnMark then scene.OnMark() end
	end
	local mechanics = Mechanics.new(config, reader, {}, player, controller.Log)
	mechanics.LocalFeatureController = controller
	function mechanics:LocalFeatureGuard()
		if scene.OnGuard then scene.OnGuard() end
		return scene.GuardAllowed ~= false, "Synthetic interaction blocker"
	end
	controller.Farming = { Mechanics = mechanics }
	controller.Scheduler = Scheduler.new(config.TASK_SETTINGS)
	scene.Controller, scene.Mechanics = controller, mechanics
	scene.Manager = Rewards.new(controller) controller.Rewards = scene.Manager
	function scene:Select() return self.Manager:Select({}) end
	function scene:Lease(decision)
		local token = { Cancelled = false }
		function token:CheckCancelled() return self.Cancelled end
		local active = { Definition = { Id = "OC_GAMEPLAY", Owner = "REWARDS", Generation = self.Controller.Generation }, Token = token }
		self.Controller.Scheduler.Active = active
		self.Token, self.Active = token, active
		return token, active
	end
	function scene:Dispatch()
		local owns, decision = self:Select()
		assert(owns and decision.Kind == "FREE_WHEEL_TICKET", "Fixture must select the narrow free-ticket family")
		local token = self:Lease(decision)
		local result, reason = self.Mechanics:RewardAction(self.Manager, decision, token)
		return result, reason, decision
	end
	function scene:Receive(deadline, stock)
		self.Reader.Revision += 1 self.Reader.Snapshot.Revision = self.Reader.Revision self.Reader.Snapshot.ReadAt = now
		self.Context.Revision, self.Context.ReadAt = self.Reader.Revision, now
		if deadline ~= nil then self.Context.NextWheelSpin = deadline end
		if stock ~= nil then self.Context.TicketCount = stock end
		self.Manager:Observe()
	end
	function scene:Status() return self.Manager:GetFreeWheelTicketStatus() end
	function scene:Unresolved()
		local pending = self.Manager.Ledger and self.Manager.Ledger.Pending
		assert(pending and pending.Attempted and pending.Status == "UNCONFIRMED", "Uncertain attempt must retain unresolved shared pending barrier")
		assert(self:Status().Attempted and self:Status().Pending)
		assert(self.Manager:AttributionBlocked())
		local owns, decision = self:Select()
		if owns then assert(decision.Kind == "OBSERVE_REWARD" and self.Manager:Definition(decision, self.Controller.Generation) == nil) end
		assert(#self.Commands <= 1)
		return pending
	end
	function scene:Reload()
		self.Manager:Destroy()
		self.Manager = Rewards.new(self.Controller) self.Controller.Rewards = self.Manager
		self.Manager:Observe()
	end
	return scene
end

local function knowledgeFixture()
	local Reader, Knowledge = requireOC("AccountStateReader"), requireOC("GameKnowledge")
	local config = Resolver.Resolve(Defaults, { GENERAL_SETTINGS = { AUTO_START = false },
		DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false }, FREE_WHEEL_TICKET_SETTINGS = copy(enabled) })
	local s = { Config = config, NativeNow = 1000, GetterCalls = 0, Raw = { Coins = 100, Gems = 50,
		NextWheelSpin = 900, Powerups = { ["Spin Ticket"] = 5, ["Mystery Box"] = 2 }, Potions = {}, Pets = {},
		MasteryLevels = {}, MasteryUpgrades = { { Type = "Playtime" } }, AreasUnlocked = {}, WorldsUnlocked = {},
		PlaytimeRewards = { Start = 0, Claimed = {} }, DailyRewards = { LastDay = 0, LastStreak = 1, Claimed = false, Stars = 0 } } }
	local reader = Reader.new(config, { UserId = 101 }) s.Reader = reader
	reader.Revision = 1
	reader.Dependencies.LocalData = { Status = "READY", Value = {
		IsReady = function() return true end, Get = function() return s.Raw end } }
	for _, name in ipairs({ "Playtime", "DailyRewards", "WorldRewards", "Chests", "Prizes", "Potions", "WheelSpin",
		"ChallengePass", "Seasons", "Worlds", "Constants", "QuestUtil", "PrizesUtil", "StatsUtil" }) do
		reader.Dependencies[name] = { Status = "READY", Value = {} }
	end
	reader.Dependencies.Playtime.Value = { Gifts = {}, Prizes = {} }
	reader.Dependencies.Prizes.Value = { data = {} }
	reader.Dependencies.Powerups = { Status = "READY", Value = { ["Spin Ticket"] = { Name = "Synthetic ticket" }, ["Mystery Box"] = {} } }
	reader.Dependencies.Time = { Status = "READY", Value = {
		now = function() if s.OnTime then s.OnTime() end return s.NativeNow end,
		getAbsoluteDay = function() return math.floor(s.NativeNow / 86400) end } }
	reader.Dependencies.IsTradingPlaza = { Status = "READY", Value = function() return false end }
	reader.Dependencies.ItemUtil = { Status = "READY", Value = { GetOwnedAmount = function(_, facts, descriptor)
		s.GetterCalls += 1 if s.OnGet then s.OnGet(descriptor) end
		if descriptor.Type == "Powerup" then return (facts.Powerups or {})[descriptor.Name] or 0 end
		return nil
	end } }
	reader.Dependencies.Remote = { Status = "READY", Value = { FireServer = function() error("Read-only native observation must never dispatch") end } }
	reader.Dependencies.HatchPresentation = { Status = "READY", Value = { IsHatching = function() return false end } }
	reader.Dependencies.GuiFrame = { Status = "READY", Value = { IsAnyOpen = function() return false end } }
	reader.Dependencies.PhysicalItem = { Status = "READY", Value = { GetActiveObjects = function(_, kind)
		assert(kind == "Gift", "Only the reviewed native gift activity getter is permitted")
		s.GiftGetterCalls = (s.GiftGetterCalls or 0) + 1
		if s.OnGifts then return s.OnGifts(s.GiftGetterCalls) end return 0
	end } }
	reader.Dependencies.FishingPlayerRods = { Status = "READY", Value = { GetRodComponent = function() return nil end } }
	s.Knowledge = Knowledge.new(reader)
	function s:Sync()
		self.Snapshot = { Ready = true, Revision = self.Reader.Revision, ReadAt = now, Identity = { UserId = 101 },
			Balances = { Coins = self.Raw.Coins, Gems = self.Raw.Gems }, Inventory = { Powerups = copy(self.Raw.Powerups) },
			Upgrades = { MasteryLevels = copy(self.Raw.MasteryLevels), MasteryUpgrades = copy(self.Raw.MasteryUpgrades) },
			UnlockedWorlds = copy(self.Raw.WorldsUnlocked), UnlockedIslands = copy(self.Raw.AreasUnlocked) }
		self.Reader.Snapshot = self.Snapshot return self
	end
	function s:Context() return self.Knowledge:FreeWheelTicketContext(self.Snapshot, now, self.Config.FREE_WHEEL_TICKET_SETTINGS) end
	return s:Sync()
end

audit("actual native observation detaches coherent canonical received facts without actions", function()
	local s = knowledgeFixture() local original = copy(s.Raw) local queued = #queue
	local context = s:Context()
	assert(context.Fresh and context.AccountId == 101 and context.TicketCount == 5 and context.NextWheelSpin == 900)
	assert(context.AutoClaimSpin == false and context.NativeNow == 1000 and context.Due)
	assert(context.QueueState == "UNKNOWN" and context.InterferenceFacts.Powerups["Spin Ticket"] == nil)
	for _, key in ipairs({ "ItemUtil", "GetOwnedAmount", "Powerups", "SpinTicket", "Time", "TimeNow", "Remote", "FireServer" }) do
		assert(type(context.NativeInterfaceIds[key]) == "string" and context.NativeInterfaceIds[key] ~= "")
	end
	context.InterferenceFacts.Powerups["Mystery Box"] = 999
	context.TicketDefinition.Name = "Changed detached definition"
	assert(same(s.Raw, original) and s.Reader.Dependencies.Powerups.Value["Spin Ticket"].Name == "Synthetic ticket")
	assert(#queue == queued) s.Reader:Destroy()
end)

audit("native absent ticket key is zero only inside a verified complete received map", function()
	local s = knowledgeFixture() s.Raw.Powerups["Spin Ticket"] = nil s:Sync()
	assert(s:Context().Fresh and s:Context().TicketCount == 0)
	s.Raw.Powerups = nil s:Sync()
	assert(not s:Context().Fresh) s.Reader:Destroy()
end)

for _, fault in ipairs({
	{ Name = "missing whole canonical Powerups map", Apply = function(s) s.Raw.Powerups = nil end },
	{ Name = "malformed canonical ticket count", Apply = function(s) s.Raw.Powerups["Spin Ticket"] = -1 end },
	{ Name = "missing MasteryUpgrades map", Apply = function(s) s.Raw.MasteryUpgrades = nil end },
	{ Name = "malformed MasteryUpgrades row", Apply = function(s) s.Raw.MasteryUpgrades[2] = "unknown" end },
	{ Name = "native AutoClaimSpin enabled", Apply = function(s) s.Raw.MasteryUpgrades[2] = { Type = "AutoClaimSpin" } end },
	{ Name = "native ticket definition missing", Apply = function(s) s.Reader.Dependencies.Powerups.Value["Spin Ticket"] = nil end },
	{ Name = "native getter disagreement", Apply = function(s)
		s.Reader.Dependencies.ItemUtil.Value.GetOwnedAmount = function(_, facts, descriptor)
			return ((facts.Powerups or {})[descriptor.Name] or 0) + 1
		end
	end },
	{ Name = "native time unavailable", Apply = function(s) s.Reader.Dependencies.Time.Status = "LOADING" end },
	{ Name = "missing guard module", Apply = function(s) s.Reader.Dependencies.HatchPresentation.Status = "LOADING" end },
	{ Name = "missing FireServer transport", Apply = function(s) s.Reader.Dependencies.Remote.Value.FireServer = nil end },
	{ Name = "known active native gift", Apply = function(s) s.OnGifts = function() return 1 end end },
	{ Name = "native gift count unknown", Apply = function(s) s.OnGifts = function() return nil end end },
	{ Name = "native gift getter error", Apply = function(s) s.OnGifts = function() error("Synthetic unavailable gift getter") end end },
	{ Name = "native gift begins during ticket observation", Apply = function(s) s.OnGifts = function(index) return index > 1 and 1 or 0 end end },
}) do
	audit("actual native observer keeps unavailable state blocked: " .. fault.Name, function()
		local s = knowledgeFixture() fault.Apply(s) s:Sync()
		assert(not s:Context().Fresh) s.Reader:Destroy()
	end)
end

audit("actual native observation rejects account mutation during a reviewed getter", function()
	local s = knowledgeFixture()
	s.OnGet = function(descriptor) if descriptor.Name == "Spin Ticket" then s.Raw.NextWheelSpin += 1 end end
	assert(not s:Context().Fresh) s.Reader:Destroy()
end)

audit("actual native observation rejects snapshot revision racing during a reviewed getter", function()
	local s = knowledgeFixture()
	s.OnGet = function(descriptor) if descriptor.Name == "Spin Ticket" then s.Reader.Revision += 1 end end
	assert(not s:Context().Fresh) s.Reader:Destroy()
end)

audit("disabled actual native observer starts no dependency loads or getter calls", function()
	local s = knowledgeFixture() s.Reader.Dependencies = {}
	s.Config.FREE_WHEEL_TICKET_SETTINGS.ENABLE_FREE_WHEEL_TICKET_CLAIM = false
	local queued = #queue
	assert(not s:Context().Fresh and s.GetterCalls == 0 and next(s.Reader.Dependencies) == nil and #queue == queued)
	s.Reader:Destroy()
end)

audit("disabled defaults do not create wheel history, observe, or dispatch", function()
	local s = fixture(nil, true)
	assert(Defaults.FREE_WHEEL_TICKET_SETTINGS.ENABLE_FREE_WHEEL_TICKET_CLAIM == false)
	assert(Defaults.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_ACCOUNT_ID == 0)
	assert(Defaults.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_TEST_ID == "")
	assert(Defaults.FREE_WHEEL_TICKET_SETTINGS.OWNER_CONFIRMED_WHEEL_IDLE == false)
	local before = copy(s.Manager.Ledger)
	assert(not s:Select() and s.ContextCalls == 0 and #s.Commands == 0)
	assert(s.Manager.Ledger.FreeWheelTicket == nil and same(before, s.Manager.Ledger))
end)

audit("published candidate overrides keep every gameplay action disabled after merging", function()
	local merged = Resolver.Resolve(Defaults, phase5FreeWheelTicketDisabledOverrides())
	local wheel = merged.FREE_WHEEL_TICKET_SETTINGS
	assert(wheel.ENABLE_FREE_WHEEL_TICKET_CLAIM == false and wheel.AUTHORIZED_ACCOUNT_ID == 0
		and wheel.AUTHORIZED_TEST_ID == "" and wheel.OWNER_CONFIRMED_WHEEL_IDLE == false)
	assert(merged.GENERAL_SETTINGS.AUTO_START == false and merged.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS == false)
	for _, field in ipairs({
		{ "PLAYTIME_SETTINGS", "AUTO_CLAIM_PLAYTIME" }, { "MYSTERY_BOX_SETTINGS", "AUTO_OPEN_MYSTERY_BOXES" },
		{ "FARMING_SETTINGS", "AUTO_RESOURCE_FARM" }, { "FARMING_SETTINGS", "AUTO_FARM_FALLBACK" },
		{ "PICKUP_SETTINGS", "BULK_COLLECT_PICKUPS" }, { "PICKUP_SETTINGS", "ENABLE_CONTINUOUS_SCANNING" },
		{ "BUBBLE_SETTINGS", "AUTO_BLOW_BUBBLES" }, { "BUBBLE_SETTINGS", "AUTO_SELL_BUBBLES" },
		{ "BUBBLE_SETTINGS", "AUTO_BUY_GUM" }, { "BUBBLE_SETTINGS", "AUTO_BUY_FLAVORS" },
		{ "WORLD_SETTINGS", "ENABLE_WORLD_PROGRESSION" }, { "WORLD_SETTINGS", "AUTO_DISCOVER_ISLANDS" },
		{ "WORLD_SETTINGS", "AUTO_UNLOCK_WORLDS" }, { "WORLD_SETTINGS", "AUTO_TRAVEL_FOR_PROGRESSION" },
		{ "ISLAND_SETTINGS", "AUTO_TRAVEL_BEST_ISLAND" }, { "ISLAND_SETTINGS", "AUTO_EXPLORE_UNLOCKED_ISLANDS" },
		{ "PET_SETTINGS", "AUTO_HATCH" }, { "PET_SETTINGS", "AUTO_EQUIP" }, { "PET_SETTINGS", "AUTO_DELETE_PETS" },
		{ "PET_SETTINGS", "AUTO_CRAFT_SHINY" }, { "PET_SETTINGS", "AUTO_FUSE_PETS" },
		{ "HATCH_SETTINGS", "HATCH_ONE_EGG_ONCE" }, { "OWNER_ONE_HATCH_TEST_SETTINGS", "OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST" },
		{ "OWNER_ONE_HATCH_TEST_SETTINGS", "OWNER_ONE_HATCH_TEST_ALLOWANCE" },
		{ "EGG_TRAVEL_SETTINGS", "OWNER_DIRECT_EGG_TELEPORT_TEST" }, { "EGG_TRAVEL_SETTINGS", "ENABLE_SELECTED_EGG_TRAVEL" },
		{ "EGG_TRAVEL_SETTINGS", "ENABLE_DIRECT_POSITIONING" }, { "ANTIAFK_SETTINGS", "ENABLE_ANTI_AFK" },
		{ "FALL_EVENT_SETTINGS", "ENABLE_FALL_EVENT" }, { "UPGRADE_SETTINGS", "ENABLE_SMART_UPGRADES" },
	}) do assert(merged[field[1]][field[2]] == false, "Disabled candidate merged action flag is enabled: " .. field[1] .. "." .. field[2]) end
end)

for _, guard in ipairs({
	{ Name = "wrong account", Settings = { AUTHORIZED_ACCOUNT_ID = 202 } },
	{ Name = "zero account", Settings = { AUTHORIZED_ACCOUNT_ID = 0 } },
	{ Name = "empty test ID", Settings = { AUTHORIZED_TEST_ID = "" } },
	{ Name = "owner idle confirmation absent", Settings = { OWNER_CONFIRMED_WHEEL_IDLE = false } },
	{ Name = "explicit native auto-claim enabled", Mutate = function(s) s.Context.AutoClaimSpin = true end },
	{ Name = "native auto-claim unknown", Mutate = function(s) s.Context.AutoClaimSpin = nil end },
	{ Name = "stale account age", Mutate = function(s) s.Context.ReadAt = now - 11 end },
	{ Name = "future read timestamp", Mutate = function(s) s.Context.ReadAt = now + 1 end },
	{ Name = "freshness unavailable", Mutate = function(s) s.Context.Fresh = false end },
	{ Name = "reader revision mismatch", Mutate = function(s) s.Context.Revision = 2 end },
	{ Name = "account identity changed", Mutate = function(s) s.Context.AccountId = 202 end },
	{ Name = "deadline unavailable", Mutate = function(s) s.Context.NextWheelSpin = nil end },
	{ Name = "deadline not due", Mutate = function(s) s.Context.NextWheelSpin = 1001 end },
	{ Name = "native time unavailable", Mutate = function(s) s.Context.NativeNow = nil end },
	{ Name = "ticket baseline unavailable", Mutate = function(s) s.Context.TicketCount = nil end },
	{ Name = "ticket baseline nonintegral", Mutate = function(s) s.Context.TicketCount = 1.5 end },
	{ Name = "native ticket definition unavailable", Mutate = function(s) s.Context.TicketDefinition = nil end },
	{ Name = "native interface identities unavailable", Mutate = function(s) s.Context.NativeInterfaceIds = nil end },
	{ Name = "interference observations unavailable", Mutate = function(s) s.Context.InterferenceFacts = nil end },
	{ Name = "known wheel conflict", Mutate = function(s) s.Context.KnownWheelActivity = true end },
	{ Name = "known active gift", Mutate = function(s) s.Context.GiftCount = 1 end },
	{ Name = "gift activity unavailable", Mutate = function(s) s.Context.GiftCount = nil end },
	{ Name = "unresolved previous reward attribution", Mutate = function(s) s.Manager.Ledger.UnresolvedAttribution = true end },
}) do
	audit("preflight fails closed: " .. guard.Name, function()
		local s = fixture(guard.Settings) if guard.Mutate then guard.Mutate(s) end
		local owns, decision = s:Select()
		assert(not owns or decision.Kind ~= "FREE_WHEEL_TICKET", "Unavailable or unapproved claim must not be selected")
		assert(#s.Commands == 0 and s.Manager.Ledger.Pending == nil and not s:Status().Attempted)
	end)
end

audit("canonical positive receipt needs both observed facts and reports actual quantity", function()
	local s = fixture() assert(s:Dispatch())
	assert(#s.Commands == 1 and s:Status().Attempted and s:Status().Pending)
	s:Receive(1900, 8)
	local status = s:Status()
	assert(status.ReceiptState == "CLAIM_AND_GRANT_OBSERVED" and status.TicketsReceived == 3)
	assert(not status.Pending and status.Attempted and status.Attribution == "EXTERNAL_GAINS_CANNOT_BE_EXCLUDED")
	assert(not s.Manager.Ledger.Pending and not s:Select() and #s.Commands == 1)
	assert(s.Manager.Ledger.FreeWheelTicket.Tests[enabled.AUTHORIZED_TEST_ID].Attempts == 1)
end)

for _, first in ipairs({ "deadline", "inventory" }) do
	audit("split receipt updates remain pending until final paired context: " .. first, function()
		local s = fixture() assert(s:Dispatch())
		if first == "deadline" then s:Receive(1900, nil) else s:Receive(nil, 6) end
		assert(s:Status().Pending and s:Status().ReceiptState == (first == "deadline" and "DEADLINE_ONLY" or "INVENTORY_ONLY"))
		assert(s.Manager.Ledger.Pending and #s.Commands == 1)
		s:Receive(1900, 6)
		assert(s:Status().ReceiptState == "CLAIM_AND_GRANT_OBSERVED" and s:Status().TicketsReceived == 1)
	end)
end

for _, partial in ipairs({ "deadline", "inventory", "neither" }) do
	audit("partial or absent receipt times out without retry: " .. partial, function()
		local s = fixture() assert(s:Dispatch())
		if partial == "deadline" then s:Receive(1900, nil) elseif partial == "inventory" then s:Receive(nil, 6) end
		now += 16 s:Receive(nil, nil)
		s:Unresolved()
		assert(s:Status().ReceiptState == "UNCONFIRMED_TIMEOUT" and s:Status().TicketsReceived == nil)
		s.Config.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_TEST_ID = "SYNTHETIC_BYPASS_ATTEMPT"
		s:Reload() s:Unresolved() assert(#s.Commands == 1)
	end)
end

audit("a changed deadline already in the past cannot satisfy a future receipt", function()
	local s = fixture() assert(s:Dispatch())
	s.Context.NativeNow = 2000 s:Receive(1900, 6)
	assert(s:Status().Pending and s:Status().ReceiptState == "INVENTORY_ONLY" and not s:Status().DeadlineObserved)
	now += 16 s:Receive(nil, nil) s:Unresolved()
	assert(s:Status().ReceiptState == "UNCONFIRMED_TIMEOUT")
end)

audit("known external ticket-gain evidence makes paired correlation sticky ambiguous", function()
	local s = fixture() assert(s:Dispatch())
	-- An observed other claim transition accompanies the ticket gain. A bare ticket delta cannot identify its source.
	s.Context.InterferenceFacts.OtherRewards.Playtime.Claimed["1"] = true
	s:Receive(1900, 7) s:Unresolved()
	assert(s:Status().ReceiptState == "AMBIGUOUS" and s:Status().TicketsReceived == nil)
	s.Context.InterferenceFacts.OtherRewards.Playtime.Claimed["1"] = nil
	s:Receive(1900, 7) s:Unresolved()
	assert(s:Status().ReceiptState == "AMBIGUOUS")
end)

audit("observationally indistinguishable external gain remains explicitly qualified", function()
	local s = fixture() assert(s:Dispatch())
	-- There is deliberately no evidence identifying the grant's source. Offline state changes cannot prove server attribution.
	s:Receive(1900, 9)
	assert(s:Status().ReceiptState == "CLAIM_AND_GRANT_OBSERVED" and s:Status().TicketsReceived == 4)
	assert(s:Status().Attribution == "EXTERNAL_GAINS_CANNOT_BE_EXCLUDED")
end)

for _, interference in ipairs({
	{ Name = "other inventory gain", Mutate = function(s) s.Context.InterferenceFacts.Powerups["Mystery Box"] += 1 end },
	{ Name = "other native reward transition", Mutate = function(s) s.Context.InterferenceFacts.OtherRewards.Daily.Claimed = true end },
	{ Name = "new pet grant", Mutate = function(s) s.Context.InterferenceFacts.Pets["synthetic-pet"] = { Name = "Synthetic Pet" } end },
	{ Name = "attribution epoch interference", Mutate = function(s) s.Controller.RewardAttributionEpoch += 1 end },
	{ Name = "known wheel activity", Mutate = function(s) s.Context.KnownWheelActivity = true end },
	{ Name = "ticket consumption", Mutate = function(s) s.Context.TicketCount = 4 end },
	{ Name = "deadline contradiction", Mutate = function(s) s.Context.NextWheelSpin = 800 end },
	{ Name = "ticket definition changed", Mutate = function(s) s.Context.TicketDefinition.Revision = "changed" end },
	{ Name = "native getter identity changed", Mutate = function(s) s.Context.NativeInterfaceIds.GetOwnedAmount = "new-getter" end },
}) do
	audit("competing or contradictory observations block settlement: " .. interference.Name, function()
		local s = fixture() assert(s:Dispatch()) interference.Mutate(s) s:Receive(nil, nil)
		s:Unresolved()
		assert(s:Status().ReceiptState ~= "CLAIM_AND_GRANT_OBSERVED" and s:Status().TicketsReceived == nil)
		s:Receive(1900, 8) s:Unresolved() assert(#s.Commands == 1)
	end)
end

audit("one attempt cannot duplicate before receipt, after receipt, reload, or test-ID change", function()
	local s = fixture() assert(s:Dispatch()) local original = s.Manager.Ledger.Pending
	local owns, decision = s:Select()
	assert(owns and decision.Kind == "OBSERVE_REWARD")
	assert(not s.Mechanics:ClaimFreeWheelTicket(s.Manager, { Kind = "FREE_WHEEL_TICKET", TestId = enabled.AUTHORIZED_TEST_ID }, s.Token, s.Remote))
	assert(s.Manager.Ledger.Pending == original and #s.Commands == 1)
	s:Receive(1900, 6) s:Reload()
	assert(not s:Select())
	s.Config.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_TEST_ID = "SYNTHETIC_NEW_ID"
	s.Context.NextWheelSpin = 900
	assert(not s:Select(), "A new test ID cannot bypass the consumed runtime authorization")
	-- A different ID cannot replay an old selected decision or rearm the consumed original authorization.
	assert(not s.Mechanics:ClaimFreeWheelTicket(s.Manager, { Kind = "FREE_WHEEL_TICKET", TestId = enabled.AUTHORIZED_TEST_ID,
		NextWheelSpin = 900, TicketCount = 5 }, s.Token, s.Remote))
	assert(#s.Commands == 1)
end)

audit("cancelled before dispatch consumes no attempt and sends no command", function()
	local s = fixture() local owns, decision = s:Select() assert(owns)
	local token = s:Lease(decision) token.Cancelled = true
	assert(not s.Mechanics:RewardAction(s.Manager, decision, token))
	assert(#s.Commands == 0 and not s:Status().Attempted and not s.Manager.Ledger.Pending)
end)

for _, chargedRace in ipairs({ "cancellation", "remote replacement", "authorization revocation", "test ID replacement",
	"native auto-claim activation", "canonical ticket baseline change" }) do
	audit("charged attempt interrupted before transport stays consumed: " .. chargedRace, function()
		local s = fixture() local owns, decision = s:Select() assert(owns)
		local token = s:Lease(decision)
		s.OnMark = function()
			if chargedRace == "cancellation" then token.Cancelled = true
			elseif chargedRace == "remote replacement" then s.Remote = { FireServer = function() error("Replacement remote must never dispatch") end }
			elseif chargedRace == "authorization revocation" then s.Config.FREE_WHEEL_TICKET_SETTINGS.ENABLE_FREE_WHEEL_TICKET_CLAIM = false
			elseif chargedRace == "test ID replacement" then s.Config.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_TEST_ID = "SYNTHETIC_POST_CHARGE_CHANGE"
			elseif chargedRace == "native auto-claim activation" then s.Context.AutoClaimSpin = true
			else s.Context.TicketCount = 6 end
		end
		assert(not s.Mechanics:RewardAction(s.Manager, decision, token))
		s:Unresolved()
		assert(#s.Commands == 0 and s.Manager.Ledger.FreeWheelTicket.Tests[enabled.AUTHORIZED_TEST_ID].Attempts == 1)
		s:Reload() s:Unresolved() assert(#s.Commands == 0)
	end)
end

audit("interaction guard change during charged final context prevents native dispatch", function()
	local s = fixture()
	s.OnContext = function(index) if index == 4 then s.GuardAllowed = false end end
	assert(not s:Dispatch())
	s:Unresolved()
	assert(s.ContextCalls >= 4 and #s.Commands == 0
		and s.Manager.Ledger.FreeWheelTicket.Tests[enabled.AUTHORIZED_TEST_ID].Attempts == 1)
end)

audit("snapshot revision change during final interaction guard prevents native dispatch", function()
	local s = fixture() local guardCalls = 0
	s.OnGuard = function()
		guardCalls += 1
		if guardCalls == 4 then
			s.Reader.Revision += 1 s.Reader.Snapshot.Revision = s.Reader.Revision
		end
	end
	assert(not s:Dispatch())
	s:Unresolved()
	assert(guardCalls >= 4 and #s.Commands == 0
		and s.Manager.Ledger.FreeWheelTicket.Tests[enabled.AUTHORIZED_TEST_ID].Attempts == 1)
end)

for _, lifecycle in ipairs({ "Pause", "Stop", "Token", "Generation", "Authorization", "Reload" }) do
	audit("interruption retains consumed pending through " .. lifecycle, function()
		local s = fixture() assert(s:Dispatch())
		if lifecycle == "Pause" then s.Controller.State = "PAUSED" s.Manager:Halt(false)
		elseif lifecycle == "Stop" then s.Controller.State = "STOPPED" s.Manager:Halt(true)
		elseif lifecycle == "Token" then s.Token.Cancelled = true s.Manager:Observe()
		elseif lifecycle == "Generation" then s.Controller.Generation += 1 s.Manager:Observe()
		elseif lifecycle == "Authorization" then s.Config.FREE_WHEEL_TICKET_SETTINGS.ENABLE_FREE_WHEEL_TICKET_CLAIM = false s.Manager:Observe()
		else s:Reload() end
		s:Unresolved()
		s.Controller.State = "RUNNING" s.Token.Cancelled = false
		s.Config.FREE_WHEEL_TICKET_SETTINGS.ENABLE_FREE_WHEEL_TICKET_CLAIM = true
		s:Receive(1900, 6) s:Unresolved()
		assert(s:Status().ReceiptState == "OBSERVED_AFTER_INTERRUPTION" and #s.Commands == 1)
		assert(s.Manager.Ledger.FreeWheelTicket.Tests[enabled.AUTHORIZED_TEST_ID].Attempts == 1)
	end)
end

audit("transport exception after attempt is unresolved even with later paired changes", function()
	local s = fixture() s.TransportError = true s:Dispatch()
	s:Unresolved() s:Receive(1900, 6) s:Unresolved()
	assert(s:Status().ReceiptState == "AMBIGUOUS" and #s.Commands == 1)
end)

audit("required observation unavailable after dispatch is sticky unresolved", function()
	local s = fixture() assert(s:Dispatch())
	s.Context.Fresh = false s.Manager:Observe() s:Unresolved()
	s.Context.Fresh = true s:Receive(1900, 6) s:Unresolved()
	assert(s:Status().ReceiptState == "AMBIGUOUS")
end)

audit("canonical account identity racing during preparation blocks native dispatch", function()
	local s = fixture() local owns, decision = s:Select() assert(owns)
	local token = s:Lease(decision)
	s.OnContext = function() s.Reader.Player.UserId = 202 end
	assert(not s.Mechanics:RewardAction(s.Manager, decision, token))
	assert(#s.Commands == 0 and not s:Status().Attempted)
end)

for _, flaw in ipairs({ "lease", "owner", "token", "generation", "manager", "transport", "remote", "guard", "intent", "command" }) do
	audit("claim adapter independently rejects invalid " .. flaw, function()
		local s = fixture() local owns, decision = s:Select() assert(owns)
		local token, active = s:Lease(decision)
		local manager, remote = s.Manager, s.Remote
		if flaw == "lease" then s.Controller.Scheduler.Active = nil
		elseif flaw == "owner" then active.Definition.Owner = "FARMING"
		elseif flaw == "token" then token = { CheckCancelled = function() return false end }
		elseif flaw == "generation" then active.Definition.Generation = 0
		elseif flaw == "manager" then manager = Rewards.new(s.Controller)
		elseif flaw == "transport" then s.Remote.FireServer = nil
		elseif flaw == "remote" then remote = { FireServer = function() error("Wrong transport must never execute") end }
		elseif flaw == "guard" then s.GuardAllowed = false
		elseif flaw == "intent" then decision.Kind = "SPIN_WHEEL"
		else decision.Command = "SpinWheel" end
		assert(not s.Mechanics:ClaimFreeWheelTicket(manager, decision, token, remote))
		assert(#s.Commands == 0 and not s:Status().Attempted)
	end)
end

audit("scheduler token replaced during coherent preflight cannot dispatch", function()
	local s = fixture() local owns, decision = s:Select() assert(owns)
	local token, active = s:Lease(decision)
	s.OnContext = function() active.Token = { CheckCancelled = function() return false end } end
	assert(not s.Mechanics:RewardAction(s.Manager, decision, token))
	assert(#s.Commands == 0 and not s:Status().Attempted)
end)

audit("pre-dispatch native state change cannot reuse a selected decision", function()
	local s = fixture() local owns, decision = s:Select() assert(owns)
	local token = s:Lease(decision)
	s.Context.TicketCount = 6
	assert(not s.Mechanics:RewardAction(s.Manager, decision, token))
	assert(#s.Commands == 0 and not s:Status().Attempted)
end)

audit("single central scheduler runs the unchanged Rewards Definition slice", function()
	local s = fixture() local owns, decision = s:Select() assert(owns)
	local definition = s.Manager:Definition(decision, s.Controller.Generation)
	assert(definition.Id == "OC_GAMEPLAY" and definition.Owner == "REWARDS")
	s.Controller.Scheduler:Resume() assert(s.Controller.Scheduler:Submit(definition)) flush()
	local active = s.Controller.Scheduler.Active
	assert(active and active.Definition == definition and #s.Commands == 1)
	s:Receive(1900, 6)
	assert(coroutine.resume(active.Thread)) flush()
	assert(s.Controller.Scheduler.Active == nil and s:Status().ReceiptState == "CLAIM_AND_GRANT_OBSERVED")
	assert(not s:Select() and #s.Commands == 1)
	s.Controller.Scheduler:Destroy()
end)

audit("old pending operation remains the same single shared barrier", function()
	local s = fixture(nil, true)
	local old = { Kind = "PLAYTIME", UserId = 101, Index = 1, CycleStart = 0, Attempted = true,
		Status = "UNCONFIRMED", Deadline = now + 15, BeforeFacts = {
			Available = {}, Balances = {}, Powerups = {}, Potions = {}, Pets = {} } }
	s.Manager.Ledger.Pending = old
	s.Config.FREE_WHEEL_TICKET_SETTINGS = copy(enabled)
	s.Manager = Rewards.new(s.Controller) s.Controller.Rewards = s.Manager
	local owns, decision = s:Select()
	assert(owns and decision.Kind == "OBSERVE_REWARD" and decision.Pending == old)
	assert(s.Manager.Ledger.Pending == old and #s.Commands == 0 and s.ContextCalls == 0)
end)

for _, corrupt in ipairs({
	{ Name = "unknown extension version", Apply = function(ledger) ledger.FreeWheelTicket.Version = 999 end },
	{ Name = "missing test map", Apply = function(ledger) ledger.FreeWheelTicket.Tests = nil end },
	{ Name = "fractional attempt charge", Apply = function(ledger) ledger.FreeWheelTicket.Tests[enabled.AUTHORIZED_TEST_ID] = { Attempts = 0.5, Outcome = "AWAITING_RECEIPT" } end },
	{ Name = "unknown pending schema", Apply = function(ledger) ledger.Pending = { Kind = "FREE_WHEEL_TICKET", UserId = 101, Attempted = true } end },
}) do
	audit("malformed retained wheel ledger remains preserved and blocks: " .. corrupt.Name, function()
		local s = fixture() corrupt.Apply(s.Manager.Ledger)
		local original = copy(shared.__OC_LOCAL_REWARD_LEDGER)
		s.Manager = Rewards.new(s.Controller) s.Controller.Rewards = s.Manager
		assert(s.Manager.UnknownBarrier and not s:Select() and #s.Commands == 0)
		assert(same(original, shared.__OC_LOCAL_REWARD_LEDGER), "Malformed ledger must not be silently reset")
	end)
end

audit("privacy-safe status exposes no account or inventory baseline facts", function()
	local s = fixture() assert(s:Dispatch()) s:Receive(1900, 7)
	local function inspect(value)
		if type(value) ~= "table" then return end
		for key, entry in pairs(value) do
			assert(key ~= "UserId" and key ~= "AccountId" and key ~= "AUTHORIZED_ACCOUNT_ID"
				and key ~= "BeforeFacts" and key ~= "BeforeTicketCount" and key ~= "TicketCount" and key ~= "Balances",
				"Public receipt status must not contain account or inventory baseline facts")
			inspect(entry)
		end
	end
	inspect(s:Status())
end)

print("[OC FREE WHEEL SYNTHETIC] " .. checks .. " actual-source contract checks passed; no live claim or server acceptance proven.")

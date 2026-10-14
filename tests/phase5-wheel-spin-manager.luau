-- Synthetic actual-manager lifecycle fixture for the separately owner-approved
-- integration. No real accounts, native input, transport or live actions.
local Defaults, Resolver = requireOC("OCConfig"), requireOC("ConfigResolver")
local Rewards, Scheduler = requireOC("RewardsManager"), requireOC("TaskScheduler")
local checks, now = 0, 100
os.clock = function() return now end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copy(entry) end return result
end
local function same(left, right)
	if type(left) ~= type(right) then return false end
	if type(left) ~= "table" then return left == right end
	for key, value in pairs(left) do if not same(value, right[key]) then return false end end
	for key in pairs(right) do if left[key] == nil then return false end end return true
end
local function test(name, callback)
	shared = {} now = 100 table.clear(queue)
	callback() checks += 1 print("[OC WHEEL MANAGER SYNTHETIC] " .. name .. " passed")
end
local enabled = { AUTO_SPIN_WHEEL = true, OWNER_ONE_SPIN_ALLOWANCE = true, AUTHORIZED_ACCOUNT_ID = 101,
	AUTHORIZED_TEST_ID = "SYNTHETIC_SPIN_1", OWNER_CONFIRMED_WHEEL_IDLE = true,
	MAXIMUM_ACCOUNT_AGE_SECONDS = 10, CONFIRMATION_TIMEOUT_SECONDS = 20 }
local function fixture(options)
	options = options or {}
	local overrides = phase5WheelSpinManagerOverrides()
	overrides.WHEEL_SPIN_SETTINGS = options.Disabled and {} or copy(enabled)
	for key, value in pairs(options.Settings or {}) do overrides.WHEEL_SPIN_SETTINGS[key] = value end
	if options.Config then options.Config(overrides) end
	local config = Resolver.Resolve(Defaults, overrides)
	local s = { Config = config, ContextCalls = 0, Logs = {}, Inputs = 0, Commands = 0, ReceiptRevision = 0 }
	s.Raw = { Coins = 100, Gems = 50, Powerups = { ["Spin Ticket"] = 5, ["Mystery Box"] = 2 },
		Potions = { { Name = "Coins", Level = 3, Amount = 2 } }, Pets = { { Id = "synthetic-doggy", Name = "Doggy", Amount = 3 } },
		MasteryUpgrades = {}, AreasUnlocked = { ["Floating Island"] = true }, WorldsUnlocked = { ["The Overworld"] = true } }
	s.Pool = {
		{ Chance = 45, Item = { Type = "Currency", Currency = "Coins", Amount = 200 } },
		{ Chance = 20, Item = { Type = "Currency", Currency = "Coins", Amount = 450 } },
		{ Chance = 14, Item = { Type = "Potion", Name = "Coins", Level = 3, Amount = 1 } },
		{ Chance = 10, Item = { Type = "Powerup", Name = "Golden Key", Amount = 1 } },
		{ Chance = 4, Item = { Type = "Potion", Name = "Speed", Level = 3, Amount = 1 } },
		{ Chance = 3, Item = { Type = "Powerup", Name = "Mystery Box", Amount = 1 } },
		{ Chance = 2.9, Item = { Type = "Powerup", Name = "Spin Ticket", Amount = 5 } },
		{ Chance = 0.1, Item = { Type = "Pet", Name = "Umbra" } },
	}
	local player = { UserId = 101 }
	local reader = { Player = player, Revision = 1, Snapshot = { Ready = true, Revision = 1, ReadAt = now, Identity = { UserId = 101 } } }
	function reader:GetSnapshot() return self.Snapshot end
	local controller = { Config = config, Reader = reader, State = "RUNNING", Generation = 1, RewardAttributionEpoch = 0,
		Scheduler = Scheduler.new(config.TASK_SETTINGS), Pets = { Hatch = {} } }
	function controller:Log(tag, text) table.insert(s.Logs, tag .. " " .. text) end
	function controller:MarkNonPickupReward() self.RewardAttributionEpoch += 1 end
	local nativeRemote, button = {}, {}
	controller.Knowledge = { WheelSpinContext = function(_, snapshot, observedAt, settings, allowBusy)
		s.ContextCalls += 1 s.ReceiptRevision += 1
		if s.OnContext then s.OnContext(s.ContextCalls, allowBusy) end
		if s.ContextError then error("Synthetic unavailable native observation") end
		if s.ContextUnknown then return { Fresh = false, Blocker = "Synthetic unknown native context" } end
		for _, row in pairs(s.Raw.MasteryUpgrades or {}) do
			if row.Type == "AutoClaimSpin" then return { Fresh = false, Blocker = "Native AutoClaimSpin conflicts with isolated wheel receipt" } end
		end
		return { Fresh = true, UserId = s.ContextAccount or 101, AccountId = s.ContextAccount or 101,
			Raw = copy(s.Raw), Balances = { Coins = s.Raw.Coins, Gems = s.Raw.Gems },
			Revision = reader.Revision, ReceiptRevision = s.ReceiptRevision, ReadAt = now,
			Pool = copy(s.Pool), TicketCount = s.Raw.Powerups and s.Raw.Powerups["Spin Ticket"] or 0,
			NativeRefs = { Remote = nativeRemote }, GUI = { SpinButton = button }, WheelAnimationSeconds = 6 }
	end }
	controller.Farming = { Mechanics = {} }
	if options.Before then options.Before(s, controller) end
	s.Controller, s.Reader = controller, reader
	s.Manager = Rewards.new(controller) controller.Rewards = s.Manager
	function s:Lease()
		local token = { Cancelled = false }
		function token:CheckCancelled() return self.Cancelled end
		controller.Scheduler.Active = { Token = token, Definition = { Id = "OC_GAMEPLAY", Owner = "REWARDS", Generation = controller.Generation } }
		self.Token = token return token
	end
	function s:Prepare()
		local owns, decision = self.Manager:SelectWheelSpin()
		assert(owns and decision.Kind == "WHEEL_SPIN" and decision.Count == 1)
		local pending, reason = self.Manager:PrepareWheelSpin(decision, self:Lease())
		assert(pending, reason)
		self.Pending, self.Decision = pending, decision return pending
	end
	function s:Charge()
		local pending = self:Prepare()
		assert(self.Manager:MarkWheelSpinDispatched(pending, self.Token))
		assert(pending.Attempted and self.Manager.Ledger.WheelSpin.Tests[pending.TestId].Attempts == 1)
		assert(self.Inputs == 0 and self.Commands == 0, "Charge must precede any synthetic input or native command")
		return pending
	end
	function s:Return(index)
		local pending = self.Pending or self:Charge()
		local context = self.Manager:GetWheelSpinContext(true)
		local ok, reason = self.Manager:AcceptWheelSpinReturn(pending, index, context)
		if ok then pending.InvokeReturned = true pending.NativeAnimationStartedAt = now pending.TransportCount = 1 end
		return ok, reason
	end
	function s:Observe() self.Manager:ObserveWheelSpin(self.Pending) return self.Pending end
	function s:Reload()
		self.Manager = Rewards.new(controller) controller.Rewards = self.Manager return self.Manager
	end
	return s
end

test("disabled extension yields nil and preserves ordinary disabled rewards", function()
	local s = fixture({ Disabled = true }) local before = copy(s.Manager.Ledger)
	assert(s.Manager:SelectWheelSpin() == nil and s.ContextCalls == 0 and s.Manager.Ledger.WheelSpin == nil)
	assert(not s.Manager:Select({}) and same(before, s.Manager.Ledger))
	assert(Defaults.WHEEL_SPIN_SETTINGS.AUTO_SPIN_WHEEL == false and Defaults.WHEEL_SPIN_SETTINGS.OWNER_ONE_SPIN_ALLOWANCE == false)
end)

for _, settings in ipairs({
	{ "disabled spin", { AUTO_SPIN_WHEEL = false } }, { "missing allowance", { OWNER_ONE_SPIN_ALLOWANCE = false } },
	{ "wrong account", { AUTHORIZED_ACCOUNT_ID = 202 } }, { "zero account", { AUTHORIZED_ACCOUNT_ID = 0 } },
	{ "missing test ID", { AUTHORIZED_TEST_ID = "" } }, { "invalid test ID", { AUTHORIZED_TEST_ID = "invalid space" } },
	{ "missing owner idle confirmation", { OWNER_CONFIRMED_WHEEL_IDLE = false } },
	{ "short confirmation timeout", { CONFIRMATION_TIMEOUT_SECONDS = 7 } }, { "unbounded confirmation timeout", { CONFIRMATION_TIMEOUT_SECONDS = 31 } },
	{ "zero freshness bound", { MAXIMUM_ACCOUNT_AGE_SECONDS = 0 } }, { "expanded freshness bound", { MAXIMUM_ACCOUNT_AGE_SECONDS = 11 } },
}) do
	test("explicit one-spin authorization rejects " .. settings[1], function()
		local s = fixture({ Settings = settings[2] })
		assert(not s.Manager:WheelSpinAuthorization() and not s.Manager:SelectWheelSpin() and s.ContextCalls == 0)
		assert(s.Manager.Ledger.Pending == nil)
	end)
end

for _, flag in ipairs({ { "FREE_WHEEL_TICKET_SETTINGS", "ENABLE_FREE_WHEEL_TICKET_CLAIM" },
	{ "PET_SETTINGS", "AUTO_HATCH" }, { "PET_SETTINGS", "AUTO_EQUIP" }, { "WORLD_SETTINGS", "ENABLE_WORLD_PROGRESSION" },
	{ "EGG_TRAVEL_SETTINGS", "ENABLE_DIRECT_POSITIONING" }, { "PLAYTIME_SETTINGS", "AUTO_CLAIM_PLAYTIME" },
	{ "MYSTERY_BOX_SETTINGS", "AUTO_OPEN_MYSTERY_BOXES" }, { "FARMING_SETTINGS", "AUTO_RESOURCE_FARM" },
	{ "PICKUP_SETTINGS", "BULK_COLLECT_PICKUPS" }, { "BUBBLE_SETTINGS", "AUTO_BLOW_BUBBLES" },
	{ "UPGRADE_SETTINGS", "ENABLE_SMART_UPGRADES" }, { "ANTIAFK_SETTINGS", "ENABLE_ANTI_AFK" } }) do
	test("isolation rejects unrelated enabled " .. flag[1] .. "." .. flag[2], function()
		local s = fixture({ Config = function(c) c[flag[1]][flag[2]] = true end })
		assert(not s.Manager:WheelSpinAuthorization() and not s.Manager:SelectWheelSpin() and s.ContextCalls == 0)
	end)
end

for _, budget in ipairs({ { "HATCH_SETTINGS", "MAXIMUM_EGG_COST" }, { "HATCH_SETTINGS", "MAXIMUM_SESSION_COST" },
	{ "OWNER_ONE_HATCH_TEST_SETTINGS", "MAXIMUM_COIN_ALLOWANCE" }, { "OWNER_ONE_HATCH_TEST_SETTINGS", "MAXIMUM_EGG_COST" },
	{ "WORLD_SETTINGS", "MAXIMUM_WORLD_UNLOCK_COST" }, { "UPGRADE_SETTINGS", "MAXIMUM_PURCHASE_COST" } }) do
	test("isolation requires zero " .. budget[1] .. "." .. budget[2], function()
		local s = fixture({ Config = function(c) c[budget[1]][budget[2]] = 1 end })
		assert(not s.Manager:WheelSpinAuthorization() and not s.Manager:SelectWheelSpin() and s.ContextCalls == 0)
	end)
end

for _, fault in ipairs({
	{ "unknown native context", function(s) s.ContextUnknown = true end },
	{ "native context exception", function(s) s.ContextError = true end },
	{ "native AutoClaimSpin", function(s) s.Raw.MasteryUpgrades = { { Type = "AutoClaimSpin" } } end },
	{ "wrong context account", function(s) s.ContextAccount = 202 end },
	{ "missing canonical inventory", function(s) s.Raw.Powerups = nil end },
	{ "zero owned stock", function(s) s.Raw.Powerups["Spin Ticket"] = 0 end },
	{ "pending equipment", function(_, c) c.Pets.PendingEquip = {} end },
	{ "pending hatch", function(_, c) c.Pets.Hatch.Pending = {} end },
}) do
	test("readiness fails closed for " .. fault[1], function()
		local s = fixture({ Before = fault[2] }) local owns, decision = s.Manager:SelectWheelSpin()
		assert(owns ~= true and decision.Kind == "WAIT" and s.Manager.Ledger.Pending == nil)
	end)
end

test("foreign pending reward retains identity and bypasses spin observation", function()
	local s = fixture()
	local pending = { Kind = "PLAYTIME", UserId = 101 }
	s.Manager.Ledger.Pending = pending
	assert(s.Manager:SelectWheelSpin() == nil and s.Manager.Ledger.Pending == pending and s.ContextCalls == 0)
end)

test("malformed shared root cannot initialize an action manager", function()
	local s = fixture({ Before = function() shared.__OC_LOCAL_REWARD_LEDGER = { Version = 99, Accounts = {} } end })
	assert(s.Manager.UnknownBarrier and not s.Manager:SelectWheelSpin() and s.ContextCalls == 0)
end)

test("unresolved attribution never becomes a new spin allowance", function()
	local s = fixture() s.Manager.Ledger.UnresolvedAttribution = true
	assert(not s.Manager:SelectWheelSpin() and s.ContextCalls == 0)
end)

for _, corrupt in ipairs({
	{ "unknown wheel ledger version", function(v) v.Version = 99 end },
	{ "missing tests map", function(v) v.Tests = nil end },
	{ "invalid wheel epoch", function(v) v.Epoch = -1 end },
	{ "malformed test record", function(v) v.Tests.BAD = { Attempts = 0 } end },
}) do
	test("malformed retained spin schema preserved: " .. corrupt[1], function()
		local s = fixture() corrupt[2](s.Manager.Ledger.WheelSpin)
		local original = copy(shared)
		local m = s:Reload()
		assert(m.UnknownBarrier and not m:SelectWheelSpin() and same(shared, original))
	end)
end

test("coherent preparation preserves copied before facts and native observation sequence", function()
	local s = fixture() local pending = s:Prepare()
	assert(pending.BeforeFacts.UserId == 101 and pending.BeforeFacts.Tickets == 5)
	assert(pending.BeforeFacts.Revision == s.ReceiptRevision and s.Reader.Revision == 1)
	assert(pending.Attempted == false and s.Manager.Ledger.WheelSpin.Tests[pending.TestId].Attempts == 0)
	local captured = copy(pending.BeforeFacts)
	s.Raw.Coins += 1 s.Raw.Potions[1].Amount += 1
	assert(same(captured, pending.BeforeFacts) and pending.Count == 1)
end)

test("one allowance is charged before any native input and cannot charge twice", function()
	local s = fixture() local pending = s:Charge()
	assert(not s.Manager:MarkWheelSpinDispatched(pending, s.Token))
	assert(s.Manager.Ledger.WheelSpin.Tests[pending.TestId].Attempts == 1 and s.Manager:GetWheelSpinStatus().ChargedAttempts == 1)
	s.Config.WHEEL_SPIN_SETTINGS.AUTHORIZED_TEST_ID = "SYNTHETIC_SECOND_ID"
	s.Manager.Ledger.Pending = nil -- Artificial corruption must not rearm a consumed unresolved record.
	assert(not s.Manager:SelectWheelSpin())
end)

test("charged pending reload retains one attempt and becomes cancelled without rearm", function()
	local s = fixture() local pending = s:Charge()
	local m = s:Reload()
	assert(not m.UnknownBarrier and m.Ledger.Pending == pending)
	local owns, decision = m:SelectWheelSpin()
	assert(owns and decision.Kind == "OBSERVE_REWARD" and pending.Cancelled and m.Ledger.Pending == pending)
	assert(m:WheelSpinDefinition(decision, s.Controller.Generation) == nil)
	s.Config.WHEEL_SPIN_SETTINGS.AUTHORIZED_TEST_ID = "SYNTHETIC_SECOND_ID"
	assert(m:SelectWheelSpin() and m:GetWheelSpinStatus().ChargedAttempts == 1)
end)

for _, control in ipairs({ "PAUSED", "STOPPED" }) do
	test("charged " .. control .. " preserves a sticky cancelled pending operation", function()
		local s = fixture() local pending = s:Charge()
		s.Controller.State = control s.Controller.Generation += 1 s.Manager:Halt(true)
		assert(s.Manager.Ledger.Pending == pending and pending.Cancelled and pending.ReceiptState == "CANCELLED")
		s.Controller.State = "RUNNING" s.Controller.Generation = pending.Generation
		s.Raw.Powerups["Spin Ticket"] = 4 s.Raw.Coins += 200 pending.NativeSettlementCompleted = true
		s:Observe()
		assert(s.Manager.Ledger.Pending == pending and pending.ReceiptState == "CANCELLED" and s.Manager:GetWheelSpinStatus().ChargedAttempts == 1)
	end)
end

for _, index in ipairs({ false, "1", 0, -1, 1.5, 9 }) do
	test("native return must be a current integral pool index: " .. tostring(index), function()
		local s = fixture() local pending = s:Charge()
		assert(not s:Return(index) and pending.Receipt == nil and s.Manager.Ledger.Pending == pending)
	end)
end

test("native return alone establishes only expected descriptor, never grant", function()
	local s = fixture() local pending = s:Charge() assert(s:Return(1))
	assert(pending.ExpectedItem.Type == "Currency" and pending.ExpectedItem.Currency == "Coins")
	assert(not pending.Receipt.GrantObserved and not pending.Receipt.TicketDebitObserved)
	s:Observe() assert(s.Manager.Ledger.Pending == pending and pending.Status == "PENDING")
end)

test("changed current pool cannot reinterpret a native return", function()
	local s = fixture() local pending = s:Charge() s.Pool[1].Item.Amount += 1
	assert(not s:Return(1) and not pending.Receipt)
end)

test("actual ticket debit and currency grant require completed native settlement", function()
	local s = fixture() local pending = s:Charge() assert(s:Return(1))
	s.Raw.Powerups["Spin Ticket"] -= 1 s:Observe()
	assert(pending.Receipt.TicketDebitObserved and not pending.Receipt.GrantObserved)
	s.Raw.Coins += 473 s:Observe()
	assert(pending.Receipt.GrantObserved and s.Manager.Ledger.Pending == pending and pending.Status == "PENDING")
	pending.NativeSettlementCompleted = true pending.SettlementCount = 1 s:Observe()
	assert(s.Manager.Ledger.Pending == nil and pending.Status == "SPIN_CONFIRMED")
	assert(s.Manager.Ledger.WheelSpin.LastResult.Receipt.ObservedGrantAmount == 473)
	assert(s.Manager:GetWheelSpinStatus().ChargedAttempts == 1 and not s.Manager:SelectWheelSpin())
end)

test("queue call and presentation completion with no received grant remain pending", function()
	local s = fixture() local pending = s:Charge() assert(s:Return(1))
	s.Raw.Powerups["Spin Ticket"] -= 1 pending.NativeSettlementCompleted = true pending.SettlementCount = 1 s:Observe()
	assert(s.Manager.Ledger.Pending == pending and pending.Status == "PENDING" and not pending.Receipt.GrantObserved)
	now = pending.Deadline + 1 s:Observe()
	assert(pending.Cancelled and pending.ReceiptState == "PENDING_TIMEOUT" and s.Manager.Ledger.Pending == pending)
	assert(s.Manager:GetWheelSpinStatus().ChargedAttempts == 1)
end)

test("five-ticket prize uses post-debit receipt rather than coalesced net change", function()
	local s = fixture() local pending = s:Charge() assert(s:Return(7))
	s.Raw.Powerups["Spin Ticket"] -= 1 s:Observe()
	s.Raw.Powerups["Spin Ticket"] += 5 pending.NativeSettlementCompleted = true s:Observe()
	assert(pending.Status == "SPIN_CONFIRMED" and pending.Receipt.ObservedGrantAmount == 5 and s.Manager.Ledger.Pending == nil)
end)

test("contradiction cancels receipt permanently and never clears an attempt", function()
	local s = fixture() local pending = s:Charge() assert(s:Return(1))
	s.Raw.Powerups["Spin Ticket"] -= 1 s.Raw.Powerups["Mystery Box"] += 1 s:Observe()
	assert(pending.Cancelled and pending.ReceiptState == "AMBIGUOUS")
	s.Raw.Powerups["Mystery Box"] -= 1 s.Raw.Coins += 200 pending.NativeSettlementCompleted = true s:Observe()
	assert(s.Manager.Ledger.Pending == pending and pending.Status == "PENDING" and s.Manager:GetWheelSpinStatus().ChargedAttempts == 1)
end)

test("settlement is rejected before six-second native animation or without observed debit", function()
	local s = fixture() local pending = s:Charge() assert(s:Return(1))
	assert(not s.Manager:WheelSpinDispatchValid(pending, s.Token, "SETTLE"))
	now += 6 assert(not s.Manager:WheelSpinDispatchValid(pending, s.Token, "SETTLE"))
	s.Raw.Powerups["Spin Ticket"] -= 1
	assert(s.Manager:WheelSpinDispatchValid(pending, s.Token, "SETTLE"))
end)

test("exact runtime transport or button identity substitution blocks settlement", function()
	local s = fixture() local pending = s:Charge() assert(s:Return(1))
	s.Raw.Powerups["Spin Ticket"] -= 1 now += 6
	s.Manager.SpinNativeBridge = { Remote = {}, SpinButton = {} }
	assert(not s.Manager:WheelSpinDispatchValid(pending, s.Token, "SETTLE"))
end)

test("malformed retained before-ticket baseline blocks without throwing or resetting", function()
	local s = fixture() local pending = s:Charge()
	pending.BeforeFacts.Tickets = nil
	local original = copy(shared)
	local ok, manager = pcall(function() return s:Reload() end)
	assert(ok and manager.UnknownBarrier and same(shared, original), "Malformed pending ticket baseline must fail closed as an unknown retained barrier")
end)

for _, outcome in ipairs({ "verified", "uncertain" }) do
	test("actual bounded definition stops after one " .. outcome .. " attempt", function()
		local s = fixture() local owns, decision = s.Manager:SelectWheelSpin() assert(owns)
		local token, stopCount, actionCount, waitCount = s:Lease(), 0, 0, 0
		function s.Controller:Stop()
			stopCount += 1 self.State = "STOPPED" self.Generation += 1 token.Cancelled = true
		end
		function s.Controller.Farming.Mechanics:RewardAction(manager, actualDecision, actualToken)
			actionCount += 1 assert(actualToken == token and manager == s.Manager)
			local pending, reason = manager:PrepareWheelSpin(actualDecision, actualToken) assert(pending, reason)
			s.Pending = pending
			assert(manager:MarkWheelSpinDispatched(pending, actualToken))
			assert(manager.Ledger.WheelSpin.Tests[pending.TestId].Attempts == 1 and s.Inputs == 0)
			s.Inputs, s.Commands = 1, 1 -- Synthetic native activation/Invoke only, after charge.
			assert(s:Return(1))
			return true, "One synthetic charged activation"
		end
		function s.Controller.Farming.Mechanics:ReleaseWheelSpinBridge(_, pending)
			return pending.Cancelled == true or pending.Status == "SPIN_CONFIRMED"
		end
		local original = task.wait
		task.wait = function(seconds)
			assert(seconds == 0.1) now += seconds waitCount += 1
			if outcome == "verified" and waitCount == 1 then
				s.Raw.Powerups["Spin Ticket"] -= 1 s:Observe()
				s.Raw.Coins += 200 s.Pending.NativeSettlementCompleted, s.Pending.SettlementCount = true, 1 s:Observe()
			end
		end
		local definition = s.Manager:WheelSpinDefinition(decision, s.Controller.Generation)
		local ok, result = pcall(definition.Execute, token)
		task.wait = original
		assert(ok, result)
		assert(stopCount == 1 and actionCount == 1 and s.Inputs == 1 and s.Commands == 1)
		assert(s.Controller.State == "STOPPED" and s.Manager:GetWheelSpinStatus().ChargedAttempts == 1)
		if outcome == "verified" then
			assert(not result.Pending and s.Manager.Ledger.Pending == nil and s.Pending.Status == "SPIN_CONFIRMED")
		else
			assert(result.Pending and s.Manager.Ledger.Pending == s.Pending and s.Pending.Cancelled)
			assert(s.Pending.ReceiptState == "PENDING_TIMEOUT" and s.Manager:AttributionBlocked())
		end
		definition.Execute(token)
		assert(actionCount == 1 and stopCount == 1, "Stopped/cancelled definition cannot activate a second spin")
	end)
end

print("[OC WHEEL MANAGER SYNTHETIC] " .. checks .. " actual-source helper/lifecycle checks passed; no live gameplay.")

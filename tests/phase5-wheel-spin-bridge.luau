-- Synthetic public-native-button bridge cases only. No real account, input or RPC.
local Mechanics = requireOC("GameMechanics")
local originalTask, originalClock = table.clone(task), os.clock
local simulatedNow, jobs, assertions = 0, {}, 0
os.clock = function() return simulatedNow end
task.defer = function(callback)
	local thread = coroutine.create(callback)
	table.insert(jobs, { Thread = thread, At = simulatedNow })
	return thread
end
task.spawn = task.defer
task.wait = function(seconds) return coroutine.yield(seconds or 0.01) end
task.delay = function(seconds, callback)
	local thread = coroutine.create(callback)
	table.insert(jobs, { Thread = thread, At = simulatedNow + seconds })
	return thread
end
local function pump(untilAt)
	local rounds = 0
	while #jobs > 0 do
		table.sort(jobs, function(a, b) return a.At < b.At end)
		local job = table.remove(jobs, 1)
		if job.At > untilAt then table.insert(jobs, job) break end
		simulatedNow = job.At
		local ok, waitFor = coroutine.resume(job.Thread)
		assert(ok, waitFor)
		if coroutine.status(job.Thread) ~= "dead" then
			table.insert(jobs, { Thread = job.Thread, At = simulatedNow + (type(waitFor) == "number" and math.max(0.001, waitFor) or 0.01) })
		end
		rounds += 1 assert(rounds < 5000, "Synthetic bridge fixture must remain bounded")
	end
	simulatedNow = untilAt
end
local function fixture(options)
	options = options or {}
	simulatedNow = 0 table.clear(jobs)
	local scene = { Commands = {}, Attributes = {}, Unresolved = {}, Attempts = 0, Count = 4 }
	local function signal()
		local listeners = {}
		return { Connect = function(_, callback)
			listeners[callback] = true
			return { Disconnect = function() listeners[callback] = nil end }
		end, Fire = function()
			for callback in pairs(listeners) do task.defer(callback) end
		end }
	end
	local spinSignal, skipSignal = signal(), signal()
	local spin = { Visible = true, GetPropertyChangedSignal = function() return spinSignal end }
	local skip = { Visible = false, GetPropertyChangedSignal = function() return skipSignal end }
	local button = { Parent = spin, Active = true, Values = { Pressed = false, ButtonActivated = false } }
	local armed = false
	local function idle()
		spin.Visible, skip.Visible = true, false
		spinSignal:Fire() skipSignal:Fire()
	end
	local remote = {}
	remote.InvokeServer = function(receiver, command, ...)
		assert(receiver == remote and command == "WheelSpin" and select("#", ...) == 0)
		table.insert(scene.Commands, command)
		if options.CancelDuringRPC then scene.Cancelled = true end
		if options.ResponseDelay then task.wait(options.ResponseDelay) end
		if options.RPCError then error("Synthetic uncertain RPC error") end
		if options.Debit ~= false then scene.Count -= 1 end
		return options.Result == nil and 1 or options.Result, "UNCHANGED_NATIVE_EXTRA_RESULT"
	end
	remote.FireServer = function(receiver, command, ...)
		assert(receiver == remote and command == "ClaimWheelSpinQueue" and select("#", ...) == 0)
		table.insert(scene.Commands, command)
		if options.QueueError then error("Synthetic uncertain queue error") end
		return "UNCHANGED_NATIVE_QUEUE_RESULT"
	end
	scene.OriginalInvoke, scene.OriginalFire = remote.InvokeServer, remote.FireServer
	local function nativeCallback()
		scene.NativeCallbacks = (scene.NativeCallbacks or 0) + 1
		if scene.Count < 1 then scene.PurchaseFallback = true return end
		spin.Visible, skip.Visible = false, true
		spinSignal:Fire() skipSignal:Fire()
		local index, extra = remote:InvokeServer("WheelSpin")
		scene.NativeResult, scene.NativeExtra = index, extra
		if index ~= nil then
			task.wait(options.SkipEarly and 1 or 6)
			if options.CancelDuringAnimation then scene.Cancelled = true end
			if options.ReplaceFire then remote.FireServer = options.ReplaceFire end
			scene.QueueResult = remote:FireServer("ClaimWheelSpinQueue")
		end
		idle() armed = false
	end
	function button:GetAttribute(name) return self.Values[name] end
	function button:SetAttribute(name, value)
		if self.Values[name] == value then return end
		self.Values[name] = value table.insert(scene.Attributes, name .. "=" .. tostring(value))
		-- Reads happen when deferred listeners execute, matching the documented
		-- native handler instead of a synchronous attribute-change convenience.
		task.defer(function()
			if name == "ButtonActivated" then armed = button.Values.ButtonActivated return end
			if name ~= "Pressed" then return end
			local pressed = button.Values.Pressed
			if not armed and pressed then armed = true return end
			if armed and not pressed then nativeCallback() end
		end)
	end
	local gui = { Spin = spin, Skip = skip, SpinButton = button, SpinControl = button }
	local player = { UserId = 101 }
	local token = { CheckCancelled = function() return scene.Cancelled == true end }
	local reader = { Player = player, _dependency = function(_, name) if name == "Remote" then return remote end end }
	local controller = { State = "RUNNING", Generation = 1, Scheduler = { Active = { Definition = { Owner = "REWARDS", Generation = 1 }, Token = token } } }
	local context = { Fresh = true, AccountId = 101, Access = true, IsTradingPlaza = false, TicketCount = 4, UIIdle = true,
		GUI = gui, NativeRefs = { Remote = remote }, Pool = { { Item = { Type = "Currency", Currency = "Coins", Amount = 25 } } } }
	local manager = { Controller = controller, Ledger = {}, SpinPreparationContext = context }
	controller.Rewards = manager
	function manager:WheelSpinAuthorization() return options.Authorization ~= false end
	function manager:PrepareWheelSpin()
		if scene.Attempts > 0 then return nil, "Consumed" end
		local pending = { Kind = "WHEEL_SPIN", Generation = 1, BeforeTickets = 4, Deadline = 20 }
		self.Ledger.Pending = pending scene.Pending = pending
		return pending
	end
	function manager:MarkWheelSpinDispatched(pending)
		scene.Attempts += 1 pending.Attempted = true return true
	end
	function manager:AbortPreparation(pending, reason)
		if not pending.Attempted then self.Ledger.Pending = nil end
		return true
	end
	function manager:WheelSpinDispatchValid(pending, _, stage)
		if options.CancelAfterArm and button.Values.Pressed then scene.Cancelled = true end
		if options.StockLostAfterArm and button.Values.Pressed then scene.Count = 0 end
		if options.RebindAfterArm and button.Values.Pressed then context.GUI = { Spin = spin, Skip = skip, SpinButton = {}, SpinControl = button } end
		if options.RebindControlAfterArm and button.Values.Pressed then context.GUI = { Spin = spin, Skip = skip, SpinButton = button, SpinControl = {} } end
		if scene.Cancelled or pending.Cancelled then return false, "Synthetic cancellation" end
		context.TicketCount, context.UIIdle = scene.Count, spin.Visible and not skip.Visible and not button.Values.Pressed
		if stage == "START" and scene.Count ~= 4 then return false, "Synthetic stock changed" end
		if stage == "SETTLE" and scene.Count ~= 3 then return false, "Synthetic distinct debit missing" end
		return true, nil, context
	end
	function manager:AcceptWheelSpinReturn(_, index)
		return type(index) == "number" and index == 1, "Synthetic invalid native pool index"
	end
	function manager:UnresolveWheelSpin(pending, state, reason)
		pending.Cancelled, pending.Status = true, "PENDING"
		table.insert(scene.Unresolved, { State = state, Reason = reason })
	end
	local mechanics = Mechanics.new({}, reader, {}, player)
	mechanics.LocalFeatureController = controller
	scene.Mechanics, scene.Manager, scene.Remote, scene.GUI, scene.Token = mechanics, manager, remote, gui, token
	function scene:Run()
		task.defer(function() self.Started, self.Reason = mechanics:SpinWheelOnce(manager, { Kind = "WHEEL_SPIN" }, token) end)
		pump(0.1)
	end
	return scene
end
local function audit(name, callback)
	callback() assertions += 1
	print("[OC SPIN BRIDGE SYNTHETIC] " .. name .. " passed")
end

audit("Deferred public press yields once and releases exactly one native spin and queue", function()
	local scene = fixture() scene:Run() pump(7)
	assert(scene.Started and scene.Attempts == 1 and scene.NativeCallbacks == 1)
	assert(#scene.Commands == 2 and scene.Commands[1] == "WheelSpin" and scene.Commands[2] == "ClaimWheelSpinQueue")
	assert(scene.NativeResult == 1 and scene.NativeExtra == "UNCHANGED_NATIVE_EXTRA_RESULT")
	assert(scene.QueueResult == "UNCHANGED_NATIVE_QUEUE_RESULT")
	assert(scene.Pending.TransportCount == 1 and scene.Pending.SettlementCount == 1 and scene.Pending.NativeSettlementCompleted)
	assert(scene.Remote.InvokeServer == scene.OriginalInvoke and scene.Remote.FireServer == scene.OriginalFire and not scene.Manager.SpinNativeBridge)
	assert(#scene.Attributes == 2 and not scene.PurchaseFallback)
end)
audit("Wrong scheduler ownership blocks preparation and every public attribute", function()
	local scene = fixture() scene.Manager.Controller.Scheduler.Active.Definition.Owner = "FARMING" scene:Run() pump(7)
	assert(not scene.Started and scene.Attempts == 0 and #scene.Attributes == 0 and #scene.Commands == 0)
end)
audit("Wrong account blocks charged allowance and native button release", function()
	local scene = fixture() scene.Manager.SpinPreparationContext.AccountId = 202 scene:Run() pump(7)
	assert(not scene.Started and scene.Attempts == 0 and #scene.Commands == 0)
end)
audit("Cancellation after arming retains press without synthetic release or fallback", function()
	local scene = fixture({ CancelAfterArm = true }) scene:Run() pump(7)
	assert(not scene.Started and scene.Attempts == 1 and #scene.Commands == 0)
	assert(#scene.Attributes == 1 and scene.GUI.SpinButton:GetAttribute("Pressed") == true)
	assert(scene.Pending.InputCleanupState == "ARMED_PRESS_RETAINED_NO_RELEASE" and not scene.PurchaseFallback)
end)
audit("Stock loss during the one yield blocks release and purchase fallback", function()
	local scene = fixture({ StockLostAfterArm = true }) scene:Run() pump(7)
	assert(not scene.Started and #scene.Commands == 0 and #scene.Attributes == 1 and not scene.PurchaseFallback)
end)
audit("Exact button identity changes during yield block release", function()
	local scene = fixture({ RebindAfterArm = true }) scene:Run() pump(7)
	assert(not scene.Started and #scene.Commands == 0 and #scene.Attributes == 1)
end)
audit("Exact native underlying control replacement during yield blocks release", function()
	local scene = fixture({ RebindControlAfterArm = true }) scene:Run() pump(7)
	assert(not scene.Started and #scene.Commands == 0 and #scene.Attributes == 1)
	assert(scene.GUI.SpinButton:GetAttribute("Pressed") == true and not scene.PurchaseFallback)
end)
audit("Malformed native index suppresses animation and queue without inventing a result", function()
	local scene = fixture({ Result = "bad" }) scene:Run() pump(7)
	assert(scene.NativeResult == nil and #scene.Commands == 1 and scene.Pending.Status == "PENDING")
	assert(scene.Pending.SettlementCount == nil and scene.Remote.InvokeServer == scene.OriginalInvoke)
end)
audit("RPC exception retains consumed attempt and never retries", function()
	local scene = fixture({ RPCError = true }) scene:Run() pump(7)
	assert(#scene.Commands == 1 and scene.Attempts == 1 and scene.Pending.Status == "PENDING" and not scene.Pending.InvocationOk)
	assert(not scene.Mechanics:SpinWheelOnce(scene.Manager, { Kind = "WHEEL_SPIN" }, scene.Token))
end)
audit("Cancellation during yielding RPC suppresses native animation and settlement", function()
	local scene = fixture({ CancelDuringRPC = true, ResponseDelay = 2 }) scene:Run() pump(7)
	assert(#scene.Commands == 1 and scene.NativeResult == nil and scene.Pending.Status == "PENDING" and scene.Remote.FireServer == scene.OriginalFire)
end)
audit("Early native skip never authorizes an alternate queue request", function()
	local scene = fixture({ SkipEarly = true }) scene:Run() pump(7)
	assert(#scene.Commands == 1 and scene.Pending.NativeSettlementSuppressed and scene.Pending.Status == "PENDING")
end)
audit("Native queue waits for distinct observed ticket debit", function()
	local scene = fixture({ Debit = false }) scene:Run() pump(7)
	assert(#scene.Commands == 1 and scene.Pending.NativeSettlementSuppressed and scene.Pending.Status == "PENDING")
end)
audit("Cancellation during native animation blocks queue and restores only owned wrappers", function()
	local scene = fixture({ CancelDuringAnimation = true }) scene:Run() pump(7)
	assert(#scene.Commands == 1 and scene.Pending.NativeSettlementSuppressed)
	assert(scene.Remote.FireServer == scene.OriginalFire and scene.Remote.InvokeServer == scene.OriginalInvoke)
end)
audit("Queue transport failure is retained and never sent a second time", function()
	local scene = fixture({ QueueError = true }) scene:Run() pump(7)
	assert(#scene.Commands == 2 and scene.Pending.SettlementCount == 1 and scene.Pending.Status == "PENDING")
	assert(not scene.Pending.NativeSettlementInvocationOk)
end)
audit("Late RPC cannot regain queue authority after bounded deadline", function()
	local scene = fixture({ ResponseDelay = 25 }) scene:Run() pump(26)
	assert(#scene.Commands == 1 and scene.NativeResult == nil and scene.Pending.Status == "PENDING")
end)
audit("Cleanup never overwrites another owner's replacement public method", function()
	local scene = fixture() scene:Run()
	local replacement = function() return "EXTERNAL_REPLACEMENT" end
	scene.Remote.FireServer = replacement
	pump(7)
	-- Replacement ownership is preserved even if external code handles a call;
	-- OC's recorded original native queue count remains zero.
	assert(scene.Remote.FireServer == replacement and scene.Pending.SettlementCount == nil)
	assert(scene.Remote.InvokeServer ~= scene.OriginalInvoke and scene.Manager.SpinNativeBridge ~= nil)
end)
audit("No native callback causes no direct RPC fallback or repeat button release", function()
	local scene = fixture()
	scene.GUI.SpinButton.SetAttribute = function(self, name, value) self.Values[name] = value table.insert(scene.Attributes, name .. "=" .. tostring(value)) end
	scene:Run() pump(21)
	assert(#scene.Commands == 0 and #scene.Attributes == 2 and scene.Attempts == 1)
end)

for key in pairs(task) do task[key] = nil end
for key, value in pairs(originalTask) do task[key] = value end
os.clock = originalClock
print("[OC SPIN BRIDGE SYNTHETIC] " .. assertions .. " native-button bridge contracts passed; no live actions")

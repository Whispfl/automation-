do
-- Synthetic adapter checks; no input is sent and no idle-prevention claim is tested.
local before = tests
local Manager = requireOC("AntiAFKManager")
local previousClock = os.clock
local now = 100
os.clock = function() return now end
local function fixture()
	local value = { Sent = 0, Releases = 0, CapabilityCalls = 0, Logs = {}, Allowed = true, Held = false,
		Controller = { State = "RUNNING", Generation = 1, Config = { ANTIAFK_SETTINGS = {
			ENABLE_ANTI_AFK = true, METHOD = "VIRTUAL_INPUT_SCROLL_LOCK", INTERVAL_SECONDS = 120 } }, Scheduler = {} } }
	local mechanics = {}
	function mechanics:AntiAFKCapability(method)
		value.CapabilityCalls += 1
		return { Available = value.Available ~= false, Method = method, Reason = "Synthetic unsupported runtime" }
	end
	function mechanics:AntiAFKGuard()
		if value.GuardError then error("Synthetic guard failure") end
		return value.Allowed, value.Suppression
	end
	function mechanics:AntiAFKPulse(_, token)
		value.Held = true -- Synthetic adapter ownership recorded before a risky input attempt.
		if value.OnPulse then value.OnPulse(token) end
		if value.InputSuppressed then return false, "SUPPRESSED: Synthetic pointer state changed" end
		if value.InputError then error("Synthetic runtime permission failure") end
		if value.InputRejected then return false, "Synthetic input rejected" end
		value.Sent += 1
		return true
	end
	function mechanics:ReleaseAntiAFKInput()
		value.Releases += 1
		if value.ReleaseError then error("Synthetic cleanup failure") end
		value.Held = false
		return true
	end
	value.Controller.Farming = { Mechanics = mechanics }
	function value.Controller:Log(kind, message) table.insert(value.Logs, { Kind = kind, Message = message }) end
	value.Manager = Manager.new(value.Controller)
	value.Token = { Cancelled = false, CheckCancelled = function(self) return self.Cancelled end }
	function value:Due()
		self.Manager:Observe()
		now = self.Manager.NextDueAt
		return self.Manager:Select()
	end
	function value:Run()
		local definition = self.Manager:Definition({ Kind = "ANTI_AFK" }, self.Controller.Generation)
		self.Controller.Scheduler.Active = { Definition = definition }
		local result = definition.Execute(self.Token)
		self.Controller.Scheduler.Active = nil
		return result
	end
	return value
end

test("Anti-AFK disabled avoids capability probes and inputs", function()
	local f = fixture()
	f.Controller.Config.ANTIAFK_SETTINGS.ENABLE_ANTI_AFK = false
	f.Manager:Observe()
	now += 1000
	assert(not f.Manager:Select() and f.CapabilityCalls == 0 and f.Sent == 0)
	f.Manager:Destroy()
end)

test("Anti-AFK is due only after interval and never pulses during selection", function()
	local f = fixture()
	f.Manager:Observe()
	local due = f.Manager.NextDueAt
	now = due - .01
	assert(not f.Manager:Select() and f.Sent == 0)
	now = due
	assert(f.Manager:Select() and f.Sent == 0)
	local result = f:Run()
	assert(result.Status == "INPUT_SENT_UNVERIFIED" and result.IdlePrevention == "OWNER_LONG_DURATION_PENDING")
	assert(result.Method == "VIRTUAL_INPUT_SCROLL_LOCK" and result.NativeActivity == "INPUT_HANDLER_INSPECTED_RUNTIME_PENDING")
	assert(f.Sent == 1 and f.Manager.SentPulses == 1 and f.Releases == 1 and not f.Manager:Select())
	assert(not f.Held)
	f.Manager:Destroy()
end)

test("Anti-AFK requires scheduler ownership and rechecks live guards", function()
	local f = fixture()
	assert(f:Due())
	f.Controller.Scheduler.Active = { Definition = { Owner = "PETS" } }
	assert(not f.Manager:Select() and f.Sent == 0)
	f.Controller.Scheduler.Active = nil
	f.Allowed, f.Suppression = false, "Sensitive UI opened"
	assert(f:Run().Status == "SUPPRESSED" and f.Sent == 0)
	f.Allowed = true
	assert(f.Manager:Select())
	f.Manager:Destroy()
end)

test("Anti-AFK suppresses every adapter conflict without consuming interval", function()
	for _, reason in ipairs({ "Typing", "Sensitive UI", "Travel", "Hatching", "Gift opening", "Egg location lease", "Mouse locked", "Manual held input",
		"ScrollLock rebound", "AFK report pets pending", "AFKReveal active" }) do
		local f = fixture()
		assert(f:Due())
		local due = f.Manager.NextDueAt
		f.Allowed, f.Suppression = false, reason
		assert(not f.Manager:Select() and f.Sent == 0 and f.Manager.NextDueAt == due)
		assert(f.Manager:GetStatus().Suppression == reason)
		f.Manager:Destroy()
	end
end)

test("Anti-AFK unavailable runtime reports once and stays fail closed", function()
	local f = fixture()
	f.Available = false
	assert(not f:Due() and f.Manager.Fault and #f.Logs == 1)
	for _ = 1, 4 do now += 120 assert(not f.Manager:Select()) end
	assert(#f.Logs == 1 and f.Sent == 0 and f.CapabilityCalls == 1)
	f.Manager:Destroy()
end)

test("Anti-AFK rejects missing adapter and uninspected key methods", function()
	for _, mutation in ipairs({ "MISSING", "MISSING_RELEASE", "SPACE", "R", "VIRTUAL_INPUT_MOUSE_MOVE" }) do
		local f = fixture()
		if mutation == "MISSING" then f.Controller.Farming.Mechanics.AntiAFKPulse = nil
		elseif mutation == "MISSING_RELEASE" then f.Controller.Farming.Mechanics.ReleaseAntiAFKInput = nil
		else f.Controller.Config.ANTIAFK_SETTINGS.METHOD = mutation end
		assert(not f:Due() and f.Sent == 0 and #f.Logs == 1)
		f.Manager:Destroy()
	end
end)

test("Anti-AFK guard exceptions fail closed once", function()
	local f = fixture()
	f.GuardError = true
	assert(not f:Due() and f.Sent == 0 and #f.Logs == 1)
	assert(not f.Manager:Select() and #f.Logs == 1)
	f.Manager:Destroy()
end)

test("Anti-AFK input errors retain attempts and never retry automatically", function()
	for _, rejection in ipairs({ "THROW", "REJECT" }) do
		local f = fixture()
		assert(f:Due())
		f.InputError, f.InputRejected = rejection == "THROW", rejection == "REJECT"
		local result = f:Run()
		assert(result.Status == "INPUT_FAILED" and f.Sent == 0 and f.Manager.AttemptedPulses == 1)
		assert(f.Releases == 1 and not f.Held and #f.Logs == 1)
		now += 120
		assert(not f.Manager:Select() and f.Manager.AttemptedPulses == 1)
		f.Manager:Destroy()
	end
end)

test("Anti-AFK cancellation and stale generations dispatch nothing", function()
	local f = fixture()
	assert(f:Due())
	local definition = f.Manager:Definition({}, f.Controller.Generation)
	f.Controller.Generation += 1
	assert(not definition.CanRun() and definition.Execute(f.Token).InputSent == false and f.Sent == 0)
	f.Token.Cancelled = true
	assert(f:Run().InputSent == false and f.Sent == 0)
	f.Manager:Destroy()
end)

test("Anti-AFK temporary dispatch suppression is paced and recoverable", function()
	local f = fixture()
	assert(f:Due())
	f.InputSuppressed = true
	local at = now
	local result = f:Run()
	assert(result.Status == "SUPPRESSED" and not result.InputSent and not f.Manager.Fault and #f.Logs == 0)
	assert(f.Manager.NextDueAt == at + 5 and f.Manager.AttemptedPulses == 1 and f.Sent == 0)
	now = at + 4
	assert(not f.Manager:Select())
	now = at + 5
	f.InputSuppressed = false
	assert(f.Manager:Select() and f:Run().InputSent and f.Manager.AttemptedPulses == 2 and f.Sent == 1)
	f.Manager:Destroy()
end)

test("Anti-AFK transient cancellation never rearms stopped input", function()
	local f = fixture()
	assert(f:Due())
	f.InputSuppressed = true
	f.OnPulse = function(token)
		token.Cancelled = true
		f.Controller.State = "PAUSED"
		f.Manager:Halt("Paused")
	end
	assert(f:Run().Status == "SUPPRESSED" and not f.Manager.Fault and f.Sent == 0)
	assert(f.Manager.NextDueAt == nil and not f.Manager:Select())
	f.Manager:Destroy()
end)

test("Anti-AFK Pause Resume Stop and repeated load release synchronously", function()
	local f = fixture()
	assert(f:Due())
	f.Controller.State = "PAUSED"
	f.Manager:Halt("Paused")
	assert(f.Releases == 1 and not f.Manager:Select() and f.Sent == 0)
	now += 500
	f.Controller.State, f.Controller.Generation = "RUNNING", 2
	f.Manager:Resume()
	assert(f.Manager.NextDueAt == now + 120 and not f.Manager:Select())
	f.Controller.State = "STOPPED"
	f.Manager:Halt("Stopped")
	assert(f.Releases == 2 and f.Manager.NextDueAt == nil)
	assert(not f.Held)
	f.Manager:Destroy()
	local releases = f.Releases
	f.Manager:Destroy()
	assert(f.Releases == releases)
	f.Controller.State = "RUNNING"
	local replacement = Manager.new(f.Controller)
	replacement:Resume()
	assert(not f.Manager:Select() and replacement.NextDueAt == now + 120 and not replacement:Select())
	assert(not f.Manager:Resume())
	replacement:Destroy()
end)

test("Anti-AFK cancellation inside adapter retains sent evidence and cleans up", function()
	local f = fixture()
	assert(f:Due())
	f.OnPulse = function(token)
		token.Cancelled = true
		f.Controller.State = "PAUSED"
		f.Manager:Halt("Paused during dispatch")
	end
	local result = f:Run()
	assert(result.InputSent and result.CancelledAfterDispatch and f.Manager.SentPulses == 1)
	assert(f.Releases == 2 and f.Manager.NextDueAt == nil)
	f.Manager:Destroy()
end)

test("Anti-AFK cleanup failure is visible and blocks resumed inputs", function()
	local f = fixture()
	assert(f:Due())
	f.Held = true -- A previously issued key-down may still be outstanding.
	f.ReleaseError = true
	f.Manager:Halt("Stopped")
	assert(f.Manager.Fault and f.Held and #f.Logs == 1)
	now += 120
	assert(not f.Manager:Select() and f.Sent == 0)
	f.Manager:Destroy()
	assert(#f.Logs == 1)
end)

test("Anti-AFK Pause and Destroy release a tracked key before scheduler teardown", function()
	local f = fixture()
	assert(f:Due())
	f.Held = true
	f.Controller.State = "PAUSED"
	f.Manager:Halt("Paused")
	assert(not f.Held and f.Releases == 1 and not f.Manager:Select())
	f.Held = true
	f.Manager:Destroy()
	assert(not f.Held and f.Releases == 2)
	local releases = f.Releases
	f.Manager:Destroy()
	assert(f.Releases == releases)
end)

os.clock = previousClock
print("[OC TEST] Anti-AFK synthetic manager checks: " .. tostring(tests - before))
end

do
-- Exercise the real adapter against isolated fake services. This never calls Roblox.
local before = tests
local Mechanics = requireOC("GameMechanics")
local function adapterFixture()
	local old = { Input = services.UserInputService, Gui = services.GuiService, Virtual = services.VirtualInputManager,
		KeyCode = Enum.KeyCode, MouseBehavior = Enum.MouseBehavior, Camera = workspace.CurrentCamera }
	local f = { Calls = {}, Raw = { Settings = { Action = "E", AutoHatch = "R" } }, Report = { Pets = {} }, GiftCount = 0,
		AFK = { Visible = false }, Reveal = { Visible = false }, Keys = {}, Buttons = {} }
	Enum.KeyCode, Enum.MouseBehavior = { ScrollLock = "fixture-scroll-lock" }, { Default = "fixture-default" }
	workspace.CurrentCamera = { ViewportSize = { X = 800, Y = 600 } }
	services.UserInputService = { MouseBehavior = Enum.MouseBehavior.Default,
		GetMouseLocation = function() return { X = 100, Y = 100 } end,
		GetKeysPressed = function() return f.Keys end, GetMouseButtonsPressed = function() return f.Buttons end,
		GetFocusedTextBox = function() return f.TextBox end }
	services.GuiService = { MenuIsOpen = false }
	local virtual = {}
	function virtual:SendKeyEvent(down, key, repeated, target)
		table.insert(f.Calls, { Down = down, Key = key, Repeated = repeated, Target = target })
		assert(key == Enum.KeyCode.ScrollLock and repeated == false and target == game)
		if f.OnInput then f.OnInput(down) end
		if down and f.DownError or not down and f.UpError then error("Synthetic key API rejection") end
	end
	services.VirtualInputManager = virtual
	local screen = { FindFirstChild = function(_, name) return name == "AFK" and f.AFK or name == "AFKReveal" and f.Reveal or nil end }
	local gui = { FindFirstChild = function(_, name) return name == "ScreenGui" and screen or nil end }
	local auto = { IsA = function(_, kind) return kind == "BindableFunction" end,
		Invoke = function() if f.OnGuard then f.OnGuard() end return f.AutoHatch end }
	local client = { FindFirstChild = function(_, name) return name == "GetAutoHatchStatus" and auto or nil end }
	local scripts = { FindFirstChild = function(_, name) return name == "ClientScript" and client or nil end }
	local player = { FindFirstChild = function(_, name) return name == "PlayerGui" and gui or name == "PlayerScripts" and scripts or nil end }
	local reader = { GetLiveProfile = function() return f.Raw end }
	function reader:_dependency(name)
		if name == "AFKReport" then return { Get = function() return f.Report end }
		elseif name == "PhysicalItem" then return { GetActiveObjects = function(_, kind) assert(kind == "Gift") return f.GiftCount end,
			GetActiveGifts = function() error("Loaded gift enumeration cannot replace the total gift guard") end }
		elseif name == "HatchPresentation" then return { IsHatching = function() return f.Hatching == true end } end
	end
	local cfg = { ANTIAFK_SETTINGS = { ENABLE_ANTI_AFK = true, METHOD = "VIRTUAL_INPUT_SCROLL_LOCK" } }
	f.Mechanics = Mechanics.new(cfg, reader, {}, player)
	f.Mechanics.Guard = function() return true, nil, {} end
	f.Controller = { State = "RUNNING", Generation = 1, Scheduler = { Active = { Definition = { Owner = "ANTI_AFK", Generation = 1 } } },
		EggTravel = { OwnsLocation = function() return f.Travel == true end }, Pets = { Hatch = {} },
		Rewards = { GetStatus = function() return { Pending = f.RewardPending } end } }
	f.Manager = { Controller = f.Controller }
	f.Controller.AntiAFK, f.Mechanics.LocalFeatureController = f.Manager, f.Controller
	f.Token = { CheckCancelled = function() return f.Cancelled == true end }
	function f:Pulse() return self.Mechanics:AntiAFKPulse(self.Manager, self.Token) end
	function f:Close()
		services.UserInputService, services.GuiService, services.VirtualInputManager = old.Input, old.Gui, old.Virtual
		Enum.KeyCode, Enum.MouseBehavior, workspace.CurrentCamera = old.KeyCode, old.MouseBehavior, old.Camera
	end
	return f
end

test("Actual anti-AFK adapter probes only the explicit ScrollLock capability", function()
	local f = adapterFixture()
	assert(f.Mechanics:AntiAFKCapability("VIRTUAL_INPUT_SCROLL_LOCK").Status == "API_PRESENT_PERMISSION_UNTESTED")
	assert(#f.Calls == 0 and not f.Mechanics:AntiAFKCapability("VIRTUAL_INPUT_MOUSE_MOVE").Available)
	services.VirtualInputManager = {}
	assert(not f.Mechanics:AntiAFKCapability("VIRTUAL_INPUT_SCROLL_LOCK").Available)
	services.VirtualInputManager = { SendKeyEvent = function() error("Capability probing must not send input") end }
	Enum.KeyCode.ScrollLock = nil
	assert(not f.Mechanics:AntiAFKCapability("VIRTUAL_INPUT_SCROLL_LOCK").Available and #f.Calls == 0)
	f:Close()
end)

test("Actual anti-AFK guard checks fresh rebound keys AFK state and total unloaded gifts", function()
	local f = adapterFixture()
	assert(f.Mechanics:AntiAFKGuard(f.Manager))
	for _, value in ipairs({ "ScrollLock", "Enum.KeyCode.ScrollLock" }) do
		f.Raw.Settings = { ArbitraryNativeAction = value }
		assert(not f.Mechanics:AntiAFKGuard(f.Manager))
	end
	f.Raw.Settings = {}
	f.Report = { Pets = { { Name = "Synthetic pending result" } } }
	assert(not f.Mechanics:AntiAFKGuard(f.Manager))
	f.Report = { Pets = {} }
	for _, presentation in ipairs({ f.AFK, f.Reveal }) do
		presentation.Visible = true assert(not f.Mechanics:AntiAFKGuard(f.Manager)) presentation.Visible = false
	end
	f.GiftCount = 1 -- No loaded gift list exists; the total registry still blocks.
	assert(not f.Mechanics:AntiAFKGuard(f.Manager))
	f.GiftCount = nil assert(not f.Mechanics:AntiAFKGuard(f.Manager))
	f.GiftCount = 0 assert(f.Mechanics:AntiAFKGuard(f.Manager) and #f.Calls == 0)
	f:Close()
end)

test("Actual anti-AFK guard respects hatch typing gameplay and real held inputs", function()
	local f = adapterFixture()
	for _, field in ipairs({ "TextBox", "Hatching", "AutoHatch", "Travel", "RewardPending" }) do
		f[field] = field == "AutoHatch" and "Synthetic Egg" or true
		assert(not f.Mechanics:AntiAFKGuard(f.Manager)) f[field] = nil
	end
	f.Controller.Pets.Hatch.Location = {} assert(not f.Mechanics:AntiAFKGuard(f.Manager)) f.Controller.Pets.Hatch.Location = nil
	f.Controller.Pets.PendingEquip = {} assert(not f.Mechanics:AntiAFKGuard(f.Manager)) f.Controller.Pets.PendingEquip = nil
	f.Keys = { {} } assert(not f.Mechanics:AntiAFKGuard(f.Manager)) f.Keys = {}
	f.Buttons = { {} } assert(not f.Mechanics:AntiAFKGuard(f.Manager)) f.Buttons = {}
	services.GuiService.MenuIsOpen = true assert(not f.Mechanics:AntiAFKGuard(f.Manager))
	assert(#f.Calls == 0) f:Close()
end)

test("Actual anti-AFK pulse requires a current manager owner and generation", function()
	local f = adapterFixture()
	f.Controller.Scheduler.Active = nil assert(not f:Pulse())
	f.Controller.Scheduler.Active = { Definition = { Owner = "PETS", Generation = 1 } } assert(not f:Pulse())
	f.Controller.Scheduler.Active.Definition = { Owner = "ANTI_AFK", Generation = 0 } assert(not f:Pulse())
	f.Controller.Scheduler.Active.Definition.Generation = 1 f.Controller.AntiAFK = {} assert(not f:Pulse())
	assert(#f.Calls == 0 and f.Mechanics.AntiAFKHeldInput == nil) f:Close()
end)

test("Actual anti-AFK pulse pairs ScrollLock down and synchronous up without held state", function()
	local f = adapterFixture()
	local sent, reason = f:Pulse()
	assert(sent and reason:find("owner", 1, true) and #f.Calls == 2 and f.Calls[1].Down and not f.Calls[2].Down)
	assert(f.Mechanics.AntiAFKHeldInput == nil)
	assert(f.Mechanics:ReleaseAntiAFKInput() and #f.Calls == 2) -- Idempotent cleanup has no extra key event.
	f:Close()
end)

test("Actual anti-AFK API down failure still attempts exact synchronous release", function()
	local f = adapterFixture() f.DownError = true
	assert(not f:Pulse() and #f.Calls == 2 and f.Calls[1].Down and not f.Calls[2].Down)
	assert(f.Mechanics.AntiAFKHeldInput == nil) f:Close()
end)

test("Actual anti-AFK up failure retains uncertainty and blocks another down", function()
	local f = adapterFixture() f.UpError = true
	assert(not f:Pulse() and #f.Calls == 2 and f.Mechanics.AntiAFKHeldInput ~= nil)
	assert(not f:Pulse() and #f.Calls == 2)
	assert(not f.Mechanics:ReleaseAntiAFKInput() and #f.Calls == 3 and f.Mechanics.AntiAFKHeldInput ~= nil)
	f.UpError = false
	assert(f.Mechanics:ReleaseAntiAFKInput() and #f.Calls == 4 and f.Mechanics.AntiAFKHeldInput == nil)
	assert(f.Mechanics:ReleaseAntiAFKInput() and #f.Calls == 4) f:Close()
end)

test("Actual anti-AFK pre-down cancellation emits neither down nor spurious up", function()
	local f = adapterFixture()
	f.OnGuard = function() f.Cancelled = true end
	local sent, reason = f:Pulse()
	assert(not sent and reason:sub(1, 11) == "SUPPRESSED:" and #f.Calls == 0 and f.Mechanics.AntiAFKHeldInput == nil)
	f:Close()
end)

test("Actual anti-AFK repeats the positive lease check after potentially yielding guards", function()
	for _, mutation in ipairs({ "GENERATION", "OWNER", "MANAGER" }) do
		local f = adapterFixture()
		f.OnGuard = function()
			if mutation == "GENERATION" then f.Controller.Generation += 1
			elseif mutation == "OWNER" then f.Controller.Scheduler.Active.Definition.Owner = "PETS"
			else f.Controller.AntiAFK = {} end
		end
		local sent, reason = f:Pulse()
		assert(not sent and reason:sub(1, 11) == "SUPPRESSED:" and #f.Calls == 0 and f.Mechanics.AntiAFKHeldInput == nil)
		f:Close()
	end
end)

test("Actual anti-AFK Pause during down synchronously releases before dispatch returns", function()
	local f = adapterFixture()
	f.OnInput = function(down)
		if down then
			f.Controller.State = "PAUSED"
			assert(f.Mechanics.AntiAFKHeldInput ~= nil)
			assert(f.Mechanics:ReleaseAntiAFKInput())
		end
	end
	assert(f:Pulse() and #f.Calls == 2 and f.Calls[1].Down and not f.Calls[2].Down and f.Mechanics.AntiAFKHeldInput == nil)
	f:Close()
end)

print("[OC TEST] Anti-AFK actual adapter synthetic checks: " .. tostring(tests - before))
end

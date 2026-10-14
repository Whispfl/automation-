-- Synthetic remote-distance wheel exception. Actual GameKnowledge/mechanics
-- run with immutable prior fixture helpers; no Studio execution or live input.
local count = 0
local function audit(name, callback)
	callback() count += 1
	print("[OC REMOTE WHEEL SYNTHETIC] " .. name .. " passed")
end

if REMOTE_WHEEL_TEST_KIND == "KNOWLEDGE" then
	local function scene()
		local s = remoteKnowledgeSupport.Fixture()
		s.CurrentlyOpen, s.WheelOpen, s.AnyOpen, s.Wheel.Visible = nil, false, false, false
		s.HRP.Position = Vector3.new(1000, 300, -1000)
		s.Modules.GuiFrame.Open = function() error("No native UI opening fallback is permitted") end
		s.Modules.GuiFrame.Close = function() error("Read-only admission cannot close native UI") end
		function s:ReadRemote(mode, busy)
			return self.Knowledge:WheelSpinContext(self.Snapshot, 100,
				{ MAXIMUM_ACCOUNT_AGE_SECONDS = 10, ALLOW_REMOTE_WHEEL_TEST = mode }, busy)
		end
		return s
	end
	local function blocked(s, mode, busy)
		local c = s:ReadRemote(mode, busy)
		assert(c.Fresh == false and type(c.Blocker) == "string")
		assert(s.Transport == 0 and s.Loads == 0)
		return c
	end
	audit("explicit remote mode admits an initialized closed wheel while far away", function()
		local s = scene() local before = s.HRP.Position
		local c = s:ReadRemote(true)
		assert(c.Fresh and c.RemoteTest == true and c.WheelUIOpen == false and c.WheelDistance > 1000)
		assert(c.GUI.SpinButton == s.Button and c.GUI.SpinControl == s.Button and c.UIIdle)
		assert(c.ActivationRoot == s.ActivationRoot and c.TicketCount == 4)
		assert(c.ActionsEnabled == false and s.Transport == 0 and s.Loads == 0)
		assert(s.Wheel.Visible == false and s.HRP.Position == before)
	end)
	audit("remote mode preserves already open own-wheel admission", function()
		local s = scene() s.CurrentlyOpen, s.WheelOpen, s.AnyOpen, s.Wheel.Visible = "WheelSpin", true, true, true
		assert(s:ReadRemote(true).Fresh and s.Transport == 0 and s.Loads == 0)
	end)
	audit("false-default mode still requires the owner to open the wheel", function()
		blocked(scene(), false) blocked(scene(), nil)
	end)
	audit("truthy strings never enable the isolated remote exception", function()
		blocked(scene(), "true")
	end)
	audit("default mode still requires native proximity even with wheel open", function()
		local s = scene() s.CurrentlyOpen, s.WheelOpen, s.AnyOpen, s.Wheel.Visible = "WheelSpin", true, true, true
		blocked(s, false)
	end)
	audit("a foreign open menu remains blocked in remote mode", function()
		local s = scene() s.CurrentlyOpen, s.AnyOpen = "Shop", true
		blocked(s, true)
	end)
	audit("a simultaneous WorldMap remains blocked in remote mode", function()
		local s = scene() s.WorldMapOpen = true blocked(s, true)
	end)
	audit("inconsistent closed-frame indicators never become remote readiness", function()
		local s = scene() s.AnyOpen = true blocked(s, true)
	end)
	audit("an uninitialized Pressed attribute fails admission without initialization", function()
		local s = scene() s.Button.Attributes.Pressed = nil blocked(s, true)
		assert(s.Button:GetAttribute("Pressed") == nil)
	end)
	audit("an uninitialized ButtonActivated attribute fails admission", function()
		local s = scene() s.Button.Attributes.ButtonActivated = nil blocked(s, true)
	end)
	audit("inactive underlying native control remains blocked despite hidden ancestor bypass", function()
		local s = scene() s.Button.Active = false blocked(s, true)
	end)
	audit("native child processing flags remain mandatory with wheel ancestor closed", function()
		local s = scene() s.Spin.Visible, s.Skip.Visible = false, true blocked(s, true)
	end)
	audit("a prompt remains a conflicting interaction in remote mode", function()
		local s = scene() s.Screen:Add(remoteKnowledgeSupport.Object("Prompt")) blocked(s, true)
	end)
	audit("trading and race guards are preserved in remote mode", function()
		local s = scene() s.Plaza = true blocked(s, true)
		s = scene() s.Player.Attributes.InRace = true blocked(s, true)
	end)
	audit("missing native wheel identity is blocked rather than moved to or synthesized", function()
		local s = scene() s.Activation.Children.Root = nil blocked(s, true)
	end)
	audit("missing world access remains blocked in remote mode", function()
		local s = scene() s.Raw.WorldsUnlocked["The Overworld"] = nil blocked(s, true)
	end)
	os.clock = remoteKnowledgeSupport.OriginalClock
else
	assert(REMOTE_WHEEL_TEST_KIND == "BRIDGE")
	audit("closed far-away native callback uses one spin and native queue without opening or movement", function()
		local s = remoteBridgeSupport.Fixture()
		local context = s.Manager.SpinPreparationContext
		local hiddenWheel = { Visible = false }
		context.GUI.Wheel, context.RemoteTest, context.WheelUIOpen, context.WheelDistance = hiddenWheel, true, false, 1500
		context.NativeRefs.GuiFrame = { Open = function() error("No automatic wheel menu opening") end }
		context.CharacterRoot = setmetatable({}, { __newindex = function() error("No direct movement for remote spin") end })
		s.Mechanics.TravelSelectedEgg = function() error("No travel fallback") end
		s.Mechanics.PositionSelectedEgg = function() error("No positioning fallback") end
		s:Run() remoteBridgeSupport.Pump(7)
		assert(s.Started and s.Attempts == 1 and s.NativeCallbacks == 1)
		assert(#s.Commands == 2 and s.Commands[1] == "WheelSpin" and s.Commands[2] == "ClaimWheelSpinQueue")
		assert(s.Pending.TransportCount == 1 and s.Pending.SettlementCount == 1)
		assert(#s.Attributes == 2 and hiddenWheel.Visible == false and context.WheelDistance == 1500)
		assert(not s.PurchaseFallback)
	end)
	audit("remote-mode callback uncertainty never becomes a direct transport fallback", function()
		local s = remoteBridgeSupport.Fixture()
		local context = s.Manager.SpinPreparationContext
		context.GUI.Wheel, context.RemoteTest, context.WheelUIOpen, context.WheelDistance = { Visible = false }, true, false, 1500
		s.GUI.SpinButton.SetAttribute = function(self, name, value) self.Values[name] = value table.insert(s.Attributes, name .. "=" .. tostring(value)) end
		s:Run() remoteBridgeSupport.Pump(21)
		assert(#s.Commands == 0 and #s.Attributes == 2 and s.Attempts == 1)
		assert(context.GUI.Wheel.Visible == false)
	end)
	for key in pairs(task) do task[key] = nil end
	for key, value in pairs(remoteBridgeSupport.OriginalTask) do task[key] = value end
	os.clock = remoteBridgeSupport.OriginalClock
end
print("[OC REMOTE WHEEL SYNTHETIC] " .. tostring(count) .. " " .. REMOTE_WHEEL_TEST_KIND .. " remote-only contract cases passed; no live actions")

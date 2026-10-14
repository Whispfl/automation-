-- Actual appended native observer, with synthetic public objects/getters only.
-- No remote, attribute setter, movement or player data mutation by OC is permitted.
local Knowledge = requireOC("GameKnowledge")
local originalClock = os.clock
local checks = 0
os.clock = function() return 100 end
local function object(name, kind)
	local value = { Name = name, ClassName = kind or "Folder", Children = {}, Attributes = {} }
	function value:FindFirstChild(key) return self.Children[key] end
	function value:FindFirstChildOfClass(key)
		for _, child in pairs(self.Children) do if child.ClassName == key then return child end end
	end
	function value:IsA(key) return self.ClassName == key or key == "BasePart" and self.ClassName == "Part" end
	function value:GetAttribute(key) return self.Attributes[key] end
	function value:SetAttribute() error("Read-only knowledge must not activate native input") end
	function value:Add(child) self.Children[child.Name] = child child.Parent = self return child end
	return value
end
local function fixture()
	local s = { Transport = 0, Setter = 0, Loads = 0, Focused = nil, World = "The Overworld", AutoHatch = nil,
		Plaza = false, Hatching = false, Gifts = 0, Rod = nil, CurrentlyOpen = "WheelSpin", AnyOpen = true }
	s.Raw = { Powerups = { ["Spin Ticket"] = 4 }, MasteryUpgrades = {}, AreasUnlocked = { ["Floating Island"] = true },
		WorldsUnlocked = { ["The Overworld"] = true }, Coins = 100, Gems = 50, Potions = {}, Pets = {} }
	s.Player = object("SyntheticPlayer", "Player") s.Player.UserId = 101
	s.Character = object("SyntheticCharacter", "Model") s.Player.Character = s.Character
	s.HRP = s.Character:Add(object("HumanoidRootPart", "Part")) s.HRP.Position = Vector3.new(0, 0, 0)
	s.Humanoid = s.Character:Add(object("Humanoid", "Humanoid")) s.Humanoid.Health = 100
	s.PlayerGui = s.Player:Add(object("PlayerGui")) s.Screen = s.PlayerGui:Add(object("ScreenGui"))
	s.Wheel = s.Screen:Add(object("WheelSpin")) s.Wheel.Visible = true
	s.Frame = s.Wheel:Add(object("Frame")) s.Main = s.Frame:Add(object("Main"))
	s.Spin = s.Main:Add(object("Spin")) s.Spin.Visible = true
	s.Skip = s.Main:Add(object("Skip")) s.Skip.Visible = false
	s.Button = s.Spin:Add(object("Button", "ImageButton")) s.Button.Active = true
	s.Button.Attributes = { Pressed = false, ButtonActivated = false }
	s.SkipButton = s.Skip:Add(object("Button", "TextButton"))
	s.PlayerScripts = s.Player:Add(object("PlayerScripts")) s.Client = s.PlayerScripts:Add(object("ClientScript"))
	s.Auto = s.Client:Add(object("GetAutoHatchStatus", "BindableFunction"))
	function s.Auto:Invoke() if s.OnAuto then s.OnAuto() end return s.AutoHatch end
	s.Workspace = object("Workspace")
	local worlds = s.Workspace:Add(object("Worlds"))
	local world = worlds:Add(object("The Overworld"))
	local islands = world:Add(object("Islands"))
	local island = islands:Add(object("Floating Island"))
	local map = island:Add(object("Island"))
	s.WheelObject = map:Add(object("WheelSpin"))
	s.Activation = s.WheelObject:Add(object("Activation"))
	s.ActivationRoot = s.Activation:Add(object("Root", "Part"))
	s.ActivationRoot.Position, s.ActivationRoot.Size = Vector3.new(0, 0, 0), Vector3.new(12, 12, 12)
	workspace = s.Workspace
	services.UserInputService = { GetFocusedTextBox = function() return s.Focused end }
	local function forbidden() s.Transport += 1 error("Knowledge cannot call native transport") end
	s.Modules = { Remote = { InvokeServer = forbidden, FireServer = forbidden },
		Powerups = { ["Spin Ticket"] = { Name = "Spin Ticket" } },
		WheelSpin = { { Chance = 1, Item = { Type = "Currency", Currency = "Coins", Amount = 10 } } },
		ItemUtil = {}, GuiFrame = {}, HatchPresentation = {}, PhysicalItem = {}, FishingPlayerRods = {}, WorldUtil = {},
		IsTradingPlaza = function() return s.Plaza end }
	function s.Modules.ItemUtil:GetOwnedAmount(account)
		if s.OnOwned then s.OnOwned(account) end
		return s.OwnedOverride or account.Powerups["Spin Ticket"] or 0
	end
	function s.Modules.GuiFrame:GetCurrentlyOpen() return s.CurrentlyOpen end
	function s.Modules.GuiFrame:IsOpen(name) return name == "WheelSpin" and s.WheelOpen ~= false or name == "WorldMap" and s.WorldMapOpen == true end
	function s.Modules.GuiFrame:IsAnyOpen() return s.AnyOpen end
	function s.Modules.HatchPresentation:IsHatching() return s.Hatching end
	function s.Modules.PhysicalItem:GetActiveObjects() return s.Gifts end
	function s.Modules.FishingPlayerRods:GetRodComponent() return s.Rod end
	function s.Modules.WorldUtil:GetPlayerWorld() return s.World end
	s.Snapshot = { Ready = true, Revision = 1, ReadAt = 100, Identity = { UserId = 101 } }
	s.Reader = { Player = s.Player, Revision = 1, Dependencies = {}, Config = { ACCOUNT_SETTINGS = { SELECTED_CURRENCIES = { "Coins", "Gems" } } } }
	function s.Reader:_dependency(name) return s.Modules[name] end
	function s.Reader:_load() s.Loads += 1 end
	function s.Reader:GetLiveProfile() return s.Raw end
	function s.Reader:GetSnapshot() return s.Snapshot end
	s.Knowledge = Knowledge.new(s.Reader)
	function s:Read(allowBusy) return self.Knowledge:WheelSpinContext(self.Snapshot, 100, { MAXIMUM_ACCOUNT_AGE_SECONDS = 10 }, allowBusy) end
	return s
end
local function test(name, callback)
	local s = fixture() callback(s)
	assert(s.Transport == 0, "Native knowledge cannot dispatch")
	checks += 1 print("[OC WHEEL KNOWLEDGE SYNTHETIC] " .. name .. " passed")
end
local function blocked(s, fragment)
	local c = s:Read()
	assert(c.Fresh == false and type(c.Blocker) == "string", "Unsafe or unknown observation must fail closed")
	if fragment then assert(string.find(c.Blocker, fragment, 1, true), c.Blocker) end
end

test("full observed current public native interfaces are detached and read-only", function(s)
	local c = s:Read()
	assert(c.Fresh and c.UserId == 101 and c.TicketCount == 4 and c.Raw ~= s.Raw and c.Raw.Powerups ~= s.Raw.Powerups)
	assert(c.GUI.SpinButton == s.Button and c.ActivationRoot == s.ActivationRoot and c.QueueState == "UNKNOWN")
	assert(c.ActionsEnabled == false and c.UIIdle and c.GiftCount == 0 and c.ReadAt == 100 and c.ReceiptRevision == 1)
	assert(s.Button:GetAttribute("Pressed") == false and s.Raw.Powerups["Spin Ticket"] == 4 and s.Loads == 0)
end)
test("observation sequence advances without fabricated reader revision", function(s)
	local first, second = s:Read(), s:Read()
	assert(first.Fresh and second.Fresh and first.Revision == second.Revision and second.ReceiptRevision == first.ReceiptRevision + 1)
end)
test("zero tickets are observed as zero with no purchase fallback", function(s) s.Raw.Powerups["Spin Ticket"] = 0 assert(s:Read().TicketCount == 0) end)
test("missing ticket key in complete valid map observes zero only", function(s) s.Raw.Powerups["Spin Ticket"] = nil assert(s:Read().TicketCount == 0) end)
test("missing inventory map is unknown", function(s) s.Raw.Powerups = nil blocked(s, "prerequisites") end)
test("malformed inventory value is unknown", function(s) s.Raw.Powerups["Spin Ticket"] = -1 blocked(s, "malformed") end)
test("malformed inventory key is unknown", function(s) s.Raw.Powerups[1] = 1 blocked(s, "malformed") end)
test("unknown mastery map is blocked", function(s) s.Raw.MasteryUpgrades = nil blocked(s, "prerequisites") end)
test("native auto claim conflicts", function(s) s.Raw.MasteryUpgrades[8] = { Type = "AutoClaimSpin" } blocked(s, "AutoClaimSpin") end)
test("malformed mastery entry is unknown", function(s) s.Raw.MasteryUpgrades[2] = false blocked(s, "unknown") end)
test("missing explicit island access blocked", function(s) s.Raw.AreasUnlocked["Floating Island"] = nil blocked(s, "prerequisites") end)
test("missing explicit world access blocked", function(s) s.Raw.WorldsUnlocked["The Overworld"] = nil blocked(s, "prerequisites") end)
test("stale snapshot blocked", function(s) s.Snapshot.ReadAt = 89 blocked(s, "stale") end)
test("future snapshot blocked", function(s) s.Snapshot.ReadAt = 101 blocked(s, "future") end)
test("changed account identity blocked", function(s) s.Player.UserId = 102 blocked(s, "identity") end)
test("changed reader revision blocked", function(s) s.Reader.Revision = 2 blocked(s, "identity") end)
test("missing ready state blocked", function(s) s.Snapshot.Ready = false blocked(s, "identity") end)
test("destroyed reader blocked", function(s) s.Reader.Destroyed = true blocked(s, "identity") end)
test("missing native ticket definition blocked", function(s) s.Modules.Powerups["Spin Ticket"] = nil blocked(s, "definition") end)
test("sparse native pool blocked", function(s) s.Modules.WheelSpin[3] = s.Modules.WheelSpin[1] blocked(s, "sparse") end)
test("empty native pool blocked", function(s) table.clear(s.Modules.WheelSpin) blocked(s, "empty") end)
test("malformed native pool blocked", function(s) s.Modules.WheelSpin[1].Chance = false blocked(s, "malformed") end)
test("missing public remote interface blocked without calling it", function(s) s.Modules.Remote.InvokeServer = nil blocked(s, "Remote.InvokeServer") end)
test("wrong current native world blocked", function(s) s.World = "Minigame Paradise" blocked(s, "world") end)
test("trading plaza blocked", function(s) s.Plaza = true blocked(s, "plaza") end)
test("race ownership blocked", function(s) s.Player.Attributes.InRace = true blocked(s, "Race") end)
test("rod ownership blocked", function(s) s.Rod = {} blocked(s, "Fishing") end)
test("active native hatch blocked", function(s) s.Hatching = true blocked(s, "hatch") end)
test("typing blocked", function(s) s.Focused = {} blocked(s, "Typing") end)
test("dead avatar blocked", function(s) s.Humanoid.Health = 0 blocked(s, "alive") end)
test("transition presentation blocked", function(s) s.PlayerGui:Add(object("TransitionGui")) blocked(s, "transition") end)
test("prompt presentation blocked", function(s) s.Screen:Add(object("Prompt")) blocked(s, "prompt") end)
test("hidden wheel blocked", function(s) s.Wheel.Visible = false blocked(s, "interface") end)
test("native button argument container retains exact Pressed identity", function(s)
	s.Button.ClassName = "Frame"
	local control = s.Button:Add(object("Activation", "ImageButton")) control.Active = true
	local c = s:Read()
	assert(c.Fresh and c.UIIdle and c.GUI.SpinButton == s.Button and c.GUI.SpinControl == control)
	assert(s.Button:GetAttribute("Pressed") == false and s.Transport == 0)
end)
test("inactive native container child blocks admission", function(s)
	s.Button.ClassName = "Frame"
	local control = s.Button:Add(object("Activation", "ImageButton")) control.Active = false
	blocked(s, "disabled")
end)
test("malformed native container activation fails closed", function(s)
	s.Button.ClassName = "Frame" s.Button:Add(object("Activation", "Frame"))
	blocked(s, "interface")
end)
test("unowned native frame blocked", function(s) s.CurrentlyOpen = "Shop" blocked(s, "only") end)
test("world map simultaneously open blocked", function(s) s.WorldMapOpen = true blocked(s, "only") end)
test("processing wheel blocked for admission", function(s) s.Spin.Visible, s.Skip.Visible = false, true blocked(s, "already processing") end)
test("busy observation is allowed only by explicit receipt parameter", function(s)
	s.Spin.Visible, s.Skip.Visible = false, true local c = s:Read(true) assert(c.Fresh and c.UIIdle == false)
end)
test("unknown pressed state blocked", function(s) s.Button.Attributes.Pressed = nil blocked(s, "idle") end)
test("pressed button blocked", function(s) s.Button.Attributes.Pressed = true blocked(s, "pressed") end)
test("inactive button blocked", function(s) s.Button.Active = false blocked(s, "disabled") end)
test("missing native auto hatch getter blocked", function(s) s.Client.Children.GetAutoHatchStatus = nil blocked(s, "auto-hatch") end)
test("active auto hatch blocked", function(s) s.AutoHatch = "Common Egg" blocked(s, "auto-hatch") end)
test("active gifts blocked", function(s) s.Gifts = 1 blocked(s, "gift") end)
test("missing loaded activation root blocked", function(s) s.Activation.Children.Root = nil blocked(s, "activation") end)
test("outside horizontal native radius blocked", function(s) s.HRP.Position = Vector3.new(6.1, 0, 0) blocked(s, "range") end)
test("outside native height blocked", function(s) s.HRP.Position = Vector3.new(0, 10.1, 0) blocked(s, "range") end)
test("canonical getter disagreement blocked", function(s) s.OwnedOverride = 3 blocked(s, "disagrees") end)
test("received ticket mutation during getter cancels observation", function(s) s.OnOwned = function() s.Raw.Powerups["Spin Ticket"] = 3 end blocked(s, "changed during") end)
test("received profile replacement during getter cancels observation", function(s) s.OnOwned = function() s.Raw = table.clone(s.Raw) end blocked(s, "changed during") end)
test("reader revision change during native getter cancels observation", function(s) s.OnAuto = function() s.Reader.Revision = 2 end blocked(s, "changed during") end)
test("public getter replacement during observation cancels observation", function(s) s.OnOwned = function() s.Modules.GuiFrame.IsOpen = function() return true end end blocked(s, "method identity") end)
test("native pool change during observation cancels observation", function(s) s.OnOwned = function() s.Modules.WheelSpin[1].Item.Amount = 11 end blocked(s, "pool") end)
test("native ticket definition replacement during observation cancels observation", function(s) s.OnOwned = function() s.Modules.Powerups["Spin Ticket"] = {} end blocked(s, "definition changed") end)
os.clock = originalClock
print("[OC WHEEL KNOWLEDGE SYNTHETIC] " .. tostring(checks) .. " read-only observation regressions passed")

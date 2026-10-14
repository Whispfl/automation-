-- Executes the actual owner loader. Synthetic accounts only; no Roblox transport.
local Controller = requireOC("OCController")
local originalPrint = print
local originalWait = task.wait
local originalInput = services.UserInputService
local originalPlayer = services.Players.LocalPlayer
local nativeKnowledgeMethod = requireOC("GameKnowledge").FreeWheelTicketContext

local function preflightScene(changes)
	local scene = knowledgeFixture()
	scene.Changes, scene.Output, scene.Waits, scene.Observations = changes or {}, {}, 0, 0
	scene.Actions, scene.Loads = 0, 0
	local function node(children)
		return { FindFirstChild = function(_, name) return children[name] end }
	end
	local auto = { IsA = function(_, kind) return kind == "BindableFunction" end,
		Invoke = function() if scene.OnAuto then scene.OnAuto() end return scene.AutoHatch end }
	local screen = node({})
	local gui = node({ ScreenGui = screen })
	local scripts = node({ ClientScript = node({ GetAutoHatchStatus = auto }) })
	local player = scene.Reader.Player
	services.Players.LocalPlayer = player
	function player:FindFirstChild(name)
		if name == "PlayerGui" then return gui elseif name == "PlayerScripts" then return scripts end
		return nil
	end
	function player:GetAttribute(name) assert(name == "InRace") return scene.InRace end
	services.UserInputService = { GetFocusedTextBox = function() return scene.Typing and {} or nil end }
	function scene:Forbidden() self.Actions += 1 error("Owner preflight must not enter a gameplay or ledger-reset action") end
	function scene:Load(overrides)
		self.Loads += 1
		local merged = Resolver.Resolve(Defaults, overrides)
		self.Config, self.Reader.Config = merged, merged
		local controller = { Config = merged, Reader = self.Reader, Knowledge = self.Knowledge,
			State = "STOPPED", Generation = 1, Scheduler = Scheduler.new(merged.TASK_SETTINGS),
			Pets = { Hatch = {} }, RewardAttributionBlocked = Controller.RewardAttributionBlocked }
		controller.Start = function() return self:Forbidden() end
		controller.Resume = controller.Start
		controller.Scheduler.Start = controller.Start
		controller.Scheduler.Submit = controller.Start
		local tracker = { Root = function()
			if self.OnRoot then self.OnRoot() end
			return not self.Dead and {} or nil, {}
		end }
		local mechanics = Mechanics.new(merged, self.Reader, tracker, player, controller.Start)
		mechanics.LocalFeatureController = controller
		mechanics.RewardAction, mechanics.ClaimFreeWheelTicket = controller.Start, controller.Start
		controller.Farming = { Mechanics = mechanics }
		controller.Rewards = Rewards.new(controller)
		for _, method in ipairs({ "Select", "SelectFreeWheelTicket", "Prepare", "PrepareFreeWheelTicket",
			"MarkFreeWheelTicketDispatched", "ObserveFreeWheelTicket", "Halt" }) do
			controller.Rewards[method] = controller.Start
		end
		self.Controller = controller
		if self.Changes.Load then self.Changes.Load(self, controller) end
		self.ConfigBefore = copy(controller.Config)
		self.LedgerBefore = copy(controller.Rewards.Ledger)
		self.SharedBefore = copy(shared)
		function self.Knowledge:FreeWheelTicketContext(snapshot, observedNow, settings)
			scene.Observations += 1
			assert(settings ~= scene.Config.FREE_WHEEL_TICKET_SETTINGS, "Only a detached reader argument may open the observation gate")
			assert(settings.ENABLE_FREE_WHEEL_TICKET_CLAIM == true)
			if not scene.IntentionalAuthorizationChange then
				assert(scene.Config.FREE_WHEEL_TICKET_SETTINGS.ENABLE_FREE_WHEEL_TICKET_CLAIM == false)
				assert(scene.Config.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_ACCOUNT_ID == 0)
				assert(scene.Config.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_TEST_ID == "")
				assert(scene.Config.FREE_WHEEL_TICKET_SETTINGS.OWNER_CONFIRMED_WHEEL_IDLE == false)
			end
			return nativeKnowledgeMethod(self, snapshot, observedNow, settings)
		end
		return controller
	end
	function scene:Run()
		wheelPreflightScene = self
		local sharedBeforeRun = copy(shared)
		print = function(message) table.insert(self.Output, tostring(message)) end
		task.wait = function(seconds)
			assert(seconds == 1, "Only the approved bounded dependency-read interval is used")
			self.Waits += 1 now += seconds
			if self.Changes.Wait then self.Changes.Wait(self) end
			if self.Changes.Refresh ~= false then self.Reader.Snapshot.ReadAt = now end
		end
		local ok, controller = pcall(executeWheelPreflightLoader)
		print, task.wait = originalPrint, originalWait
		assert(ok, controller)
		if self.Loads == 0 then
			assert(controller == nil and same(sharedBeforeRun, shared), "Prior runtime blocker must prevent replacement or ledger changes")
			assert(self.Waits == 0 and self.Observations == 0 and self.Actions == 0)
			assert(#self.Output == 2 and string.find(self.Output[1], "BLOCKED", 1, true))
			assert(string.find(self.Output[2], "existing runtime preserved", 1, true))
			return { Status = "BLOCKED", Blocker = self.Output[1] }
		end
		assert(controller == self.Controller and self.Loads == 1)
		assert(self.Actions == 0 and self.Waits <= 14 and self.Observations <= 30)
		assert(controller.Scheduler.Active == nil or self.Changes.Active, "No execution lease was acquired")
		if not self.IntentionalAuthorizationChange then assert(same(self.ConfigBefore, controller.Config), "Observer must not mutate actual Config") end
		if not self.Changes.MutatesLedger then
			assert(same(self.LedgerBefore, controller.Rewards.Ledger), "Preflight must not change/reset reward history")
			assert(same(self.SharedBefore, shared), "Preflight must preserve same-client ledgers")
		end
		local output = table.concat(self.Output, "\n")
		for _, private in ipairs({ "UserId=", "account=", "Coins=", "Gems=", "TicketCount", "Powerups=",
			"Mystery Box", "Synthetic ticket", "inventory=", "balance=" }) do
			assert(not string.find(output, private, 1, true), "Owner report must omit private baseline facts: " .. private)
		end
		assert(string.find(output, "requests issued by this loader=0", 1, true))
		assert(string.find(output, "claim permission=OFF", 1, true))
		assert(string.find(output, "wheel queue=UNKNOWN", 1, true))
		return controller.WheelPreflightReport
	end
	if scene.Changes.Before then scene.Changes.Before(scene) end
	return scene
end

local function blocked(name, changes, reason)
	audit("owner disabled preflight fails closed: " .. name, function()
		local s = preflightScene(changes)
		local report = s:Run()
		assert(report.Status == "BLOCKED" and type(report.Blocker) == "string")
		if reason then assert(string.find(report.Blocker, reason, 1, true), report.Blocker) end
		s.Reader:Destroy()
	end)
end

audit("actual owner loader reports due data only as ready for separate authorization", function()
	local s = preflightScene()
	local report = s:Run()
	assert(report.Status == "READY_FOR_SEPARATE_AUTHORIZATION" and report.Permission == "OFF", report.Blocker or report.Status)
	assert(report.Due == true and report.AutoClaimSpin == false and report.ActiveGifts == 0)
	assert(report.QueueState == "UNKNOWN" and report.ClaimRequestsThisLoader == 0 and report.SnapshotOnly)
	assert(s.Waits == 0 and s.Observations == 2 and #queue == 0)
	assert(s.Controller.State == "STOPPED" and s.Controller.Rewards.Ledger.FreeWheelTicket == nil)
	s.Reader:Destroy()
end)

audit("owner loader merges every gameplay flag OFF and zero spending ceilings", function()
	local s = preflightScene() s:Run()
	local c = s.Config
	assert(c.GENERAL_SETTINGS.AUTO_START == false and c.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS == false)
	assert(c.STATUS_UI_SETTINGS.ENABLE_STATUS_UI == false and c.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING == false)
	for _, field in ipairs({
		{ "PLAYTIME_SETTINGS", "AUTO_CLAIM_PLAYTIME" }, { "MYSTERY_BOX_SETTINGS", "AUTO_OPEN_MYSTERY_BOXES" },
		{ "MYSTERY_BOX_SETTINGS", "ENABLE_AUTOMATIC_CONTINUATION" }, { "FARMING_SETTINGS", "AUTO_RESOURCE_FARM" },
		{ "FARMING_SETTINGS", "AUTO_FARM_FALLBACK" }, { "PICKUP_SETTINGS", "BULK_COLLECT_PICKUPS" },
		{ "PICKUP_SETTINGS", "ENABLE_CONTINUOUS_SCANNING" }, { "BUBBLE_SETTINGS", "AUTO_BLOW_BUBBLES" },
		{ "BUBBLE_SETTINGS", "AUTO_SELL_BUBBLES" }, { "BUBBLE_SETTINGS", "AUTO_BUY_GUM" },
		{ "BUBBLE_SETTINGS", "AUTO_BUY_FLAVORS" }, { "BUBBLE_SETTINGS", "ENABLE_SIMULTANEOUS_BLOWING" },
		{ "WORLD_SETTINGS", "ENABLE_WORLD_PROGRESSION" }, { "WORLD_SETTINGS", "AUTO_DISCOVER_ISLANDS" },
		{ "WORLD_SETTINGS", "AUTO_UNLOCK_WORLDS" }, { "WORLD_SETTINGS", "AUTO_TRAVEL_FOR_PROGRESSION" },
		{ "WORLD_SETTINGS", "AUTO_FARM_UNLOCK_REQUIREMENTS" }, { "ISLAND_SETTINGS", "AUTO_TRAVEL_BEST_ISLAND" },
		{ "ISLAND_SETTINGS", "AUTO_EXPLORE_UNLOCKED_ISLANDS" }, { "PET_SETTINGS", "AUTO_HATCH" },
		{ "PET_SETTINGS", "AUTO_EQUIP" }, { "PET_SETTINGS", "EQUIP_OWNED_TEAM_ONCE" },
		{ "PET_SETTINGS", "AUTO_DELETE_PETS" }, { "PET_SETTINGS", "AUTO_CRAFT_SHINY" },
		{ "PET_SETTINGS", "AUTO_FUSE_PETS" }, { "HATCH_SETTINGS", "HATCH_ONE_EGG_ONCE" },
		{ "OWNER_ONE_HATCH_TEST_SETTINGS", "OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST" },
		{ "OWNER_ONE_HATCH_TEST_SETTINGS", "OWNER_ONE_HATCH_TEST_ALLOWANCE" },
		{ "EGG_TRAVEL_SETTINGS", "OWNER_DIRECT_EGG_TELEPORT_TEST" }, { "EGG_TRAVEL_SETTINGS", "ENABLE_SELECTED_EGG_TRAVEL" },
		{ "EGG_TRAVEL_SETTINGS", "ENABLE_NATIVE_ISLAND_TRAVEL" }, { "EGG_TRAVEL_SETTINGS", "ENABLE_DIRECT_POSITIONING" },
		{ "ANTIAFK_SETTINGS", "ENABLE_ANTI_AFK" }, { "UPGRADE_SETTINGS", "ENABLE_SMART_UPGRADES" },
		{ "UPGRADE_SETTINGS", "ENABLE_CAPACITY_UPGRADES" }, { "UPGRADE_SETTINGS", "ENABLE_FLAVOR_UPGRADES" },
		{ "UPGRADE_SETTINGS", "AUTO_EQUIP_OWNED_UPGRADES" }, { "FALL_EVENT_SETTINGS", "ENABLE_FALL_EVENT" },
		{ "FALL_EVENT_SETTINGS", "AUTO_REBIRTH" }, { "FALL_EVENT_SETTINGS", "AUTO_BUY_REBIRTH_UPGRADES" },
		{ "FALL_EVENT_SETTINGS", "AUTO_USE_FALL_ELIXIRS" }, { "FALL_EVENT_SETTINGS", "AUTO_BUY_AUTUMN_SHOP_ITEMS" },
	}) do assert(c[field[1]][field[2]] == false, field[1] .. "." .. field[2]) end
	for _, field in ipairs({ { "HATCH_SETTINGS", "MAXIMUM_EGG_COST" }, { "HATCH_SETTINGS", "MAXIMUM_SESSION_COST" },
		{ "OWNER_ONE_HATCH_TEST_SETTINGS", "MAXIMUM_COIN_ALLOWANCE" }, { "OWNER_ONE_HATCH_TEST_SETTINGS", "MAXIMUM_EGG_COST" },
		{ "WORLD_SETTINGS", "MAXIMUM_WORLD_UNLOCK_COST" }, { "UPGRADE_SETTINGS", "MAXIMUM_PURCHASE_COST" } }) do
		assert(c[field[1]][field[2]] == 0, field[1] .. "." .. field[2])
	end
	s.Reader:Destroy()
end)

blocked("timer not due", { Before = function(s) s.Raw.NextWheelSpin = 1001 s:Sync() end }, "not due")
blocked("missing explicit deadline", { Before = function(s) s.Raw.NextWheelSpin = nil s:Sync() end }, "NextWheelSpin")
blocked("missing complete inventory", { Before = function(s) s.Raw.Powerups = nil s:Sync() end }, "Powerups")
blocked("stale account", { Refresh = false, Before = function(s) s.Reader.Snapshot.ReadAt = now - 11 end }, "stale")
blocked("native time unavailable", { Before = function(s) s.Reader.Dependencies.Time.Status = "LOADING" end })
blocked("active native auto-ticket claim", { Before = function(s) s.Raw.MasteryUpgrades[2] = { Type = "AutoClaimSpin" } s:Sync() end }, "AutoClaimSpin")
blocked("unknown auto-ticket claim", { Before = function(s) s.Raw.MasteryUpgrades = nil s:Sync() end }, "MasteryUpgrades")
blocked("active gift", { Before = function(s) s.OnGifts = function() return 1 end end }, "gift")
blocked("unknown active gift count", { Before = function(s) s.OnGifts = function() return nil end end }, "gift")
blocked("malformed ticket count", { Before = function(s) s.Raw.Powerups["Spin Ticket"] = -1 s:Sync() end }, "Powerups")
blocked("dead avatar", { Before = function(s) s.Dead = true end }, "not alive")
blocked("typing", { Before = function(s) s.Typing = true end }, "Typing")
blocked("island race", { Before = function(s) s.InRace = true end }, "race")
blocked("trading plaza", { Before = function(s) s.Reader.Dependencies.IsTradingPlaza.Value = function() return true end end }, "Trading plaza")
blocked("open native frame", { Before = function(s) s.Reader.Dependencies.GuiFrame.Value.IsAnyOpen = function() return true end end }, "frame")
blocked("fishing", { Before = function(s) s.Reader.Dependencies.FishingPlayerRods.Value.GetRodComponent = function() return {} end end }, "fishing")
blocked("native hatch presentation", { Before = function(s) s.Reader.Dependencies.HatchPresentation.Value.IsHatching = function() return true end end }, "hatch presentation")
blocked("native auto-hatch", { Before = function(s) s.AutoHatch = true end }, "auto-hatch")
blocked("pending equipment", { Load = function(_, c) c.Pets.PendingEquip = {} end }, "Pending pet")
blocked("pending hatch", { Load = function(_, c) c.Pets.Hatch.Pending = {} end }, "Pending pet")
blocked("pending reward", { Load = function(_, c) c.Rewards.Ledger.Pending = { Kind = "synthetic" } end }, "reward operation")
blocked("unresolved attribution", { Load = function(_, c) c.Rewards.Ledger.UnresolvedAttribution = true end }, "unresolved attribution")
blocked("quiet attribution window", { Load = function(_, c) c.RewardQuietUntil = now + 20 end }, "unresolved attribution")
blocked("consumed wheel allowance", { Load = function(_, c) c.Rewards.Ledger.FreeWheelTicket = { Version = 1, Epoch = 1,
	Tests = { SYNTHETIC = { Attempts = 1, Outcome = "CLAIM_AND_GRANT_OBSERVED" } } } end }, "consumed")
blocked("malformed wheel extension", { Load = function(_, c) c.Rewards.Ledger.FreeWheelTicket = "unknown" end }, "consumed")
blocked("malformed account ID", { Before = function(s) s.Reader.Player.UserId = 0 end }, "ledger")
blocked("snapshot account mismatch", { Before = function(s) s.Reader.Snapshot.Identity.UserId = 202 end }, "Exact-account")
blocked("ledger account mismatch", { Load = function(_, c) c.Rewards.Ledger.UserId = 202 end }, "Exact-account")
blocked("unknown ledger schema", { Before = function() shared.__OC_LOCAL_REWARD_LEDGER = { Version = 99, Accounts = {} } end }, "retained reward ledger")
blocked("prior running OC", { Before = function() shared.__OC_PHASE1_INSTANCE = { State = "RUNNING" } end }, "existing OC")
blocked("prior paused OC", { Before = function() shared.__OC_PHASE1_INSTANCE = { State = "PAUSED" } end }, "existing OC")
blocked("prior stopped OC with uncertain reward", { Before = function()
	shared.__OC_PHASE1_INSTANCE = { State = "STOPPED", Rewards = { AttributionBlocked = function() return true end } }
end }, "existing OC")
blocked("prior unresolved receipt", { Before = function()
	shared.__OC_LOCAL_REWARD_LEDGER = { Version = 1, Accounts = { ["101"] = { UserId = 101, Sessions = {}, Pending = {} } } }
end }, "receipt unresolved")
blocked("prior account ledger mismatch", { Before = function()
	shared.__OC_LOCAL_REWARD_LEDGER = { Version = 1, Accounts = { ["101"] = { UserId = 202, Sessions = {} } } }
end }, "account ledger mismatch")
blocked("prior consumed wheel authorization", { Before = function()
	shared.__OC_LOCAL_REWARD_LEDGER = { Version = 1, Accounts = { ["101"] = { UserId = 101, Sessions = {},
		FreeWheelTicket = { Version = 1, Tests = { SYNTHETIC = { Attempts = 1 } } } } } }
end }, "consumed")
blocked("prior wheel schema unknown", { Before = function()
	shared.__OC_LOCAL_REWARD_LEDGER = { Version = 1, Accounts = { ["101"] = { UserId = 101, Sessions = {},
		FreeWheelTicket = { Version = 99, Tests = {} } } } }
end }, "wheel ledger")
blocked("original manager rejects malformed unconsumed wheel record", { Before = function()
	shared.__OC_LOCAL_REWARD_LEDGER = { Version = 1, Accounts = { ["101"] = { UserId = 101, Sessions = {},
		FreeWheelTicket = { Version = 1, Epoch = 1, Tests = { SYNTHETIC = { Attempts = 0 } } } } } }
end }, "Malformed free-wheel")
blocked("destroyed controller cancellation", { Load = function(_, c) c.Destroyed = true end }, "stopped controller")
blocked("paused controller", { Load = function(_, c) c.State = "PAUSED" end }, "stopped controller")
blocked("active scheduler task", { Active = true, Load = function(_, c) c.Scheduler.Active = {} end }, "stopped controller")
blocked("exact shared ledger replaced after initialization", { Load = function(_, c)
	shared.__OC_LOCAL_REWARD_LEDGER.Accounts["101"] = copy(c.Rewards.Ledger)
end }, "Exact-account")

audit("readiness waits only for bounded missing dependencies without action retries", function()
	local s = preflightScene({ Before = function(scene) scene.Reader.Dependencies.Time.Status = "LOADING" end,
		Wait = function(scene) if scene.Waits == 2 then scene.Reader.Dependencies.Time.Status = "READY" end end })
	assert(s:Run().Status == "READY_FOR_SEPARATE_AUTHORIZATION" and s.Waits == 2 and s.Actions == 0)
	s.Reader:Destroy()
end)

audit("native observation uncertainty never triggers a claim or another execution attempt", function()
	local s = preflightScene({ Before = function(scene) scene.Reader.Dependencies.Time.Status = "LOADING" end })
	assert(s:Run().Status == "BLOCKED" and s.Waits == 14 and s.Observations == 15 and s.Actions == 0)
	s.Reader:Destroy()
end)

blocked("received facts change during native getter", { Before = function(s)
	s.OnGet = function(descriptor) if descriptor.Name == "Spin Ticket" then s.Raw.NextWheelSpin += 1 end end
end }, "changed")
blocked("account changes during auto-hatch getter", { Before = function(s)
	s.OnAuto = function() s.Reader.Player.UserId = 202 end
end })
blocked("cancellation during read-only native getter", { Before = function(s)
	s.OnAuto = function() s.Controller.Destroyed = true end
end }, "changed during observation")
blocked("unexpected authorization mutation during read-only getter", { Before = function(s)
	s.OnAuto = function() s.IntentionalAuthorizationChange = true s.Config.FREE_WHEEL_TICKET_SETTINGS.ENABLE_FREE_WHEEL_TICKET_CLAIM = true end
end }, "authorization")

services.UserInputService = originalInput
services.Players.LocalPlayer = originalPlayer
print, task.wait = originalPrint, originalWait
print("[OC WHEEL PREFLIGHT SYNTHETIC] " .. checks .. " actual-loader/actual-source checks passed; no live test or claim authorized.")

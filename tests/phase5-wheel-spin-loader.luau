-- Complete disabled-loader execution with real appended manager observation
-- and normalization, synthetic received facts, and a forbidden-action barrier.
local originalPrint, originalWait = print, task.wait
local function loaderScene(options)
	options = options or {}
	local s = fixture({ Disabled = true, Before = options.Before })
	s.Options, s.Output, s.Loads, s.Waits, s.Actions = options, {}, 0, 0, 0
	s.Controller.State = "STOPPED"
	services.Players.LocalPlayer = s.Reader.Player
	function s:Forbidden() self.Actions += 1 error("Disabled loader must not enter any gameplay action") end
	function s:Load(overrides)
		self.Loads += 1
		self.Config = Resolver.Resolve(Defaults, overrides)
		self.Controller.Config, self.Manager.Config = self.Config, self.Config
		self.Controller.RewardAttributionBlocked = function() return self.Manager:AttributionBlocked() end
		self.Controller.Start, self.Controller.Resume = function() return self:Forbidden() end, function() return self:Forbidden() end
		self.Controller.Scheduler.Submit = self.Controller.Start
		for _, method in ipairs({ "Select", "SelectWheelSpin", "InitializeWheelSpin", "Prepare", "PrepareWheelSpin", "MarkWheelSpinDispatched", "ObserveWheelSpin" }) do
			self.Manager[method] = self.Controller.Start
		end
		self.Controller.Farming.Mechanics.SpinWheelOnce = self.Controller.Start
		self.Controller.Farming.Mechanics.ReleaseWheelSpinBridge = self.Controller.Start
		if options.Load then options.Load(self, self.Controller) end
		self.ConfigBefore, self.LedgerBefore, self.SharedBefore = copy(self.Config), copy(self.Manager.Ledger), copy(shared)
		return self.Controller
	end
	function s:Run()
		wheelSpinLoaderScene = self
		local sharedBefore = copy(shared)
		print = function(value) table.insert(self.Output, tostring(value)) end
		task.wait = function(seconds)
			assert(seconds == 1) self.Waits += 1 now += seconds
			if options.Wait then options.Wait(self) end
		end
		local ok, controller = pcall(executeDisabledWheelSpinLoader)
		print, task.wait = originalPrint, originalWait
		assert(ok, controller)
		assert(self.Loads <= 1 and self.Actions == 0 and self.Inputs == 0 and self.Commands == 0 and self.Waits <= 14)
		if self.Loads == 0 then
			assert(controller == shared.__OC_PHASE1_INSTANCE and same(shared, sharedBefore))
			assert(#self.Output == 1 and string.find(self.Output[1], "Prior OC", 1, true))
			return { Ready = false, PriorRuntimePreserved = true }
		end
		assert(controller == self.Controller and same(self.Config, self.ConfigBefore))
		assert(same(self.Manager.Ledger, self.LedgerBefore) and same(shared, self.SharedBefore), "No reward history reset, initialization or rearm during preflight")
		assert(self.Controller.Scheduler.Active == nil or options.Active)
		local output = table.concat(self.Output, "\n")
		for _, private in ipairs({ "UserId", "account=", "AccountId", "Coins=", "Gems=", "synthetic-doggy", "inventory=" }) do
			assert(not string.find(output, private, 1, true), "Owner preflight output must omit account/balance/instance data")
		end
		assert(string.find(output, "spin requests=0 | queue calls=0 | ticket consumption=0", 1, true))
		return controller.WheelSpinPreflight
	end
	return s
end

test("complete disabled loader reports readiness without authorizing or selecting a spin", function()
	local s = loaderScene() local report = s:Run()
	assert(report.Ready and report.ActionsAuthorized == false and report.QueueState == "UNKNOWN")
	assert(s.Controller.State == "STOPPED" and s.Controller.Scheduler.Active == nil and s.Waits == 0)
	assert(s.Manager.Ledger.WheelSpin == nil and s.Manager.Ledger.Pending == nil)
end)

test("actual loader overrides resolve to OFF controls, zero budgets and no private console summaries", function()
	local s = loaderScene() s:Run() local c = s.Config
	local wheel, free = c.WHEEL_SPIN_SETTINGS, c.FREE_WHEEL_TICKET_SETTINGS
	assert(wheel.AUTO_SPIN_WHEEL == false and wheel.OWNER_ONE_SPIN_ALLOWANCE == false and wheel.AUTHORIZED_ACCOUNT_ID == 0
		and wheel.AUTHORIZED_TEST_ID == "" and wheel.OWNER_CONFIRMED_WHEEL_IDLE == false)
	assert(free.ENABLE_FREE_WHEEL_TICKET_CLAIM == false and free.AUTHORIZED_ACCOUNT_ID == 0)
	assert(c.GENERAL_SETTINGS.AUTO_START == false and c.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS == false and c.STATUS_UI_SETTINGS.ENABLE_STATUS_UI == false)
	assert(c.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING == false and c.DIAGNOSTIC_SETTINGS.ENABLE_DEBUG_LOGGING == false)
	for category, settings in pairs(c) do
		for key, value in pairs(settings) do
			if key:match("^AUTO_") and key ~= "AUTO_SELECT_BEST_ISLAND" then assert(value == false, category .. "." .. key) end
		end
	end
	for _, field in ipairs({ { "PET_SETTINGS", "EQUIP_OWNED_TEAM_ONCE" }, { "WORLD_SETTINGS", "ENABLE_WORLD_PROGRESSION" },
		{ "EGG_TRAVEL_SETTINGS", "ENABLE_SELECTED_EGG_TRAVEL" }, { "EGG_TRAVEL_SETTINGS", "ENABLE_DIRECT_POSITIONING" },
		{ "EGG_TRAVEL_SETTINGS", "ENABLE_NATIVE_ISLAND_TRAVEL" }, { "EGG_TRAVEL_SETTINGS", "OWNER_DIRECT_EGG_TELEPORT_TEST" },
		{ "PICKUP_SETTINGS", "BULK_COLLECT_PICKUPS" }, { "PICKUP_SETTINGS", "ENABLE_CONTINUOUS_SCANNING" },
		{ "ANTIAFK_SETTINGS", "ENABLE_ANTI_AFK" }, { "UPGRADE_SETTINGS", "ENABLE_SMART_UPGRADES" },
		{ "UPGRADE_SETTINGS", "ENABLE_CAPACITY_UPGRADES" }, { "UPGRADE_SETTINGS", "ENABLE_FLAVOR_UPGRADES" },
		{ "OWNER_ONE_HATCH_TEST_SETTINGS", "OWNER_ONE_HATCH_TEST_ALLOWANCE" },
		{ "OWNER_ONE_HATCH_TEST_SETTINGS", "OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST" } }) do assert(c[field[1]][field[2]] == false) end
	for _, budget in ipairs({ { "HATCH_SETTINGS", "MAXIMUM_EGG_COST" }, { "HATCH_SETTINGS", "MAXIMUM_SESSION_COST" },
		{ "OWNER_ONE_HATCH_TEST_SETTINGS", "MAXIMUM_COIN_ALLOWANCE" }, { "OWNER_ONE_HATCH_TEST_SETTINGS", "MAXIMUM_EGG_COST" },
		{ "WORLD_SETTINGS", "MAXIMUM_WORLD_UNLOCK_COST" }, { "UPGRADE_SETTINGS", "MAXIMUM_PURCHASE_COST" } }) do assert(c[budget[1]][budget[2]] == 0) end
end)

for _, previousState in ipairs({ "RUNNING", "PAUSED" }) do
	test("prior " .. previousState .. " OC survives without fetch or initialization", function()
		local s = loaderScene() shared.__OC_PHASE1_INSTANCE = { State = previousState }
		assert(s:Run().PriorRuntimePreserved and s.Loads == 0 and s.ContextCalls == 0)
	end)
end

test("uncertain prior stopped reward survives without fetch or initialization", function()
	local s = loaderScene()
	shared.__OC_PHASE1_INSTANCE = { State = "STOPPED", Rewards = { AttributionBlocked = function() return true end } }
	assert(s:Run().PriorRuntimePreserved and s.Loads == 0 and s.ContextCalls == 0)
end)

local function blocked(name, options)
	test("disabled loader preflight blocks " .. name, function()
		local s = loaderScene(options) local report = s:Run()
		assert(not report.Ready and report.ActionsAuthorized == false and type(report.Blocker) == "string")
	end)
end
blocked("wrong coherent account", { Before = function(s) s.ContextAccount = 202 end })
blocked("unavailable native context", { Before = function(s) s.ContextUnknown = true end })
blocked("native getter exception", { Before = function(s) s.ContextError = true end })
blocked("zero ticket stock", { Before = function(s) s.Raw.Powerups["Spin Ticket"] = 0 end })
blocked("missing canonical Powerups map", { Before = function(s) s.Raw.Powerups = nil end })
blocked("missing potion baseline", { Before = function(s) s.Raw.Potions = nil end })
blocked("malformed sparse potion baseline", { Before = function(s) s.Raw.Potions[3] = s.Raw.Potions[1] end })
blocked("missing pet baseline", { Before = function(s) s.Raw.Pets = nil end })
blocked("native auto-claim Mastery", { Before = function(s) s.Raw.MasteryUpgrades = { { Type = "AutoClaimSpin" } } end })
blocked("native busy interface observation", { Before = function(s)
	s.OnContext = function(_, busy) assert(busy == false, "Preflight must never opt into a busy animation") s.ContextUnknown = true end
end })
blocked("read guard becomes unavailable", { Before = function(s) s.ContextUnknown = true end })
blocked("pending pet equipment", { Load = function(_, c) c.Pets.PendingEquip = {} end })
blocked("pending reward receipt", { Load = function(s) s.Manager.Ledger.Pending = { Kind = "synthetic" } end })
blocked("unresolved reward attribution", { Load = function(s) s.Manager.Ledger.UnresolvedAttribution = true end })
blocked("consumed spin allowance", { Load = function(s) s.Manager.Ledger.WheelSpin = { Tests = { SYNTHETIC = { Attempts = 1 } } } end })
blocked("controller already running", { Load = function(_, c) c.State = "RUNNING" end })
blocked("controller destroyed", { Load = function(_, c) c.Destroyed = true end })
blocked("scheduler already active", { Active = true, Load = function(_, c) c.Scheduler.Active = {} end })

test("bounded native read window can reach readiness without another initialization or action", function()
	local s = loaderScene({ Before = function(v) v.ContextUnknown = true end,
		Wait = function(v) if v.Waits == 2 then v.ContextUnknown = false end end })
	assert(s:Run().Ready and s.Waits == 2 and s.Loads == 1 and s.Actions == 0)
end)

test("unknown observations finish after fifteen reads with no selection or retry", function()
	local s = loaderScene({ Before = function(v) v.ContextUnknown = true end })
	assert(not s:Run().Ready and s.Waits == 14 and s.ContextCalls == 15 and s.Actions == 0)
end)

test("controller cancellation during a getter cannot report READY", function()
	local s = loaderScene({ Before = function(v) v.OnContext = function() v.Controller.Destroyed = true end end })
	assert(not s:Run().Ready and s.Waits == 0 and s.Actions == 0)
end)

print("[OC WHEEL SPIN LOADER SYNTHETIC] " .. checks .. " complete disabled-loader checks passed; no live action or approval inferred.")

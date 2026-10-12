--!nonstrict
local AccountStateReader = require(script.Parent.AccountStateReader)
local OCBrain = require(script.Parent.OCBrain)
local TaskScheduler = require(script.Parent.TaskScheduler)
local AccountPresentation = require(script.Parent.AccountPresentation)
local FarmingCoordinator = require(script.Parent.FarmingCoordinator)
local GameKnowledge = require(script.Parent.GameKnowledge)
local WorldProgressionManager = require(script.Parent.WorldProgressionManager)
local PetManager = require(script.Parent.PetManager)
local EggTravelManager = require(script.Parent.EggTravelManager)
local RewardsManager = require(script.Parent.RewardsManager)
local AntiAFKManager = require(script.Parent.AntiAFKManager)
local OwnerHatchTestAllowance = require(script.Parent.OwnerHatchTestAllowance)

local OCController = {}
OCController.__index = OCController

local function validate(config)
	for _, name in ipairs({ "GENERAL_SETTINGS", "ACCOUNT_SETTINGS", "BRAIN_SETTINGS", "RESOURCE_SETTINGS",
		"TASK_SETTINGS", "BUBBLE_SETTINGS", "FALL_EVENT_SETTINGS", "PET_SETTINGS", "STATUS_UI_SETTINGS", "DIAGNOSTIC_SETTINGS",
		"FARMING_SETTINGS", "ISLAND_SETTINGS", "PICKUP_SETTINGS", "UPGRADE_SETTINGS", "WORLD_SETTINGS", "HATCH_SETTINGS",
		"EGG_TRAVEL_SETTINGS", "OWNER_ONE_HATCH_TEST_SETTINGS", "PLAYTIME_SETTINGS", "MYSTERY_BOX_SETTINGS", "ANTIAFK_SETTINGS" }) do
		assert(type(config[name]) == "table", "Missing configuration category: " .. name)
	end
	for category, entries in pairs(config) do
		assert(type(category) == "string" and category:match("^[A-Z][A-Z_]*_SETTINGS$"), "Invalid configuration category")
		assert(type(entries) == "table", category .. " must be a table")
		for key, value in pairs(entries) do
			assert(type(key) == "string" and key:match("^[A-Z][A-Z_]*$"), "Invalid configuration setting")
			if key:match("^ENABLE_") or key:match("^AUTO_") or key:match("^READ_") or key:match("^SHOW_") or key == "OC_ENABLED" then
				assert(type(value) == "boolean", category .. "." .. key .. " must be true or false")
			elseif type(value) == "number" then
				assert(value == value and value >= 0 and value < math.huge, category .. "." .. key .. " must be finite and nonnegative")
			elseif type(value) == "table" then
				local count = 0
				for index, item in pairs(value) do
					assert(type(index) == "number" and index >= 1 and index % 1 == 0 and type(item) == "string", key .. " must be an array of strings")
					count += 1
				end
				assert(count == #value, key .. " must be a contiguous array")
			end
		end
	end
	for _, value in ipairs({ config.ACCOUNT_SETTINGS.MODULE_LOAD_TIMEOUT_SECONDS, config.ACCOUNT_SETTINGS.ACCOUNT_LOAD_TIMEOUT_SECONDS,
		config.ACCOUNT_SETTINGS.SNAPSHOT_REFRESH_SECONDS, config.TASK_SETTINGS.TASK_TIMEOUT_SECONDS, config.TASK_SETTINGS.MAXIMUM_PENDING_TASKS }) do
		assert(type(value) == "number" and value >= 1, "Timeouts, refresh intervals, and queue limits must be at least one")
	end
	assert(type(config.ACCOUNT_SETTINGS.MINIMUM_SNAPSHOT_INTERVAL_SECONDS) == "number" and config.ACCOUNT_SETTINGS.MINIMUM_SNAPSHOT_INTERVAL_SECONDS >= 0,
		"MINIMUM_SNAPSHOT_INTERVAL_SECONDS must be numeric and nonnegative")
	assert(config.GENERAL_SETTINGS.PROGRESSION_PROFILE == "FULL_AUTO_PROGRESSION", "Only FULL_AUTO_PROGRESSION is implemented")
	assert(config.BUBBLE_SETTINGS.SELL_AT_CAPACITY_RATIO > 0 and config.BUBBLE_SETTINGS.SELL_AT_CAPACITY_RATIO <= 1, "Sell threshold must be in (0, 1]")
	assert(config.RESOURCE_SETTINGS.MAXIMUM_UPGRADE_BALANCE_FRACTION > 0 and config.RESOURCE_SETTINGS.MAXIMUM_UPGRADE_BALANCE_FRACTION <= 1, "Upgrade budget fraction must be in (0, 1]")
	assert(config.STATUS_UI_SETTINGS.PANEL_WIDTH_PIXELS >= 280 and config.STATUS_UI_SETTINGS.PANEL_HEIGHT_PIXELS >= 280, "Panel dimensions must be at least 280 pixels")
	for _, limit in ipairs({ config.STATUS_UI_SETTINGS.MAXIMUM_DISPLAY_ENTRIES, config.DIAGNOSTIC_SETTINGS.MAXIMUM_LOG_ENTRIES,
		config.TASK_SETTINGS.MAXIMUM_PENDING_TASKS }) do
		assert(limit >= 1 and limit % 1 == 0, "Entry and queue limits must be positive integers")
	end
	for _, value in ipairs({ config.FARMING_SETTINGS.OBSERVATION_INTERVAL_SECONDS, config.FARMING_SETTINGS.ACTION_SLICE_SECONDS,
		config.FARMING_SETTINGS.MINIMUM_RATE_SAMPLE_SECONDS, config.FARMING_SETTINGS.RATE_WINDOW_SECONDS,
		config.PICKUP_SETTINGS.COLLECTION_REFRESH_SECONDS, config.PICKUP_SETTINGS.ZONE_REFRESH_SECONDS, config.PICKUP_SETTINGS.PREFAB_REFRESH_SECONDS,
		config.PICKUP_SETTINGS.PATH_TIMEOUT_SECONDS, config.ISLAND_SETTINGS.TRAVEL_CONFIRMATION_TIMEOUT_SECONDS,
		config.ISLAND_SETTINGS.PICKUP_PROBE_TIMEOUT_SECONDS, config.ISLAND_SETTINGS.ISLAND_EXPLORATION_RETRY_SECONDS,
		config.UPGRADE_SETTINGS.PURCHASE_CONFIRMATION_TIMEOUT_SECONDS, config.BUBBLE_SETTINGS.SELL_CONFIRMATION_TIMEOUT_SECONDS }) do
		assert(value >= 1, "Farming observation, sample, slice, and timeout intervals must be at least one second")
	end
	assert(config.BUBBLE_SETTINGS.BLOW_COOLDOWN_SECONDS >= 0.5, "Native blowing cooldown must be at least 0.5 seconds")
	assert(config.UPGRADE_SETTINGS.MAXIMUM_GOAL_RESERVE_BALANCE_FRACTION <= 1, "Goal reserve balance fraction must be in [0, 1]")
	for _, key in ipairs({ "MAXIMUM_SESSION_WORLD_UNLOCKS", "MAXIMUM_UNLOCK_ATTEMPTS", "MAXIMUM_TRAVEL_ATTEMPTS", "MAXIMUM_ISLAND_DISCOVERY_ATTEMPTS" }) do
		local value = config.WORLD_SETTINGS[key]
		assert(value >= 1 and value % 1 == 0, key .. " must be a positive integer")
	end
	assert(config.WORLD_SETTINGS.ISLAND_DISCOVERY_CONTACT_SECONDS >= 0.05 and config.WORLD_SETTINGS.ISLAND_DISCOVERY_CONTACT_SECONDS <= 0.5,
		"Discovery contact duration must be in [0.05,0.5] seconds")
	assert(config.WORLD_SETTINGS.ISLAND_DISCOVERY_CONFIRMATION_TIMEOUT_SECONDS >= 1
		and config.WORLD_SETTINGS.ISLAND_DISCOVERY_CONFIRMATION_TIMEOUT_SECONDS <= 30
		and config.WORLD_SETTINGS.ISLAND_DISCOVERY_INTERVAL_SECONDS >= 10
		and config.WORLD_SETTINGS.ISLAND_DISCOVERY_RETRY_COOLDOWN_SECONDS >= 10,
		"Discovery confirmation must be in [1,30] seconds; attempt interval/retry at least ten seconds")
	assert(config.WORLD_SETTINGS.UNLOCK_CONFIRMATION_TIMEOUT_SECONDS >= 1 and config.WORLD_SETTINGS.UNLOCK_RETRY_COOLDOWN_SECONDS >= 10,
		"World unlock confirmation must be at least one second and retry at least ten seconds")
	assert(config.WORLD_SETTINGS.FUNDING_HORIZON_HOURS > 0 and config.WORLD_SETTINGS.ECONOMIC_LOG_INTERVAL_SECONDS >= 5,
		"Funding diagnostic horizon must be positive and economic log interval at least five seconds")
	assert(config.DIAGNOSTIC_SETTINGS.SUMMARY_INTERVAL_SECONDS >= 5, "Console summary interval must be at least five seconds")
	assert(config.WORLD_SETTINGS.TRAVEL_STABILIZATION_SECONDS >= 0.4
		and config.WORLD_SETTINGS.TRAVEL_STABILIZATION_SECONDS < config.ISLAND_SETTINGS.TRAVEL_CONFIRMATION_TIMEOUT_SECONDS,
		"Progression travel stabilization must fit inside the native travel confirmation window")
	assert(config.PICKUP_SETTINGS.MAXIMUM_PATH_RECOMPUTES % 1 == 0 and config.PICKUP_SETTINGS.MAXIMUM_PATH_RECOMPUTES <= 3, "Path recomputes must be an integer in [0, 3]")
	assert(config.PICKUP_SETTINGS.WAYPOINT_STALL_SECONDS >= 1 and config.PICKUP_SETTINGS.MOVE_REISSUE_SECONDS >= 1, "Movement stall and reissue intervals must be at least one second")
	assert(config.PICKUP_SETTINGS.MINIMUM_WAYPOINT_PROGRESS_STUDS > 0, "Waypoint progress threshold must be positive")
	assert(config.FARMING_SETTINGS.RATE_WINDOW_SECONDS >= config.FARMING_SETTINGS.MINIMUM_RATE_SAMPLE_SECONDS, "Rate window is smaller than the minimum sample")
	assert(config.PICKUP_SETTINGS.MAXIMUM_CLUSTER_CANDIDATES >= 1 and config.PICKUP_SETTINGS.MAXIMUM_CLUSTER_CANDIDATES % 1 == 0, "Cluster candidate limit must be a positive integer")
	assert(config.PICKUP_SETTINGS.MAXIMUM_CLUSTER_CANDIDATES <= 64, "Cluster candidate limit must not exceed 64")
	assert(config.PICKUP_SETTINGS.ZONE_MATCH_TOLERANCE_STUDS <= 2, "Zone boundary tolerance must not exceed two studs")
	assert(config.ISLAND_SETTINGS.ARRIVAL_PICKUP_GRACE_SECONDS < config.ISLAND_SETTINGS.PICKUP_PROBE_TIMEOUT_SECONDS, "Arrival grace must be smaller than the pickup trial timeout")
	local pets, hatch = config.PET_SETTINGS, config.HATCH_SETTINGS
	assert(hatch.EGG_SELECTION_MODE == "AUTO" or hatch.EGG_SELECTION_MODE == "MANUAL", "EGG_SELECTION_MODE must be AUTO or MANUAL")
	local eggTravel, playtime, boxes, idle = config.EGG_TRAVEL_SETTINGS, config.PLAYTIME_SETTINGS,
		config.MYSTERY_BOX_SETTINGS, config.ANTIAFK_SETTINGS
	assert(eggTravel.MODE == "NORMAL" or eggTravel.MODE == "TRAVEL_ONLY", "Egg travel MODE must be NORMAL or TRAVEL_ONLY")
	local allowance = config.OWNER_ONE_HATCH_TEST_SETTINGS
	assert(type(allowance.OWNER_ONE_HATCH_TEST_ALLOWANCE) == "boolean", "OWNER_ONE_HATCH_TEST_ALLOWANCE must be boolean")
	if eggTravel.MODE == "TRAVEL_ONLY" then
		local blocker = OCBrain.new(config):TravelDiagnosticBlocker()
		assert(not blocker, blocker)
	end
	if allowance.OWNER_ONE_HATCH_TEST_ALLOWANCE then
		assert(eggTravel.MODE == "NORMAL" and hatch.HATCH_ONE_EGG_ONCE and pets.AUTO_HATCH
			and hatch.EGG_SELECTION_MODE == "MANUAL" and #hatch.SELECTED_EGGS == 1,
			"Owner allowance requires an isolated ONE manual selected-egg hatch; never ordinary AUTO or TRAVEL_ONLY")
		assert(allowance.MAXIMUM_COIN_ALLOWANCE > 0 and allowance.MAXIMUM_EGG_COST > 0,
			"Owner allowance needs explicit positive Coin allowance and per-egg ceiling")
		local blocker = require(script.Parent.OwnerHatchTestAllowance).Isolation(config)
		assert(not blocker, blocker)
	end
	for _, value in ipairs({ eggTravel.ARRIVAL_TIMEOUT_SECONDS, eggTravel.STABILITY_SECONDS, eggTravel.MAXIMUM_LOCATION_SECONDS,
		playtime.CHECK_INTERVAL_SECONDS, playtime.CLAIM_INTERVAL_SECONDS, playtime.CONFIRMATION_TIMEOUT_SECONDS,
		boxes.OPEN_INTERVAL_SECONDS, boxes.CONFIRMATION_TIMEOUT_SECONDS }) do
		assert(value >= 1, "Local feature intervals and timeouts must be at least one second")
	end
	assert(eggTravel.STABILITY_SECONDS < eggTravel.ARRIVAL_TIMEOUT_SECONDS, "Egg stability window must fit inside arrival timeout")
	for _, value in ipairs({ eggTravel.MAXIMUM_ATTEMPTS_PER_SELECTION, boxes.MAXIMUM_SESSION_BOXES, boxes.MAXIMUM_BATCH_BOXES }) do
		assert(value >= 1 and value % 1 == 0, "Local feature operation limits must be positive integers")
	end
	assert(boxes.BOX_RESERVE % 1 == 0 and eggTravel.SELECTION_REVISION % 1 == 0, "Box reserve and selection revision must be integers")
	assert(type(boxes.SESSION_KEY) == "string" and #boxes.SESSION_KEY > 0 and #boxes.SESSION_KEY <= 80, "Box session key must be a bounded nonempty string")
	assert(idle.METHOD == "VIRTUAL_INPUT_SCROLL_LOCK" and idle.INTERVAL_SECONDS >= 60, "Anti-AFK requires guarded ScrollLock method and at least sixty seconds")
	assert(table.find({ "AUTO", "Coins", "Gems", "Bubbles", "Tickets", "Pearls" }, pets.OBJECTIVE_CURRENCY), "Unknown pet objective currency")
	for _, value in ipairs({ pets.MAXIMUM_SESSION_EQUIP_COMMANDS, pets.MAXIMUM_TEAM_EVALUATIONS,
		hatch.MAXIMUM_SESSION_HATCHES, hatch.MAXIMUM_BATCH_HATCHES, hatch.MAXIMUM_EGGS_ANALYZED, hatch.MAXIMUM_PLAN_CANDIDATES }) do
		assert(value >= 1 and value % 1 == 0, "Pet/hatch count and analysis limits must be positive integers")
	end
	assert(pets.MAXIMUM_TEAM_EVALUATIONS <= 1000 and hatch.MAXIMUM_EGGS_ANALYZED <= 64 and hatch.MAXIMUM_BATCH_HATCHES <= 12, "Pet analysis/batch limits exceed supported bounds")
	assert(pets.ANALYSIS_INTERVAL_SECONDS >= 5 and pets.EQUIP_CONFIRMATION_TIMEOUT_SECONDS >= 1
		and pets.MAXIMUM_EQUIP_ATTEMPT_SECONDS >= 1 and pets.MINIMUM_EQUIP_COMMAND_INTERVAL_SECONDS >= 1
		and hatch.CONFIRMATION_TIMEOUT_SECONDS >= 1 and hatch.MAXIMUM_SESSION_SECONDS >= 1
		and hatch.MINIMUM_REQUEST_INTERVAL_SECONDS >= 1, "Pet/hatch intervals must be bounded and positive")
	assert(type(hatch.PRESERVE_PROGRESSION_RESERVE) == "boolean", "PRESERVE_PROGRESSION_RESERVE must be boolean")
	assert(type(hatch.HATCH_ONE_EGG_ONCE) == "boolean" and type(hatch.LOG_EGG_DETAILS) == "boolean", "Single-hatch/detail flags must be boolean")
	assert(hatch.MAXIMUM_PLAN_CANDIDATES <= 6, "Compact egg plan supports at most six candidates")
	if hatch.HATCH_ONE_EGG_ONCE then
		local reason = require(script.Parent.PetPolicy).HatchIsolation(config)
		assert(not reason, reason)
	end
	for _, currency in ipairs(hatch.ALLOWED_CURRENCIES) do assert(table.find({ "Coins", "Gems", "Tickets", "Pearls" }, currency), "Unsupported hatch currency") end
	if pets.AUTO_HATCH or pets.AUTO_EQUIP then assert(pets.ENABLE_PET_INTELLIGENCE, "Pet actions require ENABLE_PET_INTELLIGENCE") end
	assert(type(pets.EQUIP_OWNED_TEAM_ONCE) == "boolean" and type(pets.LOG_TEAM_DETAILS) == "boolean", "Owned-team test/detail flags must be boolean")
	if pets.EQUIP_OWNED_TEAM_ONCE then
		assert(pets.AUTO_EQUIP and not pets.AUTO_HATCH and pets.OBJECTIVE_CURRENCY == "Coins", "One-time owned-team test requires explicit Coins equipment authorization and hatching OFF")
		for category, keys in pairs({
			WORLD_SETTINGS = { "ENABLE_WORLD_PROGRESSION", "AUTO_DISCOVER_ISLANDS", "AUTO_UNLOCK_WORLDS", "AUTO_TRAVEL_FOR_PROGRESSION", "AUTO_FARM_UNLOCK_REQUIREMENTS" },
			FARMING_SETTINGS = { "AUTO_RESOURCE_FARM", "AUTO_FARM_FALLBACK" },
			ISLAND_SETTINGS = { "AUTO_TRAVEL_BEST_ISLAND", "AUTO_EXPLORE_UNLOCKED_ISLANDS" },
			BUBBLE_SETTINGS = { "AUTO_BLOW_BUBBLES", "AUTO_SELL_BUBBLES", "AUTO_BUY_GUM", "AUTO_BUY_FLAVORS", "ENABLE_SIMULTANEOUS_BLOWING" },
			UPGRADE_SETTINGS = { "ENABLE_SMART_UPGRADES", "ENABLE_CAPACITY_UPGRADES", "ENABLE_FLAVOR_UPGRADES", "AUTO_EQUIP_OWNED_UPGRADES" },
		}) do
			for _, key in ipairs(keys) do assert(not config[category][key], "Equip-only test requires " .. category .. "." .. key .. " OFF") end
		end
		assert(hatch.MAXIMUM_EGG_COST == 0 and hatch.MAXIMUM_SESSION_COST == 0 and not hatch.ENABLE_BACKGROUND_PICKUPS, "Equip-only test requires zero hatch budgets and background collection OFF")
	end
	if pets.AUTO_HATCH then
		assert((hatch.EGG_SELECTION_MODE == "AUTO" or #hatch.SELECTED_EGGS > 0) and hatch.MAXIMUM_EGG_COST > 0 and hatch.MAXIMUM_SESSION_COST > 0, "Hatching requires Brain AUTO or explicit MANUAL selection and positive spending budgets")
		assert(#hatch.ALLOWED_CURRENCIES == 1, "Each bounded hatch session must authorize exactly one currency")
	end
	-- Destructive and later-phase executors remain unavailable.
	for _, category in ipairs({ "PET_SETTINGS", "FALL_EVENT_SETTINGS" }) do
		for key, value in pairs(config[category]) do
			if (key:match("^AUTO_") or key == "ENABLE_FALL_EVENT") and value and key ~= "AUTO_HATCH" and key ~= "AUTO_EQUIP" then
				error("[OC] " .. category .. "." .. key .. " is reserved; its executor is not implemented")
			end
		end
	end
end

function OCController.new(config, player)
	validate(config)
	local self = setmetatable({}, OCController)
	self.Config = config
	self.Changed = Instance.new("BindableEvent")
	self.Reader = AccountStateReader.new(config, player)
	self.Knowledge = GameKnowledge.new(self.Reader)
	self.Brain = OCBrain.new(config)
	self.Scheduler = TaskScheduler.new(config.TASK_SETTINGS)
	self.State = "STOPPED"
	self.Generation = 0
	self.Plan = nil
	self.Error = nil
	self.Destroyed = false
	self.LastPlanAt = -math.huge
	self.Connections = {}
	self.Snapshot = self.Reader:GetSnapshot()
	self.Farming = FarmingCoordinator.new(self, player)
	self.WorldProgression = WorldProgressionManager.new(self)
	self.HatchTestAllowance = OwnerHatchTestAllowance.new(self)
	self.Pets = PetManager.new(self)
	self.EggTravel = EggTravelManager.new(self)
	self.Rewards = RewardsManager.new(self)
	self.AntiAFK = AntiAFKManager.new(self)
	self.Farming.Mechanics.LocalFeatureController = self
	self.Farming.Metrics.AttributionBlockedProvider = function() return self:RewardAttributionBlocked() end
	self.Farming.Mechanics.PetLocationOwnerProvider = function()
		return self.Pets.Hatch.Location ~= nil or self.EggTravel:OwnsLocation()
	end
	table.insert(self.Connections, self.Reader.Changed.Event:Connect(function(snapshot)
		self.Snapshot = snapshot
		self.Rewards:Observe()
		self.EggTravel:Observe()
		self:_diagnoseSnapshot(snapshot)
		self:_notify()
		self:_requestPlan(false)
	end))
	table.insert(self.Connections, self.Scheduler.Changed.Event:Connect(function() self:_notify() end))
	table.insert(self.Connections, self.Scheduler.Completed.Event:Connect(function(id, status, result, reason, definition)
		if self.Destroyed or self.State ~= "RUNNING" then return end
		if id == "OC_GAMEPLAY" then
			if definition and definition.Generation == self.Generation then
				if definition.Owner == "REWARDS" then self.Rewards:Completed(status, result, reason)
				elseif definition.Owner == "EGG_TRAVEL" then self.EggTravel:Completed(status, result, reason)
				elseif definition.Owner == "ANTI_AFK" then self.AntiAFK:Completed(status, result, reason)
				elseif definition.Owner == "WORLD_PROGRESSION" then self.WorldProgression:Completed(status, result, reason)
				elseif definition.Owner == "PETS" then self.Pets:Completed(status, result, reason)
				else self.Farming:Completed(status, result, reason) end
				self.Reader:Refresh()
				self:_requestPlan(true)
			end
			return
		end
		if id ~= "ANALYZE_ACCOUNT" then return end
		if status == "COMPLETED" and type(result) == "table" and result.Generation == self.Generation then
			if result.SnapshotRevision < self.Snapshot.Revision then self:_requestPlan(true) return end
			self.Plan = result
			self.Error = nil
			self.LastPlanAt = os.clock()
			local goal = result.Objective
			if self.LastObjectiveId ~= goal.Id then
				self.LastObjectiveId = goal.Id
				self:Log("GOAL", goal.Id .. " | " .. goal.Title .. " | " .. goal.Reason)
				self:Log("PROGRESSION", result.Progression .. " | " .. result.ProgressionEvidence)
				if #goal.Prerequisites > 0 then self:Log("PREREQUISITES", table.concat(goal.Prerequisites, "; ")) end
			end
			-- Selection precedes travel: the same Brain's fresh pet decision supplies
			-- the destination, financial guard and immutable original-model identity.
			local petOwns, petDecision = self.Pets:Select(result)
			local localOwner, localDecision = self.Brain:SelectLocalFeature(self, result, petOwns, petDecision)
			local owns, decision
			if not localOwner and not petOwns then owns, decision = self.WorldProgression:Select(result) end
			local taskDefinition
			if localOwner == "PHASE4_WAIT" then
				if self.Farming.Activity then self.Farming:Halt(true) end
				-- WAIT is an analysis result, not a movement or paid task.
			elseif localOwner then
				if self.Farming.Activity then self.Farming:Halt(true) end
				local manager = ({ REWARDS = self.Rewards, EGG_TRAVEL = self.EggTravel, ANTI_AFK = self.AntiAFK })[localOwner]
				taskDefinition = manager:Definition(localDecision, self.Generation)
			elseif petOwns then
				if self.Farming.Activity then self.Farming:Halt(true) end
				taskDefinition = self.Pets:Definition(petDecision, self.Generation)
			elseif owns then
				self.Farming:Halt(true)
				taskDefinition = self.WorldProgression:Definition(decision, self.Generation)
			else
				decision = self.Farming:Select(result)
				taskDefinition = self.Farming:Definition(decision, self.Generation)
			end
			if taskDefinition then
				local accepted, errorMessage = self.Scheduler:Submit(taskDefinition)
				if not accepted then self.Error = errorMessage self:Log("FARM][ERROR", errorMessage) end
			end
		elseif status == "FAILED" then self.Error = tostring(result) self:Log("DIAGNOSTIC", self.Error)
		elseif status == "CANCELLED" and reason == "Task timed out" then self.Error = reason self:Log("DIAGNOSTIC", reason) end
		self:_notify()
	end))
	-- Reading remains available while controls are stopped; no gameplay is executed.
	self.Reader:Start()
	self.Farming:StartObservations()
	return self
end

function OCController:Log(kind, message, explicitDetail)
	local settings = self.Config.DIAGNOSTIC_SETTINGS
	if not settings.ENABLE_CONSOLE_LOGGING then return end
	message = tostring(message)
	if not settings.ENABLE_DEBUG_LOGGING and not explicitDetail then
		local immediate = kind == "INIT" or kind == "SCOPE" or kind == "CONTROL" or kind == "GOAL" or kind == "SUMMARY"
			or kind == "ISLAND][VERIFIED" or kind == "WORLD][VERIFIED" or kind == "UPGRADE][VERIFIED" or kind == "FARM][RETURN"
			or kind == "PET][ANALYSIS" or kind == "PET][VERIFIED" or kind == "PET][TEAM_PLAN" or kind == "PET][EQUIP_RESULT"
			or kind == "EGG_PLAN" or kind == "HATCH_RESULT"
			or kind == "EGG_TRAVEL" or kind == "PLAYTIME_RESULT" or kind == "BOX_RESULT" or kind == "ANTI_AFK"
			or kind == "REWARD][RESULT" or kind == "REWARD][UNCONFIRMED"
		if kind == "FARM][TRAVEL" then immediate = not message:match("^Request ") end
		local blocker = kind == "FARM][FALLBACK" or kind == "WORLD][GATE_APPROACH" or kind == "DIAGNOSTIC" or kind == "UNAVAILABLE"
			or kind:find("ERROR", 1, true) ~= nil or kind == "ISLAND][CONTACT" or kind == "PET][BLOCKER"
		if kind == "WORLD][DECISION" then blocker = message:match("^WAIT ") ~= nil end
		if kind == "WORLD][RESULT" then
			immediate = message:find("Native portal arrival stabilized", 1, true) ~= nil
			blocker = not immediate and message:find("Actual LocalData", 1, true) == nil
		end
		if kind == "DEPENDENCY" then blocker = message:find("=ERROR", 1, true) ~= nil end
		if kind == "PICKUP][CLEANUP_ERROR" then message = message:gsub("^id=[^|]+ | ", "") end
		if kind == "WORLD][BOTTLENECK" then
			blocker = true message = "Estimated funding time exceeds the configured horizon; earning-power review needed. Recommendations do not authorize purchases."
		end
		if not immediate and not blocker then return end
		if blocker and not immediate then
			self.ConsoleBlockers = self.ConsoleBlockers or {}
			local previous, now = self.ConsoleBlockers[kind], os.clock()
			if previous and previous.Message == message and now - previous.At < math.max(60, settings.MINIMUM_LOG_INTERVAL_SECONDS) then return end
			self.ConsoleBlockers[kind] = { Message = message, At = now } -- One record per existing diagnostic category, not per pickup ID.
		end
	end
	print("[OC][" .. kind .. "] " .. message)
end

function OCController:_reportSummary(status, now)
	local settings = self.Config.DIAGNOSTIC_SETTINGS
	if not settings.ENABLE_CONSOLE_LOGGING or settings.ENABLE_DEBUG_LOGGING then self.SummaryPrevious = nil return end
	local previous = self.SummaryPrevious
	if previous and now - previous.At < settings.SUMMARY_INTERVAL_SECONDS then return end
	local balances = status.Snapshot and status.Snapshot.Balances or {}
	self.SummaryPrevious = { At = now, Balances = table.clone(balances) }
	if not previous then return end -- Establish a baseline; never invent initial interval earnings.
	local ok, output = pcall(AccountPresentation.Summary, status, previous, now, self.Config)
	self:Log(ok and "SUMMARY" or "CONSOLE][ERROR", ok and output or "Summary formatting unavailable: " .. tostring(output))
end

function OCController:PrintPetTeam()
	return self.Pets:PrintTeam()
end

function OCController:PrintAccount(limit)
	if not self.Config.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING then return false, "Console logging is disabled" end
	limit = limit or self.Config.DIAGNOSTIC_SETTINGS.MAXIMUM_LOG_ENTRIES
	assert(type(limit) == "number" and limit >= 1 and limit % 1 == 0, "PrintAccount limit must be a positive integer")
	local snapshot = self.Reader:GetSnapshot()
	self:Log("ACCOUNT", "Status=" .. snapshot.Status .. "; Ready=" .. tostring(snapshot.Ready) .. "; Revision=" .. snapshot.Revision, true)
	if snapshot.Source then self:Log("SOURCE", snapshot.Source, true) end
	local sections = AccountPresentation.Sections(snapshot, self.Config, limit)
	for _, name in ipairs({ "Balances", "Pets", "Inventory", "Worlds", "Upgrades", "Mastery" }) do
		self:Log(string.upper(name), "\n" .. sections[name], true)
	end
	for _, diagnostic in ipairs(snapshot.Diagnostics or {}) do self:Log("DIAGNOSTIC", diagnostic, true) end
	if snapshot.UnavailableFields and #snapshot.UnavailableFields > 0 then
		self:Log("UNAVAILABLE", table.concat(snapshot.UnavailableFields, ", "), true)
	end
	return true
end

function OCController:_diagnoseSnapshot(snapshot)
	local settings = self.Config.DIAGNOSTIC_SETTINGS
	if not settings.ENABLE_CONSOLE_LOGGING then return end
	self.LastDependencies = self.LastDependencies or {}
	if settings.LOG_DEPENDENCIES then
		for name, entry in pairs(snapshot.Dependencies or {}) do
			local description = entry.Status .. (entry.Error and " | " .. entry.Error or "")
			if self.LastDependencies[name] ~= description then
				self.LastDependencies[name] = description
				self:Log("DEPENDENCY", name .. "=" .. description .. " | " .. entry.Path)
			end
		end
	end
	if self.LastAccountStatus ~= snapshot.Status then
		self.LastAccountStatus = snapshot.Status
		self:Log("ACCOUNT", "Status=" .. snapshot.Status .. "; Ready=" .. tostring(snapshot.Ready))
		for _, message in ipairs(snapshot.Diagnostics or {}) do self:Log("DIAGNOSTIC", message) end
	end
	if not snapshot.Ready then return end
	if not settings.ENABLE_DEBUG_LOGGING then return end -- Only presentation: full account formatting is unnecessary in summary mode.
	if self.AccountLogThread then return end
	local delaySeconds = math.max(0, settings.MINIMUM_LOG_INTERVAL_SECONDS - (os.clock() - (self.LastAccountLogAt or -math.huge)))
	self.AccountLogThread = task.delay(delaySeconds, function()
		self.AccountLogThread = nil
		if self.Destroyed then return end
		if not settings.ENABLE_DEBUG_LOGGING then return end
		local latest = self.Reader:GetSnapshot()
		local sections = AccountPresentation.Sections(latest, self.Config, settings.MAXIMUM_LOG_ENTRIES)
		local summary = latest.Status .. "\n" .. sections.Balances
		if settings.LOG_ACCOUNT_DETAILS then
			for _, name in ipairs({ "Pets", "Inventory", "Worlds", "Upgrades", "Mastery" }) do summary ..= "\n" .. sections[name] end
		end
		if self.LastLoggedAccount ~= summary then
			self.LastLoggedAccount = summary
			self.LastAccountLogAt = os.clock()
			if settings.LOG_ACCOUNT_DETAILS then self:PrintAccount()
			else self:Log("BALANCES", sections.Balances) end
		end
	end)
end

function OCController:GetStatus()
	return { State = self.State, Snapshot = self.Reader:GetSnapshot(), Plan = self.Plan,
		Scheduler = self.Scheduler:GetStatus(), Farming = self.Farming:GetStatus(), WorldProgression = self.WorldProgression:GetStatus(),
		Pets = self.Pets and self.Pets:GetStatus(), Error = self.Error,
		EggTravel = self.EggTravel and self.EggTravel:GetStatus(), Rewards = self.Rewards and self.Rewards:GetStatus(),
		AntiAFK = self.AntiAFK and self.AntiAFK:GetStatus(),
		OwnerHatchTestAllowance = self.HatchTestAllowance and self.HatchTestAllowance:GetStatus(),
		Phase = self.Config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE and 4 or self.Config.WORLD_SETTINGS.ENABLE_WORLD_PROGRESSION and 3 or 2 }
end

function OCController:_notify()
	if not self.Destroyed then
		local status = self:GetStatus()
		self:_reportSummary(status, os.clock())
		self.Changed:Fire(status)
	end
end

function OCController:_cancelReplan()
	if self.ReplanThread then pcall(task.cancel, self.ReplanThread) self.ReplanThread = nil end
end

function OCController:_requestPlan(force)
	if self.Destroyed or self.State ~= "RUNNING" then return end
	if force then self:_cancelReplan() end
	if self.ReplanThread then return end
	local delaySeconds = force and 0 or math.max(0, self.Config.GENERAL_SETTINGS.REPLAN_COOLDOWN_SECONDS - (os.clock() - self.LastPlanAt))
	local generation = self.Generation
	self.ReplanThread = task.delay(delaySeconds, function()
		self.ReplanThread = nil
		if self.Destroyed or self.State ~= "RUNNING" or generation ~= self.Generation then return end
		local snapshot = self.Reader:GetSnapshot()
		local accepted, reason = self.Scheduler:Submit({
			Id = "ANALYZE_ACCOUNT", Priority = 100,
			CanRun = function() return self.State == "RUNNING" and generation == self.Generation end,
			Execute = function(token)
				local result = self.Brain:Plan(snapshot, token)
				if result then result.Generation = generation end
				return result
			end,
			IsComplete = function(result) return type(result) == "table" and result.Objective ~= nil end,
		})
		if not accepted then self.Error = reason self:_notify() end
	end)
end

function OCController:Start()
	if self.Destroyed then return false, "Controller was destroyed" end
	if not self.Config.GENERAL_SETTINGS.OC_ENABLED then return false, "OC is disabled in OCConfig" end
	if not self.Config.ACCOUNT_SETTINGS.ENABLE_ACCOUNT_READER then return false, "Account reading is disabled" end
	if not self.Config.TASK_SETTINGS.ENABLE_TASK_SCHEDULER then return false, "Task scheduler is disabled" end
	if self.State == "RUNNING" then return true end
	if self.State == "PAUSED" then return self:Resume() end
	self.Generation += 1
	self.State = "RUNNING"
	self.Error = nil
	self.AntiAFK:Resume()
	self.Brain:Reset()
	self.LastObjectiveId = nil
	self.Reader:Refresh()
	self.Scheduler:Resume()
	self:_requestPlan(true)
	self:_notify()
	self:Log("CONTROL", "START | account analysis and Brain-selected tasks enabled by Config | phase=" .. tostring(self:GetStatus().Phase))
	return true
end

function OCController:Pause()
	if self.Destroyed or self.State ~= "RUNNING" then return false, "OC is not running" end
	self.Generation += 1
	self.State = "PAUSED"
	self:_cancelReplan()
	self.Scheduler:Pause()
	self.Farming:Halt(true)
	self.WorldProgression:Halt()
	self.Pets:Halt()
	self.EggTravel:Halt(false)
	self.Rewards:Halt(false)
	self.AntiAFK:Halt("Paused")
	self:_notify()
	self:Log("CONTROL", "PAUSE | recommendations paused; read-only account updates remain visible")
	return true
end

function OCController:Resume()
	if self.Destroyed or self.State ~= "PAUSED" then return false, "OC is not paused" end
	self.Generation += 1
	self.State = "RUNNING"
	self.AntiAFK:Resume()
	self.Reader:Refresh()
	self.Scheduler:Resume()
	self:_requestPlan(true)
	self:_notify()
	self:Log("CONTROL", "RESUME | selecting from a fresh account snapshot")
	return true
end

function OCController:Stop()
	if self.Destroyed then return false end
	self.Generation += 1
	self.State = "STOPPED"
	self:_cancelReplan()
	self.Scheduler:Stop()
	self.Farming:Halt()
	self.WorldProgression:Halt()
	self.Pets:Halt(true)
	self.EggTravel:Halt(true)
	self.Rewards:Halt(true)
	self.Farming.Mechanics:CancelRewardTransport()
	self.AntiAFK:Halt("Stopped")
	self.Plan = nil
	self.Error = nil
	self.Brain:Reset()
	self.LastObjectiveId = nil
	self:_notify()
	self:Log("CONTROL", "STOP | objective and pending analysis cleared; account reader remains available")
	return true
end

function OCController:Destroy()
	if self.Destroyed then return end
	self:Stop()
	self.Destroyed = true
	if self.AccountLogThread then pcall(task.cancel, self.AccountLogThread) end
	if self.Interface then self.Interface:Destroy() end
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	self.Reader:Destroy()
	self.Farming:Destroy()
	self.EggTravel:Destroy()
	self.Rewards:Destroy()
	self.AntiAFK:Destroy()
	self.Scheduler:Destroy()
	self.Changed:Destroy()
	self:Log("CONTROL", "DESTROY | panel, subscriptions, and reader cleaned up")
end

function OCController:MarkNonPickupReward(pending)
	self.RewardAttributionEpoch = (self.RewardAttributionEpoch or 0) + 1
	self.RewardQuietUntil = math.max(self.RewardQuietUntil or 0, os.clock() + 10)
	self.LastNonPickupReward = pending and pending.Kind or "REWARD_OPERATION"
	-- Discard overlapping models. Known pending/settling credits never become pickup income; later external grants remain uncertain.
	self.Farming.Metrics.Samples = {}
	self.Farming.Metrics.Active = nil
	self.Farming.Metrics.Last = { At = os.clock(), Balances = self.Reader:ReadBalances() }
	self.Farming.PickupEvidence = {}
	self.Farming.Cycle = nil
	self.Farming.Stationary.LastSampleAt = nil
	self.Farming.Stationary.LastSampleArea = nil
end

function OCController:RewardAttributionBlocked()
	return os.clock() < (self.RewardQuietUntil or 0)
		or self.Rewards and self.Rewards.AttributionBlocked and self.Rewards:AttributionBlocked() == true
end

return OCController

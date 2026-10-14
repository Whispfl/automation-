-- Phase 5 remote one-spin candidate. Authorization remains OFF; this loader only reads preflight facts.
-- Preserve an existing action/uncertain receipt before initializing another controller.
local previous = type(shared) == "table" and shared.__OC_PHASE1_INSTANCE
if previous and (previous.State ~= "STOPPED" or previous.Rewards and previous.Rewards:AttributionBlocked()) then
	print("[OC][WHEEL_REMOTE_PREFLIGHT] BLOCKED | Prior OC is active or retains an uncertain reward; do not replace it or retry")
	return previous
end
local Config = {
	WHEEL_SPIN_SETTINGS = { AUTO_SPIN_WHEEL = false, OWNER_ONE_SPIN_ALLOWANCE = false,
		ALLOW_REMOTE_WHEEL_TEST = true,
		AUTHORIZED_ACCOUNT_ID = 0, AUTHORIZED_TEST_ID = "", OWNER_CONFIRMED_WHEEL_IDLE = false },
	FREE_WHEEL_TICKET_SETTINGS = { ENABLE_FREE_WHEEL_TICKET_CLAIM = false, AUTHORIZED_ACCOUNT_ID = 0,
		AUTHORIZED_TEST_ID = "", OWNER_CONFIRMED_WHEEL_IDLE = false },
	GENERAL_SETTINGS = { OC_ENABLED = true, AUTO_START = false, ENABLE_RECOMMENDATIONS = false },
	REWARD_INTELLIGENCE_SETTINGS = { ENABLE_REWARD_INTELLIGENCE = false },
	MASTERY_SETTINGS = { ENABLE_MASTERY_INTELLIGENCE = false },
	BRAIN_SETTINGS = { ENABLE_EARNING_RECOMMENDATIONS = false, ENABLE_WORLD_RECOMMENDATIONS = false,
		ENABLE_MASTERY_RECOMMENDATIONS = false, ENABLE_INVENTORY_RECOMMENDATIONS = false },
	PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = false, OBJECTIVE_CURRENCY = "Coins", AUTO_HATCH = false,
		AUTO_EQUIP = false, EQUIP_OWNED_TEAM_ONCE = false, AUTO_DELETE_PETS = false,
		AUTO_CRAFT_SHINY = false, AUTO_FUSE_PETS = false, MAXIMUM_SESSION_EQUIP_COMMANDS = 1,
		MAXIMUM_TEAM_EVALUATIONS = 1000 },
	HATCH_SETTINGS = { EGG_SELECTION_MODE = "MANUAL", SELECTED_EGGS = { "Common Egg" }, HATCH_ONE_EGG_ONCE = false,
		ALLOWED_CURRENCIES = { "Coins" }, MAXIMUM_EGG_COST = 0, MAXIMUM_SESSION_COST = 0,
		MAXIMUM_SESSION_HATCHES = 1, MAXIMUM_BATCH_HATCHES = 1,
		PRESERVE_PROGRESSION_RESERVE = true, ENABLE_BACKGROUND_PICKUPS = false },
	OWNER_ONE_HATCH_TEST_SETTINGS = { OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST = false,
		OWNER_ONE_HATCH_TEST_ALLOWANCE = false, AUTHORIZED_ACCOUNT_ID = 0,
		MAXIMUM_COIN_ALLOWANCE = 0, MAXIMUM_EGG_COST = 0 },
	EGG_TRAVEL_SETTINGS = { MODE = "NORMAL", OWNER_DIRECT_EGG_TELEPORT_TEST = false,
		ENABLE_SELECTED_EGG_TRAVEL = false,
		ENABLE_NATIVE_ISLAND_TRAVEL = false, ENABLE_DIRECT_POSITIONING = false,
		MAXIMUM_ATTEMPTS_PER_SELECTION = 1, SELECTION_REVISION = 0 },
	WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false,
		AUTO_UNLOCK_WORLDS = false, AUTO_TRAVEL_FOR_PROGRESSION = false,
		AUTO_FARM_UNLOCK_REQUIREMENTS = false, MAXIMUM_WORLD_UNLOCK_COST = 0 },
	FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false },
	ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
	PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false, STATIONARY_ISOLATED_TEST = false,
		ENABLE_CONTINUOUS_SCANNING = false },
	BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false,
		AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
	UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false,
		ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false, MAXIMUM_PURCHASE_COST = 0 },
	PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = false },
	MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = false, ENABLE_AUTOMATIC_CONTINUATION = false },
	ANTIAFK_SETTINGS = { ENABLE_ANTI_AFK = false },
	FALL_EVENT_SETTINGS = { ENABLE_FALL_EVENT = false, AUTO_REBIRTH = false,
		AUTO_BUY_REBIRTH_UPGRADES = false, AUTO_USE_FALL_ELIXIRS = false, AUTO_BUY_AUTUMN_SHOP_ITEMS = false },
	STATUS_UI_SETTINGS = { ENABLE_STATUS_UI = false },
	DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false, ENABLE_DEBUG_LOGGING = false,
		LOG_ACCOUNT_DETAILS = false, LOG_DEPENDENCIES = false,
		SUMMARY_INTERVAL_SECONDS = 15 },
}


local OC = loadstring(game:HttpGet("https://raw.githubusercontent.com/Whispfl/automation-/phase5-wheel-spin-remote-c43d84fc5121/dist/OC.lua"))()(Config)
local function readPreflight()
	if OC.Destroyed or OC.State ~= "STOPPED" or OC.Scheduler.Active ~= nil then return nil, "Stopped controller required" end
	local s = OC.Config.WHEEL_SPIN_SETTINGS
	if s.AUTO_SPIN_WHEEL ~= false or s.OWNER_ONE_SPIN_ALLOWANCE ~= false or s.AUTHORIZED_ACCOUNT_ID ~= 0
		or s.AUTHORIZED_TEST_ID ~= "" or s.OWNER_CONFIRMED_WHEEL_IDLE ~= false or s.ALLOW_REMOTE_WHEEL_TEST ~= true then return nil, "Spin authorization must remain OFF" end
	local manager = OC.Rewards
	if not manager or manager.Destroyed or manager.UnknownBarrier or not manager.Ledger then return nil, manager and manager.Blocker or "Account ledger unavailable" end
	if manager:AttributionBlocked() or OC:RewardAttributionBlocked() then return nil, "Existing pending reward or uncertain attribution; no retry" end
	local extension = manager.Ledger.WheelSpin
	for _, record in pairs(extension and extension.Tests or {}) do
		if record.Attempts ~= 0 then return nil, "One-spin allowance already consumed; do not rerun" end
	end
	local context, reason = manager:GetWheelSpinContext(false)
	if not context then return nil, reason end
	if context.TicketCount < 1 then return nil, "No owned Spin Ticket; no purchase fallback" end
	if OC.Destroyed or OC.State ~= "STOPPED" or OC.Scheduler.Active ~= nil then return nil, "Controller changed during observation" end
	return context
end
print("[OC][WHEEL_REMOTE_PREFLIGHT] READ_ONLY | controller=STOPPED | spin authorization=OFF")
local context, reason
for observation = 1, 15 do
	local ok, value, blocker = pcall(readPreflight)
	if ok then context, reason = value, blocker else context, reason = nil, "Native read-only observation failed: " .. tostring(value) end
	if context or OC.Destroyed or OC.State ~= "STOPPED" then break end
	if observation < 15 then task.wait(1) end
end
if context then
	print("[OC][WHEEL_REMOTE_PREFLIGHT] READY_FOR_SEPARATE_AUTHORIZATION | owned Spin Tickets=" .. tostring(context.TicketCount) .. "; initialized native wheel/access/idle verified; UI open=" .. tostring(context.WheelUIOpen) .. "; distance=" .. string.format("%.2f", context.WheelDistance or 0) .. "; remote server acceptance=UNKNOWN; queue=UNKNOWN")
else
	print("[OC][WHEEL_REMOTE_PREFLIGHT] BLOCKED | " .. tostring(reason or "Native observations unavailable"))
end
print("[OC][WHEEL_REMOTE_PREFLIGHT] spin requests=0 | queue calls=0 | ticket consumption=0 | purchases/spending/other actions=OFF")
OC.WheelSpinPreflight = { Ready = context ~= nil, Blocker = reason, QueueState = "UNKNOWN", ActionsAuthorized = false,
	RemoteTest = true, BuildId = "c43d84fc5121" }
return OC

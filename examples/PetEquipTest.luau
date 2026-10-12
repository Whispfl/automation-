-- Test B: OWNER-AUTHORIZED one-time owned Coins-team equipment attempt.
-- Running THIS configuration authorizes equipment changes only; no spending/gameplay.
-- Test A (examples/Pets.luau) remains the default analysis-only configuration.
local Config = {
	GENERAL_SETTINGS = { OC_ENABLED = true, AUTO_START = true, ENABLE_RECOMMENDATIONS = true },
	ACCOUNT_SETTINGS = { ENABLE_ACCOUNT_READER = true, READ_PET_INVENTORY = true, READ_UNLOCKS = true },
	PET_SETTINGS = {
		ENABLE_PET_INTELLIGENCE = true,
		OBJECTIVE_CURRENCY = "Coins", -- This bounded equip-only test validates the Coins role.
		SELECTED_PETS = {}, PROTECTED_PET_IDS = {}, FAVORITE_PET_IDS = {}, VALUABLE_PET_IDS = {},
		AUTO_HATCH = false, AUTO_EQUIP = true,
		EQUIP_OWNED_TEAM_ONCE = true, LOG_TEAM_DETAILS = true,
		MAXIMUM_SESSION_EQUIP_COMMANDS = 16, MAXIMUM_TEAM_EVALUATIONS = 1000,
		MAXIMUM_EQUIP_ATTEMPT_SECONDS = 120, MINIMUM_EQUIP_COMMAND_INTERVAL_SECONDS = 1,
		ANALYSIS_INTERVAL_SECONDS = 15, EQUIP_CONFIRMATION_TIMEOUT_SECONDS = 10,
		AUTO_DELETE_PETS = false, AUTO_CRAFT_SHINY = false, AUTO_FUSE_PETS = false,
	},
	HATCH_SETTINGS = {
		SELECTED_EGGS = {}, ALLOWED_CURRENCIES = { "Coins" },
		MAXIMUM_EGG_COST = 0, MAXIMUM_SESSION_COST = 0,
		MAXIMUM_SESSION_HATCHES = 1, MAXIMUM_BATCH_HATCHES = 1, MAXIMUM_SESSION_SECONDS = 60,
		MINIMUM_REQUEST_INTERVAL_SECONDS = 5, CONFIRMATION_TIMEOUT_SECONDS = 15,
		PRESERVE_PROGRESSION_RESERVE = true, ENABLE_BACKGROUND_PICKUPS = false, MAXIMUM_EGGS_ANALYZED = 40,
	},
	WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false,
		AUTO_FARM_UNLOCK_REQUIREMENTS = false, AUTO_UNLOCK_WORLDS = false, AUTO_TRAVEL_FOR_PROGRESSION = false },
	BRAIN_SETTINGS = { ENABLE_MASTERY_RECOMMENDATIONS = false, SELECTED_WORLDS = { "The Overworld" } },
	FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false },
	ISLAND_SETTINGS = { SELECTED_ISLANDS = { "The Void", "Zen" }, AUTO_SELECT_BEST_ISLAND = false,
		AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
	PICKUP_SETTINGS = { COLLECTION_METHOD = "STATIONARY", STATIONARY_ISOLATED_TEST = false,
		BULK_COLLECT_PICKUPS = true, ENABLE_CONTINUOUS_SCANNING = true,
		STATIONARY_MAXIMUM_BATCH_SIZE = 32, STATIONARY_REQUEST_COOLDOWN_SECONDS = 0.05, STATIONARY_BATCH_COOLDOWN_SECONDS = 1 },
	BUBBLE_SETTINGS = { ENABLE_BUBBLE_RECOMMENDATIONS = false, AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false,
		AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
	UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false,
		ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false },
	FALL_EVENT_SETTINGS = { ENABLE_FALL_EVENT = false },
	STATUS_UI_SETTINGS = { ENABLE_STATUS_UI = true },
	DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = true, ENABLE_DEBUG_LOGGING = false, SUMMARY_INTERVAL_SECONDS = 15 },
}

local OC = loadstring(game:HttpGet("https://raw.githubusercontent.com/Whispfl/automation-/main/dist/OC.lua"))()(Config)
-- Controls: OC:Pause(), OC:Resume(), OC:Stop(). Full estimates: OC:GetStatus().Pets.Analysis
-- Fill PROTECTED_PET_IDS / FAVORITE_PET_IDS / VALUABLE_PET_IDS before running.
-- One frozen team attempt: exact acknowledgements, <=16 requests, <=120 wall-clock seconds.
-- Stop ends this attempt permanently. Pause/Resume retains its deadline and command ledger.
-- Re-running this loader creates a NEW authorized attempt. OC:PrintPetTeam() shows details.
-- Manual movement is allowed. Native egg models may need to stream in near an egg.

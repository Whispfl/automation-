-- Phase 3 integrated discovery -> verified world shortage -> stationary farming.
-- Current LocalData acknowledgement is checked; saved persistence requires an owner rejoin test.
local Config = {
	GENERAL_SETTINGS = { OC_ENABLED = true, AUTO_START = true, ENABLE_RECOMMENDATIONS = true },
	WORLD_SETTINGS = {
		ENABLE_WORLD_PROGRESSION = true,
		ENABLE_ECONOMIC_DIAGNOSTICS = true,
		FUNDING_HORIZON_HOURS = 24, -- Diagnostic threshold only; farming has no experiment expiry.
		ECONOMIC_LOG_INTERVAL_SECONDS = 30,
		AUTO_DISCOVER_ISLANDS = true,
		ISLAND_DISCOVERY_CONTACT_SECONDS = 0.1,
		ISLAND_DISCOVERY_CONFIRMATION_TIMEOUT_SECONDS = 10,
		ISLAND_DISCOVERY_INTERVAL_SECONDS = 10,
		ISLAND_DISCOVERY_RETRY_COOLDOWN_SECONDS = 30,
		MAXIMUM_ISLAND_DISCOVERY_ATTEMPTS = 2,
		SELECTED_WORLDS = {}, -- All permanent native worlds, with observed gate-origin dependencies.
		AUTO_FARM_UNLOCK_REQUIREMENTS = true, -- Farm only the active world's actual native-cost shortage.
		AUTO_UNLOCK_WORLDS = false, -- Edit to true only when authorizing your chosen live world unlock.
		MAXIMUM_WORLD_UNLOCK_COST = 0, -- Set an explicit authorized ceiling in native currency units, alongside AUTO_UNLOCK_WORLDS.
		AUTO_TRAVEL_FOR_PROGRESSION = false, -- Separate opt-in for already-discovered native gate-island portal travel.
		ALLOWED_UNLOCK_CURRENCIES = { "Coins", "Gems" },
		MAXIMUM_SESSION_WORLD_UNLOCKS = 1, -- Includes uncertain requests; survives Pause/Resume/Stop in this loaded controller.
		MAXIMUM_UNLOCK_ATTEMPTS = 2,
		MAXIMUM_TRAVEL_ATTEMPTS = 2,
		UNLOCK_CONFIRMATION_TIMEOUT_SECONDS = 8,
		UNLOCK_RETRY_COOLDOWN_SECONDS = 60,
		TRAVEL_STABILIZATION_SECONDS = 1,
	},
	BRAIN_SETTINGS = { SELECTED_WORLDS = { "The Overworld" }, ENABLE_MASTERY_RECOMMENDATIONS = false },
	FARMING_SETTINGS = { AUTO_RESOURCE_FARM = true, FARMING_STRATEGY = "PICKUP_FIRST",
		ENABLE_EFFICIENCY_COMPARISON = false, ENABLE_ACTIVITY_SWITCHING = false, AUTO_FARM_FALLBACK = false },
	ISLAND_SETTINGS = { SELECTED_ISLANDS = { "The Void", "Zen" }, PREFERRED_FARMING_ISLAND = "",
		AUTO_SELECT_BEST_ISLAND = true, AUTO_TRAVEL_BEST_ISLAND = true, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
	PICKUP_SETTINGS = { COLLECTION_METHOD = "STATIONARY", STATIONARY_ISOLATED_TEST = false,
		ENABLE_NATIVE_REGISTRY_DISCOVERY = true, ENABLE_CHUNKER_DISCOVERY = true, ENABLE_CONTINUOUS_SCANNING = true,
		BULK_COLLECT_PICKUPS = true, STATIONARY_MAXIMUM_BATCH_SIZE = 32, STATIONARY_REQUEST_COOLDOWN_SECONDS = 0.05,
		STATIONARY_BATCH_COOLDOWN_SECONDS = 1, STATIONARY_ID_RETRY_SECONDS = 15, STATIONARY_MAXIMUM_ATTEMPTS_PER_ID = 2 },
	BUBBLE_SETTINGS = { ENABLE_BUBBLE_RECOMMENDATIONS = false, AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false,
		AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
	UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false,
		ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false },
	STATUS_UI_SETTINGS = { ENABLE_STATUS_UI = true },
	DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = true, ENABLE_DEBUG_LOGGING = false, SUMMARY_INTERVAL_SECONDS = 15,
		LOG_ACCOUNT_DETAILS = true, LOG_DEPENDENCIES = true }, -- Existing detail controls apply when ENABLE_DEBUG_LOGGING=true.
}

local OC = loadstring(game:HttpGet("https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"))()(Config)
-- OC:Pause(), OC:Resume(), OC:Stop(); OC:GetStatus().Snapshot.ProgressionGraph

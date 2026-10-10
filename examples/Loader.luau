-- Phase 2 test configuration. Omitted settings inherit the central OCConfig defaults.
local Config = {
	BRAIN_SETTINGS = { SELECTED_WORLDS = { "The Overworld" } }, --// Restrict the next farming test to this world.
	GENERAL_SETTINGS = {
		OC_ENABLED = true, --// Permit initialization and controls.
		AUTO_START = true, --// Start account analysis and enabled farming tasks.
	},
	ACCOUNT_SETTINGS = {
		ENABLE_ACCOUNT_READER = true, --// Read the game's real LocalData profile.
		READ_UPGRADES = true, --// Read actual owned gum and flavors.
		READ_MASTERY = true, --// Preserve Mastery statistics and recommendations.
		READ_UNLOCKS = true, --// Require actual world and island unlocks for travel.
	},
	FARMING_SETTINGS = {
		AUTO_RESOURCE_FARM = true, --// Enable Brain-coordinated resource farming.
		ENABLE_EFFICIENCY_COMPARISON = true, --// Measure and compare target-currency earnings.
		ENABLE_ACTIVITY_SWITCHING = true, --// Adapt when yields or availability change.
		AUTO_FARM_FALLBACK = true, --// Use another useful supported activity when needed.
		CURRENCY_PRIORITIES = { "Coins", "Gems", "Tickets", "Pearls" }, --// Fallback priorities; an unmet goal's currency takes precedence.
	},
	ISLAND_SETTINGS = {
		AUTO_EXPLORE_UNLOCKED_ISLANDS = true, --// Try supported unlocked pickup islands before settling on bubble farming.
		ISLAND_EXPLORATION_RETRY_SECONDS = 300, --// Bound retries of empty, failed or previously sampled islands.
		PICKUP_PROBE_TIMEOUT_SECONDS = 45, --// End an isolated pickup trial if an adequate sample is not obtained.
		AUTO_SELECT_BEST_ISLAND = true, --// Rank already unlocked, scene-present candidates.
		AUTO_TRAVEL_BEST_ISLAND = true, --// Use verified native island/sell teleport destinations.
		SELECTED_ISLANDS = { "The Void", "Zen" }, --// Only these actually unlocked islands are farming destinations.
		MIN_ISLAND_GAIN_ADVANTAGE_PERCENT = 25, --// Require a meaningful improvement to switch.
		MIN_ISLAND_DWELL_SECONDS = 60, --// Avoid rapidly switching viable islands.
	},
	PICKUP_SETTINGS = {
		ENABLE_NATIVE_REGISTRY_DISCOVERY = true, --// Read the actual loaded pickup ID-to-Model registry.
		ENABLE_CHUNKER_DISCOVERY = true, --// Observe native chunk parents rather than depend on the empty initial folder.
		BULK_COLLECT_PICKUPS = true, --// Use native radius clusters; no island-wide batch API was found.
		ENABLE_CLUSTER_ROUTING = true, --// Walk to dense reachable clusters as the supported fallback.
		FARM_CURRENCY_TYPES = {}, --// Empty allows all detected currency types, including live island currencies.
		COLLECTION_REFRESH_SECONDS = 1, --// Bound scans and subsequent collection cycles.
	},
	BUBBLE_SETTINGS = {
		AUTO_BLOW_BUBBLES = true, --// Allow bubble farming when the Brain selects it.
		AUTO_SELL_BUBBLES = true, --// Use accessible native selling activations.
		ENABLE_SIMULTANEOUS_BLOWING = true, --// Test blowing during collection when game guards permit it.
		SELL_AT_CAPACITY_RATIO = 0.95, --// Sell at this fraction of actual capacity.
		AUTO_BUY_GUM = false, --// Keep spending disabled during combined farming verification.
		AUTO_BUY_FLAVORS = false, --// Keep spending disabled during combined farming verification.
	},
	UPGRADE_SETTINGS = {
		ENABLE_SMART_UPGRADES = false, --// Keep upgrade execution disabled during farming verification.
		ENABLE_CAPACITY_UPGRADES = false, --// Keep gum purchases disabled during this test.
		ENABLE_FLAVOR_UPGRADES = false, --// Keep flavor purchases disabled during this test.
		AUTO_EQUIP_OWNED_UPGRADES = false, --// Preserve current equipment during farming comparisons.
		ENABLE_GOAL_RESERVATION = true, --// Protect important world/Mastery goal funds.
		MAXIMUM_PURCHASE_COST = 1000000, --// Per-purchase currency cap.
		MAXIMUM_PAYBACK_SECONDS = 300, --// Maximum conservative estimated payback.
	},
	RESOURCE_SETTINGS = {
		COIN_RESERVE = 0, --// Additional coins to preserve.
		GEM_RESERVE = 0, --// Additional gems to preserve.
		TICKET_RESERVE = 0, --// Additional tickets to preserve.
		PEARL_RESERVE = 0, --// Additional pearls to preserve.
		MAXIMUM_UPGRADE_BALANCE_FRACTION = 0.25, --// Spend at most this fraction after reserves.
	},
	STATUS_UI_SETTINGS = {
		ENABLE_STATUS_UI = true, --// Retain all Phase 1 statistics and controls.
		SHOW_FARMING = true, --// Show the selected activity, area and collection outcome.
		SHOW_FARMING_RATES = true, --// Show observed per-currency earnings and sample duration.
		SHOW_ISLAND_CANDIDATES = true, --// Identify measured and estimated candidate yields.
	},
	DIAGNOSTIC_SETTINGS = {
		LOG_ISLAND_DISCOVERY = true, --// Explain island unlocks, zone mapping and exclusion reasons.
		ENABLE_CONSOLE_LOGGING = true, --// Print useful [OC] test diagnostics.
		LOG_ACCOUNT_DETAILS = false, --// Keep farming logs compact; account details remain in the UI.
	},
}

loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"
))()(Config)

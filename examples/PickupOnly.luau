-- Temporary Phase 2 isolation test. Omitted settings inherit OCConfig defaults.
local Config = {
	GENERAL_SETTINGS = {
		OC_ENABLED = true, --// Enable OC controls.
		AUTO_START = true, --// Start the enabled account and farming tasks.
	},
	FARMING_SETTINGS = {
		AUTO_RESOURCE_FARM = true, --// Allow the Brain to schedule pickup work.
		ENABLE_EFFICIENCY_COMPARISON = true, --// Measure actual pickup earnings.
		ENABLE_ACTIVITY_SWITCHING = true, --// Allow bounded exploration and replanning.
	},
	ISLAND_SETTINGS = {
		AUTO_SELECT_BEST_ISLAND = true, --// Rank supported unlocked islands.
		AUTO_TRAVEL_BEST_ISLAND = true, --// Use the working native island teleport interface.
		AUTO_EXPLORE_UNLOCKED_ISLANDS = true, --// Test unknown pickup yields.
		SELECTED_ISLANDS = { "Floating Island", "Outer Space" }, --// Focus this test on the two reported islands; empty allows all.
		MIN_ISLAND_DWELL_SECONDS = 5, --// Short test dwell before considering another island.
		ARRIVAL_PICKUP_GRACE_SECONDS = 3, --// Keep scanning while rendered assets load.
		PICKUP_PROBE_TIMEOUT_SECONDS = 45, --// Bound empty or unconfirmed trials.
	},
	PICKUP_SETTINGS = {
		ENABLE_NATIVE_REGISTRY_DISCOVERY = true, --// Read live IDs from Client.Tutorial._activePickups.
		ENABLE_CHUNKER_DISCOVERY = true, --// Scan every native Rendered.Chunker folder as an additional source.
		ENABLE_CONTINUOUS_SCANNING = true, --// Include existing models and new spawns.
		BULK_COLLECT_PICKUPS = true, --// Use native radius coverage; no island-wide batch endpoint exists in inspected code.
		ENABLE_CLUSTER_ROUTING = true, --// Walk to dense coverage positions.
		COLLECTION_REFRESH_SECONDS = 1, --// Scan no more than once per second.
		FARM_CURRENCY_TYPES = {}, --// Include every verified currency type.
	},
	BUBBLE_SETTINGS = {
		AUTO_BLOW_BUBBLES = false, --// Isolate pickup collection.
		AUTO_SELL_BUBBLES = false, --// Disable OC selling during this test.
		ENABLE_SIMULTANEOUS_BLOWING = false, --// Disable combined farming.
		AUTO_BUY_GUM = false, --// Disable gum purchases.
		AUTO_BUY_FLAVORS = false, --// Disable flavor purchases.
	},
	UPGRADE_SETTINGS = {
		ENABLE_SMART_UPGRADES = false, --// Disable upgrade tasks.
		ENABLE_CAPACITY_UPGRADES = false, --// Disable storage upgrade tasks.
		ENABLE_FLAVOR_UPGRADES = false, --// Disable flavor upgrade tasks.
		AUTO_EQUIP_OWNED_UPGRADES = false, --// Disable equipment changes.
	},
	STATUS_UI_SETTINGS = {
		ENABLE_STATUS_UI = true, --// Keep real statistics and controls visible.
		SHOW_FARMING = true, --// Show counts, actual range and collection blockers.
		SHOW_FARMING_RATES = true, --// Show only evidence-qualified pickup earnings.
	},
	DIAGNOSTIC_SETTINGS = {
		ENABLE_CONSOLE_LOGGING = true, --// Print [OC] diagnostics.
		LOG_PICKUP_DIAGNOSTICS = true, --// Print scan, identity, rejection and credit evidence.
		LOG_PICKUP_DETAIL_PATHS = true, --// Show at most three rejected-object or problem-zone paths.
		LOG_ISLAND_DISCOVERY = false, --// Keep this test focused on native pickup diagnostics.
		LOG_ACCOUNT_DETAILS = false, --// Keep inventory details in the status UI.
		MINIMUM_LOG_INTERVAL_SECONDS = 5, --// Rate-limit scan summaries.
	},
}

loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"
))()(Config)

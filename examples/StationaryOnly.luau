-- Initial isolated experiment. Manually stand on unlocked The Void or Zen first.
-- No OC walking, repositioning, teleportation, blowing, selling, or purchases.
-- Omitted values inherit central OCConfig; live distant credit remains unverified.
local Config = {
	GENERAL_SETTINGS = { OC_ENABLED = true, AUTO_START = true }, --// Start the central Brain and scheduler.
	ACCOUNT_SETTINGS = { ENABLE_ACCOUNT_READER = true, READ_UNLOCKS = true }, --// Require real LocalData balances/access.
	BRAIN_SETTINGS = { SELECTED_WORLDS = { "The Overworld" } }, --// Only this world is approved for farming.
	FARMING_SETTINGS = {
		FARMING_STRATEGY = "PICKUP_FIRST", --// Select pickup work through the existing Brain.
		AUTO_RESOURCE_FARM = true, --// Enable bounded stationary experiment tasks.
		ENABLE_EFFICIENCY_COMPARISON = false, --// Measure this isolated island before strategy comparison.
		ENABLE_ACTIVITY_SWITCHING = false, --// Keep the isolated activity fixed.
		AUTO_FARM_FALLBACK = false, --// Fail honestly without another farming action.
		CURRENCY_PRIORITIES = { "Coins", "Gems" }, --// Test these actual LocalData currencies separately.
	},
	ISLAND_SETTINGS = {
		SELECTED_ISLANDS = { "The Void", "Zen" }, --// Actual unlock membership is rechecked before every request.
		AUTO_SELECT_BEST_ISLAND = false, --// Manual placement for this experiment.
		AUTO_EXPLORE_UNLOCKED_ISLANDS = false, --// Never explore automatically during isolation.
		AUTO_TRAVEL_BEST_ISLAND = false, --// Never teleport during isolation.
	},
	PICKUP_SETTINGS = {
		COLLECTION_METHOD = "STATIONARY_EXPERIMENT", --// Only supported OC pickup strategy.
		STATIONARY_ISOLATED_TEST = true, --// Executor also blocks stale non-pickup action tasks.
		STATIONARY_ALLOW_OUTSIDE_NATIVE_RANGE = true, --// Probe genuine loaded IDs; server acceptance remains unknown.
		STATIONARY_REQUEST_COOLDOWN_SECONDS = 3, --// At most one single-ID attempt per cooldown.
		STATIONARY_ID_RETRY_SECONDS = 15, --// Back off each uncredited ID.
		STATIONARY_MAXIMUM_ATTEMPTS_PER_ID = 2, --// Never retry an ID indefinitely.
		STATIONARY_MAXIMUM_REQUESTS = 24, --// Finite controller-session budget, retained across Pause/Stop.
		STATIONARY_TEST_DURATION_SECONDS = 120, --// Stop requests after two minutes from first dispatch.
		STATIONARY_MAXIMUM_DRIFT_STUDS = 0.5, --// Discard credit and end requests after position drift.
		ENABLE_NATIVE_REGISTRY_DISCOVERY = true, --// Require fresh genuine native registry IDs.
		ENABLE_CHUNKER_DISCOVERY = true, --// Preserve all native Chunker observations.
		ENABLE_CONTINUOUS_SCANNING = true, --// Reconcile existing and newly spawned pickups.
		BULK_COLLECT_PICKUPS = true, --// Allow stationary tasks; each sends just one ID.
		ENABLE_CLUSTER_ROUTING = false, --// Legacy true overrides are forced false too.
		FARM_CURRENCY_TYPES = { "Coins", "Gems" }, --// Exclude unrelated reward types from the experiment.
	},
	BUBBLE_SETTINGS = {
		AUTO_BLOW_BUBBLES = false, --// Isolate stationary currency observations.
		AUTO_SELL_BUBBLES = false, --// No OC selling or selling excursions.
		ENABLE_SIMULTANEOUS_BLOWING = false, --// Cooperative blowing is a later separately configured test.
		AUTO_BUY_GUM = false, --// No purchases.
		AUTO_BUY_FLAVORS = false, --// No purchases.
	},
	UPGRADE_SETTINGS = {
		ENABLE_SMART_UPGRADES = false, --// Block upgrade tasks.
		ENABLE_CAPACITY_UPGRADES = false, --// No capacity purchases.
		ENABLE_FLAVOR_UPGRADES = false, --// No flavor purchases.
		AUTO_EQUIP_OWNED_UPGRADES = false, --// Preserve the current equipment.
	},
	DIAGNOSTIC_SETTINGS = {
		ENABLE_CONSOLE_LOGGING = true, --// Print request distances and actual before/after Coins/Gems.
		LOG_PICKUP_DIAGNOSTICS = true, --// Explain registry discovery, credit and blockers.
		LOG_PICKUP_DETAIL_PATHS = false, --// Keep routine output compact.
		LOG_ACCOUNT_DETAILS = false, --// Keep full account facts in the status panel.
	},
}

local OC = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"
))()(Config)

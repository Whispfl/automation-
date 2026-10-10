-- Continuous stationary farming: native travel to unlocked Zen, with The Void as fallback.
-- Native island teleportation only; no pickup movement, blowing, selling, or purchases.
-- Omitted values inherit central OCConfig; each batch checks real balances without assuming every ID succeeded.
local Config = {
	GENERAL_SETTINGS = { OC_ENABLED = true, AUTO_START = true }, --// Start the central Brain and scheduler.
	ACCOUNT_SETTINGS = { ENABLE_ACCOUNT_READER = true, READ_UNLOCKS = true }, --// Require real LocalData balances/access.
	BRAIN_SETTINGS = { SELECTED_WORLDS = { "The Overworld" } }, --// Only this world is approved for farming.
	FARMING_SETTINGS = {
		FARMING_STRATEGY = "PICKUP_FIRST", --// Select pickup work through the existing Brain.
		AUTO_RESOURCE_FARM = true, --// Enable continuous stationary batch tasks.
		ENABLE_EFFICIENCY_COMPARISON = false, --// Measure this isolated island before strategy comparison.
		ENABLE_ACTIVITY_SWITCHING = false, --// Keep the isolated activity fixed.
		AUTO_FARM_FALLBACK = false, --// Fail honestly without another farming action.
		CURRENCY_PRIORITIES = { "Coins", "Gems" }, --// Test these actual LocalData currencies separately.
	},
	ISLAND_SETTINGS = {
		SELECTED_ISLANDS = { "The Void", "Zen" }, --// Actual unlock membership is rechecked before every request.
		AUTO_SELECT_BEST_ISLAND = true, --// Select an actually unlocked approved island.
		PREFERRED_FARMING_ISLAND = "Zen", --// Fall back to The Void when Zen is unavailable or locked.
		AUTO_EXPLORE_UNLOCKED_ISLANDS = false, --// Never explore automatically during isolation.
		AUTO_TRAVEL_BEST_ISLAND = true, --// Native island travel followed by stable arrival; never approach pickups.
	},
	PICKUP_SETTINGS = {
		COLLECTION_METHOD = "STATIONARY", --// Only supported OC pickup strategy.
		STATIONARY_ISOLATED_TEST = true, --// Permit approved island travel and pickups; block other farming actions.
		STATIONARY_REQUEST_COOLDOWN_SECONDS = 0.05, --// Pace requests at least 50 ms apart.
		STATIONARY_MAXIMUM_BATCH_SIZE = 32, --// Process remaining IDs in subsequent scheduler batches.
		STATIONARY_BATCH_COOLDOWN_SECONDS = 1, --// Idle at least one second between completed batches.
		STATIONARY_ID_RETRY_SECONDS = 15, --// Back off transport errors only; invoked IDs stay deduplicated.
		STATIONARY_MAXIMUM_ATTEMPTS_PER_ID = 2, --// Bound uncertain transport retries.
		ENABLE_NATIVE_REGISTRY_DISCOVERY = true, --// Require fresh genuine native registry IDs.
		ENABLE_CHUNKER_DISCOVERY = true, --// Preserve all native Chunker observations.
		ENABLE_CONTINUOUS_SCANNING = true, --// Reconcile existing and newly spawned pickups.
		BULK_COLLECT_PICKUPS = true, --// Allow stationary tasks; each sends a paced batch.
		ENABLE_CLUSTER_ROUTING = false, --// Legacy true overrides are forced false too.
		FARM_CURRENCY_TYPES = { "Coins", "Gems" }, --// Only collect the approved Coins/Gems.
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
		ENABLE_CONSOLE_LOGGING = true, --// Print distances, actual Coins/Gems gains, batch size, processing time and inconclusive outcomes.
		LOG_PICKUP_DIAGNOSTICS = true, --// Explain registry discovery, credit and blockers.
		LOG_PICKUP_DETAIL_PATHS = false, --// Keep routine output compact.
		LOG_ACCOUNT_DETAILS = false, --// Keep full account facts in the status panel.
	},
}

local OC = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"
))()(Config)

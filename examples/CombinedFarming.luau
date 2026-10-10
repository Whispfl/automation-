-- Later stationary/background-blowing comparison; use StationaryOnly.luau first.
local Config = {
	GENERAL_SETTINGS = { AUTO_START = true }, --// Start the enabled Brain tasks.
	BRAIN_SETTINGS = { SELECTED_WORLDS = { "The Overworld" } }, --// Restrict farming and exploration to this world.
	FARMING_SETTINGS = {
		FARMING_STRATEGY = "PICKUP_FIRST", --// Pickups are primary; blowing is cooperative background work.
		ISOLATED_PICKUP_PROBES = false, --// Measure real combined operation during this test.
		AUTO_RESOURCE_FARM = true, --// Use the existing foreground scheduler.
		ENABLE_EFFICIENCY_COMPARISON = true, --// Compare measured goal-currency earnings.
		ENABLE_ACTIVITY_SWITCHING = true, --// Allow bounded trials and useful strategy changes.
		MAXIMUM_COMBINED_SELL_DELAY_SECONDS = 6, --// Limit movement with a full bubble before selling.
	},
	ISLAND_SETTINGS = {
		SELECTED_ISLANDS = { "The Void", "Zen" }, --// Farm only these islands after verifying actual unlocks.
		AUTO_EXPLORE_UNLOCKED_ISLANDS = false, --// Keep this stationary comparison on the manually selected island.
		AUTO_TRAVEL_BEST_ISLAND = false, --// Future native travel requires separate configuration.
		MIN_ISLAND_DWELL_SECONDS = 60, --// Avoid rapid island switching.
	},
	PICKUP_SETTINGS = {
		COLLECTION_METHOD = "STATIONARY_EXPERIMENT", --// Never walk to pickups.
		STATIONARY_ISOLATED_TEST = false, --// Explicitly allow cooperative blowing in this later comparison.
		BULK_COLLECT_PICKUPS = true, --// Centrally scheduled single-ID stationary attempts.
		ENABLE_CLUSTER_ROUTING = false, --// Pickup movement has been removed.
		FARM_CURRENCY_TYPES = { "Coins", "Gems" }, --// Only the approved experiment currencies.
	},
	BUBBLE_SETTINGS = {
		AUTO_BLOW_BUBBLES = true, --// Blow in the background during pickup work when native guards allow.
		AUTO_SELL_BUBBLES = false, --// Selling/travel are separately configured future tests.
		ENABLE_SIMULTANEOUS_BLOWING = true, --// Blow during a Brain-selected collection task.
		AUTO_BUY_GUM = false, --// Disable purchases while measuring farming.
		AUTO_BUY_FLAVORS = false, --// Disable purchases while measuring farming.
	},
	UPGRADE_SETTINGS = {
		ENABLE_SMART_UPGRADES = false, --// Prevent all upgrade tasks during this test.
		ENABLE_CAPACITY_UPGRADES = false, --// Keep capacity purchases disabled.
		ENABLE_FLAVOR_UPGRADES = false, --// Keep flavor purchases disabled.
		AUTO_EQUIP_OWNED_UPGRADES = false, --// Keep equipment unchanged for comparisons.
	},
	DIAGNOSTIC_SETTINGS = {
		ENABLE_CONSOLE_LOGGING = true, --// Print action and verification evidence.
		LOG_MOVEMENT_DIAGNOSTICS = true, --// Explain route recovery and skipped targets.
		LOG_PICKUP_DIAGNOSTICS = true, --// Print actual disappearance and balance evidence.
		LOG_PICKUP_DETAIL_PATHS = false, --// Keep rejection summaries compact.
		LOG_ACCOUNT_DETAILS = false, --// Keep full statistics in the status UI.
	},
}

loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"
))()(Config)

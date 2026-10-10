-- Combined farming verification. Omitted values inherit central OCConfig.
local Config = {
	GENERAL_SETTINGS = { AUTO_START = true }, --// Start the enabled Brain tasks.
	FARMING_SETTINGS = {
		AUTO_RESOURCE_FARM = true, --// Use the existing foreground scheduler.
		ENABLE_EFFICIENCY_COMPARISON = true, --// Compare measured goal-currency earnings.
		ENABLE_ACTIVITY_SWITCHING = true, --// Allow bounded trials and useful strategy changes.
		MAXIMUM_COMBINED_SELL_DELAY_SECONDS = 6, --// Limit movement with a full bubble before selling.
	},
	ISLAND_SETTINGS = {
		SELECTED_ISLANDS = { "Floating Island", "Outer Space" }, --// Test these already discovered farming islands.
		AUTO_EXPLORE_UNLOCKED_ISLANDS = true, --// Obtain isolated pickup measurements first.
		AUTO_TRAVEL_BEST_ISLAND = true, --// Permit supported unlocked island and selling travel.
		MIN_ISLAND_DWELL_SECONDS = 60, --// Avoid rapid island switching.
	},
	PICKUP_SETTINGS = {
		BULK_COLLECT_PICKUPS = true, --// Collect native radius clusters of all live currencies.
		FARM_CURRENCY_TYPES = {}, --// Accept every actually detected currency type.
		WAYPOINT_STALL_SECONDS = 2, --// Recover after no forward progress.
		MAXIMUM_PATH_RECOMPUTES = 1, --// Retry once within the same slice, then back off.
	},
	BUBBLE_SETTINGS = {
		AUTO_BLOW_BUBBLES = true, --// Test bubble-only and combined modes when native guards allow.
		AUTO_SELL_BUBBLES = true, --// Verify bubble decrease and real balance credit.
		ENABLE_SIMULTANEOUS_BLOWING = true, --// Blow during a Brain-selected collection task.
		AUTO_BUY_GUM = false, --// Disable purchases while measuring farming.
		AUTO_BUY_FLAVORS = false, --// Disable purchases while measuring farming.
	},
	UPGRADE_SETTINGS = {
		ENABLE_SMART_UPGRADES = false, --// Prevent all upgrade tasks during this test.
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

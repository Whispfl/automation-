--!strict
-- Phase 1: configuration and recommendations only. Gameplay executors are absent.
return {
	GENERAL_SETTINGS = {
		OC_ENABLED = true, --// Permit the OC controls to start account analysis.
		AUTO_START = true, --// Start analysis automatically after the panel loads.
		PROGRESSION_PROFILE = "FULL_AUTO_PROGRESSION", --// Select the recommendation profile; Phase 1 supports full progression only.
		ENABLE_RECOMMENDATIONS = true, --// Allow the brain to select the next objective.
		REPLAN_COOLDOWN_SECONDS = 1, --// Coalesce account changes before scheduling another analysis.
		MINIMUM_OBJECTIVE_HOLD_SECONDS = 10, --// Keep a valid recommendation briefly to avoid constant switching.
		OBJECTIVE_SWITCH_PRIORITY_MARGIN = 50, --// Require this priority improvement to replace a valid recommendation early.
		PRIORITIES = { "RESOLVE_BLOCKERS", "EARNING_POWER", "WORLD_UNLOCKS", "MASTERY" }, --// Break ties between eligible goal families in this order.
	},
	ACCOUNT_SETTINGS = {
		ENABLE_ACCOUNT_READER = true, --// Read the existing LocalData service and account updates.
		MODULE_LOAD_TIMEOUT_SECONDS = 10, --// Report game dependencies that have not finished requiring.
		ACCOUNT_LOAD_TIMEOUT_SECONDS = 20, --// Report missing real player data after this wait; never fabricate a profile.
		SNAPSHOT_REFRESH_SECONDS = 5, --// Refresh slowly as a fallback to account change notifications.
		MINIMUM_SNAPSHOT_INTERVAL_SECONDS = 0.5, --// Coalesce rapid data changes before copying the account inventory again.
		SELECTED_CURRENCIES = { "Coins", "Gems", "Tickets", "Pearls", "Leaves26", "RebirthShards26" }, --// Read these verified top-level balances when present.
		READ_PET_INVENTORY = true, --// Include pet records and resolve equipped IDs against the inventory.
		READ_ITEM_INVENTORY = true, --// Include received powerup and potion inventories independently of pets.
		READ_UPGRADES = true, --// Include owned gum and flavor upgrades.
		READ_MASTERY = true, --// Include received Mastery levels and Mastery upgrade records.
		READ_UNLOCKS = true, --// Include discovered areas and unlocked worlds.
	},
	BRAIN_SETTINGS = {
		ENABLE_EARNING_RECOMMENDATIONS = true, --// Recommend equipping existing pets and useful gum or flavor upgrades.
		ENABLE_WORLD_RECOMMENDATIONS = true, --// Recommend verified island discovery and world gate prerequisites.
		ENABLE_MASTERY_RECOMMENDATIONS = true, --// Recommend the next permanent Mastery tier from current definitions.
		ENABLE_INVENTORY_RECOMMENDATIONS = true, --// Highlight full inventory and unresolved equipped pet records.
		SELECTED_UPGRADES = {}, --// Restrict gum/flavor recommendations to these names; empty means all verified nonpremium entries.
		SELECTED_WORLDS = {}, --// Restrict world recommendations to these names; empty means scene-present permanent worlds.
		MASTERY_PRIORITIES = { "Pets", "Buffs", "Shops", "Minigames", "Rifts" }, --// Rank permanent Mastery branches; availability still comes from game definitions.
		MINIMUM_UPGRADE_GAIN_RATIO = 0.15, --// Ignore upgrades whose base stat improvement is smaller than this fraction.
		MINIMUM_BLOWS_PER_FILL = 10, --// Treat a small capacity relative to actual bubble power as a capacity bottleneck.
	},
	RESOURCE_SETTINGS = {
		COIN_RESERVE = 0, --// Exclude these coins from affordability recommendations.
		GEM_RESERVE = 0, --// Exclude these gems from affordability recommendations.
		TICKET_RESERVE = 0, --// Exclude these tickets from affordability recommendations.
		PEARL_RESERVE = 0, --// Exclude these pearls from affordability recommendations.
		MAXIMUM_UPGRADE_BALANCE_FRACTION = 0.25, --// Mark purchases above this fraction of spendable funds as savings objectives.
	},
	TASK_SETTINGS = {
		ENABLE_TASK_SCHEDULER = true, --// Run at most one read-only foreground analysis task.
		MAXIMUM_PENDING_TASKS = 8, --// Bound the scheduler queue; duplicate IDs replace pending work.
		TASK_TIMEOUT_SECONDS = 10, --// Cancel a stuck analysis and retain its foreground lease until it exits.
	},
	BUBBLE_SETTINGS = {
		ENABLE_BUBBLE_RECOMMENDATIONS = true, --// Recommend selling a full bubble or improving capacity/output.
		SELL_AT_CAPACITY_RATIO = 0.95, --// Recommend selling when this fraction of effective capacity is occupied.
		AUTO_BLOW_BUBBLES = false, --// Reserved for a later phase; no bubble automation exists in Phase 1.
		AUTO_SELL_BUBBLES = false, --// Reserved for a later phase; no selling automation exists in Phase 1.
		AUTO_BUY_GUM = false, --// Reserved for a later phase; Phase 1 only recommends upgrades.
		AUTO_BUY_FLAVORS = false, --// Reserved for a later phase; Phase 1 never purchases flavors.
	},
	FALL_EVENT_SETTINGS = {
		ENABLE_FALL_EVENT = false, --// Reserved; event discovery and automation are outside Phase 1.
		AUTO_REBIRTH = false, --// Reserved; leaf-resetting rebirths require later explicit enablement.
		AUTO_BUY_REBIRTH_UPGRADES = false, --// Reserved; no Autumn upgrade purchase executor is installed.
		AUTO_USE_FALL_ELIXIRS = false, --// Reserved; Phase 1 never consumes elixirs.
		AUTO_BUY_AUTUMN_SHOP_ITEMS = false, --// Reserved; Phase 1 never visits or buys from event shops.
		SELECTED_EGGS = {}, --// Reserve selected Autumn egg names for a later verified feature module.
		SELECTED_SHOP_ITEMS = {}, --// Reserve selected Autumn shop item names; an empty list authorizes no purchases.
		LEAF_RESERVE = 0, --// Reserve future Leaves26 spending; unused while the event feature is absent.
		REBIRTH_SHARD_RESERVE = 0, --// Reserve future RebirthShards26 spending; unused in Phase 1.
	},
	PET_SETTINGS = {
		SELECTED_PETS = {}, --// Reserve target pet names for later modules; no acquisition tasks run now.
		AUTO_HATCH = false, --// Reserved; hatching is outside Phase 1.
		AUTO_EQUIP = false, --// Reserved; Phase 1 recommends a team change without applying it.
		AUTO_DELETE_PETS = false, --// Reserved; destructive inventory operations are disabled.
		AUTO_CRAFT_SHINY = false, --// Reserved; Phase 1 never consumes duplicate pets.
		AUTO_FUSE_PETS = false, --// Reserved; Phase 1 never submits pets to machines.
	},
	STATUS_UI_SETTINGS = {
		ENABLE_STATUS_UI = true, --// Display the foundation panel and OC controls.
		SHOW_ACCOUNT_BALANCES = true, --// Show real balances and bubble capacity; missing values display unavailable.
		SHOW_PROGRESSION = true, --// Show the evidence-based progression category and unlock counts.
		SHOW_PREREQUISITES = true, --// Show why the next objective is blocked or ready.
		SHOW_DIAGNOSTICS = true, --// Show missing data and game dependency failures.
		SHOW_PETS = true, --// Display equipped pet IDs and inventory pet records.
		SHOW_INVENTORY = true, --// Display received potion and powerup inventory entries.
		SHOW_UPGRADES = true, --// Display owned gum, flavors, and received Mastery upgrades.
		SHOW_MASTERY = true, --// Display received levels and verified next tier costs.
		SHOW_WORLDS = true, --// Display actual unlocked world and island names.
		MAXIMUM_DISPLAY_ENTRIES = 30, --// Bound each inventory display; GetStatus retains the complete read snapshot.
		PANEL_WIDTH_PIXELS = 390, --// Set the maximum panel width; small viewports scale down.
		PANEL_HEIGHT_PIXELS = 420, --// Set the maximum panel height; content can scroll.
	},
	DIAGNOSTIC_SETTINGS = {
		ENABLE_CONSOLE_LOGGING = true, --// Print prefixed control, account, dependency, and objective diagnostics.
		LOG_ACCOUNT_DETAILS = true, --// Print bounded pet, inventory, unlock, upgrade, and Mastery details on changes.
		LOG_DEPENDENCIES = true, --// Print game module load status changes and errors.
		MINIMUM_LOG_INTERVAL_SECONDS = 5, --// Rate limit account diagnostics while preserving the latest changed snapshot.
		MAXIMUM_LOG_ENTRIES = 30, --// Limit each detailed console inventory list; PrintAccount accepts an explicit limit.
	},
}

--!strict
-- Central defaults. Currency purchases require explicit enablement.
return {
	GENERAL_SETTINGS = {
		OC_ENABLED = true, --// Permit the OC controls to start account analysis.
		AUTO_START = true, --// Start analysis automatically after the panel loads.
		PROGRESSION_PROFILE = "FULL_AUTO_PROGRESSION", --// Select the supported full-progression recommendation profile.
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
		SELECTED_CURRENCIES = { "Coins", "Gems", "Tickets", "Pearls", "Candycorn26", "HalloweenShards" }, --// Read current native balances when present; catalog or balance presence alone never activates an event.
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
		ENABLE_TASK_SCHEDULER = true, --// Grant one foreground lease to analysis, navigation, farming, selling, or spending.
		MAXIMUM_PENDING_TASKS = 8, --// Bound the scheduler queue; duplicate IDs replace pending work.
		TASK_TIMEOUT_SECONDS = 10, --// Cancel a stuck analysis and retain its foreground lease until it exits.
	},
	BUBBLE_SETTINGS = {
		ENABLE_BUBBLE_RECOMMENDATIONS = true, --// Recommend selling a full bubble or improving capacity/output.
		SELL_AT_CAPACITY_RATIO = 0.95, --// Recommend selling when this fraction of effective capacity is occupied.
		AUTO_BLOW_BUBBLES = true, --// Permit Brain-selected blowing through the verified BlowBubble command.
		AUTO_SELL_BUBBLES = true, --// Walk to a reachable same-island sell activation and wait for a real sale.
		AUTO_BUY_GUM = false, --// Explicitly authorize nonpremium bubble-capacity gum purchases.
		AUTO_BUY_FLAVORS = false, --// Explicitly authorize nonpremium bubble-power flavor purchases.
		ENABLE_SIMULTANEOUS_BLOWING = true, --// Allow the Brain to test blowing during a pickup cluster task.
		BLOW_COOLDOWN_SECONDS = 0.5, --// Minimum spacing between verified blow commands; UI and Bubble Lock guards still apply.
		SELL_CONFIRMATION_TIMEOUT_SECONDS = 8, --// Stop waiting if native selling does not reduce the actual bubble amount.
		SELL_RETRY_COOLDOWN_SECONDS = 20, --// Back off after an unavailable or unconfirmed sell attempt.
	},
	FARMING_SETTINGS = {
		AUTO_RESOURCE_FARM = true, --// Permit the Brain to schedule Phase 2 actions; false retains account analysis only.
		ENABLE_EFFICIENCY_COMPARISON = true, --// Compare measured currency gains for pickup, bubble, and combined sessions.
		ENABLE_ACTIVITY_SWITCHING = true, --// Reevaluate modes as yields or availability change; safety and full-bubble selling remain active.
		OBSERVATION_INTERVAL_SECONDS = 1, --// Sample live balances and scene availability without running an independent action loop.
		ACTION_SLICE_SECONDS = 6, --// Bound each foreground farming task before the Brain decides again.
		MINIMUM_RATE_SAMPLE_SECONDS = 15, --// Show a measured per-minute rate only after this much activity time.
		RATE_WINDOW_SECONDS = 180, --// Expire old activity measurements and area-specific efficiency evidence.
		EXPLORATION_INTERVAL_SECONDS = 60, --// Retest an eligible alternative after this interval to detect changed efficiency.
		MINIMUM_ACTIVITY_HOLD_SECONDS = 20, --// Hold an available mode briefly to avoid switching on tiny samples.
		ACTIVITY_SWITCH_GAIN_RATIO = 0.2, --// Require this fractional measured-rate advantage before switching a viable mode.
		EARNINGS_CONFIRMATION_TIMEOUT_SECONDS = 3, --// Allow delayed account credit to arrive before reporting a collection or sale as unconfirmed.
		BUBBLE_PROBE_TIMEOUT_SECONDS = 180, --// Bound an initial unsold bubble trial; an unfinished trial is not a measured sale rate.
		MAXIMUM_COMBINED_SELL_DELAY_SECONDS = 6, --// Finish useful pickup coverage briefly when measured lost pickup income exceeds estimated sale value; then sell full bubbles.
		CURRENCY_PRIORITIES = { "Coins", "Gems", "Tickets", "Pearls" }, --// Fallback earning priorities when the recommended goal has no unmet currency cost.
		AUTO_FARM_FALLBACK = true, --// Permit another useful eligible activity when the preferred farming method is unavailable.
	},
	ISLAND_SETTINGS = {
		AUTO_EXPLORE_UNLOCKED_ISLANDS = true, --// Run bounded isolated pickup trials on supported unlocked islands even when bubbles currently win.
		ISLAND_EXPLORATION_RETRY_SECONDS = 300, --// Wait this long before repeating an island/currency trial, including empty or failed trials.
		PICKUP_PROBE_TIMEOUT_SECONDS = 45, --// End a pickup trial at this limit if no adequate actual earning sample is obtained.
		ARRIVAL_PICKUP_GRACE_SECONDS = 3, --// Keep scanning during this bounded arrival-loading period before measuring a pickup trial.
		AUTO_SELECT_BEST_ISLAND = true, --// Rank already unlocked islands using goal-currency value and observed area rates.
		AUTO_TRAVEL_BEST_ISLAND = true, --// Use the native Teleport command only to verified unlocked island spawn paths.
		SELECTED_ISLANDS = {}, --// Empty considers all unlocked scene-present islands; names further restrict travel candidates.
		MIN_ISLAND_GAIN_ADVANTAGE_PERCENT = 25, --// Require this net earning advantage before leaving a useful current island.
		MIN_ISLAND_DWELL_SECONDS = 60, --// Stay on a viable island for this long before another farming-island switch.
		TRAVEL_COOLDOWN_SECONDS = 10, --// Minimum spacing between supported island or sell-station travel requests.
		TRAVEL_CONFIRMATION_TIMEOUT_SECONDS = 8, --// Stop travel when character proximity does not confirm the intended arrival.
		TRAVEL_RETRY_COOLDOWN_SECONDS = 30, --// Back off a destination after failed or unconfirmed travel.
		ARRIVAL_DISTANCE_STUDS = 20, --// Require the live character to arrive this close to the supported destination.
		UNMEASURED_TRAVEL_OVERHEAD_SECONDS = 5, --// Explicit planning estimate used until actual destination travel time is measured.
		UNMEASURED_COLLECTION_CYCLE_SECONDS = 30, --// Explicit estimate for unknown routing/respawn time; never displayed as measured earnings.
		EMPTY_ISLAND_CONFIRMATION_SECONDS = 15, --// Observe an empty arrived island this long before treating its pickups as unavailable.
		EMPTY_ISLAND_RETRY_SECONDS = 60, --// Back off empty islands; a newly observed eligible spawn clears this backoff early.
	},
	PICKUP_SETTINGS = {
		ENABLE_NATIVE_REGISTRY_DISCOVERY = true, --// Read the source-confirmed Client.Tutorial._activePickups ID-to-Model registry without changing it.
		ENABLE_CHUNKER_DISCOVERY = true, --// Observe native Rendered.Chunker folders and qualify their pickup Models through IDs and native pools.
		ENABLE_CONTINUOUS_SCANNING = true, --// Refresh all currently rendered pickups at COLLECTION_REFRESH_SECONDS, including models predating OC.
		PREFAB_REFRESH_SECONDS = 15, --// Rebuild live prefab identity indexes to recover from delayed asset replication.
		ZONE_MATCH_TOLERANCE_STUDS = 0.5, --// Allow this small geometric border tolerance when associating a model with native zones.
		PICKUP_RANGE_MARGIN_STUDS = 0.25, --// Stay slightly inside the actual native radius; never increase the collection range.
		BULK_COLLECT_PICKUPS = true, --// Use the supported radius-cluster fallback; this game exposes no genuine island-wide batch API.
		ENABLE_CLUSTER_ROUTING = true, --// Walk between dense reachable clusters when the game has no island-wide batch API.
		FARM_CURRENCY_TYPES = {}, --// Empty includes every live currency pickup; names restrict OC route scoring and tracking.
		COLLECTION_REFRESH_SECONDS = 1, --// Minimum spacing between scene scans and subsequent collection cycles.
		ZONE_REFRESH_SECONDS = 10, --// Refresh live tagged zone definitions, including zones added or removed at runtime.
		MAXIMUM_ROUTE_DISTANCE_STUDS = 180, --// Reject cluster or sell destinations farther away than this walking distance estimate.
		MAXIMUM_VERTICAL_DIFFERENCE_STUDS = 20, --// Keep discovery and navigation on the player's current island height band.
		MAXIMUM_CLUSTER_CANDIDATES = 32, --// Bound density scoring while still scanning every rendered pickup.
		COLLECTION_SETTLE_SECONDS = 0.5, --// Wait in native range for the game collector after arriving at a cluster.
		UNREACHABLE_RETRY_SECONDS = 30, --// Back off failed cluster identities rather than repeatedly navigating to them.
		COLLECTION_RETRY_SECONDS = 5, --// Avoid immediately revisiting a cluster that produced no observed pickup disappearance.
		PATH_TIMEOUT_SECONDS = 3, --// Bound path computation; waypoint stall timing separately resets on real forward progress.
		WAYPOINT_STALL_SECONDS = 2, --// Replan when no meaningful progress toward the current waypoint is observed for this long.
		MINIMUM_WAYPOINT_PROGRESS_STUDS = 0.5, --// Require this cumulative distance improvement to reset the stall timer.
		MOVE_REISSUE_SECONDS = 2, --// Refresh normal MoveTo while progressing; cannot extend the foreground task deadline.
		MAXIMUM_PATH_RECOMPUTES = 1, --// Bound recovery attempts for stalled, blocked or failed paths within the same task slice; zero disables recovery.
		MAXIMUM_PATH_DETOUR_RATIO = 2.5, --// Reject paths whose length greatly exceeds the direct route.
	},
	UPGRADE_SETTINGS = {
		ENABLE_SMART_UPGRADES = true, --// Let the Brain evaluate supported gum and flavor improvements before buying.
		AUTO_EQUIP_OWNED_UPGRADES = false, --// Explicitly allow switching to better owned gum or flavor through native commands.
		ENABLE_CAPACITY_UPGRADES = true, --// Allow gum purchases to address bubble storage bottlenecks; no pet-storage purchase API was found.
		ENABLE_FLAVOR_UPGRADES = true, --// Allow flavor purchases when bubble production is the selected earning bottleneck.
		SELECTED_UPGRADES = {}, --// Further restrict actual purchases/equips by upgrade name; empty allows verified recommendations.
		MAXIMUM_PURCHASE_COST = 1000000, --// Absolute per-purchase currency spending cap; premium costs are always excluded.
		MAXIMUM_PAYBACK_SECONDS = 300, --// Require a conservative measured bubble-income payback within this time for purchases.
		PURCHASE_CONFIRMATION_TIMEOUT_SECONDS = 8, --// Wait for real ownership/equipment changes after issuing one native shop command.
		PURCHASE_RETRY_COOLDOWN_SECONDS = 30, --// Back off unconfirmed purchases or equips instead of resending every decision cycle.
		ENABLE_GOAL_RESERVATION = true, --// Preserve the remaining selected world/Mastery goal funds before buying secondary upgrades.
		MAXIMUM_GOAL_RESERVE_BALANCE_FRACTION = 0.5, --// Cap long-term goal reservation to this fraction of post-resource-reserve funds; one preserves the full available goal amount.
		ALLOWED_PURCHASE_CURRENCIES = { "Coins" }, --// Explicitly authorize currencies for gum/flavor spending; no premium or unlisted currency is ever purchased.
	},
	FALL_EVENT_SETTINGS = {
		ENABLE_FALL_EVENT = false, --// Reserved; event shops, rebirths, and consumable tasks are not implemented.
		AUTO_REBIRTH = false, --// Reserved; leaf-resetting rebirths require later explicit enablement.
		AUTO_BUY_REBIRTH_UPGRADES = false, --// Reserved; no Autumn upgrade purchase executor is installed.
		AUTO_USE_FALL_ELIXIRS = false, --// Reserved; the current build never consumes elixirs.
		AUTO_BUY_AUTUMN_SHOP_ITEMS = false, --// Reserved; the current build never purchases event shop items.
		SELECTED_EGGS = {}, --// Reserve selected Autumn egg names for a later verified feature module.
		SELECTED_SHOP_ITEMS = {}, --// Reserve selected Autumn shop item names; an empty list authorizes no purchases.
		LEAF_RESERVE = 0, --// Preserve Leaves26 if a supported catalog ever uses it; event purchases remain disabled.
		REBIRTH_SHARD_RESERVE = 0, --// Preserve RebirthShards26 if a supported catalog uses it; no rebirth executor exists.
	},
	PET_SETTINGS = {
		SELECTED_PETS = {}, --// Reserve target pet names for later modules; no acquisition tasks run now.
		AUTO_HATCH = false, --// Reserved; hatching is outside the current build.
		AUTO_EQUIP = false, --// Reserved; pet team changes remain recommendations only.
		AUTO_DELETE_PETS = false, --// Reserved; destructive inventory operations are disabled.
		AUTO_CRAFT_SHINY = false, --// Reserved; the current build never consumes duplicate pets.
		AUTO_FUSE_PETS = false, --// Reserved; the current build never submits pets to machines.
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
		SHOW_FARMING = true, --// Show the chosen activity, useful currency, current island, and native collection constraint.
		SHOW_FARMING_RATES = true, --// Show per-currency observed earnings and sample time, including combined activity attribution.
		SHOW_ISLAND_CANDIDATES = true, --// Show measured versus estimated candidate earnings and travel evidence.
		MAXIMUM_DISPLAY_ENTRIES = 30, --// Bound each inventory display; GetStatus retains the complete read snapshot.
		PANEL_WIDTH_PIXELS = 390, --// Set the maximum panel width; small viewports scale down.
		PANEL_HEIGHT_PIXELS = 420, --// Set the maximum panel height; content can scroll.
	},
	DIAGNOSTIC_SETTINGS = {
		LOG_MOVEMENT_DIAGNOSTICS = true, --// Report bounded path recovery and final blockers without per-frame progress spam.
		LOG_UPGRADE_DIAGNOSTICS = true, --// Explain each considered catalog upgrade's budgets, projected effects, payback and blocking conditions.
		LOG_PICKUP_DIAGNOSTICS = true, --// Print rate-limited scan, classification, rejection, range and balance-result summaries.
		LOG_PICKUP_DETAIL_PATHS = false, --// Include a bounded number of problem paths only when diagnosing rejected or missing targets.
		LOG_ISLAND_DISCOVERY = true, --// Explain every catalog/zone island's unlocks, mapping, destination, counts and exclusion reason.
		ENABLE_CONSOLE_LOGGING = true, --// Print prefixed control, account, dependency, and objective diagnostics.
		LOG_ACCOUNT_DETAILS = true, --// Print bounded pet, inventory, unlock, upgrade, and Mastery details on changes.
		LOG_DEPENDENCIES = true, --// Print game module load status changes and errors.
		MINIMUM_LOG_INTERVAL_SECONDS = 5, --// Rate limit account diagnostics while preserving the latest changed snapshot.
		MAXIMUM_LOG_ENTRIES = 30, --// Limit each detailed console inventory list; PrintAccount accepts an explicit limit.
	},
}

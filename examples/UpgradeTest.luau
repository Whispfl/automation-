-- Controlled opt-in: only Unreal Gum and Contrast; at most 45,000 Coins per purchase.
-- Still requires measured bubble income, economic gain, ownership/access and reserves.
local Config = {
	GENERAL_SETTINGS = { AUTO_START = true }, --// Start enabled tasks and diagnostics.
	BRAIN_SETTINGS = {
		SELECTED_UPGRADES = { "Unreal Gum", "Contrast" }, --// Restrict upgrade recommendations to the test candidates.
	},
	FARMING_SETTINGS = { AUTO_RESOURCE_FARM = true }, --// Enable bubble income measurements and selected purchases.
	ISLAND_SETTINGS = {
		AUTO_EXPLORE_UNLOCKED_ISLANDS = false, --// Keep pickup exploration out of this purchase test.
		AUTO_TRAVEL_BEST_ISLAND = true, --// Retain supported selling-station travel.
	},
	PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false }, --// Disable OC pickup routes; the native collector is game-owned.
	BUBBLE_SETTINGS = {
		AUTO_BLOW_BUBBLES = true, --// Measure actual bubble earning power.
		AUTO_SELL_BUBBLES = true, --// Complete real fill/sell cycles before pricing upgrades.
		ENABLE_SIMULTANEOUS_BLOWING = false, --// Keep the activity comparison isolated.
		AUTO_BUY_GUM = true, --// Explicitly authorize the selected nonpremium gum.
		AUTO_BUY_FLAVORS = true, --// Explicitly authorize the selected nonpremium flavor.
	},
	UPGRADE_SETTINGS = {
		ENABLE_SMART_UPGRADES = true, --// Require actual native projected benefit and measured income.
		ENABLE_CAPACITY_UPGRADES = true, --// Allow useful gum improvements.
		ENABLE_FLAVOR_UPGRADES = true, --// Allow useful flavor improvements.
		AUTO_EQUIP_OWNED_UPGRADES = true, --// Verify supported equip commands for better owned test equipment.
		SELECTED_UPGRADES = { "Unreal Gum", "Contrast" }, --// Restrict actual purchases and equips.
		ALLOWED_PURCHASE_CURRENCIES = { "Coins" }, --// Authorize Coins only.
		MAXIMUM_PURCHASE_COST = 45000, --// Cap each purchase; both named entries may qualify separately.
		MAXIMUM_PAYBACK_SECONDS = 7200, --// Explicit two-hour estimated-payback allowance for this controlled test.
		ENABLE_GOAL_RESERVATION = true, --// Keep long-term savings protected.
		MAXIMUM_GOAL_RESERVE_BALANCE_FRACTION = 0.5, --// Reserve up to half the post-resource-reserve balance for a distant goal.
	},
	RESOURCE_SETTINGS = {
		COIN_RESERVE = 25000, --// Preserve at least this many Coins independently of goal savings.
		MAXIMUM_UPGRADE_BALANCE_FRACTION = 0.25, --// Bound cost to a quarter of remaining spendable funds.
	},
	DIAGNOSTIC_SETTINGS = {
		ENABLE_CONSOLE_LOGGING = true, --// Print purchase evidence and actual blockers.
		LOG_UPGRADE_DIAGNOSTICS = true, --// Show candidate, evaluation, rejection, purchase and verification.
		LOG_PICKUP_DIAGNOSTICS = false, --// Suppress unrelated pickup scan messages.
		LOG_ACCOUNT_DETAILS = false, --// Keep complete statistics available through the UI.
	},
}

loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"
))()(Config)

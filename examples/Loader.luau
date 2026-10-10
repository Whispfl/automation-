--!nonstrict
local Config = {
	GENERAL_SETTINGS = {
		OC_ENABLED = true, --// Permit initialization and OC controls.
		AUTO_START = true, --// Immediately analyze the received account.
	},
	ACCOUNT_SETTINGS = {
		ENABLE_ACCOUNT_READER = true, --// Read the game's actual LocalData profile.
		READ_PET_INVENTORY = true, --// Read inventory and resolve equipped pet IDs.
		READ_ITEM_INVENTORY = true, --// Read received potions and powerups.
		READ_UPGRADES = true, --// Read owned gum and flavors.
		READ_MASTERY = true, --// Read received Mastery levels and upgrades.
		READ_UNLOCKS = true, --// Read unlocked worlds and discovered islands.
		SNAPSHOT_REFRESH_SECONDS = 5, --// Refresh after manual account changes.
	},
	STATUS_UI_SETTINGS = {
		ENABLE_STATUS_UI = true, --// Show statistics, account details, goals, and controls.
		SHOW_ACCOUNT_BALANCES = true, --// Show actual currencies and bubble statistics.
		SHOW_PETS = true, --// Show equipped and inventory pet records.
		SHOW_INVENTORY = true, --// Show potions, powerups, and storage.
		SHOW_WORLDS = true, --// Show actual world and island unlocks.
		SHOW_MASTERY = true, --// Show received Mastery levels and next tiers.
		SHOW_UPGRADES = true, --// Show owned equipment and Mastery upgrades.
		SHOW_PROGRESSION = true, --// Show the progression assessment.
		SHOW_DIAGNOSTICS = true, --// Show unavailable fields and dependency errors.
	},
	DIAGNOSTIC_SETTINGS = {
		ENABLE_CONSOLE_LOGGING = true, --// Print [OC] diagnostics for the test.
		LOG_ACCOUNT_DETAILS = true, --// Print the received account sections.
	},
}

local OC = loadstring(game:HttpGet("https://raw.githubusercontent.com/ryanrooflead-source/OCscript-builds/main/dist/OC.lua"))()(Config)
return OC

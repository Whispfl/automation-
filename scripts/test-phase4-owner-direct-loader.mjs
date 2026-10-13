// Actual loader + actual merged defaults; read-only mocked execution, no gameplay.
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { sources, bundle } from './bundle.mjs';

const root = path.resolve(import.meta.dirname, '..');
const source = await sources(root);
const loaderPath = path.join(root, 'examples/Phase4OwnerDirectEggTeleport.luau');
const loader = await readFile(loaderPath, 'utf8');
const generated = bundle(source);
const expectedURL = `https://raw.githubusercontent.com/Whispfl/automation-/phase4-direct-${generated.buildId}/dist/OC.lua`;
assert.equal((loader.match(/https:\/\/raw\.githubusercontent\.com\//g) || []).length, 1, 'Exactly one public pinned fetch');
assert(loader.includes(expectedURL), 'Movement loader must pin the actual current source build; run build.mjs first');
assert(!/phase4-hatch-|Authorization|GitHubToken|\bFireServer\b|\bInvokeServer\b/.test(loader), 'No paid release or native transport in movement loader');
const mechanics = source.modules.find(module => module.name === 'GameMechanics').source;
assert.equal((mechanics.match(/fresh\.CharacterRoot\.CFrame = frame/g) || []).length, 1, 'Single guarded assignment retained');
const manager = source.modules.find(module => module.name === 'EggTravelManager').source;
assert(manager.includes('if diagnostic and self.DiagnosticConsumed and (self.DiagnosticEnded or not self.Lease) then'), 'Consumed diagnostic blocks all future selections');
assert(manager.includes('if diagnostic then self.DiagnosticConsumed = true self.DiagnosticEnded = false end'), 'Permission consumed before scheduler dispatch');
assert(manager.includes('self.DiagnosticEnded, self.Lease = true, nil'), 'Successful diagnostic ends location lease');
assert(manager.includes('One bounded TRAVEL_ONLY attempt consumed; no automatic retry or revision rearm'), 'No implicit retries or revision rearm');

const environment = (await readFile(path.join(root, 'tests/foundation.luau'), 'utf8')).split('-- BUNDLE INSERTION POINT')[0];
const harness = `
${environment}
${generated.library}
local Defaults = requireOC("OCConfig")
local Resolver = requireOC("ConfigResolver")
local currentId, fetches, initialized, fetchedURL = 10864747620, 0, 0, nil
local game = {}
function game:GetService(name)
	assert(name == "Players", "Loader must read only its account before initialization")
	return { LocalPlayer = currentId and { UserId = currentId } or nil }
end
function game:HttpGet(url) fetches += 1 fetchedURL = url return "MOCK_PUBLIC_BUNDLE" end
local function loadstring(value)
	assert(value == "MOCK_PUBLIC_BUNDLE")
	return function()
		return function(overrides) initialized += 1 return Resolver.Resolve(Defaults, overrides) end
	end
end
local function executeLoader()
${loader}
end
for _, id in ipairs({ 0, 1, 10864747621 }) do
	currentId = id
	local ok = pcall(executeLoader)
	assert(not ok and fetches == 0 and initialized == 0, "Wrong-account loader must reject before fetch/init")
end
currentId = nil
assert(not pcall(executeLoader) and fetches == 0 and initialized == 0, "Missing account fails closed")
currentId = 10864747620
local c = executeLoader()
assert(fetches == 1 and initialized == 1 and fetchedURL == ${JSON.stringify(expectedURL)}, "Exact owner uses one pinned fetch/init")
assert(c.GENERAL_SETTINGS.AUTO_START and c.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS)
assert(c.PET_SETTINGS.ENABLE_PET_INTELLIGENCE and c.PET_SETTINGS.OBJECTIVE_CURRENCY == "Coins")
assert(c.ACCOUNT_SETTINGS.ENABLE_ACCOUNT_READER and c.TASK_SETTINGS.ENABLE_TASK_SCHEDULER)
assert(c.EGG_TRAVEL_SETTINGS.MODE == "TRAVEL_ONLY" and c.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL)
assert(c.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING and not c.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL)
assert(c.EGG_TRAVEL_SETTINGS.OWNER_DIRECT_EGG_TELEPORT_TEST == true)
assert(Defaults.EGG_TRAVEL_SETTINGS.OWNER_DIRECT_EGG_TELEPORT_TEST == false, "Owner direct exception is OFF in ordinary defaults")
assert(c.EGG_TRAVEL_SETTINGS.MAXIMUM_ATTEMPTS_PER_SELECTION == 1 and c.EGG_TRAVEL_SETTINGS.SELECTION_REVISION == 0)
assert(c.EGG_TRAVEL_SETTINGS.STABILITY_SECONDS == 1 and c.EGG_TRAVEL_SETTINGS.ARRIVAL_TIMEOUT_SECONDS == 12)
assert(c.HATCH_SETTINGS.EGG_SELECTION_MODE == "MANUAL" and #c.HATCH_SETTINGS.SELECTED_EGGS == 1 and c.HATCH_SETTINGS.SELECTED_EGGS[1] == "Common Egg")
for category, keys in pairs({
	PET_SETTINGS = { "AUTO_HATCH", "AUTO_EQUIP", "EQUIP_OWNED_TEAM_ONCE", "AUTO_DELETE_PETS", "AUTO_CRAFT_SHINY", "AUTO_FUSE_PETS" },
	HATCH_SETTINGS = { "HATCH_ONE_EGG_ONCE", "ENABLE_BACKGROUND_PICKUPS" },
	OWNER_ONE_HATCH_TEST_SETTINGS = { "OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST", "OWNER_ONE_HATCH_TEST_ALLOWANCE" },
	WORLD_SETTINGS = { "ENABLE_WORLD_PROGRESSION", "AUTO_DISCOVER_ISLANDS", "AUTO_UNLOCK_WORLDS", "AUTO_TRAVEL_FOR_PROGRESSION", "AUTO_FARM_UNLOCK_REQUIREMENTS" },
	FARMING_SETTINGS = { "AUTO_RESOURCE_FARM", "AUTO_FARM_FALLBACK", "ISOLATED_PICKUP_PROBES", "ENABLE_EFFICIENCY_COMPARISON", "ENABLE_ACTIVITY_SWITCHING" },
	ISLAND_SETTINGS = { "AUTO_TRAVEL_BEST_ISLAND", "AUTO_EXPLORE_UNLOCKED_ISLANDS", "AUTO_SELECT_BEST_ISLAND" },
	PICKUP_SETTINGS = { "BULK_COLLECT_PICKUPS", "STATIONARY_ISOLATED_TEST", "ENABLE_CLUSTER_ROUTING", "ENABLE_CONTINUOUS_SCANNING" },
	BUBBLE_SETTINGS = { "AUTO_BLOW_BUBBLES", "AUTO_SELL_BUBBLES", "AUTO_BUY_GUM", "AUTO_BUY_FLAVORS", "ENABLE_SIMULTANEOUS_BLOWING" },
	UPGRADE_SETTINGS = { "ENABLE_SMART_UPGRADES", "ENABLE_CAPACITY_UPGRADES", "ENABLE_FLAVOR_UPGRADES", "AUTO_EQUIP_OWNED_UPGRADES" },
	FALL_EVENT_SETTINGS = { "ENABLE_FALL_EVENT", "AUTO_REBIRTH", "AUTO_BUY_REBIRTH_UPGRADES", "AUTO_USE_FALL_ELIXIRS", "AUTO_BUY_AUTUMN_SHOP_ITEMS" },
	PLAYTIME_SETTINGS = { "AUTO_CLAIM_PLAYTIME" },
	MYSTERY_BOX_SETTINGS = { "AUTO_OPEN_MYSTERY_BOXES", "ENABLE_AUTOMATIC_CONTINUATION" },
	ANTIAFK_SETTINGS = { "ENABLE_ANTI_AFK" },
}) do
	for _, key in ipairs(keys) do assert(c[category][key] == false, category .. "." .. key .. " must remain OFF") end
end
for category, keys in pairs({
	HATCH_SETTINGS = { "MAXIMUM_EGG_COST", "MAXIMUM_SESSION_COST" },
	OWNER_ONE_HATCH_TEST_SETTINGS = { "AUTHORIZED_ACCOUNT_ID", "MAXIMUM_COIN_ALLOWANCE", "MAXIMUM_EGG_COST" },
	WORLD_SETTINGS = { "MAXIMUM_WORLD_UNLOCK_COST" },
	UPGRADE_SETTINGS = { "MAXIMUM_PURCHASE_COST" },
}) do
	for _, key in ipairs(keys) do assert(c[category][key] == 0, category .. "." .. key .. " must remain zero") end
end
assert(c.HATCH_SETTINGS.PRESERVE_PROGRESSION_RESERVE and not c.HATCH_SETTINGS.LOG_EGG_DETAILS)
assert(c.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING and not c.DIAGNOSTIC_SETTINGS.ENABLE_DEBUG_LOGGING)
assert(c.DIAGNOSTIC_SETTINGS.LOG_MOVEMENT_DIAGNOSTICS and c.DIAGNOSTIC_SETTINGS.SUMMARY_INTERVAL_SECONDS == 15)
for _, key in ipairs({ "LOG_ACCOUNT_DETAILS", "LOG_PICKUP_DIAGNOSTICS", "LOG_UPGRADE_DIAGNOSTICS", "LOG_ISLAND_DISCOVERY", "LOG_DEPENDENCIES" }) do
	assert(c.DIAGNOSTIC_SETTINGS[key] == false, "Compact console defaults required")
end
assert(requireOC("OCBrain").new(c):TravelDiagnosticBlocker() == nil, "Actual Brain must accept isolated movement Config")
assert(c.HATCH_SETTINGS.MAXIMUM_SESSION_HATCHES == 1 and c.HATCH_SETTINGS.MAXIMUM_BATCH_HATCHES == 1
	and c.PET_SETTINGS.MAXIMUM_SESSION_EQUIP_COMMANDS == 1, "Existing runtime schema needs positive count ceilings; OFF flags and zero prices authorize no actions")
local controller = requireOC("OCController").new(Resolver.Resolve(c, { DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false } }))
assert(controller.Config.PET_SETTINGS.AUTO_HATCH == false and controller.Config.PET_SETTINGS.AUTO_EQUIP == false)
assert(controller.Config.HATCH_SETTINGS.MAXIMUM_SESSION_COST == 0 and controller.Config.UPGRADE_SETTINGS.MAXIMUM_PURCHASE_COST == 0)
controller:Destroy()
assert(Defaults.FARMING_SETTINGS.AUTO_RESOURCE_FARM and Defaults.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS, "Merged loader cannot mutate defaults")
print("[OC OWNER DIRECT LOADER] Actual merged Config and controller schema PASS; wrong/missing account blocks before fetch/init; one pinned public fetch; one travel attempt; all unrelated actions OFF and spending/allowance budgets zero. Positive dormant count ceilings required by existing schema provide no action permission.")
`;
await mkdir(path.join(root, '.test-output'), { recursive: true });
const file = path.join(root, '.test-output/phase4-owner-direct-loader.luau');
await writeFile(file, harness);
const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau/luau-compile.exe');
const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau/luau.exe');
const compiled = spawnSync(compiler, ['--null', loaderPath, file], { encoding: 'utf8' });
assert.equal(compiled.status, 0, compiled.stdout + compiled.stderr);
const run = spawnSync(executable, [file], { encoding: 'utf8' });
process.stdout.write(run.stdout);
process.stderr.write(run.stderr);
assert.equal(run.status, 0, 'Movement-only actual loader/merged Config verification must pass');
console.log('[OC OWNER DIRECT LOADER] Official Luau compilation PASS; existing one-assignment, consumed diagnostic and no-rearm contracts retained.');

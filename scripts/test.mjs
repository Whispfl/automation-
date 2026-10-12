import assert from 'node:assert/strict';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { sources, bundle } from './bundle.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = await sources(root);
const generated = bundle(source);
assert.equal(generated.output, await readFile(path.join(root, 'dist/OC.lua'), 'utf8'), 'dist/OC.lua is stale; rebuild it');
assert.equal(generated.output, bundle(source).output, 'Build must be deterministic');
assert(!/\bscript\./.test(generated.output), 'Bundle must not require a Script instance');
assert(!/Instance\.new\(["'](?:Script|LocalScript|ModuleScript)["']/.test(generated.output), 'Bundle must not install scripts');
for (const module of source.modules) {
  if (module.name !== 'GameMechanics') assert(!/\b(?:FireServer|InvokeServer)\b/.test(module.source), 'Only the verified native mechanics adapter may invoke gameplay commands');
  if (module.name !== 'GameMechanics' && module.name !== 'GameKnowledge') assert(!/\bfiretouchinterest\b/.test(module.source), 'Runtime contact belongs only to the mechanics adapter; knowledge may describe the contract');
}
const mechanics = source.modules.find(m => m.name === 'GameMechanics').source;
assert(!/\.(?:AreasUnlocked|WorldsUnlocked)\s*=(?!=)|\.(?:AreasUnlocked|WorldsUnlocked)\[[^\]]+\]\s*=(?!=)/.test(mechanics), 'Mechanics must never fabricate account unlock flags');
assert(!/PathfindingService|\bMoveTo\s*\(|\bMoveToFinished\b|\bPivotTo\s*\(/.test(generated.output), 'OC automatic navigation/repositioning must be absent');
const coordinatorSource = source.modules.find(m => m.name === 'FarmingCoordinator').source;
const brainSource = source.modules.find(m => m.name === 'OCBrain').source;
assert(brainSource.includes('FarmingPolicy.Decide(') && !brainSource.includes('CompareIncome'), 'Historical income comparison must not choose active gameplay tasks');
assert(!/\.Mechanics:Walk\s*\(/.test(coordinatorSource), 'No active farming or selling walking route');
assert(mechanics.includes('if registry[key] == model then registry[key] = nil end'), 'Cleanup must preserve replacement registry entries');
assert(mechanics.includes('chunker:Remove(pending.Position, model)'), 'Cleanup must release native Chunker references');
assert(!/getgc|(?:get|set)upvalue/.test(generated.output), 'No private runtime enumeration or upvalue manipulation');
assert(!/\._activePickups\s*=/.test(generated.output), 'OC must not replace the native pickup registry');
const positionAssignment = 'fresh.CharacterRoot.CFrame = frame';
assert.equal(mechanics.split(positionAssignment).length - 1, 1, 'Only one explicitly guarded selected-egg transform site');
assert(!/\b(?:CFrame|PivotTo|WalkSpeed)\s*=/.test(mechanics.replace(positionAssignment, '')), 'No other position or speed modification');
assert(!/GitHubToken|Authorization|\bRequest\s*=/.test(generated.output), 'No client authentication');
for (const { name, source: text } of source.modules) {
  if (name === 'OCConfig') for (const line of text.split('\n')) {
    if (/^\s+[A-Z][A-Z_]+\s*=/.test(line) && !line.endsWith('= {')) assert(line.includes('--//'), `Missing setting comment: ${line}`);
  }
}
console.log('[OC] Static bundle and configuration checks passed');

const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau.exe' : 'luau');
const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau-compile.exe' : 'luau-compile');
const compile = spawnSync(compiler, ['--null', ...source.modules.map(m => path.join(root, 'src/OCFoundation', m.name + '.luau')), path.join(root, 'src/OC.luau'), path.join(root, 'dist/OC.lua'), path.join(root, 'examples/Loader.luau'), path.join(root, 'examples/PickupOnly.luau'), path.join(root, 'examples/StationaryOnly.luau'), path.join(root, 'examples/CombinedFarming.luau'), path.join(root, 'examples/UpgradeTest.luau'), path.join(root, 'examples/Progression.luau'), path.join(root, 'examples/Pets.luau'), path.join(root, 'examples/PetEquipTest.luau'), path.join(root, 'examples/EggAnalysis.luau'), path.join(root, 'examples/HatchOnceTest.luau'), path.join(root, 'examples/LocalFeatureTests.luau'), path.join(root, 'dist/OC.local.lua')], { encoding: 'utf8' });
if (compile.error) throw new Error('Official Luau CLI is required. Set LUAU_BIN and LUAU_COMPILE_BIN. ' + compile.error.message);
process.stdout.write(compile.stdout);
process.stderr.write(compile.stderr);
assert.equal(compile.status, 0, 'Luau compilation failed');

await mkdir(path.join(root, '.test-output'), { recursive: true });
const harness = await readFile(path.join(root, 'tests/foundation.luau'), 'utf8');
const [environment, assertions] = harness.split('-- BUNDLE INSERTION POINT');
assert(assertions, 'Missing harness insertion point');
const testPath = path.join(root, '.test-output/foundation.luau');
const farmingAssertions = await readFile(path.join(root, 'tests/farming.luau'), 'utf8');
const fixesAssertions = await readFile(path.join(root, 'tests/phase2-fixes.luau'), 'utf8');
const pickupFirstAssertions = await readFile(path.join(root, 'tests/pickup-first.luau'), 'utf8');
const stationaryAssertions = await readFile(path.join(root, 'tests/stationary.luau'), 'utf8');
const goalAssertions = await readFile(path.join(root, 'tests/goal-driven.luau'), 'utf8');
const progressionAssertions = await readFile(path.join(root, 'tests/progression.luau'), 'utf8');
const discoveryAssertions = await readFile(path.join(root, 'tests/discovery.luau'), 'utf8');
const integrationAssertions = await readFile(path.join(root, 'tests/integration.luau'), 'utf8');
const economicsAssertions = await readFile(path.join(root, 'tests/economics.luau'), 'utf8');
const loggingAssertions = await readFile(path.join(root, 'tests/logging.luau'), 'utf8');
const petAssertions = await readFile(path.join(root, 'tests/pets.luau'), 'utf8');
const localFeatureAssertions = (await Promise.all(['egg-travel.luau','rewards.luau','anti-afk.luau','local-features.luau','phase4-roi.luau','phase4-hatch-integration.luau','phase4-travel-integration.luau','phase4-controller-integration.luau','phase4-pickups.luau'].map(name => readFile(path.join(root, 'tests',name),'utf8')))).join('\n');
function configPrefix(contents) {
  const call = contents.indexOf('loadstring(game:HttpGet(');
  assert(call >= 0, 'Example must use the public loader');
  return contents.slice(0, contents.lastIndexOf('\n', call) + 1);
}
const example = await readFile(path.join(root, 'examples/Loader.luau'), 'utf8');
const exampleConfig = configPrefix(example);
assert(exampleConfig.includes('local Config = {'), 'Copy-ready example is missing Config');
function assertFarmingSelection(contents) {
  assert(contents.includes('SELECTED_ISLANDS = { "The Void", "Zen" }'));
  assert(contents.includes('SELECTED_WORLDS = { "The Overworld" }'));
  assert(!/Floating Island|Outer Space/.test(contents));
}
assertFarmingSelection(exampleConfig);
const exampleCheck = `\nlocal exampleOverrides = (function()\n${exampleConfig}\nreturn Config\nend)()\nexampleOverrides.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING = false\nlocal exampleController = requireOC("OCController").new(config(exampleOverrides))\nassert(exampleController.Config.BUBBLE_SETTINGS.AUTO_BUY_GUM == false)\nexampleController:Destroy()\nprint("[OC TEST] Published example Config validation passed")\n`;
const pickupExample = await readFile(path.join(root, 'examples/PickupOnly.luau'), 'utf8');
const pickupConfig = configPrefix(pickupExample);
assertFarmingSelection(pickupConfig);
const pickupCheck = `\nlocal pickupOverrides = (function()\n${pickupConfig}\nreturn Config\nend)()\npickupOverrides.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING = false\nlocal pickupController = requireOC("OCController").new(config(pickupOverrides))\nassert(pickupController.Config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING)\nfor _, key in ipairs({ "AUTO_BLOW_BUBBLES", "AUTO_SELL_BUBBLES", "AUTO_BUY_GUM", "AUTO_BUY_FLAVORS", "ENABLE_SIMULTANEOUS_BLOWING" }) do assert(pickupController.Config.BUBBLE_SETTINGS[key] == false) end\nfor _, key in ipairs({ "ENABLE_SMART_UPGRADES", "ENABLE_CAPACITY_UPGRADES", "ENABLE_FLAVOR_UPGRADES", "AUTO_EQUIP_OWNED_UPGRADES" }) do assert(pickupController.Config.UPGRADE_SETTINGS[key] == false) end\npickupController:Destroy()\nprint("[OC TEST] Pickup-only example Config isolation passed")\n`;
await writeFile(testPath, environment + '\n' + generated.library + '\n' + assertions + '\n' + farmingAssertions + '\n' + fixesAssertions + '\n' + pickupFirstAssertions + '\n' + stationaryAssertions + '\n' + goalAssertions + '\n' + progressionAssertions + '\n' + discoveryAssertions + '\n' + integrationAssertions + '\n' + economicsAssertions + '\n' + loggingAssertions + '\n' + petAssertions + '\n' + localFeatureAssertions + '\nprint("[OC TEST] MAIN_SUITE_COUNT " .. tostring(tests))\n' + exampleCheck + pickupCheck);
const run = spawnSync(executable, [testPath], { encoding: 'utf8' });
process.stdout.write(run.stdout || '');
process.stderr.write(run.stderr || '');
assert.equal(run.status, 0, 'Foundation behavior tests failed');

for (const [filename, enabled] of [['StationaryOnly.luau', false], ['CombinedFarming.luau', false], ['UpgradeTest.luau', true], ['Progression.luau', false], ['Pets.luau', false], ['PetEquipTest.luau', false], ['EggAnalysis.luau', false], ['HatchOnceTest.luau', false]]) {
  const contents = await readFile(path.join(root, 'examples', filename), 'utf8');
  const configText = configPrefix(contents);
  if (filename === 'CombinedFarming.luau') {
    assertFarmingSelection(configText);
  }
  if (filename === 'StationaryOnly.luau' || filename === 'CombinedFarming.luau') {
    assertFarmingSelection(configText);
    assert(configText.includes('STATIONARY_ISOLATED_TEST = false'));
    assert(configText.includes('AUTO_TRAVEL_BEST_ISLAND = true') && configText.includes('PREFERRED_FARMING_ISLAND = ""'));
    for (const key of ['AUTO_EXPLORE_UNLOCKED_ISLANDS', 'AUTO_SELL_BUBBLES', 'AUTO_BLOW_BUBBLES', 'ENABLE_SMART_UPGRADES']) {
      assert(configText.includes(key + ' = false'), 'Initial stationary test must disable ' + key);
    }
  }
  if (filename === 'Progression.luau') {
    assert(configText.includes('ENABLE_DEBUG_LOGGING = false') && configText.includes('SUMMARY_INTERVAL_SECONDS = 15'));
    assert(configText.includes('AUTO_DISCOVER_ISLANDS = true'));
    for (const key of ['AUTO_UNLOCK_WORLDS', 'AUTO_TRAVEL_FOR_PROGRESSION', 'AUTO_SELL_BUBBLES', 'AUTO_BLOW_BUBBLES', 'ENABLE_SMART_UPGRADES']) assert(configText.includes(key + ' = false'));
    for (const key of ['AUTO_FARM_UNLOCK_REQUIREMENTS', 'AUTO_RESOURCE_FARM', 'AUTO_TRAVEL_BEST_ISLAND']) assert(configText.includes(key + ' = true'));
    assert(configText.includes('MAXIMUM_WORLD_UNLOCK_COST = 0'));
    assertFarmingSelection(configText);
  }
  if (filename === 'Pets.luau' || filename === 'PetEquipTest.luau') {
    assert(configText.includes('ENABLE_PET_INTELLIGENCE = true'));
    for (const key of ['AUTO_HATCH', 'AUTO_DELETE_PETS', 'AUTO_CRAFT_SHINY', 'AUTO_FUSE_PETS',
      'ENABLE_WORLD_PROGRESSION', 'AUTO_DISCOVER_ISLANDS', 'AUTO_UNLOCK_WORLDS', 'AUTO_TRAVEL_FOR_PROGRESSION',
      'AUTO_RESOURCE_FARM', 'AUTO_TRAVEL_BEST_ISLAND', 'AUTO_BLOW_BUBBLES', 'AUTO_SELL_BUBBLES', 'ENABLE_SMART_UPGRADES']) {
      assert(configText.includes(key + ' = false'), 'First pet intelligence test must disable ' + key);
    }
    assert(configText.includes('MAXIMUM_SESSION_COST = 0') && configText.includes('MAXIMUM_EGG_COST = 0'));
  }
  if (filename === 'Pets.luau') assert(configText.includes('AUTO_EQUIP = false') && configText.includes('EQUIP_OWNED_TEAM_ONCE = false'));
  if (filename === 'PetEquipTest.luau') assert(configText.includes('AUTO_EQUIP = true') && configText.includes('EQUIP_OWNED_TEAM_ONCE = true'));
  if (filename === 'EggAnalysis.luau' || filename === 'HatchOnceTest.luau') {
    assert(configText.includes('AUTO_EQUIP = false') && configText.includes('ENABLE_PET_INTELLIGENCE = true'));
    for (const key of ['AUTO_DELETE_PETS', 'AUTO_CRAFT_SHINY', 'AUTO_FUSE_PETS', 'ENABLE_WORLD_PROGRESSION',
      'AUTO_DISCOVER_ISLANDS', 'AUTO_UNLOCK_WORLDS', 'AUTO_TRAVEL_FOR_PROGRESSION', 'AUTO_FARM_UNLOCK_REQUIREMENTS',
      'AUTO_RESOURCE_FARM', 'AUTO_TRAVEL_BEST_ISLAND', 'AUTO_BLOW_BUBBLES', 'AUTO_SELL_BUBBLES', 'ENABLE_SMART_UPGRADES',
      'ENABLE_BACKGROUND_PICKUPS', 'BULK_COLLECT_PICKUPS']) assert(configText.includes(key + ' = false'));
    assert(configText.includes('PRESERVE_PROGRESSION_RESERVE = true'));
    assert(contents.includes('/migration-005f77211830/dist/OC.lua'), 'Historical migration examples retain their verified baseline pin');
    assert(configText.includes('AUTO_HATCH = false') && configText.includes('HATCH_ONE_EGG_ONCE = false') && configText.includes('MAXIMUM_EGG_COST = 0') && configText.includes('MAXIMUM_SESSION_COST = 0'));
    assert(configText.includes('SELECTED_EGGS = {}') && configText.includes('SELECTED_WORLDS = {}'), 'Analysis must not select a fixed egg or assume a world unlock');
  }
  const check = `\nlocal overrides = (function()\n${configText}\nreturn Config\nend)()\noverrides.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING = false\nlocal instance = requireOC("OCController").new(config(overrides))\nassert(instance.Config.BUBBLE_SETTINGS.AUTO_BUY_GUM == ${enabled})\nassert(instance.Config.UPGRADE_SETTINGS.AUTO_EQUIP_OWNED_UPGRADES == ${enabled})\ninstance:Destroy()\nprint("[OC TEST] ${filename} Config validation passed")\n`;
  await writeFile(testPath, environment + '\n' + generated.library + '\n' + assertions + check);
  const exampleRun = spawnSync(executable, [testPath], { encoding: 'utf8' });
  process.stdout.write(exampleRun.stdout || '');
  process.stderr.write(exampleRun.stderr || '');
  assert.equal(exampleRun.status, 0, filename + ' Config validation failed');
}

const entryTestPath = path.join(root, '.test-output/bundle-entry.luau');
await writeFile(entryTestPath, environment + '\nlocal shared = {}\nlocal function loadBundle()\n' + generated.output + `\nend
-- Offline environment only: no server profile and no synthetic account statistics.
services.Players.LocalPlayer = {}
local initialize = loadBundle()
assert(type(initialize) == "function", "Generated bundle must return an initializer")
local controller = initialize({
  GENERAL_SETTINGS = { AUTO_START = false },
  STATUS_UI_SETTINGS = { ENABLE_STATUS_UI = false },
  DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false },
})
assert(controller.Config.GENERAL_SETTINGS.AUTO_START == false, "Config override was not used")
assert(controller.Reader and controller.Brain and controller.Scheduler and controller.Interface, "Missing foundation module")
assert(controller.Interface.Gui == nil, "Disabled UI must not create a panel")
assert(not controller:GetStatus().Snapshot.Ready and controller:GetStatus().Snapshot.Balances.Coins == nil, "Missing data must stay unknown")
controller:Destroy()
local oldMechanics = { AntiAFKHeldInput = {}, ReleaseAntiAFKInput = function() return false, "Synthetic keyUp rejected" end }
local prior = { Farming = { Mechanics = oldMechanics }, Destroy = function(self) self.Destroyed = true end }
shared.__OC_PHASE1_INSTANCE = prior
local opts = { GENERAL_SETTINGS = { AUTO_START = false }, STATUS_UI_SETTINGS = { ENABLE_STATUS_UI = false },
  DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false } }
local replaced, failure = pcall(initialize, opts)
assert(not replaced and tostring(failure):find("replacement/start blocked", 1, true))
assert(shared.__OC_PHASE1_INSTANCE == prior and oldMechanics.AntiAFKHeldInput ~= nil and prior.Destroyed)
oldMechanics.ReleaseAntiAFKInput = function(self) self.AntiAFKHeldInput = nil return true end
local replacement = initialize(opts)
assert(shared.__OC_PHASE1_INSTANCE == replacement and oldMechanics.AntiAFKHeldInput == nil)
replacement:Destroy()
print("[OC TEST] Actual initializer retains uncertain input cleanup barrier across reload and retries only cleanup passed.")
print("[OC TEST] Actual bundled initializer and custom Config entry passed. Live statistics remain unverified.")
`);
const entryRun = spawnSync(executable, [entryTestPath], { encoding: 'utf8' });
process.stdout.write(entryRun.stdout || '');
process.stderr.write(entryRun.stderr || '');
assert.equal(entryRun.status, 0, 'Actual bundle initializer test failed');

// Verify local artifact byte equivalence and every selectable test Config.
const localHeader = await readFile(path.join(root, 'examples/LocalFeatureTests.luau'),'utf8');
const localArtifact = await readFile(path.join(root, 'dist/OC.local.lua'),'utf8');
const expectedLocal = localHeader + `\n-- Local build: ${generated.buildId}. Complete embedded bundle; no download.\nlocal function initializeLocalBundle()\n${generated.output}\nend\nlocal OC = initializeLocalBundle()(Config)\nreturn OC\n`;
assert.equal(localArtifact, expectedLocal, 'Paste-ready bundle/header must match the tested build');
assert(!/HttpGet\s*\(|raw\.githubusercontent|loadstring\s*\(|readfile\s*\(|loadfile\s*\(/.test(localArtifact.replace(/^--.*$/gm,'')), 'Local artifact must download no code or require filesystem loader APIs');
for (const mode of ['NONE','A_TRAVEL','B_PLAYTIME','C_ONE_BOX','D_ANTI_AFK']) {
 const header = localHeader.replace('local TEST_MODE = "NONE"',`local TEST_MODE = "${mode}"`);
 const check = `\nlocal options=(function()\n${header}\nreturn Config\nend)()\noptions.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING=false\nlocal localController=requireOC("OCController").new(config(options))\nassert(not localController.Config.PET_SETTINGS.AUTO_HATCH and not localController.Config.PET_SETTINGS.AUTO_EQUIP)\nassert(not localController.Config.FARMING_SETTINGS.AUTO_RESOURCE_FARM and not localController.Config.WORLD_SETTINGS.AUTO_UNLOCK_WORLDS)\nassert(localController.Config.HATCH_SETTINGS.MAXIMUM_SESSION_COST==0)\nlocalController:Destroy()\nprint("[OC TEST] Local selectable ${mode} Config isolation passed")\n`;
 await writeFile(testPath,environment+'\n'+generated.library+'\n'+assertions+check);
 const result=spawnSync(executable,[testPath],{encoding:'utf8'});process.stdout.write(result.stdout||'');process.stderr.write(result.stderr||'');assert.equal(result.status,0,'Local Config '+mode+' failed');
}

// The migration check must retain action isolation after central defaults merge.
const migrationExample = await readFile(path.join(root, 'examples/MigrationVerify.luau'), 'utf8');
const migrationConfig = configPrefix(migrationExample);
const migrationCompile = spawnSync(compiler, ['--null', path.join(root, 'examples/MigrationVerify.luau')], { encoding: 'utf8' });
assert.equal(migrationCompile.status, 0, 'Migration verification loader must compile: ' + migrationCompile.stderr);
assert(migrationExample.includes('/Whispfl/automation-/migration-005f77211830/dist/OC.lua'), 'Historical migration loader retains its known-good baseline pin');
const migrationCheck = `
local options = (function()
${migrationConfig}
return Config
end)()
options.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING = false
local instance = requireOC("OCController").new(config(options))
local disabled = {
 WORLD_SETTINGS = { "ENABLE_WORLD_PROGRESSION", "AUTO_DISCOVER_ISLANDS", "AUTO_UNLOCK_WORLDS", "AUTO_TRAVEL_FOR_PROGRESSION", "AUTO_FARM_UNLOCK_REQUIREMENTS" },
 FARMING_SETTINGS = { "AUTO_RESOURCE_FARM", "AUTO_FARM_FALLBACK" },
 ISLAND_SETTINGS = { "AUTO_TRAVEL_BEST_ISLAND", "AUTO_EXPLORE_UNLOCKED_ISLANDS" },
 PICKUP_SETTINGS = { "BULK_COLLECT_PICKUPS", "STATIONARY_ISOLATED_TEST" },
 BUBBLE_SETTINGS = { "AUTO_BLOW_BUBBLES", "AUTO_SELL_BUBBLES", "AUTO_BUY_GUM", "AUTO_BUY_FLAVORS", "ENABLE_SIMULTANEOUS_BLOWING" },
 UPGRADE_SETTINGS = { "ENABLE_SMART_UPGRADES", "ENABLE_CAPACITY_UPGRADES", "ENABLE_FLAVOR_UPGRADES", "AUTO_EQUIP_OWNED_UPGRADES" },
 PET_SETTINGS = { "ENABLE_PET_INTELLIGENCE", "AUTO_HATCH", "AUTO_EQUIP", "EQUIP_OWNED_TEAM_ONCE", "AUTO_DELETE_PETS", "AUTO_CRAFT_SHINY", "AUTO_FUSE_PETS" },
 HATCH_SETTINGS = { "HATCH_ONE_EGG_ONCE", "ENABLE_BACKGROUND_PICKUPS" },
 EGG_TRAVEL_SETTINGS = { "ENABLE_SELECTED_EGG_TRAVEL", "ENABLE_DIRECT_POSITIONING", "ENABLE_NATIVE_ISLAND_TRAVEL" },
 PLAYTIME_SETTINGS = { "AUTO_CLAIM_PLAYTIME" },
 MYSTERY_BOX_SETTINGS = { "AUTO_OPEN_MYSTERY_BOXES", "ENABLE_AUTOMATIC_CONTINUATION" },
 ANTIAFK_SETTINGS = { "ENABLE_ANTI_AFK" },
 FALL_EVENT_SETTINGS = { "ENABLE_FALL_EVENT", "AUTO_REBIRTH", "AUTO_BUY_REBIRTH_UPGRADES", "AUTO_USE_FALL_ELIXIRS", "AUTO_BUY_AUTUMN_SHOP_ITEMS" },
}
for category, keys in pairs(disabled) do
 for _, key in ipairs(keys) do assert(instance.Config[category][key] == false, category .. "." .. key .. " must be OFF") end
end
assert(instance.Config.HATCH_SETTINGS.MAXIMUM_EGG_COST == 0 and instance.Config.HATCH_SETTINGS.MAXIMUM_SESSION_COST == 0)
assert(instance.Config.WORLD_SETTINGS.MAXIMUM_WORLD_UNLOCK_COST == 0)
instance:Destroy()
print("[OC TEST] Migration verification Config: all action permissions OFF after default merge; spending budgets zero")
`;
await writeFile(testPath, environment + '\n' + generated.library + '\n' + assertions + migrationCheck);
const migrationRun = spawnSync(executable, [testPath], { encoding: 'utf8' });
process.stdout.write(migrationRun.stdout || '');
process.stderr.write(migrationRun.stderr || '');
assert.equal(migrationRun.status, 0, 'Migration verification Config isolation failed');

const autoOnceExample = await readFile(path.join(root, 'examples/Phase4AutoOnce.luau'), 'utf8');
const autoOnceConfig = configPrefix(autoOnceExample);
assert(autoOnceExample.includes('/Whispfl/automation-/phase4-auto-' + generated.buildId + '/dist/OC.lua'), 'AUTO example must pin the matching candidate');
const autoOnceCompile = spawnSync(compiler, ['--null', path.join(root, 'examples/Phase4AutoOnce.luau')], { encoding: 'utf8' });
assert.equal(autoOnceCompile.status, 0, 'AUTO one-hatch loader must compile: ' + autoOnceCompile.stderr);
const autoOnceCheck = `
local options = (function()
${autoOnceConfig}
return Config
end)()
options.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING = false
local instance = requireOC("OCController").new(config(options))
local settings = instance.Config
assert(settings.PET_SETTINGS.ENABLE_PET_INTELLIGENCE and settings.PET_SETTINGS.AUTO_HATCH)
assert(settings.HATCH_SETTINGS.EGG_SELECTION_MODE == "AUTO" and #settings.HATCH_SETTINGS.SELECTED_EGGS == 0)
assert(settings.HATCH_SETTINGS.HATCH_ONE_EGG_ONCE and settings.HATCH_SETTINGS.MAXIMUM_SESSION_HATCHES == 1 and settings.HATCH_SETTINGS.MAXIMUM_BATCH_HATCHES == 1)
assert(settings.HATCH_SETTINGS.MAXIMUM_EGG_COST == 1000000 and settings.HATCH_SETTINGS.MAXIMUM_SESSION_COST == 1000000 and settings.HATCH_SETTINGS.PRESERVE_PROGRESSION_RESERVE)
assert(settings.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL and settings.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL and settings.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING)
local disabled = {
 WORLD_SETTINGS = { "ENABLE_WORLD_PROGRESSION", "AUTO_DISCOVER_ISLANDS", "AUTO_UNLOCK_WORLDS", "AUTO_TRAVEL_FOR_PROGRESSION", "AUTO_FARM_UNLOCK_REQUIREMENTS" },
 FARMING_SETTINGS = { "AUTO_RESOURCE_FARM", "AUTO_FARM_FALLBACK" },
 ISLAND_SETTINGS = { "AUTO_TRAVEL_BEST_ISLAND", "AUTO_EXPLORE_UNLOCKED_ISLANDS" },
 PICKUP_SETTINGS = { "BULK_COLLECT_PICKUPS", "STATIONARY_ISOLATED_TEST" },
 BUBBLE_SETTINGS = { "AUTO_BLOW_BUBBLES", "AUTO_SELL_BUBBLES", "AUTO_BUY_GUM", "AUTO_BUY_FLAVORS", "ENABLE_SIMULTANEOUS_BLOWING" },
 UPGRADE_SETTINGS = { "ENABLE_SMART_UPGRADES", "ENABLE_CAPACITY_UPGRADES", "ENABLE_FLAVOR_UPGRADES", "AUTO_EQUIP_OWNED_UPGRADES" },
 PET_SETTINGS = { "AUTO_EQUIP", "EQUIP_OWNED_TEAM_ONCE", "AUTO_DELETE_PETS", "AUTO_CRAFT_SHINY", "AUTO_FUSE_PETS" },
 HATCH_SETTINGS = { "ENABLE_BACKGROUND_PICKUPS" },
 PLAYTIME_SETTINGS = { "AUTO_CLAIM_PLAYTIME" },
 MYSTERY_BOX_SETTINGS = { "AUTO_OPEN_MYSTERY_BOXES", "ENABLE_AUTOMATIC_CONTINUATION" },
 ANTIAFK_SETTINGS = { "ENABLE_ANTI_AFK" },
 FALL_EVENT_SETTINGS = { "ENABLE_FALL_EVENT", "AUTO_REBIRTH", "AUTO_BUY_REBIRTH_UPGRADES", "AUTO_USE_FALL_ELIXIRS", "AUTO_BUY_AUTUMN_SHOP_ITEMS" },
}
for category, keys in pairs(disabled) do for _, key in ipairs(keys) do assert(settings[category][key] == false, category .. "." .. key .. " must be OFF") end end
assert(settings.WORLD_SETTINGS.MAXIMUM_WORLD_UNLOCK_COST == 0)
instance:Destroy()
print("[OC TEST] AUTO one-hatch Config: one request/count, protected reserves and unrelated actions OFF after default merge")
`;
await writeFile(testPath, environment + '\n' + generated.library + '\n' + assertions + autoOnceCheck);
const autoOnceRun = spawnSync(executable, [testPath], { encoding: 'utf8' });
process.stdout.write(autoOnceRun.stdout || '');
process.stderr.write(autoOnceRun.stderr || '');
assert.equal(autoOnceRun.status, 0, 'AUTO one-hatch Config isolation failed');

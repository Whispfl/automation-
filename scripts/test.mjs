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
assert(!/\b(?:CFrame|PivotTo|WalkSpeed)\s*=/.test(mechanics), 'No position or speed modification');
assert(!/GitHubToken|Authorization|\bRequest\s*=/.test(generated.output), 'No client authentication');
for (const { name, source: text } of source.modules) {
  if (name === 'OCConfig') for (const line of text.split('\n')) {
    if (/^\s+[A-Z][A-Z_]+\s*=/.test(line) && !line.endsWith('= {')) assert(line.includes('--//'), `Missing setting comment: ${line}`);
  }
}
console.log('[OC] Static bundle and configuration checks passed');

const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau.exe' : 'luau');
const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau-compile.exe' : 'luau-compile');
const compile = spawnSync(compiler, ['--null', ...source.modules.map(m => path.join(root, 'src/OCFoundation', m.name + '.luau')), path.join(root, 'src/OC.luau'), path.join(root, 'dist/OC.lua'), path.join(root, 'examples/Loader.luau'), path.join(root, 'examples/PickupOnly.luau'), path.join(root, 'examples/StationaryOnly.luau'), path.join(root, 'examples/CombinedFarming.luau'), path.join(root, 'examples/UpgradeTest.luau'), path.join(root, 'examples/Progression.luau'), path.join(root, 'examples/Pets.luau'), path.join(root, 'examples/PetEquipTest.luau'), path.join(root, 'examples/EggAnalysis.luau'), path.join(root, 'examples/HatchOnceTest.luau')], { encoding: 'utf8' });
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
await writeFile(testPath, environment + '\n' + generated.library + '\n' + assertions + '\n' + farmingAssertions + '\n' + fixesAssertions + '\n' + pickupFirstAssertions + '\n' + stationaryAssertions + '\n' + goalAssertions + '\n' + progressionAssertions + '\n' + discoveryAssertions + '\n' + integrationAssertions + '\n' + economicsAssertions + '\n' + loggingAssertions + '\n' + petAssertions + exampleCheck + pickupCheck);
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
    assert(contents.includes('/phase4-hatch-' + generated.buildId + '/dist/OC.lua'), 'Hatch example must pin this tested bundle release');
    if (filename === 'EggAnalysis.luau') assert(configText.includes('AUTO_HATCH = false') && configText.includes('MAXIMUM_EGG_COST = 0') && configText.includes('MAXIMUM_SESSION_COST = 0'));
    else assert(configText.includes('HATCH_ONE_EGG_ONCE = true') && configText.includes('MAXIMUM_SESSION_HATCHES = 1') && configText.includes('MAXIMUM_EGG_COST = 75000') && configText.includes('MAXIMUM_SESSION_COST = 75000'));
  }
  const check = `\nlocal overrides = (function()\n${configText}\nreturn Config\nend)()\noverrides.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING = false\nlocal instance = requireOC("OCController").new(config(overrides))\nassert(instance.Config.BUBBLE_SETTINGS.AUTO_BUY_GUM == ${enabled})\nassert(instance.Config.UPGRADE_SETTINGS.AUTO_EQUIP_OWNED_UPGRADES == ${enabled})\ninstance:Destroy()\nprint("[OC TEST] ${filename} Config validation passed")\n`;
  await writeFile(testPath, environment + '\n' + generated.library + '\n' + assertions + check);
  const exampleRun = spawnSync(executable, [testPath], { encoding: 'utf8' });
  process.stdout.write(exampleRun.stdout || '');
  process.stderr.write(exampleRun.stderr || '');
  assert.equal(exampleRun.status, 0, filename + ' Config validation failed');
}

const entryTestPath = path.join(root, '.test-output/bundle-entry.luau');
await writeFile(entryTestPath, environment + '\nlocal function loadBundle()\n' + generated.output + `\nend
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
print("[OC TEST] Actual bundled initializer and custom Config entry passed. Live statistics remain unverified.")
`);
const entryRun = spawnSync(executable, [entryTestPath], { encoding: 'utf8' });
process.stdout.write(entryRun.stdout || '');
process.stderr.write(entryRun.stderr || '');
assert.equal(entryRun.status, 0, 'Actual bundle initializer test failed');

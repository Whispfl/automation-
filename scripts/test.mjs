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
assert(!/\b(?:FireServer|InvokeServer)\b/.test(generated.output), 'Phase 1 must not call gameplay remotes');
for (const { name, source: text } of source.modules) {
  if (name === 'OCConfig') for (const line of text.split('\n')) {
    if (/^\s+[A-Z][A-Z_]+\s*=/.test(line) && !line.endsWith('= {')) assert(line.includes('--//'), `Missing setting comment: ${line}`);
  }
}
console.log('[OC] Static bundle and configuration checks passed');

const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau.exe' : 'luau');
const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau-compile.exe' : 'luau-compile');
const compile = spawnSync(compiler, ['--null', ...source.modules.map(m => path.join(root, 'src/OCFoundation', m.name + '.luau')), path.join(root, 'src/OC.luau'), path.join(root, 'dist/OC.lua')], { encoding: 'utf8' });
if (compile.error) throw new Error('Official Luau CLI is required. Set LUAU_BIN and LUAU_COMPILE_BIN. ' + compile.error.message);
process.stdout.write(compile.stdout);
process.stderr.write(compile.stderr);
assert.equal(compile.status, 0, 'Luau compilation failed');

await mkdir(path.join(root, '.test-output'), { recursive: true });
const harness = await readFile(path.join(root, 'tests/foundation.luau'), 'utf8');
const [environment, assertions] = harness.split('-- BUNDLE INSERTION POINT');
assert(assertions, 'Missing harness insertion point');
const testPath = path.join(root, '.test-output/foundation.luau');
await writeFile(testPath, environment + '\n' + generated.library + '\n' + assertions);
const run = spawnSync(executable, [testPath], { encoding: 'utf8' });
process.stdout.write(run.stdout || '');
process.stderr.write(run.stderr || '');
assert.equal(run.status, 0, 'Foundation behavior tests failed');

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

// Actual-source synthetic free-ticket lifecycle and receipt checks. No live Roblox actions.
import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { bundle, sources } from './bundle.mjs';
import { verifyFreeWheelTicketWorkspace } from './verify-phase5-free-wheel-ticket.mjs';

const root = path.resolve(import.meta.dirname, '..');
verifyFreeWheelTicketWorkspace();
const source = await sources(root);
const generated = bundle(source);
const environment = (await readFile(path.join(root, 'tests/foundation.luau'), 'utf8')).split('-- BUNDLE INSERTION POINT')[0];
const fixture = await readFile(path.join(root, 'tests/phase5-free-wheel-ticket.luau'), 'utf8');
const loaderPath = path.join(root, 'examples/Phase5FreeWheelTicketDisabled.luau');
const loader = await readFile(loaderPath, 'utf8');
const expectedURL = `https://raw.githubusercontent.com/Whispfl/automation-/phase5-free-wheel-ticket-${generated.buildId}/dist/OC.lua`;
assert.equal((loader.match(/game:HttpGet\(/g) || []).length, 1, 'Disabled candidate performs one public bundle fetch');
assert(loader.includes(`game:HttpGet("${expectedURL}")`), 'Disabled candidate uses the exact immutable public build pin');
assert(!/\b(?:GitHubToken|Authorization|FireServer|InvokeServer)\b/.test(loader), 'Disabled loader has no credentials or native action transport');
const loaderCall = loader.indexOf('local OC = loadstring(game:HttpGet(');
assert(loaderCall >= 0, 'Disabled candidate loads the function-returning bundle');
const loaderPrefix = loader.slice(0, loaderCall);
await mkdir(path.join(root, '.test-output'), { recursive: true });
const file = path.join(root, '.test-output/phase5-free-wheel-ticket.luau');
await writeFile(file, `${environment}\nlocal shared = {}\n${generated.library}\nlocal function phase5FreeWheelTicketDisabledOverrides()\n${loaderPrefix}\nreturn Config\nend\n${fixture}`);
const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau-compile.exe' : 'luau-compile');
const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau.exe' : 'luau');
const compile = spawnSync(compiler, ['--null',
  path.join(root, 'src/OCFoundation/RewardsManager.luau'),
  path.join(root, 'src/OCFoundation/GameMechanics.luau'),
  path.join(root, 'src/OCFoundation/GameKnowledge.luau'), loaderPath, file], { encoding: 'utf8' });
if (compile.error) throw compile.error;
assert.equal(compile.status, 0, compile.stdout + compile.stderr);
const run = spawnSync(executable, [file], { encoding: 'utf8' });
if (run.error) throw run.error;
process.stdout.write(run.stdout || '');
process.stderr.write(run.stderr || '');
assert.equal(run.status, 0, 'Free wheel-ticket actual-source synthetic contract suite must pass');
console.log('[OC FREE WHEEL] Official Luau compilation PASS; bounded authorization/receipt/lifecycle contracts PASS; live claim remains unapproved.');

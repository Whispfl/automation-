// Pure native-schema/received-grant checks. No network, account reads or actions.
import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const sourcePath = path.join(root, 'src/OCFoundation/WheelSpinPolicy.luau');
const policy = await readFile(sourcePath, 'utf8');
assert(!/\b(?:game|workspace|task|shared|FireServer|InvokeServer|loadstring)\b/.test(policy), 'Wheel receipt policy remains pure and cannot dispatch or read live data');
const tests = await readFile(path.join(root, 'tests/phase5-wheel-spin.luau'), 'utf8');
await mkdir(path.join(root, '.test-output'), { recursive: true });
const file = path.join(root, '.test-output/phase5-wheel-spin.luau');
await writeFile(file, `local WheelSpinPolicy = (function()\n${policy}\nend)()\n${tests}`);
const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau-compile.exe' : 'luau-compile');
const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau.exe' : 'luau');
const compiled = spawnSync(compiler, ['--null', sourcePath, file], { encoding: 'utf8' });
if (compiled.error) throw compiled.error;
assert.equal(compiled.status, 0, compiled.stdout + compiled.stderr);
const run = spawnSync(executable, [file], { encoding: 'utf8' });
if (run.error) throw run.error;
process.stdout.write(run.stdout || ''); process.stderr.write(run.stderr || '');
assert.equal(run.status, 0, 'Pure received-state wheel spin policy tests must pass');
console.log('[OC WHEEL SPIN] Official Luau compilation PASS; pure accounting contracts PASS; no protected methods or live actions modified.');

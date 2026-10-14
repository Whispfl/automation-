// Execute the complete disabled owner loader with only its bundle initializer
// replaced. Native observations are synthetic; no network or game action occurs.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { bundle, sources } from './bundle.mjs';

const root = path.resolve(import.meta.dirname, '..');
const sha = value => createHash('sha256').update(value).digest('hex');
export async function verifyWheelSpinDisabledLoader() {
  const loaderPath = path.join(root, 'examples/Phase5WheelSpinDisabled.luau');
  const bytes = await readFile(loaderPath), loader = bytes.toString('utf8');
  const matched = loader.match(/local OC = loadstring\(game:HttpGet\("(https:\/\/raw\.githubusercontent\.com\/Whispfl\/automation-\/phase5-wheel-spin-[A-Za-z0-9]+\/dist\/OC\.lua)"\)\)\(\)\(Config\)/);
  assert(matched, 'Owner loader keeps one public candidate bundle initialization');
  assert.equal((loader.match(/game:HttpGet\(/g) || []).length, 1, 'One anonymous bundle fetch only');
  assert(!/\b(?:GitHubToken|FireServer|InvokeServer|SetAttribute)\b|["']Authorization["']\s*[:=]/.test(loader), 'Disabled loader contains no credentials, native transport or state mutation');
  assert(!/:\s*(?:Start|Resume|Select|Prepare|InitializeWheelSpin|PrepareWheelSpin|MarkWheelSpinDispatched|SpinWheelOnce)\s*\(/.test(loader), 'Preflight must not select/initialize/prepare/start any gameplay action');
  const executableLoader = loader.replace(matched[0], 'local OC = wheelSpinLoaderMockInit(Config)');
  const environment = (await readFile(path.join(root, 'tests/foundation.luau'), 'utf8')).split('-- BUNDLE INSERTION POINT')[0];
  const managerFixture = await readFile(path.join(root, 'tests/phase5-wheel-spin-manager.luau'), 'utf8');
  const managerPrefix = managerFixture.slice(0, managerFixture.indexOf('test("disabled extension'));
  assert(managerPrefix.includes('local function fixture(options)'), 'Reuse actual manager/native-data fixture definitions');
  const oldDisabled = await readFile(path.join(root, 'examples/Phase5FreeWheelTicketDisabled.luau'), 'utf8');
  const oldPrefix = oldDisabled.slice(0, oldDisabled.indexOf('local OC = loadstring'));
  const generated = bundle(await sources(root));
  const tests = await readFile(path.join(root, 'tests/phase5-wheel-spin-loader.luau'), 'utf8');
  await mkdir(path.join(root, '.test-output'), { recursive: true });
  const file = path.join(root, '.test-output/phase5-wheel-spin-loader.luau');
  await writeFile(file, `${environment}\nlocal shared = {}\n${generated.library}\nlocal function phase5WheelSpinManagerOverrides()\n${oldPrefix}\nreturn Config\nend\n${managerPrefix}\nlocal wheelSpinLoaderScene\nlocal function wheelSpinLoaderMockInit(config) return wheelSpinLoaderScene:Load(config) end\nlocal function executeDisabledWheelSpinLoader()\n${executableLoader}\nend\n${tests}`);
  const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau-compile.exe' : 'luau-compile');
  const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau.exe' : 'luau');
  const compiled = spawnSync(compiler, ['--null', loaderPath, file], { encoding: 'utf8' });
  if (compiled.error) throw compiled.error;
  assert.equal(compiled.status, 0, compiled.stdout + compiled.stderr);
  const run = spawnSync(executable, [file], { encoding: 'utf8' });
  if (run.error) throw run.error;
  process.stdout.write(run.stdout || ''); process.stderr.write(run.stderr || '');
  assert.equal(run.status, 0, 'Complete disabled owner loader checks must pass');
  assert.equal(sha(await readFile(loaderPath)), sha(bytes), 'Offline fixtures never rewrite the owner loader');
  console.log('[OC WHEEL SPIN LOADER] Official Luau compilation PASS; complete stopped zero-action loader PASS; separate live approval still required.');
  return { status: 'PASS', loaderSha256: sha(bytes), fixtureSha256: sha(tests), stdoutSha256: sha(run.stdout || '') };
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await verifyWheelSpinDisabledLoader();

// Review-only proof. Apply the documented proposal IN MEMORY, compile/run offline
// mocks, and assert production source/bundles stayed unchanged. No live runtime.
import assert from 'node:assert/strict';
import { readFile, writeFile, readdir, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { sources, bundle } from './bundle.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const directory = path.join(root, '.test-output/first-hatch-proposal');
const names = ['OCConfig', 'PetPolicy', 'OCBrain'];
const digest = value => createHash('sha256').update(value).digest('hex');
const normalized = value => value.replace(/\r\n/g, '\n');
const patchPath = path.join(root, 'docs/PHASE4-FUNCTIONAL-HATCH-EXCEPTION-PROPOSED.patch');
const patchBytes = await readFile(patchPath);
const proof = JSON.parse(await readFile(path.join(root, 'docs/PHASE4-FUNCTIONAL-HATCH-EXCEPTION-PROPOSED-HASHES.json'), 'utf8'));
assert.equal(proof.Status, 'CONTINGENT_PROPOSAL_ONLY_NOT_APPLIED_NOT_AUTHORIZED');
assert.equal(digest(patchBytes), proof.PatchSha256);
assert.equal(proof.PatchSha256, '4dc7fc10a1532a2c6be2d7ef5c5e5f9fffc97fd699185098f985bc4da6d65e9d');
const check = spawnSync('git', ['apply', '--check', patchPath], { cwd: root, encoding: 'utf8' });
assert.equal(check.status, 0, 'Unapplied proposal must match current source: ' + check.stderr);
await mkdir(directory, { recursive: true });

async function runtimeHashes() {
  const files = ['src/OC.luau', 'dist/OC.lua', 'dist/OC.local.lua',
    ...(await readdir(path.join(root, 'src/OCFoundation'))).filter(n => n.endsWith('.luau')).map(n => 'src/OCFoundation/' + n)];
  return Object.fromEntries(await Promise.all(files.map(async file => [file, digest(await readFile(path.join(root, file)))])));
}

// Exact unified-hunk application to strings only. Check every original line and
// proposed hash; never invoke `git apply` without its read-only --check option.
const proposed = new Map();
for (const section of normalized(patchBytes.toString()).split(/(?=^diff --git )/m).filter(Boolean)) {
  const lines = section.trimEnd().split('\n');
  const header = lines[0].match(/^diff --git a\/(.+) b\/(.+)$/);
  assert(header && header[1] === header[2]);
  const file = header[1], name = path.basename(file, '.luau');
  assert(names.includes(name) && file === `src/OCFoundation/${name}.luau` && !proposed.has(name));
  assert.equal(lines[1], `--- a/${file}`); assert.equal(lines[2], `+++ b/${file}`);
  const originalText = normalized(await readFile(path.join(root, file), 'utf8'));
  assert.equal(digest(originalText), proof.Files[file].BeforeSha256);
  const original = originalText.trimEnd().split('\n'), result = [];
  let previous = 0, cursor = 3;
  while (cursor < lines.length) {
    const hunk = lines[cursor++].match(/^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/);
    assert(hunk, 'Unsupported proposal hunk');
    const start = Number(hunk[1]) - 1, oldCount = Number(hunk[2] ?? 1), newCount = Number(hunk[4] ?? 1);
    assert(start >= previous);
    result.push(...original.slice(previous, start));
    assert.equal(result.length + 1, Number(hunk[3]));
    let oldIndex = start, newLines = 0;
    while (cursor < lines.length && !lines[cursor].startsWith('@@ ')) {
      const line = lines[cursor++], kind = line[0], value = line.slice(1);
      assert([' ', '+', '-'].includes(kind), 'Unsupported proposal line');
      if (kind !== '+') { assert.equal(original[oldIndex], value, 'Changed proposal base line'); oldIndex++; }
      if (kind !== '-') { result.push(value); newLines++; }
    }
    assert.equal(oldIndex - start, oldCount); assert.equal(newLines, newCount);
    previous = oldIndex;
  }
  result.push(...original.slice(previous));
  const after = result.join('\n') + '\n';
  assert.equal(digest(after), proof.Files[file].AfterSha256);
  proposed.set(name, after);
}
assert.deepEqual([...proposed.keys()].sort(), [...names].sort());
const before = await runtimeHashes();
const source = await sources(root);
for (const name of names) {
  source.modules.find(m => m.name === name).source = proposed.get(name);
  await writeFile(path.join(directory, name + '.proposed.luau'), proposed.get(name));
}
const generated = bundle(source);
const [environment, assertions] = (await readFile(path.join(root, 'tests/foundation.luau'), 'utf8')).split('-- BUNDLE INSERTION POINT');
assert(assertions);
const files = ['farming','phase2-fixes','pickup-first','stationary','goal-driven','progression','discovery','integration','economics','logging','pets',
  'egg-travel','rewards','anti-afk','local-features','phase4-roi','phase4-hatch-integration','phase4-travel-integration','phase4-controller-integration',
  'phase4-pickups','phase4-benchmark-fixes','phase4-travel-only','phase4-owner-allowance','phase4-position-guards','phase4-travel-logging',
  'phase4-egg-identity','phase4-location-logging','phase4-egg-location','phase4-standing-location','phase4-test-b-interaction'];
const tests = [];
for (const name of files) {
  let contents = await readFile(path.join(root, 'tests/' + name + '.luau'), 'utf8');
  if (name === 'phase4-test-b-interaction') {
    const terminal = 'print("[OC TEST] " .. tostring(tests - before) .. " guarded Common Egg Test B regressions passed; synthetic proof only, allowance remains OFF in release preflight")';
    assert.equal(contents.split(terminal).length - 1, 1);
    contents = contents.replace(terminal, (await readFile(path.join(root, 'tests/phase4-functional-hatch-proposal.luau'), 'utf8')) + '\n' + terminal);
  }
  tests.push(contents);
}
const target = path.join(directory, 'unapplied-proposal-harness.luau');
await writeFile(target, environment + '\n' + generated.library + '\n' + assertions + '\n' + tests.join('\n')
  + '\nprint("[OC UNAPPLIED PROPOSAL] TOTAL_TEST_COUNT " .. tostring(tests))\n');
const suffix = process.platform === 'win32' ? '.exe' : '';
const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau/luau-compile' + suffix);
const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau/luau' + suffix);
const compile = spawnSync(compiler, ['--null', ...names.map(n => path.join(directory, n + '.proposed.luau')), target], { encoding: 'utf8' });
await writeFile(path.join(directory, 'compile.log'), (compile.stdout || '') + (compile.stderr || ''));
assert.equal(compile.status, 0, 'Unapplied proposal compile failed: ' + compile.stderr);
const run = spawnSync(executable, [target], { encoding: 'utf8' });
await writeFile(path.join(directory, 'behavior.log'), (run.stdout || '') + (run.stderr || ''));
process.stdout.write(((run.stdout || '') + (run.stderr || '')).split('\n').slice(-16).join('\n'));
const after = await runtimeHashes();
assert.deepEqual(after, before, 'Proposal test changed production source or bundle');
await writeFile(path.join(directory, 'runtime-preservation.json'), JSON.stringify({ buildNotPublished: true, inMemoryOnly: true,
  comparedFiles: Object.keys(before).length, before, after, runExitCode: run.status, compileExitCode: compile.status,
  patchSha256: proof.PatchSha256 }, null, 2) + '\n');
assert.equal(run.status, 0, 'Unapplied proposal behavioral tests failed');
console.log('[OC UNAPPLIED PROPOSAL] RUNTIME_UNCHANGED ' + Object.keys(before).length + '; no approval or live acceptance implied');

// Reproduce the reviewed patch IN MEMORY against its immutable review commit.
// The current candidate may contain that approved patch; this historical proof
// still never changes production source/bundles or invokes live game behavior.
import assert from 'node:assert/strict';
import { readFile, writeFile, readdir, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { bundle } from './bundle.mjs';
import { FUNCTIONAL_BASELINE, FUNCTIONAL_FILES, applyApprovedFunctionalPatch } from './verify-phase4-approved-functional.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const directory = path.join(root, '.test-output/first-hatch-proposal');
const names = ['OCConfig', 'PetPolicy', 'OCBrain'];
const digest = value => createHash('sha256').update(value).digest('hex');
const patchPath = path.join(root, 'docs/PHASE4-FUNCTIONAL-HATCH-EXCEPTION-PROPOSED.patch');
const patchBytes = await readFile(patchPath);
const proof = JSON.parse(await readFile(path.join(root, 'docs/PHASE4-FUNCTIONAL-HATCH-EXCEPTION-PROPOSED-HASHES.json'), 'utf8'));
assert.equal(proof.Status, 'CONTINGENT_PROPOSAL_ONLY_NOT_APPLIED_NOT_AUTHORIZED');
assert.equal(digest(patchBytes), proof.PatchSha256);
assert.equal(proof.PatchSha256, '4dc7fc10a1532a2c6be2d7ef5c5e5f9fffc97fd699185098f985bc4da6d65e9d');
await mkdir(directory, { recursive: true });

function reviewedText(file) {
  const result = spawnSync('git', ['show', FUNCTIONAL_BASELINE + ':' + file], { cwd: root, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
  assert.equal(result.status, 0, 'Immutable review source is required: ' + file + ': ' + result.stderr);
  return result.stdout.replace(/\r\n/g, '\n');
}

async function runtimeHashes() {
  const files = ['src/OC.luau', 'dist/OC.lua', 'dist/OC.local.lua',
    ...(await readdir(path.join(root, 'src/OCFoundation'))).filter(n => n.endsWith('.luau')).map(n => 'src/OCFoundation/' + n)];
  return Object.fromEntries(await Promise.all(files.map(async file => [file, digest(await readFile(path.join(root, file)))])));
}

// Use the same exact-hunk verifier as the approved implementation, always from
// the original source/hash pins. Historical proposal records remain unchanged.
const originals = new Map(FUNCTIONAL_FILES.map(({ file }) => [file, reviewedText(file)]));
for (const [file, original] of originals) assert.equal(digest(original), proof.Files[file].BeforeSha256);
const proposed = applyApprovedFunctionalPatch(originals, patchBytes.toString());
assert.deepEqual([...proposed.keys()].sort(), names.map(n => `src/OCFoundation/${n}.luau`).sort());
for (const [file, after] of proposed) assert.equal(digest(after), proof.Files[file].AfterSha256);
const before = await runtimeHashes();
const list = spawnSync('git', ['ls-tree', '-r', '--name-only', FUNCTIONAL_BASELINE, '--', 'src/OCFoundation'], { cwd: root, encoding: 'utf8' });
assert.equal(list.status, 0, 'Immutable review source list is required: ' + list.stderr);
const source = {
  modules: list.stdout.trim().split(/\r?\n/).filter(file => file.endsWith('.luau')).sort().map(file => ({
    name: path.basename(file, '.luau'), source: reviewedText(file),
  })),
  entry: reviewedText('src/OC.luau'),
};
for (const name of names) {
  const after = proposed.get(`src/OCFoundation/${name}.luau`);
  source.modules.find(m => m.name === name).source = after;
  await writeFile(path.join(directory, name + '.proposed.luau'), after);
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
  + '\nprint("[OC HISTORICAL REVIEW PATCH] TOTAL_TEST_COUNT " .. tostring(tests))\n');
const suffix = process.platform === 'win32' ? '.exe' : '';
const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau/luau-compile' + suffix);
const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau/luau' + suffix);
const compile = spawnSync(compiler, ['--null', ...names.map(n => path.join(directory, n + '.proposed.luau')), target], { encoding: 'utf8' });
await writeFile(path.join(directory, 'compile.log'), (compile.stdout || '') + (compile.stderr || ''));
assert.equal(compile.status, 0, 'Historical review patch compile failed: ' + compile.stderr);
const run = spawnSync(executable, [target], { encoding: 'utf8' });
await writeFile(path.join(directory, 'behavior.log'), (run.stdout || '') + (run.stderr || ''));
process.stdout.write(((run.stdout || '') + (run.stderr || '')).split('\n').slice(-16).join('\n'));
const after = await runtimeHashes();
assert.deepEqual(after, before, 'Historical review patch test changed production source or bundle');
await writeFile(path.join(directory, 'runtime-preservation.json'), JSON.stringify({ harnessNotPublished: true, inMemoryOnly: true, reviewCommit: FUNCTIONAL_BASELINE,
  comparedFiles: Object.keys(before).length, before, after, runExitCode: run.status, compileExitCode: compile.status,
  patchSha256: proof.PatchSha256 }, null, 2) + '\n');
assert.equal(run.status, 0, 'Historical review patch behavioral tests failed');
console.log('[OC HISTORICAL REVIEW PATCH] RUNTIME_UNCHANGED ' + Object.keys(before).length + '; no live acceptance or paid activation implied');

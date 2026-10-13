// Approved bounded standing contract: frozen adapter control versus exact actual source.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { sources, bundle } from './bundle.mjs';

const root = path.resolve(import.meta.dirname, '..');
const sha = value => createHash('sha256').update(value).digest('hex');
const patchPath = 'docs/PHASE4-FINAL-STANDING-RECHECK-PROPOSED.patch';
const patch = await readFile(path.join(root, patchPath), 'utf8');
assert.equal(sha(patch), '1d5259f1d8e9593f616546eb345c5c6efd8c7064f025530b2682fbec156eec4d');
const applyInMemory = (source, patchText) => {
  const lines = patchText.split('\n');
  const start = lines.findIndex(line => line.startsWith('@@ '));
  assert(start > 0 && !lines.slice(start + 1).some(line => line.startsWith('@@ ')), 'Single exact hunk required');
  const hunk = lines.slice(start + 1).filter(line => /^[ +\-]/.test(line));
  const before = hunk.filter(line => line[0] !== '+').map(line => line.slice(1)).join('\n') + '\n';
  const after = hunk.filter(line => line[0] !== '-').map(line => line.slice(1)).join('\n') + '\n';
  assert.equal(source.split(before).length, 2, 'Exact patch preimage occurs once');
  return source.replace(before, after);
};
const source = await sources(root);
const mechanics = source.modules.find(value => value.name === 'GameMechanics').source;
const standing = source.modules.find(value => value.name === 'EggTravelManager').source;
assert.equal(sha(standing), '15bd589ea9ff1e81354dbe536b347a2a852f59efa4780681234d82ee0540cf3b', 'Both exact approved standing changes remain present without extras');
const historical = spawnSync('git', ['show', '78b97d11f34e245f31e41ff6fac10cbd795f03da:src/OCFoundation/GameMechanics.luau'], { cwd: root, encoding: 'utf8' });
assert.equal(historical.status, 0, historical.stderr);
assert.equal(sha(historical.stdout), 'a2f1a3d6ab3483db3d91e9a50975e159a5107dbdf78a26e70f9765d5e1d19f87', 'Frozen control remains the approved preimage');
const proposed = applyInMemory(historical.stdout, patch);
assert.equal(sha(proposed), 'd51154114e6309dd9042de250cbd8757ce1f61e146858960d7745397e14ab531');
assert.equal(mechanics, proposed, 'Actual adapter must match the exact separately approved four-line patch');
assert.equal((proposed.match(/fresh\.CharacterRoot\.CFrame = frame/g) || []).length, 1, 'Existing single assignment is unchanged');
assert.equal((proposed.match(/self\.LastEggPositionLease = record\.LeaseId/g) || []).length, 1, 'Existing single attempt consumption is unchanged');
const tests = await readFile(path.join(root, 'tests/phase4-final-standing-validation.luau'), 'utf8');
await mkdir(path.join(root, '.test-output'), { recursive: true });
for (const variant of ['frozen-adapter-control', 'approved-final-recheck-actual']) {
  const audit = structuredClone(source);
  if (variant === 'frozen-adapter-control') audit.modules.find(value => value.name === 'GameMechanics').source = historical.stdout;
  const marker = '-- ACTUAL SOURCE BUNDLE INSERTION';
  assert.equal(tests.split(marker).length, 2);
  const file = path.join(root, `.test-output/final-standing-${variant}.luau`);
  await writeFile(file, tests.replace(marker, bundle(audit).library)
    .replace('local PROPOSED = false', 'local PROPOSED = true')
    .replace('local SUPPORT_GUARD = false', 'local SUPPORT_GUARD = true')
    .replace('local FINAL_RECHECK = false', `local FINAL_RECHECK = ${variant === 'approved-final-recheck-actual'}`)
    .replace('local VARIANT = "released"', `local VARIANT = ${JSON.stringify(variant)}`));
  const compiled = spawnSync(path.join(root, '.tools/luau/luau-compile.exe'), ['--null', file], { encoding: 'utf8' });
  assert.equal(compiled.status, 0, compiled.stdout + compiled.stderr);
  const run = spawnSync(path.join(root, '.tools/luau/luau.exe'), [file], { encoding: 'utf8' });
  process.stdout.write(run.stdout);
  process.stderr.write(run.stderr);
  assert.equal(run.status, 0, `Approval-specific expected contract must pass for ${variant}`);
}
assert.equal((await sources(root)).modules.find(value => value.name === 'GameMechanics').source, mechanics, 'Offline tests did not edit the approved adapter');
console.log('[OC FINAL STANDING] Official Luau compilation PASS; frozen adapter fault reproduced; exact actual approved adapter bounded final-validation contract PASS; no production edits by tests.');

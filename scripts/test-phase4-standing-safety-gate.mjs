// Offline known-fault detection, not a certificate of live standing safety.
// Keeps historical faults as controls and gates the exact actual approved final source.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { sources, bundle } from './bundle.mjs';
import { stripApprovedOwnerDirectDelta } from './verify-phase4-approved-owner-direct.mjs';

const root = path.resolve(import.meta.dirname, '..');
const sha = value => createHash('sha256').update(value).digest('hex');
const patch = await readFile(path.join(root, 'docs/PHASE4-UNIVERSAL-MOVEMENT-STANDING-PROPOSED.patch'), 'utf8');
assert.equal(sha(patch), 'b1131059a5b151fb699b04bbf1ae50365cbeddc9a6d2faa222d28edd42d3207f');
const footprint = await readFile(path.join(root, 'docs/PHASE4-UNIVERSAL-MOVEMENT-FOOTPRINT-PROPOSED.patch'), 'utf8');
assert.equal(sha(footprint), 'e812a4acdad9a75877dbaaa175db9fb4b5be948f8369c570366e20b6768d1c36');
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
const historical = spawnSync('git', ['show', '78b97d11f34e245f31e41ff6fac10cbd795f03da:src/OCFoundation/EggTravelManager.luau'], { cwd: root, encoding: 'utf8' });
assert.equal(historical.status, 0, historical.stderr);
const historicalAdapter = spawnSync('git', ['show', '78b97d11f34e245f31e41ff6fac10cbd795f03da:src/OCFoundation/GameMechanics.luau'], { cwd: root, encoding: 'utf8' });
assert.equal(historicalAdapter.status, 0, historicalAdapter.stderr);
assert.equal(sha(historicalAdapter.stdout), 'a2f1a3d6ab3483db3d91e9a50975e159a5107dbdf78a26e70f9765d5e1d19f87');
assert.equal(sha(historical.stdout), '7fd14d19e3befc895f3446f41d4882394d12eebc7bc555e5e8b05dd864e4cb8c');
const diagonalSource = applyInMemory(historical.stdout, patch);
const combinedSource = applyInMemory(diagonalSource, footprint);
assert.equal(sha(combinedSource), '15bd589ea9ff1e81354dbe536b347a2a852f59efa4780681234d82ee0540cf3b');
assert.equal(stripApprovedOwnerDirectDelta('src/OCFoundation/EggTravelManager.luau', source.modules.find(value => value.name === 'EggTravelManager').source), combinedSource,
  'Actual source must match both exact approved patches, without further protected changes');
const tests = await readFile(path.join(root, 'tests/phase4-standing-safety-gate.luau'), 'utf8');
await mkdir(path.join(root, '.test-output'), { recursive: true });
for (const variant of ['released-historical', 'diagonal-historical', 'combined-frozen-adapter-control']) {
  const audit = structuredClone(source);
  const module = audit.modules.find(value => value.name === 'EggTravelManager');
  module.source = variant === 'released-historical' ? historical.stdout : variant === 'diagonal-historical' ? diagonalSource : combinedSource;
  audit.modules.find(value => value.name === 'GameMechanics').source = historicalAdapter.stdout;
  const marker = '-- ACTUAL SOURCE BUNDLE INSERTION';
  assert.equal(tests.split(marker).length, 2);
  const file = path.join(root, `.test-output/standing-safety-gate-${variant}.luau`);
  await writeFile(file, tests.replace(marker, bundle(audit).library)
    .replace('local PROPOSED = false', `local PROPOSED = ${variant !== 'released-historical'}`)
    .replace('local SUPPORT_GUARD = false', `local SUPPORT_GUARD = ${variant === 'combined-frozen-adapter-control'}`)
    .replace('local VARIANT = "released"', `local VARIANT = ${JSON.stringify(variant)}`));
  const compiled = spawnSync(path.join(root, '.tools/luau/luau-compile.exe'), ['--null', file], { encoding: 'utf8' });
  assert.equal(compiled.status, 0, compiled.stdout + compiled.stderr);
  const run = spawnSync(path.join(root, '.tools/luau/luau.exe'), [file], { encoding: 'utf8' });
  process.stdout.write(run.stdout);
  process.stderr.write(run.stderr);
  assert.equal(run.status, 0, 'Known-fault expectations must match; this does not mean safety acceptance passed');
}
// Historical failure evidence remains above. The release gate applies the owner's
// approved bounded contract to actual production source, not a patched overlay.
await import('./test-phase4-final-standing-proposal.mjs');
console.log('[OC SAFETY GATE] RELEASE_SAFETY_GATE=PASS: exact actual approved source rejects support loss during final Validate; external changes after the last observation remain non-atomic; offline fixtures are not owner-live acceptance.');

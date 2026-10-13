// Offline known-fault detection, not a certificate of live standing safety.
// Exercises the actual released resolver and exact approved patch in memory.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { sources, bundle } from './bundle.mjs';

const root = path.resolve(import.meta.dirname, '..');
const patch = await readFile(path.join(root, 'docs/PHASE4-UNIVERSAL-MOVEMENT-STANDING-PROPOSED.patch'));
assert.equal(createHash('sha256').update(patch).digest('hex'), 'b1131059a5b151fb699b04bbf1ae50365cbeddc9a6d2faa222d28edd42d3207f');
const exact = '\t\tfor _, offset in ipairs({ Vector3.new(0, 0, 0), Vector3.new(radius, 0, 0), Vector3.new(-radius, 0, 0), Vector3.new(0, 0, radius), Vector3.new(0, 0, -radius) }) do';
const changed = '\t\tlocal diagonal = radius / math.sqrt(2)\n\t\tfor _, offset in ipairs({ Vector3.new(0, 0, 0), Vector3.new(radius, 0, 0), Vector3.new(-radius, 0, 0), Vector3.new(0, 0, radius), Vector3.new(0, 0, -radius),\n\t\t\tVector3.new(diagonal, 0, diagonal), Vector3.new(diagonal, 0, -diagonal), Vector3.new(-diagonal, 0, diagonal), Vector3.new(-diagonal, 0, -diagonal) }) do';
const source = await sources(root);
const tests = await readFile(path.join(root, 'tests/phase4-standing-safety-gate.luau'), 'utf8');
await mkdir(path.join(root, '.test-output'), { recursive: true });
for (const proposed of [false, true]) {
  const audit = structuredClone(source);
  const module = audit.modules.find(value => value.name === 'EggTravelManager');
  assert.equal(module.source.split(exact).length, 2, 'Current source must be the untouched released resolver');
  if (proposed) module.source = module.source.replace(exact, changed);
  const marker = '-- ACTUAL SOURCE BUNDLE INSERTION';
  assert.equal(tests.split(marker).length, 2);
  const file = path.join(root, `.test-output/standing-safety-gate-${proposed ? 'proposed' : 'released'}.luau`);
  await writeFile(file, tests.replace(marker, bundle(audit).library).replace('local PROPOSED = false', `local PROPOSED = ${proposed}`));
  const compiled = spawnSync(path.join(root, '.tools/luau/luau-compile.exe'), ['--null', file], { encoding: 'utf8' });
  assert.equal(compiled.status, 0, compiled.stdout + compiled.stderr);
  const run = spawnSync(path.join(root, '.tools/luau/luau.exe'), [file], { encoding: 'utf8' });
  process.stdout.write(run.stdout);
  process.stderr.write(run.stderr);
  assert.equal(run.status, 0, 'Known-fault expectations must match; this does not mean safety acceptance passed');
}
console.log('[OC SAFETY GATE] RELEASE_SAFETY_GATE=FAIL: unsupported footprints accepted by both variants; no movement candidate may be published under the diagonal-only approval.');
process.exitCode = 1;

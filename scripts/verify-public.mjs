import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const commit = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim();
const refs = ['main', commit];
for (const artifact of ['dist/OC.lua', 'examples/StationaryOnly.luau', 'examples/Progression.luau', 'examples/Pets.luau', 'examples/PetEquipTest.luau', 'examples/EggAnalysis.luau', 'examples/HatchOnceTest.luau']) {
  const expected = await readFile(path.join(root, artifact));
  const results = await Promise.all(refs.map(async ref => {
    const url = `https://raw.githubusercontent.com/ryanrooflead-source/OCscript/${ref}/${artifact}`;
    const response = await fetch(url, { signal: AbortSignal.timeout(15000) });
    assert(response.ok, `${ref}: public raw HTTP ${response.status}`);
    const published = Buffer.from(await response.arrayBuffer());
    assert(published.equals(expected), `${ref}: public ${artifact} does not match the local artifact`);
    return `[OC] Public raw ${ref} ${artifact}: ${published.length} bytes match local artifact`;
  }));
  for (const result of results) console.log(result);
  console.log(`[OC] ${artifact} SHA-256 ${createHash('sha256').update(expected).digest('hex')}`);
}

// New test examples and their own bundle must reference the same published release.
const dist = await readFile(path.join(root, 'dist/OC.lua'));
const build = dist.toString('utf8').match(/-- Build: ([a-f0-9]{12})/)[1];
const release = 'phase4-hatch-' + build;
assert.equal(execFileSync('git', ['rev-parse', release + '^{}'], { cwd: root, encoding: 'utf8' }).trim(), commit, 'Hatch release tag must point at this tested commit');
for (const artifact of ['dist/OC.lua', 'examples/EggAnalysis.luau', 'examples/HatchOnceTest.luau']) {
  const expected = await readFile(path.join(root, artifact));
  if (artifact.startsWith('examples/')) assert(expected.toString('utf8').includes('/' + release + '/dist/OC.lua'));
  const url = 'https://raw.githubusercontent.com/ryanrooflead-source/OCscript/' + release + '/' + artifact;
  const response = await fetch(url, { signal: AbortSignal.timeout(15000) });
  assert(response.ok, 'Pinned hatch release HTTP ' + response.status);
  assert(Buffer.from(await response.arrayBuffer()).equals(expected), 'Pinned hatch release differs: ' + artifact);
  console.log('[OC] Pinned public ' + release + ' ' + artifact + ': bytes verified');
}

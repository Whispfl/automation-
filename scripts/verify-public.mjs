import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const commit = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim();
const refs = ['main', commit];
for (const artifact of ['dist/OC.lua', 'examples/StationaryOnly.luau']) {
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

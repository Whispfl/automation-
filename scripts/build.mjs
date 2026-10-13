import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { sources, bundle } from './bundle.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const { output, buildId } = bundle(await sources(root));
await mkdir(path.join(root, 'dist'), { recursive: true });
await writeFile(path.join(root, 'dist/OC.lua'), output);
const localConfig = await readFile(path.join(root, 'examples/LocalFeatureTests.luau'), 'utf8');
const localOutput = localConfig + `\n-- Local build: ${buildId}. Complete embedded bundle; no download.\nlocal function initializeLocalBundle()\n${output}\nend\nlocal OC = initializeLocalBundle()(Config)\nreturn OC\n`;
await writeFile(path.join(root, 'dist/OC.local.lua'), localOutput);
for (const name of ['Phase5MasteryReadOnly.luau']) {
  const examplePath = path.join(root, 'examples', name);
  const example = await readFile(examplePath, 'utf8');
  const pinned = example.replace(/(https:\/\/raw\.githubusercontent\.com\/Whispfl\/automation-\/)phase5-mastery-(?:[a-f0-9]{12}|PENDING)(\/dist\/OC\.lua)/g,
    (_, prefix, suffix) => prefix + 'phase5-mastery-' + buildId + suffix);
  if (!pinned.includes('/phase5-mastery-' + buildId + '/dist/OC.lua')) throw new Error('Matching read-only Mastery pin missing: ' + name);
  await writeFile(examplePath, pinned);
}
console.log(`[OC] Built dist/OC.lua: ${buildId} (${Buffer.byteLength(output)} bytes)`);
console.log(`[OC] Built dist/OC.local.lua: ${buildId} (${Buffer.byteLength(localOutput)} bytes; paste-ready Config + bundle)`);
console.log(`[OC] Read-only Mastery example pins phase5-mastery-${buildId}; all historical movement and hatch example pins retained`);

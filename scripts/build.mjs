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
for (const name of ['Phase4TravelOnly.luau', 'Phase4OneHatchPrepared.luau']) {
  const examplePath = path.join(root, 'examples', name);
  const example = await readFile(examplePath, 'utf8');
  const pinned = example.replace(/(https:\/\/raw\.githubusercontent\.com\/Whispfl\/automation-\/)phase4-tests-[a-f0-9]{12}(\/dist\/OC\.lua)/g,
    (_, prefix, suffix) => prefix + 'phase4-tests-' + buildId + suffix);
  if (!pinned.includes('/phase4-tests-' + buildId + '/dist/OC.lua')) throw new Error('Matching Phase4 test pin missing: ' + name);
  await writeFile(examplePath, pinned);
}
console.log(`[OC] Built dist/OC.lua: ${buildId} (${Buffer.byteLength(output)} bytes)`);
console.log(`[OC] Built dist/OC.local.lua: ${buildId} (${Buffer.byteLength(localOutput)} bytes; paste-ready Config + bundle)`);
console.log(`[OC] Travel-only and prepared one-hatch examples pin phase4-tests-${buildId}; prior tested examples retained`);

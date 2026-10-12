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
const firstTestPath = path.join(root, 'examples/Phase4AutoOnce.luau');
const firstTest = await readFile(firstTestPath, 'utf8');
const pinned = firstTest.replace(/(https:\/\/raw\.githubusercontent\.com\/Whispfl\/automation-\/)phase4-auto-[a-f0-9]{12}(\/dist\/OC\.lua)/g,
  (_, prefix, suffix) => prefix + 'phase4-auto-' + buildId + suffix);
if (!pinned.includes('/phase4-auto-' + buildId + '/dist/OC.lua')) throw new Error('Phase4 first-test matching release pin missing');
await writeFile(firstTestPath, pinned);
console.log(`[OC] Built dist/OC.lua: ${buildId} (${Buffer.byteLength(output)} bytes)`);
console.log(`[OC] Built dist/OC.local.lua: ${buildId} (${Buffer.byteLength(localOutput)} bytes; paste-ready Config + bundle)`);
console.log(`[OC] First AUTO one-hatch example pins phase4-auto-${buildId}`);

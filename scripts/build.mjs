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
for (const name of ['Phase5WheelSpinRemoteDisabled.luau']) {
  const examplePath = path.join(root, 'examples', name);
  const example = await readFile(examplePath, 'utf8');
  const pinned = example.replace(/(https:\/\/raw\.githubusercontent\.com\/Whispfl\/automation-\/)phase5-wheel-spin-remote-(?:[a-f0-9]{12}|PENDING)(\/dist\/OC\.lua)/g,
    (_, prefix, suffix) => prefix + 'phase5-wheel-spin-remote-' + buildId + suffix)
    .replace(/(RemoteTest = true, BuildId = ")(?:REMOTE_CANDIDATE_PENDING|[a-f0-9]{12})(")/g,
      (_, prefix, suffix) => prefix + buildId + suffix);
  if (!pinned.includes('/phase5-wheel-spin-remote-' + buildId + '/dist/OC.lua')) throw new Error('Matching disabled remote-wheel candidate pin missing: ' + name);
  if (!pinned.includes('RemoteTest = true, BuildId = "' + buildId + '"')) throw new Error('Matching remote preflight provenance missing: ' + name);
  await writeFile(examplePath, pinned);
}
console.log(`[OC] Built dist/OC.lua: ${buildId} (${Buffer.byteLength(output)} bytes)`);
console.log(`[OC] Built dist/OC.local.lua: ${buildId} (${Buffer.byteLength(localOutput)} bytes; paste-ready Config + bundle)`);
console.log(`[OC] Disabled remote-wheel example pins phase5-wheel-spin-remote-${buildId}; all historical wheel/free-wheel/rewards/Mastery/movement/hatch example pins retained`);

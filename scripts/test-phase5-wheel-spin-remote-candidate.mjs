// A separate candidate gate; the historical wheel runner still tests default behavior.
import assert from 'node:assert/strict';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {sources,bundle} from './bundle.mjs';
import {verifyRemoteWheelWorkspace} from './verify-phase5-wheel-spin-remote.mjs';
import {verifyRemoteWheelDisabledLoader} from './test-phase5-wheel-spin-remote-loader.mjs';
const root=path.resolve(import.meta.dirname,'..');
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
export async function verifyRemoteWheelCandidate() {
  const preservation=verifyRemoteWheelWorkspace();
  await import('../tests/phase5-wheel-spin-remote-preservation.mjs');
  const generated=bundle(await sources(root));
  assert.equal(await readFile(path.join(root,'dist/OC.lua'),'utf8'),generated.output,'Remote bundle must reproduce current source');
  await import('./test-phase5-wheel-spin-remote.mjs');
  const loader=await verifyRemoteWheelDisabledLoader();
  await mkdir(path.join(root,'.test-output'),{recursive:true});
  const report={status:'OFFLINE_PASS_DISABLED_REMOTE_CANDIDATE',buildId:generated.buildId,bundleSha256:sha(generated.output),
    preservationRecordSha256:sha(JSON.stringify(preservation)),loader,limitation:'Native hidden callback verified only with synthetic fixtures; server acceptance at distance remains UNKNOWN. Exactly one explicit owner test is separate from source approval; no live actions executed.'};
  await writeFile(path.join(root,'.test-output/phase5-wheel-spin-remote-VERIFICATION.json'),JSON.stringify(report,null,2)+'\n');
  console.log(`[OC REMOTE WHEEL] Disabled candidate ${generated.buildId} PASS; default 646 behavior/history retained; server acceptance UNKNOWN`);
  return report;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url))await verifyRemoteWheelCandidate();

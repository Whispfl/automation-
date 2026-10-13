import assert from 'node:assert/strict';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const repository = 'Whispfl/automation-';
const git = (...args) => execFileSync('git', args, { cwd: root, encoding: 'utf8' }).trim();
const commit = git('rev-parse', 'HEAD');
const dist = await readFile(path.join(root, 'dist/OC.lua'));
const buildId = dist.toString('utf8').match(/-- Build: ([a-f0-9]{12})/)[1];
const release = 'phase4-hatch-' + buildId;
const branch = git('branch', '--show-current');
const rawRoot = 'https://raw.githubusercontent.com/' + repository;
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
async function get(url) {
  // Deliberately anonymous: loaders need no credentials, tokens or headers.
  const response = await fetch(url, { signal: AbortSignal.timeout(30000) });
  assert(response.ok, `${url}: public HTTP ${response.status}`);
  return Buffer.from(await response.arrayBuffer());
}
const publicJSON = async suffix => JSON.parse((await get('https://api.github.com/repos/' + repository + suffix)).toString('utf8'));
const branchRef = await publicJSON('/git/ref/heads/' + branch);
assert.equal(branchRef.object.sha, commit, 'Remote candidate branch differs from the intended local commit');
assert.equal(git('rev-parse', release + '^{}'), commit, 'Candidate release must point at the intended local commit');
const tag = await publicJSON('/git/ref/tags/' + release);
assert.equal(tag.object.type, 'commit', 'Expected the local lightweight candidate tag');
assert.equal(tag.object.sha, commit, 'Public candidate pin differs from the intended commit');

// Compare every published path and Git blob hash, in addition to raw-byte checks.
const remoteTree = await publicJSON('/git/trees/' + commit + '?recursive=1');
assert.equal(remoteTree.truncated, false, 'Public Git tree response is incomplete');
const remoteFiles = new Map(remoteTree.tree.filter(entry => entry.type === 'blob').map(entry => [entry.path, entry.sha]));
const localFiles = new Map(git('ls-tree', '-r', '--full-tree', commit).split('\n').filter(Boolean).map(line => {
  const [metadata, file] = line.split('\t');
  return [file, metadata.split(' ')[2]];
}));
assert.equal(remoteFiles.size, localFiles.size, 'Published file count differs');
for (const [file, blob] of localFiles) {
  assert.equal(remoteFiles.get(file), blob, 'Published Git blob differs: ' + file);
  assert(!/^(?:\.git\/|node_modules\/|\.tools\/|\.test-output\/)|\.zip$/i.test(file), 'Private/tool/backup artifact published: ' + file);
  if (file.startsWith('docs/local-feature-studio-evidence/') && file.endsWith('.source.txt')) assert(file.endsWith('/AntiAFK_KEY_SEARCH.source.txt'), 'Raw third-party script extract published: ' + file);
}
console.log(`[OC] Public ${branch} ${commit}; ${localFiles.size} Git file paths/blob hashes match; pin ${release} matches`);

const representative = [
  'dist/OC.lua', 'dist/OC.local.lua', 'src/OC.luau', 'src/OCFoundation/OCConfig.luau',
  'src/OCFoundation/EggTravelManager.luau', 'src/OCFoundation/RewardsManager.luau', 'src/OCFoundation/AntiAFKManager.luau',
  'src/OCFoundation/GameKnowledge.luau', 'src/OCFoundation/OCBrain.luau', 'src/OCFoundation/GameMechanics.luau',
  'src/OCFoundation/AccountPresentation.luau', 'docs/PHASE4-EGG-LOCATION-EVIDENCE.md',
  'src/OCFoundation/HatchManager.luau', 'src/OCFoundation/PetManager.luau', 'src/OCFoundation/OwnerHatchTestAllowance.luau',
  'docs/PHASE4-TEST-B-NATIVE-EVIDENCE.md', 'docs/PHASE4-TEST-A-PRESERVATION.json',
  'docs/PHASE4-TEST-B-DELIVERY.md',
  'scripts/verify-test-a-preservation.mjs', 'tests/phase4-test-b-interaction.luau',
  'tests/phase4-egg-location.luau', 'tests/phase4-location-logging.luau', 'tests/phase4-standing-location.luau',
  'scripts/build.mjs', 'scripts/test.mjs', 'package.json', 'docs/ARCHITECTURE.md', 'docs/LOCAL_FEATURES.md',
  'docs/research/replicatedstorage/README.md', 'docs/research/replicatedstorage/NATIVE_ACTION_CONTRACTS.md',
  'docs/research/replicatedstorage/catalogs/EGG_FACTS.jsonl',
  'docs/research/wiki/README.md', 'docs/research/wiki/SOURCE_INDEX.md', 'docs/research/wiki/evidence/ALL_CLAIMS.jsonl',
  ...[...localFiles.keys()].filter(file => file.startsWith('examples/')),
];
const checks = [];
for (const artifact of representative) {
  const expected = await readFile(path.join(root, artifact));
  for (const ref of [branch, commit]) {
    const published = await get(`${rawRoot}/${ref}/${artifact}`);
    assert(published.equals(expected), `${ref}: public ${artifact} differs from local bytes`);
    checks.push({ artifact, ref, bytes: expected.length, sha256: sha256(expected), result: 'PASS' });
  }
  console.log('[OC] Anonymous candidate branch + commit raw bytes match: ' + artifact);
}

for (const artifact of ['dist/OC.lua', 'examples/Phase4TestBPreflight.luau', 'examples/Phase4TestBOneHatch.luau']) {
  const expected = await readFile(path.join(root, artifact));
  if (artifact.startsWith('examples/')) assert(expected.toString('utf8').includes(`/${repository}/${release}/dist/OC.lua`), 'Example does not load its matching pin: ' + artifact);
  const published = await get(`${rawRoot}/${release}/${artifact}`);
  assert(published.equals(expected), 'Pinned artifact differs: ' + artifact);
  checks.push({ artifact, ref: release, bytes: expected.length, sha256: sha256(expected), result: 'PASS' });
  console.log('[OC] Matching pinned raw bytes verified: ' + artifact);
}
const priorPhase4Release = 'phase4-auto-890d4713edad';
const priorPhase4Commit = git('rev-parse', priorPhase4Release + '^{}');
for (const artifact of ['dist/OC.lua', 'examples/Phase4AutoOnce.luau']) {
  const expected = execFileSync('git', ['show', `${priorPhase4Commit}:${artifact}`], { cwd: root });
  assert((await get(`${rawRoot}/${priorPhase4Release}/${artifact}`)).equals(expected), 'Prior tested Phase4 pin differs: ' + artifact);
  checks.push({ artifact, ref: priorPhase4Release, bytes: expected.length, sha256: sha256(expected), result: 'PASS' });
}
const priorTestRelease = 'phase4-tests-141b7608bedf';
const priorTestCommit = git('rev-parse', priorTestRelease + '^{}');
for (const artifact of ['dist/OC.lua', 'examples/Phase4TravelOnly.luau', 'examples/Phase4OneHatchPrepared.luau']) {
  const expected = execFileSync('git', ['show', `${priorTestCommit}:${artifact}`], { cwd: root });
  assert((await get(`${rawRoot}/${priorTestRelease}/${artifact}`)).equals(expected), 'Prior Test A/B pin differs: ' + artifact);
  checks.push({ artifact, ref: priorTestRelease, bytes: expected.length, sha256: sha256(expected), result: 'PASS' });
}
const priorTravelRelease = 'phase4-travel-a0ee412ac828';
const priorTravelCommit = git('rev-parse', priorTravelRelease + '^{}');
for (const artifact of ['dist/OC.lua', 'examples/Phase4TravelOnly.luau']) {
  const expected = execFileSync('git', ['show', `${priorTravelCommit}:${artifact}`], { cwd: root });
  assert((await get(`${rawRoot}/${priorTravelRelease}/${artifact}`)).equals(expected), 'Prior owner-tested travel pin differs: ' + artifact);
  checks.push({ artifact, ref: priorTravelRelease, bytes: expected.length, sha256: sha256(expected), result: 'PASS' });
}
const approvedTravelRelease = 'phase4-travel-0d5caa499c8c';
const approvedTravelCommit = '25890f224f0448f148d009e65514c129aeb4f59c';
assert.equal(git('rev-parse', approvedTravelRelease + '^{}'), approvedTravelCommit, 'Owner-approved Test A local pin changed');
assert.equal((await publicJSON('/git/ref/tags/' + approvedTravelRelease)).object.sha, approvedTravelCommit, 'Owner-approved Test A public pin changed');
for(const artifact of ['dist/OC.lua', 'examples/Phase4TravelOnly.luau']){
  const expected = execFileSync('git', ['show', `${approvedTravelCommit}:${artifact}`], {cwd:root});
  assert((await get(`${rawRoot}/${approvedTravelRelease}/${artifact}`)).equals(expected), 'Owner-approved Test A artifact changed: ' + artifact);
  checks.push({artifact,ref:approvedTravelRelease,bytes:expected.length,sha256:sha256(expected),result:'PASS'});
}
// Historical action-OFF examples intentionally retain their accepted migration
// pin. Compare its own bundle, never pretend it is the current candidate build.
const historicalRelease = 'migration-005f77211830';
const historicalCommit = git('rev-parse', historicalRelease + '^{}');
for (const artifact of ['dist/OC.lua', 'examples/EggAnalysis.luau', 'examples/HatchOnceTest.luau', 'examples/MigrationVerify.luau']) {
  const expected = execFileSync('git', ['show', `${historicalCommit}:${artifact}`], { cwd: root });
  if (artifact.startsWith('examples/')) assert(expected.toString('utf8').includes(`/${repository}/${historicalRelease}/dist/OC.lua`), 'Historical example pin mismatch: ' + artifact);
  const published = await get(`${rawRoot}/${historicalRelease}/${artifact}`);
  assert(published.equals(expected), 'Historical pinned artifact differs: ' + artifact);
  checks.push({ artifact, ref: historicalRelease, bytes: expected.length, sha256: sha256(expected), result: 'PASS' });
}
const report = { dateUTC: new Date().toISOString(), repository, branch, commit, buildId, release,
  ownerApprovedTestA: { buildId: '0d5caa499c8c', commit: approvedTravelCommit, release: approvedTravelRelease, unchanged: true },
  anonymousAccess: true, publishedFilesCompared: localFiles.size, publicTreeComplete: true,
  bundleSHA256: sha256(dist), localBundleSHA256: sha256(await readFile(path.join(root, 'dist/OC.local.lua'))),
  rawChecks: checks, result: 'PASS', scope: 'Publication/content verification only; no gameplay executed' };
const reportPath = path.join(root, '.test-output/phase4-test-b-public-verification.json');
await mkdir(path.dirname(reportPath), { recursive: true });
await writeFile(reportPath, JSON.stringify(report, null, 2) + '\n');
console.log('[OC] Public verification PASS: ' + checks.length + ' raw content comparisons; bundle build ' + buildId);

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
const release = 'migration-' + buildId;
const rawRoot = 'https://raw.githubusercontent.com/' + repository;
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
async function get(url) {
  // Deliberately anonymous: loaders need no credentials, tokens or headers.
  const response = await fetch(url, { signal: AbortSignal.timeout(30000) });
  assert(response.ok, `${url}: public HTTP ${response.status}`);
  return Buffer.from(await response.arrayBuffer());
}
const publicJSON = async suffix => JSON.parse((await get('https://api.github.com/repos/' + repository + suffix)).toString('utf8'));
const main = await publicJSON('/git/ref/heads/main');
assert.equal(main.object.sha, commit, 'Remote main differs from the intended local commit');
assert.equal(git('rev-parse', release + '^{}'), commit, 'Migration release must point at the intended local commit');
const tag = await publicJSON('/git/ref/tags/' + release);
assert.equal(tag.object.type, 'commit', 'Expected the local lightweight migration tag');
assert.equal(tag.object.sha, commit, 'Public migration pin differs from the intended commit');

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
console.log(`[OC] Public main ${commit}; ${localFiles.size} Git file paths/blob hashes match; pin ${release} matches`);

const representative = [
  'dist/OC.lua', 'dist/OC.local.lua', 'src/OC.luau', 'src/OCFoundation/OCConfig.luau',
  'src/OCFoundation/EggTravelManager.luau', 'src/OCFoundation/RewardsManager.luau', 'src/OCFoundation/AntiAFKManager.luau',
  'scripts/build.mjs', 'scripts/test.mjs', 'package.json', 'docs/ARCHITECTURE.md', 'docs/LOCAL_FEATURES.md',
  'docs/research/replicatedstorage/README.md', 'docs/research/replicatedstorage/NATIVE_ACTION_CONTRACTS.md',
  'docs/research/replicatedstorage/catalogs/EGG_FACTS.jsonl',
  'docs/research/wiki/README.md', 'docs/research/wiki/SOURCE_INDEX.md', 'docs/research/wiki/evidence/ALL_CLAIMS.jsonl',
  ...[...localFiles.keys()].filter(file => file.startsWith('examples/')),
];
const checks = [];
for (const artifact of representative) {
  const expected = await readFile(path.join(root, artifact));
  for (const ref of ['main', commit]) {
    const published = await get(`${rawRoot}/${ref}/${artifact}`);
    assert(published.equals(expected), `${ref}: public ${artifact} differs from local bytes`);
    checks.push({ artifact, ref, bytes: expected.length, sha256: sha256(expected), result: 'PASS' });
  }
  console.log('[OC] Anonymous main + commit raw bytes match: ' + artifact);
}

for (const artifact of ['dist/OC.lua', 'examples/EggAnalysis.luau', 'examples/HatchOnceTest.luau', 'examples/MigrationVerify.luau']) {
  const expected = await readFile(path.join(root, artifact));
  if (artifact.startsWith('examples/')) assert(expected.toString('utf8').includes(`/${repository}/${release}/dist/OC.lua`), 'Example does not load its matching pin: ' + artifact);
  const published = await get(`${rawRoot}/${release}/${artifact}`);
  assert(published.equals(expected), 'Pinned artifact differs: ' + artifact);
  checks.push({ artifact, ref: release, bytes: expected.length, sha256: sha256(expected), result: 'PASS' });
  console.log('[OC] Matching pinned raw bytes verified: ' + artifact);
}
const report = { dateUTC: new Date().toISOString(), repository, branch: 'main', commit, buildId, release,
  anonymousAccess: true, publishedFilesCompared: localFiles.size, publicTreeComplete: true,
  bundleSHA256: sha256(dist), localBundleSHA256: sha256(await readFile(path.join(root, 'dist/OC.local.lua'))),
  rawChecks: checks, result: 'PASS', scope: 'Publication/content verification only; no gameplay executed' };
const reportPath = path.join(root, '.test-output/migration-public-verification.json');
await mkdir(path.dirname(reportPath), { recursive: true });
await writeFile(reportPath, JSON.stringify(report, null, 2) + '\n');
console.log('[OC] Public verification PASS: ' + checks.length + ' raw content comparisons; bundle build ' + buildId);

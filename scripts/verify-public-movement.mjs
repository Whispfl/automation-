// Anonymous publication verification only; no Roblox/gameplay execution.
import assert from 'node:assert/strict';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const git = (...args) => execFileSync('git', args, { cwd: root, encoding: 'utf8' }).trim();
const repository = 'Whispfl/automation-';
const raw = `https://raw.githubusercontent.com/${repository}`;
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const commit = git('rev-parse', 'HEAD'), branch = git('branch', '--show-current');
const dist = await readFile(path.join(root, 'dist/OC.lua'));
const buildId = dist.toString('utf8').match(/-- Build: ([a-f0-9]{12})/)[1];
const release = `phase4-travel-${buildId}`;
const get = async url => {
  const response = await fetch(url, { signal: AbortSignal.timeout(30000) });
  assert(response.ok, `Anonymous HTTP ${response.status}: ${url}`);
  return Buffer.from(await response.arrayBuffer());
};
const api = async suffix => JSON.parse((await get(`https://api.github.com/repos/${repository}${suffix}`)).toString('utf8'));
const results = await Promise.allSettled([
  api(`/git/ref/heads/${branch}`), api(`/git/ref/tags/${release}`), api(`/git/trees/${commit}?recursive=1`),
]);
for (const result of results) { if (result.status === 'rejected') throw result.reason; }
const [branchRef, tagRef, tree] = results.map(result => result.value);
assert.equal(branchRef.object.sha, commit, 'Development branch does not match implementation commit');
assert.equal(tagRef.object.type, 'commit', 'Candidate must have a lightweight immutable commit tag');
assert.equal(tagRef.object.sha, commit, 'Public release pin differs from implementation commit');
assert.equal(git('rev-parse', release + '^{}'), commit, 'Local release pin changed');
assert.equal(tree.truncated, false, 'Public Git tree incomplete');
const publishedFiles = new Map(tree.tree.filter(entry => entry.type === 'blob').map(entry => [entry.path, entry.sha]));
const localFiles = new Map(git('ls-tree', '-r', '--full-tree', commit).split('\n').filter(Boolean).map(line => {
  const [metadata, file] = line.split('\t'); return [file, metadata.split(' ')[2]];
}));
assert.equal(publishedFiles.size, localFiles.size, 'Public file count differs');
for (const [file, blob] of localFiles) {
  assert.equal(publishedFiles.get(file), blob, 'Public Git blob differs: ' + file);
  assert(!/^(?:\.git\/|node_modules\/|\.tools\/|\.test-output\/)|\.zip$|(?:^|\/)\.env(?:\.|$)/i.test(file), 'Private/tool file published: ' + file);
  if (file.startsWith('docs/local-feature-studio-evidence/') && file.endsWith('.source.txt')) assert(file.endsWith('/AntiAFK_KEY_SEARCH.source.txt'), 'Unapproved native source extract published');
}
const checks = [];
const candidatePaths = [
  'dist/OC.lua', 'dist/OC.local.lua', 'examples/Phase4MovementOnly.luau',
  'src/OCFoundation/GameMechanics.luau', 'src/OCFoundation/EggTravelManager.luau',
  'src/OCFoundation/GameKnowledge.luau', 'src/OCFoundation/HatchManager.luau',
  'docs/PHASE4-APPROVED-FINAL-STANDING-RECHECK.json', 'docs/PHASE4-APPROVED-STANDING-SUPPORT.json',
  'docs/PHASE4-FINAL-STANDING-RECHECK-PROPOSED.patch',
  'docs/PHASE4-UNIVERSAL-MOVEMENT-STANDING-PROPOSED.patch',
  'docs/PHASE4-UNIVERSAL-MOVEMENT-FOOTPRINT-PROPOSED.patch',
  'docs/PHASE4-MOVEMENT-CANDIDATE-DELIVERY.md',
];
const loader = (await readFile(path.join(root, candidatePaths[2]))).toString('utf8');
assert(loader.includes(`/${repository}/${release}/dist/OC.lua`), 'Movement loader must load its matching travel pin');
for (const batchStart of [0, 6, 12]) {
  const batch = candidatePaths.slice(batchStart, batchStart + 6);
  const settled = await Promise.allSettled(batch.map(async file => {
    const expected = await readFile(path.join(root, file));
    const actual = await get(`${raw}/${release}/${file}`);
    assert(actual.equals(expected), 'Pinned raw bytes differ: ' + file);
    return { file, ref: release, bytes: actual.length, sha256: sha256(actual), result: 'PASS' };
  }));
  for (const result of settled) { if (result.status === 'rejected') throw result.reason; checks.push(result.value); }
}
const historical = [
  ['phase4-travel-0d5caa499c8c', '25890f224f0448f148d009e65514c129aeb4f59c'],
  ['phase4-hatch-100f2c1907ae', 'aae628d9ac8f1941f9b0b92aaedc365be22fa6af'],
  ['phase4-hatch-f4e10f71c317', '55bf4cf437cccd826180519c482bdc6edbbbb51b'],
];
for (const [pin, expectedCommit] of historical) {
  assert.equal(git('rev-parse', pin + '^{}'), expectedCommit, 'Historical local tag changed: ' + pin);
  assert.equal((await api('/git/ref/tags/' + pin)).object.sha, expectedCommit, 'Historical public tag changed: ' + pin);
  const expected = execFileSync('git', ['show', `${expectedCommit}:dist/OC.lua`], { cwd: root });
  const actual = await get(`${raw}/${pin}/dist/OC.lua`);
  assert(actual.equals(expected), 'Historical bundle bytes changed: ' + pin);
  checks.push({ file: 'dist/OC.lua', ref: pin, bytes: actual.length, sha256: sha256(actual), result: 'PASS' });
}
const archive = 'docs/evidence/PHASE4-FIRST-LIVE-HATCH-100f2c1907ae-CONSOLE.txt';
const originalLog = await get(`${raw}/${release}/${archive}`);
assert.equal(sha256(originalLog), '0765815d70c439d9857d9ee3a3fa6390e346a9d65ff2bee7e9c8c1d900dd7df5', 'Original hatch console bytes changed');
const report = { dateUTC: new Date().toISOString(), repository, branch, commit, buildId, release,
  bundleBytes: dist.length, bundleSHA256: sha256(dist), publicFilesCompared: localFiles.size,
  anonymousAccess: true, historical, checks, firstHatchLogSHA256: sha256(originalLog),
  result: 'PASS', scope: 'Public content integrity; offline verification, owner-live movement pending; no gameplay executed' };
await mkdir(path.join(root, '.test-output'), { recursive: true });
await writeFile(path.join(root, '.test-output/phase4-movement-public-verification.json'), JSON.stringify(report, null, 2) + '\n');
console.log(`[OC PUBLIC MOVEMENT] PASS: ${commit}; ${release}; ${localFiles.size} Git blobs and ${checks.length + 1} anonymous raw artifacts match; original Test A/first hatch/preflight unchanged.`);

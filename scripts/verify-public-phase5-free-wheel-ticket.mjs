// Anonymous distribution integrity only. No Roblox or gameplay execution.
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { verifyFreeWheelTicketWorkspace } from './verify-phase5-free-wheel-ticket.mjs';

const root = path.resolve(import.meta.dirname, '..');
const git = (...args) => execFileSync('git', args, { cwd: root, encoding: 'utf8', timeout: 30000, maxBuffer: 16 * 1024 * 1024 }).trim();
const gitBytes = (ref, file) => execFileSync('git', ['show', `${ref}:${file}`], { cwd: root, timeout: 30000, maxBuffer: 16 * 1024 * 1024 });
const repository = 'Whispfl/automation-';
const raw = `https://raw.githubusercontent.com/${repository}`;
const verificationCommit = git('rev-parse', 'HEAD'), branch = git('branch', '--show-current');
assert(branch, 'Publication verification requires the intended current branch');
const metadata = verifyFreeWheelTicketWorkspace();
const bundle = await readFile(path.join(root, 'dist/OC.lua'));
const match = bundle.toString('utf8').match(/-- Build: ([a-f0-9]{12})/);
assert(match, 'Candidate bundle must identify its build');
const buildId = match[1], tag = `phase5-free-wheel-ticket-${buildId}`;
const commit = git('rev-parse', `${tag}^{commit}`);
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const privateCommit = '34342b60c6cb82012aa531b09861c554beb8b265';
const ancestry = spawnSync('git', ['merge-base', '--is-ancestor', privateCommit, commit], { cwd: root, timeout: 30000 });
assert.equal(ancestry.status, 1, 'Private raw-log commit must remain outside published ancestry');
assert.equal(spawnSync('git', ['merge-base', '--is-ancestor', commit, verificationCommit], { cwd: root, timeout: 30000 }).status, 0,
  'Immutable candidate must remain in the current publication branch history');
assert.equal(spawnSync('git', ['merge-base', '--is-ancestor', privateCommit, verificationCommit], { cwd: root, timeout: 30000 }).status, 1,
  'Private raw-log commit must also remain outside the verification branch ancestry');

const overallDeadline = Date.now() + 10 * 60 * 1000;
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function get(url) {
  for (let attempt = 0; attempt < 3; attempt++) {
    const remaining = overallDeadline - Date.now();
    assert(remaining > 0, 'Anonymous publication verification exceeded its bounded deadline');
    let response;
    try {
      // Deliberately anonymous: no credentials, authorization or custom headers.
      response = await fetch(url, { signal: AbortSignal.timeout(Math.min(20000, remaining)) });
    } catch (error) {
      if (attempt === 2 || !['TypeError', 'TimeoutError', 'AbortError'].includes(error.name)) throw error;
      await delay(500 * (attempt + 1));
      continue;
    }
    if (response.ok) return Buffer.from(await response.arrayBuffer());
    const rateLimited = response.status === 403 && response.headers.get('x-ratelimit-remaining') === '0';
    const transient = rateLimited || [408, 425, 429, 500, 502, 503, 504].includes(response.status);
    if (!transient || attempt === 2) throw new Error(`Anonymous HTTP ${response.status}: ${url}`);
    await response.body?.cancel();
    const retryAfter = Number(response.headers.get('retry-after'));
    await delay(Number.isFinite(retryAfter) && retryAfter > 0 ? Math.min(3000, retryAfter * 1000) : 500 * (attempt + 1));
  }
  throw new Error(`Anonymous retrieval did not complete: ${url}`);
}
const api = async suffix => JSON.parse((await get(`https://api.github.com/repos/${repository}${suffix}`)).toString('utf8'));
const encodedPath = value => value.split('/').map(encodeURIComponent).join('/');
const blobMap = ref => new Map(git('ls-tree', '-r', '--full-tree', ref).split('\n').filter(Boolean).map(line => {
  const [attributes, file] = line.split('\t');
  return [file, attributes.split(' ')[2]];
}));
function compareTree(tree, ref) {
  assert.equal(tree.truncated, false, `Public tree must be complete: ${ref}`);
  const remote = new Map(tree.tree.filter(entry => entry.type === 'blob').map(entry => [entry.path, entry.sha]));
  const local = blobMap(ref);
  assert.equal(remote.size, local.size, `Public blob count differs: ${ref}`);
  for (const [file, blob] of local) assert.equal(remote.get(file), blob, `Public blob differs: ${ref}:${file}`);
  return local;
}
async function batch(items, callback, width = 4) {
  const values = [];
  for (let start = 0; start < items.length; start += width) {
    const results = await Promise.allSettled(items.slice(start, start + width).map(callback));
    const failures = results.filter(result => result.status === 'rejected');
    if (failures.length) throw new AggregateError(failures.map(result => result.reason), 'Anonymous verification batch failed');
    values.push(...results.map(result => result.value));
  }
  return values;
}
const [branchRef, tagRef, tree, verificationTree] = await batch([
  `/git/ref/heads/${encodedPath(branch)}`, `/git/ref/tags/${tag}`, `/git/trees/${commit}?recursive=1`, `/git/trees/${verificationCommit}?recursive=1`,
], api);
assert.equal(branchRef.object.sha, verificationCommit, 'Public verification branch differs from current HEAD');
assert.equal(tagRef.object.type, 'commit', 'Candidate must use a lightweight immutable tag');
assert.equal(tagRef.object.sha, commit, 'Public candidate tag changed its immutable commit');
const localBlobs = compareTree(tree, commit);
const verificationBlobs = compareTree(verificationTree, verificationCommit);
const baselineBlobs = blobMap(metadata.baselineCommit);
for (const entry of metadata.frozenFiles) {
  assert.equal(localBlobs.get(entry.file), baselineBlobs.get(entry.file), `Published historical evidence/loader/fixture changed: ${entry.file}`);
}
for (const file of localBlobs.keys()) {
  assert(!/^(?:\.local-evidence\/|\.test-output\/|\.tools\/|node_modules\/|\.git\/)|\.zip$|PHASE4-OWNER-LIVE-DIRECT-1d27e2a74ae5-(?:CONSOLE\.txt|ARCHIVE\.json)/i.test(file), `Private evidence/tool artifact in public tree: ${file}`);
  if (file.startsWith('docs/local-feature-studio-evidence/') && file.endsWith('.source.txt')) {
    assert(file.endsWith('/AntiAFK_KEY_SEARCH.source.txt'), `Raw third-party source extract in candidate tree: ${file}`);
  }
}

const loaderFile = 'examples/Phase5FreeWheelTicketDisabled.luau';
const loader = (await readFile(path.join(root, loaderFile))).toString('utf8');
assert(loader.includes(`${raw}/${tag}/dist/OC.lua`), 'Disabled loader must use the matching immutable candidate pin');
assert.equal((loader.match(/game:HttpGet\(/g) || []).length, 1, 'Disabled loader must perform one anonymous bundle fetch');
assert(!/\b(?:GitHubToken|Authorization|FireServer|InvokeServer)\b/.test(loader), 'Disabled loader must have no credentials or native transport');
assert(loader.includes('ENABLE_FREE_WHEEL_TICKET_CLAIM = false') && loader.includes('AUTHORIZED_ACCOUNT_ID = 0')
  && loader.includes('AUTHORIZED_TEST_ID = ""') && loader.includes('OWNER_CONFIRMED_WHEEL_IDLE = false'), 'Published ticket authorization must remain OFF');
const files = [
  'dist/OC.lua', 'dist/OC.local.lua', loaderFile, 'src/OC.luau',
  'src/OCFoundation/RewardsManager.luau', 'src/OCFoundation/GameMechanics.luau',
  'src/OCFoundation/GameKnowledge.luau', 'src/OCFoundation/OCConfig.luau',
  'src/OCFoundation/OCBrain.luau', 'src/OCFoundation/OCController.luau',
  'src/OCFoundation/AccountStateReader.luau', 'src/OCFoundation/TaskScheduler.luau',
  'tests/phase5-free-wheel-ticket.luau', 'scripts/test-phase5-free-wheel-ticket.mjs',
  'scripts/verify-phase5-free-wheel-ticket.mjs', 'scripts/verify-public-phase5-free-wheel-ticket.mjs',
  'docs/PHASE5-FREE-WHEEL-TICKET.md', 'docs/PHASE5-FREE-WHEEL-SOURCE-PRESERVATION.json',
  'docs/PHASE5-FREE-WHEEL-PROTECTED-PROPOSAL.patch', 'docs/PHASE5-FREE-WHEEL-PROTECTED-PROPOSAL.json',
  'examples/Phase5RewardsReadOnly.luau', 'examples/Phase5MasteryReadOnly.luau',
  'tests/phase5-rewards.luau', 'tests/phase5-mastery.luau',
];
const checks = await batch(files.flatMap(file => [branch, commit, tag].map(ref => ({ file, ref }))), async ({ file, ref }) => {
  assert(localBlobs.has(file), `Candidate verification artifact is uncommitted: ${file}`);
  const expected = gitBytes(ref === branch ? verificationCommit : commit, file), disk = await readFile(path.join(root, file));
  assert(disk.equals(gitBytes(verificationCommit, file)), `Candidate working bytes differ from HEAD: ${file}`);
  if (file !== 'scripts/verify-public-phase5-free-wheel-ticket.mjs') {
    assert.equal(verificationBlobs.get(file), localBlobs.get(file), `Verification follow-up changed a candidate artifact: ${file}`);
  }
  const url = `${raw}/${encodedPath(ref)}/${encodedPath(file)}`;
  // Mutable branch URLs may retain an older CDN entry immediately after push.
  // A public, non-secret commit query selects a fresh cache entry; byte equality
  // remains mandatory. User loaders keep their ordinary immutable raw tag URL.
  const actual = await get(ref === branch ? `${url}?oc_verify_commit=${verificationCommit}` : url);
  assert(actual.equals(expected), `Anonymous candidate raw bytes differ: ${ref}:${file}`);
  return { file, ref, bytes: actual.length, sha256: sha(actual), result: 'PASS' };
}, 6);

// Offline preservation covers all local pins, including unpublished/held candidates.
// Every previously published milestone remains mandatory; other local-only pins
// must not be mislabeled as a public release or published merely to satisfy a check.
const publicReferences = await api('/git/matching-refs/tags/');
assert(Array.isArray(publicReferences), 'Published tag inventory must be explicit');
const publicTags = new Map(publicReferences.map(reference => [reference.ref.replace(/^refs\/tags\//, ''), reference]));
const priorPublished = JSON.parse(await readFile(path.join(root, 'docs/PHASE5-REWARDS-SOURCE-PRESERVATION.json'), 'utf8')).releasePins;
const requiredPublished = [...priorPublished, { tag: 'phase5-rewards-7d374c2879a3', commit: metadata.baselineCommit }];
for (const pin of requiredPublished) {
  assert(publicTags.has(pin.tag), `Previously published mandatory milestone is missing: ${pin.tag}`);
  assert.equal(git('rev-parse', `${pin.tag}^{commit}`), pin.commit, `Mandatory historical local pin changed: ${pin.tag}`);
}
const localOnlyPins = metadata.releasePins.filter(pin => !publicTags.has(pin.tag));
const histories = await batch(metadata.releasePins.filter(pin => publicTags.has(pin.tag)), async pin => {
  assert.equal(git('rev-parse', `${pin.tag}^{commit}`), pin.commit, `Historical local pin changed: ${pin.tag}`);
  const reference = publicTags.get(pin.tag);
  assert.equal(reference.object.sha, git('rev-parse', pin.tag), `Historical public tag object changed: ${pin.tag}`);
  let object = reference.object;
  for (let depth = 0; object.type === 'tag' && depth < 5; depth++) object = (await api(`/git/tags/${object.sha}`)).object;
  assert.equal(object.type, 'commit', `Historical tag did not resolve to a commit: ${pin.tag}`);
  assert.equal(object.sha, pin.commit, `Historical public commit changed: ${pin.tag}`);
  const historicalTree = await api(`/git/trees/${pin.commit}?recursive=1`);
  const blobs = compareTree(historicalTree, pin.commit);
  const original = gitBytes(pin.commit, 'dist/OC.lua');
  const actual = await get(`${raw}/${encodedPath(pin.tag)}/dist/OC.lua`);
  assert(actual.equals(original), `Historical release bundle changed: ${pin.tag}`);
  return { file: 'dist/OC.lua', ref: pin.tag, commit: pin.commit, publicGitBlobs: blobs.size,
    bytes: actual.length, sha256: sha(actual), result: 'PASS' };
});
checks.push(...histories);
const report = { dateUTC: new Date().toISOString(), repository, commit, verificationCommit, branch, tag, buildId,
  bundleSHA256: sha(bundle), bundleBytes: bundle.length, publicGitBlobs: localBlobs.size,
  anonymousAccess: true, authorizationDefaultsOff: true, privateRawEvidencePublished: false,
  privateAncestorExcluded: privateCommit, historicalReleaseCount: histories.length,
  localOnlyHistoricalPins: localOnlyPins.map(pin => ({ ...pin, status: 'PRESERVED_LOCAL_UNPUBLISHED' })),
  checks, result: 'PASS', scope: 'Disabled candidate publication integrity only; no Roblox claim, spending or live acceptance executed' };
await mkdir(path.join(root, '.test-output'), { recursive: true });
await writeFile(path.join(root, '.test-output/phase5-free-wheel-ticket-public-verification.json'), JSON.stringify(report, null, 2) + '\n');
console.log(`[OC PUBLIC FREE WHEEL] PASS: ${commit}; ${tag}; ${localBlobs.size} candidate blobs, ${checks.length} anonymous raw checks and ${histories.length} complete historical trees match; authorization OFF; private raw-log ancestry excluded`);

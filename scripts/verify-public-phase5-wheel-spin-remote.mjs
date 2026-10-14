// Anonymous immutable artifact verification. No game connection or gameplay action.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { sources, bundle } from './bundle.mjs';
import { verifyRemoteWheelWorkspace } from './verify-phase5-wheel-spin-remote.mjs';

const root = path.resolve(import.meta.dirname, '..');
verifyRemoteWheelWorkspace();
const generated = bundle(await sources(root));
const tag = 'phase5-wheel-spin-remote-' + generated.buildId;
const git = args => execFileSync('git', args, { cwd: root, maxBuffer: 32 * 1024 * 1024 }).toString('utf8').trim();
const commit = git(['rev-parse', tag + '^{commit}']);
assert.equal(commit, git(['rev-parse', 'HEAD']), 'New immutable tag must identify the implementation commit');
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const base = 'https://raw.githubusercontent.com/Whispfl/automation-/' + tag + '/';
const files = ['dist/OC.lua', 'examples/Phase5WheelSpinRemoteDisabled.luau', 'AGENTS.md',
  'src/OCFoundation/WheelSpinPolicy.luau', 'src/OCFoundation/RewardsManager.luau',
  'src/OCFoundation/GameMechanics.luau', 'src/OCFoundation/GameKnowledge.luau', 'src/OCFoundation/OCConfig.luau',
  'docs/PHASE5-WHEEL-SPIN-REMOTE.md', 'docs/PHASE5-WHEEL-SPIN-REMOTE-SOURCE-PRESERVATION.json'];
for (const file of files) {
  const response = await fetch(base + file, { signal: AbortSignal.timeout(30000) });
  assert.equal(response.status, 200, 'Public raw artifact is unavailable: ' + file);
  const bytes = Buffer.from(await response.arrayBuffer());
  const local = await readFile(path.join(root, file));
  assert(bytes.equals(local), 'Anonymous pinned artifact differs from verified workspace: ' + file);
  if (file === 'dist/OC.lua') assert.equal(bytes.toString('utf8'), generated.output, 'Public bundle must match deterministic source build');
}
const loader = await readFile(path.join(root, files[1]), 'utf8');
assert(loader.includes(base + 'dist/OC.lua'), 'Full disabled loader must pin this exact immutable bundle');
assert(loader.includes('AUTO_SPIN_WHEEL = false, OWNER_ONE_SPIN_ALLOWANCE = false')
  && loader.includes('AUTHORIZED_ACCOUNT_ID = 0') && loader.includes('AUTHORIZED_TEST_ID = ""'), 'Public loader must have no consumption authority');
assert(!/:\s*(?:Start|Resume|Select|Prepare|SpinWheelOnce)\s*\(/.test(loader), 'Public disabled loader must remain preflight only');
const privateCommit = '34342b60c6cb82012aa531b09861c554beb8b265';
const ancestry = execFileSync('git', ['rev-list', commit], { cwd: root }).toString('utf8').trim().split('\n');
assert(!ancestry.includes(privateCommit), 'Private raw-evidence commit must not be published');
const names = git(['ls-tree', '-r', '--name-only', commit]).split('\n');
assert(!names.some(file => file.startsWith('.local-evidence/') || file.endsWith('.docx')), 'Private logs/owner capture documents remain local');
console.log(JSON.stringify({ status: 'PUBLIC_PINNED_ARTIFACTS_PASS', commit, tag, buildId: generated.buildId,
  bundleSha256: sha(Buffer.from(generated.output)), verifiedAnonymousFiles: files.length,
  bundleURL: base + 'dist/OC.lua', disabledLoaderURL: base + files[1], liveSpinAuthorization: false }, null, 2));

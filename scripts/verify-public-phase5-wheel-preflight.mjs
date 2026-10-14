// Anonymous artifact verification only; no Roblox execution or claim authorization.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import './verify-public-phase5-free-wheel-ticket.mjs';

const root = path.resolve(import.meta.dirname, '..');
const git = (...args) => execFileSync('git', args, { cwd: root, timeout: 30000, maxBuffer: 16 * 1024 * 1024 });
const commit = git('rev-parse', 'HEAD').toString().trim();
const candidate = 'f4c495e2c3d313ed6666ff94dd34c384cc8a0631';
const tag = 'phase5-wheel-preflight-668d0af6f157';
assert.equal(git('rev-parse', `${tag}^{commit}`).toString().trim(), commit, 'Handoff tag must pin this exact commit');
const tagResponse = await fetch(`https://api.github.com/repos/Whispfl/automation-/git/ref/tags/${tag}`, { signal: AbortSignal.timeout(20000) });
assert(tagResponse.ok, `Anonymous handoff tag HTTP ${tagResponse.status}`);
const tagRef = await tagResponse.json();
assert.equal(tagRef.object.type, 'commit');
assert.equal(tagRef.object.sha, commit, 'Published immutable handoff tag differs from local commit');
for (const file of ['dist/OC.lua', 'dist/OC.local.lua', ...git('ls-tree', '-r', '--name-only', candidate, 'src').toString().trim().split('\n')]) {
  assert(git('show', `${candidate}:${file}`).equals(git('show', `${commit}:${file}`)), `Preflight changed validated gameplay bytes: ${file}`);
}
const files = ['examples/Phase5FreeWheelTicketPreflight.luau', 'tests/phase5-wheel-preflight.luau',
  'scripts/test-phase5-wheel-preflight.mjs', 'scripts/verify-public-phase5-wheel-preflight.mjs',
  'docs/PHASE5-WHEEL-OWNER-TEST.md', 'scripts/test.mjs'];
const checks = [];
for (const { file, ref } of files.flatMap(file => [commit, tag].map(ref => ({ file, ref })))) {
  const expected = git('show', `${commit}:${file}`);
  assert(expected.equals(await readFile(path.join(root, file))), `Local handoff differs from commit: ${file}`);
  const url = `https://raw.githubusercontent.com/Whispfl/automation-/${ref}/${file}`;
  const response = await fetch(url, { signal: AbortSignal.timeout(20000) });
  assert(response.ok, `Anonymous HTTP ${response.status}: ${file}`);
  const actual = Buffer.from(await response.arrayBuffer());
  assert(actual.equals(expected), `Published preflight bytes differ: ${file}`);
  checks.push({ file, ref, url, bytes: actual.length, sha256: createHash('sha256').update(actual).digest('hex'), result: 'PASS' });
}
const report = { commit, tag, preservedCandidate: candidate, buildId: '668d0af6f157',
  gameplayBytesUnchanged: true, authorizationOff: true, liveClaimExecuted: false, checks, result: 'PASS' };
await writeFile(path.join(root, '.test-output/phase5-wheel-preflight-public-verification.json'), JSON.stringify(report, null, 2) + '\n');
console.log(`[OC PUBLIC WHEEL PREFLIGHT] PASS: ${commit}; ${checks.length} exact anonymous handoff artifacts; source/bundles unchanged; claim authorization OFF.`);

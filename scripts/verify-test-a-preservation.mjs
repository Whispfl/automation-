import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { TEST_A_BASELINE, HISTORICAL_MANIFEST_COMMIT, MEMBERSHIP_FILE, MEMBERSHIP_METHOD,
  sha256, extractFrozenMethod, verifyHistoricalManifest, verifyApprovedMembership, verifyUnchangedGeometryHelper } from './verify-phase4-approved-membership.mjs';
import { FUNCTIONAL_RECORD_PATH, verifyApprovedFunctionalBrain, verifyFunctionalWorkspace } from './verify-phase4-approved-functional.mjs';
import { STANDING_FILE, verifyApprovedStanding, verifyStandingWorkspace } from './verify-phase4-approved-standing.mjs';
import { FINAL_STANDING_FILE, verifyApprovedFinalStanding, verifyFinalStandingWorkspace } from './verify-phase4-approved-final-standing.mjs';
import { stripApprovedOwnerDirectDelta, verifyOwnerDirectWorkspace } from './verify-phase4-approved-owner-direct.mjs';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifestPath = 'docs/PHASE4-TEST-A-PRESERVATION.json';
const gitFile = (commit, file) => execFileSync('git', ['show', `${commit}:${file}`], { cwd: root, maxBuffer: 8 * 1024 * 1024 });
const manifest = verifyHistoricalManifest(await readFile(path.join(root, manifestPath)), gitFile(HISTORICAL_MANIFEST_COMMIT, manifestPath));
const approval = JSON.parse(await readFile(path.join(root, 'docs/PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json'), 'utf8'));
await verifyOwnerDirectWorkspace();
const functional = await verifyFunctionalWorkspace();
const standing = await verifyStandingWorkspace();
const finalStanding = await verifyFinalStandingWorkspace();
assert.deepEqual(functional, JSON.parse(await readFile(path.join(root, FUNCTIONAL_RECORD_PATH), 'utf8')));
let unchanged = 0, approved = 0;
for (const check of manifest.checks) {
  const baseline = gitFile(TEST_A_BASELINE, check.file);
  const current = stripApprovedOwnerDirectDelta(check.file, await readFile(path.join(root, check.file)));
  const before = check.method ? extractFrozenMethod(baseline.toString('utf8'), check.method) : baseline;
  const after = check.method ? extractFrozenMethod(current.toString('utf8'), check.method) : current;
  assert.equal(sha256(before), check.sha256, `Historical Test A hash does not match immutable baseline: ${check.file}:${check.method || 'whole file'}`);
  if (check.file === STANDING_FILE && !check.method) {
    verifyApprovedStanding(before, after, standing.patches, standing.record);
    approved += 1;
  } else if (check.file === FINAL_STANDING_FILE && !check.method) {
    verifyApprovedFinalStanding(before, after, finalStanding.patch, finalStanding.record);
    approved += 1;
  } else if (check.file === MEMBERSHIP_FILE && check.method === MEMBERSHIP_METHOD) {
    verifyApprovedMembership(before, after, approval);
    approved += 1;
  } else if (check.file === 'src/OCFoundation/OCBrain.luau' && !check.method) {
    verifyApprovedFunctionalBrain(before.toString('utf8'), after.toString('utf8'), functional);
    approved += 1;
  } else {
    assert.equal(sha256(after), check.sha256, `Owner-approved travel changed: ${check.file}:${check.method || 'whole file'}`);
    assert.deepEqual(after, before, `Preserved Test A bytes changed: ${check.file}:${check.method || 'whole file'}`);
    unchanged += 1;
  }
}
assert.equal(unchanged, 6, 'Exactly six historical Test A checks must remain unchanged');
assert.equal(approved, 4, 'Only separately approved exact standing, adapter, membership and PlanPets corrections are permitted');
const knowledgeBefore = gitFile(TEST_A_BASELINE, MEMBERSHIP_FILE).toString('utf8');
const knowledgeAfter = await readFile(path.join(root, MEMBERSHIP_FILE), 'utf8');
for (const name of ['point', 'eggParts', 'eggReceiver']) verifyUnchangedGeometryHelper(knowledgeBefore, knowledgeAfter, name);
assert.equal(extractFrozenMethod(knowledgeAfter, 'InstanceId'), extractFrozenMethod(knowledgeBefore, 'InstanceId'), 'Physical-selection identity ordering changed');
console.log(`[OC] Test A preservation PASS: 10 historical hashes verified; 6 unchanged checks; 4 separately approved exact standing/adapter/membership/PlanPets corrections; historical records retained, unchanged identity/navigation and exact movement differences verified (${manifest.baseline})`);

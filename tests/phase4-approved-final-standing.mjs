import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { sha256 } from '../scripts/verify-phase4-approved-membership.mjs';
import { verifyFunctionalProtectedFiles } from '../scripts/verify-phase4-approved-functional.mjs';
import { STANDING_BASELINE, STANDING_FILE, standingApprovalContext, applyApprovedStandingPatches, verifyStandingProtectedFiles } from '../scripts/verify-phase4-approved-standing.mjs';
import { FINAL_STANDING_BASELINE, FINAL_STANDING_FILE, FINAL_STANDING_PATCH_SHA256,
  FINAL_STANDING_BEFORE_FILE_SHA256, FINAL_STANDING_AFTER_FILE_SHA256,
  FINAL_STANDING_BEFORE_METHOD_SHA256, FINAL_STANDING_AFTER_METHOD_SHA256,
  extractFinalStandingMethod, applyApprovedFinalStandingPatch, expectedFinalStandingRecord,
  verifyApprovedFinalStanding, finalStandingApprovalContext, verifyFinalStandingWorkspace } from '../scripts/verify-phase4-approved-final-standing.mjs';

const root = path.resolve(import.meta.dirname, '..');
const git = (commit, file) => execFileSync('git', ['show', `${commit}:${file}`], { cwd: root, maxBuffer: 8 * 1024 * 1024 });
const before = git(FINAL_STANDING_BASELINE, FINAL_STANDING_FILE);
const final = await finalStandingApprovalContext(root), standing = await standingApprovalContext(root);
const after = applyApprovedFinalStandingPatch(before, final.patch), clone = value => JSON.parse(JSON.stringify(value));
let groups = 0;
function test(label, callback) { callback(); groups += 1; }

test('direct owner approval is an independently pinned exact transform', () => {
  assert.equal(sha256(final.patch), FINAL_STANDING_PATCH_SHA256);
  assert.equal(sha256(before), FINAL_STANDING_BEFORE_FILE_SHA256);
  assert.equal(sha256(after), FINAL_STANDING_AFTER_FILE_SHA256);
  assert.equal(sha256(extractFinalStandingMethod(before.toString('utf8'))), FINAL_STANDING_BEFORE_METHOD_SHA256);
  assert.equal(sha256(extractFinalStandingMethod(after)), FINAL_STANDING_AFTER_METHOD_SHA256);
  assert.deepEqual(verifyApprovedFinalStanding(before, after, final.patch, final.record), expectedFinalStandingRecord(before, final.patch));
});
test('original method boundary and all outside-method bytes are retained', () => {
  assert.equal(before.toString('utf8').replace(extractFinalStandingMethod(before.toString('utf8')), '<ADAPTER>'), after.replace(extractFinalStandingMethod(after), '<ADAPTER>'));
});
test('patch contains only four additions and no replaced/deleted operations', () => {
  const lines = final.patch.toString('utf8').trimEnd().split('\n').slice(4);
  assert.equal(lines.filter(line => line[0] === '+').length, 4);
  assert.equal(lines.filter(line => line[0] === '-').length, 0);
});
test('final validation precedes support recheck and unchanged single assignment', () => {
  const method = extractFinalStandingMethod(after);
  assert(method.indexOf('manager:Validate(record, token, true)') < method.indexOf('manager:ResolveStanding(final)'));
  assert(method.indexOf('manager:ResolveStanding(final)') < method.indexOf('self.LastEggPositionLease = record.LeaseId'));
  assert.equal((method.match(/fresh\.CharacterRoot\.CFrame = frame/g) || []).length, 1);
  assert.equal((method.match(/self\.LastEggPositionLease = record\.LeaseId/g) || []).length, 1);
  assert(!method.includes('frame = latestFrame'));
});
test('unapproved preimage cannot be legalized by recomputing metadata', () => {
  assert.throws(() => applyApprovedFinalStandingPatch(before.toString('utf8') + '\n', final.patch), /Immutable final standing adapter preimage changed/);
});
test('rewritten reviewed patch bytes are rejected', () => {
  assert.throws(() => applyApprovedFinalStandingPatch(before, Buffer.concat([final.patch, Buffer.from('\n')])), /patch bytes changed/);
});
test('unapplied adapter cannot pass approved implementation preservation', () => {
  assert.throws(() => verifyApprovedFinalStanding(before, before, final.patch, final.record), /Unapproved final adapter change/);
});
for (const [label, transform] of [
  ['substitute landing frame', value => value.replace('if latestFrame ~= frame then', 'frame = latestFrame\n\tif latestFrame ~= frame then')],
  ['weaken full frame equality', value => value.replace('if latestFrame ~= frame then', 'if (latestFrame.Position - frame.Position).Magnitude > 0.25 then')],
  ['omit cancellation check', value => value.replace('if not latestFrame then return false, latestReason end', 'if token:CheckCancelled() then return false, "Cancelled" end')],
  ['skip footprint recheck', value => value.replace('local latestFrame, latestReason = manager:ResolveStanding(final)', 'local latestFrame, latestReason = frame, nil')],
  ['extra assignment', value => value.replace('local assigned, err = pcall(function()', 'fresh.CharacterRoot.CFrame = frame\n\tlocal assigned, err = pcall(function()')],
  ['extra retry', value => value.replace('return assigned, assigned and', 'if not assigned then return self:PositionSelectedEgg(manager, record, frame, token) end\n\treturn assigned, assigned and')],
  ['unrelated source bytes', value => value + '\n-- unapproved runtime delta\n'],
]) {
  test(`mutable hashes cannot broaden approval: ${label}`, () => {
    const changed = transform(after); assert.notEqual(changed, after);
    const forged = clone(final.record); forged.afterFileSha256 = sha256(changed); forged.afterMethodText = extractFinalStandingMethod(changed); forged.afterMethodSha256 = sha256(forged.afterMethodText);
    assert.throws(() => verifyApprovedFinalStanding(before, changed, final.patch, forged), /Unapproved final adapter change/);
  });
}
test('approval and historical evidence are immutable rather than metadata authority', () => {
  for (const mutate of [
    value => { value.baseline = '0'.repeat(40); }, value => { value.approval.title = 'APPROVED ALL'; },
    value => { value.approval.date = '2026-10-14'; }, value => { value.approval.scope += ' plus retries'; },
    value => { value.patch.sha256 = sha256('changed'); }, value => { value.retainedProposal.status = 'Always approved'; },
    value => { value.actionPermissions.AUTO_HATCH = true; }, value => { value.actionPermissions.spendingBudgets = 10; },
    value => { value.preservedMilestones[0].tag = 'current'; }, value => { value.nonAtomicLimit = 'Atomic guaranteed'; },
  ]) {
    const forged = clone(final.record); mutate(forged);
    assert.throws(() => verifyApprovedFinalStanding(before, after, final.patch, forged), /cannot broaden scope/);
  }
});
test('duplicate protected adapter cannot pass extraction', () => {
  assert.throws(() => extractFinalStandingMethod(`${after}\n${extractFinalStandingMethod(after)}`), /exactly once/);
});

const names = execFileSync('git', ['ls-tree', '-r', '--name-only', STANDING_BASELINE, 'src'], { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(file => file.endsWith('.luau'));
const frozen = new Map(names.map(file => [file, git(STANDING_BASELINE, file)])), current = new Map(frozen);
current.set(STANDING_FILE, applyApprovedStandingPatches(frozen.get(STANDING_FILE), standing.patches));
current.set(FINAL_STANDING_FILE, after);
test('only two approved production files change from first live hatch', () => {
  assert.equal(verifyStandingProtectedFiles(current, frozen, standing.patches, standing.record, final), 25);
  assert.throws(() => verifyStandingProtectedFiles(current, frozen, standing.patches, standing.record), /protected production source changed/);
});
test('functional guards remain frozen with only independently approved movement differences', () => {
  assert.equal(verifyFunctionalProtectedFiles(current, frozen, standing, final), 24);
  assert.throws(() => verifyFunctionalProtectedFiles(current, frozen, standing), /Protected production source changed/);
});
test('forged standing or adapter mutation is rejected by combined preservation', () => {
  for (const file of [STANDING_FILE, FINAL_STANDING_FILE]) {
    const changed = new Map(current); changed.set(file, `${current.get(file)}\n`);
    assert.throws(() => verifyStandingProtectedFiles(changed, frozen, standing.patches, standing.record, final), /Unapproved/);
  }
});
test('all other source files remain byte-for-byte protected', () => {
  for (const file of names.filter(file => file !== STANDING_FILE && file !== FINAL_STANDING_FILE)) {
    const changed = new Map(current); changed.set(file, Buffer.concat([Buffer.from(changed.get(file)), Buffer.from('\n')]));
    assert.throws(() => verifyStandingProtectedFiles(changed, frozen, standing.patches, standing.record, final), /protected production source changed/);
  }
});
test('new competing runtime module cannot bypass the source set', () => {
  const changed = new Map(current); changed.set('src/OCFoundation/UnapprovedMovement.luau', 'return {}\n');
  assert.throws(() => verifyStandingProtectedFiles(changed, frozen, standing.patches, standing.record, final), /source file set changed/);
});
test('actual source equals independently reconstructed approved adapter', () => {
  // Synchronous bytes are checked again by the workspace verifier below.
  assert.equal(sha256(after), final.record.afterFileSha256);
});
await verifyFinalStandingWorkspace();
assert.equal((await readFile(path.join(root, FINAL_STANDING_FILE), 'utf8')), after);
console.log(`[OC TEST] ${groups} final-standing approval preservation groups passed; exact four-line adapter, both prior standing patches, all 25 other first-hatch source files and historical/native/wiki evidence retained`);

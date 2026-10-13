import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { sha256 } from '../scripts/verify-phase4-approved-membership.mjs';
import { verifyFunctionalProtectedFiles } from '../scripts/verify-phase4-approved-functional.mjs';
import { STANDING_BASELINE, STANDING_FILE, STANDING_RECORD_PATH, STANDING_PATCHES,
  STANDING_AFTER_FILE_SHA256, STANDING_BEFORE_METHOD_SHA256, STANDING_AFTER_METHOD_SHA256,
  extractStandingMethod, applyApprovedStandingPatches, expectedStandingRecord,
  verifyApprovedStanding, verifyStandingProtectedFiles, verifyStandingWorkspace } from '../scripts/verify-phase4-approved-standing.mjs';

const root = path.resolve(import.meta.dirname, '..');
const git = file => execFileSync('git', ['show', `${STANDING_BASELINE}:${file}`], { cwd: root, maxBuffer: 8 * 1024 * 1024 });
const before = git(STANDING_FILE), patches = await Promise.all(STANDING_PATCHES.map(check => readFile(path.join(root, check.path))));
const after = applyApprovedStandingPatches(before, patches), record = JSON.parse(await readFile(path.join(root, STANDING_RECORD_PATH), 'utf8'));
const clone = value => JSON.parse(JSON.stringify(value));
let tests = 0;
function test(label, callback) { callback(); tests += 1; }

test('both exact approved patches and independently recorded evidence pass', () => {
  assert.deepEqual(verifyApprovedStanding(before, after, patches, record), expectedStandingRecord(before, patches));
  assert.equal(sha256(after), STANDING_AFTER_FILE_SHA256);
  assert.equal(sha256(extractStandingMethod(before.toString('utf8'))), STANDING_BEFORE_METHOD_SHA256);
  assert.equal(sha256(extractStandingMethod(after)), STANDING_AFTER_METHOD_SHA256);
});
test('only one protected method changes', () => {
  assert.equal(before.toString('utf8').replace(extractStandingMethod(before.toString('utf8')), '<APPROVED_METHOD>'), after.replace(extractStandingMethod(after), '<APPROVED_METHOD>'));
});
test('all five original candidates remain in their original exact order', () => {
  const original = 'Vector3.new(0, 0, 0), Vector3.new(radius, 0, 0), Vector3.new(-radius, 0, 0), Vector3.new(0, 0, radius), Vector3.new(0, 0, -radius)';
  assert(before.includes(original)); assert(after.includes(original));
  assert.equal(after.indexOf(original) < after.indexOf('Vector3.new(diagonal, 0, diagonal)'), true);
  assert(after.includes('local diagonal = radius / math.sqrt(2)'));
});
test('diagonals alone cannot pass the approved combined transform', () => {
  const changed = before.toString('utf8').replace('\t\tfor _, offset in ipairs({ Vector3.new', '\t\tlocal diagonal = radius / math.sqrt(2)\n\t\tfor _, offset in ipairs({ Vector3.new');
  assert.throws(() => verifyApprovedStanding(before, changed, patches, record), /Unapproved standing source edit/);
  assert.throws(() => applyApprovedStandingPatches(before, [patches[0]]), /Both approved standing patches/);
});
test('footprint-only or reordered transforms cannot pass', () => {
  assert.throws(() => applyApprovedStandingPatches(before, [patches[1]]), /Both approved standing patches/);
  assert.throws(() => applyApprovedStandingPatches(before, [...patches].reverse()), /patch bytes changed/);
});
test('extra patch transforms cannot broaden approval', () => {
  assert.throws(() => applyApprovedStandingPatches(before, [...patches, patches[0]]), /Both approved standing patches/);
});
for (const [index, check] of STANDING_PATCHES.entries()) {
  test(`immutable reviewed bytes cannot be rewritten: ${check.path}`, () => {
    const changed = [...patches]; changed[index] = Buffer.concat([changed[index], Buffer.from('\n')]);
    assert.throws(() => applyApprovedStandingPatches(before, changed), /patch bytes changed/);
  });
}
test('baseline cannot be laundered with recomputed record hashes', () => {
  const changed = before.toString('utf8') + '\n-- edited before\n';
  assert.throws(() => applyApprovedStandingPatches(changed, patches), /Immutable standing preimage changed/);
});
for (const [label, replacement] of [
  ['reduced support margin', text => text.replace('floorSize.X / 2 - 0.15', 'floorSize.X / 2')],
  ['bypassed support', text => text.replace('if not supported then continue end', 'if false then continue end')],
  ['altered floor ray', text => text.replace('-record.Range * 2', '-record.Range * 3')],
  ['expanded radius', text => text.replace('radius / math.sqrt(2)', 'radius')],
  ['reordered original samples', text => text.replace('Vector3.new(radius, 0, 0), Vector3.new(-radius, 0, 0)', 'Vector3.new(-radius, 0, 0), Vector3.new(radius, 0, 0)')],
  ['unrelated method', text => text + '\n-- unapproved outside-method bytes\n'],
]) {
  test(`record hash editing cannot authorize ${label}`, () => {
    const changed = replacement(after); assert.notEqual(changed, after);
    const forged = clone(record); forged.afterFileSha256 = sha256(changed); forged.afterMethodText = extractStandingMethod(changed); forged.afterMethodSha256 = sha256(forged.afterMethodText);
    assert.throws(() => verifyApprovedStanding(before, changed, patches, forged), /Unapproved standing source edit/);
  });
}
test('approval title/date/scope/history and activation cannot be edited', () => {
  const mutations = [
    value => { value.baseline = '0'.repeat(40); }, value => { value.approval.date = '2026-10-14'; },
    value => { value.approval.title = 'APPROVED EVERYTHING'; }, value => { value.approval.quote = 'Allow more movement'; },
    value => { value.approval.scope += ' plus retry'; }, value => { value.activation.AUTO_HATCH = true; },
    value => { value.activation.spendingBudgets = 10; }, value => { value.historicalRecords[0].sha256 = sha256('changed'); },
    value => { value.preservedMilestones[1].tag = 'current'; }, value => { value.afterMethodText += '\n'; },
  ];
  for (const mutate of mutations) { const forged = clone(record); mutate(forged); assert.throws(() => verifyApprovedStanding(before, after, patches, forged), /cannot broaden scope/); }
});
test('duplicate protected method cannot pass extraction', () => {
  assert.throws(() => extractStandingMethod(`${after}\n${extractStandingMethod(after)}`), /exactly once/);
});

const names = execFileSync('git', ['ls-tree', '-r', '--name-only', STANDING_BASELINE, 'src'], { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(file => file.endsWith('.luau'));
const frozen = new Map(names.map(file => [file, git(file)])), current = new Map(frozen); current.set(STANDING_FILE, after);
test('all 26 other first-hatch production sources remain exact', () => {
  assert.equal(verifyStandingProtectedFiles(current, frozen, patches, record), 26);
});
test('functional verifier permits only the independently verified standing transform', () => {
  assert.equal(verifyFunctionalProtectedFiles(current, frozen, { patches, record }), 24);
  assert.throws(() => verifyFunctionalProtectedFiles(current, frozen), /Protected production source changed/);
  const edited = new Map(current); edited.set(STANDING_FILE, after + '\n');
  assert.throws(() => verifyFunctionalProtectedFiles(edited, frozen, { patches, record }), /Unapproved standing source edit/);
});
for (const file of ['src/OCFoundation/GameMechanics.luau', 'src/OCFoundation/OCBrain.luau', 'src/OCFoundation/TaskScheduler.luau', 'src/OCFoundation/GameKnowledge.luau', 'src/OCFoundation/PetManager.luau', 'src/OCFoundation/HatchManager.luau', 'src/OCFoundation/OwnerHatchTestAllowance.luau', 'src/OCFoundation/OCConfig.luau']) {
  test(`unrelated runtime remains protected: ${file}`, () => {
    const changed = new Map(current); changed.set(file, Buffer.concat([Buffer.from(changed.get(file)), Buffer.from('\n')]));
    assert.throws(() => verifyStandingProtectedFiles(changed, frozen, patches, record), /protected production source changed/);
  });
}
test('new runtime module cannot bypass file-set preservation', () => {
  const changed = new Map(current); changed.set('src/OCFoundation/Unapproved.luau', 'return {}\n');
  assert.throws(() => verifyStandingProtectedFiles(changed, frozen, patches, record), /source file set changed/);
});
await verifyStandingWorkspace();
console.log(`[OC TEST] ${tests} approved-standing preservation groups passed; exact combined method, 26 frozen production files, tampering negatives and unchanged historical/live-hatch evidence enforced`);

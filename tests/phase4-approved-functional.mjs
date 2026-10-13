import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { sha256 } from '../scripts/verify-phase4-approved-membership.mjs';
import { FUNCTIONAL_BASELINE, FUNCTIONAL_PATCH_PATH, FUNCTIONAL_RECORD_PATH, FUNCTIONAL_FILES,
  FUNCTIONAL_HISTORICAL_RECORDS, FUNCTIONAL_BRAIN_BEFORE, FUNCTIONAL_BRAIN_AFTER,
  applyApprovedFunctionalPatch, expectedFunctionalRecord, extractFunctionalMethod,
  verifyApprovedFunctional, verifyApprovedFunctionalBrain, verifyFunctionalProtectedFiles,
  verifyFunctionalHistoricalRecords, verifyFunctionalWorkspace } from '../scripts/verify-phase4-approved-functional.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const gitFile = file => execFileSync('git', ['show', `${FUNCTIONAL_BASELINE}:${file}`], { cwd: root, maxBuffer: 8 * 1024 * 1024 });
const before = new Map(FUNCTIONAL_FILES.map(check => [check.file, gitFile(check.file)]));
const patch = await readFile(path.join(root, FUNCTIONAL_PATCH_PATH));
const record = JSON.parse(await readFile(path.join(root, FUNCTIONAL_RECORD_PATH), 'utf8'));
const after = applyApprovedFunctionalPatch(before, patch);
const clone = value => JSON.parse(JSON.stringify(value));
let checks = 0;
function test(label, callback) { callback(); checks += 1; }
test('exact approved transform and independently recorded evidence passes', () => {
  assert.deepEqual(verifyApprovedFunctional(before, after, patch, record), expectedFunctionalRecord(before, patch));
});
function rejectSource(label, file, replacement) {
  test(label, () => {
    const changed = new Map(after), old = changed.get(file), edited = replacement(old);
    assert.notEqual(edited, old, 'Negative test must change actual bytes'); changed.set(file, edited);
    const forged = clone(record), target = forged.files.find(value => value.file === file);
    target.afterSha256 = sha256(edited);
    assert.throws(() => verifyApprovedFunctional(before, changed, patch, forged), /Unapproved functional source change/);
  });
}
rejectSource('default activation cannot be laundered through a replacement hash', FUNCTIONAL_FILES[0].file,
  text => text.replace('OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST = false', 'OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST = true'));
rejectSource('common scope cannot broaden to another egg', FUNCTIONAL_FILES[1].file,
  text => text.replace('return egg.Name == "Common Egg"', 'return egg.Name ~= nil'));
rejectSource('owner account predicate cannot be weakened', FUNCTIONAL_FILES[1].file,
  text => text.replace('id ~= settings.AUTHORIZED_ACCOUNT_ID', 'false'));
rejectSource('ten-Coin maximum cannot broaden', FUNCTIONAL_FILES[1].file,
  text => text.replace('ceiling > 10', 'ceiling > 100'));
rejectSource('ordinary economics cannot be bypassed', FUNCTIONAL_FILES[1].file,
  text => text.replace('and not egg.OwnerCommonFunctionalTestEligible then return "NO_USEFUL_IMPROVEMENT', 'and false then return "NO_USEFUL_IMPROVEMENT'));
rejectSource('unrelated Brain movement change cannot inherit approval', FUNCTIONAL_FILES[2].file,
  text => text + '\n-- unapproved movement source edit\n');
test('Brain historical proof admits precisely its one reviewed economic condition', () => {
  const source = before.get(FUNCTIONAL_FILES[2].file).toString('utf8');
  assert.equal(verifyApprovedFunctionalBrain(source, after.get(FUNCTIONAL_FILES[2].file), record), FUNCTIONAL_FILES[2].afterSha256);
  assert.equal(after.get(FUNCTIONAL_FILES[2].file), source.replace(FUNCTIONAL_BRAIN_BEFORE, FUNCTIONAL_BRAIN_AFTER));
});
test('Brain replacement metadata cannot authorize an added action', () => {
  const source = before.get(FUNCTIONAL_FILES[2].file).toString('utf8'), forged = clone(record);
  forged.brainReplacement.after += '\nself:UnapprovedAction()';
  assert.throws(() => verifyApprovedFunctionalBrain(source, after.get(FUNCTIONAL_FILES[2].file), forged), /cannot broaden replacement/);
});
test('Brain extra edits fail even after changed record hashes', () => {
  const source = before.get(FUNCTIONAL_FILES[2].file).toString('utf8'), changed = after.get(FUNCTIONAL_FILES[2].file) + '\nself:UnapprovedAction()\n';
  const forged = clone(record); forged.files.find(value => value.file === FUNCTIONAL_FILES[2].file).afterSha256 = sha256(changed);
  assert.throws(() => verifyApprovedFunctionalBrain(source, changed, forged), /Unapproved OCBrain edit/);
});
test('immutable patch rejects whitespace as well as broader content', () => {
  assert.throws(() => applyApprovedFunctionalPatch(before, Buffer.concat([patch, Buffer.from('\n')])), /patch bytes changed/);
  const changed = patch.toString('utf8').replace('egg.Name == "Common Egg"', 'egg.Name ~= nil');
  assert.throws(() => applyApprovedFunctionalPatch(before, Buffer.from(changed)), /patch bytes changed/);
});
test('changed pre-approval files cannot be laundered through new hashes', () => {
  const changed = new Map(before); changed.set(FUNCTIONAL_FILES[0].file, Buffer.concat([changed.get(FUNCTIONAL_FILES[0].file), Buffer.from('\n')]));
  assert.throws(() => applyApprovedFunctionalPatch(changed, patch), /Immutable functional baseline changed/);
});
test('approval scope, date, baseline, activation and method text are independently pinned', () => {
  const mutations = [
    value => { value.baseline = '0'.repeat(40); },
    value => { value.approval.date = '2026-10-14'; },
    value => { value.approval.title = 'APPROVED'; },
    value => { value.approval.quote = 'Allow all hatches'; },
    value => { value.activation.AUTO_HATCH = true; },
    value => { value.activation.AUTHORIZED_ACCOUNT_ID = 123; },
    value => { value.methods[0].afterMethodText += '\n'; value.methods[0].afterSha256 = sha256(value.methods[0].afterMethodText); },
    value => { value.historicalProof.records[0].sha256 = sha256('changed'); },
  ];
  for (const mutate of mutations) { const forged = clone(record); mutate(forged); assert.throws(() => verifyApprovedFunctional(before, after, patch, forged), /cannot expand scope/); }
});
test('duplicated protected method definitions cannot pass extraction', () => {
  const text = record.methods[0].afterMethodText;
  assert.throws(() => extractFunctionalMethod(`${text}\n${text}`, record.methods[0].signature), /Missing or duplicated approved method/);
});
const protectedNames = execFileSync('git', ['ls-tree', '-r', '--name-only', FUNCTIONAL_BASELINE, 'src'], { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(file => file.endsWith('.luau'));
const frozenProtected = new Map(protectedNames.map(file => [file, gitFile(file)]));
const currentProtected = new Map(frozenProtected);
for (const [file, text] of after) currentProtected.set(file, Buffer.from(text));
test('all other production source retains immutable review bytes', () => {
  assert.equal(verifyFunctionalProtectedFiles(currentProtected, frozenProtected), protectedNames.length - 3);
});
for (const [label, file] of [
  ['movement', 'src/OCFoundation/EggTravelManager.luau'],
  ['native identity/pricing', 'src/OCFoundation/GameKnowledge.luau'],
  ['fresh final execution guards/equipment', 'src/OCFoundation/PetManager.luau'],
  ['receipt and transport', 'src/OCFoundation/HatchManager.luau'],
  ['allowance ledger', 'src/OCFoundation/OwnerHatchTestAllowance.luau'],
  ['scheduler ownership', 'src/OCFoundation/TaskScheduler.luau'],
]) {
  test(`unrelated ${label} source remains protected`, () => {
    const changed = new Map(currentProtected);
    changed.set(file, Buffer.concat([changed.get(file), Buffer.from('\n-- unapproved\n')]));
    assert.throws(() => verifyFunctionalProtectedFiles(changed, frozenProtected), /Protected production source changed/);
  });
}
test('new production modules cannot bypass protected file coverage', () => {
  const changed = new Map(currentProtected); changed.set('src/OCFoundation/Unapproved.luau', 'return {}\n');
  assert.throws(() => verifyFunctionalProtectedFiles(changed, frozenProtected), /source file set changed/);
});
const frozenHistory = new Map(FUNCTIONAL_HISTORICAL_RECORDS.map(check => [check.file, gitFile(check.file)]));
test('all original approvals and reviewed proposal history remain identical', () => {
  assert.equal(verifyFunctionalHistoricalRecords(frozenHistory, frozenHistory), 5);
});
for (const check of FUNCTIONAL_HISTORICAL_RECORDS) {
  test(`historical ${check.file} cannot be rewritten or self-repinned`, () => {
    const changed = new Map(frozenHistory); changed.set(check.file, Buffer.concat([changed.get(check.file), Buffer.from('\n')]));
    assert.throws(() => verifyFunctionalHistoricalRecords(changed, frozenHistory), /must remain unchanged/);
    assert.throws(() => verifyFunctionalHistoricalRecords(changed, changed), /Immutable functional historical source changed/);
  });
}
await verifyFunctionalWorkspace();
console.log(`[OC TEST] ${checks} approved-functional preservation checks passed; exact patch, protected movement/actions, disabled activation and immutable history enforced`);

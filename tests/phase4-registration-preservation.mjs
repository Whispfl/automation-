import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { extractFrozenMethod, sha256 } from '../scripts/verify-phase4-approved-membership.mjs';
import { CLASSIFICATION_BASELINE, CLASSIFICATION_FILE, CLASSIFICATION_PATCH_PATH, CLASSIFICATION_RECORD_PATH,
  CLASSIFICATION_METHODS, CLASSIFICATION_HELPER_SHA256, extractClassificationHelper, applyApprovedClassificationPatch,
  verifyApprovedClassification, verifyClassificationHistoricalRecords, verifyClassificationWorkspace } from '../scripts/verify-phase4-approved-classification.mjs';

// Preserve the earlier observed price/paid/cleanup behavior. Two observation
// methods now have a separate exact approval; this does not erase old proof or
// authorize edits outside the complete approved GameKnowledge patch.
const baseline = 'd864a3ec269f2bb1702b47244f3026300ec2ce29';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const gitSource = file => execFileSync('git', ['show', `${baseline}:${file}`], { cwd: root, encoding: 'utf8' });
const knowledgePath = 'src/OCFoundation/GameKnowledge.luau';
const petsPath = 'src/OCFoundation/PetManager.luau';
const beforeKnowledge = gitSource(knowledgePath);
const beforePets = gitSource(petsPath);
const [afterKnowledge, afterPets] = await Promise.all([
  readFile(path.join(root, knowledgePath), 'utf8'), readFile(path.join(root, petsPath), 'utf8'),
]);
const approved = await verifyClassificationWorkspace();
const approvedMethods = new Map(approved.methods.map(record => [record.method, record]));
for (const method of ['EnsureChunkerObserver', 'RecordNativeEggUpdate', 'ReleaseChunkerObserver', 'PickupChunker', 'Destroy']) {
  const record = approvedMethods.get(method);
  if (record) {
    assert.equal(record.beforeMethodText, extractFrozenMethod(beforeKnowledge, method),
      `Earlier immutable observation proof changed: ${method}`);
    assert.equal(extractFrozenMethod(afterKnowledge, method), record.afterMethodText,
      `Classification change exceeds the separately approved method diff: ${method}`);
  } else {
    assert.equal(extractFrozenMethod(afterKnowledge, method), extractFrozenMethod(beforeKnowledge, method),
      `Receiver classification work changed native cleanup/lifecycle: ${method}`);
  }
}
function priceBlock(source) {
  const begin = '\tlocal definitions, stats = c.Knowledge:Get("Eggs"), c.Knowledge:Get("StatsUtil")';
  const finish = '\tlocal coins = raw and raw.Coins';
  assert.equal(source.split(begin).length - 1, 1, 'Native preflight price block missing or duplicated');
  const start = source.indexOf(begin);
  const end = source.indexOf(finish, start);
  assert(end > start, 'Native preflight price boundary missing');
  return source.slice(start, end);
}
assert.equal(priceBlock(afterPets), priceBlock(beforePets), 'Owner-verified native quote implementation changed');
const priceHash = sha256(priceBlock(afterPets));
assert.equal(priceHash, '0546c562df85f9ba22fdb1437f13be9cb5edd08fa5add5d883da2ac0a1a86cea', 'Owner-verified native quote hash changed');
function prepare(source) {
  const signature = 'function PetManager:Prepare(';
  assert.equal(source.split(signature).length - 1, 1, 'Paid hatch/equipment guards missing or duplicated');
  const start = source.indexOf(signature);
  const end = source.indexOf('\nfunction ', start + signature.length);
  assert(end > start, 'Paid guard method boundary missing');
  return source.slice(start, end);
}
assert.equal(prepare(afterPets), prepare(beforePets), 'Receiver diagnostics changed paid price/account/permission guards');
console.log(`[OC TEST] 7 receiver/price preservation areas verified: 5 unchanged, 2 separately approved exact classification differences; native price SHA256 ${priceHash}`);

const classificationBefore = execFileSync('git', ['show', `${CLASSIFICATION_BASELINE}:${CLASSIFICATION_FILE}`], { cwd: root });
const [patch, recordBytes, manifest, membership] = await Promise.all([
  readFile(path.join(root, CLASSIFICATION_PATCH_PATH)), readFile(path.join(root, CLASSIFICATION_RECORD_PATH)),
  readFile(path.join(root, 'docs/PHASE4-TEST-A-PRESERVATION.json')),
  readFile(path.join(root, 'docs/PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json')),
]);
const approval = JSON.parse(recordBytes.toString('utf8'));
const expectedAfter = applyApprovedClassificationPatch(classificationBefore, patch);
const clone = value => JSON.parse(JSON.stringify(value));
let checks = 0;
function test(label, callback) { callback(); checks += 1; }
test('whole source is exactly the immutable baseline transformed by the approved patch', () => {
  verifyApprovedClassification(classificationBefore, afterKnowledge, patch, approval);
  assert.equal(afterKnowledge, expectedAfter);
});
test('all three approved method hashes and helper have independent pinned values', () => {
  assert.equal(approval.methods.length, 3);
  for (const check of CLASSIFICATION_METHODS) {
    assert.equal(sha256(extractFrozenMethod(classificationBefore.toString('utf8'), check.name)), check.beforeSha256);
    assert.equal(sha256(extractFrozenMethod(afterKnowledge, check.name)), check.afterSha256);
  }
  assert.equal(sha256(extractClassificationHelper(afterKnowledge)), CLASSIFICATION_HELPER_SHA256);
});
function rejectsSourceChange(label, replacement) {
  test(label, () => {
    const changed = replacement(expectedAfter);
    assert(changed !== expectedAfter, 'Negative preservation check must actually change the source');
    const forged = clone(approval);
    forged.afterFileSha256 = sha256(changed);
    assert.throws(() => verifyApprovedClassification(classificationBefore, changed, patch, forged),
      /Unapproved GameKnowledge change outside the exact owner-approved classification patch/);
  });
}
rejectsSourceChange('new helper/action calls outside approved methods cannot inherit approval', source => `${source}\nfunction GameKnowledge:UnapprovedAction() return true end\n`);
rejectsSourceChange('physical target discovery cannot inherit classification approval', source => source.replace('function GameKnowledge:ResolveEggLocation(', 'function GameKnowledge:UnapprovedResolveEggLocation('));
rejectsSourceChange('shared geometry relaxation remains rejected even with forged new hashes', source => source.replace('root.Parent == model and prompt.Parent == model', 'true'));
rejectsSourceChange('bounded observation deadline cannot be extended by classification approval', source => source.replace('self.EggObservationDeadline = os.clock() + 5', 'self.EggObservationDeadline = os.clock() + 50'));
rejectsSourceChange('approved classifier cannot omit exact native class identity', source => source.replace('getmetatable(receiver) ~= class', 'false'));
rejectsSourceChange('approved classifier cannot weaken loaded folder ancestry', source => source.replace('if value.Parent ~= receiver._folder or not value:IsDescendantOf(workspace) then', 'if false then'));
rejectsSourceChange('approved classifier cannot whitelist Egg while skipping malformed values', source => source.replace('if typeof(value) ~= "Instance" or not value:IsA("Model") or not eggParts(value) then', 'if value.Name ~= "Egg" and (typeof(value) ~= "Instance" or not value:IsA("Model") or not eggParts(value)) then'));
rejectsSourceChange('approved classifier cannot expand the bounded entry limit', source => source.replace('if entries > 1000 then return false, "ENTRY_LIMIT_EXCEEDED" end', 'if entries > 100000 then return false, "ENTRY_LIMIT_EXCEEDED" end'));
rejectsSourceChange('approved visual prerequisite cannot become unconditional readiness', source => source.replace('if not visual or not visual:IsA("Model") then', 'if false then'));
rejectsSourceChange('opened all-name nearest semantics remain protected by full source transform', source => source.replace('record.Distance + 0.05', 'record.Distance - 0.05'));
rejectsSourceChange('previous exact sparse membership cannot become name equality', source => source.replace('if value == model then member = true break end', 'if value.Name == model.Name then member = true break end'));
rejectsSourceChange('duplicate approved method definitions cannot bypass extraction', source => `${source}\n${approval.methods[0].afterMethodText}`);
test('changed patch bytes cannot self-authorize another transform or another file', () => {
  for (const altered of [Buffer.concat([patch, Buffer.from('\n')]), Buffer.from(patch.toString('utf8').replace(CLASSIFICATION_FILE, 'src/OCFoundation/EggTravelManager.luau'))]) {
    const forged = clone(approval); forged.patch.sha256 = sha256(altered); forged.patch.text = altered.toString('utf8');
    assert.throws(() => verifyApprovedClassification(classificationBefore, expectedAfter, altered, forged), /Owner-approved classification patch bytes changed/);
  }
});
test('changed baseline source cannot be laundered through a rewritten before hash', () => {
  const changed = Buffer.from(classificationBefore.toString('utf8').replace('self.EggObservationDeadline = os.clock() + 5', 'self.EggObservationDeadline = os.clock() + 50'));
  const forged = clone(approval); forged.beforeFileSha256 = sha256(changed);
  assert.throws(() => verifyApprovedClassification(changed, expectedAfter, patch, forged), /Immutable classification baseline source changed/);
});
test('approval metadata cannot broaden scope or impersonate a different owner instruction', () => {
  for (const alter of [
    record => { record.approval.quote += ' Any later edits are also allowed.'; },
    record => { record.approval.date = '2026-10-14'; },
    record => { record.approval.scope.push('Allow another movement system.'); },
    record => { record.file = 'src/OCFoundation/EggTravelManager.luau'; },
    record => { record.methods[0].afterMethodText += '\n-- unapproved'; record.methods[0].afterSha256 = sha256(record.methods[0].afterMethodText); },
    record => { record.helper.afterText += '\n-- unapproved'; record.helper.afterSha256 = sha256(record.helper.afterText); },
  ]) {
    const forged = clone(approval); alter(forged);
    assert.throws(() => verifyApprovedClassification(classificationBefore, expectedAfter, patch, forged), /Classification approval record cannot expand scope/);
  }
});
test('historical manifest and earlier membership approval remain immutable bytes', () => {
  const immutable = file => execFileSync('git', ['show', `${CLASSIFICATION_BASELINE}:${file}`], { cwd: root });
  const oldManifest = immutable('docs/PHASE4-TEST-A-PRESERVATION.json');
  const oldMembership = immutable('docs/PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json');
  verifyClassificationHistoricalRecords(manifest, oldManifest, membership, oldMembership);
  assert.throws(() => verifyClassificationHistoricalRecords(Buffer.concat([manifest, Buffer.from('\n')]), oldManifest, membership, oldMembership), /byte-for-byte unchanged/);
  assert.throws(() => verifyClassificationHistoricalRecords(manifest, oldManifest, Buffer.concat([membership, Buffer.from('\n')]), oldMembership), /Previously approved sparse-membership record changed/);
  const forged = JSON.parse(membership.toString('utf8')); forged.approval.quote += ' and receiver changes';
  assert.throws(() => verifyClassificationHistoricalRecords(manifest, oldManifest, Buffer.from(JSON.stringify(forged)), oldMembership), /Previously approved sparse-membership record changed/);
});
console.log(`[OC TEST] ${checks} classification exact-difference checks passed; 3 approved methods + helper, broader edits and rewritten historical proof rejected`);

import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { TEST_A_BASELINE, HISTORICAL_MANIFEST_COMMIT, MEMBERSHIP_FILE, MEMBERSHIP_METHOD,
  sha256, extractFrozenMethod, verifyHistoricalManifest, verifyApprovedMembership, verifyUnchangedGeometryHelper } from '../scripts/verify-phase4-approved-membership.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const record = JSON.parse(await readFile(path.join(root, 'docs/PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json'), 'utf8'));
const before = record.beforeMethodText;
const after = record.afterMethodText;
const currentSource = await readFile(path.join(root, MEMBERSHIP_FILE), 'utf8');
const clone = value => JSON.parse(JSON.stringify(value));
let checks = 0;
function test(label, callback) { callback(); checks += 1; }

test('exact separately approved method difference passes', () => {
  const current = extractFrozenMethod(currentSource, MEMBERSHIP_METHOD);
  assert.equal(verifyApprovedMembership(before, current, record), record.afterSha256);
});
function rejectsExtraEdit(label, replacement) {
  test(label, () => {
    const changed = replacement(after);
    assert.notEqual(changed, after, 'Negative check must actually change the method');
    const forged = clone(record);
    forged.afterMethodText = changed;
    forged.afterSha256 = sha256(changed);
    assert.throws(() => verifyApprovedMembership(before, changed, forged), /Unapproved ObserveEggModel change/);
  });
}
rejectsExtraEdit('updated hashes cannot permit weaker parent access', text => text.replace('if model.Parent ~= receiver._folder then continue end', 'if false then continue end'));
rejectsExtraEdit('updated hashes cannot permit weaker geometry', text => text.replace('if not root then', 'if false then'));
rejectsExtraEdit('updated hashes cannot permit a new action/helper call', text => text.replace('\treturn record', '\tself:UnapprovedAction()\n\treturn record'));
rejectsExtraEdit('updated hashes cannot permit reduced receiver ambiguity', text => text.replace('receivers > 1', 'receivers > 999'));
rejectsExtraEdit('updated hashes cannot permit a name-based membership replacement', text => text.replace('if value == model then', 'if value.Name == model.Name then'));
rejectsExtraEdit('restoring table.find cannot claim the correction passed', () => before);

test('a broader replacement record cannot self-authorize a helper/access edit', () => {
  const forged = clone(record);
  forged.replacement.after = forged.replacement.after.replace('value == model', 'true');
  forged.afterMethodText = before.replace(forged.replacement.before, forged.replacement.after);
  forged.afterSha256 = sha256(forged.afterMethodText);
  assert.throws(() => verifyApprovedMembership(before, forged.afterMethodText, forged), /Approved replacement is broader/);
});
test('another file or method cannot inherit this approval', () => {
  for (const [field, value] of [['file', 'src/OCFoundation/EggTravelManager.luau'], ['method', 'ResolveEggLocation']]) {
    const forged = clone(record); forged[field] = value;
    assert.throws(() => verifyApprovedMembership(before, after, forged), /Membership approval must target only/);
  }
});
test('an edited original baseline cannot be laundered through new historical hashes', () => {
  const forged = clone(record);
  forged.beforeMethodText = before.replace('if not root then', 'if false then');
  forged.beforeSha256 = sha256(forged.beforeMethodText);
  assert.throws(() => verifyApprovedMembership(forged.beforeMethodText, after, forged), /Original Test A membership method changed/);
});
test('historical manifest edits including only whitespace cannot rewrite preservation proof', () => {
  const historical = execFileSync('git', ['show', `${HISTORICAL_MANIFEST_COMMIT}:docs/PHASE4-TEST-A-PRESERVATION.json`], { cwd: root });
  verifyHistoricalManifest(historical, historical);
  const changed = Buffer.concat([historical, Buffer.from('\n')]);
  assert.throws(() => verifyHistoricalManifest(changed, historical), /byte-for-byte unchanged/);
  assert.throws(() => verifyHistoricalManifest(changed, changed), /Historical Test A manifest source changed/);
  const edited = JSON.parse(historical.toString('utf8'));
  edited.checks.find(check => check.method === MEMBERSHIP_METHOD).sha256 = record.afterSha256;
  assert.throws(() => verifyHistoricalManifest(Buffer.from(JSON.stringify(edited)), historical), /byte-for-byte unchanged/);
});
test('shared geometry and receiver helpers remain independently protected', () => {
  const baseline = execFileSync('git', ['show', `${TEST_A_BASELINE}:${MEMBERSHIP_FILE}`], { cwd: root, encoding: 'utf8' });
  for (const [name, oldText, newText] of [
    ['point', 'math.abs(n) < math.huge', 'true'],
    ['eggParts', 'root.Parent == model', 'true'],
    ['eggReceiver', 'receiver.Mode == "3D"', 'true'],
  ]) {
    verifyUnchangedGeometryHelper(baseline, baseline, name);
    const changed = baseline.replace(oldText, newText);
    assert.notEqual(changed, baseline);
    assert.throws(() => verifyUnchangedGeometryHelper(baseline, changed, name), /Shared Test A geometry helper changed/);
  }
});
test('duplicate protected method definitions cannot bypass first-method extraction', () => {
  assert.throws(() => extractFrozenMethod(`${after}\n${after}`, MEMBERSHIP_METHOD), /Missing or duplicated preserved method/);
});

console.log(`[OC TEST] ${checks} approved-membership preservation checks passed; broader edits and rewritten historical proof rejected`);

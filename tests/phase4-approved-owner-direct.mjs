import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { OWNER_DIRECT_BASELINE, OWNER_DIRECT_FILES, OWNER_DIRECT_PATCH, OWNER_DIRECT_RECORD,
  OWNER_DIRECT_PATCH_SHA256, OWNER_DIRECT_FROZEN_METHODS, extractOwnerDirectMethod,
  applyApprovedOwnerDirectPatch, expectedOwnerDirectRecord, verifyApprovedOwnerDirect,
  stripApprovedOwnerDirectDelta, stripApprovedOwnerDirectFiles, verifyOwnerDirectProtectedFiles, verifyOwnerDirectWorkspace,
} from '../scripts/verify-phase4-approved-owner-direct.mjs';

const root = path.resolve(import.meta.dirname, '..');
const sha = value => createHash('sha256').update(value).digest('hex');
const before = new Map(OWNER_DIRECT_FILES.map(check => [check.file, execFileSync('git', ['show', `${OWNER_DIRECT_BASELINE}:${check.file}`], { cwd: root })]));
const patch = await readFile(path.join(root, OWNER_DIRECT_PATCH));
const after = applyApprovedOwnerDirectPatch(before, patch), record = JSON.parse(await readFile(path.join(root, OWNER_DIRECT_RECORD), 'utf8'));
const clone = value => JSON.parse(JSON.stringify(value));
let groups = 0;
function test(label, callback) { callback(); groups += 1; }

test('new diagnostic approval is a separate exact implemented record', () => {
  assert.equal(sha(patch), OWNER_DIRECT_PATCH_SHA256);
  assert.deepEqual(verifyApprovedOwnerDirect(before, after, patch, record), expectedOwnerDirectRecord(before, patch));
  assert.equal(record.baseline, OWNER_DIRECT_BASELINE);
  assert.equal(record.enabledTest.accountId, 10864747620);
  assert.equal(record.defaults.OWNER_DIRECT_EGG_TELEPORT_TEST, false);
});

for (const check of OWNER_DIRECT_FILES) {
  test(`each actual source has its independently pinned delta: ${check.file}`, () => {
    assert.equal(sha(before.get(check.file)), check.beforeSha256);
    assert.equal(sha(after.get(check.file)), check.afterSha256);
  });
  test(`arbitrary changes cannot be hidden by mutable after hashes: ${check.file}`, () => {
    const changed = new Map(after); changed.set(check.file, `${changed.get(check.file)}\n-- unapproved\n`);
    const forged = clone(record); forged.files.find(value => value.file === check.file).afterSha256 = sha(changed.get(check.file));
    assert.throws(() => verifyApprovedOwnerDirect(before, changed, patch, forged), /Unapproved owner diagnostic source delta/);
    assert.throws(() => stripApprovedOwnerDirectDelta(check.file, changed.get(check.file)), /Unapproved owner diagnostic source delta/);
  });
  test(`unapproved before source cannot be laundered: ${check.file}`, () => {
    const changed = new Map(before); changed.set(check.file, `${Buffer.from(changed.get(check.file)).toString('utf8')}\n`);
    assert.throws(() => applyApprovedOwnerDirectPatch(changed, patch), /immutable preimage changed/);
  });
  test(`historical projection returns exact preimage only: ${check.file}`, () => {
    assert.equal(stripApprovedOwnerDirectDelta(check.file, after.get(check.file)), before.get(check.file).toString('utf8'));
    assert.deepEqual(stripApprovedOwnerDirectDelta(check.file, Buffer.from(after.get(check.file))), before.get(check.file));
    assert.throws(() => stripApprovedOwnerDirectDelta(check.file, before.get(check.file)), /Unapproved owner diagnostic source delta/);
  });
}

for (const check of OWNER_DIRECT_FROZEN_METHODS) {
  test(`protected method exact existing hash is frozen: ${check.signature}`, () => {
    const original = extractOwnerDirectMethod(before.get(check.file).toString('utf8'), check.signature, check.trailingNewline);
    const current = extractOwnerDirectMethod(after.get(check.file), check.signature, check.trailingNewline);
    assert.equal(sha(original), check.sha256); assert.equal(current, original);
    const changed = new Map(after); changed.set(check.file, changed.get(check.file).replace(current, `${current}\n-- unapproved protected method bytes\n`));
    assert.throws(() => verifyApprovedOwnerDirect(before, changed, patch, record), /Unapproved owner diagnostic source delta/);
  });
}

test('changed patch bytes cannot redefine the diagnostic', () => {
  assert.throws(() => applyApprovedOwnerDirectPatch(before, Buffer.concat([patch, Buffer.from('\n')])), /implementation patch changed/);
});

test('new dispatch does not alter ordinary Execute outside three added lines', () => {
  const file = OWNER_DIRECT_FILES[0].file;
  const added = '\tif settings.OWNER_DIRECT_EGG_TELEPORT_TEST then\n\t\treturn c.Farming.Mechanics:ExecuteOwnerDirectEggTeleportTest(self, record, token)\n\tend\n';
  assert.equal(after.get(file).split(added).length - 1, 1);
  assert.equal(after.get(file).replace(added, ''), before.get(file).toString('utf8'));
});

test('Config differs only by one false-by-default commented flag', () => {
  const file = OWNER_DIRECT_FILES[2].file;
  const added = after.get(file).split('\n').filter(line => line.includes('OWNER_DIRECT_EGG_TELEPORT_TEST'));
  assert.equal(added.length, 1); assert(added[0].includes('= false, --//'));
  assert.equal(after.get(file).replace(added[0] + '\n', ''), before.get(file).toString('utf8'));
});

test('all preceding mechanics source is preserved with only an appended helper', () => {
  const file = OWNER_DIRECT_FILES[1].file, source = after.get(file);
  const start = source.indexOf('-- Explicit owner diagnostic only. Ordinary standing/positioning methods above stay frozen.');
  assert(start > 0);
  assert.equal(source.slice(0, start) + 'return GameMechanics\n', before.get(file).toString('utf8'));
});

test('approval metadata cannot broaden permissions or rewrite history', () => {
  for (const mutate of [
    value => { value.baseline = '0'.repeat(40); },
    value => { value.approval.scope += ' plus retries'; },
    value => { value.approval.quote = 'Approve all accounts'; },
    value => { value.defaults.OWNER_DIRECT_EGG_TELEPORT_TEST = true; },
    value => { value.defaults.AUTO_HATCH = true; },
    value => { value.defaults.spendingBudgets = 10; },
    value => { value.enabledTest.accountId = 1; },
    value => { value.enabledTest.egg = 'Any Egg'; },
    value => { value.enabledTest.assignmentLimit = 2; },
    value => { value.enabledTest.nativeHatchRequests = 1; },
    value => { value.preservation.firstHatchTag = 'latest'; },
    value => { value.patch.provenance = 'Always historically approved'; },
  ]) {
    const forged = clone(record); mutate(forged);
    assert.throws(() => verifyApprovedOwnerDirect(before, after, patch, forged), /cannot broaden source\/scope\/history/);
  }
});

test('projection changes no unrelated source and keeps map file-set', () => {
  const sample = new Map(after); sample.set('src/OCFoundation/HatchManager.luau', 'unmodified sample');
  const normalized = stripApprovedOwnerDirectFiles(sample);
  assert.deepEqual([...normalized.keys()], [...sample.keys()]);
  assert.equal(normalized.get('src/OCFoundation/HatchManager.luau'), 'unmodified sample');
  for (const check of OWNER_DIRECT_FILES) assert.equal(normalized.get(check.file), before.get(check.file).toString('utf8'));
});

const names = execFileSync('git', ['ls-tree', '-r', '--name-only', OWNER_DIRECT_BASELINE, 'src'], { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(file => file.endsWith('.luau'));
const allFrozen = new Map(names.map(file => [file, execFileSync('git', ['show', `${OWNER_DIRECT_BASELINE}:${file}`], { cwd: root })]));
const allCurrent = new Map(allFrozen); for (const [file, value] of after) allCurrent.set(file, value);
test('all 24 unrelated production source files remain independently exact', () => {
  assert.equal(verifyOwnerDirectProtectedFiles(allFrozen, allCurrent), 24);
});
test('every unrelated runtime edit is rejected without changing historical validators', () => {
  for (const file of names.filter(file => !OWNER_DIRECT_FILES.some(check => check.file === file))) {
    const changed = new Map(allCurrent); changed.set(file, `${Buffer.from(changed.get(file)).toString('utf8')}\n`);
    assert.throws(() => verifyOwnerDirectProtectedFiles(allFrozen, changed), /Unapproved production edit outside owner diagnostic/);
  }
});
test('new competing runtime or missing runtime cannot bypass the source set', () => {
  const added = new Map(allCurrent); added.set('src/OCFoundation/NewTravelLoop.luau', 'return {}\n');
  assert.throws(() => verifyOwnerDirectProtectedFiles(allFrozen, added), /production file set/);
  const removed = new Map(allCurrent); removed.delete('src/OCFoundation/HatchManager.luau');
  assert.throws(() => verifyOwnerDirectProtectedFiles(allFrozen, removed), /production file set/);
});

await verifyOwnerDirectWorkspace();
console.log(`[OC TEST] ${groups} owner-direct approval preservation groups passed; isolated exact three-file additions, both protected movement methods unchanged, tampering rejected, historical release/evidence retained`);

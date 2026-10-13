import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';

export const TEST_A_BASELINE = '25890f224f0448f148d009e65514c129aeb4f59c';
export const HISTORICAL_MANIFEST_COMMIT = '358bd6b22a2158ad4be14a7a9adc1561566697b2';
export const HISTORICAL_MANIFEST_SHA256 = '22b156775d41f1528e3c1441cec407192cebef8a972d3429a403e4474747075a';
export const ORIGINAL_MEMBERSHIP_SHA256 = 'd3de29137673e4f28aef1fbf330d75e2e8136c990a05cbb1182d86083f8c3945';
export const MEMBERSHIP_FILE = 'src/OCFoundation/GameKnowledge.luau';
export const MEMBERSHIP_METHOD = 'ObserveEggModel';
export const APPROVAL_QUOTE = 'I approve the specific, minimal change to GameKnowledge:ObserveEggModel() described in your protected-membership proposal: Replace the sparse-array-sensitive table.find membership check with an exact Instance equality search using pairs. This approval is limited to correcting native Instance membership detection.';
export const APPROVED_BEFORE = '\t\t\tif type(values) == "table" and table.find(values, model) then registered += 1 break end';
export const APPROVED_AFTER = [
  '\t\t\tlocal member = false',
  '\t\t\tif type(values) == "table" then',
  '\t\t\t\tfor _, value in pairs(values) do',
  '\t\t\t\t\tif value == model then member = true break end',
  '\t\t\t\tend',
  '\t\t\tend',
  '\t\t\tif member then registered += 1 break end',
].join('\n');

export const sha256 = value => createHash('sha256').update(value).digest('hex');

export function extractFrozenMethod(source, method) {
  const signature = `function GameKnowledge:${method}(`;
  assert.equal(source.split(signature).length - 1, 1, `Missing or duplicated preserved method: ${method}`);
  const start = source.indexOf(signature);
  const end = source.indexOf('\nfunction ', start + signature.length);
  return source.slice(start, end < 0 ? source.length : end);
}

export function verifyHistoricalManifest(current, historical) {
  assert.equal(sha256(historical), HISTORICAL_MANIFEST_SHA256, 'Historical Test A manifest source changed');
  assert.deepEqual(Buffer.from(current), Buffer.from(historical), 'Historical Test A manifest must remain byte-for-byte unchanged');
  const manifest = JSON.parse(Buffer.from(current).toString('utf8'));
  assert.equal(manifest.baseline, TEST_A_BASELINE, 'Test A baseline changed');
  assert.equal(manifest.buildId, '0d5caa499c8c', 'Test A build changed');
  assert.equal(manifest.release, 'phase4-travel-0d5caa499c8c', 'Test A immutable release changed');
  assert.equal(manifest.checks.length, 10, 'Historical Test A checks changed');
  return manifest;
}

export function verifyApprovedMembership(before, after, record) {
  assert.equal(record.schemaVersion, 1, 'Unexpected membership approval record');
  assert.equal(record.baseline, TEST_A_BASELINE, 'Membership approval baseline changed');
  assert.equal(record.file, MEMBERSHIP_FILE, 'Membership approval must target only GameKnowledge');
  assert.equal(record.method, MEMBERSHIP_METHOD, 'Membership approval must target only ObserveEggModel');
  assert.equal(record.historicalManifestSha256, HISTORICAL_MANIFEST_SHA256, 'Membership record changed historical preservation proof');
  assert.equal(record.approval.date, '2026-10-12', 'Membership approval date changed');
  assert.equal(record.approval.title, 'APPROVED — NARROW PHASE 4 PROTECTED-METHOD CORRECTION', 'Membership approval source changed');
  assert.equal(record.approval.quote, APPROVAL_QUOTE, 'Membership approval scope changed');
  assert.equal(sha256(before), ORIGINAL_MEMBERSHIP_SHA256, 'Original Test A membership method changed');
  assert.equal(record.beforeSha256, ORIGINAL_MEMBERSHIP_SHA256, 'Historical membership hash changed');
  assert.equal(record.beforeMethodText, before, 'Approval before text differs from immutable Test A');
  assert.equal(record.replacement.before, APPROVED_BEFORE, 'Approved before operation changed');
  assert.equal(record.replacement.after, APPROVED_AFTER, 'Approved replacement is broader than exact Instance membership');
  assert.equal(before.split(APPROVED_BEFORE).length - 1, 1, 'Approved membership operation must occur exactly once');
  const expected = before.replace(APPROVED_BEFORE, APPROVED_AFTER);
  assert.equal(after, expected, 'Unapproved ObserveEggModel change outside the exact sparse-membership replacement');
  assert.equal(record.afterMethodText, expected, 'Approval after text does not describe the exact replacement');
  assert.equal(record.afterSha256, sha256(expected), 'Approved membership hash differs from exact replacement');
  return record.afterSha256;
}

export function verifyUnchangedGeometryHelper(before, after, name) {
  const signature = `\nlocal function ${name}(`;
  function extract(source) {
    assert.equal(source.split(signature).length - 1, 1, `Missing or duplicated shared geometry helper: ${name}`);
    const start = source.indexOf(signature);
    const tail = source.slice(start + signature.length);
    const next = /\n(?:local )?function /.exec(tail);
    return source.slice(start, next ? start + signature.length + next.index : source.length);
  }
  assert.equal(extract(after), extract(before), `Shared Test A geometry helper changed: ${name}`);
}

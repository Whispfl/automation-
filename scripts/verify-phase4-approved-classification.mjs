import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { stripPhase5Delta } from './verify-phase5-read-only.mjs';
import { sha256, extractFrozenMethod, verifyHistoricalManifest } from './verify-phase4-approved-membership.mjs';

// These pins come from the owner's exact approved patch and immutable pre-edit
// source. Updating a JSON record cannot expand the permitted source transform.
export const CLASSIFICATION_BASELINE = '478ce3710ba2ece46d46653d4372ededc3638e2f';
export const CLASSIFICATION_FILE = 'src/OCFoundation/GameKnowledge.luau';
export const CLASSIFICATION_PATCH_PATH = 'docs/PHASE4-RECEIVER-CLASSIFICATION-PROPOSED.patch';
export const CLASSIFICATION_RECORD_PATH = 'docs/PHASE4-APPROVED-CLASSIFICATION-CORRECTION.json';
export const CLASSIFICATION_PATCH_SHA256 = 'f46399a7079e6de22062a932ed8f08590724199ce7ea085073d97034e730eadf';
export const CLASSIFICATION_BEFORE_SHA256 = 'a1ef663f88843ed3bd7fdb1b0b3d2d8cb4fa66c414a98ff0319160cf70bd3264';
export const CLASSIFICATION_AFTER_SHA256 = 'e94831b4a0ec3e0049cd642e3c22f45fae54bb616e6c02bb3422cdf05153a202';
export const CLASSIFICATION_HELPER = 'classifyObservedEggQueue';
export const CLASSIFICATION_HELPER_SHA256 = 'dd9e536dc417751ff2ca4eac7e588daea6c76bc0fe7019a88973d383fa2b9cf9';
export const PRIOR_MEMBERSHIP_RECORD_SHA256 = '65b762851dfd2a046713640193ddf6ab06a4028cd73afaa70a3abba88bffec95';
export const CLASSIFICATION_APPROVAL_TITLE = 'APPROVED — PHASE 4 NATIVE EGG RECEIVER CLASSIFICATION REPAIR';
export const CLASSIFICATION_APPROVAL_QUOTE = 'I approve implementation of the narrowly scoped three-method proposal described in `docs/PHASE4-RECEIVER-CLASSIFICATION-PROPOSED.patch`, together with its shared classifier.';
export const CLASSIFICATION_METHODS = Object.freeze([
  Object.freeze({ name: 'EnsureChunkerObserver', beforeSha256: 'f8a2fcf35c88088fb13ed14f690b5cbba0ade21abe1812c8063d586b658b4e06', afterSha256: '398380ce44359616321a0a8d927b80f3d79e1eabd2096d304796b80a6ee21add' }),
  Object.freeze({ name: 'RecordNativeEggUpdate', beforeSha256: '9f904fd8b7d5676213d12699ad9949e1a8e7cf74a9c3a4636fff6605b4c23cf6', afterSha256: '2c83d2480ca8ffb0c1e780188e0787ce66a72a91f195e5f061731c8817297285' }),
  Object.freeze({ name: 'NativeEggRangeEligible', beforeSha256: '1df9b01f21ad46eabc1eb88a709dfb2ba7e66f2e0b170914e98155186fc8e108', afterSha256: '18bda385d398b2ce78d458faeecf85a885f3d9f1d63ff3089057e751c845da86' }),
]);

export function extractClassificationHelper(source) {
  const signature = `local function ${CLASSIFICATION_HELPER}(`;
  assert.equal(source.split(signature).length - 1, 1, 'Missing or duplicated approved queue classifier');
  const start = source.indexOf(signature);
  const end = source.indexOf('\nfunction ', start + signature.length);
  assert(end > start, 'Approved queue classifier boundary missing');
  return source.slice(start, end);
}

export function applyApprovedClassificationPatch(before, patch) {
  assert.equal(sha256(before), CLASSIFICATION_BEFORE_SHA256, 'Immutable classification baseline source changed');
  assert.equal(sha256(patch), CLASSIFICATION_PATCH_SHA256, 'Owner-approved classification patch bytes changed');
  const text = Buffer.from(patch).toString('utf8');
  assert(text.endsWith('\n') && !text.includes('\r'), 'Approved patch must retain exact LF bytes');
  const lines = text.slice(0, -1).split('\n');
  assert.deepEqual(lines.slice(0, 3), [
    `diff --git a/${CLASSIFICATION_FILE} b/${CLASSIFICATION_FILE}`,
    `--- a/${CLASSIFICATION_FILE}`,
    `+++ b/${CLASSIFICATION_FILE}`,
  ], 'Classification approval must target one exact source file');
  const original = Buffer.from(before).toString('utf8').split('\n');
  const result = [];
  let cursor = 0, index = 3, hunks = 0;
  while (index < lines.length) {
    const header = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(?:.*)$/.exec(lines[index++]);
    assert(header, 'Unexpected approved patch header or additional file');
    const oldStart = Number(header[1]) - 1, oldCount = Number(header[2] ?? 1);
    const newStart = Number(header[3]) - 1, newCount = Number(header[4] ?? 1);
    assert(oldStart >= cursor, 'Approved patch hunks overlap');
    result.push(...original.slice(cursor, oldStart));
    cursor = oldStart;
    assert.equal(result.length, newStart, 'Approved patch new-line position inconsistent');
    let removed = 0, added = 0;
    while (index < lines.length && !lines[index].startsWith('@@ ')) {
      const line = lines[index++], operation = line[0], content = line.slice(1);
      assert([' ', '-', '+'].includes(operation), 'Unsupported approved patch line');
      if (operation !== '+') {
        assert.equal(original[cursor], content, 'Approved patch context/removal does not match immutable source');
        cursor += 1; removed += 1;
      }
      if (operation !== '-') { result.push(content); added += 1; }
    }
    assert.equal(removed, oldCount, 'Approved patch old-line count inconsistent');
    assert.equal(added, newCount, 'Approved patch new-line count inconsistent');
    hunks += 1;
  }
  assert.equal(hunks, 5, 'Approved classification hunk count changed');
  result.push(...original.slice(cursor));
  const expected = result.join('\n');
  assert.equal(sha256(expected), CLASSIFICATION_AFTER_SHA256, 'Approved patch does not produce the pinned full source');
  return expected;
}

export function expectedClassificationRecord(before, patch) {
  const expected = applyApprovedClassificationPatch(before, patch);
  const methods = CLASSIFICATION_METHODS.map(check => {
    const beforeMethodText = extractFrozenMethod(Buffer.from(before).toString('utf8'), check.name);
    const afterMethodText = extractFrozenMethod(expected, check.name);
    assert.equal(sha256(beforeMethodText), check.beforeSha256, `Pinned pre-approval method changed: ${check.name}`);
    assert.equal(sha256(afterMethodText), check.afterSha256, `Pinned approved method changed: ${check.name}`);
    return { method: check.name, beforeSha256: check.beforeSha256, afterSha256: check.afterSha256, beforeMethodText, afterMethodText };
  });
  const helperText = extractClassificationHelper(expected);
  assert.equal(sha256(helperText), CLASSIFICATION_HELPER_SHA256, 'Pinned approved classifier changed');
  assert.equal(Buffer.from(before).toString('utf8').includes(`local function ${CLASSIFICATION_HELPER}(`), false,
    'Classification helper must be new in the immutable baseline');
  return {
    schemaVersion: 1,
    baseline: CLASSIFICATION_BASELINE,
    baselineBuildId: '6dfccccdf6cf',
    baselineRelease: 'phase4-hatch-6dfccccdf6cf',
    file: CLASSIFICATION_FILE,
    beforeFileSha256: CLASSIFICATION_BEFORE_SHA256,
    afterFileSha256: CLASSIFICATION_AFTER_SHA256,
    patch: { path: CLASSIFICATION_PATCH_PATH, sha256: CLASSIFICATION_PATCH_SHA256, text: Buffer.from(patch).toString('utf8') },
    approval: {
      date: '2026-10-13',
      title: CLASSIFICATION_APPROVAL_TITLE,
      source: 'Direct human owner message in the current Codex conversation; no attachment.',
      quote: CLASSIFICATION_APPROVAL_QUOTE,
      scope: [
        'EnsureChunkerObserver — correct the overly restrictive receiver classification according to verified native lifecycle behavior.',
        'RecordNativeEggUpdate — use the same classifier and distinguish noncatalog originals from malformed entries.',
        'NativeEggRangeEligible — implement the documented native visual-asset prerequisite conservatively.',
        'Add only the shared classifyObservedEggQueue helper contained in the exact approved patch.',
      ],
      exclusions: 'No source outside the exact approved patch; no movement, CFrame, floor/collision, physical destination discovery, OCBrain/scheduler, price implementation, account authorization, native registry mutation, hatch request or spending permission.',
    },
    historicalProof: {
      manifestPath: 'docs/PHASE4-TEST-A-PRESERVATION.json',
      manifestSha256: '22b156775d41f1528e3c1441cec407192cebef8a972d3429a403e4474747075a',
      priorMembershipApprovalPath: 'docs/PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json',
      priorMembershipApprovalSha256: PRIOR_MEMBERSHIP_RECORD_SHA256,
      requirement: 'Preserve both earlier records byte-for-byte; this is a separately approved source difference, not identical Test A observation behavior.',
    },
    methods,
    helper: { name: CLASSIFICATION_HELPER, beforeSha256: null, afterSha256: CLASSIFICATION_HELPER_SHA256, beforeText: null, afterText: helperText },
  };
}

export function verifyApprovedClassification(before, after, patch, record) {
  const expected = applyApprovedClassificationPatch(before, patch);
  assert.equal(Buffer.from(after).toString('utf8'), expected,
    'Unapproved GameKnowledge change outside the exact owner-approved classification patch');
  assert.equal(sha256(after), CLASSIFICATION_AFTER_SHA256, 'Pinned whole approved source bytes changed');
  const approved = expectedClassificationRecord(before, patch);
  assert.deepEqual(record, approved, 'Classification approval record cannot expand scope or rewrite exact before/after evidence');
  return approved;
}

export function verifyClassificationHistoricalRecords(manifest, historicalManifest, membership, historicalMembership) {
  verifyHistoricalManifest(manifest, historicalManifest);
  assert.equal(sha256(historicalMembership), PRIOR_MEMBERSHIP_RECORD_SHA256, 'Immutable prior membership approval source changed');
  assert.equal(sha256(membership), PRIOR_MEMBERSHIP_RECORD_SHA256, 'Previously approved sparse-membership record changed');
  assert.deepEqual(Buffer.from(membership), Buffer.from(historicalMembership), 'Previously approved sparse-membership record must remain byte-for-byte unchanged');
}

export async function verifyClassificationWorkspace() {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const gitFile = file => execFileSync('git', ['show', `${CLASSIFICATION_BASELINE}:${file}`], { cwd: root, maxBuffer: 8 * 1024 * 1024 });
  const [after, patch, recordBytes, manifest, membership] = await Promise.all([
    readFile(path.join(root, CLASSIFICATION_FILE)), readFile(path.join(root, CLASSIFICATION_PATCH_PATH)),
    readFile(path.join(root, CLASSIFICATION_RECORD_PATH)), readFile(path.join(root, 'docs/PHASE4-TEST-A-PRESERVATION.json')),
    readFile(path.join(root, 'docs/PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json')),
  ]);
  const record = verifyApprovedClassification(gitFile(CLASSIFICATION_FILE), stripPhase5Delta(CLASSIFICATION_FILE, after), patch, JSON.parse(recordBytes.toString('utf8')));
  assert.deepEqual(recordBytes, Buffer.from(`${JSON.stringify(record, null, 2)}\n`), 'Classification approval record serialization changed');
  verifyClassificationHistoricalRecords(manifest, gitFile('docs/PHASE4-TEST-A-PRESERVATION.json'), membership,
    gitFile('docs/PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json'));
  console.log('[OC] Classification approval PASS: exact whole-file patch; 3 approved methods + 1 shared classifier; historical and sparse-membership proof unchanged');
  return record;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await verifyClassificationWorkspace();

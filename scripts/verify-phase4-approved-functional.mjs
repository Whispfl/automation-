import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile, readdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { sha256 } from './verify-phase4-approved-membership.mjs';
import { STANDING_FILE, standingApprovalContext, verifyApprovedStanding } from './verify-phase4-approved-standing.mjs';
import { FINAL_STANDING_FILE, finalStandingApprovalContext, verifyApprovedFinalStanding } from './verify-phase4-approved-final-standing.mjs';
import { stripApprovedOwnerDirectFiles } from './verify-phase4-approved-owner-direct.mjs';

// Immutable pins are independent of the new approval JSON. Changing a record
// cannot broaden the approved three-file transform or rewrite prior evidence.
export const FUNCTIONAL_BASELINE = '56c8e7eba1653929edaa4b2c87683961879aef23';
export const FUNCTIONAL_PATCH_PATH = 'docs/PHASE4-FUNCTIONAL-HATCH-EXCEPTION-PROPOSED.patch';
export const FUNCTIONAL_RECORD_PATH = 'docs/PHASE4-APPROVED-FUNCTIONAL-EXCEPTION.json';
export const FUNCTIONAL_PATCH_SHA256 = '4dc7fc10a1532a2c6be2d7ef5c5e5f9fffc97fd699185098f985bc4da6d65e9d';
export const FUNCTIONAL_APPROVAL_TITLE = 'APPROVED — PHASE 4 ISOLATED COMMON EGG FUNCTIONAL TEST EXCEPTION';
export const FUNCTIONAL_APPROVAL_QUOTE = 'I approve implementation of the EXACT reviewed patch: `docs/PHASE4-FUNCTIONAL-HATCH-EXCEPTION-PROPOSED.patch`';
export const FUNCTIONAL_FILES = Object.freeze([
  Object.freeze({ file: 'src/OCFoundation/OCConfig.luau', beforeSha256: '0e252124807c0f853ec5badcf29621653a9e7a52f510b9c680c825d2f896d2f6', afterSha256: '572779a5762093608b27a0517b8b3b544e28eb2ddf5ca44e8a6008871fe866cd', hunks: 1 }),
  Object.freeze({ file: 'src/OCFoundation/PetPolicy.luau', beforeSha256: '2f7cbbf27bea3aed356b2b10397f05ad5b168a6c7d5cf17c1448b9bfe059614f', afterSha256: '74d569e58cad6306bf54a3ba69861feadfcb13901faffc7eff7e1e34a410d441', hunks: 4 }),
  Object.freeze({ file: 'src/OCFoundation/OCBrain.luau', beforeSha256: '65395cdde2c8d9260a92047a5b1c7c572a667a77af70ddba907dfeead4b99c61', afterSha256: '4c106958fa68cd9d006d9a2c273e5dedae9ecac54f69c71b77e04ff72d3696ca', hunks: 1 }),
]);
export const FUNCTIONAL_METHODS = Object.freeze([
  Object.freeze({ file: FUNCTIONAL_FILES[1].file, signature: 'function PetPolicy.Egg(', beforeSha256: '721a4a05edb261d827e08f13c9321b954d7c0a7012c210d0f51b01758cd22858', afterSha256: 'c5156edd8c4eb2ea656f9bbe4064c81dd538aa2290aa6be3f787bbd7b0f8d0fb' }),
  Object.freeze({ file: FUNCTIONAL_FILES[1].file, signature: 'function PetPolicy.EggBlocker(', beforeSha256: 'e0c5ddb62e2807b8ad3f215c364ff80ac23239514daf0dfc1c35cb34cfbd2148', afterSha256: '3d8cbe0ffa67a5b6b1208fa1483e4195f82c0ed11be470b0c3e8b813ed3962e6' }),
  Object.freeze({ file: FUNCTIONAL_FILES[1].file, signature: 'function PetPolicy.EggPlanText(', beforeSha256: '50f08ce7cc6d71f3000e82d2109e7e7565b42d5489c863ce0bdc6344edeaa7b4', afterSha256: '60352de0f12dc2dc52bd093dcc6e8fafa59cf3bbd5a65e95a9c013cc22754e70' }),
  Object.freeze({ file: FUNCTIONAL_FILES[2].file, signature: 'function OCBrain:PlanPets(', beforeSha256: '7378d34caee76076ad9643d9435bf88ff24ff0f25d5a464b6dbbba2fbcb9b0da', afterSha256: 'ad04473df7ef73ca4447acccc6a24a120930341b6583cd6d12e7065422ccd21f' }),
]);
export const FUNCTIONAL_HISTORICAL_RECORDS = Object.freeze([
  Object.freeze({ file: 'docs/PHASE4-TEST-A-PRESERVATION.json', sha256: '22b156775d41f1528e3c1441cec407192cebef8a972d3429a403e4474747075a' }),
  Object.freeze({ file: 'docs/PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json', sha256: '65b762851dfd2a046713640193ddf6ab06a4028cd73afaa70a3abba88bffec95' }),
  Object.freeze({ file: 'docs/PHASE4-APPROVED-CLASSIFICATION-CORRECTION.json', sha256: '97a7c2d150f8c0610a4da359f0cf135c505117be130f7a2f0ace229775243fe5' }),
  Object.freeze({ file: FUNCTIONAL_PATCH_PATH, sha256: FUNCTIONAL_PATCH_SHA256 }),
  Object.freeze({ file: 'docs/PHASE4-FUNCTIONAL-HATCH-EXCEPTION-PROPOSED-HASHES.json', sha256: '574a4a656c697cf9f3b2a3221161fa056fe4360d2d0ff656de621430c0016bef' }),
]);
export const FUNCTIONAL_BRAIN_BEFORE = '\t\t\t\tor (egg.ExpectedIncrement <= 1e-6 and egg.ClientTargetProbability <= 0) then continue end';
export const FUNCTIONAL_BRAIN_AFTER = '\t\t\t\tor (egg.ExpectedIncrement <= 1e-6 and egg.ClientTargetProbability <= 0 and not egg.OwnerCommonFunctionalTestEligible) then continue end';
const entries = files => files instanceof Map ? [...files.entries()] : Object.entries(files);
const fileValue = (files, file) => {
  const value = files instanceof Map ? files.get(file) : files[file];
  assert(value !== undefined, `Missing exact functional source: ${file}`);
  return Buffer.from(value).toString('utf8');
};

export function extractFunctionalMethod(source, signature) {
  assert.equal(source.split(signature).length - 1, 1, `Missing or duplicated approved method: ${signature}`);
  const start = source.indexOf(signature), module = signature.match(/^function (\w+)[.:]/)[1];
  const next = source.indexOf('\nfunction ', start + signature.length), returned = source.indexOf(`\nreturn ${module}`, start + signature.length);
  const end = next < 0 ? returned : returned < 0 ? next : Math.min(next, returned);
  assert(end > start, `Missing approved method boundary: ${signature}`);
  return source.slice(start, end);
}

export function applyApprovedFunctionalPatch(beforeFiles, patch) {
  assert.equal(sha256(patch), FUNCTIONAL_PATCH_SHA256, 'Owner-approved functional patch bytes changed');
  const text = Buffer.from(patch).toString('utf8');
  assert(text.endsWith('\n') && !text.includes('\r'), 'Approved functional patch must retain exact LF bytes');
  const sections = text.split(/(?=^diff --git )/m).filter(Boolean), afterFiles = new Map();
  assert.equal(sections.length, FUNCTIONAL_FILES.length, 'Only three approved functional source files are permitted');
  for (const [sectionIndex, section] of sections.entries()) {
    const check = FUNCTIONAL_FILES[sectionIndex], file = check.file;
    const lines = section.slice(0, -1).split('\n');
    assert.deepEqual(lines.slice(0, 3), [`diff --git a/${file} b/${file}`, `--- a/${file}`, `+++ b/${file}`], 'Approved functional patch targets/order changed');
    const before = fileValue(beforeFiles, file);
    assert.equal(sha256(before), check.beforeSha256, `Immutable functional baseline changed: ${file}`);
    const original = before.split('\n'), result = [];
    let cursor = 0, index = 3, hunks = 0;
    while (index < lines.length) {
      const header = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(?:.*)$/.exec(lines[index++]);
      assert(header, 'Unexpected functional patch hunk');
      const oldStart = Number(header[1]) - 1, oldCount = Number(header[2] ?? 1), newStart = Number(header[3]) - 1, newCount = Number(header[4] ?? 1);
      assert(oldStart >= cursor, 'Approved functional patch hunks overlap');
      result.push(...original.slice(cursor, oldStart)); cursor = oldStart;
      assert.equal(result.length, newStart, 'Approved functional new-line position inconsistent');
      let removed = 0, added = 0;
      while (index < lines.length && !lines[index].startsWith('@@ ')) {
        const line = lines[index++], operation = line[0], content = line.slice(1);
        assert([' ', '-', '+'].includes(operation), 'Unsupported approved functional patch line');
        if (operation !== '+') { assert.equal(original[cursor], content, 'Approved functional context/removal mismatch'); cursor += 1; removed += 1; }
        if (operation !== '-') { result.push(content); added += 1; }
      }
      assert.equal(removed, oldCount, 'Approved functional old-line count inconsistent');
      assert.equal(added, newCount, 'Approved functional new-line count inconsistent');
      hunks += 1;
    }
    assert.equal(hunks, check.hunks, 'Approved functional hunk count changed');
    result.push(...original.slice(cursor));
    const expected = result.join('\n');
    assert.equal(sha256(expected), check.afterSha256, `Approved functional after-file hash mismatch: ${file}`);
    afterFiles.set(file, expected);
  }
  return afterFiles;
}

export function expectedFunctionalRecord(beforeFiles, patch) {
  const afterFiles = applyApprovedFunctionalPatch(beforeFiles, patch);
  const methods = FUNCTIONAL_METHODS.map(check => {
    const beforeMethodText = extractFunctionalMethod(fileValue(beforeFiles, check.file), check.signature);
    const afterMethodText = extractFunctionalMethod(afterFiles.get(check.file), check.signature);
    assert.equal(sha256(beforeMethodText), check.beforeSha256, `Pinned reviewed before-method changed: ${check.signature}`);
    assert.equal(sha256(afterMethodText), check.afterSha256, `Pinned reviewed after-method changed: ${check.signature}`);
    return { ...check, beforeMethodText, afterMethodText };
  });
  const helperSignature = 'function PetPolicy.OwnerCommonEggFunctionalTestEligible(';
  assert.equal(fileValue(beforeFiles, FUNCTIONAL_FILES[1].file).includes(helperSignature), false, 'Approved functional helper must be new');
  const helperText = extractFunctionalMethod(afterFiles.get(FUNCTIONAL_FILES[1].file), helperSignature);
  return {
    schemaVersion: 1, baseline: FUNCTIONAL_BASELINE,
    preservedLiveMilestone: { commit: '55bf4cf437cccd826180519c482bdc6edbbbb51b', buildId: 'f4e10f71c317', tag: 'phase4-hatch-f4e10f71c317' },
    approval: { date: '2026-10-13', title: FUNCTIONAL_APPROVAL_TITLE,
      source: 'Direct human owner message in the current Codex conversation; no attachment.',
      quote: FUNCTIONAL_APPROVAL_QUOTE, reviewCommit: FUNCTIONAL_BASELINE,
      scope: 'Only the exact reviewed three-file patch: OCConfig, PetPolicy and the single OCBrain PlanPets economic condition. One explicitly authorized account, Common Egg in The Overworld, count=1, at most 10 Coins, solely functional receipt verification.',
      exclusions: 'No movement, EggTravelManager, GameKnowledge, Prepare, HatchManager, allowance ledger, native transport or other protected-method change. No paid activation, hatch request, equipment or spending authorization.' },
    patch: { path: FUNCTIONAL_PATCH_PATH, sha256: FUNCTIONAL_PATCH_SHA256, text: Buffer.from(patch).toString('utf8') },
    activation: { OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST: false, OWNER_ONE_HATCH_TEST_ALLOWANCE: false,
      AUTO_HATCH: false, AUTO_EQUIP: false, AUTHORIZED_ACCOUNT_ID: 0, spendingBudgets: 0,
      authorization: 'Implementation and immutable DISABLED publication only; separate explicit owner account-bound paid approval still required.' },
    files: FUNCTIONAL_FILES.map(({ file, beforeSha256, afterSha256 }) => ({ file, beforeSha256, afterSha256 })), methods,
    helper: { file: FUNCTIONAL_FILES[1].file, signature: helperSignature, beforeSha256: null, afterSha256: sha256(helperText), beforeText: null, afterText: helperText },
    brainReplacement: { before: FUNCTIONAL_BRAIN_BEFORE, after: FUNCTIONAL_BRAIN_AFTER },
    historicalProof: { records: FUNCTIONAL_HISTORICAL_RECORDS,
      requirement: 'All original records and reviewed proposal bytes remain unchanged; eight Test A checks retain original bytes, one sparse-membership and one exact PlanPets difference are separately approved. All ten historical baseline hashes remain verified.' },
  };
}

export function verifyApprovedFunctional(beforeFiles, afterFiles, patch, record) {
  const expected = applyApprovedFunctionalPatch(beforeFiles, patch);
  for (const check of FUNCTIONAL_FILES) assert.equal(fileValue(afterFiles, check.file), expected.get(check.file), `Unapproved functional source change outside exact patch: ${check.file}`);
  const approved = expectedFunctionalRecord(beforeFiles, patch);
  assert.deepEqual(record, approved, 'Functional approval record cannot expand scope or rewrite hashes/history/activation');
  return approved;
}

export function verifyApprovedFunctionalBrain(before, after, record) {
  const check = FUNCTIONAL_FILES[2];
  assert.equal(sha256(before), check.beforeSha256, 'Historical Test A Brain bytes changed');
  assert.equal(before.split(FUNCTIONAL_BRAIN_BEFORE).length - 1, 1, 'Exact approved Brain condition must occur once');
  const expected = before.replace(FUNCTIONAL_BRAIN_BEFORE, FUNCTIONAL_BRAIN_AFTER);
  assert.equal(sha256(expected), check.afterSha256, 'Exact reviewed Brain replacement hash changed');
  assert.equal(after, expected, 'Unapproved OCBrain edit outside the exact PlanPets condition');
  assert.deepEqual(record.brainReplacement, { before: FUNCTIONAL_BRAIN_BEFORE, after: FUNCTIONAL_BRAIN_AFTER }, 'Brain approval cannot broaden replacement');
  assert.equal(record.baseline, FUNCTIONAL_BASELINE, 'Brain functional review baseline changed');
  assert.equal(record.approval.title, FUNCTIONAL_APPROVAL_TITLE, 'Brain functional approval title changed');
  assert.equal(record.approval.quote, FUNCTIONAL_APPROVAL_QUOTE, 'Brain functional approval quote changed');
  assert.deepEqual(record.files.find(value => value.file === check.file), { file: check.file, beforeSha256: check.beforeSha256, afterSha256: check.afterSha256 }, 'Brain historical hashes cannot be rewritten');
  return check.afterSha256;
}

export function verifyFunctionalProtectedFiles(currentFiles, frozenFiles, standing, finalStanding) {
  assert.deepEqual(entries(currentFiles).map(([file]) => file).sort(), entries(frozenFiles).map(([file]) => file).sort(), 'Protected production source file set changed');
  let checked = 0;
  for (const [file, frozen] of entries(frozenFiles)) {
    if (FUNCTIONAL_FILES.some(check => check.file === file)) continue;
    if (finalStanding && file === FINAL_STANDING_FILE) {
      verifyApprovedFinalStanding(frozen, fileValue(currentFiles, file), finalStanding.patch, finalStanding.record);
      checked += 1;
      continue;
    }
    if (standing && file === STANDING_FILE) {
      verifyApprovedStanding(frozen, fileValue(currentFiles, file), standing.patches, standing.record);
      checked += 1;
      continue;
    }
    assert.deepEqual(Buffer.from(fileValue(currentFiles, file)), Buffer.from(frozen), `Protected production source changed: ${file}`);
    checked += 1;
  }
  return checked;
}

export function verifyFunctionalHistoricalRecords(currentFiles, frozenFiles) {
  for (const check of FUNCTIONAL_HISTORICAL_RECORDS) {
    const frozen = fileValue(frozenFiles, check.file), current = fileValue(currentFiles, check.file);
    assert.equal(sha256(frozen), check.sha256, `Immutable functional historical source changed: ${check.file}`);
    assert.equal(current, frozen, `Historical approval/proposal bytes must remain unchanged: ${check.file}`);
  }
  return FUNCTIONAL_HISTORICAL_RECORDS.length;
}

export async function verifyFunctionalWorkspace() {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const gitFile = file => execFileSync('git', ['show', `${FUNCTIONAL_BASELINE}:${file}`], { cwd: root, maxBuffer: 8 * 1024 * 1024 });
  const beforeFiles = new Map(FUNCTIONAL_FILES.map(check => [check.file, gitFile(check.file)]));
  const afterFiles = stripApprovedOwnerDirectFiles(new Map(await Promise.all(FUNCTIONAL_FILES.map(async check => [check.file, await readFile(path.join(root, check.file))]))));
  const patch = await readFile(path.join(root, FUNCTIONAL_PATCH_PATH)), recordBytes = await readFile(path.join(root, FUNCTIONAL_RECORD_PATH));
  const record = verifyApprovedFunctional(beforeFiles, afterFiles, patch, JSON.parse(recordBytes.toString('utf8')));
  assert.deepEqual(recordBytes, Buffer.from(`${JSON.stringify(record, null, 2)}\n`), 'Functional approval record serialization changed');
  const protectedNames = execFileSync('git', ['ls-tree', '-r', '--name-only', FUNCTIONAL_BASELINE, 'src'], { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(file => file.endsWith('.luau'));
  async function sourceFiles(directory) {
    const contents = await readdir(path.join(root, directory), { withFileTypes: true });
    const nested = await Promise.all(contents.map(entry => entry.isDirectory() ? sourceFiles(`${directory}/${entry.name}`) : entry.name.endsWith('.luau') ? [`${directory}/${entry.name}`] : []));
    return nested.flat();
  }
  const currentNames = await sourceFiles('src');
  const current = stripApprovedOwnerDirectFiles(new Map(await Promise.all(currentNames.map(async file => [file, await readFile(path.join(root, file))])))), frozen = new Map(protectedNames.map(file => [file, gitFile(file)]));
  const standing = await standingApprovalContext(root);
  const finalStanding = await finalStandingApprovalContext(root);
  const protectedCount = verifyFunctionalProtectedFiles(current, frozen, standing, finalStanding);
  const history = new Map(await Promise.all(FUNCTIONAL_HISTORICAL_RECORDS.map(async check => [check.file, await readFile(path.join(root, check.file))])));
  verifyFunctionalHistoricalRecords(history, new Map(FUNCTIONAL_HISTORICAL_RECORDS.map(check => [check.file, gitFile(check.file)])));
  console.log(`[OC] Functional approval PASS: exact 3 files, 4 reviewed methods + 1 helper; ${protectedCount - 2} other production source files and 5 historical records unchanged; separately approved exact standing and final adapter transforms; paid activation remains separately unauthorized`);
  return record;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await verifyFunctionalWorkspace();

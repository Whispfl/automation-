import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { sha256 } from './verify-phase4-approved-membership.mjs';
import { FINAL_STANDING_FILE, finalStandingApprovalContext, verifyApprovedFinalStanding } from './verify-phase4-approved-final-standing.mjs';

// These independent pins are not derived from a mutable approval record.
export const STANDING_BASELINE = 'aae628d9ac8f1941f9b0b92aaedc365be22fa6af';
export const STANDING_REVIEW = '78b97d11f34e245f31e41ff6fac10cbd795f03da';
export const STANDING_FILE = 'src/OCFoundation/EggTravelManager.luau';
export const STANDING_RECORD_PATH = 'docs/PHASE4-APPROVED-STANDING-SUPPORT.json';
export const STANDING_BEFORE_FILE_SHA256 = '7fd14d19e3befc895f3446f41d4882394d12eebc7bc555e5e8b05dd864e4cb8c';
export const STANDING_AFTER_FILE_SHA256 = '15bd589ea9ff1e81354dbe536b347a2a852f59efa4780681234d82ee0540cf3b';
export const STANDING_BEFORE_METHOD_SHA256 = '4996169eb8641b238ac1e52b3784c57a9b690ddf3e47993ddbddb9e2b2fec09a';
export const STANDING_AFTER_METHOD_SHA256 = 'b00f2cf4bf49e91fc7cda952293c6b04c119b7809b0567bad24177ec28f32db6';
export const STANDING_PATCHES = Object.freeze([
  Object.freeze({ path: 'docs/PHASE4-UNIVERSAL-MOVEMENT-STANDING-PROPOSED.patch', sha256: 'b1131059a5b151fb699b04bbf1ae50365cbeddc9a6d2faa222d28edd42d3207f', beforeFileSha256: STANDING_BEFORE_FILE_SHA256, afterFileSha256: '125fb8125a32c998ceb58e4bfa649d6d982e7f6a41da25ef3f8ac08064ecff20', beforeMethodSha256: STANDING_BEFORE_METHOD_SHA256, afterMethodSha256: '8d3129ec4a04c80964f36a0e5f15dc8bf83656618567e9b1a197ee409b893dda' }),
  Object.freeze({ path: 'docs/PHASE4-UNIVERSAL-MOVEMENT-FOOTPRINT-PROPOSED.patch', sha256: 'e812a4acdad9a75877dbaaa175db9fb4b5be948f8369c570366e20b6768d1c36', beforeFileSha256: '125fb8125a32c998ceb58e4bfa649d6d982e7f6a41da25ef3f8ac08064ecff20', afterFileSha256: STANDING_AFTER_FILE_SHA256, beforeMethodSha256: '8d3129ec4a04c80964f36a0e5f15dc8bf83656618567e9b1a197ee409b893dda', afterMethodSha256: STANDING_AFTER_METHOD_SHA256 }),
]);
export const STANDING_HISTORY = Object.freeze([
  ['docs/PHASE4-TEST-A-PRESERVATION.json', '22b156775d41f1528e3c1441cec407192cebef8a972d3429a403e4474747075a'],
  ['docs/PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json', '65b762851dfd2a046713640193ddf6ab06a4028cd73afaa70a3abba88bffec95'],
  ['docs/PHASE4-APPROVED-CLASSIFICATION-CORRECTION.json', '97a7c2d150f8c0610a4da359f0cf135c505117be130f7a2f0ace229775243fe5'],
  ['docs/PHASE4-APPROVED-FUNCTIONAL-EXCEPTION.json', 'bef23ddbe1e4e5ce94057a7f443a081f643340a40e9535635f9850979e262076'],
  ['docs/PHASE4-UNIVERSAL-MOVEMENT-STANDING-PROPOSED.json', 'e76d02c07ae3b17bf544f17e229b089c6e2e878ce70a1d46df8216d4bbd765f7'],
  ['docs/PHASE4-UNIVERSAL-MOVEMENT-FOOTPRINT-PROPOSED.json', '72c5fe58d72c86a195e414c90f11686f26cc644791e9b84c508bc791ebb2c664'],
  ['docs/PHASE4-STANDING-DIAGONAL-APPROVAL.json', '5ad8bacc386fb25d17f28071b9ab78c6399a0b1028f881ee9ba33298dc166bda'],
  ['docs/PHASE4-FIRST-LIVE-HATCH-MILESTONE.md', '1144dd3e1eed2089f87262e6f3e76efbc5693c04a6065dff98c2324779b9a87e'],
  ['docs/evidence/PHASE4-FIRST-LIVE-HATCH-100f2c1907ae-ARCHIVE.json', '0caebc41140a0e0cd709a45c7685b3d292c5a83494d24a3a0f4f164061409bda'],
  ['docs/evidence/PHASE4-FIRST-LIVE-HATCH-100f2c1907ae-CONSOLE.txt', '0765815d70c439d9857d9ee3a3fa6390e346a9d65ff2bee7e9c8c1d900dd7df5'],
  ['docs/evidence/PHASE4-FIRST-LIVE-HATCH-100f2c1907ae-ORIGINAL-SUBMISSION.txt', '3be2f4e5be9c79f4054706f179e5d1b1a4ded5d92d0b74bf236e6d85e848451f'],
  ['docs/evidence/PHASE4-FIRST-LIVE-HATCH-100f2c1907ae-OWNER-REPORT.txt', '02f479fb58f3088266bb97a63c425c8baee6eba950af977bc7ce68a0102c5b10'],
].map(([file, digest]) => Object.freeze({ file, sha256: digest })));
const asText = value => Buffer.from(value).toString('utf8');
const value = (files, file) => { const result = files instanceof Map ? files.get(file) : files[file]; assert(result !== undefined, `Missing standing preservation file: ${file}`); return asText(result); };

export function extractStandingMethod(source) {
  const signature = 'function EggTravelManager:ResolveStanding(';
  assert.equal(source.split(signature).length - 1, 1, 'Standing method must occur exactly once');
  const start = source.indexOf(signature), end = source.indexOf('\nfunction ', start + signature.length);
  assert(end > start, 'Standing method boundary missing');
  return source.slice(start, end);
}

export function applyApprovedStandingPatches(before, patchBytes) {
  let source = asText(before);
  assert.equal(patchBytes.length, 2, 'Both approved standing patches are mandatory');
  for (const [index, check] of STANDING_PATCHES.entries()) {
    const patch = asText(patchBytes[index]);
    assert.equal(sha256(patchBytes[index]), check.sha256, 'Exact approved standing patch bytes changed');
    assert.equal(sha256(source), check.beforeFileSha256, 'Immutable standing preimage changed');
    assert.equal(sha256(extractStandingMethod(source)), check.beforeMethodSha256, 'Standing preimage method changed');
    assert(patch.endsWith('\n') && !patch.includes('\r'), 'Standing patch LF bytes changed');
    const lines = patch.slice(0, -1).split('\n');
    assert.deepEqual(lines.slice(0, 3), [`diff --git a/${STANDING_FILE} b/${STANDING_FILE}`, `--- a/${STANDING_FILE}`, `+++ b/${STANDING_FILE}`], 'Standing patch target changed');
    const match = /^@@ -(\d+),(\d+) \+(\d+),(\d+) @@$/.exec(lines[3]);
    assert(match && !lines.slice(4).some(line => line.startsWith('@@ ')), 'One exact standing hunk required');
    const original = source.split('\n'), start = Number(match[1]) - 1, hunk = lines.slice(4);
    assert(hunk.every(line => [' ', '-', '+'].includes(line[0])), 'Invalid standing hunk operation');
    const removed = hunk.filter(line => line[0] !== '+').map(line => line.slice(1));
    const added = hunk.filter(line => line[0] !== '-').map(line => line.slice(1));
    assert.equal(start, Number(match[3]) - 1, 'Standing patch start changed');
    assert.equal(removed.length, Number(match[2]), 'Standing removal count changed');
    assert.equal(added.length, Number(match[4]), 'Standing addition count changed');
    assert.deepEqual(original.slice(start, start + removed.length), removed, 'Standing exact hunk context changed');
    source = [...original.slice(0, start), ...added, ...original.slice(start + removed.length)].join('\n');
    assert.equal(sha256(source), check.afterFileSha256, 'Standing exact after-file hash changed');
    assert.equal(sha256(extractStandingMethod(source)), check.afterMethodSha256, 'Standing exact after-method hash changed');
  }
  const beforeMethod = extractStandingMethod(asText(before)), afterMethod = extractStandingMethod(source);
  assert.equal(asText(before).replace(beforeMethod, '\n<ONLY_APPROVED_STANDING_METHOD>\n'), source.replace(afterMethod, '\n<ONLY_APPROVED_STANDING_METHOD>\n'), 'Standing patch changed source outside ResolveStanding');
  return source;
}

export function expectedStandingRecord(before, patches) {
  const after = applyApprovedStandingPatches(before, patches);
  return {
    schemaVersion: 1, baseline: STANDING_BASELINE,
    preservedMilestones: [
      { commit: '25890f224f0448f148d009e65514c129aeb4f59c', buildId: '0d5caa499c8c', tag: 'phase4-travel-0d5caa499c8c', status: 'Historical Test A remains immutable; this separately approved method differs.' },
      { commit: STANDING_BASELINE, buildId: '100f2c1907ae', tag: 'phase4-hatch-100f2c1907ae', bundleSha256: '14da5d26f543c0c1d3e9d51e946f21baafe78379502cc05e9954de864ef161e0', status: 'Owner-live first hatch and exact console archive remain immutable; manual final approach, no universal travel claim.' },
    ],
    approval: { date: '2026-10-13', title: 'APPROVED — PHASE 4 SUPPLEMENTAL AVATAR FOOTPRINT SAFETY PATCH', source: 'Direct human owner message in the current Codex conversation.', reviewCommit: STANDING_REVIEW,
      quote: 'Apply BOTH narrowly scoped patches together: 1. The previously approved four-diagonal standing-search patch. 2. This separately approved full-avatar footprint support patch. Both changes must remain exclusively inside EggTravelManager:ResolveStanding.',
      scope: 'Only four same-radius diagonal samples appended after the five original candidates, plus padded projected-avatar support on one verified numerically level solid Block Part with 0.15-stud edge margin. Every existing floor, collision, native range and safety check remains required.',
      exclusions: 'No avatar calculation, raycast, CFrame adapter, native travel, destination, Brain, scheduler, account/lease, arrival, cancellation, retry/recovery, registration, hatch receipt, inventory, equipment, spending or other runtime edit.',
      publicationCondition: 'New immutable TRAVEL_ONLY ZERO-SPEND candidate only after every mandatory gate passes; any failed safety gate stops publication. This record is exact implementation evidence, not live acceptance.' },
    file: STANDING_FILE, method: 'ResolveStanding',
    beforeFileSha256: STANDING_BEFORE_FILE_SHA256, afterFileSha256: STANDING_AFTER_FILE_SHA256,
    beforeMethodSha256: STANDING_BEFORE_METHOD_SHA256, afterMethodSha256: STANDING_AFTER_METHOD_SHA256,
    beforeMethodText: extractStandingMethod(asText(before)), afterMethodText: extractStandingMethod(after),
    patches: STANDING_PATCHES.map((check, index) => ({ ...check, text: asText(patches[index]) })),
    historicalRecords: STANDING_HISTORY,
    activation: { AUTO_HATCH: false, OWNER_ONE_HATCH_TEST_ALLOWANCE: false, OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST: false, AUTO_EQUIP: false, spendingBudgets: 0, policy: 'One separately owner-run bounded movement-only test; no paid action authorization.' },
    limitations: 'One known solid level Block only; Terrain, MeshPart, unions, tilted/complex or multi-piece support fail closed, including legitimate sites. Two existing standing observations are not atomic with CFrame assignment; later geometry changes remain an unresolved race. Offline fixtures do not prove universal live movement.',
  };
}

export function verifyApprovedStanding(before, after, patches, record) {
  const expected = applyApprovedStandingPatches(before, patches);
  assert.equal(asText(after), expected, 'Unapproved standing source edit outside the two exact patches');
  const expectedRecord = expectedStandingRecord(before, patches);
  assert.deepEqual(record, expectedRecord, 'Standing approval record cannot broaden scope or rewrite historical proof');
  return record;
}

export function verifyStandingProtectedFiles(current, frozen, patches, record, finalStanding) {
  assert.deepEqual([...current.keys()].sort(), [...frozen.keys()].sort(), 'First-hatch production source file set changed');
  verifyApprovedStanding(value(frozen, STANDING_FILE), value(current, STANDING_FILE), patches, record);
  let unchanged = 0;
  for (const [file, bytes] of frozen) {
    if (file === STANDING_FILE) continue;
    if (finalStanding && file === FINAL_STANDING_FILE) {
      verifyApprovedFinalStanding(bytes, value(current, file), finalStanding.patch, finalStanding.record);
      continue;
    }
    assert.deepEqual(Buffer.from(value(current, file)), Buffer.from(bytes), `First-hatch protected production source changed: ${file}`);
    unchanged += 1;
  }
  return unchanged;
}

export async function standingApprovalContext(root) {
  return { patches: await Promise.all(STANDING_PATCHES.map(check => readFile(path.join(root, check.path)))), record: JSON.parse(await readFile(path.join(root, STANDING_RECORD_PATH), 'utf8')) };
}

export async function verifyStandingWorkspace() {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const git = (commit, file) => execFileSync('git', ['show', `${commit}:${file}`], { cwd: root, maxBuffer: 8 * 1024 * 1024 });
  const context = await standingApprovalContext(root);
  const names = execFileSync('git', ['ls-tree', '-r', '--name-only', STANDING_BASELINE, 'src'], { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(file => file.endsWith('.luau'));
  async function files(dir) { const entries = await readdir(path.join(root, dir), { withFileTypes: true }); return (await Promise.all(entries.map(entry => entry.isDirectory() ? files(`${dir}/${entry.name}`) : entry.name.endsWith('.luau') ? [`${dir}/${entry.name}`] : []))).flat(); }
  const current = new Map(await Promise.all((await files('src')).map(async file => [file, await readFile(path.join(root, file))])));
  const frozen = new Map(names.map(file => [file, git(STANDING_BASELINE, file)]));
  const finalStanding = await finalStandingApprovalContext(root);
  const count = verifyStandingProtectedFiles(current, frozen, context.patches, context.record, finalStanding);
  for (const [index, check] of STANDING_PATCHES.entries()) assert.deepEqual(context.patches[index], git(STANDING_REVIEW, check.path), 'Reviewed standing patch bytes must remain immutable');
  for (const check of STANDING_HISTORY) {
    const historical = git(STANDING_REVIEW, check.file), now = await readFile(path.join(root, check.file));
    assert.equal(sha256(historical), check.sha256, `Pinned historical standing evidence changed: ${check.file}`);
    assert.deepEqual(now, historical, `Historical standing/hatch approval evidence must remain unchanged: ${check.file}`);
  }
  const recordBytes = await readFile(path.join(root, STANDING_RECORD_PATH));
  assert.deepEqual(recordBytes, Buffer.from(`${JSON.stringify(context.record, null, 2)}\n`), 'Standing record serialization changed');
  assert.equal(execFileSync('git', ['rev-parse', 'phase4-travel-0d5caa499c8c^{commit}'], { cwd: root, encoding: 'utf8' }).trim(), '25890f224f0448f148d009e65514c129aeb4f59c', 'Historical Test A immutable tag changed');
  assert.equal(execFileSync('git', ['rev-parse', 'phase4-hatch-100f2c1907ae^{commit}'], { cwd: root, encoding: 'utf8' }).trim(), STANDING_BASELINE, 'First-hatch immutable tag changed');
  assert.equal(sha256(git(STANDING_BASELINE, 'dist/OC.lua')), context.record.preservedMilestones[1].bundleSha256, 'First-hatch immutable bundle changed');
  console.log(`[OC] Standing approval PASS: exact two patches only inside ResolveStanding; ${count} other first-hatch production files and ${STANDING_HISTORY.length} historical records unchanged; one separately approved exact final adapter recheck; historical release pins preserved; publication remains safety-gated`);
  return context;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await verifyStandingWorkspace();

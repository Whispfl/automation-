import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { sha256 } from './verify-phase4-approved-membership.mjs';

// These pins independently bind the direct owner approval; mutable metadata
// cannot authorize a different patch or rewrite the original review/evidence.
export const FINAL_STANDING_BASELINE = '78b97d11f34e245f31e41ff6fac10cbd795f03da';
export const FINAL_STANDING_FILE = 'src/OCFoundation/GameMechanics.luau';
export const FINAL_STANDING_PATCH = 'docs/PHASE4-FINAL-STANDING-RECHECK-PROPOSED.patch';
export const FINAL_STANDING_PROPOSAL = 'docs/PHASE4-FINAL-STANDING-RECHECK-PROPOSED.json';
export const FINAL_STANDING_RECORD = 'docs/PHASE4-APPROVED-FINAL-STANDING-RECHECK.json';
export const FINAL_STANDING_PATCH_SHA256 = '1d5259f1d8e9593f616546eb345c5c6efd8c7064f025530b2682fbec156eec4d';
export const FINAL_STANDING_PROPOSAL_SHA256 = '3db37e03101ce77f777bee75f60f219bfdfe91fa377d21c1e034f68c08a9b219';
export const FINAL_STANDING_BEFORE_FILE_SHA256 = 'a2f1a3d6ab3483db3d91e9a50975e159a5107dbdf78a26e70f9765d5e1d19f87';
export const FINAL_STANDING_AFTER_FILE_SHA256 = 'd51154114e6309dd9042de250cbd8757ce1f61e146858960d7745397e14ab531';
export const FINAL_STANDING_BEFORE_METHOD_SHA256 = 'cb8f2973810e11daaaab948e3ae0303c0bbb3ce9bea9624b6ce57b4b9d542c7a';
export const FINAL_STANDING_AFTER_METHOD_SHA256 = 'e049e8c5c459c40502813312219bd2ca59b87be6a93fcf347297edd9b1396a6a';
export const FINAL_STANDING_TITLE = 'APPROVED — FINAL PHASE 4 MOVEMENT PATCH';
const text = value => Buffer.from(value).toString('utf8');

export function extractFinalStandingMethod(source) {
  const signature = 'function GameMechanics:PositionSelectedEgg(';
  assert.equal(source.split(signature).length - 1, 1, 'Final standing adapter must occur exactly once');
  const start = source.indexOf(signature), end = source.indexOf('\nfunction ', start + signature.length);
  assert(end > start, 'Final standing adapter boundary missing');
  // The approved proposal includes the separating newline before the next
  // declaration. Preserve that recorded hash convention exactly.
  return source.slice(start, end + 1);
}

export function applyApprovedFinalStandingPatch(before, patchBytes) {
  const source = text(before), patch = text(patchBytes);
  assert.equal(sha256(patchBytes), FINAL_STANDING_PATCH_SHA256, 'Exact approved final standing patch bytes changed');
  assert.equal(sha256(source), FINAL_STANDING_BEFORE_FILE_SHA256, 'Immutable final standing adapter preimage changed');
  assert.equal(sha256(extractFinalStandingMethod(source)), FINAL_STANDING_BEFORE_METHOD_SHA256, 'Immutable final standing method preimage changed');
  assert(patch.endsWith('\n') && !patch.includes('\r'), 'Exact final standing patch LF bytes changed');
  const lines = patch.slice(0, -1).split('\n');
  assert.deepEqual(lines.slice(0, 3), [`diff --git a/${FINAL_STANDING_FILE} b/${FINAL_STANDING_FILE}`, `--- a/${FINAL_STANDING_FILE}`, `+++ b/${FINAL_STANDING_FILE}`], 'Final standing target changed');
  assert.equal(lines[3], '@@ -828,6 +828,10 @@', 'Final standing hunk boundary changed');
  const original = source.split('\n'), hunk = lines.slice(4), start = 827;
  assert(hunk.every(line => [' ', '+'].includes(line[0])), 'Only four additions to one adapter hunk are approved');
  const removed = hunk.filter(line => line[0] !== '+').map(line => line.slice(1));
  const added = hunk.map(line => line.slice(1));
  assert.equal(removed.length, 6); assert.equal(added.length, 10);
  assert.deepEqual(original.slice(start, start + removed.length), removed, 'Exact final standing context changed');
  const after = [...original.slice(0, start), ...added, ...original.slice(start + removed.length)].join('\n');
  assert.equal(sha256(after), FINAL_STANDING_AFTER_FILE_SHA256, 'Exact final standing after-file hash changed');
  assert.equal(sha256(extractFinalStandingMethod(after)), FINAL_STANDING_AFTER_METHOD_SHA256, 'Exact final standing after-method hash changed');
  assert.equal(source.replace(extractFinalStandingMethod(source), '<ONLY_APPROVED_FINAL_STANDING_METHOD>'), after.replace(extractFinalStandingMethod(after), '<ONLY_APPROVED_FINAL_STANDING_METHOD>'), 'Source changed outside approved PositionSelectedEgg');
  return after;
}

export function expectedFinalStandingRecord(before, patch) {
  const after = applyApprovedFinalStandingPatch(before, patch);
  return {
    schemaVersion: 1, baseline: FINAL_STANDING_BASELINE,
    approval: { date: '2026-10-13', title: FINAL_STANDING_TITLE,
      source: 'Direct human owner message in the current Codex conversation.',
      quote: 'I approve implementation of the exact proposed patch: `docs/PHASE4-FINAL-STANDING-RECHECK-PROPOSED.patch` SHA256: `1d5259f1d8e9593f616546eb345c5c6efd8c7064f025530b2682fbec156eec4d`. This approval is limited to the proposed final standing recheck inside GameMechanics:PositionSelectedEgg.',
      scope: 'Exactly four added adapter lines after final destination validation: repeat existing complete standing checks; reject unavailable or different full CFrame; repeat pure cancellation/lease ownership/direct-positioning checks. Retain the original selected frame, ledger and single assignment.',
      exclusions: 'No destination selection, avatar calculation, native transition, scheduler, access/range, stable arrival, retry/recovery, hatch, equipment, inventory, spending or other protected-method changes.',
      publicationCondition: 'New immutable TRAVEL_ONLY ZERO-SPEND candidate only after official compilation, 684 baseline regressions, final safety gate, exact three-patch preservation and distribution checks pass; owner performs one movement-only live test.' },
    file: FINAL_STANDING_FILE, method: 'PositionSelectedEgg',
    beforeFileSha256: FINAL_STANDING_BEFORE_FILE_SHA256, afterFileSha256: FINAL_STANDING_AFTER_FILE_SHA256,
    beforeMethodSha256: FINAL_STANDING_BEFORE_METHOD_SHA256, afterMethodSha256: FINAL_STANDING_AFTER_METHOD_SHA256,
    beforeMethodText: extractFinalStandingMethod(text(before)), afterMethodText: extractFinalStandingMethod(after),
    patch: { path: FINAL_STANDING_PATCH, sha256: FINAL_STANDING_PATCH_SHA256, text: text(patch) },
    retainedProposal: { path: FINAL_STANDING_PROPOSAL, sha256: FINAL_STANDING_PROPOSAL_SHA256, status: 'Original unapproved proposal record retained unchanged; this separate record documents later direct owner approval.' },
    approvedDependencies: [
      { path: 'docs/PHASE4-UNIVERSAL-MOVEMENT-STANDING-PROPOSED.patch', sha256: 'b1131059a5b151fb699b04bbf1ae50365cbeddc9a6d2faa222d28edd42d3207f' },
      { path: 'docs/PHASE4-UNIVERSAL-MOVEMENT-FOOTPRINT-PROPOSED.patch', sha256: 'e812a4acdad9a75877dbaaa175db9fb4b5be948f8369c570366e20b6768d1c36' },
    ],
    preservedMilestones: [
      { commit: '25890f224f0448f148d009e65514c129aeb4f59c', buildId: '0d5caa499c8c', tag: 'phase4-travel-0d5caa499c8c', status: 'Historical Test A hashes remain unchanged; exact standing and adapter differences are separately approved.' },
      { commit: 'aae628d9ac8f1941f9b0b92aaedc365be22fa6af', buildId: '100f2c1907ae', tag: 'phase4-hatch-100f2c1907ae', bundleSha256: '14da5d26f543c0c1d3e9d51e946f21baafe78379502cc05e9954de864ef161e0', status: 'Owner-live first hatch bundle, received console text and archive remain immutable; manual final approach does not establish universal travel.' },
    ],
    actionPermissions: { AUTO_HATCH: false, OWNER_ONE_HATCH_TEST_ALLOWANCE: false, OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST: false, AUTO_EQUIP: false, spendingBudgets: 0, attempts: 1, retries: 0, policy: 'Owner-run movement-only test. No hatching, equipment, purchase, pickup, farming, bubbles or unrelated automatic actions.' },
    boundedContract: 'Reject changed/missing/insufficient support observed after potentially yielding final validation. No yielding validation/native helper remains between the final ResolveStanding return and the original CFrame assignment; exact CFrame comparison and pure local guards only.',
    nonAtomicLimit: 'Workspace queries and HRP assignment are not atomic. External geometry changes after the last possible observation, physics/replication and server correction remain possible; unchanged observed stable-arrival confirmation is required. No absolute guarantee or universal live movement claim.',
  };
}

export function verifyApprovedFinalStanding(before, after, patch, record) {
  assert.equal(text(after), applyApprovedFinalStandingPatch(before, patch), 'Unapproved final adapter change outside exact four-line patch');
  assert.deepEqual(record, expectedFinalStandingRecord(before, patch), 'Final standing approval record cannot broaden scope or rewrite historical proof');
  return record;
}

export async function finalStandingApprovalContext(root) {
  return { patch: await readFile(path.join(root, FINAL_STANDING_PATCH)), record: JSON.parse(await readFile(path.join(root, FINAL_STANDING_RECORD), 'utf8')) };
}

export async function verifyFinalStandingWorkspace() {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const git = file => execFileSync('git', ['show', `${FINAL_STANDING_BASELINE}:${file}`], { cwd: root, maxBuffer: 16 * 1024 * 1024 });
  const context = await finalStandingApprovalContext(root);
  verifyApprovedFinalStanding(git(FINAL_STANDING_FILE), await readFile(path.join(root, FINAL_STANDING_FILE)), context.patch, context.record);
  assert.equal(sha256(await readFile(path.join(root, FINAL_STANDING_PROPOSAL))), FINAL_STANDING_PROPOSAL_SHA256, 'Original final standing proposal metadata changed');
  assert.deepEqual(await readFile(path.join(root, FINAL_STANDING_RECORD)), Buffer.from(`${JSON.stringify(context.record, null, 2)}\n`), 'Final standing approval record serialization changed');
  for (const dependency of context.record.approvedDependencies) assert.equal(sha256(await readFile(path.join(root, dependency.path))), dependency.sha256, 'Required exact standing patch changed');
  const frozenNames = execFileSync('git', ['ls-tree', '-r', '--name-only', FINAL_STANDING_BASELINE, 'docs/research/replicatedstorage', 'docs/research/wiki'], { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(Boolean);
  async function files(directory) { const entries = await readdir(path.join(root, directory), { withFileTypes: true }); return (await Promise.all(entries.map(entry => entry.isDirectory() ? files(`${directory}/${entry.name}`) : [`${directory}/${entry.name}`]))).flat(); }
  const currentNames = [...await files('docs/research/replicatedstorage'), ...await files('docs/research/wiki')];
  assert.deepEqual(currentNames.sort(), frozenNames.sort(), 'Completed native/wiki research file set changed');
  for (const file of frozenNames) assert.deepEqual(await readFile(path.join(root, file)), git(file), `Completed research bytes changed: ${file}`);
  console.log(`[OC] Final standing approval PASS: exact four lines only inside PositionSelectedEgg; separate before/after hashes; both prior exact patches and ${frozenNames.length} completed native/wiki research files preserved; non-atomic Workspace limit acknowledged`);
  return context;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await verifyFinalStandingWorkspace();

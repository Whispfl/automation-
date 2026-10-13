import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Independent implementation pins for the current explicit owner diagnostic.
// These do not change or replace any historical approval or method hash.
export const OWNER_DIRECT_BASELINE = 'e939f07f7ae898f3491e089615da802d7a07b9e5';
export const OWNER_DIRECT_PATCH = 'docs/PHASE4-OWNER-DIRECT-EGG-TELEPORT-APPROVED.patch';
export const OWNER_DIRECT_RECORD = 'docs/PHASE4-OWNER-DIRECT-EGG-TELEPORT-APPROVAL.json';
export const OWNER_DIRECT_PATCH_SHA256 = '129a893e4cf0c23d0740004bb15d4160101b6dd6ade5323984c37e5d7a6df2c2';
export const OWNER_DIRECT_FILES = Object.freeze([
  Object.freeze({ file: 'src/OCFoundation/EggTravelManager.luau', beforeSha256: '15bd589ea9ff1e81354dbe536b347a2a852f59efa4780681234d82ee0540cf3b', afterSha256: '50255f5fe90a510d04d4959490efdde5fab5b91413504dba42b5118fbb7ec54e', hunks: 1 }),
  Object.freeze({ file: 'src/OCFoundation/GameMechanics.luau', beforeSha256: 'd51154114e6309dd9042de250cbd8757ce1f61e146858960d7745397e14ab531', afterSha256: 'de2cd62b5e42e44b13fab5a1502d25e79686e2e14eb8ca0ba16d6b58b5e0378a', hunks: 1 }),
  Object.freeze({ file: 'src/OCFoundation/OCConfig.luau', beforeSha256: '572779a5762093608b27a0517b8b3b544e28eb2ddf5ca44e8a6008871fe866cd', afterSha256: '25af644b4063743da3af29835ac2903d8aebf06fa42912d1cb296c1e3884a277', hunks: 1 }),
]);
export const OWNER_DIRECT_FROZEN_METHODS = Object.freeze([
  Object.freeze({ file: OWNER_DIRECT_FILES[0].file, signature: 'function EggTravelManager:ResolveStanding(', sha256: 'b00f2cf4bf49e91fc7cda952293c6b04c119b7809b0567bad24177ec28f32db6', trailingNewline: false }),
  Object.freeze({ file: OWNER_DIRECT_FILES[1].file, signature: 'function GameMechanics:PositionSelectedEgg(', sha256: 'e049e8c5c459c40502813312219bd2ca59b87be6a93fcf347297edd9b1396a6a', trailingNewline: true }),
]);
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sha = value => createHash('sha256').update(value).digest('hex');
const text = value => Buffer.from(value).toString('utf8');
const get = (files, file) => { const value = files instanceof Map ? files.get(file) : files[file]; assert(value !== undefined, `Missing owner diagnostic source: ${file}`); return text(value); };
const git = file => execFileSync('git', ['show', `${OWNER_DIRECT_BASELINE}:${file}`], { cwd: root, maxBuffer: 16 * 1024 * 1024 });

export function extractOwnerDirectMethod(source, signature, trailingNewline = false) {
  assert.equal(source.split(signature).length - 1, 1, `Diagnostic preservation method must occur once: ${signature}`);
  const start = source.indexOf(signature), next = source.indexOf('\nfunction ', start + signature.length);
  const returned = source.indexOf('\nreturn ', start + signature.length);
  const end = next < 0 ? returned : returned < 0 ? next : Math.min(next, returned);
  assert(end > start, `Diagnostic preservation method boundary missing: ${signature}`);
  return source.slice(start, end + (trailingNewline ? 1 : 0));
}

export function applyApprovedOwnerDirectPatch(beforeFiles, patchBytes) {
  assert.equal(sha(patchBytes), OWNER_DIRECT_PATCH_SHA256, 'Exact owner direct diagnostic implementation patch changed');
  const patch = text(patchBytes);
  assert(patch.endsWith('\n') && !patch.includes('\r'), 'Owner diagnostic exact patch LF bytes changed');
  const sections = patch.split(/(?=^diff --git )/m).filter(Boolean);
  assert.equal(sections.length, OWNER_DIRECT_FILES.length, 'Only three owner diagnostic source files are permitted');
  const afterFiles = new Map();
  for (const [index, section] of sections.entries()) {
    const check = OWNER_DIRECT_FILES[index], before = get(beforeFiles, check.file);
    assert.equal(sha(before), check.beforeSha256, `Owner diagnostic immutable preimage changed: ${check.file}`);
    const lines = section.slice(0, -1).split('\n');
    assert.equal(lines[0], `diff --git a/${check.file} b/${check.file}`, 'Owner diagnostic patch target/order changed');
    assert(/^index [0-9a-f]+\.\.[0-9a-f]+ 100644$/.test(lines[1]), 'Owner diagnostic patch index line changed');
    assert.deepEqual(lines.slice(2, 4), [`--- a/${check.file}`, `+++ b/${check.file}`], 'Owner diagnostic patch target changed');
    const original = before.split('\n'), result = [];
    let cursor = 0, lineIndex = 4, hunks = 0;
    while (lineIndex < lines.length) {
      const header = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(?:.*)$/.exec(lines[lineIndex++]);
      assert(header, 'Unexpected owner diagnostic patch hunk');
      const oldStart = Number(header[1]) - 1, oldCount = Number(header[2] ?? 1), newStart = Number(header[3]) - 1, newCount = Number(header[4] ?? 1);
      assert(oldStart >= cursor, 'Owner diagnostic patch hunks overlap');
      result.push(...original.slice(cursor, oldStart)); cursor = oldStart;
      assert.equal(result.length, newStart, 'Owner diagnostic patch line position inconsistent');
      let removed = 0, added = 0;
      while (lineIndex < lines.length && !lines[lineIndex].startsWith('@@ ')) {
        const line = lines[lineIndex++], op = line[0], content = line.slice(1);
        assert([' ', '+'].includes(op), 'Owner diagnostic patch may add only; frozen source lines cannot be replaced');
        if (op !== '+') { assert.equal(original[cursor], content, 'Owner diagnostic exact context mismatch'); cursor += 1; removed += 1; }
        result.push(content); added += 1;
      }
      assert.equal(removed, oldCount, 'Owner diagnostic patch old count changed');
      assert.equal(added, newCount, 'Owner diagnostic patch new count changed'); hunks += 1;
    }
    assert.equal(hunks, check.hunks, 'Owner diagnostic patch hunk count changed');
    result.push(...original.slice(cursor));
    const after = result.join('\n');
    assert.equal(sha(after), check.afterSha256, `Owner diagnostic exact after-source changed: ${check.file}`);
    afterFiles.set(check.file, after);
  }
  for (const check of OWNER_DIRECT_FROZEN_METHODS) {
    const beforeMethod = extractOwnerDirectMethod(get(beforeFiles, check.file), check.signature, check.trailingNewline);
    const afterMethod = extractOwnerDirectMethod(get(afterFiles, check.file), check.signature, check.trailingNewline);
    assert.equal(sha(beforeMethod), check.sha256, `Published protected method pin changed: ${check.signature}`);
    assert.equal(afterMethod, beforeMethod, `Owner diagnostic changed frozen protected method: ${check.signature}`);
  }
  return afterFiles;
}

export function expectedOwnerDirectRecord(beforeFiles, patch) {
  const afterFiles = applyApprovedOwnerDirectPatch(beforeFiles, patch);
  const execute = 'function EggTravelManager:Execute(', helper = 'function GameMechanics:ExecuteOwnerDirectEggTeleportTest(';
  return {
    schemaVersion: 1, baseline: OWNER_DIRECT_BASELINE,
    approval: { date: '2026-10-13', title: 'OC PHASE 4 — OWNER APPROVES DIRECT EGG TELEPORT TEST',
      source: 'Direct explicit human owner message in the current Codex conversation.',
      quote: 'I explicitly authorize a narrowly scoped direct-positioning experiment on my own Roblox account.',
      scope: 'False-by-default OWNER_DIRECT_EGG_TELEPORT_TEST; only account 10864747620, exact verified loaded physical Common Egg Instance in The Overworld, one direct physical Root CFrame setter, no retries. This isolated experiment bypasses standing search, footprint and clearance only; native identity, access, account, cancellation, lease, scheduler and presentation checks remain.',
      sourceChanges: 'One commented Config flag, three-line Execute diagnostic dispatch and one separate appended mechanics diagnostic; existing ResolveStanding and PositionSelectedEgg are byte-for-byte frozen.',
      exclusions: 'No hatching, equipment, spending, purchases, pickups, farming, bubbles, native transitions, automatic retries, snap-back, walking, ordinary movement changes or competing scheduler.',
      uncertainty: 'Overlap, falling, Roblox physics and external corrections are accepted experiment risks, not guaranteed behavior. Arrival and native interaction range require actual observation; the existing physical diagnostic radius alone is not proof of native eligibility.' },
    patch: { path: OWNER_DIRECT_PATCH, sha256: OWNER_DIRECT_PATCH_SHA256, provenance: 'Exact implemented source delta recorded after the direct behavioral approval; not an earlier owner-reviewed hash.', text: text(patch) },
    files: OWNER_DIRECT_FILES,
    frozenMethods: OWNER_DIRECT_FROZEN_METHODS.map(check => ({ ...check, beforeText: extractOwnerDirectMethod(get(beforeFiles, check.file), check.signature, check.trailingNewline), afterText: extractOwnerDirectMethod(get(afterFiles, check.file), check.signature, check.trailingNewline) })),
    dispatch: { file: OWNER_DIRECT_FILES[0].file, signature: execute, beforeSha256: sha(extractOwnerDirectMethod(get(beforeFiles, OWNER_DIRECT_FILES[0].file), execute)), afterSha256: sha(extractOwnerDirectMethod(get(afterFiles, OWNER_DIRECT_FILES[0].file), execute)) },
    diagnostic: { file: OWNER_DIRECT_FILES[1].file, signature: helper, afterSha256: sha(extractOwnerDirectMethod(get(afterFiles, OWNER_DIRECT_FILES[1].file), helper)) },
    defaults: { OWNER_DIRECT_EGG_TELEPORT_TEST: false, AUTO_HATCH: false, AUTO_EQUIP: false, OWNER_ONE_HATCH_TEST_ALLOWANCE: false, OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST: false, AUTHORIZED_ACCOUNT_ID: 0, spendingBudgets: 0 },
    enabledTest: { accountId: 10864747620, egg: 'Common Egg', world: 'The Overworld', mode: 'TRAVEL_ONLY', assignmentLimit: 1, retries: 0, nativeHatchRequests: 0, equipmentCommands: 0, spending: 0 },
    preservation: { previousCandidateCommit: OWNER_DIRECT_BASELINE, previousCandidateTag: 'phase4-travel-fec9bed3bd3f', historicalTestACommit: '25890f224f0448f148d009e65514c129aeb4f59c', historicalTestATag: 'phase4-travel-0d5caa499c8c', firstHatchCommit: 'aae628d9ac8f1941f9b0b92aaedc365be22fa6af', firstHatchTag: 'phase4-hatch-100f2c1907ae', policy: 'Historical records, exact patches, tags, bundles and owner evidence remain immutable; this separate diagnostic record does not relabel changed whole files as historically identical.' },
  };
}

export function verifyApprovedOwnerDirect(beforeFiles, afterFiles, patch, record) {
  const expected = applyApprovedOwnerDirectPatch(beforeFiles, patch);
  for (const check of OWNER_DIRECT_FILES) assert.equal(get(afterFiles, check.file), expected.get(check.file), `Unapproved owner diagnostic source delta: ${check.file}`);
  assert.deepEqual(record, expectedOwnerDirectRecord(beforeFiles, patch), 'Owner diagnostic approval record cannot broaden source/scope/history');
  return record;
}

// Historical validators still validate their original exact transforms. This
// projection accepts only the independently pinned current diagnostic files and
// returns the exact published preimages; it cannot hide an arbitrary edit.
export function stripApprovedOwnerDirectDelta(file, source) {
  const check = OWNER_DIRECT_FILES.find(value => value.file === file);
  if (!check) return source;
  assert.equal(sha(source), check.afterSha256, `Unapproved owner diagnostic source delta: ${file}`);
  const before = git(file);
  assert.equal(sha(before), check.beforeSha256, `Owner diagnostic immutable baseline changed: ${file}`);
  return typeof source === 'string' ? before.toString('utf8') : before;
}

export function stripApprovedOwnerDirectFiles(files) {
  return new Map([...files].map(([file, bytes]) => [file, stripApprovedOwnerDirectDelta(file, bytes)]));
}

export function verifyOwnerDirectProtectedFiles(beforeFiles, afterFiles) {
  assert.deepEqual([...afterFiles.keys()].sort(), [...beforeFiles.keys()].sort(), 'Owner diagnostic cannot change the production file set');
  let unchanged = 0;
  for (const [file, before] of beforeFiles) {
    const check = OWNER_DIRECT_FILES.find(value => value.file === file);
    if (check) {
      assert.equal(sha(before), check.beforeSha256, `Owner diagnostic immutable baseline changed: ${file}`);
      assert.equal(sha(get(afterFiles, file)), check.afterSha256, `Unapproved owner diagnostic source delta: ${file}`);
    } else {
      assert.deepEqual(Buffer.from(get(afterFiles, file)), Buffer.from(before), `Unapproved production edit outside owner diagnostic: ${file}`);
      unchanged += 1;
    }
  }
  return unchanged;
}

export async function verifyOwnerDirectWorkspace() {
  const names = execFileSync('git', ['ls-tree', '-r', '--name-only', OWNER_DIRECT_BASELINE, 'src'], { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(file => file.endsWith('.luau'));
  async function files(directory) { const entries = await readdir(path.join(root, directory), { withFileTypes: true }); return (await Promise.all(entries.map(entry => entry.isDirectory() ? files(`${directory}/${entry.name}`) : entry.name.endsWith('.luau') ? [`${directory}/${entry.name}`] : []))).flat(); }
  const currentNames = await files('src'); assert.deepEqual(currentNames.sort(), [...names].sort(), 'Owner diagnostic cannot change the production file set');
  const before = new Map(names.map(file => [file, git(file)])), after = new Map(await Promise.all(names.map(async file => [file, await readFile(path.join(root, file))])));
  const patch = await readFile(path.join(root, OWNER_DIRECT_PATCH)), recordBytes = await readFile(path.join(root, OWNER_DIRECT_RECORD));
  const record = verifyApprovedOwnerDirect(before, after, patch, JSON.parse(recordBytes.toString('utf8')));
  assert.deepEqual(recordBytes, Buffer.from(`${JSON.stringify(record, null, 2)}\n`), 'Owner diagnostic approval serialization changed');
  const unchanged = verifyOwnerDirectProtectedFiles(before, after);
  const history = execFileSync('git', ['ls-tree', '-r', '--name-only', OWNER_DIRECT_BASELINE, 'docs'], { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(file => /(?:APPROVED|APPROVAL|PROPOSED|PRESERVATION|FIRST-LIVE-HATCH)/.test(file));
  for (const file of history) assert.deepEqual(await readFile(path.join(root, file)), git(file), `Historical approval/evidence changed: ${file}`);
  for (const [tag, commit] of [['phase4-travel-fec9bed3bd3f', OWNER_DIRECT_BASELINE], ['phase4-travel-0d5caa499c8c', record.preservation.historicalTestACommit], ['phase4-hatch-100f2c1907ae', record.preservation.firstHatchCommit]]) {
    assert.equal(execFileSync('git', ['rev-parse', `${tag}^{commit}`], { cwd: root, encoding: 'utf8' }).trim(), commit, `Immutable release tag changed: ${tag}`);
  }
  console.log(`[OC] Owner direct diagnostic preservation PASS: exact three-file additions; both protected movement methods frozen; ${unchanged} other source files and ${history.length} historical approval/evidence files unchanged; previous/Test A/first-hatch release pins preserved`);
  return record;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await verifyOwnerDirectWorkspace();

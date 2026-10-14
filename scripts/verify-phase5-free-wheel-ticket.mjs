import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { stripWheelSpinDelta, stripWheelSpinFiles } from './verify-phase5-wheel-spin.mjs';

const root = path.resolve(import.meta.dirname, '..');
export const FREE_WHEEL_BASELINE = '701eafb1c2cfaaa73237235d0c255b59b2a3ef52';
export const FREE_WHEEL_PATCH = 'docs/PHASE5-FREE-WHEEL-PROTECTED-PROPOSAL.patch';
export const FREE_WHEEL_PATCH_SHA256 = '6b08aa9cc1bac60acd12310eb74728dfe1d50b65ee75d69ec31768d8a93cbc2c';
export const FREE_WHEEL_RECORD = 'docs/PHASE5-FREE-WHEEL-SOURCE-PRESERVATION.json';
export const FREE_WHEEL_FILES = Object.freeze([
  'src/OCFoundation/RewardsManager.luau',
  'src/OCFoundation/GameMechanics.luau',
  'src/OCFoundation/GameKnowledge.luau',
  'src/OCFoundation/OCConfig.luau',
]);
const beginMarker = '-- PHASE5_FREE_WHEEL_TICKET_BEGIN';
const endMarker = '-- PHASE5_FREE_WHEEL_TICKET_END';
const sha = value => createHash('sha256').update(value).digest('hex');
const git = file => execFileSync('git', ['show', `${FREE_WHEEL_BASELINE}:${file}`], { cwd: root, maxBuffer: 16 * 1024 * 1024 });
const gitNames = directory => execFileSync('git', ['ls-tree', '-r', '--name-only', FREE_WHEEL_BASELINE, directory], { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(Boolean);
const diskNames = directory => readdirSync(path.join(root, directory), { withFileTypes: true }).flatMap(entry => entry.isDirectory()
  ? diskNames(`${directory}/${entry.name}`) : entry.name.endsWith('.luau') ? [`${directory}/${entry.name}`] : []);
const metadata = () => JSON.parse(readFileSync(path.join(root, FREE_WHEEL_RECORD), 'utf8'));

// This module is deliberately independent of the historical Phase 5 verifiers.
// Reproduce the approved patch from its pinned bytes; never reset source to Git.
function approvedPatch() {
  const bytes = readFileSync(path.join(root, FREE_WHEEL_PATCH));
  assert.equal(sha(bytes), FREE_WHEEL_PATCH_SHA256, 'The owner-approved four-hook patch changed');
  const proposal = JSON.parse(readFileSync(path.join(root, 'docs/PHASE5-FREE-WHEEL-PROTECTED-PROPOSAL.json'), 'utf8'));
  assert.equal(proposal.baselineCommit, FREE_WHEEL_BASELINE);
  assert.equal(proposal.patchSha256, FREE_WHEEL_PATCH_SHA256);
  const hunks = new Map();
  let file, hunk;
  for (const line of bytes.toString('utf8').replace(/\r\n/g, '\n').split('\n')) {
    if (line.startsWith('diff --git ')) { file = undefined; hunk = undefined; }
    else if (line.startsWith('+++ b/')) { file = line.slice(6); hunks.set(file, []); }
    else if (line.startsWith('@@ ')) { assert(file, 'Patch hunk has no file'); hunk = []; hunks.get(file).push(hunk); }
    else if (hunk && /^[ +\-]/.test(line)) hunk.push(line);
    else if (line.startsWith('\\ No newline')) throw new Error('Unsupported no-newline patch hunk');
  }
  assert.deepEqual([...hunks.keys()].sort(), ['src/OCFoundation/GameMechanics.luau', 'src/OCFoundation/RewardsManager.luau']);
  return { hunks, proposal };
}

function applyHooks(source, file, reverse = false) {
  const { hunks } = approvedPatch();
  const eol = source.includes('\r\n') ? '\r\n' : '\n';
  for (const lines of reverse ? [...(hunks.get(file) || [])].reverse() : hunks.get(file) || []) {
    const old = lines.filter(line => line[0] !== (reverse ? '-' : '+')).map(line => line.slice(1)).join(eol) + eol;
    const replacement = lines.filter(line => line[0] !== (reverse ? '+' : '-')).map(line => line.slice(1)).join(eol) + eol;
    const start = source.indexOf(old);
    assert(start >= 0 && source.indexOf(old, start + old.length) < 0, `Approved hook hunk is absent or ambiguous: ${file}`);
    source = source.slice(0, start) + replacement + source.slice(start + old.length);
  }
  return source;
}

function removeAddition(file, bytes) {
  const text = Buffer.from(bytes).toString('utf8');
  const begin = text.indexOf(beginMarker), end = text.indexOf(endMarker);
  assert(begin >= 0 && end > begin && text.indexOf(beginMarker, begin + beginMarker.length) < 0
    && text.indexOf(endMarker, end + endMarker.length) < 0, `Missing or duplicated free-wheel addition boundaries: ${file}`);
  const start = text.lastIndexOf('\n', begin) + 1;
  assert(/^\s*$/.test(text.slice(start, begin)), `Unexpected text before free-wheel BEGIN marker: ${file}`);
  const afterMarker = end + endMarker.length;
  assert(text.slice(afterMarker).startsWith('\n') || text.slice(afterMarker).startsWith('\r\n'), `Free-wheel END must have its own complete line: ${file}`);
  const after = afterMarker + (text.slice(afterMarker).startsWith('\r\n') ? 2 : 1);
  return { projected: Buffer.from(text.slice(0, start) + text.slice(after)), addition: Buffer.from(text.slice(start, after)) };
}

function checkRecord(record) {
  assert.equal(record.status, 'FINALIZED_FOR_OFFLINE_VERIFICATION', 'Free-wheel source preservation record is not finalized');
  assert.equal(record.baselineCommit, FREE_WHEEL_BASELINE);
  assert.equal(record.approvedPatchSha256, FREE_WHEEL_PATCH_SHA256);
  assert.deepEqual(record.changed.map(entry => entry.file).sort(), [...FREE_WHEEL_FILES].sort());
  approvedPatch();
}

export function stripFreeWheelTicketDelta(file, bytes) {
  bytes = stripWheelSpinDelta(file, bytes);
  const data = Buffer.from(bytes);
  // Baseline consumers retain their exact prior behavior, including no new record dependency.
  if (!data.includes(Buffer.from(beginMarker))) return bytes;
  assert(FREE_WHEEL_FILES.includes(file), `Unapproved source addition file: ${file}`);
  const record = metadata(); checkRecord(record);
  const entry = record.changed.find(value => value.file === file);
  assert.equal(sha(data), entry.afterSha256, `Unrecorded free-wheel source change: ${file}`);
  const { projected, addition } = removeAddition(file, data);
  assert.equal(sha(addition), entry.additionSha256, `Free-wheel appended block changed: ${file}`);
  assert.equal(sha(projected), entry.approvedHooksSha256, `Free-wheel changed an unapproved existing method: ${file}`);
  const restored = Buffer.from(applyHooks(projected.toString('utf8'), file, true));
  const before = git(file);
  assert(restored.equals(before), `Free-wheel projection does not reproduce the protected baseline: ${file}`);
  assert.equal(sha(before), entry.beforeSha256, `Free-wheel immutable baseline hash changed: ${file}`);
  return typeof bytes === 'string' ? restored.toString('utf8') : restored;
}

export function stripFreeWheelTicketFiles(files) {
  return new Map([...stripWheelSpinFiles(files)].map(([file, bytes]) => [file, stripFreeWheelTicketDelta(file, bytes)]));
}

const historicalNames = () => [...new Set([
  ...gitNames('docs').filter(file => file.startsWith('docs/research/') || file.startsWith('docs/verification/')
    || file.startsWith('docs/local-feature-studio-evidence/') || /^docs\/PHASE[45](?:[-.])/.test(file)
    || /^docs\/LOCAL_FEATURES(?:[-_.])/.test(file)),
  ...gitNames('examples'), ...gitNames('tests'),
])].sort();

export function recordFreeWheelTicketWorkspace() {
  const { proposal } = approvedPatch();
  const expected = gitNames('src').filter(file => file.endsWith('.luau'));
  const current = diskNames('src');
  assert.deepEqual([...current].sort(), [...expected].sort(), 'Free-wheel scope adds no production module or entry point');
  const changed = [];
  for (const file of current) {
    const before = git(file), after = readFileSync(path.join(root, file));
    if (!FREE_WHEEL_FILES.includes(file)) { assert(after.equals(before), `Unapproved production change: ${file}`); continue; }
    const { projected, addition } = removeAddition(file, after);
    const approved = Buffer.from(applyHooks(before.toString('utf8'), file));
    assert(projected.equals(approved), `Existing methods differ from exactly the approved hooks: ${file}`);
    const hookRecord = proposal.existingFiles.find(entry => entry.file === file);
    if (hookRecord) {
      assert.equal(sha(before), hookRecord.beforeSha256);
      assert.equal(sha(approved), hookRecord.proposedSha256);
    }
    changed.push({ file, beforeSha256: sha(before), approvedHooksSha256: sha(approved), afterSha256: sha(after), additionSha256: sha(addition) });
  }
  const frozenFiles = historicalNames().map(file => {
    const before = git(file);
    assert(readFileSync(path.join(root, file)).equals(before), `Historical evidence, loader or fixture changed: ${file}`);
    return { file, sha256: sha(before) };
  });
  const releasePins = execFileSync('git', ['for-each-ref', '--format=%(refname:short) %(objectname)', 'refs/tags'], { cwd: root, encoding: 'utf8' })
    .trim().split('\n').filter(Boolean).map(line => {
      const [tag] = line.split(' ');
      const commit = execFileSync('git', ['rev-parse', `${tag}^{commit}`], { cwd: root, encoding: 'utf8' }).trim();
      return { tag, commit };
    });
  assert(releasePins.some(pin => pin.tag === 'phase5-rewards-7d374c2879a3' && pin.commit === FREE_WHEEL_BASELINE), 'Published reward intelligence milestone must remain immutable');
  const record = {
    status: 'FINALIZED_FOR_OFFLINE_VERIFICATION',
    scope: 'Owner-approved exact four existing-method hooks plus separate free-wheel helpers/config; ClaimFreeWheelSpin only, disabled candidate, no live action authorization',
    baselineCommit: FREE_WHEEL_BASELINE,
    approvedPatch: FREE_WHEEL_PATCH,
    approvedPatchSha256: FREE_WHEEL_PATCH_SHA256,
    changed: changed.sort((a, b) => a.file.localeCompare(b.file)),
    existingMethods: proposal.existingFiles.flatMap(entry => entry.changedMethods.map(method => ({ file: entry.file, ...method }))),
    projection: 'Verify exact final file/block hashes; remove only the unique FREE_WHEEL_TICKET blocks; reproduce exactly the approved patch; reverse only those pinned patch hunks; reproduce every 701eafb production byte before the original historical preservation checks.',
    frozenFiles, releasePins,
    acceptance: 'Offline source preservation only; owner live eligibility, dispatch and receipt acceptance remain unverified. No claimed server grant quantity is inferred from a spin-cost descriptor.',
  };
  writeFileSync(path.join(root, FREE_WHEEL_RECORD), JSON.stringify(record, null, 2) + '\n');
  return record;
}

export function verifyFreeWheelTicketWorkspace() {
  const record = metadata(); checkRecord(record);
  const expected = gitNames('src').filter(file => file.endsWith('.luau'));
  const current = stripWheelSpinFiles(new Map(diskNames('src').map(file => [file, readFileSync(path.join(root, file))])));
  assert.deepEqual([...current.keys()].sort(), [...expected].sort(), 'Free-wheel scope adds no production module or entry point');
  for (const file of FREE_WHEEL_FILES) assert(current.get(file)?.includes(Buffer.from(beginMarker)), `Free-wheel addition missing: ${file}`);
  const projected = stripFreeWheelTicketFiles(current);
  for (const [file, bytes] of projected) assert(Buffer.from(bytes).equals(git(file)), `Protected production bytes changed: ${file}`);
  assert.deepEqual(record.frozenFiles.map(entry => entry.file), historicalNames(), 'Historical evidence coverage changed');
  for (const entry of record.frozenFiles) {
    assert.equal(sha(git(entry.file)), entry.sha256, `Historical evidence baseline hash changed: ${entry.file}`);
    assert.equal(sha(readFileSync(path.join(root, entry.file))), entry.sha256, `Historical evidence, loader or fixture changed: ${entry.file}`);
  }
  for (const pin of record.releasePins) assert.equal(execFileSync('git', ['rev-parse', `${pin.tag}^{commit}`], { cwd: root, encoding: 'utf8' }).trim(), pin.commit, `Immutable milestone moved: ${pin.tag}`);
  console.log(`[OC] Free-wheel preservation PASS: exact four approved method hooks, four appended blocks, ${record.frozenFiles.length} historical files and ${record.releasePins.length} immutable milestones retained`);
  return record;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv.includes('--record')) recordFreeWheelTicketWorkspace();
  else verifyFreeWheelTicketWorkspace();
}

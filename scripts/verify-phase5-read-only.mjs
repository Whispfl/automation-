import assert from 'node:assert/strict';
import {readFileSync, readdirSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {stripRewardDelta,stripRewardFiles,verifyRewardWorkspace} from './verify-phase5-rewards.mjs';

const root = path.resolve(import.meta.dirname, '..');
export const PHASE5_BASELINE = 'f0efe911c8958118ae4084f88be376c647d21e33';
const recordPath = 'docs/PHASE5-READ-ONLY-SOURCE-PRESERVATION.json';
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const git = file => execFileSync('git', ['show', `${PHASE5_BASELINE}:${file}`], {cwd:root,maxBuffer:8*1024*1024});
const record = () => JSON.parse(readFileSync(path.join(root,recordPath),'utf8'));
const changed = ['src/OCFoundation/OCConfig.luau','src/OCFoundation/OCBrain.luau','src/OCFoundation/OCController.luau','src/OCFoundation/GameKnowledge.luau'];
const addition = 'src/OCFoundation/MasteryPolicy.luau';

export function stripPhase5Delta(file, bytes) {
  bytes = stripRewardDelta(file, bytes);
  const data = Buffer.from(bytes);
  if (!changed.includes(file) || !data.includes(Buffer.from('-- PHASE5_READ_ONLY_MASTERY_BEGIN'))) return bytes;
  const before = git(file);
  if (data.equals(before)) return bytes;
  const entry = record().changed.find(value=>value.file===file);
  assert(entry && sha(data)===entry.afterSha256, `Unrecorded Phase 5 delta: ${file}`);
  const text = data.toString('utf8');
  const begin = text.indexOf('-- PHASE5_READ_ONLY_MASTERY_BEGIN');
  const endMarker = '-- PHASE5_READ_ONLY_MASTERY_END';
  const end = text.indexOf(endMarker);
  assert(begin>=0 && end>begin && text.indexOf(endMarker,end+endMarker.length)<0, `Nonunique Phase 5 boundaries: ${file}`);
  // Include indentation and exactly one following newline, preserving original bytes.
  const start = text.lastIndexOf('\n',begin)+1;
  const after = end+endMarker.length+(text.slice(end+endMarker.length).startsWith('\r\n')?2:1);
  const projected = Buffer.from(text.slice(0,start)+text.slice(after));
  assert.deepEqual(projected,before, `Phase 5 changed an existing method or interface: ${file}`);
  assert.equal(sha(before),entry.beforeSha256,`Immutable Phase 5 baseline hash: ${file}`);
  return typeof bytes==='string'?projected.toString('utf8'):projected;
}

export function stripPhase5Files(files) {
  const result = new Map();
  for (const [file,bytes] of stripRewardFiles(files)) {
    if (file===addition) {
      assert.equal(sha(bytes),record().addition.sha256,'Unrecorded MasteryPolicy source');
      continue;
    }
    result.set(file,stripPhase5Delta(file,bytes));
  }
  return result;
}

function names(directory) {
  return readdirSync(path.join(root,directory),{withFileTypes:true}).flatMap(entry=>entry.isDirectory()?names(`${directory}/${entry.name}`):entry.name.endsWith('.luau')?[`${directory}/${entry.name}`]:[]);
}

export function verifyPhase5Workspace() {
  verifyRewardWorkspace();
  const metadata=record();
  assert.equal(metadata.baselineCommit,PHASE5_BASELINE);
  assert.deepEqual(metadata.changed.map(value=>value.file).sort(),[...changed].sort());
  assert.equal(metadata.addition.file,addition);
  const expected=execFileSync('git',['ls-tree','-r','--name-only',PHASE5_BASELINE,'src'],{cwd:root,encoding:'utf8'}).trim().split('\n').filter(file=>file.endsWith('.luau'));
  const current=new Map(names('src').map(file=>[file,readFileSync(path.join(root,file))]));
  const projected=stripPhase5Files(current);
  assert.deepEqual([...projected.keys()].sort(),expected.sort(),'Only the one read-only module may expand production files');
  for(const [file,bytes] of projected) assert.deepEqual(bytes,git(file),`Protected production bytes changed: ${file}`);
  const policy=current.get(addition).toString('utf8');
  assert(!/FireServer|InvokeServer|HatchEgg|UpgradeMastery|CFrame\s*=|Scheduler:Submit|task\.(?:spawn|defer|delay|wait)|:Collect\s*\(|:Claim\s*\(/.test(policy),'Read-only policy cannot contain action transport or automation');
  for(const pin of metadata.releasePins) assert.equal(execFileSync('git',['rev-parse',`${pin.tag}^{commit}`],{cwd:root,encoding:'utf8'}).trim(),pin.commit,`Historical release moved: ${pin.tag}`);
  console.log(`[OC] Phase 5 preservation PASS: one pure module, four exact append-only additions; all existing production bytes and ${metadata.releasePins.length} immutable milestones retained`);
  return metadata;
}
if(process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) verifyPhase5Workspace();

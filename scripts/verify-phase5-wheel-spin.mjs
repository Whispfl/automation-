// Exact current-source projection; historical records and release pins are immutable.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {readFileSync, readdirSync, writeFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.resolve(import.meta.dirname, '..');
export const WHEEL_SPIN_BASELINE = '918f8a58096c59f592fe94fd0d71fe5487f423d8';
export const WHEEL_SPIN_PATCH = 'docs/PHASE5-WHEEL-SPIN-PROTECTED-PROPOSED.patch';
export const WHEEL_SPIN_PATCH_SHA256 = '06382c6dbbe8191aea636bba4c8a80a73785f9caf4b640443e5646f51448b3d1';
export const WHEEL_SPIN_RECORD = 'docs/PHASE5-WHEEL-SPIN-SOURCE-PRESERVATION.json';
export const WHEEL_SPIN_FILES = Object.freeze([
  'src/OCFoundation/OCConfig.luau', 'src/OCFoundation/GameKnowledge.luau',
  'src/OCFoundation/GameMechanics.luau', 'src/OCFoundation/RewardsManager.luau',
]);
const policy = 'src/OCFoundation/WheelSpinPolicy.luau';
const beginMarker = '-- PHASE5_ONE_WHEEL_SPIN_BEGIN';
const endMarker = '-- PHASE5_ONE_WHEEL_SPIN_END';
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const git = (...args) => execFileSync('git', args, {cwd:root,maxBuffer:32*1024*1024});
const baselineCache = new Map();
const before = file => {
  if(!baselineCache.has(file))baselineCache.set(file,git('show', `${WHEEL_SPIN_BASELINE}:${file}`));
  return baselineCache.get(file);
};
const baselineNames = directory => git('ls-tree','-r','--name-only',WHEEL_SPIN_BASELINE,directory).toString().trim().split('\n').filter(Boolean);
const diskNames = directory => readdirSync(path.join(root,directory),{withFileTypes:true}).flatMap(entry => entry.isDirectory()
  ? diskNames(`${directory}/${entry.name}`) : entry.name.endsWith('.luau') ? [`${directory}/${entry.name}`] : []);
const metadata = () => JSON.parse(readFileSync(path.join(root,WHEEL_SPIN_RECORD),'utf8'));

function approvedPatch() {
  const bytes = readFileSync(path.join(root,WHEEL_SPIN_PATCH));
  assert.equal(sha(bytes),WHEEL_SPIN_PATCH_SHA256,'The owner-approved five-hook patch changed');
  const proposal = JSON.parse(readFileSync(path.join(root,'docs/PHASE5-WHEEL-SPIN-PROTECTED-PROPOSED.json'),'utf8'));
  assert.equal(proposal.baselineCommit,WHEEL_SPIN_BASELINE);
  assert.equal(proposal.patchSha256,WHEEL_SPIN_PATCH_SHA256);
  assert.equal(proposal.validation.changedExistingMethods,5);
  const hunks = new Map(); let file,hunk;
  for(const line of bytes.toString('utf8').replace(/\r\n/g,'\n').split('\n')) {
    if(line.startsWith('diff --git ')){file=undefined;hunk=undefined;}
    else if(line.startsWith('+++ b/')){file=line.slice(6);hunks.set(file,[]);}
    else if(line.startsWith('@@ ')){assert(file);hunk=[];hunks.get(file).push(hunk);}
    else if(hunk && /^[ +\-]/.test(line))hunk.push(line);
    else if(line.startsWith('\\ No newline'))throw new Error('Unsupported no-newline approved hunk');
  }
  assert.deepEqual([...hunks.keys()].sort(),['src/OCFoundation/GameMechanics.luau','src/OCFoundation/RewardsManager.luau']);
  return {hunks,proposal};
}

function applyHooks(source,file,reverse=false) {
  const {hunks}=approvedPatch();
  const eol=source.includes('\r\n')?'\r\n':'\n';
  for(const lines of reverse ? [...(hunks.get(file)||[])].reverse() : hunks.get(file)||[]) {
    const old=lines.filter(line=>line[0] !== (reverse?'-':'+')).map(line=>line.slice(1)).join(eol)+eol;
    const replacement=lines.filter(line=>line[0] !== (reverse?'+':'-')).map(line=>line.slice(1)).join(eol)+eol;
    const start=source.indexOf(old);
    assert(start>=0 && source.indexOf(old,start+old.length)<0,`Approved spin hook is absent or ambiguous: ${file}`);
    source=source.slice(0,start)+replacement+source.slice(start+old.length);
  }
  return source;
}

function removeAddition(file,bytes) {
  const text=Buffer.from(bytes).toString('utf8');
  const begin=text.indexOf(beginMarker),end=text.indexOf(endMarker);
  assert(begin>=0 && end>begin && text.indexOf(beginMarker,begin+beginMarker.length)<0
    && text.indexOf(endMarker,end+endMarker.length)<0,`Missing or duplicate spin addition boundaries: ${file}`);
  const start=text.lastIndexOf('\n',begin)+1;
  assert(/^\s*$/.test(text.slice(start,begin)),`Unexpected text before spin BEGIN: ${file}`);
  const afterMarker=end+endMarker.length,suffix=text.slice(afterMarker);
  assert(suffix.startsWith('\n')||suffix.startsWith('\r\n'),`Spin END must be a complete line: ${file}`);
  const after=afterMarker+(suffix.startsWith('\r\n')?2:1);
  return {projected:Buffer.from(text.slice(0,start)+text.slice(after)),addition:Buffer.from(text.slice(start,after))};
}

function noReplacement(file,addition) {
  const text=addition.toString('utf8'),className=path.basename(file,'.luau');
  const methods=[...before(file).toString('utf8').matchAll(new RegExp(`^function (${className}(?:\\.[A-Za-z0-9_]+|:[A-Za-z0-9_]+))\\(`,'gm'))].map(match=>match[1]);
  const newMethods=[...text.matchAll(new RegExp(`^function (${className}(?:\\.[A-Za-z0-9_]+|:[A-Za-z0-9_]+))\\(`,'gm'))].map(match=>match[1]);
  for(const method of methods) {
    assert(!newMethods.includes(method),`A spin block redefines an existing method: ${method}`);
    const name=method.split(/[.:]/)[1];
    assert(!new RegExp(`\\b${className}\\s*(?:\\.\\s*${name}\\s*|\\[\\s*["']${name}["']\\s*\\])=`).test(text),`Runtime existing-method replacement: ${method}`);
  }
}

function checkRecord(record) {
  assert.equal(record.status,'FINALIZED_FOR_OFFLINE_VERIFICATION');
  assert.equal(record.baselineCommit,WHEEL_SPIN_BASELINE);
  assert.equal(record.approvedPatchSha256,WHEEL_SPIN_PATCH_SHA256);
  assert.deepEqual(record.changed.map(entry=>entry.file).sort(),[...WHEEL_SPIN_FILES].sort());
  assert.equal(record.addition.file,policy);
  approvedPatch();
}

export function stripWheelSpinDelta(file,bytes) {
  const data=Buffer.from(bytes);
  // Older baseline consumers keep their original behavior and need no new record.
  if(!data.includes(Buffer.from(beginMarker)))return bytes;
  assert(WHEEL_SPIN_FILES.includes(file),`Unrecorded spin addition file: ${file}`);
  const record=metadata();checkRecord(record);
  const entry=record.changed.find(entry=>entry.file===file);
  assert.equal(sha(data),entry.afterSha256,`Unrecorded spin source change: ${file}`);
  const {projected,addition}=removeAddition(file,data);
  assert.equal(sha(addition),entry.additionSha256,`Spin helper block changed: ${file}`);
  assert.equal(sha(projected),entry.approvedHooksSha256,`Existing source differs from the approved five hooks: ${file}`);
  const restored=Buffer.from(applyHooks(projected.toString('utf8'),file,true));
  assert(restored.equals(before(file)),`Spin projection does not reproduce every protected baseline byte: ${file}`);
  assert.equal(sha(restored),entry.beforeSha256);
  return typeof bytes==='string'?restored.toString('utf8'):restored;
}

export function stripWheelSpinFiles(files) {
  const result=new Map();
  for(const [file,bytes]of files) {
    if(file===policy) {
      const record=metadata();checkRecord(record);
      assert.equal(sha(bytes),record.addition.sha256,'Unrecorded pure WheelSpinPolicy source');
    } else result.set(file,stripWheelSpinDelta(file,bytes));
  }
  return result;
}

const historicalNames=()=>[...new Set([
  ...baselineNames('docs').filter(file=>file.startsWith('docs/research/')||file.startsWith('docs/verification/')
    ||file.startsWith('docs/local-feature-studio-evidence/')||/^docs\/PHASE[45](?:[-.])/.test(file)||/^docs\/LOCAL_FEATURES(?:[-_.])/.test(file)),
  ...baselineNames('examples'),...baselineNames('tests'),
])].sort();

export function recordWheelSpinWorkspace() {
  const {proposal}=approvedPatch();
  const current=diskNames('src'),expected=baselineNames('src').filter(file=>file.endsWith('.luau'));
  assert.deepEqual([...current].sort(),[...expected,policy].sort(),'Only the new pure policy may expand production files');
  const changed=[];
  for(const file of expected) {
    const old=before(file),after=readFileSync(path.join(root,file));
    if(!WHEEL_SPIN_FILES.includes(file)){assert(after.equals(old),`Unrecorded production change: ${file}`);continue;}
    const {projected,addition}=removeAddition(file,after),approved=Buffer.from(applyHooks(old.toString('utf8'),file));
    assert(projected.equals(approved),`Existing source differs from the exact approved five hooks: ${file}`);
    noReplacement(file,addition);
    const hook=proposal.existingFiles.find(entry=>entry.file===file);
    if(hook){assert.equal(sha(old),hook.beforeSha256);assert.equal(sha(approved),hook.proposedSha256);}
    changed.push({file,beforeSha256:sha(old),approvedHooksSha256:sha(approved),afterSha256:sha(after),additionSha256:sha(addition)});
  }
  const pure=readFileSync(path.join(root,policy));
  assert(!/\b(?:FireServer|InvokeServer|Submit|Execute|PivotTo|MoveTo)\s*\(|\bCFrame\s*=|task\.(?:spawn|defer|delay|wait)\s*\(/.test(pure.toString('utf8')),'Receipt policy must remain pure');
  const frozenFiles=historicalNames().map(file=>{
    const old=before(file);assert(readFileSync(path.join(root,file)).equals(old),`Historical evidence/loader/fixture changed: ${file}`);
    return {file,sha256:sha(old)};
  });
  const releasePins=git('for-each-ref','--format=%(refname:short)','refs/tags').toString().trim().split('\n').filter(Boolean)
    .map(tag=>({tag,commit:git('rev-parse',`${tag}^{commit}`).toString().trim()}));
  assert(releasePins.some(pin=>pin.tag==='phase5-free-wheel-ticket-668d0af6f157'&&pin.commit==='f4c495e2c3d313ed6666ff94dd34c384cc8a0631'));
  const record={status:'FINALIZED_FOR_OFFLINE_VERIFICATION',baselineCommit:WHEEL_SPIN_BASELINE,
    scope:'Exactly five owner-approved integration hooks plus four appended WheelSpin blocks and one pure receipt policy; disabled native one-spin candidate. No live ticket consumption authorization.',
    approvedPatch:WHEEL_SPIN_PATCH,approvedPatchSha256:WHEEL_SPIN_PATCH_SHA256,
    changed:changed.sort((a,b)=>a.file.localeCompare(b.file)),addition:{file:policy,sha256:sha(pure)},
    existingMethods:proposal.existingFiles.flatMap(entry=>entry.changedMethods.map(method=>({file:entry.file,...method}))),
    projection:'Verify exact current file/block/module hashes, remove only four unique ONE_WHEEL_SPIN blocks and the new pure policy, reverse only the immutable approved five-hook patch, reproduce every 918f8a production byte, then run the untouched historical projections.',
    frozenFiles,releasePins,acceptance:'Offline preservation only. Native animation, ticket debit and grant still need a separately authorized owner live test. Uncertain receipts remain unresolved barriers.'};
  writeFileSync(path.join(root,WHEEL_SPIN_RECORD),JSON.stringify(record,null,2)+'\n');
  return record;
}

export function verifyWheelSpinWorkspace() {
  const record=metadata();checkRecord(record);
  const current=new Map(diskNames('src').map(file=>[file,readFileSync(path.join(root,file))]));
  assert.deepEqual([...current.keys()].sort(),[...baselineNames('src').filter(file=>file.endsWith('.luau')),policy].sort());
  for(const file of WHEEL_SPIN_FILES)assert(current.get(file)?.includes(Buffer.from(beginMarker)),`Spin helper block missing: ${file}`);
  const projected=stripWheelSpinFiles(current);
  for(const [file,bytes]of projected)assert(Buffer.from(bytes).equals(before(file)),`Protected production bytes changed: ${file}`);
  assert.deepEqual(record.frozenFiles.map(entry=>entry.file),historicalNames(),'Historical coverage changed');
  for(const entry of record.frozenFiles){assert.equal(sha(before(entry.file)),entry.sha256);assert.equal(sha(readFileSync(path.join(root,entry.file))),entry.sha256,`Historical evidence/loader/fixture changed: ${entry.file}`);}
  for(const pin of record.releasePins)assert.equal(git('rev-parse',`${pin.tag}^{commit}`).toString().trim(),pin.commit,`Immutable milestone moved: ${pin.tag}`);
  console.log(`[OC WHEEL] Source preservation PASS: exact five approved hooks, four pinned blocks, pure policy, ${record.frozenFiles.length} historical files and ${record.releasePins.length} immutable milestones retained`);
  return record;
}

if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  if(process.argv.includes('--record'))recordWheelSpinWorkspace();
  else verifyWheelSpinWorkspace();
}

// A new exact delta; never rewrites the original 646 wheel approval/hash record.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {readFileSync,readdirSync,writeFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=path.resolve(import.meta.dirname,'..');
export const REMOTE_WHEEL_BASELINE='65bdddba4dab6fa5d03e4e5a1d24bb15d159b760';
export const REMOTE_WHEEL_PATCH='docs/PHASE5-WHEEL-SPIN-REMOTE-IMPLEMENTED.patch';
export const REMOTE_WHEEL_RECORD='docs/PHASE5-WHEEL-SPIN-REMOTE-SOURCE-PRESERVATION.json';
export const REMOTE_WHEEL_PATCH_SHA256='755c530523dfe278a4ab9cd0befc638b3c5734c2d63480024408b563dc592cbd';
export const REMOTE_WHEEL_FILES=Object.freeze(['src/OCFoundation/OCConfig.luau','src/OCFoundation/GameKnowledge.luau']);
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const git=(...args)=>execFileSync('git',args,{cwd:root,maxBuffer:32*1024*1024});
const baselineCache=new Map();
const before=file=>{if(!baselineCache.has(file))baselineCache.set(file,git('show',`${REMOTE_WHEEL_BASELINE}:${file}`));return baselineCache.get(file);};
const baselineNames=directory=>git('ls-tree','-r','--name-only',REMOTE_WHEEL_BASELINE,directory).toString().trim().split('\n').filter(Boolean);
const diskNames=directory=>readdirSync(path.join(root,directory),{withFileTypes:true}).flatMap(entry=>entry.isDirectory()?diskNames(`${directory}/${entry.name}`):entry.name.endsWith('.luau')?[`${directory}/${entry.name}`]:[]);
const metadata=()=>JSON.parse(readFileSync(path.join(root,REMOTE_WHEEL_RECORD),'utf8'));

function methodRange(text) {
  const begin=text.indexOf('function GameKnowledge:WheelSpinContext('),end=text.indexOf('-- PHASE5_ONE_WHEEL_SPIN_END',begin);
  assert(begin>=0&&end>begin&&text.indexOf('function GameKnowledge:WheelSpinContext(',begin+1)<0,'Exact existing wheel observer required');
  return {begin,end,body:text.slice(begin,end)};
}
function scope(file,old,data) {
  const original=old.toString('utf8'),current=data.toString('utf8');
  if(file.endsWith('/OCConfig.luau')) {
    const flag=/^\s*ALLOW_REMOTE_WHEEL_TEST\s*=\s*false\s*,[^\r\n]*(?:\r?\n)/gm;
    assert.equal([...current.matchAll(flag)].length,1,'Exactly one false-default remote test setting is required');
    assert.equal(current.replace(flag,''),original,'Config change must add only the false-default remote test flag');
  } else {
    const a=methodRange(original),b=methodRange(current);
    assert.equal(current.slice(0,b.begin)+current.slice(b.end),original.slice(0,a.begin)+original.slice(a.end),'Remote wheel may change only the existing WheelSpinContext method');
    assert(current.includes('ALLOW_REMOTE_WHEEL_TEST'),'Remote mode requires the explicit isolated setting');
  }
}
function patchHunks(bytes) {
  const hunks=new Map();let file,hunk;
  for(const line of bytes.toString('utf8').replace(/\r\n/g,'\n').split('\n')) {
    if(line.startsWith('diff --git ')){file=undefined;hunk=undefined;}
    else if(line.startsWith('+++ b/')){file=line.slice(6);hunks.set(file,[]);}
    else if(line.startsWith('@@ ')){assert(file);hunk=[];hunks.get(file).push(hunk);}
    else if(hunk&&/^[ +\-]/.test(line))hunk.push(line);
    else if(line.startsWith('\\ No newline'))throw new Error('Unsupported no-newline remote wheel delta');
  }
  assert.deepEqual([...hunks.keys()].sort(),[...REMOTE_WHEEL_FILES].sort());
  return hunks;
}
function reversePatch(source,file,patch) {
  const eol=source.includes('\r\n')?'\r\n':'\n';
  for(const lines of [...(patchHunks(patch).get(file)||[])].reverse()) {
    const after=lines.filter(line=>line[0]!=='-').map(line=>line.slice(1)).join(eol)+eol;
    const old=lines.filter(line=>line[0]!=='+').map(line=>line.slice(1)).join(eol)+eol;
    const start=source.indexOf(after);
    assert(start>=0&&source.indexOf(after,start+after.length)<0,`Remote delta anchor absent/ambiguous: ${file}`);
    source=source.slice(0,start)+old+source.slice(start+after.length);
  }
  return source;
}
function checkedRecord() {
  const record=metadata(),patch=readFileSync(path.join(root,REMOTE_WHEEL_PATCH));
  assert.equal(record.status,'FINALIZED_FOR_OFFLINE_VERIFICATION');
  assert.equal(record.baselineCommit,REMOTE_WHEEL_BASELINE);
  assert.equal(record.patchSha256,REMOTE_WHEEL_PATCH_SHA256);
  assert.equal(sha(patch),REMOTE_WHEEL_PATCH_SHA256,'Pinned remote wheel patch changed');
  assert.deepEqual(record.changed.map(entry=>entry.file).sort(),[...REMOTE_WHEEL_FILES].sort());
  patchHunks(patch);
  return {record,patch};
}
export function stripRemoteWheelDelta(file,bytes) {
  const data=Buffer.from(bytes);
  // Every earlier historical source passes through without needing the new record.
  if(!REMOTE_WHEEL_FILES.includes(file)||!data.includes(Buffer.from('ALLOW_REMOTE_WHEEL_TEST')))return bytes;
  const {record,patch}=checkedRecord(),entry=record.changed.find(entry=>entry.file===file);
  assert.equal(sha(data),entry.afterSha256,`Unrecorded remote wheel source: ${file}`);
  const restored=Buffer.from(reversePatch(data.toString('utf8'),file,patch));
  assert(restored.equals(before(file)),`Remote wheel projection must reproduce every 646 source byte: ${file}`);
  assert.equal(sha(restored),entry.beforeSha256);
  scope(file,restored,data);
  return typeof bytes==='string'?restored.toString('utf8'):restored;
}
export function stripRemoteWheelFiles(files){return new Map([...files].map(([file,bytes])=>[file,stripRemoteWheelDelta(file,bytes)]));}
const historicalNames=()=>[...new Set([
  ...baselineNames('docs').filter(file=>file.startsWith('docs/research/')||file.startsWith('docs/verification/')||file.startsWith('docs/local-feature-studio-evidence/')||/^docs\/PHASE[45](?:[-.])/.test(file)||/^docs\/LOCAL_FEATURES(?:[-_.])/.test(file)),
  ...baselineNames('examples'),...baselineNames('tests'),
])].sort();
export function recordRemoteWheelWorkspace() {
  const expected=baselineNames('src').filter(file=>file.endsWith('.luau')),current=diskNames('src');
  assert.deepEqual([...current].sort(),[...expected].sort(),'Remote wheel introduces no production module or new loop');
  const changed=[];
  for(const file of expected) {
    const old=before(file),data=readFileSync(path.join(root,file));
    if(!REMOTE_WHEEL_FILES.includes(file)){assert(data.equals(old),`Unrelated production source changed: ${file}`);continue;}
    scope(file,old,data);
    changed.push({file,beforeSha256:sha(old),afterSha256:sha(data),...(file.endsWith('/GameKnowledge.luau')?{method:'GameKnowledge:WheelSpinContext',beforeMethodSha256:sha(methodRange(old.toString('utf8')).body),afterMethodSha256:sha(methodRange(data.toString('utf8')).body)}:{})});
  }
  const patch=git('diff','--no-ext-diff','--binary',REMOTE_WHEEL_BASELINE,'--',...REMOTE_WHEEL_FILES);
  patchHunks(patch);
  for(const entry of changed)assert(Buffer.from(reversePatch(readFileSync(path.join(root,entry.file),'utf8'),entry.file,patch)).equals(before(entry.file)));
  writeFileSync(path.join(root,REMOTE_WHEEL_PATCH),patch);
  const frozenFiles=historicalNames().map(file=>{
    const old=before(file);assert(readFileSync(path.join(root,file)).equals(old),`Historical wheel/evidence/fixture changed: ${file}`);
    return {file,sha256:sha(old)};
  });
  const releasePins=git('for-each-ref','--format=%(refname:short)','refs/tags').toString().trim().split('\n').filter(Boolean).map(tag=>({tag,commit:git('rev-parse',`${tag}^{commit}`).toString().trim()}));
  assert(releasePins.some(pin=>pin.tag==='phase5-wheel-spin-646b0df72fed'&&pin.commit===REMOTE_WHEEL_BASELINE));
  const record={status:'FINALIZED_FOR_OFFLINE_VERIFICATION',baselineCommit:REMOTE_WHEEL_BASELINE,
    scope:'Standing owner implementation approval: add one false-default remote-wheel test option and condition only native UI open/visible and physical wheel proximity requirements in the existing read-only observer. Native initialized callback, account/access/stock/lease/foreign UI/auto-claim/receipt safeguards remain required. No live ticket consumption inferred.',
    patch:REMOTE_WHEEL_PATCH,patchSha256:sha(patch),changed:changed.sort((a,b)=>a.file.localeCompare(b.file)),
    projection:'Verify exact before/after bytes, reverse only this separately recorded two-file patch, reproduce all 65bdddba production bytes, then run the untouched original 646 wheel record and every earlier historical projection.',
    frozenFiles,releasePins,acceptance:'Offline candidate only. Server remote acceptance and hidden native animation/settlement require the separately authorized bounded owner test; uncertainty preserves the one-attempt barrier.'};
  writeFileSync(path.join(root,REMOTE_WHEEL_RECORD),JSON.stringify(record,null,2)+'\n');
  console.log(`[OC REMOTE WHEEL] Recorded exact new patch SHA256 ${record.patchSha256}; pin that value in verifier before validating`);
  return record;
}
export function verifyRemoteWheelWorkspace() {
  const {record}=checkedRecord();
  const current=new Map(diskNames('src').map(file=>[file,readFileSync(path.join(root,file))]));
  assert.deepEqual([...current.keys()].sort(),baselineNames('src').filter(file=>file.endsWith('.luau')).sort());
  for(const file of REMOTE_WHEEL_FILES)assert(current.get(file).includes(Buffer.from('ALLOW_REMOTE_WHEEL_TEST')),`Remote test flag/guard missing: ${file}`);
  for(const [file,bytes]of stripRemoteWheelFiles(current))assert(Buffer.from(bytes).equals(before(file)),`646 source not preserved: ${file}`);
  assert.deepEqual(record.frozenFiles.map(entry=>entry.file),historicalNames());
  for(const entry of record.frozenFiles){assert.equal(sha(before(entry.file)),entry.sha256);assert.equal(sha(readFileSync(path.join(root,entry.file))),entry.sha256,`Historical evidence/loader/fixture changed: ${entry.file}`);}
  for(const pin of record.releasePins)assert.equal(git('rev-parse',`${pin.tag}^{commit}`).toString().trim(),pin.commit,`Historical release pin moved: ${pin.tag}`);
  console.log(`[OC REMOTE WHEEL] Source preservation PASS: exact two-file delta; ${record.frozenFiles.length} original evidence/fixture/loader files and ${record.releasePins.length} immutable pins retained`);
  return record;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  if(process.argv.includes('--record'))recordRemoteWheelWorkspace();else verifyRemoteWheelWorkspace();
}

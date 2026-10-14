import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {stripFreeWheelTicketDelta} from './verify-phase5-free-wheel-ticket.mjs';

const root=path.resolve(import.meta.dirname,'..');
export const REWARD_BASELINE='7e833f94a1d2ff4011be3bdc74fcea0d10e30efc';
const recordPath='docs/PHASE5-REWARDS-SOURCE-PRESERVATION.json';
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const git=file=>execFileSync('git',['show',`${REWARD_BASELINE}:${file}`],{cwd:root,maxBuffer:8*1024*1024});
const record=()=>JSON.parse(readFileSync(path.join(root,recordPath),'utf8'));
const changed=['src/OCFoundation/OCConfig.luau','src/OCFoundation/OCBrain.luau','src/OCFoundation/OCController.luau','src/OCFoundation/GameKnowledge.luau'];
const addition='src/OCFoundation/RewardPolicy.luau';

export function stripRewardDelta(file,bytes){
 bytes=stripFreeWheelTicketDelta(file,bytes);
 const data=Buffer.from(bytes);
 if(!changed.includes(file)||!data.includes(Buffer.from('-- PHASE5_READ_ONLY_REWARDS_BEGIN'))) return bytes;
 const entry=record().changed.find(value=>value.file===file);
 assert(entry&&sha(data)===entry.afterSha256,`Unrecorded reward intelligence delta: ${file}`);
 const text=data.toString('utf8'),marker='-- PHASE5_READ_ONLY_REWARDS_END';
 const begin=text.indexOf('-- PHASE5_READ_ONLY_REWARDS_BEGIN'),end=text.indexOf(marker);
 assert(begin>=0&&end>begin&&text.indexOf(marker,end+marker.length)<0,`Nonunique reward boundaries: ${file}`);
 const start=text.lastIndexOf('\n',begin)+1;
 const after=end+marker.length+(text.slice(end+marker.length).startsWith('\r\n')?2:1);
 const projected=Buffer.from(text.slice(0,start)+text.slice(after)), before=git(file);
 assert(projected.equals(before),`Reward intelligence changed an existing method or interface: ${file}`);
 assert.equal(sha(before),entry.beforeSha256,`Immutable Mastery source baseline: ${file}`);
 return typeof bytes==='string'?projected.toString('utf8'):projected;
}
export function stripRewardFiles(files){
 const result=new Map();
 for(const [file,original] of files){
  const bytes=stripFreeWheelTicketDelta(file,original);
  if(file===addition){assert.equal(sha(bytes),record().addition.sha256,'Unrecorded pure RewardPolicy source');continue;}
  result.set(file,stripRewardDelta(file,bytes));
 }
 return result;
}
const files=directory=>readdirSync(path.join(root,directory),{withFileTypes:true}).flatMap(entry=>entry.isDirectory()?files(`${directory}/${entry.name}`):entry.name.endsWith('.luau')?[`${directory}/${entry.name}`]:[]);
export function verifyRewardWorkspace(){
 const metadata=record();assert.equal(metadata.baselineCommit,REWARD_BASELINE);
 assert.deepEqual(metadata.changed.map(value=>value.file).sort(),[...changed].sort());assert.equal(metadata.addition.file,addition);
 const expected=execFileSync('git',['ls-tree','-r','--name-only',REWARD_BASELINE,'src'],{cwd:root,encoding:'utf8'}).trim().split('\n').filter(file=>file.endsWith('.luau'));
 const current=new Map(files('src').map(file=>[file,readFileSync(path.join(root,file))])),projected=stripRewardFiles(current);
 assert.deepEqual([...projected.keys()].sort(),expected.sort(),'Only the pure reward intelligence module may expand production files');
 for(const [file,bytes] of projected)assert(Buffer.from(bytes).equals(git(file)),`Existing production bytes changed: ${file}`);
 const policy=current.get(addition).toString('utf8');
 assert(!/FireServer|InvokeServer|HatchEgg|CFrame\s*=|Scheduler:Submit|task\.(?:spawn|defer|delay|wait)|:Collect\s*\(|:Claim\s*\(|:Use\s*\(/.test(policy),'Reward policy cannot transport actions or run automation');
 for(const file of metadata.frozenFiles)assert(readFileSync(path.join(root,file)).equals(git(file)),`Mastery evidence/example/tests changed: ${file}`);
 for(const pin of metadata.releasePins)assert.equal(execFileSync('git',['rev-parse',`${pin.tag}^{commit}`],{cwd:root,encoding:'utf8'}).trim(),pin.commit,`Immutable milestone moved: ${pin.tag}`);
 console.log(`[OC] Reward intelligence preservation PASS: one pure module/four exact additions, every existing production byte, Mastery evidence and ${metadata.releasePins.length} immutable milestones retained`);
 return metadata;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url))verifyRewardWorkspace();

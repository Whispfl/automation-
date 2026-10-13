// Anonymous distribution integrity only. No Roblox or gameplay execution.
import assert from 'node:assert/strict';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {execFileSync,spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import path from 'node:path';

const root=path.resolve(import.meta.dirname,'..');
const git=(...args)=>execFileSync('git',args,{cwd:root,encoding:'utf8'}).trim();
const repository='Whispfl/automation-', raw=`https://raw.githubusercontent.com/${repository}`;
const commit=git('rev-parse','HEAD'), branch=git('branch','--show-current');
const bundle=await readFile(path.join(root,'dist/OC.lua'));
const buildId=bundle.toString('utf8').match(/-- Build: ([a-f0-9]{12})/)[1], tag=`phase5-mastery-${buildId}`;
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const get=async url=>{
 const response=await fetch(url,{signal:AbortSignal.timeout(30000)});
 assert(response.ok,`Anonymous HTTP ${response.status}: ${url}`);
 return Buffer.from(await response.arrayBuffer());
};
const api=async suffix=>JSON.parse((await get(`https://api.github.com/repos/${repository}${suffix}`)).toString('utf8'));
const metadata=JSON.parse(await readFile(path.join(root,'docs/PHASE5-READ-ONLY-SOURCE-PRESERVATION.json'),'utf8'));
const refs=await Promise.allSettled([api(`/git/ref/heads/${branch}`),api(`/git/ref/tags/${tag}`),api(`/git/trees/${commit}?recursive=1`)]);
for(const result of refs) if(result.status==='rejected') throw result.reason;
const [branchRef,tagRef,tree]=refs.map(result=>result.value);
assert.equal(branchRef.object.sha,commit); assert.equal(tagRef.object.type,'commit'); assert.equal(tagRef.object.sha,commit);
assert.equal(git('rev-parse',`${tag}^{commit}`),commit); assert.equal(tree.truncated,false);
const publicBlobs=new Map(tree.tree.filter(entry=>entry.type==='blob').map(entry=>[entry.path,entry.sha]));
const localBlobs=new Map(git('ls-tree','-r','--full-tree',commit).split('\n').filter(Boolean).map(line=>{
 const [attributes,file]=line.split('\t'); return [file,attributes.split(' ')[2]];
}));
assert.equal(publicBlobs.size,localBlobs.size);
for(const [file,blob] of localBlobs){
 assert.equal(publicBlobs.get(file),blob,`Public blob differs: ${file}`);
 assert(!/^(?:\.local-evidence\/|\.test-output\/|\.tools\/|node_modules\/)|PHASE4-OWNER-LIVE-DIRECT-1d27e2a74ae5-(?:CONSOLE\.txt|ARCHIVE\.json)/.test(file),`Private evidence/tool output in public tree: ${file}`);
}
const privateAncestor=spawnSync('git',['merge-base','--is-ancestor','34342b60c6cb82012aa531b09861c554beb8b265',commit],{cwd:root});
assert.equal(privateAncestor.status,1,'Private raw-log commit must remain outside published ancestry');
const files=['dist/OC.lua','dist/OC.local.lua','examples/Phase5MasteryReadOnly.luau','src/OCFoundation/MasteryPolicy.luau',
 'src/OCFoundation/GameKnowledge.luau','src/OCFoundation/OCBrain.luau','src/OCFoundation/OCController.luau','src/OCFoundation/OCConfig.luau',
 'docs/PHASE5-MASTERY-READ-ONLY.md','docs/PHASE5-READ-ONLY-SOURCE-PRESERVATION.json','tests/phase5-mastery.luau'];
const checks=[];
for(let start=0;start<files.length;start+=6){
 const results=await Promise.allSettled(files.slice(start,start+6).map(async file=>{
  const expected=await readFile(path.join(root,file)), actual=await get(`${raw}/${tag}/${file}`);
  assert(actual.equals(expected),`Pinned bytes differ: ${file}`);
  return {file,ref:tag,bytes:actual.length,sha256:sha(actual),result:'PASS'};
 }));
 for(const result of results){if(result.status==='rejected') throw result.reason; checks.push(result.value);}
}
const histories=await Promise.allSettled(metadata.releasePins.map(async pin=>{
 assert.equal((await api(`/git/ref/tags/${pin.tag}`)).object.sha,pin.commit,`Historical public tag changed: ${pin.tag}`);
 const original=execFileSync('git',['show',`${pin.commit}:dist/OC.lua`],{cwd:root}), actual=await get(`${raw}/${pin.tag}/dist/OC.lua`);
 assert(actual.equals(original),`Historical release bytes changed: ${pin.tag}`);
 return {file:'dist/OC.lua',ref:pin.tag,bytes:actual.length,sha256:sha(actual),result:'PASS'};
}));
for(const result of histories){if(result.status==='rejected') throw result.reason;checks.push(result.value);}
const loader=(await readFile(path.join(root,files[2]))).toString('utf8');
assert(loader.includes(`${raw}/${tag}/dist/OC.lua`),'Read-only example must match immutable candidate');
const report={commit,branch,tag,buildId,bundleSHA256:sha(bundle),bundleBytes:bundle.length,publicGitBlobs:localBlobs.size,anonymousAccess:true,
 privateRawEvidencePublished:false,checks,result:'PASS',scope:'Offline/read-only distribution; no owner Mastery live acceptance or gameplay action'};
await mkdir(path.join(root,'.test-output'),{recursive:true});
await writeFile(path.join(root,'.test-output/phase5-public-verification.json'),JSON.stringify(report,null,2)+'\n');
console.log(`[OC PUBLIC PHASE5] PASS: ${commit}; ${tag}; ${localBlobs.size} Git blobs and ${checks.length} anonymous raw artifacts match; all five historical releases unchanged; private raw-log ancestry excluded`);

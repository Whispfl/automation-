// Actual approved-source synthetic checks. No Roblox or gameplay actions.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {bundle,sources} from './bundle.mjs';
import {verifyWheelSpinWorkspace,WHEEL_SPIN_PATCH,WHEEL_SPIN_PATCH_SHA256} from './verify-phase5-wheel-spin.mjs';
import {verifyWheelSpinDisabledLoader} from './test-phase5-wheel-spin-loader.mjs';

const root=path.resolve(import.meta.dirname,'..');
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
function run(executable,args,label) {
  const result=spawnSync(executable,args,{cwd:root,encoding:'utf8',timeout:120000,maxBuffer:16*1024*1024});
  if(result.error)throw result.error;
  process.stdout.write(result.stdout||'');process.stderr.write(result.stderr||'');
  assert.equal(result.status,0,`${label} failed`);
  return result.stdout||'';
}

export async function verifyWheelSpinCandidate() {
  const preservation=verifyWheelSpinWorkspace();
  await import('../tests/phase5-wheel-spin-preservation.mjs');
  const source=await sources(root),generated=bundle(source);
  assert.equal(await readFile(path.join(root,'dist/OC.lua'),'utf8'),generated.output,'Published candidate bundle must reproduce actual source');
  const directory=path.join(root,'.test-output','spin-candidate');
  await mkdir(directory,{recursive:true});
  const compiler=process.env.LUAU_COMPILE_BIN||path.join(root,'.tools/luau',process.platform==='win32'?'luau-compile.exe':'luau-compile');
  const executable=process.env.LUAU_BIN||path.join(root,'.tools/luau',process.platform==='win32'?'luau.exe':'luau');
  const loaderPath=path.join(root,'examples/Phase5WheelSpinDisabled.luau');
  const loader=await readFile(loaderPath,'utf8');
  const expectedURL=`https://raw.githubusercontent.com/Whispfl/automation-/phase5-wheel-spin-${generated.buildId}/dist/OC.lua`;
  assert.equal((loader.match(/game:HttpGet\(/g)||[]).length,1,'Disabled WheelSpin loader fetches once');
  assert(loader.includes(`game:HttpGet("${expectedURL}")`),'Disabled loader must pin this exact candidate');
  assert(!/\b(?:GitHubToken|FireServer|InvokeServer)\b|["']Authorization["']\s*[:=]|OC:Start\s*\(/.test(loader),'Disabled loader has no credentials, transport or Start');
  run(compiler,['--null',...source.modules.map(module=>path.join(root,'src/OCFoundation',module.name+'.luau')),
    path.join(root,'src/OC.luau'),path.join(root,'dist/OC.lua'),loaderPath],'Official actual-source compilation');
  const environment=(await readFile(path.join(root,'tests/foundation.luau'),'utf8')).split('-- BUNDLE INSERTION POINT')[0];
  const prefixEnd=loader.indexOf('local OC = loadstring(game:HttpGet(');
  assert(prefixEnd>=0,'Disabled WheelSpin loader must retain the public bundle invocation');
  const configBinding=`local function phase5WheelSpinManagerOverrides()\n${loader.slice(0,prefixEnd)}\nreturn Config\nend\n`;
  const fixtures=[
    {name:'receipt-policy',file:'tests/phase5-wheel-spin.luau',binding:'local WheelSpinPolicy = requireOC("WheelSpinPolicy")\n',environment:''},
    {name:'native-observation',file:'tests/phase5-wheel-spin-knowledge.luau',binding:'',environment},
    {name:'native-bridge',file:'tests/phase5-wheel-spin-bridge.luau',binding:'',environment},
    {name:'reward-manager',file:'tests/phase5-wheel-spin-manager.luau',binding:configBinding,environment},
  ];
  const results=[];
  for(const fixture of fixtures) {
    const text=await readFile(path.join(root,fixture.file),'utf8'),file=path.join(directory,fixture.name+'.luau');
    await writeFile(file,fixture.environment+'\nlocal shared = {}\n'+generated.library+'\n'+fixture.binding+text);
    run(compiler,['--null',file],`Official ${fixture.name} fixture compilation`);
    const stdout=run(executable,[file],`${fixture.name} actual-source regressions`);
    results.push({name:fixture.name,fixture:fixture.file,fixtureSha256:sha(text),stdoutSha256:sha(stdout),status:'PASS'});
  }
  const disabledLoader = await verifyWheelSpinDisabledLoader();
  const report={status:'OFFLINE_PASS_DISABLED_CANDIDATE',approvedPatch:WHEEL_SPIN_PATCH,
    approvedPatchSha256:WHEEL_SPIN_PATCH_SHA256,buildId:generated.buildId,bundleSha256:sha(generated.output),
    sourcePreservationRecordSha256:sha(JSON.stringify(preservation)),fixtures:results,disabledLoader,
    limitation:'Synthetic actual-source fixtures only. The disabled loader performs no spin. Owner live native animation, ticket debit and grant require separate explicit approval; uncertain receipts remain barriers.'};
  await writeFile(path.join(directory,'VERIFICATION.json'),JSON.stringify(report,null,2)+'\n');
  verifyWheelSpinWorkspace();
  console.log(`[OC WHEEL] PASS: disabled candidate ${generated.buildId}; receipt, native knowledge, bridge, reward manager and complete disabled loader regressions`);
  return report;
}

if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url))await verifyWheelSpinCandidate();

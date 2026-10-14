// Reuse the unchanged 646 loader cases against the new read-only remote loader.
import assert from 'node:assert/strict';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {sources,bundle} from './bundle.mjs';
const root=path.resolve(import.meta.dirname,'..');
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
export async function verifyRemoteWheelDisabledLoader() {
  const source=await sources(root),generated=bundle(source);
  const filePath=path.join(root,'examples/Phase5WheelSpinRemoteDisabled.luau');
  const bytes=await readFile(filePath),loader=bytes.toString('utf8');
  const url=`https://raw.githubusercontent.com/Whispfl/automation-/phase5-wheel-spin-remote-${generated.buildId}/dist/OC.lua`;
  const invocation=`local OC = loadstring(game:HttpGet("${url}"))()(Config)`;
  assert(loader.includes(invocation),'Remote disabled loader must pin this exact build');
  assert(loader.includes(`RemoteTest = true, BuildId = "${generated.buildId}"`),'Read-only report must identify the exact remote candidate');
  assert.equal((loader.match(/game:HttpGet\(/g)||[]).length,1);
  assert(!/\b(?:GitHubToken|FireServer|InvokeServer|SetAttribute)\b|["']Authorization["']\s*[:=]/.test(loader),'Read-only loader has no native input/transport or credentials');
  assert(!/:\s*(?:Start|Resume|Select|Prepare|InitializeWheelSpin|PrepareWheelSpin|MarkWheelSpinDispatched|SpinWheelOnce)\s*\(/.test(loader),'Loader cannot start or prepare a game action');
  const environment=(await readFile(path.join(root,'tests/foundation.luau'),'utf8')).split('-- BUNDLE INSERTION POINT')[0];
  const manager=await readFile(path.join(root,'tests/phase5-wheel-spin-manager.luau'),'utf8');
  const managerPrefix=manager.slice(0,manager.indexOf('test("disabled extension'));
  const oldLoader=await readFile(path.join(root,'examples/Phase5FreeWheelTicketDisabled.luau'),'utf8');
  const oldPrefix=oldLoader.slice(0,oldLoader.indexOf('local OC = loadstring'));
  const originalTests=await readFile(path.join(root,'tests/phase5-wheel-spin-loader.luau'),'utf8');
  const additions=`
test("remote observation flag defaults false in production and grants no action permission", function()
 assert(Defaults.WHEEL_SPIN_SETTINGS.ALLOW_REMOTE_WHEEL_TEST == false)
 local s = loaderScene() local report = s:Run()
 assert(s.Config.WHEEL_SPIN_SETTINGS.ALLOW_REMOTE_WHEEL_TEST == true and report.RemoteTest == true)
 assert(report.BuildId == "${generated.buildId}" and report.Ready and report.ActionsAuthorized == false)
 assert(s.Config.WHEEL_SPIN_SETTINGS.AUTO_SPIN_WHEEL == false and s.Config.WHEEL_SPIN_SETTINGS.OWNER_ONE_SPIN_ALLOWANCE == false)
 assert(s.Actions == 0 and s.Inputs == 0 and s.Commands == 0 and s.Manager.Ledger.WheelSpin == nil)
end)
test("remote preflight rejects an altered remote observation scope before native reads", function()
 local s = loaderScene({ Load = function(v) v.Config.WHEEL_SPIN_SETTINGS.ALLOW_REMOTE_WHEEL_TEST = false end })
 local report = s:Run()
 assert(not report.Ready and s.ContextCalls == 0 and s.Actions == 0)
end)
print("[OC REMOTE WHEEL LOADER SYNTHETIC] " .. tostring(checks) .. " complete read-only remote-loader checks passed")
`;
  await mkdir(path.join(root,'.test-output'),{recursive:true});
  const testPath=path.join(root,'.test-output/phase5-wheel-spin-remote-loader.luau');
  await writeFile(testPath,environment+'\nlocal shared = {}\n'+generated.library
    +'\nlocal function phase5WheelSpinManagerOverrides()\n'+oldPrefix+'\nreturn Config\nend\n'+managerPrefix
    +'\nlocal wheelSpinLoaderScene\nlocal function wheelSpinLoaderMockInit(config) return wheelSpinLoaderScene:Load(config) end\nlocal function executeDisabledWheelSpinLoader()\n'
    +loader.replace(invocation,'local OC = wheelSpinLoaderMockInit(Config)')+'\nend\n'+originalTests+additions);
  const compiler=process.env.LUAU_COMPILE_BIN||path.join(root,'.tools/luau',process.platform==='win32'?'luau-compile.exe':'luau-compile');
  const executable=process.env.LUAU_BIN||path.join(root,'.tools/luau',process.platform==='win32'?'luau.exe':'luau');
  for(const [binary,args,label]of [[compiler,['--null',filePath,testPath],'official remote loader compilation'],[executable,[testPath],'complete actual remote loader fixtures']]) {
    const result=spawnSync(binary,args,{cwd:root,encoding:'utf8',timeout:30000});
    if(result.error)throw result.error;
    process.stdout.write(result.stdout||'');process.stderr.write(result.stderr||'');
    assert.equal(result.status,0,label);
  }
  assert.equal(sha(await readFile(filePath)),sha(bytes),'Fixtures must preserve the public disabled loader');
  return {status:'PASS',buildId:generated.buildId,loaderSha256:sha(bytes),historicalFixtureSha256:sha(originalTests)};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url))await verifyRemoteWheelDisabledLoader();

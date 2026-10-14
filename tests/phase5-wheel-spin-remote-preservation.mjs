// Separate remote-wheel delta; in-memory negatives never change historical source.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import path from 'node:path';
import {stripRemoteWheelDelta,stripRemoteWheelFiles,REMOTE_WHEEL_FILES,REMOTE_WHEEL_BASELINE} from '../scripts/verify-phase5-wheel-spin-remote.mjs';
const root=path.resolve(import.meta.dirname,'..');let checks=0;
const test=(name,callback)=>{callback();checks++;console.log(`[OC REMOTE WHEEL PRESERVATION] ${name} passed`);};
for(const file of REMOTE_WHEEL_FILES) {
  const current=readFileSync(path.join(root,file)),old=execFileSync('git',['show',`${REMOTE_WHEEL_BASELINE}:${file}`],{cwd:root,maxBuffer:8*1024*1024});
  test(`exact current source restores original 646 bytes: ${path.basename(file)}`,()=>assert(Buffer.from(stripRemoteWheelDelta(file,current)).equals(old)));
  test(`immutable 646 bytes need no new projection: ${path.basename(file)}`,()=>assert.strictEqual(stripRemoteWheelDelta(file,old),old));
  test(`unrecorded current edit rejected: ${path.basename(file)}`,()=>assert.throws(()=>stripRemoteWheelDelta(file,Buffer.concat([current,Buffer.from('\n')]))));
  test(`unrecorded remote guard changed rejected: ${path.basename(file)}`,()=>assert.throws(()=>stripRemoteWheelDelta(file,current.toString('utf8').replace('ALLOW_REMOTE_WHEEL_TEST','ALLOW_REMOTE_WHEEL_TEST_BROADENED'))));
}
test('remote projection removes no production file',()=>{
  const entries=REMOTE_WHEEL_FILES.map(file=>[file,readFileSync(path.join(root,file))]);
  const files=new Map([...entries,['src/OCFoundation/WheelSpinPolicy.luau','unchanged pure policy bytes']]);
  const projected=stripRemoteWheelFiles(files);
  assert.deepEqual([...projected.keys()],[...files.keys()]);
  assert.equal(projected.get('src/OCFoundation/WheelSpinPolicy.luau'),'unchanged pure policy bytes');
});
console.log(`[OC REMOTE WHEEL PRESERVATION] ${checks} exact delta/tampering checks passed`);

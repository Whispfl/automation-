// In-memory tampering tests; never write production or historical evidence.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import path from 'node:path';
import {stripWheelSpinDelta,stripWheelSpinFiles,WHEEL_SPIN_FILES,WHEEL_SPIN_BASELINE} from '../scripts/verify-phase5-wheel-spin.mjs';
const root=path.resolve(import.meta.dirname,'..');
let checks=0;
const test=(name,callback)=>{callback();checks++;console.log(`[OC WHEEL PRESERVATION] ${name} passed`);};
for(const file of WHEEL_SPIN_FILES) {
  const current=readFileSync(path.join(root,file));
  const before=execFileSync('git',['show',`${WHEEL_SPIN_BASELINE}:${file}`],{cwd:root,maxBuffer:8*1024*1024});
  test(`exact source projects to immutable baseline: ${path.basename(file)}`,()=>assert(Buffer.from(stripWheelSpinDelta(file,current)).equals(before)));
  test(`old baseline stays exact: ${path.basename(file)}`,()=>assert.strictEqual(stripWheelSpinDelta(file,before),before));
  test(`extra source edit rejected: ${path.basename(file)}`,()=>assert.throws(()=>stripWheelSpinDelta(file,Buffer.concat([current,Buffer.from('\n')]))));
  test(`changed helper block rejected: ${path.basename(file)}`,()=>assert.throws(()=>stripWheelSpinDelta(file,current.toString('utf8').replace('-- PHASE5_ONE_WHEEL_SPIN_BEGIN','-- PHASE5_ONE_WHEEL_SPIN_BEGIN\n-- tampered synthetic block'))));
  test(`duplicate marker rejected: ${path.basename(file)}`,()=>assert.throws(()=>stripWheelSpinDelta(file,current.toString('utf8').replace('-- PHASE5_ONE_WHEEL_SPIN_END','-- PHASE5_ONE_WHEEL_SPIN_BEGIN\n-- PHASE5_ONE_WHEEL_SPIN_END'))));
}
const policy='src/OCFoundation/WheelSpinPolicy.luau',bytes=readFileSync(path.join(root,policy));
test('only the exactly pinned pure policy is removed from the map',()=>{
  const files=new Map([[policy,bytes],['src/OCFoundation/SyntheticUnrelated.luau','exact unrelated bytes']]);
  const projected=stripWheelSpinFiles(files);
  assert.equal(projected.size,1);assert.equal(projected.get('src/OCFoundation/SyntheticUnrelated.luau'),'exact unrelated bytes');
});
test('changed pure policy cannot disappear from the map',()=>assert.throws(()=>stripWheelSpinFiles(new Map([[policy,Buffer.concat([bytes,Buffer.from('\n')])]]))));
test('an arbitrary source file cannot borrow the approved marker',()=>assert.throws(()=>stripWheelSpinDelta('src/OCFoundation/SyntheticUnapproved.luau','-- PHASE5_ONE_WHEEL_SPIN_BEGIN\nreturn {}\n-- PHASE5_ONE_WHEEL_SPIN_END\n')));
console.log(`[OC WHEEL PRESERVATION] ${checks} exact source/projection/tampering checks passed`);

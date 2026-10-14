// New targeted fixtures reuse immutable prior helpers; no old tests are edited.
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { sources, bundle } from './bundle.mjs';
const root = path.resolve(import.meta.dirname, '..');
const source = await sources(root), generated = bundle(source);
const environment = (await readFile(path.join(root, 'tests/foundation.luau'), 'utf8')).split('-- BUNDLE INSERTION POINT')[0];
const knowledge = await readFile(path.join(root, 'tests/phase5-wheel-spin-knowledge.luau'), 'utf8');
const bridge = await readFile(path.join(root, 'tests/phase5-wheel-spin-bridge.luau'), 'utf8');
const knowledgeMarker = 'test("full observed current public native interfaces are detached and read-only"';
const bridgeMarker = 'audit("Deferred public press yields once and releases exactly one native spin and queue"';
assert.equal(knowledge.split(knowledgeMarker).length, 2);
assert.equal(bridge.split(bridgeMarker).length, 2);
const fixture = await readFile(path.join(root, 'tests/phase5-wheel-spin-remote.luau'), 'utf8');
const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau-compile.exe' : 'luau-compile');
const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau.exe' : 'luau');
const cases = [
  { kind: 'KNOWLEDGE', prefix: knowledge.slice(0, knowledge.indexOf(knowledgeMarker)), binding: 'remoteKnowledgeSupport', exports: '{ Fixture = fixture, Object = object, OriginalClock = originalClock }' },
  { kind: 'BRIDGE', prefix: bridge.slice(0, bridge.indexOf(bridgeMarker)), binding: 'remoteBridgeSupport', exports: '{ Fixture = fixture, Pump = pump, OriginalTask = originalTask, OriginalClock = originalClock }' },
];
await mkdir(path.join(root, '.test-output'), { recursive: true });
for (const test of cases) {
  const file = path.join(root, '.test-output', `phase5-wheel-spin-remote-${test.kind.toLowerCase()}.luau`);
  const text = environment + '\nlocal shared = {}\n' + generated.library
    + `\nlocal ${test.binding} = (function()\n${test.prefix}\nreturn ${test.exports}\nend)()\nlocal REMOTE_WHEEL_TEST_KIND = "${test.kind}"\n` + fixture;
  await writeFile(file, text);
  for (const [binary, args, label] of [[compiler, ['--null', file], 'official compile'], [executable, [file], 'actual-source remote fixtures']]) {
    const result = spawnSync(binary, args, { cwd: root, encoding: 'utf8', timeout: 30000 });
    if (result.error) throw result.error;
    process.stdout.write(result.stdout || ''); process.stderr.write(result.stderr || '');
    assert.equal(result.status, 0, `${test.kind} ${label} must pass`);
  }
}
console.log(`[OC REMOTE WHEEL] Official compilation and scoped read-only/native-bridge fixtures PASS on ${generated.buildId}; server distance acceptance UNKNOWN.`);

import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { extractFrozenMethod, sha256 } from '../scripts/verify-phase4-approved-membership.mjs';

// The owner observed 85 native Updates and the correct 10-Coin quote in this
// immutable candidate. Further receiver evidence must preserve its hooks,
// classification, cleanup and price/paid guards, independently of diagnostics.
const baseline = 'd864a3ec269f2bb1702b47244f3026300ec2ce29';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const gitSource = file => execFileSync('git', ['show', `${baseline}:${file}`], { cwd: root, encoding: 'utf8' });
const knowledgePath = 'src/OCFoundation/GameKnowledge.luau';
const petsPath = 'src/OCFoundation/PetManager.luau';
const beforeKnowledge = gitSource(knowledgePath);
const beforePets = gitSource(petsPath);
const [afterKnowledge, afterPets] = await Promise.all([
  readFile(path.join(root, knowledgePath), 'utf8'), readFile(path.join(root, petsPath), 'utf8'),
]);
for (const method of ['EnsureChunkerObserver', 'RecordNativeEggUpdate', 'ReleaseChunkerObserver', 'PickupChunker', 'Destroy']) {
  assert.equal(extractFrozenMethod(afterKnowledge, method), extractFrozenMethod(beforeKnowledge, method),
    `Receiver diagnostic work changed native observation/lifecycle: ${method}`);
}
function priceBlock(source) {
  const begin = '\tlocal definitions, stats = c.Knowledge:Get("Eggs"), c.Knowledge:Get("StatsUtil")';
  const finish = '\tlocal coins = raw and raw.Coins';
  assert.equal(source.split(begin).length - 1, 1, 'Native preflight price block missing or duplicated');
  const start = source.indexOf(begin);
  const end = source.indexOf(finish, start);
  assert(end > start, 'Native preflight price boundary missing');
  return source.slice(start, end);
}
assert.equal(priceBlock(afterPets), priceBlock(beforePets), 'Owner-verified native quote implementation changed');
const priceHash = sha256(priceBlock(afterPets));
assert.equal(priceHash, '0546c562df85f9ba22fdb1437f13be9cb5edd08fa5add5d883da2ac0a1a86cea', 'Owner-verified native quote hash changed');
function prepare(source) {
  const signature = 'function PetManager:Prepare(';
  assert.equal(source.split(signature).length - 1, 1, 'Paid hatch/equipment guards missing or duplicated');
  const start = source.indexOf(signature);
  const end = source.indexOf('\nfunction ', start + signature.length);
  assert(end > start, 'Paid guard method boundary missing');
  return source.slice(start, end);
}
assert.equal(prepare(afterPets), prepare(beforePets), 'Receiver diagnostics changed paid price/account/permission guards');
console.log(`[OC TEST] 7 receiver/price preservation areas match ${baseline}; native price SHA256 ${priceHash}`);

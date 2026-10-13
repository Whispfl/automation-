// Actual-source owner-only adapter regression; synthetic account and observations.
import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { bundle, sources } from './bundle.mjs';

const root = path.resolve(import.meta.dirname, '..');
const source = await sources(root);
const mechanics = source.modules.find(module => module.name === 'GameMechanics').source;
const isolated = mechanics.slice(mechanics.indexOf('function GameMechanics:ExecuteOwnerDirectEggTeleportTest('));
assert(isolated.startsWith('function GameMechanics:ExecuteOwnerDirectEggTeleportTest('), 'Isolated adapter is present');
assert.equal((isolated.match(/fresh\.CharacterRoot\.CFrame = directFrame/g) || []).length, 1, 'Exactly one isolated assignment site');
assert(!/\b(?:FireServer|InvokeServer|ResolveStanding|PositionSelectedEgg|Raycast|GetPartBoundsInBox)\b/.test(isolated), 'Isolated direct path contains no transport, ordinary standing adapter or geometry search');
assert(isolated.includes('CFrame.new(position)') && isolated.includes('local position = fresh.TargetRoot.Position'), 'Direct target is the exact current selected physical Root');
assert(isolated.includes('self.OwnerDirectEggTeleportConsumed = true'), 'Attempt consumes before setter, including uncertainty');
assert(!/\b(?:HatchEgg|Equip|BuyWorld|BuyGum|Collect)\b/.test(isolated), 'No unrelated gameplay command in isolated adapter');
const env = (await readFile(path.join(root, 'tests/foundation.luau'), 'utf8')).split('-- BUNDLE INSERTION POINT')[0];
const loaderPath = path.join(root, 'examples/Phase4OwnerDirectEggTeleport.luau');
const loader = await readFile(loaderPath, 'utf8');
const call = loader.indexOf('loadstring(game:HttpGet(');
assert(call >= 0);
const prefix = loader.slice(0, loader.lastIndexOf('\n', call) + 1);
const tests = await readFile(path.join(root, 'tests/phase4-owner-direct-teleport.luau'), 'utf8');
const harness = `${env}
-- Semantic vectors and minimal direct CFrame only; not a Roblox physics engine.
function vectorMeta.__eq(a,b) return a.X==b.X and a.Y==b.Y and a.Z==b.Z end
local builtinTypeof = typeof
local function typeof(value) return type(value)=="table" and value.SyntheticFrame and "CFrame" or builtinTypeof(value) end
local CFrame = { new = function(position)
 return { SyntheticFrame=true, Position=position, RightVector=Vector3.new(1,0,0), UpVector=Vector3.new(0,1,0), LookVector=Vector3.new(0,0,-1) }
end }
services.Players.LocalPlayer = { UserId=10864747620 }
local function ownerDirectOverrides()
${prefix}
return Config
end
${bundle(source).library}
local Defaults, Resolver = requireOC("OCConfig"), requireOC("ConfigResolver")
${tests}
`;
await mkdir(path.join(root, '.test-output'), { recursive: true });
const file = path.join(root, '.test-output/phase4-owner-direct-teleport.luau');
await writeFile(file, harness);
const compiler = process.env.LUAU_COMPILE_BIN || path.join(root, '.tools/luau/luau-compile.exe');
const executable = process.env.LUAU_BIN || path.join(root, '.tools/luau/luau.exe');
const compile = spawnSync(compiler, ['--null', loaderPath, file], { encoding: 'utf8' });
assert.equal(compile.status, 0, compile.stdout + compile.stderr);
const run = spawnSync(executable, [file], { encoding: 'utf8' });
process.stdout.write(run.stdout);
process.stderr.write(run.stderr);
assert.equal(run.status, 0, 'Owner direct actual-source tests must pass');
console.log('[OC OWNER DIRECT] Official Luau compilation PASS; exact owner target/account, one assignment, cancellation, isolated safeguards, zero transport/spending and honest observed range result PASS.');

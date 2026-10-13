import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { sources, bundle } from '../scripts/bundle.mjs';

const root = path.resolve(import.meta.dirname, '..');
const [environment, assertions] = (await readFile(path.join(root, 'tests/foundation.luau'), 'utf8')).split('-- BUNDLE INSERTION POINT');
const standing = await readFile(path.join(root, 'tests/phase4-standing-location.luau'), 'utf8');
const firstTest = standing.indexOf('test("TRAVEL_ONLY center anchor');
assert(firstTest > 0);
const fixture = standing.slice(0, firstTest);
const cases = `
test("Original center and four cardinal winners retain their exact positions and query order", function()
 for _, selectedIndex in ipairs({ 1, 2, 3, 4, 5 }) do
  standingFixture(function(s)
   local coords = { {0,0}, {3.25,0}, {-3.25,0}, {0,3.25}, {0,-3.25} }
   workspace.Raycast = function(_, origin)
    s.Casts += 1
    if s.Casts ~= selectedIndex then return nil end
    return { Instance = s.Floor, Position = Vector3.new(origin.X, 10, origin.Z), Normal = Vector3.new(0, 1, 0) }
   end
   local value = s.Manager:ResolveStanding(s.Record)
   assert(value and s.Casts == selectedIndex and s.Queries == 1)
   assert(value.Position.X == s.Target.Position.X + coords[selectedIndex][1])
   assert(value.Position.Z == s.Target.Position.Z + coords[selectedIndex][2])
   assert(math.abs(value.Position.Y - 13.15) < .001)
  end)
 end
end)
test("Standing search can miss a supported diagonal within the unchanged range", function()
 standingFixture(function(s)
  workspace.Raycast = function(_, origin, _, params)
   s.Casts += 1
   assert(params.RespectCanCollide == true)
   local dx, dz = origin.X - s.Target.Position.X, origin.Z - s.Target.Position.Z
   if math.abs(dx) < 0.05 or math.abs(dz) < 0.05 then return nil end
   return { Instance = s.Floor, Position = Vector3.new(origin.X, 10, origin.Z), Normal = Vector3.new(0, 1, 0) }
  end
  local value, reason = s.Manager:ResolveStanding(s.Record)
  if AUDIT_PROPOSED then
   assert(value and s.Casts == 6 and s.Queries == 1)
   assert(math.abs((value.Position - s.Target.Position).Magnitude - math.sqrt(3.25^2 + 1.15^2)) < .001)
  else
   assert(not value and reason:find("No supported floor", 1, true) and s.Casts == 5 and s.Queries == 0)
  end
 end)
end)
test("All collidable obstructions remain rejected", function()
 standingFixture(function(s)
  s.Blocked = true
  assert(not s.Manager:ResolveStanding(s.Record))
  assert(s.Casts == (AUDIT_PROPOSED and 9 or 5) and s.Queries == s.Casts)
 end)
end)
test("Full bounds elevate an R6-shaped observed lower body despite zero HipHeight", function()
 standingFixture(function(s)
  s.Humanoid.HipHeight = 0
  local bodyFrame = s.Root.CFrame:ToObjectSpace(s.Root.CFrame)
  bodyFrame.Position = s.Root.Position + Vector3.new(0, -1, 0)
  s.Character.GetBoundingBox = function() return bodyFrame, Vector3.new(4, 6, 4) end
  local value = s.Manager:ResolveStanding(s.Record)
  assert(value and math.abs(value.Position.Y - 14.15) < .001)
 end)
end)
test("Tall full-avatar body can legitimately exceed physical range", function()
 standingFixture(function(s)
  local bodyFrame = s.Root.CFrame
  s.Character.GetBoundingBox = function() return bodyFrame, Vector3.new(4, 18, 4) end
  local value, reason = s.Manager:ResolveStanding(s.Record)
  assert(not value and reason:find("No supported floor", 1, true) and s.Queries == 0)
 end)
end)
test("Unanchored support remains rejected", function()
 standingFixture(function(s)
  s.Floor.Anchored = false
  assert(not s.Manager:ResolveStanding(s.Record) and s.Queries == 0)
 end)
end)
test("Slope beyond preserved near-horizontal threshold remains rejected", function()
 standingFixture(function(s)
  workspace.Raycast = function(_, origin)
   s.Casts += 1
   return { Instance = s.Floor, Position = Vector3.new(origin.X, 10, origin.Z), Normal = Vector3.new(0, .979, 0) }
  end
  assert(not s.Manager:ResolveStanding(s.Record) and s.Queries == 0)
 end)
end)
test("No observed standing runtime remains blocked", function()
 standingFixture(function(s)
  workspace.Raycast = nil
  local value, reason = s.Manager:ResolveStanding(s.Record)
  assert(not value and reason:find("runtime unavailable", 1, true))
 end)
end)
print("[OC MOVEMENT AUDIT] " .. (tests - before) .. " geometry audit cases passed; proposed=" .. tostring(AUDIT_PROPOSED))
end
`;
const source = await sources(root);
const exact = '\t\tfor _, offset in ipairs({ Vector3.new(0, 0, 0), Vector3.new(radius, 0, 0), Vector3.new(-radius, 0, 0), Vector3.new(0, 0, radius), Vector3.new(0, 0, -radius) }) do';
const changed = '\t\tlocal diagonal = radius / math.sqrt(2)\n\t\tfor _, offset in ipairs({ Vector3.new(0, 0, 0), Vector3.new(radius, 0, 0), Vector3.new(-radius, 0, 0), Vector3.new(0, 0, radius), Vector3.new(0, 0, -radius),\n\t\t\tVector3.new(diagonal, 0, diagonal), Vector3.new(diagonal, 0, -diagonal), Vector3.new(-diagonal, 0, diagonal), Vector3.new(-diagonal, 0, -diagonal) }) do';
for (const proposed of [false, true]) {
  const auditSource = structuredClone(source);
  if (proposed) {
    const module = auditSource.modules.find(value => value.name === 'EggTravelManager');
    assert.equal(module.source.split(exact).length, 2);
    module.source = module.source.replace(exact, changed);
  }
  const target = path.join(root, `.test-output/movement-standing-audit-${proposed ? 'proposed' : 'released'}.luau`);
  await writeFile(target, environment + bundle(auditSource).library + assertions + `\nlocal AUDIT_PROPOSED = ${proposed}\n` + fixture + cases);
  const compile = spawnSync(path.join(root, '.tools/luau/luau-compile.exe'), ['--null', target], { encoding: 'utf8' });
  assert.equal(compile.status, 0, compile.stdout + compile.stderr);
  const run = spawnSync(path.join(root, '.tools/luau/luau.exe'), [target], { encoding: 'utf8' });
  process.stdout.write(run.stdout);
  process.stderr.write(run.stderr);
  assert.equal(run.status, 0);
}

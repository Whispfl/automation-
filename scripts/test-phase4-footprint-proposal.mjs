// Proposed support guard only: never writes source, bundle, loader or game state.
import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { sources, bundle } from './bundle.mjs';
const root = path.resolve(import.meta.dirname, '..');
const sha = value => createHash('sha256').update(value).digest('hex');
const record = JSON.parse(await readFile(path.join(root, 'docs/PHASE4-UNIVERSAL-MOVEMENT-FOOTPRINT-PROPOSED.json'), 'utf8'));
const patch = await readFile(path.join(root, record.patchPath), 'utf8');
assert.equal(sha(patch), record.patchSha256);
const approvedPatch = await readFile(path.join(root, record.dependency.patchPath), 'utf8');
assert.equal(sha(approvedPatch), record.dependency.patchSha256);
const applyInMemory = (source, patchText) => {
  const lines = patchText.split('\n');
  const start = lines.findIndex(line => line.startsWith('@@ '));
  assert(start > 0 && !lines.slice(start + 1).some(line => line.startsWith('@@ ')), 'Single exact hunk required');
  const hunk = lines.slice(start + 1).filter(line => /^[ +\-]/.test(line));
  const before = hunk.filter(line => line[0] !== '+').map(line => line.slice(1)).join('\n') + '\n';
  const after = hunk.filter(line => line[0] !== '-').map(line => line.slice(1)).join('\n') + '\n';
  assert.equal(source.split(before).length, 2, 'Exact patch preimage occurs once');
  return source.replace(before, after);
};
const [environment, assertions] = (await readFile(path.join(root, 'tests/foundation.luau'), 'utf8')).split('-- BUNDLE INSERTION POINT');
const source = await sources(root);
const module = source.modules.find(value => value.name === 'EggTravelManager');
assert.equal(sha(module.source), record.releasedFileSha256);
const diagonals = applyInMemory(module.source, approvedPatch);
assert.equal(sha(diagonals), record.beforeOverlayFileSha256);
const proposed = applyInMemory(diagonals, patch);
assert.equal(sha(proposed), record.proposedAfterFileSha256);
const cases = `
do
local before = tests
local Travel = requireOC("EggTravelManager")
local function geometry(callback)
 local old = { CFrame=CFrame, RaycastParams=RaycastParams, OverlapParams=OverlapParams, Cast=workspace.Raycast,
  Query=workspace.GetPartBoundsInBox, PartType=Enum.PartType, RaycastFilterType=Enum.RaycastFilterType }
 local function dot(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end
 local meta = {}
 local function frame(p, r, u, l)
  local f = { Position=p, RightVector=r or Vector3.new(1,0,0), UpVector=u or Vector3.new(0,1,0), LookVector=l or Vector3.new(0,0,-1) }
  function f:PointToObjectSpace(v)
   local q=v-self.Position
   return Vector3.new(dot(q,self.RightVector),dot(q,self.UpVector),-dot(q,self.LookVector))
  end
  function f:ToObjectSpace(other)
   return frame(self:PointToObjectSpace(other.Position),
    Vector3.new(dot(other.RightVector,self.RightVector),dot(other.RightVector,self.UpVector),-dot(other.RightVector,self.LookVector)),
    Vector3.new(dot(other.UpVector,self.RightVector),dot(other.UpVector,self.UpVector),-dot(other.UpVector,self.LookVector)),
    Vector3.new(dot(other.LookVector,self.RightVector),dot(other.LookVector,self.UpVector),-dot(other.LookVector,self.LookVector)))
  end
  return setmetatable(f,meta)
 end
 function meta.__mul(a,b)
  local function rotate(v) return a.RightVector*v.X+a.UpVector*v.Y-a.LookVector*v.Z end
  return frame(a.Position+rotate(b.Position),rotate(b.RightVector),rotate(b.UpVector),rotate(b.LookVector))
 end
 local function yaw(p, radians)
  local c,s=math.cos(radians),math.sin(radians)
  return frame(p,Vector3.new(c,0,-s),Vector3.new(0,1,0),Vector3.new(-s,0,-c))
 end
 CFrame={lookAt=function(p,to)
  local l=to-p
  l=l*(1/l.Magnitude)
  return frame(p,Vector3.new(-l.Z,0,l.X),Vector3.new(0,1,0),l)
 end}
 RaycastParams,OverlapParams={new=function() return {} end},{new=function() return {} end}
 Enum.RaycastFilterType,Enum.PartType={Exclude="Exclude"},{Block="Block",Ball="Ball"}
 local ok,reason=xpcall(function()
  local s={Casts=0,Queries=0,AvatarSize=Vector3.new(4,6,4),Offset=Vector3.new(0,0,0),AvatarYaw=0,FloorSize=Vector3.new(30,1,30),FloorYaw=0}
  local function part(p)
   return {Position=p,Parent=true,CanCollide=true,Anchored=true,Shape="Block",Size=Vector3.new(2,2,1),
    IsA=function(_,kind) return kind=="BasePart" or kind=="Part" end,IsDescendantOf=function() return true end}
  end
  s.Character={}
  s.Root=part(Vector3.new(100,13.15,100));s.Root.CFrame=frame(s.Root.Position)
  s.Target=part(Vector3.new(-12,12,-34));s.Target.CanCollide=false
  s.Floor=part(Vector3.new(-12,9.5,-34))
  s.Humanoid={HipHeight=2,MoveDirection=Vector3.new(0,0,0)}
  s.Character.GetBoundingBox=function()
   local body=yaw(s.Root.Position+s.Offset,s.AvatarYaw)
   if s.AvatarRoll then
    local c,t=math.cos(s.AvatarRoll),math.sin(s.AvatarRoll)
    body=body*frame(Vector3.new(0,0,0),Vector3.new(c,t,0),Vector3.new(-t,c,0),Vector3.new(0,0,-1))
   end
   return body,s.AvatarSize
  end
  s.Record={Model={},TargetRoot=s.Target,RangeOrigin=s.Target,Character=s.Character,CharacterRoot=s.Root,
   Humanoid=s.Humanoid,LocationOnly=true,LocationVerified=true,PhysicalRange=6.5,Range=6.5}
  s.Manager=Travel.new({Config=Resolver.Resolve(Defaults,{EGG_TRAVEL_SETTINGS={MODE="TRAVEL_ONLY"}})})
  workspace.Raycast=function(_,origin,_,params)
   s.Casts+=1
   assert(params.RespectCanCollide==true and #params.FilterDescendantsInstances==1)
   s.Floor.Size=s.FloorSize
   s.Floor.CFrame=yaw(s.Floor.Position,s.FloorYaw)
   if s.FloorTilt then
    local c,t=.995,math.sqrt(1-.995^2)
    s.Floor.CFrame=frame(s.Floor.Position,Vector3.new(1,0,0),Vector3.new(0,c,t),Vector3.new(0,t,-c))
   end
   local hit=s.Floor.CFrame:PointToObjectSpace(Vector3.new(origin.X,10,origin.Z))
   if math.abs(hit.X)>s.FloorSize.X/2 or math.abs(hit.Z)>s.FloorSize.Z/2 then return nil end
   if s.SelectedCast and s.Casts<s.SelectedCast then return nil end
   if s.NoCenter and origin.X==s.Target.Position.X and origin.Z==s.Target.Position.Z then return nil end
   return {Instance=s.Floor,Position=Vector3.new(origin.X,10,origin.Z),Normal=s.Floor.CFrame.UpVector}
  end
  workspace.GetPartBoundsInBox=function(_,_,size,params)
   s.Queries+=1
   assert(params.RespectCanCollide==true and params.FilterDescendantsInstances[2]==s.Floor)
   assert(size.X==s.AvatarSize.X+.3 and size.Y==s.AvatarSize.Y+.1 and size.Z==s.AvatarSize.Z+.3)
   return s.Blocked and {{CanCollide=true}} or {}
  end
  callback(s)
 end,debug.traceback)
 CFrame,RaycastParams,OverlapParams=old.CFrame,old.RaycastParams,old.OverlapParams
 workspace.Raycast,workspace.GetPartBoundsInBox=old.Cast,old.Query
 Enum.PartType,Enum.RaycastFilterType=old.PartType,old.RaycastFilterType
 assert(ok,reason)
end
local function unsupported(s)
 local value=s.Manager:ResolveStanding(s.Record)
 assert(SUPPORT_PROPOSED and not value or not SUPPORT_PROPOSED and value,"Unsupported footprint must expose old policy and be rejected by proposed containment")
end
test("Footprint: broad block preserves original center",function()
 geometry(function(s)
  local value=s.Manager:ResolveStanding(s.Record)
  assert(value and value.Position.X==-12 and value.Position.Z==-34 and math.abs(value.Position.Y-13.15)<.001)
  assert(s.Casts==1 and s.Queries==1)
 end)
end)
test("Footprint: all five previously valid winners preserve positions and order",function()
 local coords={{0,0},{3.25,0},{-3.25,0},{0,3.25},{0,-3.25}}
 for i=1,5 do
  geometry(function(s)
   s.SelectedCast=i
   local value=s.Manager:ResolveStanding(s.Record)
   assert(value and s.Casts==i and s.Queries==1)
   assert(value.Position.X==s.Target.Position.X+coords[i][1] and value.Position.Z==s.Target.Position.Z+coords[i][2])
   assert(math.abs(value.Position.Y-13.15)<.001)
  end)
 end
end)
test("Footprint: first approved diagonal retains full support guard",function()
 geometry(function(s)
  s.SelectedCast=6
  local value=s.Manager:ResolveStanding(s.Record)
  assert(value and s.Casts==6 and s.Queries==1)
  local diagonal=3.25/math.sqrt(2)
  assert(math.abs(value.Position.X-s.Target.Position.X-diagonal)<.001 and math.abs(value.Position.Z-s.Target.Position.Z-diagonal)<.001)
 end)
end)
test("Footprint: tiny center slab cannot support full avatar",function()
 geometry(function(s) s.FloorSize=Vector3.new(.2,1,.2);unsupported(s) end)
end)
test("Footprint: edge overhang rejected despite upward center ray",function()
 geometry(function(s) s.FloorSize=Vector3.new(4,1,4);s.Floor.Position=s.Floor.Position+Vector3.new(1.5,0,0);unsupported(s) end)
end)
test("Footprint: large horizontal accessories do not shrink",function()
 geometry(function(s) s.FloorSize=Vector3.new(8,1,8);s.AvatarSize=Vector3.new(20,6,20);unsupported(s) end)
end)
test("Footprint: shifted body support uses actual root-relative center",function()
 geometry(function(s) s.FloorSize=Vector3.new(6,1,6);s.Offset=Vector3.new(7,0,0);unsupported(s) end)
end)
test("Footprint: yaw-rotated avatar corners preserve orientation",function()
 geometry(function(s) s.FloorSize=Vector3.new(5,1,5);s.AvatarYaw=math.pi/4;unsupported(s) end)
end)
test("Footprint: rolled bounds include projected vertical half-extent",function()
 geometry(function(s) s.FloorSize=Vector3.new(4,1,4);s.AvatarRoll=math.pi/4;unsupported(s) end)
end)
test("Footprint: yaw-rotated wide floor remains eligible",function()
 geometry(function(s) s.FloorYaw=math.pi/4;assert(s.Manager:ResolveStanding(s.Record)) end)
end)
test("Footprint: unknown complex floor shape is not corner-proven",function()
 geometry(function(s) s.Floor.IsA=function(_,kind) return kind=="BasePart" or kind=="MeshPart" end;unsupported(s) end)
end)
test("Footprint: round Part is not assumed rectangular",function()
 geometry(function(s) s.Floor.Shape="Ball";unsupported(s) end)
end)
test("Footprint: near-horizontal tilted floor remains unproven",function()
 geometry(function(s) s.FloorTilt=true;unsupported(s) end)
end)
test("Footprint: geometry shrink on final observation loses support",function()
 geometry(function(s)
  local initial=s.Manager:ResolveStanding(s.Record);assert(initial)
  s.FloorSize=Vector3.new(.2,1,.2)
  local fresh=s.Manager:ResolveStanding(s.Record)
  if SUPPORT_PROPOSED then assert(not fresh)
  else assert(fresh and (initial.Position-fresh.Position).Magnitude==0) end
 end)
end)
test("Footprint: existing full-volume obstruction remains blocked",function()
 geometry(function(s) s.Blocked=true;assert(not s.Manager:ResolveStanding(s.Record));assert(s.Queries>0) end)
end)
test("Footprint: finite bounded search keeps at most nine samples",function()
 geometry(function(s) s.FloorSize=Vector3.new(.2,1,.2);s.NoCenter=true;assert(not s.Manager:ResolveStanding(s.Record));assert(s.Casts==9) end)
end)
print("[OC FOOTPRINT PROPOSAL] "..(tests-before).." groups passed; proposed="..tostring(SUPPORT_PROPOSED))
end
`;
for (const variant of ['approved-diagonals-only', 'separate-support-proposal']) {
  const audit = structuredClone(source);
  audit.modules.find(value => value.name === 'EggTravelManager').source = variant === 'approved-diagonals-only' ? diagonals : proposed;
  const target = path.join(root, `.test-output/footprint-proposal-${variant}.luau`);
  await writeFile(target, environment + bundle(audit).library + assertions + `\nlocal SUPPORT_PROPOSED = ${variant === 'separate-support-proposal'}\n` + cases);
  const compile = spawnSync(path.join(root, '.tools/luau/luau-compile.exe'), ['--null', target], {encoding:'utf8'});
  assert.equal(compile.status, 0, compile.stdout + compile.stderr);
  const run = spawnSync(path.join(root, '.tools/luau/luau.exe'), [target], {encoding:'utf8'});
  process.stdout.write(run.stdout);process.stderr.write(run.stderr);assert.equal(run.status, 0);
}
console.log('[OC FOOTPRINT PROPOSAL] Exact patches/hashes verified; both variants only in memory; source/bundle unchanged; no live physics/action');

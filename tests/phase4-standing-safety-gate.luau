-- Synthetic flat bounded parts, complete rigid transforms and OBB intersection.
-- The independent support oracle is deliberately separate from ResolveStanding.
-- It detects footprint support uncertainty; it does not simulate Roblox physics
-- or establish that accessories must touch the floor, nor diagnose owner failure.
local PROPOSED = false
local SUPPORT_GUARD = false
local VARIANT = "released"
local vectorMeta = {}
local Vector3 = {}
function Vector3.new(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, vectorMeta) end
function vectorMeta.__add(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
function vectorMeta.__sub(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
function vectorMeta.__unm(a) return Vector3.new(-a.X, -a.Y, -a.Z) end
function vectorMeta.__mul(a, b) return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
function vectorMeta.__index(a, key) if key == "Magnitude" then return math.sqrt(a.X*a.X + a.Y*a.Y + a.Z*a.Z) end end
local function dot(a, b) return a.X*b.X + a.Y*b.Y + a.Z*b.Z end
local function cross(a, b) return Vector3.new(a.Y*b.Z-a.Z*b.Y, a.Z*b.X-a.X*b.Z, a.X*b.Y-a.Y*b.X) end
local function unit(a) return a * (1 / a.Magnitude) end
local frameMeta = {}
local function frame(position, right, up, back)
 return setmetatable({ Type = "CFrame", Position = position, RightVector = right or Vector3.new(1,0,0),
  UpVector = up or Vector3.new(0,1,0), BackVector = back or Vector3.new(0,0,1), LookVector = -(back or Vector3.new(0,0,1)) }, frameMeta)
end
local function rotate(f, v) return f.RightVector*v.X + f.UpVector*v.Y + f.BackVector*v.Z end
function frameMeta.__mul(a, b) return frame(a.Position + rotate(a, b.Position), rotate(a,b.RightVector), rotate(a,b.UpVector), rotate(a,b.BackVector)) end
function frameMeta.__index(a, key)
 if key == "PointToObjectSpace" then return function(_, point)
  local delta=point-a.Position
  return Vector3.new(dot(delta,a.RightVector),dot(delta,a.UpVector),dot(delta,a.BackVector))
 end end
 if key == "ToObjectSpace" then return function(_, other)
  local function inverse(v) return Vector3.new(dot(v,a.RightVector), dot(v,a.UpVector), dot(v,a.BackVector)) end
  return frame(inverse(other.Position-a.Position), inverse(other.RightVector), inverse(other.UpVector), inverse(other.BackVector))
 end end
end
local function yaw(position, angle) local c,s = math.cos(angle), math.sin(angle) return frame(position, Vector3.new(c,0,-s), Vector3.new(0,1,0), Vector3.new(s,0,c)) end
local CFrame = { lookAt = function(position, destination)
 local back = -unit(destination-position)
 local right = unit(cross(Vector3.new(0,1,0),back))
 return frame(position,right,cross(back,right),back)
end }
local function typeof(value) return type(value) == "table" and value.Type or type(value) end
local RaycastParams, OverlapParams = { new = function() return {} end }, { new = function() return {} end }
local Enum = { RaycastFilterType = { Exclude = "Exclude" }, PartType = { Block = "Block", Ball = "Ball", Cylinder = "Cylinder" } }
local workspace = {}
local game = { GetService = function() return {} end }
-- ACTUAL SOURCE BUNDLE INSERTION
local Travel, Mechanics = requireOC("EggTravelManager"), requireOC("GameMechanics")
local detected, checked = 0, 0
local function test(name, callback) callback() checked += 1 print("[OC SAFETY GATE] " .. name) end
local function part(name, className)
 local kindName=className or "Part"
 return { Name = name, Parent = workspace, Anchored = true, CanCollide = true,
  Shape=Enum.PartType.Block, Size=Vector3.new(2,2,1), CFrame=frame(Vector3.new(0,0,0)),
  IsA = function(_, kind) return kind == kindName or kind == "BasePart" and kindName ~= "Terrain" end,
  IsDescendantOf = function() return true end }
end
local function boxCorners(f, size)
 local result = {}
 for _, x in ipairs({-1,1}) do for _, y in ipairs({-1,1}) do for _, z in ipairs({-1,1}) do
  table.insert(result, f.Position + rotate(f, Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2)))
 end end end
 return result
end
local function boxesIntersect(af, asize, bf, bsize)
 local aa,ba = {af.RightVector,af.UpVector,af.BackVector}, {bf.RightVector,bf.UpVector,bf.BackVector}
 local axes = table.clone(aa) for _, a in ipairs(ba) do table.insert(axes,a) end
 for _, a in ipairs(aa) do for _, b in ipairs(ba) do local axis = cross(a,b) if axis.Magnitude > 1e-8 then table.insert(axes,unit(axis)) end end end
 local ah,bh = {asize.X/2,asize.Y/2,asize.Z/2},{bsize.X/2,bsize.Y/2,bsize.Z/2}
 for _, axis in ipairs(axes) do
  local ar,br = 0,0 for i=1,3 do ar += math.abs(dot(aa[i],axis))*ah[i] br += math.abs(dot(ba[i],axis))*bh[i] end
  if math.abs(dot(bf.Position-af.Position,axis)) > ar+br then return false end
 end return true
end
local function fixture()
 local s = { Casts = 0, Queries = 0, Assignments = 0, Floors = {}, Obstacles = {} }
 s.Character = {}
 s.Root = part("HumanoidRootPart") s.Root.Parent = s.Character
 s.Root.Position, s.Root.Size = Vector3.new(83,13.15,0), Vector3.new(2,2,1)
 s.Root.CFrame = frame(s.Root.Position)
 s.Offset, s.BodySize = frame(Vector3.new(0,0,0)), Vector3.new(4,6,4)
 s.Character.GetBoundingBox = function() return s.Root.CFrame*s.Offset, s.BodySize end
 s.Humanoid = { HipHeight = 2, MoveDirection = Vector3.new(0,0,0) }
 s.Target = part("Root") s.Target.Position = Vector3.new(0,12,0)
 s.Model = { Name = "Common Egg", Parent = workspace }
 s.Record = { Model = s.Model, TargetRoot = s.Target, RangeOrigin = s.Target, LocationOnly = true, LocationVerified = true,
  Range = 6.5, PhysicalRange = 6.5, Character = s.Character, CharacterRoot = s.Root, Humanoid = s.Humanoid,
  NeedsNativeTravel = false, InRange = false, LeaseId = 1 }
 s.Controller = { Config = { EGG_TRAVEL_SETTINGS = { MODE = "TRAVEL_ONLY", ENABLE_DIRECT_POSITIONING = true } }, State = "RUNNING", Generation = 1 }
 s.Manager = Travel.new(s.Controller)
 s.Controller.EggTravel = s.Manager
 s.Token = { CheckCancelled = function() return false end }
 s.Controller.Scheduler = { Active = { Definition = { Owner = "EGG_TRAVEL", Generation = 1 }, Token = s.Token } }
 s.Mechanics = setmetatable({ Config = s.Controller.Config, LocalFeatureController = s.Controller, LocalFeatureGuard = function() return true end }, Mechanics)
 s.Manager.Validate = function() return s.Record end
 function s:AddFloor(xmin,xmax,zmin,zmax,holes,className)
  local f = part("Support",className or holes and "MeshPart" or "Part") f.Y=10 f.XMin=xmin f.XMax=xmax f.ZMin=zmin f.ZMax=zmax f.Holes=holes or {}
  f.Size=Vector3.new(xmax-xmin,1,zmax-zmin)
  f.CFrame=frame(Vector3.new((xmin+xmax)/2,9.5,(zmin+zmax)/2))
  table.insert(self.Floors,f) return f
 end
 function s:UpdateFloor(f)
  f.Size=Vector3.new(f.XMax-f.XMin,1,f.ZMax-f.ZMin)
  f.CFrame=frame(Vector3.new((f.XMin+f.XMax)/2,f.Y-.5,(f.ZMin+f.ZMax)/2))
 end
 function s:Supported(x,z)
  for _,f in ipairs(self.Floors) do
   if f.Parent and f.CanCollide and f.Anchored and x >= f.XMin and x <= f.XMax and z >= f.ZMin and z <= f.ZMax then
    local hole = false for _,h in ipairs(f.Holes) do if x >= h[1] and x <= h[2] and z >= h[3] and z <= h[4] then hole = true end end
    if not hole then return f end
   end
  end return nil
 end
 function s:FootprintSupported(value)
  if not value then return false end
  for _,corner in ipairs(boxCorners(value*self.Offset,self.BodySize)) do if not self:Supported(corner.X,corner.Z) then return false end end
  return true -- sufficient only for these convex rectangles without internal holes
 end
 function s:BothSoleCentersSupported(value)
  -- Synthetic two-foot character: even the two sole-center contacts, not only
  -- the conservative whole-avatar projection, must have observed support here.
  for _,x in ipairs({-.7,.7}) do
   local sole=value.Position+rotate(value,Vector3.new(x,-3,0))
   if not self:Supported(sole.X,sole.Z) then return false end
  end return true
 end
 workspace.Raycast = function(_, origin, direction, params)
  s.Casts += 1 assert(direction.X == 0 and direction.Z == 0 and direction.Y < 0)
  assert(params.RespectCanCollide and #params.FilterDescendantsInstances == 1 and params.FilterDescendantsInstances[1] == s.Character)
  local f = s:Supported(origin.X,origin.Z)
  if f and f.Y <= origin.Y and f.Y >= origin.Y+direction.Y then
   s:UpdateFloor(f)
   if s.FloorFrameOverride then f.CFrame=s.FloorFrameOverride end
   return { Instance=f, Position=Vector3.new(origin.X,f.Y,origin.Z), Normal=s.FloorNormal or Vector3.new(0,1,0) }
  end
  return nil
 end
 workspace.GetPartBoundsInBox = function(_, value, size, params)
  s.Queries += 1 assert(params.RespectCanCollide and params.FilterDescendantsInstances[1] == s.Character)
  s.LastQueryFrame,s.LastQuerySize = value,size
  local result = {} for _,o in ipairs(s.Obstacles) do if o.CanCollide and boxesIntersect(value,size,o.Frame,o.Size) then table.insert(result,o) end end
  return result
 end
 return s
end
local function knownUnsupported(s, message)
 local value = s.Manager:ResolveStanding(s.Record)
 if SUPPORT_GUARD then
  assert(not value,"Approved support guard must reject: "..message)
  print("[UNSAFE CASE REJECTED] "..message)
  return nil
 end
 assert(value, "Expected existing resolver acceptance: " .. message)
 assert(not s:FootprintSupported(value), "Independent support oracle must expose unsupported projected avatar bounds")
 detected += 1
 print("[KNOWN FAULT DETECTED] " .. message .. "; resolver returned frame while footprint support was absent; proposed=" .. tostring(PROPOSED))
 return value
end
test("Rigid transform multiplication and inverse preserve shifted/rotated body offsets",function()
 local a=yaw(Vector3.new(7,2,-3),math.pi/3) local b=yaw(Vector3.new(2,-1,4),math.pi/4)
 local relative=a:ToObjectSpace(a*b)
 assert((relative.Position-b.Position).Magnitude < 1e-8 and (relative.RightVector-b.RightVector).Magnitude < 1e-8)
 assert(((a*b).Position-(a.Position+b.Position)).Magnitude > 1, "Test must actually rotate translations")
end)
test("Broad support retains released center winner and complete avatar clearance",function()
 local s=fixture() s:AddFloor(-20,20,-20,20)
 local value=s.Manager:ResolveStanding(s.Record)
 assert(value and s:FootprintSupported(value) and s.Casts==1 and s.Queries==1)
 assert(value.Position.X==0 and value.Position.Z==0 and math.abs(value.Position.Y-13.15)<1e-8)
end)
test("Bounded ledge does not prove whole-footprint support",function()
 local s=fixture() s:AddFloor(-.4,.4,-.4,.4) local value=knownUnsupported(s,"0.8 by 0.8 floor beneath 4 by 4 projected avatar")
 if value then assert(not s:BothSoleCentersSupported(value),"Neither synthetic foot sole center has support on this root-center-only ledge") end
end)
test("Floor hole away from center remains unknown to the single ray",function()
 local s=fixture() s:AddFloor(-20,20,-20,20,{{-2.1,-1.9,-2.1,-1.9}}) knownUnsupported(s,"one projected avatar corner is over a physical hole")
end)
test("Shifted observed body bounds are transformed and can overhang support",function()
 local s=fixture() s.Offset=frame(Vector3.new(1,0,0)) s:AddFloor(-2.1,2.1,-2.1,2.1)
 local value=knownUnsupported(s,"shifted 4 by 4 avatar bound extends past floor edge")
 if value then assert((s.LastQueryFrame.Position-(value*s.Offset).Position).Magnitude<1e-8)
  assert(math.abs(s.LastQueryFrame.Position.X)>0.9) else assert(s.Queries==0) end
end)
test("Rotated body bounds use full rigid transform and can cross an edge",function()
 local s=fixture() s.Offset=yaw(Vector3.new(0,0,0),math.pi/4) s.BodySize=Vector3.new(4,6,2) s:AddFloor(-2.05,2.05,-2.05,2.05)
 local value=knownUnsupported(s,"45-degree rectangular body projection extends beyond 4.1 by 4.1 floor")
 if value then assert((s.LastQueryFrame.RightVector-(value*s.Offset).RightVector).Magnitude<1e-8) else assert(s.Queries==0) end
end)
test("Large accessory bound is included in clearance but supplies no support proof",function()
 local s=fixture() s.BodySize=Vector3.new(10,6,4) s:AddFloor(-2.1,2.1,-2.1,2.1)
 knownUnsupported(s,"10-stud full accessory bound over 4.2-stud floor; physical falling outcome unproven")
 if SUPPORT_GUARD then assert(s.Queries==0) else assert(s.LastQuerySize.X==10.3) end
end)
test("Real collidable obstruction of rotated/shifted full box remains blocked",function()
 local s=fixture() s.Offset=yaw(Vector3.new(1,0,0),math.pi/4) s:AddFloor(-20,20,-20,20)
 local obstruction=part("Wall") obstruction.Frame=frame(Vector3.new(0,13.15,0)) obstruction.Size=Vector3.new(20,10,20) s.Obstacles={obstruction}
 assert(not s.Manager:ResolveStanding(s.Record) and s.Casts==(PROPOSED and 9 or 5))
end)
test("Diagonal-only narrow platform creates newly accepted unsupported candidate",function()
 local s=fixture() local d=3.25/math.sqrt(2) s:AddFloor(d-.4,d+.4,d-.4,d+.4)
 local value=s.Manager:ResolveStanding(s.Record)
 if SUPPORT_GUARD then assert(not value and s.Casts==9 and s.Queries==0)
 elseif PROPOSED then assert(value and not s:FootprintSupported(value) and not s:BothSoleCentersSupported(value) and s.Casts==6) detected+=1 print("[KNOWN FAULT DETECTED] Approved diagonal adds narrow-platform acceptance without either synthetic sole-center support after released variant blocked")
 else assert(not value and s.Casts==5) end
end)
test("Disappeared floor between initial and adapter re-observation blocks assignment",function()
 local s=fixture() local f=s:AddFloor(-20,20,-20,20) local initial=s.Manager:ResolveStanding(s.Record)
 f.Parent=nil local ok,reason=s.Mechanics:PositionSelectedEgg(s.Manager,s.Record,initial,s.Token)
 assert(not ok and reason:find("No supported floor",1,true) and s.Root.CFrame.Position.X==83)
end)
test("Changed elevation between initial and adapter re-observation blocks assignment",function()
 local s=fixture() local f=s:AddFloor(-20,20,-20,20) local initial=s.Manager:ResolveStanding(s.Record)
 f.Y=11 local ok,reason=s.Mechanics:PositionSelectedEgg(s.Manager,s.Record,initial,s.Token)
 assert(not ok and reason:find("Standing geometry changed",1,true) and s.Root.CFrame.Position.X==83)
end)
test("Shrinking floor with same center and elevation is rejected by combined adapter re-observation",function()
 local s=fixture() local f=s:AddFloor(-20,20,-20,20) local initial=s.Manager:ResolveStanding(s.Record)
 assert(s:FootprintSupported(initial)) f.XMin=-.4 f.XMax=.4 f.ZMin=-.4 f.ZMax=.4
 local ok=s.Mechanics:PositionSelectedEgg(s.Manager,s.Record,initial,s.Token)
 if SUPPORT_GUARD then assert(not ok and s.Root.CFrame.Position.X==83 and not s.Mechanics.LastEggPositionLease)
 else assert(ok and s.Root.CFrame.Position.X==0 and not s:FootprintSupported(s.Root.CFrame))
  detected+=1 print("[KNOWN FAULT DETECTED] Same-height footprint loss passes historical adapter recheck") end
end)
test("Geometry disappears after final standing check before final Validate returns",function()
 local s=fixture() local f=s:AddFloor(-20,20,-20,20) local initial=s.Manager:ResolveStanding(s.Record)
 local calls=0 s.Manager.Validate=function() calls+=1 if calls==3 then f.Parent=nil end return s.Record end
 local ok=s.Mechanics:PositionSelectedEgg(s.Manager,s.Record,initial,s.Token)
 assert(ok and calls==3 and s.Root.CFrame.Position.X==0 and not s:FootprintSupported(s.Root.CFrame))
 detected+=1 print("[KNOWN FAULT DETECTED] Synthetic floor loss after adapter standing recheck is not re-observed by final identity Validate; no live cause inferred; variant="..VARIANT)
end)
test("Five original samples retain exact order and coordinates on supported observations",function()
 local coords={{0,0},{3.25,0},{-3.25,0},{0,3.25},{0,-3.25}}
 for selected=1,5 do
  local s=fixture() s:AddFloor(-20,20,-20,20)
  local original=workspace.Raycast
  workspace.Raycast=function(...) if s.Casts<selected-1 then s.Casts+=1 return nil end return original(...) end
  local value=s.Manager:ResolveStanding(s.Record)
  assert(value and s.Casts==selected and value.Position.X==coords[selected][1] and value.Position.Z==coords[selected][2])
 end
end)
test("Every appended diagonal has the existing radius and bounded query order",function()
 if not PROPOSED then return end
 local d=3.25/math.sqrt(2) local points={{d,d},{d,-d},{-d,d},{-d,-d}}
 for i=1,4 do
  local s=fixture() s:AddFloor(-20,20,-20,20) local original=workspace.Raycast
  workspace.Raycast=function(...) if s.Casts<i+4 then s.Casts+=1 return nil end return original(...) end
  local value=s.Manager:ResolveStanding(s.Record)
  assert(value and s.Casts==i+5 and math.abs(value.Position.X-points[i][1])<1e-8 and math.abs(value.Position.Z-points[i][2])<1e-8)
  assert(math.abs(math.sqrt(value.Position.X^2+value.Position.Z^2)-3.25)<1e-8)
 end
end)
test("Terrain MeshPart UnionOperation and nonblock floors fail closed",function()
 if not SUPPORT_GUARD then return end
 for _,kind in ipairs({"Terrain","MeshPart","UnionOperation"}) do
  local s=fixture() s:AddFloor(-20,20,-20,20,nil,kind)
  assert(not s.Manager:ResolveStanding(s.Record) and s.Queries==0)
 end
 for _,shape in ipairs({Enum.PartType.Ball,Enum.PartType.Cylinder}) do
  local s=fixture() local f=s:AddFloor(-20,20,-20,20) f.Shape=shape
  assert(not s.Manager:ResolveStanding(s.Record) and s.Queries==0)
 end
end)
test("Several individually insufficient support pieces do not become one certified face",function()
 local s=fixture() s:AddFloor(-2.5,0.01,-2.5,2.5) s:AddFloor(-0.01,2.5,-2.5,2.5)
 if SUPPORT_GUARD then assert(not s.Manager:ResolveStanding(s.Record)) else assert(s.Manager:ResolveStanding(s.Record)) end
end)
test("Rolled observed bounds include projected vertical extent",function()
 local s=fixture() local c,t=math.cos(math.pi/4),math.sin(math.pi/4)
 s.Offset=frame(Vector3.new(0,0,0),Vector3.new(c,t,0),Vector3.new(-t,c,0),Vector3.new(0,0,1))
 s:AddFloor(-2.1,2.1,-2.1,2.1)
 knownUnsupported(s,"rolled body projection extends beyond narrow floor")
end)
test("Large shifted and rotated accessories remain acceptable only on broad support",function()
 local s=fixture() s.Offset=yaw(Vector3.new(1,0,0),math.pi/4) s.BodySize=Vector3.new(10,6,4) s:AddFloor(-20,20,-20,20)
 local value=s.Manager:ResolveStanding(s.Record)
 assert(value and s:FootprintSupported(value) and s.LastQuerySize.X==10.3 and s.LastQuerySize.Z==4.3)
end)
test("Padded footprint requires the approved 0.15-stud additional edge margin",function()
 if not SUPPORT_GUARD then return end
 local s=fixture() s:AddFloor(-2.299,2.299,-2.299,2.299)
 assert(not s.Manager:ResolveStanding(s.Record) and s.Queries==0)
 s=fixture() s:AddFloor(-2.301,2.301,-2.301,2.301)
 assert(s.Manager:ResolveStanding(s.Record) and s.Casts==1 and s.Queries==1)
end)
test("Near-level tilted support and incorrect top-plane observations fail closed",function()
 if not SUPPORT_GUARD then return end
 local s=fixture() s:AddFloor(-20,20,-20,20)
 local c,t=.995,math.sqrt(1-.995^2)
 s.FloorFrameOverride=frame(Vector3.new(0,9.5,0),Vector3.new(1,0,0),Vector3.new(0,c,t),Vector3.new(0,-t,c))
 s.FloorNormal=Vector3.new(0,c,t)
 assert(not s.Manager:ResolveStanding(s.Record) and s.Queries==0)
 s=fixture() s:AddFloor(-20,20,-20,20) s.FloorFrameOverride=frame(Vector3.new(0,8.5,0))
 assert(not s.Manager:ResolveStanding(s.Record) and s.Queries==0)
end)
test("Existing adapter keeps one lease assignment and rejects a repeated dispatch",function()
 local s=fixture() s:AddFloor(-20,20,-20,20) local initial=s.Manager:ResolveStanding(s.Record)
 assert(s.Mechanics:PositionSelectedEgg(s.Manager,s.Record,initial,s.Token))
 local moved=s.Root.CFrame
 local ok,reason=s.Mechanics:PositionSelectedEgg(s.Manager,s.Record,initial,s.Token)
 assert(not ok and reason:find("already attempted",1,true) and s.Root.CFrame==moved and s.Mechanics.LastEggPositionLease==1)
end)
print("[OC SAFETY GATE] " .. checked .. " audit groups matched; " .. detected .. " known safety-proof gaps detected; variant=" .. VARIANT .. "; NOT live physics acceptance")
if SUPPORT_GUARD then print("[OC SAFETY GATE] POST_FINAL_STANDING_MUTATION_REMAINS_UNGUARDED; REQUIRED_GATE=FAIL") end

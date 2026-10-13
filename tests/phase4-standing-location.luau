do
-- Real standing resolver with synthetic ray/overlap observations. These tests
-- demonstrate policy and geometry checks, not live character movement.
local before = tests
local Travel = requireOC("EggTravelManager")

local function standingFixture(callback)
	local oldCFrame, oldRay, oldOverlap, oldEnum, oldPartType = CFrame, RaycastParams, OverlapParams, Enum.RaycastFilterType, Enum.PartType
	local oldCast, oldQuery = workspace.Raycast, workspace.GetPartBoundsInBox
	local meta = {}
	local function frame(position, facing)
		local value = { Position = position, RightVector = Vector3.new(1, 0, 0), UpVector = Vector3.new(0, 1, 0),
			LookVector = facing or Vector3.new(-1, 0, 0) }
		function value:ToObjectSpace(other) return frame(other.Position - self.Position) end
		function value:PointToObjectSpace(point) return point - self.Position end -- This fixture's support block is axis-aligned.
		return setmetatable(value, meta)
	end
	function meta.__mul(a, b) return frame(a.Position + b.Position, a.LookVector) end
	CFrame = { lookAt = function(position, destination)
		local direction = destination - position
		assert(direction.Magnitude > 0.05, "Center standing orientation must not look at the same point")
		return frame(position, direction * (1 / direction.Magnitude))
	end }
	RaycastParams, OverlapParams = { new = function() return {} end }, { new = function() return {} end }
	Enum.RaycastFilterType = { Exclude = "Exclude" }
	Enum.PartType = { Block = "Block" }
	local ok, reason = xpcall(function()
		local s = { Character = {}, Casts = 0, Queries = 0 }
		local function part(position, collidable, parent)
			return { Position = position, Parent = parent or true, CanCollide = collidable, Anchored = true,
				Shape = Enum.PartType.Block, IsA = function(_, kind) return kind == "BasePart" or kind == "Part" end, IsDescendantOf = function() return true end }
		end
		s.Root = part(Vector3.new(100, 13.15, 100), true, s.Character)
		s.Root.Size, s.Root.CFrame = Vector3.new(2, 2, 1), frame(s.Root.Position)
		s.Humanoid = { HipHeight = 2, MoveDirection = Vector3.new(0, 0, 0) }
		s.Character.GetBoundingBox = function() return frame(s.Root.Position), Vector3.new(4, 6, 4) end
		s.Rendered = { Name = "Rendered", Parent = workspace }
		s.Model = { Name = "Common Egg", Parent = { Name = "Chunker", Parent = s.Rendered } }
		s.Target = part(Vector3.new(-12, 12, -34), false, s.Model)
		s.Floor = part(Vector3.new(-12, 9.5, -34), true, s.Model)
		s.Floor.Size, s.Floor.CFrame = Vector3.new(40, 1, 40), frame(s.Floor.Position, Vector3.new(0, 0, -1))
		s.Visual = part(Vector3.new(-12, 13, -34), false, { Name = "Generic", Parent = s.Rendered })
		s.Solid = part(Vector3.new(-12, 13, -34), true)
		s.Record = { Model = s.Model, TargetRoot = s.Target, RangeOrigin = s.Target,
			RangeOriginPosition = s.Target.Position, Character = s.Character, CharacterRoot = s.Root, Humanoid = s.Humanoid,
			LocationOnly = true, LocationVerified = true, PhysicalRange = 6.5, Range = 6.5 }
		s.Manager = Travel.new({ Config = Resolver.Resolve(Defaults, { EGG_TRAVEL_SETTINGS = { MODE = "TRAVEL_ONLY" } }) })
		workspace.Raycast = function(_, origin, _direction, params)
			s.Casts += 1
			assert(#params.FilterDescendantsInstances == 1 and params.FilterDescendantsInstances[1] == s.Character,
				"Collidable egg platforms and Rendered geometry must remain observable")
			assert(params.RespectCanCollide == true)
			if s.NoCenterFloor and origin.X == s.Target.Position.X and origin.Z == s.Target.Position.Z then return nil end
			return { Instance = s.Floor, Position = Vector3.new(origin.X, 10, origin.Z), Normal = Vector3.new(0, 1, 0) }
		end
		workspace.GetPartBoundsInBox = function(_, _frame, size, params)
			s.Queries += 1
			assert(#params.FilterDescendantsInstances == 2 and params.FilterDescendantsInstances[1] == s.Character
				and params.FilterDescendantsInstances[2] == s.Floor, "Only avatar and observed support floor are excluded")
			assert(params.RespectCanCollide == true and size.X >= 4 and size.Y > 6 and size.Z >= 4)
			return s.Blocked and { s.Solid, s.Visual } or { s.Visual }
		end
		callback(s)
	end, debug.traceback)
	CFrame, RaycastParams, OverlapParams, Enum.RaycastFilterType = oldCFrame, oldRay, oldOverlap, oldEnum
	Enum.PartType = oldPartType
	workspace.Raycast, workspace.GetPartBoundsInBox = oldCast, oldQuery
	assert(ok, reason)
end

test("TRAVEL_ONLY center anchor permits noncollidable visible egg overlap and finite upright facing", function()
	standingFixture(function(s)
		local standing = s.Manager:ResolveStanding(s.Record)
		assert(standing and standing.Position.X == -12 and standing.Position.Z == -34 and math.abs(standing.Position.Y - 13.15) < 0.001)
		assert(s.Casts == 1 and s.Queries == 1, "Center must be tried before outside offsets")
		assert(standing.LookVector.X == -1 and standing.LookVector.Y == 0 and standing.LookVector.Z == 0)
		assert(s.Manager:RangeEligibleAt(s.Record, standing.Position))
	end)
end)

test("TRAVEL_ONLY real collidable avatar obstruction rejects center and every fallback", function()
	standingFixture(function(s)
		s.Blocked = true
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(not standing and reason:find("No supported floor", 1, true) and s.Casts == 9 and s.Queries == 9)
	end)
end)

test("TRAVEL_ONLY support inside rendered egg model is not excluded by name or parent", function()
	for _, folder in ipairs({ "Chunker", "Generic" }) do
		standingFixture(function(s)
			s.Model.Parent.Name, s.Floor.Name = folder, "Common Egg"
			assert(s.Manager:ResolveStanding(s.Record), "Actual anchored collidable platform remains a standing support")
			assert(s.Casts == 1 and s.Queries == 1)
		end)
	end
end)

test("TRAVEL_ONLY offset fallback remains available only after unsupported center geometry", function()
	standingFixture(function(s)
		s.NoCenterFloor = true
		local standing = s.Manager:ResolveStanding(s.Record)
		assert(standing and standing.Position.X == -12 + 3.25 and standing.Position.Z == -34)
		assert(s.Casts == 2 and s.Queries == 1)
	end)
end)

print("[OC TEST] " .. (tests - before) .. " physical standing location regressions passed; live arrival remains owner pending")
end

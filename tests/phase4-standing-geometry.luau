do
-- Real standing resolver over finite ray intervals, actual body-part geometry,
-- and synthetic collision observations. These do not certify live gameplay.
local before = tests
local Travel = requireOC("EggTravelManager")

local function standingGeometryFixture(callback)
	local oldCFrame, oldRay, oldOverlap, oldEnum = CFrame, RaycastParams, OverlapParams, Enum.RaycastFilterType
	local oldCast, oldQuery = workspace.Raycast, workspace.GetPartBoundsInBox
	local oldTypeof = typeof
	local meta = {}
	local function frame(position)
		local value = { SyntheticStandingFrame = true, Position = position,
			RightVector = Vector3.new(1, 0, 0), UpVector = Vector3.new(0, 1, 0), LookVector = Vector3.new(0, 0, -1) }
		function value:ToObjectSpace(other) return frame(other.Position - self.Position) end
		function value:PointToObjectSpace(point) return point - self.Position end
		function value:PointToWorldSpace(point) return point + self.Position end
		function value:VectorToWorldSpace(direction) return direction end
		return setmetatable(value, meta)
	end
	function meta.__mul(a, b) return frame(a.Position + b.Position) end
	CFrame = { new = function(a, b, c) return frame(type(a) == "number" and Vector3.new(a, b, c) or a) end,
		lookAt = function(position, destination)
			assert((destination - position).Magnitude > 0.05)
			return frame(position)
		end }
	typeof = function(value) return type(value) == "table" and value.SyntheticStandingFrame and "CFrame" or oldTypeof(value) end
	RaycastParams, OverlapParams = { new = function() return {} end }, { new = function() return {} end }
	Enum.RaycastFilterType = { Exclude = "Exclude" }
	local ok, failure = xpcall(function()
		local s = { Character = { Name = "SyntheticCharacter", Parent = workspace }, BodyParts = {}, Extras = {},
			Logs = {}, Casts = {}, Queries = {}, FloorY = 0, Normal = Vector3.new(0, 1, 0), Assignments = 0 }
		function s.Character:IsA(kind) return kind == "Model" end
		local function part(name, position, size, parent, collidable)
			local value = { Name = name, Position = position, Size = size, CFrame = frame(position), Parent = parent,
				CanCollide = collidable == true, CanQuery = true, Anchored = true, CollisionGroup = "Default",
				AssemblyLinearVelocity = Vector3.new(0, 0, 0), AssemblyAngularVelocity = Vector3.new(0, 0, 0) }
			function value:IsA(kind) return kind == "BasePart" or kind == "Part" end
			function value:IsDescendantOf(ancestor)
				if ancestor == workspace then return self.Parent ~= nil end
				local current = self.Parent
				while type(current) == "table" do if current == ancestor then return true end current = current.Parent end
				return false
			end
			function value:GetFullName() return "Workspace." .. (parent == s.Character and "SyntheticCharacter." or "Geometry.") .. name end
			function value:GetAttribute() return nil end
			function value:FindFirstAncestorOfClass(kind)
				local current = self.Parent
				while type(current) == "table" do if current.IsA and current:IsA(kind) then return current end current = current.Parent end
				return nil
			end
			return value
		end
		s.Part = part
		s.CurrentFrame = frame(Vector3.new(50, 3.15, 50))
		s.Root = part("HumanoidRootPart", s.CurrentFrame.Position, Vector3.new(2, 2, 1), s.Character, false)
		s.Root.CFrame = nil
		setmetatable(s.Root, { __index = function(_, key) if key == "CFrame" then return s.CurrentFrame end end,
			__newindex = function(_, key, value)
				assert(key == "CFrame") s.Assignments += 1
				if s.AssignmentError then error("Synthetic geometry destination assignment failed") end
				local delta = value.Position - s.Root.Position
				for _, bodyPart in ipairs(s.BodyParts) do
					if bodyPart ~= s.Root then bodyPart.Position += delta bodyPart.CFrame.Position += delta end
				end
				s.CurrentFrame, s.Root.Position = value, value.Position
			end })
		table.insert(s.BodyParts, s.Root)
		-- A compact supported body volume is explicit rather than inferred from
		-- an unbounded Model:GetBoundingBox that includes cosmetic descendants.
		table.insert(s.BodyParts, part("Torso", s.Root.Position, Vector3.new(4, 6, 4), s.Character, true))
		table.insert(s.BodyParts, part("Head", s.Root.Position + Vector3.new(0, 2.5, 0), Vector3.new(2, 1, 2), s.Character, true))
		table.insert(s.BodyParts, part("Left Arm", s.Root.Position + Vector3.new(-1.5, 0, 0), Vector3.new(1, 2, 1), s.Character, false))
		table.insert(s.BodyParts, part("Right Arm", s.Root.Position + Vector3.new(1.5, 0, 0), Vector3.new(1, 2, 1), s.Character, false))
		table.insert(s.BodyParts, part("Left Leg", s.Root.Position + Vector3.new(-0.5, -2, 0), Vector3.new(1, 2, 1), s.Character, false))
		table.insert(s.BodyParts, part("Right Leg", s.Root.Position + Vector3.new(0.5, -2, 0), Vector3.new(1, 2, 1), s.Character, false))
		s.Humanoid = { HipHeight = 2, MoveDirection = Vector3.new(0, 0, 0), RigType = "R6" }
		function s.Character:GetChildren()
			local result = table.clone(s.BodyParts)
			for _, value in ipairs(s.Extras) do if value.Parent == self then table.insert(result, value) end end
			return result
		end
		function s.Character:GetDescendants()
			local result = table.clone(s.BodyParts)
			for _, value in ipairs(s.Extras) do table.insert(result, value) end
			return result
		end
		function s.Character:FindFirstChild(name)
			for _, value in ipairs(self:GetChildren()) do if value.Name == name then return value end end
			return nil
		end
		function s.Character:GetBoundingBox() return frame(s.Root.Position + (s.BoundsOffset or Vector3.new(0, 0, 0))), s.BoundsSize or Vector3.new(4, 6, 4) end
		s.Rendered = { Name = "Rendered", Parent = workspace }
		s.Model = { Name = "Common Egg", Parent = { Name = "Chunker", Parent = s.Rendered },
			GetFullName = function() return "Workspace.Rendered.Chunker.Common Egg" end }
		s.Target = part("Root", Vector3.new(-10.2552786, 7.7361164, -79.8115845), Vector3.new(1, 1, 1), s.Model, false)
		s.Prompt = part("Prompt", s.Target.Position + Vector3.new(2.5, 1.4, 0), Vector3.new(1, 1, 1), s.Model, false)
		s.Floor = part("ObservedFloor", Vector3.new(s.Target.Position.X, -1, s.Target.Position.Z), Vector3.new(20, 2, 20), workspace, true)
		s.Floor.AssemblyRootPart = s.Floor
		function s:SetFloorY(height)
			self.FloorY = height
			self.Floor.Position = Vector3.new(self.Target.Position.X, height - self.Floor.Size.Y / 2, self.Target.Position.Z)
			self.Floor.CFrame = frame(self.Floor.Position)
		end
		s.Visual = part("VisualEgg", s.Target.Position, Vector3.new(30, 30, 30), { Name = "Generic", Parent = s.Rendered }, false)
		s.Obstacle = part("SolidCeiling", s.Target.Position, Vector3.new(20, 20, 20), workspace, true)
		s.Record = { Model = s.Model, EggName = "Common Egg", IdentityId = "I0020", TargetRoot = s.Target, PromptPart = s.Prompt,
			RangeOrigin = s.Target, RangeOriginPosition = s.Target.Position, TargetPosition = s.Target.Position,
			Character = s.Character, CharacterRoot = s.Root, Humanoid = s.Humanoid,
			LocationOnly = true, LocationVerified = true, PhysicalRange = 6.5, Range = 6.5, World = "The Overworld", Generation = 1,
			Distance = (s.Root.Position - s.Target.Position).Magnitude }
		s.Config = Resolver.Resolve(Defaults, { EGG_TRAVEL_SETTINGS = { MODE = "TRAVEL_ONLY", ENABLE_SELECTED_EGG_TRAVEL = true, ENABLE_DIRECT_POSITIONING = true } })
		s.Controller = { Config = s.Config, State = "RUNNING", Generation = 1,
			Log = function(_, kind, message) table.insert(s.Logs, kind .. " | " .. message) end }
		s.Manager = Travel.new(s.Controller)
		workspace.Raycast = function(_, origin, direction, params)
			table.insert(s.Casts, { Origin = origin, Direction = direction, Params = params })
			assert(params.FilterDescendantsInstances[1] == s.Character and params.RespectCanCollide == true)
			local endY = origin.Y + direction.Y
			if s.NoFloor or s.FloorY > origin.Y or s.FloorY < endY then return nil end
			return { Instance = s.Floor, Position = Vector3.new(origin.X, s.FloorY, origin.Z), Normal = s.Normal }
		end
		workspace.GetPartBoundsInBox = function(_, candidateFrame, size, params)
			table.insert(s.Queries, { Frame = candidateFrame, Size = size, Params = params })
			assert(params.RespectCanCollide == true)
			-- Native Characters/Characters do not collide. A Default-group query
			-- would incorrectly return the other avatar as a solid obstruction.
			if s.NearbyPlayer and params.CollisionGroup ~= "Characters" then return { s.NearbyPlayer, s.Visual } end
			return s.Blocked and { s.Obstacle, s.Visual } or { s.Visual }
		end
		callback(s)
	end, debug.traceback)
	CFrame, RaycastParams, OverlapParams, Enum.RaycastFilterType = oldCFrame, oldRay, oldOverlap, oldEnum
	workspace.Raycast, workspace.GetPartBoundsInBox, typeof = oldCast, oldQuery, oldTypeof
	assert(ok, failure)
end

test("Raised Common Egg anchor observes a floor beyond the former short ray interval", function()
	standingGeometryFixture(function(s)
		assert(s.Target.Position.Y - s.Record.Range > s.FloorY, "Fixture must reproduce the former missed-floor interval")
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing, tostring(reason))
		assert(math.abs(standing.Position.Y - 3.15) < 0.001 and standing.Position.X == s.Target.Position.X and standing.Position.Z == s.Target.Position.Z)
		assert(#s.Casts > 0 and #s.Casts <= 10, "Support search is finite")
		assert(s.Casts[1].Origin.Y + s.Casts[1].Direction.Y <= s.FloorY)
		assert(proof and proof.Model == s.Model and proof.TargetRoot == s.Target and proof.Support == s.Floor)
		assert(proof.CharacterRoot == s.Root and (proof.Position - standing.Position).Magnitude < 0.001)
		local report = s.Manager.LastStandingReport
		assert(report and report.Avatar.BodySource == "NATIVE_RIG" and report.Candidates[1].RayEndY <= s.FloorY)
		assert(report.Candidates[1].Hit.Path:find("ObservedFloor", 1, true))
	end)
end)

test("Saved-scene equivalent Common Egg support was inside the former ray and remains usable", function()
	standingGeometryFixture(function(s)
		s:SetFloorY(6.6)
		assert(s.FloorY >= s.Target.Position.Y - s.Record.Range,
			"Saved-scene equivalent distinguishes the real short-ray uncertainty from the synthetic missed-floor case")
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing, tostring(reason))
		assert(math.abs(standing.Position.Y - 9.75) < 0.001 and proof.Support == s.Floor)
		assert(s.Manager.LastStandingReport.Candidates[1].RangeEligible == true)
	end)
end)

test("Ordinary supported destination accepts only the selected physical anchor and actual floor", function()
	standingGeometryFixture(function(s)
		s:SetFloorY(5)
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(standing, tostring(reason))
		assert(math.abs(standing.Position.Y - 8.15) < 0.001 and #s.Queries == 1)
		assert(s.Queries[1].Params.FilterDescendantsInstances[1] == s.Character)
		assert(s.Queries[1].Params.FilterDescendantsInstances[2] == s.Floor)
	end)
end)

test("Noncollidable visual egg overlap does not reject observed standing support", function()
	standingGeometryFixture(function(s)
		assert(s.Manager:ResolveStanding(s.Record) and #s.Queries == 1)
		assert(s.Visual.CanCollide == false and s.Visual.Size.Y > s.Record.Range)
	end)
end)

test("Real collidable obstruction rejects all bounded standing candidates", function()
	standingGeometryFixture(function(s)
		s.Blocked = true
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(not standing and type(reason) == "string" and #s.Queries > 0 and #s.Queries <= 10)
		assert(reason:find("AVATAR_COLLISION", 1, true), reason)
		local report = s.Manager.LastStandingReport
		assert(report and #report.Candidates == #s.Queries and report.Candidates[1].BlockingParts[1].Path:find("SolidCeiling", 1, true))
	end)
end)

test("Missing observed support reports an exact ray failure without a positioning guess", function()
	standingGeometryFixture(function(s)
		s.NoFloor = true
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(not standing and #s.Casts > 0 and #s.Casts <= 10 and #s.Queries == 0)
		assert(type(reason) == "string" and reason:find("NO_FLOOR_HIT", 1, true), reason)
		assert(s.Manager.LastStandingReport.Candidates[1].Reason == "NO_FLOOR_HIT")
		assert(s.Assignments == 0)
	end)
end)

test("An oversized noncollidable cosmetic cannot inflate avatar standing height or clearance", function()
	standingGeometryFixture(function(s)
		local accessory = { Name = "LargeCosmetic", Parent = s.Character, IsA = function(_, kind) return kind == "Accessory" end }
		local handle = s.Part("Handle", s.Root.Position + Vector3.new(0, -80, 0), Vector3.new(200, 200, 200), accessory, false)
		table.insert(s.Extras, handle)
		s.BoundsSize, s.BoundsOffset = Vector3.new(200, 240, 200), Vector3.new(0, -80, 0)
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(standing, tostring(reason))
		assert(math.abs(standing.Position.Y - 3.15) < 0.001)
		assert(#s.Queries == 1 and s.Queries[1].Size.X < 10 and s.Queries[1].Size.Y < 10 and s.Queries[1].Size.Z < 10)
		local avatar = s.Manager.LastStandingReport.Avatar
		assert((avatar.AggregateSize - s.BoundsSize).Magnitude < 0.001 and (avatar.AggregateOffset.Position or avatar.AggregateOffset).Y == -80)
		assert(avatar.BodySource == "NATIVE_RIG" and avatar.IgnoredNonCollidableCount > 0)
	end)
end)

test("Unexpected collidable avatar descendants remain part of the observed collision volume", function()
	standingGeometryFixture(function(s)
		local extra = s.Part("CollidableExtra", s.Root.Position, Vector3.new(10, 6, 10), s.Character, true)
		table.insert(s.Extras, extra)
		s.Blocked = true
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(not standing and reason:find("AVATAR_COLLISION", 1, true), tostring(reason))
		assert(s.Manager.LastStandingReport.Avatar.CollidableExtraCount > 0)
		assert(s.Queries[1].Size.X >= 10 and s.Queries[1].Size.Z >= 10, "The unexpected collidable part must not be discarded as cosmetic")
	end)
end)

test("A solid avatar extra below supported feet cannot hide in the excluded floor", function()
	standingGeometryFixture(function(s)
		local extra = s.Part("SolidBelowFeet", s.Root.Position + Vector3.new(0, -5, 0), Vector3.new(2, 2, 2), s.Character, true)
		table.insert(s.Extras, extra)
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(not standing and reason:find("AVATAR_SOLID_BELOW_SUPPORTED_FEET", 1, true), tostring(reason))
		assert(s.Manager.LastStandingReport.Avatar.CollidableExtraCount == 1)
		assert(s.Manager.LastStandingReport.Avatar.SupportIntersection == true)
		assert(#s.Casts == 0 and #s.Queries == 0 and s.Assignments == 0)
	end)
end)

test("A noncollidable original anchor uses an observed collidable floor rather than the anchor as support", function()
	standingGeometryFixture(function(s)
		assert(s.Target.CanCollide == false)
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing and proof.Support == s.Floor and proof.Support ~= s.Target, tostring(reason))
		assert(s.Manager.LastStandingReport.Candidates[1].Hit.CanCollide == true)
	end)
end)

test("Observed native character collision group prevents another noncolliding avatar from blocking standing", function()
	standingGeometryFixture(function(s)
		for _, bodyPart in ipairs(s.BodyParts) do bodyPart.CollisionGroup = "Characters" end
		local otherCharacter = { Name = "OtherCharacter", Parent = workspace }
		s.NearbyPlayer = s.Part("OtherPlayerTorso", s.Target.Position, Vector3.new(4, 6, 4), otherCharacter, true)
		s.NearbyPlayer.CollisionGroup = "Characters"
		local defaultQuery = workspace:GetPartBoundsInBox(s.Root.CFrame, Vector3.new(4, 6, 4), { RespectCanCollide = true, CollisionGroup = "Default" })
		assert(defaultQuery[1] == s.NearbyPlayer, "Fixture must reproduce the false blocker from the previous Default query")
		table.clear(s.Queries)
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing and proof, tostring(reason))
		assert(s.Manager.LastStandingReport.Avatar.CollisionGroup == "Characters" and proof.CollisionGroup == "Characters")
		assert(s.Casts[1].Params.CollisionGroup == "Characters" and s.Queries[1].Params.CollisionGroup == "Characters")
		assert(#s.Queries == 1 and s.Manager.LastStandingReport.Candidates[1].BlockingCount == nil)
	end)
end)

test("A collidable body part with a different group cannot borrow the root-only collision query", function()
	standingGeometryFixture(function(s)
		for _, bodyPart in ipairs(s.BodyParts) do bodyPart.CollisionGroup = "Characters" end
		s.Character:FindFirstChild("Torso").CollisionGroup = "Default"
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(not standing and reason:find("AVATAR_COLLISION_GROUP_MISMATCH", 1, true), tostring(reason))
		assert(#s.Casts == 0 and #s.Queries == 0 and s.Assignments == 0)
	end)
end)

test("Unsupported aggregate-only avatar height preserves its actual diagnostic dimensions before blocking", function()
	standingGeometryFixture(function(s)
		s.Character.FindFirstChild = nil -- This custom form exposes no native rig correspondence.
		s.BoundsSize = Vector3.new(4, 300, 4)
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(not standing and reason:find("AVATAR_STANDING_HEIGHT_UNSUPPORTED", 1, true), tostring(reason))
		local report = s.Manager.LastStandingReport
		assert(report.Avatar and report.Avatar.AggregateSize.Y == 300 and report.Avatar.BodySource == "FULL_MODEL_FALLBACK")
		assert(report.Avatar.Height > 128 and #report.Candidates == 0)
		assert(table.concat(s.Logs, "\n"):find("300.000", 1, true), "Rejected bounds must remain visible in the owner's one diagnostic report")
		assert(#s.Casts == 0 and #s.Queries == 0 and s.Assignments == 0)
	end)
end)

test("A platform welded into an anchored assembly can provide actual static standing support", function()
	standingGeometryFixture(function(s)
		s.Floor.Anchored = false
		s.Floor.AssemblyRootPart = s.Part("AnchoredAssemblyRoot", s.Floor.Position, Vector3.new(2, 2, 2), workspace, true)
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing and proof.Support == s.Floor, tostring(reason))
		assert(s.Manager.LastStandingReport.Candidates[1].Hit.Anchored == false)
	end)
end)

test("An unsupported free platform or observed moving support cannot authorize a destination", function()
	for _, failure in ipairs({ "UNANCHORED", "MOVING" }) do
		standingGeometryFixture(function(s)
			if failure == "UNANCHORED" then s.Floor.Anchored = false
			else s.Floor.AssemblyLinearVelocity = Vector3.new(0, 2, 0) end
			local standing, reason = s.Manager:ResolveStanding(s.Record)
			assert(not standing and reason:find(failure == "UNANCHORED" and "SUPPORT_UNANCHORED" or "SUPPORT_MOVING", 1, true), tostring(reason))
			assert(#s.Queries == 0 and s.Assignments == 0)
		end)
	end
end)

test("A physical support proof cannot authorize beyond-radius or far-above-floor positions", function()
	standingGeometryFixture(function(s)
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing and proof, tostring(reason))
		s.Record.StandingDestination = proof
		assert(s.Manager:RangeEligibleAt(s.Record, standing.Position))
		assert(not s.Manager:RangeEligibleAt(s.Record, standing.Position + Vector3.new(7, 0, 0)))
		assert(not s.Manager:RangeEligibleAt(s.Record, standing.Position + Vector3.new(0, 3, 0)))
		assert(not s.Manager:RangeEligibleAt(s.Record, standing.Position + Vector3.new(0, -3, 0)))
	end)
end)

test("A raised original's observed bounds support physical arrival below Root without claiming native hatch range", function()
	standingGeometryFixture(function(s)
		s.Target.Position = Vector3.new(s.Target.Position.X, 12, s.Target.Position.Z)
		s.Target.CFrame.Position = s.Target.Position
		s.Record.RangeOriginPosition, s.Record.TargetPosition = s.Target.Position, s.Target.Position
		s.Model.GetBoundingBox = function() return s.Target.CFrame, Vector3.new(4, 24, 4) end
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing and proof, tostring(reason))
		assert((standing.Position - s.Target.Position).Magnitude > s.Record.Range)
		assert(not s.Manager:RangeEligibleAt(s.Record, standing.Position), "Raw geometry alone does not grant out-of-sphere arrival")
		s.Record.StandingDestination = proof
		assert(s.Manager:RangeEligibleAt(s.Record, standing.Position), "Observed floor and avatar height establish supported physical arrival")
		assert(s.Record.InteractionVerified ~= true, "This fixture grants no native hatch registration/range")
	end)
end)

test("An actually scaled rig retains real body clearance while physical arrival uses its proven standing height", function()
	standingGeometryFixture(function(s)
		s:SetFloorY(6.6)
		s.Character:FindFirstChild("Torso").Size = Vector3.new(4, 20, 4)
		s.BoundsSize = Vector3.new(4, 20, 4)
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing and proof, tostring(reason))
		assert(s.Manager.LastStandingReport.Avatar.BodySize.Y == 20)
		assert(s.Queries[1].Size.Y > 20, "Real body geometry must not be clipped to a default-sized avatar")
		assert((standing.Position - s.Target.Position).Magnitude > s.Record.Range)
		s.Record.StandingDestination = proof
		assert(s.Manager:RangeEligibleAt(s.Record, standing.Position))
		assert(s.Record.InteractionVerified ~= true)
	end)
end)

test("Native paid interaction range remains three dimensional despite supported physical geometry", function()
	standingGeometryFixture(function(s)
		s.Record.LocationOnly, s.Record.LocationVerified = false, nil
		s.Target.Position = Vector3.new(s.Target.Position.X, 12, s.Target.Position.Z)
		s.Target.CFrame.Position = s.Target.Position
		s.Record.RangeOriginPosition, s.Record.TargetPosition = s.Target.Position, s.Target.Position
		s.Model.GetBoundingBox = function() return s.Target.CFrame, Vector3.new(4, 24, 4) end
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(not standing and type(reason) == "string" and #s.Queries == 0)
		assert(s.Manager.LastStandingReport.Candidates[1].Hit and reason:find("Outside the actual native egg range origin", 1, true), reason)
		assert(not s.Manager:RangeEligibleAt(s.Record, Vector3.new(s.Target.Position.X, 3.15, s.Target.Position.Z)))
	end)
end)

test("A standing proof retains the exact original Instance even when the name and full path are duplicated", function()
	standingGeometryFixture(function(s)
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing and proof, tostring(reason))
		s.Record.StandingDestination = proof
		local duplicate = { Name = s.Model.Name, Parent = s.Model.Parent, GetFullName = s.Model.GetFullName }
		assert(duplicate ~= s.Model and duplicate:GetFullName() == s.Model:GetFullName())
		local changed = table.clone(s.Record) changed.Model = duplicate
		assert(not s.Manager:RangeEligibleAt(changed, standing.Position))
		assert(s.Manager:RangeEligibleAt(s.Record, standing.Position))
	end)
end)

test("Moved supporting geometry invalidates the retained pose instead of selecting another destination", function()
	standingGeometryFixture(function(s)
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing and proof, tostring(reason))
		s.Record.StandingDestination = proof
		s.Floor.Position += Vector3.new(0, 2, 0)
		local second, secondReason = s.Manager:ResolveStanding(s.Record)
		assert(not second and type(secondReason) == "string" and s.Assignments == 0)
		assert(not s.Manager:RangeEligibleAt(s.Record, standing.Position))
	end)
end)

test("Standing rejection reports exact observed geometry once for the selected target", function()
	standingGeometryFixture(function(s)
		s.Blocked = true
		local standing, reason = s.Manager:ResolveStanding(s.Record)
		assert(not standing and reason:find("AVATAR_COLLISION", 1, true))
		local report = s.Manager.LastStandingReport
		assert(report.Avatar.BodySize.X == 4 and report.Avatar.BodySize.Y == 6 and report.Avatar.Height > 0)
		assert(#report.Candidates > 0 and #report.Candidates <= 10)
		local first = report.Candidates[1]
		assert(first.Id ~= nil and first.X == s.Target.Position.X and first.Z == s.Target.Position.Z)
		assert(first.RayStartY > first.RayEndY and first.Hit.CanCollide == true and first.Hit.Anchored == true)
		assert(first.Hit.Position.Y == s.FloorY and first.Hit.Normal.Y == 1)
		assert(first.ProposedPosition and type(first.AnchorDistance) == "number" and first.RangeEligible == true)
		assert(#first.BlockingParts > 0 and #first.BlockingParts <= 6)
		local reported = #s.Logs
		assert(reported > 0, "The owner needs the candidate geometry that rejected the destination")
		s.Manager:ResolveStanding(s.Record)
		assert(#s.Logs == reported, "Revisiting the same selected target must not print another identical geometry report")
	end)
end)

test("Real supported standing geometry survives final guarded adapter dispatch exactly once", function()
	standingGeometryFixture(function(s)
		local standing, reason, proof = s.Manager:ResolveStanding(s.Record)
		assert(standing and proof, tostring(reason))
		s.Record.StandingDestination, s.Record.LeaseId, s.Record.NeedsNativeTravel = proof, 1, false
		s.Manager.Lease = s.Record s.Controller.EggTravel = s.Manager
		local token = { CheckCancelled = function() return false end }
		s.Controller.Scheduler = { Active = { Token = token, Definition = { Owner = "EGG_TRAVEL", Generation = 1 } } }
		s.Manager.Validate = function(_, record)
			assert(record.Model == s.Model and record.TargetRoot == s.Target)
			record.Distance = (s.Root.Position - s.Target.Position).Magnitude
			record.InRange = s.Manager:RangeEligibleAt(record, s.Root.Position)
			return record
		end
		local adapter = setmetatable({ LocalFeatureController = s.Controller, Config = s.Config,
			LocalFeatureGuard = function() return true end }, requireOC("GameMechanics"))
		local assigned, assignedReason = adapter:PositionSelectedEgg(s.Manager, s.Record, standing, token)
		assert(assigned and s.Assignments == 1 and (s.Root.Position - standing.Position).Magnitude < 0.001, tostring(assignedReason))
		assert(assignedReason:find("pending", 1, true), "Assignment is not observed arrival")
		adapter:PositionSelectedEgg(s.Manager, s.Record, standing, token)
		assert(s.Assignments == 1, "A valid standing proof does not grant another positioning attempt")
		assert(s.Config.PET_SETTINGS.AUTO_HATCH == false and s.Config.PET_SETTINGS.AUTO_EQUIP == false)
	end)
end)

print("[OC TEST] " .. tostring(tests - before) .. " standing geometry regressions passed; live surface/arrival remains owner pending")
end

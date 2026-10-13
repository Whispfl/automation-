--!nonstrict
-- Read-only standing observations. Native CharacterUtil:GetRig supplies the R15
-- body names; collision queries use the observed character group. No movement.
local Geometry = {}
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
local function vector(v) return v and finite(v.X) and finite(v.Y) and finite(v.Z) end
local function live(part) return part and part.Parent and part:IsA("BasePart") and part:IsDescendantOf(workspace) end
Geometry.Vector, Geometry.Live = vector, live
function Geometry.Path(part)
	local ok, path = pcall(function() return part:GetFullName() end)
	return ok and path or tostring(part and part.Name or "UNKNOWN")
end
function Geometry.Part(part)
	local function read(key) local ok, value = pcall(function() return part[key] end) if ok then return value end return nil end
	local assembly = read("AssemblyRootPart")
	return { Name = read("Name"), Path = Geometry.Path(part), Position = read("Position"), Size = read("Size"),
		Anchored = read("Anchored"), CanCollide = read("CanCollide"), CanQuery = read("CanQuery"),
		CollisionGroup = read("CollisionGroup"), AssemblyRoot = assembly and Geometry.Path(assembly),
		LinearVelocity = read("AssemblyLinearVelocity"), AngularVelocity = read("AssemblyAngularVelocity") }
end
local r15 = { "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
local r6 = { "HumanoidRootPart", "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local function halfExtents(frame, size)
	if not frame or not vector(frame.Position) or not vector(frame.RightVector) or not vector(frame.UpVector) or not vector(frame.LookVector)
		or not vector(size) or size.X <= 0 or size.Y <= 0 or size.Z <= 0 then return nil end
	return Vector3.new(
		(math.abs(frame.RightVector.X) * size.X + math.abs(frame.UpVector.X) * size.Y + math.abs(frame.LookVector.X) * size.Z) / 2,
		(math.abs(frame.RightVector.Y) * size.X + math.abs(frame.UpVector.Y) * size.Y + math.abs(frame.LookVector.Y) * size.Z) / 2,
		(math.abs(frame.RightVector.Z) * size.X + math.abs(frame.UpVector.Z) * size.Y + math.abs(frame.LookVector.Z) * size.Z) / 2)
end
function Geometry.Avatar(record)
	local root, character, humanoid = record.CharacterRoot, record.Character, record.Humanoid
	if not root or not root.CFrame or not vector(root.Size) or not humanoid or not finite(humanoid.HipHeight) or humanoid.HipHeight < 0
		or not character or type(character.GetBoundingBox) ~= "function" then return nil, "AVATAR_GEOMETRY_UNAVAILABLE" end
	local aggregateFrame, aggregateSize = character:GetBoundingBox()
	local aggregateOffset = aggregateFrame and root.CFrame:ToObjectSpace(aggregateFrame)
	local aggregateHalf = halfExtents(aggregateOffset, aggregateSize)
	if not aggregateHalf then return nil, "AVATAR_AGGREGATE_BOUNDS_UNAVAILABLE" end
	local group = type(root.CollisionGroup) == "string" and root.CollisionGroup or "Default"
	local avatar = { AggregateSize = aggregateSize, AggregateOffset = aggregateOffset, CollisionGroup = group,
		BodySource = "FULL_MODEL_FALLBACK", BodySize = aggregateSize, BodyOffset = aggregateOffset,
		IgnoredNonCollidableCount = 0, CollidableExtraCount = 0, UnexpectedParts = {} }
	local body, membership = {}, {}
	if type(character.FindFirstChild) == "function" and type(character.GetDescendants) == "function" then
		local names = character:FindFirstChild("UpperTorso") and r15 or character:FindFirstChild("Torso") and r6
		if names then
			for _, name in ipairs(names) do
				local part = character:FindFirstChild(name)
				if not live(part) or part.Parent ~= character then return nil, "AVATAR_RIG_PART_UNAVAILABLE:" .. name end
				table.insert(body, part) membership[part] = true
			end
			avatar.BodySource = "NATIVE_RIG"
		end
	end
	local minimum, maximum
	local function include(part)
		local offset = root.CFrame:ToObjectSpace(part.CFrame)
		local half = halfExtents(offset, part.Size)
		if not half then return false end
		local low, high = offset.Position - half, offset.Position + half
		minimum = minimum and Vector3.new(math.min(minimum.X, low.X), math.min(minimum.Y, low.Y), math.min(minimum.Z, low.Z)) or low
		maximum = maximum and Vector3.new(math.max(maximum.X, high.X), math.max(maximum.Y, high.Y), math.max(maximum.Z, high.Z)) or high
		return true
	end
	for _, part in ipairs(body) do if not include(part) then return nil, "AVATAR_RIG_BOUNDS_UNAVAILABLE:" .. part.Name end end
	-- The rig determines feet/support height. Solid extras still occupy clearance;
	-- noncollidable cosmetic geometry remains visible in diagnostics, not physics.
	local feetHeight = minimum and -minimum.Y or aggregateHalf.Y - aggregateOffset.Position.Y
	if type(character.GetDescendants) == "function" then
		local descendants = character:GetDescendants()
		if #descendants > 512 then return nil, "AVATAR_OBSERVATION_LIMIT_EXCEEDED" end
		for _, part in ipairs(descendants) do
			if part:IsA("BasePart") then
				if part.CanCollide == true and type(part.CollisionGroup) == "string" and part.CollisionGroup ~= group then
					return nil, "AVATAR_COLLISION_GROUP_MISMATCH:" .. Geometry.Path(part)
				end
				if not membership[part] then
					if part.CanCollide == true then
						avatar.CollidableExtraCount += 1
						if #body > 0 and not include(part) then return nil, "AVATAR_EXTRA_BOUNDS_UNAVAILABLE:" .. Geometry.Path(part) end
					else avatar.IgnoredNonCollidableCount += 1 end
					if #avatar.UnexpectedParts < 6 then table.insert(avatar.UnexpectedParts, Geometry.Part(part)) end
				end
			end
		end
	end
	if minimum then
		avatar.BodySize, avatar.BodyOffset = maximum - minimum, CFrame.new((minimum + maximum) * 0.5)
	end
	avatar.Height = math.max(humanoid.HipHeight + root.Size.Y / 2, feetHeight) + 0.15
	if not finite(avatar.Height) or avatar.Height <= 0 or avatar.Height > 128 then return nil, "AVATAR_STANDING_HEIGHT_UNSUPPORTED", avatar end
	local clearanceHalf = halfExtents(avatar.BodyOffset, avatar.BodySize)
	avatar.ClearanceBottom = avatar.Height + avatar.BodyOffset.Position.Y - clearanceHalf.Y
	-- The overlap query excludes the support itself. Explicitly reject a solid
	-- extra penetrating that support instead of silently hiding the intersection.
	avatar.SupportIntersection = avatar.ClearanceBottom < 0.05
	return avatar
end
function Geometry.Support(part, normal)
	if not live(part) then return false, "SUPPORT_INSTANCE_UNAVAILABLE" end
	if part.CanCollide ~= true then return false, "SUPPORT_NOT_COLLIDABLE" end
	if not vector(normal) or normal.Y < 0.98 then return false, "SUPPORT_TOO_STEEP:OC_FLAT_SURFACE_POLICY" end
	local assembly = part.AssemblyRootPart
	if part.Anchored ~= true and not (live(assembly) and assembly.Anchored == true) then return false, "SUPPORT_UNANCHORED" end
	for _, velocity in ipairs({ part.AssemblyLinearVelocity or false, part.AssemblyAngularVelocity or false }) do
		if velocity ~= false and (not vector(velocity) or velocity.Magnitude > 0.05) then return false, "SUPPORT_MOVING" end
		if velocity == false and part.Anchored ~= true then return false, "SUPPORT_ASSEMBLY_MOTION_UNAVAILABLE" end
	end
	return true
end
function Geometry.CheckProof(record, proof)
	if not proof or proof.Model ~= record.Model or proof.TargetRoot ~= record.TargetRoot or proof.CharacterRoot ~= record.CharacterRoot
		or not vector(proof.Position) or not live(record.TargetRoot) or not vector(record.TargetRoot.Position)
		or not vector(proof.AnchorPosition) or (record.TargetRoot.Position - proof.AnchorPosition).Magnitude > 0.05 then
		return false, "STANDING_IDENTITY_OR_ANCHOR_CHANGED"
	end
	local supported, reason = Geometry.Support(proof.Support, proof.SupportNormal)
	if not supported then return false, reason end
	local part = proof.Support
	if not vector(part.Position) or not vector(part.Size) or not vector(proof.SupportPosition) or not vector(proof.SupportSize)
		or (part.Position - proof.SupportPosition).Magnitude > 0.05 or (part.Size - proof.SupportSize).Magnitude > 0.05 then
		return false, "STANDING_SUPPORT_GEOMETRY_CHANGED"
	end
	if proof.SupportFrame and part.CFrame then
		for _, axis in ipairs({ "RightVector", "UpVector", "LookVector" }) do
			if not vector(part.CFrame[axis]) or not vector(proof.SupportFrame[axis]) or (part.CFrame[axis] - proof.SupportFrame[axis]).Magnitude > 0.01 then
				return false, "STANDING_SUPPORT_ROTATION_CHANGED"
			end
		end
	end
	if (type(record.CharacterRoot.CollisionGroup) == "string" and record.CharacterRoot.CollisionGroup or "Default") ~= proof.CollisionGroup then
		return false, "STANDING_CHARACTER_COLLISION_GROUP_CHANGED"
	end
	return true
end
function Geometry.SearchDepth(record, avatar)
	local up = record.Range + avatar.Height
	local down = record.Range + avatar.Height
	-- Original-model extents can evidence a lower support search. The actual ray
	-- hit still authorizes standing; a bounding box never becomes a destination.
	if type(record.Model.GetBoundingBox) == "function" then
		local frame, size = record.Model:GetBoundingBox()
		local half = halfExtents(frame, size)
		if half then down = math.max(down, record.RangeOrigin.Position.Y - (frame.Position.Y - half.Y) + avatar.Height + 0.5) end
	end
	return math.min(up, 128), math.min(down, 128)
end
return Geometry

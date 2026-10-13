do
-- Same bundled entry/harness as existing tests. Synthetic world/geometry only.
local before = tests
local Manager = requireOC("EggTravelManager")
local function fixture()
	local s = { Profile = { WorldsUnlocked = { ["The Overworld"] = true }, AreasUnlocked = { Zen = true }, EggsOpened = {} },
		Character = {}, Commands = {}, Logs = {}, CurrentWorld = "The Overworld", Loaded = true }
	s.Root = { Position = Vector3.new(0, 100, 0), Size = Vector3.new(2, 2, 1), Parent = s.Character }
	s.Humanoid = { HipHeight = 2, MoveDirection = Vector3.new(0, 0, 0) }
	s.Part = { Position = Vector3.new(2, 100, 0), Parent = true,
		IsA = function(_, kind) return kind == "BasePart" end, IsDescendantOf = function(self) return self.Parent ~= nil end }
	s.Prompt = setmetatable({ Parent = true, IsA = function(_, kind) return kind == "BasePart" end,
		IsDescendantOf = function(self) return self.Parent ~= nil end,
		FindFirstChildOfClass = function() return not s.MissingInitialPrompt and s.NativePrompt or nil end },
		{ __index = function(_, key) if key == "Position" then return s.PromptPosition or s.Part.Position end end })
	s.NativePrompt = { Parent = s.Prompt, Enabled = true, MaxActivationDistance = 6.5, RequiresLineOfSight = false }
	s.Prompts = { Visible = 0 }
	s.Egg = { Name = "Selected Egg", Parent = true, IsDescendantOf = function(self) return self.Parent ~= nil end,
		FindFirstChild = function(_, name) if name == "Root" then return s.Part elseif name == "Prompt" then return s.Prompt end return {} end,
		GetAttribute = function(_, name) if name == "Island" then return "Zen" elseif name == "Unlocked" then return s.Opened == true end end }
	s.Definitions = { ["Selected Egg"] = { World = "The Overworld", Island = "Zen" } }
	s.Worlds = { ["The Overworld"] = { Islands = { { Name = "Zen" } } } }
	s.Config = { HATCH_SETTINGS = { SELECTED_EGGS = { "Selected Egg" } }, PET_SETTINGS = { AUTO_HATCH = false },
		EGG_TRAVEL_SETTINGS = { ENABLE_SELECTED_EGG_TRAVEL = true, ENABLE_DIRECT_POSITIONING = false,
			ENABLE_NATIVE_ISLAND_TRAVEL = false, ARRIVAL_TIMEOUT_SECONDS = 2, STABILITY_SECONDS = 0.3,
			MAXIMUM_ATTEMPTS_PER_SELECTION = 1, MAXIMUM_LOCATION_SECONDS = 120, SELECTION_REVISION = 0 } }
	s.Controller = { Config = s.Config, State = "RUNNING", Generation = 1, Log = function(_, kind, message) table.insert(s.Logs, kind .. " | " .. message) end,
		Reader = { Player = { Character = s.Character }, GetLiveProfile = function() return s.Profile end,
			GetSnapshot = function() return { Ready = s.Ready ~= false } end },
		Knowledge = { Get = function(_, name)
			if name == "Eggs" then return s.Definitions elseif name == "Worlds" then return s.Worlds
			elseif name == "WorldUtil" then return { GetPlayerWorld = function() return s.CurrentWorld end } end
			if name == "ProximityPrompt" and not s.UnknownPrompts then return s.Prompts end
		end, EggModels = function() return s.Loaded and (s.OtherEgg and { s.Egg, s.OtherEgg } or { s.Egg }) or {} end },
		Farming = { Tracker = { Root = function() if s.Dead then return nil end return s.Root, s.Humanoid end }, Mechanics = {} } }
	mockNativeEggIdentity(s.Controller.Knowledge)
	s.Controller.Farming.Mechanics.LocalFeatureGuard = function() return s.GuardBlocked ~= true, "Synthetic native UI/input guard blocks" end
	s.Controller.Farming.Mechanics.TravelSelectedEgg = function(_, manager, record, token)
		assert(manager:Validate(record, token))
		table.insert(s.Commands, "NATIVE_AREA_TRAVEL")
		if s.NativeFailure then return false, "Synthetic native arrival failed" end
		if s.NativeDelay then task.wait(s.NativeDelay) end
		s.CurrentWorld = record.World
		s.Root.Position = s.Part.Position + Vector3.new(2, 0, 0)
		return true, "Synthetic observed native area"
	end
	s.Controller.Farming.Mechanics.PositionSelectedEgg = function(_, manager, record, frame, token)
		assert(manager:Validate(record, token))
		table.insert(s.Commands, "DIRECT_POSITION")
		if s.PositionFailure then return false, "Synthetic transform failure" end
		if not s.NoArrival then s.Root.Position = frame.Position end
		if s.OnPosition then s.OnPosition() end
		return true, "Local assignment only"
	end
	s.Manager = Manager.new(s.Controller)
	s.Token = { CheckCancelled = function() return s.Cancelled == true end }
	function s:Standing() self.Manager.ResolveStanding = function(_, record) return { Position = record.RangeOriginPosition + Vector3.new(2, 0, 0) } end end
	function s:Run()
		local owns, decision = self.Manager:Select()
		if not owns then return nil, decision end
		return self.Manager:Definition(decision, self.Controller.Generation).Execute(self.Token), decision
	end
	return s
end

test("Selected egg travel is independently disabled and ambiguous selections do not move", function()
	local s = fixture() s.Config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL = false
	assert(not s.Manager:Select() and not s.Manager:OwnsLocation())
	s.Config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL = true
	s.Config.HATCH_SETTINGS.SELECTED_EGGS = { "Selected Egg", "Other Egg" }
	assert(not s.Manager:Select() and #s.Commands == 0)
	s.Config.HATCH_SETTINGS.SELECTED_EGGS = {} assert(not s.Manager:Select())
end)

test("Selected egg resolve uses actual loaded geometry and fresh access, not event appearance", function()
	local s = fixture() local r = s.Manager:Resolve()
	assert(r.Model == s.Egg and r.TargetRoot == s.Part and r.Range == 6.5 and r.InRange)
	s.Opened = true s.Profile.EggsOpened["Selected Egg"] = 0
	assert(s.Manager:Resolve().Range == 16)
	s.Profile.AreasUnlocked.Zen = nil assert(s.Manager:Resolve() == nil)
	s.Profile.AreasUnlocked.Zen = true s.Profile.WorldsUnlocked["The Overworld"] = nil assert(s.Manager:Resolve() == nil)
	s.Profile.WorldsUnlocked["The Overworld"] = true s.Loaded = false assert(s.Manager:Resolve() == nil)
	s.Loaded = true s.Definitions["Selected Egg"].Event = "Explicitly selected known event"
	assert(not s.Manager:Resolve(), "Known permanent-world access does not verify current event eligibility; manual approach required")
	s.Definitions["Selected Egg"].World = "Unknown Event" assert(s.Manager:Resolve() == nil and #s.Commands == 0)
end)

test("Unopened range uses the actual Prompt, even when Root is within six and a half studs", function()
	local s = fixture() s.PromptPosition = Vector3.new(20, 100, 0)
	local record = s.Manager:Resolve()
	assert(record.RootDistance == 2 and record.Distance == 20 and record.RangeOrigin == s.Prompt and not record.InRange)
	assert(not s.Manager:Select() and s.Manager.LastResult == nil and #s.Commands == 0)
	s.PromptPosition = Vector3.new(3, 100, 0) assert(s.Manager:Resolve().InRange)
	s.MissingInitialPrompt = true assert(s.Manager:Resolve() == nil)
	s.MissingInitialPrompt = false s.NativePrompt.Enabled = false assert(s.Manager:Resolve() == nil)
	s.NativePrompt.Enabled = true s.NativePrompt.RequiresLineOfSight = true assert(s.Manager:Resolve() == nil)
end)

test("Opened scan requires known zero global prompt visibility and the selected nearest unlocked egg", function()
	local s = fixture() s.Opened = true s.Profile.EggsOpened["Selected Egg"] = 1
	s.PromptPosition = Vector3.new(50, 100, 0)
	local record = s.Manager:Resolve() assert(record.InRange and record.RangeOrigin == s.Part and record.Range == 16)
	s.Prompts.Visible = 1 assert(s.Manager:Resolve() == nil and not s.Manager:Select())
	s.Prompts.Visible = nil assert(s.Manager:Resolve() == nil)
	s.Prompts.Visible = 0 s.UnknownPrompts = true assert(s.Manager:Resolve() == nil)
	s.UnknownPrompts = false
	local otherRoot = { Parent = true, Position = Vector3.new(0.5, 100, 0), IsA = s.Part.IsA, IsDescendantOf = s.Part.IsDescendantOf }
	s.OtherEgg = { Parent = true, Name = "Other Egg", IsDescendantOf = function() return true end,
		FindFirstChild = function() return otherRoot end, GetAttribute = function() return true end }
	record = s.Manager:Resolve() assert(not record.InRange and record.RangeBlocker:find("nearest", 1, true))
	assert(not s.Manager:Select() and s.Manager.LastResult == nil and #s.Commands == 0)
end)

test("Unknown or blocked final native interaction cannot claim observed eligible arrival", function()
	simulated(function()
		for _, failure in ipairs({ "Unknown", "Blocked" }) do
			local s = fixture()
			if failure == "Unknown" then s.Controller.Farming.Mechanics.LocalFeatureGuard = nil else s.GuardBlocked = true end
			local result = s:Run()
			assert(not result.Verified and s.Manager.LastResult.Status == "HALTED" and #s.Commands == 0)
			assert(not s.Manager:Select(), "Uncertain eligibility is bounded and requires explicit rearm")
		end
	end)
end)

test("Replaced or shifted native Prompt invalidates the original positioning lease", function()
	simulated(function()
		for _, failure in ipairs({ "Replacement", "Position" }) do
			local s = fixture() s.Part.Position = Vector3.new(100, 100, 0)
			s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true s:Standing()
			s.OnPosition = function()
				if failure == "Replacement" then s.Prompt = table.clone(s.Prompt) s.NativePrompt.Parent = s.Prompt
				else s.PromptPosition = s.Part.Position + Vector3.new(1, 0, 0) end
			end
			local result = s:Run() assert(not result.Verified and s.Manager.LastResult.Status == "HALTED" and #s.Commands == 1)
			assert(not s.Manager:Select(), "A changed prompt must not reuse old standing geometry or snap again")
		end
	end)
end)

test("Already nearby travel-only confirms stable actual range without hatch or spending", function()
	simulated(function()
		local s = fixture() local result = s:Run()
		assert(result.Verified and s.Manager.LastResult.Status == "HATCH_RANGE_OBSERVED")
		assert(s.Manager.LastResult.HatchCommands == 0 and s.Manager.LastResult.Spending == 0 and #s.Commands == 0)
		assert(s.Manager:OwnsLocation() and s.Manager:AtOwnedLocation({ World = "The Overworld", Name = "Zen" }))
		assert(not s.Manager:AtOwnedLocation({ World = "The Overworld", Name = "The Void" }))
		s.Config.PET_SETTINGS.AUTO_HATCH = true
		local owns, decision = s.Manager:Select()
		assert(not owns and decision.Kind == "HANDOFF" and s.Manager:OwnsLocation(), "Hatching retains its separate existing authorization")
	end)
end)

test("Explicit direct positioning is one attempt followed by observed range, not adapter return", function()
	simulated(function()
		local s = fixture() s.Part.Position = Vector3.new(100, 100, 0)
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL = true s:Standing()
		local result = s:Run() assert(result.Verified and #s.Commands == 1 and s.Commands[1] == "DIRECT_POSITION")
		s:Run() assert(#s.Commands == 1, "Observing the owned location must not snap repeatedly")
		assert(s.Manager.LastResult.DirectPositionAttempted and s.Manager.Attempts["Selected Egg:0"] == 1)
		assert(#s.Logs == 1 and s.Logs[1]:find("HATCH_RANGE_OBSERVED", 1, true), "Arrival reports actual proximity without hatch/spend")
	end)
end)

test("Correct existing unlocked native island travel precedes positioning when required", function()
	simulated(function()
		local s = fixture() s.Part.Position = Vector3.new(100, 1000, 0)
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true
		assert(not s.Manager:Select(), "Direct positioning does not cross a different island height")
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL = true
		local record = s.Manager:Resolve()
		assert(record.DestinationPath == "Workspace.Worlds.The Overworld.Islands.Zen.Island.Portal.Spawn" and record.NativeAreaKnown)
		local result = s:Run() assert(result.Verified and #s.Commands == 1 and s.Commands[1] == "NATIVE_AREA_TRAVEL")
		assert(not s.Manager.LastResult.DirectPositionAttempted)
	end)
end)

test("Slow confirmed native area arrival retains a separately bounded final stability window", function()
	simulated(function(clock)
		local s = fixture() s.Part.Position = Vector3.new(100, 1000, 0)
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL = true s.NativeDelay = 1.9
		local owns, decision = s.Manager:Select() assert(owns)
		local definition = s.Manager:Definition(decision, 1)
		assert(definition.TimeoutSeconds == 6)
		local result = definition.Execute(s.Token)
		assert(result.Verified and clock.Time > 2 and clock.Time < definition.TimeoutSeconds)
		assert(#s.Commands == 1 and s.Manager.LastResult.NativeTravelAttempted)
	end)
end)

test("Missing geometry capability fails closed without position assignment", function()
	simulated(function()
		local s = fixture() s.Part.Position = Vector3.new(100, 100, 0)
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true
		local result = s:Run() assert(not result.Verified and #s.Commands == 0 and not s.Manager:OwnsLocation())
		assert(s.Manager.Blocked["Selected Egg:0"], "Unsupported standing surface does not invent an offset")
	end)
end)

test("Standing clearance observes full avatar bounds, ceiling and unknown avatar geometry", function()
	local oldCFrame, oldRay, oldOverlap, oldEnum, oldPartType = CFrame, RaycastParams, OverlapParams, Enum.RaycastFilterType, Enum.PartType
	local oldCast, oldQuery = workspace.Raycast, workspace.GetPartBoundsInBox
	local meta = {}
	local function frame(position)
		local value = { Position = position, RightVector = Vector3.new(1, 0, 0), UpVector = Vector3.new(0, 1, 0), LookVector = Vector3.new(0, 0, -1) }
		function value:ToObjectSpace(other) return frame(other.Position - self.Position) end
		function value:PointToObjectSpace(point) return point - self.Position end -- Axis-aligned synthetic support.
		return setmetatable(value, meta)
	end
	function meta.__mul(a, b) return frame(a.Position + b.Position) end
	CFrame = { lookAt = function(position) return frame(position) end }
	RaycastParams, OverlapParams = { new = function() return {} end }, { new = function() return {} end }
	Enum.RaycastFilterType = { Exclude = "Exclude" }
	Enum.PartType = { Block = "Block" }
	local ok, reason = xpcall(function()
		local s = fixture() s.Part.Position = Vector3.new(0, 4, 0) s.Root.Position = Vector3.new(100, 4, 0)
		s.Root.CFrame = frame(s.Root.Position)
		s.Character.GetBoundingBox = function() return frame(s.Root.Position), Vector3.new(4, 6, 4) end
		local floor = { Parent = true, CanCollide = true, Anchored = true, Shape = Enum.PartType.Block,
			Size = Vector3.new(40, 1, 40), CFrame = frame(Vector3.new(0, -0.5, 0)),
			IsA = function(_, kind) return kind == "BasePart" or kind == "Part" end, IsDescendantOf = function() return true end }
		workspace.Raycast = function(_, origin, _direction, params)
			assert(params.FilterDescendantsInstances[1] == s.Character and params.RespectCanCollide)
			return { Instance = floor, Position = Vector3.new(origin.X, 0, origin.Z), Normal = Vector3.new(0, 1, 0) }
		end
		local queries, ceiling = 0, false
		workspace.GetPartBoundsInBox = function(_, _cf, size, params)
			queries += 1 assert(size.X >= 4 and size.Y > 6 and size.Z >= 4, "Root-only clearance ignores actual head/legs")
			assert(params.FilterDescendantsInstances[1] == s.Character and params.FilterDescendantsInstances[2] == floor)
			return ceiling and { { CanCollide = true } } or {}
		end
		local record = s.Manager:Resolve()
		local standing = s.Manager:ResolveStanding(record)
		assert(standing and math.abs(standing.Position.Y - 3.15) < 0.001 and queries == 1)
		ceiling = true queries = 0 assert(s.Manager:ResolveStanding(record) == nil and queries == 9, "Ceiling collision blocks center and every bounded fallback candidate")
		s.Character.GetBoundingBox = nil queries = 0 assert(s.Manager:ResolveStanding(record) == nil and queries == 0)
	end, debug.traceback)
	CFrame, RaycastParams, OverlapParams, Enum.RaycastFilterType = oldCFrame, oldRay, oldOverlap, oldEnum
	Enum.PartType = oldPartType
	workspace.Raycast, workspace.GetPartBoundsInBox = oldCast, oldQuery
	assert(ok, reason)
end)

test("Delayed correction or failed transform cannot establish arrival or produce repeated snaps", function()
	simulated(function()
		for _, failure in ipairs({ "NoArrival", "PositionFailure" }) do
			local s = fixture() s.Part.Position = Vector3.new(100, 100, 0)
			s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true s:Standing() s[failure] = true
			local result = s:Run() assert(not result.Verified and #s.Commands == 1)
			assert(not s.Manager:Select() and #s.Commands == 1 and s.Manager.LastResult.DirectPositionAttempted)
		end
	end)
end)

test("Disappearing or moved target and respawn cancel the same selected request", function()
	simulated(function()
		for _, failure in ipairs({ "Gone", "Moved", "Respawn" }) do
			local s = fixture() s.Part.Position = Vector3.new(100, 100, 0)
			s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true s:Standing()
			s.OnPosition = function()
				if failure == "Gone" then s.Egg.Parent = nil
				elseif failure == "Moved" then s.Part.Position += Vector3.new(5, 0, 0)
				else s.Controller.Reader.Player.Character = {} end
			end
			local result = s:Run() assert(not result.Verified and #s.Commands == 1 and not s.Manager:OwnsLocation())
			assert(not s.Manager:Select(), "Changed geometry/character requires explicit owner rearm")
		end
	end)
end)

test("Manual departure releases location and only an explicit selection revision rearms", function()
	simulated(function()
		local s = fixture() assert(s:Run().Verified)
		s.Root.Position = Vector3.new(100, 100, 0) s.Manager:Observe()
		assert(not s.Manager:OwnsLocation() and not s.Manager:Select() and #s.Commands == 0)
		s.Config.EGG_TRAVEL_SETTINGS.SELECTION_REVISION = 1
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true s:Standing()
		assert(s:Run().Verified and #s.Commands == 1)
		assert(s.Manager.Attempts["Selected Egg:0"] == 1 and s.Manager.Attempts["Selected Egg:1"] == 1)
	end)
end)

test("Manual movement, cancellation, pause and stale generations cannot position or restore", function()
	simulated(function()
		local s = fixture() s.Humanoid.MoveDirection = Vector3.new(1, 0, 0)
		assert(not s:Run().Verified and not s.Manager:OwnsLocation())
		s = fixture() s.Part.Position = Vector3.new(100, 100, 0) s:Standing()
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true s.Humanoid.MoveDirection = Vector3.new(1, 0, 0)
		assert(not s:Run().Verified and #s.Commands == 0, "Manual movement must block the final transform, not only invalidate arrival afterward")
		s = fixture() local owns, decision = s.Manager:Select() assert(owns)
		local definition = s.Manager:Definition(decision, 1)
		assert(definition.Id == "OC_GAMEPLAY" and definition.Owner == "EGG_TRAVEL" and definition.CanRun())
		s.Controller.Generation = 2 assert(not definition.CanRun())
		s.Cancelled = true assert(not definition.Execute(s.Token).Verified and #s.Commands == 0)
		s = fixture() assert(s:Run().Verified) s.Manager:Halt(false)
		assert(not s.Manager:OwnsLocation() and not s.Manager:Select())
		s.Manager:Halt(true) s.Manager:Destroy() s.Manager:Destroy()
		assert(not s.Manager:Select() and #s.Commands == 0 and s.Manager.OriginalPosition == nil)
	end)
end)

test("Wall-clock lease expiry releases ownership without resetting the request ledger", function()
	simulated(function(clock)
		local s = fixture() assert(s:Run().Verified)
		clock.Time = 121 s.Manager:Observe()
		assert(not s.Manager:OwnsLocation() and not s.Manager:Select() and s.Manager.Attempts["Selected Egg:0"] == 1)
	end)
end)

print("[OC TEST] " .. (tests - before) .. " selected-egg offline tests passed; physical geometry/server acceptance remain owner pending")
end

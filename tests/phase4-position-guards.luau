do
-- Actual mechanics adapter over synthetic CFrame/character/lease observations.
-- These checks never assign a real avatar or establish live game acceptance.
local before = tests
local Mechanics = requireOC("GameMechanics")
local nativeTypeof = typeof
typeof = function(value) return type(value) == "table" and value.SyntheticFrame and "CFrame" or nativeTypeof(value) end
local function frame(position)
	return { SyntheticFrame = true, Position = position, RightVector = Vector3.new(1, 0, 0), UpVector = Vector3.new(0, 1, 0), LookVector = Vector3.new(0, 0, -1) }
end
local function fixture()
	local s = { Assignments = 0, Validations = 0 }
	s.Token = { CheckCancelled = function() return s.Cancelled == true end }
	s.Root = setmetatable({ Position = Vector3.new(100, 0, 0) }, { __newindex = function(_, key, value)
		assert(key == "CFrame") s.Assignments += 1
		if s.AssignmentError then error("Synthetic HRP assignment error") end
		s.Root.Position = value.Position
	end })
	s.Controller = { State = "RUNNING", Generation = 1, Scheduler = { Active = { Definition = { Owner = "EGG_TRAVEL", Generation = 1 }, Token = s.Token } } }
	s.Frame = frame(Vector3.new(2, 0, 0))
	s.Record = { LeaseId = 1 }
	s.Manager = {
		Validate = function()
			s.Validations += 1 if s.OnValidate then s.OnValidate(s.Validations) end
			if s.Invalid then return nil, "Synthetic stale original model" end
			return { CharacterRoot = s.ChangedRoot or s.Root, NeedsNativeTravel = s.NeedsNativeTravel == true, InRange = s.InRange == true,
				Range = 16, RangeOrigin = { Position = Vector3.new(0, 0, 0) } }
		end,
		ResolveStanding = function() if s.OnStanding then s.OnStanding() end return s.Frame end,
		RangeEligibleAt = function() return s.RangeBlocked ~= true end,
	}
	s.Controller.EggTravel = s.Manager
	s.Mechanics = setmetatable({ LocalFeatureController = s.Controller,
		Config = config({ EGG_TRAVEL_SETTINGS = { ENABLE_SELECTED_EGG_TRAVEL = true, ENABLE_DIRECT_POSITIONING = true } }),
		LocalFeatureGuard = function() if s.OnGuard then s.OnGuard() end return true end }, Mechanics)
	function s:Position() return self.Mechanics:PositionSelectedEgg(self.Manager, self.Record, self.Frame, self.Token) end
	return s
end

test("Actual direct-position adapter treats assignment failure honestly and consumes its single attempt", function()
	local s = fixture() s.AssignmentError = true
	local assigned, reason = s:Position()
	assert(not assigned and reason:find("Synthetic HRP assignment error", 1, true) and s.Assignments == 1)
	assert(not s:Position() and s.Assignments == 1 and s.Mechanics.LastEggPositionLease == 1)
end)

test("Actual direct assignment reports pending observation rather than verified arrival", function()
	local s = fixture() local assigned, reason = s:Position()
	assert(assigned and s.Assignments == 1 and s.Root.Position == s.Frame.Position and reason:find("pending", 1, true))
end)

test("Actual adapter permits signed physical anchor coordinates without requiring hatch registration", function()
	local s = fixture() s.Frame = frame(Vector3.new(-10, -5, -79))
	local validate = s.Manager.Validate
	s.Manager.Validate = function(...)
		local fresh, reason = validate(...)
		if fresh then
			fresh.LocationOnly, fresh.LocationVerified, fresh.InteractionVerified = true, true, false
			fresh.Range, fresh.PhysicalRange, fresh.RangeOrigin = 6.5, 6.5, { Position = s.Frame.Position }
		end
		return fresh, reason
	end
	local assigned, reason = s:Position()
	assert(assigned and s.Assignments == 1 and s.Root.Position == s.Frame.Position and reason:find("pending", 1, true))
	assert(not s:Position() and s.Assignments == 1, "A physical-only location still gets one guarded assignment")
end)

test("Actual position adapter skips an already valid native range including entry during guards", function()
	for _, late in ipairs({ false, true }) do
		local s = fixture()
		if late then s.OnValidate = function(n) if n == 3 then s.InRange = true end end else s.InRange = true end
		assert(s:Position() and s.Assignments == 0)
	end
end)

test("Actual position adapter requires its exact scheduler token and generation before movement", function()
	for _, stale in ipairs({ "TOKEN", "GENERATION", "OWNER" }) do
		local s = fixture() local active = s.Controller.Scheduler.Active
		if stale == "TOKEN" then active.Token = {} elseif stale == "GENERATION" then active.Definition.Generation = 2 else active.Definition.Owner = "PETS" end
		assert(not s:Position() and s.Assignments == 0 and s.Validations == 0)
	end
end)

test("Actual scheduler cancellation or ownership change inside a yielding guard prevents assignment", function()
	for _, stale in ipairs({ "CANCELLED", "OWNER", "GENERATION", "CHARACTER" }) do
		local s = fixture()
		s.OnStanding = function()
			if stale == "CANCELLED" then s.Cancelled = true elseif stale == "OWNER" then s.Controller.Scheduler.Active = nil
			elseif stale == "GENERATION" then s.Controller.Generation = 2 else s.ChangedRoot = {} end
		end
		assert(not s:Position() and s.Assignments == 0)
	end
end)

test("Actual positioning rejects nonfinite transforms blocked ranges and unreached native areas", function()
	for _, invalid in ipairs({ "NAN", "RANGE", "AREA", "MODEL" }) do
		local s = fixture()
		if invalid == "NAN" then s.Frame = frame(Vector3.new(0/0, 0, 0)) elseif invalid == "RANGE" then s.RangeBlocked = true
		elseif invalid == "AREA" then s.NeedsNativeTravel = true else s.Invalid = true end
		assert(not s:Position() and s.Assignments == 0)
	end
end)

test("Actual native area adapter logs its exact dispatch then verifies observed stable arrival", function()
	simulated(function()
		local s = fixture() local events = {}
		s.NeedsNativeTravel = true s.Mechanics.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL = true s.Mechanics.LastTravelAt = -math.huge
		local path = "Workspace.Worlds.The Overworld.Islands.Zen.Island.Portal.Spawn"
		local destination = { Parent = true, Position = Vector3.new(0, 9500, 0), IsDescendantOf = function() return true end }
		local validate = s.Manager.Validate
		s.Manager.Validate = function(...)
			local fresh, reason = validate(...)
			if fresh then fresh.World, fresh.Island, fresh.NativeAreaKnown, fresh.DestinationPath, fresh.Destination = "The Overworld", "Zen", true, path, destination end
			return fresh, reason
		end
		s.Manager.DiagnosticTrace = function(_, stage, fresh, reason)
			assert(stage == "AREA_TRAVEL_REQUESTED" and type(fresh) == "table" and fresh.DestinationPath == path and reason:find(path, 1, true))
			table.insert(events, "REQUESTED")
		end
		s.Mechanics.Unlocked = function() return true end
		s.Mechanics.Reader = { _dependency = function()
			return { FireServer = function(_, command, actualPath)
				assert(command == "Teleport" and actualPath == path) table.insert(events, "FIRE")
				s.NeedsNativeTravel = false s.Root.Position = destination.Position
			end }
		end }
		local arrived, reason = s.Mechanics:TravelSelectedEgg(s.Manager, s.Record, s.Token)
		assert(arrived and reason:find("arrival observed", 1, true) and table.concat(events, ",") == "REQUESTED,FIRE" and s.Assignments == 0)
	end)
end)

test("Actual native area dispatch rechecks scheduler authority after dependency loading", function()
	local s = fixture() local calls = 0 s.NeedsNativeTravel = true
	s.Mechanics.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL = true s.Mechanics.LastTravelAt = -math.huge
	local validate = s.Manager.Validate
	s.Manager.Validate = function(...)
		local fresh, reason = validate(...)
		if fresh then fresh.World, fresh.Island, fresh.NativeAreaKnown, fresh.DestinationPath = "The Overworld", "Zen", true, "Workspace.Worlds.The Overworld.Islands.Zen.Island.Portal.Spawn" end
		return fresh, reason
	end
	s.Mechanics.Unlocked = function() return true end
	s.Mechanics.Reader = { _dependency = function()
		s.Controller.Scheduler.Active = nil
		return { FireServer = function() calls += 1 end }
	end }
	assert(not s.Mechanics:TravelSelectedEgg(s.Manager, s.Record, s.Token) and calls == 0 and s.Assignments == 0)
end)

typeof = nativeTypeof
print("[OC TEST] " .. tostring(tests-before) .. " real adapter positioning guards passed; synthetic observations only")
end

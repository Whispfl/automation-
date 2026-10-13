do
-- Production positioning adapter and arrival observer over synthetic geometry.
-- These checks prove guarded dispatch/observation behavior, never live acceptance.
local before = tests
local Travel, Adapter = requireOC("EggTravelManager"), requireOC("GameMechanics")
local originalTypeof = typeof
typeof = function(value)
	return type(value) == "table" and value.SyntheticStandingFrame and "CFrame" or originalTypeof(value)
end

local function frame(position)
	return { SyntheticStandingFrame = true, Position = position,
		RightVector = Vector3.new(1, 0, 0), UpVector = Vector3.new(0, 1, 0), LookVector = Vector3.new(0, 0, -1) }
end

local function dispatchFixture()
	local s = { Assignments = 0, Validations = 0, Guards = 0, Logs = {}, Commands = {}, Character = {},
		Balances = { Coins = 7267071, Gems = 1847585 } }
	s.Config = Resolver.Resolve(Defaults, {
		PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = false, AUTO_EQUIP = false },
		HATCH_SETTINGS = { EGG_SELECTION_MODE = "MANUAL", SELECTED_EGGS = { "Common Egg" }, MAXIMUM_EGG_COST = 0, MAXIMUM_SESSION_COST = 0 },
		EGG_TRAVEL_SETTINGS = { MODE = "TRAVEL_ONLY", ENABLE_SELECTED_EGG_TRAVEL = true, ENABLE_DIRECT_POSITIONING = true,
			ENABLE_NATIVE_ISLAND_TRAVEL = false, STABILITY_SECONDS = 1, ARRIVAL_TIMEOUT_SECONDS = 2 },
	})
	s.Token = { CheckCancelled = function() return s.Cancelled == true end }
	s.Model = { Name = "Common Egg", Parent = true, GetFullName = function() return "Workspace.Rendered.Chunker.Common Egg" end }
	s.Duplicate = { Name = "Common Egg", Parent = s.Model.Parent, GetFullName = s.Model.GetFullName }
	s.Target = { Parent = s.Model, Position = Vector3.new(-10, 12, -79),
		IsA = function(_, kind) return kind == "BasePart" end, IsDescendantOf = function() return true end }
	s.Frame = frame(Vector3.new(-10, 3.15, -79))
	s.ActualFrame = frame(Vector3.new(-10, 3.15, -130))
	s.Root = setmetatable({ Parent = s.Character, Position = s.ActualFrame.Position, Size = Vector3.new(2, 2, 1) }, {
		__index = function(_, key) if key == "CFrame" then return s.ActualFrame end end,
		__newindex = function(_, key, value)
			assert(key == "CFrame", "Synthetic HRP only observes the protected CFrame assignment")
			s.Assignments += 1
			if s.AssignmentError then error("Synthetic standing assignment failure") end
			s.ActualFrame = value s.Root.Position = s.CorrectedPosition or value.Position
		end,
	})
	s.Humanoid = { MoveDirection = Vector3.new(0, 0, 0), HipHeight = 2 }
	s.Controller = { State = "RUNNING", Generation = 1, Config = s.Config,
		Log = function(_, kind, message) table.insert(s.Logs, kind .. " " .. message) end,
		Farming = { Mechanics = {} }, Scheduler = { Active = { Definition = { Owner = "EGG_TRAVEL", Generation = 1 }, Token = s.Token } } }
	s.Manager = Travel.new(s.Controller) s.Controller.EggTravel = s.Manager
	s.Record = { LeaseId = 1, SelectionKey = "STANDING_DISPATCH", Generation = 1, Scope = "TRAVEL_ONLY", Status = "PLANNED",
		EggName = "Common Egg", Model = s.Model, IdentityId = "I0001", LocationOnly = true, LocationVerified = true,
		TargetRoot = s.Target, RangeOrigin = s.Target, TargetPosition = s.Target.Position, RangeOriginPosition = s.Target.Position,
		Character = s.Character, CharacterRoot = s.Root, Humanoid = s.Humanoid, World = "The Overworld", CurrentWorld = "The Overworld",
		Range = 6.5, PhysicalRange = 6.5, Deadline = os.clock() + 100, StartedAt = os.clock(), Distance = 51,
		NeedsNativeTravel = false }
	s.Proof = { Model = s.Model, TargetRoot = s.Target, Character = s.Character, CharacterRoot = s.Root,
		Frame = s.Frame, Support = { Name = "Observed support" }, StandingPosition = s.Frame.Position }
	s.Record.StandingDestination = s.Proof
	s.Manager.Lease, s.Manager.DiagnosticConsumed = s.Record, true
	s.Manager.BrainIntent = { Scope = "TRAVEL_ONLY", EggName = "Common Egg", Model = s.Model }
	-- Standing geometry itself is covered by the real-resolver suite. This fake
	-- models its accepted support pose so the real adapter must honor that result.
	s.Manager.RangeEligibleAt = function(_, record, position)
		assert(record.Model == s.Model and record.TargetRoot == s.Target)
		return not s.RangeBlocked and math.abs(position.Y - s.Frame.Position.Y) <= 0.5
			and Vector3.new(position.X - s.Frame.Position.X, 0, position.Z - s.Frame.Position.Z).Magnitude <= 6.5
	end
	s.Manager.ResolveStanding = function(_, record)
		assert(record.Model == s.Model and record.TargetRoot == s.Target)
		assert(record.StandingDestination == s.Proof, "The exact selected standing evidence must survive every guard")
		if s.OnStanding then s.OnStanding() end
		if s.StandingBlocked then return nil, "Synthetic collidable obstruction" end
		return s.Frame, nil, s.Proof
	end
	s.Manager.Validate = function(_, record, token)
		s.Validations += 1 if s.OnValidate then s.OnValidate(s.Validations) end
		if not s.Manager.Lease then return nil, "Synthetic travel lease already released" end
		if s.Cancelled or s.Controller.State ~= "RUNNING" or token:CheckCancelled() then return nil, "Synthetic cancelled task" end
		if s.TargetChanged then return nil, "Selected exact physical original changed" end
		local fresh = table.clone(record)
		fresh.CharacterRoot, fresh.TargetRoot = s.Root, s.Target
		fresh.InRange = s.Manager:RangeEligibleAt(fresh, s.Root.Position)
		fresh.Distance = (s.Root.Position - s.Target.Position).Magnitude
		return fresh
	end
	s.Manager.HatchInteractionAt = function() s.InteractionChecks = (s.InteractionChecks or 0) + 1 return false, "Exact native hatch registration unverified" end
	s.Mechanics = setmetatable({ Config = s.Config, LocalFeatureController = s.Controller,
		LocalFeatureGuard = function()
			s.Guards += 1 if s.OnGuard then s.OnGuard(s.Guards) end
			return not s.ForegroundBlocked, s.ForegroundBlocked and "Synthetic foreground obstruction" or nil
		end,
		Reader = { _dependency = function() return { FireServer = function(_, command) table.insert(s.Commands, command) end } end },
	}, Adapter)
	s.Controller.Farming.Mechanics = s.Mechanics
	function s:Position() return self.Mechanics:PositionSelectedEgg(self.Manager, self.Record, self.Frame, self.Token) end
	function s:Execute() return self.Manager:Execute(self.Record, self.Token) end
	return s
end

test("Real adapter honors a verified physical standing pose below an elevated egg anchor", function()
	local s = dispatchFixture()
	assert((s.Frame.Position - s.Target.Position).Magnitude > s.Record.Range)
	local assigned, reason = s:Position()
	assert(assigned and s.Assignments == 1 and s.Root.Position == s.Frame.Position and reason:find("pending", 1, true))
	assert(#s.Commands == 0 and s.Balances.Coins == 7267071 and s.Balances.Gems == 1847585)
end)

test("Paid native travel retains its actual three dimensional hatch range", function()
	local s = dispatchFixture() s.Record.LocationOnly = false
	local assigned = s:Position()
	assert(not assigned and s.Assignments == 0 and #s.Commands == 0)
end)

test("Real direct standing assignment failure is honest and cannot dispatch again", function()
	local s = dispatchFixture() s.AssignmentError = true
	local assigned, reason = s:Position()
	assert(not assigned and s.Assignments == 1 and reason:find("Synthetic standing assignment failure", 1, true))
	assert(not s:Position() and s.Assignments == 1 and #s.Commands == 0)
end)

test("Uncleared or out of policy standing destination never reaches the CFrame assignment", function()
	for _, condition in ipairs({ "CLEARANCE", "RANGE" }) do
		local s = dispatchFixture()
		if condition == "CLEARANCE" then s.StandingBlocked = true else s.RangeBlocked = true end
		assert(not s:Position() and s.Assignments == 0 and #s.Commands == 0)
	end
end)

test("Final scheduler and cancellation guards suppress a previously cleared standing pose", function()
	for _, condition in ipairs({ "PAUSE", "CANCEL", "OWNER", "GENERATION", "TARGET" }) do
		local s = dispatchFixture()
		s.OnStanding = function()
			if condition == "PAUSE" then s.Controller.State = "PAUSED" elseif condition == "CANCEL" then s.Cancelled = true
			elseif condition == "OWNER" then s.Controller.Scheduler.Active.Definition.Owner = "PETS"
			elseif condition == "GENERATION" then s.Controller.Generation = 2 else s.TargetChanged = true end
		end
		assert(not s:Position() and s.Assignments == 0 and #s.Commands == 0)
	end
end)

test("A support or standing evidence change in final guards blocks actual assignment", function()
	for _, condition in ipairs({ "SUPPORT", "EVIDENCE" }) do
		local s = dispatchFixture() local standingChecks = 0
		if condition == "SUPPORT" then
			s.OnStanding = function()
				standingChecks += 1
				if standingChecks == 2 then s.StandingBlocked = true end
			end
		else
			s.OnValidate = function(n)
				if n == 3 then s.Record.StandingDestination = { Frame = s.Frame } end
			end
		end
		assert(not s:Position() and s.Assignments == 0 and not s.Record.DirectPositionAttempted and #s.Commands == 0)
	end
end)

test("Exact selected physical Instance stays selected despite identical names and paths", function()
	local s = dispatchFixture()
	assert(s.Model ~= s.Duplicate and s.Model:GetFullName() == s.Duplicate:GetFullName())
	assert(s:Position() and s.Assignments == 1 and s.Manager.BrainIntent.Model == s.Model and s.Record.Model == s.Model)
end)

test("Real physical arrival waits for observed stability after the single guarded assignment", function()
	simulated(function()
		local s = dispatchFixture() local started = os.clock()
		local result = s:Execute()
		assert(result.Verified and os.clock() - started >= s.Config.EGG_TRAVEL_SETTINGS.STABILITY_SECONDS)
		assert(s.Assignments == 1 and s.Manager.LastResult.PhysicalArrivalVerified and s.Manager.LastResult.Status == "PHYSICAL_ARRIVAL_OBSERVED")
		assert(not s.Manager.LastResult.InteractionVerified and s.Manager.LastResult.HatchInteraction == "HATCH_INTERACTION_UNVERIFIED")
		assert(s.Manager.DiagnosticEnded and not s.Manager.Lease and #s.Commands == 0)
		assert(s.Manager.LastResult.HatchCommands == 0 and s.Manager.LastResult.Spending == 0)
		assert(not s:Position() and s.Assignments == 1, "One observed arrival must not permit a second assignment")
	end)
end)

test("Server correction within broad physical vicinity fails the requested standing arrival", function()
	simulated(function()
		local s = dispatchFixture() s.CorrectedPosition = s.Frame.Position + Vector3.new(3, 0, 0)
		local result = s:Execute()
		assert(not result.Verified and s.Assignments == 1 and s.Manager.DiagnosticEnded)
		assert(s.Manager.LastResult.Status == "HALTED" and not s.Manager.LastResult.PhysicalArrivalVerified)
		assert(not s:Position() and s.Assignments == 1 and #s.Commands == 0)
	end)
end)

test("Server correction to the elevated anchor is not physical standing arrival", function()
	simulated(function()
		local s = dispatchFixture() s.CorrectedPosition = s.Target.Position
		assert(not s:Execute().Verified and s.Assignments == 1 and s.Manager.DiagnosticEnded)
		assert(not s.Manager.LastResult.PhysicalArrivalVerified and #s.Commands == 0)
	end)
end)

test("Actual same name replacement interrupts pending arrival without position restoration", function()
	simulated(function()
		local s = dispatchFixture()
		s.OnValidate = function() if s.Assignments > 0 then s.TargetChanged = true end end
		assert(not s:Execute().Verified and s.Assignments == 1 and s.Manager.DiagnosticEnded and #s.Commands == 0)
		assert(s.Manager.LastResult.Reason:find("exact physical original changed", 1, true))
	end)
end)

typeof = originalTypeof
print("[OC TEST] " .. tostring(tests - before) .. " real standing dispatch/arrival regressions passed; owner live result pending")
end

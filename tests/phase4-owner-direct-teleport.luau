-- Actual isolated adapter over synthetic Workspace/account/physics observations.
-- No live transport or physics claim: the owner runs the single live experiment.
local Travel, Mechanics = requireOC("EggTravelManager"), requireOC("GameMechanics")
local checked = 0
local function test(name, callback)
	callback()
	checked += 1
	print("[OC OWNER DIRECT] " .. name .. " PASS")
end
local function part(name, position, parent)
	return { Name = name, Position = position, Parent = parent or workspace,
		IsA = function(_, kind) return kind == "BasePart" or kind == "Part" end,
		IsDescendantOf = function(self) return self.Parent ~= nil end }
end
local function fixture()
	local s = { Time = 100, Assignments = 0, GuardCalls = 0, ResolveCalls = 0, Commands = {}, Logs = {},
		Profile = { WorldsUnlocked = { ["The Overworld"] = true }, AreasUnlocked = {}, EggsOpened = {} } }
	os.clock = function() return s.Time end
	task.wait = function(seconds) s.Time += seconds or 0.1 if s.OnWait then s.OnWait() end end
	s.Config = Resolver.Resolve(Defaults, ownerDirectOverrides())
	s.Character = {}
	s.Humanoid = { HipHeight = 2, MoveDirection = Vector3.new(0, 0, 0) }
	s.Root = part("HumanoidRootPart", Vector3.new(83, 12, 0), s.Character)
	s.Root.Size = Vector3.new(2, 2, 1)
	setmetatable(s.Root, { __index = function(_, key) if key == "CFrame" then return s.RootFrame or CFrame.new(s.Root.Position) end end,
		__newindex = function(object, key, value)
			if key == "CFrame" then
				s.Assignments += 1 s.AssignedFrame = value
				if s.AssignmentError then error("Synthetic CFrame assignment rejected") end
				s.RootFrame = value s.Root.Position = value.Position + (s.PhysicsOffset or Vector3.new(0, 0, 0))
				if s.OnAssignment then s.OnAssignment() end
			else rawset(object, key, value) end
		end })
	s.Player = { UserId = 10864747620, Character = s.Character }
	s.Target = part("Root", Vector3.new(0, 12, 0))
	s.Prompt = part("Prompt", s.Target.Position)
	s.Model = { Name = "Common Egg", Parent = workspace,
		IsDescendantOf = function(self) return self.Parent ~= nil end,
		FindFirstChild = function(_, name) if name == "Root" then return s.Target elseif name == "Prompt" then return s.Prompt end end }
	s.Record = { SelectionKey = "Common Egg:0", EggName = "Common Egg", Model = s.Model,
		IdentityId = "SYNTHETIC_SESSION_INSTANCE", IdentityEvidence = "EXACT_NATIVE_ORIGINAL",
		LocationOnly = true, LocationVerified = true, LocationEvidence = "EXACT_PHYSICAL_ORIGINAL",
		TargetRoot = s.Target, TargetPosition = s.Target.Position, PromptPart = s.Prompt, PromptPosition = s.Prompt.Position,
		RangeOrigin = s.Target, RangeOriginPosition = s.Target.Position, Range = 6.5, PhysicalRange = 6.5,
		Character = s.Character, CharacterRoot = s.Root, Humanoid = s.Humanoid,
		World = "The Overworld", CurrentWorld = "The Overworld", NativeAreaKnown = true, NeedsNativeTravel = false,
		LeaseId = 1, Generation = 1, Deadline = s.Time + 120, Status = "READY" }
	s.Controller = { Config = s.Config, State = "RUNNING", Generation = 1,
		Reader = { Player = s.Player, GetLiveProfile = function() return s.Profile end,
			GetSnapshot = function() return { Ready = true } end },
		Brain = requireOC("OCBrain").new(s.Config), Log = function(_, kind, message) table.insert(s.Logs, kind .. " | " .. message) end }
	s.Manager = Travel.new(s.Controller) s.Controller.EggTravel = s.Manager
	s.Manager.Lease, s.Manager.DiagnosticConsumed, s.Manager.DiagnosticEnded = s.Record, true, false
	s.Manager.BrainUserId = s.Player.UserId
	s.Manager.BrainIntent = { Kind = "EGG_TRAVEL", Scope = "TRAVEL_ONLY", DecisionSource = "BRAIN_TRAVEL_DIAGNOSTIC",
		SelectionMode = "MANUAL", EggName = "Common Egg", Model = s.Model, World = "The Overworld",
		Generation = 1, SelectionRevision = 0, GoalId = "TRAVEL_ONLY_DIAGNOSTIC" }
	s.Manager.Resolve = function(_, force)
		s.ResolveCalls += 1
		if s.OnResolve then s.OnResolve(s.ResolveCalls, force) end
		if s.InvalidAccess then return nil, "Synthetic current native access invalid" end
		local fresh = table.clone(s.Record)
		fresh.Model, fresh.TargetRoot, fresh.CharacterRoot = s.OtherModel or s.Model, s.OtherTarget or s.Target, s.OtherRoot or s.Root
		fresh.World, fresh.CurrentWorld = s.World or "The Overworld", s.CurrentWorld or "The Overworld"
		fresh.NeedsNativeTravel = s.NeedsNativeTravel == true
		fresh.LocationVerified = not s.Unverified
		fresh.TargetPosition, fresh.RangeOriginPosition = s.Target.Position, s.Target.Position
		fresh.Distance, fresh.RootDistance = (s.Root.Position - s.Target.Position).Magnitude, (s.Root.Position - s.Target.Position).Magnitude
		fresh.InRange = fresh.Distance <= 6.5
		return fresh
	end
	s.Manager.ResolveStanding = function() error("Owner direct experiment must not perform standing search") end
	s.Manager.HatchInteractionAt = function(_, record, position)
		assert(record.Model == s.Model and record.TargetRoot == s.Target)
		if s.OnInteraction then s.OnInteraction() end
		if s.NativeRangeBlocked then return false, "SYNTHETIC_NATIVE_RANGE_NOT_ACHIEVED" end
		return true, "SYNTHETIC_NATIVE_RANGE_OBSERVED", { Model = s.HatchModelReplacement or s.Model, TargetRoot = s.HatchRootReplacement or s.Target,
			Range = s.NativeRange or 6.5, RangeOrigin = s.Target }
	end
	s.Manager.RangeEligibleAt = function(_, native, position, force)
		assert(native.Model == s.Model and native.TargetRoot == s.Target and force == true)
		s.NativeEligibilityQueries = (s.NativeEligibilityQueries or 0) + 1
		if s.OnNativeEligibility then s.OnNativeEligibility() end
		if s.NearestChanged then return false, "SYNTHETIC_ANOTHER_NEAREST_EGG" end
		if s.PromptChanged then return false, "SYNTHETIC_PROMPT_VISIBLE" end
		if (position - native.RangeOrigin.Position).Magnitude > native.Range then return false, "SYNTHETIC_OUTSIDE_NATIVE_RANGE" end
		return true
	end
	s.Token = { CheckCancelled = function() return s.Cancelled == true end }
	s.Controller.Scheduler = { Active = { Definition = { Owner = "EGG_TRAVEL", Generation = 1 }, Token = s.Token } }
	s.Mechanics = setmetatable({ Config = s.Config, Player = s.Player, Reader = s.Controller.Reader,
		LocalFeatureController = s.Controller, LocalFeatureGuard = function()
			s.GuardCalls += 1 if s.OnGuard then s.OnGuard(s.GuardCalls) end return s.GuardBlocked ~= true, "Synthetic foreground guard blocks"
		end }, Mechanics)
	s.Controller.Farming = { Mechanics = s.Mechanics, Tracker = { Root = function() return s.Root, s.Humanoid end } }
	workspace.Raycast = function() error("Owner direct experiment must not raycast") end
	workspace.GetPartBoundsInBox = function() error("Owner direct experiment must not query avatar clearance") end
	function s:Run() return self.Manager:Execute(self.Record, self.Token) end
	function s:HasLog(fragment)
		for _, message in ipairs(self.Logs) do if message:find(fragment, 1, true) then return true end end
		return false
	end
	return s
end

test("Exact owner direct Root assignment bypasses standing and observes stable arrival without gameplay commands", function()
	local s = fixture()
	local result = s:Run()
	assert(result.Verified and s.Assignments == 1 and s.AssignedFrame.Position == s.Target.Position)
	assert(s.Manager.LastResult.PhysicalArrivalVerified and s.Manager.LastResult.InteractionVerified)
	assert(s.Manager.LastResult.HatchCommands == 0 and s.Manager.LastResult.Spending == 0 and #s.Commands == 0)
	assert(s.Manager.DiagnosticEnded and s.Manager.Lease == nil)
end)

test("Disabled option and ordinary movement mode cannot enter isolated adapter", function()
	for _, change in ipairs({ "FLAG", "NORMAL", "DIRECT", "NATIVE_TRAVEL" }) do
		local s = fixture()
		if change == "FLAG" then s.Config.EGG_TRAVEL_SETTINGS.OWNER_DIRECT_EGG_TELEPORT_TEST = false
		elseif change == "NORMAL" then s.Config.EGG_TRAVEL_SETTINGS.MODE = "NORMAL"
		elseif change == "DIRECT" then s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = false
		else s.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL = true end
		local result = s.Mechanics:ExecuteOwnerDirectEggTeleportTest(s.Manager, s.Record, s.Token)
		assert(not result.Verified and s.Assignments == 0)
	end
end)

test("Wrong and missing accounts fail before assignment", function()
	for _, id in ipairs({ 0, 1, 10864747621 }) do
		local s = fixture() s.Player.UserId = id
		assert(not s:Run().Verified and s.Assignments == 0)
	end
	local s = fixture() s.Player.UserId = nil
	assert(not s:Run().Verified and s.Assignments == 0)
end)

test("Wrong egg world unresolved original and same-name replacement retain exact identity guards", function()
	for _, invalid in ipairs({ "EGG", "WORLD", "CURRENT_WORLD", "UNVERIFIED", "MODEL", "ROOT", "TARGET", "ACCESS", "AREA" }) do
		local s = fixture()
		if invalid == "EGG" then s.Record.EggName = "Spotted Egg"
		elseif invalid == "WORLD" then s.World = "Seven Seas"
		elseif invalid == "CURRENT_WORLD" then s.CurrentWorld = "Seven Seas"
		elseif invalid == "UNVERIFIED" then s.Unverified = true
		elseif invalid == "MODEL" then s.OtherModel = table.clone(s.Model)
		elseif invalid == "ROOT" then s.OtherRoot = table.clone(s.Root)
		elseif invalid == "TARGET" then s.OtherTarget = table.clone(s.Target)
		elseif invalid == "ACCESS" then s.InvalidAccess = true
		else s.NeedsNativeTravel = true end
		assert(not s:Run().Verified and s.Assignments == 0, invalid)
	end
end)

test("Positive unrelated permissions and spending budgets cannot use owner direct experiment", function()
	for _, mutation in ipairs({
		{ "PET_SETTINGS", "AUTO_HATCH", true }, { "PET_SETTINGS", "AUTO_EQUIP", true },
		{ "OWNER_ONE_HATCH_TEST_SETTINGS", "OWNER_ONE_HATCH_TEST_ALLOWANCE", true },
		{ "HATCH_SETTINGS", "MAXIMUM_SESSION_COST", 10 }, { "HATCH_SETTINGS", "MAXIMUM_EGG_COST", 10 },
		{ "UPGRADE_SETTINGS", "MAXIMUM_PURCHASE_COST", 10 }, { "WORLD_SETTINGS", "MAXIMUM_WORLD_UNLOCK_COST", 10 },
		{ "PICKUP_SETTINGS", "BULK_COLLECT_PICKUPS", true }, { "FARMING_SETTINGS", "AUTO_RESOURCE_FARM", true },
		{ "BUBBLE_SETTINGS", "AUTO_BLOW_BUBBLES", true },
	}) do
		local s = fixture() s.Config[mutation[1]][mutation[2]] = mutation[3]
		assert(not s:Run().Verified and s.Assignments == 0, mutation[1] .. "." .. mutation[2])
	end
end)

test("Cancellation wrong token scheduler generation lease and consumed permission prevent assignment", function()
	for _, change in ipairs({ "CANCEL", "TOKEN", "SCHEDULER", "GENERATION", "LEASE", "CONSUMED" }) do
		local s = fixture()
		if change == "CANCEL" then s.Cancelled = true
		elseif change == "TOKEN" then s.Controller.Scheduler.Active.Token = {}
		elseif change == "SCHEDULER" then s.Controller.Scheduler.Active.Definition.Owner = "PETS"
		elseif change == "GENERATION" then s.Controller.Generation = 2
		elseif change == "LEASE" then s.Manager.Lease = nil
		else s.Mechanics.OwnerDirectEggTeleportConsumed = true end
		assert(not s:Run().Verified and s.Assignments == 0, change)
	end
end)

test("Cancellation account and identity changes inside final validation cancel assignment", function()
	for _, change in ipairs({ "CANCEL", "ACCOUNT", "MODEL", "ROOT", "ACCESS", "SCHEDULER", "FLAG" }) do
		local s = fixture()
		s.OnResolve = function(call)
			if call ~= 1 then return end
			if change == "CANCEL" then s.Cancelled = true
			elseif change == "ACCOUNT" then s.Player.UserId = 1
			elseif change == "MODEL" then s.OtherModel = table.clone(s.Model)
			elseif change == "ROOT" then s.OtherRoot = table.clone(s.Root)
			elseif change == "ACCESS" then s.InvalidAccess = true
			elseif change == "SCHEDULER" then s.Controller.Scheduler.Active = nil
			else s.Config.EGG_TRAVEL_SETTINGS.OWNER_DIRECT_EGG_TELEPORT_TEST = false end
		end
		assert(not s:Run().Verified and s.Assignments == 0, change)
	end
end)

test("A genuine yielding foreground guard is followed by cancellation and ownership checks", function()
	for _, change in ipairs({ "CANCEL", "ACCOUNT", "SCHEDULER" }) do
		local s = fixture() s.OnGuard = function(call) if call == 1 then coroutine.yield("GUARD_SUSPENDED") end end
		local result
		local thread = coroutine.create(function() result = s:Run() end)
		local ok, signal = coroutine.resume(thread) assert(ok and signal == "GUARD_SUSPENDED" and s.Assignments == 0)
		if change == "CANCEL" then s.Cancelled = true elseif change == "ACCOUNT" then s.Player.UserId = 1 else s.Controller.Scheduler.Active = nil end
		ok, signal = coroutine.resume(thread) assert(ok, signal)
		assert(coroutine.status(thread) == "dead" and not result.Verified and s.Assignments == 0)
	end
end)

test("Assignment failure consumes the one owner attempt and cannot retry with a changed revision", function()
	local s = fixture() s.AssignmentError = true
	assert(not s:Run().Verified and s.Assignments == 1)
	s.AssignmentError = false s.Config.EGG_TRAVEL_SETTINGS.SELECTION_REVISION = 20
	local result = s.Mechanics:ExecuteOwnerDirectEggTeleportTest(s.Manager, s.Record, s.Token)
	assert(not result.Verified and s.Assignments == 1 and s.Manager.DiagnosticEnded)
end)

test("Successful movement consumes permission across pause resume and direct reentry", function()
	local s = fixture() assert(s:Run().Verified and s.Assignments == 1)
	s.Controller.State = "PAUSED" s.Controller.State = "RUNNING"
	local result = s.Mechanics:ExecuteOwnerDirectEggTeleportTest(s.Manager, s.Record, s.Token)
	assert(not result.Verified and s.Assignments == 1)
	local selected = s.Manager:Select(nil, s.Manager.BrainIntent)
	assert(not selected and s.Assignments == 1)
end)

test("Native hatch interaction failure is reported separately from physical arrival without a hatch", function()
	local s = fixture() s.NativeRangeBlocked = true
	local result = s:Run()
	assert(result.Verified and s.Assignments == 1 and s.Manager.LastResult.PhysicalArrivalVerified)
	assert(not s.Manager.LastResult.InteractionVerified and s:HasLog("SYNTHETIC_NATIVE_RANGE_NOT_ACHIEVED"))
	assert(s.Manager.LastResult.HatchCommands == 0 and s.Manager.LastResult.Spending == 0)
end)

test("Physics displacement within physical radius can be observed honestly without restoring Root coordinates", function()
	local s = fixture() s.PhysicsOffset = Vector3.new(2, 0, 0)
	local result = s:Run()
	assert(result.Verified and s.Assignments == 1 and (s.Root.Position - s.Target.Position).Magnitude == 2)
	assert(s.Root.Position ~= s.AssignedFrame.Position and s.Manager.LastResult.PhysicalArrivalVerified)
end)

test("Opened native interaction range can be reported beyond diagnostic physical policy without inventing physical containment", function()
	local s = fixture() s.PhysicsOffset = Vector3.new(10, 0, 0) s.NativeRange = 16
	local result = s:Run()
	assert(result.Verified and result.InteractionVerified and s.Assignments == 1)
	assert(s.Manager.LastResult.Status == "OWNER_DIRECT_NATIVE_ARRIVAL_OBSERVED")
	assert(s.Manager.LastResult.PhysicalPolicyInRange == false and s.Manager.LastResult.Distance == 10)
	assert(s.Manager.LastResult.ObservedDisplacement == 10 and s.Manager.LastResult.MovementObserved)
end)

test("Position changes during native interaction observation invalidate stale range proof", function()
	local s = fixture()
	s.OnInteraction = function() s.Root.Position = s.Target.Position + Vector3.new(20, 0, 0) end
	local result = s:Run()
	assert(not result.Verified and not result.InteractionVerified and s.Assignments == 1)
	assert(s.Manager.LastResult.MaximumObservedDisplacement == 20 and s.Manager.LastResult.PhysicalPolicyInRange == false)
end)

test("Prompt and nearest-egg changes during final observation block native eligibility rather than claiming it", function()
	for _, change in ipairs({ "PROMPT", "NEAREST" }) do
		local s = fixture()
		s.OnResolve = function(call)
			if call ~= 3 then return end
			if change == "PROMPT" then s.PromptChanged = true else s.NearestChanged = true end
		end
		local result = s:Run()
		assert(result.Verified and not result.InteractionVerified and s.Assignments == 1)
		assert(s.NativeEligibilityQueries and s.NativeEligibilityQueries > 0)
		assert(s.Manager.LastResult.PhysicalPolicyInRange and not s.Manager.LastResult.InteractionVerified)
		assert(s:HasLog(change == "PROMPT" and "SYNTHETIC_PROMPT_VISIBLE" or "SYNTHETIC_ANOTHER_NEAREST_EGG"))
	end
end)

test("Range query return cannot certify a character that escaped or fell while that query ran", function()
	for _, offset in ipairs({ Vector3.new(20, 0, 0), Vector3.new(0, -30, 0) }) do
		local s = fixture()
		s.OnNativeEligibility = function() s.Root.Position = s.Target.Position + offset end
		local result = s:Run()
		assert(not result.Verified and not result.InteractionVerified and s.Assignments == 1)
		assert(s.Manager.LastResult.PhysicalPolicyInRange == false)
		assert(s.Manager.LastResult.MaximumObservedDisplacement == offset.Magnitude)
	end
end)

test("Same-name native interaction replacement is not the exact selected physical Instance", function()
	for _, changed in ipairs({ "MODEL", "ROOT" }) do
		local s = fixture()
		if changed == "MODEL" then s.HatchModelReplacement = table.clone(s.Model) else s.HatchRootReplacement = table.clone(s.Target) end
		local result = s:Run()
		assert(result.Verified and not result.InteractionVerified and s.Assignments == 1)
		assert(not s.NativeEligibilityQueries, "Mismatched native Instance must fail before querying its range")
	end
end)

test("Physics escape and fall outside physical range time out without retries or snap-back", function()
	for _, offset in ipairs({ Vector3.new(20, 0, 0), Vector3.new(0, -30, 0) }) do
		local s = fixture() s.PhysicsOffset = offset
		local result = s:Run()
		assert(not result.Verified and s.Assignments == 1 and s.Manager.DiagnosticEnded)
		assert(s.Root.Position == s.Target.Position + offset and s.Manager.LastResult.HatchCommands == 0)
	end
end)

test("Post-assignment cancellation and manual movement halt observation without any additional assignment", function()
	for _, change in ipairs({ "CANCEL", "INPUT", "ACCESS", "ACCOUNT" }) do
		local s = fixture()
		s.OnWait = function()
			if change == "CANCEL" then s.Cancelled = true
			elseif change == "INPUT" then s.Humanoid.MoveDirection = Vector3.new(1, 0, 0)
			elseif change == "ACCESS" then s.InvalidAccess = true
			else s.Player.UserId = 1 end
		end
		assert(not s:Run().Verified and s.Assignments == 1 and s.Manager.DiagnosticEnded, change)
	end
end)

test("Unloaded or nonfinite physical target cannot receive direct positioning", function()
	for _, change in ipairs({ "UNLOADED", "NAN", "INFINITY" }) do
		local s = fixture()
		if change == "UNLOADED" then s.Target.Parent = nil
		elseif change == "NAN" then s.Target.Position = Vector3.new(0 / 0, 12, 0)
		else s.Target.Position = Vector3.new(math.huge, 12, 0) end
		assert(not s:Run().Verified and s.Assignments == 0, change)
	end
end)

assert(checked == 20, "All owner direct audit groups must execute")
print("[OC OWNER DIRECT] " .. checked .. " actual-source audit groups PASS; one owner Root assignment; exact identity/account/access/cancellation; zero spending and no gameplay requests. Synthetic observation is not live physics acceptance.")

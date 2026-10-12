do
-- Synthetic Brain-to-travel boundaries. Native movement/financial acceptance
-- remains owner-tested; this file never ships in the client bundle.
local before = tests
local Travel = requireOC("EggTravelManager")

local function integrationFixture()
	local s = { Profile = { Coins = 1000, WorldsUnlocked = { ["The Overworld"] = true },
		AreasUnlocked = { Zen = true }, EggsOpened = {} }, Commands = {}, Logs = {},
		Character = {}, Currency = "Coins", CurrentWorld = "The Overworld", Loaded = true, Authorized = true }
	s.Root = { Parent = s.Character, Position = Vector3.new(0, 100, 0), Size = Vector3.new(2, 2, 1) }
	s.Humanoid = { HipHeight = 2, MoveDirection = Vector3.new(0, 0, 0) }
	local function part(position)
		return { Parent = true, Position = position, IsA = function(_, kind) return kind == "BasePart" end,
			IsDescendantOf = function(self) return self.Parent ~= nil end }
	end
	s.EggRoot = part(Vector3.new(100, 100, 0))
	s.Prompt = part(s.EggRoot.Position)
	s.NativePrompt = { Parent = s.Prompt, Enabled = true, RequiresLineOfSight = false, MaxActivationDistance = 6.5 }
	s.Prompt.FindFirstChildOfClass = function() return s.NativePrompt end
	s.Egg = { Name = "Brain Egg", Parent = true, IsDescendantOf = function(self) return self.Parent ~= nil end,
		FindFirstChild = function(_, name)
			if name == "Root" then return s.EggRoot elseif name == "Prompt" then return s.Prompt end return {}
		end,
		GetAttribute = function(_, name) if name == "Island" then if not s.Surface then return "Zen" end elseif name == "Unlocked" then return s.Opened == true end end }
	s.Config = { HATCH_SETTINGS = { EGG_SELECTION_MODE = "AUTO", SELECTED_EGGS = {}, ENABLE_BACKGROUND_PICKUPS = false },
		PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = true, AUTO_EQUIP = false },
		EGG_TRAVEL_SETTINGS = { ENABLE_SELECTED_EGG_TRAVEL = true, ENABLE_NATIVE_ISLAND_TRAVEL = false,
			ENABLE_DIRECT_POSITIONING = true, ARRIVAL_TIMEOUT_SECONDS = 2, STABILITY_SECONDS = 0.3,
			MAXIMUM_LOCATION_SECONDS = 120, MAXIMUM_ATTEMPTS_PER_SELECTION = 1, SELECTION_REVISION = 0 } }
	s.Player = { UserId = 123, Character = s.Character }
	s.Snapshot = { Ready = true, Revision = 1, Balances = { Coins = 1000 } }
	s.Context = { Currency = s.Currency, AccountFacts = s.Profile, Eggs = {}, Inventory = { Team = {}, ById = {} } }
	function s:Intent()
		return { Kind = "HATCH", EggName = "Brain Egg", Model = self.Egg, Count = 1, OwnsLocation = true,
			DecisionSource = "BRAIN", SelectionMode = "AUTO", Currency = "Coins", Reason = "Synthetic useful affordable native estimate" }
	end
	s.Controller = { Config = s.Config, State = "RUNNING", Generation = 1, Plan = {},
		Log = function(_, kind, message) table.insert(s.Logs, kind .. " | " .. message) end,
		Reader = { Player = s.Player, GetLiveProfile = function() return s.Profile end,
			GetSnapshot = function() return s.Snapshot end },
		Knowledge = { Get = function(_, name)
			if name == "Eggs" then
				local definition = { World = "The Overworld" } if not s.Surface then definition.Island = "Zen" end
				return { ["Brain Egg"] = definition }
			elseif name == "Worlds" then return { ["The Overworld"] = { Islands = { { Name = "Zen" } } } }
			elseif name == "WorldUtil" then return { GetPlayerWorld = function() return s.CurrentWorld end }
			elseif name == "ProximityPrompt" then return { Visible = s.PromptVisible or 0 }
			elseif name == "HatchPresentation" then return { IsHatching = function() return s.PresentationActive == true end } end
		end, EggModels = function() return s.Loaded and { s.Egg } or {} end },
		Farming = { Tracker = { Root = function() return s.Root, s.Humanoid end }, Mechanics = {} } }
	mockNativeEggIdentity(s.Controller.Knowledge)
	s.Controller.Pets = { Fresh = function()
		s.Context.Currency = s.Currency
		s.Context.Eggs = { { Name = "Brain Egg", Model = s.Egg, World = "The Overworld", Island = "Zen" } }
		return s.Snapshot, s.Context
	end, State = function() return { Pending = false, Location = nil, SessionEnded = s.SessionEnded == true } end,
		Hatch = { Ended = function() return s.SessionEnded == true end } }
	s.Controller.Brain = { AnalyzePets = function() return { Currency = s.Currency, Eggs = s.Context.Eggs } end,
		PlanPets = function()
			if not s.Authorized then return { Kind = "WAIT", OwnsLocation = false, Reason = s.Blocker or "PROTECTED_RESERVE" } end
			local intent = s:Intent()
			intent.Currency = s.Currency
			if s.FreshName then intent.EggName = s.FreshName end
			if s.FreshModel then intent.Model = s.FreshModel end
			return intent
		end }
	s.Manager = Travel.new(s.Controller) s.Controller.EggTravel = s.Manager
	s.Manager.ResolveStanding = function(_, record)
		if s.OnStanding then s.OnStanding() end
		return { Position = record.RangeOriginPosition + Vector3.new(2, 0, 0) }
	end
	s.Token = { CheckCancelled = function() return s.Cancelled == true end }
	s.Controller.Farming.Mechanics.LocalFeatureGuard = function()
		if s.OnGuard then s.OnGuard() end
		return true
	end
	s.Controller.Farming.Mechanics.PositionSelectedEgg = function(_, manager, record, frame, token)
		local fresh, reason = manager:Validate(record, token)
		if not fresh then return false, reason end
		table.insert(s.Commands, "DIRECT_POSITION")
		s.Root.Position = frame.Position
		return true, "Synthetic transform; stable native range still required"
	end
	s.Controller.Farming.Mechanics.TravelSelectedEgg = function(_, manager, record, token)
		local fresh, reason = manager:Validate(record, token)
		if not fresh then return false, reason end
		table.insert(s.Commands, "NATIVE_AREA_TRAVEL")
		s.CurrentWorld, s.Root.Position = record.World, s.EggRoot.Position + Vector3.new(2, 0, 0)
		return true
	end
	function s:Select() return self.Manager:Select(self.Controller.Plan, self:Intent()) end
	function s:Run()
		local owns, decision = self:Select()
		if not owns then return nil, decision end
		return self.Manager:Definition(decision, self.Controller.Generation).Execute(self.Token), decision
	end
	return s
end

test("AUTO travel consumes a Brain destination without filling the manual egg list", function()
	simulated(function()
		local s = integrationFixture()
		local owns, decision = s:Select()
		assert(owns and decision.Kind == "EGG_TRAVEL" and decision.Record.Model == s.Egg)
		assert(decision.Record.SelectionKey == "AUTO:Brain Egg:0" and #s.Config.HATCH_SETTINGS.SELECTED_EGGS == 0)
		assert(s.Manager:GetStatus().BrainIntent.EggName == "Brain Egg")
		local result = s.Manager:Definition(decision, 1).Execute(s.Token)
		assert(result.Verified and #s.Commands == 1 and s.Commands[1] == "DIRECT_POSITION")
		assert(s.Manager.LastResult.HatchCommands == 0 and s.Manager.LastResult.Spending == 0)
	end)
end)

test("AUTO travel rejects an absent Brain intent instead of choosing an egg", function()
	local s = integrationFixture()
	assert(not s.Manager:Select(s.Controller.Plan) and not s.Manager:OwnsLocation() and #s.Commands == 0)
end)

test("Protected reserve or no useful egg prevents AUTO travel as well as spending", function()
	for _, reason in ipairs({ "PROTECTED_RESERVE", "NO_USEFUL_IMPROVEMENT", "CAPACITY_UNAVAILABLE_OR_FULL" }) do
		local s = integrationFixture() s.Authorized, s.Blocker = false, reason
		local owns, decision = s:Select()
		assert(not owns and decision.Kind == "WAIT" and not s.Manager:OwnsLocation() and #s.Commands == 0)
	end
end)

test("Losing native financial authorization after planning prevents the first position assignment", function()
	simulated(function()
		local s = integrationFixture() local owns, decision = s:Select() assert(owns)
		s.Authorized = false s.Profile.Coins = 0 s.Snapshot.Balances.Coins = 0
		local result = s.Manager:Definition(decision, 1).Execute(s.Token)
		assert(not result.Verified and #s.Commands == 0 and not s.Manager:OwnsLocation())
	end)
end)

test("Stale egg or model from a fresh Brain replan cannot execute the old destination", function()
	simulated(function()
		for _, change in ipairs({ "EGG", "MODEL" }) do
			local s = integrationFixture() local owns, decision = s:Select() assert(owns)
			if change == "EGG" then s.FreshName = "Other Egg" else s.FreshModel = {} end
			local result = s.Manager:Definition(decision, 1).Execute(s.Token)
			assert(not result.Verified and #s.Commands == 0 and not s.Manager:OwnsLocation())
		end
	end)
end)

test("Account or objective changes invalidate an already planned AUTO movement lease", function()
	simulated(function()
		for _, change in ipairs({ "ACCOUNT", "OBJECTIVE" }) do
			local s = integrationFixture() local owns, decision = s:Select() assert(owns)
			if change == "ACCOUNT" then s.Player.UserId = 456 else s.Currency = "Gems" end
			local result = s.Manager:Definition(decision, 1).Execute(s.Token)
			assert(not result.Verified and #s.Commands == 0 and not s.Manager:OwnsLocation())
		end
	end)
end)

test("Native authorization changing during standing observation prevents AUTO positioning", function()
	simulated(function()
		local s = integrationFixture() s.OnStanding = function() s.Authorized = false end
		local result = s:Run()
		assert(result and not result.Verified and #s.Commands == 0 and not s.Manager:OwnsLocation())
	end)
end)

test("Loaded model and actual native access are mandatory for an AUTO travel destination", function()
	for _, change in ipairs({ "UNLOADED", "WORLD_LOCKED", "ISLAND_LOCKED" }) do
		local s = integrationFixture()
		if change == "UNLOADED" then s.Loaded = false
		elseif change == "WORLD_LOCKED" then s.Profile.WorldsUnlocked["The Overworld"] = nil
		else s.Profile.AreasUnlocked.Zen = nil end
		assert(not s:Select() and not s.Manager:OwnsLocation() and #s.Commands == 0)
	end
end)

test("A removed original model cancels planned AUTO travel without a fallback target", function()
	simulated(function()
		local s = integrationFixture() local owns, decision = s:Select() assert(owns)
		s.Egg.Parent = nil
		local result = s.Manager:Definition(decision, 1).Execute(s.Token)
		assert(not result.Verified and #s.Commands == 0 and not s.Manager:OwnsLocation())
	end)
end)

test("Stable AUTO arrival hands the same model to hatch without another position assignment", function()
	simulated(function()
		local s = integrationFixture() assert(s:Run().Verified)
		local owns, decision = s:Select()
		assert(not owns and decision.Kind == "HANDOFF" and s.Manager:OwnsLocation())
		assert(s.Manager:HatchEligible({ Name = "Brain Egg", Model = s.Egg }))
		assert(not s.Manager:HatchEligible({ Name = "Other Egg", Model = s.Egg }))
		assert(not s.Manager:HatchEligible({ Name = "Brain Egg", Model = {} }))
		assert(#s.Commands == 1 and s.Manager.Lease.Model == s.Egg)
	end)
end)

test("Manual departure blocks AUTO hatch and return until the owner rearms its selection", function()
	simulated(function()
		local s = integrationFixture() assert(s:Run().Verified)
		s.Root.Position = Vector3.new(0, 100, 0) s.Manager:Observe()
		assert(not s.Manager:OwnsLocation() and not s.Manager:HatchEligible({ Name = "Brain Egg", Model = s.Egg }))
		assert(not s:Select() and #s.Commands == 1, "Same selection must respect manual movement without snapping back")
		s.Config.EGG_TRAVEL_SETTINGS.SELECTION_REVISION = 1
		assert(s:Run().Verified and #s.Commands == 2)
	end)
end)

test("Cancellation and manual movement cannot turn AUTO selection into a position change", function()
	simulated(function()
		for _, change in ipairs({ "CANCELLED", "MANUAL_MOVEMENT" }) do
			local s = integrationFixture() local owns, decision = s:Select() assert(owns)
			if change == "CANCELLED" then s.Cancelled = true else s.Humanoid.MoveDirection = Vector3.new(1, 0, 0) end
			local result = s.Manager:Definition(decision, 1).Execute(s.Token)
			assert(not result.Verified and #s.Commands == 0 and not s.Manager:OwnsLocation())
		end
	end)
end)

test("A stale scheduler generation cannot execute an AUTO travel decision", function()
	local s = integrationFixture() local owns, decision = s:Select() assert(owns)
	local definition = s.Manager:Definition(decision, 1)
	assert(definition.Id == "OC_GAMEPLAY" and definition.Owner == "EGG_TRAVEL" and definition.CanRun())
	s.Controller.Generation = 2
	assert(not definition.CanRun() and #s.Commands == 0)
end)

test("AUTO surface travel from an island cannot substitute PortalSpawn or directly jump to its egg", function()
	simulated(function()
		local s = integrationFixture() s.Surface = true s.Root.Position = Vector3.new(0, 9500, 0)
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL = true
		local old = workspace.FindFirstChild
		local portal = { Parent = true, IsA = function() return true end, IsDescendantOf = function() return true end }
		local world = { FindFirstChild = function(_, name) if name == "PortalSpawn" then return portal end end }
		workspace.FindFirstChild = function(_, name) if name == "Worlds" then return { FindFirstChild = function() return world end } end end
		local owns, decision = s:Select()
		assert(not owns and decision.Kind == "WAIT" and #s.Commands == 0 and not s.Manager:OwnsLocation())
		local record = s.Manager:Resolve()
		assert(record and record.NeedsNativeTravel and not record.NativeAreaKnown and record.DestinationPath == nil)
		workspace.FindFirstChild = old
	end)
end)

test("AUTO surface travel requires the observed exact FastTravel Spawn before final positioning", function()
	simulated(function()
		local s = integrationFixture() s.Surface = true s.Root.Position = Vector3.new(0, 9500, 0)
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL = true
		local old = workspace.FindFirstChild
		local destination = { Parent = true, IsA = function(_, kind) return kind == "BasePart" end,
			IsDescendantOf = function() return true end, GetFullName = function() return "Workspace.Worlds.The Overworld.FastTravel.Spawn" end }
		local world = { FindFirstChild = function(_, name) if name == "FastTravel" then return { FindFirstChild = function(_, name) if name == "Spawn" then return destination end end } end end }
		workspace.FindFirstChild = function(_, name) if name == "Worlds" then return { FindFirstChild = function() return world end } end end
		local owns, decision = s:Select()
		assert(owns and decision.Record.NeedsNativeTravel and decision.Record.NativeAreaKnown)
		assert(decision.Record.Destination == destination and decision.Record.DestinationPath == destination:GetFullName() and #s.Commands == 0)
		workspace.FindFirstChild = old
	end)
end)

print("[OC TEST] " .. (tests - before) .. " Phase 4 Brain/travel integration tests passed; real gameplay remains owner pending")
end

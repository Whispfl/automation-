do
-- Physical diagnostic over actual Brain/travel implementations. Synthetic native
-- observations never certify accepted transport, interaction or live gameplay.
local before = tests
local Travel = requireOC("EggTravelManager")
local function fixture(manual)
	local s = { Profile = { Coins = 0, WorldsUnlocked = { ["The Overworld"] = true }, AreasUnlocked = { Zen = true }, EggsOpened = {} },
		Character = {}, Commands = {}, Logs = {}, Models = {}, Definitions = {}, Currency = "Coins" }
	s.Config = Resolver.Resolve(Defaults, {
		PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = false, AUTO_EQUIP = false },
		HATCH_SETTINGS = { EGG_SELECTION_MODE = manual and "MANUAL" or "AUTO", SELECTED_EGGS = {}, MAXIMUM_EGG_COST = 0, MAXIMUM_SESSION_COST = 0,
			HATCH_ONE_EGG_ONCE = false, ENABLE_BACKGROUND_PICKUPS = false },
		EGG_TRAVEL_SETTINGS = { MODE = "TRAVEL_ONLY", ENABLE_SELECTED_EGG_TRAVEL = true,
			ENABLE_NATIVE_ISLAND_TRAVEL = false, ENABLE_DIRECT_POSITIONING = false, STABILITY_SECONDS = 1, ARRIVAL_TIMEOUT_SECONDS = 3 },
		WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false, AUTO_UNLOCK_WORLDS = false,
			AUTO_TRAVEL_FOR_PROGRESSION = false, AUTO_FARM_UNLOCK_REQUIREMENTS = false, MAXIMUM_WORLD_UNLOCK_COST = 0 },
		FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false },
		ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
		PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false, STATIONARY_ISOLATED_TEST = false },
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
		UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false, ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false },
	})
	s.Root = { Position = Vector3.new(0, 100, 0), Size = Vector3.new(2, 2, 1), Parent = s.Character }
	s.Humanoid = { HipHeight = 2, MoveDirection = Vector3.new(0, 0, 0) }
	s.Player = { UserId = 123, Character = s.Character }
	s.Worlds = { ["The Overworld"] = { Islands = { { Name = "Zen" } } },
		Next = { Order = 2, UnlockCost = { Type = "Currency", Currency = "Coins", Amount = 1000000000 } } }
	function s:AddEgg(name, distance)
		local part = { Parent = true, Position = Vector3.new(distance, 100, 0),
			IsA = function(_, kind) return kind == "BasePart" end, IsDescendantOf = function(self) return self.Parent ~= nil end }
		local prompt = table.clone(part)
		local nativePrompt = { Parent = prompt, Enabled = true, MaxActivationDistance = 6.5, RequiresLineOfSight = false }
		prompt.FindFirstChildOfClass = function() return nativePrompt end
		local model = { Name = name, Parent = true, Root = part, Prompt = prompt,
			IsDescendantOf = function(self) return self.Parent ~= nil end,
			GetAttribute = function(_, key) if key == "Island" and not s.Surface then return "Zen" elseif key == "Unlocked" then return false end end,
			FindFirstChild = function(_, key) if key == "Root" then return part elseif key == "Prompt" then return prompt end return {} end }
		self.Definitions[name] = { World = "The Overworld", Island = "Zen", Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } }
		table.insert(self.Models, model)
		return model
	end
	s.Egg = s:AddEgg("Observed Egg", 2)
	if manual then s.Config.HATCH_SETTINGS.SELECTED_EGGS = { s.Egg.Name } end
	s.Controller = { Config = s.Config, State = "RUNNING", Generation = 1,
		Log = function(_, kind, message) table.insert(s.Logs, kind .. " | " .. message) end,
		Reader = { Player = s.Player, GetLiveProfile = function() return s.Profile end,
			GetSnapshot = function() return { Ready = true } end },
		Knowledge = { Get = function(_, name)
			if name == "Eggs" then return s.Definitions elseif name == "Worlds" then return s.Worlds
			elseif name == "WorldUtil" then return { GetPlayerWorld = function() return "The Overworld" end } end
		end, EggModels = function() return s.Models end },
		Farming = { Tracker = { Root = function() return s.Root, s.Humanoid end }, Mechanics = {} },
		Rewards = { Select = function() error("TRAVEL_ONLY must not select rewards") end },
		AntiAFK = { Select = function() error("TRAVEL_ONLY must not select idle input") end } }
	s.Controller.Brain = Brain.new(s.Config)
	s.Controller.Pets = { Fresh = function()
		local eggs = {}
		for _, model in ipairs(s.Models) do
			if not model.Root then continue end
			table.insert(eggs, { Name = model.Name, Model = model, World = "The Overworld", Island = not s.Surface and "Zen" or nil, Loaded = s.NotLoaded ~= true,
				Accessible = true, Distance = (model.Root.Position - s.Root.Position).Magnitude, Cost = s.Definitions[model.Name].Cost })
		end
		return { Ready = s.Ready ~= false, Balances = { Coins = 0 }, UnlockedWorlds = s.Profile.WorldsUnlocked,
			UnlockedIslands = s.Profile.AreasUnlocked, ProgressionGraph = { Worlds = { { Name = "Next", Unlocked = false,
				Cost = { Type = "Currency", Currency = "Coins", Amount = 1000000000 } } } } },
			{ Currency = s.Currency, EggAvailability = eggs, Eggs = eggs, Inventory = nil,
				AccountId = s.Player.UserId, BaselineIncomplete = true, Error = "Native owned search incomplete" }
	end }
	s.Controller.EggTravel = Travel.new(s.Controller) s.Manager = s.Controller.EggTravel
	s.Token = { CheckCancelled = function() return s.Cancelled == true end }
	s.Controller.Farming.Mechanics.LocalFeatureGuard = function()
		if s.OnGuard then s.OnGuard() end
		return true
	end
	s.Manager.ResolveStanding = function(_, record)
		if s.OnStanding then s.OnStanding() end
		return { Position = record.RangeOriginPosition + Vector3.new(2, 0, 0) }
	end
	s.Controller.Farming.Mechanics.PositionSelectedEgg = function(_, manager, record, frame, token)
		local fresh, reason = manager:Validate(record, token)
		if not fresh then return false, reason end
		assert(manager.DiagnosticConsumed, "Diagnostic permission must be consumed before position assignment")
		table.insert(s.Commands, "DIRECT_POSITION")
		if s.PositionFailure then return false, "Synthetic CFrame assignment rejected" end
		if not s.NoArrival then s.Root.Position = frame.Position end
		if s.OnPosition then s.OnPosition() end
		return true
	end
	s.Controller.Farming.Mechanics.TravelSelectedEgg = function(_, manager, record, token)
		local fresh, reason = manager:Validate(record, token)
		if not fresh then return false, reason end
		assert(manager.DiagnosticConsumed)
		manager:DiagnosticTrace("AREA_TRAVEL_REQUESTED", fresh, "Synthetic exact native request dispatch site; server acceptance unverified")
		table.insert(s.Commands, "NATIVE_AREA_TRAVEL")
		if s.NativeFailure then return false, "Synthetic native arrival unconfirmed" end
		s.Root.Position = record.RangeOriginPosition + Vector3.new(2, 0, 0)
		if s.OnNativeArrival then s.OnNativeArrival() end
		return true, "Synthetic observed native target area"
	end
	function s:Select()
		local owner, decision = self.Controller.Brain:SelectLocalFeature(self.Controller, self.Controller.Plan or {}, false,
			{ Kind = "WAIT", Reason = "INCOMPLETE_OWNED_TEAM_BASELINE; PROTECTED_RESERVE", OwnsLocation = false })
		return owner, decision
	end
	function s:Execute()
		local owner, decision = self:Select()
		if owner ~= "EGG_TRAVEL" then return nil, decision end
		return self.Manager:Definition(decision, 1).Execute(self.Token), decision
	end
	return s
end

test("TRAVEL_ONLY AUTO is independent of incomplete owned benchmark zero funds and native billion reserve", function()
	simulated(function()
		local s = fixture() s:AddEgg("Farther Egg", 100)
		local owner, decision = s:Select()
		assert(owner == "EGG_TRAVEL" and decision.Record.EggName == "Observed Egg")
		assert(s.Manager.BrainIntent.DecisionSource == "BRAIN_TRAVEL_DIAGNOSTIC" and s.Manager.BrainIntent.Scope == "TRAVEL_ONLY")
		assert(s.Manager.BrainIntent.EconomicSelection == "DIAGNOSTIC_PHYSICAL_TARGET; optimal economic choice not claimed")
		assert(s.Manager.BrainIntent.Generation == 1 and s.Manager.BrainIntent.AccountId == 123 and s.Manager.BrainIntent.DefinitionReference)
		assert(s.Config.HATCH_SETTINGS.MAXIMUM_SESSION_COST == 0 and not s.Config.PET_SETTINGS.AUTO_HATCH)
		assert(s.Manager.DiagnosticConsumed and #s.Commands == 0)
		local result = s.Manager:Definition(decision, 1).Execute(s.Token)
		assert(result.Verified and s.Manager.LastResult.Status == "TRAVEL_ONLY_ARRIVAL_OBSERVED" and s.Manager.DiagnosticEnded)
		assert(not s.Manager:OwnsLocation() and not s.Manager:HatchEligible({ Name = s.Egg.Name, Model = s.Egg }))
		assert(s.Manager.LastResult.HatchCommands == 0 and s.Manager.LastResult.Spending == 0 and #s.Commands == 0 and s.Profile.Coins == 0)
		local logs = table.concat(s.Logs, "\n")
		assert(logs:find("TARGET_SELECTED", 1, true) and logs:find("HATCH_RANGE_OBSERVED", 1, true) and not logs:find("DIRECT_POSITION_ATTEMPTED", 1, true))
		assert(s:Select() == "PHASE4_WAIT")
		s.Config.EGG_TRAVEL_SETTINGS.SELECTION_REVISION = 99 s.Root.Position = Vector3.new(100, 100, 0)
		assert(s:Select() == "PHASE4_WAIT" and #s.Commands == 0, "One diagnostic cannot snap back or rearm from a revised selection")
	end)
end)

test("TRAVEL_ONLY MANUAL permits one exact native target with one bounded position attempt", function()
	simulated(function()
		local s = fixture(true) local distant = s:AddEgg("Owner Exact Egg", 100)
		s.Config.HATCH_SETTINGS.SELECTED_EGGS = { distant.Name } s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true
		local result = s:Execute()
		assert(result.Verified and s.Manager.LastResult.EggName == distant.Name and #s.Commands == 1)
		assert(s.Manager.LastResult.HatchCommands == 0 and s.Manager.LastResult.Spending == 0)
		s.Manager:Halt(false) s.Manager:Halt(true) s.Config.EGG_TRAVEL_SETTINGS.SELECTION_REVISION += 1
		assert(s:Select() == "PHASE4_WAIT" and #s.Commands == 1)
	end)
end)

test("TRAVEL_ONLY still rejects locked missing premium event and removed native destinations", function()
	for _, failure in ipairs({ "WORLD", "ISLAND", "MODEL", "PREMIUM", "EVENT", "REMOVED", "ACCOUNT" }) do
		local s = fixture()
		if failure == "WORLD" then s.Profile.WorldsUnlocked["The Overworld"] = nil
		elseif failure == "ISLAND" then s.Profile.AreasUnlocked.Zen = nil
		elseif failure == "MODEL" then s.NotLoaded = true
		elseif failure == "PREMIUM" then s.Definitions[s.Egg.Name].ProductId = 123
		elseif failure == "EVENT" then s.Definitions[s.Egg.Name].Event = "Historical Catalog"
		elseif failure == "REMOVED" then s.Worlds["The Overworld"].Removed = true
		else s.Ready = false end
		assert(s:Select() == "PHASE4_WAIT" and not s.Manager:OwnsLocation() and #s.Commands == 0)
	end
end)

test("TRAVEL_ONLY rejects ambiguous original identity and ignores visual duplicates without the native interface", function()
	simulated(function()
		local s = fixture() s:AddEgg(s.Egg.Name, 100)
		local owner, decision = s:Select()
		assert(owner == "PHASE4_WAIT" and decision.Reason:find("AMBIGUOUS_NATIVE_EGG_MODEL", 1, true))
		assert(#s.Commands == 0 and not s.Manager:OwnsLocation())
		s = fixture()
		table.insert(s.Models, { Name = s.Egg.Name, Parent = true, IsDescendantOf = function() return true end,
			FindFirstChild = function() return nil end })
		assert(s:Execute().Verified and #s.Commands == 0)
		assert(s.Manager.LastResult.EggName == s.Egg.Name)
	end)
end)

test("TRAVEL_ONLY cannot be changed into hatch equipment pickups rewards or an allowance during final guards", function()
	simulated(function()
		for _, change in ipairs({ "HATCH", "EQUIP", "PICKUPS", "REWARD", "ALLOWANCE" }) do
			local s = fixture()
			s.OnGuard = function()
				if change == "HATCH" then s.Config.PET_SETTINGS.AUTO_HATCH = true
				elseif change == "EQUIP" then s.Config.PET_SETTINGS.AUTO_EQUIP = true
				elseif change == "PICKUPS" then s.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS = true
				elseif change == "REWARD" then s.Config.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME = true
				else s.Config.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_HATCH_TEST_ALLOWANCE = true end
			end
			local result = s:Execute()
			assert(not result.Verified and s.Manager.DiagnosticConsumed and s.Manager.DiagnosticEnded and #s.Commands == 0)
		end
	end)
end)

test("TRAVEL_ONLY identity geometry cancellation and manual motion invalidate a consumed planned attempt", function()
	simulated(function()
		for _, failure in ipairs({ "ACCOUNT", "MODEL", "CANCELLED", "MANUAL" }) do
			local s = fixture() local owner, decision = s:Select() assert(owner == "EGG_TRAVEL")
			if failure == "ACCOUNT" then s.Player.UserId = 456
			elseif failure == "MODEL" then s.Egg.Parent = nil
			elseif failure == "CANCELLED" then s.Cancelled = true
			else s.Humanoid.MoveDirection = Vector3.new(1, 0, 0) end
			local result = s.Manager:Definition(decision, 1).Execute(s.Token)
			assert(not result.Verified and s.Manager.DiagnosticEnded and not s.Manager:OwnsLocation() and #s.Commands == 0)
			s.Config.EGG_TRAVEL_SETTINGS.SELECTION_REVISION += 1
			assert(s:Select() == "PHASE4_WAIT" and #s.Commands == 0)
		end
	end)
end)

test("TRAVEL_ONLY objective currency changes do not invent a paid or funding prerequisite", function()
	simulated(function()
		local s = fixture() local owner, decision = s:Select() assert(owner == "EGG_TRAVEL")
		s.Currency = nil
		assert(s.Manager:Definition(decision, 1).Execute(s.Token).Verified and #s.Commands == 0)
	end)
end)

test("TRAVEL_ONLY native area transport precedes stable range and reports separate observed stages", function()
	simulated(function()
		local s = fixture() s.Egg.Root.Position = Vector3.new(2, 500, 0) s.Egg.Prompt.Position = s.Egg.Root.Position
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL = true
		local result = s:Execute()
		assert(result.Verified and #s.Commands == 1 and s.Commands[1] == "NATIVE_AREA_TRAVEL")
		local logs = table.concat(s.Logs, "\n")
		local requested, arrived, ranged = logs:find("AREA_TRAVEL_REQUESTED", 1, true), logs:find("AREA_ARRIVAL_OBSERVED", 1, true), logs:find("HATCH_RANGE_OBSERVED", 1, true)
		assert(requested and arrived and ranged and requested < arrived and arrived < ranged)
		assert(not logs:find("DIRECT_POSITION_ATTEMPTED", 1, true) and s.Manager.LastResult.Spending == 0)
	end)
end)

test("TRAVEL_ONLY retains its acquired original when native travel makes another loaded egg closer", function()
	simulated(function()
		local s = fixture() s.Egg.Root.Position = Vector3.new(2, 500, 0) s.Egg.Prompt.Position = s.Egg.Root.Position
		s.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL = true
		local previouslyFar = s:AddEgg("Previously Far Egg", 1000)
		s.OnNativeArrival = function()
			previouslyFar.Root.Position = s.Root.Position + Vector3.new(0.5, 0, 0)
			previouslyFar.Prompt.Position = previouslyFar.Root.Position
			local newlyLoaded = s:AddEgg("Newly Loaded Closer Egg", 2000)
			newlyLoaded.Root.Position = s.Root.Position + Vector3.new(0.2, 0, 0)
			newlyLoaded.Prompt.Position = newlyLoaded.Root.Position
			local snapshot, context = s.Controller.Pets:Fresh()
			local ranked = s.Controller.Brain:PlanEggTravelDiagnostic(snapshot, context, s.Definitions, s.Worlds)
			assert(ranked.EggName == newlyLoaded.Name, "Fresh proximity ranking now differs from the acquired target")
			local owner, decision = s:Select()
			assert(owner == "EGG_TRAVEL" and decision.Record.Model == s.Egg,
				"A fresh controller arbitration must retain the exact acquired travel target as well")
		end
		local result = s:Execute()
		assert(result.Verified and s.Manager.LastResult.EggName == s.Egg.Name and #s.Commands == 1)
		assert(s.Manager.DiagnosticEnded and s.Manager.LastResult.Spending == 0)
	end)
end)

test("TRAVEL_ONLY acquired goal or exact MANUAL configuration change invalidates planned travel", function()
	simulated(function()
		for _, change in ipairs({ "GOAL", "MANUAL_NAME", "SELECTION_MODE" }) do
			local s = fixture(change == "MANUAL_NAME")
			s.Controller.Plan = { Objective = { Id = "ORIGINAL_DIAGNOSTIC_GOAL" } }
			local owner, decision = s:Select() assert(owner == "EGG_TRAVEL")
			if change == "GOAL" then s.Controller.Plan.Objective.Id = "OTHER_GOAL"
			elseif change == "MANUAL_NAME" then
				local other = s:AddEgg("New Owner Choice", 100) s.Config.HATCH_SETTINGS.SELECTED_EGGS = { other.Name }
			else s.Config.HATCH_SETTINGS.EGG_SELECTION_MODE = "MANUAL" s.Config.HATCH_SETTINGS.SELECTED_EGGS = { s.Egg.Name } end
			local result = s.Manager:Definition(decision, 1).Execute(s.Token)
			assert(not result.Verified and #s.Commands == 0 and s.Manager.DiagnosticEnded and not s.Manager:OwnsLocation())
		end
	end)
end)

test("TRAVEL_ONLY accurately reports failed assignment and unobserved server-corrected arrival without retry", function()
	simulated(function()
		for _, failure in ipairs({ "ASSIGNMENT", "CORRECTION" }) do
			local s = fixture() s.Egg.Root.Position = Vector3.new(100, 100, 0) s.Egg.Prompt.Position = s.Egg.Root.Position
			s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true
			if failure == "ASSIGNMENT" then s.PositionFailure = true else s.NoArrival = true end
			local result = s:Execute()
			assert(not result.Verified and #s.Commands == 1 and s.Manager.DiagnosticEnded)
			local logs = table.concat(s.Logs, "\n")
			assert(logs:find("DIRECT_POSITION_ATTEMPTED", 1, true) and not logs:find("HATCH_RANGE_OBSERVED", 1, true))
			assert(logs:find(failure == "ASSIGNMENT" and "DIRECT_POSITION_FAILED" or "ARRIVAL_UNCONFIRMED", 1, true))
			assert(s:Select() == "PHASE4_WAIT" and #s.Commands == 1)
		end
	end)
end)

test("TRAVEL_ONLY preserves existing surface-area restriction and rejects missing native transport", function()
	local s = fixture() s.Surface = true s.Definitions[s.Egg.Name].Island = nil
	s.Egg.Root.Position = Vector3.new(2, 0, 0) s.Egg.Prompt.Position = s.Egg.Root.Position
	s.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING = true
	local owner, decision = s:Select()
	assert(owner == "PHASE4_WAIT" and decision.Reason:find("native area travel", 1, true))
	assert(#s.Commands == 0 and not s.Manager:OwnsLocation())
	assert(table.concat(s.Logs, "\n"):find("TRAVEL_BLOCKED", 1, true))
end)

test("TRAVEL_ONLY stale generation and character respawn cancel old selected geometry", function()
	simulated(function()
		for _, failure in ipairs({ "GENERATION", "RESPAWN" }) do
			local s = fixture() local owner, decision = s:Select() assert(owner == "EGG_TRAVEL")
			if failure == "GENERATION" then s.Controller.Generation += 1 else s.Player.Character = {} end
			local result = s.Manager:Definition(decision, 1).Execute(s.Token)
			assert(not result.Verified and #s.Commands == 0 and s.Manager.DiagnosticEnded)
		end
	end)
end)

test("TRAVEL_ONLY Pause Stop and skipped scheduler work consume the bounded permission", function()
	for _, control in ipairs({ "PAUSE", "STOP", "SKIPPED" }) do
		local s = fixture() local owner = s:Select() assert(owner == "EGG_TRAVEL")
		if control == "SKIPPED" then s.Manager:Completed("SKIPPED", nil, "Stale generation")
		else s.Controller.State = control == "PAUSE" and "PAUSED" or "STOPPED" s.Manager:Halt(control == "STOP") end
		s.Controller.State = "RUNNING" s.Config.EGG_TRAVEL_SETTINGS.SELECTION_REVISION += 1
		assert(s:Select() == "PHASE4_WAIT" and s.Manager.DiagnosticEnded and not s.Manager:OwnsLocation() and #s.Commands == 0)
	end
end)

print("[OC TEST] " .. (tests - before) .. " isolated travel-only diagnostic tests passed; native acceptance remains owner pending")
end

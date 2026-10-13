do
-- Actual GameKnowledge/Brain/PetManager over one synthetic current account.
-- These fixtures never execute in Studio or establish live server acceptance.
local before = tests
local Pets, Allowance, Policy, Travel = requireOC("PetManager"), requireOC("OwnerHatchTestAllowance"), requireOC("PetPolicy"), requireOC("EggTravelManager")

local function options(enabled)
	return {
		PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = enabled, AUTO_EQUIP = false,
			EQUIP_OWNED_TEAM_ONCE = false, OBJECTIVE_CURRENCY = "Coins", AUTO_DELETE_PETS = false, AUTO_CRAFT_SHINY = false, AUTO_FUSE_PETS = false },
		HATCH_SETTINGS = { EGG_SELECTION_MODE = "MANUAL", SELECTED_EGGS = { "Common Egg" }, HATCH_ONE_EGG_ONCE = enabled,
			ALLOWED_CURRENCIES = { "Coins" }, MAXIMUM_EGG_COST = enabled and 10 or 0, MAXIMUM_SESSION_COST = enabled and 10 or 0,
			MAXIMUM_SESSION_HATCHES = 1, MAXIMUM_BATCH_HATCHES = 1, ENABLE_BACKGROUND_PICKUPS = false, PRESERVE_PROGRESSION_RESERVE = true },
		OWNER_ONE_HATCH_TEST_SETTINGS = { OWNER_ONE_HATCH_TEST_ALLOWANCE = enabled, MAXIMUM_COIN_ALLOWANCE = enabled and 10 or 0,
			MAXIMUM_EGG_COST = enabled and 10 or 0, AUTHORIZED_ACCOUNT_ID = enabled and 123 or 0 },
		WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false, AUTO_UNLOCK_WORLDS = false,
			AUTO_TRAVEL_FOR_PROGRESSION = false, AUTO_FARM_UNLOCK_REQUIREMENTS = false, MAXIMUM_WORLD_UNLOCK_COST = 0 },
		FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false },
		ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
		PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false, STATIONARY_ISOLATED_TEST = false },
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
		UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false, ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false },
		EGG_TRAVEL_SETTINGS = { MODE = "NORMAL", ENABLE_SELECTED_EGG_TRAVEL = false, ENABLE_DIRECT_POSITIONING = false, ENABLE_NATIVE_ISLAND_TRAVEL = false },
		PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = false }, MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = false, ENABLE_AUTOMATIC_CONTINUATION = false },
		ANTIAFK_SETTINGS = { ENABLE_ANTI_AFK = false }, RESOURCE_SETTINGS = { COIN_RESERVE = 50 },
		FALL_EVENT_SETTINGS = { ENABLE_FALL_EVENT = false, AUTO_REBIRTH = false, AUTO_BUY_REBIRTH_UPGRADES = false,
			AUTO_USE_FALL_ELIXIRS = false, AUTO_BUY_AUTUMN_SHOP_ITEMS = false },
	}
end

local function fixture(enabled)
	local s = stationaryFixture(options(enabled))
	s.Profile.Coins = 500
	s.Profile.Pets = { { Id = "owned", Name = "Owned", Amount = 2 } }
	s.Profile.Teams, s.Profile.TeamEquipped = { { Pets = { "owned" } } }, 1
	s.Profile.EggsOpened, s.Profile.AutoDelete = { ["Common Egg"] = 0 }, {}
	s.Cost, s.Storage, s.Commands, s.Opened, s.Time, s.GuardCalls = 10, 100, {}, true, 100, 0
	s.Character = {}
	s.Root.Parent = s.Character
	s.Character.FindFirstChild = function(_, name) return name == "HumanoidRootPart" and s.Root or nil end
	local d = s.Dependencies
	d.Pets = { Owned = { Rarity = "Rare" }, New = { Rarity = "Epic" } }
	d.Eggs = { ["Common Egg"] = { World = "The Overworld", Island = "The Void", Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } } }
	d.Worlds = { ["The Overworld"] = { Order = 1, Islands = { { Name = "The Void", Height = 9500 } } },
		Next = { Order = 2, Islands = {}, UnlockCost = { Type = "Currency", Currency = "Coins", Amount = 1000000000 } } }
	d.StatsUtil.GetMaxPetsEquipped = function() return 2 end
	d.StatsUtil.GetMaxEggHatches = function() return 1 end
	d.StatsUtil.GetMaxPetStorage = function() return s.Storage end
	d.StatsUtil.GetUsedPetStorage = function(_, facts) local count = 0 for _, pet in pairs(facts.Pets) do count += pet.Amount or 1 end return count end
	d.StatsUtil.HasDigitalStorage = function() return false end
	d.StatsUtil.IsInventoryFull = function(self, facts) return self:GetUsedPetStorage(facts) >= s.Storage end
	d.StatsUtil.GetCurrencyMultiplier = function(_, facts)
		local by, score = {}, 2 for _, pet in pairs(facts.Pets) do by[pet.Id] = pet end
		for _, id in ipairs(facts.Teams[facts.TeamEquipped].Pets) do score += by[id].Name == "New" and 8 or 4 end return score
	end
	d.PetUtil = { GetStats = function(_, pet) return { Coins = pet.Name == "New" and 9 or 5 } end }
	d.StatsUtil.GetEggCost = function() return { Type = "Currency", Currency = "Coins", Amount = s.Cost } end
	d.StatsUtil.GetLuckMultiplier = function() return 1 end d.StatsUtil.GetHatchDuration = function() return 2 end
	d.GetEggPool = function() return { { Chance = 1, Item = { Type = "Pet", Name = "New" } } } end
	d.WorldUtil = { GetPlayerWorld = function() return "The Overworld" end }
	d.ProximityPrompt = { Visible = 0 }
	d.Time = { now = function() return s.Time end }
	d.HatchPresentation = { IsHatching = function() return s.Hatching == true end }
	local auto = { IsA = function(_, kind) return kind == "BindableFunction" end, Invoke = function()
		s.AutoCalls = (s.AutoCalls or 0) + 1 if s.OnAuto then s.OnAuto(s.AutoCalls) end return s.NativeAuto
	end }
	s.Controller.Reader.Player = { UserId = 123, Name = "SyntheticTestB", Character = s.Character,
		FindFirstChild = function() return { FindFirstChild = function() return { FindFirstChild = function() return auto end } end } end,
		GetAttribute = function(_, name) return name == "NextEggOpenAt" and s.NextAt or nil end }
	s.Controller.Reader.Config = s.Controller.Config
	s.Controller.Reader.GetSnapshot = function() return { Ready = true, Revision = 1, Balances = { Coins = s.Profile.Coins, Gems = s.Profile.Gems }, AvailableProgression = {} } end
	s.Controller.Reader.ReadBalances = function() return { Coins = s.Profile.Coins, Gems = s.Profile.Gems } end
	s.Controller.Farming, s.Controller.Knowledge = s.Coordinator, s.Coordinator.Knowledge
	s.Models = {}
	function s:AddEgg(name, distance)
		local part = { Position = self.Root.Position + Vector3.new(distance, 0, 0), IsA = function(_, kind) return kind == "BasePart" end }
		local model = { Name = name, Parent = true, FindFirstChild = function(_, key) return key == "Root" and part or nil end,
			GetAttribute = function(_, key) if key == "Unlocked" then return self.Opened elseif key == "Island" then return "The Void" end end }
		if not d.Eggs[name] then d.Eggs[name] = { World = "The Overworld", Island = "The Void", Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } } end
		registerNativeEggFixture(self.Controller.Knowledge, model, self)
		table.insert(self.Models, model) return model
	end
	s.Egg = s:AddEgg("Common Egg", 2.01)
	s.Other = s:AddEgg("Common Egg", 100)
	s.Controller.Knowledge.EggModels = function(self)
		local catalog = {} for _, model in ipairs(s.Models) do if d.Eggs[model.Name] then table.insert(catalog, model) end end
		self.NativeEggModels = catalog return catalog
	end
	s.Controller.HatchTestAllowance = Allowance.new(s.Controller)
	s.Manager = Pets.new(s.Controller) s.Controller.Pets = s.Manager
	s.Coordinator.Mechanics.Guard = function()
		s.GuardCalls += 1 if s.OnGuard then s.OnGuard(s.GuardCalls) end return true, nil, s.Root
	end
	d.Remote = { FireServer = function(_, command, name, count)
		assert(command == "HatchEgg" and name == "Common Egg" and count == 1, "Test B cannot dispatch another game action")
		assert(shared.__OC_OWNER_ONE_HATCH_TEST_LEDGER.Accounts["123"].Consumed, "Consume once before actual native invocation")
		table.insert(s.Commands, { Command = command, Name = name, Count = count })
		if s.RemoteFailure then error("Synthetic uncertain invocation") end
	end }
	s.Token = { CheckCancelled = function() return s.Cancelled == true end }
	function s:Decision()
		local snap, context = self.Manager:Fresh()
		return self.Controller.Brain:PlanPets(self.Controller.Brain:AnalyzePets(snap, context), context, self.Manager:State()), context
	end
	function s:Dispatch()
		local decision = self:Decision()
		if decision.Kind == "WAIT" then return false, decision.Reason end
		return self.Coordinator.Mechanics:PetAction(self.Manager, decision, self.Token)
	end
	function s:NoActions()
		assert(#self.Commands == 0 and self.Manager.Hatch.RequestedHatches == 0 and self.Manager.Hatch.RequestCost == 0)
		assert(self.Manager.EquipCommands == 0 and #self.Teleports == 0 and #self.Calls == 0 and self.Blows == 0)
	end
	return s
end

local function mixedNativeQueue(enabled)
	local s = fixture(enabled)
	local knowledge = s.Controller.Knowledge
	s.Profile.EggsOpened["Common Egg"] = 2
	local cold = {}
	for index = 1, 53 do table.insert(cold, s:AddEgg("Spotted Egg", 1000 + index)) end
	for index = 1, 21 do table.insert(cold, s:AddEgg("Coming Soon", 2000 + index)) end
	for index = 1, 60 do table.insert(cold, s:AddEgg("Egg", 3000 + index)) end
	s.Dependencies.Eggs["Coming Soon"], s.Dependencies.Eggs.Egg = nil, nil
	knowledge.NativeEggFixtureAssets["Coming Soon"], knowledge.NativeEggFixtureAssets.Egg = nil, nil
	local receiver = knowledge.NativeEggFixtureReceiver
	receiver._folder.SyntheticEggInstance = true
	receiver._chunks, receiver._loaded = { loaded = { s.Egg, s.Other }, coldA = {}, coldB = {} }, { loaded = true }
	for index, model in ipairs(cold) do
		model.Parent = nil
		table.insert(index <= 67 and receiver._chunks.coldA or receiver._chunks.coldB, model)
	end
	-- Source-owned opened originals no longer have an attached initial Buy Prompt.
	-- Their exact current loaded queue membership must establish identity instead.
	for _, model in ipairs(s.Models) do model.Prompt:FindFirstChildOfClass("ProximityPrompt").Parent = nil end
	local class = {} class.__index = class
	class.Remove = function() error("Read-only egg preflight cannot remove a native value") end
	class.IsValueLoaded = function() error("Classifier must read the queue without calling native methods") end
	s.NativeUpdates = 0
	class.Update = function(actual, position)
		assert(actual == receiver and position == s.Root.Position)
		s.NativeUpdates += 1 return "unchanged native result", nil, 3
	end
	setmetatable(receiver, class)
	s.Dependencies.Chunker = class
	knowledge.NativeEggChunkers, knowledge.EggObservationFinished = {}, nil
	s.NativeClass, s.ColdOriginals = class, cold
	knowledge:ObserveEggChunker()
	local result = table.pack(class.Update(receiver, s.Root.Position))
	assert(result.n == 3 and result[1] == "unchanged native result" and result[2] == nil and result[3] == 3)
	assert(knowledge.NativeEggChunkers[receiver] == true and s.NativeUpdates == 1)
	return s
end

local function completeNativeObservation(s, clock)
	local knowledge = s.Controller.Knowledge
	clock.Time = knowledge.EggObservationDeadline + 0.1
	knowledge:ObserveEggChunker()
	assert(knowledge.EggObservationFinished and knowledge.ChunkerObserver == nil)
end

local function scenario(callback)
	local previous = shared shared = {}
	local ok, reason = pcall(function() simulated(callback) end)
	shared = previous assert(ok, reason)
end

local function preflight(s, beforeReport)
	s.Controller.Config.EGG_TRAVEL_SETTINGS.MODE = "TRAVEL_ONLY"
	-- The synthetic arrival observation authorizes reporting only; this helper
	-- performs no movement and supplies no spending approval.
	s.Controller.EggTravel = { LastResult = { PhysicalArrivalVerified = true },
		BrainIntent = { EggName = "Common Egg", Model = s.Egg }, BrainUserId = 123 }
	local snapshot, context = s.Manager:Fresh()
	if beforeReport then beforeReport(snapshot, context) end
	s.Manager:ReportHatchPreflight(snapshot, context)
	return s.Manager.HatchPreflight
end

local function verifyExistingTravelLease(s)
	local c = s.Controller
	c.Config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL = true
	c.Config.EGG_TRAVEL_SETTINGS.MAXIMUM_ATTEMPTS_PER_SELECTION = 1
	s.Humanoid = { HipHeight = 2, MoveDirection = Vector3.new(0, 0, 0) }
	c.Farming.Tracker.Root = function() return s.Root, s.Humanoid end
	c.Farming.Mechanics.LocalFeatureGuard = function() return true end
	c.EggTravel = Travel.new(c)
	local intent = s:Decision()
	assert(intent.Kind == "HATCH" and intent.Model == s.Egg)
	local owns, decision = c.EggTravel:Select(c.Plan, intent)
	assert(owns and decision.Record.Model == s.Egg and decision.Record.InRange)
	local position = s.Root.Position
	local arrival = c.EggTravel:Definition(decision, c.Generation).Execute(s.Token)
	assert(arrival.Verified and c.EggTravel.Lease and c.EggTravel.Lease.Status == "ARRIVED")
	assert(c.EggTravel:HatchEligible({ Name = "Common Egg", Model = s.Egg }))
	assert(s.Root.Position == position and c.EggTravel.LastResult.DirectPositionAttempted == false)
	s:NoActions()
	s.GuardCalls = 0
	return c.EggTravel
end

test("Test B preflight observes exact current interaction with the allowance OFF and zero possible OC spending", function()
	scenario(function()
		local s = fixture(false)
		local _, context = s:Decision()
		assert(context.AccountId == 123 and context.EggAvailability[1].Model == s.Egg and context.EggAvailability[1].InRange)
		assert(not s:Dispatch()) s:NoActions()
		assert(not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:Close()
	end)
end)

test("Test B read-only arrived preflight reports ready with price storage account facts and deduplicates unchanged reporting", function()
	scenario(function()
		local s = fixture(false)
		local report = preflight(s)
		assert(report.Status == "HATCH_PREFLIGHT_READY_ALLOWANCE_OFF" and report.SpendingPermission == false)
		assert(report.Before.AccountId == 123 and report.Before.InstanceId == s.Controller.Knowledge:InstanceId(s.Egg))
		assert(report.Before.NativePrice == 10 and report.Before.Coins == 500 and report.Before.FreeStorage == 98)
		assert(report.Before.EggsOpened == 0 and report.Before.InteractionMode == "OPENED_NEAREST")
		local logCount = #s.Logs
		preflight(s) assert(#s.Logs == logCount)
		s.Dependencies.ProximityPrompt.Visible = 1
		assert(preflight(s).Status == "HATCH_PREFLIGHT_BLOCKED" and #s.Logs == logCount + 1)
		assert(not s:Dispatch()) s:NoActions() s:Close()
	end)
end)

test("Test B read-only arrived preflight exposes native cooldown full storage price and current account blockers without actions", function()
	for _, mutate in ipairs({ function(s) s.NextAt = 101 end, function(s) s.Storage = 2 end,
		function(s) s.Cost = 11 end, function(s) s.Profile.Coins = 9 end,
		function(s) s.Controller.Reader.Player.UserId = 456 end,
		function(s) s.Hatching = true end, function(s) s.NativeAuto = "Common Egg" end }) do
		scenario(function()
			local s = fixture(false) mutate(s)
			local report = preflight(s)
			assert(report.Status == "HATCH_PREFLIGHT_BLOCKED" and report.SpendingPermission == false)
			assert(not s:Dispatch()) s:NoActions() s:Close()
		end)
	end
end)

test("Test B actual passive classifier accepts the observed 136-member mixed queue and completes ready preflight with allowance OFF", function()
	scenario(function(clock)
		local s = mixedNativeQueue(false)
		local knowledge, receiver = s.Controller.Knowledge, s.Controller.Knowledge.NativeEggFixtureReceiver
		local row = knowledge.EggObserverStats.Receivers[receiver]
		assert(row.Qualifies and row.Entries == 136 and row.CatalogOriginals == 55 and row.Sentinels == 21 and row.NonCatalogOriginals == 60)
		local pending = preflight(s)
		assert(pending.Status == "HATCH_PREFLIGHT_BLOCKED" and pending.Before.NativePrice == 10 and pending.SpendingPermission == false)
		completeNativeObservation(s, clock)
		local report = preflight(s)
		assert(report.Status == "HATCH_PREFLIGHT_READY_ALLOWANCE_OFF" and report.SpendingPermission == false)
		assert(report.Before.NativePrice == 10 and report.Before.PriceReason == "NATIVE_STATSUTIL_QUOTE" and report.Before.EggsOpened == 2)
		assert(report.Before.InstanceId == knowledge:InstanceId(s.Egg) and report.Before.InteractionMode == "OPENED_NEAREST")
		assert(report.Registration.QualifyingReceivers == 1 and report.Registration.SelectedFound and report.Registration.SelectedLoaded)
		local loaded = knowledge:NativeRegisteredEggModels()
		assert(#loaded == 2 and table.find(loaded, s.Egg) and table.find(loaded, s.Other))
		assert(knowledge:InstanceId(s.Egg) ~= knowledge:InstanceId(s.Other) and s.NativeUpdates == 1)
		local logCount = #s.Logs preflight(s) assert(#s.Logs == logCount)
		assert(not s:Dispatch()) s:NoActions() s:Close()
	end)
end)

test("Test B classified noncatalog queue members block closer or tied all-name selection without becoming paid targets", function()
	for _, distance in ipairs({ 1, 2.01 }) do
		scenario(function(clock)
			local s = mixedNativeQueue(false)
			local knowledge, receiver = s.Controller.Knowledge, s.Controller.Knowledge.NativeEggFixtureReceiver
			local unknown = table.remove(receiver._chunks.coldB)
			assert(unknown.Name == "Egg" and s.Dependencies.Eggs[unknown.Name] == nil)
			unknown.Parent = receiver._folder
			unknown.Root.Position = s.Root.Position + Vector3.new(distance, 0, 0)
			unknown.Prompt.Position = unknown.Root.Position
			table.insert(receiver._chunks.loaded, unknown)
			s.NativeClass.Update(receiver, s.Root.Position)
			assert(knowledge.NativeEggChunkers[receiver] and knowledge.EggObserverStats.Receivers[receiver].Qualifies)
			completeNativeObservation(s, clock)
			local registered = knowledge:NativeRegisteredEggModels()
			assert(#registered == 3 and table.find(registered, unknown))
			assert(not knowledge:ResolveEggInstance("Egg", true, unknown), "Queue membership cannot create a known paid target")
			local eligible, observed, reason = knowledge:NativeEggRangeEligible({ Model = s.Egg }, s.Root, true)
			assert(not eligible and observed.Model == s.Egg and reason:find("Another or tied eligible registered original", 1, true))
			assert(not knowledge:NativeEggRangeEligible({ Model = unknown }, s.Root, true))
			local report = preflight(s)
			assert(report.Status == "HATCH_PREFLIGHT_BLOCKED" and report.Before.NativePrice == 10 and report.SpendingPermission == false)
			assert(not s:Dispatch()) s:NoActions() s:Close()
		end)
	end
end)

test("Test B a positively classified unknown original cannot dispatch an authorized synthetic paid hatch", function()
	scenario(function(clock)
		local s = mixedNativeQueue(true)
		local receiver, knowledge = s.Controller.Knowledge.NativeEggFixtureReceiver, s.Controller.Knowledge
		local unknown = table.remove(receiver._chunks.coldB)
		unknown.Parent = receiver._folder
		unknown.Root.Position = s.Root.Position + Vector3.new(3, 0, 0)
		unknown.Prompt.Position = unknown.Root.Position
		table.insert(receiver._chunks.loaded, unknown)
		s.NativeClass.Update(receiver, s.Root.Position)
		completeNativeObservation(s, clock)
		s.Controller.Config.HATCH_SETTINGS.SELECTED_EGGS = { "Egg" }
		local decision, context = s:Decision()
		assert(decision.Kind == "WAIT")
		local blocked
		for _, egg in ipairs(context.Eggs) do if egg.Name == "Egg" then blocked = egg end end
		assert(blocked and blocked.AccessStatus == "UNKNOWN_DEFINITION" and blocked.Model == nil and blocked.Cost == nil)
		assert(not knowledge:ResolveEggInstance("Egg", true, unknown) and not s:Dispatch())
		assert(not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:NoActions() s:Close()
	end)
end)

test("Test B selected visual prerequisite is separate from accepted exact queue membership and the independent price10 quote", function()
	for _, missing in ipairs({ true, false }) do
		scenario(function(clock)
			local s = mixedNativeQueue(false)
			completeNativeObservation(s, clock)
			local knowledge = s.Controller.Knowledge
			if missing then knowledge.NativeEggFixtureAssets["Common Egg"] = nil
			else knowledge.NativeEggFixtureAssets["Common Egg"] = { IsA = function() return false end } end
			assert(knowledge:ResolveEggInstance("Common Egg", true, s.Egg).Model == s.Egg)
			local eligible, _, reason = knowledge:NativeEggRangeEligible({ Model = s.Egg }, s.Root, true)
			assert(not eligible and reason:find("Selected native visual prerequisite unavailable", 1, true))
			local report = preflight(s)
			assert(report.Status == "HATCH_PREFLIGHT_BLOCKED" and report.Before.NativePrice == 10 and report.SpendingPermission == false)
			assert(report.Registration.QualifyingReceivers == 1 and report.Registration.SelectedLoaded)
			assert(not s:Dispatch()) s:NoActions() s:Close()
		end)
	end
end)

test("Test B mixed-queue registration cannot bypass current UI account storage cooldown or native hatch-idle guards", function()
	for _, mutate in ipairs({ function(s) s.Dependencies.ProximityPrompt.Visible = 1 end,
		function(s) s.Controller.Reader.Player.UserId = 456 end,
		function(s) s.Storage = 2 end, function(s) s.NextAt = 101 end,
		function(s) s.Hatching = true end, function(s) s.NativeAuto = "Common Egg" end,
		function(s) s.Profile.AutoDelete = { Rare = true } end }) do
		scenario(function(clock)
			local s = mixedNativeQueue(false)
			completeNativeObservation(s, clock) mutate(s)
			local report = preflight(s)
			assert(report.Registration.QualifyingReceivers == 1 and report.Registration.SelectedLoaded)
			assert(report.Status == "HATCH_PREFLIGHT_BLOCKED" and report.Before.NativePrice == 10 and report.SpendingPermission == false)
			assert(not s:Dispatch()) s:NoActions() s:Close()
		end)
	end
end)

test("Test B registration-blocked preflight reports an independent modifier-aware native price without permission", function()
	scenario(function()
		local s = fixture(false)
		s.Cost = 7
		s.Controller.Knowledge.NativeEggChunkers = {}
		for _, model in ipairs(s.Models) do model.Prompt:FindFirstChildOfClass("ProximityPrompt").Parent = nil end
		local report = preflight(s, function(_, context)
			assert(context.Eggs[1].Model == nil and context.Eggs[1].Cost.Amount == 10)
		end)
		assert(report.Status == "HATCH_PREFLIGHT_BLOCKED" and report.SpendingPermission == false)
		assert(report.Reason:find("NATIVE_EGG_IDENTITY_UNVERIFIED", 1, true))
		assert(report.Before.InstanceId == s.Controller.Knowledge.InstanceIds[s.Egg])
		assert(report.Before.NativePrice == 7 and report.Before.PriceReason == "NATIVE_STATSUTIL_QUOTE")
		local quoted = false
		for _, line in ipairs(s.Logs) do
			if line:find("HATCH_PREFLIGHT ", 1, true) and line:find("native price=7 Coins", 1, true) then quoted = true end
		end
		assert(quoted)
		assert(not s:Dispatch()) s:NoActions() s:Close()
	end)
end)

test("Test B native preflight quote requires current known ordinary Coins catalog and available valid helper output", function()
	for _, variant in ipairs({ "missing_catalog", "unsupported_catalog", "missing_helper", "throw", "invalid_currency", "invalid_amount" }) do
		scenario(function()
			local s = fixture(false)
			local report = preflight(s, function()
				if variant == "missing_catalog" then s.Dependencies.Eggs["Common Egg"] = nil
				elseif variant == "unsupported_catalog" then s.Dependencies.Eggs["Common Egg"].ProductId = 12345
				elseif variant == "missing_helper" then s.Dependencies.StatsUtil.GetEggCost = nil
				elseif variant == "throw" then s.Dependencies.StatsUtil.GetEggCost = function() error("Synthetic missing price") end
				elseif variant == "invalid_currency" then s.Dependencies.StatsUtil.GetEggCost = function() return { Type = "Currency", Currency = "Gems", Amount = 7 } end
				else s.Dependencies.StatsUtil.GetEggCost = function() return { Type = "Currency", Currency = "Coins", Amount = math.huge } end end
			end)
			assert(report.Status == "HATCH_PREFLIGHT_BLOCKED" and report.Before.NativePrice == nil)
			local reason = variant == "missing_catalog" and "NATIVE_PRICE_DEFINITION_UNAVAILABLE"
				or variant == "unsupported_catalog" and "NATIVE_PRICE_UNSUPPORTED_DEFINITION"
				or variant == "missing_helper" and "NATIVE_PRICE_HELPER_UNAVAILABLE"
				or variant == "throw" and "NATIVE_PRICE_HELPER_FAILED" or "NATIVE_PRICE_INVALID_QUOTE"
			assert(report.Before.PriceReason == reason and report.SpendingPermission == false)
			s:NoActions() s:Close()
		end)
	end
end)

test("Test B read-only native price quotation cannot mutate current LocalData through helper account caches", function()
	scenario(function()
		local s = fixture(false)
		local original = { Coins = s.Profile.Coins, PetAmount = s.Profile.Pets[1].Amount, TeamId = s.Profile.Teams[1].Pets[1] }
		s.Dependencies.StatsUtil.GetEggCost = function(_, player, facts, name)
			assert(player == s.Controller.Reader.Player and name == "Common Egg" and facts ~= s.Profile)
			facts.Coins, facts.Pets[1].Amount, facts.Teams[1].Pets[1] = 1, 999, "mutated detached quote"
			return { Type = "Currency", Currency = "Coins", Amount = 7 }
		end
		local report = preflight(s)
		assert(report.Status == "HATCH_PREFLIGHT_READY_ALLOWANCE_OFF" and report.Before.NativePrice == 7)
		assert(s.Profile.Coins == original.Coins and s.Profile.Pets[1].Amount == original.PetAmount
			and s.Profile.Teams[1].Pets[1] == original.TeamId)
		assert(not s:Dispatch()) s:NoActions() s:Close()
	end)
end)

test("Test B preflight status changes appear immediately while routine balance churn is throttled", function()
	scenario(function(clock)
		local s = fixture(false)
		preflight(s) local count = #s.Logs
		s.Profile.Coins += 1 clock.Time = 1 preflight(s) assert(#s.Logs == count)
		s.Profile.Coins += 1 clock.Time = 2 preflight(s) assert(#s.Logs == count)
		clock.Time = s.Controller.Config.DIAGNOSTIC_SETTINGS.MINIMUM_LOG_INTERVAL_SECONDS
		preflight(s) assert(#s.Logs == count + 1)
		s.Dependencies.ProximityPrompt.Visible = 1
		preflight(s) assert(#s.Logs == count + 2 and s.Manager.HatchPreflight.Status == "HATCH_PREFLIGHT_BLOCKED")
		preflight(s) assert(#s.Logs == count + 2)
		assert(not s:Dispatch()) s:NoActions() s:Close()
	end)
end)

test("Test B native registration diagnostics report the retained Instance without replacing eligibility or flooding update counters", function()
	scenario(function(clock)
		local s = fixture(false)
		local calls, diagnosticReason = 0, "OBSERVER_NATIVE_UPDATE_PENDING"
		s.Controller.Knowledge.NativeEggRegistrationDiagnostics = function(_, selected)
			assert(selected == s.Egg) calls += 1
			return { Reason = diagnosticReason, Summary = "read-only native Update count=" .. calls }
		end
		local report = preflight(s) local count = #s.Logs
		assert(report.Status == "HATCH_PREFLIGHT_READY_ALLOWANCE_OFF" and report.Before.RegistrationReason == diagnosticReason)
		assert(report.Registration.Summary == report.Before.RegistrationSummary and report.Before.RegistrationSummary:find("count=1", 1, true))
		clock.Time = 1 preflight(s) assert(#s.Logs == count and calls == 2)
		diagnosticReason = "OBSERVER_WINDOW_ENDED_BEFORE_QUALIFYING_UPDATE"
		preflight(s) assert(#s.Logs == count + 1 and s.Manager.HatchPreflight.Before.RegistrationReason == diagnosticReason)
		s.Controller.Knowledge.NativeEggRegistrationDiagnostics = function() error("Synthetic optional diagnostic failure") end
		report = preflight(s)
		assert(report.Before.RegistrationReason == "REGISTRATION_DIAGNOSTICS_UNAVAILABLE"
			and report.Status == "HATCH_PREFLIGHT_READY_ALLOWANCE_OFF" and report.SpendingPermission == false)
		assert(not s:Dispatch()) s:NoActions() s:Close()
	end)
end)

test("Test B ready and blocked preflight remain visible with debug OFF and identical reports remain silent", function()
	local originalPrint, output = print, {}
	print = function(value) table.insert(output, tostring(value)) end
	local ok, failure = xpcall(function()
		scenario(function()
			local s = fixture(false)
			s.Controller.Config.DIAGNOSTIC_SETTINGS.ENABLE_DEBUG_LOGGING = false
			s.Controller.Log = requireOC("OCController").Log
			local function countPreflight()
				local count = 0 for _, line in ipairs(output) do if line:find("[OC][HATCH_PREFLIGHT]", 1, true) then count += 1 end end return count
			end
			preflight(s) assert(countPreflight() == 1 and output[1]:find("HATCH_PREFLIGHT_READY_ALLOWANCE_OFF", 1, true))
			local initial = #output preflight(s) assert(#output == initial)
			s.Dependencies.ProximityPrompt.Visible = 1
			preflight(s) assert(countPreflight() == 2 and output[#output]:find("HATCH_PREFLIGHT_BLOCKED", 1, true))
			local changed = #output preflight(s) assert(#output == changed)
			assert(not s:Dispatch()) s:NoActions() s:Close()
		end)
	end, debug.traceback)
	print = originalPrint assert(ok, failure)
end)

test("Test B captured rejected receiver evidence is visible with debug OFF while native price10 remains blocked without trusted registration", function()
	local originalPrint, output = print, {}
	print = function(value) table.insert(output, tostring(value)) end
	local ok, failure = xpcall(function()
		scenario(function()
			local s = fixture(false)
			s.Profile.EggsOpened["Common Egg"] = 2
			s.Controller.Knowledge.NativeEggChunkers = {}
			for _, model in ipairs(s.Models) do model.Prompt:FindFirstChildOfClass("ProximityPrompt").Parent = nil end
			s.Controller.Config.DIAGNOSTIC_SETTINGS.ENABLE_DEBUG_LOGGING = false
			s.Controller.Log = requireOC("OCController").Log
			s.Controller.Knowledge.NativeEggRegistrationDiagnostics = function(_, selected)
				assert(selected == s.Egg)
				return { Stage = "TIMED_OUT_WITHOUT_QUALIFYING_EGG_RECEIVER", Reason = "Unsupported unloaded entry; trusted classification unchanged",
					SelectedInstanceId = s.Controller.Knowledge.InstanceIds[selected], CapturedSelectedFound = true, CapturedOtherOriginalFound = true,
					QualifyingReceivers = 0, ReceiverObservationComplete = true,
					ReceiverObservationKey = "captured_selected=true; other=true; qualifiers=0; complete=true",
					ReceiverObservationSummary = "Updates observed=85; candidates=5; exact selected original found=true; exact other original found=true; qualifiers=0; observation complete=true\n"
						.. "candidate=syntheticR4; structure=3D; loaded=2; coordinates=3; selected=true; same folder=true; rejected=MISSING_CATALOG_DEFINITION" }
			end
			local report = preflight(s)
			assert(report.Status == "HATCH_PREFLIGHT_BLOCKED" and report.Before.NativePrice == 10 and report.Before.PriceReason == "NATIVE_STATSUTIL_QUOTE")
			assert(report.Registration.CapturedSelectedFound and report.Registration.CapturedOtherOriginalFound and report.Registration.QualifyingReceivers == 0)
			assert(#output == 2 and output[1]:find("[OC][HATCH_PREFLIGHT]", 1, true)
				and output[2]:find("[OC][NATIVE_EGG_RECEIVER_OBSERVATION]", 1, true))
			assert(not output[1]:find("candidate=syntheticR4", 1, true) and output[2]:find("candidate=syntheticR4", 1, true))
			assert(output[1]:find("hatch requests=0; requested spending=0", 1, true))
			preflight(s) assert(#output == 2 and not s:Dispatch()) s:NoActions() s:Close()
		end)
	end, debug.traceback)
	print = originalPrint assert(ok, failure)
end)

test("Test B receiver observation call-count churn is throttled and exact membership or completion changes appear immediately", function()
	scenario(function(clock)
		local s = fixture(false)
		local updates, member, complete = 29, false, false
		s.Controller.Knowledge.NativeEggRegistrationDiagnostics = function()
			return { Stage = "NATIVE_UPDATES_OBSERVED_NO_QUALIFYING_EGG_RECEIVER", Reason = "Non-egg receiver remains rejected",
				ReceiverObservationComplete = complete, ReceiverObservationKey = "selected=" .. tostring(member),
				ReceiverObservationSummary = "Updates observed=" .. updates .. "; selected=" .. tostring(member) .. "; complete=" .. tostring(complete)
					.. "\nreceiver=syntheticR1; non-egg content; no trusted registration granted" }
		end
		local function observed()
			local count = 0 for _, line in ipairs(s.Logs) do if line:find("NATIVE_EGG_RECEIVER_OBSERVATION ", 1, true) then count += 1 end end return count
		end
		preflight(s) assert(observed() == 1)
		updates = 30 clock.Time = 1 preflight(s) assert(observed() == 1)
		updates = 31 clock.Time = 2 preflight(s) assert(observed() == 1)
		clock.Time = s.Controller.Config.DIAGNOSTIC_SETTINGS.MINIMUM_LOG_INTERVAL_SECONDS preflight(s) assert(observed() == 2)
		member = true preflight(s) assert(observed() == 3)
		complete = true preflight(s) assert(observed() == 4)
		preflight(s) assert(observed() == 4)
		assert(not s:Dispatch()) s:NoActions() s:Close()
	end)
end)

test("Test B duplicate Common originals permit one explicitly bounded eligible request and no unrelated actions", function()
	scenario(function()
		local s = fixture(true) local originalPosition = s.Root.Position
		local decision, context = s:Decision()
		assert(decision.Kind == "HATCH" and decision.Model == s.Egg and context.EggAvailability[1].Model == s.Egg)
		assert(s:Dispatch() and #s.Commands == 1 and s.Commands[1].Count == 1)
		assert(s.Manager.Hatch.RequestCost == 10 and s.Manager.Hatch.Pending.OwnerAllowance.WorldReserveBorrowed == 10)
		assert(not s:Dispatch() and #s.Commands == 1 and s.Root.Position == originalPosition)
		assert(s.Manager.EquipCommands == 0 and #s.Teleports == 0 and #s.Calls == 0 and s.Blows == 0) s:Close()
	end)
end)

test("Test B first-time cached native Buy Prompt permits only one request despite a far same-name original", function()
	scenario(function()
		local s = fixture(true) s.Opened = false s.Profile.EggsOpened["Common Egg"] = nil
		-- The opened scanner is intentionally suppressed while this exact initial
		-- Prompt remains usable. Its callback uses the separately verified name/1 contract.
		s.Dependencies.ProximityPrompt.Visible = 1
		local decision, context = s:Decision()
		assert(decision.Kind == "HATCH" and decision.Model == s.Egg)
		assert(context.EggAvailability[1].Opened == false and context.EggAvailability[1].InteractionMode == "INITIAL_PROMPT")
		assert(s:Dispatch() and #s.Commands == 1 and s.Commands[1].Count == 1 and s.Manager.Hatch.Pending.Counter == 0)
		assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.EquipCommands == 0) s:Close()
	end)
end)

test("Test B dispatch blocks insufficient Coins full storage and actual modified native cost above 10", function()
	for _, mutate in ipairs({ function(s) s.Profile.Coins = 59 end, function(s) s.Storage = 2 end, function(s) s.Cost = 11 end }) do
		scenario(function()
			local s = fixture(true) mutate(s) assert(not s:Dispatch()) s:NoActions()
			assert(not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:Close()
		end)
	end
end)

test("Test B native cooldown presentation competing auto hatch and prompt visibility prevent dispatch", function()
	for _, mutate in ipairs({ function(s) s.NextAt = 101 end, function(s) s.Hatching = true end,
		function(s) s.NativeAuto = "Common Egg" end, function(s) s.Dependencies.ProximityPrompt.Visible = 1 end }) do
		scenario(function()
			local s = fixture(true) mutate(s) assert(not s:Dispatch()) s:NoActions() s:Close()
		end)
	end
end)

test("Test B final native scan rejects a closer other egg without substituting it for the selected Common", function()
	scenario(function()
		local s = fixture(true)
		s.OnGuard = function(call) if call == 2 then s:AddEgg("Spotted Egg", 1) end end
		assert(not s:Dispatch()) s:NoActions()
		assert(not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:Close()
	end)
end)

test("Test B a same-name competitor becoming closer during the final guard cannot replace the retained selected Instance", function()
	scenario(function()
		local s = fixture(true)
		s.OnGuard = function(call) if call == 2 then s.Other.Root.Position = s.Root.Position + Vector3.new(1, 0, 0) end end
		assert(not s:Dispatch()) s:NoActions()
		assert(not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:Close()
	end)
end)

test("Test B enabled frozen travel observes stable already-in-range arrival and permits one independent paid hatch", function()
	scenario(function()
		local s = fixture(true)
		local travel = verifyExistingTravelLease(s)
		assert(s:Dispatch() and #s.Commands == 1 and s.Commands[1].Count == 1)
		assert(travel.Lease.Model == s.Egg and s.Manager.Hatch.Pending.DiagnosticBefore.InstanceId == s.Controller.Knowledge:InstanceId(s.Egg))
		assert(not s:Dispatch() and #s.Commands == 1 and #s.Teleports == 0 and s.Manager.EquipCommands == 0) s:Close()
	end)
end)

test("Test B enabled frozen travel cannot bypass a new closer registered egg or a competing usable initial Prompt", function()
	for _, initial in ipairs({ false, true }) do
		scenario(function()
			local s = fixture(true)
			if initial then s.Opened = false s.Profile.EggsOpened["Common Egg"] = nil end
			local travel = verifyExistingTravelLease(s)
			s.OnGuard = function(call)
				if call ~= 2 then return end
				if initial then s.Other.Prompt.Position = s.Root.Position + Vector3.new(6, 0, 0)
				else s:AddEgg("Spotted Egg", 1) end
			end
			assert(not s:Dispatch()) s:NoActions()
			assert(travel.Lease and travel.Lease.Model == s.Egg)
			assert(not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:Close()
		end)
	end
end)

test("Test B final paid verification includes a newly registered uncatalogued competitor even with a valid frozen travel lease", function()
	scenario(function()
		local s = fixture(true)
		verifyExistingTravelLease(s)
		s.Controller.Knowledge.EggModels = function()
			local visible = {} for _, model in ipairs(s.Models) do if s.Dependencies.Eggs[model.Name] then table.insert(visible, model) end end return visible
		end
		s.OnGuard = function(call)
			if call ~= 2 then return end
			local competitor = s:AddEgg("New uncatalogued native egg", 1)
			s.Dependencies.Eggs[competitor.Name] = nil
		end
		assert(not s:Dispatch()) s:NoActions()
		assert(not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:Close()
	end)
end)

test("Test B replaced or unloaded selected physical Instance cannot transfer a one-hatch request", function()
	for _, replace in ipairs({ false, true }) do
		scenario(function()
			local s = fixture(true)
			s.OnGuard = function(call)
				if call ~= 2 then return end
				if replace then s:AddEgg("Common Egg", 2.01) s.Egg.Parent = nil
				else s.Controller.Knowledge.NativeEggFixtureReceiver._loaded.fixture = nil end
			end
			assert(not s:Dispatch()) s:NoActions() s:Close()
		end)
	end
end)

test("Test B frozen account authorization rejects a different current account before its first hatch", function()
	scenario(function()
		local s = fixture(true) s.Controller.Reader.Player.UserId = 456
		assert(not s:Dispatch()) s:NoActions()
		assert(not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:Close()
	end)
end)

test("Test B final account respawn cancellation and pause guards consume no allowance or commands", function()
	for _, mutate in ipairs({ function(s) s.Controller.Reader.Player.UserId = 456 end,
		function(s) s.Controller.Reader.Player.Character = {} end,
		function(s) s.Root = { Position = s.Root.Position, Parent = s.Character } end,
		function(s) s.Cancelled = true end, function(s) s.Controller.State = "PAUSED" end }) do
		scenario(function()
			local s = fixture(true) s.OnGuard = function(call) if call == 2 then mutate(s) end end
			assert(not s:Dispatch()) s:NoActions()
			assert(not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:Close()
		end)
	end
end)

test("Test B a current account with zero pets remains valid rather than using a prior account inventory", function()
	scenario(function()
		local s = fixture(true) s.Profile.Pets = {} s.Profile.Teams[1].Pets = {}
		local decision, context = s:Decision()
		assert(context.Inventory and context.Inventory.Records == 0 and context.AccountId == 123)
		assert(context.ScoreTeam({}) == 2 and decision.Kind == "HATCH")
		assert(s:Dispatch() and next(s.Manager.Hatch.Pending.Before) == nil and #s.Commands == 1) s:Close()
	end)
end)

test("Test B received matching pet counter and net Coins change verify only the actual current account outcome", function()
	scenario(function()
		local s = fixture(true) assert(s:Dispatch())
		s.Profile.Pets[2] = { Id = "received", Name = "New" }
		s.Profile.EggsOpened["Common Egg"], s.Profile.Coins = 1, 490
		s.Manager:Observe()
		local result = s.Manager.Hatch.LastResult
		assert(result.Status == "INVENTORY_GAIN_OBSERVED" and result.Quantity == 1 and result.CounterDelta == 1)
		assert(result.Balances.Coins.Before == 500 and result.Balances.Coins.After == 490 and result.Balances.Coins.Delta == -10)
		assert(result.Changes[1].Id == "received" and not s:Dispatch() and #s.Commands == 1 and s.Manager.EquipCommands == 0) s:Close()
	end)
end)

test("Test B actual Pet task executor reports exactly one captured snapshot and actual invocation before receiving its result", function()
	scenario(function()
		local s = fixture(true)
		local intent = s:Decision()
		local slice = s.Manager:Definition(intent, s.Controller.Generation)
		assert(type(slice.Execute(s.Token)) == "table" and #s.Commands == 1)
		local function count(tag)
			local total = 0 for _, line in ipairs(s.Logs) do if line:find(tag .. " ", 1, true) == 1 then total += 1 end end return total
		end
		assert(count("HATCH_BEFORE_SNAPSHOT") == 1 and count("HATCH_REQUEST_ATTEMPTED") == 1)
		assert(s.Manager.Hatch.Pending and not s.Manager.Hatch.LastResult and s.Manager.Hatch.VerifiedHatches == 0)
		assert(type(slice.Execute(s.Token)) == "table" and #s.Commands == 1)
		assert(count("HATCH_BEFORE_SNAPSHOT") == 1 and count("HATCH_REQUEST_ATTEMPTED") == 1)
		s.Profile.Pets[2] = { Id = "received", Name = "New" }
		s.Profile.EggsOpened["Common Egg"], s.Profile.Coins = 1, 490
		s.Manager:Observe()
		assert(s.Manager.Hatch.LastResult.Status == "INVENTORY_GAIN_OBSERVED" and s.Manager.Hatch.VerifiedHatches == 1)
		assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.EquipCommands == 0) s:Close()
	end)
end)

test("Test B optional post-dispatch diagnostic logging failure cannot inhibit result observation or permit another request", function()
	scenario(function()
		local s = fixture(true)
		local originalLog = s.Controller.Log
		s.Controller.Log = function(c, tag, message)
			if tag == "HATCH_BEFORE_SNAPSHOT" or tag == "HATCH_REQUEST_ATTEMPTED" then error("Synthetic diagnostic sink failure") end
			return originalLog(c, tag, message)
		end
		local intent = s:Decision()
		assert(type(s.Manager:Definition(intent, s.Controller.Generation).Execute(s.Token)) == "table")
		assert(#s.Commands == 1 and s.Manager.Hatch.Pending)
		s.Profile.Pets[2] = { Id = "received", Name = "New" }
		s.Profile.EggsOpened["Common Egg"], s.Profile.Coins = 1, 490
		s.Manager:Observe()
		assert(s.Manager.Hatch.LastResult.Status == "INVENTORY_GAIN_OBSERVED" and not s:Dispatch() and #s.Commands == 1) s:Close()
	end)
end)

test("Test B delayed or missing acknowledgment keeps one consumed request across same-VM reload", function()
	scenario(function(clock)
		local s = fixture(true) assert(s:Dispatch())
		clock.Time = 10 s.Manager:Observe() assert(s.Manager.Hatch.Pending and not s:Dispatch() and #s.Commands == 1)
		clock.Time = 16 s.Manager:Observe() assert(s.Manager.Hatch.LastResult.Status == "UNCONFIRMED")
		s.Controller.HatchTestAllowance = Allowance.new(s.Controller)
		s.Manager = Pets.new(s.Controller) s.Controller.Pets = s.Manager
		assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.Hatch.RequestedHatches == 0 and s.Manager.EquipCommands == 0) s:Close()
	end)
end)

test("Test B Stop before dispatch permanently ends the prepared authorization without consumption", function()
	scenario(function()
		local s = fixture(true) s.Manager:Halt(true) s.Controller.HatchTestAllowance:Halt(true)
		assert(not s:Dispatch()) s:NoActions()
		assert(not s.Controller.HatchTestAllowance:GetStatus().Consumed) s:Close()
	end)
end)

print("[OC TEST] " .. tostring(tests - before) .. " guarded Common Egg Test B regressions passed; synthetic proof only, allowance remains OFF in release preflight")
end

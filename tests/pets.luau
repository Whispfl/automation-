-- Test-only native registration fixtures. Production observation stays strict:
-- these tables explicitly model an original in a loaded native 3D egg chunk.
local function registerNativeEggFixture(knowledge, model, scene)
	local folder = knowledge.NativeEggFixtureFolder
	if not folder then
		assert(scene, "First native registration fixture requires scene cleanup ownership")
		local previousFind = workspace.FindFirstChild
		local previousTypeof = typeof
		local previousAssetsOverride, inheritedAssets = rawget(knowledge, "Assets"), knowledge.Assets
		local visualRows = {}
		knowledge.NativeEggFixtureAssets = visualRows
		local eggAssets = { FindFirstChild = function(_, name) return visualRows[name] end }
		knowledge.Assets = function(self, name)
			if name == "Eggs" then return eggAssets end
			return inheritedAssets(self, name)
		end
		typeof = function(value)
			return type(value) == "table" and rawget(value, "SyntheticEggInstance") == true and "Instance" or previousTypeof(value)
		end
		local rendered = previousFind(workspace, "Rendered") or { Name = "Rendered", Parent = workspace }
		workspace.FindFirstChild = function(self, name)
			if name == "Rendered" then return rendered end
			return previousFind(self, name)
		end
		local previousClose = scene.Close
		scene.Close = function(self)
			workspace.FindFirstChild = previousFind
			typeof = previousTypeof
			knowledge.Assets, knowledge.NativeEggFixtureAssets = previousAssetsOverride, nil
			return previousClose(self)
		end
		folder = { Name = "Chunker", Parent = rendered, IsA = function(_, kind) return kind == "Folder" end }
		knowledge.NativeEggFixtureFolder = folder
		-- Source-shaped current geometry, distinct from the registration table.
		-- Each world has an actual Spawn and each defined island has a live pivot.
		local worlds, worldRows = {}, {}
		for worldName, definition in pairs(knowledge:Get("Worlds") or {}) do
			local world = { Name = worldName, Parent = worlds }
			local x = worldName == "The Overworld" and 0 or 10000 + #worldRows * 10000
			local spawn = { Parent = world, Position = Vector3.new(x, 0, 0), IsA = function(_, kind) return kind == "BasePart" end }
			local islands, rows = {}, {}
			for index, entry in ipairs(definition.Islands or {}) do
				local position = Vector3.new(x, entry.Height or scene.Root.Position.Y + (index - 1) * 3000, 0)
				local island = { GetPivot = function() return { Position = position } end, FindFirstChild = function() return nil end }
				rows[entry.Name] = { FindFirstChild = function(_, name) return name == "Island" and island or nil end }
			end
			islands.FindFirstChild = function(_, name) return rows[name] end
			world.FindFirstChild = function(_, name) if name == "Spawn" then return spawn elseif name == "Islands" then return islands end end
			worlds[worldName] = world table.insert(worldRows, world)
		end
		worlds.GetChildren = function() return worldRows end
		worlds.FindFirstChild = function(_, name) return worlds[name] end
		local renderedFind = workspace.FindFirstChild
		workspace.FindFirstChild = function(self, name) if name == "Worlds" then return worlds end return renderedFind(self, name) end
		knowledge.NativeEggFixtureWorlds = worlds
		local receiver = { Mode = "3D", _chunkSize = 128, RenderDistance = 2, _folder = folder,
			_chunks = { fixture = {} }, _loaded = { fixture = true } }
		knowledge.NativeEggFixtureReceiver = receiver
		knowledge.NativeEggChunkers = { [receiver] = true }
		knowledge.EggObservationFinished = true
	end
	-- Explicit test visual prerequisite, separate from original registration.
	knowledge.NativeEggFixtureAssets[model.Name] = { Name = model.Name, IsA = function(_, kind) return kind == "Model" end }
	local root, prompt = model:FindFirstChild("Root"), model:FindFirstChild("Prompt")
	if root.Parent and root.Parent ~= model and root.Parent ~= true then root = table.clone(root) end
	if not prompt or not prompt.IsA or not prompt:IsA("BasePart") then
		prompt = { Position = root.Position, IsA = function(_, kind) return kind == "BasePart" end }
	elseif prompt.Parent and prompt.Parent ~= model and prompt.Parent ~= true then
		prompt = table.clone(prompt)
	end
	if prompt == root then prompt = table.clone(prompt) end
	model.Root, model.Prompt = root, prompt
	model.SyntheticEggInstance, root.SyntheticEggInstance, prompt.SyntheticEggInstance = true, true, true
	root.Parent, prompt.Parent, model.Parent = model, model, folder
	root.IsDescendantOf = root.IsDescendantOf or function(self) return self.Parent ~= nil and self.Parent.Parent ~= nil end
	prompt.IsDescendantOf = prompt.IsDescendantOf or root.IsDescendantOf
	model.IsA = model.IsA or function(_, kind) return kind == "Model" end
	model.IsDescendantOf = model.IsDescendantOf or function(self) return self.Parent ~= nil end
	local plate = { Parent = model, Position = root.Position, IsA = function(_, kind) return kind == "BasePart" end }
	local cost = { Parent = model, Position = root.Position, IsA = function(_, kind) return kind == "BasePart" end }
	plate.SyntheticEggInstance, cost.SyntheticEggInstance = true, true
	model.FindFirstChild = function(_, name)
		if name == "Root" then return root elseif name == "Prompt" then return prompt
		elseif name == "Plate" then return plate elseif name == "Cost" then return cost end
	end
	local nativePrompt = prompt.FindFirstChildOfClass and prompt:FindFirstChildOfClass("ProximityPrompt")
	if not nativePrompt or nativePrompt.Parent ~= prompt then
		nativePrompt = { Parent = prompt, Enabled = true, MaxActivationDistance = 6.5, RequiresLineOfSight = false }
		prompt.FindFirstChildOfClass = function() return nativePrompt end
	end
	local prompts = knowledge:Get("ProximityPrompt")
	if prompts then prompts._cache = prompts._cache or {} prompts._cache[nativePrompt] = true end
	table.insert(knowledge.NativeEggFixtureReceiver._chunks.fixture, model)
	return model
end

-- Manager-only mock knowledge intentionally supplies an explicit identity
-- contract; it does not create a production interface-only fallback.
local function mockNativeEggIdentity(knowledge)
	local ids, nextId = {}, 0
	function knowledge:InteractiveEggModels(force)
		local models = {}
		for _, model in ipairs(self:EggModels(force)) do
			if model.Parent and model:IsDescendantOf(workspace) then
				local root, prompt = model:FindFirstChild("Root"), model:FindFirstChild("Prompt")
				if root and root.IsA and root:IsA("BasePart") and prompt and prompt.IsA and prompt:IsA("BasePart")
					and model:FindFirstChild("Plate") and model:FindFirstChild("Cost") then table.insert(models, model) end
			end
		end
		return models
	end
	function knowledge:ResolveEggInstance(name, force, expectedModel)
		local models = {}
		for _, model in ipairs(self:InteractiveEggModels(force)) do if model.Name == name then table.insert(models, model) end end
		if #models > 1 then return nil, "AMBIGUOUS_NATIVE_EGG_MODEL: synthetic registered original instances remain ambiguous" end
		if #models == 0 then return nil, "Selected original egg model is not loaded; no force-load or event chase" end
		local model = models[1]
		if expectedModel and model ~= expectedModel then return nil, "Brain selected original egg model changed; no stale travel" end
		if not ids[model] then nextId += 1 ids[model] = "SYNTHETIC_EGG_" .. nextId end
		local definition = (self:Get("Eggs") or {})[name] or {}
		local prompt = model:FindFirstChild("Prompt")
		local engine = prompt.FindFirstChildOfClass and prompt:FindFirstChildOfClass("ProximityPrompt")
		return { Model = model, Root = model:FindFirstChild("Root"), Prompt = model:FindFirstChild("Prompt"),
			World = definition.World, Island = model:GetAttribute("Island") or definition.Island,
			IdentityId = ids[model], IdentityEvidence = "SYNTHETIC_REGISTERED_NATIVE_ORIGINAL",
			PromptCacheMember = engine ~= nil and engine.Parent == prompt, NativePrompt = engine }
	end
	function knowledge:ResolveEggLocation(name, force, expectedModel, characterRoot)
		local models = {}
		for _, model in ipairs(self:InteractiveEggModels(force)) do
			if model.Name == name and (not expectedModel or model == expectedModel) then table.insert(models, model) end
		end
		if #models == 0 then return nil, "EGG_LOCATION_SELECTED_INSTANCE_UNAVAILABLE: synthetic physical original missing" end
		if characterRoot then table.sort(models, function(a, b)
			return (a:FindFirstChild("Root").Position - characterRoot.Position).Magnitude < (b:FindFirstChild("Root").Position - characterRoot.Position).Magnitude
		end) end
		local model = models[1]
		if not ids[model] then nextId += 1 ids[model] = "SYNTHETIC_EGG_" .. nextId end
		local definition = (self:Get("Eggs") or {})[name] or {}
		return { Model = model, Root = model:FindFirstChild("Root"), Prompt = model:FindFirstChild("Prompt"),
			World = definition.World, Island = model:GetAttribute("Island") or definition.Island, IdentityId = ids[model],
			LocationVerified = true, LocationAnchor = model:FindFirstChild("Root"), LocationAnchorPosition = model:FindFirstChild("Root").Position,
			LocationEvidence = "SYNTHETIC_SOURCE_ASSOCIATED_PHYSICAL_ORIGINAL", InteractionVerified = false }
	end
end

do
-- Synthetic native helpers/contracts. No real account, probability or server proof.
local before = tests
local Policy = requireOC("PetPolicy")
local Manager = requireOC("PetManager")
local Controller = requireOC("OCController")
local token = { CheckCancelled = function() return false end }
local function fixture(overrides)
	local values = { PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, OBJECTIVE_CURRENCY = "Coins", AUTO_HATCH = true },
		HATCH_SETTINGS = { SELECTED_EGGS = { "Test Egg" }, MAXIMUM_EGG_COST = 10, MAXIMUM_SESSION_COST = 30,
			MAXIMUM_SESSION_HATCHES = 3, MAXIMUM_BATCH_HATCHES = 2 }, PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = false },
		RESOURCE_SETTINGS = { COIN_RESERVE = 50 }, FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false } }
	for category, settings in pairs(overrides or {}) do values[category] = values[category] or {} for key, value in pairs(settings) do values[category][key] = value end end
	local s = stationaryFixture(values)
	s.Profile.Coins = 10000
	s.Profile.Pets = { { Id = "weak", Name = "Weak", XP = 0 }, { Id = "strong", Name = "Strong", XP = 0, Amount = 2 } }
	s.Profile.Teams = { { Pets = { "weak" } } } s.Profile.TeamEquipped = 1
	s.Profile.AutoDelete, s.Profile.EggsOpened = {}, { ["Test Egg"] = 0 }
	s.Ranks, s.GemRanks = { Weak = 2, Strong = 5, New = 9 }, { Weak = 20, Strong = 2, New = 1 }
	s.MaxEquipped, s.MaxHatches, s.StorageCap, s.Digital = 2, 3, 100, false
	s.Cost, s.Duration, s.NextAt, s.NativeActive, s.Hatching = 10, 2, nil, nil, false
	s.Pool = { { Chance = 1, Item = { Type = "Pet", Name = "Weak" } }, { Chance = 3, Item = { Type = "Pet", Name = "New" } } }
	s.Commands = {}
	local d = s.Dependencies
	d.Pets = { Weak = { Rarity = "Common" }, Strong = { Rarity = "Rare" }, New = { Rarity = "Epic" } }
	d.Eggs = { ["Test Egg"] = { World = "The Overworld", Island = "The Void", Cost = { Type = "Currency", Currency = "Coins", Amount = 1000 } } }
	d.Worlds = { ["The Overworld"] = { Order = 1, Islands = {} }, Next = { Order = 2, UnlockCost = { Type = "Currency", Currency = "Coins", Amount = 100 } } }
	d.StatsUtil.GetMaxPetsEquipped = function() return s.MaxEquipped end
	d.StatsUtil.GetMaxEggHatches = function() return s.MaxHatches end
	d.StatsUtil.GetMaxPetStorage = function() return s.StorageCap end
	d.StatsUtil.HasDigitalStorage = function() return s.Digital end
	d.StatsUtil.GetUsedPetStorage = function(_, raw) if s.Digital then return s.Bytes or 999 end local n = 0 for _, p in ipairs(raw.Pets) do n += p.Amount or 1 end return n end
	d.StatsUtil.IsInventoryFull = function(self, raw) return self:GetUsedPetStorage(raw) >= self:GetMaxPetStorage(raw) end
	d.StatsUtil.GetCurrencyMultiplier = function(_, raw, currency)
		if s.ScoreError then error("Synthetic helper unavailable") end
		local byId = {} for _, p in ipairs(raw.Pets) do byId[p.Id] = p end
		local value = 1
		for _, id in ipairs(raw.Teams[raw.TeamEquipped].Pets) do value += (currency == "Gems" and s.GemRanks or s.Ranks)[byId[id].Name] - 1 end
		return value
	end
	d.StatsUtil.GetBubblePower = function() if s.BubbleError then error("Synthetic bubbles unavailable") end return 20 end
	d.PetUtil = { GetStats = function(_, pet) return { Coins = s.Ranks[pet.Name], Gems = s.GemRanks[pet.Name], Bubbles = 3 } end }
	d.StatsUtil.GetEggCost = function() return { Type = "Currency", Currency = "Coins", Amount = s.Cost } end
	d.StatsUtil.GetLuckMultiplier = function() return 2 end
	d.StatsUtil.GetHatchDuration = function() return s.Duration end
	d.GetEggPool = function(_, world, luck, secret, infinity) assert(world == "The Overworld" and luck == 2 and secret == nil and infinity == nil) return s.Pool end
	d.WorldUtil = { GetPlayerWorld = function() return "The Overworld" end }
	d.ProximityPrompt = { Visible = 0 }
	d.HatchPresentation = { IsHatching = function() return s.Hatching end }
	d.Time = { now = function() return os.clock() end }
	d.Remote = { FireServer = function(_, command, first, second)
		table.insert(s.Commands, { Command = command, First = first, Count = second })
		if s.OnCommand then s.OnCommand(command, first, second) end
		if s.RemoteError then error("Synthetic uncertain delivery") end
	end }
	local auto = { IsA = function(_, kind) return kind == "BindableFunction" end,
		Invoke = function() if s.OnAutoGuard then s.OnAutoGuard() end return s.NativeActive end }
	s.Controller.Reader.Player = { Name = "CurrentTestAccount", UserId = 123,
		FindFirstChild = function(_, name) return name == "PlayerScripts" and { FindFirstChild = function() return { FindFirstChild = function() return auto end } end } end,
		GetAttribute = function(_, name) return name == "NextEggOpenAt" and s.NextAt or nil end }
	s.Controller.Reader.GetSnapshot = function() return { Ready = true, Revision = 1, Balances = { Coins = s.Profile.Coins, Gems = s.Profile.Gems }, AvailableProgression = {} } end
	s.Controller.Reader.Config = s.Controller.Config
	local part = { Position = s.Root.Position + Vector3.new(2, 0, 0), IsA = function(_, kind) return kind == "BasePart" end }
	local prompt = setmetatable({ IsA = function(_, kind) return kind == "BasePart" end },
		{ __index = function(_, key) if key == "Position" then return s.PromptPosition or part.Position end end })
	local nativePrompt = { Parent = prompt, Enabled = true, MaxActivationDistance = 6.5, RequiresLineOfSight = false }
	prompt.FindFirstChildOfClass = function() return nativePrompt end
	s.EggPrompt, s.NativePrompt = prompt, nativePrompt
	s.Egg = { Name = "Test Egg", Parent = true, IsA = function(_, kind) return kind == "Model" end,
		IsDescendantOf = function(self) return self.Parent ~= nil end,
		FindFirstChild = function(_, name) if name == "Root" then return part elseif name == "Prompt" then return prompt end return {} end,
		GetAttribute = function(_, name) if name == "Unlocked" then return s.Unlocked ~= false end end }
	s.EggPart = part
	s.Controller.Knowledge = s.Coordinator.Knowledge
	registerNativeEggFixture(s.Controller.Knowledge, s.Egg, s)
	s.Controller.Knowledge.EggModels = function() return { s.Egg } end
	s.Controller.Farming = s.Coordinator
	s.Manager = Manager.new(s.Controller)
	function s:Decision() local _, ctx = self.Manager:Fresh() return self.Controller.Brain:PlanPets(self.Controller.Brain:AnalyzePets(select(1, self.Manager:Fresh()), ctx), ctx, self.Manager:State()) end
	function s:Dispatch(decision) return self.Coordinator.Mechanics:PetAction(self.Manager, decision or self:Decision(), token) end
	return s
end

test("Phase 4 defaults and validation require separate explicit action authorization", function()
	assert(not Defaults.PET_SETTINGS.ENABLE_PET_INTELLIGENCE and not Defaults.PET_SETTINGS.AUTO_HATCH and not Defaults.PET_SETTINGS.AUTO_EQUIP)
	for _, bad in ipairs({ { PET_SETTINGS = { AUTO_EQUIP = true } }, { PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = true } },
		{ PET_SETTINGS = { AUTO_DELETE_PETS = true } }, { PET_SETTINGS = { AUTO_CRAFT_SHINY = true } }, { PET_SETTINGS = { AUTO_FUSE_PETS = true } },
		{ HATCH_SETTINGS = { MAXIMUM_BATCH_HATCHES = 13 } }, { PET_SETTINGS = { OBJECTIVE_CURRENCY = "Robux" } },
		{ PET_SETTINGS = { MAXIMUM_TEAM_EVALUATIONS = 1.5 } }, { HATCH_SETTINGS = { MINIMUM_REQUEST_INTERVAL_SECONDS = 0 } } }) do
		assert(not pcall(function() local c = Controller.new(config(bad)) c:Destroy() end))
	end
end)

test("Pet inventory distinguishes stack quantity and record count and validates duplicate equipped copies", function()
	local raw = { Pets = { { Id = "a", Name = "A", Amount = 3 } }, Teams = { { Pets = { "a", "a" } } }, TeamEquipped = 1 }
	local inv = Policy.Inventory(raw) assert(inv.Records == 1 and inv.Quantity == 3 and #inv.Team == 2)
	raw.Pets[1].Amount = 1 assert(Policy.Inventory(raw) == nil)
	raw.Pets[1].Amount = false assert(Policy.Inventory(raw) == nil)
	raw.Pets[1].Amount = 3 raw.Teams[1].Pets = { [2] = "a" } assert(Policy.Inventory(raw) == nil)
	raw.Teams[1].Pets = { "a" } raw.Pets[2] = table.clone(raw.Pets[1]) assert(Policy.Inventory(raw) == nil)
end)

test("Native projections find stronger owned stacked copies first without mutating live profile", function()
	simulated(function()
		local s = fixture() local snapshot, ctx = s.Manager:Fresh() local report = s.Controller.Brain:AnalyzePets(snapshot, ctx)
		assert(report.Team.CurrentScore == 2 and report.Team.ProjectedScore == 9 and report.Team.Gain == 7)
		assert(Policy.SameTeam(report.Team.ProposedIds, { "strong", "strong" }))
		assert(#s.Profile.Pets == 2 and #s.Profile.Teams[1].Pets == 1 and s.Profile.Teams[1].Pets[1] == "weak" and #s.Commands == 0)
		assert(ctx.DigitalStorage == false and ctx.InventoryFull == false) s:Close()
	end)
end)

test("Team roles use actual currency modifiers and helper failures remain unknown", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { OBJECTIVE_CURRENCY = "Gems" } }) local _, ctx = s.Manager:Fresh()
		assert(Policy.Team(s.Controller.Config, ctx).CurrentScore == 20)
		s.ScoreError = true _, ctx = s.Manager:Fresh() assert(Policy.Team(s.Controller.Config, ctx).Status == "UNKNOWN")
		s.ScoreError = false s.BubbleError = true s.Controller.Config.PET_SETTINGS.OBJECTIVE_CURRENCY = "Bubbles"
		_, ctx = s.Manager:Fresh() assert(Policy.Team(s.Controller.Config, ctx).Status == "UNKNOWN", "Bubbles cannot fall back to a currency multiplier") s:Close()
	end)
end)

test("Locked target protected unknown-definition and Super pets survive owned-team optimization", function()
	simulated(function()
		local s = fixture() s.MaxEquipped = 1
		for _, protection in ipairs({ "Locked", "Target", "ID", "Super", "Unknown" }) do
			s.Profile.Pets[1].Locked, s.Profile.Pets[1].Super = protection == "Locked", protection == "Super"
			s.Controller.Config.PET_SETTINGS.SELECTED_PETS = protection == "Target" and { "Weak" } or {}
			s.Controller.Config.PET_SETTINGS.PROTECTED_PET_IDS = protection == "ID" and { "weak" } or {}
			s.Dependencies.Pets.Weak = protection ~= "Unknown" and { Rarity = "Common" } or nil
			local _, ctx = s.Manager:Fresh() assert(Policy.Team(s.Controller.Config, ctx).Gain == 0)
		end s:Close()
	end)
end)

test("Egg weights give explicitly estimated incremental benefit against feasible owned team", function()
	simulated(function()
		local s = fixture() local snap, ctx = s.Manager:Fresh() local r = s.Controller.Brain:AnalyzePets(snap, ctx).Eggs[1]
		assert(r.Cost.Amount == 10 and r.Reserve == 150 and r.Spendable == 9850 and r.Affordable)
		assert(r.BaselineScore == 9 and r.ExpectedIncrement == 3 and r.ClientImprovementProbability == 0.75 and r.Outcomes[2].ClientPoolProbability == 0.75)
		assert(r.EffectiveCycleSeconds == 5 and r.ExpectedIncrementPerSecond == 0.6)
		assert(r.TotalTimeSeconds == "UNKNOWN" and r.EffectiveServerOdds == "UNKNOWN" and r.VariantOdds == "UNKNOWN" and r.PityGuarantee == "UNKNOWN") s:Close()
	end)
end)

test("Missing weights stats access balances and progression costs never fabricate eligible egg estimates", function()
	simulated(function()
		local s = fixture()
		local function report() local a, b = s.Manager:Fresh() return s.Controller.Brain:AnalyzePets(a, b).Eggs[1] end
		s.Pool[2].Chance = nil assert(report().Status == "UNKNOWN") s.Pool[2].Chance = 3
		s.Pool[2].Item.Type = "Currency" assert(report().Status == "UNKNOWN") s.Pool[2].Item.Type = "Pet"
		s.Dependencies.Worlds.Next.UnlockCost = nil assert(report().Status == "ESTIMATE" and report().FundingStatus == "UNKNOWN_RESERVE" and not report().Affordable)
		s.Dependencies.Worlds.Next.UnlockCost = { Type = "Currency", Currency = "Coins", Amount = 100 }
		s.Profile.Coins = nil assert(report().FundingStatus == "UNKNOWN_BALANCE" and not report().Affordable) s.Profile.Coins = 10000
		s.Profile.AreasUnlocked["The Void"] = nil assert(not report().Eligible) s:Close()
	end)
end)

test("Premium events and special eggs are excluded despite retained scene/catalog definitions", function()
	simulated(function()
		local s = fixture() for _, flag in ipairs({ "Event", "ProductId", "IsAdminEgg" }) do
			s.Dependencies.Eggs["Test Egg"][flag] = true local snap, ctx = s.Manager:Fresh()
			assert(not s.Controller.Brain:AnalyzePets(snap, ctx).Eggs[1].Eligible) s.Dependencies.Eggs["Test Egg"][flag] = nil
		end s:Close()
	end)
end)

test("Analysis-only settings never own location or issue hatch/equipment commands", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false, AUTO_EQUIP = false } })
		local owns = s.Manager:Select({}) assert(not owns and not s.Manager.Hatch.Location)
		assert(not s:Dispatch({ Kind = "HATCH", EggName = "Test Egg", Count = 1 }))
		assert(not s:Dispatch({ Kind = "TEAM", AddId = "strong" })) assert(#s.Commands == 0)
		assert(s.Manager.Report.Account.Name == "CurrentTestAccount") s:Close()
	end)
end)

test("Bounded hatch dispatch retains request cost and awaits both actual inventory and counter", function()
	simulated(function()
		local s = fixture() local owns, action = s.Manager:Select({}) assert(owns and action.Kind == "HATCH" and action.Count == 2)
		assert(s:Dispatch(action) and #s.Commands == 1 and s.Commands[1].Command == "HatchEgg" and s.Commands[1].Count == 2)
		assert(s.Manager.Hatch.RequestedHatches == 2 and s.Manager.Hatch.RequestCost == 20 and s.Manager.Hatch.VerifiedHatches == 0)
		s.Profile.Coins -= 20 s.Profile.Pets[3] = { Id = "new", Name = "New", Amount = 2 }
		s.Manager:Observe() assert(s.Manager.Hatch.Pending and s.Manager.Hatch.VerifiedHatches == 0)
		s.Profile.EggsOpened["Test Egg"] = 2 s.Manager:Observe()
		assert(not s.Manager.Hatch.Pending and s.Manager.Hatch.VerifiedHatches == 2 and s.Manager.Hatch.BestHatch.Name == "New")
		assert(s.Profile.Teams[1].Pets[1] == "weak" and #s.Commands == 1) s:Close()
	end)
end)

test("Hatch counter or balance changes alone cannot verify received pets", function()
	simulated(function()
		local s = fixture() assert(s:Dispatch()) s.Profile.Coins -= 20 s.Profile.EggsOpened["Test Egg"] = 2
		s.Manager:Observe() assert(s.Manager.Hatch.Pending and s.Manager.Hatch.VerifiedHatches == 0)
		s.Profile.Pets[3] = { Id = "unrelated", Name = "Strong", Amount = 2 } s.Manager:Observe() assert(s.Manager.Hatch.Pending) s:Close()
	end)
end)

test("Pending timeout and uncertain delivery never retry or refund request budgets", function()
	simulated(function(clock)
		local s = fixture() s.RemoteError = true assert(s:Dispatch()) assert(s.Manager.Fault and #s.Commands == 1)
		s.Manager:Halt() clock.Time = 20 s.Manager:Observe()
		assert(s.Manager.Hatch.Fault and s.Manager.Hatch.RequestCost == 20 and s.Manager.Hatch.RequestedHatches == 2)
		assert(not s:Dispatch() and #s.Commands == 1) s:Close()
	end)
end)

test("Hatch budgets cap batch by spendable reserves actual cost native capacity and remaining limits", function()
	simulated(function()
		local s = fixture() s.Profile.Coins = 169 assert(s:Decision().Count == 1)
		s.Profile.Coins = 159 assert(s:Decision().Kind == "WAIT") s.Profile.Coins = 10000
		s.Manager.Hatch.RequestCost = 25 assert(s:Decision().Kind == "WAIT") s.Manager.Hatch.RequestCost = 20
		s.Manager.Hatch.RequestedHatches = 2 assert(s:Decision().Count == 1)
		s.StorageCap = 3 assert(s:Decision().Kind == "WAIT") s:Close()
	end)
end)

test("Digital storage uses native bytes/fullness and caps to one egg without invented slot conversion", function()
	simulated(function()
		local s = fixture() s.Digital, s.Bytes, s.StorageCap = true, 999999, 1000000
		assert(s:Decision().Count == 1) local _, ctx = s.Manager:Fresh() assert(ctx.StorageUnit == "JSON_BYTES")
		s.Bytes = 1000000 assert(s:Decision().Kind == "WAIT") s:Close()
	end)
end)

test("Native auto deletion blocks hatching without mutating account settings", function()
	simulated(function()
		local s = fixture() s.Profile.AutoDelete.New = { Shiny = true }
		assert(s:Decision().Kind == "WAIT" and not s:Dispatch() and #s.Commands == 0 and s.Profile.AutoDelete.New.Shiny)
		s.Profile.AutoDelete = nil assert(s:Decision().Kind == "WAIT") s:Close()
	end)
end)

test("Native hatch cooldown presentation competing auto hatch and range all guard dispatch", function()
	simulated(function()
		local s = fixture() s.NativeActive = "Test Egg" assert(not s:Dispatch()) s.NativeActive = nil
		s.Hatching = true assert(not s:Dispatch()) s.Hatching = false
		s.NextAt = 10 assert(not s:Dispatch()) s.NextAt = nil
		s.EggPart.Position = s.Root.Position + Vector3.new(17, 0, 0) assert(not s:Dispatch())
		assert(#s.Commands == 0 and #s.Teleports == 0) s:Close()
	end)
end)

test("Account and cancellation changes during native guards cannot spend stale funds", function()
	simulated(function()
		local s = fixture() s.OnAutoGuard = function() s.Profile.Coins = 150 end
		assert(not s:Dispatch() and #s.Commands == 0 and s.Manager.Hatch.RequestCost == 0)
		s.Profile.Coins = 10000 s.OnAutoGuard = function() s.Controller.State = "PAUSED" end
		assert(not s:Dispatch() and #s.Commands == 0) s:Close()
	end)
end)

test("First hatch uses one egg and subsequent cooldown prevents immediate redispatch", function()
	simulated(function()
		local s = fixture() s.Unlocked = false assert(s:Dispatch() and s.Commands[1].Count == 1)
		s.Profile.Pets[1].Amount = 2 s.Profile.EggsOpened["Test Egg"] = 1 s.Manager:Observe()
		assert(not s.Manager.Hatch.Pending and not s:Dispatch() and #s.Commands == 1) s:Close()
	end)
end)

test("Owned equipment fills free capacity through one command and requires exact received multiplicity", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false, AUTO_EQUIP = true } }) local action = s:Decision()
		assert(action.Kind == "TEAM" and not action.RemoveId and s:Dispatch(action))
		assert(s.Commands[1].Command == "EquipPet" and s.Manager.PendingEquip and s.Manager.EquipCommands == 1)
		s.Manager:Observe() assert(s.Manager.PendingEquip)
		table.insert(s.Profile.Teams[1].Pets, "strong") s.Manager:Observe()
		assert(not s.Manager.PendingEquip and s.Manager.LastEquipment.Status == "EQUIPPED_IDS_OBSERVED") s:Close()
	end)
end)

test("Full team replacement verifies unequip before equip and preserves stack copies", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false, AUTO_EQUIP = true } }) s.MaxEquipped = 2 s.Profile.Teams[1].Pets = { "weak", "strong" }
		assert(s:Dispatch() and s.Commands[1].Command == "UnequipPet" and s.Manager.Transaction)
		assert(s:Decision().Kind == "OBSERVE" and not s:Dispatch() and #s.Commands == 1)
		s.Profile.Teams[1].Pets = { "strong" } s.Manager:Observe() assert(s:Decision().Kind == "TEAM_ADD")
		assert(s:Dispatch() and s.Commands[2].Command == "EquipPet") s.Profile.Teams[1].Pets = { "strong", "strong" } s.Manager:Observe()
		assert(not s.Manager.Transaction and not s.Manager.PendingEquip and s.Manager.EquipCommands == 2) s:Close()
	end)
end)

test("Replacement budgets require both commands before any unequip", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false, AUTO_EQUIP = true, MAXIMUM_SESSION_EQUIP_COMMANDS = 1 } }) s.MaxEquipped = 1
		assert(s:Decision().Kind == "WAIT" and not s:Dispatch() and #s.Commands == 0) s:Close()
	end)
end)

test("Manual equipment changes and team switches stop a pending replacement", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false, AUTO_EQUIP = true } }) s.MaxEquipped = 1
		assert(s:Dispatch()) s.Profile.Teams[1].Pets = {} s.Manager:Observe()
		s.Profile.Teams[1].Pets = { "strong" } assert(not s:Dispatch() and s.Manager.Fault and #s.Commands == 1) s:Close()
	end)
end)

test("Equipment timeout cannot imply success or reset command ledger on Halt", function()
	simulated(function(clock)
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false, AUTO_EQUIP = true } }) assert(s:Dispatch())
		s.Manager:Halt() clock.Time = 11 s.Manager:Observe()
		assert(s.Manager.Fault and s.Manager.LastEquipment.Status == "UNCONFIRMED" and s.Manager.EquipCommands == 1)
		assert(not s:Dispatch() and #s.Commands == 1) s:Close()
	end)
end)

test("Location ownership blocks stale farming and progression travel and permits manual movement", function()
	simulated(function(clock)
		local s = fixture() s.Manager:Select({}) local m = s.Coordinator.Mechanics local original = s.Root.Position
		assert(not m:Travel({}, "The Overworld", "Zen", token, true) and not m:TravelForProgression("Next", token))
		s.Root.Position = original + Vector3.new(100, 0, 0) assert(not s:Dispatch() and s.Root.Position ~= original and #s.Teleports == 0)
		s.Manager:Halt() assert(not s.Manager.Hatch.Location and s.Manager.Hatch.StartedAt == 0)
		clock.Time = 61 assert(s.Manager.Hatch:Ended()) s:Close()
	end)
end)

test("Hatch location reuses loaded ID cleanup at an otherwise excluded area without moving", function()
	simulated(function()
		local s = fixture() s.Area.Name, s.Area.Key = "The Overworld", "The Overworld/The Overworld"
		s.Dependencies.Eggs["Test Egg"].Island = nil s.Coordinator.Tracker.Areas[s.Area.Key] = s.Area
		s.Controller.Plan = { Objective = { Metadata = { Cost = { Type = "Currency", Currency = "Coins" } } } }
		s.Manager:Select({}) local record = s:Add("egg-location")
		s.OnDispatch = function() s.Profile.Coins += 10 end
		local original = s.Root.Position local result = s.Coordinator.Stationary:Collect({ Cluster = s.Coordinator.Tracker:Cluster("Coins"), Mode = "HATCH_PICKUPS", HatchSpending = false }, token,
			function() return s.Manager:AtOwnedLocation(s.Area) end)
		assert(result.Verified and #s.Calls == 1 and record.Model.Destroyed and not s.Coordinator.Stationary.LastResult.Contaminated)
		assert(#s.Teleports == 0 and s.Root.Position == original and #s.Commands == 0)
		local other = s:Add("lease-ended") s.Manager:Halt() assert(not s.Coordinator.Mechanics:CollectStationary(other, token)) s:Close()
	end)
end)

test("Bounded hatch completion waits for presentation before releasing location", function()
	simulated(function(clock)
		local s = fixture() s.Manager:Select({}) s.Manager.Hatch.RequestedHatches = 3 s.Hatching = true
		local owns, decision = s.Manager:Select({}) assert(owns and decision.Kind == "OBSERVE" and s.Manager.Hatch.Location)
		s.Hatching = false s.Manager:Select({}) assert(not s.Manager.Hatch.Location)
		clock.Time = 61 assert(s.Manager.Hatch:Ended()) s:Close()
	end)
end)

test("Pet task uses the same scheduler lease and cancellation prevents stale action dispatch", function()
	simulated(function()
		local s = fixture() local owns, decision = s.Manager:Select({}) assert(owns)
		local definition = s.Manager:Definition(decision, 1)
		assert(definition.Id == "OC_GAMEPLAY" and definition.Owner == "PETS" and definition.CanRun())
		s.Controller.Generation = 2 assert(not definition.CanRun()) s.Controller.Generation = 1
		assert(definition.Execute({ CheckCancelled = function() return true end }) == nil and #s.Commands == 0)
		local scheduler = Scheduler.new(s.Controller.Config.TASK_SETTINGS) scheduler:Resume()
		local completed = 0 scheduler.Completed.Event:Connect(function(id, status) assert(id == "OC_GAMEPLAY" and status == "COMPLETED") completed += 1 end)
		assert(scheduler:Submit(definition)) flush()
		assert(completed == 1 and #s.Commands == 1 and scheduler.Active == nil and s.Manager.Hatch.Pending)
		scheduler:Destroy() s:Close()
	end)
end)

test("Native egg observation retains diagnostics and excludes decorative clones from interaction", function()
	simulated(function()
		local s = fixture() local knowledge = s.Controller.Knowledge
		knowledge.EggModels = nil
		local savedDescendants = workspace.GetDescendants
		local clone = { Name = "Test Egg", Parent = knowledge.NativeEggFixtureFolder,
			IsA = function() return true end, IsDescendantOf = function() return true end,
			GetAttribute = function() return nil end, FindFirstChild = function() return nil end }
		workspace.GetDescendants = function() return { clone, s.Egg } end
		local models = knowledge:EggModels() assert(#models == 2)
		local interactive = knowledge:InteractiveEggModels() assert(#interactive == 1 and interactive[1] == s.Egg)
		assert(knowledge:ResolveEggInstance("Test Egg").Model == s.Egg)
		workspace.GetDescendants = savedDescendants s:Close()
	end)
end)

test("Target pet probability cannot masquerade as team gain or rarity/variant guarantee", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { SELECTED_PETS = { "Weak" } } }) local snap, ctx = s.Manager:Fresh()
		local report = s.Controller.Brain:AnalyzePets(snap, ctx)
		assert(report.Eggs[1].ClientTargetProbability == 0.25 and report.Eggs[1].VariantOdds == "UNKNOWN")
		assert(report.Team.ProposedIds[1] == "weak", "Existing target stays equipped") s:Close()
	end)
end)

test("Confirmed hatch session budgets survive controls and native presentation blocks later travel", function()
	simulated(function()
		local s = fixture() s.Manager:Select({}) assert(s:Dispatch())
		s.Profile.Pets[1].Amount = 3 s.Profile.EggsOpened["Test Egg"] = 2 s.Manager:Observe() s.Manager:Halt()
		assert(s.Manager.Hatch.RequestCost == 20 and s.Manager.Hatch.RequestedHatches == 2 and s.Manager.Hatch.VerifiedHatches == 2)
		s.Hatching = true assert(not s.Coordinator.Mechanics:Travel({}, "The Overworld", "Zen", token, true)) assert(#s.Teleports == 0) s:Close()
	end)
end)

test("Lost LocalData still expires an outstanding hatch acknowledgement", function()
	simulated(function(clock)
		local s = fixture() assert(s:Dispatch()) s.Controller.Reader.GetLiveProfile = function() return nil end
		clock.Time = 16 s.Manager:Observe()
		assert(s.Manager.Fault and not s.Manager.Hatch.Pending and s.Manager.Hatch.RequestCost == 20 and #s.Commands == 1) s:Close()
	end)
end)

test("Unavailable replacement benefit expires after confirmed removal without further commands", function()
	simulated(function(clock)
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false, AUTO_EQUIP = true } }) s.MaxEquipped = 1 assert(s:Dispatch())
		s.Profile.Teams[1].Pets = {} s.Manager:Observe() s.ScoreError = true assert(not s:Dispatch())
		clock.Time = 21 s.Manager:Observe()
		assert(s.Manager.Fault and not s.Manager.Transaction and #s.Commands == 1 and s.Manager.EquipCommands == 1)
		assert(#s.Profile.Teams[1].Pets == 0) s:Close()
	end)
end)

local function once(overrides)
	local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false, AUTO_EQUIP = true, EQUIP_OWNED_TEAM_ONCE = true, MAXIMUM_SESSION_EQUIP_COMMANDS = 16 } })
	for key, value in pairs(overrides or {}) do s.Controller.Config.PET_SETTINGS[key] = value end
	return s
end
local function applyReceived(s, command, id)
	local ids = s.Profile.Teams[s.Profile.TeamEquipped].Pets
	if command == "EquipPet" then table.insert(ids, id)
	elseif command == "UnequipPet" then table.remove(ids, table.find(ids, id))
	else error("Equip-only test attempted " .. command) end
end

test("Detailed team plan exposes identities variants native cap contributions and swap evidence", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false } }) s.Profile.Pets[2].Shiny = true
		local snap, ctx = s.Manager:Fresh() local team = Policy.Team(s.Controller.Config, ctx)
		assert(team.MaxEquipped == 2 and team.CurrentPets[1].Name == "Weak" and team.CurrentPets[1].NativeRoleStat == 2)
		assert(team.ProposedPets[1].Id == "strong" and team.ProposedPets[1].OwnedQuantity == 2 and team.ProposedPets[1].Variant == "Shiny")
		assert(team.ProposedPets[2].Id == "strong" and team.ProposedPets[1].EquippedCopies == 2)
		local text = Policy.TeamText(team, true) assert(text:find("FULL%-team") and text:find("UNCERTAINTY") and text:find("earnings rates"))
		assert(#s.Commands == 0 and #s.Teleports == 0 and s.Profile.Coins == 10000) s:Close()
	end)
end)

test("Team plan marks unresolved definitions and candidate stat failures without guessing", function()
	simulated(function()
		local s = fixture() s.Dependencies.Pets.Strong = nil
		local _, ctx = s.Manager:Fresh() local t = Policy.Team(s.Controller.Config, ctx)
		assert(Policy.SameTeam(t.ProposedIds, { "weak" }) and table.concat(t.Unknowns, " "):find("UNKNOWN"))
		s.ScoreError = true _, ctx = s.Manager:Fresh() t = Policy.Team(s.Controller.Config, ctx)
		assert(t.Status == "UNKNOWN" and Policy.TeamText(t, true):find("no guessed fallback")) s:Close()
	end)
end)

test("Protection preserves favorite valuable variant Secret locked and target equipped copies", function()
	simulated(function()
		for _, key in ipairs({ "Locked", "Favorite", "Favorited", "Shiny", "Mythic", "XL", "Super" }) do
			local s = once() s.MaxEquipped = 1 s.Profile.Pets[1][key] = true
			s.Manager:Select({}) assert(s.Manager.Attempt.Ended and #s.Commands == 0 and s.Profile.Teams[1].Pets[1] == "weak") s:Close()
		end
		for _, setting in ipairs({ "FAVORITE_PET_IDS", "VALUABLE_PET_IDS", "PROTECTED_PET_IDS" }) do
			local s = once({ [setting] = { "weak" } }) s.MaxEquipped = 1 s.Manager:Select({})
			assert(s.Manager.Attempt.Ended and #s.Commands == 0) s:Close()
		end
		local s = once() s.MaxEquipped = 1 s.Dependencies.Pets.Weak.Rarity = "Secret" s.Manager:Select({})
		assert(s.Manager.Attempt.Ended and #s.Commands == 0) s:Close()
	end)
end)

test("Explicitly protected unequipped candidate never enters a command plan", function()
	simulated(function()
		local s = once({ PROTECTED_PET_IDS = { "strong" } }) s.MaxEquipped = 1 s.Manager:Select({})
		assert(s.Manager.Attempt.Ended and s.Manager.Attempt.Status == "NO_ACTION" and #s.Commands == 0) s:Close()
	end)
end)

test("Analysis-only detailed logging stays opt-in and never dispatches equipment", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false, AUTO_EQUIP = false, LOG_TEAM_DETAILS = true } })
		local messages = {} s.Controller.Log = function(_, kind, text) table.insert(messages, kind .. text) end
		s.Manager:Select({}) local count = #messages s.Manager:Analyze(true)
		assert(count == #messages and table.concat(messages, " "):find("PET%]%[TEAM_PLAN") and table.concat(messages, " "):find("TEAM_DETAILS"))
		assert(s.Manager:PrintTeam() and #messages == count + 1 and #s.Commands == 0) s:Close()
	end)
end)

test("One frozen whole-team attempt verifies all stacked changes then permanently ends", function()
	simulated(function(clock)
		local s = once() s.OnCommand = function(command, id) applyReceived(s, command, id) end
		for _ = 1, 6 do local owns, decision = s.Manager:Select({}) if owns then s:Dispatch(decision) s.Manager:Observe() end clock.Time += 1 end
		assert(Policy.SameTeam(s.Profile.Teams[1].Pets, { "strong", "strong" }) and #s.Commands == 3)
		assert(s.Commands[1].Command == "EquipPet", "Fill native free capacity before any unequip")
		assert(s.Manager.Attempt.Ended and s.Manager.Attempt.Status == "TARGET_MEMBERSHIP_OBSERVED" and s.Manager.Attempt.ConfirmedTarget)
		assert(s.Manager.Attempt.BeforeScore == 2 and s.Manager.Attempt.AfterScore == 9 and s.Manager.Hatch.RequestCost == 0)
		s.Profile.Teams[1].Pets = { "weak" } s.Manager:Select({}) assert(not s:Dispatch() and #s.Commands == 3)
		assert(#s.Teleports == 0 and s.Profile.Coins == 10000) s:Close()
	end)
end)

test("Whole-team preflight sends nothing if total command budget cannot complete target", function()
	simulated(function()
		local s = once({ MAXIMUM_SESSION_EQUIP_COMMANDS = 2 }) local owns = s.Manager:Select({})
		assert(not owns and s.Manager.Attempt.Ended and s.Manager.Attempt.Status == "NO_ACTION" and #s.Commands == 0)
		assert(s.Profile.Teams[1].Pets[1] == "weak" and s.Manager.EquipCommands == 0) s:Close()
	end)
end)

test("One-time preflight handles seven-slot team and actual repeated stack IDs", function()
	simulated(function(clock)
		local s = once({ MAXIMUM_TEAM_EVALUATIONS = 1000 }) s.MaxEquipped = 7
		s.Profile.Pets[1].Amount, s.Profile.Pets[2].Amount = 7, 7
		s.Profile.Teams[1].Pets = { "weak", "weak", "weak", "weak", "weak", "weak", "weak" }
		s.OnCommand = function(command, id) applyReceived(s, command, id) end
		for _ = 1, 16 do local owns, d = s.Manager:Select({}) if owns then s:Dispatch(d) s.Manager:Observe() end clock.Time += 1 end
		assert(s.Manager.Attempt.ConfirmedTarget and #s.Commands == 14 and #s.Profile.Teams[1].Pets == 7)
		for _, command in ipairs(s.Commands) do assert(command.First == "strong" or command.First == "weak") end
		s:Close()
	end)
end)

test("One-time equipment awaits acknowledgement and respects OC pacing without retry spam", function()
	simulated(function(clock)
		local s = once() local _, d = s.Manager:Select({}) assert(s:Dispatch(d))
		for _ = 1, 4 do s.Manager:Select({}) assert(not s:Dispatch()) end assert(#s.Commands == 1)
		applyReceived(s, "EquipPet", "strong") s.Manager:Observe()
		assert(not s:Dispatch() and #s.Commands == 1) clock.Time = 1 assert(s:Dispatch() and #s.Commands == 2) s:Close()
	end)
end)

test("One-time timeout reports received partial membership and never starts another attempt", function()
	simulated(function(clock)
		local s = once() s.MaxEquipped = 1 local _, d = s.Manager:Select({}) assert(s:Dispatch(d))
		s.Profile.Teams[1].Pets = {} s.Manager:Observe() clock.Time = 1 assert(s:Dispatch())
		clock.Time = 12 s.Manager:Observe()
		assert(s.Manager.Attempt.Ended and not s.Manager.Attempt.ConfirmedTarget and #s.Manager.Attempt.AfterIds == 0)
		assert(s.Manager.Attempt.Status == "PARTIAL_OR_UNCONFIRMED" and not s:Dispatch() and #s.Commands == 2) s:Close()
	end)
end)

test("Unexpected unequip multiplicity ends frozen attempt instead of inventing stack success", function()
	simulated(function()
		local s = once() s.MaxEquipped = 2 s.Profile.Pets[1].Amount = 2 s.Profile.Teams[1].Pets = { "weak", "weak" }
		local _, d = s.Manager:Select({}) assert(s:Dispatch(d)) s.Profile.Teams[1].Pets = {} s.Manager:Observe()
		assert(s.Manager.Attempt.Ended and s.Manager.Fault and s.Manager.LastEquipment.Status == "MISMATCH" and #s.Commands == 1)
		assert(not s:Dispatch()) s:Close()
	end)
end)

test("Frozen attempt detects team switching and lost target ownership before next command", function()
	simulated(function(clock)
		local s = once() s.Manager:Select({}) s.Profile.Teams[2] = { Pets = { "weak" } } s.Profile.TeamEquipped = 2
		s.Manager:Select({}) assert(s.Manager.Fault and s.Manager.Attempt.Ended and #s.Commands == 0) s:Close()
		s = once() s.Manager:Select({}) s.Profile.Pets[2].Amount = 1
		assert(not s:Dispatch() and s.Manager.Fault and s.Manager.Attempt.Ended and #s.Commands == 0) s:Close()
	end)
end)

test("Frozen attempt rechecks newly protected IDs and native capacity before dispatch", function()
	simulated(function()
		local s = once() s.MaxEquipped = 1 s.Manager:Select({}) s.Profile.Pets[1].Locked = true
		assert(not s:Dispatch() and s.Manager.Fault and #s.Commands == 0) s:Close()
		s = once() s.Manager:Select({}) s.MaxEquipped = 3
		assert(not s:Dispatch() and s.Manager.Fault and #s.Commands == 0) s:Close()
	end)
end)

test("Final guard refresh prevents stale owned-team dispatch after yielding account change", function()
	simulated(function()
		local s = once() s.Manager:Select({}) local calls = 0
		s.Coordinator.Mechanics.Guard = function() calls += 1 if calls == 2 then s.Profile.Pets[2].Locked = true end return true end
		assert(not s:Dispatch() and s.Manager.Fault and s.Manager.EquipCommands == 0 and #s.Commands == 0) s:Close()
	end)
end)

test("Pause retains frozen continuation and ledger; Stop permanently ends it", function()
	simulated(function(clock)
		local s = once() s.MaxEquipped = 1 local _, d = s.Manager:Select({}) assert(s:Dispatch(d))
		s.Profile.Teams[1].Pets = {} s.Manager:Observe() s.Controller.State = "PAUSED" s.Manager:Halt()
		assert(not s:Dispatch() and s.Manager.Transaction and not s.Manager.Attempt.Ended)
		s.Controller.State = "RUNNING" clock.Time = 1 assert(s:Dispatch())
		s.Manager:Halt(true) s.Profile.Teams[1].Pets = { "strong" } s.Manager:Observe()
		assert(s.Manager.Attempt.Status == "STOPPED" and s.Manager.Attempt.Ended and not s:Dispatch() and #s.Commands == 2) s:Close()
	end)
end)

test("One-time wall-clock deadline and lost profile block further equipment", function()
	simulated(function(clock)
		local s = once({ MAXIMUM_EQUIP_ATTEMPT_SECONDS = 5 }) s.Manager:Select({}) s.Manager:Halt() clock.Time = 6
		s.Manager:Observe() assert(s.Manager.Attempt.Ended and s.Manager.Fault and #s.Commands == 0) s:Close()
		s = once() s.Manager:Select({}) assert(s:Dispatch()) s.Controller.Reader.GetLiveProfile = function() return nil end
		clock.Time += 11 s.Manager:Observe() assert(s.Manager.Attempt.Ended and s.Manager.Attempt.AfterIds == nil and not s:Dispatch()) s:Close()
	end)
end)

test("No owned improvement consumes zero commands and ends the one-time authorization", function()
	simulated(function()
		local s = once() s.Profile.Teams[1].Pets = { "strong", "strong" } s.Manager:Select({})
		assert(s.Manager.Attempt.Status == "NO_ACTION" and s.Manager.EquipCommands == 0 and #s.Commands == 0)
		s.Profile.Teams[1].Pets = { "weak" } s.Manager:Select({}) assert(not s:Dispatch() and #s.Commands == 0) s:Close()
	end)
end)

test("One-time mode rejects implicit equip authorization non-Coins roles and hatching", function()
	for _, settings in ipairs({ { ENABLE_PET_INTELLIGENCE = true, EQUIP_OWNED_TEAM_ONCE = true },
		{ ENABLE_PET_INTELLIGENCE = true, EQUIP_OWNED_TEAM_ONCE = true, AUTO_EQUIP = true, OBJECTIVE_CURRENCY = "Gems" },
		{ ENABLE_PET_INTELLIGENCE = true, EQUIP_OWNED_TEAM_ONCE = true, AUTO_EQUIP = true, OBJECTIVE_CURRENCY = "Coins", AUTO_HATCH = true },
		{ EQUIP_OWNED_TEAM_ONCE = "true" }, { LOG_TEAM_DETAILS = "true" } }) do
		assert(not pcall(function() local c = Controller.new(config({ PET_SETTINGS = settings })) c:Destroy() end))
	end
end)

test("Final equipment guard catches changed non-inventory account capacity facts", function()
	simulated(function()
		local s = once() s.Manager:Select({}) local calls = 0
		s.Coordinator.Mechanics.Guard = function() calls += 1 if calls == 2 then s.Profile.MasteryLevels = { Pets = 5 } end return true end
		assert(not s:Dispatch() and s.Manager.Fault and #s.Commands == 0) s:Close()
	end)
end)

test("Final yielding guard honors newly protected Config IDs and expired attempt deadlines", function()
	simulated(function(clock)
		local s = once() s.Manager:Select({}) local calls = 0
		s.Coordinator.Mechanics.Guard = function() calls += 1 if calls == 2 then s.Controller.Config.PET_SETTINGS.PROTECTED_PET_IDS = { "strong" } end return true end
		assert(not s:Dispatch() and s.Manager.Fault and #s.Commands == 0) s:Close()
		s = once({ MAXIMUM_EQUIP_ATTEMPT_SECONDS = 5 }) s.Manager:Select({}) calls = 0
		s.Coordinator.Mechanics.Guard = function() calls += 1 if calls == 2 then clock.Time += 6 end return true end
		assert(not s:Dispatch() and s.Manager.Attempt.Ended and #s.Commands == 0) s:Close()
	end)
end)

test("Consumed one-time equipment authorization cannot become an ongoing optimizer", function()
	simulated(function()
		local s = once() s.Profile.Teams[1].Pets = { "strong", "strong" } s.Manager:Select({})
		s.Controller.Config.PET_SETTINGS.EQUIP_OWNED_TEAM_ONCE = false s.Profile.Teams[1].Pets = { "weak" }
		s.Manager:Select({}) assert(not s:Dispatch() and #s.Commands == 0 and s.Manager.Attempt.Ended) s:Close()
	end)
end)

test("Equip-only Config rejects enabled competing farming and nonzero hatch budgets", function()
	local isolated = {
		PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_EQUIP = true, EQUIP_OWNED_TEAM_ONCE = true, OBJECTIVE_CURRENCY = "Coins" },
		HATCH_SETTINGS = { ENABLE_BACKGROUND_PICKUPS = false },
		WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false, AUTO_UNLOCK_WORLDS = false, AUTO_TRAVEL_FOR_PROGRESSION = false, AUTO_FARM_UNLOCK_REQUIREMENTS = false },
		FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false },
		ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
		UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false, ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false },
	}
	local c = Controller.new(config(isolated)) c:Destroy()
	for _, entry in ipairs({ { "FARMING_SETTINGS", "AUTO_RESOURCE_FARM", true }, { "BUBBLE_SETTINGS", "AUTO_BUY_GUM", true },
		{ "WORLD_SETTINGS", "AUTO_UNLOCK_WORLDS", true }, { "HATCH_SETTINGS", "MAXIMUM_SESSION_COST", 1 } }) do
		local bad = table.clone(isolated) bad[entry[1]] = table.clone(bad[entry[1]]) bad[entry[1]][entry[2]] = entry[3]
		assert(not pcall(function() local instance = Controller.new(config(bad)) instance:Destroy() end))
	end
end)

local function hatchOnce()
	return fixture({
		PET_SETTINGS = { AUTO_HATCH = true, AUTO_EQUIP = false },
		HATCH_SETTINGS = { HATCH_ONE_EGG_ONCE = true, ENABLE_BACKGROUND_PICKUPS = false, MAXIMUM_EGG_COST = 10,
			MAXIMUM_SESSION_COST = 10, MAXIMUM_BATCH_HATCHES = 1, MAXIMUM_SESSION_HATCHES = 1 },
		WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false, AUTO_UNLOCK_WORLDS = false, AUTO_TRAVEL_FOR_PROGRESSION = false, AUTO_FARM_UNLOCK_REQUIREMENTS = false },
		ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
		PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false },
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
		UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false, ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false },
	})
end
local function eggReport(s)
	local snap, ctx = s.Manager:Fresh()
	return s.Controller.Brain:AnalyzePets(snap, ctx), ctx
end

test("Egg analysis distinguishes disabled spending and genuinely unhelpful pool", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false }, HATCH_SETTINGS = { MAXIMUM_EGG_COST = 0, MAXIMUM_SESSION_COST = 0 } })
		s.Profile.Teams[1].Pets = { "strong", "strong" }
		local r = eggReport(s) assert(r.RecommendedEgg and r.Eggs[1].ExpectedIncrement == 3 and r.Eggs[1].SpendingStatus == "DISABLED_AUTO_HATCH")
		local text = Policy.EggPlanText(s.Controller.Config, r, false) assert(text:find("budgets=0/0") and text:find("DISABLED_AUTO_HATCH") and not text:find("No useful affordable egg"))
		s.Pool = { { Chance = 1, Item = { Type = "Pet", Name = "Weak" } } }
		r = eggReport(s) assert(not r.RecommendedEgg and r.Eggs[1].ExpectedIncrement == 0 and Policy.EggBlocker(r.Eggs[1]):find("NO_USEFUL_IMPROVEMENT"))
		assert(not s:Dispatch() and #s.Commands == 0) s:Close()
	end)
end)

test("Egg analysis keeps owned baseline when manually changing equipped team", function()
	simulated(function()
		local s = fixture() local a = eggReport(s) assert(a.Team.CurrentScore == 2 and a.Eggs[1].ExpectedIncrement == 3)
		s.Profile.Teams[1].Pets = { "strong", "strong" }
		local b = eggReport(s) assert(b.Team.CurrentScore == 9 and b.Eggs[1].ExpectedIncrement == 3 and b.Eggs[1].ClientImprovementProbability == 0.75)
		s.Ranks.Strong = 10 b = eggReport(s) assert(b.Team.CurrentScore == 19 and b.Eggs[1].ExpectedIncrement == 0) s:Close()
	end)
end)

test("Egg funding reports actual funds reserve and unknown evidence independently", function()
	simulated(function()
		local s = hatchOnce()
		for _, pair in ipairs({ { 9, "INSUFFICIENT_FUNDS" }, { 159, "PROTECTED_RESERVE" }, { 160, "AFFORDABLE" } }) do
			s.Profile.Coins = pair[1] local r = eggReport(s).Eggs[1]
			assert(r.Status == "ESTIMATE" and r.FundingStatus == pair[2] and r.Reserve == 150)
			assert(r.Affordable == (pair[2] == "AFFORDABLE"))
		end
		s.Dependencies.Worlds.Next.UnlockCost = nil local r = eggReport(s).Eggs[1]
		assert(r.FundingStatus == "UNKNOWN_RESERVE" and r.Status == "ESTIMATE" and not s:Dispatch())
		s.Profile.Coins = nil r = eggReport(s).Eggs[1] assert(r.FundingStatus == "UNKNOWN_BALANCE") s:Close()
	end)
end)

test("Egg coverage reports loaded scope cap and prioritized selected candidate", function()
	simulated(function()
		local s = fixture({ HATCH_SETTINGS = { MAXIMUM_EGGS_ANALYZED = 1 } })
		s.Dependencies.Eggs["A Egg"] = table.clone(s.Dependencies.Eggs["Test Egg"])
		local a = table.clone(s.Egg) a.Name = "A Egg"
		registerNativeEggFixture(s.Controller.Knowledge, a)
		s.Controller.Knowledge.EggModels = function() return { a, s.Egg } end
		local r = eggReport(s) assert(r.Coverage.LoadedModels == 2 and r.Coverage.Evaluated == 1 and r.Coverage.LimitReached)
		assert(r.Eggs[1].Name == "Test Egg" and Policy.EggPlanText(s.Controller.Config, r, false):find("limited loaded%-model coverage")) s:Close()
	end)
end)

test("Missing selected egg is distinct from a locked egg or unknown definition", function()
	simulated(function()
		local s = hatchOnce() s.Egg.Parent = nil local r = eggReport(s)
		assert(r.Eggs[1].AccessStatus == "NOT_LOADED" and r.Coverage.Evaluated == 0 and not s:Dispatch())
		s.Dependencies.Eggs["Test Egg"] = nil r = eggReport(s) assert(r.Eggs[1].AccessStatus == "UNKNOWN_DEFINITION")
		s.Dependencies.Eggs["Test Egg"] = { World = "The Overworld", Island = "The Void" } s.Egg.Parent = s.Controller.Knowledge.NativeEggFixtureFolder s.Profile.AreasUnlocked["The Void"] = nil
		r = eggReport(s) assert(r.Eggs[1].AccessStatus == "LOCKED_OR_UNKNOWN_UNLOCK" and not s:Dispatch() and #s.Commands == 0) s:Close()
	end)
end)

test("Unknown native pool statistics stay separate from budget availability", function()
	simulated(function()
		local s = fixture({ PET_SETTINGS = { AUTO_HATCH = false }, HATCH_SETTINGS = { MAXIMUM_EGG_COST = 0, MAXIMUM_SESSION_COST = 0 } })
		s.Pool[2].Chance = nil local r = eggReport(s).Eggs[1]
		assert(r.FundingStatus == "AFFORDABLE" and r.Status == "UNKNOWN" and Policy.EggBlocker(r):find("INSUFFICIENT_EVIDENCE"))
		s.ScoreError = true r = eggReport(s).Eggs[1] assert(r.Status == "UNKNOWN" and not s:Dispatch() and #s.Commands == 0) s:Close()
	end)
end)

test("Single hatch uses one explicit request and cannot enlarge its consumed ledger", function()
	simulated(function()
		local s = hatchOnce() s.Profile.Teams[1].Pets = { "strong", "strong" }
		local owns, d = s.Manager:Select({}) assert(owns and d.Count == 1 and s:Dispatch(d))
		assert(#s.Commands == 1 and s.Commands[1].Count == 1 and s.Manager.Hatch.RequestCost == 10)
		s.Profile.Pets[3] = { Id = "new", Name = "New" } s.Profile.EggsOpened["Test Egg"] = 1 s.Manager:Observe()
		assert(s.Manager.Hatch.VerifiedHatches == 1 and s.Manager.Hatch:Ended())
		s.Controller.Config.HATCH_SETTINGS.MAXIMUM_SESSION_HATCHES = 20 s.Controller.Config.HATCH_SETTINGS.MAXIMUM_SESSION_COST = 1000
		s.Controller.Config.HATCH_SETTINGS.HATCH_ONE_EGG_ONCE = false
		assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.Hatch.RequestCost == 10) s:Close()
	end)
end)

test("Single hatch confirms actual existing-stack amount counter variant and team benefit", function()
	simulated(function()
		local s = hatchOnce() s.Profile.Pets[3] = { Id = "new", Name = "New", Amount = 1, Shiny = true }
		s.Profile.Teams[1].Pets = { "strong", "strong" } assert(s:Dispatch())
		s.Profile.Pets[3].Amount = 2 s.Profile.EggsOpened["Test Egg"] = 1 s.Profile.Coins -= 10 s.Manager:Observe()
		local r = s.Manager.Hatch.LastResult local c = r.Changes[1]
		assert(r.Status == "INVENTORY_GAIN_OBSERVED" and r.CounterDelta == 1 and c.Id == "new" and c.ExistingStack and c.Variant == "Shiny" and c.Quantity == 1)
		assert(c.Usefulness == "USEFUL_NATIVE_TEAM_ESTIMATE" and c.ActualIncrement == 4 and r.Balances.Coins.Delta == -10)
		assert(Policy.SameTeam(r.TeamBefore, r.TeamAfter) and r.OCEquipmentCommands == 0 and s.Manager.EquipCommands == 0 and #s.Commands == 1) s:Close()
	end)
end)

test("Received non-improving pet verifies hatch but is not reported as useful investment", function()
	simulated(function()
		local s = hatchOnce() s.Profile.Teams[1].Pets = { "strong", "strong" } assert(s:Dispatch())
		s.Profile.Pets[1].Amount = 2 s.Profile.EggsOpened["Test Egg"] = 1 s.Manager:Observe()
		local r = s.Manager.Hatch.LastResult assert(r.Status == "INVENTORY_GAIN_OBSERVED" and r.Changes[1].Usefulness == "NO_CURRENT_TEAM_IMPROVEMENT" and r.Changes[1].ActualIncrement == 0)
		assert(s.Manager.Hatch:ResultText():find("NO_CURRENT_TEAM_IMPROVEMENT") and not s:Dispatch() and #s.Commands == 1) s:Close()
	end)
end)

test("Received variant uses real native pet fields rather than base pet estimate", function()
	simulated(function()
		local s = hatchOnce() s.Profile.Teams[1].Pets = { "strong", "strong" } assert(s:Dispatch())
		s.Profile.Pets[3] = { Id = "variant", Name = "Weak", Shiny = true, Mythic = true, XP = 75 } s.Profile.EggsOpened["Test Egg"] = 1
		local nativeScore = s.Dependencies.StatsUtil.GetCurrencyMultiplier
		s.Dependencies.StatsUtil.GetCurrencyMultiplier = function(self, raw, currency)
			local n = nativeScore(self, raw, currency)
			for _, id in ipairs(raw.Teams[raw.TeamEquipped].Pets) do for _, pet in ipairs(raw.Pets) do if pet.Id == id and pet.Shiny and pet.Mythic and pet.XP == 75 then n += 20 end end end
			return n
		end
		s.Manager:Observe() local c = s.Manager.Hatch.LastResult.Changes[1]
		assert(c.Variant == "Shiny Mythic" and c.ActualIncrement == 17 and c.Usefulness == "USEFUL_NATIVE_TEAM_ESTIMATE" and #s.Commands == 1) s:Close()
	end)
end)

test("Single hatch rejects genuinely unhelpful pool despite selected target names", function()
	simulated(function()
		local s = hatchOnce() s.Profile.Teams[1].Pets = { "strong", "strong" }
		s.Controller.Config.PET_SETTINGS.SELECTED_PETS = { "Weak" } s.Pool = { { Chance = 1, Item = { Type = "Pet", Name = "Weak" } } }
		assert(s:Decision().Kind == "WAIT" and s:Decision().Reason:find("NO_USEFUL_IMPROVEMENT") and not s:Dispatch())
		assert(#s.Commands == 0 and s.Manager.Hatch.RequestCost == 0) s:Close()
	end)
end)

test("Single hatch respects native full capacity and auto-delete without changing settings", function()
	simulated(function()
		local s = hatchOnce() s.StorageCap = 3 assert(s:Decision().Reason:find("CAPACITY") and not s:Dispatch())
		s.StorageCap = 100 s.Profile.AutoDelete.Weak = { Shiny = false }
		assert(s:Decision().Reason:find("NATIVE_AUTO_DELETE_ACTIVE") and not s:Dispatch() and s.Profile.AutoDelete.Weak.Shiny == false)
		assert(#s.Commands == 0 and s.Manager.Hatch.RequestCost == 0) s:Close()
	end)
end)

test("Unopened egg enforces native 6.5-stud prompt while opened egg permits 16", function()
	simulated(function()
		local s = hatchOnce() s.Unlocked = false s.Profile.EggsOpened["Test Egg"] = nil s.EggPart.Position = s.Root.Position + Vector3.new(7,0,0)
		assert(not s:Dispatch() and s:Decision().Kind == "HATCH" and #s.Teleports == 0)
		s.EggPart.Position = s.Root.Position + Vector3.new(6.5,0,0) assert(s:Dispatch() and s.Commands[1].Count == 1) s:Close()
		s = hatchOnce() s.EggPart.Position = s.Root.Position + Vector3.new(16,0,0) assert(s:Dispatch()) s:Close()
	end)
end)

test("Leaving native range during a yielding guard never dispatches or teleports", function()
	simulated(function()
		local s = hatchOnce() local calls = 0
		s.Coordinator.Mechanics.Guard = function() calls += 1 if calls == 2 then s.Root.Position += Vector3.new(100,0,0) end return true end
		assert(not s:Dispatch() and #s.Commands == 0 and #s.Teleports == 0 and s.Manager.Hatch.RequestCost == 0) s:Close()
	end)
end)

test("Final hatch guard rechecks account funds auto-delete identity and authorization", function()
	simulated(function()
		for _, change in ipairs({ function(s) s.Profile.Coins = 0 end, function(s) s.Profile.AutoDelete.New = {} end,
			function(s) s.Controller.Reader.Player.UserId = 456 end, function(s) s.Controller.Config.PET_SETTINGS.AUTO_HATCH = false end,
			function(s) s.Controller.Config.HATCH_SETTINGS.SELECTED_EGGS = { "Other Egg" } end,
			function(s) s.Controller.Config.FARMING_SETTINGS.AUTO_RESOURCE_FARM = true end }) do
			local s = hatchOnce() local calls = 0 s.Coordinator.Mechanics.Guard = function() calls += 1 if calls == 2 then change(s) end return true end
			assert(not s:Dispatch() and #s.Commands == 0 and s.Manager.Hatch.RequestCost == 0) s:Close()
		end
	end)
end)

test("Final native guard catches cost capacity presentation cooldown and missing egg changes", function()
	simulated(function()
		for _, change in ipairs({ function(s) s.Cost = 11 end, function(s) s.StorageCap = 3 end,
			function(s) s.NativeActive = "Test Egg" end, function(s) s.Hatching = true end,
			function(s) s.NextAt = 50 end, function(s) s.Egg.Parent = nil end }) do
			local s = hatchOnce() local calls = 0 s.Coordinator.Mechanics.Guard = function() calls += 1 if calls == 2 then change(s) end return true end
			assert(not s:Dispatch() and #s.Commands == 0 and s.Manager.Hatch.RequestCost == 0) s:Close()
		end
	end)
end)

test("Rejected or counter-only hatch times out as uncertain without blind retry", function()
	simulated(function(clock)
		for _, counter in ipairs({ 0, 1 }) do
			local s = hatchOnce() assert(s:Dispatch()) s.Profile.EggsOpened["Test Egg"] = counter s.Profile.Coins -= 10
			clock.Time += 16 s.Manager:Observe() local r = s.Manager.Hatch.LastResult
			assert(r.Status == "UNCONFIRMED" and r.Quantity == 0 and r.CounterDelta == counter and r.Balances.Coins.Delta == -10)
			assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.Hatch.RequestCost == 10) s:Close()
		end
	end)
end)

test("Delayed stack counter acknowledgement stays pending and sends no duplicate", function()
	simulated(function(clock)
		local s = hatchOnce() assert(s:Dispatch()) s.Profile.Pets[1].Amount = 2
		clock.Time = 10 s.Manager:Observe() assert(s.Manager.Hatch.Pending.Observed.MatchedQuantity == 1 and not s:Dispatch())
		s.Profile.EggsOpened["Test Egg"] = 1 clock.Time = 14 s.Manager:Observe()
		assert(s.Manager.Hatch.VerifiedHatches == 1 and not s:Dispatch() and #s.Commands == 1) s:Close()
	end)
end)

test("Late hatch after timeout cannot reset consumed budget or enable equipment", function()
	simulated(function(clock)
		local s = hatchOnce() assert(s:Dispatch()) clock.Time = 16 s.Manager:Observe()
		s.Profile.Pets[3] = { Id = "late", Name = "New" } s.Profile.EggsOpened["Test Egg"] = 1 s.Manager:Observe()
		assert(s.Manager.Hatch.LastResult.Status == "UNCONFIRMED" and s.Manager.Hatch.RequestedHatches == 1 and s.Manager.Hatch.RequestCost == 10)
		assert(not s:Dispatch() and not s:Dispatch({ Kind = "TEAM", AddId = "late" }) and #s.Commands == 1) s:Close()
	end)
end)

test("Pause Resume Stop preserve pending single request and prevent duplicate spending", function()
	simulated(function()
		local s = hatchOnce() s.Manager:Select({}) assert(s:Dispatch())
		s.Controller.State = "PAUSED" s.Manager:Halt() assert(not s:Dispatch()) s.Controller.State = "RUNNING" s.Manager:Select({})
		assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.Hatch.Pending)
		s.Manager:Halt(true) s.Profile.Pets[1].Amount = 2 s.Profile.EggsOpened["Test Egg"] = 1 s.Manager:Observe()
		assert(s.Manager.Hatch.VerifiedHatches == 1 and s.Manager.Hatch:Ended() and not s:Dispatch() and #s.Commands == 1) s:Close()
	end)
end)

test("Stop before first dispatch permanently ends single hatch authorization", function()
	simulated(function()
		local s = hatchOnce() s.Manager:Halt(true) s.Controller.State = "RUNNING"
		s.Manager:Select({}) assert(not s:Dispatch() and #s.Commands == 0 and s.Manager.Hatch:Ended() and s.Manager.Hatch.RequestCost == 0) s:Close()
	end)
end)

test("Cancellation after native guard consumes no hatch budget or equipment command", function()
	simulated(function()
		local s = hatchOnce() local cancelled = false local calls = 0
		s.Coordinator.Mechanics.Guard = function() calls += 1 if calls == 2 then cancelled = true end return true end
		assert(not s.Coordinator.Mechanics:PetAction(s.Manager, s:Decision(), { CheckCancelled = function() return cancelled end }))
		assert(#s.Commands == 0 and s.Manager.EquipCommands == 0 and s.Manager.Hatch.RequestCost == 0) s:Close()
	end)
end)

test("Single hatch uncertain remote delivery retains ledger and never retries", function()
	simulated(function(clock)
		local s = hatchOnce() s.RemoteError = true assert(s:Dispatch()) assert(s.Manager.Fault)
		clock.Time = 16 s.Manager:Observe() s.Manager:Halt() s.Manager:Select({})
		assert(not s:Dispatch() and #s.Commands == 1 and s.Manager.Hatch.RequestedHatches == 1 and s.Manager.Hatch.RequestCost == 10) s:Close()
	end)
end)

test("Single-hatch location prevents farming travel while manual movement never snaps back", function()
	simulated(function()
		local s = hatchOnce() s.EggPart.Position += Vector3.new(100,0,0) local owns, d = s.Manager:Select({})
		assert(owns and d.Kind == "HATCH" and s.Manager.Hatch.Location and not s:Dispatch(d))
		assert(not s.Coordinator.Mechanics:Travel({}, "The Overworld", "Zen", token, true) and #s.Teleports == 0)
		s.Root.Position += Vector3.new(100,0,0) assert(s:Dispatch(d) and #s.Teleports == 0) s:Close()
	end)
end)

test("Single-hatch controller refuses equipment even after runtime Config modification", function()
	simulated(function()
		local s = hatchOnce() s.Controller.Config.PET_SETTINGS.AUTO_EQUIP = true
		assert(s:Decision().Kind == "WAIT" and not s:Dispatch({ Kind = "TEAM", AddId = "strong" }))
		assert(#s.Commands == 0 and s.Manager.EquipCommands == 0) s:Close()
	end)
end)

test("Compact egg plan and hatch result log only meaningful changes with optional detail", function()
	simulated(function()
		local s = hatchOnce() local logs = {} s.Controller.Log = function(_, kind, text) table.insert(logs, kind .. text) end
		s.Manager:Analyze(true) local count = #logs s.Manager:Analyze(true) assert(#logs == count)
		assert(table.concat(logs, " "):find("EGG_PLAN") and not table.concat(logs, " "):find("EGG_DETAILS"))
		assert(s:Dispatch()) s.Profile.Pets[1].Amount = 2 s.Profile.EggsOpened["Test Egg"] = 1 s.Manager:Observe()
		assert(table.concat(logs, " "):find("HATCH_RESULT")) count = #logs s.Manager:Observe() assert(#logs == count) s:Close()
	end)
end)

test("Single hatch Config rejects competing actions multiple requests and unprotected reserves", function()
	local safe = config({
		PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = true, AUTO_EQUIP = false, OBJECTIVE_CURRENCY = "Coins" },
		HATCH_SETTINGS = { HATCH_ONE_EGG_ONCE = true, SELECTED_EGGS = { "Test Egg" }, MAXIMUM_EGG_COST = 10, MAXIMUM_SESSION_COST = 10, ENABLE_BACKGROUND_PICKUPS = false },
		WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false, AUTO_UNLOCK_WORLDS = false, AUTO_TRAVEL_FOR_PROGRESSION = false, AUTO_FARM_UNLOCK_REQUIREMENTS = false },
		FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false },
		ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
		PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false },
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
		UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false, ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false },
	})
	local instance = Controller.new(safe) instance:Destroy()
	for _, entry in ipairs({ { "HATCH_SETTINGS", "MAXIMUM_SESSION_HATCHES", 2 }, { "HATCH_SETTINGS", "MAXIMUM_BATCH_HATCHES", 2 },
		{ "HATCH_SETTINGS", "PRESERVE_PROGRESSION_RESERVE", false }, { "HATCH_SETTINGS", "HATCH_ONE_EGG_ONCE", "true" },
		{ "HATCH_SETTINGS", "SELECTED_EGGS", { "Test Egg", "Other Egg" } }, { "HATCH_SETTINGS", "MAXIMUM_EGG_COST", 0 },
		{ "HATCH_SETTINGS", "ENABLE_BACKGROUND_PICKUPS", true }, { "PET_SETTINGS", "AUTO_EQUIP", true },
		{ "PICKUP_SETTINGS", "BULK_COLLECT_PICKUPS", true }, { "ISLAND_SETTINGS", "AUTO_TRAVEL_BEST_ISLAND", true },
		{ "WORLD_SETTINGS", "AUTO_UNLOCK_WORLDS", true }, { "BUBBLE_SETTINGS", "AUTO_SELL_BUBBLES", true },
		{ "PET_SETTINGS", "AUTO_DELETE_PETS", true }, { "PET_SETTINGS", "AUTO_CRAFT_SHINY", true } }) do
		local c = table.clone(safe) c[entry[1]] = table.clone(safe[entry[1]]) c[entry[1]][entry[2]] = entry[3]
		assert(not pcall(function() local object = Controller.new(c) object:Destroy() end))
	end
end)

test("Egg plan does not rank unlike currencies by a fabricated conversion", function()
	simulated(function()
		local s = fixture() local snap, ctx = s.Manager:Fresh()
		local coin = ctx.Eggs[1] local ticket = table.clone(coin)
		ticket.Name, ticket.Cost = "Ticket Egg", { Type = "Currency", Currency = "Tickets", Amount = 0.01 }
		snap.Balances.Tickets = 1000 ctx.Eggs = { ticket, coin }
		local r = Policy.Analyze(s.Controller.Config, snap, ctx)
		assert(r.Eggs[1].Name == "Test Egg" and r.RecommendedEgg.Name == "Test Egg") s:Close()
	end)
end)

test("Summary-mode console shows egg plan and hatch result without enabling detail", function()
	local original, output = print, {}
	print = function(value) table.insert(output, tostring(value)) end
	local ok, reason = xpcall(function()
		local c = setmetatable({ Config = config({ DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = true, ENABLE_DEBUG_LOGGING = false } }) }, Controller)
		c:Log("EGG_PLAN", "Native candidate") c:Log("HATCH_RESULT", "Received stack result") c:Log("EGG_DETAILS", "hidden routine")
		assert(#output == 2 and output[1]:find("EGG_PLAN") and output[2]:find("HATCH_RESULT"))
	end, debug.traceback)
	print = original assert(ok, reason)
end)

test("Partial matching inventory without hatch counter cannot become a best verified hatch", function()
	simulated(function(clock)
		local s = hatchOnce() assert(s:Dispatch()) s.Profile.Pets[3] = { Id = "partial", Name = "New" }
		clock.Time = 16 s.Manager:Observe() local r = s.Manager.Hatch.LastResult
		assert(r.Status == "UNCONFIRMED" and r.Quantity == 1 and r.Changes[1].Usefulness == "UNKNOWN" and not s.Manager.Hatch.BestHatch)
		assert(not s:Dispatch() and #s.Commands == 1) s:Close()
	end)
end)

local function eggAnalysisFixture()
	return fixture({ PET_SETTINGS = { AUTO_HATCH = false, AUTO_EQUIP = false },
		HATCH_SETTINGS = { SELECTED_EGGS = {}, MAXIMUM_EGG_COST = 0, MAXIMUM_SESSION_COST = 0 } })
end

test("Dynamic analysis recommends a received native egg without selecting or enabling actions", function()
	simulated(function()
		local s = eggAnalysisFixture()
		s.Egg.Name = "Account Scene Egg"
		s.Dependencies.Eggs[s.Egg.Name], s.Dependencies.Eggs["Test Egg"] = s.Dependencies.Eggs["Test Egg"], nil
		s.Egg.GetFullName = function() return "Workspace.Rendered.Chunker.Account Scene Egg" end
		local snap, ctx = s.Manager:Fresh() local r = Policy.Analyze(s.Controller.Config, snap, ctx)
		assert(r.RecommendedEgg.Name == s.Egg.Name and r.HatchTestPlan.EggName == s.Egg.Name)
		assert(r.HatchTestPlan.ModelPath == s.Egg:GetFullName() and r.HatchTestPlan.Position == s.EggPart.Position)
		assert(r.HatchTestPlan.NativePrice == 10 and r.HatchTestPlan.RequiredEggBudget == 10 and r.HatchTestPlan.RequiredSessionBudget == 10)
		assert(r.HatchTestPlan.RequiredBalance == 160 and r.HatchTestPlan.SpendingPermission:find("OFF"))
		assert(#s.Controller.Config.HATCH_SETTINGS.SELECTED_EGGS == 0 and not s:Dispatch() and #s.Commands == 0)
		assert(Policy.EggPlanText(s.Controller.Config, r, false):find("stand beside Account Scene Egg")) s:Close()
	end)
end)

test("Minigame Paradise status distinguishes received unlocked locked and missing map", function()
	simulated(function()
		local s = eggAnalysisFixture()
		local function report() local a, b = s.Manager:Fresh() return Policy.Analyze(s.Controller.Config, a, b) end
		assert(report().MinigameParadise.Status == "LOCKED" and not report().MinigameParadise.EntryPresent)
		s.Profile.WorldsUnlocked["Minigame Paradise"] = true
		assert(report().MinigameParadise.Status == "UNLOCKED" and report().MinigameParadise.RawValue == true)
		s.Profile.WorldsUnlocked = nil assert(report().MinigameParadise.Status == "UNKNOWN" and not report().RecommendedEgg) s:Close()
	end)
end)

test("Native presence-based world access preserves false and nonboolean received evidence", function()
	for _, entry in ipairs({ false, 0, "received" }) do
		local r = Policy.WorldAccess({ WorldsUnlocked = { ["Minigame Paradise"] = entry } }, "Minigame Paradise")
		assert(r.Status == "UNLOCKED" and r.EntryPresent and r.RawValue == entry)
	end
	assert(Policy.WorldAccess(nil, "Minigame Paradise").Status == "UNKNOWN")
end)

test("One-hatch proposal follows native account price changes rather than catalog base cost", function()
	simulated(function()
		local s = eggAnalysisFixture()
		local function report() local a, b = s.Manager:Fresh() return Policy.Analyze(s.Controller.Config, a, b) end
		assert(report().HatchTestPlan.NativePrice == 10)
		s.Cost = 7 local r = report()
		assert(r.HatchTestPlan.NativePrice == 7 and r.HatchTestPlan.RequiredSessionBudget == 7 and r.HatchTestPlan.RequiredBalance == 157)
		s.Cost = 9900 r = report() assert(not r.RecommendedEgg and not r.HatchTestPlan and r.CoinsAvailability[1].FundingStatus == "PROTECTED_RESERVE")
		assert(s.Controller.Config.HATCH_SETTINGS.MAXIMUM_SESSION_COST == 0 and #s.Commands == 0) s:Close()
	end)
end)

test("Dynamic egg ranking follows native efficiency and current received team", function()
	simulated(function()
		local s = eggAnalysisFixture() local other = table.clone(s.Egg) other.Name = "Better Scene Egg"
		s.Dependencies.Eggs[other.Name] = table.clone(s.Dependencies.Eggs["Test Egg"])
		registerNativeEggFixture(s.Controller.Knowledge, other)
		s.Controller.Knowledge.EggModels = function() return { s.Egg, other } end
		s.Dependencies.StatsUtil.GetEggCost = function(_, _, _, name) return { Type = "Currency", Currency = "Coins", Amount = name == other.Name and 5 or s.Cost } end
		local a, b = s.Manager:Fresh() local r = Policy.Analyze(s.Controller.Config, a, b)
		assert(r.RecommendedEgg.Name == other.Name and #r.CoinsAvailability == 2)
		s.Profile.Teams[1].Pets = { "strong", "strong" } s.Ranks.Strong = 20
		a, b = s.Manager:Fresh() r = Policy.Analyze(s.Controller.Config, a, b)
		assert(not r.RecommendedEgg and not r.HatchTestPlan and #r.CoinsAvailability == 2 and r.CoinsAvailability[1].Affordable)
		s:Close()
	end)
end)

test("Loaded availability remains complete when expensive pool projections reach cap", function()
	simulated(function()
		local s = eggAnalysisFixture() s.Controller.Config.HATCH_SETTINGS.MAXIMUM_EGGS_ANALYZED = 1
		local other = table.clone(s.Egg) other.Name = "Other Scene Egg"
		s.Dependencies.Eggs[other.Name] = table.clone(s.Dependencies.Eggs["Test Egg"])
		registerNativeEggFixture(s.Controller.Knowledge, other)
		s.Controller.Knowledge.EggModels = function() return { s.Egg, other } end
		local a, b = s.Manager:Fresh() local r = Policy.Analyze(s.Controller.Config, a, b)
		assert(#r.Eggs == 1 and #r.CoinsAvailability == 2 and r.Coverage.LimitReached and r.Coverage.LoadedModels == 2)
		assert(Policy.EggPlanText(s.Controller.Config, r, false):find("Test Egg %(10 Coins")) s:Close()
	end)
end)

test("Unknown native Coins price is reported without substituted definition price or budget", function()
	simulated(function()
		local s = eggAnalysisFixture() s.Dependencies.StatsUtil.GetEggCost = function() return nil end
		local a, b = s.Manager:Fresh() local r = Policy.Analyze(s.Controller.Config, a, b)
		assert(#r.CoinsAvailability == 1 and r.CoinsAvailability[1].FundingStatus == "UNKNOWN_NATIVE_COST")
		assert(not r.HatchTestPlan and not r.RecommendedEgg and Policy.EggPlanText(s.Controller.Config, r, false):find("Test Egg %(UNKNOWN Coins")) s:Close()
	end)
end)

test("Retained Coins definitions never establish loaded egg availability or recommendation", function()
	simulated(function()
		local s = eggAnalysisFixture() s.Controller.Knowledge.EggModels = function() return {} end
		local a, b = s.Manager:Fresh() local r = Policy.Analyze(s.Controller.Config, a, b)
		assert(#r.CoinsAvailability == 0 and #r.Eggs == 0 and not r.RecommendedEgg and not r.HatchTestPlan)
		assert(r.Coverage.UnloadedCoinsDefinitions[1] == "Test Egg")
		assert(Policy.EggPlanText(s.Controller.Config, r, false):find("availability unverified")) s:Close()
	end)
end)

test("Fresh locked world excludes its loaded Coins egg without claiming account access", function()
	simulated(function()
		local s = eggAnalysisFixture() s.Dependencies.Eggs["Test Egg"].World = "Minigame Paradise"
		local a, b = s.Manager:Fresh() local r = Policy.Analyze(s.Controller.Config, a, b)
		assert(r.MinigameParadise.Status == "LOCKED" and not r.RecommendedEgg and not r.CoinsAvailability[1].Eligible)
		assert(r.CoinsAvailability[1].AccessStatus == "LOCKED_OR_UNKNOWN_UNLOCK") s:Close()
	end)
end)

test("Manual analysis movement refreshes proximity while never claiming hatch location", function()
	simulated(function()
		local s = eggAnalysisFixture() local a, b = s.Manager:Fresh() local r = Policy.Analyze(s.Controller.Config, a, b)
		assert(r.HatchTestPlan.InRange and r.HatchTestPlan.Distance == 2)
		s.Root.Position += Vector3.new(100,0,0) a, b = s.Manager:Fresh() r = Policy.Analyze(s.Controller.Config, a, b)
		assert(not r.HatchTestPlan.InRange and r.HatchTestPlan.Distance == 98)
		s.Manager:Select({}) assert(not s.Manager.Hatch.Location and #s.Teleports == 0 and #s.Commands == 0)
		assert(Policy.EggPlanText(s.Controller.Config, r, false):find("distance=98.0 studs")) s:Close()
	end)
end)

test("Native pet projections isolate mutating helpers from the benchmark and each other", function()
	simulated(function()
		local s = fixture() s.Profile.ProjectionProbe = { Uses = 5 }
		local originalScore = s.Dependencies.StatsUtil.GetCurrencyMultiplier
		s.Dependencies.StatsUtil.GetCurrencyMultiplier = function(self, raw, currency)
			raw.ProjectionProbe.Uses -= 1
			return originalScore(self, raw, currency) + raw.ProjectionProbe.Uses
		end
		local originalLuck = s.Dependencies.StatsUtil.GetLuckMultiplier
		s.Dependencies.StatsUtil.GetLuckMultiplier = function(self, player, raw, ...)
			raw.ProjectionProbe.Uses -= 1 return originalLuck(self, player, raw, ...)
		end
		local _, ctx = s.Manager:Fresh()
		assert(ctx.AccountFacts.ProjectionProbe.Uses == 5 and s.Profile.ProjectionProbe.Uses == 5)
		local a = ctx.ScoreTeam({ "weak" }) local b = ctx.ScoreTeam({ "weak" })
		assert(a == 6 and b == 6 and ctx.AccountFacts.ProjectionProbe.Uses == 5)
		ctx.ScoreNewPet("New", { "strong", "strong" })
		assert(ctx.AccountFacts.ProjectionProbe.Uses == 5 and s.Profile.ProjectionProbe.Uses == 5) s:Close()
	end)
end)

print("[OC TEST] Phase 4 regressions passed: " .. tostring(tests - before) .. "; total=" .. tostring(tests) .. "; native action/gameplay verification remains owner-pending")
end

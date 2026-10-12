--!nonstrict
-- ReplicatedStorage knowledge facade. Reuses the approved reader's dependency cache;
-- it neither loads future systems nor executes actions or substitutes account/world facts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameKnowledge = {}
local PetPolicy = require(script.Parent.PetPolicy)
GameKnowledge.__index = GameKnowledge

local pickupContract = table.freeze({
	DefinitionSource = "ReplicatedStorage.Shared.Data.Worlds",
	ZoneInterface = "ReplicatedStorage.Shared.Utils.GetPickupZones",
	AssetSource = "ReplicatedStorage.Assets.Pickups",
	SpawnSource = "ReplicatedStorage.Remotes.Pickups.SpawnPickups",
	ClientEvidence = "StarterPlayer.StarterPlayerScripts.ClientScript:1134-1344",
	InitialRenderPath = "Workspace.Rendered.Pickups",
	RenderedPath = "Workspace.Rendered.Chunker (all native folders with this name)",
	ActiveRegistry = "ReplicatedStorage.Client.Tutorial._activePickups",
	RegistryEvidence = "ClientScript:1137-1140,1255-1279; Client.Tutorial:44,522",
	ParentEvidence = "ReplicatedStorage.Shared.Utils.Chunker:33-55,118-167",
	PositionSource = "Actual Model:GetPivot().Position; spawn payload contains Root/Visual/Id, not an exact position",
	IdOrigin = "Received SpawnPickups payload Id; generation is server-side/unavailable",
	ExistingPickupSync = "Read current native registry; past spawn events are not replayed",
	RenderedClass = "Model",
	RangeMethod = "StatsUtil:GetPickupRange(profile)",
	CollectionOwner = "Native radius collector plus scheduler-owned stationary ID batches; per-ID server acceptance unknown",
	OwnerEvidence = "Owner approved Phase 2 stationary collection, visual cleanup, native travel and goal-driven routing; individual request acceptance is not established",
	CleanupEvidence = "ClientScript:1243-1279 destroys Models and calls native Chunker.Remove; OC removes the native chunk and matching registry entry only after dispatch",
	IslandWideBatchFound = false,
	Evidence = "CLIENT_SOURCE_INSPECTED; execution requires owner verification",
	ServerValidation = "UNAVAILABLE",
})

function GameKnowledge.new(reader) return setmetatable({ Reader = reader }, GameKnowledge) end

function GameKnowledge:Get(name)
	-- Returning the same native dependency avoids competing discovery/require loops.
	return self.Reader:_dependency(name)
end

function GameKnowledge:Assets(name)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	return assets and assets:FindFirstChild(name)
end

function GameKnowledge:PetContract()
	return { Definitions = "Shared.Data.Eggs/Pets + native builders",
		Stats = "Shared.Utils.Stats.PetUtil:GetStats; StatsUtil:GetCurrencyMultiplier/GetBubblePower on detached team projections",
		Pool = "Client.Gui.LootPoolViewer:601-613; GetEggPool; ApplyMultiplierToPool; GetRandomWeightedItem normalizes Chance weights",
		Probability = "CLIENT_UI_ESTIMATE; effective server Secret/Infinity/variant/pity odds UNKNOWN",
		Hatch = "ClientScript:569,616,879,926-931,986-1025; unopened prompt <=6.5 studs, opened egg <=16; account cost/capacity, NextEggOpenAt; HatchEgg(name,count)",
		Equip = "Client.Gui.Frames.Inventory:2140-2192; EquipPet/UnequipPet(base ID); duplicate team IDs represent stacked copies",
		EquipmentRules = "Inventory:2615-2637 EquipTeam exists, but this test preserves the current TeamEquipped; Locked:2229; no pet-favorite field found; no verified server cooldown",
		Space = "StatsUtil:GetUsedPetStorage ordinary Amount counts or Digital Storage JSON bytes; IsInventoryFull native guard; digital requests limited to one egg",
		Result = "Received LocalData.Pets and Teams[TeamEquipped].Pets multiplicity, not invocation or hatch animation",
		Actions = "OWNER_LIVE_PENDING", ServerValidation = "UNAVAILABLE" }
end

local function detached(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, entry in pairs(value) do result[key] = detached(entry) end
	return result
end

local function native(object, method, ...)
	if not object or type(object[method]) ~= "function" then return nil end
	local ok, value = pcall(object[method], object, ...)
	if ok then return value end
	return nil
end

function GameKnowledge:EggModels(force)
	if force or os.clock() - (self.LastEggScan or -math.huge) >= self.Reader.Config.PET_SETTINGS.ANALYSIS_INTERVAL_SECONDS then
		self.LastEggScan, self.NativeEggModels = os.clock(), {}
		local eggs = self:Get("Eggs") or {}
		-- Native tags are removed by ClientScript:674. Keep original Root/Prompt/
		-- Plate/Cost models, including actual Rendered.Chunker receivers; visual
		-- Generic egg clones lack this interface. No object mutation or hidden scan.
		for _, model in ipairs(workspace:GetDescendants()) do
			if model:IsA("Model") and eggs[model.Name] and model:FindFirstChild("Root")
				and model:FindFirstChild("Prompt") and model:FindFirstChild("Plate") and model:FindFirstChild("Cost") then
				table.insert(self.NativeEggModels, model)
			end
		end
	end
	return self.NativeEggModels or {}
end

function GameKnowledge:NativeEggRangeEligible(egg, root, force)
	-- Existing native physical-egg contract: unopened Prompt / opened nearest Root.
	-- Shared fresh observation, no positioning, registry mutation or new loop.
	local function point(v)
		return v and type(v.X) == "number" and type(v.Y) == "number" and type(v.Z) == "number"
			and v.X == v.X and v.Y == v.Y and v.Z == v.Z
			and math.abs(v.X) < math.huge and math.abs(v.Y) < math.huge and math.abs(v.Z) < math.huge
	end
	local ok, eligible, range = pcall(function()
		local model = egg and egg.Model
		if not model or not model.Parent or not model:IsDescendantOf(workspace) or not root or not point(root.Position) then return false end
		local part, prompt = model:FindFirstChild("Root"), model:FindFirstChild("Prompt")
		if not part or not part:IsA("BasePart") or not point(part.Position) then return false end
		local raw = self.Reader:GetLiveProfile()
		if not raw or type(raw.EggsOpened) ~= "table" then return false end
		local opened = model:GetAttribute("Unlocked") == true and raw.EggsOpened[model.Name] ~= nil
		local origin, limit = part, 16
		if not opened then
			if not prompt or not prompt:IsA("BasePart") or not point(prompt.Position) then return false end
			local nativePrompt = prompt:FindFirstChildOfClass("ProximityPrompt")
			if not nativePrompt or nativePrompt.Parent ~= prompt or nativePrompt.Enabled ~= true
				or nativePrompt.RequiresLineOfSight ~= false or not PetPolicy.Finite(nativePrompt.MaxActivationDistance)
				or nativePrompt.MaxActivationDistance <= 0 then return false end
			origin, limit = prompt, math.min(6.5, nativePrompt.MaxActivationDistance)
		end
		local record = { Range = limit, Distance = (origin.Position - root.Position).Magnitude, Opened = opened,
			RangeOrigin = origin, RangeOriginPosition = origin.Position }
		if record.Distance > limit then return false, record end
		if opened then
			local prompts = self:Get("ProximityPrompt")
			if not prompts or prompts.Visible ~= 0 then return false, record end
			for _, other in ipairs(self:EggModels(force)) do
				local otherRoot = other ~= model and other.Parent and other:IsDescendantOf(workspace) and other:FindFirstChild("Root")
				if otherRoot and otherRoot:IsA("BasePart") and point(otherRoot.Position) and other:GetAttribute("Unlocked") == true
					and (otherRoot.Position - root.Position).Magnitude <= record.Distance + 0.05 then return false, record end
			end
		end
		return true, record
	end)
	return ok and eligible == true, ok and range or nil
end

function GameKnowledge:PetContext(snapshot, plan, tracker)
	local raw = self.Reader:GetLiveProfile()
	local currency = PetPolicy.Currency(self.Reader.Config, plan)
	local context = { Currency = currency, AccountId = self.Reader.Player and self.Reader.Player.UserId, Eggs = {}, EggAvailability = {}, Pets = self:Get("Pets"),
		MinigameParadise = PetPolicy.WorldAccess(nil, "Minigame Paradise") }
	if not raw or not snapshot.Ready then context.Error = "Current LocalData unavailable" return context end
	-- Helpers receive a detached account. Their weak caches cannot mutate live inventory.
	local profile = detached(raw)
	context.MinigameParadise = PetPolicy.WorldAccess(profile, "Minigame Paradise")
	context.AccountFacts = profile -- Final equipment dispatch compares received facts again after any yielding guards.
	context.Inventory, context.Error = PetPolicy.Inventory(profile)
	local stats, util, pools = self:Get("StatsUtil"), self:Get("PetUtil"), self:Get("GetEggPool")
	-- BuffUtil-backed native helpers can decrement uses/update queues even when
	-- estimating. Isolate every call, preserving one immutable account benchmark.
	context.MaxEquipped = native(stats, "GetMaxPetsEquipped", detached(profile))
	context.MaxHatches = native(stats, "GetMaxEggHatches", detached(profile))
	context.StorageUsed, context.StorageCapacity = native(stats, "GetUsedPetStorage", detached(profile)), native(stats, "GetMaxPetStorage", detached(profile))
	context.DigitalStorage = native(stats, "HasDigitalStorage", detached(profile))
	context.InventoryFull = native(stats, "IsInventoryFull", detached(profile))
	context.AutoDeleteKnown = type(profile.AutoDelete) == "table"
	context.AutoDeleteActive = context.AutoDeleteKnown and next(profile.AutoDelete) ~= nil
	context.StorageUnit = context.DigitalStorage == true and "JSON_BYTES" or context.DigitalStorage == false and "PET_QUANTITY" or "UNKNOWN"
	if context.Inventory and stats and currency then
		local function score(ids, pets)
			local projected = detached(profile)
			if pets then projected.Pets = detached(pets) end
			projected.Teams[profile.TeamEquipped].Pets = table.clone(ids)
			if currency == "Bubbles" then return native(stats, "GetBubblePower", projected) end
			return native(stats, "GetCurrencyMultiplier", projected, currency)
		end
		context.ScoreTeam = score
		context.PetStats = function(pet, ids)
			local projected = detached(profile)
			projected.Teams[profile.TeamEquipped].Pets = table.clone(ids or context.Inventory.Team)
			return native(util, "GetStats", detached(pet), projected)
		end
		context.PetScore = function(pet, ids)
			local values = context.PetStats(pet, ids)
			return type(values) == "table" and (values[currency] or (currency ~= "Bubbles" and 1 or nil)) or nil
		end
		context.ScoreNewPet = function(name, ids)
			local pet = { Id = "OC_DETACHED_PROJECTION", Name = name, XP = 0 }
			local pets = table.clone(profile.Pets) table.insert(pets, pet)
			local best = score(ids, pets)
			if not PetPolicy.Finite(best) or not PetPolicy.Finite(context.MaxEquipped) then return nil end
			for slot = 1, #ids + (#ids < context.MaxEquipped and 1 or 0) do
				local old = context.Inventory.ById[ids[slot]]
				if old and (old.Super or PetPolicy.Protected(self.Reader.Config, old, (context.Pets or {})[old.Name]) or not context.Pets or not context.Pets[old.Name] or not context.Pets[old.Name].Rarity) then continue end
				local proposal = table.clone(ids) proposal[slot] = pet.Id
				local value = score(proposal, pets)
				if not PetPolicy.Finite(value) then return nil end
				best = math.max(best, value)
			end
			return best
		end
		-- Evaluate one actually received copy with its real XP/variant/enchants.
		-- No synthetic inventory entry and no equipment action.
		context.ScoreReceivedPet = function(id, ids)
			local pet = context.Inventory.ById[id]
			if not pet or pet.Super or not context.Pets or not context.Pets[pet.Name] then return nil end
			local best = score(ids)
			if not PetPolicy.Finite(best) or not PetPolicy.Finite(context.MaxEquipped) then return nil end
			if (PetPolicy.Counts(ids)[id] or 0) >= (pet.Amount or 1) then return best end
			for slot = 1, #ids + (#ids < context.MaxEquipped and 1 or 0) do
				local old = context.Inventory.ById[ids[slot]]
				if old and (old.Super or PetPolicy.Protected(self.Reader.Config, old, context.Pets[old.Name])
					or not context.Pets[old.Name] or not context.Pets[old.Name].Rarity) then continue end
				local proposal = table.clone(ids) proposal[slot] = id
				local value = score(proposal)
				if not PetPolicy.Finite(value) then return nil end
				best = math.max(best, value)
			end
			return best
		end
	end
	local definitions = self:Get("Eggs") or {}
	local coverage = { Definitions = 0, PermanentDefinitions = 0, LoadedModels = 0, Evaluated = 0, Limit = self.Reader.Config.HATCH_SETTINGS.MAXIMUM_EGGS_ANALYZED,
		Scope = "Loaded native models only; retained definitions/assets do not establish live availability", MissingSelected = {}, UnloadedCoinsDefinitions = {} }
	context.EggCoverage = coverage
	for name, def in pairs(definitions) do
		coverage.Definitions += 1
		if def.World and not def.Event and not def.ProductId and not def.IsAdminEgg and name ~= "Infinity Egg" then coverage.PermanentDefinitions += 1 end
	end
	local currentWorld = native(self:Get("WorldUtil"), "GetPlayerWorld", self.Reader.Player)
	local root = tracker:Root()
	local byName = {}
	for _, model in ipairs(self:EggModels()) do
		if not model.Parent or not model:IsDescendantOf(workspace) then continue end
		local part = model:FindFirstChild("Root")
		if not part or not part:IsA("BasePart") then continue end
		local distance = root and (part.Position - root.Position).Magnitude
		local old = byName[model.Name]
		if old and (old.Distance or math.huge) <= (distance or math.huge) then continue end
		local def = definitions[model.Name]
		local island = model:GetAttribute("Island") or def.Island
		local world = def.World
		local accessible = world ~= nil and not def.Event and not def.ProductId and not def.IsAdminEgg and model.Name ~= "Infinity Egg"
			and type(profile.WorldsUnlocked) == "table" and profile.WorldsUnlocked[world] ~= nil
			and (not island or type(profile.AreasUnlocked) == "table" and profile.AreasUnlocked[island] ~= nil)
		local bonus = model:GetAttribute("BonusLuck")
		local poolWorld = world == currentWorld and currentWorld or "None"
		local luck = native(stats, "GetLuckMultiplier", self.Reader.Player, detached(profile), poolWorld, nil, bonus, model.Name)
		local pool
		if pools and PetPolicy.Finite(luck) and luck > 0 then
			local ok, value = pcall(pools, model.Name, poolWorld, luck, nil, nil, detached(profile))
			if ok then pool = value end
		end
		local opened = model:GetAttribute("Unlocked") == true and type(profile.EggsOpened) == "table" and profile.EggsOpened[model.Name] ~= nil
		local nativeRange, observedRange = self:NativeEggRangeEligible({ Model = model }, root)
		local range = observedRange and observedRange.Range or opened and 16 or 6.5
		local access = not world and "UNKNOWN_ACCESS" or (def.Event or def.ProductId or def.IsAdminEgg or model.Name == "Infinity Egg") and "UNSUPPORTED"
			or accessible and "ACCESSIBLE" or "LOCKED_OR_UNKNOWN_UNLOCK"
		local ok, path = pcall(function() return model:GetFullName() end)
		byName[model.Name] = { Name = model.Name, Model = model, World = world, Island = island, Distance = distance, Range = range,
			ModelPath = ok and path or nil, Position = part.Position,
			DefinitionCurrency = def.Cost and def.Cost.Type == "Currency" and def.Cost.Currency or nil,
			AccessStatus = access, Loaded = true, Accessible = accessible == true,
			InRange = accessible and world == currentWorld and nativeRange, NativeRangeEligible = nativeRange,
			RangeOrigin = observedRange and observedRange.RangeOrigin, InteractionDistance = observedRange and observedRange.Distance,
			Cost = native(stats, "GetEggCost", self.Reader.Player, detached(profile), model.Name), Pool = pool, Luck = luck,
			Duration = native(stats, "GetHatchDuration", detached(profile)), Opened = opened, Unlocked = model:GetAttribute("Unlocked"),
			Reason = accessible and "Scene-present native egg; account world/island access confirmed" or "Premium/event/special/locked or unknown access; no hatch action" }
	end
	local names = {} for name in pairs(byName) do table.insert(names, name) end table.sort(names)
	coverage.LoadedModels = #names
	-- Availability/funding covers every loaded original model, even when the
	-- more expensive native team projections reach their configured cap.
	for _, name in ipairs(names) do table.insert(context.EggAvailability, byName[name]) end
	for name, def in pairs(definitions) do
		if not byName[name] and def.World and not def.Event and not def.ProductId and not def.IsAdminEgg and name ~= "Infinity Egg"
			and def.Cost and def.Cost.Type == "Currency" and def.Cost.Currency == "Coins" then table.insert(coverage.UnloadedCoinsDefinitions, name) end
	end
	table.sort(coverage.UnloadedCoinsDefinitions)
	-- Explicit selection is never lost behind the projection cap.
	table.sort(names, function(a, b)
		local x, y = table.find(self.Reader.Config.HATCH_SETTINGS.SELECTED_EGGS, a) ~= nil, table.find(self.Reader.Config.HATCH_SETTINGS.SELECTED_EGGS, b) ~= nil
		return x == y and a < b or x and not y
	end)
	for index, name in ipairs(names) do
		if index > self.Reader.Config.HATCH_SETTINGS.MAXIMUM_EGGS_ANALYZED then context.EggLimitReached = true break end
		table.insert(context.Eggs, byName[name])
	end
	coverage.Evaluated, coverage.LimitReached = #context.Eggs, context.EggLimitReached == true
	for _, name in ipairs(self.Reader.Config.HATCH_SETTINGS.SELECTED_EGGS) do
		if not byName[name] then
			table.insert(coverage.MissingSelected, name)
			local def = definitions[name]
			table.insert(context.Eggs, { Name = name, Loaded = false, Accessible = false, AccessStatus = def and "NOT_LOADED" or "UNKNOWN_DEFINITION",
				World = def and def.World, Island = def and def.Island, Cost = def and def.Cost,
				Reason = def and "Selected definition exists; original native egg model not loaded. Approach manually; no force-load or travel" or "Selected egg definition unavailable" })
		end
	end
	return context
end

function GameKnowledge:PickupContract() return pickupContract end

function GameKnowledge:ProgressionContract()
	return { Definitions = "ReplicatedStorage.Shared.Data.Worlds", Account = "LocalData.AreasUnlocked / WorldsUnlocked",
		WorldGate = "ClientScript:2138-2326; tagged WorldGate.World; UnlockCost; native command UnlockWorld with world identifier",
		Activation = "Client.Activation:357-360 horizontal <= Root.Size.Y/2; vertical <= 10",
		IslandTravel = "Client.Gui.Frames.WorldMap:168-198; Shared.Utils.WorldUtil.toIslandLocation; discovered islands only",
		Traversal = "Client.Effects.Physics uses actual Bubble.Amount and Bubble Gravity; no verified minimum or safe undiscovered-island route",
		IslandDiscovery = "Overworld Island.UnlockHitbox: anchored, touch-enabled, noncolliding; server handler unavailable; simulated contact is an owner-requested runtime experiment",
		DiscoveryVerification = "Correct LocalData.AreasUnlocked absent -> present, received by LocalData PlayerDataChanged; durable save requires owner rejoin testing",
		DiscoveryCapability = "firetouchinterest is runtime-specific, absent from inspected native scripts; check at live execution, never assume Studio support",
		WorldTravel = "Native FastTravel.Spawn; Seven Seas has a separate fishing-area contract, deferred",
		UnlockVerification = "Actual WorldsUnlocked absent -> present; balances logged separately; invocation/visuals not proof",
		ServerValidation = "UNAVAILABLE", LivePhase3Verification = "OWNER_CONFIRMED_DISCOVERY_AND_FUNDING_IN_SESSION",
		SavedDiscoveryPersistence = "OWNER_REJOIN_PENDING", WorldPurchase = "OWNER_LIVE_PENDING", AutomaticGateApproach = "UNVERIFIED_MANUAL_BLOCKER" }
end

function GameKnowledge:ActivePickups()
	local tutorial = self:Get("Tutorial")
	if type(tutorial) ~= "table" then
		local dependency = (self.Reader.Dependencies or {}).Tutorial
		return nil, "Client.Tutorial " .. tostring(dependency and dependency.Status or "not loaded") .. (dependency and dependency.Error and ": " .. dependency.Error or "")
	end
	if type(tutorial._activePickups) ~= "table" then return nil, "Client.Tutorial loaded but _activePickups is absent or not a table" end
	return tutorial._activePickups, "Client.Tutorial._activePickups available"
end

function GameKnowledge:GetStatus()
	local dependencies = {}
	for name, entry in pairs(self.Reader.Dependencies or {}) do
		dependencies[name] = { Status = entry.Status, Source = "ReplicatedStorage." .. entry.Path, Error = entry.Error }
	end
	return { Dependencies = dependencies, PickupAssetsAvailable = self:Assets("Pickups") ~= nil,
		Pickup = table.clone(pickupContract), Progression = self:ProgressionContract(), Pets = self:PetContract(), ServerOnlyRules = "UNAVAILABLE" }
end

function GameKnowledge:ReleaseChunkerObserver()
	if self.ChunkerClass and self.ChunkerClass.Update == self.ChunkerObserver then self.ChunkerClass.Update = self.OriginalChunkerUpdate end
	self.ChunkerClass, self.ChunkerObserver, self.OriginalChunkerUpdate, self.CleanupRegistry = nil, nil, nil, nil
end

function GameKnowledge:PickupChunker()
	if self.NativePickupChunker then return self.NativePickupChunker end
	if self.ChunkerObserver and os.clock() - self.ChunkerObserverAt >= 5 then
		self:ReleaseChunkerObserver() self.ChunkerRetryAt = os.clock() + 5
	end
	if os.clock() < (self.ChunkerRetryAt or 0) then return nil, "Native pickup Chunker observation is in backoff" end
	if not self.ChunkerObserver then
		local class, registry = self:Get("Chunker"), self:ActivePickups()
		if not class or type(class.Update) ~= "function" or not registry then return nil, "Native Chunker/registry dependency unavailable" end
		self.ChunkerClass, self.OriginalChunkerUpdate, self.CleanupRegistry = class, class.Update, registry
		local original = class.Update
		self.ChunkerObserver = function(chunker, ...)
			-- Observe the real receiver; preserve native Update arguments/results and never choose an action here.
			local result = table.pack(original(chunker, ...))
			pcall(function() -- Observation failures must never interrupt the game's Update.
				if type(chunker) == "table" and type(chunker.Remove) == "function" and type(chunker.IsValueLoaded) == "function" then
					for _, pickup in pairs(self.CleanupRegistry or {}) do
						if pickup.Parent and pickup.Parent == chunker._folder and chunker:IsValueLoaded(pickup) then
							self.NativePickupChunker = chunker self:ReleaseChunkerObserver() break
						end
					end
				end
			end)
			return table.unpack(result, 1, result.n)
		end
		local ok = pcall(function() class.Update = self.ChunkerObserver end)
		if not ok then self:ReleaseChunkerObserver() return nil, "Native Chunker receiver observation unavailable" end
		self.ChunkerObserverAt = os.clock()
	end
	return nil, "Waiting for native pickup Chunker receiver; no request or visual mutation yet"
end

function GameKnowledge:Destroy()
	self:ReleaseChunkerObserver() self.NativePickupChunker = nil
end

function GameKnowledge:RewardContract()
	return { Playtime = "Shared.Data.Playtime.Gifts[{Time,Luck}]; Client.Gui.Frames.Playtime:99-135,369-376,394-404",
		Claimed = "PlaytimeRewards.Claimed[tostring(index)]~=nil; elapsed Time.now()-Start; received Playtime mastery",
		OrdinaryBox = "ItemUtil:GetOwnedAmount(profile,{Type='Powerup',Name='Mystery Box'}); PromptBuilder:297-383 UseGift(name,count)",
		Physical = "PhysicalItem:GetActiveGifts:109-121; Gift:Hit:206-270; eight guarded native hits precede native ClaimGift",
		Result = "Received exact claimed key or stock debit plus correlated physical completion and observable reward; dispatch is not success",
		Bulk = "ClaimAllPlaytime exists but automatic bulk is not enabled; authoritative server eligibility remains unknown",
		ServerValidation = "UNAVAILABLE", LiveVerification = "OWNER_PENDING" }
end

return GameKnowledge

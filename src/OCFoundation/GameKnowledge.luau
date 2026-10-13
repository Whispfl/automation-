--!nonstrict
-- ReplicatedStorage knowledge facade. Reuses the approved reader's dependency cache;
-- it neither loads future systems nor executes actions or substitutes account/world facts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
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

local function point(value)
	-- Coordinates are signed. PetPolicy.Finite deliberately rejects negative
	-- economic values and must never validate a world-space component.
	local function component(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
	return value and component(value.X) and component(value.Y) and component(value.Z)
end

local function eggParts(model)
	if not model or not model:IsA("Model") then return nil end
	local root, prompt = model:FindFirstChild("Root"), model:FindFirstChild("Prompt")
	if root and prompt and root.Parent == model and prompt.Parent == model
		and root:IsA("BasePart") and prompt:IsA("BasePart") and point(root.Position) and point(prompt.Position)
		and model:FindFirstChild("Plate") and model:FindFirstChild("Cost") then return root, prompt end
end

local function eggReceiver(receiver)
	local rendered = workspace:FindFirstChild("Rendered")
	return type(receiver) == "table" and receiver.Mode == "3D" and receiver._chunkSize == 128
		and receiver.RenderDistance == 2 and type(receiver._chunks) == "table" and type(receiver._loaded) == "table"
		and receiver._folder and receiver._folder.Parent == rendered and rendered ~= nil
end

local function classifyObservedEggQueue(receiver, class, definitions)
	-- Queue identity is distinct from private interaction/paid eligibility.
	if type(receiver) ~= "table" or type(class) ~= "table" or getmetatable(receiver) ~= class
		or type(receiver.Remove) ~= "function" or type(receiver.IsValueLoaded) ~= "function"
		or typeof(receiver._folder) ~= "Instance" or not receiver._folder:IsA("Folder")
		or not eggReceiver(receiver) then return false, "NATIVE_CLASS_OR_QUEUE_STRUCTURE_UNVERIFIED" end
	if type(definitions) ~= "table" then return false, "EGG_CATALOG_NOT_READY_FOR_POSITIVE_ANCHOR" end
	local coordinates, entries, loadedCoordinates, loadedCatalog = 0, 0, 0, 0
	for coord, loaded in pairs(receiver._loaded) do
		loadedCoordinates += 1
		if loadedCoordinates > 1000 then return false, "LOADED_COORDINATE_LIMIT_EXCEEDED" end
		if loaded ~= true then return false, "LOADED_FLAG_INCONSISTENT" end
		local values = receiver._chunks[coord]
		-- Native Remove can leave a true loaded flag with an absent bucket.
		if values ~= nil and type(values) ~= "table" then return false, "CHUNK_VALUES_NOT_TABLE" end
	end
	for coord, values in pairs(receiver._chunks) do
		coordinates += 1
		if coordinates > 1000 then return false, "COORDINATE_LIMIT_EXCEEDED" end
		if type(values) ~= "table" then return false, "CHUNK_VALUES_NOT_TABLE" end
		local loaded = receiver._loaded[coord] == true
		for index, value in pairs(values) do
			entries += 1
			if entries > 1000 then return false, "ENTRY_LIMIT_EXCEEDED" end
			if type(index) ~= "number" or index < 1 or index % 1 ~= 0 then return false, "UNSUPPORTED_MEMBER_KEY" end
			if typeof(value) ~= "Instance" or not value:IsA("Model") or not eggParts(value) then
				return false, "ORIGINAL_INTERFACE_OR_GEOMETRY_INCOMPLETE"
			end
			if loaded then
				if value.Parent ~= receiver._folder or not value:IsDescendantOf(workspace) then
					return false, "LOADED_MEMBER_ANCESTRY_INCONSISTENT"
				end
				if definitions[value.Name] then loadedCatalog += 1 end
			elseif value.Parent ~= nil then return false, "UNLOADED_MEMBER_ANCESTRY_INCONSISTENT" end
		end
	end
	if loadedCatalog == 0 then return false, "NO_LOADED_CATALOG_ORIGINAL_ANCHOR" end
	return true, "SOURCE_MATCHING_ORIGINAL_QUEUE_OBSERVED; private interaction/target eligibility checked separately"
end

function GameKnowledge:InstanceId(instance)
	if not instance then return "NONE" end
	self.InstanceIds = self.InstanceIds or setmetatable({}, { __mode = "k" })
	if not self.InstanceIds[instance] then
		self.InstanceSequence = (self.InstanceSequence or 0) + 1
		self.InstanceIds[instance] = string.format("I%04d", self.InstanceSequence)
	end
	return self.InstanceIds[instance]
end

function GameKnowledge:EggModels(force)
	if force or os.clock() - (self.LastEggScan or -math.huge) >= self.Reader.Config.PET_SETTINGS.ANALYSIS_INTERVAL_SECONDS then
		self.LastEggScan, self.NativeEggModels = os.clock(), {}
		local eggs = self:Get("Eggs") or {}
		-- All catalog-named Models are observations, not proof of registration.
		-- Include rendered copies in diagnostics; tags/names/paths are not identity.
		for _, model in ipairs(workspace:GetDescendants()) do
			if model:IsA("Model") and eggs[model.Name] then
				table.insert(self.NativeEggModels, model)
			end
		end
	end
	return self.NativeEggModels or {}
end

function GameKnowledge:ObserveEggModel(model)
	local def = (self:Get("Eggs") or {})[model.Name]
	local record = { Model = model, IdentityId = self:InstanceId(model), Verified = false, World = def and def.World,
		Island = model:GetAttribute("Island") or def and def.Island }
	local ok, path = pcall(function() return model:GetFullName() end)
	record.Path = ok and path or "UNKNOWN"
	record.ParentId = self:InstanceId(model.Parent)
	local root, prompt = eggParts(model)
	record.Root, record.Prompt = root, prompt
	if not model.Parent or not model:IsDescendantOf(workspace) then record.Reason = "UNLOADED_INSTANCE" return record end
	if not root then
		-- Native visual Clone gets Offset/Size and a Hitbox, not the original interface.
		record.Reason = "NON_INTERACTIVE_REPRESENTATION: original Root/Prompt/Plate/Cost interface absent"
		return record
	end
	local prompts = self:Get("ProximityPrompt")
	local engine = prompt:FindFirstChildOfClass("ProximityPrompt")
	record.NativePrompt = engine
	record.PromptCacheMember = engine ~= nil and type(prompts) == "table" and type(prompts._cache) == "table" and prompts._cache[engine] == true
	if record.PromptCacheMember and engine.Parent == prompt then
		record.Verified, record.IdentityEvidence = true, "EXACT_INITIAL_PROMPT_CACHE_MEMBERSHIP (ProximityPrompt:13,29-51; ClientScript:622)"
	end
	local registered, receivers = 0, 0
	for receiver in pairs(self.NativeEggChunkers or {}) do
		if not eggReceiver(receiver) then continue end
		receivers += 1
		if model.Parent ~= receiver._folder then continue end
		for coord in pairs(receiver._loaded) do
			local values = receiver._chunks[coord]
			local member = false
			if type(values) == "table" then
				for _, value in pairs(values) do
					if value == model then member = true break end
				end
			end
			if member then registered += 1 break end
		end
	end
	record.RegisteredReceivers = registered
	if self.EggObservationFinished and receivers == 1 then
		-- One source-matching receiver observed after native Update; membership is
		-- actual Instance equality. A same-parent/path captured copy is not a member.
		record.Verified = registered == 1
		record.IdentityEvidence = registered == 1 and "EXACT_LOADED_EGG_CHUNKER_MEMBERSHIP (ClientScript:375-376,747; Chunker:99-117,148-152)" or nil
	elseif self.EggObservationFinished and receivers > 1 then
		record.Verified = false record.Reason = "AMBIGUOUS_EGG_REGISTRATION_RECEIVER"
	end
	record.Reason = record.Reason or (record.Verified and "REGISTERED_INTERACTIVE_INSTANCE"
		or self.EggObservationFinished and "UNREGISTERED_PHYSICAL_REPRESENTATION_OR_UNKNOWN_REGISTRY"
		or "NATIVE_EGG_REGISTRATION_PENDING: bounded passive observation; no structural/name/path selection")
	return record
end

function GameKnowledge:InteractiveEggModels(force)
	self:ObserveEggChunker()
	local models = {}
	for _, model in ipairs(self:EggModels(force)) do
		if self:ObserveEggModel(model).Verified then table.insert(models, model) end
	end
	return models
end

function GameKnowledge:ResolveEggInstance(name, force, expectedModel)
	self:ObserveEggChunker()
	local observed = { Name = name, Candidates = {}, Count = 0, VerifiedCount = 0 }
	local receivers = 0 for receiver in pairs(self.NativeEggChunkers or {}) do if eggReceiver(receiver) then receivers += 1 end end
	local completeRegistry = self.EggObservationFinished and receivers == 1
	local chosen, unknown = nil, false
	for _, model in ipairs(self:EggModels(force)) do
		if model.Name ~= name then continue end
		local record = self:ObserveEggModel(model)
		observed.Count += 1 table.insert(observed.Candidates, record)
		if record.Verified then
			if not expectedModel or model == expectedModel then chosen = record end
			observed.VerifiedCount += 1
		elseif record.Root and not completeRegistry then unknown = true end
	end
	local reason
	if observed.VerifiedCount > 1 and not expectedModel then
		reason = "AMBIGUOUS_NATIVE_EGG_MODEL: multiple independently registered interactive Instances; exact target unresolved; no nearest/path substitution"
	elseif unknown then reason = self.EggObservationFinished and "NATIVE_EGG_IDENTITY_UNVERIFIED: unresolved physical candidates; native egg receiver unavailable/ambiguous; no travel attempt"
		or "NATIVE_EGG_REGISTRATION_PENDING: physical candidates lack complete current registration evidence; no travel attempt"
	elseif not chosen then reason = expectedModel and "Selected exact egg Instance lacks current registration; no name/path replacement or retarget"
		or observed.Count == 0 and "Selected egg model not loaded; no force-load"
		or "NATIVE_EGG_IDENTITY_UNVERIFIED: no unique current interactive registration; names/paths/attributes cannot authorize travel"
	elseif expectedModel and chosen.Model ~= expectedModel then reason = "Brain selected exact egg Instance changed; no name/path replacement or retarget" end
	observed.Reason = reason or (expectedModel and "EXACT_RETAINED_REGISTERED_INSTANCE; native interaction eligibility checked separately" or "UNIQUE_VERIFIED_INTERACTIVE_INSTANCE")
	return not reason and chosen or nil, reason, observed
end

function GameKnowledge:EggLocationCandidates(name, force)
	local definitions, worlds = self:Get("Eggs") or {}, self:Get("Worlds") or {}
	local def, profile = definitions[name], self.Reader:GetLiveProfile()
	local candidates, observations = {}, { Name = name, Count = 0, VerifiedCount = 0, LocationCount = 0, LocationVerifiedCount = 0, Candidates = {} }
	if type(def) ~= "table" or type(def.World) ~= "string" or def.Event or def.ProductId or def.IsAdminEgg or name == "Infinity Egg" then
		observations.Reason = "EGG_LOCATION_UNSUPPORTED: permanent native world/egg definition required" return candidates, observations
	end
	local worldDef = worlds[def.World]
	if type(worldDef) ~= "table" or worldDef.Removed or worldDef.Event or not profile or type(profile.WorldsUnlocked) ~= "table"
		or profile.WorldsUnlocked[def.World] == nil or type(profile.AreasUnlocked) ~= "table" then
		observations.Reason = "EGG_LOCATION_ACCESS_BLOCKED: actual world/island facts locked or unavailable" return candidates, observations
	end
	local sceneWorlds = workspace:FindFirstChild("Worlds")
	local worldModel = sceneWorlds and sceneWorlds:FindFirstChild(def.World)
	if not worldModel then observations.Reason = "EGG_LOCATION_WORLD_GEOMETRY_UNAVAILABLE" return candidates, observations end
	local function spatialArea(position)
		-- Mirrors native WorldUtil:12-38 and WorldMap:GetLocation:457-475 using
		-- current scene geometry, with conservative tie/missing-data rejection.
		local nearestWorld, distance, tie = nil, math.huge, false
		local worldNames = {}
		for _, entry in ipairs(sceneWorlds:GetChildren()) do
			if worldNames[entry.Name] then return nil, "EGG_LOCATION_AMBIGUOUS_WORLD_GEOMETRY" end
			worldNames[entry.Name] = true
			local spawn = entry:FindFirstChild("Spawn")
			if not spawn or not spawn:IsA("BasePart") or not point(spawn.Position) then return nil, "EGG_LOCATION_WORLD_SPAWN_UNAVAILABLE" end
			local delta = Vector3.new(position.X - spawn.Position.X, 0, position.Z - spawn.Position.Z).Magnitude
			if delta < distance - 0.05 then nearestWorld, distance, tie = entry.Name, delta, false
			elseif math.abs(delta - distance) <= 0.05 then tie = true end
		end
		if tie or nearestWorld ~= def.World then return nil, "EGG_LOCATION_WORLD_SPATIAL_MISMATCH_OR_TIE" end
		local spawn = worldModel:FindFirstChild("Spawn")
		local closest, vertical, areaTie = def.World, math.abs(position.Y - spawn.Position.Y), false
		local islands = worldModel:FindFirstChild("Islands")
		local areaNames = {}
		for _, entry in ipairs(worldDef.Islands or {}) do
			if areaNames[entry.Name] then return nil, "EGG_LOCATION_AMBIGUOUS_ISLAND_DEFINITION" end
			areaNames[entry.Name] = true
			local folder = islands and islands:FindFirstChild(entry.Name)
			local island = folder and folder:FindFirstChild("Island")
			local ok, pivot = pcall(function() return island:GetPivot() end)
			if not ok or not pivot or not point(pivot.Position) then return nil, "EGG_LOCATION_ISLAND_GEOMETRY_UNAVAILABLE: " .. tostring(entry.Name) end
			local delta = math.abs(position.Y - pivot.Position.Y)
			if delta < vertical - 0.05 then closest, vertical, areaTie = entry.Name, delta, false
			elseif math.abs(delta - vertical) <= 0.05 then areaTie = true end
		end
		if areaTie then return nil, "EGG_LOCATION_AMBIGUOUS_VERTICAL_AREA" end
		return closest
	end
	for _, model in ipairs(self:EggModels(force)) do
		if model.Name ~= name then continue end
		local observed = self:ObserveEggModel(model)
		observations.Count += 1 table.insert(observations.Candidates, observed)
		if observed.Verified then observations.VerifiedCount += 1 end
		if not model.Parent or not model:IsDescendantOf(workspace) then observed.LocationReason = "EGG_LOCATION_STREAMED_OUT" continue end
		local root, prompt = eggParts(model)
		if not root then observed.LocationReason = "EGG_LOCATION_ORIGINAL_INTERFACE_UNAVAILABLE: display/decor is not a spatial anchor" continue end
		local parent, rendered = model.Parent, workspace:FindFirstChild("Rendered")
		local chunkedOriginal = parent:IsA("Folder") and parent.Name == "Chunker" and parent.Parent == rendered and rendered ~= nil
		local okTag, tagged = pcall(function() return CollectionService:HasTag(model, "Egg") end)
		local worldOriginal = model:IsDescendantOf(worldModel) and okTag and tagged == true
		if not chunkedOriginal and not worldOriginal then
			observed.LocationReason = "EGG_LOCATION_SOURCE_ASSOCIATION_UNVERIFIED: original interface lacks native placement/tag or chunked ancestry" continue
		end
		local island = model:GetAttribute("Island") or def.Island
		if island ~= nil and (type(island) ~= "string" or profile.AreasUnlocked[island] == nil) then
			observed.LocationReason = "EGG_LOCATION_ISLAND_ACCESS_BLOCKED" continue
		end
		local area, spatialReason = spatialArea(root.Position)
		if not area or area ~= (island or def.World) then
			observed.LocationReason = spatialReason or "EGG_LOCATION_ISLAND_SPATIAL_MISMATCH: annotation and native scene area disagree" continue
		end
		observed.LocationVerified, observed.LocationReason = true, "NATIVE_ORIGINAL_SPATIAL_ANCHOR"
		observations.LocationCount += 1
		observations.LocationVerifiedCount = observations.LocationCount
		observed.LocationEvidence = "ClientScript:658-674,747 original interface/reparenting + WorldUtil:12-38 world Spawn + WorldMap:457-475 area geometry; current LocalData access"
		table.insert(candidates, { Model = model, Root = root, Prompt = prompt, World = def.World, Island = island,
			IdentityId = observed.IdentityId, IdentityEvidence = observed.IdentityEvidence, LocationVerified = true,
			LocationAnchor = root, LocationAnchorPosition = root.Position, InteractionVerified = false, RegistrationVerified = observed.Verified == true,
			LocationEvidence = observed.LocationEvidence })
	end
	if #candidates == 0 then
		local reason = observations.Candidates[1] and observations.Candidates[1].LocationReason
		-- Prefer a physical-original rejection over a decorative-copy explanation.
		for _, row in ipairs(observations.Candidates) do if row.Root and row.LocationReason then reason = row.LocationReason break end end
		observations.Reason = reason or "EGG_LOCATION_NOT_LOADED: no trustworthy physical original"
	else observations.Reason = "PHYSICAL_LOCATION_VERIFIED; hatch eligibility remains independent" end
	return candidates, observations
end

function GameKnowledge:ResolveEggLocation(name, force, expectedModel, characterRoot)
	local candidates, observations = self:EggLocationCandidates(name, force)
	if expectedModel then
		for _, candidate in ipairs(candidates) do if candidate.Model == expectedModel then return candidate, nil, observations end end
		return nil, "EGG_LOCATION_SELECTED_INSTANCE_UNAVAILABLE: retained exact target lost, moved area, or access changed; " .. observations.Reason, observations
	end
	if #candidates == 0 then return nil, observations.Reason, observations end
	local character = self.Reader.Player and self.Reader.Player.Character
	local root = characterRoot or character and character:FindFirstChild("HumanoidRootPart")
	if #candidates > 1 and (not root or not point(root.Position)) then return nil, "EGG_LOCATION_SELECTION_POSITION_UNAVAILABLE", observations end
	for _, candidate in ipairs(candidates) do candidate.Distance = root and (candidate.Root.Position - root.Position).Magnitude or math.huge end
	table.sort(candidates, function(a, b)
		if a.Distance ~= b.Distance then return a.Distance < b.Distance end
		return a.IdentityId < b.IdentityId
	end)
	return candidates[1], nil, observations
end

function GameKnowledge:NativeRegisteredEggModels()
	-- Read every exact loaded value from the already identified public receiver.
	-- Native nearest scanning is not catalog/name-filtered. Do not infer a
	-- complete competing set from the subset returned by EggModels alone.
	self:ObserveEggChunker()
	local receiver, count = nil, 0
	for observed in pairs(self.NativeEggChunkers or {}) do
		if eggReceiver(observed) then receiver = observed count += 1 end
	end
	if not self.EggObservationFinished or count ~= 1 then return nil, "Complete current native egg registration evidence unavailable for nearest selection" end
	local models, seen, entries, coordinates = {}, {}, 0, 0
	for coord, loaded in pairs(receiver._loaded) do
		coordinates += 1
		if coordinates > 1000 then return nil, "Native loaded coordinate observation limit exceeded" end
		local values = receiver._chunks[coord]
		if loaded ~= true then return nil, "Native loaded egg registration coordinates inconsistent" end
		-- Remove:73-75 clears an empty chunk without clearing _loaded. Native
		-- IsValueLoaded:105-107 skips that absent chunk; present malformed data
		-- remains a blocker rather than being treated as an empty coordinate.
		if values == nil then continue end
		if type(values) ~= "table" then return nil, "Native loaded egg registration coordinates inconsistent" end
		for index, model in pairs(values) do
			entries += 1
			if entries > 512 then return nil, "Native loaded egg registration observation limit exceeded" end
			if type(index) ~= "number" or index % 1 ~= 0 or index < 1 then return nil, "Native loaded egg registration array inconsistent" end
			if typeof(model) ~= "Instance" or not model:IsA("Model") or model.Parent ~= receiver._folder
				or not model:IsDescendantOf(workspace) or not eggParts(model) then return nil, "Native loaded original registration geometry inconsistent" end
			if not seen[model] then seen[model] = true table.insert(models, model) end
		end
		-- Native Remove leaves holes (Chunker:66-75). Generic iteration reads
		-- every remaining exact value; a hole is not an unknown registry entry.
	end
	return models
end

function GameKnowledge:NativeEggRangeEligible(egg, root, force)
	-- Existing native physical-egg contract: unopened Prompt / opened nearest Root.
	-- Shared fresh observation, no positioning, registry mutation or new loop.
	local function point(v)
		return v and type(v.X) == "number" and type(v.Y) == "number" and type(v.Z) == "number"
			and v.X == v.X and v.Y == v.Y and v.Z == v.Z
			and math.abs(v.X) < math.huge and math.abs(v.Y) < math.huge and math.abs(v.Z) < math.huge
	end
	local ok, eligible, range, reason = pcall(function()
		local model = egg and egg.Model
		if not model or not model.Parent or not model:IsDescendantOf(workspace) or not root or not point(root.Position) then return false, nil, "Selected egg/character geometry unavailable" end
		local identity, identityReason = self:ResolveEggInstance(model.Name, force, model)
		if not identity then return false, nil, identityReason end
		-- Native create returns before private registration without its visual asset.
		local assets = self:Assets("Eggs")
		local visual = assets and assets:FindFirstChild(model.Name)
		if not visual or not visual:IsA("Model") then
			return false, nil, "Selected native visual prerequisite unavailable; private interaction registration unverified"
		end
		local part, prompt = model:FindFirstChild("Root"), model:FindFirstChild("Prompt")
		if not part or not part:IsA("BasePart") or not point(part.Position) then return false, nil, "Selected original Root geometry unavailable" end
		local raw = self.Reader:GetLiveProfile()
		if not raw or type(raw.EggsOpened) ~= "table" then return false, nil, "Current account EggsOpened unavailable" end
		local opened = model:GetAttribute("Unlocked") == true and raw.EggsOpened[model.Name] ~= nil
		local origin, limit = part, 16
		if not opened then
			if not prompt or not prompt:IsA("BasePart") or not point(prompt.Position) then return false, nil, "Selected initial Prompt geometry unavailable" end
			local nativePrompt = prompt:FindFirstChildOfClass("ProximityPrompt")
			if not nativePrompt or nativePrompt.Parent ~= prompt or nativePrompt.Enabled ~= true
				or nativePrompt.RequiresLineOfSight ~= false or not PetPolicy.Finite(nativePrompt.MaxActivationDistance)
				or nativePrompt.MaxActivationDistance <= 0 or identity.PromptCacheMember ~= true then return false, nil, "Selected initial native Prompt cache/eligibility unavailable" end
			origin, limit = prompt, math.min(6.5, nativePrompt.MaxActivationDistance)
		end
		local record = { Model = model, IdentityId = identity.IdentityId, Range = limit, Distance = (origin.Position - root.Position).Magnitude, Opened = opened,
			RangeOrigin = origin, RangeOriginPosition = origin.Position, InteractionMode = opened and "OPENED_NEAREST" or "INITIAL_PROMPT",
			Mode = opened and "OPENED_NEAREST" or "INITIAL_PROMPT" }
		if record.Distance > limit then return false, record, "Outside selected native " .. record.InteractionMode .. " range" end
		if opened then
			local prompts = self:Get("ProximityPrompt")
			if not prompts or prompts.Visible ~= 0 then return false, record, "Native opened scanner requires known global Prompt Visible=0" end
			local registered, registryReason = self:NativeRegisteredEggModels()
			if not registered then return false, record, registryReason end
			if not table.find(registered, model) then return false, record, "Selected exact original no longer in the complete loaded registration set" end
			for _, other in ipairs(registered) do
				local otherRoot = other ~= model and other.Parent and other:IsDescendantOf(workspace) and other:FindFirstChild("Root")
				if otherRoot and otherRoot:IsA("BasePart") and point(otherRoot.Position) and other:GetAttribute("Unlocked") == true
					and (otherRoot.Position - root.Position).Magnitude <= 16 and (otherRoot.Position - root.Position).Magnitude <= record.Distance + 0.05 then
					return false, record, "Another or tied eligible registered original owns native nearest selection: " .. self:InstanceId(other)
				end
			end
		else
			-- Initial trigger closes over this exact cached prompt. Name/count transport
			-- cannot resolve competing simultaneously usable initial prompts safely.
			local prompts, selectedPrompt = self:Get("ProximityPrompt"), prompt:FindFirstChildOfClass("ProximityPrompt")
			for engine, member in pairs(prompts._cache) do
				if member ~= true or engine == selectedPrompt or not engine.Parent or engine.Enabled ~= true then continue end
				local parent, position = engine.Parent, nil
				if parent:IsA("BasePart") then position = parent.Position
				elseif parent:IsA("Attachment") then position = parent.WorldPosition end
				if not point(position) or not PetPolicy.Finite(engine.MaxActivationDistance) or engine.MaxActivationDistance <= 0 then
					return false, record, "Other enabled cached native Prompt geometry unavailable; active initial interaction unresolved"
				end
				if (position - root.Position).Magnitude <= engine.MaxActivationDistance then
					return false, record, "Competing eligible initial Prompt; exact native active prompt unresolved: " .. self:InstanceId(engine)
				end
			end
		end
		return true, record, "NATIVE_INTERACTION_VERIFIED: exact selected registered original; " .. record.InteractionMode
	end)
	return ok and eligible == true, ok and range or nil, ok and reason or "Native interaction observation failed: " .. tostring(eligible)
end

function GameKnowledge:PetContext(snapshot, plan, tracker, retainedModel)
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
	if (self.Reader.Config.EGG_TRAVEL_SETTINGS.MODE or "NORMAL") == "TRAVEL_ONLY" then
		context.EggLocations, context.EggLocationDiagnostics = {}, {}
		local seen = {}
		for _, model in ipairs(self:EggModels()) do
			if seen[model.Name] then continue end seen[model.Name] = true
			local locations, observation = self:EggLocationCandidates(model.Name)
			context.EggLocationDiagnostics[model.Name] = observation
			for _, location in ipairs(locations) do
				location.Name, location.Loaded, location.Accessible = model.Name, true, true
				location.Distance = root and (location.Root.Position - root.Position).Magnitude
				location.Cost = definitions[model.Name].Cost
				table.insert(context.EggLocations, location)
			end
		end
		coverage.PhysicalLocations = #context.EggLocations
	end
	local byName = {}
	context.EggIdentityDiagnostics = {}
	for _, model in ipairs(self:EggModels()) do
		if not model.Parent or not model:IsDescendantOf(workspace) then continue end
		if byName[model.Name] then continue end
		local def = definitions[model.Name]
		local expected = retainedModel and retainedModel.Name == model.Name and retainedModel or nil
		local identity, identityReason, observed = self:ResolveEggInstance(model.Name, false, expected)
		if not identity and not expected and observed and observed.VerifiedCount > 1 then
			-- Reuse Test A's source/access/scene-associated physical selection for
			-- planning. Paid readiness still requires native interaction below; no
			-- name-only nearest substitution or alteration of discovery/movement.
			local physical = self:ResolveEggLocation(model.Name, false, nil, root)
			if physical then identity, identityReason, observed = self:ResolveEggInstance(model.Name, false, physical.Model) end
		end
		context.EggIdentityDiagnostics[model.Name] = observed
		if not identity then
			byName[model.Name] = { Name = model.Name, Loaded = false, Accessible = false, World = def.World, Island = def.Island,
				AccessStatus = "BLOCKED_INSTANCE_IDENTITY", IdentityReason = identityReason, Cost = def.Cost, Reason = identityReason }
			continue
		end
		model = identity.Model
		local part = identity.Root
		local distance = root and (part.Position - root.Position).Magnitude
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
		local nativeRange, observedRange, interactionReason = self:NativeEggRangeEligible({ Model = model }, root)
		local range = observedRange and observedRange.Range or opened and 16 or 6.5
		local access = not world and "UNKNOWN_ACCESS" or (def.Event or def.ProductId or def.IsAdminEgg or model.Name == "Infinity Egg") and "UNSUPPORTED"
			or accessible and "ACCESSIBLE" or "LOCKED_OR_UNKNOWN_UNLOCK"
		local ok, path = pcall(function() return model:GetFullName() end)
		byName[model.Name] = { Name = model.Name, Model = model, IdentityId = identity.IdentityId, IdentityEvidence = identity.IdentityEvidence,
			World = world, Island = island, Distance = distance, Range = range,
			ModelPath = ok and path or nil, Position = part.Position,
			DefinitionCurrency = def.Cost and def.Cost.Type == "Currency" and def.Cost.Currency or nil,
			AccessStatus = access, Loaded = true, Accessible = accessible == true,
			InRange = accessible and world == currentWorld and nativeRange, NativeRangeEligible = nativeRange,
			RangeOrigin = observedRange and observedRange.RangeOrigin, InteractionDistance = observedRange and observedRange.Distance,
			InteractionMode = observedRange and observedRange.InteractionMode, InteractionReason = interactionReason,
			Cost = native(stats, "GetEggCost", self.Reader.Player, detached(profile), model.Name), Pool = pool, Luck = luck,
			Duration = native(stats, "GetHatchDuration", detached(profile)), Opened = opened, Unlocked = model:GetAttribute("Unlocked"),
			Reason = accessible and "Scene-present native egg; account world/island access confirmed" or "Premium/event/special/locked or unknown access; no hatch action" }
	end
	local names = {} for name in pairs(byName) do table.insert(names, name) end table.sort(names)
	coverage.ObservedEggNames, coverage.BlockedIdentityNames = #names, 0
	for _, egg in pairs(byName) do
		if egg.Loaded then coverage.LoadedModels += 1 else coverage.BlockedIdentityNames += 1 end
	end
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

function GameKnowledge:ObserveEggChunker()
	if self.Destroyed or self.EggObservationFinished then return end
	if self.EggObservationDeadline and os.clock() >= self.EggObservationDeadline then
		self.EggObservationFinished = true self:ReleaseChunkerObserver() return
	end
	if self:Get("Chunker") then
		if not self.EggObservationDeadline then
			self.EggObservationDeadline = os.clock() + 5
			-- One bounded observer cleanup, no polling/automation thread.
			task.delay(5, function()
				if not self.Destroyed and not self.EggObservationFinished then self.EggObservationFinished = true self:ReleaseChunkerObserver() end
			end)
		end
		self:EnsureChunkerObserver()
	end
end

function GameKnowledge:EnsureChunkerObserver()
	if self.Destroyed then return nil, "Knowledge observation destroyed" end
	if not self.ChunkerObserver then
		local class = self:Get("Chunker")
		if not class or type(class.Update) ~= "function" then return nil, "Native Chunker dependency unavailable" end
		self.ChunkerClass, self.OriginalChunkerUpdate = class, class.Update
		local original = class.Update
		local observer
		observer = function(chunker, ...)
			-- Observe the real receiver; preserve native Update arguments/results and never choose an action here.
			if not self.Destroyed and self.ChunkerObserver == observer then
				pcall(self.RecordNativeEggUpdate, self, chunker, true)
			end
			local result = table.pack(original(chunker, ...))
			if self.Destroyed or self.ChunkerObserver ~= observer then return table.unpack(result, 1, result.n) end
			-- Reporting only: separate protection prevents diagnostics from changing
			-- the existing registration/pickup observation or native return values.
			local diagnosticOK, diagnosticError = pcall(self.RecordNativeEggUpdate, self, chunker)
			if not diagnosticOK then
				self.EggObserverDiagnosticError = tostring(diagnosticError)
			end
			pcall(function() -- Observation failures must never interrupt the game's Update.
				-- Settings alone are shared; inspect every original after native Update.
				if not self.EggObservationFinished and self.EggObservationDeadline and os.clock() < self.EggObservationDeadline then
					if type(chunker) == "table" and self.NativeEggChunkers then self.NativeEggChunkers[chunker] = nil end
					local valid = classifyObservedEggQueue(chunker, class, self:Get("Eggs"))
					if valid then
						self.NativeEggChunkers = self.NativeEggChunkers or setmetatable({}, { __mode = "k" })
						self.NativeEggChunkers[chunker] = true
					end
				end
				if type(chunker) == "table" and type(chunker.Remove) == "function" and type(chunker.IsValueLoaded) == "function" then
					for _, pickup in pairs(self.CleanupRegistry or {}) do
						if pickup.Parent and pickup.Parent == chunker._folder and chunker:IsValueLoaded(pickup) then
							self.NativePickupChunker = chunker
							if not self.EggObservationDeadline or self.EggObservationFinished then self:ReleaseChunkerObserver() end
							break
						end
					end
				end
			end)
			return table.unpack(result, 1, result.n)
		end
		self.ChunkerObserver = observer
		local ok = pcall(function() class.Update = self.ChunkerObserver end)
		if not ok then self.EggObserverInstallFailure = true self:ReleaseChunkerObserver() return nil, "Native Chunker receiver observation unavailable" end
		self.EggObserverInstalled = true
		self.ChunkerObserverAt = os.clock()
	end
	return true
end

function GameKnowledge:EggDiagnosticId(instance)
	if not instance then return "NONE" end
	-- Physical selection has an existing InstanceId tie order. Diagnostics must
	-- never allocate into that namespace before the Brain observes originals.
	if self.EggDiagnosticIds and self.EggDiagnosticIds[instance] then return self.EggDiagnosticIds[instance] end
	if self.InstanceIds and self.InstanceIds[instance] then return self.InstanceIds[instance] end
	self.EggDiagnosticIds = self.EggDiagnosticIds or setmetatable({}, { __mode = "k" })
	if not self.EggDiagnosticIds[instance] then
		self.EggDiagnosticSequence = (self.EggDiagnosticSequence or 0) + 1
		self.EggDiagnosticIds[instance] = string.format("D%04d", self.EggDiagnosticSequence)
	end
	return self.EggDiagnosticIds[instance]
end

function GameKnowledge:RecordNativeEggUpdate(receiver, entered)
	-- No native method invocation, mutation, registry inference or timer here.
	if self.Destroyed or self.EggObservationFinished or not self.EggObservationDeadline
		or os.clock() >= self.EggObservationDeadline then return end
	self.EggObserverStats = self.EggObserverStats or { UpdateCalls = 0, CompletedUpdates = 0, Receivers = setmetatable({}, { __mode = "k" }), ReceiverCount = 0 }
	local stats = self.EggObserverStats
	if entered then stats.UpdateCalls += 1 return end
	stats.CompletedUpdates += 1
	if type(receiver) ~= "table" then stats.NonTableCalls = (stats.NonTableCalls or 0) + 1 return end
	local row = stats.Receivers[receiver]
	if not row then
		if stats.ReceiverCount >= 64 then stats.LimitExceeded = true return end
		stats.ReceiverCount += 1
		row = { Id = self:EggDiagnosticId(receiver), Calls = 0 }
		stats.Receivers[receiver] = row
	end
	row.Calls += 1
	row.StructureMatched, row.Qualifies, row.Entries, row.CatalogOriginals, row.Sentinels, row.NonCatalogOriginals = false, false, 0, 0, 0, 0
	row.FolderId = self:EggDiagnosticId(receiver._folder)
	local function reject(reason) row.Reason = reason end
	if type(receiver.Remove) ~= "function" then reject("MISSING_REMOVE_INTERFACE") return end
	if type(receiver.IsValueLoaded) ~= "function" then reject("MISSING_IS_VALUE_LOADED_INTERFACE") return end
	if not eggReceiver(receiver) then
		local rendered = workspace:FindFirstChild("Rendered")
		local reasons = {}
		if receiver.Mode ~= "3D" then table.insert(reasons, "MODE=" .. tostring(receiver.Mode)) end
		if receiver._chunkSize ~= 128 then table.insert(reasons, "CHUNK_SIZE=" .. tostring(receiver._chunkSize)) end
		if receiver.RenderDistance ~= 2 then table.insert(reasons, "RENDER_DISTANCE=" .. tostring(receiver.RenderDistance)) end
		if type(receiver._chunks) ~= "table" then table.insert(reasons, "CHUNKS_UNAVAILABLE") end
		if type(receiver._loaded) ~= "table" then table.insert(reasons, "LOADED_UNAVAILABLE") end
		if not rendered or not receiver._folder or receiver._folder.Parent ~= rendered then table.insert(reasons, "FOLDER_ANCESTRY_UNVERIFIED") end
		reject(table.concat(reasons, ",")) return
	end
	row.StructureMatched = true
	local definitions = self:Get("Eggs")
	row.EggDefinitionsReady = type(definitions) == "table"
	definitions = definitions or {}
	local coordinates = 0
	for coord, values in pairs(receiver._chunks) do
		coordinates += 1
		if coordinates > 1000 then reject("COORDINATE_LIMIT_EXCEEDED") return end
		if type(values) ~= "table" then reject("CHUNK_VALUES_NOT_TABLE; coord=" .. tostring(coord)) return end
		for _, value in pairs(values) do
			row.Entries += 1
			local suffix = "; coord=" .. tostring(coord) .. "; loaded=" .. tostring(receiver._loaded[coord])
			if row.Entries > 1000 then reject("ENTRY_LIMIT_EXCEEDED" .. suffix) return end
			if typeof(value) ~= "Instance" then reject("ENTRY_NOT_INSTANCE" .. suffix) return end
			suffix ..= "; instance=" .. self:EggDiagnosticId(value) .. "; name=" .. tostring(value.Name)
			local shapeOK, root = pcall(eggParts, value)
			if not shapeOK then reject("ORIGINAL_INTERFACE_READ_FAILED: " .. tostring(root) .. suffix) return end
			if not root then
				local missing = {}
				if not value:IsA("Model") then table.insert(missing, "NOT_MODEL")
				else
					for _, name in ipairs({ "Root", "Prompt" }) do
						local part = value:FindFirstChild(name)
						if not part then table.insert(missing, name .. "_ABSENT")
						elseif part.Parent ~= value then table.insert(missing, name .. "_PARENT_MISMATCH")
						elseif not part:IsA("BasePart") then table.insert(missing, name .. "_NOT_BASEPART")
						elseif not point(part.Position) then table.insert(missing, name .. "_POSITION_NONFINITE_OR_ABSENT") end
					end
					for _, name in ipairs({ "Plate", "Cost" }) do if not value:FindFirstChild(name) then table.insert(missing, name .. "_ABSENT") end end
				end
				reject("ORIGINAL_INTERFACE_OR_GEOMETRY_INCOMPLETE: " .. table.concat(missing, ",") .. suffix) return
			end
			if definitions[value.Name] then row.CatalogOriginals += 1
			elseif value.Name == "Coming Soon" then row.Sentinels += 1
			else row.NonCatalogOriginals += 1 end
		end
	end
	row.Qualifies, row.Reason = classifyObservedEggQueue(receiver, self:Get("Chunker"), self:Get("Eggs"))
end

function GameKnowledge:ReadObservedEggReceiver(receiver, selectedModel, otherOriginals)
	-- Inventory of a captured receiver, including rejected receivers. These raw
	-- facts are never added to NativeEggChunkers and cannot authorize a hatch.
	local row = { Id = self:EggDiagnosticId(receiver), Mode = tostring(receiver.Mode), ChunkSize = receiver._chunkSize,
		RenderDistance = receiver.RenderDistance, FolderId = self:EggDiagnosticId(receiver._folder),
		StructureMatched = eggReceiver(receiver) == true, CatalogReady = type(self:Get("Eggs")) == "table",
		ChunkCoordinates = 0, LoadedCoordinates = 0, Values = 0, Instances = 0, Models = 0,
		FullOriginalInterfaces = 0, CatalogOriginals = 0, Sentinels = 0, MissingCatalog = 0,
		SelectedFound = false, SelectedLoaded = false, OtherOriginalsFound = 0,
		OtherOriginalIds = {}, Issues = {}, Examples = {}, InspectionComplete = true }
	local rendered, definitions = workspace:FindFirstChild("Rendered"), self:Get("Eggs") or {}
	row.FolderUnderRendered = receiver._folder ~= nil and rendered ~= nil and receiver._folder.Parent == rendered
	row.FolderParentId = self:EggDiagnosticId(receiver._folder and receiver._folder.Parent)
	row.FolderParentName = receiver._folder and receiver._folder.Parent and receiver._folder.Parent.Name or "ABSENT"
	local class = self:Get("Chunker")
	row.ClassMetatableMatches = type(class) == "table" and getmetatable(receiver) == class
	row.HasOwnUpdate = type(rawget(receiver, "Update")) == "function"
	row.ResolvedUpdateMatchesPublicClass = type(class) == "table" and type(class.Update) == "function" and receiver.Update == class.Update
	row.SelectedParentEqualsFolder = selectedModel ~= nil and receiver._folder ~= nil and selectedModel.Parent == receiver._folder
	local issueCounts, otherSeen = {}, {}
	local function issue(kind, example)
		issueCounts[kind] = (issueCounts[kind] or 0) + 1
		if example and #row.Examples < 2 then table.insert(row.Examples, kind .. ":" .. example) end
	end
	if type(receiver.Remove) ~= "function" then issue("REMOVE_INTERFACE_UNAVAILABLE") end
	if type(receiver.IsValueLoaded) ~= "function" then issue("IS_VALUE_LOADED_INTERFACE_UNAVAILABLE") end
	if not row.StructureMatched then issue("STRUCTURE_MISMATCH") end
	if type(receiver._loaded) ~= "table" then issue("LOADED_COORDINATES_UNAVAILABLE") row.InspectionComplete = false
	else
		for coord, loaded in pairs(receiver._loaded) do
			row.LoadedCoordinates += 1
			if row.LoadedCoordinates > 1000 then issue("LOADED_COORDINATE_LIMIT") row.InspectionComplete = false break end
			if loaded ~= true then issue("LOADED_FLAG_INCONSISTENT") end
			if type(receiver._chunks) == "table" and receiver._chunks[coord] == nil then row.EmptyLoadedCoordinates = (row.EmptyLoadedCoordinates or 0) + 1 end
		end
	end
	if type(receiver._chunks) ~= "table" then issue("CHUNKS_UNAVAILABLE") row.InspectionComplete = false
	else
		for coord, values in pairs(receiver._chunks) do
			row.ChunkCoordinates += 1
			if row.ChunkCoordinates > 1000 then issue("CHUNK_COORDINATE_LIMIT") row.InspectionComplete = false break end
			local loaded = type(receiver._loaded) == "table" and receiver._loaded[coord]
			if type(values) ~= "table" then issue("CHUNK_VALUES_NOT_TABLE", "coord=" .. tostring(coord)) row.InspectionComplete = false continue end
			for index, value in pairs(values) do
				row.Values += 1
				if row.Values > 1000 then issue("VALUE_LIMIT") row.InspectionComplete = false break end
				if value == selectedModel and selectedModel ~= nil then
					row.SelectedFound = true
					if loaded == true and value.Parent == receiver._folder then row.SelectedLoaded = true end
				end
				if otherOriginals[value] and not otherSeen[value] then
					otherSeen[value] = true row.OtherOriginalsFound += 1
					table.insert(row.OtherOriginalIds, self.InstanceIds and self.InstanceIds[value] or self:EggDiagnosticId(value))
				end
				local suffix = "coord=" .. tostring(coord) .. "; loaded=" .. tostring(loaded)
				if type(index) ~= "number" or index < 1 or index % 1 ~= 0 then issue("UNSUPPORTED_MEMBER_KEY", suffix) end
				if typeof(value) ~= "Instance" then issue("NON_INSTANCE_CONTENT", suffix) continue end
				row.Instances += 1
				if not value:IsA("Model") then issue("NON_MODEL_CONTENT", suffix) continue end
				row.Models += 1
				local ok, root = pcall(eggParts, value)
				if not ok then issue("ORIGINAL_INTERFACE_READ_FAILED", suffix) row.InspectionComplete = false continue end
				if not root then issue("NON_ORIGINAL_OR_INCOMPLETE_INTERFACE", suffix) continue end
				row.FullOriginalInterfaces += 1
				if definitions[value.Name] then row.CatalogOriginals += 1
				elseif value.Name == "Coming Soon" then row.Sentinels += 1
				else
					row.MissingCatalog += 1
					issue(row.CatalogReady and "MISSING_CATALOG_DEFINITION" or "CATALOG_NOT_READY",
						"name=" .. tostring(value.Name) .. "[" .. self:EggDiagnosticId(value) .. "]; " .. suffix)
				end
				if loaded == true and (value.Parent ~= receiver._folder or not value:IsDescendantOf(workspace)) then issue("LOADED_MEMBER_ANCESTRY_INCONSISTENT", suffix) end
			end
			if row.Values > 1000 then break end
		end
	end
	for kind, count in pairs(issueCounts) do table.insert(row.Issues, kind .. "=" .. count) end
	table.sort(row.Issues) table.sort(row.OtherOriginalIds)
	row.ContentSourceCompatible = row.InspectionComplete and row.StructureMatched and row.Values > 0
		and row.Values == row.FullOriginalInterfaces and issueCounts.UNSUPPORTED_MEMBER_KEY == nil
	row.ContentAssessment = row.ContentSourceCompatible and "ORIGINAL_QUEUE_COMPATIBLE; NOT_REGISTRATION_PROOF" or "NON_EGG_OR_INCOMPLETE_CONTENT"
	row.EmptyLoadedCoordinates = row.EmptyLoadedCoordinates or 0
	return row
end

function GameKnowledge:NativeEggRegistrationDiagnostics(selectedModel)
	-- Detached reporting facts only. This method cannot grant identity/eligibility.
	local stats = self.EggObserverStats or {}
	local class = self:Get("Chunker")
	local report = { ModuleLoaded = class ~= nil, DependencyReady = type(class) == "table" and type(class.Update) == "function", Installed = self.EggObserverInstalled == true,
		Active = self.ChunkerObserver ~= nil and self.ChunkerClass ~= nil and self.ChunkerClass.Update == self.ChunkerObserver,
		UpdateCalls = stats.UpdateCalls or 0, CompletedUpdates = stats.CompletedUpdates or 0, CandidateReceivers = stats.ReceiverCount or 0,
		StructureMatched = 0, RejectedReceivers = 0, QualifyingReceivers = 0, Receivers = {},
		SelectedFound = false, SelectedLoaded = false, SelectedObservedFound = false, ReceiverChanged = false }
	for receiver, row in pairs(stats.Receivers or {}) do
		if row.StructureMatched then report.StructureMatched += 1 end
		if not row.Qualifies then report.RejectedReceivers += 1 end
		table.insert(report.Receivers, table.clone(row))
		if row.Qualifies and not eggReceiver(receiver) then report.ReceiverChanged = true end
	end
	table.sort(report.Receivers, function(a, b) return a.Id < b.Id end)
	local entries, coordinates = 0, 0
	local selectedRoot, selectedPrompt
	if selectedModel then selectedRoot, selectedPrompt = eggParts(selectedModel) end
	report.SelectedGeometryAvailable = selectedRoot ~= nil and selectedPrompt ~= nil
	local receiverEntries = 0
	for receiver in pairs(self.NativeEggChunkers or {}) do
		receiverEntries += 1
		if receiverEntries > 64 then report.LimitExceeded = true break end
		if not eggReceiver(receiver) then report.ReceiverChanged = true continue end
		report.QualifyingReceivers += 1
		for coord, values in pairs(receiver._chunks) do
			coordinates += 1
			if coordinates > 1000 then report.LimitExceeded = true break end
			if type(values) ~= "table" then report.ReceiverChanged = true continue end
			for _, value in pairs(values) do
				entries += 1
				if entries > 1000 then report.LimitExceeded = true break end
				if selectedModel and value == selectedModel then
					report.SelectedFound = true
					if receiver._loaded[coord] == true and value.Parent == receiver._folder then
						report.SelectedLoaded = true
						-- Match the separately approved exact-value membership repair.
						-- Reporting stays read-only and cannot allocate physical IDs.
						if report.SelectedGeometryAvailable and selectedModel:IsDescendantOf(workspace) then report.SelectedObservedFound = true end
					end
				end
			end
			if report.LimitExceeded then break end
		end
		if report.LimitExceeded then break end
	end
	if selectedModel then
		report.SelectedDiagnosticId = self:EggDiagnosticId(selectedModel)
		report.SelectedInstanceId = self.InstanceIds and self.InstanceIds[selectedModel] or report.SelectedDiagnosticId
		report.SelectedObservationReason = report.SelectedGeometryAvailable and "ORIGINAL_INTERFACE_PRESENT" or "ORIGINAL_INTERFACE_OR_GEOMETRY_INCOMPLETE"
		local originals, excluded = {}, 0
		local prompts = self:Get("ProximityPrompt")
		for modelIndex, model in ipairs(self.NativeEggModels or {}) do
			if modelIndex > 1000 then report.LimitExceeded = true break end
			if model.Name ~= selectedModel.Name then continue end
			local root, prompt = eggParts(model)
			if not root then excluded += 1 continue end
			local engine = prompt:FindFirstChildOfClass("ProximityPrompt")
			local diagnosticId = self:EggDiagnosticId(model)
			table.insert(originals, { InstanceId = self.InstanceIds and self.InstanceIds[model] or diagnosticId, DiagnosticId = diagnosticId, Selected = model == selectedModel,
				ParentId = self:EggDiagnosticId(model.Parent), Root = root.Position, Prompt = prompt.Position,
				PromptCacheMember = engine ~= nil and type(prompts) == "table" and type(prompts._cache) == "table" and prompts._cache[engine] == true,
				RegisteredReceivers = model == selectedModel and (report.SelectedObservedFound and 1 or 0) or nil })
		end
		table.sort(originals, function(a, b) if a.Selected ~= b.Selected then return a.Selected end return a.InstanceId < b.InstanceId end)
		report.PhysicalOriginals, report.ExcludedRepresentations, report.Originals = #originals, excluded, originals
	end
	local reason
	if self.Destroyed then reason = "OBSERVER_DESTROYED"
	elseif not report.ModuleLoaded then reason = "CHUNKER_DEPENDENCY_UNAVAILABLE"
	elseif not report.DependencyReady then reason = "CHUNKER_UPDATE_INTERFACE_UNAVAILABLE"
	elseif self.EggObserverInstallFailure then reason = "OBSERVER_INSTALL_FAILED"
	elseif not report.Installed and not self.NativeEggChunkers then reason = "OBSERVER_NOT_INSTALLED"
	elseif stats.LimitExceeded or report.LimitExceeded then reason = "READ_ONLY_DIAGNOSTIC_LIMIT_EXCEEDED"
	elseif self.EggObserverDiagnosticError then reason = "READ_ONLY_DIAGNOSTIC_ERROR: " .. self.EggObserverDiagnosticError
	elseif report.ReceiverChanged then reason = "OBSERVED_RECEIVER_STRUCTURE_CHANGED"
	elseif report.QualifyingReceivers > 1 then reason = "MULTIPLE_QUALIFYING_EGG_RECEIVERS"
	elseif report.QualifyingReceivers == 0 then
		if report.UpdateCalls == 0 then reason = self.EggObservationFinished and "TIMED_OUT_BEFORE_ANY_NATIVE_UPDATE" or "WAITING_FOR_NATIVE_UPDATE"
		elseif report.CompletedUpdates == 0 then reason = "NATIVE_UPDATE_ENTERED_WITHOUT_COMPLETED_OBSERVATION"
		else reason = self.EggObservationFinished and "TIMED_OUT_WITHOUT_QUALIFYING_EGG_RECEIVER" or "NATIVE_UPDATES_OBSERVED_NO_QUALIFYING_EGG_RECEIVER" end
	elseif selectedModel and not selectedModel.Parent then reason = "SELECTED_INSTANCE_UNLOADED"
	elseif selectedModel and not report.SelectedFound then reason = "SELECTED_EXACT_INSTANCE_ABSENT_FROM_OBSERVED_CHUNKS"
	elseif selectedModel and not report.SelectedLoaded then reason = "SELECTED_EXACT_INSTANCE_COORDINATE_UNLOADED_OR_ANCESTRY_CHANGED"
	elseif selectedModel and not report.SelectedGeometryAvailable then reason = "SELECTED_ORIGINAL_GEOMETRY_CHANGED: " .. tostring(report.SelectedObservationReason)
	else reason = self.EggObservationFinished and "CURRENT_EXACT_REGISTRATION_OBSERVED" or "REGISTRATION_OBSERVED_WINDOW_STILL_OPEN" end
	report.Stage, report.Reason = reason, reason
	local rejections = {}
	for _, row in ipairs(report.Receivers) do if not row.Qualifies then table.insert(rejections, row.Id .. ":" .. tostring(row.Reason)) end end
	if #rejections > 0 then report.Reason ..= "; rejected={" .. table.concat(rejections, " | ") .. "}" end
	report.Summary = string.format("registration=%s; dependency=%s; installed=%s; active=%s; native Updates=%d; completed=%d; receivers=%d; 3D structure=%d; rejected=%d; qualifying=%d; exact selected in chunks=%s; selected loaded=%s; protected membership=%s",
		report.Stage, tostring(report.DependencyReady), tostring(report.Installed), tostring(report.Active), report.UpdateCalls, report.CompletedUpdates, report.CandidateReceivers,
		report.StructureMatched, report.RejectedReceivers, report.QualifyingReceivers, tostring(report.SelectedFound), tostring(report.SelectedLoaded), tostring(report.SelectedObservedFound))
	if report.Originals then
		local rows = {}
		local function position(v) return string.format("(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z) end
		for i, original in ipairs(report.Originals) do
			if i > 4 then break end
			local label = original.InstanceId .. (original.DiagnosticId ~= original.InstanceId and "[" .. original.DiagnosticId .. "]" or "")
			table.insert(rows, string.format("%s%s parent=%s Root=%s Prompt=%s cached=%s protected selected membership=%s", label,
				original.Selected and " SELECTED" or "", original.ParentId, position(original.Root), position(original.Prompt),
				tostring(original.PromptCacheMember == true), tostring(original.RegisteredReceivers or "not checked")))
		end
		report.Summary ..= string.format("; original-shaped=%d; excluded representations=%d | %s", report.PhysicalOriginals, report.ExcludedRepresentations, table.concat(rows, " | "))
	end
	-- Search ALL captured receivers independently of acceptance. The old trusted
	-- SelectedFound field stays scoped to accepted registration and is not proof
	-- that a selected original was absent from rejected receivers.
	local otherOriginals, cachedCount = {}, 0
	for _, model in ipairs(self.NativeEggModels or {}) do
		cachedCount += 1
		if cachedCount > 1000 then break end
		if selectedModel and model ~= selectedModel and model.Name == selectedModel.Name and model.Parent
			and model:IsDescendantOf(workspace) and eggParts(model) then otherOriginals[model] = true end
	end
	report.CapturedReceivers, report.CapturedSelectedFound, report.CapturedOtherOriginalFound = {}, false, false
	report.FullCandidateInspectionComplete = cachedCount <= 1000 and not stats.LimitExceeded and report.UpdateCalls == report.CompletedUpdates
	report.ReceiverObservationComplete = self.EggObservationFinished == true
	local available, structural, otherSeen = 0, 0, {}
	for receiver, observed in pairs(stats.Receivers or {}) do
		available += 1
		if available > 64 then report.FullCandidateInspectionComplete = false break end
		local ok, row = pcall(self.ReadObservedEggReceiver, self, receiver, selectedModel, otherOriginals)
		if not ok then
			row = { Id = observed.Id, InspectionComplete = false, Issues = { "RECEIVER_READ_FAILED" },
				Examples = { tostring(row) }, OtherOriginalIds = {}, SelectedFound = false, SelectedLoaded = false }
		end
		row.LastObserverReason, row.LastObserverQualified, row.ObservedCalls = observed.Reason, observed.Qualifies == true, observed.Calls
		row.AcceptedReceiver = self.NativeEggChunkers ~= nil and self.NativeEggChunkers[receiver] == true
		if not row.InspectionComplete then report.FullCandidateInspectionComplete = false end
		if row.StructureMatched then structural += 1 end
		if row.SelectedFound then report.CapturedSelectedFound = true end
		for _, id in ipairs(row.OtherOriginalIds) do otherSeen[id] = true report.CapturedOtherOriginalFound = true end
		table.insert(report.CapturedReceivers, row)
	end
	report.CurrentCandidateReceiversCount = #report.CapturedReceivers
	if report.CurrentCandidateReceiversCount < report.CandidateReceivers then report.FullCandidateInspectionComplete = false end
	report.OtherOriginalsFound = 0 for _ in pairs(otherSeen) do report.OtherOriginalsFound += 1 end
	table.sort(report.CapturedReceivers, function(a, b) return a.Id < b.Id end)
	local rawSelected = report.CapturedSelectedFound and "true" or report.FullCandidateInspectionComplete and "false" or "UNKNOWN"
	local rawOther = report.CapturedOtherOriginalFound and "true" or report.FullCandidateInspectionComplete and "false" or "UNKNOWN"
	report.CapturedSelectedPresence = rawSelected
	report.CapturedOtherOriginalPresence = rawOther
	local attribution = report.SelectedFound and report.QualifyingReceivers == 1 and "SOURCE_MATCHING_ACCEPTED_RECEIVER_OBSERVED" or "UNVERIFIED"
	report.ReceiverUpdateAttribution = attribution
	report.ReceiverObservationSummary = string.format("NATIVE_EGG_RECEIVER_OBSERVATION | Updates observed=%d; completed=%d; candidate receivers=%d; currently inspectable=%d; structurally compatible=%d; exact selected in ANY captured=%s; exact other original in ANY captured=%s; qualifying=%d; trusted selected in accepted=%s; observation complete=%s; full inspection=%s; excluded representations=%s; egg receiver Update attribution=%s",
		report.UpdateCalls, report.CompletedUpdates, report.CandidateReceivers, report.CurrentCandidateReceiversCount, structural, rawSelected, rawOther,
		report.QualifyingReceivers, tostring(report.SelectedObservedFound), tostring(report.ReceiverObservationComplete), tostring(report.FullCandidateInspectionComplete), tostring(report.ExcludedRepresentations or "UNKNOWN"), attribution)
	local lines, keys = {}, { tostring(report.ReceiverObservationComplete), tostring(report.FullCandidateInspectionComplete), rawSelected, rawOther, tostring(report.QualifyingReceivers) }
	for index, row in ipairs(report.CapturedReceivers) do
		local issues = table.concat(row.Issues or {}, ",")
		table.insert(keys, table.concat({ row.Id, tostring(row.FolderId), tostring(row.Mode), tostring(row.ChunkSize), tostring(row.RenderDistance),
			tostring(row.CatalogReady), tostring(row.SelectedFound), tostring(row.SelectedLoaded), tostring(row.SelectedParentEqualsFolder),
			tostring(row.OtherOriginalsFound), tostring(row.AcceptedReceiver), tostring(row.ClassMetatableMatches), tostring(row.HasOwnUpdate),
			tostring(row.ResolvedUpdateMatchesPublicClass), issues:gsub("=%d+", "") }, ":"))
		if index > 6 then continue end
		table.insert(lines, string.format("%s | mode=%s; chunk=%s; render=%s; folder=%s; parent=%s[%s]; under Rendered=%s; selected parent equals folder=%s; class metatable=%s; own Update=%s; resolved public Update=%s; coords=%s; loaded coords=%s; empty loaded=%s; values=%s; Instances=%s; Models=%s; full originals=%s; catalog=%s; sentinel=%s; missing catalog=%s; selected present=%s; selected loaded=%s; other originals=%s; accepted=%s | current issues={%s}; last native rejection=%s; examples={%s}",
			row.Id, tostring(row.Mode), tostring(row.ChunkSize), tostring(row.RenderDistance), tostring(row.FolderId), tostring(row.FolderParentName),
			tostring(row.FolderParentId), tostring(row.FolderUnderRendered), tostring(row.SelectedParentEqualsFolder), tostring(row.ClassMetatableMatches),
			tostring(row.HasOwnUpdate), tostring(row.ResolvedUpdateMatchesPublicClass), tostring(row.ChunkCoordinates), tostring(row.LoadedCoordinates),
			tostring(row.EmptyLoadedCoordinates), tostring(row.Values), tostring(row.Instances),
			tostring(row.Models), tostring(row.FullOriginalInterfaces), tostring(row.CatalogOriginals), tostring(row.Sentinels), tostring(row.MissingCatalog),
			tostring(row.SelectedFound), tostring(row.SelectedLoaded), tostring(row.OtherOriginalsFound), tostring(row.AcceptedReceiver), issues,
			tostring(row.LastObserverReason), table.concat(row.Examples or {}, " | ")))
	end
	report.ReceiverObservationSummary ..= "\n" .. table.concat(lines, "\n")
	report.ReceiverObservationKey = table.concat(keys, "|")
	report.Summary = report.Summary:gsub("exact selected in chunks=", "exact selected in ACCEPTED chunks=")
	return report
end

function GameKnowledge:PickupChunker()
	if self.NativePickupChunker then return self.NativePickupChunker end
	if self.ChunkerObserver and os.clock() - self.ChunkerObserverAt >= 5 then
		self:ReleaseChunkerObserver() self.ChunkerRetryAt = os.clock() + 5
	end
	if os.clock() < (self.ChunkerRetryAt or 0) then return nil, "Native pickup Chunker observation is in backoff" end
	local registry = self:ActivePickups()
	if not registry then return nil, "Native pickup registry dependency unavailable" end
	local ok, reason = self:EnsureChunkerObserver()
	if not ok then return nil, reason end
	self.CleanupRegistry = registry
	return nil, "Waiting for native pickup Chunker receiver; no request or visual mutation yet"
end

function GameKnowledge:Destroy()
	self.Destroyed, self.EggObservationFinished = true, true
	self:ReleaseChunkerObserver() self.NativePickupChunker, self.NativeEggChunkers = nil, nil
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

-- PHASE5_READ_ONLY_MASTERY_BEGIN
-- A detached observation for advisory planning. No request, claim, or scheduler task is emitted.
function GameKnowledge:MasteryContext(snapshot, now, settings)
	settings = settings or {}
	local startedAt = os.clock()
	local function finite(value)
		return type(value) == "number" and value == value and value >= 0 and value < math.huge
	end
	local function equal(left, right, seen)
		if type(left) ~= type(right) then return false end
		if type(left) ~= "table" then return left == right end
		seen = seen or {}
		if seen[left] == right then return true end
		seen[left] = right
		for key, value in pairs(left) do if not equal(value, right[key], seen) then return false end end
		for key in pairs(right) do if left[key] == nil then return false end end
		return true
	end
	local context = { Catalog = {}, Account = nil, Snapshot = type(snapshot) == "table" and detached(snapshot) or {},
		ObservedAt = now, Fresh = false, CategoryObservations = {}, TierObservations = {}, Balances = {},
		EffectiveUpgrades = type(snapshot) == "table" and snapshot.Upgrades and detached(snapshot.Upgrades.MasteryUpgrades) or nil,
		Access = { Visibility = "UNKNOWN", PhysicalEligibility = "UNKNOWN", ServerEligibility = "UNKNOWN",
			Reason = "Received AreasUnlocked unavailable; physical/server purchase requirements unverified" },
		AccessState = "UNKNOWN", TradingPlazaStatus = "UNKNOWN",
		Evidence = "Shared.Data.Mastery.Upgrades; Client.Gui.Frames.Mastery:257,539-568; ClientScript:2010",
		ActionsEnabled = false }
	local function block(reason)
		context.Fresh, context.Blocker = false, reason
		return context
	end
	if self.Destroyed or type(snapshot) ~= "table" or snapshot.Ready ~= true then return block("Ready account snapshot unavailable") end
	local maximumAge = settings.MAXIMUM_ACCOUNT_AGE_SECONDS or 10
	if not finite(now) or not finite(snapshot.ReadAt) or not finite(maximumAge)
		or now < snapshot.ReadAt or now - snapshot.ReadAt > maximumAge then return block("Account snapshot is stale or its age is unknown") end
	if not finite(snapshot.Revision) or snapshot.Revision % 1 ~= 0 or snapshot.Revision ~= self.Reader.Revision then
		return block("Account snapshot revision differs from the current reader revision")
	end
	local current = self.Reader:GetSnapshot()
	if type(current) ~= "table" or current.Revision ~= snapshot.Revision then return block("Current account snapshot revision unavailable or changed") end
	local identity = snapshot.Identity and snapshot.Identity.UserId
	local player = self.Reader.Player
	if not finite(identity) or identity <= 0 or identity % 1 ~= 0 or not player or player.UserId ~= identity then
		return block("Snapshot account identity differs from the actual reader player or is unavailable")
	end
	context.AccountId = identity
	local raw = self.Reader:GetLiveProfile()
	if type(raw) ~= "table" then return block("Ready native LocalData profile unavailable") end
	local account = detached(raw)
	context.Account = account
	local function matchesSnapshot(profile)
		local upgrades = snapshot.Upgrades or {}
		if not equal(upgrades.MasteryLevels, profile.MasteryLevels) or not equal(upgrades.MasteryUpgrades, profile.MasteryUpgrades)
			or not equal(snapshot.UnlockedIslands, profile.AreasUnlocked) or not equal(snapshot.UnlockedWorlds, profile.WorldsUnlocked) then return false end
		for currency, balance in pairs(snapshot.Balances or {}) do if balance ~= profile[currency] then return false end end
		return true
	end
	if not matchesSnapshot(account) then return block("Snapshot Mastery, unlock, or currency facts differ from live LocalData") end
	local catalog = self:Get("Mastery")
	if type(catalog) ~= "table" or type(catalog.Upgrades) ~= "table" then return block("Native Mastery.Upgrades catalog unavailable") end
	context.Catalog = detached(catalog.Upgrades)
	local areas = snapshot.UnlockedIslands
	if type(areas) == "table" then
		context.Access.Visibility = areas["Outer Space"] ~= nil and "VISIBLE" or "LOCKED"
		context.Access.Reason = areas["Outer Space"] ~= nil and "Received AreasUnlocked[Outer Space] entry is present; native HUD prerequisite observed"
			or "Native Mastery HUD requires an AreasUnlocked[Outer Space] entry"
	end
	local plaza = self:Get("IsTradingPlaza")
	if type(plaza) == "function" then
		local ok, value = pcall(plaza)
		if ok and type(value) == "boolean" then
			context.TradingPlazaStatus = value and "ACTIVE" or "INACTIVE"
			if value then context.Access.Visibility, context.Access.Reason = "LOCKED", "Native Mastery HUD is unavailable in Trading Plaza" end
		end
	end
	context.AccessState = context.Access.Visibility
	local currencies = {}
	for currency in pairs(snapshot.Balances or {}) do currencies[currency] = true end
	local levels = snapshot.Upgrades and snapshot.Upgrades.MasteryLevels
	-- Permanent scope is established by the completed native catalog audit, not visibility or Config order.
	local permanent = { Pets = true, Buffs = true, Shops = true, Minigames = true, Rifts = true }
	for name, definition in pairs(context.Catalog) do
		if type(name) ~= "string" or type(definition) ~= "table" then continue end
		local observation = { Visibility = "VISIBLE", VisibilityReason = "Native optional ShouldShow predicate is absent",
			PrerequisiteReason = context.Access.Reason, EarlyUnlockStatus = "UNKNOWN", PriceStatus = "UNKNOWN",
			Permanence = permanent[name] and "VERIFIED_PERMANENT" or "UNKNOWN",
			PermanenceEvidence = "Completed native MASTERY_AND_UPGRADES.md:40; an unreviewed visible category is not assumed permanent" }
		context.CategoryObservations[name] = observation
		if definition.ShouldShow ~= nil then
			if type(definition.ShouldShow) == "function" then
				local ok, shown = pcall(definition.ShouldShow, detached(account))
				if ok and type(shown) == "boolean" then
					observation.Visibility = shown and "VISIBLE" or "LOCKED"
					observation.VisibilityReason = shown and "Native ShouldShow returned true" or "Native ShouldShow returned false"
				else observation.Visibility, observation.VisibilityReason = "UNKNOWN", "Native ShouldShow failed or returned an unsupported result" end
			else observation.Visibility, observation.VisibilityReason = "UNKNOWN", "Native ShouldShow interface is not callable" end
		end
		local tierObservations = {}
		context.TierObservations[name] = tierObservations
		for index, level in pairs(type(definition.Levels) == "table" and definition.Levels or {}) do
			if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or type(level) ~= "table" then continue end
			local tier = { EarlyUnlock = false, EarlyUnlockStatus = "OBSERVED", PriceStatus = "UNKNOWN",
				PriceReason = "Native fixed item Cost unavailable; callable costs are not a verified Mastery contract" }
			tierObservations[index] = tier
			if level.UnlockEarly ~= nil then
				if type(level.UnlockEarly) == "function" then
					local ok, early = pcall(level.UnlockEarly, detached(account))
					if ok and type(early) == "boolean" then tier.EarlyUnlock = early
					else tier.EarlyUnlock, tier.EarlyUnlockStatus = nil, "UNKNOWN" end
				else tier.EarlyUnlock, tier.EarlyUnlockStatus = nil, "UNKNOWN" end
			end
			if tier.EarlyUnlock == true then
				tier.NativePrice, tier.PriceStatus, tier.PriceReason = { Type = "Currency", Currency = "Coins", Amount = 0 }, "OBSERVED", "Native UnlockEarly returned true; native UI substitutes zero Coins"
			elseif tier.EarlyUnlockStatus == "UNKNOWN" then
				tier.PriceReason = "Native early-unlock predicate unavailable; effective price is unknown"
			elseif type(level.Cost) == "table" then
				tier.NativePrice, tier.PriceStatus, tier.PriceReason = detached(level.Cost), "OBSERVED", "Observed native fixed tier Cost"
			end
			if type(level.Cost) == "table" and type(level.Cost.Currency) == "string" then currencies[level.Cost.Currency] = true end
			if tier.NativePrice and type(tier.NativePrice.Currency) == "string" then currencies[tier.NativePrice.Currency] = true end
		end
		local currentLevel = type(levels) == "table" and levels[name] or nil
		local nextTier = finite(currentLevel) and currentLevel % 1 == 0 and tierObservations[currentLevel + 1]
		if nextTier then
			for key, value in pairs(nextTier) do observation[key] = detached(value) end
		else observation.PriceReason = "Actual next tier unavailable; missing category levels are not inferred as zero" end
	end
	for currency in pairs(currencies) do if finite(account[currency]) then context.Balances[currency] = account[currency] end end
	local final = self.Reader:GetLiveProfile()
	local finalSnapshot = self.Reader:GetSnapshot()
	if self.Destroyed or self.Reader.Revision ~= snapshot.Revision or type(finalSnapshot) ~= "table" or finalSnapshot.Revision ~= snapshot.Revision
		or self.Reader.Player ~= player or player.UserId ~= identity or type(final) ~= "table" or not matchesSnapshot(final) then
		return block("Account identity, revision, Mastery, unlock, or balance facts changed during native observation")
	end
	for _, field in ipairs({ "MasteryLevels", "MasteryUpgrades", "AreasUnlocked", "WorldsUnlocked", "OGData" }) do
		if not equal(account[field], final[field]) then return block("Native account prerequisite facts changed during observation") end
	end
	for currency in pairs(currencies) do if account[currency] ~= final[currency] then return block("Relevant native currency balance changed during observation") end end
	local finalCatalog = self:Get("Mastery")
	if type(finalCatalog) ~= "table" or not equal(context.Catalog, finalCatalog.Upgrades) then return block("Native Mastery definitions changed during observation") end
	context.CompletedAt = now + math.max(0, os.clock() - startedAt)
	if context.CompletedAt - snapshot.ReadAt > maximumAge then return block("Account snapshot became stale during native observation") end
	context.Fresh = true
	return context
end
-- PHASE5_READ_ONLY_MASTERY_END
-- PHASE5_READ_ONLY_REWARDS_BEGIN
-- Detached received facts and reviewed pure native getters only. No reward action is prepared.
function GameKnowledge:RewardContext(snapshot, now, settings)
	settings = settings or {}
	local startedAt = os.clock()
	local function finite(value)
		return type(value) == "number" and value == value and value >= 0 and value < math.huge
	end
	local function integer(value) return finite(value) and value % 1 == 0 end
	local function copy(value, seen)
		if type(value) ~= "table" then return value end
		seen = seen or {}
		if seen[value] then return seen[value] end
		local result = {} seen[value] = result
		for key, entry in pairs(value) do result[key] = copy(entry, seen) end
		return result
	end
	local function equal(left, right, seen)
		if type(left) ~= type(right) then return false end
		if type(left) ~= "table" then return left == right end
		seen = seen or {}
		if seen[left] == right then return true end
		seen[left] = right
		for key, value in pairs(left) do if not equal(value, right[key], seen) then return false end end
		for key in pairs(right) do if left[key] == nil then return false end end
		return true
	end
	local context = { Fresh = false, ObservedAt = now, Catalogs = {}, Balances = {}, Diagnostics = {},
		QuestObservations = {}, PrizeObservations = {}, ChestObservations = {}, WorldRewardObservations = {},
		InventoryObservations = { Powerups = {}, Potions = {}, Items = {}, SchemaState = "UNKNOWN" },
		TradingPlazaStatus = "UNKNOWN", WheelQueueState = "UNKNOWN", ActionsEnabled = false,
		Evidence = "Completed REWARDS_QUESTS_AND_EVENTS.md; SHOPS_QUESTS_AND_CONSUMABLES.md; DATA_SCHEMAS.md; native client eligibility is not server permission" }
	local function block(reason) context.Fresh, context.Blocker = false, reason return context end
	local reader = self.Reader
	if self.Destroyed or not reader or reader.Destroyed or type(snapshot) ~= "table" or snapshot.Ready ~= true then
		return block("Ready received account snapshot unavailable")
	end
	local maximumAge = settings.MAXIMUM_ACCOUNT_AGE_SECONDS or 10
	if not finite(now) or not finite(snapshot.ReadAt) or not finite(maximumAge)
		or now < snapshot.ReadAt or now - snapshot.ReadAt > maximumAge then
		return block("Reward account snapshot is stale or its age is unknown")
	end
	if not integer(snapshot.Revision) or snapshot.Revision ~= reader.Revision then
		return block("Reward snapshot revision differs from the current reader revision")
	end
	local current, player = reader:GetSnapshot(), reader.Player
	local identity = snapshot.Identity and snapshot.Identity.UserId
	if type(current) ~= "table" or current.Ready ~= true or current.Revision ~= snapshot.Revision
		or not integer(identity) or identity < 1 or not player or player.UserId ~= identity then
		return block("Reward account identity or current ready snapshot is unavailable or changed")
	end
	local raw = reader:GetLiveProfile()
	if type(raw) ~= "table" then return block("Ready native LocalData reward profile unavailable") end
	local account = copy(raw)
	context.Account, context.Raw, context.AccountId = account, account, identity
	context.EffectiveMasteryUpgrades = copy(account.MasteryUpgrades)
	local function matchesSnapshot(profile)
		local upgrades, inventory = snapshot.Upgrades or {}, snapshot.Inventory or {}
		if upgrades.MasteryLevels ~= nil and not equal(upgrades.MasteryLevels, profile.MasteryLevels) then return false end
		if upgrades.MasteryUpgrades ~= nil and not equal(upgrades.MasteryUpgrades, profile.MasteryUpgrades) then return false end
		if snapshot.UnlockedIslands ~= nil and not equal(snapshot.UnlockedIslands, profile.AreasUnlocked) then return false end
		if snapshot.UnlockedWorlds ~= nil and not equal(snapshot.UnlockedWorlds, profile.WorldsUnlocked) then return false end
		for _, field in ipairs({ "Pets", "Powerups", "Potions" }) do
			if inventory[field] ~= nil and not equal(inventory[field], profile[field]) then return false end
		end
		for currency, balance in pairs(snapshot.Balances or {}) do if balance ~= profile[currency] then return false end end
		return true
	end
	if not matchesSnapshot(account) then return block("Snapshot reward prerequisites, inventory, or currency facts differ from live LocalData") end
	local modules, copiedModules = {}, {}
	local definitions = {
		Playtime = "Shared.Data.Playtime", DailyRewards = "Shared.Data.DailyRewards", WorldRewards = "Shared.Data.WorldRewards",
		Chests = "Shared.Data.Chests", Prizes = "Shared.Data.Prizes", Powerups = "Shared.Data.Powerups",
		Potions = "Shared.Data.Potions", WheelSpin = "Shared.Data.WheelSpin", ChallengePass = "Shared.Data.ChallengePass",
		Seasons = "Shared.Data.Seasons", Worlds = "Shared.Data.Worlds", Constants = "Shared.Constants",
		Time = "Shared.Framework.Utilities.Math.Time", IsTradingPlaza = "Shared.Utils.IsTradingPlaza",
		QuestUtil = "Shared.Utils.Stats.QuestUtil", PrizesUtil = "Shared.Utils.PrizesUtil", ItemUtil = "Shared.Utils.Stats.ItemUtil",
		StatsUtil = "Shared.Utils.Stats.StatsUtil",
	}
	for name, path in pairs(definitions) do
		local value = self:Get(name)
		if value == nil and type(reader.Dependencies) == "table" and reader.Dependencies[name] == nil and type(reader._load) == "function" then
			-- The existing cache/lifecycle owns this one nonblocking static dependency request.
			reader:_load(name, path, name == "IsTradingPlaza" and "function" or "table")
			value = self:Get(name)
		end
		if value ~= nil then modules[name], copiedModules[name] = value, copy(value)
		else
			local entry = type(reader.Dependencies) == "table" and reader.Dependencies[name]
			table.insert(context.Diagnostics, name .. ": " .. tostring(entry and entry.Status or "UNAVAILABLE"))
		end
	end
	for _, name in ipairs({ "Playtime", "DailyRewards", "WorldRewards", "Chests", "Prizes", "Powerups", "Potions", "WheelSpin", "ChallengePass", "Seasons", "Worlds" }) do
		context.Catalogs[name] = copy(modules[name])
	end
	local time = modules.Time
	if type(time) == "table" and type(time.now) == "function" then
		local ok, value = pcall(time.now)
		if ok and finite(value) then context.NativeNow = value else table.insert(context.Diagnostics, "Native Time.now unavailable or invalid") end
	end
	if type(time) == "table" and type(time.getAbsoluteDay) == "function" then
		local ok, value = pcall(time.getAbsoluteDay)
		if ok and integer(value) then context.NativeDay = value else table.insert(context.Diagnostics, "Native UTC absolute day unavailable or invalid") end
	end
	if type(modules.IsTradingPlaza) == "function" then
		local ok, value = pcall(modules.IsTradingPlaza)
		if ok and type(value) == "boolean" then
			context.IsTradingPlaza, context.TradingPlazaStatus = value, value and "ACTIVE" or "INACTIVE"
		end
	end
	if type(account.MasteryUpgrades) == "table" then
		local valid, observed = true, false
		for _, upgrade in pairs(account.MasteryUpgrades) do
			if type(upgrade) ~= "table" or type(upgrade.Type) ~= "string" then valid = false
			elseif upgrade.Type == "Playtime" then observed = true end
		end
		if observed then context.HasPlaytime = true elseif valid then context.HasPlaytime = false end
	end
	for currency, value in pairs(snapshot.Balances or {}) do if finite(value) then context.Balances[currency] = value end end
	local currencies = {}
	for _, definition in pairs(type(context.Catalogs.WorldRewards) == "table" and context.Catalogs.WorldRewards or {}) do
		if type(definition) == "table" and type(definition.Currency) == "string" then currencies[definition.Currency] = true end
	end
	for currency in pairs(currencies) do if finite(account[currency]) then context.Balances[currency] = account[currency] end end
	if type(account.DailyRewards) == "table" and finite(account.DailyRewards.Stars) then context.Balances.Stars = account.DailyRewards.Stars end
	local daily = { State = "UNKNOWN", NativeDay = context.NativeDay, Reason = "Explicit received daily day, streak, claim boolean and native day required" }
	context.DailyObservation = daily
	local receivedDaily = account.DailyRewards
	if type(receivedDaily) == "table" and integer(receivedDaily.LastDay) and integer(receivedDaily.LastStreak)
		and receivedDaily.LastStreak >= 1 and type(receivedDaily.Claimed) == "boolean" and integer(context.NativeDay) then
		daily.Observed, daily.Claimed, daily.DayIndex = true, receivedDaily.Claimed, (receivedDaily.LastStreak - 1) % 7 + 1
		local gifts = context.Catalogs.DailyRewards
		daily.DeclaredReward = type(gifts) == "table" and copy(gifts[daily.DayIndex]) or nil
		daily.GrantAssociation = "UNKNOWN: daily catalog gifts are not independently proven to be granted by the Stars claim request"
		if receivedDaily.LastDay < context.NativeDay then
			daily.State, daily.Locked, daily.Due, daily.Reason = "LOCKED", true, false, "Native daily UI reports a lost streak; recovery/rollover is unverified and never simulated"
		elseif receivedDaily.LastDay > context.NativeDay then
			daily.Reason = "Received daily day is ahead of the observed native day"
		elseif receivedDaily.Claimed then
			daily.State, daily.Due, daily.Reason = "CLAIMED", false, "Explicit received daily claim boolean is true for the native day"
		else
			daily.State, daily.Due, daily.Reason = "DUE", true, "Native daily login visibility prerequisites observed; server claim eligibility remains unknown"
		end
		local constants = modules.Constants
		if type(constants) == "table" and finite(constants.DailyRewardsStarsPerDay) and finite(constants.DailyRewardsStarCap) then
			daily.DeclaredStars = math.clamp(receivedDaily.LastStreak * constants.DailyRewardsStarsPerDay, 0, constants.DailyRewardsStarCap)
		end
	end
	local questUtil = modules.QuestUtil
	local seenQuests = {}
	for _, quest in pairs(type(account.Quests) == "table" and account.Quests or {}) do
		if type(quest) ~= "table" or type(quest.Id) ~= "string" or quest.Id == "" then continue end
		if seenQuests[quest.Id] then
			context.QuestObservations[quest.Id] = { State = "UNKNOWN", Reason = "Duplicate received quest identifiers are ambiguous", Tasks = {} }
			continue
		end
		seenQuests[quest.Id] = true
		local observation = { State = "UNKNOWN", Tasks = {}, Reason = "Complete explicit task requirements and progress required" }
		context.QuestObservations[quest.Id] = observation
		if type(quest.Tasks) ~= "table" or type(quest.Progress) ~= "table" then continue end
		local taskCount, completeCount, valid = 0, 0, true
		for index, taskDefinition in pairs(quest.Tasks) do
			if not integer(index) or index < 1 or type(taskDefinition) ~= "table" then valid = false continue end
			taskCount += 1
			local taskObservation = { Current = finite(quest.Progress[index]) and quest.Progress[index] or nil,
				State = "UNKNOWN", Reason = "Native requirement or explicit received progress unavailable" }
			observation.Tasks[index] = taskObservation
			if type(questUtil) == "table" and type(questUtil.GetRequirement) == "function" then
				local ok, required = pcall(questUtil.GetRequirement, questUtil, copy(taskDefinition))
				if ok and finite(required) and required > 0 then taskObservation.Required = required end
			end
			if taskObservation.Required ~= nil and taskObservation.Current ~= nil then
				taskObservation.Complete = taskObservation.Current == taskObservation.Required
				taskObservation.State, taskObservation.Reason = "OBSERVED", "Native QuestUtil exact-equality requirement and received progress observed"
				if taskObservation.Complete then completeCount += 1 end
			else valid = false end
		end
		if taskCount < 1 then valid = false end
		for index = 1, taskCount do if quest.Tasks[index] == nil then valid = false end end
		if valid then
			observation.Complete, observation.State = completeCount == taskCount, "OBSERVED"
			observation.Reason = "Native sequential task shape and exact-equality progress observed; automatic grant/claim timing unverified"
		end
	end
	local prizes, prizeUtil = context.Catalogs.Prizes, modules.PrizesUtil
	for _, prize in pairs(type(prizes) == "table" and type(prizes.data) == "table" and prizes.data or {}) do
		if type(prize) ~= "table" or type(prize.Key) ~= "string" or prize.Key == "" then continue end
		local observation = { Required = finite(prize.Requirement) and prize.Requirement or nil, State = "UNKNOWN",
			Reason = "Native prize progress helper and explicit prerequisite fields required" }
		context.PrizeObservations[prize.Key] = observation
		if type(prizeUtil) == "table" and type(prizeUtil.GetProgress) == "function" and type(prize.Type) == "string" then
			local ok, progress = pcall(prizeUtil.GetProgress, prizeUtil, copy(account), prize.Type)
			if ok and finite(progress) then observation.Progress = progress end
		end
		if observation.Required ~= nil and observation.Progress ~= nil then
			observation.Complete, observation.State = observation.Progress >= observation.Required, "OBSERVED"
			observation.Reason = "Native PrizesUtil progress meets or falls short of the catalog threshold; grant remains unverified"
		end
	end
	local pass, receivedPass = modules.ChallengePass, account.ChallengePass
	local challenge = { State = "UNKNOWN", Reason = "Current native pass identity, deadline, received points and native time required" }
	context.ChallengeObservation = challenge
	if type(pass) == "table" then
		challenge.Id = type(pass.Id) == "string" and pass.Id or nil
		local expiryOK, expiry = pcall(function() return pass.FinishTime and pass.FinishTime.UnixTimestamp end)
		if expiryOK and finite(expiry) then challenge.ExpiryUnix, challenge.Deadline = expiry, expiry end
		if challenge.Id and challenge.ExpiryUnix and finite(context.NativeNow) then
			challenge.Expired = context.NativeNow >= challenge.ExpiryUnix
			challenge.State = challenge.Expired and "EXPIRED" or "ACTIVE"
			challenge.Reason = "Current native catalog deadline compared with native server time; catalog presence alone is not active account availability"
		end
		if type(receivedPass) == "table" and finite(receivedPass.Points) and type(pass.GetTier) == "function" then
			local ok, tier = pcall(pass.GetTier, pass, receivedPass.Points)
			if ok and integer(tier) then challenge.EligibleTier = tier end
		end
	end
	local inventory = context.InventoryObservations
	local itemUtil = modules.ItemUtil
	local function owned(item, prerequisitePresent)
		if not prerequisitePresent or type(itemUtil) ~= "table" or type(itemUtil.GetOwnedAmount) ~= "function" then return nil end
		local ok, amount = pcall(itemUtil.GetOwnedAmount, itemUtil, copy(account), copy(item))
		return ok and integer(amount) and amount or nil
	end
	local function inventoryEntry(item, amount, definition, reason)
		return { Type = item.Type, Name = item.Name, Level = item.Level, Owned = amount, Amount = amount,
			QuantityStatus = amount ~= nil and "OBSERVED" or "UNKNOWN", State = amount ~= nil and "OBSERVED" or "UNKNOWN",
			Item = item, Definition = copy(definition), Reason = reason }
	end
	if type(account.Powerups) == "table" then
		for name, receivedAmount in pairs(account.Powerups) do
			if type(name) ~= "string" then continue end
			local definition = type(context.Catalogs.Powerups) == "table" and context.Catalogs.Powerups[name]
			local item = { Type = "Powerup", Name = name }
			local amount = type(definition) == "table" and owned(item, true) or nil
			if not integer(receivedAmount) or amount ~= receivedAmount then amount = nil end
			inventory.Powerups[name] = inventoryEntry(item, amount, definition,
				"Native ItemUtil agrees with an explicit received Powerups count; missing definitions or disagreement remain unknown; ownership does not authorize use")
			table.insert(inventory.Items, copy(inventory.Powerups[name]))
		end
	end
	if type(account.Potions) == "table" then
		local shapeValid, seenPotions = true, {}
		for _, record in pairs(account.Potions) do
			if type(record) ~= "table" or type(record.Name) ~= "string" or record.Name == ""
				or record.Level ~= nil and (not integer(record.Level) or record.Level < 1) or not integer(record.Amount) then
				shapeValid = false continue
			end
			local key = record.Name .. ":" .. tostring(record.Level or "DEFAULT")
			local definition = type(context.Catalogs.Potions) == "table" and context.Catalogs.Potions[record.Name]
			local item = { Type = "Potion", Name = record.Name, Level = record.Level }
			local amount = type(definition) == "table" and owned(item, true) or nil
			if amount ~= record.Amount then amount = nil end
			if seenPotions[key] then shapeValid, amount = false, nil end
			seenPotions[key] = true
			inventory.Potions[key] = inventoryEntry(item, amount, definition,
				"Native received Potions records carry exact Name/optional Level/Amount; duplicate, malformed or unsupported records stay unknown")
		end
		inventory.PotionSchemaState = shapeValid and "OBSERVED_NATIVE_RECORDS" or "UNKNOWN"
		for _, entry in pairs(inventory.Potions) do table.insert(inventory.Items, copy(entry)) end
	end
	inventory.SchemaState = type(account.Powerups) == "table" and inventory.PotionSchemaState == "OBSERVED_NATIVE_RECORDS" and "OBSERVED" or "PARTIAL_OR_UNKNOWN"
	local rendered = workspace and workspace:FindFirstChild("Rendered")
	local locations = rendered and rendered:FindFirstChild("Chests")
	local locationEntries = locations and locations:GetChildren() or nil
	for name in pairs(type(context.Catalogs.Chests) == "table" and context.Catalogs.Chests or {}) do
		if type(name) ~= "string" then continue end
		local observation = { Interaction = "UNKNOWN", Reason = "Native location representation is not proof of private physical chest registry membership" }
		context.ChestObservations[name] = observation
		if locationEntries then
			local matches = {}
			for _, instance in ipairs(locationEntries) do if instance.Name == name and instance.Parent == locations then table.insert(matches, instance) end end
			observation.LocationPresent, observation.Loaded = #matches > 0, #matches > 0
			if #matches == 1 then
				local island, world = matches[1]:GetAttribute("Island"), matches[1]:GetAttribute("World")
				observation.Island, observation.World = type(island) == "string" and island or nil, type(world) == "string" and world or nil
				if type(island) == "string" and type(account.AreasUnlocked) == "table" then
					local unlocked = account.AreasUnlocked[island]
					observation.Access, observation.MapAccess = unlocked ~= nil and unlocked ~= false, unlocked ~= nil and unlocked ~= false
					observation.AccessReason = "Native WorldMap map-area visibility uses the received area's truthy entry; physical/server interaction remains unknown"
				else observation.AccessReason = "Native WorldMap skips location entries with no Island; no world or physical access is inferred" end
			elseif #matches > 1 then observation.Reason = "Multiple native chest location representations; interaction and access identity remain unknown" end
		end
	end
	local storage = snapshot.Inventory or {}
	context.StorageObservation = { Used = finite(storage.StorageUsed) and storage.StorageUsed or nil,
		Capacity = finite(storage.StorageCapacity) and storage.StorageCapacity or nil,
		Reason = "Existing reader StatsUtil:GetUsedPetStorage/GetMaxPetStorage observations; missing units and server grant-space rules remain unknown" }
	for world, definition in pairs(type(context.Catalogs.WorldRewards) == "table" and context.Catalogs.WorldRewards or {}) do
		if type(world) ~= "string" or type(definition) ~= "table" then continue end
		local received = type(account.WorldRewards) == "table" and account.WorldRewards[world]
		local worldDefinition = type(context.Catalogs.Worlds) == "table" and context.Catalogs.Worlds[world]
		local observation = { WorldDefinitionState = type(worldDefinition) == "table" and "OBSERVED" or "UNKNOWN",
			WorldActivity = "UNKNOWN", Access = type(account.WorldsUnlocked) == "table" and account.WorldsUnlocked[world] == true or nil,
			Progress = type(received) == "table" and integer(received.Progress) and received.Progress or nil,
			Reason = "Native WorldRewards[world].Progress and strict WorldsUnlocked[world]==true; paid next-tier transaction, no permission" }
		if type(worldDefinition) == "table" then
			observation.Removed = worldDefinition.Removed ~= nil and worldDefinition.Removed ~= false
			observation.Event = worldDefinition.Event ~= nil and worldDefinition.Event ~= false
			observation.WorldActivity = observation.Removed and "REMOVED" or observation.Event and "UNKNOWN_EVENT_ACTIVITY" or "PERMANENT_CATALOG_DEFINITION"
		end
		if type(account.WorldsUnlocked) == "table" then observation.Access = account.WorldsUnlocked[world] == true end
		if observation.Progress ~= nil and type(definition.Levels) == "table" then
			local tier = definition.Levels[observation.Progress + 1]
			observation.NextTier = observation.Progress + 1
			observation.NativePrice = type(tier) == "table" and copy(tier.Cost) or nil
			observation.DeclaredReward = type(tier) == "table" and copy(tier.Reward) or nil
			local reward, stats = type(tier) == "table" and tier.Reward, modules.StatsUtil
			if type(reward) == "table" and reward.Type == "Pet" then
				if type(stats) == "table" and type(stats.IsInventoryFull) == "function" then
					local ok, full = pcall(stats.IsInventoryFull, stats, copy(account))
					if ok and type(full) == "boolean" then
						observation.StorageEligible = not full
						observation.StorageReason = "Native StatsUtil:IsInventoryFull observed for this next paid pet reward; grant sizing/server acceptance remains unverified"
					end
				end
			elseif type(reward) == "table" and type(reward.Type) == "string" then
				observation.StorageEligible, observation.StorageReason = true, "Native next reward descriptor is not a Pet; this does not authorize a paid request"
			end
		end
		context.WorldRewardObservations[world] = observation
	end
	local final, finalSnapshot = reader:GetLiveProfile(), reader:GetSnapshot()
	if self.Destroyed or reader.Destroyed or reader.Player ~= player or player.UserId ~= identity
		or reader.Revision ~= snapshot.Revision or type(finalSnapshot) ~= "table" or finalSnapshot.Ready ~= true
		or finalSnapshot.Revision ~= snapshot.Revision or type(final) ~= "table" or not matchesSnapshot(final) or not equal(account, final) then
		return block("Received reward account identity, revision, prerequisite or inventory facts changed during native observation")
	end
	for name, value in pairs(copiedModules) do if not equal(value, self:Get(name)) then return block("Native reward definitions or getter interfaces changed during observation") end end
	context.CompletedAt = now + math.max(0, os.clock() - startedAt)
	if context.CompletedAt - snapshot.ReadAt > maximumAge then return block("Reward account snapshot became stale during native observation") end
	context.Fresh = true
	return context
end
-- PHASE5_READ_ONLY_REWARDS_END
return GameKnowledge

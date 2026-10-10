--!nonstrict
-- Scene observation only. Native ClientScript owns pickup collection and credit.
local PickupTracker = {}
PickupTracker.__index = PickupTracker
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameKnowledge = require(script.Parent.GameKnowledge)

local function allowed(list, value) return #list == 0 or table.find(list, value) ~= nil end
local function worldOf(instance)
	local worlds = workspace:FindFirstChild("Worlds")
	local node = instance
	while node and node ~= workspace do
		if node.Parent == worlds then return node.Name end
		node = node.Parent
	end
	return nil
end
local function vectorKey(vector)
	return string.format("%.4f,%.4f,%.4f", vector.X, vector.Y, vector.Z)
end
local function colorKey(color) return string.format("%.4f,%.4f,%.4f", color.R, color.G, color.B) end
local function fingerprint(model, meshOnly)
	local pieces = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("MeshPart") then
			table.insert(pieces, part.Name .. ":" .. part.MeshId .. ":" .. part.TextureID .. (meshOnly and "" or ":" .. vectorKey(part.Size)))
		elseif part:IsA("SpecialMesh") then
			table.insert(pieces, part.Name .. ":" .. part.MeshId .. ":" .. part.TextureId .. (meshOnly and "" or ":" .. vectorKey(part.Scale)))
		elseif part:IsA("BasePart") then
			table.insert(pieces, part.Name .. ":" .. part.ClassName .. (meshOnly and "" or ":" .. vectorKey(part.Size)) .. ":" .. colorKey(part.Color))
		end
	end
	table.sort(pieces)
	return #pieces > 0 and table.concat(pieces, "|") or nil
end
local function spawnFor(area, world)
	local worlds = workspace:FindFirstChild("Worlds")
	local root = worlds and worlds:FindFirstChild(world or "")
	if not root then return nil end
	if area == world then
		local travel = root:FindFirstChild("FastTravel")
		-- PortalSpawn is the verified return destination used by native island portals.
		return (travel and travel:FindFirstChild("Spawn")) or root:FindFirstChild("PortalSpawn")
	end
	local islands = root:FindFirstChild("Islands")
	local island = islands and islands:FindFirstChild(area)
	local model = island and island:FindFirstChild("Island")
	local portal = model and model:FindFirstChild("Portal")
	return portal and portal:FindFirstChild("Spawn")
end

local function islandOf(instance, world)
	local worlds = workspace:FindFirstChild("Worlds")
	local root = worlds and worlds:FindFirstChild(world or "")
	local islands = root and root:FindFirstChild("Islands")
	local node = instance
	while node and node ~= workspace do
		if node.Parent == islands then return node.Name end
		node = node.Parent
	end
	return nil
end

function PickupTracker.new(config, reader, player, knowledge)
	return setmetatable({ Config = config, Reader = reader, Knowledge = knowledge or GameKnowledge.new(reader), Player = player, Zones = {}, Areas = {},
		Metadata = {}, Models = {}, Backoff = {}, Connections = {}, Prefabs = nil,
		LastZoneRefresh = -math.huge, LastScan = -math.huge, ObservedSpawns = 0, Disappeared = 0,
		LastPrefabRefresh = -math.huge, IdentityCache = {}, PrefabRevision = 0,
		NativeSpawnEvents = 0, NativeSpawnRecords = 0,
		RespawnObservations = 0, Destroyed = false }, PickupTracker)
end

function PickupTracker:Root()
	local character = self.Player and self.Player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and humanoid and humanoid.Health > 0 then return root, humanoid end
	return nil
end

function PickupTracker:_hookSpawn()
	if self.SpawnConnection or not self.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS or not self.Config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING then return end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local pickups = remotes and remotes:FindFirstChild("Pickups")
	local spawn = pickups and pickups:FindFirstChild("SpawnPickups")
	if not spawn or not spawn:IsA("RemoteEvent") then return end
	self.SpawnConnection = spawn.OnClientEvent:Connect(function(payload)
		self.NativeSpawnEvents += 1
		if type(payload) ~= "table" then return end
		for _, entry in pairs(payload) do
			if type(entry) == "table" and (type(entry.Id) == "string" or (type(entry.Id) == "number" and entry.Id == entry.Id and math.abs(entry.Id) < math.huge)) and type(entry.Visual) == "string" then
				self.Metadata[tostring(entry.Id)] = { Root = entry.Root, Visual = entry.Visual, At = os.clock() }
				self.NativeSpawnRecords += 1
			end
		end
	end)
	table.insert(self.Connections, self.SpawnConnection)
end

function PickupTracker:_zones(now)
	if now - self.LastZoneRefresh < self.Config.PICKUP_SETTINGS.ZONE_REFRESH_SECONDS then return end
	local getZones = self.Knowledge:Get("GetPickupZones")
	if type(getZones) ~= "function" then self.Error = "GetPickupZones interface is unavailable" return end
	self.LastZoneRefresh = now
	local ok, zones = pcall(getZones)
	if not ok or type(zones) ~= "table" then self.Error = "Zone read failed: " .. tostring(zones) return end
	self.Zones = zones
	self.Error = nil
end

function PickupTracker:_prefabs(now)
	if now - self.LastPrefabRefresh < self.Config.PICKUP_SETTINGS.PREFAB_REFRESH_SECONDS then return end
	local pickups = self.Knowledge:Assets("Pickups")
	if not pickups then return end
	self.Prefabs, self.MeshPrefabs = {}, {}
	self.LastPrefabRefresh, self.PrefabRevision = now, self.PrefabRevision + 1
	local function insert(index, key, name)
		if not key then return end
		index[key] = index[key] or {}
		index[key][name] = true -- Duplicate assets with the same visual name are not different rewards.
	end
	for _, prefab in ipairs(pickups:GetChildren()) do
		if prefab:IsA("Model") then
			local ok, exact, meshes = pcall(function() return fingerprint(prefab), fingerprint(prefab, true) end)
			if ok then insert(self.Prefabs, exact, prefab.Name) insert(self.MeshPrefabs, meshes, prefab.Name) end
		end
	end
end

function PickupTracker:Refresh(snapshot, now)
	if self.Destroyed or not self.Config.FARMING_SETTINGS.AUTO_RESOURCE_FARM then return end
	self:_hookSpawn()
	self:_zones(now)
	local root = self:Root()
	local position = root and root.Position
	local profile = self.Reader:GetLiveProfile()
	local stats = self.Knowledge:Get("StatsUtil")
	local oldAreas, areas, current, currentDistance = self.Areas, {}, nil, math.huge
	self.ZoneAreas, self.ZoneInfo = {}, {}
	local catalog = (snapshot.AvailableProgression or {}).Islands or {}
	local function areaFor(name, world)
		local key = (world or "Live event") .. "/" .. name
		if areas[key] then return areas[key] end
		local prior = oldAreas[key]
		local area = { Key = key, Name = name, World = world, Zones = {}, Currencies = {}, Expected = {}, Available = {},
			VisibleCount = 0, EligibleCount = 0, UnknownCount = 0, ZoneCount = 0, ConfiguredCount = 0,
			LastDepletionAt = prior and prior.LastDepletionAt, RespawnSeconds = prior and prior.RespawnSeconds,
			LastSpawnAt = prior and prior.LastSpawnAt, TravelSeconds = prior and prior.TravelSeconds }
		areas[key] = area
		return area
	end
	-- Keep real catalog islands visible even when no tagged zone is loaded. This is not pickup availability.
	local function catalogIsland(name, world)
		local area = areaFor(name, world)
		area.CatalogKnown = true
		-- Native WorldMap sends this exact path without requiring a locally visible Portal.Spawn.
		area.DestinationPath = "Workspace.Worlds." .. world .. ".Islands." .. name .. ".Island.Portal.Spawn"
	end
	for _, island in ipairs(catalog) do catalogIsland(island.Name, island.World) end
	-- The Phase 1 progression catalog filters absent scene models. Still diagnose defined islands whose geometry is not loaded.
	local definitions = self.Knowledge:Get("Worlds")
	local areaWorlds = {}
	local function registerArea(name, world)
		if areaWorlds[name] == nil then areaWorlds[name] = world elseif areaWorlds[name] ~= world then areaWorlds[name] = false end
	end
	for world, definition in pairs(type(definitions) == "table" and definitions or {}) do
		if type(definition) == "table" and not definition.Removed and not definition.Event then
			registerArea(world, world)
			for _, island in ipairs(definition.Islands or {}) do catalogIsland(island.Name, world) registerArea(island.Name, world) end
		end
	end
	for _, island in ipairs(catalog) do registerArea(island.Name, island.World) end
	local stages = workspace:FindFirstChild("Stages")
	local multiplierCache = {}
	for zoneRoot, data in pairs(self.Zones) do
		if zoneRoot.Parent and zoneRoot:IsDescendantOf(workspace) and data.Zone and type(data.Area) == "string" and data.Area ~= "" then
			local physicalWorld = worldOf(zoneRoot)
			local world = physicalWorld or areaWorlds[data.Area] or nil
			local transit = stages ~= nil and zoneRoot:IsDescendantOf(stages)
			local physicalIsland = islandOf(zoneRoot, world)
			local area = areaFor(physicalIsland or data.Area, world)
			self.ZoneAreas[zoneRoot] = area
			area.AllZoneCount = (area.AllZoneCount or 0) + 1
			if transit then area.TransitZoneCount = (area.TransitZoneCount or 0) + 1 else
				area.ZoneCount += 1
				if type(data.Count) == "number" then area.ConfiguredCount += data.Count else area.UnknownZoneCount = true end
			end
			if physicalIsland and physicalIsland ~= data.Area then area.MappingWarning = "Physical island differs from native reward pool Area=" .. data.Area end
			local zoneInfo = { Root = zoneRoot, Data = data, IsTransit = transit }
			table.insert(area.Zones, zoneInfo) self.ZoneInfo[zoneRoot] = zoneInfo
			local sumChance = 0
			for _, pickup in ipairs(data.Pickups or {}) do sumChance += type(pickup.Chance) == "number" and pickup.Chance or 0 end
			for _, pickup in ipairs(data.Pickups or {}) do
				local item = pickup.Item and pickup.Item.Item
				if item and item.Type == "Currency" and type(item.Currency) == "string" and type(item.Amount) == "number" then
					if not transit then area.Currencies[item.Currency] = true end
					self.Reader:RegisterCurrency(item.Currency)
					local multiplier = multiplierCache[item.Currency]
					if multiplier == nil and profile and stats and type(stats.GetCurrencyMultiplier) == "function" then
						local success, value = pcall(stats.GetCurrencyMultiplier, stats, profile, item.Currency)
						if success and type(value) == "number" and value > 0 then multiplier = value end
						multiplierCache[item.Currency] = multiplier or false
					end
					if multiplier == false then multiplier = nil end
					area.Multipliers = area.Multipliers or {}
					area.Multipliers[item.Currency] = multiplier
					local count = type(data.Count) == "number" and data.Count or nil
					if not transit and count and multiplier and sumChance > 0 and type(pickup.Chance) == "number" then
						area.Expected[item.Currency] = (area.Expected[item.Currency] or 0) + count * pickup.Chance / sumChance * item.Amount * multiplier
					end
				end
			end
			if not transit and position and math.abs(position.Y - data.Zone.Height) <= self.Config.PICKUP_SETTINGS.MAXIMUM_VERTICAL_DIFFERENCE_STUDS then
				local distance = data.Zone:GetDistanceToPoint(position)
				if distance < currentDistance and distance <= self.Config.PICKUP_SETTINGS.MAXIMUM_ROUTE_DISTANCE_STUDS then
					current, currentDistance = area, distance
				end
			end
		end
	end
	for _, area in pairs(areas) do
		area.WorldUnlocked = area.World ~= nil and snapshot.UnlockedWorlds ~= nil and snapshot.UnlockedWorlds[area.World] ~= nil or false
		area.Discovered = snapshot.UnlockedIslands ~= nil and snapshot.UnlockedIslands[area.Name] ~= nil or false
		area.Unlocked = area.WorldUnlocked and (area.Name == area.World or area.Discovered)
		-- A live special zone may be farmed where the player already is, but no unverified event teleport is invented.
		area.AtCurrentLocation = area == current
		if area == current then area.Unlocked = true end
		area.Spawn = spawnFor(area.Name, area.World)
		if area.Spawn and not area.Spawn:IsA("BasePart") then area.Spawn = nil end
	end
	self.Areas, self.Current = areas, current
	if self.LastAreaKey ~= (current and current.Key) then self.LastAreaKey = current and current.Key self.ArrivedAt = now end
	if self.Config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING and now - self.LastScan >= self.Config.PICKUP_SETTINGS.COLLECTION_REFRESH_SECONDS then
		self.LastScan = now
		self:_scan(now)
	else
		-- Preserve counts between expensive scans, but rebuild zone eligibility each observation.
		for key, area in pairs(areas) do
			local previous = oldAreas[key]
			if previous then
				area.Available, area.VisibleCount, area.EligibleCount, area.UnknownCount = previous.Available, previous.VisibleCount, previous.EligibleCount, previous.UnknownCount
			end
		end
	end
end

function PickupTracker:_identity(model, zones, metadata)
	local pool = {}
	for _, zone in ipairs(zones) do
		for _, entry in ipairs(zone.Data.Pickups or {}) do
			if entry.Item and type(entry.Item.Visual) == "string" then pool[entry.Item.Visual] = true end
		end
	end
	if metadata and type(metadata.Visual) == "string" then return metadata.Visual, "SPAWN_METADATA" end
	local cached = self.IdentityCache[model]
	if not cached or cached.Revision ~= self.PrefabRevision then
		local ok, exact, meshes = pcall(function() return fingerprint(model), fingerprint(model, true) end)
		cached = { Revision = self.PrefabRevision, Exact = ok and exact or nil, Meshes = ok and meshes or nil, Error = not ok and tostring(exact) or nil }
		self.IdentityCache[model] = cached
	end
	if cached.Error then return nil, nil, "Prefab read failed: " .. cached.Error end
	local function unique(index, key)
		local name, count = nil, 0
		for visual in pairs((key and index and index[key]) or {}) do
			if pool[visual] then name = visual count += 1 end
		end
		return count == 1 and name or nil, count
	end
	local visual, count = unique(self.Prefabs, cached.Exact)
	if visual then return visual, "LIVE_PREFAB_GEOMETRY" end
	if count > 1 then return nil, nil, "Ambiguous prefab visuals in native pool" end
	visual, count = unique(self.MeshPrefabs, cached.Meshes)
	if visual then return visual, "LIVE_PREFAB_MESH_IDENTITY" end
	return nil, nil, count > 1 and "Ambiguous mesh visuals in native pool" or "No matching live prefab or spawn metadata"
end

local function nativeId(value)
	if type(value) == "string" and value ~= "" then return value end
	if type(value) == "number" and value == value and math.abs(value) < math.huge then return tostring(value) end
	return nil
end

local function guidShaped(name)
	local a, b, c, d, e = name:match("^(%x+)%-(%x+)%-(%x+)%-(%x+)%-(%x+)$")
	return a ~= nil and #a == 8 and #b == 4 and #c == 4 and #d == 4 and #e == 12
end

function PickupTracker:_discover(report, reject)
	local rendered = workspace:FindFirstChild("Rendered")
	local legacy = rendered and rendered:FindFirstChild("Pickups")
	local legacyObjects = legacy and legacy:GetChildren() or {}
	report.FolderPresent, report.LegacyObjects = legacy ~= nil, #legacyObjects
	report.RegistryEntries, report.RegistryActiveIds, report.ChunkerFolders, report.ChunkerObjects = 0, 0, 0, 0
	report.IdSources, report.CandidateIds, report.UnloadedEntries = {}, 0, 0
	report.NativeSpawnEvents, report.NativeSpawnRecords = self.NativeSpawnEvents, self.NativeSpawnRecords
	report.SpawnListener = self.SpawnConnection ~= nil
	local registry, registryStatus
	if self.Config.PICKUP_SETTINGS.ENABLE_NATIVE_REGISTRY_DISCOVERY then registry, registryStatus = self.Knowledge:ActivePickups()
	else registryStatus = "Native registry discovery disabled" end
	report.RegistryAvailable, report.RegistryStatus = registry ~= nil, registryStatus
	self.ActiveRegistry = registry
	local candidates, byModel, byId, collisions = {}, {}, {}, {}
	local function add(model, id, source, registryKey)
		local valid, isModel = pcall(function() return model:IsA("Model") end)
		if not valid or not isModel then
			if source == "LEGACY_PICKUP_MODEL" and valid then reject("Unexpected native pickup class " .. model.ClassName, model)
			else reject("Native source entry is not a Model", nil) end
			return
		end
		if not id or model.Name ~= id then reject("Native ID missing or registry key differs from Model.Name", model) return end
		if not model.Parent or not model:IsDescendantOf(workspace) then report.UnloadedEntries += 1 return end
		if byModel[model] then return end
		if byId[id] and byId[id] ~= model then collisions[id] = true end
		byId[id], byModel[model] = model, true
		table.insert(candidates, { Model = model, Id = id, IdSource = source, RegistryKey = registryKey })
		if source == "NATIVE_ACTIVE_REGISTRY" then report.RegistryActiveIds += 1 end
	end
	for id, model in pairs(registry or {}) do
		report.RegistryEntries += 1
		add(model, nativeId(id), "NATIVE_ACTIVE_REGISTRY", id)
	end
	if self.Config.PICKUP_SETTINGS.ENABLE_CHUNKER_DISCOVERY and rendered then
		-- Chunker owns multiple identically named folders; never use FindFirstChild here.
		for _, child in ipairs(rendered:GetChildren()) do
			if child.Name ~= "Chunker" or not child:IsA("Folder") then continue end
			report.ChunkerFolders += 1
			for _, model in ipairs(child:GetChildren()) do
				report.ChunkerObjects += 1
				local id = nativeId(model.Name)
				-- Chunkers also serve other game systems. A name alone never establishes currency.
				if id and (self.Metadata[id] or guidShaped(id)) then add(model, id, "NATIVE_CHUNKER_MODEL") end
			end
		end
	end
	for _, model in ipairs(legacyObjects) do add(model, nativeId(model.Name), "LEGACY_PICKUP_MODEL") end
	local objects = {}
	self.ModelIds = {}
	for _, candidate in ipairs(candidates) do
		if collisions[candidate.Id] then reject("Conflicting live Models share the same native ID", candidate.Model) continue end
		table.insert(objects, candidate.Model) self.ModelIds[candidate.Model] = candidate
		report.IdSources[candidate.IdSource] = (report.IdSources[candidate.IdSource] or 0) + 1
		report.CandidateIds += 1
	end
	report.RenderedObjects = #objects
	local metadataCount, unresolved = 0, 0
	for id in pairs(self.Metadata) do metadataCount += 1 if not byId[id] then unresolved += 1 end end
	report.MetadataIds, report.MetadataWithoutModel = metadataCount, unresolved
	return objects
end

function PickupTracker:IsActive(record)
	if not record.Model.Parent then return false end
	if record.IdSource and record.Model.Name ~= record.Id then return false end
	if record.IdSource == "NATIVE_ACTIVE_REGISTRY" then
		local registry = self.Knowledge:ActivePickups()
		return registry ~= nil and registry[record.RegistryKey or record.Id] == record.Model
	end
	return true
end

function PickupTracker:_scan(now)
	if not self.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS or not self.Config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING then return end
	self:_prefabs(now)
	local report = { At = now, Models = 0, CurrencyCount = 0, PositionsResolved = 0,
		Unidentified = 0, CurrentDetected = 0, CurrentCurrency = 0, Sources = {}, Rejected = {}, Examples = {}, Classes = {}, Currencies = {} }
	local function reject(reason, model)
		report.Rejected[reason] = (report.Rejected[reason] or 0) + 1
		if model and #report.Examples < 3 then table.insert(report.Examples, model:GetFullName() .. " | " .. reason) end
	end
	local objects = self:_discover(report, reject)
	local seen, root = {}, self:Root()
	for _, area in pairs(self.Areas) do
		area.Available = {} area.VisibleCount = 0 area.EligibleCount = 0 area.UnknownCount = 0 area.CurrencyCount = 0
	end
	for _, model in ipairs(objects) do
		report.Classes[model.ClassName] = (report.Classes[model.ClassName] or 0) + 1
		if not model:IsA("Model") then reject("Unexpected native pickup class " .. model.ClassName, model) continue end
		report.Models += 1
		local pivotOK, pivot = pcall(function() return model:GetPivot() end)
		if not pivotOK then reject("Model pivot unavailable", model) report.Unidentified += 1 continue end
		local position = pivot.Position
		report.PositionsResolved += 1
		local metadata = self.Metadata[model.Name]
		local nativeZone = metadata and self.ZoneInfo[metadata.Root]
		local area, zones = nativeZone and self.ZoneAreas[metadata.Root] or nil, {}
		if area then table.insert(zones, nativeZone) else
			local ambiguous = false
			for _, candidate in pairs(self.Areas) do
				for _, zone in ipairs(candidate.Zones) do
					local geometry = zone.Data.Zone
					if math.abs(position.Y - geometry.Height) <= self.Config.PICKUP_SETTINGS.MAXIMUM_VERTICAL_DIFFERENCE_STUDS
						and geometry:GetDistanceToPoint(position) <= self.Config.PICKUP_SETTINGS.ZONE_MATCH_TOLERANCE_STUDS then
						if area and candidate ~= area then ambiguous = true end
						area = candidate table.insert(zones, zone)
					end
				end
			end
			if ambiguous then reject("Overlapping zones from different areas; metadata required", model) area = nil
			elseif not area then reject("Outside loaded native zone geometry/height", model) end
		end
		if not area then report.Unidentified += 1 continue end
		area.VisibleCount += 1
		if area == self.Current then report.CurrentDetected += 1 end
		local visual, source, identityReason = self:_identity(model, zones, metadata)
		local item, conflicting, transit = nil, false, true
		for _, zone in ipairs(zones) do
			if not zone.IsTransit then transit = false end
			for _, definition in ipairs(zone.Data.Pickups or {}) do
				if definition.Item and definition.Item.Visual == visual then
					local candidate = definition.Item.Item
					if item and (candidate.Type ~= item.Type or candidate.Currency ~= item.Currency or candidate.Amount ~= item.Amount) then conflicting = true end
					item = candidate
				end
			end
		end
		local discovery = self.ModelIds[model]
		local old = self.Models[model]
		if old and old.Id ~= discovery.Id then
			-- A changed native ID starts a new lifecycle, including a new frozen sweep.
			old = nil
			if self.Sweep then self.Sweep.Pending[model] = nil end
		end
		local record = old or { Model = model, Id = discovery.Id, FirstSeenAt = now }
		record.IdSource, record.RegistryKey = discovery.IdSource, discovery.RegistryKey
		record.Position, record.AreaKey, record.Visual, record.Source, record.IsTransit = position, area.Key, visual, source, transit
		record.Currency = not conflicting and item and item.Type == "Currency" and type(item.Currency) == "string" and item.Currency or nil
		record.Amount = record.Currency and type(item.Amount) == "number" and item.Amount or nil
		record.RouteEligible = record.Currency ~= nil and record.Amount ~= nil and not transit and allowed(self.Config.PICKUP_SETTINGS.FARM_CURRENCY_TYPES, record.Currency)
		if area == self.Current and root and math.abs(position.Y - root.Position.Y) > self.Config.PICKUP_SETTINGS.MAXIMUM_VERTICAL_DIFFERENCE_STUDS then record.RouteEligible = false end
		seen[model] = true self.Models[model] = record
		if not old then
			self.ObservedSpawns += 1
			if area.LastDepletionAt then
				local interval = now - area.LastDepletionAt
				if interval > 0 then area.RespawnSeconds = interval self.RespawnObservations += 1 end
				area.LastDepletionAt = nil
			end
			area.LastSpawnAt = now
		end
		if record.Currency then
			report.CurrencyCount += 1 area.CurrencyCount += 1
			report.Currencies[record.Currency] = (report.Currencies[record.Currency] or 0) + 1
			if area == self.Current then report.CurrentCurrency += 1 end
			report.Sources[source or "UNKNOWN"] = (report.Sources[source or "UNKNOWN"] or 0) + 1
		else
			if not item or conflicting then report.Unidentified += 1 area.UnknownCount += 1 end
			reject(conflicting and "Conflicting native reward definitions" or (not item and (identityReason or "Visual absent from native zone pool") or "Native reward is not currency"), model)
		end
		if record.RouteEligible then
			area.EligibleCount += 1 area.Available[record.Currency] = (area.Available[record.Currency] or 0) + 1
		elseif record.Currency then
			reject(transit and "Jump-stage transit pickup; outside supported island surface" or (not allowed(self.Config.PICKUP_SETTINGS.FARM_CURRENCY_TYPES, record.Currency)
				and "Currency excluded by FARM_CURRENCY_TYPES" or "Invalid amount or incompatible current height"), model)
		end
	end
	for model, record in pairs(self.Models) do
		if not seen[model] then
			self.Disappeared += 1
			local area = self.Areas[record.AreaKey]
			if area and not model.Parent then area.LastDepletionAt = now end
			self.Models[model] = nil self.IdentityCache[model] = nil
			if self.Sweep then self.Sweep.Pending[model] = nil end
		end
	end
	for model in pairs(self.IdentityCache) do if not model.Parent then self.IdentityCache[model] = nil end end
	for id, metadata in pairs(self.Metadata) do if now - metadata.At > 300 then self.Metadata[id] = nil end end
	for id, failure in pairs(self.Backoff) do if now >= failure.Until then self.Backoff[id] = nil end end
	self.ScanReport = report
end

function PickupTracker:BackOff(records, seconds, reason)
	for _, record in ipairs(records) do
		self.Backoff[record.Id] = { Until = os.clock() + seconds, Reason = reason }
		if self.Sweep then self.Sweep.Pending[record.Model] = nil end
	end
end

function PickupTracker:ReadRange()
	local ok, range = pcall(function() return self.Knowledge:Get("StatsUtil"):GetPickupRange(self.Reader:GetLiveProfile()) end)
	self.Range = ok and type(range) == "number" and range > 0 and range < math.huge and range or nil
	self.RangeReason = self.Range and nil or "Actual StatsUtil pickup range unavailable"
	return self.Range
end

function PickupTracker:Cluster(currency)
	self.ClusterReason = nil
	local function unavailable(reason) self.ClusterReason = reason return nil end
	if not self.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS or not self.Config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING then return unavailable("Collection/scanning disabled") end
	local root, humanoid = self:Root()
	if not root or not self.Current then return unavailable("Character or current island geometry unavailable") end
	local range = self:ReadRange()
	if not range then return unavailable(self.RangeReason) end
	local records = {}
	local eligibleModels = {}
	for _, record in pairs(self.Models) do
		if record.AreaKey == self.Current.Key and record.Currency and allowed(self.Config.PICKUP_SETTINGS.FARM_CURRENCY_TYPES, record.Currency)
			and record.RouteEligible ~= false and not record.IsTransit and self:IsActive(record) and not self.Backoff[record.Id]
			and math.abs(record.Position.Y - root.Position.Y) <= self.Config.PICKUP_SETTINGS.MAXIMUM_VERTICAL_DIFFERENCE_STUDS then
			table.insert(records, record) eligibleModels[record.Model] = true
		end
	end
	if self.Sweep then for model in pairs(self.Sweep.Pending) do if not eligibleModels[model] then self.Sweep.Pending[model] = nil end end end
	table.sort(records, function(a, b) return a.Id < b.Id end)
	-- Freeze the currently eligible island set for a sweep. New spawns enter the next sweep,
	-- so repeated new coin spawns cannot indefinitely starve remaining gems/event currencies.
	if not self.Sweep or self.Sweep.AreaKey ~= self.Current.Key or next(self.Sweep.Pending) == nil then
		self.SweepSequence = (self.SweepSequence or 0) + 1
		self.Sweep = { Id = self.SweepSequence, AreaKey = self.Current.Key, Pending = {}, Total = #records }
		for _, record in ipairs(records) do self.Sweep.Pending[record.Model] = true end
	end
	local pendingRecords = {}
	for _, record in ipairs(records) do if self.Sweep.Pending[record.Model] then table.insert(pendingRecords, record) end end
	records = pendingRecords
	if #records == 0 then return unavailable("No classified eligible current-island models outside retry backoff") end
	local points = { root.Position }
	if self.Config.PICKUP_SETTINGS.ENABLE_CLUSTER_ROUTING then
		local stride = math.max(1, math.ceil(#records / self.Config.PICKUP_SETTINGS.MAXIMUM_CLUSTER_CANDIDATES))
		for index = 1, #records, stride do
			local position = records[index].Position
			table.insert(points, Vector3.new(position.X, root.Position.Y, position.Z))
		end
		-- Bounded pair midpoints can cover two clusters without visiting each model.
		local anchors = #points
		for first = 2, anchors do
			for second = first + 1, anchors do
				local a, b = points[first], points[second]
				if (a - b).Magnitude <= range * 2 then table.insert(points, Vector3.new((a.X + b.X) / 2, root.Position.Y, (a.Z + b.Z) / 2)) end
			end
		end
	end
	local best
	for _, point in ipairs(points) do
		local distance = (point - root.Position).Magnitude
		if distance > self.Config.PICKUP_SETTINGS.MAXIMUM_ROUTE_DISTANCE_STUDS then continue end
		local covered, useful, value = {}, 0, 0
		for _, record in ipairs(records) do
			if (record.Position - point).Magnitude <= math.max(0, range - self.Config.PICKUP_SETTINGS.PICKUP_RANGE_MARGIN_STUDS) then
				table.insert(covered, record)
				if record.Currency == currency then useful += 1 value += record.Amount or 0 end
			end
		end
		-- Maximize coverage per movement time; goal-currency reward breaks ties without converting currencies.
		local travel = 1 + distance / math.max(1, humanoid.WalkSpeed)
		local score, coverageScore = value / travel, #covered / travel
		if #covered > 0 and (not best or coverageScore > best.CoverageScore or (coverageScore == best.CoverageScore and score > best.Score)) then
			best = { Position = point, Records = covered, Score = score, Radius = range, Distance = distance,
				AreaKey = self.Current.Key, RelevantCount = useful, Currency = currency, CoverageScore = coverageScore,
				SweepId = self.Sweep.Id, SweepTotal = self.Sweep.Total, SweepRemaining = #records }
		end
	end
	if not best then self.ClusterReason = "No native-radius coverage within route distance/height limits" end
	return best
end

function PickupTracker:Destroy()
	self.Destroyed = true
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	table.clear(self.Models) table.clear(self.Metadata) table.clear(self.Backoff)
end

return PickupTracker

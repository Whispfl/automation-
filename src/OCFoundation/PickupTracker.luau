--!nonstrict
-- Scene observation only. Native ClientScript owns pickup collection and credit.
local PickupTracker = {}
PickupTracker.__index = PickupTracker
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local function fingerprint(model)
	local pieces = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("MeshPart") then
			table.insert(pieces, part.Name .. ":" .. part.MeshId .. ":" .. part.TextureID .. ":" .. tostring(part.Size))
		elseif part:IsA("SpecialMesh") then
			table.insert(pieces, part.Name .. ":" .. part.MeshId .. ":" .. part.TextureId .. ":" .. tostring(part.Scale))
		elseif part:IsA("BasePart") then
			table.insert(pieces, part.Name .. ":" .. part.ClassName .. ":" .. tostring(part.Size) .. ":" .. tostring(part.Color))
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

function PickupTracker.new(config, reader, player)
	return setmetatable({ Config = config, Reader = reader, Player = player, Zones = {}, Areas = {},
		Metadata = {}, Models = {}, Backoff = {}, Connections = {}, Prefabs = nil,
		LastZoneRefresh = -math.huge, LastScan = -math.huge, ObservedSpawns = 0, Disappeared = 0,
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
	if self.SpawnConnection or not self.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS then return end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local pickups = remotes and remotes:FindFirstChild("Pickups")
	local spawn = pickups and pickups:FindFirstChild("SpawnPickups")
	if not spawn or not spawn:IsA("RemoteEvent") then return end
	self.SpawnConnection = spawn.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then return end
		for _, entry in pairs(payload) do
			if type(entry) == "table" and type(entry.Id) == "string" and type(entry.Visual) == "string" then
				self.Metadata[entry.Id] = { Root = entry.Root, Visual = entry.Visual, At = os.clock() }
			end
		end
	end)
	table.insert(self.Connections, self.SpawnConnection)
end

function PickupTracker:_zones(now)
	if now - self.LastZoneRefresh < self.Config.PICKUP_SETTINGS.ZONE_REFRESH_SECONDS then return end
	local getZones = self.Reader:_dependency("GetPickupZones")
	if type(getZones) ~= "function" then self.Error = "GetPickupZones interface is unavailable" return end
	self.LastZoneRefresh = now
	local ok, zones = pcall(getZones)
	if not ok or type(zones) ~= "table" then self.Error = "Zone read failed: " .. tostring(zones) return end
	self.Zones = zones
	self.Error = nil
end

function PickupTracker:_prefabs()
	if self.Prefabs then return end
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local pickups = assets and assets:FindFirstChild("Pickups")
	if not pickups then return end
	self.Prefabs = {}
	for _, prefab in ipairs(pickups:GetChildren()) do
		local key = fingerprint(prefab)
		if key then
			if self.Prefabs[key] ~= nil then self.Prefabs[key] = false else self.Prefabs[key] = prefab.Name end
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
	local stats = self.Reader:_dependency("StatsUtil")
	local oldAreas, areas, current, currentDistance = self.Areas, {}, nil, math.huge
	self.ZoneAreas = {}
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
	local definitions = self.Reader:_dependency("Worlds")
	for world, definition in pairs(type(definitions) == "table" and definitions or {}) do
		if type(definition) == "table" and not definition.Removed and not definition.Event then
			for _, island in ipairs(definition.Islands or {}) do catalogIsland(island.Name, world) end
		end
	end
	local multiplierCache = {}
	for zoneRoot, data in pairs(self.Zones) do
		if zoneRoot.Parent and zoneRoot:IsDescendantOf(workspace) and data.Zone and type(data.Area) == "string" and data.Area ~= "" then
			local world = worldOf(zoneRoot)
			local physicalIsland = islandOf(zoneRoot, world)
			local area = areaFor(physicalIsland or data.Area, world)
			self.ZoneAreas[zoneRoot] = area
			area.ZoneCount += 1
			if type(data.Count) == "number" then area.ConfiguredCount += data.Count else area.UnknownZoneCount = true end
			if physicalIsland and physicalIsland ~= data.Area then area.MappingWarning = "Physical island differs from native reward pool Area=" .. data.Area end
			table.insert(area.Zones, { Root = zoneRoot, Data = data })
			local sumChance = 0
			for _, pickup in ipairs(data.Pickups or {}) do sumChance += type(pickup.Chance) == "number" and pickup.Chance or 0 end
			for _, pickup in ipairs(data.Pickups or {}) do
				local item = pickup.Item and pickup.Item.Item
				if item and item.Type == "Currency" and type(item.Currency) == "string" and type(item.Amount) == "number" then
					area.Currencies[item.Currency] = true
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
					if count and multiplier and sumChance > 0 and type(pickup.Chance) == "number" then
						area.Expected[item.Currency] = (area.Expected[item.Currency] or 0) + count * pickup.Chance / sumChance * item.Amount * multiplier
					end
				end
			end
			if position and math.abs(position.Y - data.Zone.Height) <= self.Config.PICKUP_SETTINGS.MAXIMUM_VERTICAL_DIFFERENCE_STUDS then
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
	if now - self.LastScan >= self.Config.PICKUP_SETTINGS.COLLECTION_REFRESH_SECONDS then
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

function PickupTracker:_scan(now)
	if not self.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS then return end
	self:_prefabs()
	local rendered = workspace:FindFirstChild("Rendered")
	local folder = rendered and rendered:FindFirstChild("Pickups")
	local seen = {}
	for _, model in ipairs(folder and folder:GetChildren() or {}) do
		if not model:IsA("Model") then continue end
		local position = model:GetPivot().Position
		local metadata = self.Metadata[model.Name]
		local zoneData = metadata and self.Zones[metadata.Root]
		local area
		if zoneData then area = self.ZoneAreas[metadata.Root] end
		if not area then
			local matches = 0
			for _, candidate in pairs(self.Areas) do
				for _, zone in ipairs(candidate.Zones) do
					if math.abs(position.Y - zone.Data.Zone.Height) < self.Config.PICKUP_SETTINGS.MAXIMUM_VERTICAL_DIFFERENCE_STUDS
						and zone.Data.Zone:IsPointInside(position) then
						matches += 1 area = candidate zoneData = zone.Data break
					end
				end
			end
			if matches ~= 1 then area = nil end
		end
		if not area then continue end
		area.VisibleCount += 1
		local old = self.Models[model]
		local visual = metadata and metadata.Visual or (old and old.Visual)
		if not visual and self.Prefabs then visual = self.Prefabs[fingerprint(model)] end
		local item, conflicting
		for _, definition in ipairs(zoneData.Pickups or {}) do
			if definition.Item and definition.Item.Visual == visual then
				local candidate = definition.Item.Item
				if item and (candidate.Type ~= item.Type or candidate.Currency ~= item.Currency or candidate.Amount ~= item.Amount) then conflicting = true end
				item = candidate
			end
		end
		seen[model] = true
		local record = old or { Model = model, Id = model.Name, FirstSeenAt = now }
		record.Position, record.AreaKey, record.Visual = position, area.Key, visual
		record.Currency = not conflicting and item and item.Type == "Currency" and item.Currency or nil
		record.Amount = record.Currency and item.Amount or nil
		self.Models[model] = record
		if not old then
			self.ObservedSpawns += 1
			if area.LastDepletionAt then
				local interval = now - area.LastDepletionAt
				if interval > 0 then area.RespawnSeconds = interval self.RespawnObservations += 1 end
				area.LastDepletionAt = nil
			end
			area.LastSpawnAt = now
		end
		if record.Currency and allowed(self.Config.PICKUP_SETTINGS.FARM_CURRENCY_TYPES, record.Currency) then
			area.EligibleCount += 1
			area.Available[record.Currency] = (area.Available[record.Currency] or 0) + 1
		elseif not item or conflicting then area.UnknownCount += 1 end
	end
	for model, record in pairs(self.Models) do
		if not seen[model] then
			self.Disappeared += 1
			local area = self.Areas[record.AreaKey]
			if area and not model.Parent then area.LastDepletionAt = now end
			self.Models[model] = nil
			if self.Sweep then self.Sweep.Pending[model] = nil end
		end
	end
	for id, metadata in pairs(self.Metadata) do if now - metadata.At > 300 then self.Metadata[id] = nil end end
	for id, failure in pairs(self.Backoff) do if now >= failure.Until then self.Backoff[id] = nil end end
end

function PickupTracker:BackOff(records, seconds, reason)
	for _, record in ipairs(records) do
		self.Backoff[record.Id] = { Until = os.clock() + seconds, Reason = reason }
		if self.Sweep then self.Sweep.Pending[record.Model] = nil end
	end
end

function PickupTracker:Cluster(currency)
	local root, humanoid = self:Root()
	if not root or not self.Current then return nil end
	local profile = self.Reader:GetLiveProfile()
	local stats = self.Reader:_dependency("StatsUtil")
	local ok, range = pcall(function() return stats:GetPickupRange(profile) end)
	if not ok or type(range) ~= "number" or range <= 0 then return nil end
	self.Range = range
	local records = {}
	for _, record in pairs(self.Models) do
		if record.AreaKey == self.Current.Key and record.Currency and allowed(self.Config.PICKUP_SETTINGS.FARM_CURRENCY_TYPES, record.Currency)
			and record.Model.Parent and not self.Backoff[record.Id] then table.insert(records, record) end
	end
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
	local points = { root.Position }
	if self.Config.PICKUP_SETTINGS.ENABLE_CLUSTER_ROUTING then
		local stride = math.max(1, math.ceil(#records / self.Config.PICKUP_SETTINGS.MAXIMUM_CLUSTER_CANDIDATES))
		for index = 1, #records, stride do
			local position = records[index].Position
			table.insert(points, Vector3.new(position.X, root.Position.Y, position.Z))
		end
	end
	local best
	for _, point in ipairs(points) do
		local distance = (point - root.Position).Magnitude
		if distance > self.Config.PICKUP_SETTINGS.MAXIMUM_ROUTE_DISTANCE_STUDS then continue end
		local covered, useful, value = {}, 0, 0
		for _, record in ipairs(records) do
			if (record.Position - point).Magnitude <= math.max(0, range - 1) then
				table.insert(covered, record)
				if record.Currency == currency then useful += 1 value += record.Amount or 0 end
			end
		end
		-- Score only the target currency. All eligible currencies inside the chosen radius are collected by the game.
		local travel = 1 + distance / math.max(1, humanoid.WalkSpeed)
		local score, coverageScore = value / travel, #covered / travel
		if #covered > 0 and (not best or score > best.Score or (score == best.Score and coverageScore > best.CoverageScore)) then
			best = { Position = point, Records = covered, Score = score, Radius = range, Distance = distance,
				AreaKey = self.Current.Key, RelevantCount = useful, Currency = currency, CoverageScore = coverageScore,
				SweepId = self.Sweep.Id, SweepTotal = self.Sweep.Total, SweepRemaining = #records }
		end
	end
	return best
end

function PickupTracker:Destroy()
	self.Destroyed = true
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	table.clear(self.Models) table.clear(self.Metadata) table.clear(self.Backoff)
end

return PickupTracker

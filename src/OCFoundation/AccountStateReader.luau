--!nonstrict
-- Read-only adapter for this workspace's LocalData and Shared game definitions.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local AccountStateReader = {}
AccountStateReader.__index = AccountStateReader

local function copy(value, seen)
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local result = {}
	seen[value] = result
	for key, entry in pairs(value) do result[key] = copy(entry, seen) end
	return result
end

local function number(value)
	if type(value) == "number" and value == value and value >= 0 then return value end
	return nil
end

local function findPath(path)
	local node = ReplicatedStorage
	for name in string.gmatch(path, "[^%.]+") do
		node = node and node:FindFirstChild(name)
	end
	return node
end

local function allowed(list, name)
	return #list == 0 or table.find(list, name) ~= nil
end

function AccountStateReader.new(config, player)
	local self = setmetatable({}, AccountStateReader)
	self.Config = config
	self.Player = player or Players.LocalPlayer
	self.Changed = Instance.new("BindableEvent")
	self.Dependencies = {}
	self.Connections = {}
	self.Threads = {}
	self.Destroyed = false
	self.StartedAt = nil
	self.Revision = 0
	self.DiscoveredCurrencies = {}
	self.Snapshot = { Ready = false, Status = "NOT_STARTED", Diagnostics = {}, Revision = 0 }
	return self
end

function AccountStateReader:_load(name, path, expectedType)
	local entry = { Status = "LOADING", Path = path }
	self.Dependencies[name] = entry
	local module = findPath(path)
	if not module or not module:IsA("ModuleScript") then
		entry.Status = "MISSING"
		entry.Error = "ModuleScript is absent: " .. path
		return
	end
	table.insert(self.Threads, task.defer(function()
		local ok, result = pcall(require, module)
		if self.Destroyed then return end
		if ok and type(result) ~= (expectedType or "table") then
			ok = false
			result = "Observed game interface requires " .. (expectedType or "table") .. "; module returned " .. type(result)
		end
		entry.Status = ok and "READY" or "ERROR"
		entry.Value = ok and result or nil
		entry.Error = not ok and tostring(result) or nil
		if name == "LocalData" and ok and type(result) == "table" then
			for _, signalName in ipairs({ "Changed", "DataReady", "PetsChanged" }) do
				local signal = result[signalName]
				if typeof(signal) == "RBXScriptSignal" then
					table.insert(self.Connections, signal:Connect(function() self:_queueRefresh() end))
				end
			end
		end
		self:Refresh()
	end))
	table.insert(self.Threads, task.delay(self.Config.ACCOUNT_SETTINGS.MODULE_LOAD_TIMEOUT_SECONDS, function()
		if self.Destroyed or entry.Status ~= "LOADING" then return end
		entry.Status = "TIMED_OUT"
		entry.Error = "Game module has not finished loading: " .. path
		self:Refresh()
	end))
end

function AccountStateReader:_dependency(name)
	local entry = self.Dependencies[name]
	return entry and entry.Status == "READY" and entry.Value or nil
end

function AccountStateReader:_stat(method, raw, diagnostics)
	local stats = self:_dependency("StatsUtil")
	if not stats then return nil end
	if type(stats[method]) ~= "function" then
		table.insert(diagnostics, "StatsUtil is missing method " .. method)
		return nil
	end
	local ok, result = pcall(stats[method], stats, raw)
	if not ok then
		table.insert(diagnostics, method .. " failed: " .. tostring(result))
		return nil
	end
	return number(result)
end

function AccountStateReader:_catalog(snapshot)
	local result = { Worlds = {}, Islands = {}, Upgrades = {}, Mastery = {} }
	local worlds = self:_dependency("Worlds")
	local sceneWorlds = workspace:FindFirstChild("Worlds")
	local gates = {}
	for _, gate in ipairs(CollectionService:GetTagged("WorldGate")) do
		local destination = gate:GetAttribute("World")
		if type(destination) == "string" and gate:IsDescendantOf(workspace) then
			local node, area, origin = gate, nil, nil
			while node and node ~= workspace do
				if node.Parent and node.Parent.Name == "Islands" then area = node.Name end
				if node.Parent == sceneWorlds then origin = node.Name end
				node = node.Parent
			end
			gates[destination] = { RequiredIsland = area, OriginWorld = origin, Path = gate:GetFullName() }
		end
	end
	if type(worlds) == "table" and sceneWorlds then
		for name, definition in pairs(worlds) do
			-- A retained seasonal definition is not proof that its event is active.
			if type(definition) == "table" and not definition.Event and not definition.Removed and sceneWorlds:FindFirstChild(name) then
				local gate = gates[name]
				table.insert(result.Worlds, {
					Name = name, Order = definition.Order or 999,
					Cost = copy(definition.UnlockCost), Gate = gate,
					Unlocked = snapshot.UnlockedWorlds and snapshot.UnlockedWorlds[name] ~= nil,
					Selected = allowed(self.Config.BRAIN_SETTINGS.SELECTED_WORLDS, name),
				})
				local islandRoot = sceneWorlds[name]:FindFirstChild("Islands")
				for _, island in ipairs(definition.Islands or {}) do
					local instance = islandRoot and islandRoot:FindFirstChild(island.Name)
					if instance then
						table.insert(result.Islands, {
							Name = island.Name, World = name,
							Height = instance:GetAttribute("Height") or island.Height,
							Unlocked = snapshot.UnlockedIslands and snapshot.UnlockedIslands[island.Name] ~= nil,
						})
					end
				end
			end
		end
	end
	table.sort(result.Worlds, function(a, b) return a.Order < b.Order end)
	table.sort(result.Islands, function(a, b)
		if a.World == b.World then return (a.Height or math.huge) < (b.Height or math.huge) end
		return a.World < b.World
	end)
	for _, kind in ipairs({ "Gum", "Flavors" }) do
		local definitions = self:_dependency(kind)
		if type(definitions) == "table" then
			for name, definition in pairs(definitions) do
				if type(definition) == "table" and type(definition.Cost) == "table"
					and definition.Cost.Type == "Currency" and allowed(self.Config.BRAIN_SETTINGS.SELECTED_UPGRADES, name) then
					local accessKnown = definition.Area == nil or (snapshot.UnlockedWorlds ~= nil and snapshot.UnlockedIslands ~= nil)
					local accessible = definition.Area == nil or (accessKnown and (snapshot.UnlockedWorlds[definition.Area] ~= nil
						or snapshot.UnlockedIslands[definition.Area] ~= nil))
					local owned = kind == "Gum" and snapshot.Upgrades.Gum or snapshot.Upgrades.Flavors
					table.insert(result.Upgrades, {
						Name = name, Kind = kind, Cost = copy(definition.Cost), Area = definition.Area,
						BaseStat = number(kind == "Gum" and definition.Storage or definition.Bubbles),
						Accessible = accessible == true, AccessKnown = accessKnown,
						Owned = owned and owned[name] ~= nil, OwnershipKnown = owned ~= nil,
					})
				end
			end
		end
	end
	local mastery = self:_dependency("Mastery")
	if type(mastery) == "table" then
		for _, branch in ipairs(self.Config.BRAIN_SETTINGS.MASTERY_PRIORITIES) do
			local definition = mastery[branch]
			local current = snapshot.Upgrades.MasteryLevels and number(snapshot.Upgrades.MasteryLevels[branch])
			-- Never infer a missing Mastery level as level zero.
			if type(definition) == "table" and type(definition.Levels) == "table" then
				local maximum = 0
				for level in pairs(definition.Levels) do if type(level) == "number" then maximum = math.max(maximum, level) end end
				local nextLevel = current and definition.Levels[current + 1]
				table.insert(result.Mastery, {
					Name = branch, Current = current, Maximum = maximum,
					NextCost = nextLevel and copy(nextLevel.Cost),
					NextUpgrades = nextLevel and copy(nextLevel.Upgrades),
				})
			end
		end
	end
	return result
end

function AccountStateReader:Read()
	local diagnostics = {}
	for name, entry in pairs(self.Dependencies) do
		if entry.Status ~= "READY" then table.insert(diagnostics, name .. ": " .. (entry.Error or entry.Status)) end
	end
	local snapshot = {
		Ready = false, Status = "WAITING_FOR_ACCOUNT", Diagnostics = diagnostics,
		Revision = self.Revision + 1, ReadAt = os.clock(),
		Identity = self.Player and { UserId = self.Player.UserId, AccountAge = self.Player.AccountAge } or {},
		Balances = {}, Bubble = {}, Inventory = {}, Upgrades = {}, UnavailableFields = {}, Dependencies = {},
	}
	for name, entry in pairs(self.Dependencies) do
		snapshot.Dependencies[name] = { Status = entry.Status, Path = entry.Path, Error = entry.Error }
	end
	local settings = self.Config.ACCOUNT_SETTINGS
	if not settings.ENABLE_ACCOUNT_READER then
		snapshot.Status = "READER_DISABLED"
		table.insert(diagnostics, "Account reading is disabled in OCConfig.")
	else
		local service = self:_dependency("LocalData")
		if service and type(service.IsReady) == "function" and type(service.Get) == "function" then
			local readyOK, ready = pcall(service.IsReady, service)
			local dataOK, raw = pcall(service.Get, service)
			if readyOK and ready and dataOK and type(raw) == "table" then
				snapshot.Ready = true
				snapshot.Status = "READY"
				snapshot.Source = "ReplicatedStorage.Client.Framework.Services.LocalData:Get()"
				for _, currency in ipairs(settings.SELECTED_CURRENCIES) do
					snapshot.Balances[currency] = number(raw[currency])
				end
				for currency in pairs(self.DiscoveredCurrencies) do snapshot.Balances[currency] = number(raw[currency]) end
				if type(raw.Bubble) == "table" then
					snapshot.Bubble.Amount = number(raw.Bubble.Amount)
					snapshot.Bubble.Gum = raw.Bubble.Gum
					snapshot.Bubble.Flavor = raw.Bubble.Flavor
				end
				snapshot.Bubble.Capacity = self:_stat("GetBubbleStorage", raw, diagnostics)
				snapshot.Bubble.PowerPerBlow = self:_stat("GetBubblePower", raw, diagnostics)
				local gum, flavors = self:_dependency("Gum"), self:_dependency("Flavors")
				local gumDefinition = gum and gum[snapshot.Bubble.Gum]
				local flavorDefinition = flavors and flavors[snapshot.Bubble.Flavor]
				snapshot.Bubble.BaseCapacity = gumDefinition and number(gumDefinition.Storage)
				snapshot.Bubble.BaseOutput = flavorDefinition and number(flavorDefinition.Bubbles)
				if settings.READ_PET_INVENTORY then
					snapshot.Inventory.Pets = type(raw.Pets) == "table" and copy(raw.Pets) or nil
					snapshot.Inventory.Teams = type(raw.Teams) == "table" and copy(raw.Teams) or nil
					snapshot.Inventory.TeamEquipped = raw.TeamEquipped
					local team = snapshot.Inventory.Teams and snapshot.Inventory.Teams[raw.TeamEquipped]
					snapshot.Inventory.EquippedIds = team and type(team.Pets) == "table" and copy(team.Pets) or nil
					snapshot.Inventory.EquippedPets = {}
					snapshot.Inventory.UnresolvedEquippedIds = {}
					if snapshot.Inventory.Pets and snapshot.Inventory.EquippedIds then
						local byId = {}
						for _, pet in pairs(snapshot.Inventory.Pets) do
							if type(pet) == "table" and type(pet.Id) == "string" then byId[pet.Id] = pet end
						end
						for _, id in ipairs(snapshot.Inventory.EquippedIds) do
							if byId[id] then table.insert(snapshot.Inventory.EquippedPets, byId[id])
							else table.insert(snapshot.Inventory.UnresolvedEquippedIds, id) end
						end
					end
					snapshot.Inventory.MaxEquipped = self:_stat("GetMaxPetsEquipped", raw, diagnostics)
					snapshot.Inventory.StorageCapacity = self:_stat("GetMaxPetStorage", raw, diagnostics)
					snapshot.Inventory.StorageUsed = self:_stat("GetUsedPetStorage", raw, diagnostics)
				end
				if settings.READ_ITEM_INVENTORY then
					snapshot.Inventory.Powerups = type(raw.Powerups) == "table" and copy(raw.Powerups) or nil
					snapshot.Inventory.Potions = type(raw.Potions) == "table" and copy(raw.Potions) or nil
				end
				if settings.READ_UPGRADES then
					snapshot.Upgrades.Gum = type(raw.Gum) == "table" and copy(raw.Gum) or nil
					snapshot.Upgrades.Flavors = type(raw.Flavors) == "table" and copy(raw.Flavors) or nil
				end
				if settings.READ_MASTERY then
					snapshot.Upgrades.MasteryLevels = type(raw.MasteryLevels) == "table" and copy(raw.MasteryLevels) or nil
					snapshot.Upgrades.MasteryUpgrades = type(raw.MasteryUpgrades) == "table" and copy(raw.MasteryUpgrades) or nil
				end
				if settings.READ_UNLOCKS then
					snapshot.UnlockedIslands = type(raw.AreasUnlocked) == "table" and copy(raw.AreasUnlocked) or nil
					snapshot.UnlockedWorlds = type(raw.WorldsUnlocked) == "table" and copy(raw.WorldsUnlocked) or nil
				end
			elseif type(service.DidLoadFail) == "function" then
				local ok, failed = pcall(service.DidLoadFail, service)
				if ok and failed then snapshot.Status = "ACCOUNT_LOAD_FAILED" end
			end
			if not readyOK then table.insert(diagnostics, "LocalData:IsReady failed: " .. tostring(ready)) end
			if not dataOK then table.insert(diagnostics, "LocalData:Get failed: " .. tostring(raw)) end
		end
		if not snapshot.Ready and self.StartedAt and os.clock() - self.StartedAt >= settings.ACCOUNT_LOAD_TIMEOUT_SECONDS then
			if snapshot.Status == "WAITING_FOR_ACCOUNT" then snapshot.Status = "ACCOUNT_DATA_UNAVAILABLE" end
			table.insert(diagnostics, "No ready player profile was received from LocalData. Check its module status and whether your client received PlayerDataLoaded. No statistics have been substituted.")
		end
	end
	if snapshot.Ready then
		for name, value in pairs({ Coins = not table.find(settings.SELECTED_CURRENCIES, "Coins") or snapshot.Balances.Coins ~= nil,
			Gems = not table.find(settings.SELECTED_CURRENCIES, "Gems") or snapshot.Balances.Gems ~= nil,
			Bubbles = snapshot.Bubble.Amount ~= nil, Capacity = snapshot.Bubble.Capacity ~= nil,
			PetInventory = not settings.READ_PET_INVENTORY or snapshot.Inventory.Pets ~= nil,
			EquippedPets = not settings.READ_PET_INVENTORY or snapshot.Inventory.EquippedIds ~= nil,
			Powerups = not settings.READ_ITEM_INVENTORY or snapshot.Inventory.Powerups ~= nil,
			Potions = not settings.READ_ITEM_INVENTORY or snapshot.Inventory.Potions ~= nil,
			Mastery = not settings.READ_MASTERY or snapshot.Upgrades.MasteryLevels ~= nil,
			MasteryUpgrades = not settings.READ_MASTERY or snapshot.Upgrades.MasteryUpgrades ~= nil,
			Upgrades = not settings.READ_UPGRADES or (snapshot.Upgrades.Gum ~= nil and snapshot.Upgrades.Flavors ~= nil),
			Islands = not settings.READ_UNLOCKS or snapshot.UnlockedIslands ~= nil,
			Worlds = not settings.READ_UNLOCKS or snapshot.UnlockedWorlds ~= nil }) do
			if not value then table.insert(snapshot.UnavailableFields, name) end
		end
		if #snapshot.UnavailableFields > 0 then snapshot.Status = "PARTIAL_ACCOUNT_DATA" end
	end
	snapshot.AvailableProgression = settings.ENABLE_ACCOUNT_READER and self:_catalog(snapshot) or {}
	table.sort(diagnostics)
	return snapshot
end

function AccountStateReader:_queueRefresh()
	if self.Destroyed or self.RefreshThread then return end
	local interval = self.Config.ACCOUNT_SETTINGS.MINIMUM_SNAPSHOT_INTERVAL_SECONDS
	local waitSeconds = math.max(0, interval - (os.clock() - (self.LastRefreshAt or -math.huge)))
	self.RefreshThread = task.delay(waitSeconds, function()
		self.RefreshThread = nil
		if not self.Destroyed then self:Refresh() end
	end)
end

function AccountStateReader:Refresh()
	if self.Destroyed then return end
	self.LastRefreshAt = os.clock()
	local ok, result = xpcall(function() return self:Read() end, debug.traceback)
	if not ok then
		result = { Ready = false, Status = "READER_ERROR", Revision = self.Revision + 1,
			Diagnostics = { tostring(result) }, UnavailableFields = {}, AvailableProgression = {} }
	end
	self.Revision = result.Revision
	self.Snapshot = result
	self.Changed:Fire(result)
end

function AccountStateReader:GetSnapshot()
	return copy(self.Snapshot)
end

-- Internal consumers treat this native profile as read-only. No writes or synthetic values.
function AccountStateReader:GetLiveProfile()
	if self.Destroyed or not self.Config.ACCOUNT_SETTINGS.ENABLE_ACCOUNT_READER then return nil end
	local service = self:_dependency("LocalData")
	if not service or type(service.Get) ~= "function" or type(service.IsReady) ~= "function" then return nil end
	local ok, ready = pcall(service.IsReady, service)
	if not ok or not ready then return nil end
	local received, profile = pcall(service.Get, service)
	return received and type(profile) == "table" and profile or nil
end

function AccountStateReader:RegisterCurrency(name)
	if type(name) == "string" then self.DiscoveredCurrencies[name] = true end
end

function AccountStateReader:ReadBalances()
	local raw, result = self:GetLiveProfile(), {}
	if not raw then return result end
	for _, name in ipairs(self.Config.ACCOUNT_SETTINGS.SELECTED_CURRENCIES) do result[name] = number(raw[name]) end
	for name in pairs(self.DiscoveredCurrencies) do result[name] = number(raw[name]) end
	return result
end

function AccountStateReader:Start()
	if self.StartedAt or self.Destroyed then return end
	self.StartedAt = os.clock()
	if self.Config.ACCOUNT_SETTINGS.ENABLE_ACCOUNT_READER then
		if RunService:IsClient() then self:_load("LocalData", "Client.Framework.Services.LocalData")
		else self.Dependencies.LocalData = { Status = "ERROR", Path = "Client.Framework.Services.LocalData", Error = "Client runtime is required" } end
		for name, path in pairs({ Worlds = "Shared.Data.Worlds", Gum = "Shared.Data.Gum",
			Flavors = "Shared.Data.Flavors", Mastery = "Shared.Data.Mastery", StatsUtil = "Shared.Utils.Stats.StatsUtil" }) do
			self:_load(name, path)
		end
		if self.Config.FARMING_SETTINGS.AUTO_RESOURCE_FARM then
			if self.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS and self.Config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING
				and self.Config.PICKUP_SETTINGS.ENABLE_NATIVE_REGISTRY_DISCOVERY then
				self:_load("Tutorial", "Client.Tutorial") self:_load("Chunker", "Shared.Utils.Chunker")
			end
			self:_load("GetPickupZones", "Shared.Utils.GetPickupZones", "function")
			self:_load("Remote", "Shared.Framework.Network.Remote")
			self:_load("GuiFrame", "Client.Gui.GuiFrame")
			self:_load("PhysicalItem", "Client.Effects.PhysicalItem")
			self:_load("FishingPlayerRods", "Client.Gui.Frames.Fishing.FishingPlayerRods")
			self:_load("IsTradingPlaza", "Shared.Utils.IsTradingPlaza", "function")
		end
	end
	self:Refresh()
	if not self.Config.ACCOUNT_SETTINGS.ENABLE_ACCOUNT_READER then return end
	table.insert(self.Threads, task.spawn(function()
		while not self.Destroyed do
			task.wait(self.Config.ACCOUNT_SETTINGS.SNAPSHOT_REFRESH_SECONDS)
			if not self.Destroyed then self:Refresh() end
		end
	end))
end

function AccountStateReader:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	if self.RefreshThread then pcall(task.cancel, self.RefreshThread) end
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	for _, thread in ipairs(self.Threads) do pcall(task.cancel, thread) end
	self.Changed:Destroy()
end

return AccountStateReader

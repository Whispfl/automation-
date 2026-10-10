--!nonstrict
-- Native command adapter. Stationary pickup requests are experimental; server credit is never inferred from invocation.
local GameMechanics = {}
GameMechanics.__index = GameMechanics
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function GameMechanics.new(config, reader, tracker, player, log)
	return setmetatable({ Config = config, Reader = reader, Tracker = tracker, Player = player,
		LastBlowAt = -math.huge, LastTravelAt = -math.huge, Failures = {}, PathThread = nil, Log = log }, GameMechanics)
end

function GameMechanics:Guard()
	local root, humanoid = self.Tracker:Root()
	if not root then return false, "Character is not alive" end
	local plaza = self.Reader:_dependency("IsTradingPlaza")
	local frames = self.Reader:_dependency("GuiFrame")
	local rods = self.Reader:_dependency("FishingPlayerRods")
	if not plaza or not frames or not rods then return false, "Interaction guard modules are not ready" end
	local ok, reason = pcall(function()
		if plaza() then return "Trading plaza is active" end
		if self.Player:GetAttribute("InRace") then return "An island race owns movement" end
		if rods:GetRodComponent(self.Player) ~= nil then return "A fishing rod is active" end
		local gui = self.Player:FindFirstChild("PlayerGui")
		local screen = gui and gui:FindFirstChild("ScreenGui")
		if not gui or not screen then return "Game ScreenGui is unavailable" end
		if gui:FindFirstChild("Intro") or gui:FindFirstChild("TransitionGui") then return "Intro or transition is active" end
		local trading = screen:FindFirstChild("Trading")
		if trading and trading.Visible then return "Trading is active" end
		if screen:FindFirstChild("Prompt") or frames:IsAnyOpen() then return "A game prompt or frame is open" end
		return nil
	end)
	if not ok then return false, "Interaction guards failed: " .. tostring(reason) end
	if reason then return false, reason end
	return true, nil, root, humanoid
end

function GameMechanics:CanBlow()
	if self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST then return false, "Isolated stationary test blocks blowing" end
	if not self.Config.BUBBLE_SETTINGS.AUTO_BLOW_BUBBLES then return false, "Bubble blowing is disabled" end
	local allowed, reason = self:Guard()
	if not allowed then return false, reason end
	local raw = self.Reader:GetLiveProfile()
	if not raw or type(raw.Bubble) ~= "table" or type(raw.Settings) ~= "table" then return false, "Bubble profile is unavailable" end
	if raw.Settings["Bubble Lock"] == true then return false, "Bubble Lock is enabled" end
	local effects = self.Reader:_dependency("PhysicalItem")
	if not effects then return false, "PhysicalItem guard is unavailable" end
	if effects.IsGiftInRange then return false, "Gift interaction is active" end
	local screen = self.Player.PlayerGui.ScreenGui
	local hud, race = screen:FindFirstChild("HUD"), screen:FindFirstChild("IslandRace")
	if not ((hud and hud.Visible) or (race and race.Visible)) then return false, "Bubble HUD is hidden" end
	local capacity = self.Reader:_stat("GetBubbleStorage", raw, {})
	if type(raw.Bubble.Amount) ~= "number" or not capacity then return false, "Actual bubble capacity is unavailable" end
	if raw.Bubble.Amount >= capacity and not (raw.Passes and raw.Passes["Infinity Gum"]) then return false, "Bubble is full" end
	return true
end

function GameMechanics:Blow(token)
	if token:CheckCancelled() then return false end
	if os.clock() - self.LastBlowAt < self.Config.BUBBLE_SETTINGS.BLOW_COOLDOWN_SECONDS then return false end
	local permitted, reason = self:CanBlow()
	if not permitted then self.LastBlocker = reason return false end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then self.LastBlocker = "Native Remote module unavailable" return false end
	if token:CheckCancelled() then return false end
	self.LastBlowAt = os.clock()
	remote:FireServer("BlowBubble")
	self.LastBlocker = nil
	return true
end

function GameMechanics:Failure(key, seconds, reason)
	self.Failures[key] = { Until = os.clock() + seconds, Reason = reason }
end

function GameMechanics:Available(key)
	local failed = self.Failures[key]
	return not failed or os.clock() >= failed.Until
end

function GameMechanics:Unlocked(world, area)
	local raw = self.Reader:GetLiveProfile()
	return raw and type(raw.WorldsUnlocked) == "table" and raw.WorldsUnlocked[world] ~= nil
		and (world == area or (type(raw.AreasUnlocked) == "table" and raw.AreasUnlocked[area] ~= nil)) or false
end

function GameMechanics:CollectStationary(record, token)
	local settings = self.Config.PICKUP_SETTINGS
	if token:CheckCancelled() then return false, "Cancelled" end
	if self.PendingPickupCleanup then
		self:RetryPickupCleanup(token)
		if self.PendingPickupCleanup then return false, "Native visual cleanup is pending; new dispatches are held to prevent accumulation" end
	end
	if settings.COLLECTION_METHOD ~= "STATIONARY" or not settings.BULK_COLLECT_PICKUPS or not settings.ENABLE_CONTINUOUS_SCANNING then return false, "Stationary collection disabled" end
	if os.clock() - (self.LastPickupRequestAt or -math.huge) < settings.STATIONARY_REQUEST_COOLDOWN_SECONDS - 1e-6 then return false, "Stationary request cooldown" end
	local permitted, reason, root = self:Guard()
	if not permitted then return false, reason end
	local area = self.Tracker.Current
	if not area or area.World ~= "The Overworld" or (area.Name ~= "The Void" and area.Name ~= "Zen")
		or record.AreaKey ~= area.Key or not self:Unlocked(area.World, area.Name) then return false, "Stationary island excluded, stale or locked" end
	if self.Config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND and self.Config.ISLAND_SETTINGS.PREFERRED_FARMING_ISLAND ~= ""
		and os.clock() - (self.Tracker.ArrivedAt or os.clock()) < self.Config.ISLAND_SETTINGS.ARRIVAL_PICKUP_GRACE_SECONDS then return false, "Selected island/character stabilization pending" end
	local selected = self.Config.ISLAND_SETTINGS.SELECTED_ISLANDS
	local worlds = self.Config.BRAIN_SETTINGS.SELECTED_WORLDS
	if (#selected > 0 and not table.find(selected, area.Name) and not table.find(selected, area.Key))
		or (#worlds > 0 and not table.find(worlds, area.World)) then return false, "Stationary island excluded by Config" end
	local registry = self.Tracker.Knowledge:ActivePickups()
	local key = record.RegistryKey or record.Id
	local model = record.Model
	if type(key) ~= "string" and type(key) ~= "number" then return false, "Genuine registry ID unavailable" end
	if (type(key) == "number" and (key ~= key or math.abs(key) == math.huge)) or key == "" then return false, "Invalid native registry ID" end
	if not registry or registry[key] ~= model or not model or not model.Parent or not model:IsA("Model")
		or not model:IsDescendantOf(workspace) or tostring(key) ~= model.Name then return false, "Live native registry entry unavailable or changed" end
	if record.Currency ~= "Coins" and record.Currency ~= "Gems" then return false, "Stationary collection accepts only Coins/Gems" end
	local range = self.Tracker:ReadRange()
	local position = model:GetPivot().Position
	local distance = (position - root.Position).Magnitude
	local outsideNative = nil
	if range then outsideNative = distance > range end
	-- Distance/radius are observations only. Genuine loaded IDs are subject to the server's validation.
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local pickups = remotes and remotes:FindFirstChild("Pickups")
	local remote = pickups and pickups:FindFirstChild("CollectPickup")
	if not remote or not remote:IsA("RemoteEvent") then return false, "Native CollectPickup RemoteEvent unavailable" end
	local chunker, chunkerReason = self.Tracker.Knowledge:PickupChunker()
	if not chunker then return false, chunkerReason end
	if not chunker:IsValueLoaded(model) then return false, "Pickup is no longer in the native pickup Chunker" end
	local freshRegistry = self.Tracker.Knowledge:ActivePickups()
	if not self.Tracker.Current or self.Tracker.Current.Key ~= area.Key or not self:Unlocked(area.World, area.Name)
		or not freshRegistry or freshRegistry[key] ~= model or not model.Parent or tostring(key) ~= model.Name then return false, "Registry/island changed before dispatch" end
	if token:CheckCancelled() then return false, "Cancelled" end
	self.LastPickupRequestAt = os.clock()
	local ok, errorText = pcall(function() remote:FireServer(key) end)
	local cleaned, cleanupReason = false, nil
	if ok then
		self.PendingPickupCleanup = { Record = record, Chunker = chunker, Position = position, Until = os.clock() }
		cleaned, cleanupReason = self:RetryPickupCleanup({ CheckCancelled = function() return false end }) -- Finish cleanup of this already-dispatched request.
	end
	return true, ok and "Request invoked; credit awaits LocalData" or "Invocation error; credit unknown: " .. tostring(errorText),
		{ Id = tostring(key), Distance = distance, Radius = range, OutsideNativeRange = outsideNative, InvocationSucceeded = ok, VisualCleaned = cleaned, CleanupError = cleanupReason }
end

function GameMechanics:RetryPickupCleanup(token)
	local pending = self.PendingPickupCleanup
	if not pending then return true end
	if token:CheckCancelled() or os.clock() < pending.Until then return false, pending.Reason or "Native cleanup retry backoff" end
	local record, chunker = pending.Record, pending.Chunker
	local model, key = record.Model, record.RegistryKey or record.Id
	local ok, reason = pcall(function()
		local registry = self.Tracker.Knowledge:ActivePickups()
		if not registry then error("Native registry unavailable for cleanup") end
		if registry[key] ~= nil and registry[key] ~= model then error("Native registry replacement retained; cleanup pending") end
		-- Native Remove releases the actual chunk, Unloaded/animation state and registry entry.
		chunker:Remove(pending.Position, model) -- Also release a chunk that unloaded while cleanup was in backoff.
		if chunker:IsValueLoaded(model) then error("Native Chunker still retains pickup") end
		if registry[key] == model then registry[key] = nil end
		model:Destroy() self.Tracker:ForgetCollected(record)
	end)
	if ok then self.PendingPickupCleanup = nil
	else pending.Reason, pending.Until = tostring(reason), os.clock() + self.Config.PICKUP_SETTINGS.STATIONARY_ID_RETRY_SECONDS end
	return ok, not ok and tostring(reason) or nil
end

function GameMechanics:SellStations()
	local result, root = {}, self.Tracker:Root()
	if not root then return result end
	local worlds = workspace:FindFirstChild("Worlds")
	for _, model in ipairs(CollectionService:GetTagged("Activation")) do
		local stationRoot = model:FindFirstChild("Root")
		if model.Name ~= "Sell" or not model:IsDescendantOf(workspace) or not stationRoot or not stationRoot:IsA("BasePart") then continue end
		local node, world, area = model, nil, nil
		while node and node ~= workspace do
			if node.Parent and node.Parent.Name == "Islands" then area = node.Name end
			if node.Parent == worlds then world = node.Name end
			node = node.Parent
		end
		area = area or world
		-- Match the locations used by native HUD.findBestSell; nested VIP/event facilities have unverified access rules.
		local worldRoot = worlds and worlds:FindFirstChild(world or "")
		local islandRoot = worldRoot and worldRoot:FindFirstChild("Islands")
		local island = islandRoot and islandRoot:FindFirstChild(area or "")
		local islandModel = island and island:FindFirstChild("Island")
		if model.Parent ~= worldRoot and model.Parent ~= islandModel then continue end
		if not world or not self:Unlocked(world, area) or not self:Available("SELL:" .. model:GetFullName()) then continue end
		local multiplier = model:GetAttribute("Multiplier") or 1 -- Verified native HUD defaults.
		local currency = model:GetAttribute("Currency") or "Coins"
		if type(multiplier) ~= "number" or multiplier <= 0 or type(currency) ~= "string" then continue end
		self.Reader:RegisterCurrency(currency)
		table.insert(result, { Model = model, Root = stationRoot, Key = model:GetFullName(), World = world, Area = area,
			Currency = currency, Multiplier = multiplier, Distance = (stationRoot.Position - root.Position).Magnitude,
			SellCycleSeconds = self.SellTimes and self.SellTimes[model:GetFullName()],
			TravelSeconds = self.TravelTimes and self.TravelTimes[stationRoot:GetFullName()] })
	end
	return result
end

function GameMechanics:Travel(destination, world, area, token, islandTravel)
	if self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST and not islandTravel then return false, "Pickup-only mode blocks selling excursions" end
	local permitted, reason = self:Guard()
	if not permitted then return false, reason end
	if token:CheckCancelled() then return false, "Cancelled" end
	if not self.Config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND then return false, "Supported teleport travel is disabled" end
	if not destination or not destination.Parent or not destination:IsA("BasePart") or not destination:IsDescendantOf(workspace)
		or not self:Unlocked(world, area) then return false, "Destination is unavailable or locked" end
	local path = destination:GetFullName()
	if not self:Available("TRAVEL:" .. path) then return false, "Destination travel is in backoff" end
	if os.clock() - self.LastTravelAt < self.Config.ISLAND_SETTINGS.TRAVEL_COOLDOWN_SECONDS then return false, "Travel cooldown" end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then return false, "Native Remote module unavailable" end
	local started = os.clock()
	self.LastTravelAt = started
	if token:CheckCancelled() then return false, "Cancelled" end
	local sent, transportError = pcall(function() remote:FireServer("Teleport", path) end)
	if not sent then
		self:Failure("TRAVEL:" .. path, self.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS, tostring(transportError))
		return false, "Native teleport invocation failed: " .. tostring(transportError)
	end
	local arrivedAt
	while not token:CheckCancelled() and os.clock() - started < self.Config.ISLAND_SETTINGS.TRAVEL_CONFIRMATION_TIMEOUT_SECONDS do
		local root = self.Tracker:Root()
		if root and destination.Parent and (root.Position - destination.Position).Magnitude <= self.Config.ISLAND_SETTINGS.ARRIVAL_DISTANCE_STUDS then
			arrivedAt = arrivedAt or os.clock()
			if os.clock() - arrivedAt >= 0.4 then
				local seconds = os.clock() - started
				self.TravelTimes = self.TravelTimes or {} self.TravelTimes[path] = seconds
				return true, "Character arrival confirmed", seconds
			end
		else arrivedAt = nil end
		task.wait(0.1)
	end
	if not token:CheckCancelled() then self:Failure("TRAVEL:" .. path, self.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS, "Arrival was not confirmed") end
	return false, token:CheckCancelled() and "Cancelled" or "Arrival was not confirmed"
end

function GameMechanics:TravelIsland(area, token)
	if token:CheckCancelled() then return false, "Cancelled" end
	if not self.Config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND or not self.Config.ISLAND_SETTINGS.AUTO_SELECT_BEST_ISLAND then return false, "Native island selection/travel disabled" end
	if not self:Unlocked(area.World, area.Name) then return false, "Actual LocalData island/world access is locked or unavailable" end
	if self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST or self.Config.ISLAND_SETTINGS.PREFERRED_FARMING_ISLAND ~= "" then
		local selected = self.Config.ISLAND_SETTINGS.SELECTED_ISLANDS
		if area.World ~= "The Overworld" or (area.Name ~= "Zen" and area.Name ~= "The Void")
			or (#selected > 0 and not table.find(selected, area.Name) and not table.find(selected, area.Key)) then return false, "Farming teleport destination is excluded" end
	end
	if self.Tracker.Current and self.Tracker.Current.Key == area.Key then
		local root = self.Tracker:Root()
		for _, zone in ipairs(self.Tracker.Current.Zones or {}) do
			if root and math.abs(root.Position.Y - zone.Data.Zone.Height) <= self.Config.PICKUP_SETTINGS.MAXIMUM_VERTICAL_DIFFERENCE_STUDS
				and zone.Data.Zone:GetDistanceToPoint(root.Position) <= self.Config.PICKUP_SETTINGS.MAXIMUM_ROUTE_DISTANCE_STUDS then
				return true, "Already on selected island; no teleport dispatched", 0
			end
		end
	end
	if area.Spawn then return self:Travel(area.Spawn, area.World, area.Name, token, true) end
	local permitted, reason = self:Guard()
	if not permitted then return false, reason end
	if token:CheckCancelled() then return false, "Cancelled" end
	local path = area.DestinationPath
	local expected = "Workspace.Worlds." .. tostring(area.World) .. ".Islands." .. tostring(area.Name) .. ".Island.Portal.Spawn"
	if not self.Config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND or not self.Config.ISLAND_SETTINGS.AUTO_SELECT_BEST_ISLAND
		or not area.CatalogKnown or path ~= expected or area.MappingWarning or not self:Unlocked(area.World, area.Name) then
		return false, "Native island destination/access/zone evidence unavailable"
	end
	if not self:Available("TRAVEL:" .. path) or os.clock() - self.LastTravelAt < self.Config.ISLAND_SETTINGS.TRAVEL_COOLDOWN_SECONDS then return false, "Travel cooldown/backoff" end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then return false, "Native Remote module unavailable" end
	local started, stable = os.clock(), nil
	self.LastTravelAt = started
	-- Matches native WorldMap/WorldUtil; a server destination need not be replicated locally.
	if token:CheckCancelled() then return false, "Cancelled" end
	local sent, transportError = pcall(function() remote:FireServer("Teleport", path) end)
	if not sent then
		self:Failure("TRAVEL:" .. path, self.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS, tostring(transportError))
		return false, "Native teleport invocation failed: " .. tostring(transportError)
	end
	while not token:CheckCancelled() and os.clock() - started < self.Config.ISLAND_SETTINGS.TRAVEL_CONFIRMATION_TIMEOUT_SECONDS do
		self.Tracker:Refresh(self.Reader:GetSnapshot(), os.clock())
		local actual = self.Tracker.Current
		local root = self.Tracker:Root()
		local inside = false
		if root and actual and actual.Key == area.Key then
			for _, zone in ipairs(actual.Zones) do
				if math.abs(root.Position.Y - zone.Data.Zone.Height) <= self.Config.PICKUP_SETTINGS.MAXIMUM_VERTICAL_DIFFERENCE_STUDS
					and zone.Data.Zone:GetDistanceToPoint(root.Position) <= self.Config.PICKUP_SETTINGS.MAXIMUM_ROUTE_DISTANCE_STUDS then inside = true break end
			end
		end
		if inside then
			stable = stable or os.clock()
			if os.clock() - stable >= 0.4 then
				local seconds = os.clock() - started
				self.TravelTimes = self.TravelTimes or {} self.TravelTimes[path] = seconds
				return true, "Actual island height and nearby target pickup-zone arrival confirmed", seconds
			end
		else stable = nil end
		task.wait(0.2)
	end
	if not token:CheckCancelled() then self:Failure("TRAVEL:" .. path, self.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS, "Target pickup-zone arrival unconfirmed") end
	return false, token:CheckCancelled() and "Cancelled" or "Target pickup-zone arrival unconfirmed"
end

function GameMechanics:StopMovement()
	-- Compatibility hook: this build never owns character movement or pathfinding.
end

function GameMechanics:Walk()
	return false, "OC automatic walking has been removed; no pickup movement fallback"
end

function GameMechanics:Upgrade(upgrade, token)
	if self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST then return false, "Isolated stationary test blocks upgrades" end
	if token:CheckCancelled() then return false, "Cancelled" end
	local permitted, reason = self:Guard()
	if not permitted then return false, reason end
	local config, raw = self.Config, self.Reader:GetLiveProfile()
	if not config.FARMING_SETTINGS.AUTO_RESOURCE_FARM or not config.UPGRADE_SETTINGS.ENABLE_SMART_UPGRADES then return false, "Upgrade automation disabled" end
	if upgrade.Kind == "Gum" and not config.UPGRADE_SETTINGS.ENABLE_CAPACITY_UPGRADES then return false, "Capacity upgrades disabled" end
	if upgrade.Kind == "Flavors" and not config.UPGRADE_SETTINGS.ENABLE_FLAVOR_UPGRADES then return false, "Flavor upgrades disabled" end
	if not raw or type(raw.Bubble) ~= "table" then return false, "No real account/equipment profile" end
	if not self:Available("UPGRADE:" .. upgrade.Name) then return false, "Upgrade is in backoff" end
	local definitions = self.Reader:_dependency(upgrade.Kind)
	local definition = definitions and definitions[upgrade.Name]
	if not definition or type(definition.Cost) ~= "table" or definition.Cost.Type ~= "Currency" then return false, "Verified nonpremium definition unavailable" end
	if definition.Area and not ((raw.AreasUnlocked and raw.AreasUnlocked[definition.Area] ~= nil) or (raw.WorldsUnlocked and raw.WorldsUnlocked[definition.Area] ~= nil)) then
		return false, "Upgrade area is locked" end
	if type(raw[upgrade.Kind]) ~= "table" then return false, "Actual ownership map unavailable" end
	local currentOwned = raw[upgrade.Kind][upgrade.Name] ~= nil
	local evidence = { Name = upgrade.Name, Kind = upgrade.Kind, OwnedBefore = currentOwned, Cost = definition.Cost.Amount, Currency = definition.Cost.Currency }
	local command
	if currentOwned then
		if not config.UPGRADE_SETTINGS.AUTO_EQUIP_OWNED_UPGRADES then return false, "Owned upgrade equip disabled" end
		command = upgrade.Kind == "Gum" and "UpdateStorage" or "UpdateFlavor"
	else
		local enabled = upgrade.Kind == "Gum" and config.BUBBLE_SETTINGS.AUTO_BUY_GUM or (upgrade.Kind == "Flavors" and config.BUBBLE_SETTINGS.AUTO_BUY_FLAVORS)
		if not enabled then return false, "Purchase disabled" end
		local cost = definition.Cost
		if cost.Currency == "Robux" or not table.find(config.UPGRADE_SETTINGS.ALLOWED_PURCHASE_CURRENCIES, cost.Currency) then return false, "Purchase currency is not explicitly authorized" end
		local funds = raw[cost.Currency]
		if type(funds) ~= "number" or type(cost.Amount) ~= "number" or cost.Amount < 0 then return false, "Actual funds or cost unknown" end
		local spendable = math.max(0, funds - (upgrade.Reserve or 0) - (upgrade.GoalReserve or 0))
		if cost.Amount > config.UPGRADE_SETTINGS.MAXIMUM_PURCHASE_COST or cost.Amount > spendable * config.RESOURCE_SETTINGS.MAXIMUM_UPGRADE_BALANCE_FRACTION then
			return false, "Actual funds no longer meet goal reserve and purchase budget" end
		evidence.BeforeBalance = funds
		command = "GumShopPurchase"
	end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then return false, "Native Remote unavailable" end
	if token:CheckCancelled() then return false, "Cancelled" end
	self.LastUpgrade = evidence
	self:Failure("UPGRADE:" .. upgrade.Name, config.UPGRADE_SETTINGS.PURCHASE_RETRY_COOLDOWN_SECONDS, "Awaiting ownership/equipment confirmation")
	if self.Log then self.Log("UPGRADE][PURCHASE", upgrade.Name .. " | command=" .. command .. " | currency=" .. tostring(evidence.Currency) .. " cost=" .. tostring(evidence.Cost) .. " before=" .. tostring(evidence.BeforeBalance or "owned equip")) end
	remote:FireServer(command, upgrade.Name)
	local deadline = os.clock() + config.UPGRADE_SETTINGS.PURCHASE_CONFIRMATION_TIMEOUT_SECONDS
	while not token:CheckCancelled() and os.clock() < deadline do
		local live = self.Reader:GetLiveProfile()
		if live then
			local owned = live[upgrade.Kind] and live[upgrade.Kind][upgrade.Name] ~= nil
			local equipped = live.Bubble and live.Bubble[upgrade.Kind == "Gum" and "Gum" or "Flavor"] == upgrade.Name
			evidence.OwnedAfter, evidence.Equipped = owned, equipped
			evidence.AfterBalance = live[evidence.Currency]
			if not currentOwned and type(evidence.AfterBalance) == "number" then
				evidence.ObservedDeduction = math.max(evidence.ObservedDeduction or 0, evidence.BeforeBalance - evidence.AfterBalance)
			end
			local paid = not currentOwned and (evidence.Cost == 0 or (evidence.ObservedDeduction or 0) >= evidence.Cost)
			if (not currentOwned and owned and paid) or (currentOwned and equipped) then
				evidence.Verified = true
				return true, currentOwned and "Actual equipped upgrade changed" or ("Actual ownership received and currency deduction observed: " .. tostring(evidence.ObservedDeduction)), evidence
			end
		end
		task.wait(0.2)
	end
	local reason = token:CheckCancelled() and "Cancelled" or (currentOwned and "Equipment change unconfirmed" or
		("Purchase unconfirmed: ownership=" .. tostring(evidence.OwnedAfter) .. "; observed deduction=" .. tostring(evidence.ObservedDeduction or 0) .. "; required=" .. tostring(evidence.Cost)))
	return false, reason, evidence
end

return GameMechanics

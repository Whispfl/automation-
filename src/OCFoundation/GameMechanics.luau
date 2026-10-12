--!nonstrict
-- Native command adapter. Stationary pickup requests are experimental; server credit is never inferred from invocation.
local GameMechanics = {}
GameMechanics.__index = GameMechanics
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function GameMechanics.new(config, reader, tracker, player, log)
	return setmetatable({ Config = config, Reader = reader, Tracker = tracker, Player = player,
		LastBlowAt = -math.huge, LastTravelAt = -math.huge, LastDiscoveryAt = -math.huge,
		IslandDiscoveryAttempts = {}, Failures = {}, PathThread = nil, Log = log }, GameMechanics)
end

function GameMechanics:Guard(expectedUnlockTitle)
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
		if screen:FindFirstChild("Prompt") then return "A game prompt or frame is open" end
		if frames:IsAnyOpen() then
			-- Native gate entry itself opens Unlock. Permit only its exact expected world title.
			local unlock = screen:FindFirstChild("Unlock")
			local frame = unlock and unlock:FindFirstChild("Frame")
			local top = frame and frame:FindFirstChild("Top")
			local label = top and top:FindFirstChild("Label")
			if not expectedUnlockTitle or not frames.IsOpen or not frames:IsOpen("Unlock") or frames:IsOpen("WorldMap")
				or not label or label.Text ~= expectedUnlockTitle then return "A game prompt or frame is open" end
		end
		return nil
	end)
	if not ok then return false, "Interaction guards failed: " .. tostring(reason) end
	if reason then return false, reason end
	return true, nil, root, humanoid
end

function GameMechanics:CanBlow()
	if not self:BubbleRequirement() then return false, "No active verified unfinished bubble task" end
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
	if not self:BubbleRequirement() then return false end
	if os.clock() - self.LastBlowAt < self.Config.BUBBLE_SETTINGS.BLOW_COOLDOWN_SECONDS then return false end
	local permitted, reason = self:CanBlow()
	if not permitted then self.LastBlocker = reason return false end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then self.LastBlocker = "Native Remote module unavailable" return false end
	if token:CheckCancelled() then return false end
	if not self:BubbleRequirement() then return false end
	self.LastBlowAt = os.clock()
	remote:FireServer("BlowBubble")
	self.LastBlocker = nil
	return true
end

function GameMechanics:BubbleRequirement()
	return self.BubbleGoalProvider and self.BubbleGoalProvider() or nil
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
	local hatchLocation = self.HatchLocationProvider and self.HatchLocationProvider(area)
	if not area or (not hatchLocation and (area.World ~= "The Overworld" or (area.Name ~= "The Void" and area.Name ~= "Zen")))
		or record.AreaKey ~= area.Key or not self:Unlocked(area.World, area.Name) then return false, "Stationary island excluded, stale or locked" end
	if self.Config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND and self.Config.ISLAND_SETTINGS.PREFERRED_FARMING_ISLAND ~= ""
		and os.clock() - (self.Tracker.ArrivedAt or os.clock()) < self.Config.ISLAND_SETTINGS.ARRIVAL_PICKUP_GRACE_SECONDS then return false, "Selected island/character stabilization pending" end
	local selected = self.Config.ISLAND_SETTINGS.SELECTED_ISLANDS
	local worlds = self.Config.BRAIN_SETTINGS.SELECTED_WORLDS
	if not hatchLocation and ((#selected > 0 and not table.find(selected, area.Name) and not table.find(selected, area.Key))
		or (#worlds > 0 and not table.find(worlds, area.World))) then return false, "Stationary island excluded by Config" end
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
	if hatchLocation and not self.HatchLocationProvider(area) then return false, "Hatch location ownership ended before pickup dispatch" end
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

function GameMechanics:Travel(destination, world, area, token, islandTravel, sellingTravel)
	if self.PetLocationOwnerProvider and self.PetLocationOwnerProvider() then return false, "Authorized hatch task owns location" end
	local hatch = self.Config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE and self.Config.PET_SETTINGS.AUTO_HATCH and self.Reader:_dependency("HatchPresentation")
	if hatch then local ok, active = pcall(function() return hatch:IsHatching() end) if not ok or active ~= false then return false, "Native hatch presentation owns movement" end end
	if sellingTravel and not self:BubbleRequirement() then return false, "Selling travel requires an active verified bubble task" end
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
	if sellingTravel and not self:BubbleRequirement() then return false, "Bubble task ended before selling travel" end
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
	local selected = self.Config.ISLAND_SETTINGS.SELECTED_ISLANDS
	if area.World ~= "The Overworld" or (area.Name ~= "Zen" and area.Name ~= "The Void")
		or (#selected > 0 and not table.find(selected, area.Name) and not table.find(selected, area.Key)) then return false, "Farming teleport destination is excluded" end
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
		local major = self.ProgressionReserveProvider and self.ProgressionReserveProvider()
		local goalReserve = math.max(upgrade.GoalReserve or 0, major and major.Currency == cost.Currency and major.Amount or 0)
		local spendable = math.max(0, funds - (upgrade.Reserve or 0) - goalReserve)
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

function GameMechanics:IslandDiscoveryCapability()
	return { Available = type(firetouchinterest) == "function", Method = "RUNTIME_SIMULATED_CONTACT",
		Source = "Runtime global firetouchinterest; not a native Studio Luau API", ServerValidation = "UNVERIFIED",
		SavedPersistence = "OWNER_REJOIN_TEST_REQUIRED" }
end

function GameMechanics:IslandDiscovery(node)
	if not node or node.Kind ~= "ISLAND" or node.World ~= "The Overworld" then return nil, "Only researched Overworld island hitboxes are supported by this discovery experiment" end
	if not self:IslandDiscoveryCapability().Available then return nil, "Runtime firetouchinterest unavailable; stationary discovery cannot dispatch; no climbing or movement fallback" end
	local raw, definitions = self.Reader:GetLiveProfile(), self.Reader:_dependency("Worlds")
	if not raw or type(raw.AreasUnlocked) ~= "table" or type(raw.WorldsUnlocked) ~= "table" then return nil, "Actual LocalData discovery/world maps unavailable" end
	if raw.WorldsUnlocked[node.World] == nil then return nil, "Discovery origin world is not unlocked" end
	if raw.AreasUnlocked[node.Name] ~= nil then return nil, "Island already discovered in actual LocalData; refresh the Brain" end
	local worldDefinition = definitions and definitions[node.World]
	local nativeIsland
	for _, island in ipairs(worldDefinition and worldDefinition.Islands or {}) do if island.Name == node.Name then nativeIsland = island break end end
	if not nativeIsland or worldDefinition.Event or worldDefinition.Removed then return nil, "Island is absent from the native permanent Overworld definition" end
	local root = self.Tracker:Root()
	local util = self.Reader:_dependency("WorldUtil")
	if not root or not root.Parent or not util or util:GetPlayerWorld(self.Player) ~= node.World then return nil, "Alive character in the actual Overworld is required; no automatic travel for discovery" end
	local worlds = workspace:FindFirstChild("Worlds")
	local world = worlds and worlds:FindFirstChild(node.World)
	local islands = world and world:FindFirstChild("Islands")
	local island = islands and islands:FindFirstChild(node.Name)
	local model = island and island:FindFirstChild("Island")
	local hitbox = model and model:FindFirstChild("UnlockHitbox")
	if not hitbox or not hitbox:IsA("BasePart") or not hitbox:IsDescendantOf(workspace) or not hitbox.CanTouch or not hitbox.Anchored then
		return nil, "Correct native Island.UnlockHitbox is missing, unloaded or not touch-enabled"
	end
	if root.CanTouch == false then return nil, "Character root has native contact disabled" end
	return { Root = root, Hitbox = hitbox, Path = hitbox:GetFullName(), Distance = (root.Position-hitbox.Position).Magnitude,
		NativeIsland = nativeIsland, Contact = firetouchinterest }
end

function GameMechanics:EndIslandContact()
	local contact = self.PendingIslandContact
	if not contact then return true end
	self.PendingIslandContact = nil -- One end call only, including Pause/Stop and transport errors.
	local ok, reason = pcall(contact.Callback, contact.Root, contact.Hitbox, 1)
	contact.EndSucceeded, contact.EndReason = ok, reason
	if not ok then self.Log("ISLAND][CONTACT", "Contact end failed for " .. contact.Id .. ": " .. tostring(reason) .. "; outcome unconfirmed") end
	return ok, reason
end

function GameMechanics:DiscoverIsland(node, token)
	local settings = self.Config.WORLD_SETTINGS
	local function current()
		local goal = self.ProgressionGoalProvider and self.ProgressionGoalProvider()
		return not token:CheckCancelled() and settings.ENABLE_WORLD_PROGRESSION and settings.AUTO_DISCOVER_ISLANDS
			and not self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST and goal and goal.Kind == "ISLAND" and goal.Id == node.Id
	end
	if not current() then return false, "Discovery disabled, isolated, cancelled or Brain goal changed" end
	local raw = self.Reader:GetLiveProfile()
	if raw and type(raw.AreasUnlocked) == "table" and raw.AreasUnlocked[node.Name] ~= nil then return true, "Already discovered in actual LocalData; no contact replay" end
	local discovery, reason = self:IslandDiscovery(node)
	if not discovery then return false, reason end
	local permitted, guardReason = self:Guard()
	if not permitted then return false, guardReason end
	if self.PendingIslandContact then return false, "A previous contact must finish before another attempt" end
	if not self:Available("DISCOVER:" .. node.Id) or os.clock()-self.LastDiscoveryAt < settings.ISLAND_DISCOVERY_INTERVAL_SECONDS then return false, "Discovery retry/global pacing" end
	if (self.IslandDiscoveryAttempts[node.Id] or 0) >= settings.MAXIMUM_ISLAND_DISCOVERY_ATTEMPTS then return false, "Island contact attempt limit reached" end
	local graph = self.Reader:GetSnapshot().ProgressionGraph
	if not graph or not graph.Next or graph.Next.Id ~= node.Id then return false, "Fresh Brain graph no longer selects this discovery island" end
	-- Recheck identities and received flags immediately before touching; no position or account writes.
	local fresh = self:IslandDiscovery(node)
	if not current() or not fresh or fresh.Root ~= discovery.Root or fresh.Hitbox ~= discovery.Hitbox or fresh.Contact ~= discovery.Contact then return false, "Discovery character, hitbox, runtime capability, access or goal changed" end
	local beforePosition = discovery.Root.Position
	self.IslandDiscoveryAttempts[node.Id] = (self.IslandDiscoveryAttempts[node.Id] or 0)+1
	self.LastDiscoveryAt = os.clock()
	self:Failure("DISCOVER:" .. node.Id, settings.ISLAND_DISCOVERY_RETRY_COOLDOWN_SECONDS, "Awaiting actual island acknowledgement")
	local contactRecord = { Callback = discovery.Contact, Root = discovery.Root, Hitbox = discovery.Hitbox, Id = node.Id }
	self.PendingIslandContact = contactRecord
	self.Log("ISLAND][ATTEMPT", string.format("%s | attempt=%d/%d | distance=%.2f | %s | discoveryBefore=absent | runtime simulated contact, server acceptance unknown",
		node.Id, self.IslandDiscoveryAttempts[node.Id], settings.MAXIMUM_ISLAND_DISCOVERY_ATTEMPTS, discovery.Distance, discovery.Path))
	local began, beginReason = pcall(discovery.Contact, discovery.Root, discovery.Hitbox, 0)
	local contactUntil = os.clock()+settings.ISLAND_DISCOVERY_CONTACT_SECONDS
	while began and current() and os.clock() < contactUntil and self.PendingIslandContact do task.wait(math.min(0.05, contactUntil-os.clock())) end
	local ended, endReason = self:EndIslandContact() -- End is cleanup of this attempt, even after cancellation; never another begin.
	ended, endReason = contactRecord.EndSucceeded, contactRecord.EndReason
	local evidence = { Island = node.Name, BeginSucceeded = began, EndSucceeded = ended, AccountAcknowledged = false, SavedPersistenceVerified = false }
	if not began or not ended then return false, "Runtime contact failed; no discovery inferred: " .. tostring(beginReason or endReason), evidence end
	local started, deadline = self.LastDiscoveryAt, os.clock()+settings.ISLAND_DISCOVERY_CONFIRMATION_TIMEOUT_SECONDS
	while current() and os.clock() < deadline do
		local actual = self.Reader:GetLiveProfile()
		if not actual or type(actual.AreasUnlocked) ~= "table" or type(actual.WorldsUnlocked) ~= "table" then return false, "Actual discovery account maps became unavailable", evidence end
		if actual.WorldsUnlocked[node.World] == nil then return false, "Actual origin world access changed", evidence end
		if actual.AreasUnlocked[node.Name] ~= nil then
			evidence.AccountAcknowledged, evidence.Seconds = true, os.clock()-started
			evidence.CharacterDelta = (discovery.Root.Position-beforePosition).Magnitude
			self.Failures["DISCOVER:" .. node.Id] = nil
			self:EndIslandContact()
			self.Reader:Refresh()
			self.Log("ISLAND][VERIFIED", string.format("%s | LocalData.AreasUnlocked: absent -> present | seconds=%.2f | characterDelta=%.2f | saved persistence requires rejoin test", node.Name, evidence.Seconds, evidence.CharacterDelta))
			return true, "Correct current LocalData discovery acknowledged; saved persistence unverified", evidence
		end
		local allowed, blocker = self:Guard()
		if not allowed then return false, blocker, evidence end
		local actualRoot = self.Tracker:Root()
		if actualRoot ~= discovery.Root or not discovery.Hitbox:IsDescendantOf(workspace) then return false, "Character or discovery hitbox changed during acknowledgement", evidence end
		task.wait(0.1)
	end
	return false, token:CheckCancelled() and "Cancelled; an already-issued contact cannot be recalled" or "Discovery unconfirmed: no correct LocalData.AreasUnlocked acknowledgement; contact invocation is not proof", evidence
end

function GameMechanics:WorldGate(name)
	local definitions, raw = self.Reader:_dependency("Worlds"), self.Reader:GetLiveProfile()
	local definition = definitions and definitions[name]
	if not definition or definition.Event or definition.Removed or not raw or type(raw.WorldsUnlocked) ~= "table"
		or type(raw.AreasUnlocked) ~= "table" then return nil, "Native definition or real unlock maps unavailable" end
	if raw.WorldsUnlocked[name] ~= nil then return nil, "Already unlocked; no request" end
	local worlds, found = workspace:FindFirstChild("Worlds"), nil
	for _, model in ipairs(CollectionService:GetTagged("WorldGate")) do
		if model:IsDescendantOf(workspace) and model:GetAttribute("World") == name then
			if found then return nil, "Ambiguous native WorldGate" end
			found = model
		end
	end
	if not found then return nil, "Native WorldGate unavailable" end
	local node, origin, area = found, nil, nil
	while node and node ~= workspace do
		if node.Parent and node.Parent.Name == "Islands" then area = node.Name end
		if node.Parent == worlds then origin = node.Name end
		node = node.Parent
	end
	if not origin or not self:Unlocked(origin, area or origin) then return nil, "Actual gate origin/discovery prerequisite locked or unknown" end
	local activation = found:FindFirstChild("Activation")
	local target = activation and activation:FindFirstChild("Root")
	if not target or not target.Parent or not target:IsA("BasePart") then return nil, "Live gate Activation.Root unavailable" end
	local root = self.Tracker:Root()
	if not root then return nil, "Character unavailable" end
	local horizontalDistance = ((root.Position - target.Position) * Vector3.new(1, 0, 1)).Magnitude
	local verticalDifference, horizontalLimit = math.abs(root.Position.Y - target.Position.Y), target.Size.Y / 2
	local inRange = horizontalDistance <= horizontalLimit and verticalDifference <= 10 -- Client.Activation:357-360
	local originWorld = worlds and worlds:FindFirstChild(origin)
	local islands = originWorld and originWorld:FindFirstChild("Islands")
	local island = islands and area and islands:FindFirstChild(area)
	local islandModel = island and island:FindFirstChild("Island")
	local portal = islandModel and islandModel:FindFirstChild("Portal")
	local spawn = portal and portal:FindFirstChild("Spawn")
	local expectedPath = area and "Workspace.Worlds." .. origin .. ".Islands." .. area .. ".Island.Portal.Spawn" or nil
	if not spawn or not spawn:IsA("BasePart") or spawn:GetFullName() ~= expectedPath then spawn = nil end
	local catalogIsland = false
	for _, candidate in ipairs((definitions[origin] or {}).Islands or {}) do if candidate.Name == area then catalogIsland = true break end end
	local areaObservation = self.Tracker.Areas and self.Tracker.Areas[origin .. "/" .. tostring(area)]
	local zones = {}
	if catalogIsland and areaObservation and areaObservation.CatalogKnown and areaObservation.DestinationPath == expectedPath and not areaObservation.MappingWarning then
		for _, zone in ipairs(areaObservation.Zones or {}) do if not zone.IsTransit then table.insert(zones, zone) end end
	end
	local current = self.Tracker.Current
	local atIsland = current and current.World == origin and current.Name == area or false
	if not atIsland then
		local util = self.Reader:_dependency("WorldUtil")
		local actualWorld = util and util:GetPlayerWorld(self.Player)
		local highest, currentArea = -math.huge, nil
		for _, candidate in ipairs(islands and islands:GetChildren() or {}) do
			local height = candidate:GetAttribute("Height")
			if type(height) == "number" and height <= root.Position.Y and height > highest then highest, currentArea = height, candidate.Name end
		end
		atIsland = actualWorld == origin and currentArea == area
	end
	return { Name = name, Model = found, OriginWorld = origin, RequiredIsland = area, Root = target,
		Spawn = spawn, DestinationPath = catalogIsland and expectedPath or nil, Zones = zones,
		AtOriginIsland = atIsland or inRange, InRange = inRange, Cost = definition.UnlockCost, Order = definition.Order,
		HorizontalDistance = horizontalDistance, VerticalDifference = verticalDifference, HorizontalLimit = horizontalLimit, VerticalLimit = 10 }
end

function GameMechanics:_gateTravelAuthorized(gate)
	local settings, cost, raw = self.Config.WORLD_SETTINGS, gate.Cost, self.Reader:GetLiveProfile()
	local active = self.ProgressionGoalProvider and self.ProgressionGoalProvider()
	if not active or active.Name ~= gate.Name or active.Kind ~= "WORLD" then return false, "Active Brain world objective changed" end
	if not settings.ENABLE_WORLD_PROGRESSION or not settings.AUTO_TRAVEL_FOR_PROGRESSION then return false, "Progression travel disabled" end
	if not settings.AUTO_UNLOCK_WORLDS then return false, "World spending disabled; no gate travel" end
	if (self.SessionUnlockRequests or 0) >= settings.MAXIMUM_SESSION_WORLD_UNLOCKS
		or (self.UnlockAttempts or {})[gate.Name] and self.UnlockAttempts[gate.Name] >= settings.MAXIMUM_UNLOCK_ATTEMPTS
		or not self:Available("UNLOCK:" .. gate.Name) then return false, "World request limit/backoff blocks gate travel" end
	if type(cost) ~= "table" or cost.Type ~= "Currency" or cost.Currency == "Robux"
		or not table.find(settings.ALLOWED_UNLOCK_CURRENCIES, cost.Currency) or type(cost.Amount) ~= "number"
		or cost.Amount ~= cost.Amount or cost.Amount < 0 or cost.Amount == math.huge
		or cost.Amount > settings.MAXIMUM_WORLD_UNLOCK_COST then return false, "Native gate cost/currency exceeds explicit authorization" end
	local reserveKey = ({ Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" })[cost.Currency]
	local reserve = reserveKey and self.Config.RESOURCE_SETTINGS[reserveKey] or 0
	local balance = raw and raw[cost.Currency]
	if type(balance) ~= "number" or balance ~= balance or balance == math.huge or balance < cost.Amount + reserve then
		return false, "Actual funds insufficient or unknown after reserve; no gate travel"
	end
	return true
end

function GameMechanics:TravelForProgression(name, token)
	if self.PetLocationOwnerProvider and self.PetLocationOwnerProvider() then return false, "Authorized hatch task owns location" end
	local hatch = self.Config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE and self.Config.PET_SETTINGS.AUTO_HATCH and self.Reader:_dependency("HatchPresentation")
	if hatch then local ok, active = pcall(function() return hatch:IsHatching() end) if not ok or active ~= false then return false, "Native hatch presentation owns movement" end end
	local settings = self.Config.WORLD_SETTINGS
	if token:CheckCancelled() then return false, "Cancelled" end
	if not settings.ENABLE_WORLD_PROGRESSION or not settings.AUTO_TRAVEL_FOR_PROGRESSION then return false, "Progression travel disabled" end
	local active = self.ProgressionGoalProvider and self.ProgressionGoalProvider()
	if not active or active.Name ~= name or active.Kind ~= "WORLD" then return false, "Active Brain world objective changed" end
	local gate, blocker = self:WorldGate(name)
	if not gate then return false, blocker end
	local authorized, authorizationReason = self:_gateTravelAuthorized(gate)
	if not authorized then return false, authorizationReason end
	if gate.AtOriginIsland then return true, "Already at gate island; no teleport", 0 end
	if not gate.Spawn and (not gate.DestinationPath or #gate.Zones == 0) then return false, "Native portal arrival geometry unavailable; no unverified travel" end
	local permitted, reason = self:Guard()
	if not permitted then return false, reason end
	local destination, path = gate.Spawn, gate.Spawn and gate.Spawn:GetFullName() or gate.DestinationPath
	if not self:Available("TRAVEL:" .. path) or os.clock() - self.LastTravelAt < self.Config.ISLAND_SETTINGS.TRAVEL_COOLDOWN_SECONDS then return false, "Travel cooldown/backoff" end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then return false, "Native Remote unavailable" end
	permitted, reason = self:Guard()
	if not permitted then return false, reason end
	if token:CheckCancelled() then return false, "Cancelled" end
	local fresh = self:WorldGate(name)
	if not fresh or fresh.Spawn ~= destination or fresh.DestinationPath ~= gate.DestinationPath then return false, "Gate access/destination changed" end
	authorized, authorizationReason = self:_gateTravelAuthorized(fresh)
	if not authorized then return false, authorizationReason end
	if token:CheckCancelled() then return false, "Cancelled" end
	local started, stable = os.clock(), nil
	self.LastTravelAt = started
	self.ProgressionTravelRequests = (self.ProgressionTravelRequests or 0) + 1
	self:Failure("TRAVEL:" .. path, self.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS, "Awaiting progression arrival")
	local sent, errorText = pcall(function() remote:FireServer("Teleport", path) end)
	if not sent then return false, "Native teleport invocation failed: " .. tostring(errorText) end
	while not token:CheckCancelled() and os.clock() - started < self.Config.ISLAND_SETTINGS.TRAVEL_CONFIRMATION_TIMEOUT_SECONDS do
		local root = self.Tracker:Root()
		local inside = root and destination and destination.Parent and (root.Position - destination.Position).Magnitude <= self.Config.ISLAND_SETTINGS.ARRIVAL_DISTANCE_STUDS or false
		if root and not destination then
			for _, zone in ipairs(gate.Zones) do
				if zone.Root and zone.Root.Parent and zone.Root:IsDescendantOf(workspace) and zone.Data and zone.Data.Zone
					and math.abs(root.Position.Y - zone.Data.Zone.Height) <= self.Config.PICKUP_SETTINGS.MAXIMUM_VERTICAL_DIFFERENCE_STUDS
					and zone.Data.Zone:GetDistanceToPoint(root.Position) <= self.Config.PICKUP_SETTINGS.MAXIMUM_ROUTE_DISTANCE_STUDS then inside = true break end
			end
		end
		if inside and self:Unlocked(gate.OriginWorld, gate.RequiredIsland) then
			stable = stable or os.clock()
			if os.clock() - stable >= settings.TRAVEL_STABILIZATION_SECONDS then
				self.Failures["TRAVEL:" .. path] = nil return true, "Native portal arrival stabilized", os.clock() - started
			end
		else stable = nil end
		task.wait(0.1)
	end
	return false, token:CheckCancelled() and "Cancelled" or "Progression portal arrival unconfirmed"
end

function GameMechanics:UnlockWorld(name, token)
	local settings = self.Config.WORLD_SETTINGS
	if token:CheckCancelled() then return false, "Cancelled" end
	if not settings.ENABLE_WORLD_PROGRESSION or not settings.AUTO_UNLOCK_WORLDS then return false, "World spending disabled" end
	local active = self.ProgressionGoalProvider and self.ProgressionGoalProvider()
	if not active or active.Name ~= name or active.Kind ~= "WORLD" then return false, "Active Brain world objective changed" end
	local gate, blocker = self:WorldGate(name)
	if not gate then return false, blocker end
	if not gate.InRange then return false, "Outside native gate activation range; manual approach required, no pickup or gate walking" end
	local permitted, reason = self:Guard("World " .. tostring(gate.Order))
	if not permitted then return false, reason end
	local cost, raw = gate.Cost, self.Reader:GetLiveProfile()
	if type(cost) ~= "table" or cost.Type ~= "Currency" or cost.Currency == "Robux"
		or not table.find(settings.ALLOWED_UNLOCK_CURRENCIES, cost.Currency) or type(cost.Amount) ~= "number"
		or cost.Amount ~= cost.Amount or cost.Amount < 0 or cost.Amount > settings.MAXIMUM_WORLD_UNLOCK_COST then return false, "Native unlock cost/currency exceeds explicit authorization" end
	local reserveKey = ({ Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" })[cost.Currency]
	local reserve = reserveKey and self.Config.RESOURCE_SETTINGS[reserveKey] or 0
	if not raw or type(raw[cost.Currency]) ~= "number" or raw[cost.Currency] ~= raw[cost.Currency]
		or raw[cost.Currency] == math.huge or raw[cost.Currency] < cost.Amount + reserve then return false, "Actual funds insufficient or unknown after reserve" end
	if not self:Available("UNLOCK:" .. name) then return false, "Unlock retry cooldown" end
	self.UnlockAttempts = self.UnlockAttempts or {}
	if (self.UnlockAttempts[name] or 0) >= settings.MAXIMUM_UNLOCK_ATTEMPTS then return false, "Per-world unlock attempt limit reached" end
	if (self.SessionUnlockRequests or 0) >= settings.MAXIMUM_SESSION_WORLD_UNLOCKS then return false, "Controller lifetime unlock request limit reached" end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then return false, "Native Remote unavailable" end
	-- No yield between final live checks and dispatch. Ledger survives cancellation/Stop.
	if token:CheckCancelled() then return false, "Cancelled" end
	local fresh = self:WorldGate(name)
	if not fresh or fresh.Model ~= gate.Model or not fresh.InRange or fresh.Cost ~= cost then return false, "Gate contract/access changed before dispatch" end
	self.UnlockAttempts[name] = (self.UnlockAttempts[name] or 0) + 1
	self.SessionUnlockRequests = (self.SessionUnlockRequests or 0) + 1
	self:Failure("UNLOCK:" .. name, settings.UNLOCK_RETRY_COOLDOWN_SECONDS, "Awaiting actual world unlock acknowledgement")
	local evidence = { Name = name, Currency = cost.Currency, Cost = cost.Amount, BeforeBalance = raw[cost.Currency], BeforeUnlocked = false, Verified = false }
	if self.Log then self.Log("WORLD][REQUEST", name .. " | UnlockWorld | cost=" .. cost.Amount .. " " .. cost.Currency .. " | before=" .. evidence.BeforeBalance .. " | unlockBefore=false") end
	local sent, errorText = pcall(function() remote:FireServer("UnlockWorld", name) end)
	if not sent then return false, "Unlock invocation failed; delivery/credit unknown: " .. tostring(errorText), evidence end
	local started = os.clock()
	while not token:CheckCancelled() and os.clock() - started < settings.UNLOCK_CONFIRMATION_TIMEOUT_SECONDS do
		local live = self.Reader:GetLiveProfile()
		evidence.AfterBalance = live and live[cost.Currency]
		evidence.AfterUnlocked = live and type(live.WorldsUnlocked) == "table" and live.WorldsUnlocked[name] ~= nil or false
		if evidence.AfterUnlocked then
			evidence.Verified = true
			evidence.ObservedDeduction = type(evidence.AfterBalance) == "number" and evidence.BeforeBalance - evidence.AfterBalance or nil
			if self.Log then self.Log("WORLD][VERIFIED", name .. " | LocalData.WorldsUnlocked: false -> true | " .. cost.Currency .. " before=" .. evidence.BeforeBalance .. " after=" .. tostring(evidence.AfterBalance) .. " deduction=" .. tostring(evidence.ObservedDeduction) .. " | external balance sources may contribute") end
			-- Close only the native result panel for this exact world, without faking gate animations.
			local frames = self.Reader:_dependency("GuiFrame")
			local matches = self:Guard("World " .. tostring(gate.Order))
			if matches and frames and frames.IsOpen and frames:IsOpen("Unlock") then frames:Close() end
			self.Reader:Refresh()
			return true, "Actual LocalData world unlock confirmed; account refreshed", evidence
		end
		task.wait(0.2)
	end
	return false, token:CheckCancelled() and "Cancelled; dispatched request cannot be recalled" or "Unlock unconfirmed: no LocalData WorldsUnlocked acknowledgement", evidence
end

-- Pet managers prepare evidence/ledgers; only this shared adapter invokes native
-- commands, inside the single foreground scheduler task. No yield after final guards.
function GameMechanics:PetAction(manager, decision, token)
	if token:CheckCancelled() or manager.Controller.State ~= "RUNNING" then return false, "Cancelled or stopped" end
	local permitted, blocker = self:Guard()
	if not permitted then return false, blocker end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then return false, "Native Remote unavailable" end
	local command, first, second, reason = manager:Prepare(decision, token)
	if not command then return false, reason end
	-- Prepare validates fresh account, authorization, limits and native interfaces,
	-- then records the pending request before even an uncertain invocation.
	local ok, err = pcall(function() remote:FireServer(command, first, second) end)
	if not ok then manager:Uncertain("Pet invocation failed; delivery unknown: " .. tostring(err)) end
	return true, ok and "Dispatched; awaiting received LocalData result" or manager.Fault
end


-- Narrow owner-authorized local features. No account fields or native geometry are changed.
local function featureFinite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function GameMechanics:LocalFeatureGuard()
	local allowed, reason, root, humanoid = self:Guard()
	if not allowed then return false, reason end
	local c = self.LocalFeatureController
	if not c or c.State ~= "RUNNING" then return false, "Local feature controller is not running" end
	local ok, blocker = pcall(function()
		local input = game:GetService("UserInputService")
		if input:GetFocusedTextBox() ~= nil then return "Typing owns input" end
		local hatch = self.Reader:_dependency("HatchPresentation")
		if not hatch or type(hatch.IsHatching) ~= "function" or hatch:IsHatching() ~= false then return "Native hatch presentation active or unavailable" end
		local scripts = self.Player:FindFirstChild("PlayerScripts")
		local client = scripts and scripts:FindFirstChild("ClientScript")
		local auto = client and client:FindFirstChild("GetAutoHatchStatus")
		if not auto or not auto:IsA("BindableFunction") or auto:Invoke() ~= nil then return "Native auto-hatch active or unavailable" end
		if c.Pets and (c.Pets.PendingEquip or c.Pets.Hatch.Pending) then return "Pending pet operation owns presentation" end
		return nil
	end)
	if not ok then return false, "Local feature guards unavailable: " .. tostring(blocker) end
	if blocker then return false, blocker end
	return true, nil, root, humanoid
end

function GameMechanics:TravelSelectedEgg(manager, record, token)
	local c = self.LocalFeatureController
	if not c or manager ~= c.EggTravel or not c.Scheduler.Active or c.Scheduler.Active.Definition.Owner ~= "EGG_TRAVEL" then return false, "Selected-egg task does not own the scheduler" end
	if not self.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL then return false, "Selected-egg native travel disabled" end
	local fresh, reason = manager:Validate(record, token)
	if not fresh then return false, reason end
	local allowed, blocker = self:LocalFeatureGuard()
	if not allowed then return false, blocker end
	fresh, reason = manager:Validate(record, token) -- Guard can yield; all eligibility is rechecked.
	if not fresh then return false, reason end
	if not fresh.NeedsNativeTravel then return true, "Already in selected area; no unnecessary native teleport" end
	local path = fresh.DestinationPath
	if not fresh.NativeAreaKnown or type(path) ~= "string" or not self:Unlocked(fresh.World, fresh.Island) then return false, "Exact unlocked native egg-area destination unavailable" end
	if fresh.Island then
		if path ~= "Workspace.Worlds." .. fresh.World .. ".Islands." .. fresh.Island .. ".Island.Portal.Spawn" then return false, "Selected area path does not match native contract" end
	elseif not fresh.Destination or not fresh.Destination.Parent or fresh.Destination:GetFullName() ~= path then return false, "Observed world return destination disappeared" end
	if os.clock() - self.LastTravelAt < self.Config.ISLAND_SETTINGS.TRAVEL_COOLDOWN_SECONDS then return false, "Native travel cooldown; explicit rearm after bounded failure" end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then return false, "Native Remote unavailable" end
	if token:CheckCancelled() or not self.Config.EGG_TRAVEL_SETTINGS.ENABLE_NATIVE_ISLAND_TRAVEL then return false, "Cancelled" end
	local beforePosition = fresh.CharacterRoot.Position
	local destination = fresh.Destination
	self.LastTravelAt = os.clock()
	local sent, err = pcall(function() remote:FireServer("Teleport", path) end)
	if not sent then return false, "Native area travel delivery uncertain: " .. tostring(err) end
	local started, stable = os.clock(), nil
	while os.clock() - started < self.Config.EGG_TRAVEL_SETTINGS.ARRIVAL_TIMEOUT_SECONDS do
		fresh, reason = manager:Validate(record, token)
		if not fresh then return false, reason end
		local spawnObserved = destination and destination.Parent and destination:IsDescendantOf(workspace)
			and (fresh.CharacterRoot.Position - destination.Position).Magnitude <= self.Config.ISLAND_SETTINGS.ARRIVAL_DISTANCE_STUDS
		local transitionObserved = not destination and not fresh.NeedsNativeTravel
			and (fresh.CharacterRoot.Position - beforePosition).Magnitude > 1
		if not fresh.NeedsNativeTravel and (spawnObserved or transitionObserved) then
			stable = stable or os.clock()
			if os.clock() - stable >= 0.4 then return true, "Native target-area arrival observed; egg range still requires verification" end
		else stable = nil end
		task.wait(0.1)
	end
	return false, "Native target-area arrival unconfirmed"
end

function GameMechanics:PositionSelectedEgg(manager, record, frame, token)
	local c = self.LocalFeatureController
	if not c or manager ~= c.EggTravel or not c.Scheduler.Active or c.Scheduler.Active.Definition.Owner ~= "EGG_TRAVEL" then return false, "Selected-egg task does not own the scheduler" end
	if not self.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING then return false, "Direct egg positioning disabled" end
	local fresh, reason = manager:Validate(record, token)
	if not fresh then return false, reason end
	local allowed, blocker = self:LocalFeatureGuard()
	if not allowed then return false, blocker end
	fresh, reason = manager:Validate(record, token)
	if not fresh then return false, reason end
	if fresh.NeedsNativeTravel then return false, "Correct unlocked native area must be reached first" end
	local clearedFrame, clearanceReason = manager:ResolveStanding(fresh)
	if not clearedFrame then return false, clearanceReason end
	if typeof(frame) ~= "CFrame" or (frame.Position - clearedFrame.Position).Magnitude > 0.25 then return false, "Standing geometry changed during guards; explicit rearm required" end
	frame = clearedFrame -- Assign exactly the freshly cleared avatar orientation/volume.
	if typeof(frame) ~= "CFrame" or not featureFinite(frame.Position.X) or not featureFinite(frame.Position.Y)
		or not featureFinite(frame.Position.Z) or not fresh.RangeOrigin
		or (frame.Position - fresh.RangeOrigin.Position).Magnitude > fresh.Range
		or not manager:RangeEligibleAt(fresh, frame.Position) then return false, "Validated standing transform unavailable or outside actual native hatch eligibility" end
	if self.LastEggPositionLease == record.LeaseId then return false, "Direct position already attempted for this lease" end
	if token:CheckCancelled() or not self.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING then return false, "Cancelled" end
	self.LastEggPositionLease = record.LeaseId -- Mark before assignment; failure cannot trigger repeated snapping.
	local assigned, err = pcall(function() fresh.CharacterRoot.CFrame = frame end)
	return assigned, assigned and "Direct CFrame assigned; observed arrival/stability/range still pending" or "Direct position failed: " .. tostring(err)
end

function GameMechanics:RewardsContext()
	local raw = self.Reader:GetLiveProfile()
	local result = { Raw = raw, UserId = self.Player and self.Player.UserId, Balances = self.Reader:ReadBalances(),
		GiftIds = {}, GiftRecords = {}, CanClaim = false, CanOpen = false, GiftCompletionAvailable = false }
	local time, playtime = self.Reader:_dependency("Time"), self.Reader:_dependency("Playtime")
	if time and type(time.now) == "function" then local ok, value = pcall(time.now) if ok and featureFinite(value) then result.NativeNow = value end end
	result.PlaytimeGifts = playtime and playtime.Gifts
	if raw and type(raw.MasteryUpgrades) == "table" then
		result.HasPlaytime = false
		for _, upgrade in pairs(raw.MasteryUpgrades) do if type(upgrade) == "table" and upgrade.Type == "Playtime" then result.HasPlaytime = true break end end
	end
	local plaza = self.Reader:_dependency("IsTradingPlaza")
	if type(plaza) == "function" then local ok, value = pcall(plaza) if ok and type(value) == "boolean" then result.IsTradingPlaza = value end end
	local item, constants, powerups = self.Reader:_dependency("ItemUtil"), self.Reader:_dependency("Constants"), self.Reader:_dependency("Powerups")
	if raw and item and type(item.GetOwnedAmount) == "function" then
		local ok, value = pcall(item.GetOwnedAmount, item, raw, { Type = "Powerup", Name = "Mystery Box" })
		if ok and featureFinite(value) and value >= 0 and value % 1 == 0 then result.OwnedBoxes = value end
	end
	if constants and featureFinite(constants.MaxSpawnableLimit) and constants.MaxSpawnableLimit >= 1 then result.MaxGiftCount = constants.MaxSpawnableLimit end
	local physical, giftClass = self.Reader:_dependency("PhysicalItem"), self.Reader:_dependency("PhysicalGift")
	local identityOK, identity = false, nil
	if type(self.Reader.GetNativeGiftFacts) == "function" then identityOK, identity = pcall(self.Reader.GetNativeGiftFacts, self.Reader) end
	if identityOK and type(identity) == "table" and identity.Available == true then
		result.GiftIdentityAvailable = true
		result.GiftIdentityEpoch, result.GiftRevision = identity.Epoch, identity.Revision
	end
	if physical and type(physical.GetActiveObjects) == "function" then
		local ok, total = pcall(physical.GetActiveObjects, physical, "Gift")
		if ok and featureFinite(total) and total >= 0 and total % 1 == 0 then result.GiftCount = total end
	end
	if physical and type(physical.GetActiveGifts) == "function" then
		local ok, active = pcall(physical.GetActiveGifts, physical)
		if ok and type(active) == "table" then
			for instance, component in pairs(active) do
				-- Native GetActiveGifts is the loaded Instance -> component subset.
				-- The component has a BasePart Model and no item Name. Item identity
				-- comes only from received RenderGifts facts, never guessed geometry.
				local model = type(component) == "table" and component.Model
				if model == instance and typeof(model) == "Instance" and model:IsA("BasePart") and model.Parent and model:IsDescendantOf(workspace) then
					local id = model.Name
					result.GiftIds[id] = true
					local fact = result.GiftIdentityAvailable and type(identity.Records) == "table" and identity.Records[id]
					if type(fact) == "table" and fact.Name == "Mystery Box" and type(component.Hit) == "function" then
						result.GiftRecords[id] = { Id = id, Name = fact.Name, IdentityEpoch = identity.Epoch,
							Revision = fact.Revision, Model = model, Component = component }
					end
				end
			end
			result.GiftCompletionAvailable = result.GiftIdentityAvailable == true and result.GiftCount ~= nil
				and giftClass ~= nil and type(giftClass.Hit) == "function"
		end
	end
	local allowed, reason = self:LocalFeatureGuard()
	result.Reason = reason
	result.CanClaim = allowed and raw ~= nil and result.IsTradingPlaza == false and result.GiftCount == 0
	result.CanOpen = result.CanClaim and powerups ~= nil and powerups["Mystery Box"] ~= nil
		and result.GiftCompletionAvailable and result.OwnedBoxes ~= nil and result.MaxGiftCount ~= nil
	return result
end

function GameMechanics:RewardAction(manager, decision, token)
	local c = self.LocalFeatureController
	if not c or manager ~= c.Rewards or not c.Scheduler.Active or c.Scheduler.Active.Definition.Owner ~= "REWARDS" then return false, "Reward task does not own the scheduler" end
	if token:CheckCancelled() or manager.Controller.State ~= "RUNNING" then return false, "Cancelled" end
	local allowed, reason = self:LocalFeatureGuard()
	if not allowed then return false, reason end
	local remote = self.Reader:_dependency("Remote")
	if not remote then return false, "Native Remote unavailable" end
	if decision.Kind ~= "PLAYTIME" and decision.Kind ~= "MYSTERY_BOX" then return false, "Unsupported reward intent" end
	if decision.Kind == "PLAYTIME" and type(remote.InvokeServer) ~= "function"
		or decision.Kind == "MYSTERY_BOX" and type(remote.FireServer) ~= "function" then return false, "Required native transport unavailable before preparation" end
	local command, first, second, pending = manager:Prepare(decision, token)
	if not command then return false, pending end
	if command ~= "ClaimPlaytime" and not (command == "UseGift" and first == "Mystery Box" and second == 1) then manager:AbortPreparation(pending, "Unsupported local reward command") return false, "Unsupported local reward command" end
	if command == "ClaimPlaytime" and type(remote.InvokeServer) ~= "function" or command == "UseGift" and type(remote.FireServer) ~= "function" then manager:AbortPreparation(pending, "Required native transport unavailable") return false, "Required native transport unavailable" end
	manager.Controller:MarkNonPickupReward(pending)
	if command == "ClaimPlaytime" then
		-- Start transport within this positive foreground lease, then bound the
		-- parent's observation slice even if InvokeServer waits indefinitely.
		self.RewardRPCs = self.RewardRPCs or {}
		local thread = task.spawn(function()
			local active = c.Scheduler.Active
			if token:CheckCancelled() or c.State ~= "RUNNING" or not self.Config.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME
				or not active or active.Definition.Owner ~= "REWARDS" or active.Definition.Generation ~= c.Generation then
				manager:AbortPreparation(pending, "Cancelled or stale before playtime transport") return
			end
			if not manager:MarkDispatched(pending) then manager:AbortPreparation(pending, "Dispatch reservation rejected") return end
			pending.TransportStarted = true
			local ok, output = pcall(function() return remote:InvokeServer(command, first) end)
			manager:DispatchReturned(pending, ok, output)
		end)
		self.RewardRPCs[thread] = true
	else
		if not manager:MarkDispatched(pending) then manager:AbortPreparation(pending, "Dispatch reservation rejected") return false, "Dispatch reservation rejected" end
		pending.TransportStarted = true
		local ok, output = pcall(function() return remote:FireServer(command, first, second) end)
		manager:DispatchReturned(pending, ok, output)
	end
	return true, "Request recorded; received acknowledgement required"
end

function GameMechanics:CancelRewardTransport()
	for thread in pairs(self.RewardRPCs or {}) do pcall(task.cancel, thread) end
	self.RewardRPCs = {}
end

function GameMechanics:AdvanceMysteryGift(pending, token)
	local c = self.LocalFeatureController
	if not c or c.State ~= "RUNNING" or not c.Scheduler.Active or c.Scheduler.Active.Definition.Owner ~= "REWARDS" then return false, "Gift task does not own the scheduler" end
	if not self.Config.MYSTERY_BOX_SETTINGS.AUTO_OPEN_MYSTERY_BOXES or not c.Rewards or not c.Rewards.Ledger
		or c.Rewards.Ledger.Pending ~= pending or pending.Kind ~= "MYSTERY_BOX" or pending.Attempted ~= true then return false, "Gift task lacks its exact attempted owned-box operation" end
	if token:CheckCancelled() then return false, "Cancelled" end
	local allowed, reason, root = self:LocalFeatureGuard()
	if not allowed then return false, reason end
	local context = self:RewardsContext()
	if not context.GiftCompletionAvailable then return false, "Native gift completion representation unavailable" end
	if os.clock() - (self.LastOrdinaryGiftHit or -math.huge) < 0.5 then return false, "Native gift hit pacing" end
	for id, record in pairs(context.GiftRecords) do
		if id == pending.GiftId and not pending.AmbiguousGift and not pending.BeforeGiftIds[id] and record.Name == "Mystery Box" and record.Model.Parent
			and context.GiftIdentityAvailable == true and context.GiftIdentityEpoch == pending.GiftIdentityEpoch
			and record.IdentityEpoch == pending.GiftIdentityEpoch and featureFinite(record.Revision)
			and featureFinite(pending.BeforeGiftRevision) and record.Revision > pending.BeforeGiftRevision
			and featureFinite(context.GiftRevision) and record.Revision <= context.GiftRevision
			and record.Component.InRange == true and type(record.Component.Hit) == "function" then
			local okPosition, position = pcall(function() return record.Model:GetPivot().Position end)
			local physical = self.Reader:_dependency("PhysicalItem")
			if okPosition and physical and physical.IsGiftInRange == true
				and ((position - root.Position) * Vector3.new(1, 0, 1)).Magnitude <= 15 then
				if token:CheckCancelled() or self.LocalFeatureController.State ~= "RUNNING" then return false, "Cancelled" end
				local active = c.Scheduler.Active
				if not active or active.Definition.Owner ~= "REWARDS" or active.Definition.Generation ~= c.Generation
					or c.Rewards.Ledger.Pending ~= pending or not self.Config.MYSTERY_BOX_SETTINGS.AUTO_OPEN_MYSTERY_BOXES then return false, "Gift lease/operation changed during guards" end
				self.LastOrdinaryGiftHit = os.clock()
				local ok, err = pcall(record.Component.Hit, record.Component)
				return ok, ok and "Guarded native ordinary gift Hit; reward still unverified" or tostring(err)
			end
		end
	end
	return false, "No correlated in-range ordinary gift with verified completion interface; manual completion may be required"
end

function GameMechanics:AntiAFKCapability(method)
	if method ~= "VIRTUAL_INPUT_SCROLL_LOCK" then return { Available = false, Reason = "Unsupported method; native AFK reporting ignores mouse movement" } end
	local ok, service = pcall(game.GetService, game, "VirtualInputManager")
	local readable, callable, key = pcall(function()
		return service and type(service.SendKeyEvent) == "function" and Enum.KeyCode.ScrollLock ~= nil, Enum.KeyCode.ScrollLock
	end)
	if not ok or not readable or not callable then return { Available = false, Method = method, Reason = "VirtualInputManager.SendKeyEvent / ScrollLock unavailable in this runtime" } end
	return { Available = true, Method = method, Status = "API_PRESENT_PERMISSION_UNTESTED", Service = service, Key = key }
end

function GameMechanics:AntiAFKGuard(manager)
	local c = manager.Controller
	if c.State ~= "RUNNING" or not self.Config.ANTIAFK_SETTINGS.ENABLE_ANTI_AFK then return false, "Anti-AFK disabled/stopped" end
	local active = c.Scheduler.Active
	if active and active.Definition.Owner ~= "ANTI_AFK" then return false, "Another scheduler task owns input" end
	if c.EggTravel:OwnsLocation() or c.Pets.Hatch.Location or c.Pets.Hatch.Pending or c.Pets.PendingEquip then return false, "Egg travel/hatch/equipment owns interaction" end
	local rewards = c.Rewards:GetStatus()
	if rewards.Pending then return false, "Reward/gift operation pending or uncertain" end
	local allowed, reason = self:LocalFeatureGuard()
	if not allowed then return false, reason end
	local ok, blocker = pcall(function()
		local raw = self.Reader:GetLiveProfile()
		if not raw or type(raw.Settings) ~= "table" then return "Fresh native keybind settings unavailable" end
		for _, value in pairs(raw.Settings) do
			if value == "ScrollLock" or value == "Enum.KeyCode.ScrollLock" then return "ScrollLock is assigned to a native game action" end
		end
		local report = self.Reader:_dependency("AFKReport")
		if not report or type(report.Get) ~= "function" then return "Native AFK report guard unavailable" end
		local state = report:Get()
		if type(state) ~= "table" or type(state.Pets) ~= "table" or next(state.Pets) ~= nil then return "AFK report/reveal has pending or unknown pet results" end
		local playerGui = self.Player:FindFirstChild("PlayerGui")
		local screen = playerGui and playerGui:FindFirstChild("ScreenGui")
		local afk, reveal = screen and screen:FindFirstChild("AFK"), screen and screen:FindFirstChild("AFKReveal")
		if not afk or not reveal or afk.Visible ~= false or reveal.Visible ~= false then return "Native AFK/report presentation active or unavailable" end
		local input = game:GetService("UserInputService")
		local camera, point = workspace.CurrentCamera, input:GetMouseLocation()
		local viewport = camera and camera.ViewportSize
		if not point or not viewport or not featureFinite(point.X) or not featureFinite(point.Y)
			or point.X < 2 or point.Y < 2 or point.X > viewport.X - 2 or point.Y > viewport.Y - 2 then return "Actual pointer/camera outside safe viewport" end
		if input.MouseBehavior ~= Enum.MouseBehavior.Default then return "Locked camera/cursor owns movement" end
		if #input:GetKeysPressed() > 0 or #input:GetMouseButtonsPressed() > 0 then return "Real keyboard/mouse input is active" end
		local gui = game:GetService("GuiService")
		if gui.MenuIsOpen then return "Roblox menu is open" end
		local physical = self.Reader:_dependency("PhysicalItem")
		if not physical or type(physical.GetActiveObjects) ~= "function" then return "Total gift input guard unavailable" end
		local gifts = physical:GetActiveObjects("Gift")
		if gifts ~= 0 then return "Gift interaction is active or unknown, including unloaded gifts" end
		return nil
	end)
	if not ok then return false, "Anti-AFK guards unavailable: " .. tostring(blocker) end
	return blocker == nil, blocker
end

function GameMechanics:AntiAFKPulse(manager, token)
	local c = self.LocalFeatureController
	if not c or manager ~= c.AntiAFK or not c.Scheduler.Active or c.Scheduler.Active.Definition.Owner ~= "ANTI_AFK"
		or c.Scheduler.Active.Definition.Generation ~= c.Generation then return false, "SUPPRESSED: anti-AFK task lacks current scheduler lease" end
	if token:CheckCancelled() then return false, "SUPPRESSED: Cancelled" end
	local allowed, reason = self:AntiAFKGuard(manager)
	if not allowed then return false, "SUPPRESSED: " .. tostring(reason) end
	local capability = self:AntiAFKCapability(self.Config.ANTIAFK_SETTINGS.METHOD)
	if not capability.Available then return false, capability.Reason end
	if self.AntiAFKHeldInput then return false, "Previous simulated input has not been released" end
	if token:CheckCancelled() or manager.Controller.State ~= "RUNNING" then return false, "SUPPRESSED: Cancelled before keyDown" end
	local active = c.Scheduler.Active
	if manager ~= c.AntiAFK or not active or active.Definition.Owner ~= "ANTI_AFK"
		or active.Definition.Generation ~= c.Generation then return false, "SUPPRESSED: anti-AFK lease changed during guards" end
	-- Reserve before keyDown: even an API error can leave delivery uncertain.
	-- Pause/Stop/Destroy can synchronously release this exact service/key.
	self.AntiAFKHeldInput = { Service = capability.Service, Key = capability.Key }
	local ok, output = pcall(function()
		capability.Service:SendKeyEvent(true, capability.Key, false, game)
		return nil
	end)
	local released, releaseReason = self:ReleaseAntiAFKInput()
	if not released then return false, "ScrollLock release failed; input delivery uncertain: " .. tostring(releaseReason) end
	if not ok or output then return false, tostring(ok and output or output) end
	return true, "Unassigned ScrollLock down/up API accepted; native activity reception and idle-prevention effectiveness remain owner-tested"
end

function GameMechanics:ReleaseAntiAFKInput()
	local held = self.AntiAFKHeldInput
	if not held then return true, "No simulated key/button held" end
	local ok, reason = pcall(function() held.Service:SendKeyEvent(false, held.Key, false, game) end)
	if ok then self.AntiAFKHeldInput = nil return true, "ScrollLock released" end
	return false, tostring(reason)
end

return GameMechanics

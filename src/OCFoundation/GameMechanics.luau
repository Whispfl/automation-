--!nonstrict
-- Only native commands inspected in HUD, WorldMap and GumShop. No pickup remote calls.
local GameMechanics = {}
GameMechanics.__index = GameMechanics
local CollectionService = game:GetService("CollectionService")

function GameMechanics.new(config, reader, tracker, player)
	return setmetatable({ Config = config, Reader = reader, Tracker = tracker, Player = player,
		LastBlowAt = -math.huge, LastTravelAt = -math.huge, Failures = {}, PathThread = nil }, GameMechanics)
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
			TravelSeconds = self.TravelTimes and self.TravelTimes[stationRoot:GetFullName()] })
	end
	return result
end

function GameMechanics:Travel(destination, world, area, token)
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
	remote:FireServer("Teleport", path)
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
	if area.Spawn then return self:Travel(area.Spawn, area.World, area.Name, token) end
	local permitted, reason = self:Guard()
	if not permitted then return false, reason end
	if token:CheckCancelled() then return false, "Cancelled" end
	local path = area.DestinationPath
	local expected = "Workspace.Worlds." .. tostring(area.World) .. ".Islands." .. tostring(area.Name) .. ".Island.Portal.Spawn"
	if not self.Config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND or not self.Config.ISLAND_SETTINGS.AUTO_SELECT_BEST_ISLAND
		or not area.CatalogKnown or path ~= expected or #area.Zones == 0 or area.MappingWarning or not self:Unlocked(area.World, area.Name) then
		return false, "Native island destination/access/zone evidence unavailable"
	end
	if not self:Available("TRAVEL:" .. path) or os.clock() - self.LastTravelAt < self.Config.ISLAND_SETTINGS.TRAVEL_COOLDOWN_SECONDS then return false, "Travel cooldown/backoff" end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then return false, "Native Remote module unavailable" end
	local started, stable = os.clock(), nil
	self.LastTravelAt = started
	-- Matches native WorldMap/WorldUtil; a server destination need not be replicated locally.
	remote:FireServer("Teleport", path)
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
	if self.PathThread then pcall(task.cancel, self.PathThread) self.PathThread = nil end
	local lease = self.MovementLease
	self.MovementLease = nil
	if lease and lease.Root.Parent then
		pcall(function() lease.Humanoid:MoveTo(lease.Root.Position) lease.Humanoid:Move(Vector3.zero) end)
	end
end

function GameMechanics:Walk(point, token, deadline, tick, finished)
	local permitted, reason, root, humanoid = self:Guard()
	if not permitted then return false, reason end
	local settings = self.Config.PICKUP_SETTINGS
	local start = root.Position
	local function reached(position, waypoint)
		-- Pathfinding waypoints lie on the floor; HumanoidRootPart is above it.
		local dx, dz = position.X - waypoint.X, position.Z - waypoint.Z
		return dx * dx + dz * dz <= 9 and math.abs(position.Y - waypoint.Y) <= math.min(8, settings.MAXIMUM_VERTICAL_DIFFERENCE_STUDS)
	end
	if (point - start).Magnitude <= 2 then return true, "Already in range" end
	if math.abs(point.Y - start.Y) > settings.MAXIMUM_VERTICAL_DIFFERENCE_STUDS then return false, "Destination is outside current island height" end
	local path = game:GetService("PathfindingService"):CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
	local computed, computeError
	self.PathThread = task.spawn(function()
		local success, message = pcall(function() path:ComputeAsync(start, point) end)
		computed, computeError = success, message
	end)
	local computeDeadline = math.min(deadline, os.clock() + settings.PATH_TIMEOUT_SECONDS)
	while computed == nil and not token:CheckCancelled() and os.clock() < computeDeadline do task.wait(0.1) end
	if self.PathThread then pcall(task.cancel, self.PathThread) self.PathThread = nil end
	if token:CheckCancelled() then path:Destroy() return false, "Cancelled" end
	if computed ~= true or path.Status ~= Enum.PathStatus.Success then path:Destroy() return false, "No supported path: " .. tostring(computeError) end
	local waypoints = path:GetWaypoints()
	local length, previous = 0, start
	for _, waypoint in ipairs(waypoints) do
		length += (waypoint.Position - previous).Magnitude previous = waypoint.Position
		if math.abs(waypoint.Position.Y - start.Y) > settings.MAXIMUM_VERTICAL_DIFFERENCE_STUDS then path:Destroy() return false, "Path leaves current island height" end
	end
	if length > settings.MAXIMUM_ROUTE_DISTANCE_STUDS or length > math.max(8, (point - start).Magnitude * settings.MAXIMUM_PATH_DETOUR_RATIO) then
		path:Destroy() return false, "Path requires excessive travel" end
	local blocked
	local connection = path.Blocked:Connect(function(index) blocked = index end)
	local result, message = true, "Cluster reached"
	for index, waypoint in ipairs(waypoints) do
		if index == 1 then continue end
		if finished and finished() then break end
		if token:CheckCancelled() or os.clock() >= deadline then result, message = false, "Slice ended" break end
		if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
		self.MovementLease = { Root = root, Humanoid = humanoid }
		humanoid:MoveTo(waypoint.Position)
		local waypointDeadline = math.min(deadline, os.clock() + settings.PATH_TIMEOUT_SECONDS)
		while not token:CheckCancelled() and os.clock() < waypointDeadline do
			local liveRoot = self.Tracker:Root()
			local active, blockReason = self:Guard()
			if not liveRoot or not active then result, message = false, blockReason or "Character unavailable" break end
			if blocked and blocked >= index then result, message = false, "Path was blocked" break end
			if reached(liveRoot.Position, waypoint.Position) then break end
			if finished and finished() then break end
			if tick then tick() end
			task.wait(0.1)
		end
		if not result then break end
		local liveRoot = self.Tracker:Root()
		if token:CheckCancelled() then result, message = false, "Cancelled" break end
		if not (finished and finished()) and (not liveRoot or not reached(liveRoot.Position, waypoint.Position)) then
			result, message = false, os.clock() >= deadline and "Slice ended" or "Waypoint stalled" break
		end
	end
	connection:Disconnect() path:Destroy()
	self:StopMovement()
	return result, message
end

function GameMechanics:Upgrade(upgrade, token)
	if token:CheckCancelled() then return false, "Cancelled" end
	local permitted, reason = self:Guard()
	if not permitted then return false, reason end
	local config, raw = self.Config, self.Reader:GetLiveProfile()
	if not config.FARMING_SETTINGS.AUTO_RESOURCE_FARM or not config.UPGRADE_SETTINGS.ENABLE_SMART_UPGRADES then return false, "Upgrade automation disabled" end
	if upgrade.Kind == "Gum" and not config.UPGRADE_SETTINGS.ENABLE_CAPACITY_UPGRADES then return false, "Capacity upgrades disabled" end
	if upgrade.Kind == "Flavors" and not config.UPGRADE_SETTINGS.ENABLE_FLAVOR_UPGRADES then return false, "Flavor upgrades disabled" end
	if not raw then return false, "No real account profile" end
	if not self:Available("UPGRADE:" .. upgrade.Name) then return false, "Upgrade is in backoff" end
	local definitions = self.Reader:_dependency(upgrade.Kind)
	local definition = definitions and definitions[upgrade.Name]
	if not definition or type(definition.Cost) ~= "table" or definition.Cost.Type ~= "Currency" then return false, "Verified nonpremium definition unavailable" end
	if definition.Area and not ((raw.AreasUnlocked and raw.AreasUnlocked[definition.Area] ~= nil) or (raw.WorldsUnlocked and raw.WorldsUnlocked[definition.Area] ~= nil)) then
		return false, "Upgrade area is locked" end
	local currentOwned = raw[upgrade.Kind] and raw[upgrade.Kind][upgrade.Name] ~= nil
	local command
	if currentOwned then
		if not config.UPGRADE_SETTINGS.AUTO_EQUIP_OWNED_UPGRADES then return false, "Owned upgrade equip disabled" end
		command = upgrade.Kind == "Gum" and "UpdateStorage" or "UpdateFlavor"
	else
		local enabled = upgrade.Kind == "Gum" and config.BUBBLE_SETTINGS.AUTO_BUY_GUM or (upgrade.Kind == "Flavors" and config.BUBBLE_SETTINGS.AUTO_BUY_FLAVORS)
		if not enabled then return false, "Purchase disabled" end
		local cost = definition.Cost
		local funds = raw[cost.Currency]
		if type(funds) ~= "number" or type(cost.Amount) ~= "number" or cost.Amount < 0 then return false, "Actual funds or cost unknown" end
		local spendable = math.max(0, funds - (upgrade.Reserve or 0) - (upgrade.GoalReserve or 0))
		if cost.Amount > config.UPGRADE_SETTINGS.MAXIMUM_PURCHASE_COST or cost.Amount > spendable * config.RESOURCE_SETTINGS.MAXIMUM_UPGRADE_BALANCE_FRACTION then
			return false, "Actual funds no longer meet goal reserve and purchase budget" end
		command = "GumShopPurchase"
	end
	local remote = self.Reader:_dependency("Remote")
	if not remote or type(remote.FireServer) ~= "function" then return false, "Native Remote unavailable" end
	self:Failure("UPGRADE:" .. upgrade.Name, config.UPGRADE_SETTINGS.PURCHASE_RETRY_COOLDOWN_SECONDS, "Awaiting ownership/equipment confirmation")
	remote:FireServer(command, upgrade.Name)
	local deadline = os.clock() + config.UPGRADE_SETTINGS.PURCHASE_CONFIRMATION_TIMEOUT_SECONDS
	while not token:CheckCancelled() and os.clock() < deadline do
		local live = self.Reader:GetLiveProfile()
		if live then
			local owned = live[upgrade.Kind] and live[upgrade.Kind][upgrade.Name] ~= nil
			local equipped = live.Bubble and live.Bubble[upgrade.Kind == "Gum" and "Gum" or "Flavor"] == upgrade.Name
			if (not currentOwned and owned) or (currentOwned and equipped) then return true, currentOwned and "Actual equipped upgrade changed" or "Actual ownership received" end
		end
		task.wait(0.2)
	end
	return false, token:CheckCancelled() and "Cancelled" or "Ownership/equipment change was not confirmed"
end

return GameMechanics

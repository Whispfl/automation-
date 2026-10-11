--!nonstrict
-- Native definitions describe destinations/costs. LocalData alone confirms unlocks.
-- Height order is a travel frontier, never proof of a server prerequisite or a route.
local ProgressionGraph = {}

local function currencyReserve(config, currency)
	local key = ({ Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" })[currency]
	return key and config.RESOURCE_SETTINGS[key] or 0
end

function ProgressionGraph.Build(config, snapshot, definitions, observations)
	local graph = { Worlds = {}, Islands = {}, Capabilities = {}, Source = "Shared.Data.Worlds + LocalData + Workspace", Complete = false }
	if not snapshot.Ready or type(snapshot.UnlockedWorlds) ~= "table" or type(snapshot.UnlockedIslands) ~= "table" then
		graph.Blocker = "Real LocalData world/area unlock maps unavailable" return graph
	end
	if type(definitions) ~= "table" then graph.Blocker = "Native Worlds definitions unavailable" return graph end
	local observed, islandObservations = {}, {}
	for _, world in ipairs((observations or {}).Worlds or {}) do observed[world.Name] = world end
	for _, island in ipairs((observations or {}).Islands or {}) do islandObservations[island.World .. "/" .. island.Name] = island end
	local selected = {}
	for name, definition in pairs(definitions) do
		if type(definition) == "table" and not definition.Event and not definition.Removed
			and (#config.WORLD_SETTINGS.SELECTED_WORLDS == 0 or table.find(config.WORLD_SETTINGS.SELECTED_WORLDS, name)) then selected[name] = true end
	end
	-- Include actual gate-origin dependencies of requested destinations, not assumed world-order edges.
	local changed = true
	while changed do
		changed = false
		for name in pairs(selected) do
			local gate = observed[name] and observed[name].Gate
			local origin = gate and gate.OriginWorld
			local definition = origin and definitions[origin]
			if definition and not definition.Event and not definition.Removed and not selected[origin] then selected[origin], changed = true, true end
		end
	end
	for name in pairs(selected) do
		local definition, scene = definitions[name], observed[name]
		local world = { Id = name, Name = name, Order = definition.Order or 999, Kind = "WORLD",
			Unlocked = snapshot.UnlockedWorlds[name] ~= nil, UnlockKnown = true, Gate = scene and scene.Gate,
			ScenePresent = scene ~= nil, Cost = definition.UnlockCost, Islands = {},
			TravelAvailable = snapshot.UnlockedWorlds[name] ~= nil and scene ~= nil and scene.WorldTravelPath ~= nil,
			TravelPath = scene and scene.WorldTravelPath }
		world.State = world.Unlocked and "COMPLETE" or "BLOCKED"
		if not world.Unlocked then
			local gate, cost = world.Gate, world.Cost
			if not gate then world.Blocker = "Native WorldGate not observed; no unlock command inferred"
			elseif gate.Ambiguous then world.Blocker = "Multiple native WorldGate observations; destination contract ambiguous"
			elseif gate.ActivationObserved ~= true then world.Blocker = "Native gate Activation.Root unavailable; no supported unlock interaction observed"
			elseif not gate.OriginWorld or snapshot.UnlockedWorlds[gate.OriginWorld] == nil then world.Blocker = "Gate origin world is locked or unknown: " .. tostring(gate.OriginWorld)
			elseif gate.RequiredIsland and snapshot.UnlockedIslands[gate.RequiredIsland] == nil then world.Blocker = "Gate requires discovered island " .. gate.RequiredIsland
			elseif type(cost) ~= "table" or cost.Type ~= "Currency" or type(cost.Currency) ~= "string"
				or cost.Currency == "Robux" or type(cost.Amount) ~= "number" or cost.Amount ~= cost.Amount or cost.Amount < 0 or cost.Amount == math.huge then
				world.Blocker = "Native nonpremium currency cost unavailable"
			elseif type((snapshot.Balances or {})[cost.Currency]) ~= "number" or snapshot.Balances[cost.Currency] ~= snapshot.Balances[cost.Currency]
				or snapshot.Balances[cost.Currency] < 0 or snapshot.Balances[cost.Currency] == math.huge then world.Blocker = "Actual finite " .. cost.Currency .. " balance unavailable"
			else
				world.Reserve = currencyReserve(config, cost.Currency)
				world.Deficit = math.max(0, cost.Amount + world.Reserve - snapshot.Balances[cost.Currency])
				world.State = world.Deficit > 0 and "FUNDING" or "READY"
			end
		end
		for index, definitionIsland in ipairs(definition.Islands or {}) do
			local key = name .. "/" .. definitionIsland.Name
			local sceneIsland = islandObservations[key]
			local discovered = snapshot.UnlockedIslands[definitionIsland.Name] ~= nil
			local island = { Id = key, Name = definitionIsland.Name, World = name, Kind = "ISLAND", Index = index,
				Height = sceneIsland and sceneIsland.Height or definitionIsland.Height, DefinitionHeight = definitionIsland.Height,
				DiscoveryKnown = true, Discovered = discovered, NativePortalUnlocked = discovered,
				Reached = sceneIsland and sceneIsland.Reached or nil, -- position observation, independent of account discovery
				TravelAvailable = world.Unlocked and discovered and sceneIsland ~= nil and sceneIsland.TravelPath ~= nil,
				TravelPath = sceneIsland and sceneIsland.TravelPath, ScenePresent = sceneIsland ~= nil,
				DestinationPartObserved = sceneIsland and sceneIsland.DestinationPartObserved or false,
				Facilities = sceneIsland and sceneIsland.Facilities or {},
				State = discovered and "COMPLETE" or "BLOCKED",
				Blocker = not discovered and (world.Unlocked and (config.WORLD_SETTINGS.AUTO_DISCOVER_ISLANDS and name == "The Overworld"
					and "Undiscovered island: runtime contact capability and actual account acknowledgement must be checked"
					or "Undiscovered island: native ascent/discovery route and required bubble/jump capability unverified; manual discovery required") or "Origin world is locked") or nil }
			table.insert(world.Islands, island) table.insert(graph.Islands, island)
		end
		table.sort(world.Islands, function(a, b) return (a.Height or math.huge) < (b.Height or math.huge) end)
		table.insert(graph.Worlds, world)
	end
	table.sort(graph.Worlds, function(a, b) return a.Order == b.Order and a.Name < b.Name or a.Order < b.Order end)
	-- Discovery experiment uses the native definition array order, never scene child iteration.
	if config.WORLD_SETTINGS.AUTO_DISCOVER_ISLANDS then
		for _, world in ipairs(graph.Worlds) do
			if world.Name == "The Overworld" and world.Unlocked then
				local ordered = table.clone(world.Islands)
				table.sort(ordered, function(a, b) return a.Index < b.Index end)
				for _, island in ipairs(ordered) do if not island.Discovered then graph.Next = island break end end
			end
		end
	end
	-- Preserve the existing world-action policy when no experiment discovery remains.
	for _, state in ipairs({ "READY", "FUNDING" }) do
		if graph.Next then break end
		for _, world in ipairs(graph.Worlds) do if world.State == state then graph.Next = world break end end
		if graph.Next then break end
	end
	if not graph.Next then
		for _, world in ipairs(graph.Worlds) do
			if not world.Unlocked then graph.Next = world break end
			for _, island in ipairs(world.Islands) do if not island.Discovered then graph.Next = island break end end
			if graph.Next then break end
		end
	end
	if #graph.Worlds == 0 then graph.Blocker = "No selected permanent world has a verified native definition"
	else graph.Complete = graph.Next == nil end
	graph.Capabilities.Mastery = { Available = snapshot.UnlockedIslands["Outer Space"] ~= nil,
		Prerequisite = "AreasUnlocked[Outer Space]", Evidence = "ClientScript:2010 native Mastery visibility; executor deferred to Phase 5" }
	graph.Capabilities.Shops = (observations or {}).Upgrades or {}
	graph.Capabilities.WorldFacilities = { ["Minigame Paradise"] = { Available = snapshot.UnlockedWorlds["Minigame Paradise"] ~= nil, Features = { "Game Board", "Minigames" }, Executor = "DEFERRED" },
		["Seven Seas"] = { Available = snapshot.UnlockedWorlds["Seven Seas"] ~= nil, Features = { "Fishing", "Bounty quests" }, Executor = "DEFERRED" } }
	return graph
end

function ProgressionGraph.Goal(config, graph)
	if graph.Blocker then return { Id = "PROGRESSION:BLOCKED", Title = "Resolve progression evidence", Reason = graph.Blocker, State = "BLOCKED" } end
	local node = graph.Next
	if not node then return nil end
	local goal = { Id = "PROGRESSION:" .. node.Kind .. ":" .. node.Id, Title = (node.Kind == "WORLD" and "Unlock " or "Discover ") .. node.Name,
		State = node.State, Node = node, Reason = node.Blocker or string.format("Native gate requires %.0f %s; actual shortage=%.0f; origin/discovery prerequisites verified", node.Cost.Amount, node.Cost.Currency, node.Deficit) }
	if node.State == "FUNDING" and config.WORLD_SETTINGS.AUTO_FARM_UNLOCK_REQUIREMENTS then goal.Cost = node.Cost end
	return goal
end

return ProgressionGraph

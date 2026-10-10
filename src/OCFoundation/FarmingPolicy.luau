--!nonstrict
-- Pure decision policy used exclusively by OCBrain. Executors cannot choose their own activities.
local FarmingPolicy = {}
local UpgradePolicy = require(script.Parent.UpgradePolicy)
local function allowed(list, value) return #list == 0 or table.find(list, value) ~= nil end
local function reserve(config, currency)
	local field = ({ Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" })[currency]
	if currency == "Leaves26" then return config.FALL_EVENT_SETTINGS.LEAF_RESERVE end
	if currency == "RebirthShards26" then return config.FALL_EVENT_SETTINGS.REBIRTH_SHARD_RESERVE end
	return field and config.RESOURCE_SETTINGS[field] or 0
end
local function rate(context, mode, currency)
	local entry = context.Rates[mode]
	return entry and entry.Ready and entry.PerMinute[currency] or nil
end

function FarmingPolicy.IsFarmingArea(config, area)
	return area ~= nil and area.Unlocked == true
		and (allowed(config.ISLAND_SETTINGS.SELECTED_ISLANDS, area.Name) or table.find(config.ISLAND_SETTINGS.SELECTED_ISLANDS, area.Key) ~= nil)
		and allowed(config.BRAIN_SETTINGS.SELECTED_WORLDS, area.World)
end

function FarmingPolicy.IsStationaryArea(config, area)
	return FarmingPolicy.IsFarmingArea(config, area) and area.World == "The Overworld" and (area.Name == "The Void" or area.Name == "Zen")
end

function FarmingPolicy.IncomeTarget(config, snapshot, plan, context)
	local candidates = {}
	if plan.Objective then table.insert(candidates, plan.Objective) end
	for _, candidate in ipairs(plan.Candidates or {}) do if candidate ~= plan.Objective then table.insert(candidates, candidate) end end
	for _, candidate in ipairs(candidates) do
		local cost = candidate.Metadata and candidate.Metadata.Cost
		if cost and cost.Type == "Currency" and type(cost.Amount) == "number" and snapshot.Balances[cost.Currency] ~= nil
			and allowed(config.PICKUP_SETTINGS.FARM_CURRENCY_TYPES, cost.Currency) then
			local required = cost.Amount + reserve(config, cost.Currency)
			if candidate.Metadata.Upgrade then required = cost.Amount / config.RESOURCE_SETTINGS.MAXIMUM_UPGRADE_BALANCE_FRACTION + reserve(config, cost.Currency) end
			if snapshot.Balances[cost.Currency] < required then
				return cost.Currency, candidate, required - snapshot.Balances[cost.Currency]
			end
		end
	end
	for _, currency in ipairs(config.FARMING_SETTINGS.CURRENCY_PRIORITIES) do
		if not allowed(config.PICKUP_SETTINGS.FARM_CURRENCY_TYPES, currency) then continue end
		for _, area in ipairs(context.Islands or {}) do if area.Unlocked and area.Currencies[currency] then return currency, plan.Objective, nil end end
		for _, sell in ipairs(context.Sells or {}) do if sell.Currency == currency then return currency, plan.Objective, nil end end
	end
	return nil, plan.Objective, nil
end

function FarmingPolicy.CompareIncome(config, snapshot, plan, context, memory)
	-- Retained pure historical income evaluator. Active Brain decisions use Decide below;
	-- its combined/probe recommendations are never submitted as gameplay tasks.
	local decision = { Kind = "WAIT", Reason = "Waiting for supported farming data", IslandCandidates = {}, IslandDiagnostics = {}, Currency = nil }
	if not config.FARMING_SETTINGS.AUTO_RESOURCE_FARM or not snapshot.Ready or not config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS then
		decision.Reason = "Farming disabled or real account/planner not ready" return decision
	end
	if context.SceneReady == false then decision.Reason = context.Blocker or "Waiting for actual zone inspection before selecting a farming activity" return decision end
	local preferred = config.ISLAND_SETTINGS.PREFERRED_FARMING_ISLAND
	if preferred ~= "" and config.ISLAND_SETTINGS.AUTO_SELECT_BEST_ISLAND and config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND then
		local destination, fallback, returning
		for _, area in ipairs(context.Islands or {}) do
			if not FarmingPolicy.IsStationaryArea(config, area) or area.ActualUnlocked ~= true then continue end
			if context.ReturnKey == area.Key then returning = area end
			if area.Name == preferred then destination = area else fallback = area end
		end
		destination = returning or destination or fallback
		if not destination then decision.Reason = "Neither selected farming island has confirmed LocalData world/island access; no unlock or invalid teleport attempted" return decision end
		decision.PreferredIsland = destination.Key
		local current = context.Current
		if not current or current.Key ~= destination.Key then
			if context.CanInteract and context.CanTravel and not destination.InBackoff and (destination.Spawn or destination.DestinationPath) then
				decision.Kind, decision.Island, decision.Returning = "TRAVEL", destination, returning ~= nil
				decision.Reason = returning and "Return to the saved farming island after selling" or "Native island travel: prefer unlocked " .. preferred .. "; The Void is the approved fallback"
			else
				decision.Kind = "INSPECT"
				decision.Reason = "Preferred farming island travel pending: " .. tostring(context.Blocker or (destination.InBackoff and "destination retry backoff" or "native destination/cooldown unavailable"))
			end
			return decision
		end
		if context.Now - (context.ArrivedAt or context.Now) < config.ISLAND_SETTINGS.ARRIVAL_PICKUP_GRACE_SECONDS then
			decision.Kind, decision.Reason = "INSPECT", "Waiting for selected island/character state to stabilize before stationary collection"
			return decision
		end
	end
	if config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST then
		decision.Goal = "Stationary Coins/Gems farming with isolated balance logging"
		if not FarmingPolicy.IsStationaryArea(config, context.Current) then
			decision.Reason = "Selected unlocked island required; enable native island travel or position manually"
		elseif not context.CanInteract then decision.Reason = context.Blocker or "Native interaction guard"
		elseif context.Cluster then
			decision.Kind, decision.Mode, decision.Cluster = "FARM", "PICKUPS", context.Cluster
			decision.Currency = context.Cluster.Currency or "Coins"
			decision.Reason = "Continuous paced stationary ID batches; verify LocalData credit"
		else
			decision.Kind = "INSPECT"
			decision.Reason = context.PickupUnavailableReason or "Waiting for live stationary pickup IDs; no movement fallback"
		end
		return decision
	end
	local currency, goal, deficit = FarmingPolicy.IncomeTarget(config, snapshot, plan, context)
	decision.Currency, decision.Goal, decision.Deficit = currency, goal and goal.Title, deficit
	if not currency then decision.Reason = "No allowed goal currency with an accessible earning source" return decision end
	local current = context.Current
	local currentAllowed = FarmingPolicy.IsFarmingArea(config, current)
	local pickupFirst = config.FARMING_SETTINGS.FARMING_STRATEGY == "PICKUP_FIRST"
	local activeProbe = context.PickupProbe
	local isolated = activeProbe and current and activeProbe.Key == current.Key and activeProbe.Currency == currency
	local bestSell, bestSellScore
	for _, sell in ipairs(context.Sells or {}) do
		if sell.Currency ~= currency then continue end
		local walking = false -- OC walking was removed. Future selling uses separately configured native travel.
		local canTravel = config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND and context.CanTravel
		if not walking and not canTravel then continue end
		local travel = walking and sell.Distance / math.max(1, context.WalkSpeed or 16)
			or sell.TravelSeconds or config.ISLAND_SETTINGS.UNMEASURED_TRAVEL_OVERHEAD_SECONDS
		local bubble = snapshot.Bubble
		local fillSeconds = bubble.Capacity and bubble.PowerPerBlow and bubble.PowerPerBlow > 0
			and bubble.Capacity / bubble.PowerPerBlow * config.BUBBLE_SETTINGS.BLOW_COOLDOWN_SECONDS or nil
		local score = sell.Multiplier / math.max(1, (fillSeconds or 60) + travel + 2)
		if not bestSell or score > bestSellScore then bestSell, bestSellScore = sell, score end
	end
	local bubble = snapshot.Bubble or {}
	local full = bubble.Amount and bubble.Capacity and bubble.Capacity > 0 and bubble.Amount / bubble.Capacity >= config.BUBBLE_SETTINGS.SELL_AT_CAPACITY_RATIO
	-- Sell an existing full bubble even when its station pays a different resource; do not value that payout as target currency.
	if full and config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES then
		if not context.CanInteract then decision.Reason = "Sale pending: " .. tostring(context.Blocker or "native interaction guard") return decision end
		local sell = bestSell
		if not sell then
			for _, candidate in ipairs(context.Sells or {}) do
				local sameArea = false
				if sameArea or (config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND and context.CanTravel) then
					if not sell or candidate.Distance < sell.Distance then sell = candidate end
				end
			end
		end
		if sell then
			local pickupRate, bubbleRate = rate(context, "PICKUPS", currency), rate(context, "BUBBLES", currency)
			local sellSeconds = sell.SellCycleSeconds or (sell.TravelSeconds or sell.Distance / math.max(1, context.WalkSpeed or 16)) + 2
			local fillSeconds = bubble.Capacity and bubble.PowerPerBlow and bubble.PowerPerBlow > 0 and bubble.Capacity / bubble.PowerPerBlow * config.BUBBLE_SETTINGS.BLOW_COOLDOWN_SECONDS
			local lostPickups = pickupRate and pickupRate * sellSeconds / 60
			local saleEstimate = bubbleRate and fillSeconds and bubbleRate * (fillSeconds + sellSeconds) / 60
			local delay = not isolated and currentAllowed and (pickupFirst or memory.Mode == "COMBINED") and config.BUBBLE_SETTINGS.ENABLE_SIMULTANEOUS_BLOWING and context.Cluster
				and config.BUBBLE_SETTINGS.AUTO_BLOW_BUBBLES and config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS and config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING
				and context.CanInteract and context.FullSince and context.Now - context.FullSince < config.FARMING_SETTINGS.MAXIMUM_COMBINED_SELL_DELAY_SECONDS
				and lostPickups and saleEstimate and lostPickups > saleEstimate
			decision.SellComparison = { LostPickupEstimate = lostPickups, SaleValueEstimate = saleEstimate, SellSeconds = sellSeconds, Delayed = delay == true }
			if delay then
				decision.Kind, decision.Mode, decision.Cluster, decision.Sell = "FARM", "COMBINED", context.Cluster, sell
				decision.Reason = "Briefly finish valuable pickup coverage with a full bubble; bounded sell delay, no further blowing"
			else decision.Kind, decision.Sell, decision.Reason = "SELL", sell, "Bubble reached sell threshold; verify native sale before producing more" end
			return decision
		end
		decision.Reason = "Sale pending: no accessible station or native travel cooldown/backoff"
		return decision
	end
	local bestIsland, currentScore = nil, nil
	if config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS and config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING then
		for _, area in ipairs(context.Islands or {}) do
			local exclusion
			if decision.PreferredIsland and area.Key ~= decision.PreferredIsland then exclusion = "Excluded by preferred farming island"
			elseif not area.Unlocked then exclusion = "World locked/unknown or island not discovered"
			elseif not (allowed(config.ISLAND_SETTINGS.SELECTED_ISLANDS, area.Name) or table.find(config.ISLAND_SETTINGS.SELECTED_ISLANDS, area.Key) ~= nil) then exclusion = "Excluded by SELECTED_ISLANDS"
			elseif not allowed(config.BRAIN_SETTINGS.SELECTED_WORLDS, area.World) then exclusion = "Excluded by SELECTED_WORLDS"
			elseif area.ZoneCount == 0 then exclusion = "No live tagged PickupZone; availability unknown"
			elseif area.MappingWarning then exclusion = area.MappingWarning
			elseif not area.Currencies[currency] then exclusion = "Native pool has no goal currency " .. currency
			elseif area.InBackoff then exclusion = "Empty island or failed travel in backoff"
			elseif area ~= current and not (area.Spawn or area.DestinationPath) then exclusion = "No verified native island destination"
			elseif area ~= current and (not config.ISLAND_SETTINGS.AUTO_SELECT_BEST_ISLAND or not config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND) then exclusion = "Island selection/travel disabled" end
			table.insert(decision.IslandDiagnostics, { Area = area, Reason = exclusion or "Eligible; off-island pickup availability remains unknown" })
			if exclusion then continue end
			local rates = context.AreaRates[area.Key] or {}
			local observed = rates.PICKUPS and rates.PICKUPS.Ready and rates.PICKUPS or rates.PICKUP_ACTIVITY
			local measured = observed and observed.Ready and observed.PerMinute[currency] or nil
			local cycle = config.ISLAND_SETTINGS.UNMEASURED_COLLECTION_CYCLE_SECONDS
			local overhead = area == current and 0 or area.TravelSeconds or config.ISLAND_SETTINGS.UNMEASURED_TRAVEL_OVERHEAD_SECONDS
			local estimate = area.Expected[currency] and area.Expected[currency] * 60 / math.max(1, cycle) or nil
			local value = measured ~= nil and measured or estimate
			local net = value and value * cycle / math.max(1, cycle + overhead) or nil
			local emptyCurrent = area == current and (area.Available[currency] or 0) == 0
			if measured == nil and emptyCurrent then net = nil end
			local entry = { Key = area.Key, Name = area.Name, Currency = currency, PerMinute = net,
				Evidence = measured ~= nil and (observed == rates.PICKUPS and "OBSERVED" or "OBSERVED_PICKUP_ACTIVITY: excludes sale/return; external rewards may contribute") or (net and "ESTIMATE: definitions, actual stat multiplier, unknown availability/respawn" or (emptyCurrent and "UNKNOWN: no eligible current-island models; requires bounded scan/collection trial" or "UNKNOWN: zone count/stat multiplier unavailable; requires actual trial")), Area = area,
				TravelSeconds = overhead, RespawnSeconds = area.RespawnSeconds, RespawnEvidence = "depletion-to-next-observed-model latency; streaming may contribute" }
			table.insert(decision.IslandCandidates, entry)
			if area == current then currentScore = net end
			if net and (not bestIsland or net > bestIsland.PerMinute or (net == bestIsland.PerMinute and area.Key < bestIsland.Key)) then bestIsland = entry end
		end
	end
	table.sort(decision.IslandCandidates, function(a, b)
		if a.PerMinute == b.PerMinute then return a.Key < b.Key end
		return (a.PerMinute or -1) > (b.PerMinute or -1)
	end)
	-- Mandatory return/enforcement precedes dwell, active sweeps and income comparisons.
	local destination
	if context.ReturnKey then
		for _, entry in ipairs(decision.IslandCandidates) do if entry.Key == context.ReturnKey then destination = entry.Area break end end
	end
	if not currentAllowed or (context.ReturnKey and context.ReturnKey ~= (current and current.Key)) then
		destination = destination or (bestIsland and bestIsland.Area) or (decision.IslandCandidates[1] and decision.IslandCandidates[1].Area)
		if destination and destination ~= current and context.CanTravel and context.CanInteract then
			decision.Kind, decision.Island, decision.Returning = "TRAVEL", destination, context.ReturnKey ~= nil
			decision.Reason = context.ReturnKey and "Return after selling to an eligible farming island" or "Current island excluded; travel to an eligible farming island"
		else
			decision.Kind, decision.Background = "INSPECT", pickupFirst
			decision.Reason = "Farming island return/enforcement pending: " .. tostring(context.Blocker or "travel cooldown, destination backoff or no eligible island")
		end
		return decision
	end
	if bestIsland and currentAllowed and bestIsland.Area ~= current and current.Currencies[currency] and not current.InBackoff then
		if context.Now - (context.ArrivedAt or 0) < config.ISLAND_SETTINGS.MIN_ISLAND_DWELL_SECONDS
			or ((currentScore or 0) > 0 and bestIsland.PerMinute <= currentScore * (1 + config.ISLAND_SETTINGS.MIN_ISLAND_GAIN_ADVANTAGE_PERCENT / 100)) then
			for _, entry in ipairs(decision.IslandCandidates) do if entry.Area == current then bestIsland = entry break end end
		end
	end
	local cluster = context.Cluster
	local pickupReady = currentAllowed and not current.InBackoff and config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS and config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING and cluster ~= nil and context.CanInteract
	local bubbleReady = config.BUBBLE_SETTINGS.AUTO_BLOW_BUBBLES and config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES and bestSell ~= nil and context.CanBlow and not full
	local backgroundReady = config.BUBBLE_SETTINGS.AUTO_BLOW_BUBBLES and config.BUBBLE_SETTINGS.ENABLE_SIMULTANEOUS_BLOWING and context.CanBlow and not full
	-- Execute exploration through the same foreground task. Never manufacture income for an untested island.
	local explore = config.ISLAND_SETTINGS.AUTO_EXPLORE_UNLOCKED_ISLANDS and config.FARMING_SETTINGS.ENABLE_EFFICIENCY_COMPARISON
		and config.FARMING_SETTINGS.ENABLE_ACTIVITY_SWITCHING and config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS and config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING
	if explore and isolated then
		decision.Probe = true
		if context.Now < (activeProbe.ReadyAt or activeProbe.StartedAt) then
			decision.Kind = "INSPECT" decision.Reason = "Arrival loading grace; continue scanning before pickup measurement"
		elseif pickupReady then
			decision.Kind, decision.Mode, decision.Cluster, decision.Sell = "FARM", "PICKUPS", cluster, bestSell
			decision.Reason = "Isolated pickup trial; measure actual balances before comparing with bubble sales"
		else decision.Kind = "INSPECT" decision.Reason = "Bounded pickup observation: " .. tostring(context.PickupUnavailableReason or "no eligible models") end
		return decision
	end
	if explore and not activeProbe and context.CanInteract and not context.ActiveSweepPending
		and not context.BubbleProbePending and context.Now - (context.ArrivedAt or 0) >= config.ISLAND_SETTINGS.MIN_ISLAND_DWELL_SECONDS then
		local trial, oldest = nil, math.huge
		for _, entry in ipairs(decision.IslandCandidates) do
			local area = entry.Area
			if pickupFirst and not config.FARMING_SETTINGS.ISOLATED_PICKUP_PROBES and area == current then continue end
			local stamp = (context.IslandProbeHistory or {})[area.Key .. ":" .. currency]
			-- A measured trial need not be repeated while its observed sample is still current.
			if entry.Evidence:sub(1, 8) == "OBSERVED" then continue end
			local last = stamp or -math.huge
			if context.Now - last < config.ISLAND_SETTINGS.ISLAND_EXPLORATION_RETRY_SECONDS then continue end
			if area ~= current and not context.CanTravel then continue end
			if not trial or last < oldest or (last == oldest and (area == current or (trial.Area ~= current and area.Key < trial.Key))) then trial, oldest = entry, last end
		end
		if trial then
			decision.Probe = not pickupFirst or config.FARMING_SETTINGS.ISOLATED_PICKUP_PROBES
			decision.Exploration = true
			if trial.Area ~= current then
				decision.Kind, decision.Island = "TRAVEL", trial.Area
				decision.Reason = "Bounded exploration of " .. trial.Key .. "; pickup earnings unverified; background blowing follows configured strategy"
				return decision
			else
				decision.Kind = "INSPECT"
				decision.Reason = "Begin bounded loading/scanning trial on the current island"
				return decision
			end
		end
	end
	local choices = {}
	if pickupReady then table.insert(choices, "PICKUPS") end
	if bubbleReady then table.insert(choices, "BUBBLES") end
	if pickupReady and bubbleReady and config.BUBBLE_SETTINGS.ENABLE_SIMULTANEOUS_BLOWING then table.insert(choices, "COMBINED") end
	if not config.FARMING_SETTINGS.AUTO_FARM_FALLBACK and memory.Mode and not table.find(choices, memory.Mode) then
		decision.Reason = "Preferred activity unavailable; fallback is disabled" return decision
	end
	local mode, modeScore
	if config.FARMING_SETTINGS.ENABLE_EFFICIENCY_COMPARISON then
		for _, candidate in ipairs(choices) do
			local measured = rate(context, candidate, currency)
			if measured and (not modeScore or measured > modeScore) then mode, modeScore = candidate, measured end
		end
	elseif table.find(choices, "COMBINED") then
		mode = "COMBINED"
	end
	-- Unknown modes get bounded probes, rather than fabricated income rates.
	local untested, oldestTest = nil, math.huge
	for _, candidate in ipairs(choices) do
		local lastTest = memory.LastTest[candidate] or -math.huge
		if candidate ~= memory.Mode and (not memory.Mode or context.Now - memory.StartedAt >= config.FARMING_SETTINGS.MINIMUM_ACTIVITY_HOLD_SECONDS)
			and context.Now - lastTest >= config.FARMING_SETTINGS.EXPLORATION_INTERVAL_SECONDS and lastTest < oldestTest then
			untested, oldestTest = candidate, lastTest
		end
	end
	if config.FARMING_SETTINGS.ENABLE_EFFICIENCY_COMPARISON and untested then mode = untested modeScore = nil end
	mode = mode or choices[1]
	if memory.Mode and table.find(choices, memory.Mode) then
		local age = context.Now - memory.StartedAt
		local currentRate = rate(context, memory.Mode, currency)
		if not config.FARMING_SETTINGS.ENABLE_ACTIVITY_SWITCHING or age < config.FARMING_SETTINGS.MINIMUM_ACTIVITY_HOLD_SECONDS
			or (modeScore and currentRate and modeScore <= currentRate * (1 + config.FARMING_SETTINGS.ACTIVITY_SWITCH_GAIN_RATIO)) then mode = memory.Mode end
		if (memory.Mode == "BUBBLES" and context.BubbleProbePending or memory.Mode == "COMBINED" and context.CombinedProbePending)
			and age < config.FARMING_SETTINGS.BUBBLE_PROBE_TIMEOUT_SECONDS then mode = memory.Mode end
	end
	if pickupFirst then
		mode = pickupReady and (backgroundReady and "COMBINED" or "PICKUPS") or (config.FARMING_SETTINGS.AUTO_FARM_FALLBACK and bubbleReady and "BUBBLES" or nil)
	end
	modeScore = mode and rate(context, mode, currency) or nil
	if bestIsland and bestIsland.Area ~= current and bestIsland.PerMinute > 0 and context.CanTravel and context.CanInteract
		and not (context.ActiveSweepPending and pickupReady) then
		local currentIncome = 0
		if pickupFirst then currentIncome = pickupReady and (rate(context, "PICKUPS", currency) or currentScore or 0) or 0
		else for _, viable in ipairs(choices) do currentIncome = math.max(currentIncome, rate(context, viable, currency) or 0) end end
		if currentIncome == 0 or bestIsland.PerMinute > currentIncome * (1 + config.FARMING_SETTINGS.ACTIVITY_SWITCH_GAIN_RATIO) then
			decision.Kind = "TRAVEL" decision.Island = bestIsland.Area
			decision.Reason = string.format("Best eligible %s island: %s; %.2f/min %s after %.1fs travel overhead", currency, bestIsland.Name, bestIsland.PerMinute, bestIsland.Evidence, bestIsland.TravelSeconds)
			return decision
		end
	end
	if not mode then
		if pickupFirst then decision.Kind, decision.Background = "INSPECT", true end
		decision.Reason = context.Blocker or "No reachable relevant pickups or useful bubble selling route" return decision
	end
	decision.Kind, decision.Mode, decision.Cluster, decision.Sell = "FARM", mode, cluster, bestSell
	decision.Reason = pickupFirst and (pickupReady and (backgroundReady and "Pickup-first farming with guarded background blowing" or "Pickup-first farming; background blow blocked: " .. tostring(context.BlowBlocker or "full/disabled/native guard")) or "Pickup-first fallback: no actionable pickup cluster")
		or modeScore and string.format("Observed %.2f %s/min supports the current goal", modeScore, currency)
		or "Bounded " .. mode .. " trial; observed balances will establish earning efficiency"
	local upgrade, evaluations = UpgradePolicy.Evaluate(config, snapshot, plan, context, currency, mode, bestSell, goal)
	decision.UpgradeEvaluations = evaluations
	if upgrade then
		decision.Kind, decision.Upgrade = "UPGRADE", upgrade.Upgrade
		decision.Reason = upgrade.Upgrade.Owned and "Use a verified better owned upgrade without spending"
			or string.format("Native stat projection; estimated discounted payback %.1fs; protected goal funds %.0f", upgrade.Row.Payback, upgrade.Row.GoalReserve)
	end
	return decision
end

function FarmingPolicy.Requirement(snapshot, plan)
	local expected = plan and plan.Objective and plan.Objective.Metadata and plan.Objective.Metadata.Requirement
	if not expected then return nil end
	for _, actual in ipairs(snapshot.TaskRequirements or {}) do
		if actual.QuestId == expected.QuestId and actual.TaskIndex == expected.TaskIndex and actual.Type == expected.Type
			and actual.Currency == expected.Currency and actual.Current < actual.Required then return actual end
	end
	return nil
end

function FarmingPolicy.Target(config, snapshot, plan, context)
	local goal = plan and plan.Objective
	if not goal then return nil end
	local requirement = FarmingPolicy.Requirement(snapshot, plan)
	if requirement and requirement.Type == "Collect" then return requirement.Currency, goal, requirement.Required - requirement.Current end
	local cost = goal.Metadata and goal.Metadata.Cost
	local balances = snapshot.Balances or {}
	if cost and cost.Type == "Currency" and (cost.Currency == "Coins" or cost.Currency == "Gems")
		and type(cost.Amount) == "number" and cost.Amount >= 0 and cost.Amount < math.huge and type(balances[cost.Currency]) == "number" then
		local required = cost.Amount + reserve(config, cost.Currency)
		if goal.Metadata.Upgrade then required = cost.Amount / config.RESOURCE_SETTINGS.MAXIMUM_UPGRADE_BALANCE_FRACTION + reserve(config, cost.Currency) end
		if balances[cost.Currency] < required then return cost.Currency, goal, required - balances[cost.Currency] end
	end
	return nil, goal
end

function FarmingPolicy.Decide(config, snapshot, plan, context, memory)
	local decision = { Kind = "WAIT", Reason = "No verified resource requirement in the active goal; bubble production and selling remain off",
		IslandCandidates = {}, IslandDiagnostics = {}, Goal = plan.Objective and plan.Objective.Title, GoalId = plan.Objective and plan.Objective.Id }
	if not config.FARMING_SETTINGS.AUTO_RESOURCE_FARM or not snapshot.Ready or not config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS then
		decision.Reason = "Farming disabled or actual account/planner not ready" return decision
	end
	local currency, _, deficit = FarmingPolicy.Target(config, snapshot, plan, context)
	local requirement = FarmingPolicy.Requirement(snapshot, plan)
	local bubbleGoal = requirement and (requirement.Type == "Bubbles" or requirement.Type == "Sell")
	local diagnostic = config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST and not currency and not bubbleGoal
	if diagnostic then currency = config.FARMING_SETTINGS.CURRENCY_PRIORITIES[1] end -- Explicit pickup diagnostic; no bubble objective is invented.
	decision.Currency, decision.Deficit, decision.Requirement = currency, deficit, requirement
	if not currency and not bubbleGoal and not context.ReturnKey then
		if context.PendingCleanup then decision.Kind, decision.Reason = "INSPECT", "Finish pending cleanup of an already-dispatched pickup; no new farming goal" end
		return decision
	end
	if currency and currency ~= "Coins" and currency ~= "Gems" then decision.Reason = "Only Coins/Gems pickup farming is approved" return decision end
	if context.SceneReady == false then decision.Reason = context.Blocker or "Waiting for native scene observations" return decision end
	local preferred = currency == "Coins" and "The Void" or currency == "Gems" and "Zen" or nil
	if diagnostic then preferred = config.ISLAND_SETTINGS.PREFERRED_FARMING_ISLAND ~= "" and config.ISLAND_SETTINGS.PREFERRED_FARMING_ISLAND or preferred end
	local destination, fallback, returning
	for _, area in ipairs(context.Islands or {}) do
		local access = area.ActualUnlocked
		if access == nil then access = snapshot.UnlockedWorlds and snapshot.UnlockedWorlds[area.World] ~= nil and snapshot.UnlockedIslands and snapshot.UnlockedIslands[area.Name] ~= nil end
		if not FarmingPolicy.IsStationaryArea(config, area) or not access then continue end
		if context.ReturnKey == area.Key then returning = area end
		if area.Name == preferred then destination = area
		elseif not fallback or area.Key == (context.Current and context.Current.Key) then fallback = area end
	end
	if destination and (destination.MappingWarning or (destination.InBackoff and destination.Key ~= (context.Current and context.Current.Key))
		or (destination.Key ~= (context.Current and context.Current.Key) and not destination.Spawn and not destination.DestinationPath)) then destination = nil end
	local retained
	if memory.TargetCurrency == currency then
		for _, area in ipairs(context.Islands or {}) do
			if area.Key == memory.TargetIsland and FarmingPolicy.IsStationaryArea(config, area) and area.ActualUnlocked == true and not area.MappingWarning
				and (not area.InBackoff or area.Key == (context.Current and context.Current.Key)) then retained = area end
		end
	end
	destination = returning or retained or destination or fallback
	if not destination then decision.Reason = "Neither selected farming island has confirmed LocalData access; no invalid teleport or unlock attempted" return decision end
	local limitation
	if preferred and destination.Name ~= preferred and not returning then
		if retained and destination == retained then
			limitation = "Retain " .. destination.Name .. " for unchanged " .. currency .. " goal; preferred " .. preferred .. " previously unavailable"
		else limitation = preferred .. " unavailable/locked; evaluate " .. destination.Name .. " for " .. currency end
	end
	decision.Limitation, decision.PreferredIsland = limitation, destination.Key
	if currency and not returning and not (destination.Currencies or {})[currency] then
		decision.Reason = (limitation and limitation .. "; " or "") .. "Native reward pool has no matching currency"
		return decision
	end
	if currency and not returning then memory.TargetCurrency, memory.TargetIsland = currency, destination.Key end
	local current = context.Current
	if not current or current.Key ~= destination.Key then
		if config.ISLAND_SETTINGS.AUTO_SELECT_BEST_ISLAND and config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND and context.CanTravel and context.CanInteract
			and not destination.InBackoff and not destination.MappingWarning and (destination.Spawn or destination.DestinationPath) then
			decision.Kind, decision.Island, decision.Returning = "TRAVEL", destination, returning ~= nil
			decision.Reason = returning and "Return to intended farming island after required bubble selling" or (limitation or "Active " .. tostring(currency or "bubble") .. " goal prefers " .. destination.Name)
		else decision.Kind, decision.Reason = "INSPECT", (limitation and limitation .. "; " or "") .. "Native selected-island travel pending: " .. tostring(context.Blocker or "disabled, cooldown/backoff or missing destination") end
		return decision
	end
	if config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND and context.Now - (context.ArrivedAt or context.Now) < config.ISLAND_SETTINGS.ARRIVAL_PICKUP_GRACE_SECONDS then
		decision.Kind, decision.Reason = "INSPECT", "Waiting for stable selected island arrival" return decision
	end
	if not context.CanInteract then decision.Reason = context.Blocker or "Native interaction guard" return decision end
	if not currency and not bubbleGoal then return decision end -- A completed selling task still returns before going idle.
	if currency then
		decision.Kind = "INSPECT"
		decision.Reason = (limitation and limitation .. "; " or "") .. "Wait for genuine stationary " .. currency .. " pickup IDs; bubbles and selling off"
		if context.Cluster and config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS and config.PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING then
			decision.Kind, decision.Mode, decision.Cluster = "FARM", "PICKUPS", context.Cluster
			decision.Reason = (limitation and limitation .. "; " or "") .. "Stationary pickups for active " .. currency .. " requirement; no bubble cycle"
		end
		return decision
	end
	if config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST then decision.Reason = "Pickup diagnostic blocks bubble actions" return decision end
	local amount, capacity = (snapshot.Bubble or {}).Amount, (snapshot.Bubble or {}).Capacity
	local needsSale = requirement.Type == "Sell" and amount and amount > 0 or amount and capacity and capacity > 0 and amount / capacity >= config.BUBBLE_SETTINGS.SELL_AT_CAPACITY_RATIO
	if needsSale then
		if not config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES then decision.Reason = "Real bubble task requires selling; AUTO_SELL_BUBBLES is off" return decision end
		local sell
		for _, station in ipairs(context.Sells or {}) do if not sell or station.Distance < sell.Distance then sell = station end end
		if sell and context.CanTravel then decision.Kind, decision.Sell, decision.Reason = "SELL", sell, "Native selling required by the actual bubble task"
		else decision.Reason = "Actual bubble task awaits an accessible native selling route" end
	elseif config.BUBBLE_SETTINGS.AUTO_BLOW_BUBBLES and context.CanBlow then
		decision.Kind, decision.Mode, decision.Reason = "FARM", "BUBBLES", "Blow only for the actual unfinished native bubble task"
	else decision.Reason = "Actual bubble task pending: " .. tostring(context.BlowBlocker or "AUTO_BLOW_BUBBLES is off") end
	return decision
end

return FarmingPolicy

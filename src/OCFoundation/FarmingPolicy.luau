--!nonstrict
-- Pure decision policy used exclusively by OCBrain. Executors cannot choose their own activities.
local FarmingPolicy = {}
local function allowed(list, value) return #list == 0 or table.find(list, value) ~= nil end
local function reserve(config, currency)
	local field = ({ Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" })[currency]
	if currency == "Leaves26" then return config.FALL_EVENT_SETTINGS.LEAF_RESERVE end
	if currency == "RebirthShards26" then return config.FALL_EVENT_SETTINGS.REBIRTH_SHARD_RESERVE end
	return field and config.RESOURCE_SETTINGS[field] or 0
end
local function rate(context, mode, currency)
	local entry = context.Rates[mode]
	return entry and entry.Ready and (entry.PerMinute[currency] or 0) or nil
end

function FarmingPolicy.Target(config, snapshot, plan, context)
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

function FarmingPolicy.Decide(config, snapshot, plan, context, memory)
	local decision = { Kind = "WAIT", Reason = "Waiting for supported farming data", IslandCandidates = {}, IslandDiagnostics = {}, Currency = nil }
	if not config.FARMING_SETTINGS.AUTO_RESOURCE_FARM or not snapshot.Ready or not config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS then
		decision.Reason = "Farming disabled or real account/planner not ready" return decision
	end
	if context.SceneReady == false then decision.Reason = context.Blocker or "Waiting for actual zone inspection before selecting a farming activity" return decision end
	local currency, goal, deficit = FarmingPolicy.Target(config, snapshot, plan, context)
	decision.Currency, decision.Goal, decision.Deficit = currency, goal and goal.Title, deficit
	if not currency then decision.Reason = "No allowed goal currency with an accessible earning source" return decision end
	local current = context.Current
	local bestSell, bestSellScore
	for _, sell in ipairs(context.Sells or {}) do
		if sell.Currency ~= currency then continue end
		local walking = current and sell.World == current.World and sell.Area == current.Name and sell.Distance <= config.PICKUP_SETTINGS.MAXIMUM_ROUTE_DISTANCE_STUDS
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
	if full and config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES and context.CanInteract then
		local sell = bestSell
		if not sell then
			for _, candidate in ipairs(context.Sells or {}) do
				local sameArea = current and candidate.World == current.World and candidate.Area == current.Name and candidate.Distance <= config.PICKUP_SETTINGS.MAXIMUM_ROUTE_DISTANCE_STUDS
				if sameArea or (config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND and context.CanTravel) then
					if not sell or candidate.Distance < sell.Distance then sell = candidate end
				end
			end
		end
		if sell then decision.Kind = "SELL" decision.Sell = sell decision.Reason = "Bubble reached sell threshold; verify native sale before producing more" return decision end
	end
	local bestIsland, currentScore = nil, nil
	if config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS then
		for _, area in ipairs(context.Islands or {}) do
			local exclusion
			if not area.Unlocked then exclusion = "World locked/unknown or island not discovered"
			elseif not allowed(config.ISLAND_SETTINGS.SELECTED_ISLANDS, area.Name) then exclusion = "Excluded by SELECTED_ISLANDS"
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
			local observed = rates.PICKUPS
			local measured = observed and observed.Ready and (observed.PerMinute[currency] or 0) or nil
			local cycle = area.RespawnSeconds or config.ISLAND_SETTINGS.UNMEASURED_COLLECTION_CYCLE_SECONDS
			local overhead = area == current and 0 or area.TravelSeconds or config.ISLAND_SETTINGS.UNMEASURED_TRAVEL_OVERHEAD_SECONDS
			local estimate = area.Expected[currency] and area.Expected[currency] * 60 / math.max(1, cycle) or nil
			local value = measured ~= nil and measured or estimate
			local net = value and value * cycle / math.max(1, cycle + overhead) or nil
			if net and area == current and (area.Available[currency] or 0) == 0 then net = 0 end
			local entry = { Key = area.Key, Name = area.Name, Currency = currency, PerMinute = net,
				Evidence = measured ~= nil and "OBSERVED" or (net and "ESTIMATE: definitions, actual stat multiplier, unknown availability/respawn" or "UNKNOWN: zone count/stat multiplier unavailable; requires actual trial"), Area = area,
				TravelSeconds = overhead, RespawnSeconds = area.RespawnSeconds }
			table.insert(decision.IslandCandidates, entry)
			if area == current then currentScore = net end
			if net and (not bestIsland or net > bestIsland.PerMinute or (net == bestIsland.PerMinute and area.Key < bestIsland.Key)) then bestIsland = entry end
		end
	end
	table.sort(decision.IslandCandidates, function(a, b)
		if a.PerMinute == b.PerMinute then return a.Key < b.Key end
		return (a.PerMinute or -1) > (b.PerMinute or -1)
	end)
	if bestIsland and current and bestIsland.Area ~= current and current.Currencies[currency] and not current.InBackoff then
		if context.Now - (context.ArrivedAt or 0) < config.ISLAND_SETTINGS.MIN_ISLAND_DWELL_SECONDS
			or ((currentScore or 0) > 0 and bestIsland.PerMinute <= currentScore * (1 + config.ISLAND_SETTINGS.MIN_ISLAND_GAIN_ADVANTAGE_PERCENT / 100)) then
			for _, entry in ipairs(decision.IslandCandidates) do if entry.Area == current then bestIsland = entry break end end
		end
	end
	local cluster = context.Cluster
	local pickupReady = config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS and cluster ~= nil and context.CanInteract
	local bubbleReady = config.BUBBLE_SETTINGS.AUTO_BLOW_BUBBLES and config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES and bestSell ~= nil and context.CanBlow and not full
	-- Execute exploration through the same foreground task. Never manufacture income for an untested island.
	local explore = config.ISLAND_SETTINGS.AUTO_EXPLORE_UNLOCKED_ISLANDS and config.FARMING_SETTINGS.ENABLE_EFFICIENCY_COMPARISON
		and config.FARMING_SETTINGS.ENABLE_ACTIVITY_SWITCHING and config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS
	local activeProbe = context.PickupProbe
	if explore and activeProbe and current and activeProbe.Key == current.Key and activeProbe.Currency == currency then
		decision.Probe = true
		if pickupReady then
			decision.Kind, decision.Mode, decision.Cluster, decision.Sell = "FARM", "PICKUPS", cluster, bestSell
			decision.Reason = "Isolated pickup trial; measure actual balances before comparing with bubble sales"
		else decision.Reason = "Pickup trial observing unavailable/unreachable models; timeout bounds this wait" end
		return decision
	end
	if explore and not activeProbe and context.CanInteract and not context.ActiveSweepPending
		and not context.BubbleProbePending and context.Now - (context.ArrivedAt or 0) >= config.ISLAND_SETTINGS.MIN_ISLAND_DWELL_SECONDS then
		local trial, oldest = nil, math.huge
		for _, entry in ipairs(decision.IslandCandidates) do
			local area = entry.Area
			local stamp = (context.IslandProbeHistory or {})[area.Key .. ":" .. currency]
			-- A measured trial need not be repeated while its observed sample is still current.
			if entry.Evidence == "OBSERVED" then continue end
			local last = stamp or -math.huge
			if context.Now - last < config.ISLAND_SETTINGS.ISLAND_EXPLORATION_RETRY_SECONDS then continue end
			if area ~= current and not context.CanTravel then continue end
			if not trial or last < oldest or (last == oldest and (area == current or (trial.Area ~= current and area.Key < trial.Key))) then trial, oldest = entry, last end
		end
		if trial then
			decision.Probe = true
			if trial.Area ~= current then
				decision.Kind, decision.Island = "TRAVEL", trial.Area
				decision.Reason = "Bounded exploration of " .. trial.Key .. "; pickup earnings unverified, measured bubbles do not exclude this trial"
				return decision
			elseif pickupReady then
				decision.Kind, decision.Mode, decision.Cluster, decision.Sell = "FARM", "PICKUPS", cluster, bestSell
				decision.Reason = "Bounded isolated pickup trial on the current island"
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
		if memory.Mode == "BUBBLES" and context.BubbleProbePending and age < config.FARMING_SETTINGS.BUBBLE_PROBE_TIMEOUT_SECONDS then mode = "BUBBLES" end
	end
	if bestIsland and bestIsland.Area ~= current and bestIsland.PerMinute > 0 and context.CanTravel and context.CanInteract
		and not (context.ActiveSweepPending and pickupReady) then
		local bubbleIncome = rate(context, "BUBBLES", currency)
		if not bubbleReady or not bubbleIncome or bestIsland.PerMinute > bubbleIncome * (1 + config.FARMING_SETTINGS.ACTIVITY_SWITCH_GAIN_RATIO) then
			decision.Kind = "TRAVEL" decision.Island = bestIsland.Area
			decision.Reason = string.format("Best eligible %s island: %s; %.2f/min %s after %.1fs travel overhead", currency, bestIsland.Name, bestIsland.PerMinute, bestIsland.Evidence, bestIsland.TravelSeconds)
			return decision
		end
	end
	if not mode then decision.Reason = context.Blocker or "No reachable relevant pickups or useful bubble selling route" return decision end
	decision.Kind, decision.Mode, decision.Cluster, decision.Sell = "FARM", mode, cluster, bestSell
	decision.Reason = modeScore and string.format("Observed %.2f %s/min supports the current goal", modeScore, currency)
		or "Bounded " .. mode .. " trial; observed balances will establish earning efficiency"
	local upgrades = config.UPGRADE_SETTINGS
	if upgrades.ENABLE_SMART_UPGRADES and config.BRAIN_SETTINGS.ENABLE_EARNING_RECOMMENDATIONS and config.BUBBLE_SETTINGS.ENABLE_BUBBLE_RECOMMENDATIONS then
		local income = rate(context, "BUBBLES", currency)
		local orderedUpgrades = table.clone((snapshot.AvailableProgression or {}).Upgrades or {})
		table.sort(orderedUpgrades, function(a, b)
			if a.Owned ~= b.Owned then return a.Owned == true end
			local left = a.Cost and a.Cost.Amount or math.huge
			local right = b.Cost and b.Cost.Amount or math.huge
			if left == right then return a.Name < b.Name end
			return left < right
		end)
		for _, upgrade in ipairs(orderedUpgrades) do
			local currentStat = upgrade.Kind == "Gum" and bubble.BaseCapacity or bubble.BaseOutput
			local capacityAllowed = upgrade.Kind == "Gum" and upgrades.ENABLE_CAPACITY_UPGRADES
			local flavorAllowed = upgrade.Kind == "Flavors" and upgrades.ENABLE_FLAVOR_UPGRADES
			if not upgrade.Accessible or not upgrade.OwnershipKnown or not currentStat or currentStat <= 0 or not upgrade.BaseStat
				or not (capacityAllowed or flavorAllowed) or not allowed(upgrades.SELECTED_UPGRADES, upgrade.Name) or context.UpgradeBackoff[upgrade.Name] then continue end
			local gain = upgrade.BaseStat / currentStat - 1
			if gain < config.BRAIN_SETTINGS.MINIMUM_UPGRADE_GAIN_RATIO then continue end
			local gumBottleneck = bubble.Capacity and bubble.PowerPerBlow and bubble.PowerPerBlow > 0
				and bubble.Capacity / bubble.PowerPerBlow < config.BRAIN_SETTINGS.MINIMUM_BLOWS_PER_FILL
			if upgrade.Kind == "Gum" and not gumBottleneck then continue end
			if upgrade.Owned and upgrades.AUTO_EQUIP_OWNED_UPGRADES then
				decision.Kind, decision.Upgrade = "UPGRADE", table.clone(upgrade)
				decision.Reason = "Use a verified better owned bubble upgrade without spending" return decision
			end
			local enabled = upgrade.Kind == "Gum" and config.BUBBLE_SETTINGS.AUTO_BUY_GUM or (upgrade.Kind == "Flavors" and config.BUBBLE_SETTINGS.AUTO_BUY_FLAVORS)
			if upgrade.Owned or not enabled or mode == "PICKUPS" or not income or income <= 0 then continue end
			local cost = upgrade.Cost
			if not cost or cost.Currency ~= currency or type(cost.Amount) ~= "number" or cost.Amount < 0 then continue end
			local funds = snapshot.Balances[cost.Currency]
			local goalReserve = 0
			if upgrades.ENABLE_GOAL_RESERVATION then
				for _, reservedGoal in ipairs({ plan.Objective, goal }) do
					local goalCost = reservedGoal and reservedGoal.Metadata and reservedGoal.Metadata.Cost
					if goalCost and not reservedGoal.Metadata.Upgrade and goalCost.Currency == cost.Currency then
						goalReserve = math.max(goalReserve, goalCost.Amount or 0)
					end
				end
			end
			local reserveAmount = reserve(config, cost.Currency)
			local available = math.max(0, (funds or 0) - reserveAmount - goalReserve)
			local projection = context.EffectiveUpgrades and context.EffectiveUpgrades[upgrade.Name]
			if not projection or not projection.Capacity or not projection.Power or projection.Power <= 0 or not bubble.Capacity
				or not bubble.PowerPerBlow or bubble.PowerPerBlow <= 0 then continue end
			local fill = bubble.Capacity / bubble.PowerPerBlow * config.BUBBLE_SETTINGS.BLOW_COOLDOWN_SECONDS
			local projectedFill = projection.Capacity / projection.Power * config.BUBBLE_SETTINGS.BLOW_COOLDOWN_SECONDS
			local overhead = bestSell and (bestSell.TravelSeconds or math.min(config.ISLAND_SETTINGS.UNMEASURED_TRAVEL_OVERHEAD_SECONDS,
				bestSell.Distance / math.max(1, context.WalkSpeed or 16))) or config.ISLAND_SETTINGS.UNMEASURED_TRAVEL_OVERHEAD_SECONDS
			overhead += 2 -- Native Activation's observed sell interval.
			local rateGain = projection.Capacity / bubble.Capacity * (fill + overhead) / math.max(0.1, projectedFill + overhead) - 1
			-- Discount projected gain: catalog stat simulation is a model, not a verified new earning rate.
			local incremental = income / 60 * math.max(0, rateGain) * 0.5
			local payback = incremental > 0 and cost.Amount / incremental or math.huge
			if cost.Amount <= available * config.RESOURCE_SETTINGS.MAXIMUM_UPGRADE_BALANCE_FRACTION and cost.Amount <= upgrades.MAXIMUM_PURCHASE_COST
				and payback <= upgrades.MAXIMUM_PAYBACK_SECONDS then
				decision.Kind, decision.Upgrade = "UPGRADE", table.clone(upgrade)
				decision.Upgrade.Reserve, decision.Upgrade.GoalReserve = reserveAmount, goalReserve
				decision.Reason = string.format("Verified %s improvement %.0f%%; conservative estimated payback %.1fs from observed bubble income", upgrade.Kind, gain * 100, payback)
				return decision
			end
		end
	end
	return decision
end

return FarmingPolicy

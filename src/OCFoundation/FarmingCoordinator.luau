--!nonstrict
-- Observations may run in the background; every action is an OCBrain-selected scheduler task.
local PickupTracker = require(script.Parent.PickupTracker)
local GameMechanics = require(script.Parent.GameMechanics)
local ResourceMetrics = require(script.Parent.ResourceMetrics)
local FarmingPolicy = require(script.Parent.FarmingPolicy)
local FarmingCoordinator = {}
FarmingCoordinator.__index = FarmingCoordinator

local function balancesText(values)
	local items = {}
	for name, amount in pairs(values) do table.insert(items, string.format("%s=%.0f", name, amount)) end
	table.sort(items)
	return #items > 0 and table.concat(items, ", ") or "unavailable"
end

function FarmingCoordinator.new(controller, player)
	local self = setmetatable({ Controller = controller, Config = controller.Config, Reader = controller.Reader,
		Activity = nil, Decision = nil, Destroyed = false, LastLogAt = -math.huge, SaleEvidence = {}, ProbeStart = nil }, FarmingCoordinator)
	self.Tracker = PickupTracker.new(self.Config, self.Reader, player)
	self.Mechanics = GameMechanics.new(self.Config, self.Reader, self.Tracker, player)
	self.Metrics = ResourceMetrics.new(self.Config.FARMING_SETTINGS)
	return self
end

function FarmingCoordinator:Observe()
	if self.Destroyed or not self.Config.FARMING_SETTINGS.AUTO_RESOURCE_FARM then return end
	local now, snapshot = os.clock(), self.Reader:GetSnapshot()
	local ok, reason = xpcall(function() self.Tracker:Refresh(snapshot, now) end, debug.traceback)
	if not ok then self.Tracker.Error = tostring(reason) end
	local balances = self.Reader:ReadBalances()
	local gains = self.Metrics:Observe(balances, now)
	local live = self.Reader:GetLiveProfile()
	local amount = live and live.Bubble and live.Bubble.Amount
	if self.Controller.State == "RUNNING" and self.Metrics.Active and type(amount) == "number" and type(self.LastBubbleAmount) == "number"
		and amount < self.LastBubbleAmount then
		self.PendingSale = { Scope = self.Metrics.Active.Scope, ExpiresAt = now + self.Config.FARMING_SETTINGS.EARNINGS_CONFIRMATION_TIMEOUT_SECONDS }
	end
	if self.PendingSale and next(gains) and now <= self.PendingSale.ExpiresAt then
		self.SaleEvidence[self.PendingSale.Scope] = true self.ProbeStart = nil self.PendingSale = nil
		self.Controller:Log("FARM][SELL", "Observed native sale: bubble amount decreased and actual balances subsequently increased")
	end
	if self.PendingSale and now > self.PendingSale.ExpiresAt then self.PendingSale = nil end
	self.LastBubbleAmount = amount
	local current = self.Tracker.Current
	if current then
		self.EmptySince = self.EmptySince or {}
		if current.EligibleCount > 0 then
			self.EmptySince[current.Key] = nil
			local failure = self.Mechanics.Failures["ISLAND:" .. current.Key]
			if failure and failure.Reason == "No eligible pickups observed" then self.Mechanics.Failures["ISLAND:" .. current.Key] = nil end
		else
			self.EmptySince[current.Key] = self.EmptySince[current.Key] or now
			if now - self.EmptySince[current.Key] >= self.Config.ISLAND_SETTINGS.EMPTY_ISLAND_CONFIRMATION_SECONDS
				and self.Mechanics:Available("ISLAND:" .. current.Key) then
				self.Mechanics:Failure("ISLAND:" .. current.Key, self.Config.ISLAND_SETTINGS.EMPTY_ISLAND_RETRY_SECONDS, "No eligible pickups observed")
			end
		end
	end
	if self.Controller.State == "RUNNING" then
		local raw = self.Reader:GetLiveProfile()
		local capacity = raw and self.Reader:_stat("GetBubbleStorage", raw, {})
		if self.Activity and self.Activity.Kind == "FARM" and self.Activity.Mode ~= "PICKUPS" and raw and raw.Bubble and type(raw.Bubble.Amount) == "number" and capacity and capacity > 0
			and raw.Bubble.Amount / capacity >= self.Config.BUBBLE_SETTINGS.SELL_AT_CAPACITY_RATIO and self.Config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES then
			self.Controller.Scheduler:CancelActive("Bubble reached sell threshold") self.Mechanics:StopMovement()
		end
		self.Controller:_requestPlan(false)
	end
	self.Controller:_notify()
end

function FarmingCoordinator:StartObservations()
	if self.ObservationThread or not self.Config.FARMING_SETTINGS.AUTO_RESOURCE_FARM then return end
	self.ObservationThread = task.spawn(function()
		while not self.Destroyed do
			task.wait(self.Config.FARMING_SETTINGS.OBSERVATION_INTERVAL_SECONDS)
			if not self.Destroyed then self:Observe() end
		end
	end)
end

function FarmingCoordinator:Context(plan)
	local now = os.clock()
	local tracker, mechanics = self.Tracker, self.Mechanics
	local islands, areaRates = {}, {}
	for _, area in pairs(tracker.Areas) do
		area.InBackoff = not mechanics:Available("ISLAND:" .. area.Key)
		if area.Spawn then
			area.InBackoff = area.InBackoff or not mechanics:Available("TRAVEL:" .. area.Spawn:GetFullName())
			area.TravelSeconds = mechanics.TravelTimes and mechanics.TravelTimes[area.Spawn:GetFullName()]
		end
		table.insert(islands, area) areaRates[area.Key] = self.Metrics:Rates(area.Key, now)
	end
	local allowed, reason = mechanics:Guard()
	local canBlow, bubbleReason = mechanics:CanBlow()
	canBlow = canBlow and mechanics:Available("BLOW")
	local _, humanoid = tracker:Root()
	local raw = self.Reader:GetLiveProfile()
	local currentKey = tracker.Current and tracker.Current.Key or "UNKNOWN"
	local snapshot = self.Reader:GetSnapshot()
	local context = { Current = tracker.Current, Islands = islands, AreaRates = areaRates,
		SceneReady = tracker.LastZoneRefresh > -math.huge and tracker.Error == nil,
		Rates = self.Metrics:Rates(currentKey, now), Sells = mechanics:SellStations(), CanInteract = allowed,
		CanBlow = canBlow, CanTravel = now - mechanics.LastTravelAt >= self.Config.ISLAND_SETTINGS.TRAVEL_COOLDOWN_SECONDS,
		Blocker = reason or bubbleReason or tracker.Error, Now = now, ArrivedAt = tracker.ArrivedAt,
		WalkSpeed = humanoid and humanoid.WalkSpeed, UpgradeBackoff = {}, EffectiveUpgrades = {},
		BubbleProbePending = self.ProbeStart and raw and raw.Bubble and raw.Bubble.Amount > self.ProbeStart.Amount }
	for _, upgrade in ipairs((snapshot.AvailableProgression or {}).Upgrades or {}) do
		context.UpgradeBackoff[upgrade.Name] = not mechanics:Available("UPGRADE:" .. upgrade.Name)
		local enabled = upgrade.Kind == "Gum" and self.Config.BUBBLE_SETTINGS.AUTO_BUY_GUM
			or (upgrade.Kind == "Flavors" and self.Config.BUBBLE_SETTINGS.AUTO_BUY_FLAVORS)
		if raw and raw.Bubble and enabled and upgrade.Accessible and upgrade.OwnershipKnown and not upgrade.Owned then
			local cost = upgrade.Cost
			if cost and type(raw[cost.Currency]) == "number" and type(cost.Amount) == "number" and cost.Amount <= raw[cost.Currency]
				and cost.Amount <= self.Config.UPGRADE_SETTINGS.MAXIMUM_PURCHASE_COST then
				-- Project only the equipment field in a detached table; the received profile is never mutated.
				local projected = table.clone(raw) projected.Bubble = table.clone(raw.Bubble)
				projected.Bubble[upgrade.Kind == "Gum" and "Gum" or "Flavor"] = upgrade.Name
				context.EffectiveUpgrades[upgrade.Name] = { Capacity = self.Reader:_stat("GetBubbleStorage", projected, {}),
					Power = self.Reader:_stat("GetBubblePower", projected, {}) }
			end
		end
	end
	local currency = FarmingPolicy.Target(self.Config, snapshot, plan, context)
	context.Cluster = currency and tracker:Cluster(currency) or nil
	context.ActiveSweepPending = tracker.Sweep and tracker.Sweep.Started and next(tracker.Sweep.Pending) ~= nil
	-- A zero-yield completed trial must not be advertised as proven bubble income merely because time elapsed.
	if not self.SaleEvidence[currentKey] and context.Rates.BUBBLES then context.Rates.BUBBLES.Ready = false end
	return context
end

function FarmingCoordinator:Select(plan)
	local context = self:Context(plan)
	local decision = self.Controller.Brain:PlanFarming(self.Reader:GetSnapshot(), plan, context)
	self.Decision = decision
	local signature = decision.Kind .. ":" .. tostring(decision.Mode) .. ":" .. tostring(decision.Currency) .. ":" .. (decision.Island and decision.Island.Key or "")
	if signature ~= self.LastDecisionSignature or os.clock() - self.LastLogAt >= math.max(5, self.Config.DIAGNOSTIC_SETTINGS.MINIMUM_LOG_INTERVAL_SECONDS) then
		self.LastDecisionSignature, self.LastLogAt = signature, os.clock()
		self.Controller:Log("FARM][GOAL", tostring(decision.Goal) .. " | required=" .. tostring(decision.Currency) .. " | deficit=" .. tostring(decision.Deficit or "no fixed deficit"))
		for index, candidate in ipairs(decision.IslandCandidates) do
			if index > self.Config.DIAGNOSTIC_SETTINGS.MAXIMUM_LOG_ENTRIES then break end
			self.Controller:Log("FARM][ISLANDS", string.format("%s | %.2f %s/min | %s | overhead %.1fs | respawn %s", candidate.Key, candidate.PerMinute,
				candidate.Currency, candidate.Evidence, candidate.TravelSeconds, tostring(candidate.RespawnSeconds or "unknown")))
		end
		self.Controller:Log(decision.Kind == "WAIT" and "FARM][FALLBACK" or "FARM][DECISION", decision.Kind .. "/" .. tostring(decision.Mode) .. " | " .. decision.Reason)
		for mode, entry in pairs(context.Rates) do
			if entry.Ready then
				self.Controller:Log("FARM][EARNINGS", string.format("%s observed sample %.1fs | %.2f %s/min | external rewards can affect attribution",
					mode, entry.Seconds, entry.PerMinute[decision.Currency] or 0, tostring(decision.Currency)))
			end
		end
	end
	return decision
end

function FarmingCoordinator:_settle(token, seconds, tick)
	local deadline = os.clock() + seconds
	while not token:CheckCancelled() and os.clock() < deadline do
		if tick then tick() end
		task.wait(0.1)
	end
end

function FarmingCoordinator:_awaitCredit(before, token)
	local deadline = os.clock() + self.Config.FARMING_SETTINGS.EARNINGS_CONFIRMATION_TIMEOUT_SECONDS
	local after = self.Reader:ReadBalances()
	while not token:CheckCancelled() and os.clock() < deadline do
		for currency, value in pairs(after) do if before[currency] ~= nil and value > before[currency] then return after end end
		task.wait(0.1) after = self.Reader:ReadBalances()
	end
	return after
end

function FarmingCoordinator:_collection(decision, token)
	local cluster = decision.Cluster
	if not self.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS or not cluster then return { Verified = false, Reason = "Collection disabled or cluster unavailable" } end
	if self.Tracker.Sweep and self.Tracker.Sweep.Id == cluster.SweepId then self.Tracker.Sweep.Started = true end
	local before = self.Reader:ReadBalances()
	local beforeVisible = 0
	for _, record in ipairs(cluster.Records) do if record.Model.Parent then beforeVisible += 1 end end
	self.Controller:Log("FARM][BULK", string.format("Island=%s | total eligible=%d | cluster=%d | native radius=%.1f | method=NATIVE_RADIUS_CLUSTER_FALLBACK; no island-wide batch API",
		cluster.AreaKey, self.Tracker.Current and self.Tracker.Current.EligibleCount or 0, beforeVisible, cluster.Radius))
	self.Controller:Log("FARM][BULK", string.format("Sweep %d | %d/%d pending in frozen island set; new spawns enter the next sweep", cluster.SweepId, cluster.SweepRemaining, cluster.SweepTotal))
	local function allGone()
		for _, record in ipairs(cluster.Records) do if record.Model.Parent then return false end end
		return true
	end
	local tick = decision.Mode == "COMBINED" and function() self.Mechanics:Blow(token) end or nil
	local permitted, reason = self.Mechanics:Walk(cluster.Position, token, os.clock() + self.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS, tick, allGone)
	if token:CheckCancelled() then return nil end
	if permitted then self:_settle(token, self.Config.PICKUP_SETTINGS.COLLECTION_SETTLE_SECONDS, tick) end
	local disappeared = 0
	for _, record in ipairs(cluster.Records) do if not record.Model.Parent then disappeared += 1 end end
	if not permitted then
		self.Tracker:BackOff(cluster.Records, reason == "Slice ended" and self.Config.PICKUP_SETTINGS.COLLECTION_RETRY_SECONDS or self.Config.PICKUP_SETTINGS.UNREACHABLE_RETRY_SECONDS, reason)
	elseif disappeared == 0 then
		self.Tracker:BackOff(cluster.Records, self.Config.PICKUP_SETTINGS.COLLECTION_RETRY_SECONDS, "No disappearance observed")
	end
	local after = self:_awaitCredit(before, token)
	local gains = self.Metrics:ConfirmCycle(before, after, "Native collection cycle")
	self.Controller:Log("FARM][BULK", string.format("%d/%d models disappeared (not proof of credit) | %s", disappeared, beforeVisible, reason or "observed"))
	self.Controller:Log("FARM][EARNINGS", "before: " .. balancesText(before) .. " | after: " .. balancesText(after) .. " | " .. self.Metrics.LastConfirmation)
	self.Tracker:Refresh(self.Reader:GetSnapshot(), os.clock())
	return { Verified = next(gains) ~= nil, Disappeared = disappeared, Gains = gains, Reason = reason }
end

function FarmingCoordinator:_bubble(token)
	if not self.Config.BUBBLE_SETTINGS.AUTO_BLOW_BUBBLES then return { Verified = false, Reason = "Blowing disabled" } end
	local raw = self.Reader:GetLiveProfile()
	local before = raw and raw.Bubble and raw.Bubble.Amount
	local maximum = before
	local beforeBalances = self.Reader:ReadBalances()
	local requests, deadline = 0, os.clock() + self.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS
	while not token:CheckCancelled() and os.clock() < deadline do
		local allowed, reason = self.Mechanics:CanBlow()
		if not allowed then self.Mechanics.LastBlocker = reason break end
		local live = self.Reader:GetLiveProfile()
		if live and live.Bubble and type(live.Bubble.Amount) == "number" then maximum = math.max(maximum or 0, live.Bubble.Amount) end
		local capacity = live and self.Reader:_stat("GetBubbleStorage", live, {})
		if live and live.Bubble and capacity and live.Bubble.Amount / capacity >= self.Config.BUBBLE_SETTINGS.SELL_AT_CAPACITY_RATIO then break end
		if self.Mechanics:Blow(token) then requests += 1 end
		task.wait(0.1)
	end
	local live = self.Reader:GetLiveProfile()
	local after = live and live.Bubble and live.Bubble.Amount
	local afterBalances = self.Reader:ReadBalances()
	local income = false
	for currency, value in pairs(afterBalances) do if beforeBalances[currency] and value > beforeBalances[currency] then income = true end end
	local changed = type(before) == "number" and type(maximum) == "number" and maximum > before or income
	if income and self.Metrics.Active then self.SaleEvidence[self.Metrics.Active.Scope] = true end
	if requests > 0 and not changed and not token:CheckCancelled() then self.Mechanics:Failure("BLOW", 10, "No bubble growth confirmed") end
	self.Controller:Log("FARM][BUBBLE", "requests=" .. requests .. " | actual amount " .. tostring(before) .. " -> " .. tostring(after)
		.. " | " .. tostring(self.Mechanics.LastBlocker or "awaiting native sale for currency yield"))
	return { Verified = changed, Reason = self.Mechanics.LastBlocker }
end

function FarmingCoordinator:_sell(decision, token)
	local sell = decision.Sell
	if not self.Config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES or not sell then return { Verified = false, Reason = "Selling disabled" } end
	local raw = self.Reader:GetLiveProfile()
	local beforeAmount = raw and raw.Bubble and raw.Bubble.Amount
	local before = self.Reader:ReadBalances()
	local current = self.Tracker.Current
	local sameArea = current and current.World == sell.World and current.Name == sell.Area
	local permitted, reason
	if sameArea and sell.Distance <= self.Config.PICKUP_SETTINGS.MAXIMUM_ROUTE_DISTANCE_STUDS then
		permitted, reason = self.Mechanics:Walk(sell.Root.Position, token, os.clock() + self.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS)
	else
		self.Controller:Log("FARM][TRAVEL", "Native selling-station travel to " .. sell.Key .. " | currency=" .. sell.Currency .. " | multiplier=" .. sell.Multiplier)
		permitted, reason = self.Mechanics:Travel(sell.Root, sell.World, sell.Area, token)
	end
	if not permitted or token:CheckCancelled() then
		if not token:CheckCancelled() then self.Mechanics:Failure("SELL:" .. sell.Key, self.Config.BUBBLE_SETTINGS.SELL_RETRY_COOLDOWN_SECONDS, reason) end
		return { Verified = false, Reason = reason }
	end
	local deadline = os.clock() + self.Config.BUBBLE_SETTINGS.SELL_CONFIRMATION_TIMEOUT_SECONDS
	while not token:CheckCancelled() and os.clock() < deadline do
		local live = self.Reader:GetLiveProfile()
		local root = self.Tracker:Root()
		if not root or not sell.Root.Parent then break end
		local horizontal = ((root.Position - sell.Root.Position) * Vector3.new(1, 0, 1)).Magnitude
		if horizontal > sell.Root.Size.Y / 2 or math.abs(root.Position.Y - sell.Root.Position.Y) > 10 then
			self.Mechanics:StopMovement() reason = "Native sell activation range was not reached" break
		end
		if live and live.Bubble and type(beforeAmount) == "number" and live.Bubble.Amount < beforeAmount then
			local after = self:_awaitCredit(before, token)
			local gains = self.Metrics:ConfirmCycle(before, after, "Native bubble sale")
			local active = self.Metrics.Active
			if active and next(gains) then self.SaleEvidence[active.Scope] = true end
			self.ProbeStart = nil
			self.Controller:Log("FARM][SELL", string.format("Actual bubble amount %.0f -> %.0f | station multiplier %.2f | %s", beforeAmount, live.Bubble.Amount, sell.Multiplier, self.Metrics.LastConfirmation))
			self.Controller:Log("FARM][EARNINGS", "before: " .. balancesText(before) .. " | after: " .. balancesText(after))
			return { Verified = next(gains) ~= nil, BubbleReduced = true, Gains = gains }
		end
		task.wait(0.2)
	end
	if not token:CheckCancelled() then self.Mechanics:Failure("SELL:" .. sell.Key, self.Config.BUBBLE_SETTINGS.SELL_RETRY_COOLDOWN_SECONDS, reason or "Native sale not confirmed") end
	return { Verified = false, Reason = reason or "Native sale not confirmed" }
end

function FarmingCoordinator:Definition(decision, generation)
	if decision.Kind == "WAIT" then return nil end
	return { Id = "OC_GAMEPLAY", Priority = 10, Generation = generation,
		TimeoutSeconds = self.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS + self.Config.ISLAND_SETTINGS.TRAVEL_CONFIRMATION_TIMEOUT_SECONDS
			+ self.Config.BUBBLE_SETTINGS.SELL_CONFIRMATION_TIMEOUT_SECONDS + self.Config.UPGRADE_SETTINGS.PURCHASE_CONFIRMATION_TIMEOUT_SECONDS + 5,
		CanRun = function() return not self.Destroyed and self.Controller.State == "RUNNING" and generation == self.Controller.Generation end,
		Execute = function(token)
			self.Activity = decision
			local scope = self.Tracker.Current and self.Tracker.Current.Key or "UNKNOWN"
			local beforeBalances = self.Reader:ReadBalances()
			if decision.Kind == "FARM" then
				self.Metrics:SetMode(decision.Mode, scope, beforeBalances, os.clock())
				if decision.Mode == "BUBBLES" and not self.ProbeStart then
					local raw = self.Reader:GetLiveProfile()
					self.ProbeStart = raw and raw.Bubble and { Amount = raw.Bubble.Amount, At = os.clock() } or nil
				end
			elseif decision.Kind ~= "SELL" then self.Metrics:SetMode(nil, scope, beforeBalances, os.clock()) end
			if decision.Kind == "TRAVEL" then
				local area = decision.Island
				self.Controller:Log("FARM][TRAVEL", "Request " .. area.Key .. " through native unlocked island Teleport | " .. decision.Reason)
				local success, reason, seconds = self.Mechanics:Travel(area.Spawn, area.World, area.Name, token)
				if success then
					self.Tracker:Refresh(self.Reader:GetSnapshot(), os.clock())
					local actual = self.Tracker.Current
					success = actual ~= nil and actual.Key == area.Key
					if success then self.Controller:Log("FARM][TRAVEL", "Arrival and island identity confirmed: " .. area.Key .. " | " .. tostring(seconds) .. "s") end
				end
				if not success and not token:CheckCancelled() then
					self.Mechanics:Failure("ISLAND:" .. area.Key, self.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS, reason or "Island identity uncertain")
					self.Controller:Log("FARM][TRAVEL", "Unconfirmed arrival: " .. area.Key .. " | " .. tostring(reason))
				end
				return { Verified = success, Reason = reason }
			elseif decision.Kind == "SELL" then return self:_sell(decision, token)
			elseif decision.Kind == "UPGRADE" then
				self.Controller:Log("UPGRADE", decision.Upgrade.Name .. " | " .. decision.Reason)
				local success, reason = self.Mechanics:Upgrade(decision.Upgrade, token)
				self.Controller:Log("UPGRADE", decision.Upgrade.Name .. " | " .. tostring(reason) .. " | verified=" .. tostring(success))
				if success then
					self.Metrics.Samples = {} self.SaleEvidence = {} self.ProbeStart = nil
					self.Controller.Brain.FarmingMemory = nil
				end
				return { Verified = success, Reason = reason }
			elseif decision.Mode == "BUBBLES" then return self:_bubble(token)
			else return self:_collection(decision, token) end
		end,
		IsComplete = function(result) return type(result) == "table" end,
	}
end

function FarmingCoordinator:Completed(status, result, reason)
	self.Mechanics:StopMovement()
	self.Activity = nil
	self.Metrics:Observe(self.Reader:ReadBalances(), os.clock())
	if status == "FAILED" then self.Controller:Log("FARM][ERROR", tostring(result))
	elseif result and not result.Verified and result.Reason then self.Controller:Log("FARM][FALLBACK", result.Reason)
	elseif status == "CANCELLED" then self.Controller:Log("FARM][CANCELLED", tostring(reason)) end
	self:Observe()
end

function FarmingCoordinator:Halt()
	self.Mechanics:StopMovement()
	self.Metrics:SetMode(nil, nil, self.Reader:ReadBalances(), os.clock())
	self.Activity = nil self.ProbeStart = nil self.PendingSale = nil self.EmptySince = {}
end

function FarmingCoordinator:GetStatus()
	local current = self.Tracker.Current
	return { Activity = self.Activity and (self.Activity.Mode or self.Activity.Kind), Decision = self.Decision,
		Area = current and current.Key, VisiblePickups = current and current.VisibleCount or 0,
		EligiblePickups = current and current.EligibleCount or 0, UnknownPickups = current and current.UnknownCount or 0,
		Disappeared = self.Tracker.Disappeared, ObservedSpawns = self.Tracker.ObservedSpawns,
		RespawnObservations = self.Tracker.RespawnObservations, Radius = self.Tracker.Range,
		Rates = self.Metrics:Rates(current and current.Key or "UNKNOWN", os.clock()),
		ConfirmedCycles = self.Metrics.ConfirmedCycles, LastConfirmation = self.Metrics.LastConfirmation,
		Error = self.Tracker.Error, CollectionMethod = "Native radius clusters; no genuine island-wide batch API found" }
end

function FarmingCoordinator:Destroy()
	self:Halt() self.Destroyed = true
	if self.ObservationThread then pcall(task.cancel, self.ObservationThread) end
	self.Tracker:Destroy()
end

return FarmingCoordinator

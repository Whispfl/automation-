--!nonstrict
-- Observations may run in the background; every action is an OCBrain-selected scheduler task.
local PickupTracker = require(script.Parent.PickupTracker)
local GameMechanics = require(script.Parent.GameMechanics)
local ResourceMetrics = require(script.Parent.ResourceMetrics)
local FarmingPolicy = require(script.Parent.FarmingPolicy)
local GameKnowledge = require(script.Parent.GameKnowledge)
local StationaryExperiment = require(script.Parent.StationaryExperiment)
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
		Activity = nil, Decision = nil, Destroyed = false, LastLogAt = -math.huge, SaleEvidence = {}, ProbeStart = nil,
		IslandProbeHistory = {}, PickupProbe = nil, PickupEvidence = {}, CombinedEvidence = {}, LastPickupLogAt = -math.huge, CollectionVisits = 0 }, FarmingCoordinator)
	self.Knowledge = controller.Knowledge or GameKnowledge.new(self.Reader)
	self.Tracker = PickupTracker.new(self.Config, self.Reader, player, self.Knowledge)
	self.Mechanics = GameMechanics.new(self.Config, self.Reader, self.Tracker, player, function(tag, message) controller:Log(tag, message) end)
	self.Metrics = ResourceMetrics.new(self.Config.FARMING_SETTINGS)
	self.Stationary = StationaryExperiment.new(self)
	return self
end

function FarmingCoordinator:_beginCombined(scope)
	if self.Cycle and self.Cycle.Scope == scope then return end
	local raw = self.Reader:GetLiveProfile()
	self.CycleSequence = (self.CycleSequence or 0) + 1
	self.Cycle = { Id = self.CycleSequence, Scope = scope, StartedAt = os.clock(), Before = self.Reader:ReadBalances(),
		InitialBubble = raw and raw.Bubble and raw.Bubble.Amount, LastBubble = raw and raw.Bubble and raw.Bubble.Amount, Requests = 0 }
	self.Controller:Log("FARM][CYCLE", "begin=" .. self.Cycle.Id .. " island=" .. scope .. " initial bubble=" .. tostring(self.Cycle.InitialBubble))
end

function FarmingCoordinator:_finishCombined()
	local cycle = self.Cycle
	if not cycle or not cycle.SaleAt then return end
	local after, gains, spending = self.Reader:ReadBalances(), {}, false
	for currency, before in pairs(cycle.Before) do
		local value = after[currency]
		if type(value) == "number" then
			if value < before then spending = true end
			if value > before then gains[currency] = value - before end
		end
	end
	local seconds = os.clock() - cycle.StartedAt
	local complete = cycle.InitialBubble == 0 and cycle.Requests > 0 and cycle.GrowthAt and cycle.PickupAt and not spending and not cycle.Spending and next(gains) ~= nil
	if complete then
		self.Metrics:AddSample("COMBINED", cycle.Scope, gains, seconds, os.clock())
		self.CombinedEvidence[cycle.Scope] = { GrowthAt = cycle.GrowthAt, PickupAt = cycle.PickupAt, SaleAt = cycle.SaleAt, ReturnedAt = os.clock() }
	end
	self.Controller:Log("FARM][CYCLE", string.format("end=%d island=%s elapsed=%.1fs requests=%d complete=%s | includes loading, failures, selling and return; external rewards may contribute; pre-existing bubbles excluded", cycle.Id, cycle.Scope, seconds, cycle.Requests, tostring(complete == true)))
	self.Cycle = nil
end

function FarmingCoordinator:_background(token)
	if self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST then return false end
	if token:CheckCancelled() or not self.Config.BUBBLE_SETTINGS.ENABLE_SIMULTANEOUS_BLOWING then return end
	local raw = self.Reader:GetLiveProfile()
	local capacity = raw and self.Reader:_stat("GetBubbleStorage", raw, {})
	if raw and raw.Bubble and type(raw.Bubble.Amount) == "number" and capacity and capacity > 0 and raw.Bubble.Amount / capacity >= self.Config.BUBBLE_SETTINGS.SELL_AT_CAPACITY_RATIO then return false end
	local requested = self.Mechanics:Blow(token)
	if requested and self.Cycle then self.Cycle.Requests += 1 end
	return requested
end

function FarmingCoordinator:Observe()
	if self.Destroyed or not self.Config.FARMING_SETTINGS.AUTO_RESOURCE_FARM then return end
	local now, snapshot = os.clock(), self.Reader:GetSnapshot()
	local ok, reason = xpcall(function() self.Tracker:Refresh(snapshot, now) end, debug.traceback)
	if not ok then self.Tracker.Error = tostring(reason) end
	self:_logPickupScan(now)
	local balances = self.Reader:ReadBalances()
	if self.Cycle then
		for currency, value in pairs(balances) do
			local old = (self.Cycle.LastBalances or self.Cycle.Before)[currency]
			if type(old) == "number" and value < old then self.Cycle.Spending = true end
		end
		self.Cycle.LastBalances = table.clone(balances)
	end
	local gains = self.Metrics:Observe(balances, now)
	local live = self.Reader:GetLiveProfile()
	local amount = live and live.Bubble and live.Bubble.Amount
	if self.Controller.State == "RUNNING" and self.Metrics.Active and type(amount) == "number" and type(self.LastBubbleAmount) == "number"
		and amount < self.LastBubbleAmount then
		self.SaleSequence = (self.SaleSequence or 0) + 1
		if self.Metrics.Active.Mode == "PICKUPS" or self.Metrics.Active.Mode == "STATIONARY" then
			local scope = self.Metrics.Active.Scope
			for index = #self.Metrics.Samples, 1, -1 do
				local sample = self.Metrics.Samples[index]
				if sample.Scope == scope and (sample.Mode == "PICKUPS" or sample.Mode == "STATIONARY") then table.remove(self.Metrics.Samples, index) end
			end
			for key in pairs(self.PickupEvidence) do if key:sub(1, #scope + 1) == scope .. ":" then self.PickupEvidence[key] = nil end end
			if self.PickupProbe then self.PickupProbe.Confirmed = false end
			self.Controller:Log("PICKUP][RESULT", "UNCONFIRMED: bubble amount decreased during isolated measurement; potentially mixed pickup/sale samples discarded")
		end
		self.PendingSale = { Scope = self.Metrics.Active.Scope, Mode = self.Metrics.Active.Mode, ExpiresAt = now + self.Config.FARMING_SETTINGS.EARNINGS_CONFIRMATION_TIMEOUT_SECONDS }
	end
	if self.PendingSale and next(gains) and now <= self.PendingSale.ExpiresAt then
		if self.Metrics.Active and (self.Metrics.Active.Mode == "PICKUPS" or self.Metrics.Active.Mode == "STATIONARY") then
			local scope = self.Metrics.Active.Scope
			for index = #self.Metrics.Samples, 1, -1 do
				local sample = self.Metrics.Samples[index]
				if sample.Scope == scope and (sample.Mode == "PICKUPS" or sample.Mode == "STATIONARY") then table.remove(self.Metrics.Samples, index) end
			end
			if self.PickupProbe then self.PickupProbe.Confirmed = false end
		end
		if self.PendingSale.Mode == "COMBINED" then
			local scope = self.PendingSale.Scope
			self.CombinedEvidence[scope] = self.CombinedEvidence[scope] or {}
			self.CombinedEvidence[scope].SaleAt = now self.CombinedProbeStart = nil
			if self.Cycle and self.Cycle.Scope == scope then
				self.Cycle.SaleAt = now
				if not self.ReturnKey and self.Activity and self.Activity.Kind ~= "SELL" then self:_finishCombined() end
			end
		end
		self.SaleEvidence[self.PendingSale.Scope] = true self.ProbeStart = nil self.PendingSale = nil
		self.Controller:Log("FARM][SELL", "Observed native sale: bubble amount decreased and actual balances subsequently increased")
	end
	if self.PendingSale and now > self.PendingSale.ExpiresAt then self.PendingSale = nil end
	self.LastBubbleAmount = amount
	if self.Cycle then
		local cycle = self.Cycle
		if self.Activity and self.Activity.Kind == "FARM" and self.Activity.Mode == "COMBINED" and self.Activity.Cluster
			and self.Activity.Cluster.AreaKey == cycle.Scope and type(amount) == "number" and type(cycle.LastBubble) == "number" and amount > cycle.LastBubble then
			cycle.GrowthAt = now
		end
		cycle.LastBubble = amount
		if now - cycle.StartedAt > self.Config.FARMING_SETTINGS.BUBBLE_PROBE_TIMEOUT_SECONDS + self.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS then
			self.Controller:Log("FARM][CYCLE", "incomplete cycle expired; no combined income published") self.Cycle = nil
		end
	end
	local current = self.Tracker.Current
	if self.PickupProbe then
		local probe = self.PickupProbe
		local sample = self.Metrics:Rates(probe.Key, now).STATIONARY
		local confirmed = probe.Confirmed and (probe.Attempts or 0) > 0 and sample and sample.Ready
		local finished = (now >= (probe.ReadyAt or probe.StartedAt) and (not current or current.Key ~= probe.Key))
			or probe.Currency ~= (self.Decision and self.Decision.Currency)
			or confirmed or now - probe.StartedAt >= self.Config.ISLAND_SETTINGS.PICKUP_PROBE_TIMEOUT_SECONDS
		if finished then
			self.IslandProbeHistory[probe.Key .. ":" .. probe.Currency] = now
			self.PickupProbe = nil
			self.Metrics:SetMode(nil, nil, balances, now)
			self.Controller:Log("FARM][EXPLORE", probe.Key .. " | trial ended | " .. (confirmed
				and string.format("actual sample %.1fs, %.2f %s/min; external rewards may affect attribution", sample.Seconds, sample.PerMinute[probe.Currency] or 0, probe.Currency)
				or "insufficient sample, unavailable location, or timeout; pickup income remains unverified"))
		end
	end
	if current then
		if self.ReturnKey == current.Key and self.Activity == nil then self.ReturnKey = nil self:_finishCombined() end
		self.EmptySince = self.EmptySince or {}
		if current.EligibleCount > 0 then
			self.EmptySince[current.Key] = nil
			local failure = self.Mechanics.Failures["ISLAND:" .. current.Key]
			if failure and failure.Reason == "No eligible pickups observed" then self.Mechanics.Failures["ISLAND:" .. current.Key] = nil end
		elseif not self.PickupProbe and now - (self.Tracker.ArrivedAt or now) >= self.Config.ISLAND_SETTINGS.ARRIVAL_PICKUP_GRACE_SECONDS then
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
		local full = raw and raw.Bubble and type(raw.Bubble.Amount) == "number" and capacity and capacity > 0
			and raw.Bubble.Amount / capacity >= self.Config.BUBBLE_SETTINGS.SELL_AT_CAPACITY_RATIO
		if full and not self.FullSince then self.Controller:Log("FARM][SELL_TIMING", "Threshold observed; stable discretionary-delay clock started") end
		self.FullSince = full and (self.FullSince or now) or nil
		if self.Activity and self.Activity.Kind ~= "SELL" and full and self.Config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES and not self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST
			and (self.Activity.Kind == "TRAVEL" or self.Activity.Probe or self.Activity.Mode == "BUBBLES"
				or now - self.FullSince >= self.Config.FARMING_SETTINGS.MAXIMUM_COMBINED_SELL_DELAY_SECONDS) then
			self.Controller.Scheduler:CancelActive("Bubble reached sell threshold") self.Mechanics:StopMovement()
		end
		self.Controller:_requestPlan(false)
	end
	self.Controller:_notify()
end

function FarmingCoordinator:_beginPickupProbe(key, currency)
	local now = os.clock()
	local readyAt = now + self.Config.ISLAND_SETTINGS.ARRIVAL_PICKUP_GRACE_SECONDS
	for index = #self.Metrics.Samples, 1, -1 do
		local sample = self.Metrics.Samples[index]
		if sample.Scope == key and sample.Mode == "PICKUPS" then table.remove(self.Metrics.Samples, index) end
	end
	self.PickupEvidence[key .. ":" .. currency] = nil
	self.PickupProbe = { Key = key, Currency = currency, CreatedAt = now, ReadyAt = readyAt, StartedAt = readyAt, Attempts = 0, Confirmed = false }
	self.IslandProbeHistory[key .. ":" .. currency] = now
	self.Controller:Log("FARM][EXPLORE", key .. " | begin bounded isolated pickup trial | loading grace=" .. self.Config.ISLAND_SETTINGS.ARRIVAL_PICKUP_GRACE_SECONDS .. "s")
end

function FarmingCoordinator:_pickupRates(key, now)
	local rates = self.Metrics:Rates(key, now)
	rates.PICKUPS = rates.STATIONARY -- Compatibility policy view; these are actual stationary observation windows.
	local pickups = rates.PICKUPS
	if pickups then
		for currency in pairs(pickups.PerMinute) do
			local evidence = self.PickupEvidence[key .. ":" .. currency]
			if not evidence or now - evidence > self.Config.FARMING_SETTINGS.RATE_WINDOW_SECONDS then pickups.PerMinute[currency] = nil end
		end
		if next(pickups.PerMinute) == nil then pickups.Ready = false end
	end
	if rates.BUBBLES and not self.SaleEvidence[key] then rates.BUBBLES.Ready = false end
	if rates.COMBINED then
		local evidence = self.CombinedEvidence[key]
		if not evidence or not evidence.GrowthAt or not evidence.PickupAt or not evidence.SaleAt or not evidence.ReturnedAt
			or now - math.min(evidence.GrowthAt, evidence.PickupAt, evidence.SaleAt) > self.Config.FARMING_SETTINGS.RATE_WINDOW_SECONDS then rates.COMBINED.Ready = false end
	end
	return rates
end

function FarmingCoordinator:_logPickupScan(now)
	if not self.Config.DIAGNOSTIC_SETTINGS.LOG_PICKUP_DIAGNOSTICS or now - self.LastPickupLogAt < math.max(5, self.Config.DIAGNOSTIC_SETTINGS.MINIMUM_LOG_INTERVAL_SECONDS) then return end
	self.LastPickupLogAt = now
	local tracker, report = self.Tracker, self.Tracker.ScanReport
	local range = tracker:ReadRange()
	local area = tracker.Current
	local function counts(values)
		local entries = {} for name, count in pairs(values or {}) do table.insert(entries, tostring(name) .. "=" .. count) end
		table.sort(entries) return #entries > 0 and table.concat(entries, "; ") or "none"
	end
	if not report then self.Controller:Log("PICKUP][SCAN", "Scan unavailable: " .. tostring(tracker.Error or "collection/scanning disabled or not initialized")) return end
	self.Controller:Log("PICKUP][SCAN", string.format("island=%s | candidates=%d Models=%d | actual range=%s | scan age=%.1fs", area and area.Key or "unknown", report.RenderedObjects, report.Models, range and string.format("%.2f", range) or "unavailable", now - report.At))
	self.Controller:Log("PICKUP][SOURCES", string.format("registry: %s entries=%d active IDs=%d | Rendered.Chunker folders=%d objects=%d | legacy Pickups folder=%s objects=%d | spawn listener=%s events=%d valid records=%d metadata IDs=%d without position/model=%d", report.RegistryStatus, report.RegistryEntries, report.RegistryActiveIds, report.ChunkerFolders, report.ChunkerObjects, tostring(report.FolderPresent), report.LegacyObjects, tostring(report.SpawnListener), report.NativeSpawnEvents, report.NativeSpawnRecords, report.MetadataIds, report.MetadataWithoutModel))
	self.Controller:Log("PICKUP][DETECTED", string.format("ID candidates=%d positions resolved=%d | ID sources: %s | current island=%d currency=%d unidentified=%d unloaded/stale registry entries=%d", report.CandidateIds, report.PositionsResolved, counts(report.IdSources), report.CurrentDetected, report.CurrencyCount, report.Unidentified, report.UnloadedEntries))
	self.Controller:Log("PICKUP][CLASSIFIED", string.format("current currency=%d eligible=%d | currencies: %s | identities: %s", report.CurrentCurrency, area and area.EligibleCount or 0, counts(report.Currencies), counts(report.Sources)))
	local reason = report.RenderedObjects == 0 and ("No live candidates from checked native registry/Chunker/legacy sources; " .. report.RegistryStatus .. "; spawn metadata alone has no exact position") or counts(report.Rejected)
	self.Controller:Log("PICKUP][REJECTED", reason .. (tracker.Error and " | " .. tracker.Error or ""))
	if self.Config.DIAGNOSTIC_SETTINGS.LOG_PICKUP_DETAIL_PATHS then
		for _, example in ipairs(report.Examples) do self.Controller:Log("PICKUP][REJECTED", example) end
	end
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
		local destination = area.Spawn and area.Spawn:GetFullName() or area.DestinationPath
		if destination then
			area.InBackoff = area.InBackoff or not mechanics:Available("TRAVEL:" .. destination)
			area.TravelSeconds = mechanics.TravelTimes and mechanics.TravelTimes[destination]
		end
		table.insert(islands, area) areaRates[area.Key] = self:_pickupRates(area.Key, now)
	end
	local allowed, reason = mechanics:Guard()
	local canBlow, bubbleReason = mechanics:CanBlow()
	canBlow = canBlow and mechanics:Available("BLOW")
	local raw = self.Reader:GetLiveProfile()
	local currentKey = tracker.Current and tracker.Current.Key or "UNKNOWN"
	local snapshot = self.Reader:GetSnapshot()
	local context = { Current = tracker.Current, Islands = islands, AreaRates = areaRates,
		SceneReady = tracker.LastZoneRefresh > -math.huge and tracker.Error == nil,
		Rates = self:_pickupRates(currentKey, now), Sells = mechanics:SellStations(), CanInteract = allowed,
		CanBlow = canBlow, CanTravel = not self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST and self.Config.ISLAND_SETTINGS.AUTO_TRAVEL_BEST_ISLAND
			and now - mechanics.LastTravelAt >= self.Config.ISLAND_SETTINGS.TRAVEL_COOLDOWN_SECONDS,
		Blocker = reason or tracker.Error, BlowBlocker = bubbleReason, Now = now, ArrivedAt = tracker.ArrivedAt,
		ReturnKey = self.ReturnKey,
		UpgradeBackoff = {}, EffectiveUpgrades = {},
		FullSince = self.FullSince,
		CombinedProbePending = self.CombinedProbeStart and now - self.CombinedProbeStart < self.Config.FARMING_SETTINGS.BUBBLE_PROBE_TIMEOUT_SECONDS
			and not (self.CombinedEvidence[currentKey] and self.CombinedEvidence[currentKey].SaleAt),
		BubbleProbePending = self.ProbeStart and now - self.ProbeStart.At < self.Config.FARMING_SETTINGS.BUBBLE_PROBE_TIMEOUT_SECONDS
			and not self.SaleEvidence[currentKey] and raw and raw.Bubble and raw.Bubble.Amount > self.ProbeStart.Amount,
		PickupProbe = self.PickupProbe, IslandProbeHistory = self.IslandProbeHistory }
	table.sort(islands, function(a, b) return a.Key < b.Key end)
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
	local currency = self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST and "Coins" or FarmingPolicy.Target(self.Config, snapshot, plan, context)
	context.Cluster = currency and tracker:Cluster(currency) or nil
	if context.Cluster then
		local candidate, stationaryReason = self.Stationary:Candidate(context.Cluster)
		if not candidate then context.Cluster = nil tracker.ClusterReason = stationaryReason end
	end
	context.PickupUnavailableReason = tracker.Error or tracker.ClusterReason
	context.ActiveSweepPending = false
	-- A zero-yield completed trial must not be advertised as proven bubble income merely because time elapsed.
	if not self.SaleEvidence[currentKey] and context.Rates.BUBBLES then context.Rates.BUBBLES.Ready = false end
	return context
end

function FarmingCoordinator:_logUpgrades(decision)
	if not self.Config.DIAGNOSTIC_SETTINGS.LOG_UPGRADE_DIAGNOSTICS or not decision.UpgradeEvaluations then return end
	local now = os.clock()
	if now - (self.LastUpgradeLogAt or -math.huge) < math.max(10, self.Config.DIAGNOSTIC_SETTINGS.MINIMUM_LOG_INTERVAL_SECONDS) then return end
	self.LastUpgradeLogAt = now self.UpgradeLogSignatures = self.UpgradeLogSignatures or {}
	local count = 0
	for _, row in ipairs(decision.UpgradeEvaluations) do
		local reasons = table.concat(row.Reasons, "; ")
		local signature = tostring(row.Eligible) .. ":" .. tostring(row.Owned) .. ":" .. reasons
		if self.UpgradeLogSignatures[row.Name] == signature then continue end
		if count >= self.Config.DIAGNOSTIC_SETTINGS.MAXIMUM_LOG_ENTRIES then break end
		count += 1 self.UpgradeLogSignatures[row.Name] = signature
		self.Controller:Log("UPGRADE][CANDIDATE", row.Name .. " | " .. row.Kind .. " | owned=" .. tostring(row.Owned) .. " | cost=" .. tostring(row.Cost and row.Cost.Amount) .. " " .. tostring(row.Cost and row.Cost.Currency))
		local projection = row.Projection or {}
		self.Controller:Log("UPGRADE][EVALUATION", row.Name .. " | strategy=" .. tostring(decision.Mode) .. " | balance=" .. tostring(row.Balance) .. " budget=" .. tostring(row.Budget)
			.. " resource reserve=" .. tostring(row.Reserve) .. " goal reserve=" .. tostring(row.GoalReserve) .. " | blows/fill=" .. tostring(row.BlowsPerFill)
			.. " urgent capacity=" .. tostring(row.CapacityUrgent) .. " | projected capacity=" .. tostring(projection.Capacity) .. " power=" .. tostring(projection.Power)
			.. " | measured bubble income=" .. tostring(row.BubbleIncome) .. " | estimated discounted payback=" .. tostring(row.Payback))
		self.Controller:Log(row.Eligible and "UPGRADE][EVALUATION" or "UPGRADE][REJECTED", row.Name .. " | " .. (row.Eligible and "Eligible; Brain chooses the qualified candidate with shortest estimated payback" or reasons))
	end
end

function FarmingCoordinator:Select(plan)
	local context = self:Context(plan)
	local decision = self.Controller.Brain:PlanFarming(self.Reader:GetSnapshot(), plan, context)
	self.Decision = decision
	self:_logUpgrades(decision)
	local signature = decision.Kind .. ":" .. tostring(decision.Mode) .. ":" .. tostring(decision.Currency) .. ":" .. (decision.Island and decision.Island.Key or "")
	if signature ~= self.LastDecisionSignature or os.clock() - self.LastLogAt >= math.max(5, self.Config.DIAGNOSTIC_SETTINGS.MINIMUM_LOG_INTERVAL_SECONDS) then
		self.LastDecisionSignature, self.LastLogAt = signature, os.clock()
		self.Controller:Log("FARM][GOAL", tostring(decision.Goal) .. " | required=" .. tostring(decision.Currency) .. " | deficit=" .. tostring(decision.Deficit or "no fixed deficit"))
		for index, candidate in ipairs(decision.IslandCandidates) do
			if index > self.Config.DIAGNOSTIC_SETTINGS.MAXIMUM_LOG_ENTRIES then break end
			self.Controller:Log("FARM][ISLANDS", string.format("%s | %s %s/min | %s | overhead %.1fs | respawn %s", candidate.Key,
				candidate.PerMinute and string.format("%.2f", candidate.PerMinute) or "unknown",
				candidate.Currency, candidate.Evidence, candidate.TravelSeconds, tostring(candidate.RespawnSeconds or "unknown") .. " (observation latency; streaming may contribute)"))
		end
		if self.Config.DIAGNOSTIC_SETTINGS.LOG_ISLAND_DISCOVERY then
			for index, row in ipairs(decision.IslandDiagnostics or {}) do
				if index > self.Config.DIAGNOSTIC_SETTINGS.MAXIMUM_LOG_ENTRIES then break end
				local area, pools = row.Area, {}
				self.DiscoveryLogSignatures = self.DiscoveryLogSignatures or {}
				local discoverySignature = tostring(area.WorldUnlocked) .. ":" .. tostring(area.Discovered) .. ":" .. tostring(area.AtCurrentLocation) .. ":" .. tostring(area.ZoneCount) .. ":" .. row.Reason
				if self.DiscoveryLogSignatures[area.Key] ~= discoverySignature then
				self.DiscoveryLogSignatures[area.Key] = discoverySignature
				self.Controller:Log("FARM][DISCOVERY", string.format("%s | worldUnlocked=%s discovered=%s current=%s | zones=%d configured=%s visible=%d eligible=%d unidentified=%d | destination=%s | %s",
					area.Key, tostring(area.WorldUnlocked), tostring(area.Discovered), tostring(area.AtCurrentLocation), area.ZoneCount or #(area.Zones or {}),
					area.UnknownZoneCount and "partial/unknown" or tostring(area.ConfiguredCount), area.VisibleCount or 0, area.EligibleCount or 0, area.UnknownCount or 0,
					area.Spawn and area.Spawn:GetFullName() or (area.DestinationPath and area.DestinationPath .. " (native path; local part absent)" or "unavailable"), row.Reason))
				end
				local zoneSignature = tostring(area.ZoneCount) .. ":" .. tostring(area.TransitZoneCount or 0) .. ":" .. tostring(area.ConfiguredCount)
				self.ZoneLogSignatures = self.ZoneLogSignatures or {}
				local changedZones = self.ZoneLogSignatures[area.Key] ~= zoneSignature
				if changedZones then
					self.ZoneLogSignatures[area.Key] = zoneSignature
					self.Controller:Log("FARM][ZONES", area.Key .. " | surface zones=" .. tostring(area.ZoneCount) .. " | jump-stage transit zones=" .. tostring(area.TransitZoneCount or 0) .. " (excluded from island routing/yield)")
				end
				if changedZones and self.Config.DIAGNOSTIC_SETTINGS.LOG_PICKUP_DETAIL_PATHS and (area.MappingWarning or area.ZoneCount == 0) then
					for _, zone in ipairs(area.Zones or {}) do
						if #pools >= 3 then break end table.insert(pools, zone.Root:GetFullName())
					end
					if #pools > 0 then self.Controller:Log("FARM][ZONES", table.concat(pools, "; ")) end
				end
			end
		end
		self.Controller:Log(decision.Kind == "WAIT" and "FARM][FALLBACK" or "FARM][DECISION", decision.Kind .. "/" .. tostring(decision.Mode) .. " | " .. decision.Reason)
		if decision.SellComparison then
			local comparison = decision.SellComparison
			self.Controller:Log("FARM][SELL_POLICY", "estimated selling overhead=" .. tostring(comparison.SellSeconds) .. "s | estimated lost pickups=" .. tostring(comparison.LostPickupEstimate)
				.. " | estimated sale value=" .. tostring(comparison.SaleValueEstimate) .. " | delayed=" .. tostring(comparison.Delayed))
		end
		for mode, entry in pairs(context.Rates) do
			if mode == "PICKUPS" and context.Rates.STATIONARY then continue end
			if entry.Ready then
				self.Controller:Log("FARM][EARNINGS", string.format("%s observed sample %.1fs | %.2f %s/min | external rewards can affect attribution",
					mode, entry.Seconds, entry.PerMinute[decision.Currency] or 0, tostring(decision.Currency)))
			end
		end
	end
	return decision
end

function FarmingCoordinator:_settle(token, seconds, tick, finished)
	local deadline = os.clock() + seconds
	while not token:CheckCancelled() and os.clock() < deadline do
		if finished and finished() then break end
		if tick then tick() end
		task.wait(0.1)
	end
end

function FarmingCoordinator:_awaitCredit(before, token, currencies, tick, stopAt)
	local deadline = os.clock() + self.Config.FARMING_SETTINGS.EARNINGS_CONFIRMATION_TIMEOUT_SECONDS
	if stopAt then deadline = math.min(deadline, stopAt) end
	local after = self.Reader:ReadBalances()
	while not token:CheckCancelled() and os.clock() < deadline do
		for currency, value in pairs(after) do if (not currencies or currencies[currency]) and before[currency] ~= nil and value > before[currency] then return after end end
		if tick then tick() end
		task.wait(0.1) after = self.Reader:ReadBalances()
	end
	return after
end

function FarmingCoordinator:_collection(decision, token)
	if token:CheckCancelled() then return nil end
	local cluster = decision.Cluster
	if not self.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS or not cluster then return { Verified = false, Reason = "Stationary collection disabled or IDs unavailable" } end
	if not FarmingPolicy.IsStationaryArea(self.Config, self.Tracker.Current) or self.Tracker.Current.Key ~= cluster.AreaKey then
		return { Verified = false, Reason = "Stationary execution rejected: excluded or stale island" }
	end
	return self.Stationary:Collect(decision, token)
end

function FarmingCoordinator:_bubble(token)
	if self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST then return { Verified = false, Reason = "Isolated stationary test blocks blowing" } end
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
	if self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST then return { Verified = false, Reason = "Isolated stationary test blocks selling and travel" } end
	local sell = decision.Sell
	if not self.Config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES or not sell then return { Verified = false, Reason = "Selling disabled" } end
	local raw = self.Reader:GetLiveProfile()
	local beforeAmount = raw and raw.Bubble and raw.Bubble.Amount
	local before = self.Reader:ReadBalances()
	local started = os.clock()
	local current = self.Tracker.Current
	local sameArea = current and current.World == sell.World and current.Name == sell.Area
	if not sameArea and FarmingPolicy.IsFarmingArea(self.Config, current) then
		self.ReturnKey = current.Key
		self.Controller:Log("FARM][RETURN", "Saved farming destination " .. current.Key .. "; selling excursion permits travel outside farming selection")
	end
	self.Controller:Log("FARM][SELL_TIMING", "dispatch | threshold age=" .. tostring(self.FullSince and os.clock() - self.FullSince or "unknown") .. "s | travel/activation/credit bounded separately")
	local permitted, reason
	local root = self.Tracker:Root()
	if sameArea and root and ((root.Position - sell.Root.Position) * Vector3.new(1, 0, 1)).Magnitude <= sell.Root.Size.Y / 2
		and math.abs(root.Position.Y - sell.Root.Position.Y) <= 10 then
		permitted = true -- Native activation already in range; no OC movement.
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
			local after = self:_awaitCredit(before, token, { [sell.Currency] = true })
			if token:CheckCancelled() then return nil end
			if type(before[sell.Currency]) ~= "number" or type(after[sell.Currency]) ~= "number" or after[sell.Currency] <= before[sell.Currency] then
				self.Controller:Log("FARM][SELL", "Bubble decreased; matching station-currency credit unconfirmed")
				self.Mechanics:Failure("SELL:" .. sell.Key, self.Config.BUBBLE_SETTINGS.SELL_RETRY_COOLDOWN_SECONDS, "Station-currency credit unconfirmed")
				self.Cycle = nil
				return { Verified = false, BubbleReduced = true, Reason = "Station-currency credit unconfirmed; return remains pending" }
			end
			local gains = self.Metrics:ConfirmCycle(before, after, "Native bubble sale")
			local active = self.Metrics.Active
			if active and next(gains) then self.SaleEvidence[active.Scope] = true end
			if next(gains) then
				if self.Cycle then self.Cycle.SaleAt = os.clock() end
				self.Mechanics.SellTimes = self.Mechanics.SellTimes or {} self.Mechanics.SellTimes[sell.Key] = os.clock() - started
				if active and active.Mode == "COMBINED" then
					local evidence = self.CombinedEvidence[active.Scope] or {} self.CombinedEvidence[active.Scope] = evidence
					evidence.SaleAt = os.clock() self.CombinedProbeStart = nil
				end
			end
			self.ProbeStart = nil
			self.FullSince = nil
			self.Controller:Log("FARM][SELL", string.format("Actual bubble amount %.0f -> %.0f | station multiplier %.2f | %s", beforeAmount, live.Bubble.Amount, sell.Multiplier, self.Metrics.LastConfirmation))
			self.Controller:Log("FARM][EARNINGS", "before: " .. balancesText(before) .. " | after: " .. balancesText(after))
			if not self.ReturnKey then self:_finishCombined() end
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
			if token:CheckCancelled() or generation ~= self.Controller.Generation then return nil end
			if self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST and decision.Kind ~= "INSPECT"
				and (decision.Kind ~= "FARM" or decision.Mode ~= "PICKUPS") then return { Verified = false, Reason = "Isolated stationary experiment blocks other OC actions" } end
			if decision.Kind == "TRAVEL" and not FarmingPolicy.IsFarmingArea(self.Config, decision.Island) then return { Verified = false, Reason = "Travel destination excluded or stale" } end
			if decision.Kind == "FARM" and decision.Mode ~= "BUBBLES" and
				(not FarmingPolicy.IsFarmingArea(self.Config, self.Tracker.Current) or not decision.Cluster or decision.Cluster.AreaKey ~= self.Tracker.Current.Key) then
				return { Verified = false, Reason = "Pickup execution rejected: excluded or stale island" }
			end
			self.Activity = decision
			local scope = self.Tracker.Current and self.Tracker.Current.Key or "UNKNOWN"
			local beforeBalances = self.Reader:ReadBalances()
			if decision.Probe and decision.Kind ~= "TRAVEL" and not self.PickupProbe then self:_beginPickupProbe(scope, decision.Currency) end
			if decision.Kind == "FARM" then
				if decision.Mode == "COMBINED" then self:_beginCombined(scope) end
				self.Metrics:SetMode(decision.Mode == "PICKUPS" and "STATIONARY" or decision.Mode, scope, beforeBalances, os.clock())
				if decision.Mode == "COMBINED" and not self.CombinedProbeStart then self.CombinedProbeStart = os.clock() end
				if decision.Mode == "BUBBLES" and not self.ProbeStart then
					local raw = self.Reader:GetLiveProfile()
					self.ProbeStart = raw and raw.Bubble and { Amount = raw.Bubble.Amount, At = os.clock() } or nil
				end
			elseif decision.Kind == "INSPECT" then
				local ready = self.PickupProbe and os.clock() >= self.PickupProbe.ReadyAt
				self.Metrics:SetMode(nil, scope, beforeBalances, os.clock())
			elseif decision.Kind ~= "SELL" or (self.Metrics.Active and (self.Metrics.Active.Mode == "PICKUPS" or self.Metrics.Active.Mode == "STATIONARY")) then
				-- A standalone bubble sale cannot count as isolated pickup income.
				self.Metrics:SetMode(nil, scope, beforeBalances, os.clock())
				if decision.Kind == "SELL" and self.PickupProbe then
					self.IslandProbeHistory[self.PickupProbe.Key .. ":" .. self.PickupProbe.Currency] = os.clock()
					self.PickupProbe = nil
					self.Controller:Log("FARM][EXPLORE", "Pickup trial interrupted by required selling; sale excluded from isolated pickup income")
				end
			end
			if decision.Kind == "TRAVEL" then
				local area = decision.Island
				if decision.Probe or decision.Exploration then self.IslandProbeHistory[area.Key .. ":" .. decision.Currency] = os.clock() end
				self.Controller:Log("FARM][TRAVEL", "Request " .. area.Key .. " through native unlocked island Teleport | " .. decision.Reason)
				local success, reason, seconds = self.Mechanics:TravelIsland(area, token)
				if success then
					self.Tracker:Refresh(self.Reader:GetSnapshot(), os.clock())
					local actual = self.Tracker.Current
					success = actual ~= nil and actual.Key == area.Key
					if success then
						self.Controller:Log("FARM][TRAVEL", "Arrival and island identity confirmed: " .. area.Key .. " | " .. tostring(seconds) .. "s")
						if decision.Probe then self:_beginPickupProbe(area.Key, decision.Currency) end
						if self.ReturnKey then
							self.Controller:Log("FARM][RETURN", "Confirmed return to " .. area.Key .. "; farming resumes through Brain")
							self.ReturnKey = nil self:_finishCombined()
						end
					end
				end
				if not success and not token:CheckCancelled() then
					self.Mechanics:Failure("ISLAND:" .. area.Key, self.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS, reason or "Island identity uncertain")
					self.Controller:Log("FARM][TRAVEL", "Unconfirmed arrival: " .. area.Key .. " | " .. tostring(reason))
				end
				return { Verified = success, Reason = reason }
			elseif decision.Kind == "INSPECT" then
				local duration = math.min(2, self.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS)
				local background = not self.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST and (decision.Background or (self.Config.FARMING_SETTINGS.FARMING_STRATEGY == "PICKUP_FIRST" and not decision.Probe))
				self:_settle(token, duration, background and function() self:_background(token) end or nil)
				if token:CheckCancelled() then return nil end
				self.Tracker:Refresh(self.Reader:GetSnapshot(), os.clock())
				return { Verified = false, Reason = "Pickup observation: " .. tostring(self.Tracker.ClusterReason or decision.Reason) }
			elseif decision.Kind == "SELL" then return self:_sell(decision, token)
			elseif decision.Kind == "UPGRADE" then
				local success, reason, evidence = self.Mechanics:Upgrade(decision.Upgrade, token)
				if token:CheckCancelled() then return nil end
				self.Controller:Log(success and "UPGRADE][VERIFIED" or "UPGRADE][REJECTED", decision.Upgrade.Name .. " | " .. tostring(reason) .. " | verified=" .. tostring(success))
				if success then
					self.Metrics.Samples = {} self.SaleEvidence = {} self.CombinedEvidence = {} self.ProbeStart = nil self.CombinedProbeStart = nil
					self.Controller.Brain.FarmingMemory = nil
				end
				return { Verified = success, Reason = reason, Evidence = evidence }
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
	elseif result and not result.Verified and not result.CombinedCreditObserved and result.Reason then
		local now = os.clock()
		if self.LastFallbackReason ~= result.Reason or now - (self.LastFallbackLogAt or -math.huge) >= math.max(5, self.Config.DIAGNOSTIC_SETTINGS.MINIMUM_LOG_INTERVAL_SECONDS) then
			self.LastFallbackReason, self.LastFallbackLogAt = result.Reason, now
			self.Controller:Log("FARM][FALLBACK", result.Reason)
		end
	elseif status == "CANCELLED" then self.Controller:Log("FARM][CANCELLED", tostring(reason)) end
	self:Observe()
end

function FarmingCoordinator:Halt(preserveReturn)
	self.Mechanics:StopMovement()
	self.Metrics:SetMode(nil, nil, self.Reader:ReadBalances(), os.clock())
	self.Activity = nil self.ProbeStart = nil self.PendingSale = nil self.EmptySince = {} self.PickupProbe = nil self.FullSince = nil self.CombinedProbeStart = nil
	self.RouteContinuation = nil self.Cycle = nil
	if not preserveReturn then self.ReturnKey = nil end
end

function FarmingCoordinator:GetStatus()
	local current = self.Tracker.Current
	return { Activity = self.Activity and (self.Activity.Mode or self.Activity.Kind), Decision = self.Decision,
		Strategy = self.Config.FARMING_SETTINGS.FARMING_STRATEGY, ReturnIsland = self.ReturnKey, FullSince = self.FullSince,
		Cycle = self.Cycle and { Id = self.Cycle.Id, Island = self.Cycle.Scope, Requests = self.Cycle.Requests, SaleAt = self.Cycle.SaleAt },
		Area = current and current.Key, VisiblePickups = current and current.VisibleCount or 0,
		EligiblePickups = current and current.EligibleCount or 0, UnknownPickups = current and current.UnknownCount or 0,
		Disappeared = self.Tracker.Disappeared, ObservedSpawns = self.Tracker.ObservedSpawns,
		RespawnObservations = self.Tracker.RespawnObservations, Radius = self.Tracker.Range, CollectionVisits = self.CollectionVisits,
		Rates = self:_pickupRates(current and current.Key or "UNKNOWN", os.clock()), Scan = self.Tracker.ScanReport, CollectionBlocker = self.Tracker.ClusterReason,
		ConfirmedCycles = self.Metrics.ConfirmedCycles, LastConfirmation = self.Metrics.LastConfirmation,
		Error = self.Tracker.Error, GameKnowledge = self.Knowledge:GetStatus(), Stationary = self.Stationary:GetStatus(),
		CollectionMethod = "Continuous stationary ID batches; actual credit unverified until owner testing; no movement fallback" }
end

function FarmingCoordinator:Destroy()
	self:Halt() self.Destroyed = true
	if self.ObservationThread then pcall(task.cancel, self.ObservationThread) end
	self.Tracker:Destroy()
end

return FarmingCoordinator

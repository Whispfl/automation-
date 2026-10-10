--!nonstrict
-- Observations may run in the background; every action is an OCBrain-selected scheduler task.
local PickupTracker = require(script.Parent.PickupTracker)
local GameMechanics = require(script.Parent.GameMechanics)
local ResourceMetrics = require(script.Parent.ResourceMetrics)
local FarmingPolicy = require(script.Parent.FarmingPolicy)
local GameKnowledge = require(script.Parent.GameKnowledge)
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
	return self
end

function FarmingCoordinator:Observe()
	if self.Destroyed or not self.Config.FARMING_SETTINGS.AUTO_RESOURCE_FARM then return end
	local now, snapshot = os.clock(), self.Reader:GetSnapshot()
	local ok, reason = xpcall(function() self.Tracker:Refresh(snapshot, now) end, debug.traceback)
	if not ok then self.Tracker.Error = tostring(reason) end
	self:_logPickupScan(now)
	local balances = self.Reader:ReadBalances()
	local gains = self.Metrics:Observe(balances, now)
	local live = self.Reader:GetLiveProfile()
	local amount = live and live.Bubble and live.Bubble.Amount
	if self.Controller.State == "RUNNING" and self.Metrics.Active and type(amount) == "number" and type(self.LastBubbleAmount) == "number"
		and amount < self.LastBubbleAmount then
		self.SaleSequence = (self.SaleSequence or 0) + 1
		if self.Metrics.Active.Mode == "PICKUPS" then
			local scope = self.Metrics.Active.Scope
			for index = #self.Metrics.Samples, 1, -1 do
				local sample = self.Metrics.Samples[index]
				if sample.Scope == scope and sample.Mode == "PICKUPS" then table.remove(self.Metrics.Samples, index) end
			end
			for key in pairs(self.PickupEvidence) do if key:sub(1, #scope + 1) == scope .. ":" then self.PickupEvidence[key] = nil end end
			if self.PickupProbe then self.PickupProbe.Confirmed = false end
			self.Controller:Log("PICKUP][RESULT", "UNCONFIRMED: bubble amount decreased during isolated measurement; potentially mixed pickup/sale samples discarded")
		end
		self.PendingSale = { Scope = self.Metrics.Active.Scope, Mode = self.Metrics.Active.Mode, ExpiresAt = now + self.Config.FARMING_SETTINGS.EARNINGS_CONFIRMATION_TIMEOUT_SECONDS }
	end
	if self.PendingSale and next(gains) and now <= self.PendingSale.ExpiresAt then
		if self.Metrics.Active and self.Metrics.Active.Mode == "PICKUPS" then
			local scope = self.Metrics.Active.Scope
			for index = #self.Metrics.Samples, 1, -1 do
				local sample = self.Metrics.Samples[index]
				if sample.Scope == scope and sample.Mode == "PICKUPS" then table.remove(self.Metrics.Samples, index) end
			end
			if self.PickupProbe then self.PickupProbe.Confirmed = false end
		end
		if self.PendingSale.Mode == "COMBINED" then
			local scope = self.PendingSale.Scope
			self.CombinedEvidence[scope] = self.CombinedEvidence[scope] or {}
			self.CombinedEvidence[scope].SaleAt = now self.CombinedProbeStart = nil
		end
		self.SaleEvidence[self.PendingSale.Scope] = true self.ProbeStart = nil self.PendingSale = nil
		self.Controller:Log("FARM][SELL", "Observed native sale: bubble amount decreased and actual balances subsequently increased")
	end
	if self.PendingSale and now > self.PendingSale.ExpiresAt then self.PendingSale = nil end
	self.LastBubbleAmount = amount
	local current = self.Tracker.Current
	if self.PickupProbe then
		local probe = self.PickupProbe
		local sample = self.Metrics:Rates(probe.Key, now).PICKUPS
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
		self.FullSince = full and (self.FullSince or now) or nil
		if self.Activity and self.Activity.Kind == "FARM" and self.Activity.Mode == "BUBBLES" and full and self.Config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES then
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
		if not evidence or not evidence.GrowthAt or not evidence.PickupAt or not evidence.SaleAt
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
	local _, humanoid = tracker:Root()
	local raw = self.Reader:GetLiveProfile()
	local currentKey = tracker.Current and tracker.Current.Key or "UNKNOWN"
	local snapshot = self.Reader:GetSnapshot()
	local context = { Current = tracker.Current, Islands = islands, AreaRates = areaRates,
		SceneReady = tracker.LastZoneRefresh > -math.huge and tracker.Error == nil,
		Rates = self:_pickupRates(currentKey, now), Sells = mechanics:SellStations(), CanInteract = allowed,
		CanBlow = canBlow, CanTravel = now - mechanics.LastTravelAt >= self.Config.ISLAND_SETTINGS.TRAVEL_COOLDOWN_SECONDS,
		Blocker = reason or bubbleReason or tracker.Error, Now = now, ArrivedAt = tracker.ArrivedAt,
		WalkSpeed = humanoid and humanoid.WalkSpeed, UpgradeBackoff = {}, EffectiveUpgrades = {},
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
	local currency = FarmingPolicy.Target(self.Config, snapshot, plan, context)
	context.Cluster = currency and tracker:Cluster(currency) or nil
	context.PickupUnavailableReason = tracker.Error or tracker.ClusterReason
	context.ActiveSweepPending = tracker.Sweep and tracker.Sweep.Started and next(tracker.Sweep.Pending) ~= nil
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
				candidate.Currency, candidate.Evidence, candidate.TravelSeconds, tostring(candidate.RespawnSeconds or "unknown")))
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

function FarmingCoordinator:_awaitCredit(before, token, currencies)
	local deadline = os.clock() + self.Config.FARMING_SETTINGS.EARNINGS_CONFIRMATION_TIMEOUT_SECONDS
	local after = self.Reader:ReadBalances()
	while not token:CheckCancelled() and os.clock() < deadline do
		for currency, value in pairs(after) do if (not currencies or currencies[currency]) and before[currency] ~= nil and value > before[currency] then return after end end
		task.wait(0.1) after = self.Reader:ReadBalances()
	end
	return after
end

function FarmingCoordinator:_collection(decision, token)
	local cluster = decision.Cluster
	if not self.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS or not cluster then return { Verified = false, Reason = "Collection disabled or cluster unavailable" } end
	if self.Tracker.Sweep and self.Tracker.Sweep.Id == cluster.SweepId then self.Tracker.Sweep.Started = true end
	local before = self.Reader:ReadBalances()
	local beforeProfile = self.Reader:GetLiveProfile()
	local beforeBubble = beforeProfile and beforeProfile.Bubble and beforeProfile.Bubble.Amount
	local beforeSale = self.SaleSequence or 0
	local beforeVisible = 0
	local currencies = {}
	for _, record in ipairs(cluster.Records) do if self.Tracker:IsActive(record) then beforeVisible += 1 currencies[record.Currency] = true end end
	if beforeVisible == 0 then return { Verified = false, Reason = "Frozen targets disappeared before collection began" } end
	self.CollectionVisits += 1
	if self.PickupProbe then self.PickupProbe.Attempts = (self.PickupProbe.Attempts or 0) + 1 end
	local point = cluster.Position
	if self.Config.DIAGNOSTIC_SETTINGS.LOG_PICKUP_DIAGNOSTICS then
		self.Controller:Log("PICKUP][COLLECTION", string.format("visit=%d island=%s position=(%.1f,%.1f,%.1f) range=%.2f | before targets=%d island=%d | interaction=NATIVE_AUTO_RADIUS; OC remote requests=0; native outbound call count unobserved | balances: %s", self.CollectionVisits, cluster.AreaKey, point.X, point.Y, point.Z, cluster.Radius, beforeVisible, self.Tracker.Current and self.Tracker.Current.VisibleCount or 0, balancesText(before)))
	end
	self.Controller:Log("FARM][BULK", string.format("Island=%s | total eligible=%d | cluster=%d | native radius=%.1f | method=NATIVE_RADIUS_CLUSTER_FALLBACK; no island-wide batch API",
		cluster.AreaKey, self.Tracker.Current and self.Tracker.Current.EligibleCount or 0, beforeVisible, cluster.Radius))
	self.Controller:Log("FARM][BULK", string.format("Sweep %d | %d/%d pending in frozen island set; new spawns enter the next sweep", cluster.SweepId, cluster.SweepRemaining, cluster.SweepTotal))
	local saleDue = false
	local function fullBubble()
		local raw = self.Reader:GetLiveProfile()
		local capacity = raw and self.Reader:_stat("GetBubbleStorage", raw, {})
		return raw and raw.Bubble and type(raw.Bubble.Amount) == "number" and capacity and capacity > 0
			and raw.Bubble.Amount / capacity >= self.Config.BUBBLE_SETTINGS.SELL_AT_CAPACITY_RATIO
	end
	local function allGone()
		if decision.Mode == "COMBINED" and self.Config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES and fullBubble() then
			self.FullSince = self.FullSince or os.clock()
			if os.clock() - self.FullSince >= self.Config.FARMING_SETTINGS.MAXIMUM_COMBINED_SELL_DELAY_SECONDS then saleDue = true return true end
		end
		for _, record in ipairs(cluster.Records) do if self.Tracker:IsActive(record) then return false end end
		return true
	end
	local tick = decision.Mode == "COMBINED" and function()
		if not (self.Config.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES and fullBubble()) then self.Mechanics:Blow(token) end
	end or nil
	local permitted, reason = self.Mechanics:Walk(cluster.Position, token, os.clock() + self.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS, tick, allGone)
	if token:CheckCancelled() then return nil end
	if permitted and not saleDue then self:_settle(token, self.Config.PICKUP_SETTINGS.COLLECTION_SETTLE_SECONDS, tick) end
	if token:CheckCancelled() then return nil end
	local disappeared = 0
	for _, record in ipairs(cluster.Records) do if not record.Model.Parent then disappeared += 1 end end
	if not permitted then
		self.Tracker:BackOff(cluster.Records, reason == "Slice ended" and self.Config.PICKUP_SETTINGS.COLLECTION_RETRY_SECONDS or self.Config.PICKUP_SETTINGS.UNREACHABLE_RETRY_SECONDS, reason)
	elseif disappeared == 0 and not saleDue then
		self.Tracker:BackOff(cluster.Records, self.Config.PICKUP_SETTINGS.COLLECTION_RETRY_SECONDS, "No disappearance observed")
	end
	local after = self:_awaitCredit(before, token, currencies)
	if token:CheckCancelled() then return nil end
	disappeared = 0
	local disappearedCurrencies = {}
	for _, record in ipairs(cluster.Records) do if not record.Model.Parent then disappeared += 1 disappearedCurrencies[record.Currency] = true end end
	local gains = {}
	for currency in pairs(disappearedCurrencies) do
		if type(before[currency]) == "number" and type(after[currency]) == "number" and after[currency] > before[currency] then gains[currency] = after[currency] - before[currency] end
	end
	local afterProfile = self.Reader:GetLiveProfile()
	local afterBubble = afterProfile and afterProfile.Bubble and afterProfile.Bubble.Amount
	local mixedSale = self.PendingSale ~= nil or beforeSale ~= (self.SaleSequence or 0) or (type(beforeBubble) == "number" and type(afterBubble) == "number" and afterBubble < beforeBubble)
	local verified = next(gains) ~= nil and decision.Mode == "PICKUPS" and not mixedSale
	local combined = decision.Mode == "COMBINED" and next(gains) ~= nil
	if combined then
		local evidence = self.CombinedEvidence[cluster.AreaKey] or {}
		self.CombinedEvidence[cluster.AreaKey] = evidence
		if not mixedSale then evidence.PickupAt = os.clock() end
		if type(beforeBubble) == "number" and type(afterBubble) == "number" and afterBubble > beforeBubble then evidence.GrowthAt = os.clock() end
		self.Controller:Log("FARM][COMBINED", "Matching pickup disappearance and live credit observed; bubble amount " .. tostring(beforeBubble) .. " -> " .. tostring(afterBubble)
			.. " | complete sale evidence=" .. tostring(evidence.SaleAt ~= nil) .. "; comparison also requires an adequate sample")
	end
	if verified then
		self.Metrics:ConfirmCycle(before, after, "Native pickup disappearance and matching credit observed; external rewards can affect attribution")
		for currency in pairs(gains) do self.PickupEvidence[cluster.AreaKey .. ":" .. currency] = os.clock() end
		if self.PickupProbe and gains[self.PickupProbe.Currency] then self.PickupProbe.Confirmed = true end
	else
		self.Metrics.UnconfirmedCycles += 1
		self.Metrics.LastConfirmation = mixedSale and "Bubble sale may have contributed; isolated pickup credit unconfirmed" or (decision.Mode == "COMBINED" and "Combined balance gain; isolated pickup credit unconfirmed" or "Pickup credit unconfirmed: disappearance and matching currency increase are both required")
	end
	self.Controller:Log("FARM][BULK", string.format("%d/%d models disappeared (not proof of credit) | %s", disappeared, beforeVisible, reason or "observed"))
	self.Controller:Log("FARM][EARNINGS", "before: " .. balancesText(before) .. " | after: " .. balancesText(after) .. " | " .. self.Metrics.LastConfirmation)
	self.Tracker:Refresh(self.Reader:GetSnapshot(), os.clock())
	if self.Config.DIAGNOSTIC_SETTINGS.LOG_PICKUP_DIAGNOSTICS then
		self.Controller:Log("PICKUP][RESULT", string.format("%s | targets before=%d after=%d disappeared=%d | before: %s | after: %s | %s", verified and "SUCCESS: matching live balance credit" or "UNCONFIRMED", beforeVisible, math.max(0, beforeVisible - disappeared), disappeared, balancesText(before), balancesText(after), self.Metrics.LastConfirmation))
	end
	if not permitted and self.Config.DIAGNOSTIC_SETTINGS.LOG_MOVEMENT_DIAGNOSTICS then
		self.Controller:Log("MOVE][SKIP", tostring(reason) .. " | selected IDs in temporary backoff; other eligible targets remain available")
	end
	return { Verified = verified, CombinedCreditObserved = combined, Disappeared = disappeared, Gains = gains, Reason = saleDue and "Full bubble: bounded combined sell delay reached" or reason }
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
	local started = os.clock()
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
			if token:CheckCancelled() then return nil end
			local gains = self.Metrics:ConfirmCycle(before, after, "Native bubble sale")
			local active = self.Metrics.Active
			if active and next(gains) then self.SaleEvidence[active.Scope] = true end
			if next(gains) then
				self.Mechanics.SellTimes = self.Mechanics.SellTimes or {} self.Mechanics.SellTimes[sell.Key] = os.clock() - started
				if active and active.Mode == "COMBINED" then
					local evidence = self.CombinedEvidence[active.Scope] or {} self.CombinedEvidence[active.Scope] = evidence
					evidence.SaleAt = os.clock() self.CombinedProbeStart = nil
				end
			end
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
			if decision.Probe and decision.Kind ~= "TRAVEL" and not self.PickupProbe then self:_beginPickupProbe(scope, decision.Currency) end
			if decision.Kind == "FARM" then
				self.Metrics:SetMode(decision.Mode, scope, beforeBalances, os.clock())
				if decision.Mode == "COMBINED" and not self.CombinedProbeStart then self.CombinedProbeStart = os.clock() end
				if decision.Mode == "BUBBLES" and not self.ProbeStart then
					local raw = self.Reader:GetLiveProfile()
					self.ProbeStart = raw and raw.Bubble and { Amount = raw.Bubble.Amount, At = os.clock() } or nil
				end
			elseif decision.Kind == "INSPECT" then
				local ready = self.PickupProbe and os.clock() >= self.PickupProbe.ReadyAt
				self.Metrics:SetMode(ready and "PICKUPS" or nil, scope, beforeBalances, os.clock())
			elseif decision.Kind ~= "SELL" or (self.Metrics.Active and self.Metrics.Active.Mode == "PICKUPS") then
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
				if decision.Probe then self.IslandProbeHistory[area.Key .. ":" .. decision.Currency] = os.clock() end
				self.Controller:Log("FARM][TRAVEL", "Request " .. area.Key .. " through native unlocked island Teleport | " .. decision.Reason)
				local success, reason, seconds = self.Mechanics:TravelIsland(area, token)
				if success then
					self.Tracker:Refresh(self.Reader:GetSnapshot(), os.clock())
					local actual = self.Tracker.Current
					success = actual ~= nil and actual.Key == area.Key
					if success then
						self.Controller:Log("FARM][TRAVEL", "Arrival and island identity confirmed: " .. area.Key .. " | " .. tostring(seconds) .. "s")
						if decision.Probe then self:_beginPickupProbe(area.Key, decision.Currency) end
					end
				end
				if not success and not token:CheckCancelled() then
					self.Mechanics:Failure("ISLAND:" .. area.Key, self.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS, reason or "Island identity uncertain")
					self.Controller:Log("FARM][TRAVEL", "Unconfirmed arrival: " .. area.Key .. " | " .. tostring(reason))
				end
				return { Verified = success, Reason = reason }
			elseif decision.Kind == "INSPECT" then
				local duration = math.min(2, self.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS)
				self:_settle(token, duration)
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
	elseif result and not result.Verified and result.Reason then
		local now = os.clock()
		if self.LastFallbackReason ~= result.Reason or now - (self.LastFallbackLogAt or -math.huge) >= math.max(5, self.Config.DIAGNOSTIC_SETTINGS.MINIMUM_LOG_INTERVAL_SECONDS) then
			self.LastFallbackReason, self.LastFallbackLogAt = result.Reason, now
			self.Controller:Log("FARM][FALLBACK", result.Reason)
		end
	elseif status == "CANCELLED" then self.Controller:Log("FARM][CANCELLED", tostring(reason)) end
	self:Observe()
end

function FarmingCoordinator:Halt()
	self.Mechanics:StopMovement()
	self.Metrics:SetMode(nil, nil, self.Reader:ReadBalances(), os.clock())
	self.Activity = nil self.ProbeStart = nil self.PendingSale = nil self.EmptySince = {} self.PickupProbe = nil self.FullSince = nil self.CombinedProbeStart = nil
end

function FarmingCoordinator:GetStatus()
	local current = self.Tracker.Current
	return { Activity = self.Activity and (self.Activity.Mode or self.Activity.Kind), Decision = self.Decision,
		Area = current and current.Key, VisiblePickups = current and current.VisibleCount or 0,
		EligiblePickups = current and current.EligibleCount or 0, UnknownPickups = current and current.UnknownCount or 0,
		Disappeared = self.Tracker.Disappeared, ObservedSpawns = self.Tracker.ObservedSpawns,
		RespawnObservations = self.Tracker.RespawnObservations, Radius = self.Tracker.Range, CollectionVisits = self.CollectionVisits,
		Rates = self:_pickupRates(current and current.Key or "UNKNOWN", os.clock()), Scan = self.Tracker.ScanReport, CollectionBlocker = self.Tracker.ClusterReason,
		ConfirmedCycles = self.Metrics.ConfirmedCycles, LastConfirmation = self.Metrics.LastConfirmation,
		Error = self.Tracker.Error, GameKnowledge = self.Knowledge:GetStatus(), CollectionMethod = "Native radius clusters; no genuine island-wide batch API found" }
end

function FarmingCoordinator:Destroy()
	self:Halt() self.Destroyed = true
	if self.ObservationThread then pcall(task.cancel, self.ObservationThread) end
	self.Tracker:Destroy()
end

return FarmingCoordinator

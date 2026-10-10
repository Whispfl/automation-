--!nonstrict
-- Existing foreground collector, retained under its compatibility module name.
-- Discovery observes genuine Tutorial IDs; only the scheduler sends requests.
local StationaryExperiment = {}
StationaryExperiment.__index = StationaryExperiment

function StationaryExperiment.new(owner)
	return setmetatable({ Owner = owner, PerId = {}, Requests = 0, CreditWindows = 0, UncreditedWindows = 0, Gains = {} }, StationaryExperiment)
end

function StationaryExperiment:LimitReason()
	if os.clock() < (self.NextBatchAt or 0) then return "Stationary batch cooldown" end
	return nil
end

function StationaryExperiment:_eligible(record)
	local state = self.PerId[record.Id]
	return record.Id ~= nil and (record.Currency == "Coins" or record.Currency == "Gems")
		and (not state or (not state.Dispatched and state.Attempts < self.Owner.Config.PICKUP_SETTINGS.STATIONARY_MAXIMUM_ATTEMPTS_PER_ID and os.clock() >= state.Until))
end

function StationaryExperiment:Candidate(cluster)
	local registry, now = self.Owner.Knowledge:ActivePickups(), os.clock()
	-- Preserve deduplication through short Chunker unloads, reclaim retired IDs.
	for id, state in pairs(self.PerId) do
		if registry and registry[state.Key] then state.LastSeen = now
		elseif registry and now - state.LastSeen > 60 then self.PerId[id] = nil end
	end
	local reason = self:LimitReason()
	if reason then return nil, reason end
	for _, record in ipairs(cluster and cluster.Records or {}) do
		if self:_eligible(record) then return record end
	end
	return nil, "Waiting for new genuine Coins/Gems IDs; existing requests are deduplicated"
end

function StationaryExperiment:Collect(decision, token)
	local owner, settings = self.Owner, self.Owner.Config.PICKUP_SETTINGS
	if token:CheckCancelled() then return nil end
	local candidate, reason = self:Candidate(decision.Cluster)
	if not candidate then return { Verified = false, Reason = reason } end
	local before = owner.Reader:ReadBalances()
	if not owner.Tracker:Root() or type(before.Coins) ~= "number" or type(before.Gems) ~= "number" then return { Verified = false, Reason = "Ready LocalData Coins/Gems and root required; no request dispatched" } end
	local areaKey, started = owner.Tracker.Current.Key, os.clock()
	local deadline = started + owner.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS
	local raw = owner.Reader:GetLiveProfile()
	local initialBubble = raw and raw.Bubble and raw.Bubble.Amount
	local saleSequence, previousBubble = owner.SaleSequence or 0, initialBubble
	local previous, after = before, before
	local contaminated, missing, areaChanged = false, false, false
	local ids, currencies, outside, invocationSucceeded = {}, {}, 0, true
	local function observe()
		after = owner.Reader:ReadBalances()
		for _, currency in ipairs({ "Coins", "Gems" }) do
			if type(after[currency]) ~= "number" then missing = true
			elseif type(previous[currency]) == "number" and after[currency] < previous[currency] then contaminated = true end
		end
		previous = after
		local live = owner.Reader:GetLiveProfile()
		local amount = live and live.Bubble and live.Bubble.Amount
		if owner.PendingSale or saleSequence ~= (owner.SaleSequence or 0) or (type(previousBubble) == "number" and type(amount) == "number" and amount < previousBubble) then contaminated = true end
		previousBubble = amount
		if owner.Cycle and type(initialBubble) == "number" and type(amount) == "number" and amount > initialBubble then owner.Cycle.GrowthAt = os.clock() end
		local current = owner.Tracker.Current
		if not owner.Tracker:Root() or not current or current.Key ~= areaKey then areaChanged = true end
	end
	for _, record in ipairs(decision.Cluster.Records) do
		if token:CheckCancelled() or os.clock() >= deadline or #ids >= settings.STATIONARY_MAXIMUM_BATCH_SIZE then break end
		if not self:_eligible(record) then continue end
		local delay = settings.STATIONARY_REQUEST_COOLDOWN_SECONDS - (os.clock() - (owner.Mechanics.LastPickupRequestAt or -math.huge))
		while delay > 1e-6 and not token:CheckCancelled() and os.clock() < deadline do
			task.wait(math.min(0.05, delay, deadline - os.clock())) observe()
			delay = settings.STATIONARY_REQUEST_COOLDOWN_SECONDS - (os.clock() - (owner.Mechanics.LastPickupRequestAt or -math.huge))
		end
		if token:CheckCancelled() or areaChanged or os.clock() >= deadline then break end
		local requested, invocation, evidence = owner.Mechanics:CollectStationary(record, token)
		if not requested then reason = invocation continue end
		self.StartedAt = self.StartedAt or started
		self.Requests += 1
		local state = self.PerId[record.Id] or { Attempts = 0, Key = record.RegistryKey or record.Id }
		self.PerId[record.Id] = state
		state.Attempts += 1 state.Until = os.clock() + settings.STATIONARY_ID_RETRY_SECONDS state.LastSeen = os.clock()
		state.Dispatched = evidence.InvocationSucceeded -- Invocation deduplication, never credit evidence.
		table.insert(ids, record.Id) currencies[record.Currency] = true
		if evidence.OutsideNativeRange then outside += 1 end
		invocationSucceeded = invocationSucceeded and evidence.InvocationSucceeded
		owner.Controller:Log("PICKUP][STATIONARY_REQUEST", string.format("id=%s currency=%s distance=%.2f radius=%s outsideNative=%s | %s",
			tostring(record.Id), record.Currency, evidence.Distance, tostring(evidence.Radius), tostring(evidence.OutsideNativeRange), invocation))
		observe()
		if decision.Mode == "COMBINED" and not settings.STATIONARY_ISOLATED_TEST then owner:_background(token) end
	end
	if #ids == 0 then return { Verified = false, Reason = reason or "No eligible live registry IDs dispatched" } end
	self.NextBatchAt = os.clock() + settings.STATIONARY_BATCH_COOLDOWN_SECONDS
	owner.CollectionVisits += 1
	deadline = math.min(deadline, os.clock() + owner.Config.FARMING_SETTINGS.EARNINGS_CONFIRMATION_TIMEOUT_SECONDS)
	while not token:CheckCancelled() and not areaChanged do
		observe()
		if os.clock() >= deadline then break end
		if decision.Mode == "COMBINED" and not settings.STATIONARY_ISOLATED_TEST then owner:_background(token) end
		task.wait(math.min(0.1, deadline - os.clock()))
	end
	if token:CheckCancelled() then
		self.NextBatchAt = os.clock() + settings.STATIONARY_BATCH_COOLDOWN_SECONDS
		self.LastResult = { Cancelled = true, Ids = ids, Reason = "Cancelled; dispatched IDs retained and credit window discarded" }
		return nil
	end
	local gains, creditedAfter = {}, {}
	if not contaminated and not missing and not areaChanged then
		for currency in pairs(currencies) do
			local gain = after[currency] - before[currency]
			if gain > 0 then gains[currency] = gain creditedAfter[currency] = after[currency] end
		end
	end
	local credit = next(gains) ~= nil
	if credit then
		self.CreditWindows += 1
		owner.Metrics:ConfirmCycle(before, creditedAfter, "Stationary batch LocalData credit observed; request/native/external attribution unproven")
		for currency, gain in pairs(gains) do
			self.Gains[currency] = (self.Gains[currency] or 0) + gain owner.PickupEvidence[areaKey .. ":" .. currency] = os.clock()
			if owner.PickupProbe and owner.PickupProbe.Currency == currency then owner.PickupProbe.Confirmed = true owner.PickupProbe.Attempts = (owner.PickupProbe.Attempts or 0) + 1 end
		end
		if decision.Mode == "COMBINED" and owner.Cycle then owner.Cycle.PickupAt = os.clock() end
	else
		self.UncreditedWindows += 1 owner.Metrics.UnconfirmedCycles += 1
		owner.Metrics.LastConfirmation = areaChanged and "Current credit window discarded after island/root change; farming resumes on eligible IDs"
			or contaminated and "Stationary window contaminated by sale/spending; credit unconfirmed"
			or missing and "LocalData unavailable; stationary credit unconfirmed" or "No matching LocalData credit; server acceptance unknown; no movement fallback"
	end
	owner.Metrics:AddSample("STATIONARY", areaKey, gains, os.clock() - (self.LastSampleAt or started), os.clock())
	self.LastSampleAt = os.clock()
	self.NextBatchAt = os.clock() + settings.STATIONARY_BATCH_COOLDOWN_SECONDS
	self.LastResult = { Ids = ids, BatchSize = #ids, CreditObserved = credit, Gains = gains, Before = before, After = after,
		OutsideNativeRange = outside > 0, OutsideNativeCount = outside, Contaminated = contaminated or missing or areaChanged,
		InvocationSucceeded = invocationSucceeded, Attribution = "UNPROVEN: native collection/external rewards can contribute" }
	owner.Controller:Log("PICKUP][STATIONARY_RESULT", string.format("batch=%d creditObserved=%s outsideNative=%d | Coins %s -> %s | Gems %s -> %s | %s",
		#ids, tostring(credit), outside, tostring(before.Coins), tostring(after.Coins), tostring(before.Gems), tostring(after.Gems), owner.Metrics.LastConfirmation))
	return { Verified = credit, CreditObserved = credit, CombinedCreditObserved = credit and decision.Mode == "COMBINED", Gains = gains, Reason = owner.Metrics.LastConfirmation }
end

function StationaryExperiment:GetStatus()
	return { Experimental = true, Requests = self.Requests, StartedAt = self.StartedAt, CreditWindows = self.CreditWindows,
		BatchLimit = self.Owner.Config.PICKUP_SETTINGS.STATIONARY_MAXIMUM_BATCH_SIZE, Continuous = true,
		UncreditedWindows = self.UncreditedWindows, Gains = table.clone(self.Gains), LastResult = self.LastResult,
		Blocker = self:LimitReason(), ServerAcceptance = "UNKNOWN", MovementFallback = false }
end

return StationaryExperiment

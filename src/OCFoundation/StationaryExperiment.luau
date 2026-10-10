--!nonstrict
-- Called only by the existing foreground farming task. No action thread or movement fallback.
local StationaryExperiment = {}
StationaryExperiment.__index = StationaryExperiment

function StationaryExperiment.new(owner)
	return setmetatable({ Owner = owner, PerId = {}, Requests = 0, CreditWindows = 0, UncreditedWindows = 0, Gains = {} }, StationaryExperiment)
end

function StationaryExperiment:LimitReason()
	local settings = self.Owner.Config.PICKUP_SETTINGS
	if self.Invalidated then return self.Invalidated end
	if self.Requests >= settings.STATIONARY_MAXIMUM_REQUESTS then return "Stationary request budget exhausted; no movement fallback" end
	if self.StartedAt and os.clock() - self.StartedAt >= settings.STATIONARY_TEST_DURATION_SECONDS then return "Stationary experiment expired; no movement fallback" end
	local current, root = self.Owner.Tracker.Current, self.Owner.Tracker:Root()
	if self.StartedAt and (not current or current.Key ~= self.AreaKey or not root or (root.Position - self.Anchor).Magnitude > settings.STATIONARY_MAXIMUM_DRIFT_STUDS) then
		self.Invalidated = "Stationary position/island changed; experiment invalidated, no movement fallback"
		return self.Invalidated
	end
	if os.clock() - (self.Owner.Mechanics.LastPickupRequestAt or -math.huge) < settings.STATIONARY_REQUEST_COOLDOWN_SECONDS then return "Stationary request cooldown" end
	return nil
end

function StationaryExperiment:Candidate(cluster)
	local reason = self:LimitReason()
	if reason then return nil, reason end
	local settings = self.Owner.Config.PICKUP_SETTINGS
	local best, attempts
	for _, record in ipairs(cluster and cluster.Records or {}) do
		local state = self.PerId[record.Id]
		local count = state and state.Attempts or 0
		if record.Id and (record.Currency == "Coins" or record.Currency == "Gems")
			and count < settings.STATIONARY_MAXIMUM_ATTEMPTS_PER_ID and not (state and state.CreditObserved)
			and (not state or os.clock() >= state.Until) then
			if not best or count < attempts or (count == attempts and record.Currency ~= self.LastCurrency and best.Currency == self.LastCurrency) then best, attempts = record, count end
		end
	end
	return best, best and nil or "No eligible stationary IDs outside deduplication/retry backoff; no movement fallback"
end

function StationaryExperiment:Collect(decision, token)
	local owner, settings = self.Owner, self.Owner.Config.PICKUP_SETTINGS
	if token:CheckCancelled() then return nil end
	local record, reason = self:Candidate(decision.Cluster)
	if not record then return { Verified = false, Reason = reason } end
	local root = owner.Tracker:Root()
	local before = owner.Reader:ReadBalances()
	if not root or type(before.Coins) ~= "number" or type(before.Gems) ~= "number" then return { Verified = false, Reason = "Ready LocalData Coins/Gems and root required; no request dispatched" } end
	local initialPosition, areaKey = root.Position, owner.Tracker.Current.Key
	local raw = owner.Reader:GetLiveProfile()
	local initialBubble = raw and raw.Bubble and raw.Bubble.Amount
	local saleSequence = owner.SaleSequence or 0
	local started = os.clock()
	local requested, invocation, evidence = owner.Mechanics:CollectStationary(record, token)
	if not requested then return { Verified = false, Reason = invocation } end
	self.StartedAt, self.Anchor, self.AreaKey = self.StartedAt or started, self.Anchor or initialPosition, self.AreaKey or areaKey
	self.Requests += 1 self.LastCurrency = record.Currency
	local state = self.PerId[record.Id] or { Attempts = 0 }
	self.PerId[record.Id] = state
	state.Attempts += 1 state.Until = started + settings.STATIONARY_ID_RETRY_SECONDS
	owner.CollectionVisits += 1
	owner.Controller:Log("PICKUP][STATIONARY_REQUEST", string.format("attempt=%d/%d id=%s currency=%s distance=%.2f radius=%.2f outsideNative=%s | %s; invocation is not credit",
		self.Requests, settings.STATIONARY_MAXIMUM_REQUESTS, tostring(record.Id), record.Currency, evidence.Distance, evidence.Radius, tostring(evidence.OutsideNativeRange), invocation))
	local previous, after = before, before
	local previousBubble = initialBubble
	local contaminated, drifted, missing = false, false, false
	local deadline = math.min(started + owner.Config.FARMING_SETTINGS.EARNINGS_CONFIRMATION_TIMEOUT_SECONDS,
		started + owner.Config.FARMING_SETTINGS.ACTION_SLICE_SECONDS, self.StartedAt + settings.STATIONARY_TEST_DURATION_SECONDS)
	while not token:CheckCancelled() do
		local currentRoot, current = owner.Tracker:Root(), owner.Tracker.Current
		if not currentRoot or not current or current.Key ~= areaKey or (currentRoot.Position - self.Anchor).Magnitude > settings.STATIONARY_MAXIMUM_DRIFT_STUDS then drifted = true break end
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
		if os.clock() >= deadline then break end
		if decision.Mode == "COMBINED" and not settings.STATIONARY_ISOLATED_TEST then owner:_background(token) end
		task.wait(math.min(0.1, deadline - os.clock()))
	end
	if token:CheckCancelled() then
		self.LastResult = { Cancelled = true, Id = record.Id, Reason = "Cancelled; attempt budget retained and credit window discarded" }
		return nil
	end
	if drifted then self.Invalidated = "Stationary position/island changed; credit window discarded, no movement fallback" end
	local gain = type(after[record.Currency]) == "number" and after[record.Currency] - before[record.Currency] or 0
	local credit = gain > 0 and not contaminated and not drifted and not missing
	local gains = credit and { [record.Currency] = gain } or {}
	state.CreditObserved = credit
	if credit then
		self.CreditWindows += 1 self.Gains[record.Currency] = (self.Gains[record.Currency] or 0) + gain
		owner.Metrics:ConfirmCycle(before, { [record.Currency] = after[record.Currency] }, "Stationary matching LocalData credit observed; request/native/external attribution unproven")
		owner.PickupEvidence[areaKey .. ":" .. record.Currency] = os.clock()
		if owner.PickupProbe and owner.PickupProbe.Currency == record.Currency then owner.PickupProbe.Confirmed = true owner.PickupProbe.Attempts = (owner.PickupProbe.Attempts or 0) + 1 end
		if decision.Mode == "COMBINED" and owner.Cycle then owner.Cycle.PickupAt = os.clock() end
	else
		self.UncreditedWindows += 1 owner.Metrics.UnconfirmedCycles += 1
		owner.Metrics.LastConfirmation = drifted and self.Invalidated or contaminated and "Stationary window contaminated by sale/spending; credit unconfirmed"
			or missing and "LocalData unavailable; stationary credit unconfirmed" or "No matching LocalData credit; server acceptance unknown; no movement fallback"
	end
	-- Include idle/cooldown time since the preceding window, without snapshot double counting.
	owner.Metrics:AddSample("STATIONARY", areaKey, gains, os.clock() - (self.LastSampleAt or started), os.clock())
	self.LastSampleAt = os.clock()
	self.LastResult = { Id = record.Id, Currency = record.Currency, CreditObserved = credit, Gain = credit and gain or 0,
		Before = before, After = after, OutsideNativeRange = evidence.OutsideNativeRange,
		Distance = evidence.Distance, Radius = evidence.Radius, Contaminated = contaminated or missing or drifted,
		InvocationSucceeded = evidence.InvocationSucceeded, Attribution = "UNPROVEN: native collection/external rewards can contribute" }
	owner.Controller:Log("PICKUP][STATIONARY_RESULT", string.format("id=%s creditObserved=%s outsideNative=%s | Coins %s -> %s | Gems %s -> %s | %s",
		tostring(record.Id), tostring(credit), tostring(evidence.OutsideNativeRange), tostring(before.Coins), tostring(after.Coins), tostring(before.Gems), tostring(after.Gems), owner.Metrics.LastConfirmation))
	return { Verified = credit, CreditObserved = credit, CombinedCreditObserved = credit and decision.Mode == "COMBINED", Gains = gains,
		Reason = credit and "Matching LocalData credit observed; distant-request attribution remains unproven" or owner.Metrics.LastConfirmation }
end

function StationaryExperiment:GetStatus()
	return { Experimental = true, Requests = self.Requests, StartedAt = self.StartedAt, CreditWindows = self.CreditWindows,
		RequestLimit = self.Owner.Config.PICKUP_SETTINGS.STATIONARY_MAXIMUM_REQUESTS, DurationLimit = self.Owner.Config.PICKUP_SETTINGS.STATIONARY_TEST_DURATION_SECONDS,
		UncreditedWindows = self.UncreditedWindows, Gains = table.clone(self.Gains), LastResult = self.LastResult,
		Blocker = self:LimitReason(), ServerAcceptance = "UNKNOWN", MovementFallback = false }
end

return StationaryExperiment

--!nonstrict
-- Observed balance deltas, never pickup face values or predicted sale credit.
local ResourceMetrics = {}
ResourceMetrics.__index = ResourceMetrics

function ResourceMetrics.new(settings)
	return setmetatable({ Settings = settings, Samples = {}, Active = nil, Last = nil, Totals = {},
		ConfirmedCycles = 0, UnconfirmedCycles = 0, LastConfirmation = "No collection verified yet" }, ResourceMetrics)
end

function ResourceMetrics:Observe(balances, now)
	local previous = self.Last
	self.Last = { At = now, Balances = table.clone(balances) }
	if self.AttributionBlockedProvider and self.AttributionBlockedProvider() then return {} end
	if not previous or not self.Active then return {} end
	local dt = math.max(0, now - previous.At)
	local gains, spending = {}, false
	for currency, value in pairs(balances) do
		local old = previous.Balances[currency]
		if type(value) == "number" and type(old) == "number" then
			if value < old then spending = true end
			if value > old then gains[currency] = value - old end
		end
	end
	-- A purchase or externally observed spend makes this interval unsuitable for rate attribution.
	if spending then return {} end
	if dt > 0 then
		-- Combined income is recorded once, after a complete fill/sale/return cycle.
		if self.Active.Mode ~= "COMBINED" and self.Active.Mode ~= "STATIONARY" then
			table.insert(self.Samples, { At = now, Seconds = dt, Mode = self.Active.Mode,
				Scope = self.Active.Scope, Gains = gains })
		end
		for currency, value in pairs(gains) do self.Totals[currency] = (self.Totals[currency] or 0) + value end
	end
	self:Prune(now)
	return gains
end

function ResourceMetrics:AddSample(mode, scope, gains, seconds, now)
	if self.AttributionBlockedProvider and self.AttributionBlockedProvider() then return end
	if seconds <= 0 then return end
	table.insert(self.Samples, { At = now, Seconds = seconds, Mode = mode, Scope = scope, Gains = table.clone(gains) })
	self:Prune(now)
end

function ResourceMetrics:Prune(now)
	for index = #self.Samples, 1, -1 do
		if now - self.Samples[index].At > self.Settings.RATE_WINDOW_SECONDS then table.remove(self.Samples, index) end
	end
	while #self.Samples > 1024 do table.remove(self.Samples, 1) end
end

function ResourceMetrics:SetMode(mode, scope, balances, now)
	self:Observe(balances, now)
	if not mode then self.Active = nil return end
	if not self.Active or self.Active.Mode ~= mode or self.Active.Scope ~= scope then
		self.Active = { Mode = mode, Scope = scope, StartedAt = now }
	end
end

function ResourceMetrics:Rates(scope, now)
	self:Prune(now)
	local result = {}
	for _, sample in ipairs(self.Samples) do
		if sample.Scope == scope then
			local entry = result[sample.Mode] or { Seconds = 0, Earned = {}, PerMinute = {}, LastAt = sample.At }
			result[sample.Mode] = entry
			entry.Seconds += sample.Seconds
			entry.LastAt = math.max(entry.LastAt, sample.At)
			for currency, amount in pairs(sample.Gains) do entry.Earned[currency] = (entry.Earned[currency] or 0) + amount end
		end
	end
	for _, entry in pairs(result) do
		entry.Ready = entry.Seconds >= self.Settings.MINIMUM_RATE_SAMPLE_SECONDS
		if entry.Ready then
			for currency, amount in pairs(entry.Earned) do entry.PerMinute[currency] = amount * 60 / entry.Seconds end
		end
	end
	return result
end

function ResourceMetrics:ConfirmCycle(before, after, source)
	if self.AttributionBlockedProvider and self.AttributionBlockedProvider() then
		self.LastConfirmation = "Non-pickup reward attribution pending/uncertain; no farming credit published"
		return {}
	end
	local gains = {}
	for currency, value in pairs(after) do
		if type(before[currency]) == "number" and value > before[currency] then gains[currency] = value - before[currency] end
	end
	if next(gains) then
		self.ConfirmedCycles += 1
		local items = {}
		for currency, value in pairs(gains) do table.insert(items, string.format("+%.0f %s", value, currency)) end
		table.sort(items)
		self.LastConfirmation = source .. " | actual balance increased: " .. table.concat(items, ", ")
	else
		self.UnconfirmedCycles += 1
		self.LastConfirmation = source .. " | no positive balance change confirmed"
	end
	return gains
end

return ResourceMetrics

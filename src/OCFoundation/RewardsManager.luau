--!nonstrict
-- Narrow playtime/ordinary-box coordinator. Native commands/input remain in
-- GameMechanics; observation uses the existing reader and scheduler only.
local RewardsManager = {}
RewardsManager.__index = RewardsManager

local function finite(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function count(value)
	return finite(value) and value >= 0 and value % 1 == 0
end

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copy(entry) end
	return result
end

local function facts(context)
	local raw, result = context.Raw or {}, { Balances = {}, Powerups = {}, Potions = {}, Pets = {}, Available = {} }
	result.Available.Balances = type(context.Balances) == "table"
	result.Available.Powerups = type(raw.Powerups) == "table"
	result.Available.Potions = type(raw.Potions) == "table"
	result.Available.Pets = type(raw.Pets) == "table"
	for name, value in pairs(context.Balances or {}) do if finite(value) then result.Balances[name] = value end end
	for name, value in pairs(type(raw.Powerups) == "table" and raw.Powerups or {}) do
		if count(value) then result.Powerups[name] = value end
	end
	for name, levels in pairs(type(raw.Potions) == "table" and raw.Potions or {}) do
		if type(levels) == "table" then
			for level, amount in pairs(levels) do if count(amount) then result.Potions[tostring(name) .. ":" .. tostring(level)] = amount end end
		end
	end
	for _, pet in pairs(type(raw.Pets) == "table" and raw.Pets or {}) do
		if type(pet) == "table" and type(pet.Id) == "string" and type(pet.Name) == "string" and count(pet.Amount or 1) then
			result.Pets[pet.Id] = { Name = pet.Name, Amount = pet.Amount or 1 }
		end
	end
	return result
end

local function deltas(before, after)
	local result = {}
	for _, category in ipairs({ "Balances", "Powerups", "Potions" }) do
		if not before.Available[category] or not after.Available[category] then continue end
		for name, value in pairs(after[category]) do
			local old = before[category][name]
			-- A missing inventory key can represent a newly received item; a missing
			-- currency baseline stays unknown, never substituted with zero.
			if old == nil and category ~= "Balances" then old = 0 end
			if finite(old) and value > old then table.insert(result, { Kind = category, Name = name, Amount = value - old }) end
		end
	end
	for id, pet in pairs(before.Available.Pets and after.Available.Pets and after.Pets or {}) do
		local old = before.Pets[id]
		if not old or old.Name == pet.Name then
			local gain = pet.Amount - (old and old.Amount or 0)
			if gain > 0 then table.insert(result, { Kind = "Pets", Id = id, Name = pet.Name, Amount = gain }) end
		end
	end
	table.sort(result, function(a, b) return a.Kind .. tostring(a.Id or a.Name) < b.Kind .. tostring(b.Id or b.Name) end)
	return result
end

function RewardsManager.new(controller)
	local self = setmetatable({ Controller = controller, Config = controller.Config, NextCheckAt = 0 }, RewardsManager)
	local player = controller.Reader and controller.Reader.Player
	self.UserId = player and player.UserId
	if not count(self.UserId) or self.UserId == 0 or type(shared) ~= "table" then
		self.Blocker = "Persistent account reward ledger unavailable; no reward dispatch"
		return self
	end
	local root = shared.__OC_LOCAL_REWARD_LEDGER
	if root ~= nil and (type(root) ~= "table" or root.Version ~= 1 or type(root.Accounts) ~= "table") then
		self.Blocker = "Existing reward ledger has an unknown schema; preserved without dispatch"
		self.UnknownBarrier = true
		return self
	end
	if not root then root = { Version = 1, Accounts = {} } shared.__OC_LOCAL_REWARD_LEDGER = root end
	local key = tostring(self.UserId)
	local ledger = root.Accounts[key]
	if ledger ~= nil and (type(ledger) ~= "table" or ledger.UserId ~= self.UserId or type(ledger.Sessions) ~= "table") then
		self.Blocker = "Existing account reward ledger is inconsistent; preserved without dispatch"
		self.UnknownBarrier = true
		return self
	end
	if not ledger then
		ledger = { UserId = self.UserId, Sessions = {}, ClaimsRequested = 0, ClaimsAcknowledged = 0, NextClaimAt = 0, NextBoxAt = 0 }
		root.Accounts[key] = ledger
	end
	local pending = ledger.Pending
	if type(pending) == "table" and pending.Kind == "WHEEL_SPIN" then
		local valid, reason = self:ValidateWheelSpinPending(ledger, pending)
		if not valid then self.Blocker, self.UnknownBarrier = reason, true return self end
	elseif type(pending) == "table" and pending.Kind == "FREE_WHEEL_TICKET" then
		local valid, reason = self:ValidateFreeWheelTicketPending(ledger, pending)
		if not valid then self.Blocker, self.UnknownBarrier = reason, true return self end
	elseif pending ~= nil and (type(pending) ~= "table" or pending.UserId ~= self.UserId or not finite(pending.Deadline)
		or type(pending.Attempted) ~= "boolean" or type(pending.BeforeFacts) ~= "table" or type(pending.BeforeFacts.Available) ~= "table"
		or type(pending.BeforeFacts.Balances) ~= "table" or type(pending.BeforeFacts.Powerups) ~= "table"
		or type(pending.BeforeFacts.Potions) ~= "table" or type(pending.BeforeFacts.Pets) ~= "table"
		or pending.Kind ~= "PLAYTIME" and pending.Kind ~= "MYSTERY_BOX"
		or pending.Kind == "PLAYTIME" and (not count(pending.Index) or pending.Index < 1 or not finite(pending.CycleStart))
		or pending.Kind == "MYSTERY_BOX" and (pending.Count ~= 1 or not count(pending.BeforeOwned)
			or type(pending.BeforeGiftIds) ~= "table" or type(pending.SessionKey) ~= "string"
			or type(pending.GiftIdentityEpoch) ~= "string" or pending.GiftIdentityEpoch == "" or not count(pending.BeforeGiftRevision))) then
		self.Blocker, self.UnknownBarrier = "Malformed pending reward ledger preserved; no action or automatic retry", true
		return self
	end
	self.Ledger = ledger
	local wheelValid, wheelReason = self:InitializeFreeWheelTicketLedger()
	if not wheelValid then
		self.Blocker, self.UnknownBarrier, self.Ledger = wheelReason, true, nil
		return self
	end
	local spinValid, spinReason = self:InitializeWheelSpin()
	if not spinValid then
		self.Blocker, self.UnknownBarrier, self.Ledger = spinReason, true, nil
		return self
	end
	if pending and pending.Kind == "MYSTERY_BOX" then pending.GiftIdentityCurrent = false end
	return self
end

function RewardsManager:_context()
	local mechanics = self.Controller.Farming and self.Controller.Farming.Mechanics
	if not mechanics or type(mechanics.RewardsContext) ~= "function" then return nil, "Native reward context adapter unavailable" end
	local ok, context, reason = pcall(mechanics.RewardsContext, mechanics)
	if not ok or type(context) ~= "table" then return nil, tostring(reason or context or "Reward context unavailable") end
	if context.UserId ~= self.UserId or type(context.Raw) ~= "table" then return nil, "Ready reward account identity unavailable or changed" end
	return context
end

function RewardsManager:_session(key)
	if not self.Ledger then return nil end
	local session = self.Ledger.Sessions[key]
	if not session then session = { Requested = 0, Consumed = 0, OutcomesObserved = 0 } self.Ledger.Sessions[key] = session end
	return session
end

function RewardsManager:_playtime(context)
	if not self.Config.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME then return nil end
	if context.CanClaim ~= true or context.HasPlaytime ~= true or context.IsTradingPlaza ~= false then return nil end
	if not finite(context.NativeNow) or type(context.PlaytimeGifts) ~= "table" then return nil end
	local playtime = context.Raw.PlaytimeRewards
	if type(playtime) ~= "table" or not finite(playtime.Start) or type(playtime.Claimed) ~= "table" then return nil end
	if context.NativeNow < playtime.Start then return nil end
	local eligible = {}
	for index, gift in pairs(context.PlaytimeGifts) do
		if count(index) and index >= 1 and type(gift) == "table" and finite(gift.Time) and gift.Time >= 0
			and playtime.Claimed[tostring(index)] == nil and context.NativeNow - playtime.Start >= gift.Time then
			table.insert(eligible, index)
		end
	end
	table.sort(eligible)
	if #eligible == 0 or os.clock() < (self.Ledger.NextClaimAt or 0) then return nil end
	return { Kind = "PLAYTIME", Index = eligible[1], CycleStart = playtime.Start, Reason = "Eligible sparse unclaimed playtime index" }
end

function RewardsManager:_box(context)
	local settings = self.Config.MYSTERY_BOX_SETTINGS
	if not settings.AUTO_OPEN_MYSTERY_BOXES or context.CanOpen ~= true or context.GiftCompletionAvailable ~= true then return nil end
	if context.GiftIdentityAvailable ~= true or type(context.GiftIdentityEpoch) ~= "string" or context.GiftIdentityEpoch == ""
		or not count(context.GiftRevision) then return nil end
	if context.IsTradingPlaza ~= false or not count(context.OwnedBoxes) or not count(context.GiftCount)
		or context.GiftCount ~= 0 or not count(context.MaxGiftCount) or context.MaxGiftCount < 1 or type(context.GiftIds) ~= "table" then return nil end
	if next(context.GiftIds) ~= nil then return nil end
	local session = self:_session(settings.SESSION_KEY)
	if not session or not count(session.Requested) or not count(settings.BOX_RESERVE) or not count(settings.MAXIMUM_SESSION_BOXES)
		or not count(settings.MAXIMUM_BATCH_BOXES) or settings.MAXIMUM_BATCH_BOXES < 1 then return nil end
	if not settings.ENABLE_AUTOMATIC_CONTINUATION and session.Requested > 0 then return nil end
	if os.clock() < (self.Ledger.NextBoxAt or 0) then return nil end
	-- Single boxes are the supported correlated operation. A higher maximum is
	-- a ceiling, not permission to assume multi-gift result correlation.
	local amount = math.min(1, context.OwnedBoxes - settings.BOX_RESERVE,
		settings.MAXIMUM_SESSION_BOXES - session.Requested, settings.MAXIMUM_BATCH_BOXES, context.MaxGiftCount)
	if amount < 1 then return nil end
	return { Kind = "MYSTERY_BOX", Count = amount, SessionKey = settings.SESSION_KEY, Reason = "Owned ordinary single box within protected allowance" }
end

function RewardsManager:Observe()
	if self.Destroyed or not self.Ledger then return end
	local pending = self.Ledger.Pending
	if not pending or not pending.Attempted then return end
	if pending.Kind == "WHEEL_SPIN" then self:ObserveWheelSpin(pending) return end
	if pending.Kind == "FREE_WHEEL_TICKET" then self:ObserveFreeWheelTicket(pending) return end
	local context, reason = self:_context()
	if context then
		pending.RewardDeltas = deltas(pending.BeforeFacts, facts(context))
		pending.RewardObserved = #pending.RewardDeltas > 0
		if pending.Kind == "PLAYTIME" then
			local current = context.Raw.PlaytimeRewards
			if type(current) == "table" and current.Start == pending.CycleStart and type(current.Claimed) == "table"
				and current.Claimed[tostring(pending.Index)] ~= nil then
				pending.Acknowledged = true
				self.Ledger.ClaimsAcknowledged += 1
				pending.Status = "CLAIM_STATE_ACKNOWLEDGED"
				self:_finish(pending)
				return
			elseif type(current) == "table" and current.Start ~= pending.CycleStart then
				pending.Reason = "Playtime cycle changed before matching claim acknowledgement; no automatic retry"
			end
		else
			pending.GiftIdentityCurrent = false
			if not pending.ConsumptionAcknowledged and count(context.OwnedBoxes) and pending.BeforeOwned - context.OwnedBoxes >= pending.Count then
				pending.ConsumptionAcknowledged = true
				self:_session(pending.SessionKey).Consumed += pending.Count
			end
			local records = type(context.GiftRecords) == "table" and context.GiftRecords or {}
			local active = type(context.GiftIds) == "table" and context.GiftIds or nil
			local matches = {}
			local identityCurrent = context.GiftIdentityAvailable == true and context.GiftIdentityEpoch == pending.GiftIdentityEpoch
				and count(context.GiftRevision) and context.GiftRevision >= pending.BeforeGiftRevision
			if not identityCurrent then
				pending.InputBlocker = "Gift identity observer unavailable or reader lifetime changed; retained request will not be hit or resent"
			end
			if active and identityCurrent then
				for id in pairs(active) do
					local record = records[id]
					if type(id) == "string" and not pending.BeforeGiftIds[id] and type(record) == "table" and record.Id == id
						and record.Name == "Mystery Box" and record.IdentityEpoch == pending.GiftIdentityEpoch
						and count(record.Revision) and record.Revision > pending.BeforeGiftRevision and record.Revision <= context.GiftRevision then
						table.insert(matches, id)
					end
				end
			end
			for _, id in ipairs(matches) do
				if pending.GiftId and id ~= pending.GiftId then pending.AmbiguousGift = true end
			end
			if #matches > pending.Count then pending.Reason = "Multiple new ordinary gifts; request identity ambiguous; input disabled" pending.AmbiguousGift = true end
			if not pending.GiftId and #matches == 1 and not pending.AmbiguousGift then pending.GiftId = matches[1] pending.GiftSeen = true end
			if pending.GiftId and not pending.AmbiguousGift and table.find(matches, pending.GiftId) then pending.GiftIdentityCurrent = true end
			-- GiftCount is the native TOTAL registry count, not the loaded subset.
			-- A previously correlated ID may be observed gone after reload, but a
			-- new reader epoch never authorizes another Hit or a guessed identity.
			if pending.GiftSeen and active and context.GiftCount == 0 and active[pending.GiftId] == nil then pending.GiftFinished = true end
			if pending.ConsumptionAcknowledged and pending.GiftFinished and pending.RewardObserved and not pending.AmbiguousGift then
				pending.Acknowledged, pending.Status = true, "CONSUMPTION_AND_REWARD_DELTA_OBSERVED"
				local session = self:_session(pending.SessionKey)
				session.OutcomesObserved += 1
				self:_finish(pending)
				return
			end
		end
	else pending.Reason = reason pending.GiftIdentityCurrent = false end
	if os.clock() >= pending.Deadline then
		pending.Status = "UNCONFIRMED"
		pending.Reason = pending.Reason or (pending.ConsumptionAcknowledged and "Box consumed; completion/reward remains unknown, manual native completion may be required"
			or "Reward acknowledgement timed out; delivery/rejection unresolved; no automatic retry")
	end
end

function RewardsManager:_finish(pending)
	pending.FinishedAt = os.clock()
	pending.Attribution = "Observed in a non-pickup request window; manual/external rewards cannot be excluded; invocation is not receipt"
	self.Ledger.LastResult = copy(pending)
	-- Claimed acknowledgement is sufficient to advance playtime; a missing
	-- observed reward still makes earnings attribution unresolved across reload.
	if not pending.RewardObserved then self.Ledger.UnresolvedAttribution = true end
	self.Ledger.Pending = nil
	if pending.Kind == "PLAYTIME" then
		self.Ledger.NextClaimAt = math.max(self.Ledger.NextClaimAt or 0, os.clock() + self.Config.PLAYTIME_SETTINGS.CLAIM_INTERVAL_SECONDS)
	else
		self.Ledger.NextBoxAt = math.max(self.Ledger.NextBoxAt or 0, os.clock() + self.Config.MYSTERY_BOX_SETTINGS.OPEN_INTERVAL_SECONDS)
	end
	self.NextCheckAt = 0
	if type(self.Controller.MarkNonPickupReward) == "function" then self.Controller:MarkNonPickupReward({ Kind = "REWARD_SETTLED" }) end
	self:_report() -- Received results remain visible even when acknowledged during Pause.
end

function RewardsManager:Select(plan)
	if self.Destroyed then return false end
	local spinOwns, spinDecision = self:SelectWheelSpin(plan)
	if spinOwns ~= nil then return spinOwns, spinDecision end
	local wheelOwns, wheelDecision = self:SelectFreeWheelTicket(plan)
	if wheelOwns ~= nil then return wheelOwns, wheelDecision end
	local enabled = self.Config.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME or self.Config.MYSTERY_BOX_SETTINGS.AUTO_OPEN_MYSTERY_BOXES
	if not self.Ledger then
		if enabled then self:_blocker(self.Blocker) end
		return false, { Kind = "WAIT", Reason = self.Blocker }
	end
	if not enabled and not self.Ledger.Pending then return false, { Kind = "WAIT", Reason = "Reward actions disabled" } end
	self:Observe()
	local pending = self.Ledger.Pending
	if pending then
		return true, { Kind = "OBSERVE_REWARD", Reason = pending.Reason or "Awaiting one retained reward operation", Pending = pending }
	end
	local context, reason = self:_context()
	if not context then self:_blocker(reason) return false, { Kind = "WAIT", Reason = reason } end
	local playtime
	if os.clock() >= self.NextCheckAt then
		playtime = self:_playtime(context)
		self.NextCheckAt = os.clock() + self.Config.PLAYTIME_SETTINGS.CHECK_INTERVAL_SECONDS
	end
	local decision = playtime or self:_box(context)
	if decision then self.Blocker = nil
	else
		local blocker = context.Reason
		if not blocker and self.Config.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME then
			if context.HasPlaytime ~= true then blocker = "Playtime capability unavailable or not unlocked"
			elseif context.CanClaim ~= true then blocker = "Native playtime interaction guards block claiming"
			elseif not finite(context.NativeNow) or type(context.Raw.PlaytimeRewards) ~= "table" then blocker = "Actual playtime clock/state unavailable" end
		end
		if not blocker and self.Config.MYSTERY_BOX_SETTINGS.AUTO_OPEN_MYSTERY_BOXES then
			if context.GiftCompletionAvailable ~= true then blocker = "Verified native gift completion capability unavailable; no box consumed"
			elseif context.GiftIdentityAvailable ~= true or type(context.GiftIdentityEpoch) ~= "string" or context.GiftIdentityEpoch == ""
				or not count(context.GiftRevision) then blocker = "Public native gift identity observer unavailable; no box consumed"
			elseif not count(context.OwnedBoxes) then blocker = "Owned ordinary box count unavailable"
			elseif context.GiftCount ~= 0 then blocker = "Other gifts are active or gift count is unknown"
			elseif context.OwnedBoxes <= self.Config.MYSTERY_BOX_SETTINGS.BOX_RESERVE then blocker = "No owned ordinary box above reserve" end
		end
		self:_blocker(blocker)
	end
	return decision ~= nil, decision or { Kind = "WAIT", Reason = self.Blocker or "No eligible enabled reward action" }
end

function RewardsManager:_blocker(reason)
	self.Blocker = reason
	if reason and reason ~= self.LastLoggedBlocker then
		self.LastLoggedBlocker = reason
		self.Controller:Log("REWARD][BLOCKER", reason)
	end
end

function RewardsManager:Prepare(decision, token)
	if self.Destroyed or not self.Ledger or self.Ledger.Pending or token:CheckCancelled() or self.Controller.State ~= "RUNNING" then return nil end
	local context, reason = self:_context()
	if not context then return nil, nil, nil, reason end
	local fresh = decision.Kind == "PLAYTIME" and self:_playtime(context) or decision.Kind == "MYSTERY_BOX" and self:_box(context)
	if not fresh or fresh.Kind ~= decision.Kind or fresh.Index ~= decision.Index or fresh.CycleStart ~= decision.CycleStart
		or fresh.SessionKey ~= decision.SessionKey or fresh.Count ~= decision.Count then return nil, nil, nil, "Fresh reward eligibility/budget changed" end
	if token:CheckCancelled() then return nil end
	local settings = fresh.Kind == "PLAYTIME" and self.Config.PLAYTIME_SETTINGS or self.Config.MYSTERY_BOX_SETTINGS
	local pending = { Kind = fresh.Kind, Index = fresh.Index, CycleStart = fresh.CycleStart, Count = fresh.Count,
		SessionKey = fresh.SessionKey, UserId = self.UserId, BeforeFacts = facts(context), BeforeOwned = context.OwnedBoxes,
		BeforeGiftIds = copy(context.GiftIds or {}), StartedAt = os.clock(), Deadline = os.clock() + settings.CONFIRMATION_TIMEOUT_SECONDS,
		GiftIdentityEpoch = context.GiftIdentityEpoch, BeforeGiftRevision = context.GiftRevision,
		Status = "PREPARED", Attempted = false, RewardDeltas = {} }
	self.Ledger.Pending = pending
	if pending.Kind == "PLAYTIME" then return "ClaimPlaytime", pending.Index, nil, pending end
	return "UseGift", "Mystery Box", pending.Count, pending
end

function RewardsManager:MarkDispatched(pending)
	if not self.Ledger or self.Ledger.Pending ~= pending or pending.Attempted then return false end
	if pending.Kind == "MYSTERY_BOX" then
		local context = self:_context()
		local fresh = context and self:_box(context)
		if not fresh or fresh.SessionKey ~= pending.SessionKey or fresh.Count ~= pending.Count
			or context.GiftIdentityEpoch ~= pending.GiftIdentityEpoch or context.GiftRevision ~= pending.BeforeGiftRevision then return false end
	end
	pending.Attempted, pending.Status = true, "AWAITING_ACKNOWLEDGEMENT"
	if pending.Kind == "PLAYTIME" then
		self.Ledger.ClaimsRequested += 1
		self.Ledger.NextClaimAt = os.clock() + self.Config.PLAYTIME_SETTINGS.CLAIM_INTERVAL_SECONDS
	else
		self:_session(pending.SessionKey).Requested += pending.Count
		self.Ledger.NextBoxAt = os.clock() + self.Config.MYSTERY_BOX_SETTINGS.OPEN_INTERVAL_SECONDS
	end
	return true
end

function RewardsManager:AbortPreparation(pending, reason)
	if not self.Ledger or self.Ledger.Pending ~= pending or pending.Attempted then return false end
	self.Ledger.Pending = nil
	self:_blocker(reason or "Undispatched reward preparation released")
	return true
end

function RewardsManager:DispatchReturned(pending, invocationOk, result)
	if not self.Ledger or self.Ledger.Pending ~= pending then return end
	pending.InvocationOk = invocationOk
	-- Store a description, not a native profile/module/result handle in shared.
	pending.InvocationResultType = type(result)
	if not invocationOk then pending.Reason = "Reward invocation raised after attempt; delivery is uncertain; no automatic retry" end
	self:Observe()
end

function RewardsManager:Definition(decision, generation)
	if decision.Kind == "WHEEL_SPIN" or decision.Kind == "OBSERVE_REWARD"
		and type(decision.Pending) == "table" and decision.Pending.Kind == "WHEEL_SPIN" then
		return self:WheelSpinDefinition(decision, generation)
	end
	if decision.Kind == "OBSERVE_REWARD" and decision.Pending and decision.Pending.Status == "UNCONFIRMED" then
		return nil -- Retain the barrier; existing received-state/five-second reader updates reconcile without a hot task cycle.
	end
	local timeout = decision.Kind == "PLAYTIME" and self.Config.PLAYTIME_SETTINGS.CONFIRMATION_TIMEOUT_SECONDS + 2 or 3
	return { Id = "OC_GAMEPLAY", Owner = "REWARDS", Generation = generation, Priority = 100,
		TimeoutSeconds = timeout,
		CanRun = function() return not self.Destroyed and self.Controller.State == "RUNNING" and self.Controller.Generation == generation end,
		Execute = function(token)
			if token:CheckCancelled() then return { Cancelled = true } end
			self:Observe()
			local mechanics = self.Controller.Farming.Mechanics
			local pending = self.Ledger and self.Ledger.Pending
			if not pending and decision.Kind ~= "OBSERVE_REWARD" then
				if type(mechanics.RewardAction) ~= "function" then return { Reason = "Native reward action adapter unavailable" } end
				mechanics:RewardAction(self, decision, token)
				pending = self.Ledger.Pending
			end
			local sliceEnd = os.clock() + 1
			while pending and pending.Attempted and pending.Kind == "MYSTERY_BOX" and pending.GiftId and not pending.AmbiguousGift
				and pending.GiftIdentityCurrent == true
				and pending.Status ~= "UNCONFIRMED" and self.Config.MYSTERY_BOX_SETTINGS.AUTO_OPEN_MYSTERY_BOXES
				and type(mechanics.AdvanceMysteryGift) == "function" and not token:CheckCancelled() and os.clock() < sliceEnd do
				local progressed, blocker = mechanics:AdvanceMysteryGift(pending, token)
				if not progressed and blocker then pending.InputBlocker = blocker break end
				self:Observe()
				if self.Ledger.Pending ~= pending or pending.GiftFinished then break end
				task.wait(0.1)
			end
			-- Controller replans after each slice. Keep unresolved observation paced
			-- inside that same foreground lease, including the no-gift and fault paths.
			if self.Ledger.Pending and not token:CheckCancelled() then task.wait(0.5) end
			self:Observe()
			return { Pending = self.Ledger.Pending ~= nil, LastResult = self.Ledger.LastResult, Reason = self.Ledger.Pending and self.Ledger.Pending.Reason }
		end,
		IsComplete = function(result) return type(result) == "table" end }
end

function RewardsManager:Completed(status, result, reason)
	self:Observe()
	self:_report()
end

function RewardsManager:_report()
	local last = self.Ledger and self.Ledger.LastResult
	if last and last.FinishedAt ~= self.LastLoggedResult then
		self.LastLoggedResult = last.FinishedAt
		local observed = {}
		for index, change in ipairs(last.RewardDeltas or {}) do
			if index > 10 then table.insert(observed, "additional deltas in GetStatus") break end
			table.insert(observed, string.format("%s:%s +%.2f", change.Kind, change.Name, change.Amount))
		end
		self.Controller:Log("REWARD][RESULT", string.format("%s | %s | claim acknowledgement=%s; box consumption=%s; reward delta observed=%s | %s | %s",
			last.Kind, last.Status, tostring(last.Kind == "PLAYTIME" and last.Acknowledged or false), tostring(last.ConsumptionAcknowledged or false),
			tostring(last.RewardObserved or false), #observed > 0 and table.concat(observed, "; ") or "No observed reward delta", last.Attribution))
	end
	local pending = self.Ledger and self.Ledger.Pending
	if pending and pending.Reason ~= self.LastLoggedReason then
		self.LastLoggedReason = pending.Reason
		if pending.Reason then self.Controller:Log("REWARD][UNCONFIRMED", pending.Reason) end
	end
end

function RewardsManager:AttributionBlocked()
	return self.UnknownBarrier == true or self.Ledger and (self.Ledger.Pending ~= nil or self.Ledger.UnresolvedAttribution == true) or false
end

function RewardsManager:Halt(stopped)
	-- Cancellation releases only a preparation that provably did not dispatch.
	-- Attempted requests, budgets and unknown outcomes survive every lifecycle.
	local pending = self.Ledger and self.Ledger.Pending
	if pending and not pending.Attempted then self.Ledger.Pending = nil end
	self:Observe()
end

function RewardsManager:Destroy()
	if self.Destroyed then return end
	self:Halt(true)
	self.Destroyed = true
end

function RewardsManager:GetStatus()
	local settings = self.Config.MYSTERY_BOX_SETTINGS
	local session = self.Ledger and self.Ledger.Sessions[settings.SESSION_KEY]
	local pending = self.Ledger and self.Ledger.Pending
	return { EnabledPlaytime = self.Config.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME, EnabledBoxes = settings.AUTO_OPEN_MYSTERY_BOXES,
		SessionKey = settings.SESSION_KEY, BoxesRequested = session and session.Requested or 0, BoxesConsumed = session and session.Consumed or 0,
		BoxOutcomesObserved = session and session.OutcomesObserved or 0, ClaimsRequested = self.Ledger and self.Ledger.ClaimsRequested or 0,
		ClaimsAcknowledged = self.Ledger and self.Ledger.ClaimsAcknowledged or 0, AttributionBlocked = self:AttributionBlocked(), Blocker = self.Blocker,
		Pending = pending and { Kind = pending.Kind, Index = pending.Index, Count = pending.Count, Status = pending.Status,
			Deadline = pending.Deadline, Reason = pending.Reason, GiftId = pending.GiftId, ConsumptionAcknowledged = pending.ConsumptionAcknowledged,
			RewardObserved = pending.RewardObserved, InputBlocker = pending.InputBlocker },
		LastResult = self.Ledger and copy(self.Ledger.LastResult) }
end

-- PHASE5_FREE_WHEEL_TICKET_BEGIN
-- One fixed free family. Shared Pending and the existing Brain/scheduler own all action authority.
local WHEEL_KIND, WHEEL_COMMAND = "FREE_WHEEL_TICKET", "ClaimFreeWheelSpin"
local function wheelId(value)
	return type(value) == "string" and #value >= 1 and #value <= 80 and value:match("^[%w_.%-]+$") ~= nil
end
local function wheelEqual(left, right, seen)
	if type(left) ~= type(right) then return false end
	if type(left) ~= "table" then return left == right end
	seen = seen or {}
	if seen[left] == right then return true end
	seen[left] = right
	for key, value in pairs(left) do if not wheelEqual(value, right[key], seen) then return false end end
	for key in pairs(right) do if left[key] == nil then return false end end
	return true
end
local function wheelData(value, seen, depth)
	local kind = type(value)
	if kind == "number" then return finite(value) end
	if kind == "string" or kind == "boolean" or kind == "nil" then return true end
	if kind ~= "table" or (depth or 0) > 20 then return false end
	seen = seen or {}
	if seen[value] then return false end
	seen[value] = true
	for key, entry in pairs(value) do
		if type(key) ~= "string" and not count(key) then return false end
		if not wheelData(entry, seen, (depth or 0) + 1) then return false end
	end
	seen[value] = nil
	return true
end
local function wheelInterfaces(value)
	if type(value) ~= "table" then return false end
	for _, key in ipairs({ "ItemUtil", "GetOwnedAmount", "Powerups", "SpinTicket", "Time", "TimeNow", "Remote", "FireServer" }) do
		if type(value[key]) ~= "string" or value[key] == "" then return false end
	end
	return wheelData(value)
end

function RewardsManager:ValidateFreeWheelTicketPending(ledger, pending)
	local extension = type(ledger) == "table" and ledger.FreeWheelTicket
	local record = type(extension) == "table" and type(extension.Tests) == "table" and extension.Tests[pending.TestId]
	local valid = pending.Kind == WHEEL_KIND and pending.Command == WHEEL_COMMAND and pending.UserId == self.UserId
		and wheelId(pending.TestId) and type(pending.Attempted) == "boolean" and finite(pending.Deadline)
		and finite(pending.BeforeDeadline) and pending.BeforeDeadline >= 0 and count(pending.BeforeTickets)
		and finite(pending.BeforeNativeNow) and pending.BeforeNativeNow >= pending.BeforeDeadline
		and count(pending.Generation) and count(pending.ManagerEpoch) and pending.ManagerEpoch > 0
		and count(pending.BeforeAttributionEpoch) and count(pending.ExpectedAttributionEpoch)
		and type(pending.Status) == "string" and type(pending.ReceiptState) == "string"
		and type(pending.BeforeInterference) == "table" and wheelData(pending.BeforeInterference)
		and type(pending.TicketDefinition) == "table" and wheelData(pending.TicketDefinition)
		and wheelInterfaces(pending.NativeInterfaceIds) and wheelData(pending)
		and type(extension) == "table" and extension.Version == 1 and count(extension.Epoch)
		and type(record) == "table" and record.UserId == self.UserId and record.TestId == pending.TestId
		and record.Attempts == (pending.Attempted and 1 or 0)
	if not valid then return false, "Malformed free-wheel pending operation preserved; no action or retry" end
	return true
end

function RewardsManager:InitializeFreeWheelTicketLedger()
	local settings = self.Config.FREE_WHEEL_TICKET_SETTINGS or {}
	local ledger = self.Ledger
	if not ledger then return false, "Account reward ledger unavailable" end
	local extension = ledger.FreeWheelTicket
	if extension == nil and settings.ENABLE_FREE_WHEEL_TICKET_CLAIM ~= true then return true end
	if extension == nil then extension = { Version = 1, Epoch = 0, Tests = {} } ledger.FreeWheelTicket = extension end
	if type(extension) ~= "table" or extension.Version ~= 1 or not count(extension.Epoch)
		or extension.Epoch >= 9007199254740990 or type(extension.Tests) ~= "table" then
		return false, "Unknown free-wheel ledger schema preserved; no action or retry"
	end
	for id, record in pairs(extension.Tests) do
		if not wheelId(id) or type(record) ~= "table" or record.TestId ~= id or record.UserId ~= self.UserId
			or record.Attempts ~= 0 and record.Attempts ~= 1 or type(record.Outcome) ~= "string" or not wheelData(record) then
			return false, "Malformed free-wheel test authorization preserved; no action or retry"
		end
		if record.Attempts == 1 and record.Outcome ~= "CLAIM_AND_GRANT_OBSERVED"
			and not (ledger.Pending and ledger.Pending.Kind == WHEEL_KIND and ledger.Pending.TestId == id and ledger.Pending.Attempted) then
			return false, "Consumed unresolved free-wheel authorization lacks its pending barrier; no action or retry"
		end
	end
	if not self.WheelManagerEpoch then
		extension.Epoch += 1
		self.WheelManagerEpoch = extension.Epoch
	end
	return true
end

function RewardsManager:_freeWheelAuthorization()
	local s = self.Config.FREE_WHEEL_TICKET_SETTINGS or {}
	if s.ENABLE_FREE_WHEEL_TICKET_CLAIM ~= true then return false, "Free wheel-ticket claim disabled" end
	if not count(s.AUTHORIZED_ACCOUNT_ID) or s.AUTHORIZED_ACCOUNT_ID == 0 or s.AUTHORIZED_ACCOUNT_ID ~= self.UserId then
		return false, "Explicit matching owner account authorization required"
	end
	if not wheelId(s.AUTHORIZED_TEST_ID) then return false, "Explicit free-wheel test identity required" end
	if s.OWNER_CONFIRMED_WHEEL_IDLE ~= true then return false, "Owner-confirmed idle wheel conditions required; queue state remains unproven" end
	if not finite(s.MAXIMUM_ACCOUNT_AGE_SECONDS) or s.MAXIMUM_ACCOUNT_AGE_SECONDS <= 0 or s.MAXIMUM_ACCOUNT_AGE_SECONDS > 10
		or not finite(s.CONFIRMATION_TIMEOUT_SECONDS) or s.CONFIRMATION_TIMEOUT_SECONDS <= 0 or s.CONFIRMATION_TIMEOUT_SECONDS > 60 then
		return false, "Invalid bounded free-wheel observation settings"
	end
	return true
end

function RewardsManager:_freeWheelContext()
	local c, s = self.Controller, self.Config.FREE_WHEEL_TICKET_SETTINGS or {}
	local reader, knowledge = c.Reader, c.Knowledge
	if not reader or not knowledge or type(knowledge.FreeWheelTicketContext) ~= "function" then return nil, "Fresh free-wheel knowledge unavailable" end
	local snapshot = reader:GetSnapshot()
	local ok, context = pcall(knowledge.FreeWheelTicketContext, knowledge, snapshot, os.clock(), s)
	if not ok or type(context) ~= "table" or context.Fresh ~= true then return nil, "Free-wheel observations unavailable, changed or stale" end
	local current = reader:GetSnapshot()
	if self.Destroyed or reader.Destroyed or not reader.Player or reader.Player.UserId ~= self.UserId
		or context.AccountId ~= self.UserId or type(current) ~= "table" or current.Ready ~= true
		or context.Revision ~= reader.Revision or context.Revision ~= current.Revision
		or not finite(context.ReadAt) or context.ReadAt > os.clock() or os.clock() - context.ReadAt > (s.MAXIMUM_ACCOUNT_AGE_SECONDS or 10)
		or not finite(context.NativeNow) or context.NativeNow < 0 or not finite(context.NextWheelSpin) or context.NextWheelSpin < 0
		or not count(context.TicketCount) or type(context.TicketDefinition) ~= "table" or not wheelData(context.TicketDefinition)
		or not wheelInterfaces(context.NativeInterfaceIds) or type(context.InterferenceFacts) ~= "table" or not wheelData(context.InterferenceFacts) then
		return nil, "Required coherent free-wheel account, inventory or native interfaces unavailable"
	end
	if context.AutoClaimSpin ~= false then return nil, "Native AutoClaimSpin enabled or unknown" end
	if context.GiftCount ~= 0 then return nil, "Native active gift conflict or unavailable required gift count" end
	if context.KnownWheelActivity == true then return nil, "Known conflicting wheel activity observed" end
	return context
end

function RewardsManager:_freeWheelOwns(token, generation)
	local c, player = self.Controller, self.Controller.Reader and self.Controller.Reader.Player
	local active = c.Scheduler and c.Scheduler.Active
	local root = type(shared) == "table" and shared.__OC_LOCAL_REWARD_LEDGER
	return not self.Destroyed and c.Rewards == self and c.State == "RUNNING" and c.Generation == generation
		and player and player.UserId == self.UserId and type(token) == "table" and type(token.CheckCancelled) == "function" and not token:CheckCancelled()
		and type(self.Ledger) == "table" and type(root) == "table" and root.Version == 1 and type(root.Accounts) == "table"
		and root.Accounts[tostring(self.UserId)] == self.Ledger and self.Ledger.UserId == self.UserId
		and active and active.Token == token and type(active.Definition) == "table"
		and active.Definition.Owner == "REWARDS" and active.Definition.Generation == generation
end

function RewardsManager:_freeWheelCharged()
	local extension = self.Ledger and self.Ledger.FreeWheelTicket
	if type(extension) ~= "table" or type(extension.Tests) ~= "table" then return true end
	for _, record in pairs(extension.Tests) do if type(record) ~= "table" or record.Attempts ~= 0 then return true end end
	return false
end

function RewardsManager:SelectFreeWheelTicket(plan)
	local s = self.Config.FREE_WHEEL_TICKET_SETTINGS or {}
	local pending = self.Ledger and self.Ledger.Pending
	if pending and pending.Kind ~= WHEEL_KIND then return nil end -- Exact legacy pending path keeps ownership.
	if s.ENABLE_FREE_WHEEL_TICKET_CLAIM ~= true and not pending then return nil end
	if not self.Ledger or self.UnknownBarrier then return false, { Kind = "WAIT", Reason = self.Blocker or "Reward ledger unavailable" } end
	if pending then self:ObserveFreeWheelTicket(pending) pending = self.Ledger.Pending end
	if pending then return true, { Kind = "OBSERVE_REWARD", Pending = pending, Reason = pending.Reason or "Awaiting retained free-wheel receipt" } end
	local authorized, reason = self:_freeWheelAuthorization()
	if not authorized then self.WheelBlocker = reason return false, { Kind = "WAIT", Reason = reason } end
	local valid, ledgerReason = self:InitializeFreeWheelTicketLedger()
	if not valid then self.WheelBlocker = ledgerReason return false, { Kind = "WAIT", Reason = ledgerReason } end
	if self.Ledger.UnresolvedAttribution == true then self.WheelBlocker = "Existing unresolved reward attribution blocks a free claim" return false, { Kind = "WAIT", Reason = self.WheelBlocker } end
	if self:_freeWheelCharged() then self.WheelBlocker = "One-attempt free-wheel authorization already consumed; another test ID cannot rearm this client runtime" return false, { Kind = "WAIT", Reason = self.WheelBlocker } end
	local context, blocker = self:_freeWheelContext()
	if not context then self.WheelBlocker = blocker return false, { Kind = "WAIT", Reason = blocker } end
	if context.NextWheelSpin > context.NativeNow then self.WheelBlocker = "Free-wheel deadline is not due" return false, { Kind = "WAIT", Reason = self.WheelBlocker } end
	self.WheelBlocker = nil
	return true, { Kind = WHEEL_KIND, Command = WHEEL_COMMAND, TestId = s.AUTHORIZED_TEST_ID,
		NextWheelSpin = context.NextWheelSpin, TicketCount = context.TicketCount, Context = context,
		Reason = "One authorized due free-wheel claim; receipt and external attribution remain separate" }
end

function RewardsManager:PrepareFreeWheelTicket(decision, token)
	local authorized, reason = self:_freeWheelAuthorization()
	local c = self.Controller
	if not authorized then return nil, reason end
	if not self.Ledger or self.UnknownBarrier or self.Ledger.Pending or self.Ledger.UnresolvedAttribution == true then return nil, "Existing reward operation or attribution barrier" end
	if not self:_freeWheelOwns(token, c.Generation) then return nil, "Free-wheel scheduler authorization unavailable" end
	if type(decision) ~= "table" or decision.Kind ~= WHEEL_KIND or decision.Command ~= WHEEL_COMMAND
		or decision.TestId ~= self.Config.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_TEST_ID or type(decision.Context) ~= "table" then return nil, "Exact free-wheel command and test authorization required" end
	local valid, ledgerReason = self:InitializeFreeWheelTicketLedger()
	if not valid then return nil, ledgerReason end
	local extension, context = self.Ledger.FreeWheelTicket, nil
	local record = extension.Tests[decision.TestId]
	if self:_freeWheelCharged() then return nil, "Free-wheel runtime attempt authorization already consumed" end
	context, reason = self:_freeWheelContext()
	if not context then return nil, reason end
	local chosen = decision.Context
	if context.NextWheelSpin ~= decision.NextWheelSpin or context.TicketCount ~= decision.TicketCount or context.NextWheelSpin > context.NativeNow
		or not wheelEqual(context.InterferenceFacts, chosen.InterferenceFacts) or not wheelEqual(context.TicketDefinition, chosen.TicketDefinition)
		or not wheelEqual(context.NativeInterfaceIds, chosen.NativeInterfaceIds) then return nil, "Free-wheel selection facts changed before preparation" end
	if not self:_freeWheelOwns(token, c.Generation) or self.Ledger.Pending then return nil, "Free-wheel preparation interrupted" end
	local epoch = c.RewardAttributionEpoch or 0
	if not count(epoch) or type(c.MarkNonPickupReward) ~= "function" then return nil, "Reward attribution observation unavailable" end
	if not record then record = { UserId = self.UserId, TestId = decision.TestId, Attempts = 0, Outcome = "PREPARED" } extension.Tests[decision.TestId] = record end
	local pending = { Kind = WHEEL_KIND, Command = WHEEL_COMMAND, UserId = self.UserId, TestId = decision.TestId,
		Attempted = false, Status = "PREPARED", ReceiptState = "PREPARED", Generation = c.Generation, ManagerEpoch = self.WheelManagerEpoch,
		Deadline = os.clock() + self.Config.FREE_WHEEL_TICKET_SETTINGS.CONFIRMATION_TIMEOUT_SECONDS,
		BeforeDeadline = context.NextWheelSpin, BeforeTickets = context.TicketCount, BeforeNativeNow = context.NativeNow,
		BeforeAttributionEpoch = epoch, ExpectedAttributionEpoch = epoch, BeforeInterference = copy(context.InterferenceFacts),
		TicketDefinition = copy(context.TicketDefinition), NativeInterfaceIds = copy(context.NativeInterfaceIds) }
	self.Ledger.Pending = pending
	return pending
end

function RewardsManager:MarkFreeWheelTicketDispatched(pending, token)
	if not self.Ledger or self.Ledger.Pending ~= pending or pending.Attempted or not self:_freeWheelOwns(token, pending.Generation) then return false, "Free-wheel dispatch reservation unavailable" end
	local authorized, reason = self:_freeWheelAuthorization()
	if not authorized or pending.TestId ~= self.Config.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_TEST_ID then return false, reason or "Free-wheel test identity changed" end
	local context, blocker = self:_freeWheelContext()
	if not context then return false, blocker end
	if context.NextWheelSpin ~= pending.BeforeDeadline or context.TicketCount ~= pending.BeforeTickets or context.NextWheelSpin > context.NativeNow
		or not wheelEqual(context.InterferenceFacts, pending.BeforeInterference) or not wheelEqual(context.TicketDefinition, pending.TicketDefinition)
		or not wheelEqual(context.NativeInterfaceIds, pending.NativeInterfaceIds) or (self.Controller.RewardAttributionEpoch or 0) ~= pending.BeforeAttributionEpoch then
		return false, "Free-wheel baseline or competing observations changed before dispatch"
	end
	if not self:_freeWheelOwns(token, pending.Generation) or self.Ledger.Pending ~= pending or pending.ManagerEpoch ~= self.WheelManagerEpoch then return false, "Free-wheel dispatch interrupted" end
	local record = self.Ledger.FreeWheelTicket.Tests[pending.TestId]
	if not record or record.Attempts ~= 0 or self:_freeWheelCharged() then return false, "Free-wheel one-attempt authorization already consumed" end
	-- No yield between charging the fixed allowance, marking attempted and the adapter's final dispatch checks.
	record.Attempts, record.Outcome = 1, "AWAITING_RECEIPT"
	pending.Attempted, pending.Status, pending.ReceiptState = true, "AWAITING_ACKNOWLEDGEMENT", "AWAITING_RECEIPT"
	pending.Deadline = os.clock() + self.Config.FREE_WHEEL_TICKET_SETTINGS.CONFIRMATION_TIMEOUT_SECONDS
	self.WheelAttemptToken = token
	self.Controller:MarkNonPickupReward(pending)
	pending.ExpectedAttributionEpoch = self.Controller.RewardAttributionEpoch or 0
	return true
end

function RewardsManager:UnresolveFreeWheelTicket(pending, state, reason)
	if not self.Ledger or self.Ledger.Pending ~= pending or not pending.Attempted then return end
	if not pending.UnresolvedState then pending.UnresolvedState, pending.Reason = state, reason end
	pending.Status, pending.ReceiptState = "UNCONFIRMED", pending.UnresolvedState
	local record = self.Ledger.FreeWheelTicket.Tests[pending.TestId]
	record.Outcome = pending.UnresolvedState
	self.WheelBlocker = pending.Reason
end

function RewardsManager:ValidateFreeWheelTicketDispatch(pending, token)
	local authorized, reason = self:_freeWheelAuthorization()
	if not authorized or self.Config.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_TEST_ID ~= pending.TestId
		or not self:_freeWheelOwns(token, pending.Generation) or not self.Ledger or self.Ledger.Pending ~= pending then
		return false, "CANCELLED_AFTER_DISPATCH", reason or "Charged free-wheel authorization or lease changed"
	end
	local context, blocker = self:_freeWheelContext()
	if not context then return false, "AMBIGUOUS", blocker end
	if context.NextWheelSpin ~= pending.BeforeDeadline or context.TicketCount ~= pending.BeforeTickets or context.NextWheelSpin > context.NativeNow
		or not wheelEqual(context.InterferenceFacts, pending.BeforeInterference) or not wheelEqual(context.TicketDefinition, pending.TicketDefinition)
		or not wheelEqual(context.NativeInterfaceIds, pending.NativeInterfaceIds)
		or (self.Controller.RewardAttributionEpoch or 0) ~= pending.ExpectedAttributionEpoch or os.clock() >= pending.Deadline then
		return false, "AMBIGUOUS", "Received baseline or attribution changed after charged authorization; no transport or retry"
	end
	local finalAuthorized = self:_freeWheelAuthorization()
	if not finalAuthorized or self.Config.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_TEST_ID ~= pending.TestId
		or not self:_freeWheelOwns(token, pending.Generation) or self.Ledger.Pending ~= pending then
		return false, "CANCELLED_AFTER_DISPATCH", "Charged free-wheel authorization changed during final observation"
	end
	self.WheelDispatchObservation = { Revision = context.Revision, ReadAt = context.ReadAt }
	return true
end

function RewardsManager:ObserveFreeWheelTicket(pending)
	if self.Destroyed or not self.Ledger or self.Ledger.Pending ~= pending or not pending.Attempted then return end
	local c = self.Controller
	local authorized = self:_freeWheelAuthorization()
	if not authorized or self.Config.FREE_WHEEL_TICKET_SETTINGS.AUTHORIZED_TEST_ID ~= pending.TestId
		or c.State ~= "RUNNING" or c.Generation ~= pending.Generation or self.WheelManagerEpoch ~= pending.ManagerEpoch
		or self.WheelAttemptToken and self.WheelAttemptToken:CheckCancelled() then
		self:UnresolveFreeWheelTicket(pending, "CANCELLED_AFTER_DISPATCH", "Free-wheel request interrupted or authorization revoked; no automatic retry")
	end
	local context, reason = self:_freeWheelContext()
	if not context then
		self:UnresolveFreeWheelTicket(pending, "AMBIGUOUS", reason or "Required free-wheel observations unavailable")
	else
		if not wheelEqual(context.InterferenceFacts, pending.BeforeInterference)
			or not wheelEqual(context.TicketDefinition, pending.TicketDefinition) or not wheelEqual(context.NativeInterfaceIds, pending.NativeInterfaceIds)
			or (c.RewardAttributionEpoch or 0) ~= pending.ExpectedAttributionEpoch
			or context.TicketCount < pending.BeforeTickets or context.TicketCount < (pending.LastTickets or pending.BeforeTickets)
			or context.NextWheelSpin < pending.BeforeDeadline or context.NextWheelSpin < (pending.LastDeadline or pending.BeforeDeadline)
			or context.NativeNow < (pending.LastNativeNow or pending.BeforeNativeNow) then
			self:UnresolveFreeWheelTicket(pending, "AMBIGUOUS", "Competing or contradictory received reward observations; attribution unresolved; no automatic retry")
		end
		pending.LastTickets, pending.LastDeadline, pending.LastNativeNow = context.TicketCount, context.NextWheelSpin, context.NativeNow
		pending.DeadlineObserved = context.NextWheelSpin > pending.BeforeDeadline and context.NextWheelSpin > context.NativeNow
		pending.InventoryObserved = context.TicketCount > pending.BeforeTickets
		pending.TicketsReceived = pending.InventoryObserved and context.TicketCount - pending.BeforeTickets or nil
		if pending.DeadlineObserved and pending.InventoryObserved then
			if not pending.UnresolvedState and os.clock() < pending.Deadline then
				local record = self.Ledger.FreeWheelTicket.Tests[pending.TestId]
				record.Outcome, record.TicketsReceived, record.FinishedAt = "CLAIM_AND_GRANT_OBSERVED", pending.TicketsReceived, os.clock()
				record.Attribution = "EXTERNAL_GAINS_CANNOT_BE_EXCLUDED"
				self.Ledger.FreeWheelTicket.LastTestId = pending.TestId
				self.Ledger.Pending, self.WheelAttemptToken, self.WheelBlocker = nil, nil, nil
				c:MarkNonPickupReward({ Kind = WHEEL_KIND })
				c:Log("REWARD][FREE_WHEEL", "CLAIM_AND_GRANT_OBSERVED | received tickets=" .. tostring(record.TicketsReceived) .. " | external gains cannot be excluded")
				return
			end
			pending.LateReceiptObserved = true
		end
		if not pending.UnresolvedState then pending.ReceiptState = pending.DeadlineObserved and "DEADLINE_ONLY" or pending.InventoryObserved and "INVENTORY_ONLY" or "AWAITING_RECEIPT" end
	end
	if os.clock() >= pending.Deadline then self:UnresolveFreeWheelTicket(pending, "UNCONFIRMED_TIMEOUT", "Free-wheel paired receipt timed out or arrived late; no automatic retry") end
end

function RewardsManager:GetFreeWheelTicketStatus()
	local s = self.Config.FREE_WHEEL_TICKET_SETTINGS or {}
	local extension = self.Ledger and self.Ledger.FreeWheelTicket
	local pending = self.Ledger and self.Ledger.Pending
	if pending and pending.Kind ~= WHEEL_KIND then pending = nil end
	local id = pending and pending.TestId or type(extension) == "table" and extension.LastTestId or s.AUTHORIZED_TEST_ID
	local record = type(extension) == "table" and extension.Tests[id]
	local attempted = false
	if type(extension) == "table" then for _, entry in pairs(extension.Tests) do if entry.Attempts == 1 then attempted = true end end end
	local authorized = self:_freeWheelAuthorization()
	return { Enabled = s.ENABLE_FREE_WHEEL_TICKET_CLAIM == true, Authorized = authorized == true,
		Attempted = attempted, Pending = pending ~= nil,
		ReceiptState = pending and (pending.LateReceiptObserved and pending.UnresolvedState == "CANCELLED_AFTER_DISPATCH" and "OBSERVED_AFTER_INTERRUPTION" or pending.ReceiptState)
			or record and record.Outcome or "DISABLED_OR_NOT_ATTEMPTED",
		BarrierState = pending and pending.UnresolvedState, DeadlineObserved = pending and pending.DeadlineObserved,
		InventoryObserved = pending and pending.InventoryObserved, TicketsReceived = not pending and record and record.TicketsReceived or nil,
		ObservedTicketIncrease = pending and pending.TicketsReceived,
		Attribution = "EXTERNAL_GAINS_CANNOT_BE_EXCLUDED", QueueState = "UNKNOWN", Persistence = "SAME_CLIENT_RUNTIME_ONLY",
		Blocker = pending and pending.Reason or self.WheelBlocker or self.Blocker }
end
-- PHASE5_FREE_WHEEL_TICKET_END
-- PHASE5_ONE_WHEEL_SPIN_BEGIN
local WheelSpinPolicy = require(script.Parent.WheelSpinPolicy)
local SPIN_KIND = "WHEEL_SPIN"

local function spinNormalize(context)
	return WheelSpinPolicy.Normalize({ Fresh = context.Fresh, UserId = context.UserId, Raw = context.Raw,
		Balances = context.Balances, Revision = context.ReceiptRevision, ReadAt = context.ReadAt })
end

function RewardsManager:ValidateWheelSpinPending(ledger, pending)
	if type(pending) ~= "table" or type(pending.BeforeFacts) ~= "table" or not count(pending.BeforeFacts.Tickets) then
		return false, "Malformed wheel spin pending baseline retained; no retry"
	end
	local extension = type(ledger) == "table" and ledger.WheelSpin
	local record = type(extension) == "table" and type(extension.Tests) == "table" and extension.Tests[pending.TestId]
	if pending.Kind ~= SPIN_KIND or pending.Version ~= 1 or pending.UserId ~= self.UserId or pending.Count ~= 1
		or not wheelId(pending.TestId) or not count(pending.Generation) or not count(pending.ManagerEpoch)
		or pending.ManagerEpoch < 1 or not finite(pending.StartedAt) or not finite(pending.Deadline) or pending.Deadline < pending.StartedAt
		or type(pending.Attempted) ~= "boolean" or type(pending.BeforeFacts) ~= "table" or pending.BeforeFacts.Status ~= "READY"
		or pending.BeforeFacts.UserId ~= self.UserId or pending.BeforeFacts.Tickets < 1 or not wheelData(pending)
		or type(extension) ~= "table" or extension.Version ~= 1 or not count(extension.Epoch)
		or type(record) ~= "table" or record.UserId ~= self.UserId or record.TestId ~= pending.TestId
		or record.Attempts ~= (pending.Attempted and 1 or 0) then return false, "Malformed wheel spin pending record preserved; no retry" end
	return true
end

function RewardsManager:InitializeWheelSpin()
	local ledger, settings = self.Ledger, self.Config.WHEEL_SPIN_SETTINGS or {}
	if not ledger then return false, "Account reward ledger unavailable" end
	local extension = ledger.WheelSpin
	if extension == nil and settings.AUTO_SPIN_WHEEL ~= true then return true end
	if extension == nil then extension = { Version = 1, Epoch = 0, Tests = {} } ledger.WheelSpin = extension end
	if type(extension) ~= "table" or extension.Version ~= 1 or not count(extension.Epoch)
		or extension.Epoch >= 9007199254740990 or type(extension.Tests) ~= "table" then return false, "Unknown wheel spin ledger schema retained" end
	for id, record in pairs(extension.Tests) do
		if not wheelId(id) or type(record) ~= "table" or record.TestId ~= id or record.UserId ~= self.UserId
			or record.Attempts ~= 0 and record.Attempts ~= 1 or type(record.Outcome) ~= "string" or not wheelData(record) then return false, "Malformed wheel spin allowance retained" end
		if record.Attempts == 1 and record.Outcome ~= "TICKET_DEBIT_AND_GRANT_OBSERVED"
			and not (ledger.Pending and ledger.Pending.Kind == SPIN_KIND and ledger.Pending.TestId == id and ledger.Pending.Attempted) then
			return false, "Unresolved consumed spin lacks its retained pending barrier"
		end
	end
	if not self.SpinManagerEpoch then extension.Epoch += 1 self.SpinManagerEpoch = extension.Epoch end
	return true
end

function RewardsManager:WheelSpinAuthorization()
	local s = self.Config.WHEEL_SPIN_SETTINGS or {}
	if s.AUTO_SPIN_WHEEL ~= true or s.OWNER_ONE_SPIN_ALLOWANCE ~= true then return false, "One wheel spin permission is OFF" end
	if not count(s.AUTHORIZED_ACCOUNT_ID) or s.AUTHORIZED_ACCOUNT_ID < 1 or s.AUTHORIZED_ACCOUNT_ID ~= self.UserId then return false, "Explicit matching owner account required" end
	if not wheelId(s.AUTHORIZED_TEST_ID) or s.OWNER_CONFIRMED_WHEEL_IDLE ~= true then return false, "Explicit one-spin test ID and owner-confirmed idle wheel required" end
	if not finite(s.CONFIRMATION_TIMEOUT_SECONDS) or s.CONFIRMATION_TIMEOUT_SECONDS < 8 or s.CONFIRMATION_TIMEOUT_SECONDS > 30
		or not finite(s.MAXIMUM_ACCOUNT_AGE_SECONDS) or s.MAXIMUM_ACCOUNT_AGE_SECONDS <= 0 or s.MAXIMUM_ACCOUNT_AGE_SECONDS > 10 then return false, "Invalid bounded wheel observation settings" end
	local off = { FREE_WHEEL_TICKET_SETTINGS = { "ENABLE_FREE_WHEEL_TICKET_CLAIM" },
		PET_SETTINGS = { "AUTO_HATCH", "AUTO_EQUIP", "EQUIP_OWNED_TEAM_ONCE", "AUTO_DELETE_PETS", "AUTO_CRAFT_SHINY", "AUTO_FUSE_PETS" },
		HATCH_SETTINGS = { "HATCH_ONE_EGG_ONCE", "ENABLE_BACKGROUND_PICKUPS" },
		OWNER_ONE_HATCH_TEST_SETTINGS = { "OWNER_ONE_HATCH_TEST_ALLOWANCE", "OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST" },
		EGG_TRAVEL_SETTINGS = { "ENABLE_SELECTED_EGG_TRAVEL", "ENABLE_DIRECT_POSITIONING", "ENABLE_NATIVE_ISLAND_TRAVEL", "OWNER_DIRECT_EGG_TELEPORT_TEST" },
		WORLD_SETTINGS = { "ENABLE_WORLD_PROGRESSION", "AUTO_DISCOVER_ISLANDS", "AUTO_UNLOCK_WORLDS", "AUTO_TRAVEL_FOR_PROGRESSION", "AUTO_FARM_UNLOCK_REQUIREMENTS" },
		ISLAND_SETTINGS = { "AUTO_TRAVEL_BEST_ISLAND", "AUTO_EXPLORE_UNLOCKED_ISLANDS" },
		FARMING_SETTINGS = { "AUTO_RESOURCE_FARM", "AUTO_FARM_FALLBACK" },
		PICKUP_SETTINGS = { "BULK_COLLECT_PICKUPS", "ENABLE_CONTINUOUS_SCANNING", "STATIONARY_ISOLATED_TEST" },
		BUBBLE_SETTINGS = { "AUTO_BLOW_BUBBLES", "AUTO_SELL_BUBBLES", "AUTO_BUY_GUM", "AUTO_BUY_FLAVORS", "ENABLE_SIMULTANEOUS_BLOWING" },
		UPGRADE_SETTINGS = { "ENABLE_SMART_UPGRADES", "ENABLE_CAPACITY_UPGRADES", "ENABLE_FLAVOR_UPGRADES", "AUTO_EQUIP_OWNED_UPGRADES" },
		PLAYTIME_SETTINGS = { "AUTO_CLAIM_PLAYTIME" }, MYSTERY_BOX_SETTINGS = { "AUTO_OPEN_MYSTERY_BOXES", "ENABLE_AUTOMATIC_CONTINUATION" },
		ANTIAFK_SETTINGS = { "ENABLE_ANTI_AFK" }, FALL_EVENT_SETTINGS = { "ENABLE_FALL_EVENT", "AUTO_REBIRTH", "AUTO_BUY_REBIRTH_UPGRADES", "AUTO_USE_FALL_ELIXIRS", "AUTO_BUY_AUTUMN_SHOP_ITEMS" } }
	for category, keys in pairs(off) do
		for _, key in ipairs(keys) do if type(self.Config[category]) ~= "table" or self.Config[category][key] ~= false then return false, "Isolated spin requires " .. category .. "." .. key .. " OFF" end end
	end
	for _, pair in ipairs({ { "HATCH_SETTINGS", "MAXIMUM_EGG_COST" }, { "HATCH_SETTINGS", "MAXIMUM_SESSION_COST" },
		{ "OWNER_ONE_HATCH_TEST_SETTINGS", "MAXIMUM_COIN_ALLOWANCE" }, { "OWNER_ONE_HATCH_TEST_SETTINGS", "MAXIMUM_EGG_COST" },
		{ "WORLD_SETTINGS", "MAXIMUM_WORLD_UNLOCK_COST" }, { "UPGRADE_SETTINGS", "MAXIMUM_PURCHASE_COST" } }) do
		if self.Config[pair[1]][pair[2]] ~= 0 then return false, "All unrelated spending budgets must be zero" end
	end
	return true
end

function RewardsManager:GetWheelSpinContext(allowNativeBusy)
	local c, s = self.Controller, self.Config.WHEEL_SPIN_SETTINGS or {}
	if not c.Reader or not c.Knowledge or type(c.Knowledge.WheelSpinContext) ~= "function" then return nil, "Wheel knowledge unavailable" end
	local ok, context = pcall(c.Knowledge.WheelSpinContext, c.Knowledge, c.Reader:GetSnapshot(), os.clock(), s, allowNativeBusy)
	if not ok then return nil, "Native wheel context raised: " .. tostring(context) end
	if type(context) ~= "table" or context.Fresh ~= true then return nil, type(context) == "table" and context.Blocker or "Native wheel context unavailable" end
	if context.UserId ~= self.UserId or context.AccountId ~= self.UserId then return nil, "Wheel received account identity mismatch" end
	if c.Pets and (c.Pets.PendingEquip or c.Pets.Hatch and c.Pets.Hatch.Pending) then return nil, "Pending pet operation conflicts with wheel" end
	local baseline = spinNormalize(context)
	if baseline.Status ~= "READY" then return nil, baseline.Reason end
	if baseline.Tickets > 0 and allowNativeBusy ~= true then
		for _, row in ipairs(context.Pool) do
			local expected = WheelSpinPolicy.Begin(baseline, row.Item)
			if expected.ReceiptState == "UNKNOWN" then return nil, expected.Reason end
		end
	end
	return context
end

function RewardsManager:SelectWheelSpin(plan)
	local s, pending = self.Config.WHEEL_SPIN_SETTINGS or {}, self.Ledger and self.Ledger.Pending
	if pending and pending.Kind ~= SPIN_KIND then return nil end
	if s.AUTO_SPIN_WHEEL ~= true and not pending then return nil end
	if not self.Ledger or self.UnknownBarrier then return false, { Kind = "WAIT", Reason = self.Blocker or "Wheel account ledger unavailable" } end
	if pending then
		self:ObserveWheelSpin(pending)
		if self.Ledger.Pending then return true, { Kind = "OBSERVE_REWARD", Pending = pending, Reason = pending.Reason } end
	end
	local authorized, reason = self:WheelSpinAuthorization()
	if not authorized then self.SpinBlocker = reason return false, { Kind = "WAIT", Reason = reason } end
	local valid, blocker = self:InitializeWheelSpin()
	if not valid then self.SpinBlocker = blocker return false, { Kind = "WAIT", Reason = blocker } end
	if self.Ledger.UnresolvedAttribution == true then return false, { Kind = "WAIT", Reason = "Unresolved prior reward attribution blocks spin" } end
	for _, record in pairs(self.Ledger.WheelSpin.Tests) do
		if record.Attempts ~= 0 then return false, { Kind = "WAIT", Reason = "One-spin allowance already consumed; no continuation or retry" } end
	end
	local context, contextReason = self:GetWheelSpinContext(false)
	if not context then self.SpinBlocker = contextReason return false, { Kind = "WAIT", Reason = contextReason } end
	local baseline = spinNormalize(context)
	if baseline.Status ~= "READY" or baseline.Tickets < 1 then return false, { Kind = "WAIT", Reason = baseline.Reason or "No received owned Spin Ticket; no purchase fallback" } end
	for _, row in ipairs(context.Pool) do
		local receipt = WheelSpinPolicy.Begin(baseline, row.Item)
		if receipt.ReceiptState == "UNKNOWN" then return false, { Kind = "WAIT", Reason = receipt.Reason } end
	end
	return true, { Kind = SPIN_KIND, TestId = s.AUTHORIZED_TEST_ID, Count = 1,
		Reason = "One owned-ticket spin using native animation; no purchases or unrelated actions" }
end

function RewardsManager:PrepareWheelSpin(decision, token)
	if self.Destroyed or not self.Ledger or self.Ledger.Pending or not self:_freeWheelOwns(token, self.Controller.Generation) then return nil, "Wheel lease or retained reward barrier blocks preparation" end
	local owns, fresh = self:SelectWheelSpin()
	if owns ~= true or not fresh or fresh.Kind ~= SPIN_KIND or fresh.TestId ~= decision.TestId or decision.Count ~= 1 then return nil, fresh and fresh.Reason or "Fresh spin eligibility changed" end
	local context, reason = self:GetWheelSpinContext(false)
	if not context then return nil, reason end
	local baseline = spinNormalize(context)
	if baseline.Status ~= "READY" or baseline.Tickets < 1 then return nil, baseline.Reason or "Spin ticket baseline unavailable" end
	local pending = { Kind = SPIN_KIND, Version = 1, UserId = self.UserId, Count = 1, TestId = decision.TestId,
		Generation = self.Controller.Generation, ManagerEpoch = self.SpinManagerEpoch, BeforeFacts = baseline,
		Pool = copy(context.Pool), StartedAt = os.clock(), Deadline = os.clock() + self.Config.WHEEL_SPIN_SETTINGS.CONFIRMATION_TIMEOUT_SECONDS,
		Attempted = false, Status = "PREPARED", ReceiptState = "PENDING", TransportCount = 0, SettlementCount = 0 }
	self.Ledger.WheelSpin.Tests[pending.TestId] = { UserId = self.UserId, TestId = pending.TestId, Attempts = 0, Outcome = "PREPARED" }
	self.Ledger.Pending, self.SpinPreparationContext = pending, context
	return pending
end

function RewardsManager:MarkWheelSpinDispatched(pending, token)
	local authorized, reason = self:WheelSpinAuthorization()
	if not authorized or not self:_freeWheelOwns(token, pending.Generation) or self.Ledger.Pending ~= pending or pending.Attempted
		or pending.ManagerEpoch ~= self.SpinManagerEpoch then return false, reason or "Spin lease changed before charged attempt" end
	local record = self.Ledger.WheelSpin.Tests[pending.TestId]
	if not record or record.Attempts ~= 0 then return false, "Spin allowance already charged" end
	for id, other in pairs(self.Ledger.WheelSpin.Tests) do if id ~= pending.TestId and other.Attempts ~= 0 then return false, "Another spin allowance already charged" end end
	pending.Attempted, pending.Status, record.Attempts, record.Outcome = true, "PENDING", 1, "PENDING"
	self.Controller:MarkNonPickupReward(pending)
	pending.AttributionEpoch = self.Controller.RewardAttributionEpoch
	return true
end

function RewardsManager:WheelSpinDispatchValid(pending, token, stage)
	local authorized, reason = self:WheelSpinAuthorization()
	if not authorized or not self:_freeWheelOwns(token, pending.Generation) or self.Ledger.Pending ~= pending
		or pending.ManagerEpoch ~= self.SpinManagerEpoch or not pending.Attempted or pending.Cancelled
		or self.Config.WHEEL_SPIN_SETTINGS.AUTHORIZED_TEST_ID ~= pending.TestId or os.clock() >= pending.Deadline
		or self.Controller.RewardAttributionEpoch ~= pending.AttributionEpoch then return false, reason or "Spin authorization, account, lease or attribution changed" end
	local runtime = self.SpinNativeBridge
	local context, blocker = self:GetWheelSpinContext(pending.ButtonActivationStarted == true)
	if not context then return false, blocker end
	if not wheelEqual(context.Pool, pending.Pool) then return false, "Native wheel pool changed after preparation" end
	if runtime then
		if runtime.Remote ~= context.NativeRefs.Remote or runtime.SpinButton ~= context.GUI.SpinButton then return false, "Exact native wheel/transport instance changed" end
	end
	if stage == "SETTLE" then
		if not pending.InvokeReturned or not pending.ReturnedIndex or not finite(pending.NativeAnimationStartedAt)
			or os.clock() - pending.NativeAnimationStartedAt < context.WheelAnimationSeconds then return false, "Native animation finish is early or unverified; no guessed queue settlement" end
		self:ObserveWheelSpin(pending)
		if pending.Cancelled or not pending.Receipt or pending.Receipt.TicketDebitObserved ~= true then return false, "Distinct ticket debit not observed before native settlement" end
	elseif stage == "START" then
		if context.TicketCount ~= pending.BeforeFacts.Tickets or context.TicketCount < 1 then return false, "Ticket stock changed before one spin; no purchase fallback" end
	else return false, "Unsupported wheel lifecycle stage" end
	return true, nil, context
end

function RewardsManager:AcceptWheelSpinReturn(pending, index, context)
	if not self.Ledger or self.Ledger.Pending ~= pending or pending.Cancelled or not count(index) or index < 1
		or type(pending.Pool[index]) ~= "table" or type(context) ~= "table" or not wheelEqual(context.Pool, pending.Pool) then
		return false, "Native wheel returned no valid current pool index; reward and queue remain unknown"
	end
	local receipt = WheelSpinPolicy.Begin(pending.BeforeFacts, pending.Pool[index].Item)
	if receipt.ReceiptState == "UNKNOWN" then return false, receipt.Reason end
	pending.ReturnedIndex, pending.ExpectedItem, pending.Receipt = index, copy(pending.Pool[index].Item), receipt
	return true
end

function RewardsManager:UnresolveWheelSpin(pending, state, reason)
	if not self.Ledger or self.Ledger.Pending ~= pending then return end
	pending.Status, pending.ReceiptState, pending.Reason = "PENDING", state or "PENDING", reason or "Spin receipt unresolved; no retry"
	-- Cancellation, transport uncertainty and contradictory evidence are sticky.
	pending.Cancelled = true
	local record = self.Ledger.WheelSpin.Tests[pending.TestId]
	if record then record.Outcome = "PENDING" end
	self:ReportWheelSpin(pending)
end

function RewardsManager:ObserveWheelSpin(pending)
	if self.Destroyed or not self.Ledger or self.Ledger.Pending ~= pending or not pending.Attempted then return end
	if pending.Cancelled then self:ReportWheelSpin(pending) return end
	if self.Controller.State ~= "RUNNING" or self.Controller.Generation ~= pending.Generation or self.SpinManagerEpoch ~= pending.ManagerEpoch
		or self:WheelSpinAuthorization() ~= true then self:UnresolveWheelSpin(pending, "CANCELLED", "Spin interrupted or permission revoked; pending retained without retry") return end
	if not pending.Receipt then return end
	local context, reason = self:GetWheelSpinContext(true)
	if context then
		pending.Receipt = WheelSpinPolicy.Observe(pending.Receipt, spinNormalize(context), { SettlementCompleted = pending.NativeSettlementCompleted == true })
		pending.ReceiptState, pending.Reason = pending.Receipt.ReceiptState, pending.Receipt.Reason
		if pending.ReceiptState == "AMBIGUOUS" then self:UnresolveWheelSpin(pending, "AMBIGUOUS", pending.Reason) return end
		if pending.ReceiptState == "TICKET_DEBIT_AND_GRANT_OBSERVED" then
			pending.Status, pending.FinishedAt = "SPIN_CONFIRMED", os.clock()
			pending.Attribution = "Actual matching received gain observed; external same-item grants cannot be excluded; invocation/presentation alone is not receipt"
			self.Ledger.WheelSpin.Tests[pending.TestId].Outcome = pending.ReceiptState
			self.Ledger.LastResult, self.Ledger.WheelSpin.LastResult = copy(pending), copy(pending)
			self.Ledger.Pending = nil
			self:ReportWheelSpin(pending)
			return
		end
	else pending.Reason = reason or "Current wheel receipt observations unavailable" end
	if os.clock() >= pending.Deadline then self:UnresolveWheelSpin(pending, "PENDING_TIMEOUT", pending.Reason or "One-spin receipt timed out; no retry") end
	self:ReportWheelSpin(pending)
end

function RewardsManager:ReportWheelSpin(pending)
	local item, receipt = pending.ExpectedItem or {}, pending.Receipt or {}
	local text = string.format("%s | attempts=%d; native spin requests=%d; native queue calls=%d; ticket debit=%s; reward=%s; observed amount=%s | %s | no retry",
		pending.Status or "PENDING", pending.Attempted and 1 or 0, pending.TransportCount or 0, pending.SettlementCount or 0,
		tostring(receipt.TicketDebitObserved == true), tostring(item.Name or item.Currency or "UNKNOWN"), tostring(receipt.ObservedGrantAmount or "UNKNOWN"), tostring(pending.Reason or "Awaiting native lifecycle and receipt"))
	if text ~= self.LastSpinReport then self.LastSpinReport = text self.Controller:Log("WHEEL_SPIN", text) end
end

function RewardsManager:WheelSpinDefinition(decision, generation)
	if decision.Kind == "OBSERVE_REWARD" then return nil end -- Retained pending never rearms input or a hot retry task.
	return { Id = "OC_GAMEPLAY", Owner = "REWARDS", Generation = generation, Priority = 100,
		TimeoutSeconds = (self.Config.WHEEL_SPIN_SETTINGS.CONFIRMATION_TIMEOUT_SECONDS or 20) + 2,
		CanRun = function() return not self.Destroyed and self.Controller.State == "RUNNING" and self.Controller.Generation == generation end,
		Execute = function(token)
			local mechanics = self.Controller.Farming and self.Controller.Farming.Mechanics
			if token:CheckCancelled() or not mechanics or type(mechanics.RewardAction) ~= "function" then return { Reason = "Cancelled or wheel mechanics unavailable" } end
			local ok, reason = mechanics:RewardAction(self, decision, token)
			local pending = self.Ledger and self.Ledger.Pending
			while pending and pending.Attempted and not token:CheckCancelled() and os.clock() < pending.Deadline do
				self:ObserveWheelSpin(pending)
				local quiet = type(mechanics.ReleaseWheelSpinBridge) == "function" and mechanics:ReleaseWheelSpinBridge(self, pending, token)
				if (pending.Cancelled or pending.Status == "SPIN_CONFIRMED") and quiet then break end
				task.wait(0.1)
			end
			if pending and pending.Attempted and self.Ledger.Pending == pending and not pending.Cancelled then
				self:UnresolveWheelSpin(pending, token:CheckCancelled() and "CANCELLED" or "PENDING_TIMEOUT", token:CheckCancelled() and "Wheel task cancelled; uncertain operation retained" or pending.Reason)
			end
			if pending and type(mechanics.ReleaseWheelSpinBridge) == "function" then mechanics:ReleaseWheelSpinBridge(self, pending, token) end
			-- This isolated allowance ends the existing controller after its one
			-- bounded attempt. A retained pending record never becomes a retry.
			if self.Controller.State == "RUNNING" and self.Controller.Generation == generation
				and type(self.Controller.Stop) == "function" then self.Controller:Stop() end
			return { Pending = self.Ledger and self.Ledger.Pending ~= nil, Reason = reason, Started = ok == true }
		end,
		IsComplete = function(result) return type(result) == "table" end }
end

function RewardsManager:GetWheelSpinStatus()
	local ledger = self.Ledger
	local pending = ledger and ledger.Pending
	local extension = ledger and ledger.WheelSpin
	local charged = 0
	for _, record in pairs(extension and extension.Tests or {}) do charged += record.Attempts or 0 end
	return { Enabled = (self.Config.WHEEL_SPIN_SETTINGS or {}).AUTO_SPIN_WHEEL == true, ChargedAttempts = charged,
		Pending = pending and pending.Kind == SPIN_KIND and copy(pending) or nil,
		LastResult = extension and copy(extension.LastResult), Blocker = self.SpinBlocker or self.Blocker,
		LedgerScope = "Same-client VM only; rejoin can lose history and never creates a new human authorization" }
end
-- PHASE5_ONE_WHEEL_SPIN_END
return RewardsManager

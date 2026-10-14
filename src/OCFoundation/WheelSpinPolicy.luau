--!nonstrict
-- Pure received-state accounting. No readers, native calls, scheduler or actions.
-- A native result index identifies an expected item, never an inventory grant.
local WheelSpinPolicy = {}
local TICKET = "Spin Ticket"
local function finite(value)
	return type(value) == "number" and value == value and value >= 0 and value < math.huge
end
local function integer(value) return finite(value) and value % 1 == 0 end
local function name(value) return type(value) == "string" and value ~= "" end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copy(entry) end return result
end
local function data(value, depth, seen)
	if type(value) == "number" then return finite(value) end
	if type(value) == "nil" or type(value) == "boolean" or type(value) == "string" then return true end
	if type(value) ~= "table" or (depth or 0) > 10 then return false end
	seen = seen or {} if seen[value] then return false end seen[value] = true
	for key, entry in pairs(value) do
		if not (type(key) == "string" or integer(key)) or not data(entry, (depth or 0) + 1, seen) then return false end
	end
	seen[value] = nil return true
end
local function equal(left, right)
	if type(left) ~= type(right) then return false end
	if type(left) ~= "table" then return left == right end
	for key, entry in pairs(left) do if not equal(entry, right[key]) then return false end end
	for key in pairs(right) do if left[key] == nil then return false end end return true
end
local function dense(value)
	if type(value) ~= "table" then return false end
	local count = 0
	for key in pairs(value) do if not integer(key) or key < 1 then return false end count += 1 end
	if count ~= #value then return false end
	for index = 1, count do if value[index] == nil then return false end end
	return true
end
local function potionKey(item)
	return tostring(#item.Name) .. ":" .. item.Name .. ":" .. (item.Level == nil and "NO_LEVEL" or "LEVEL_" .. tostring(item.Level))
end
local function variant(item)
	local result = {}
	for _, flag in ipairs({ "Shiny", "Mythic", "XL" }) do
		if item[flag] ~= nil and type(item[flag]) ~= "boolean" then return nil end
		result[flag] = item[flag] == true
	end
	if not data(item.Super) then return nil end
	if item.Super == nil then result.Super = false else result.Super = copy(item.Super) end
	return result
end

function WheelSpinPolicy.Normalize(context)
	local result = { Status = "UNKNOWN", Attribution = "EXTERNAL_GAINS_CANNOT_BE_EXCLUDED" }
	local function block(reason) result.Reason = reason return result end
	if type(context) ~= "table" or context.Fresh ~= true then return block("Fresh coherent received account observations required") end
	if not integer(context.UserId) or context.UserId < 1 or not integer(context.Revision) or not finite(context.ReadAt) then
		return block("Exact account identity, received revision and read timestamp required")
	end
	local raw, balances = context.Raw, context.Balances
	if type(raw) ~= "table" or type(balances) ~= "table" then return block("Received account or currency observations unavailable") end
	local facts = { Balances = {}, Powerups = {}, Potions = {}, Pets = {} }
	for currency, amount in pairs(balances) do
		if not name(currency) or not finite(amount) or raw[currency] ~= amount then
			return block("Received currency observations are malformed or inconsistent")
		end
		facts.Balances[currency] = amount
	end
	if type(raw.Powerups) ~= "table" then return block("Complete received Powerups map unavailable") end
	for itemName, amount in pairs(raw.Powerups) do
		if not name(itemName) or not integer(amount) then return block("Received Powerups name or count malformed") end
		facts.Powerups[itemName] = amount
	end
	if not dense(raw.Potions) then return block("Received Potions must be a complete dense native record array") end
	for _, item in ipairs(raw.Potions) do
		if type(item) ~= "table" or not name(item.Name) or not integer(item.Amount)
			or item.Level ~= nil and (not integer(item.Level) or item.Level < 1) then return block("Received Potion record malformed") end
		local key = potionKey(item)
		if facts.Potions[key] ~= nil then return block("Duplicate received Potion Name/Level records are ambiguous") end
		facts.Potions[key] = { Name = item.Name, Level = item.Level, Amount = item.Amount }
	end
	if not dense(raw.Pets) then return block("Received Pets must be a complete dense native record array") end
	for _, item in ipairs(raw.Pets) do
		if type(item) ~= "table" or not name(item.Id) or not name(item.Name) then return block("Received Pet identity malformed") end
		local amount = item.Amount == nil and 1 or item.Amount
		local variants = variant(item)
		if not integer(amount) or amount < 1 or not variants then return block("Received Pet amount or variants malformed") end
		if facts.Pets[item.Id] ~= nil then return block("Duplicate received Pet Instance IDs are ambiguous") end
		facts.Pets[item.Id] = { Id = item.Id, Name = item.Name, Amount = amount, Variants = variants }
	end
	result.Status, result.UserId, result.Revision, result.ReadAt = "READY", context.UserId, context.Revision, context.ReadAt
	result.Facts, result.Tickets = facts, facts.Powerups[TICKET] or 0
	return result
end

local function expectedItem(item)
	if type(item) ~= "table" or not data(item) then return nil end
	local result = copy(item)
	if item.Type == "Currency" then
		if not name(item.Currency) or not finite(item.Amount) or item.Amount <= 0 then return nil end
	elseif item.Type == "Powerup" then
		if not name(item.Name) or not integer(item.Amount) or item.Amount < 1 then return nil end
	elseif item.Type == "Potion" then
		if not name(item.Name) or not integer(item.Amount) or item.Amount < 1
			or item.Level ~= nil and (not integer(item.Level) or item.Level < 1) then return nil end
	elseif item.Type == "Pet" then
		if not name(item.Name) or item.Amount ~= nil and (not integer(item.Amount) or item.Amount < 1) then return nil end
		result.Variants = variant(item) if not result.Variants then return nil end
		result.Amount = item.Amount == nil and 1 or item.Amount
	else return nil end
	return result
end

local function ready(value)
	return type(value) == "table" and value.Status == "READY" and integer(value.UserId) and value.UserId >= 1
		and integer(value.Revision) and finite(value.ReadAt) and integer(value.Tickets)
		and type(value.Facts) == "table" and data(value.Facts)
		and type(value.Facts.Balances) == "table" and type(value.Facts.Powerups) == "table"
		and type(value.Facts.Potions) == "table" and type(value.Facts.Pets) == "table"
		and value.Tickets == (value.Facts.Powerups[TICKET] or 0)
end

function WheelSpinPolicy.Begin(baseline, item)
	local state = { ReceiptState = "PENDING", TicketDebitObserved = false, GrantObserved = false,
		SettlementCompleted = false, Attribution = "EXTERNAL_GAINS_CANNOT_BE_EXCLUDED" }
	if not ready(baseline) then
		state.ReceiptState, state.Reason = "UNKNOWN", "Verified complete received baseline unavailable" return state
	end
	local expected = expectedItem(item)
	if not expected then state.ReceiptState, state.Reason = "UNKNOWN", "Current native expected item descriptor unsupported or unavailable" return state end
	if baseline.Tickets < 1 then state.ReceiptState, state.Reason = "UNKNOWN", "No received owned Spin Ticket; no purchase fallback" return state end
	if expected.Type == "Currency" and baseline.Facts.Balances[expected.Currency] == nil then
		state.ReceiptState, state.Reason = "UNKNOWN", "Expected currency has no explicit received baseline" return state
	end
	state.Baseline, state.Last, state.ExpectedItem = copy(baseline), copy(baseline), expected
	state.Reason = "Awaiting actual one-ticket debit, native settlement and received grant"
	return state
end

-- Returns the total positive matching reward delta and any contradictory change.
local function rewardDelta(before, after, item, permitDebit)
	local gain, failure = 0, nil
	local function delta(kind, key, old, value, matching)
		local change = value - old
		if change == 0 then return end
		if kind == "Powerup" and key == TICKET and permitDebit and change == -1 then return end
		if matching and change > 0 then gain += change
		else failure = "Unrelated or negative received " .. kind .. " change" end
	end
	local currencies = {} for key in pairs(before.Balances) do currencies[key] = true end for key in pairs(after.Balances) do currencies[key] = true end
	for key in pairs(currencies) do
		if before.Balances[key] == nil or after.Balances[key] == nil then return nil, "Currency observation availability changed" end
		delta("Currency", key, before.Balances[key], after.Balances[key], item.Type == "Currency" and item.Currency == key)
	end
	local powerups = {} for key in pairs(before.Powerups) do powerups[key] = true end for key in pairs(after.Powerups) do powerups[key] = true end
	for key in pairs(powerups) do
		delta("Powerup", key, before.Powerups[key] or 0, after.Powerups[key] or 0, item.Type == "Powerup" and item.Name == key)
	end
	local potions = {} for key in pairs(before.Potions) do potions[key] = true end for key in pairs(after.Potions) do potions[key] = true end
	for key in pairs(potions) do
		local old, value = before.Potions[key], after.Potions[key]
		delta("Potion", key, old and old.Amount or 0, value and value.Amount or 0, item.Type == "Potion" and potionKey(item) == key)
	end
	local pets = {} for key in pairs(before.Pets) do pets[key] = true end for key in pairs(after.Pets) do pets[key] = true end
	for key in pairs(pets) do
		local old, value = before.Pets[key], after.Pets[key]
		if old and value and (old.Name ~= value.Name or not equal(old.Variants, value.Variants)) then
			return nil, "Existing exact Pet ID changed name or variant identity"
		end
		local matching = value and item.Type == "Pet" and value.Name == item.Name and equal(value.Variants, item.Variants)
		delta("Pet", key, old and old.Amount or 0, value and value.Amount or 0, matching)
	end
	return failure and nil or gain, failure
end

function WheelSpinPolicy.Observe(previous, current, lifecycle)
	local state = copy(previous)
	if type(state) ~= "table" or not state.Baseline or not state.ExpectedItem then
		return { ReceiptState = "UNKNOWN", Reason = "A valid receipt baseline and expected native item are required" }
	end
	if state.ReceiptState == "AMBIGUOUS" then return state end -- Contradictions never disappear or authorize retry.
	if not ready(current) then
		state.ReceiptState, state.Reason = "PENDING", "Current received observations unavailable; no grant confirmation or retry" return state
	end
	local function ambiguous(reason) state.ReceiptState, state.Reason = "AMBIGUOUS", reason return state end
	if current.UserId ~= state.Baseline.UserId or current.Revision < state.Last.Revision or current.ReadAt < state.Last.ReadAt then
		return ambiguous("Account identity or received observation order changed")
	end
	if current.Revision == state.Last.Revision and not equal(current.Facts, state.Last.Facts) then
		return ambiguous("Received facts changed without a new coherent account revision")
	end
	state.SettlementCompleted = state.SettlementCompleted or type(lifecycle) == "table" and lifecycle.SettlementCompleted == true or false
	local ticketReward = state.ExpectedItem.Type == "Powerup" and state.ExpectedItem.Name == TICKET
	local reference, gain, reason
	if ticketReward then
		if not state.TicketDebitObserved then
			-- A coalesced +4 net change cannot prove the distinct debit and +5 grant.
			local _, unrelated = rewardDelta(state.Baseline.Facts, current.Facts, state.ExpectedItem, true)
			if unrelated then return ambiguous(unrelated) end
			if current.Tickets == state.Baseline.Tickets - 1 then
				state.TicketDebitObserved, state.DebitSnapshot = true, copy(current)
			elseif current.Tickets < state.Baseline.Tickets - 1 then return ambiguous("More than one Spin Ticket debit observed") end
			state.Last, state.ReceiptState = copy(current), "PENDING"
			state.Reason = state.TicketDebitObserved and "Distinct ticket debit observed; awaiting returned-ticket grant" or "Distinct ticket debit not observed; net ticket change cannot prove grant"
			return state
		end
		reference = state.DebitSnapshot
		gain, reason = rewardDelta(reference.Facts, current.Facts, state.ExpectedItem, false)
	else
		gain, reason = rewardDelta(state.Baseline.Facts, current.Facts, state.ExpectedItem, true)
		if state.TicketDebitObserved and current.Tickets ~= state.Baseline.Tickets - 1 then return ambiguous("Previously observed ticket debit changed or was refunded") end
		if current.Tickets == state.Baseline.Tickets - 1 then state.TicketDebitObserved = true
		elseif current.Tickets ~= state.Baseline.Tickets then return ambiguous("Unexpected Spin Ticket change") end
	end
	if reason then return ambiguous(reason) end
	if state.MatchingIncreaseObserved and gain < (state.ObservedGrantAmount or 0) then return ambiguous("Previously observed matching grant decreased") end
	if state.ExpectedItem.Type ~= "Currency" and gain > state.ExpectedItem.Amount then
		return ambiguous("Matching item quantity exceeds the native expected grant; external or duplicate gain cannot be excluded")
	end
	state.MatchingIncreaseObserved, state.ObservedGrantAmount = gain > 0, gain > 0 and gain or nil
	state.GrantObserved = gain > 0 and (state.ExpectedItem.Type == "Currency" or gain == state.ExpectedItem.Amount)
	state.Last = copy(current)
	if state.TicketDebitObserved and state.GrantObserved and state.SettlementCompleted then
		state.ReceiptState, state.Reason = "TICKET_DEBIT_AND_GRANT_OBSERVED", "One ticket debit and matching received grant observed after native settlement; server attribution remains unproven"
	elseif state.GrantObserved then
		state.ReceiptState, state.Reason = "GRANT_OBSERVED_AWAITING_SETTLEMENT", "Matching received increase observed; ticket debit or native settlement still incomplete"
	elseif gain > 0 then
		state.ReceiptState, state.Reason = "PENDING", "Partial matching item increase observed; awaiting the complete native catalog quantity"
	else
		state.ReceiptState, state.Reason = "PENDING", "Awaiting matching received grant; presentation/return/queue call alone is insufficient"
	end
	return state
end

return WheelSpinPolicy

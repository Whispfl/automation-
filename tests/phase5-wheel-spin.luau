-- Pure synthetic received-account fixtures. No real account or native actions.
local checks = 0
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copy(entry) end return result
end
local function same(left, right)
	if type(left) ~= type(right) then return false end
	if type(left) ~= "table" then return left == right end
	for key, entry in pairs(left) do if not same(entry, right[key]) then return false end end
	for key in pairs(right) do if left[key] == nil then return false end end return true
end
local function test(label, callback)
	callback() checks += 1 print("[OC WHEEL SPIN SYNTHETIC] " .. label .. " passed")
end
local function context()
	return { Fresh = true, UserId = 101, Revision = 1, ReadAt = 100,
		Balances = { Coins = 100, Gems = 50 }, Raw = { Coins = 100, Gems = 50,
			Powerups = { ["Spin Ticket"] = 5, ["Mystery Box"] = 2 },
			Potions = { { Name = "Coins", Level = 3, Amount = 1 }, { Name = "Coins", Amount = 2 } },
			Pets = { { Id = "synthetic-doggy", Name = "Doggy", Amount = 3 }, { Id = "synthetic-umbra", Name = "Umbra" } } } }
end
local function observed(c, revision)
	c.Revision, c.ReadAt = revision or c.Revision + 1, c.ReadAt + 1
	c.Balances = { Coins = c.Raw.Coins, Gems = c.Raw.Gems }
	return WheelSpinPolicy.Normalize(c)
end
local currency = { Type = "Currency", Currency = "Coins", Amount = 200 }
local function begin(item)
	local c = context() local base = WheelSpinPolicy.Normalize(c)
	assert(base.Status == "READY")
	return c, WheelSpinPolicy.Begin(base, item or currency), base
end
local function debit(c, state)
	c.Raw.Powerups["Spin Ticket"] -= 1
	local output = WheelSpinPolicy.Observe(state, observed(c), {})
	assert(output.TicketDebitObserved and not output.GrantObserved and output.ReceiptState == "PENDING")
	return output
end

test("current native inventories normalize into detached exact facts", function()
	local c = context() local original = copy(c)
	local result = WheelSpinPolicy.Normalize(c)
	assert(result.Status == "READY" and result.UserId == 101 and result.Tickets == 5)
	assert(result.Facts.Pets["synthetic-umbra"].Amount == 1 and result.Facts.Pets["synthetic-doggy"].Amount == 3)
	assert(result.Facts.Pets["synthetic-umbra"].Variants.Shiny == false)
	result.Facts.Powerups["Spin Ticket"] = 99 result.Facts.Pets["synthetic-doggy"].Amount = 99
	assert(same(c, original))
end)

for _, fault in ipairs({
	{ "stale or unverified facts", function(c) c.Fresh = false end },
	{ "missing exact account", function(c) c.UserId = nil end },
	{ "zero account", function(c) c.UserId = 0 end },
	{ "fractional account", function(c) c.UserId = 1.5 end },
	{ "missing revision", function(c) c.Revision = nil end },
	{ "negative timestamp", function(c) c.ReadAt = -1 end },
	{ "missing received account", function(c) c.Raw = nil end },
	{ "missing currency map", function(c) c.Balances = nil end },
	{ "currency disagreement", function(c) c.Balances.Coins = 101 end },
	{ "negative currency", function(c) c.Raw.Coins = -1 c.Balances.Coins = -1 end },
	{ "nonfinite currency", function(c) c.Raw.Coins = math.huge c.Balances.Coins = math.huge end },
	{ "NaN currency", function(c) c.Raw.Coins = 0/0 c.Balances.Coins = 0/0 end },
	{ "missing Powerups map", function(c) c.Raw.Powerups = nil end },
	{ "invalid Powerup name", function(c) c.Raw.Powerups[""] = 1 end },
	{ "fractional Powerup count", function(c) c.Raw.Powerups["Spin Ticket"] = 1.5 end },
	{ "negative Powerup count", function(c) c.Raw.Powerups["Spin Ticket"] = -1 end },
	{ "missing potion array", function(c) c.Raw.Potions = nil end },
	{ "historical nested potion map", function(c) c.Raw.Potions = { Coins = { [3] = 2 } } end },
	{ "sparse potion rows", function(c) c.Raw.Potions = { [1] = c.Raw.Potions[1], [3] = c.Raw.Potions[2] } end },
	{ "duplicate potion Name and Level", function(c) c.Raw.Potions[3] = copy(c.Raw.Potions[1]) end },
	{ "duplicate nil-level potion", function(c) c.Raw.Potions[3] = copy(c.Raw.Potions[2]) end },
	{ "malformed potion amount", function(c) c.Raw.Potions[1].Amount = nil end },
	{ "zero potion Level", function(c) c.Raw.Potions[1].Level = 0 end },
	{ "noninteger potion Level", function(c) c.Raw.Potions[1].Level = 1.5 end },
	{ "string potion Level", function(c) c.Raw.Potions[1].Level = "3" end },
	{ "missing pet array", function(c) c.Raw.Pets = nil end },
	{ "sparse pet rows", function(c) c.Raw.Pets = { [2] = c.Raw.Pets[1] } end },
	{ "duplicate exact pet ID", function(c) c.Raw.Pets[3] = copy(c.Raw.Pets[1]) end },
	{ "missing pet ID", function(c) c.Raw.Pets[1].Id = nil end },
	{ "invalid pet name", function(c) c.Raw.Pets[1].Name = "" end },
	{ "zero pet amount", function(c) c.Raw.Pets[1].Amount = 0 end },
	{ "invalid pet variant", function(c) c.Raw.Pets[1].Shiny = 1 end },
	{ "cyclic Super metadata", function(c) local v = {} v.Self = v c.Raw.Pets[1].Super = v end },
}) do
	test("normalization rejects " .. fault[1], function()
		local c = context() fault[2](c)
		local result = WheelSpinPolicy.Normalize(c)
		assert(result.Status == "UNKNOWN" and type(result.Reason) == "string")
	end)
end

test("complete empty maps establish zero stock; missing maps never do", function()
	local c = context() c.Raw.Powerups = {} c.Raw.Potions = {} c.Raw.Pets = {}
	local result = WheelSpinPolicy.Normalize(c)
	assert(result.Status == "READY" and result.Tickets == 0)
	local state = WheelSpinPolicy.Begin(result, currency)
	assert(state.ReceiptState == "UNKNOWN" and string.find(state.Reason, "No received owned", 1, true))
	c.Raw.Powerups = nil assert(WheelSpinPolicy.Normalize(c).Status == "UNKNOWN")
end)

test("missing expected currency never becomes an invented zero balance", function()
	local c = context() c.Raw.Coins = nil c.Balances.Coins = nil
	local result = WheelSpinPolicy.Normalize(c)
	assert(result.Status == "READY" and result.Facts.Balances.Coins == nil)
	assert(WheelSpinPolicy.Begin(result, currency).ReceiptState == "UNKNOWN")
end)

for _, item in ipairs({ {}, { Type = "Currency", Currency = "Coins" }, { Type = "Powerup", Name = "Golden Key" },
	{ Type = "Potion", Name = "Coins", Level = -1, Amount = 1 }, { Type = "Pet", Name = "Umbra", Shiny = 1 },
	{ Type = "Rod", Name = "Unknown" }, { Type = "Pet", Name = "Umbra", Amount = 0 } }) do
	test("unsupported or incomplete catalog descriptor does not authorize a receipt", function()
		local _, state = begin(item) assert(state.ReceiptState == "UNKNOWN")
	end)
end

test("return value, animation and queue call alone never confirm a grant", function()
	local c, state = begin()
	local result = WheelSpinPolicy.Observe(state, WheelSpinPolicy.Normalize(c),
		{ SettlementCompleted = true, InvocationReturn = 1, AnimationCompleted = true, QueueClaimRequested = true })
	assert(not result.GrantObserved and not result.TicketDebitObserved and result.ReceiptState == "PENDING")
end)

test("native currency amount is a catalog expectation, while receipt reports actual measured gain", function()
	local c, state = begin() state = debit(c, state)
	c.Raw.Coins += 473
	local result = WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true })
	assert(result.ReceiptState == "TICKET_DEBIT_AND_GRANT_OBSERVED" and result.ObservedGrantAmount == 473)
	assert(result.ExpectedItem.Amount == 200 and result.Attribution == "EXTERNAL_GAINS_CANNOT_BE_EXCLUDED")
end)

test("combined non-ticket debit and matching grant remain received evidence", function()
	local c, state = begin() c.Raw.Powerups["Spin Ticket"] -= 1 c.Raw.Coins += 200
	local result = WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true })
	assert(result.TicketDebitObserved and result.GrantObserved and result.ReceiptState == "TICKET_DEBIT_AND_GRANT_OBSERVED")
end)

test("split grant before debit waits for the second actual fact", function()
	local c, state = begin() c.Raw.Coins += 200
	state = WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true })
	assert(state.GrantObserved and not state.TicketDebitObserved and state.ReceiptState == "GRANT_OBSERVED_AWAITING_SETTLEMENT")
	c.Raw.Powerups["Spin Ticket"] -= 1
	state = WheelSpinPolicy.Observe(state, observed(c), {})
	assert(state.ReceiptState == "TICKET_DEBIT_AND_GRANT_OBSERVED")
end)

test("matching grant without native settlement remains pending", function()
	local c, state = begin() state = debit(c, state) c.Raw.Coins += 200
	state = WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = false })
	assert(state.GrantObserved and state.ReceiptState == "GRANT_OBSERVED_AWAITING_SETTLEMENT")
	state = WheelSpinPolicy.Observe(state, WheelSpinPolicy.Normalize(c), { SettlementCompleted = true })
	assert(state.ReceiptState == "TICKET_DEBIT_AND_GRANT_OBSERVED")
end)

for _, reward in ipairs({
	{ "existing Powerup", { Type = "Powerup", Name = "Mystery Box", Amount = 1 }, function(c) c.Raw.Powerups["Mystery Box"] += 1 end },
	{ "new Powerup", { Type = "Powerup", Name = "Golden Key", Amount = 1 }, function(c) c.Raw.Powerups["Golden Key"] = 1 end },
	{ "existing exact-level Potion", { Type = "Potion", Name = "Coins", Level = 3, Amount = 1 }, function(c) c.Raw.Potions[1].Amount += 1 end },
	{ "existing nil-level Potion", { Type = "Potion", Name = "Coins", Amount = 1 }, function(c) c.Raw.Potions[2].Amount += 1 end },
	{ "new exact-level Potion", { Type = "Potion", Name = "Speed", Level = 3, Amount = 1 }, function(c) table.insert(c.Raw.Potions, { Name = "Speed", Level = 3, Amount = 1 }) end },
	{ "existing normal pet stack", { Type = "Pet", Name = "Umbra" }, function(c) c.Raw.Pets[2].Amount = 2 end },
	{ "new normal pet", { Type = "Pet", Name = "Umbra" }, function(c) table.insert(c.Raw.Pets, { Id = "synthetic-new-umbra", Name = "Umbra" }) end },
	{ "exact shiny pet", { Type = "Pet", Name = "Umbra", Shiny = true }, function(c) table.insert(c.Raw.Pets, { Id = "synthetic-shiny-umbra", Name = "Umbra", Shiny = true }) end },
}) do
	test("observed native grant family: " .. reward[1], function()
		local c, state = begin(reward[2]) state = debit(c, state) reward[3](c)
		local result = WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true })
		assert(result.ReceiptState == "TICKET_DEBIT_AND_GRANT_OBSERVED" and result.ObservedGrantAmount == 1)
	end)
end

test("returned five tickets require the separately observed single-ticket debit", function()
	local item = { Type = "Powerup", Name = "Spin Ticket", Amount = 5 }
	local c, state = begin(item) state = debit(c, state)
	c.Raw.Powerups["Spin Ticket"] += 5
	state = WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true })
	assert(state.ReceiptState == "TICKET_DEBIT_AND_GRANT_OBSERVED" and state.ObservedGrantAmount == 5)
	assert(c.Raw.Powerups["Spin Ticket"] == 9 and state.DebitSnapshot.Tickets == 4)
end)

test("coalesced net plus four tickets does not invent the hidden debit and grant", function()
	local c, state = begin({ Type = "Powerup", Name = "Spin Ticket", Amount = 5 })
	c.Raw.Powerups["Spin Ticket"] += 4
	state = WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true })
	assert(state.ReceiptState == "PENDING" and not state.TicketDebitObserved and not state.GrantObserved)
end)

for _, change in ipairs({
	{ "extra ticket debit", function(c) c.Raw.Powerups["Spin Ticket"] -= 2 end },
	{ "unexpected ticket gain", function(c) c.Raw.Powerups["Spin Ticket"] += 1 end },
	{ "unrelated currency gain", function(c) c.Raw.Gems += 1 end },
	{ "negative target currency", function(c) c.Raw.Coins -= 1 end },
	{ "unrelated item gain", function(c) c.Raw.Powerups["Mystery Box"] += 1 end },
	{ "unrelated Potion gain", function(c) c.Raw.Potions[1].Amount += 1 end },
	{ "unrelated pet gain", function(c) c.Raw.Pets[1].Amount += 1 end },
	{ "exact pet ID renamed", function(c) c.Raw.Pets[1].Name = "Changed" end },
	{ "exact pet ID changed variant", function(c) c.Raw.Pets[1].Shiny = true end },
	{ "existing item consumption", function(c) c.Raw.Powerups["Mystery Box"] -= 1 end },
}) do
	test("contradictory received changes stay blocked: " .. change[1], function()
		local c, state = begin() change[2](c)
		state = WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true })
		assert(state.ReceiptState == "AMBIGUOUS")
		c.Raw.Powerups["Spin Ticket"] = 4 c.Raw.Coins += 200
		assert(WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true }).ReceiptState == "AMBIGUOUS")
	end)
end

test("wrong Potion Level is not the expected reward", function()
	local c, state = begin({ Type = "Potion", Name = "Coins", Level = 1, Amount = 1 }) state = debit(c, state)
	c.Raw.Potions[2].Amount += 1
	assert(WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true }).ReceiptState == "AMBIGUOUS")
end)

test("wrong pet variant is not a visual or name-only receipt", function()
	local c, state = begin({ Type = "Pet", Name = "Umbra" }) state = debit(c, state)
	table.insert(c.Raw.Pets, { Id = "synthetic-shiny", Name = "Umbra", Shiny = true })
	assert(WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true }).ReceiptState == "AMBIGUOUS")
end)

test("native absent and false variant flags consistently describe a normal pet", function()
	local c, state = begin({ Type = "Pet", Name = "Umbra" }) state = debit(c, state)
	c.Raw.Pets[2].Super, c.Raw.Pets[2].Shiny, c.Raw.Pets[2].Mythic, c.Raw.Pets[2].XL = false, false, false, false
	c.Raw.Pets[2].Amount = 2
	assert(WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true }).ReceiptState == "TICKET_DEBIT_AND_GRANT_OBSERVED")
end)

test("restored ticket after observed debit is a contradiction for a non-ticket prize", function()
	local c, state = begin() state = debit(c, state)
	c.Raw.Powerups["Spin Ticket"] += 1 c.Raw.Coins += 200
	assert(WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true }).ReceiptState == "AMBIGUOUS")
end)

test("ticket prize cannot hide unrelated gains before a separate debit", function()
	local c, state = begin({ Type = "Powerup", Name = "Spin Ticket", Amount = 5 })
	c.Raw.Powerups["Spin Ticket"] += 4 c.Raw.Gems += 1
	assert(WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true }).ReceiptState == "AMBIGUOUS")
end)

test("unknown or partial received updates wait without resetting the debit baseline", function()
	local c, state = begin() state = debit(c, state)
	local previous = copy(state)
	state = WheelSpinPolicy.Observe(state, { Status = "UNKNOWN" }, { SettlementCompleted = true })
	assert(state.ReceiptState == "PENDING" and state.TicketDebitObserved and not state.GrantObserved)
	assert(same(state.Baseline, previous.Baseline) and same(previous.Last, state.Last))
	c.Raw.Coins += 200
	assert(WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true }).ReceiptState == "TICKET_DEBIT_AND_GRANT_OBSERVED")
end)

test("changed account and regressed revisions remain ambiguous", function()
	for _, mutate in ipairs({ function(v) v.UserId = 202 end, function(v) v.Revision = 0 end, function(v) v.ReadAt = 0 end }) do
		local c, state = begin() local current = WheelSpinPolicy.Normalize(c) mutate(current)
		assert(WheelSpinPolicy.Observe(state, current, {}).ReceiptState == "AMBIGUOUS")
	end
end)

test("same revision cannot carry new received grant facts", function()
	local c, state = begin() c.Raw.Coins += 200 c.Raw.Powerups["Spin Ticket"] -= 1
	assert(WheelSpinPolicy.Observe(state, observed(c, 1), { SettlementCompleted = true }).ReceiptState == "AMBIGUOUS")
end)

test("partial native item grant waits for complete expected quantity", function()
	local c, state = begin({ Type = "Powerup", Name = "Golden Key", Amount = 2 }) state = debit(c, state)
	c.Raw.Powerups["Golden Key"] = 1
	state = WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true })
	assert(state.ReceiptState == "PENDING" and not state.GrantObserved and state.ObservedGrantAmount == 1)
	c.Raw.Powerups["Golden Key"] = 2
	assert(WheelSpinPolicy.Observe(state, observed(c), {}).ReceiptState == "TICKET_DEBIT_AND_GRANT_OBSERVED")
end)

test("excess item grant and multiple matching new pets remain ambiguous", function()
	local c, state = begin({ Type = "Powerup", Name = "Golden Key", Amount = 1 }) state = debit(c, state)
	c.Raw.Powerups["Golden Key"] = 2
	assert(WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true }).ReceiptState == "AMBIGUOUS")
	c, state = begin({ Type = "Pet", Name = "Umbra" }) state = debit(c, state)
	table.insert(c.Raw.Pets, { Name = "Umbra", Id = "synthetic-new-one" })
	table.insert(c.Raw.Pets, { Name = "Umbra", Id = "synthetic-new-two" })
	assert(WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true }).ReceiptState == "AMBIGUOUS")
end)

test("later lost or reduced reward never overwrites observed grant evidence", function()
	local c, state = begin() state = debit(c, state) c.Raw.Coins += 200
	state = WheelSpinPolicy.Observe(state, observed(c), {}) c.Raw.Coins -= 100
	assert(WheelSpinPolicy.Observe(state, observed(c), { SettlementCompleted = true }).ReceiptState == "AMBIGUOUS")
end)

test("missing pending baseline and forged READY shape fail closed", function()
	assert(WheelSpinPolicy.Begin({ Status = "READY" }, currency).ReceiptState == "UNKNOWN")
	assert(WheelSpinPolicy.Observe({}, {}, {}).ReceiptState == "UNKNOWN")
end)

test("observations and catalog descriptors are never mutated", function()
	local c, state, base = begin() local stateBefore, baseBefore = copy(state), copy(base)
	local catalogBefore = copy(currency)
	c.Raw.Powerups["Spin Ticket"] -= 1 c.Raw.Coins += 200
	local current = observed(c) local currentBefore = copy(current)
	local output = WheelSpinPolicy.Observe(state, current, { SettlementCompleted = true })
	output.Baseline.Facts.Powerups["Spin Ticket"] = 99
	assert(same(state, stateBefore) and same(base, baseBefore) and same(current, currentBefore) and same(currency, catalogBefore))
end)

print("[OC WHEEL SPIN SYNTHETIC] " .. checks .. " pure native-schema/receipt checks passed; no live gameplay acceptance claimed.")

--!nonstrict
-- Explicit one-request exception to held future-world Coins, never a world-cost
-- change. Shared consumption survives bundle reloads only in this client VM.
local Allowance = {}
Allowance.__index = Allowance
local ledgerKey = "__OC_OWNER_ONE_HATCH_TEST_LEDGER"
local limitation = "Same client VM shared ledger only; client restart/rejoin can lose this record; no cross-client durable persistence is claimed"
local states = { REQUESTED_UNRESOLVED = true, INVOCATION_UNCERTAIN = true, RECEIVED_CONFIRMED = true, RECEIVED_UNCONFIRMED = true }

local function finite(value) return type(value) == "number" and value == value and value >= 0 and value < math.huge end
local function account(value) return finite(value) and value > 0 and value % 1 == 0 end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copy(entry) end
	return result
end
local function enabled(config)
	return config.OWNER_ONE_HATCH_TEST_SETTINGS and config.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_HATCH_TEST_ALLOWANCE == true
end
local function ledger(create)
	if type(shared) ~= "table" then return nil, "Same-VM shared allowance ledger unavailable; no exception request" end
	local value = rawget(shared, ledgerKey)
	if value == nil and create then value = { Version = 1, Accounts = {} } rawset(shared, ledgerKey, value) end
	if type(value) ~= "table" or value.Version ~= 1 or type(value.Accounts) ~= "table"
		or getmetatable(value) ~= nil or getmetatable(value.Accounts) ~= nil then return nil, "Allowance ledger missing/corrupt/unsupported; no exception request" end
	for key, record in pairs(value.Accounts) do
		local id = tonumber(key)
		if type(key) ~= "string" or not account(id) or tostring(id) ~= key or type(record) ~= "table"
			or record.AccountId ~= id or record.Consumed ~= true or not states[record.State]
			or record.RequestedHatches ~= 1 or record.Currency ~= "Coins" or type(record.EggName) ~= "string" or record.EggName == ""
			or not finite(record.RequestedPrice) or record.RequestedPrice <= 0 or not finite(record.WorldReserveBorrowed)
			or not finite(record.IssuedAt) then return nil, "Allowance account record corrupt; no exception request" end
	end
	return value
end

local function isolation(config, eggName)
	local p, h, settings = config.PET_SETTINGS, config.HATCH_SETTINGS, config.OWNER_ONE_HATCH_TEST_SETTINGS
	if not p or not h or not settings or p.ENABLE_PET_INTELLIGENCE ~= true or p.AUTO_HATCH ~= true
		or p.AUTO_EQUIP ~= false or p.EQUIP_OWNED_TEAM_ONCE ~= false or p.OBJECTIVE_CURRENCY ~= "Coins"
		or h.HATCH_ONE_EGG_ONCE ~= true or h.EGG_SELECTION_MODE ~= "MANUAL"
		or type(h.SELECTED_EGGS) ~= "table" or #h.SELECTED_EGGS ~= 1 or h.SELECTED_EGGS[1] ~= eggName
		or type(h.ALLOWED_CURRENCIES) ~= "table" or #h.ALLOWED_CURRENCIES ~= 1 or h.ALLOWED_CURRENCIES[1] ~= "Coins"
		or h.MAXIMUM_SESSION_HATCHES ~= 1 or h.MAXIMUM_BATCH_HATCHES ~= 1
		or not finite(h.MAXIMUM_EGG_COST) or h.MAXIMUM_EGG_COST <= 0 or not finite(h.MAXIMUM_SESSION_COST) or h.MAXIMUM_SESSION_COST <= 0
		or h.ENABLE_BACKGROUND_PICKUPS ~= false or h.PRESERVE_PROGRESSION_RESERVE ~= true
		or not finite(settings.MAXIMUM_COIN_ALLOWANCE) or settings.MAXIMUM_COIN_ALLOWANCE <= 0
		or not finite(settings.MAXIMUM_EGG_COST) or settings.MAXIMUM_EGG_COST <= 0 then return "Owner allowance requires one named isolated MANUAL Coins hatch with positive explicit ceilings" end
	local travel = config.EGG_TRAVEL_SETTINGS
	if not travel or travel.MODE ~= "NORMAL" then return "Owner allowance requires NORMAL mode for the isolated hatch" end
	if travel.ENABLE_SELECTED_EGG_TRAVEL then
		if travel.MAXIMUM_ATTEMPTS_PER_SELECTION ~= 1 then return "Owner allowance selected-egg travel requires one bounded attempt" end
	elseif travel.ENABLE_DIRECT_POSITIONING or travel.ENABLE_NATIVE_ISLAND_TRAVEL then
		return "Owner allowance direct/native travel requires the selected-egg travel owner"
	end
	for category, keys in pairs({
		WORLD_SETTINGS = { "ENABLE_WORLD_PROGRESSION", "AUTO_DISCOVER_ISLANDS", "AUTO_UNLOCK_WORLDS", "AUTO_TRAVEL_FOR_PROGRESSION", "AUTO_FARM_UNLOCK_REQUIREMENTS" },
		FARMING_SETTINGS = { "AUTO_RESOURCE_FARM", "AUTO_FARM_FALLBACK" },
		ISLAND_SETTINGS = { "AUTO_TRAVEL_BEST_ISLAND", "AUTO_EXPLORE_UNLOCKED_ISLANDS" },
		PICKUP_SETTINGS = { "BULK_COLLECT_PICKUPS", "STATIONARY_ISOLATED_TEST" },
		BUBBLE_SETTINGS = { "AUTO_BLOW_BUBBLES", "AUTO_SELL_BUBBLES", "AUTO_BUY_GUM", "AUTO_BUY_FLAVORS", "ENABLE_SIMULTANEOUS_BLOWING" },
		UPGRADE_SETTINGS = { "ENABLE_SMART_UPGRADES", "ENABLE_CAPACITY_UPGRADES", "ENABLE_FLAVOR_UPGRADES", "AUTO_EQUIP_OWNED_UPGRADES" },
		PET_SETTINGS = { "AUTO_DELETE_PETS", "AUTO_CRAFT_SHINY", "AUTO_FUSE_PETS" },
		PLAYTIME_SETTINGS = { "AUTO_CLAIM_PLAYTIME" },
		MYSTERY_BOX_SETTINGS = { "AUTO_OPEN_MYSTERY_BOXES", "ENABLE_AUTOMATIC_CONTINUATION" },
		ANTIAFK_SETTINGS = { "ENABLE_ANTI_AFK" },
		FALL_EVENT_SETTINGS = { "ENABLE_FALL_EVENT", "AUTO_REBIRTH", "AUTO_BUY_REBIRTH_UPGRADES", "AUTO_USE_FALL_ELIXIRS", "AUTO_BUY_AUTUMN_SHOP_ITEMS" },
	}) do
		for _, key in ipairs(keys) do if config[category] and config[category][key] then return "Owner allowance requires " .. category .. "." .. key .. " OFF" end end
	end
end

function Allowance.Isolation(config)
	local selected = config.HATCH_SETTINGS and config.HATCH_SETTINGS.SELECTED_EGGS
	return isolation(config, type(selected) == "table" and selected[1] or nil)
end

function Allowance.EffectiveFunds(config, snapshot, currency, eggName, balance, accountId)
	local result = { Enabled = enabled(config), Eligible = false, Persistence = limitation }
	if not result.Enabled then result.Reason = "Owner one-hatch allowance OFF; normal world reserve applies" return result end
	local reason = isolation(config, eggName)
	if reason then result.Reason = reason return result end
	if currency ~= "Coins" or not account(accountId) then result.Reason = "Owner allowance requires verified current account identity and Coins" return result end
	local authorizedId = config.OWNER_ONE_HATCH_TEST_SETTINGS.AUTHORIZED_ACCOUNT_ID
	if not account(authorizedId) or authorizedId ~= accountId then
		result.Reason = "Owner allowance requires the explicit authorized account ID to match the current account" return result
	end
	local current, ledgerReason = ledger(false)
	if not current then result.Reason = ledgerReason return result end
	if current.Accounts[tostring(accountId)] then result.Reason = "Owner one-hatch allowance already consumed/unresolved for this account in this client VM; normal reserve restored" return result end
	local resource = config.RESOURCE_SETTINGS and config.RESOURCE_SETTINGS.COIN_RESERVE
	local graph = snapshot and snapshot.ProgressionGraph
	if not finite(resource) or not finite(balance) or not graph or graph.Blocker or type(graph.Worlds) ~= "table" or #graph.Worlds == 0 then
		result.Reason = "Current Coins/configured reserve/native future-world reserve unavailable; no allowance" return result
	end
	local worldReserve, worldName = 0
	for _, world in ipairs(graph.Worlds) do
		if world.Unlocked then continue end
		local cost = world.Cost
		if not cost or cost.Type ~= "Currency" or type(cost.Currency) ~= "string" or cost.Currency == "" or not finite(cost.Amount) then
			result.Reason = "Native next-world cost/currency unknown; no reserve exception" return result
		end
		if cost.Currency == "Coins" then worldReserve, worldName = cost.Amount, world.Name end
		break
	end
	local normal = resource + worldReserve
	if not finite(normal) then result.Reason = "Combined native/configured reserve invalid; no allowance" return result end
	local heldWorld = math.min(worldReserve, math.max(0, balance - resource))
	local additional = math.min(config.OWNER_ONE_HATCH_TEST_SETTINGS.MAXIMUM_COIN_ALLOWANCE, heldWorld)
	result.Eligible, result.ResourceReserve, result.WorldReserve, result.WorldName = true, resource, worldReserve, worldName
	result.NormalReserve, result.NormalSpendable, result.HeldWorldReserve = normal, math.max(0, balance - normal), heldWorld
	result.AdditionalSpendable, result.Spendable = additional, math.max(0, balance - normal) + additional
	result.EffectiveReserve = resource + heldWorld - additional
	result.Reason = "One explicit named hatch may draw only capped currently held future-world Coins; native world goal/cost and configured resource reserve remain intact"
	return result
end

function Allowance.new(controller)
	local self = setmetatable({ Controller = controller, Persistence = limitation }, Allowance)
	if enabled(controller.Config) then
		self.AccountId = controller.Reader.Player and controller.Reader.Player.UserId
		self.AuthorizedAccountId = controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS.AUTHORIZED_ACCOUNT_ID
		if not account(self.AccountId) or not account(self.AuthorizedAccountId) or self.AccountId ~= self.AuthorizedAccountId then
			self.Fault = "Owner allowance explicit authorized account ID does not match the initial current account; no request"
		else self.Ledger, self.Fault = ledger(true) end
	end
	return self
end

function Allowance:AccountValid()
	if not enabled(self.Controller.Config) then return true end
	if self.Fault then return false, self.Fault end
	local player = self.Controller.Reader.Player
	local settings = self.Controller.Config.OWNER_ONE_HATCH_TEST_SETTINGS
	if not player or player.UserId ~= self.AccountId or settings.AUTHORIZED_ACCOUNT_ID ~= self.AuthorizedAccountId
		or not account(self.AccountId) or self.AccountId ~= self.AuthorizedAccountId then
		self.Cancelled = true
		self.CancelReason = "Owner allowance initial/authorized account identity changed; authorization invalidated without consumption"
	end
	if self.Cancelled then return false, self.CancelReason or "Controller's owner test authorization stopped before request; no consumption" end
	return true
end

function Allowance:Eligibility(eggName, price, snapshot, balance, accountId)
	local config = self.Controller.Config
	if not enabled(config) then return true, "Owner allowance OFF; normal policy required" end
	local accountValid, accountReason = self:AccountValid()
	if not accountValid or accountId ~= self.AccountId then return false, accountReason or "Owner allowance account identity changed; no request" end
	local current, reason = ledger(false)
	if not current or not self.Ledger or current ~= self.Ledger then return false, reason or "Owner allowance ledger identity changed; no request" end
	local funds = Allowance.EffectiveFunds(config, snapshot, "Coins", eggName, balance, accountId)
	if not funds.Eligible then return false, funds.Reason, funds end
	local settings, h = config.OWNER_ONE_HATCH_TEST_SETTINGS, config.HATCH_SETTINGS
	if not finite(price) or price <= 0 or price > settings.MAXIMUM_EGG_COST or price > h.MAXIMUM_EGG_COST or price > h.MAXIMUM_SESSION_COST
		or price > funds.Spendable or balance - price < funds.ResourceReserve then return false, "Exact native egg price exceeds owner allowance/cost/held funds or configured resource reserve", funds end
	local borrowed = math.max(0, price - funds.NormalSpendable)
	if borrowed > settings.MAXIMUM_COIN_ALLOWANCE or borrowed > funds.HeldWorldReserve then return false, "Actual held future-world Coins draw exceeds explicit allowance", funds end
	return true, funds.Reason, funds
end

function Allowance:Consume(eggName, price, snapshot, balance, accountId, beforeEvidence)
	if not enabled(self.Controller.Config) then return true end
	local allowed, reason, funds = self:Eligibility(eggName, price, snapshot, balance, accountId)
	if not allowed then return false, reason end
	local player = self.Controller.Reader.Player
	if self.Controller.State ~= "RUNNING" or not player or player.UserId ~= accountId then return false, "Owner allowance controller/account changed before consumption" end
	local record = { AccountId = accountId, Consumed = true, State = "REQUESTED_UNRESOLVED", RequestedHatches = 1,
		EggName = eggName, Currency = "Coins", RequestedPrice = price, IssuedAt = os.clock(), BeforeBalance = balance,
		WorldReserveBorrowed = math.max(0, price - funds.NormalSpendable), ResourceReserve = funds.ResourceReserve,
		WorldGoalCost = funds.WorldReserve, NormalReserve = funds.NormalReserve, EffectiveReserve = funds.EffectiveReserve,
		BeforeEvidence = beforeEvidence and copy(beforeEvidence),
		Persistence = limitation, Attribution = "Request allowance consumed before invocation; actual charge/delivery remain unconfirmed" }
	self.Ledger.Accounts[tostring(accountId)] = record
	self.Record = record
	return true, reason, copy(record)
end

function Allowance:Uncertain(reason)
	if self.Record then self.Record.State, self.Record.Reason = "INVOCATION_UNCERTAIN", reason end
end

function Allowance:Observe(result)
	if not self.Record or not result or self.LastObservedResult == result then return end
	self.LastObservedResult = result -- private transient reference, never stored in the shared status record.
	local value = result.Balances and result.Balances.Coins
	self.Record.State = result.Status == "INVENTORY_GAIN_OBSERVED" and "RECEIVED_CONFIRMED" or "RECEIVED_UNCONFIRMED"
	self.Record.Result = { Status = result.Status, CounterBefore = result.CounterBefore, CounterAfter = result.CounterAfter,
		CounterDelta = result.CounterDelta, RequestedQuantity = result.RequestedQuantity, ReceivedQuantity = result.Quantity,
		Changes = copy(result.Changes), BeforeBalance = value and value.Before, AfterBalance = value and value.After,
		ObservedNetDebit = value and value.Delta and -value.Delta or nil, RequestedPrice = self.Record.RequestedPrice,
		Reason = result.Reason, Attribution = "Received inventory/counter and observed net balance only; exact server charge/ownership attribution UNKNOWN", Persistence = limitation }
end

function Allowance:Halt(stopped) if stopped then self.Cancelled = true end end
function Allowance:GetStatus()
	local current, reason = ledger(false)
	local id = self.Controller.Reader.Player and self.Controller.Reader.Player.UserId
	return { Enabled = enabled(self.Controller.Config), Consumed = current and account(id) and current.Accounts[tostring(id)] ~= nil or false,
		AccountId = self.AccountId, AuthorizedAccountId = self.AuthorizedAccountId, CurrentAccountId = id,
		Record = self.Record and copy(self.Record) or current and account(id) and current.Accounts[tostring(id)] and copy(current.Accounts[tostring(id)]),
		Fault = self.Fault or enabled(self.Controller.Config) and (not current or current ~= self.Ledger) and (reason or "Ledger identity changed") or nil,
		Cancelled = self.Cancelled == true, CancelReason = self.CancelReason, Persistence = limitation }
end

return Allowance

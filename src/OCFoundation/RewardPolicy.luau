--!nonstrict
-- Pure Phase 5 reward intelligence. This module never requests or consumes a reward.
local RewardPolicy = {}

local function finite(value)
	return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

local function integer(value)
	return finite(value) and value % 1 == 0
end

local function nativeStringIndexMap(value)
	if type(value) ~= "table" then return false end
	for key in pairs(value) do
		if type(key) ~= "string" or not string.match(key, "^%d+$") then return false end
		local index = tonumber(key)
		if not integer(index) or index < 1 or tostring(index) ~= key then return false end
	end
	return true
end

local function stringKeyMap(value)
	if type(value) ~= "table" then return false end
	for key in pairs(value) do if type(key) ~= "string" or key == "" then return false end end
	return true
end

local function nativeTierValues(value)
	if type(value) ~= "table" then return false end
	for key, tier in pairs(value) do
		if not integer(key) or key < 1 or not integer(tier) or tier < 1 then return false end
	end
	return true
end

local function copy(value, seen)
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local result = {} seen[value] = result
	for key, entry in pairs(value) do result[key] = copy(entry, seen) end
	return result
end

local function keys(value)
	local result = {}
	for key in pairs(type(value) == "table" and value or {}) do
		if type(key) == "string" or type(key) == "number" and finite(key) then table.insert(result, key) end
	end
	table.sort(result, function(a, b)
		if type(a) == type(b) then return a < b end
		return type(a) == "number"
	end)
	return result
end

local function unknown(row, message)
	if not table.find(row.Unknowns, message) then table.insert(row.Unknowns, message) end
end

local function nativeBenefit(value, random)
	return { State = type(value) == "table" and "DECLARED_NATIVE" or "UNKNOWN", Items = copy(value),
		Randomized = random == true, ActualGrant = "UNKNOWN", EarningGain = "UNKNOWN",
		Reason = random and "Native pool descriptors are possible outcomes, not verified final odds or credited rewards"
			or "Declared native reward is not a received grant or measured earning improvement" }
end

local reserveFields = { Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" }

local function currencyCost(value)
	if type(value) ~= "table" or value.Type ~= "Currency" or type(value.Currency) ~= "string"
		or value.Currency == "" or not finite(value.Amount) then return nil end
	return { Type = "Currency", Currency = value.Currency, Amount = value.Amount }
end

local function affordability(config, raw, cost)
	if not cost then return "UNKNOWN" end
	local balance = raw[cost.Currency]
	local field = reserveFields[cost.Currency]
	local reserve = field and config.RESOURCE_SETTINGS and config.RESOURCE_SETTINGS[field]
	if not finite(balance) or not finite(reserve) then return "UNKNOWN", finite(balance) and balance or nil end
	local shortage = math.max(0, cost.Amount - math.max(0, balance - reserve))
	return shortage == 0 and "AFFORDABLE" or "INSUFFICIENT", balance, reserve, shortage
end

local function masteryPriority(report)
	if type(report) ~= "table" or report.ReadOnly ~= true or report.ActionAuthorization ~= "NONE"
		or report.Status == "DISABLED" or report.Status == "UNKNOWN" then return "UNKNOWN" end
	if not integer(report.ObtainableRemainingCategories) or not integer(report.UnresolvedCategories) then return "UNKNOWN" end
	if report.ObtainableRemainingCategories > 0 then return "INCOMPLETE" end
	if report.UnresolvedCategories > 0 then return "UNKNOWN" end
	return "NO_KNOWN_OBTAINABLE_TIER"
end

function RewardPolicy.Analyze(config, snapshot, context)
	config, snapshot, context = config or {}, snapshot or {}, context or {}
	local settings = config.REWARD_INTELLIGENCE_SETTINGS or {}
	local report = { ReadOnly = true, ActionsEnabled = false, ActionAuthorization = "NONE", Status = "UNKNOWN",
		Rows = {}, Groups = {}, Unknowns = {}, MasteryPriority = masteryPriority(context.MasteryReport),
		Recommendation = { Kind = "WAIT", Reason = "Reward evidence UNKNOWN", ExecutionAuthorized = false, ActionAuthorization = "NONE" },
		Policy = "Read-only eligibility; free rewards, paid World Rewards, quests, chests and consumed inventory remain separate; obtainable permanent Mastery retains priority" }
	if settings.ENABLE_REWARD_INTELLIGENCE ~= true then
		report.Status = "DISABLED" report.Recommendation.Reason = "Read-only reward intelligence is disabled" return report
	end
	local now, readAt = context.ObservedAt, snapshot.ReadAt
	if snapshot.Ready ~= true or context.Fresh ~= true or not finite(now) or not finite(readAt) or readAt > now
		or not finite(settings.MAXIMUM_ACCOUNT_AGE_SECONDS) or now - readAt > settings.MAXIMUM_ACCOUNT_AGE_SECONDS then
		table.insert(report.Unknowns, context.Blocker or "Account/native observation is unavailable, stale or inconsistent")
		return report
	end
	local raw = type(context.Raw) == "table" and context.Raw or type(context.Account) == "table" and context.Account
	if not raw then table.insert(report.Unknowns, "Received reward profile unavailable") return report end
	local catalogs = type(context.Catalogs) == "table" and context.Catalogs or {}
	local limit = integer(settings.MAXIMUM_REPORT_ROWS) and settings.MAXIMUM_REPORT_ROWS >= 1 and settings.MAXIMUM_REPORT_ROWS or 200
	local omitted = 0
	local function row(family, key, name)
		local result = { Key = family .. ":" .. tostring(key), Family = family, Name = name or tostring(key), Status = "UNKNOWN",
			Eligibility = "UNKNOWN", ClaimState = "UNKNOWN", Requirements = {}, Unknowns = {},
			Cost = { State = "UNKNOWN" }, PossibleBenefit = nativeBenefit(nil), InterruptsMastery = "UNKNOWN",
			ActionAuthorization = "NONE", ExecutionAuthorized = false }
		if #report.Rows < limit then
			table.insert(report.Rows, result)
			if not report.Groups[family] then report.Groups[family] = {} end
			table.insert(report.Groups[family], result)
		else omitted += 1 end
		return result
	end
	local function free(result)
		result.Cost = { Type = "FREE", Amount = 0, State = "NATIVE_FREE_INTERFACE" }
		unknown(result, "Server claim acceptance, actual grant and setup/presentation interruption remain unverified")
	end
	local function unavailable(family, name, reason)
		local result = row(family, "OBSERVATION", name) unknown(result, reason) return result
	end
	local playtime = catalogs.Playtime
	local gifts = type(playtime) == "table" and playtime.Gifts
	local state = raw.PlaytimeRewards
	if type(gifts) ~= "table" or next(gifts) == nil then
		unavailable("FREE_PLAYTIME", "Playtime rewards", "Native Playtime.Gifts catalog unavailable")
	else
		for _, index in ipairs(keys(gifts)) do
			if not integer(index) or index < 1 then continue end
			local gift = gifts[index]
			local result = row("FREE_PLAYTIME", index, "Playtime gift " .. tostring(index))
			free(result) result.Index = index result.PossibleBenefit = nativeBenefit(type(playtime) == "table" and playtime.Prizes, true)
			result.Requirements = { "Received Playtime capability", "Native Trading Plaza restriction", "Current cycle and exact sparse claimed map", "Native due time" }
			if type(gift) ~= "table" or not finite(gift.Time) then unknown(result, "Native gift time unavailable") continue end
			result.RequiredSeconds, result.ClientLuckDescriptor = gift.Time, gift.Luck
			if type(state) ~= "table" or type(state.Claimed) ~= "table" or not finite(state.Start) then
				unknown(result, "Received Playtime Start/Claimed unavailable; missing claim data is not unclaimed") continue
			end
			if state.Claimed[tostring(index)] ~= nil then result.Status, result.ClaimState = "CLAIMED", "CLAIMED_KEY_PRESENT" continue end
			if not nativeStringIndexMap(state.Claimed) then unknown(result, "Received Playtime claim map has non-native keys; no unclaimed state is inferred") continue end
			result.ClaimState = "UNCLAIMED_IN_RECEIVED_MAP"
			if context.HasPlaytime == false or context.IsTradingPlaza == true then
				result.Status, result.Eligibility = "LOCKED", "INELIGIBLE"
				result.Blocker = context.HasPlaytime == false and "Playtime capability not present in received Mastery upgrades" or "Native Playtime is disabled in Trading Plaza"
			elseif context.HasPlaytime ~= true or context.IsTradingPlaza ~= false then unknown(result, "Playtime capability or Trading Plaza observation unavailable")
			elseif not finite(context.NativeNow) or context.NativeNow < state.Start then unknown(result, "Native time unavailable or precedes received cycle start")
			else
				result.DueAt = state.Start + gift.Time
				if not finite(result.DueAt) then unknown(result, "Observed playtime deadline is not finite") continue end
				result.SecondsUntilDue = math.max(0, result.DueAt - context.NativeNow)
				result.Status = result.SecondsUntilDue == 0 and "DUE" or "AVAILABLE"
				result.Eligibility = result.Status == "DUE" and "CLIENT_ELIGIBLE" or "NOT_DUE"
			end
		end
	end

	local daily = row("FREE_DAILY", "STARS", "Daily reward stars")
	free(daily) daily.Requirements = { "Received LastDay/LastStreak and explicit Claimed boolean", "Native absolute UTC day", "Native rollover/streak eligibility" }
	local dailyState, dailyObservation = raw.DailyRewards, context.DailyObservation
	if type(dailyState) ~= "table" or type(dailyState.Claimed) ~= "boolean" then
		unknown(daily, "Received explicit daily claim state unavailable; missing is not unclaimed")
	elseif not integer(dailyState.LastDay) or not integer(dailyState.LastStreak) or not integer(context.NativeDay) then
		unknown(daily, "Received daily day/streak or native absolute day unavailable")
	elseif type(dailyObservation) == "table" and dailyObservation.Observed == true then
		daily.NativeDay, daily.DayIndex = context.NativeDay, dailyObservation.DayIndex
		daily.PossibleBenefit = nativeBenefit(nil)
		daily.PossibleBenefit.DeclaredStars = finite(dailyObservation.DeclaredStars) and dailyObservation.DeclaredStars or nil
		daily.PossibleBenefit.State = daily.PossibleBenefit.DeclaredStars ~= nil and "CLIENT_DISPLAY_ESTIMATE" or "UNKNOWN"
		daily.PossibleBenefit.AssociatedDailyCatalogGift = copy(dailyObservation.DeclaredReward)
		daily.PossibleBenefit.GiftGrantAssociation = "UNKNOWN"
		daily.ObservedReason = dailyObservation.Reason
		daily.ClaimState = dailyObservation.Claimed == true and dailyState.LastDay == context.NativeDay and "CLAIMED_CURRENT_NATIVE_DAY"
			or dailyObservation.Claimed == false and dailyState.LastDay == context.NativeDay and "EXPLICIT_UNCLAIMED" or "UNKNOWN"
		unknown(daily, "Daily catalog gift timing/association is separate from the stars-claim interface and remains unknown")
		if dailyObservation.Claimed == true and dailyObservation.State == "CLAIMED" then daily.Status = "CLAIMED"
		elseif dailyObservation.Locked == true or dailyObservation.State == "LOCKED" then
			daily.Status, daily.Eligibility, daily.Blocker = "LOCKED", "INELIGIBLE", dailyObservation.Reason or "Native daily eligibility blocked"
		elseif dailyObservation.Due == true and dailyObservation.Claimed == false then daily.Status, daily.Eligibility = "DUE", "CLIENT_ELIGIBLE"
		elseif dailyObservation.Due == false then daily.Status, daily.Eligibility = "AVAILABLE", "NOT_DUE"
		else unknown(daily, dailyObservation.Reason or "Daily native eligibility unresolved") end
	elseif dailyState.LastDay == context.NativeDay and dailyState.Claimed == true then
		daily.Status, daily.ClaimState = "CLAIMED", "CLAIMED_CURRENT_NATIVE_DAY"
	else
		daily.ClaimState = dailyState.Claimed == false and "EXPLICIT_UNCLAIMED_STATE" or "PRIOR_DAY_CLAIMED_STATE"
		unknown(daily, "Daily native rollover/streak observation unavailable; prior-day state is not a current claim authorization")
	end

	local wheel = row("FREE_WHEEL_TICKET", "TICKET", "Free wheel ticket")
	free(wheel) wheel.Requirements = { "Received NextWheelSpin deadline", "Native server time", "No unresolved native wheel queue" }
	wheel.PossibleBenefit = { State = "NATIVE_INTERFACE", Item = "Spin Ticket", Amount = "UNKNOWN", ActualGrant = "UNKNOWN", EarningGain = "UNKNOWN",
		Reason = "Collecting a due ticket is separate from consuming a ticket to spin or settling its reward queue" }
	if not finite(raw.NextWheelSpin) then unknown(wheel, "Received free-wheel deadline unavailable; missing does not mean due")
	elseif not finite(context.NativeNow) then unknown(wheel, "Native server time unavailable")
	elseif context.WheelQueuePending == true then wheel.Status, wheel.Eligibility = "PENDING", "BLOCKED_PENDING_RECEIPT"
	else
		wheel.DueAt, wheel.SecondsUntilDue = raw.NextWheelSpin, math.max(0, raw.NextWheelSpin - context.NativeNow)
		wheel.Status, wheel.Eligibility = wheel.SecondsUntilDue == 0 and "DUE" or "AVAILABLE", wheel.SecondsUntilDue == 0 and "CLIENT_TIME_ELIGIBLE" or "NOT_DUE"
		wheel.ClaimState = wheel.SecondsUntilDue == 0 and "DEADLINE_DUE_OBSERVED" or "NEXT_DEADLINE_OBSERVED"
		if context.WheelQueuePending == nil then unknown(wheel, "Native wheel queue/unfinished presentation observation unavailable") end
	end

	local worlds = catalogs.WorldRewards
	if type(worlds) ~= "table" or next(worlds) == nil then
		unavailable("PAID_WORLD_REWARD", "World Rewards", "Native WorldRewards catalog unavailable")
	else
		for _, name in ipairs(keys(worlds)) do
			if type(name) ~= "string" then continue end
			local definition, received = worlds[name], type(raw.WorldRewards) == "table" and raw.WorldRewards[name]
			local result = row("PAID_WORLD_REWARD", name, name .. " World Reward") result.World = name
			result.Requirements = { "Exact received sequential Progress", "WorldsUnlocked[world] == true", "Native next-tier price", "Protected currency reserves", "Native pet storage guard if applicable" }
			result.InterruptsMastery = report.MasteryPriority == "INCOMPLETE" and "YES" or "UNKNOWN"
			result.PolicyDeferral = report.MasteryPriority == "INCOMPLETE" and "DEFER_BEHIND_OBTAINABLE_PERMANENT_MASTERY" or "SEPARATE_PAID_PROGRESSION_REVIEW"
			unknown(result, "Paid progression; no purchase authorization; server proximity/grant and marginal earning benefit unknown")
			local worldObservation = context.WorldRewardObservations and context.WorldRewardObservations[name]
			if type(worldObservation) == "table" and worldObservation.Removed == true then
				result.Status, result.Eligibility, result.Blocker = "LOCKED", "INELIGIBLE", "Current native world definition is Removed; retained reward catalog is not an available world"
				continue
			end
			if type(worldObservation) ~= "table" or worldObservation.WorldDefinitionState ~= "OBSERVED" then
				unknown(result, "Current native world definition is unavailable; retained paid reward catalog does not establish world availability")
				continue
			elseif worldObservation.WorldActivity ~= "PERMANENT_CATALOG_DEFINITION" then
				unknown(result, "Current native event-world activity is unverified; retained catalog and unlock data alone do not establish an available event reward")
				continue
			end
			if type(definition) ~= "table" or type(definition.Levels) ~= "table" then unknown(result, "Native sequential World Reward levels unavailable") continue end
			if type(received) ~= "table" or not integer(received.Progress) then unknown(result, "Received World Reward Progress unavailable; missing is not tier zero or unclaimed") continue end
			result.CompletedTiers, result.NextTier = received.Progress, received.Progress + 1
			local maximum, dense, expectedIndex = 0, true, 1
			for _, index in ipairs(keys(definition.Levels)) do
				if integer(index) and index >= 1 and index == expectedIndex and type(definition.Levels[index]) == "table" then
					maximum, expectedIndex = index, expectedIndex + 1
				else dense = false end
			end
			if not dense or maximum == 0 or received.Progress > maximum then unknown(result, "World Reward levels are sparse, malformed or inconsistent with received Progress") continue end
			if received.Progress == maximum then result.Status, result.ClaimState = "CLAIMED", "ALL_NATIVE_SEQUENTIAL_TIERS_RECEIVED" continue end
			result.ClaimState = "NEXT_SEQUENTIAL_TIER_UNRECEIVED"
			local nextTier = definition.Levels[result.NextTier]
			result.Cost, result.PossibleBenefit = currencyCost(nextTier.Cost), nativeBenefit(nextTier.Reward)
			result.Affordability, result.Balance, result.Reserve, result.Shortage = affordability(config, raw, result.Cost)
			if not result.Cost then result.Cost = { State = "UNKNOWN" } unknown(result, "Native fixed next-tier currency price unavailable") end
			if type(raw.WorldsUnlocked) ~= "table" then unknown(result, "Received world access map unavailable")
			elseif raw.WorldsUnlocked[name] ~= true then result.Status, result.Eligibility, result.Blocker = "LOCKED", "INELIGIBLE", "Native World Rewards requires an explicit true world unlock"
			elseif result.Affordability == "INSUFFICIENT" then result.Status, result.Eligibility, result.Blocker = "LOCKED", "UNAFFORDABLE", "Next native price exceeds funds after explicit reserve"
			elseif result.Affordability == "UNKNOWN" then unknown(result, "Relevant currency balance or explicit reserve unavailable")
			else
				local reward = nextTier.Reward
				local observed = context.WorldRewardObservations and context.WorldRewardObservations[name]
				local storageEligible = type(observed) == "table" and observed.StorageEligible
				if type(reward) == "table" and reward.Type == "Pet" and storageEligible ~= true then
					if storageEligible == false then result.Status, result.Eligibility, result.Blocker = "LOCKED", "INELIGIBLE", "Observed native pet storage guard blocks reward"
					else unknown(result, "Native reward pet-space eligibility unavailable") end
				else result.Status, result.Eligibility = "AVAILABLE", "CLIENT_REVIEW_ELIGIBLE" end
			end
		end
	end

	local chests = catalogs.Chests
	if type(chests) ~= "table" or next(chests) == nil then
		unavailable("CHEST", "Chest rewards", "Native chest catalog unavailable; retained catalog does not establish spawned availability")
	else
		for _, name in ipairs(keys(chests)) do
			if type(name) ~= "string" then continue end
			local definition = chests[name]
			local result = row("CHEST", name, name) free(result)
			result.PossibleBenefit = nativeBenefit(type(definition) == "table" and definition.Reward)
			result.PossibleBenefit.Pool = type(definition) == "table" and copy(definition.Pool) or nil
			result.Requirements = { "Actual loaded native chest", "Received area access", "Received exact Cooldowns deadline", "Verified physical or mastery-gated map interaction" }
			local observation = context.ChestObservations and context.ChestObservations[name]
			if type(observation) == "table" then result.Loaded, result.Access = observation.Loaded, observation.Access end
			local deadline = type(raw.Cooldowns) == "table" and raw.Cooldowns[name]
			if not finite(deadline) then unknown(result, "Received exact chest cooldown unavailable; missing does not mean unclaimed or due")
			elseif not finite(context.NativeNow) then unknown(result, "Native server time unavailable")
			else
				result.DueAt, result.SecondsUntilDue = deadline, math.max(0, deadline - context.NativeNow)
				result.ClaimState = "RECEIVED_COOLDOWN_OBSERVED"
				result.Status = result.SecondsUntilDue == 0 and "DUE" or "AVAILABLE"
				result.Eligibility = result.Status == "DUE" and "UNKNOWN" or "NOT_DUE"
			end
			if result.Access == false then result.Status, result.Eligibility, result.Blocker = "LOCKED", "INELIGIBLE", "Actual native chest area access is locked"
			elseif result.Access ~= true then unknown(result, "Native chest access is unavailable") end
			if result.Loaded ~= true then unknown(result, "Actual native chest is not observed loaded; catalog presence is not availability") end
			unknown(result, "Exact native chest interaction, composite/scaled reward and interrupted travel time are unverified")
		end
	end

	if type(raw.Quests) ~= "table" then
		unavailable("QUEST", "Received quests", "Received quest collection unavailable; no claim or completion is inferred")
	else
		if next(raw.Quests) == nil then unavailable("QUEST", "Received quests", "Received quest collection is empty; inactive/historical quests are not invented") end
		for _, index in ipairs(keys(raw.Quests)) do
			local quest = raw.Quests[index]
			if type(quest) ~= "table" or type(quest.Id) ~= "string" then
				unavailable("QUEST", "Malformed received quest", "Received quest identity/shape is unavailable") continue
			end
			local result = row("QUEST", quest.Id, quest.DisplayName or quest.Id)
			result.QuestId, result.PossibleBenefit = quest.Id, nativeBenefit(quest.Rewards)
			result.Requirements = { "Exact received task/filter progress", "Native task requirement and completion observations", "Received completed state and actual grant" }
			result.Cost = { Type = "ACTIVITY", State = "UNKNOWN", Reason = "Task costs, time and any required spending remain distinct from the reward" }
			local observation = context.QuestObservations and context.QuestObservations[quest.Id]
			result.Tasks = type(observation) == "table" and copy(observation.Tasks) or nil
			local completed = type(raw.QuestsCompleted) == "table" and raw.QuestsCompleted[quest.Id]
			if completed ~= nil then result.CompletionHistory = copy(completed) end
			if type(quest.Tasks) ~= "table" or next(quest.Tasks) == nil or type(quest.Progress) ~= "table" then
				unknown(result, "Exact received quest tasks/progress unavailable; empty or missing tasks are not a completed reward")
			elseif type(observation) ~= "table" or type(observation.Complete) ~= "boolean" then unknown(result, "Native exact task completion observation unavailable")
			elseif observation.Complete then result.Status, result.Eligibility = "DUE", "COMPLETION_OBSERVED_GRANT_UNKNOWN"
			else result.Status, result.Eligibility = "AVAILABLE", "TASKS_INCOMPLETE" end
			unknown(result, "Ordinary quests have no established generic claim interface; completion/history does not prove the current reward was credited")
		end
	end

	local prizes = type(catalogs.Prizes) == "table" and catalogs.Prizes.data
	if type(prizes) ~= "table" or next(prizes) == nil then
		unavailable("ACHIEVEMENT_PRIZE", "Achievement prizes", "Native Prizes.data catalog unavailable")
	else
		for _, index in ipairs(keys(prizes)) do
			local definition = prizes[index]
			if type(definition) ~= "table" or type(definition.Key) ~= "string" then
				unavailable("ACHIEVEMENT_PRIZE", "Malformed prize", "Native prize Key unavailable") continue
			end
			local result = row("ACHIEVEMENT_PRIZE", definition.Key, definition.Key) free(result)
			result.PossibleBenefit = nativeBenefit(definition.Reward)
			result.Requirements = { "Received ClaimedPrizes map", "Native key-specific requirement/progress", "Native prize eligibility and eventual grant" }
			if type(raw.ClaimedPrizes) ~= "table" then unknown(result, "Received prize claim map unavailable; missing is not unclaimed")
			elseif raw.ClaimedPrizes[definition.Key] ~= nil then result.Status, result.ClaimState = "CLAIMED", "CLAIMED_KEY_PRESENT"
			elseif not stringKeyMap(raw.ClaimedPrizes) then unknown(result, "Received prize claim map has non-native keys; no unclaimed state is inferred")
			else
				result.ClaimState = "UNCLAIMED_IN_RECEIVED_MAP"
				local observation = context.PrizeObservations and context.PrizeObservations[definition.Key]
				if type(observation) ~= "table" or type(observation.Complete) ~= "boolean" then unknown(result, "Native key-specific prize completion observation unavailable")
				else
					result.Required, result.Current = observation.Required, observation.Progress
					result.Status, result.Eligibility = observation.Complete and "DUE" or "LOCKED", observation.Complete and "CLIENT_ELIGIBLE" or "REQUIREMENT_INCOMPLETE"
				end
			end
		end
	end

	local inventory = context.InventoryObservations
	if type(inventory) ~= "table" or type(inventory.Items) ~= "table" then
		unavailable("CONSUMABLE", "Owned consumables", "Native current inventory schema/quantity observations unavailable; historical nested potion shapes are not assumed")
	else
		if inventory.SchemaState ~= "OBSERVED" then
			unavailable("CONSUMABLE", "Inventory schema", "Current native inventory normalization is partial or unknown; unsupported records are not treated as usable stock")
		end
		if type(raw.Powerups) ~= "table" then unavailable("CONSUMABLE", "Powerups", "Received Powerups inventory unavailable") end
		if type(raw.Potions) ~= "table" then unavailable("CONSUMABLE", "Potions", "Received Potions inventory unavailable") end
		for _, index in ipairs(keys(inventory.Items)) do
			local item = inventory.Items[index]
			if type(item) ~= "table" or type(item.Name) ~= "string" or item.Name == ""
				or item.Type ~= "Powerup" and item.Type ~= "Potion" then
				unavailable("CONSUMABLE", "Malformed inventory observation", "Native item identity/quantity interface unavailable") continue
			end
			local category = item.Type == "Potion" and "Potions" or "Powerups"
			local result = row("CONSUMABLE", category .. ":" .. item.Name .. ":" .. tostring(item.Level or "none"),
				item.Name .. (item.Type == "Potion" and (item.Level ~= nil and " level " .. tostring(item.Level) or " (native level unspecified)") or ""))
			result.InventoryCategory, result.ItemName, result.Level = category, item.Name, item.Level
			result.Cost = { Type = "CONSUMPTION", State = "OWNED_ITEM_OPPORTUNITY_COST", Item = item.Name, Amount = "UNKNOWN" }
			result.ClaimState = "NOT_A_FREE_CLAIM"
			result.PossibleBenefit = nativeBenefit(item.Definition)
			result.Requirements = { "Known received stock and native ItemUtil quantity", "Native item-use eligibility and activity-specific need", "Separate consumption authorization" }
			result.InterruptsMastery = "UNKNOWN"
			result.PolicyDeferral = "CONSUMPTION_COMPATIBILITY_AND_SEPARATE_AUTHORIZATION_REQUIRED"
			if type(raw[category]) ~= "table" or item.QuantityStatus ~= "OBSERVED" or not integer(item.Owned)
				or type(item.Definition) ~= "table" or item.Type == "Potion" and item.Level ~= nil and (not integer(item.Level) or item.Level < 1) then
				unknown(result, item.Reason or "Received current item schema, native definition or owned amount is unavailable")
			else
				result.Owned = item.Owned
				if item.Owned > 0 then result.Status, result.Eligibility = "AVAILABLE", "STOCK_OBSERVED_USE_UNKNOWN"
				else result.Status, result.Eligibility = "LOCKED", "NO_OWNED_STOCK" end
			end
			unknown(result, "Inventory is not a due reward; consumption, reserves, effects and marginal benefit require separate scope")
		end
		if next(inventory.Items) == nil then unavailable("CONSUMABLE", "Owned consumables", "No normalized owned item observations; missing native quantities are not fabricated") end
	end

	local challenge, receivedChallenge = context.ChallengeObservation, raw.ChallengePass
	local challengeCatalog = catalogs.ChallengePass
	local challengeRewards = type(receivedChallenge) == "table" and receivedChallenge.Rewards
	if type(challenge) ~= "table" or type(challengeRewards) ~= "table" or next(challengeRewards) == nil then
		local result = unavailable("CHALLENGE_PASS", "Challenge pass", "Received current challenge reward track or native identity/deadline observation unavailable")
		local deadline = type(challenge) == "table" and (challenge.Deadline or challenge.ExpiryUnix)
		if type(challenge) == "table" and challenge.Expired == true and finite(deadline) and finite(context.NativeNow) and context.NativeNow >= deadline then
			result.Status, result.Eligibility, result.ExpiresAt = "EXPIRED", "INELIGIBLE", deadline
		end
	else
		for _, tier in ipairs(keys(challengeRewards)) do
			if not integer(tier) or tier < 1 then continue end
			local result = row("CHALLENGE_PASS", tier, "Challenge pass tier " .. tostring(tier)) free(result)
			result.Tier, result.PossibleBenefit = tier, nativeBenefit(challengeRewards[tier])
			result.Requirements = { "Current native challenge catalog identity and deadline", "Received reward track and claimed value membership", "Native point threshold", "Native grant/storage guard" }
			local deadline = challenge.Deadline or challenge.ExpiryUnix
			if finite(deadline) then result.ExpiresAt = deadline end
			local claimedMap = receivedChallenge.Claimed
			if type(claimedMap) == "table" then
				local claimed = false
				for _, value in pairs(claimedMap) do if value == tier then claimed = true break end end
				result.ClaimState = claimed and "CLAIMED_VALUE_PRESENT" or "UNCLAIMED_IN_RECEIVED_VALUES"
				if claimed then result.Status = "CLAIMED"
				elseif not nativeTierValues(claimedMap) then result.ClaimState = "UNKNOWN" unknown(result, "Received challenge claim values have an unsupported native array schema") end
			else unknown(result, "Received challenge claim values unavailable; missing is not unclaimed") end
			if challenge.Expired == true and finite(deadline) and finite(context.NativeNow) and context.NativeNow >= deadline then
				result.PreExpiryStatus, result.Status, result.Eligibility = result.Status, "EXPIRED", "INELIGIBLE"
			elseif challenge.State ~= "ACTIVE" or challenge.Expired ~= false or not finite(deadline) or not finite(context.NativeNow)
				or context.NativeNow >= deadline or type(challenge.Id) ~= "string" then unknown(result, "Current active native pass identity/deadline unavailable")
			elseif result.Status ~= "CLAIMED" and nativeTierValues(claimedMap) then
				if type(challengeCatalog) ~= "table" or not integer(challengeCatalog.FinalTier) or tier > challengeCatalog.FinalTier
					or not finite(receivedChallenge.Points) or not integer(challenge.EligibleTier) then unknown(result, "Native final tier or received point eligibility unavailable")
				elseif challenge.EligibleTier >= tier then result.Status, result.Eligibility = "DUE", "CLIENT_PROGRESS_ELIGIBLE"
				else result.Status, result.Eligibility = "LOCKED", "POINT_REQUIREMENT_INCOMPLETE" end
			end
			unknown(result, "Track/reset persistence, premium entitlements, native storage/grant and final reward scaling remain unverified; resets/skips are separate")
		end
	end

	for _, family in ipairs({ "SEASON_PASS", "INDEX", "MILESTONE" }) do
		local observation = context.AdditionalObservations and context.AdditionalObservations[family]
		local result = row(family, "OBSERVATION", family)
		if type(observation) == "table" and observation.Expired == true and finite(observation.Deadline)
			and finite(context.NativeNow) and context.NativeNow >= observation.Deadline then
			result.Status, result.Eligibility, result.ExpiresAt = "EXPIRED", "INELIGIBLE", observation.Deadline
			result.Evidence = observation.Evidence
		else unknown(result, "Current exact track/group eligibility, received claimed state and grant contract require separately scoped normalization") end
	end

	local pending = context.PendingObservation
	local pendingItem = type(pending) == "table" and pending.Pending
	local barrier = type(pendingItem) == "table" or type(pending) == "table" and pending.AttributionBlocked == true or context.WheelQueuePending == true
	if type(pendingItem) == "table" then
		local family = pendingItem.Kind == "PLAYTIME" and "FREE_PLAYTIME" or pendingItem.Kind == "MYSTERY_BOX" and "CONSUMABLE" or nil
		local matched = false
		for _, result in ipairs(report.Rows) do
			if family and result.Family == family and (family ~= "FREE_PLAYTIME" or result.Index == pendingItem.Index) then
				result.PrePendingStatus, result.Status, result.Eligibility = result.Status, "PENDING", "BLOCKED_PENDING_RECEIPT"
				result.PendingStatus = pendingItem.Status or "UNKNOWN" unknown(result, "Retained unresolved operation; elapsed timeout is not proof of rejection or permission to retry")
				matched = true
			end
		end
		if not matched then
			local result = row("PENDING_RECEIPT", "RETAINED", "Retained reward operation")
			result.Status, result.Eligibility, result.PendingStatus = "PENDING", "BLOCKED_PENDING_RECEIPT", pendingItem.Status or "UNKNOWN"
			unknown(result, "Exact retained operation cannot be reconciled with this report; do not retry or infer expiry")
		end
	end
	if omitted > 0 then report.OmittedRows = omitted table.insert(report.Unknowns, "Report row bound reached; omitted candidates are not evaluated as ineligible or complete") end
	report.PendingBarrier = barrier
	report.Status = "READ_ONLY_REPORT"
	if barrier then
		report.Recommendation = { Kind = "OBSERVE_PENDING", Reason = "Retained or unresolved reward receipt/attribution barrier; no claim, consumption or automatic retry",
			ExecutionAuthorized = false, ActionAuthorization = "NONE" }
	else
		local candidate
		for _, result in ipairs(report.Rows) do
			if result.Status == "DUE" and result.Family ~= "QUEST" and result.Eligibility ~= "INELIGIBLE" then candidate = result break end
		end
		if candidate then
			report.Recommendation = { Kind = "REWARD_REVIEW", RowKey = candidate.Key, Family = candidate.Family,
				Reason = "Review observed due reward facts; preserve permanent Mastery priority until setup/presentation interruption is established; separate action approval is required",
				Status = candidate.Status, Eligibility = candidate.Eligibility, ClaimState = candidate.ClaimState, Cost = copy(candidate.Cost),
				Requirements = copy(candidate.Requirements), PossibleBenefit = copy(candidate.PossibleBenefit), Unknowns = copy(candidate.Unknowns),
				InterruptsMastery = "UNKNOWN", MasteryPriority = report.MasteryPriority, ExecutionAuthorized = false, ActionAuthorization = "NONE" }
		elseif report.MasteryPriority == "INCOMPLETE" then
			report.Recommendation = { Kind = "PRESERVE_MASTERY_PRIORITY", Reason = "Continue advisory permanent Mastery progression review; paid rewards and consumable use do not supersede it",
				ExecutionAuthorized = false, ActionAuthorization = "NONE" }
		else
			report.Recommendation = { Kind = "WAIT", Reason = "No confirmed due free reward with enough observed facts; paid rewards, quests and consumables remain separate read-only reviews",
				ExecutionAuthorized = false, ActionAuthorization = "NONE" }
		end
	end
	return report
end

function RewardPolicy.Format(report)
	local recommendation = report.Recommendation or {}
	local counts = {}
	for _, result in ipairs(report.Rows or {}) do counts[result.Status] = (counts[result.Status] or 0) + 1 end
	local parts = { "READ_ONLY | " .. tostring(report.Status), tostring(recommendation.Kind or "WAIT"),
		"rows=" .. tostring(#(report.Rows or {})), "Mastery priority=" .. tostring(report.MasteryPriority or "UNKNOWN") }
	for _, status in ipairs({ "DUE", "AVAILABLE", "LOCKED", "CLAIMED", "EXPIRED", "PENDING", "UNKNOWN" }) do
		if counts[status] then table.insert(parts, status .. "=" .. tostring(counts[status])) end
	end
	if recommendation.RowKey then table.insert(parts, "review=" .. recommendation.RowKey) end
	if recommendation.Eligibility then table.insert(parts, "status=" .. tostring(recommendation.Status or "UNKNOWN") .. "; eligibility=" .. recommendation.Eligibility .. "; Mastery interruption=" .. tostring(recommendation.InterruptsMastery or "UNKNOWN")) end
	local cost = recommendation.Cost
	if cost then
		if cost.Type == "Currency" then table.insert(parts, "cost=" .. tostring(cost.Amount) .. " " .. tostring(cost.Currency))
		elseif cost.Type == "FREE" then table.insert(parts, "cost=FREE native interface (0); setup/presentation UNKNOWN")
		else table.insert(parts, "cost=" .. tostring(cost.Type or cost.State or "UNKNOWN")) end
	end
	if recommendation.PossibleBenefit then table.insert(parts, "possible benefit=" .. tostring(recommendation.PossibleBenefit.State or "UNKNOWN") .. "; actual grant/earning gain UNKNOWN") end
	if recommendation.Requirements and #recommendation.Requirements > 0 then
		local requirements = {}
		for index, requirement in ipairs(recommendation.Requirements) do if index > 2 then break end table.insert(requirements, requirement) end
		table.insert(parts, "requires=" .. table.concat(requirements, "; "))
	end
	table.insert(parts, recommendation.Reason or "Reward evidence UNKNOWN")
	if recommendation.Unknowns and recommendation.Unknowns[1] then table.insert(parts, recommendation.Unknowns[1]) end
	if report.Unknowns and #report.Unknowns > 0 then table.insert(parts, table.concat(report.Unknowns, "; ")) end
	table.insert(parts, "claims/consumption/movement/spending OFF; receipt and marginal benefit unverified")
	return table.concat(parts, " | ")
end

return RewardPolicy

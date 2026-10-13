--!nonstrict
-- Pure Phase 5 recommendations. This module owns no task or gameplay action.
local MasteryPolicy = {}

local function finite(value)
	return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

local function integer(value)
	return finite(value) and value % 1 == 0
end

local function copy(value, seen)
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local result = {} seen[value] = result
	for key, entry in pairs(value) do result[key] = copy(entry, seen) end
	return result
end

local function price(value)
	if type(value) ~= "table" or value.Type ~= "Currency" or type(value.Currency) ~= "string"
		or value.Currency == "" or not finite(value.Amount) then return nil end
	return { Type = "Currency", Currency = value.Currency, Amount = value.Amount }
end

local reserveFields = { Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" }

local function affordability(config, balances, cost)
	if not cost then return "UNKNOWN", nil, nil, nil end
	local balance = type(balances) == "table" and balances[cost.Currency]
	local field = reserveFields[cost.Currency]
	local reserve = field and config.RESOURCE_SETTINGS and config.RESOURCE_SETTINGS[field]
	if not finite(balance) or not finite(reserve) then return "UNKNOWN", finite(balance) and balance or nil, nil, nil end
	local available = math.max(0, balance - reserve)
	local shortage = math.max(0, cost.Amount - available)
	return shortage == 0 and "AFFORDABLE" or "INSUFFICIENT", balance, shortage, reserve
end

local function funding(row, settings, context)
	if not finite(row.Shortage) then return end
	local rate = context.StationaryRate or context.Rate
	local now = context.ObservedAt
	local perMinute = type(rate) == "table" and rate.PerMinute
	if type(perMinute) == "table" then perMinute = perMinute[row.Currency] end
	if type(rate) ~= "table" or rate.ScopeVerified ~= true or rate.Ready ~= true
		or rate.Currency ~= row.Currency or (row.Currency ~= "Coins" and row.Currency ~= "Gems")
		or not finite(rate.Seconds) or not finite(settings.MINIMUM_RATE_SAMPLE_SECONDS)
		or rate.Seconds < settings.MINIMUM_RATE_SAMPLE_SECONDS or not finite(rate.LastAt)
		or not finite(now) or rate.LastAt > now or not finite(settings.MAXIMUM_RATE_AGE_SECONDS)
		or now - rate.LastAt > settings.MAXIMUM_RATE_AGE_SECONDS or not finite(perMinute) then return end
	row.ObservedPerMinute = perMinute
	row.FundingEvidence = "Observed stationary balance sample; unchanged-rate extrapolation; external credits may contribute"
	if perMinute > 0 then
		local seconds = row.Shortage / perMinute * 60
		if finite(seconds) then row.FundingETASeconds = seconds end
	elseif row.Shortage > 0 then row.FundingBlocker = "No positive income in the qualified stationary sample" end
end

local function observedPrice(context, name, index, tier, nextTier)
	local observations = context.TierObservations and context.TierObservations[name]
	local observed = observations and observations[index]
	if not observed and index == nextTier then observed = context.CategoryObservations and context.CategoryObservations[name] end
	if observed then
		if observed.PriceStatus ~= "OBSERVED" then return nil, "Native tier price is unavailable" end
		return price(observed.NativePrice), "Observed native tier price/early-unlock predicate"
	end
	-- A future entitlement predicate cannot be assumed false, and a price
	-- function cannot be executed by this pure policy.
	if type(tier) ~= "table" or tier.UnlockEarly ~= nil then return nil, "Future early-unlock price is unverified" end
	return price(tier.Cost), "Native fixed catalog price"
end

local function category(config, snapshot, context, name, definition, order)
	local row = { Name = name, Category = name, Order = order, Status = "UNKNOWN", Blockers = {},
		CompletedTiers = {}, ExpectedIncomeGain = "UNKNOWN", Effects = {},
		RemainingPackage = { Status = "UNKNOWN", Costs = {}, Unknowns = {} } }
	local observed = context.CategoryObservations and context.CategoryObservations[name]
	row.Visibility = observed and observed.Visibility or "UNKNOWN"
	row.VisibilityReason = observed and observed.VisibilityReason or "Native category visibility unavailable"
	row.Permanence = observed and observed.Permanence or "UNKNOWN"
	row.PermanenceEvidence = observed and observed.PermanenceEvidence or "Permanent category classification unavailable"
	row.PhysicalEligibility = "UNKNOWN"
	row.TradingPlazaStatus = context.TradingPlazaStatus or "UNKNOWN"
	row.EffectiveUpgrades = copy(context.EffectiveUpgrades or snapshot.Upgrades and snapshot.Upgrades.MasteryUpgrades)
	row.EffectiveUpgradeState = type(row.EffectiveUpgrades) == "table" and "RECEIVED" or "UNKNOWN"
	local received = snapshot.Upgrades and snapshot.Upgrades.MasteryLevels and snapshot.Upgrades.MasteryLevels[name]
	row.CurrentTier = integer(received) and received or nil
	if row.Visibility == "LOCKED" then
		-- Locked is not complete. Still report consistent received progress when
		-- its native tier sequence can be established without guessing.
		if type(definition) == "table" and type(definition.Levels) == "table" then
			local count, maximum, valid = 0, 0, true
			for index, tier in pairs(definition.Levels) do
				if not integer(index) or index < 1 or type(tier) ~= "table" then valid = false break end
				count, maximum = count + 1, math.max(maximum, index)
			end
			if valid and count > 0 and count == maximum and row.CurrentTier and row.CurrentTier <= maximum then
				row.MaximumTier = maximum
				for index = 1, row.CurrentTier do table.insert(row.CompletedTiers, index) end
				row.NextTier = row.CurrentTier < maximum and row.CurrentTier + 1 or nil
				row.CompletionObserved = row.CurrentTier == maximum
			end
		end
		row.Status = "LOCKED" table.insert(row.Blockers, row.VisibilityReason) return row
	end
	if type(definition) ~= "table" or type(definition.Levels) ~= "table" then
		table.insert(row.Blockers, "Native category tier definitions unavailable") return row
	end
	if row.Visibility ~= "VISIBLE" then table.insert(row.Blockers, row.VisibilityReason) return row end
	if row.Permanence ~= "VERIFIED_PERMANENT" then table.insert(row.Blockers, row.PermanenceEvidence) return row end
	local maximum, count = 0, 0
	for index, tier in pairs(definition.Levels) do
		if not integer(index) or index < 1 or type(tier) ~= "table" then
			table.insert(row.Blockers, "Malformed native tier index or definition") return row
		end
		maximum, count = math.max(maximum, index), count + 1
	end
	if maximum == 0 or count ~= maximum then
		table.insert(row.Blockers, "Native tier catalog is empty or sparse; completion and sequential prerequisites are UNKNOWN") return row
	end
	row.MaximumTier = maximum
	local current = snapshot.Upgrades and snapshot.Upgrades.MasteryLevels and snapshot.Upgrades.MasteryLevels[name]
	if not integer(current) or current > maximum then
		table.insert(row.Blockers, "Received Mastery level is absent, invalid or inconsistent with the native catalog") return row
	end
	row.CurrentTier = current
	for index = 1, current do table.insert(row.CompletedTiers, index) end
	if current == maximum then
		row.Status = "COMPLETE" row.CompletionObserved = true row.RemainingPackage.Status = "COMPLETE" return row
	end
	row.NextTier = current + 1
	row.Requirements = { "Complete tiers sequentially through " .. tostring(current), "Native category visibility", "Outer Space Mastery HUD access", "Fresh account and native price" }
	table.insert(row.Requirements, "Observe native not-Trading-Plaza HUD condition; advisory review is not purchase eligibility")
	if row.TradingPlazaStatus == "UNKNOWN" then
		table.insert(row.Blockers, "Native Trading Plaza condition UNKNOWN; full HUD/purchase eligibility remains unverified")
	end
	local tier = definition.Levels[row.NextTier]
	row.Effects = copy(type(tier.Upgrades) == "table" and tier.Upgrades or {})
	row.BenefitEvidence = type(tier.Upgrades) == "table" and "Native declared next-tier effects; received effective upgrades remain separate; earning gain UNKNOWN" or "Native next-tier effects UNKNOWN"
	row.NextPrice, row.PriceEvidence = observedPrice(context, name, row.NextTier, tier, row.NextTier)
	row.RemainingPackage.Status = "OBSERVED"
	for index = row.NextTier, maximum do
		local cost = observedPrice(context, name, index, definition.Levels[index], row.NextTier)
		if cost then
			row.RemainingPackage.Costs[cost.Currency] = (row.RemainingPackage.Costs[cost.Currency] or 0) + cost.Amount
			if not finite(row.RemainingPackage.Costs[cost.Currency]) then
				row.RemainingPackage.Status = "UNKNOWN" table.insert(row.RemainingPackage.Unknowns, "Package total is not finite")
			end
		else
			row.RemainingPackage.Status = "UNKNOWN" table.insert(row.RemainingPackage.Unknowns, "Tier " .. tostring(index) .. " price UNKNOWN")
		end
	end
	row.RemainingPackage.Assumption = "Current native prices/entitlements; re-evaluate after each received tier or account change; currencies remain separate"
	if not row.NextPrice then table.insert(row.Blockers, "Next sequential native price UNKNOWN") return row end
	row.Currency, row.Amount = row.NextPrice.Currency, row.NextPrice.Amount
	local balances = context.Balances or snapshot.Balances
	row.Affordability, row.Balance, row.Shortage, row.Reserve = affordability(config, balances, row.NextPrice)
	if row.Affordability == "UNKNOWN" then table.insert(row.Blockers, "Actual currency balance or explicit reserve policy unavailable") end
	local access = context.Access and context.Access.Visibility or "UNKNOWN"
	row.Access = access
	if access ~= "VISIBLE" then
		row.Status = access == "LOCKED" and "PREREQUISITE" or "UNKNOWN"
		table.insert(row.Blockers, context.Access and context.Access.Reason or "Mastery HUD access UNKNOWN") return row
	end
	if row.Affordability == "UNKNOWN" then return row end
	row.Status = row.Affordability == "AFFORDABLE" and "REVIEW" or "FUNDING"
	if row.Status == "FUNDING" then table.insert(row.Blockers, "Earn the remaining native currency without changing configured reserves") end
	funding(row, config.MASTERY_SETTINGS, context)
	return row
end

local function worldGate(config, snapshot, context)
	local node = context.WorldGate
	if not node and snapshot.ProgressionGraph and snapshot.ProgressionGraph.Next
		and snapshot.ProgressionGraph.Next.Kind == "WORLD" then node = snapshot.ProgressionGraph.Next end
	if not node then
		local candidates = {}
		for _, world in pairs(snapshot.AvailableProgression and snapshot.AvailableProgression.Worlds or {}) do
			if type(world) == "table" and type(world.Name) == "string" and world.Selected == true
				and snapshot.UnlockedWorlds and snapshot.UnlockedWorlds[world.Name] == nil then table.insert(candidates, world) end
		end
		table.sort(candidates, function(a, b)
			local left, right = finite(a.Order) and a.Order or math.huge, finite(b.Order) and b.Order or math.huge
			return left == right and a.Name < b.Name or left < right
		end)
		node = candidates[1]
	end
	if not node then return { Status = "UNKNOWN", Reason = "Next paid world gate is unavailable from current native observations" } end
	local result = { Status = "UNKNOWN", Name = node.Name or node.World, Price = price(node.Cost or node.Price), Blockers = {},
		ActionAuthorization = "NONE", Prerequisites = copy(node.Prerequisites or {}) }
	if not result.Price or result.Price.Amount <= 0 then result.Reason = "Next paid world cost UNKNOWN or not a paid gate" return result end
	result.Currency, result.Amount = result.Price.Currency, result.Price.Amount
	result.Affordability, result.Balance, result.Shortage, result.Reserve = affordability(config, context.Balances or snapshot.Balances, result.Price)
	result.Status = "DEFERRED_FOR_MASTERY_REVIEW"
	result.Reason = "Read-only native world gate projection; no purchase, claim or reserve override"
	return result
end

local function recommendation(row)
	local kinds = { REVIEW = "MASTERY_REVIEW", FUNDING = "MASTERY_FUNDING", PREREQUISITE = "MASTERY_PREREQUISITE" }
	return { Kind = kinds[row.Status] or "WAIT", Category = row.Name, Tier = row.NextTier,
		Price = copy(row.NextPrice), Currency = row.Currency, Amount = row.Amount, Balance = row.Balance,
		Shortage = row.Shortage, Affordability = row.Affordability or "UNKNOWN", Reserve = row.Reserve,
		Effects = copy(row.Effects), ExpectedIncomeGain = "UNKNOWN", FundingETASeconds = row.FundingETASeconds,
		Reason = row.Status == "REVIEW" and "Review the next obtainable permanent Mastery tier before the next paid world unlock; configured category order, no claim of optimal ROI"
			or row.Status == "FUNDING" and "Fund the next sequential permanent Mastery tier before the next paid world unlock; stationary income is used only when qualified"
			or row.Status == "PREREQUISITE" and "Resolve observed Mastery access before reviewing this sequential tier; no travel is authorized"
			or "Resolve unavailable Mastery evidence before declaring permanent progression complete",
		Blockers = copy(row.Blockers), Requirements = copy(row.Requirements or {}), ActionAuthorization = "NONE" }
end

function MasteryPolicy.Analyze(config, snapshot, context)
	context, snapshot = context or {}, snapshot or {}
	local settings = config.MASTERY_SETTINGS or {}
	local report = { ReadOnly = true, ActionAuthorization = "NONE", Status = "UNKNOWN", Categories = {}, Unknowns = {},
		Access = copy(context.Access or { Visibility = "UNKNOWN", PhysicalEligibility = "UNKNOWN", ServerEligibility = "UNKNOWN" }),
		TradingPlazaStatus = context.TradingPlazaStatus or "UNKNOWN",
		Recommendation = { Kind = "WAIT", Reason = "Mastery evidence UNKNOWN", Blockers = {}, ActionAuthorization = "NONE" },
		Policy = "Complete currently obtainable permanent Mastery tiers before the next paid world unlock; sequential native tiers, independent currencies and explicit reserves; no automatic action" }
	if settings.ENABLE_MASTERY_INTELLIGENCE ~= true then
		report.Status = "DISABLED" report.Recommendation.Reason = "Read-only Mastery intelligence is disabled" return report
	end
	local now, readAt = context.ObservedAt, snapshot.ReadAt
	if snapshot.Ready ~= true or context.Fresh ~= true or not finite(now) or not finite(readAt) or readAt > now
		or not finite(settings.MAXIMUM_ACCOUNT_AGE_SECONDS) or now - readAt > settings.MAXIMUM_ACCOUNT_AGE_SECONDS then
		table.insert(report.Unknowns, context.Blocker or "Account/native observation is unavailable, stale or inconsistent")
		report.Recommendation.Blockers = copy(report.Unknowns) return report
	end
	if type(context.Catalog) ~= "table" or next(context.Catalog) == nil then
		table.insert(report.Unknowns, "Native Mastery.Upgrades catalog unavailable") report.Recommendation.Blockers = copy(report.Unknowns) return report
	end
	local priorities = {}
	for index, name in ipairs(settings.CATEGORY_ORDER or config.BRAIN_SETTINGS and config.BRAIN_SETTINGS.MASTERY_PRIORITIES or {}) do priorities[name] = index end
	local names = {} for name in pairs(context.Catalog) do
		if type(name) == "string" then table.insert(names, name) else table.insert(report.Unknowns, "Native category identifier is malformed") end
	end
	table.sort(names)
	local selectable, unresolved, eligible = {}, {}, 0
	for _, name in ipairs(names) do
		local row = category(config, snapshot, context, name, context.Catalog[name], priorities[name] or math.huge)
		table.insert(report.Categories, row)
		if row.Status == "UNKNOWN" then table.insert(unresolved, row)
		elseif row.Status ~= "COMPLETE" and row.Status ~= "LOCKED" then table.insert(selectable, row) eligible += 1 end
	end
	local rank = { REVIEW = 1, FUNDING = 2, PREREQUISITE = 3 }
	table.sort(selectable, function(a, b)
		if rank[a.Status] ~= rank[b.Status] then return rank[a.Status] < rank[b.Status] end
		if a.Amount == 0 and b.Amount ~= 0 then return true elseif b.Amount == 0 and a.Amount ~= 0 then return false end
		if a.Order ~= b.Order then return a.Order < b.Order end
		if a.Currency == b.Currency and a.Amount ~= b.Amount then return a.Amount < b.Amount end
		return a.Name < b.Name
	end)
	report.WorldGate = worldGate(config, snapshot, context)
	report.ObtainableRemainingCategories = eligible
	report.UnresolvedCategories = #unresolved
	report.EffectiveUpgrades = copy(context.EffectiveUpgrades or snapshot.Upgrades and snapshot.Upgrades.MasteryUpgrades)
	report.EffectiveUpgradeState = type(report.EffectiveUpgrades) == "table" and "RECEIVED" or "UNKNOWN"
	for _, row in ipairs(unresolved) do table.insert(report.Unknowns, row.Name .. ": " .. table.concat(row.Blockers, "; ")) end
	if selectable[1] then
		report.Status = "READ_ONLY_RECOMMENDATION" report.Recommendation = recommendation(selectable[1])
	elseif #unresolved > 0 or #report.Unknowns > 0 then
		report.Recommendation = unresolved[1] and recommendation(unresolved[1]) or report.Recommendation
	elseif report.WorldGate.Price and report.WorldGate.Affordability ~= "UNKNOWN" then
		report.Status = "READ_ONLY_RECOMMENDATION" report.WorldGate.Status = "REVIEW_AFTER_OBTAINABLE_MASTERY"
		report.Recommendation = { Kind = "WORLD_GATE_REVIEW", World = report.WorldGate.Name, Price = copy(report.WorldGate.Price),
			Currency = report.WorldGate.Currency, Amount = report.WorldGate.Amount, Balance = report.WorldGate.Balance,
			Shortage = report.WorldGate.Shortage, Affordability = report.WorldGate.Affordability,
			Reason = "No known currently obtainable permanent Mastery tier remains; review the native world gate and its separate access/action guards",
			Blockers = { "World action authorization remains separate; locked Mastery categories are not complete" }, ActionAuthorization = "NONE" }
	else
		report.Status = "NO_OBTAINABLE_MASTERY" report.Recommendation.Reason = "No known currently obtainable Mastery tier remains; next paid world gate UNKNOWN"
	end
	return report
end

function MasteryPolicy.Format(report)
	local row = report.Recommendation or {}
	local parts = { "READ_ONLY | " .. tostring(report.Status) .. " | " .. tostring(row.Kind or "WAIT") }
	if row.Category then table.insert(parts, row.Category .. " tier " .. tostring(row.Tier or "UNKNOWN")) end
	if row.World then table.insert(parts, "world=" .. row.World) end
	if row.Price then table.insert(parts, string.format("native price=%g %s; affordability=%s", row.Price.Amount, row.Price.Currency, tostring(row.Affordability or "UNKNOWN")))
	else table.insert(parts, "native price=UNKNOWN") end
	if row.Shortage ~= nil then table.insert(parts, "shortage=" .. tostring(row.Shortage)) end
	if row.FundingETASeconds then table.insert(parts, string.format("stationary funding ETA=%.1fs (conditional)", row.FundingETASeconds)) end
	table.insert(parts, row.Reason or "Evidence UNKNOWN")
	if row.Blockers and #row.Blockers > 0 then table.insert(parts, "blockers=" .. table.concat(row.Blockers, "; ")) end
	table.insert(parts, "earning benefit UNKNOWN; actions=NONE")
	return table.concat(parts, " | ")
end

return MasteryPolicy

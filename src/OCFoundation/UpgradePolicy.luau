--!nonstrict
-- Pure catalog evaluation for the existing Brain. No purchases or profile mutations.
local UpgradePolicy = {}
local function allowed(list, name) return #list == 0 or table.find(list, name) ~= nil end
local function reserve(config, currency)
	local key = ({ Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" })[currency]
	return key and config.RESOURCE_SETTINGS[key] or 0
end

function UpgradePolicy.Evaluate(config, snapshot, plan, context, currency, mode, sell, goal)
	local settings, bubble, rows, best = config.UPGRADE_SETTINGS, snapshot.Bubble or {}, {}, nil
	for _, upgrade in ipairs((snapshot.AvailableProgression or {}).Upgrades or {}) do
		local row = { Name = upgrade.Name, Kind = upgrade.Kind, Cost = upgrade.Cost, Owned = upgrade.Owned, Reasons = {} }
		table.insert(rows, row)
		local function reject(reason) table.insert(row.Reasons, reason) end
		if not settings.ENABLE_SMART_UPGRADES then reject("ENABLE_SMART_UPGRADES=false") end
		if not config.BRAIN_SETTINGS.ENABLE_EARNING_RECOMMENDATIONS or not config.BUBBLE_SETTINGS.ENABLE_BUBBLE_RECOMMENDATIONS then reject("Upgrade recommendations disabled") end
		if upgrade.Kind == "Gum" and not settings.ENABLE_CAPACITY_UPGRADES then reject("ENABLE_CAPACITY_UPGRADES=false") end
		if upgrade.Kind == "Flavors" and not settings.ENABLE_FLAVOR_UPGRADES then reject("ENABLE_FLAVOR_UPGRADES=false") end
		if not upgrade.Accessible then reject(upgrade.AccessKnown == false and "Area access unknown" or "Required area locked") end
		if not upgrade.OwnershipKnown then reject("Ownership map unavailable") end
		if not allowed(settings.SELECTED_UPGRADES, upgrade.Name) then reject("Excluded by SELECTED_UPGRADES") end
		if not allowed(config.BRAIN_SETTINGS.SELECTED_UPGRADES, upgrade.Name) then reject("Excluded by BRAIN_SETTINGS.SELECTED_UPGRADES") end
		if (context.UpgradeBackoff or {})[upgrade.Name] then reject("Purchase/equip retry cooldown") end
		local current = upgrade.Kind == "Gum" and bubble.BaseCapacity or bubble.BaseOutput
		if not current or current <= 0 or not upgrade.BaseStat then reject("Actual equipped base stat or native candidate stat unavailable")
		else
			row.BaseGain = upgrade.BaseStat / current - 1
			if row.BaseGain < config.BRAIN_SETTINGS.MINIMUM_UPGRADE_GAIN_RATIO then reject("Base gain below MINIMUM_UPGRADE_GAIN_RATIO") end
		end
		row.BlowsPerFill = bubble.Capacity and bubble.PowerPerBlow and bubble.PowerPerBlow > 0 and bubble.Capacity / bubble.PowerPerBlow or nil
		row.CapacityUrgent = row.BlowsPerFill ~= nil and row.BlowsPerFill < config.BRAIN_SETTINGS.MINIMUM_BLOWS_PER_FILL
		-- This threshold describes urgency, not a ban on every economically useful gum upgrade.
		if upgrade.Owned then
			if not settings.AUTO_EQUIP_OWNED_UPGRADES then reject("AUTO_EQUIP_OWNED_UPGRADES=false") end
			if mode == "PICKUPS" then reject("Selected pickup-only strategy has no verified bubble benefit") end
			row.Payback = 0
		else
			local enabled = upgrade.Kind == "Gum" and config.BUBBLE_SETTINGS.AUTO_BUY_GUM or (upgrade.Kind == "Flavors" and config.BUBBLE_SETTINGS.AUTO_BUY_FLAVORS)
			if not enabled then reject(upgrade.Kind == "Gum" and "AUTO_BUY_GUM=false" or "AUTO_BUY_FLAVORS=false") end
			local cost = upgrade.Cost
			if not cost or cost.Type ~= "Currency" or type(cost.Amount) ~= "number" or cost.Amount < 0 or type(cost.Currency) ~= "string" then
				reject("Verified nonpremium currency cost unavailable")
			else
				if cost.Currency == "Robux" or not table.find(settings.ALLOWED_PURCHASE_CURRENCIES, cost.Currency) then reject("Purchase currency not explicitly authorized") end
				if cost.Currency ~= currency then reject("Purchase currency does not support current resource objective") end
				row.Balance, row.Reserve = snapshot.Balances[cost.Currency], reserve(config, cost.Currency)
				row.GoalReserve = 0
				if settings.ENABLE_GOAL_RESERVATION then
					for _, reserved in pairs({ plan.Objective, goal }) do
						local metadata = reserved and reserved.Metadata
						local goalCost = metadata and metadata.Cost
						if goalCost and not metadata.Upgrade and goalCost.Currency == cost.Currency then row.GoalReserve = math.max(row.GoalReserve, goalCost.Amount or 0) end
					end
					row.GoalReserve = math.min(row.GoalReserve, math.max(0, (row.Balance or 0) - row.Reserve) * settings.MAXIMUM_GOAL_RESERVE_BALANCE_FRACTION)
				end
				local major = plan.MajorUnlockReservation
				if major and major.Currency == cost.Currency then row.GoalReserve = math.max(row.GoalReserve, major.Amount or 0) end
				row.Spendable = math.max(0, (row.Balance or 0) - row.Reserve - row.GoalReserve)
				row.Budget = row.Spendable * config.RESOURCE_SETTINGS.MAXIMUM_UPGRADE_BALANCE_FRACTION
				if row.Balance == nil then reject("Actual currency balance unavailable") end
				if cost.Amount > row.Budget then reject("Cost exceeds post-reserve balance fraction budget") end
				if cost.Amount > settings.MAXIMUM_PURCHASE_COST then reject("Cost exceeds MAXIMUM_PURCHASE_COST") end
				local sample = (context.Rates or {}).BUBBLES
				row.BubbleIncome = sample and sample.Ready and sample.PerMinute[cost.Currency] or nil
				if not row.BubbleIncome or row.BubbleIncome <= 0 then reject("Measured bubble sale income unavailable; complete a bubble-only trial") end
				local projection = (context.EffectiveUpgrades or {})[upgrade.Name]
				row.Projection = projection
				if not projection or not projection.Capacity or not projection.Power or projection.Power <= 0 or not bubble.Capacity
					or bubble.Capacity <= 0 or not bubble.PowerPerBlow or bubble.PowerPerBlow <= 0 then
					reject("Native effective-stat projection unavailable")
				else
					local fill = bubble.Capacity / bubble.PowerPerBlow * config.BUBBLE_SETTINGS.BLOW_COOLDOWN_SECONDS
					local projectedFill = projection.Capacity / projection.Power * config.BUBBLE_SETTINGS.BLOW_COOLDOWN_SECONDS
					local overhead = sell and sell.SellCycleSeconds or ((sell and (sell.TravelSeconds or sell.Distance / math.max(1, context.WalkSpeed or 16))
						or config.ISLAND_SETTINGS.UNMEASURED_TRAVEL_OVERHEAD_SECONDS) + 2)
					row.EffectiveRateGain = projection.Capacity / bubble.Capacity * (fill + overhead) / math.max(0.1, projectedFill + overhead) - 1
					row.IncrementalPerMinute = (row.BubbleIncome or 0) * math.max(0, row.EffectiveRateGain) * 0.5
					row.Payback = row.IncrementalPerMinute > 0 and cost.Amount * 60 / row.IncrementalPerMinute or math.huge
					if row.Payback > settings.MAXIMUM_PAYBACK_SECONDS then reject("Conservative estimated payback exceeds MAXIMUM_PAYBACK_SECONDS") end
					if mode == "PICKUPS" then
						local selected = (context.Rates or {}).PICKUPS
						local pickupIncome = selected and selected.Ready and selected.PerMinute[currency]
						if not pickupIncome or (row.BubbleIncome or 0) + row.IncrementalPerMinute <= pickupIncome * (1 + config.FARMING_SETTINGS.ACTIVITY_SWITCH_GAIN_RATIO) then
							reject("Projected bubble benefit does not beat the selected measured pickup strategy")
						end
					end
				end
			end
		end
		row.Eligible = #row.Reasons == 0
		if row.Eligible and (not best or row.Payback < best.Row.Payback or (row.Payback == best.Row.Payback and (upgrade.Cost.Amount < best.Upgrade.Cost.Amount
			or (upgrade.Cost.Amount == best.Upgrade.Cost.Amount and upgrade.Name < best.Upgrade.Name)))) then
			best = { Upgrade = table.clone(upgrade), Row = row }
			best.Upgrade.Reserve, best.Upgrade.GoalReserve = row.Reserve or 0, row.GoalReserve or 0
		end
	end
	table.sort(rows, function(a, b) if a.Name == b.Name then return a.Kind < b.Kind end return a.Name < b.Name end)
	return best, rows
end

return UpgradePolicy

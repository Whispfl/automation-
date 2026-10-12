--!nonstrict
-- Only formats values supplied by the account reader. Unknown stays unavailable.
local AccountPresentation = {}

function AccountPresentation.Number(value)
	if type(value) ~= "number" then return "unavailable" end
	if value == math.huge then return "unlimited" end
	return tostring(value)
end

local function keys(map)
	local result = {}
	for key in pairs(map) do table.insert(result, key) end
	table.sort(result, function(a, b) return tostring(a) < tostring(b) end)
	return result
end

function AccountPresentation.Describe(value, depth, seen)
	if value == nil then return "unavailable" end
	if type(value) ~= "table" then return tostring(value) end
	depth = depth or 0
	seen = seen or {}
	if seen[value] then return "<cycle>" end
	local sorted = keys(value)
	if depth >= 2 then return "<" .. tostring(#sorted) .. " entries>" end
	seen[value] = true
	local lines = {}
	for index, key in ipairs(sorted) do
		if index > 10 then table.insert(lines, "... " .. tostring(#sorted - 10) .. " more fields") break end
		table.insert(lines, tostring(key) .. "=" .. AccountPresentation.Describe(value[key], depth + 1, seen))
	end
	seen[value] = nil
	return "{" .. table.concat(lines, ", ") .. "}"
end

function AccountPresentation.List(map, limit)
	if type(map) ~= "table" then return "unavailable" end
	local sorted = keys(map)
	if #sorted == 0 then return "(empty received table)" end
	local lines = {}
	for index, key in ipairs(sorted) do
		if index > limit then table.insert(lines, "... " .. tostring(#sorted - limit) .. " more entries; GetStatus has the complete snapshot") break end
		table.insert(lines, tostring(key) .. ": " .. AccountPresentation.Describe(map[key]))
	end
	return table.concat(lines, "\n")
end

function AccountPresentation.Sections(snapshot, config, limit)
	local sections = {}
	local inventory, bubble, upgrades = snapshot.Inventory or {}, snapshot.Bubble or {}, snapshot.Upgrades or {}
	local balances = {}
	local displayed = {}
	for _, name in ipairs(config.ACCOUNT_SETTINGS.SELECTED_CURRENCIES) do
		table.insert(balances, name .. ": " .. AccountPresentation.Number((snapshot.Balances or {})[name]))
		displayed[name] = true
	end
	for _, name in ipairs(keys(snapshot.Balances or {})) do
		if not displayed[name] then table.insert(balances, name .. ": " .. AccountPresentation.Number(snapshot.Balances[name])) end
	end
	table.insert(balances, "Bubbles: " .. AccountPresentation.Number(bubble.Amount) .. " / " .. AccountPresentation.Number(bubble.Capacity))
	table.insert(balances, "Power per blow: " .. AccountPresentation.Number(bubble.PowerPerBlow))
	table.insert(balances, "Equipped gum: " .. tostring(bubble.Gum or "unavailable") .. "; flavor: " .. tostring(bubble.Flavor or "unavailable"))
	sections.Balances = table.concat(balances, "\n")
	sections.Pets = "Active team: " .. tostring(inventory.TeamEquipped or "unavailable")
		.. "\nEquip limit: " .. AccountPresentation.Number(inventory.MaxEquipped)
		.. "\nEquipped IDs:\n" .. AccountPresentation.List(inventory.EquippedIds, limit)
		.. "\nEquipped records:\n" .. (inventory.EquippedIds and AccountPresentation.List(inventory.EquippedPets, limit) or "unavailable")
		.. "\nUnresolved equipped IDs:\n" .. (inventory.EquippedIds and AccountPresentation.List(inventory.UnresolvedEquippedIds, limit) or "unavailable")
		.. "\nPet inventory:\n" .. AccountPresentation.List(inventory.Pets, limit)
	sections.Inventory = "Storage used / capacity (game-defined units): " .. AccountPresentation.Number(inventory.StorageUsed)
		.. " / " .. AccountPresentation.Number(inventory.StorageCapacity)
		.. "\nPowerups:\n" .. AccountPresentation.List(inventory.Powerups, limit)
		.. "\nPotions:\n" .. AccountPresentation.List(inventory.Potions, limit)
	sections.Worlds = "Unlocked worlds:\n" .. AccountPresentation.List(snapshot.UnlockedWorlds, limit)
		.. "\nDiscovered islands:\n" .. AccountPresentation.List(snapshot.UnlockedIslands, limit)
	sections.Upgrades = "Owned gum:\n" .. AccountPresentation.List(upgrades.Gum, limit)
		.. "\nOwned flavors:\n" .. AccountPresentation.List(upgrades.Flavors, limit)
		.. "\nMastery upgrades:\n" .. AccountPresentation.List(upgrades.MasteryUpgrades, limit)
	sections.Mastery = "Received levels:\n" .. AccountPresentation.List(upgrades.MasteryLevels, limit)
		.. "\nVerified next tiers:\n" .. AccountPresentation.List(snapshot.AvailableProgression and snapshot.AvailableProgression.Mastery, limit)
	return sections
end

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- Console-only formatting. One previous displayed balance baseline; never sum batch results or visual cleanup.
function AccountPresentation.Summary(status, previous, now, config)
	local snapshot, farming, world = status.Snapshot or {}, status.Farming or {}, status.WorldProgression or {}
	local goal = status.Plan and status.Plan.Objective
	local balances, metadata = snapshot.Balances or {}, goal and goal.Metadata or {}
	local parts = { tostring(status.State), "goal=" .. tostring(goal and (goal.Title or goal.Id) or "waiting for account/goal"),
		"activity=" .. tostring(status.State ~= "RUNNING" and status.State or farming.Activity
			or (world.Decision and world.Decision.Kind) or (farming.Decision and (farming.Decision.Mode or farming.Decision.Kind)) or "WAIT"),
		"island=" .. tostring(farming.Area or "unknown") }
	local owner = status.Scheduler and status.Scheduler.ActiveOwner
	if owner == "REWARDS" or owner == "EGG_TRAVEL" or owner == "ANTI_AFK" or owner == "PETS" then table.insert(parts, "local task=" .. owner) end
	local pets = status.Pets
	if pets and pets.Enabled then
		local hatch, decision = pets.Hatch or {}, pets.Decision or {}
		local location, pending = hatch.Location or {}, hatch.Pending
		local target = pending and pending.EggName or decision.EggName or location.EggName
			or status.EggTravel and status.EggTravel.BrainIntent and status.EggTravel.BrainIntent.EggName
		table.insert(parts, "pet task=" .. tostring(decision.Kind or "WAIT") .. ":" .. tostring(target or "no eligible egg"))
		table.insert(parts, "hatches=" .. tostring(hatch.VerifiedHatches or 0) .. "/" .. tostring(hatch.RequestedHatches or 0) .. " received/requested")
	end
	if status.Rewards and status.Rewards.Pending then table.insert(parts, "reward=" .. tostring(status.Rewards.Pending.Kind) .. ":" .. tostring(status.Rewards.Pending.Status)) end
	if status.Rewards and status.Rewards.AttributionBlocked then table.insert(parts, "farming attribution=excluded/pending reward evidence") end
	if status.EggTravel and status.EggTravel.Enabled then table.insert(parts, "egg travel=" .. tostring(status.EggTravel.LastResult and status.EggTravel.LastResult.Status or status.EggTravel.Reason or "waiting")) end
	if status.AntiAFK and status.AntiAFK.Enabled then table.insert(parts, "anti-AFK=" .. tostring(status.AntiAFK.Fault or status.AntiAFK.Suppression or "guarded ScrollLock pair; effectiveness unverified")) end
	for _, currency in ipairs({ "Coins", "Gems" }) do
		local value, old = balances[currency], (previous.Balances or {})[currency]
		local delta = finite(value) and finite(old) and string.format("%+.0f", value - old) or "unknown"
		table.insert(parts, currency .. "=" .. (finite(value) and string.format("%.0f", value) or "unknown") .. " (balance change " .. delta .. ")")
	end
	local cost, deficit = metadata.Cost, nil
	local progression = metadata.Progression
	if progression then
		local node = snapshot.ProgressionGraph and snapshot.ProgressionGraph.Next
		cost = node and progression.Node and node.Id == progression.Node.Id and node.Kind == "WORLD"
			and (node.State == "FUNDING" or node.State == "READY") and node.Cost or nil
	end
	local currency = cost and cost.Currency or metadata.Requirement and metadata.Requirement.Currency or farming.Decision and farming.Decision.Currency
	if cost and cost.Type == "Currency" and finite(cost.Amount) and cost.Amount >= 0 and finite(balances[currency]) then
		local field = ({ Coins = "COIN_RESERVE", Gems = "GEM_RESERVE", Tickets = "TICKET_RESERVE", Pearls = "PEARL_RESERVE" })[currency]
		deficit = math.max(0, cost.Amount + (field and config.RESOURCE_SETTINGS[field] or 0) - balances[currency])
	end
	local entry = farming.Rates and farming.Rates.STATIONARY
	local rate, rateDescription = nil, "unknown (no adequate current stationary sample)"
	if entry and finite(entry.LastAt) and finite(entry.Seconds) then
		local age = now - entry.LastAt
		if age < 0 or age > config.FARMING_SETTINGS.RATE_WINDOW_SECONDS then rateDescription = "unknown (stale/future sample)"
		elseif entry.Ready and entry.Seconds >= config.FARMING_SETTINGS.MINIMUM_RATE_SAMPLE_SECONDS
			and currency and entry.PerMinute and finite(entry.PerMinute[currency]) and entry.PerMinute[currency] >= 0 then
			rate = entry.PerMinute[currency]
			rateDescription = string.format("%.2f %s/min, sample %.1fs, age %.1fs", rate, currency, entry.Seconds, age)
		end
	end
	table.insert(parts, "rate=" .. rateDescription)
	table.insert(parts, "shortage=" .. (deficit and string.format("%.0f %s", deficit, currency) or "unknown/no fixed resource target"))
	local hours = deficit and rate and rate > 0 and deficit / rate / 60 or nil
	local eta = "unknown"
	if deficit == 0 then eta = "funded"
	elseif finite(hours) then eta = string.format("%.2f days / %.1fh (short-sample estimate, not guaranteed)", hours / 24, hours) end
	table.insert(parts, "funding ETA=" .. eta)
	local blocker = status.Error or farming.Error or farming.CleanupBlocker
	if not blocker and pets and pets.Enabled then
		blocker = pets.Fault or pets.Hatch and pets.Hatch.Fault
			or pets.Decision and (pets.Decision.Kind == "WAIT" or pets.Decision.Kind == "OBSERVE") and pets.Decision.Reason
	end
	if not blocker and world.Decision and world.Decision.Kind == "WAIT" then blocker = world.Decision.Reason end
	if not blocker and farming.Decision and (farming.Decision.Kind == "WAIT" or farming.Decision.Kind == "INSPECT") then blocker = farming.Decision.Reason end
	if not blocker then blocker = farming.CollectionBlocker end
	local lastBatch = farming.Stationary and farming.Stationary.LastResult
	if not blocker and lastBatch and lastBatch.Outcome == "INCONCLUSIVE_NO_MATCHING_CREDIT" then
		blocker = "Last batch inconclusive: no matching LocalData currency credit; server acceptance unknown"
	end
	if not blocker and finite(hours) and hours > config.WORLD_SETTINGS.FUNDING_HORIZON_HOURS then
		blocker = "Estimated funding time exceeds the configured horizon; earning-power review needed"
	end
	if not blocker and not snapshot.Ready then blocker = snapshot.Status or "account data unavailable" end
	table.insert(parts, "blocker=" .. tostring(blocker or "none observed"):gsub("[\r\n]+", " "):sub(1, 220))
	table.insert(parts, string.format("interval %.1fs; net balance change includes possible external rewards/spending", math.max(0, now - previous.At)))
	return table.concat(parts, " | ")
end

return AccountPresentation

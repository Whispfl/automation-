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

return AccountPresentation

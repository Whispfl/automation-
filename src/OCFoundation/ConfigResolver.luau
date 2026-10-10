--!nonstrict
-- Overrides replace setting values, including entire arrays; the defaults are never mutated.
local ConfigResolver = {}

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

function ConfigResolver.Resolve(defaults, overrides)
	assert(overrides == nil or type(overrides) == "table", "[OC] Config must be a table")
	local result = copy(defaults)
	for category, values in pairs(overrides or {}) do
		assert(defaults[category] ~= nil, "[OC] Unknown configuration category: " .. tostring(category))
		assert(type(values) == "table", "[OC] " .. category .. " must be a table")
		for key, value in pairs(values) do
			local expected = defaults[category][key]
			local path = category .. "." .. tostring(key)
			assert(expected ~= nil, "[OC] Unknown configuration setting: " .. path)
			assert(type(value) == type(expected), "[OC] " .. path .. " must be a " .. type(expected))
			if type(value) == "table" then
				local count = 0
				for index, item in pairs(value) do
					assert(type(index) == "number" and index >= 1 and index % 1 == 0 and type(item) == "string",
						"[OC] " .. path .. " must be an array of strings")
					count += 1
				end
				for index = 1, count do assert(value[index] ~= nil, "[OC] Sparse array: " .. path) end
			end
			result[category][key] = copy(value)
		end
	end
	return result
end

return ConfigResolver

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
	assert(result.FARMING_SETTINGS.FARMING_STRATEGY == "EFFICIENCY" or result.FARMING_SETTINGS.FARMING_STRATEGY == "PICKUP_FIRST", "[OC] Unknown FARMING_STRATEGY")
	local pickup = result.PICKUP_SETTINGS
	assert(pickup.COLLECTION_METHOD == "STATIONARY_EXPERIMENT", "[OC] Only STATIONARY_EXPERIMENT pickup collection is supported")
	pickup.ENABLE_CLUSTER_ROUTING = false -- Legacy overrides cannot reactivate movement collection.
	for key, minimum in pairs({ STATIONARY_REQUEST_COOLDOWN_SECONDS = 1, STATIONARY_ID_RETRY_SECONDS = 5,
		STATIONARY_MAXIMUM_ATTEMPTS_PER_ID = 1, STATIONARY_MAXIMUM_REQUESTS = 1,
		STATIONARY_TEST_DURATION_SECONDS = 1, STATIONARY_MAXIMUM_DRIFT_STUDS = 0.05 }) do
		local value = pickup[key]
		assert(value == value and value < math.huge and value >= minimum, "[OC] Invalid PICKUP_SETTINGS." .. key)
	end
	assert(pickup.STATIONARY_MAXIMUM_ATTEMPTS_PER_ID % 1 == 0 and pickup.STATIONARY_MAXIMUM_ATTEMPTS_PER_ID <= 2, "[OC] Stationary attempts per ID must be 1 or 2")
	assert(pickup.STATIONARY_MAXIMUM_REQUESTS % 1 == 0 and pickup.STATIONARY_MAXIMUM_REQUESTS <= 24, "[OC] Stationary request budget must be an integer up to 24")
	assert(pickup.STATIONARY_TEST_DURATION_SECONDS <= 120, "[OC] Stationary experiment duration cannot exceed 120 seconds")
	return result
end

return ConfigResolver

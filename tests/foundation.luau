-- Offline harness only. These synthetic fixtures never ship in dist/OC.lua and
-- are not evidence that any real player profile or Roblox runtime works.
local queue = {}
local os = table.clone(os) -- Test-controlled clock; never included in the published bundle.
local task = {}
function task.defer(callback)
	local thread = coroutine.create(callback)
	table.insert(queue, thread)
	return thread
end
task.spawn = task.defer
function task.delay(_, callback)
	-- Timeouts are held until explicitly resumed; tests control task ordering.
	return coroutine.create(callback)
end
function task.cancel(thread) if coroutine.status(thread) ~= "dead" then coroutine.close(thread) end end
function task.wait() coroutine.yield() end
local function flush()
	while #queue > 0 do
		local thread = table.remove(queue, 1)
		local ok, result = coroutine.resume(thread)
		assert(ok, result)
	end
end

local function event()
	local callbacks = {}
	local object = { Event = {} }
	function object.Event:Connect(callback)
		callbacks[callback] = true
		return { Disconnect = function() callbacks[callback] = nil end }
	end
	function object:Fire(...) for callback in pairs(callbacks) do callback(...) end end
	function object:Destroy() table.clear(callbacks) end
	return object
end
local Instance = { new = function(kind) assert(kind == "BindableEvent", "Offline tests permit only events") return event() end }
local workspace = { FindFirstChild = function() return nil end }
local firetouchinterest -- Synthetic runtime capability, assigned only in discovery fixtures; never ships.
local Enum = { PathStatus = { Success = "Success" }, PathWaypointAction = { Jump = "Jump" } }
-- Minimal offline vector arithmetic for coverage-scoring fixtures, not Roblox geometry verification.
local vectorMeta = {}
local Vector3 = {}
function Vector3.new(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, vectorMeta) end
function vectorMeta.__sub(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
function vectorMeta.__add(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
function vectorMeta.__mul(a, b)
	if type(b) == "number" then return Vector3.new(a.X*b, a.Y*b, a.Z*b) end
	return Vector3.new(a.X*b.X, a.Y*b.Y, a.Z*b.Z)
end
function vectorMeta.__index(a, key) if key == "Magnitude" then return math.sqrt(a.X*a.X + a.Y*a.Y + a.Z*a.Z) end end
local services = {
	Players = {}, ReplicatedStorage = { FindFirstChild = function() return nil end },
	RunService = { IsClient = function() return true end },
	CollectionService = { GetTagged = function() return {} end },
}
local game = { GetService = function(_, name) assert(services[name], name) return services[name] end }

-- BUNDLE INSERTION POINT

local tests = 0
local function test(name, callback)
	callback()
	tests += 1
	print("[OC TEST] " .. name .. " passed")
end
local Defaults = requireOC("OCConfig")
local Resolver = requireOC("ConfigResolver")
local Brain = requireOC("OCBrain")
local Reader = requireOC("AccountStateReader")
local Scheduler = requireOC("TaskScheduler")
local function config(overrides)
	-- Broad synthetic fixtures exercise separately configured future policies. Production
	-- defaults/isolated behavior are tested explicitly without these fixture overrides.
	local values = { PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = false },
		FARMING_SETTINGS = { FARMING_STRATEGY = "EFFICIENCY", ENABLE_EFFICIENCY_COMPARISON = true, ENABLE_ACTIVITY_SWITCHING = true, AUTO_FARM_FALLBACK = true }, -- Historical pure income comparisons only.
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = true, AUTO_SELL_BUBBLES = true, ENABLE_SIMULTANEOUS_BLOWING = true }, -- Historical income math/capability fixtures only; active production goals are tested separately.
		ISLAND_SETTINGS = { SELECTED_ISLANDS = {}, PREFERRED_FARMING_ISLAND = "", AUTO_TRAVEL_BEST_ISLAND = true, AUTO_EXPLORE_UNLOCKED_ISLANDS = true } }
	for category, settings in pairs(overrides or {}) do
		values[category] = values[category] or {}
		for key, value in pairs(settings) do values[category][key] = value end
	end
	return Resolver.Resolve(Defaults, values)
end

test("Partial overrides and arrays replace without mutating defaults", function()
	local changed = config({ ACCOUNT_SETTINGS = { SELECTED_CURRENCIES = { "Gems" } }, GENERAL_SETTINGS = { AUTO_START = false } })
	assert(changed.ACCOUNT_SETTINGS.SELECTED_CURRENCIES[1] == "Gems" and #changed.ACCOUNT_SETTINGS.SELECTED_CURRENCIES == 1)
	assert(changed.GENERAL_SETTINGS.AUTO_START == false and Defaults.GENERAL_SETTINGS.AUTO_START == true)
	assert(#config({ ACCOUNT_SETTINGS = { SELECTED_CURRENCIES = {} } }).ACCOUNT_SETTINGS.SELECTED_CURRENCIES == 0)
	changed.ACCOUNT_SETTINGS.SELECTED_CURRENCIES[1] = "Modified"
	assert(Defaults.ACCOUNT_SETTINGS.SELECTED_CURRENCIES[1] == "Coins")
end)

test("Unknown keys, wrong types, and sparse arrays rejected", function()
	for _, overrides in ipairs({ { GENERAL_SETTINGS = { MISSPELLED_KEY = true } },
		{ GENERAL_SETTINGS = { AUTO_START = "true" } }, { BAD_SETTINGS = {} },
		{ ACCOUNT_SETTINGS = { SELECTED_CURRENCIES = { [1] = "Coins", [3] = "Gems" } } } }) do
		assert(not pcall(config, overrides))
	end
end)

test("Missing player data stays unknown and selects a data prerequisite", function()
	local reader = Reader.new(config())
	local snapshot = reader:Read()
	assert(not snapshot.Ready and snapshot.Balances.Coins == nil and snapshot.Bubble.Capacity == nil)
	local plan = Brain.new(config()):Plan(snapshot)
	assert(plan.Objective.Id == "WAIT_FOR_ACCOUNT" and plan.Progression == "UNDETERMINED")
	reader.Dependencies.LocalData = { Status = "READY", Path = "test-only", Value = {
		IsReady = function() return true end, Get = function() return nil end } }
	assert(not reader:Read().Ready, "IsReady alone must not invent a profile")
	reader:Destroy()
end)

test("Disabled account reader loads no modules and starts no background loop", function()
	local reader = Reader.new(config({ ACCOUNT_SETTINGS = { ENABLE_ACCOUNT_READER = false } }))
	reader:Start()
	assert(reader:GetSnapshot().Status == "READER_DISABLED")
	assert(next(reader.Dependencies) == nil and #reader.Threads == 0)
	reader:Destroy()
end)

local function fixture()
	return { Ready = true, Revision = 1, Inventory = { Pets = {}, EquippedIds = {} },
		Bubble = { Amount = 95, Capacity = 100, BaseCapacity = 100, BaseOutput = 1 },
		Balances = { Coins = 100 }, Upgrades = { MasteryLevels = {} },
		UnlockedWorlds = {}, UnlockedIslands = {}, AvailableProgression = { Upgrades = {
			{ Name = "Synthetic test gum", Kind = "Gum", BaseStat = 200, Accessible = true, OwnershipKnown = true,
				Owned = false, Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } } } } }
end
test("Disabled recommendations and bubble features cannot produce their tasks", function()
	local plan = Brain.new(config({ GENERAL_SETTINGS = { ENABLE_RECOMMENDATIONS = false } })):Plan(fixture())
	assert(plan.Objective.Id == "RECOMMENDATIONS_DISABLED")
	plan = Brain.new(config({ BUBBLE_SETTINGS = { ENABLE_BUBBLE_RECOMMENDATIONS = false } })):Plan(fixture())
	for _, candidate in ipairs(plan.Candidates) do
		assert(candidate.Id ~= "SELL_BUBBLES" and not candidate.Id:find("BUY_UPGRADE:", 1, true))
	end
end)
test("Capacity threshold and reserves affect actual decision eligibility", function()
	assert(Brain.new(config()):Plan(fixture()).Objective.Id ~= "SELL_BUBBLES", "A full bubble is not an actual progression requirement")
	local data = fixture()
	data.Bubble.Amount = 0
	assert(Brain.new(config()):Plan(data).Objective.Title == "Consider Synthetic test gum")
	local reserved = config({ RESOURCE_SETTINGS = { COIN_RESERVE = 100 } })
	assert(Brain.new(reserved):Plan(data).Objective.Title == "Save for Synthetic test gum")
end)

test("Cancellation retains one foreground lease until task returns", function()
	local scheduler = Scheduler.new(config().TASK_SETTINGS)
	local started, complete = {}, {}
	scheduler.Completed.Event:Connect(function(id, status) complete[id] = status end)
	scheduler:Resume()
	scheduler:Submit({ Id = "first", Priority = 1, Execute = function(token)
		table.insert(started, "first") coroutine.yield() assert(token.Cancelled) return "ignored"
	end })
	flush()
	local active = scheduler.Active
	scheduler:Pause()
	scheduler:Submit({ Id = "second", Priority = 2, Execute = function() table.insert(started, "second") return true end })
	scheduler:Resume()
	assert(scheduler.Active == active and #started == 1 and scheduler:GetStatus().CancellationPending)
	assert(coroutine.resume(active.Thread))
	flush()
	assert(complete.first == "CANCELLED" and complete.second == "COMPLETED" and #started == 2)
	scheduler:Destroy()
end)

test("Priorities, pending replacement, and completion checks", function()
	local scheduler = Scheduler.new(config().TASK_SETTINGS)
	local started, outcomes = {}, {}
	scheduler.Completed.Event:Connect(function(id, status) outcomes[id] = status end)
	for _, item in ipairs({ { "low", 1 }, { "high", 20 }, { "low", 30 } }) do
		scheduler:Submit({ Id = item[1], Priority = item[2], Execute = function() table.insert(started, item[1]) return true end })
	end
	assert(scheduler:GetStatus().PendingCount == 2)
	scheduler:Resume() flush()
	assert(started[1] == "low" and started[2] == "high")
	scheduler:Submit({ Id = "bad", Priority = 1, Execute = function() return false end, IsComplete = function(result) return result == true end })
	flush() assert(outcomes.bad == "FAILED")
	scheduler:Stop() assert(scheduler:GetStatus().PendingCount == 0 and not scheduler.Enabled)
	scheduler:Destroy()
end)

test("Controller controls reject disabled executors and stale work", function()
	local Controller = requireOC("OCController")
	assert(not pcall(Controller.new, config({ PET_SETTINGS = { AUTO_HATCH = true } })))
	local controller = Controller.new(config({ DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false } }))
	assert(controller.State == "STOPPED")
	assert(controller:Start())
	local replan = controller.ReplanThread
	assert(coroutine.resume(replan)) flush()
	assert(controller.Plan.Objective.Id == "WAIT_FOR_ACCOUNT")
	assert(controller:Pause())
	local generation = controller.Generation
	controller.Scheduler.Completed:Fire("ANALYZE_ACCOUNT", "COMPLETED", { Generation = generation - 1, SnapshotRevision = 0, Objective = { Id = "STALE" } })
	assert(controller.Plan.Objective.Id ~= "STALE")
	assert(controller:Resume())
	assert(controller:Stop() and controller.Plan == nil)
	assert(controller:Start())
	controller:Destroy()
	assert(controller.Destroyed and not controller:Start())
end)

print("[OC TEST] " .. tests .. " offline tests passed. Real account/runtime verification remains pending.")

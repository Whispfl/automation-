-- Synthetic goal-policy regressions; no live account/quest/server verification.
local goalsBefore = tests
local function goalFixture(overrides)
	local settings = Resolver.Resolve(Defaults, overrides)
	local void = { Name = "The Void", World = "The Overworld", Key = "The Overworld/The Void", Unlocked = true,
		ActualUnlocked = true, DestinationPath = "Workspace.Worlds.The Overworld.Islands.The Void.Island.Portal.Spawn", Currencies = { Coins = true } }
	local zen = { Name = "Zen", World = "The Overworld", Key = "The Overworld/Zen", Unlocked = true,
		ActualUnlocked = true, DestinationPath = "Workspace.Worlds.The Overworld.Islands.Zen.Island.Portal.Spawn", Currencies = { Gems = true } }
	local snapshot = { Ready = true, Revision = 1, Balances = { Coins = 10, Gems = 10 }, Bubble = { Amount = 100, Capacity = 100 },
		Inventory = { Pets = {}, EquippedIds = {} }, Upgrades = { MasteryLevels = {} }, AvailableProgression = {},
		UnlockedWorlds = { ["The Overworld"] = true }, UnlockedIslands = { ["The Void"] = true, Zen = true }, TaskRequirements = {} }
	local plan = { Objective = { Id = "coins-goal", Title = "Actual currency requirement", Metadata = { Cost = { Type = "Currency", Currency = "Coins", Amount = 100 } } } }
	local context = { Now = 100, ArrivedAt = 0, Current = void, Islands = { void, zen }, SceneReady = true, CanInteract = true, CanTravel = true,
		CanBlow = true, Sells = {}, Cluster = { AreaKey = void.Key, Currency = "Coins", Records = {} }, Rates = { BUBBLES = { Ready = true, PerMinute = { Coins = 1e9 } } } }
	return settings, snapshot, plan, context, {}, void, zen
end
local function attachNativeTasks(scene, definitions, progress)
	local quest = { Id = "received-task", Tasks = definitions, Progress = progress }
	scene.Profile.Quests = { quest }
	local read = Reader.new(scene.Controller.Config)
	read.Dependencies.LocalData = { Status = "READY", Value = { IsReady = function() return true end, Get = function() return scene.Profile end } }
	read.Dependencies.QuestUtil = { Status = "READY", Value = { GetRequirement = function(_, definition)
		return definition.Type == "Collect" and definition.Item.Amount or definition.Amount
	end } }
	scene.Controller.Reader.GetTaskRequirement = function(_, id, index) return read:GetTaskRequirement(id, index) end
	return read, quest
end

test("Goal defaults turn automatic bubbles selling and background blowing off", function()
	local settings = Resolver.Resolve(Defaults)
	assert(not settings.BUBBLE_SETTINGS.AUTO_BLOW_BUBBLES and not settings.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES and not settings.BUBBLE_SETTINGS.ENABLE_SIMULTANEOUS_BLOWING)
	assert(settings.ISLAND_SETTINGS.PREFERRED_FARMING_ISLAND == "" and not settings.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST)
end)

test("Coins goal selects stationary Void even with full bubbles and higher bubble income", function()
	local settings, data, plan, context, memory, void = goalFixture({ BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = true, AUTO_SELL_BUBBLES = true, ENABLE_SIMULTANEOUS_BLOWING = true } })
	local decision = Policy.Decide(settings, data, plan, context, memory)
	assert(decision.Kind == "FARM" and decision.Mode == "PICKUPS" and decision.Currency == "Coins" and decision.PreferredIsland == void.Key)
end)

test("Gems goal travels to native Zen while Coins goal travels to Void", function()
	local settings, data, plan, context, memory, void, zen = goalFixture()
	plan.Objective.Metadata.Cost.Currency = "Gems"
	local decision = Policy.Decide(settings, data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Island == zen)
	context.Current, context.Cluster.AreaKey = zen, zen.Key
	assert(Policy.Decide(settings, data, plan, context, memory).Mode == "PICKUPS")
	plan.Objective.Metadata.Cost.Currency = "Coins"
	decision = Policy.Decide(settings, data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Island == void)
end)

test("No known active deficit cannot borrow another candidate's need or invent a bubble goal", function()
	local settings, data, plan, context, memory = goalFixture()
	plan.Candidates = { plan.Objective }
	plan.Objective = { Id = "review", Metadata = {} }
	assert(Policy.Decide(settings, data, plan, context, memory).Kind == "WAIT")
	plan.Objective = plan.Candidates[1] data.Balances.Coins = 100000000
	assert(Policy.Decide(settings, data, plan, context, memory).Kind == "WAIT")
	data.Balances.Coins = nil assert(Policy.Decide(settings, data, plan, context, memory).Kind == "WAIT")
end)

test("Actual collect progress drives currency farming independently of existing balances", function()
	local settings, data, plan, context, memory = goalFixture()
	local taskRequirement = { QuestId = "received", TaskIndex = 1, Type = "Collect", Currency = "Gems", Current = 1, Required = 100 }
	data.TaskRequirements, data.Balances.Gems = { taskRequirement }, 1e9
	plan.Objective.Metadata = { Requirement = taskRequirement }
	local decision = Policy.Decide(settings, data, plan, context, memory)
	assert(decision.Currency == "Gems" and decision.Deficit == 99 and decision.Island.Name == "Zen")
	taskRequirement.Current = 100 assert(Policy.Decide(settings, data, plan, context, memory).Kind == "WAIT")
end)

test("Locked preferred island reports fallback and rejects a mismatched fallback reward pool", function()
	local settings, data, plan, context, memory, void, zen = goalFixture()
	plan.Objective.Metadata.Cost.Currency = "Gems" zen.ActualUnlocked = false zen.Unlocked = false
	local decision = Policy.Decide(settings, data, plan, context, memory)
	assert(decision.Kind == "WAIT" and decision.Reason:find("no matching currency", 1, true) and decision.Limitation:find("Zen", 1, true))
	void.Currencies.Gems = true
	decision = Policy.Decide(settings, data, plan, context, memory)
	assert(decision.Mode == "PICKUPS" and decision.PreferredIsland == void.Key and decision.Limitation)
end)

test("Neither selected island unlocked or outside approved world blocks goal travel", function()
	local settings, data, plan, context, memory, void, zen = goalFixture()
	void.ActualUnlocked, zen.ActualUnlocked = false, false
	assert(Policy.Decide(settings, data, plan, context, memory).Kind == "WAIT")
	void.ActualUnlocked = true void.World = "Another World"
	assert(Policy.Decide(settings, data, plan, context, memory).Kind == "WAIT")
end)

test("An unchanged resource goal retains fallback across new unlocks rate changes and empty scans", function()
	local settings, data, plan, context, memory, void, zen = goalFixture()
	plan.Objective.Metadata.Cost.Currency = "Gems" zen.ActualUnlocked = false void.Currencies.Gems = true
	assert(Policy.Decide(settings, data, plan, context, memory).PreferredIsland == void.Key)
	zen.ActualUnlocked = true context.Cluster = nil plan.Objective.Id = "another-gems-requirement"
	local decision = Policy.Decide(settings, data, plan, context, memory)
	assert(decision.Kind == "INSPECT" and decision.PreferredIsland == void.Key and decision.Limitation:find("Retain", 1, true))
	plan.Objective.Metadata.Cost.Currency = "Coins" Policy.Decide(settings, data, plan, context, memory)
	plan.Objective.Metadata.Cost.Currency = "Gems"
	assert(Policy.Decide(settings, data, plan, context, memory).Island == zen)
end)

test("Brain scope changes preserve the chosen island and stable arrival still precedes pickups", function()
	local settings, data, plan, context, _, _, zen = goalFixture()
	plan.Objective.Metadata.Cost.Currency = "Gems"
	local brain = Brain.new(settings) assert(brain:PlanFarming(data, plan, context).Island == zen)
	context.Current = zen context.ArrivedAt = context.Now context.Cluster.AreaKey = zen.Key
	assert(brain:PlanFarming(data, plan, context).Kind == "INSPECT" and brain.FarmingMemory.TargetIsland == zen.Key)
	context.Now += 4 assert(brain:PlanFarming(data, plan, context).Mode == "PICKUPS")
end)

test("Completed bubble task still returns from selling before goal-driven idle", function()
	local settings, data, plan, context, memory, void = goalFixture()
	plan.Objective.Metadata = {} context.Current = { Key = "The Overworld", Name = "The Overworld", World = "The Overworld" } context.ReturnKey = void.Key
	local decision = Policy.Decide(settings, data, plan, context, memory)
	assert(decision.Kind == "TRAVEL" and decision.Returning and decision.Island == void)
	context.Current = void assert(Policy.Decide(settings, data, plan, context, memory).Kind == "WAIT")
	context.ReturnKey = nil context.PendingCleanup = true
	assert(Policy.Decide(settings, data, plan, context, memory).Kind == "INSPECT")
end)

test("Reader recognizes only received unfinished supported tasks with native amounts and actual progress", function()
	local scene = stationaryFixture()
	local reader, quest = attachNativeTasks(scene, { { Type = "Bubbles", Amount = 100 }, { Type = "Sell", Amount = 10 },
		{ Type = "Collect", Item = { Type = "Currency", Currency = "Gems", Amount = 50 } }, { Type = "Hatch", Amount = 100 } }, { 20, 10, 5, 0 })
	local snapshot = reader:Read()
	assert(#snapshot.TaskRequirements == 2 and quest.Progress[1] == 20 and quest.Tasks[1].Amount == 100)
	local requirement = reader:GetTaskRequirement(quest.Id, 3)
	assert(requirement.Required == 50 and requirement.Current == 5 and requirement.Currency == "Gems")
	quest.Progress[3] = nil assert(not reader:GetTaskRequirement(quest.Id, 3))
	quest.Progress[1] = 100 assert(not reader:GetTaskRequirement(quest.Id, 1))
	reader.Dependencies.QuestUtil = nil assert(not reader:GetTaskRequirement(quest.Id, 1))
	reader:Destroy() scene:Close()
end)

test("Brain uses actual task requirements rather than fullness or catalog task existence", function()
	local settings, data = goalFixture()
	data.TaskRequirements = { { QuestId = "actual", TaskIndex = 1, Type = "Bubbles", Current = 0, Required = 100 } }
	assert(Brain.new(settings):Plan(data).Objective.Id == "TASK:actual:1")
	data.TaskRequirements = {} local plan = Brain.new(settings):Plan(data)
	assert(plan.Objective.Id == "REVIEW_AVAILABLE_PROGRESSION")
	data.TaskRequirements = { { QuestId = "actual", TaskIndex = 1, Type = "Collect", Currency = "Coins", Current = 0, Required = 100 } }
	assert(Brain.new(settings):Plan(data).Objective.Metadata.Requirement.Currency == "Coins")
	settings.BRAIN_SETTINGS.ENABLE_EARNING_RECOMMENDATIONS = false
	assert(Brain.new(settings):Plan(data).Objective.Id == "REVIEW_AVAILABLE_PROGRESSION")
end)

test("Bubble work and selling require a matching unfinished native requirement and explicit permission", function()
	local settings, data, plan, context, memory = goalFixture()
	local requirement = { QuestId = "actual", TaskIndex = 1, Type = "Bubbles", Current = 0, Required = 100 }
	plan.Objective.Metadata = { Requirement = requirement } data.TaskRequirements = { requirement } data.Bubble.Amount = 0
	assert(Policy.Decide(settings, data, plan, context, memory).Kind == "WAIT")
	settings.BUBBLE_SETTINGS.AUTO_BLOW_BUBBLES = true
	assert(Policy.Decide(settings, data, plan, context, memory).Mode == "BUBBLES")
	data.Bubble.Amount = 100 settings.BUBBLE_SETTINGS.AUTO_SELL_BUBBLES = true context.Sells = { { Distance = 10 } }
	assert(Policy.Decide(settings, data, plan, context, memory).Kind == "SELL")
	data.TaskRequirements = {} assert(Policy.Decide(settings, data, plan, context, memory).Kind == "WAIT")
end)

test("Native bubble adapter rechecks live task completion goal changes and cancellation", function()
	local scene = stationaryFixture({ PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = false }, BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = true } })
	local reader, quest = attachNativeTasks(scene, { { Type = "Bubbles", Amount = 100 } }, { 0 })
	local requirement = reader:GetTaskRequirement(quest.Id, 1)
	scene.Controller.Plan = { Objective = { Id = "actual-bubbles", Metadata = { Requirement = requirement } } }
	local mechanics = scene.Coordinator.Mechanics
	mechanics.CanBlow = function() return true end -- Other native guards covered separately; retain live goal guards.
	assert(mechanics:Blow({ CheckCancelled = function() return false end }) and scene.Blows == 1)
	mechanics.LastBlowAt = -math.huge quest.Progress[1] = 100
	assert(not mechanics:Blow({ CheckCancelled = function() return false end }))
	quest.Progress[1] = 0 scene.Controller.Plan.Objective.Metadata = { Cost = { Type = "Currency", Currency = "Coins", Amount = 100 } }
	assert(not mechanics:Blow({ CheckCancelled = function() return false end }))
	scene.Controller.Plan.Objective.Metadata = { Requirement = requirement }
	assert(not mechanics:Blow({ CheckCancelled = function() return true end }) and scene.Blows == 1)
	mechanics.CanBlow = function() quest.Progress[1] = 100 return true end
	assert(not mechanics:Blow({ CheckCancelled = function() return false end }) and scene.Blows == 1)
	reader:Destroy() scene:Close()
end)

test("Stale scheduled goals cannot dispatch bubbles selling or currency travel", function()
	local scene = stationaryFixture({ PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = false }, BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = true, AUTO_SELL_BUBBLES = true } })
	local token = { CheckCancelled = function() return false end }
	scene.Controller.Plan = { Objective = { Id = "new-currency-goal", Metadata = {} } }
	for _, decision in ipairs({ { Kind = "FARM", Mode = "BUBBLES", GoalId = "old-bubble-goal" }, { Kind = "SELL", GoalId = "old-bubble-goal" },
		{ Kind = "TRAVEL", GoalId = "old-currency-goal", Island = travelIsland(scene, "Zen") } }) do
		assert(not scene.Coordinator:Definition(decision, 1).Execute(token).Verified)
	end
	assert(#scene.Teleports == 0 and scene.Blows == 0)
	assert(not scene.Coordinator:_sell({}, token).Verified)
	assert(not scene.Coordinator.Mechanics:Travel(nil, "The Overworld", nil, token, false, true))
	scene:Close()
end)

test("Goal-driven currency dispatch preserves real 32-ID cleanup credit and controls without bubble work", function()
	simulated(function(clock)
		local scene = stationaryFixture({ PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = false }, BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = true, AUTO_SELL_BUBBLES = true, ENABLE_SIMULTANEOUS_BLOWING = true } })
		local settings, data, plan, context, memory = goalFixture()
		for index = 1, 35 do scene:Add("goal-" .. index) end
		context.Cluster = scene.Coordinator.Tracker:Cluster("Coins") scene.Controller.Plan = plan
		local decision = Policy.Decide(settings, data, plan, context, memory)
		scene.OnDispatch = function() scene.Profile.Coins += 10 end
		local result = scene.Coordinator:Definition(decision, 1).Execute({ CheckCancelled = function() return false end })
		assert(result.Verified and #scene.Calls == 32 and #scene.Removed == 32 and scene.Blows == 0 and #scene.Teleports == 0)
		clock.Time += 10
		assert(scene.Coordinator:Definition(decision, 1).Execute({ CheckCancelled = function() return true end }) == nil and #scene.Calls == 32)
		assert(scene:Collect().Verified and #scene.Calls == 35 and #scene.Removed == 35 and scene.Blows == 0)
		scene:Close()
	end)
end)

print(string.format("[OC TEST] %d goal-driven farming regressions passed. Synthetic checks are not live gameplay approval.", tests - goalsBefore))

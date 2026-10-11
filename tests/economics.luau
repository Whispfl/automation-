-- Synthetic offline fixtures only; no live account changes or purchase verification.
local economicsBefore = tests

for _, change in ipairs({
	{ Name = "funds fall", Apply = function(scene) scene.Profile.Coins = 0 end },
	{ Name = "spending disabled", Apply = function(scene) scene.Controller.Config.WORLD_SETTINGS.AUTO_UNLOCK_WORLDS = false end },
	{ Name = "ceiling reduced", Apply = function(scene) scene.Controller.Config.WORLD_SETTINGS.MAXIMUM_WORLD_UNLOCK_COST = 0 end },
	{ Name = "currency disallowed", Apply = function(scene) scene.Controller.Config.WORLD_SETTINGS.ALLOWED_UNLOCK_CURRENCIES = { "Gems" } end },
	{ Name = "reserve rises", Apply = function(scene) scene.Controller.Config.RESOURCE_SETTINGS.COIN_RESERVE = 1000 end },
}) do
	test("Selected gate travel cannot dispatch after " .. change.Name, function()
		simulated(function()
			local scene = progressionFixture()
			scene.Profile.Coins = 1500
			local selected, decision = scene.Manager:Select(scene:Plan())
			assert(selected and decision.Kind == "TRAVEL_GATE_ISLAND")
			local definition = scene.Manager:Definition(decision, 1)
			change.Apply(scene)
			local result = definition.Execute({ CheckCancelled = function() return false end })
			assert(not result.Verified and #scene.Teleports == 0, "Stale gate task must not teleport")
			scene:Close()
		end)
	end)
end

local function economicFixture(currency)
	local scene = progressionFixture()
	scene.Definitions["Minigame Paradise"].UnlockCost = { Type = "Currency", Currency = currency or "Coins", Amount = 1000000000 }
	scene.Profile.Coins, scene.Profile.Gems = 1300, 25
	local context = { Now = 100, Current = scene.Area,
		Rate = { Ready = true, Seconds = 24.1, LastAt = 100, PerMinute = { Coins = 2858.87 } } }
	function scene:Economics()
		local plan = self:Plan()
		return self.Controller.Brain:ProgressionEconomics(self:Snapshot(), plan, context)
	end
	return scene, context
end

test("Native billion-Coin cost and observed balance rate produce an honest conditional bottleneck ETA", function()
	local scene = economicFixture()
	local result = scene:Economics()
	assert(result.Status == "BOTTLENECK" and result.Deficit == 999998700)
	assert(math.abs(result.ETADays - 242.908) < 0.001 and result.PerMinute == 2858.87 and result.SampleSeconds == 24.1)
	assert(result.Assumption:find("external credits", 1, true) and #scene.Teleports == 0 and #scene.Unlocks == 0)
	scene:Close()
end)

test("Gem world analysis uses only observed Gems and configured reserve", function()
	local scene, context = economicFixture("Gems")
	context.Current = { Name = "Zen", World = "The Overworld", Key = "The Overworld/Zen" }
	context.Rate.PerMinute.Gems = 6000
	scene.Controller.Config.RESOURCE_SETTINGS.GEM_RESERVE = 100
	local result = scene:Economics()
	assert(result.Currency == "Gems" and result.Island == "The Overworld/Zen" and result.Deficit == 1000000075 and result.PerMinute == 6000)
	scene:Close()
end)

for _, change in ipairs({
	{ Name = "other currency", Apply = function(_, context) context.Rate.PerMinute = { Gems = 999999 } end },
	{ Name = "insufficient sample", Apply = function(_, context) context.Rate.Seconds = 1 end },
	{ Name = "unready sample", Apply = function(_, context) context.Rate.Ready = false end },
	{ Name = "stale sample", Apply = function(scene, context) context.Now += scene.Controller.Config.FARMING_SETTINGS.RATE_WINDOW_SECONDS + 1 end },
	{ Name = "future timestamp", Apply = function(_, context) context.Rate.LastAt = 101 end },
	{ Name = "infinite rate", Apply = function(_, context) context.Rate.PerMinute.Coins = math.huge end },
	{ Name = "NaN rate", Apply = function(_, context) context.Rate.PerMinute.Coins = 0/0 end },
	{ Name = "unpermitted island", Apply = function(_, context) context.Current = { World = "The Overworld", Name = "Twilight", Key = "The Overworld/Twilight" } end },
	{ Name = "excluded selected island", Apply = function(scene) scene.Controller.Config.ISLAND_SETTINGS.SELECTED_ISLANDS = { "Zen" } end },
}) do
	test("Economic estimate remains unknown for " .. change.Name, function()
		local scene, context = economicFixture()
		change.Apply(scene, context)
		local result = scene:Economics()
		assert(result.Status == "UNMEASURED" and result.PerMinute == nil and result.ETAMinutes == nil)
		scene:Close()
	end)
end

test("Zero observed income gives no infinite ETA and affordable world stays funded without spending", function()
	local scene, context = economicFixture()
	context.Rate.PerMinute.Coins = 0
	local result = scene:Economics()
	assert(result.Status == "NO_OBSERVED_INCOME" and result.ETAMinutes == nil)
	scene.Profile.Coins = 1000000000
	scene.Controller.Config.WORLD_SETTINGS.AUTO_UNLOCK_WORLDS = false
	result = scene:Economics()
	local _, decision = scene.Manager:Select(scene.Controller.Plan)
	assert(result.Status == "FUNDED" and result.Deficit == 0 and decision.Kind == "WAIT" and #scene.Unlocks == 0)
	scene:Close()
end)

test("Economic threshold is diagnostic only and does not change the existing funding decision", function()
	local scene = economicFixture()
	scene.Controller.Config.WORLD_SETTINGS.FUNDING_HORIZON_HOURS = 10000
	assert(scene:Economics().Status == "MEASURED")
	assert(not scene.Manager:Select(scene.Controller.Plan) and #scene.Teleports == 0 and #scene.Unlocks == 0)
	scene:Close()
end)

test("Missing facts discovery goals and disabled economics never invent a funding estimate", function()
	local scene, context = economicFixture()
	scene.Profile.Coins = nil assert(scene:Economics() == nil)
	scene.Profile.Coins = 0 scene.Profile.AreasUnlocked = {} scene.Controller.Config.WORLD_SETTINGS.AUTO_DISCOVER_ISLANDS = true
	assert(scene:Economics() == nil)
	scene.Profile.AreasUnlocked = { ["The Void"] = true, Zen = true }
	scene.Controller.Config.WORLD_SETTINGS.ENABLE_ECONOMIC_DIAGNOSTICS = false assert(scene:Economics() == nil)
	scene:Close()
end)

test("Native earning recommendations respect access ownership and currency; bubble upgrades never promise pickup ROI", function()
	local scene = economicFixture()
	local function upgrade(name, kind, amount, stat)
		return { Name = name, Kind = kind, Cost = { Type = "Currency", Currency = "Coins", Amount = amount }, BaseStat = stat,
			AccessKnown = true, Accessible = true, OwnershipKnown = true, Owned = false }
	end
	local cheap, flavor = upgrade("Fixture Gum", "Gum", 25, 45), upgrade("Fixture Flavor", "Flavors", 25, 3)
	scene.Profile.Bubble.BaseCapacity, scene.Profile.Bubble.BaseOutput = 10, 1
	local locked, unknown, owned, premium = upgrade("Locked", "Gum", 1, 999), upgrade("Unknown", "Gum", 1, 999), upgrade("Owned", "Gum", 1, 999), upgrade("Premium", "Gum", 1, 999)
	locked.Accessible = false unknown.OwnershipKnown = false owned.Owned = true premium.Cost.Type = "Gamepass"
	scene.Observations.Upgrades = { locked, unknown, owned, premium, flavor, cheap }
	scene.Area.Multipliers = { Coins = 2 }
	local result = scene:Economics()
	assert(result.NativePickupMultiplier == 2 and result.EquippedPets == 0 and #result.Recommendations == 3)
	local text = table.concat(result.Recommendations, " | ")
	assert(text:find("Fixture Gum", 1, true) and text:find("Fixture Flavor", 1, true) and text:find("pickup ROI unverified", 1, true))
	assert(not text:find("Locked", 1, true) and not text:find("Unknown", 1, true) and not text:find("Owned", 1, true) and not text:find("Premium", 1, true))
	assert(text:find("Phase 4", 1, true) and text:find("Phase 5", 1, true) and text:find("Missing Mastery levels remain unknown", 1, true))
	assert(#scene.Unlocks == 0 and scene.Blows == 0) scene:Close()
end)

test("Sell diagnostics include only discovered unlocked native stations with matching currency", function()
	local scene = economicFixture()
	scene.Profile.AreasUnlocked.Twilight = true
	for _, island in ipairs(scene.Observations.Islands) do
		island.Facilities = { Sell = { Path = island.Name .. ".Sell", Currency = island.Name == "Zen" and "Gems" or "Coins", Multiplier = island.Name == "Twilight" and 5 or 999 } }
		if island.Name == "The Void" then island.Facilities = {} end
	end
	local result = scene:Economics()
	assert(result.BestObservedIslandSell.Island == "The Overworld/Twilight" and result.BestObservedIslandSell.Multiplier == 5)
	assert(#scene.Teleports == 0 and scene.Blows == 0)
	scene.Profile.AreasUnlocked.Twilight = nil
	assert(scene:Economics().BestObservedIslandSell == nil) scene:Close()
end)

test("Manager reuses verified samples and fresh balances with throttled logs and cancels its estimate on Pause", function()
	simulated(function(clock)
		local scene = economicFixture()
		scene.Coordinator.Metrics:AddSample("STATIONARY", scene.Area.Key, { Coins = 1000 }, 20, clock.Time)
		scene.Coordinator.PickupEvidence[scene.Area.Key .. ":Coins"] = clock.Time
		local plan = scene:Plan()
		scene.Profile.Coins = 2000
		assert(not scene.Manager:Select(plan))
		assert(scene.Manager.Economics.Balance == 2000 and scene.Manager.Economics.PerMinute == 3000)
		local logs = #scene.Logs scene.Manager:Select(plan) assert(#scene.Logs == logs)
		clock.Time += scene.Controller.Config.WORLD_SETTINGS.ECONOMIC_LOG_INTERVAL_SECONDS
		scene.Manager:Select(plan) assert(#scene.Logs > logs)
		scene.Manager:Halt() assert(scene.Manager:GetStatus().Economics == nil and #scene.Coordinator.Metrics.Samples == 1)
		scene:Close()
	end)
end)

test("Gate manual blocker reports actual native horizontal and vertical limits without navigation", function()
	local scene = progressionFixture() scene.Profile.Coins = 1500
	scene.Root.Position = scene.WorldRoot["The Overworld"].Islands.Zen.Island.Portal.Spawn.Position
	scene.Coordinator.Tracker.Current = nil
	local _, decision = scene.Manager:Select(scene:Plan())
	assert(decision.Kind == "WAIT" and decision.GateApproach.Status == "MANUAL_REQUIRED")
	assert(decision.GateApproach.HorizontalDistance == 12 and decision.GateApproach.HorizontalLimit == 6
		and decision.GateApproach.VerticalDifference == 0 and decision.GateApproach.VerticalLimit == 10)
	assert(decision.Reason:find("manual gate approach", 1, true) and #scene.Teleports == 0) scene:Close()
end)

test("Gate travel rechecks authorization after native dependency access before sending", function()
	simulated(function()
		local scene = progressionFixture() scene.Profile.Coins = 1500
		local _, decision = scene.Manager:Select(scene:Plan())
		local original = scene.Controller.Reader._dependency
		scene.Controller.Reader._dependency = function(owner, name)
			if name == "Remote" then scene.Profile.Coins = 0 end
			return original(owner, name)
		end
		local result = scene.Manager:Definition(decision, 1).Execute({ CheckCancelled = function() return false end })
		assert(not result.Verified and #scene.Teleports == 0) scene:Close()
	end)
end)

test("Economic configuration rejects zero horizon too-fast logging and nonfinite values", function()
	for _, overrides in ipairs({ { FUNDING_HORIZON_HOURS = 0 }, { FUNDING_HORIZON_HOURS = math.huge },
		{ FUNDING_HORIZON_HOURS = 0/0 }, { ECONOMIC_LOG_INTERVAL_SECONDS = 4 } }) do
		assert(not pcall(function() local controller = requireOC("OCController").new(config({ WORLD_SETTINGS = overrides })) controller:Destroy() end))
	end
end)

print("[OC TEST] Economics/gate checks passed: " .. tostring(tests - economicsBefore) .. "; total=" .. tostring(tests) .. "; offline only")

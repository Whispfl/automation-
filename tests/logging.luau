-- Console presentation and synthetic gameplay comparisons only. Never live verification.
do
local before = tests
local ConsoleController, Presentation = requireOC("OCController"), requireOC("AccountPresentation")
local function captured(callback)
	local original, output = print, {}
	print = function(value) table.insert(output, tostring(value)) end
	local ok, reason = xpcall(function() callback(output) end, debug.traceback)
	print = original
	assert(ok, reason)
end
local function logger(debugMode)
	return setmetatable({ Config = Resolver.Resolve(Defaults, { DIAGNOSTIC_SETTINGS = { ENABLE_DEBUG_LOGGING = debugMode or false } }) }, ConsoleController)
end
local function summaryStatus()
	local node = { Id = "Minigame Paradise", Kind = "WORLD", State = "FUNDING", Cost = { Type = "Currency", Currency = "Coins", Amount = 1000000000 } }
	return { State = "RUNNING", Snapshot = { Ready = true, Balances = { Coins = 1300, Gems = 25 }, ProgressionGraph = { Next = node } },
		Plan = { Objective = { Id = "PROGRESSION:WORLD:Minigame Paradise", Title = "Unlock Minigame Paradise", Metadata = { Progression = { Node = node } } } },
		Farming = { Area = "The Overworld/The Void", Activity = "PICKUPS",
			Rates = { STATIONARY = { Ready = true, Seconds = 24.1, LastAt = 30, PerMinute = { Coins = 2858.87 } } } }, WorldProgression = {} }
end

test("Summary mode hides routine IDs account dumps dependencies scans and repeated income detail", function()
	captured(function(output)
		local controller = logger()
		for _, kind in ipairs({ "PICKUP][STATIONARY_REQUEST", "PICKUP][STATIONARY_RESULT", "PICKUP][SCAN", "PICKUP][CLASSIFIED", "PICKUP][REJECTED",
			"ACCOUNT", "PETS", "INVENTORY", "WORLDS", "UPGRADES", "MASTERY", "BALANCES", "FARM][EARNINGS", "WORLD][ECONOMY", "DEPENDENCY" }) do
			controller:Log(kind, "routine id=fixture-secret | LOADING | Coins=1300")
		end
		assert(#output == 0)
		for _, kind in ipairs({ "INIT", "CONTROL", "GOAL", "ISLAND][VERIFIED", "WORLD][VERIFIED", "FARM][ERROR" }) do controller:Log(kind, "meaningful event") end
		controller:Log("FARM][TRAVEL", "Request native travel") assert(#output == 6)
		controller:Log("FARM][TRAVEL", "Arrival and island identity confirmed")
		controller:Log("FARM][TRAVEL", "Unconfirmed arrival: native geometry unavailable")
		controller:Log("WORLD][RESULT", "COMPLETED | native | Native portal arrival stabilized")
		assert(#output == 9)
	end)
end)

test("Debug restores detail and existing console/account/dependency controls still work", function()
	captured(function(output)
		local controller = logger(true)
		controller:Log("PICKUP][STATIONARY_REQUEST", "id=fixture") controller:Log("PETS", "explicit records")
		assert(#output == 2 and output[1]:find("id=fixture", 1, true))
		controller.Config.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING = false
		controller:Log("CONTROL", "hidden") assert(#output == 2)
		controller.Config.DIAGNOSTIC_SETTINGS.ENABLE_CONSOLE_LOGGING = true
		controller.Config.DIAGNOSTIC_SETTINGS.LOG_DEPENDENCIES = false
		controller.Config.DIAGNOSTIC_SETTINGS.LOG_ACCOUNT_DETAILS = false
		local snapshot = { Ready = true, Status = "READY", Balances = {}, Dependencies = { fixture = { Status = "LOADING", Path = "Fixture" } } }
		controller.Reader = { GetSnapshot = function() return snapshot end }
		controller:_diagnoseSnapshot(snapshot)
		local thread = controller.AccountLogThread assert(thread)
		assert(coroutine.resume(thread))
		for _, line in ipairs(output) do assert(not line:find("[OC][DEPENDENCY]", 1, true) and not line:find("[OC][INVENTORY]", 1, true)) end
	end)
end)

test("Identical blockers wait for an occasional reminder while changed blockers errors and controls appear immediately", function()
	captured(function(output)
		simulated(function(clock)
			local controller = logger()
			controller:Log("FARM][FALLBACK", "Waiting for native Chunker")
			clock.Time = 5 controller:Log("FARM][FALLBACK", "Waiting for native Chunker") assert(#output == 1)
			clock.Time = 10 controller:Log("FARM][FALLBACK", "No matching balance credit") assert(#output == 2)
			clock.Time = 69 controller:Log("FARM][FALLBACK", "No matching balance credit") assert(#output == 2)
			clock.Time = 70 controller:Log("FARM][FALLBACK", "No matching balance credit") assert(#output == 3)
			controller:Log("DEPENDENCY", "LocalData=ERROR | unavailable")
			controller:Log("CONTROL", "PAUSE") controller:Log("CONTROL", "RESUME") controller:Log("CONTROL", "STOP")
			assert(#output == 7)
		end)
	end)
end)

test("Bottleneck wording compares estimated time to horizon and cleanup error deduplication never retains individual IDs", function()
	captured(function(output)
		simulated(function()
			local controller = logger()
			controller:Log("WORLD][BOTTLENECK", "old verbose economics A") controller:Log("WORLD][BOTTLENECK", "old verbose economics B")
			assert(#output == 1 and output[1]:find("Estimated funding time exceeds the configured horizon", 1, true))
			controller:Log("PICKUP][CLEANUP_ERROR", "id=one | native receiver unavailable")
			controller:Log("PICKUP][CLEANUP_ERROR", "id=two | native receiver unavailable")
			assert(#output == 2 and not output[2]:find("id=", 1, true))
		end)
	end)
end)

test("Summary interval consumes each balance baseline once rather than summing batch credit or cleaned visuals", function()
	captured(function(output)
		local controller, status = logger(), summaryStatus()
		status.Snapshot.Balances.Coins = 100
		controller:_reportSummary(status, 0) assert(#output == 0)
		status.Snapshot.Balances.Coins = 130
		controller:_reportSummary(status, 5) assert(#output == 0)
		status.Snapshot.Balances.Coins = 160
		controller:_reportSummary(status, 15) assert(#output == 1 and output[1]:find("balance change +60", 1, true))
		controller:_reportSummary(status, 15) controller:_reportSummary(status, 20) assert(#output == 1)
		controller:_reportSummary(status, 30) assert(#output == 2 and output[2]:find("balance change +0", 1, true))
		assert(output[2]:find("goal=Unlock Minigame Paradise", 1, true) and output[2]:find("island=The Overworld/The Void", 1, true))
		assert(output[2]:find("short-sample estimate, not guaranteed", 1, true) and output[2]:find("sample 24.1s", 1, true))
		assert(output[2]:find("external rewards/spending", 1, true))
	end)
end)

test("Summary baseline starts unknown and spending is a signed net change without manufactured positive credit", function()
	captured(function(output)
		local controller, status = logger(), summaryStatus()
		status.Snapshot.Balances = {} controller:_reportSummary(status, 0)
		status.Snapshot.Balances = { Coins = 100, Gems = 20 } controller:_reportSummary(status, 15)
		assert(output[1]:find("Coins=100 (balance change unknown)", 1, true))
		status.Snapshot.Balances.Coins = 50 controller:_reportSummary(status, 30)
		assert(output[2]:find("Coins=50 (balance change -50)", 1, true))
		status.Snapshot.Balances = {} controller:_reportSummary(status, 45)
		status.Snapshot.Balances = { Coins = 90 } controller:_reportSummary(status, 60)
		assert(output[4]:find("Coins=90 (balance change unknown)", 1, true))
	end)
end)

test("Missing stale wrong-currency short and zero stationary samples cannot guarantee an ETA", function()
	local settings = Resolver.Resolve(Defaults)
	for _, change in ipairs({
		function(status) status.Farming.Rates = {} end,
		function(status) status.Farming.Rates.STATIONARY.LastAt = -1000 end,
		function(status) status.Farming.Rates.STATIONARY.PerMinute = { Gems = 100000 } end,
		function(status) status.Farming.Rates.STATIONARY.Seconds = 1 end,
		function(status) status.Farming.Rates.STATIONARY.PerMinute.Coins = 0 end,
		function(status) status.Farming.Rates.STATIONARY.PerMinute.Coins = math.huge end,
	}) do
		local status = summaryStatus() change(status)
		local line = Presentation.Summary(status, { At = 15, Balances = {} }, 30, settings)
		assert(line:find("funding ETA=unknown", 1, true) and not line:find("not guaranteed", 1, true))
	end
	local status = summaryStatus() status.Farming.Rates.STATIONARY.LastAt = -1000
	assert(Presentation.Summary(status, { At = 0 }, 30, settings):find("stale/future sample", 1, true))
end)

test("Affordable disabled world spending and real blockers remain explicit in summaries", function()
	local status = summaryStatus() status.Snapshot.Balances.Coins = 1000000000
	status.WorldProgression.Decision = { Kind = "WAIT", Reason = "World affordable; AUTO_UNLOCK_WORLDS=false (no farming or spending)" }
	local line = Presentation.Summary(status, { At = 15 }, 30, Resolver.Resolve(Defaults))
	assert(line:find("shortage=0 Coins", 1, true) and line:find("funding ETA=funded", 1, true) and line:find("AUTO_UNLOCK_WORLDS=false", 1, true))
	status.Farming.CleanupBlocker = "Native cleanup receiver unavailable"
	line = Presentation.Summary(status, { At = 15 }, 30, Resolver.Resolve(Defaults))
	assert(line:find("blocker=Native cleanup receiver unavailable", 1, true))
end)

test("Inconclusive last batches remain honest despite local visual cleanup", function()
	local status = summaryStatus()
	status.Farming.Stationary = { LastResult = { Outcome = "INCONCLUSIVE_NO_MATCHING_CREDIT", VisualsCleaned = 32, CreditObserved = false } }
	local line = Presentation.Summary(status, { At = 15 }, 30, Resolver.Resolve(Defaults))
	assert(line:find("no matching LocalData currency credit", 1, true) and not line:find("VisualsCleaned", 1, true))
end)

test("Summary logging errors are isolated and cannot set a gameplay error or change notifications", function()
	captured(function(output)
		local controller, status = logger(), summaryStatus()
		controller.GetStatus = function() return status end
		controller.Changed = event()
		local notified = 0 controller.Changed.Event:Connect(function() notified += 1 end)
		controller:_reportSummary(status, 0)
		local original = Presentation.Summary
		Presentation.Summary = function() error("Synthetic formatting failure") end
		controller:_reportSummary(status, 15)
		Presentation.Summary = original
		assert(controller.Error == nil and #output == 1 and output[1]:find("CONSOLE][ERROR", 1, true))
		controller:_notify() assert(notified == 1 and controller.Error == nil)
	end)
end)

test("Explicit PrintAccount remains available without enabling repeated automatic dumps", function()
	captured(function(output)
		local controller, status = logger(), summaryStatus()
		status.Snapshot.Status, status.Snapshot.Revision = "READY", 1
		controller.Reader = { GetSnapshot = function() return status.Snapshot end }
		controller:_diagnoseSnapshot(status.Snapshot) assert(not controller.AccountLogThread)
		assert(controller:PrintAccount(10))
		local found = false for _, line in ipairs(output) do if line:find("[OC][PETS]", 1, true) then found = true end end
		assert(found)
	end)
end)

test("Summary debug and disabled console produce identical stationary batches pacing balance reads and cleanup", function()
	local results = {}
	for _, mode in ipairs({ "SUMMARY", "DEBUG", "DISABLED" }) do
		captured(function()
			simulated(function(clock)
				local scene = stationaryFixture({ DIAGNOSTIC_SETTINGS = { ENABLE_DEBUG_LOGGING = mode == "DEBUG", ENABLE_CONSOLE_LOGGING = mode ~= "DISABLED", SUMMARY_INTERVAL_SECONDS = 15 } })
				scene.Controller.Log = ConsoleController.Log
				local reads, read = 0, scene.Controller.Reader.ReadBalances
				scene.Controller.Reader.ReadBalances = function(owner) reads += 1 return read(owner) end
				for index = 1, 64 do scene:Add("paced-" .. tostring(index), "Coins", 100) end
				scene.OnDispatch = function() scene.Profile.Coins += 10 end
				local first = scene:Collect() clock.Time += 1 local second = scene:Collect()
				assert(first.Verified and second.Verified and #scene.Calls == 64 and #scene.Removed == 64 and next(scene.Registry) == nil)
				local pacing = {} for _, call in ipairs(scene.Calls) do table.insert(pacing, call.Id .. "@" .. string.format("%.3f", call.At)) end
				table.insert(results, table.concat(pacing, ",") .. " reads=" .. reads .. " Coins=" .. scene.Profile.Coins .. " Blows=" .. scene.Blows .. " teleports=" .. #scene.Teleports .. " cycles=" .. scene.Coordinator.Metrics.ConfirmedCycles)
				scene:Close()
			end)
		end)
	end
	assert(results[1] == results[2] and results[2] == results[3])
end)

test("Console modes leave Pause cancellation tokens and ID deduplication identical", function()
	local results = {}
	for _, debugMode in ipairs({ false, true }) do
		captured(function()
			simulated(function()
				local scene = stationaryFixture({ DIAGNOSTIC_SETTINGS = { ENABLE_DEBUG_LOGGING = debugMode } })
				scene.Controller.Log = ConsoleController.Log
				for index = 1, 8 do scene:Add("cancel-" .. tostring(index)) end
				local cancelled = false
				scene.OnDispatch = function() cancelled = true scene.Controller.State = "PAUSED" end
				local result = scene:Collect({ CheckCancelled = function() return cancelled end })
				assert(result == nil and #scene.Calls == 1 and #scene.Removed == 1)
				results[debugMode and 2 or 1] = scene.Calls[1].Id .. ":" .. tostring(scene.Coordinator.Stationary.Requests)
				scene:Close()
			end)
		end)
	end
	assert(results[1] == results[2])
end)

test("Console modes leave native gate travel and actual world verification unchanged", function()
	for _, debugMode in ipairs({ false, true }) do
		captured(function()
			simulated(function()
				local scene = progressionFixture({ DIAGNOSTIC_SETTINGS = { ENABLE_DEBUG_LOGGING = debugMode } })
				scene.Controller.Log = ConsoleController.Log scene.Profile.Coins = 1500
				local spawn = scene.Coordinator.Mechanics:WorldGate("Minigame Paradise").Spawn
				scene.OnTeleport = function() scene.Root.Position = spawn.Position end
				local _, decision = scene.Manager:Select(scene:Plan())
				local result = scene.Manager:Definition(decision, 1).Execute({ CheckCancelled = function() return false end })
				assert(result.Verified and #scene.Teleports == 1)
				scene:AtGate("Minigame Paradise")
				scene.OnUnlock = function(name) scene.Profile.Coins -= 1000 scene.Profile.WorldsUnlocked[name] = true end
				assert(scene.Coordinator.Mechanics:UnlockWorld("Minigame Paradise", { CheckCancelled = function() return false end }))
				assert(#scene.Unlocks == 1 and scene.Profile.Coins == 500 and scene.Profile.WorldsUnlocked["Minigame Paradise"])
				scene:Close()
			end)
		end)
	end
end)

test("Console modes leave genuine hitbox contact order correct discovery flags and skip logic unchanged", function()
	for _, debugMode in ipairs({ false, true }) do
		captured(function()
			simulated(function()
				local scene = progressionFixture({ DIAGNOSTIC_SETTINGS = { ENABLE_DEBUG_LOGGING = debugMode }, WORLD_SETTINGS = { AUTO_DISCOVER_ISLANDS = true, AUTO_UNLOCK_WORLDS = false } })
				scene.Controller.Log = ConsoleController.Log scene.Profile.AreasUnlocked = {}
				local model = scene.WorldRoot["The Overworld"].Islands["Floating Island"].Island
				local hitbox = progressionNode("UnlockHitbox", model, "Part")
				hitbox.CanTouch, hitbox.Anchored, hitbox.Position = true, true, Vector3.new(0, 400, 0)
				local original, contacts = firetouchinterest, {}
				firetouchinterest = function(_, target, phase)
					assert(target == hitbox) table.insert(contacts, phase)
					if phase == 1 then scene.Profile.AreasUnlocked["Floating Island"] = true end
				end
				local _, decision = scene.Manager:Select(scene:Plan())
				assert(decision.Kind == "DISCOVER_ISLAND" and decision.Node.Name == "Floating Island")
				local result = scene.Manager:Definition(decision, 1).Execute({ CheckCancelled = function() return false end })
				assert(result.Verified and #contacts == 2 and contacts[1] == 0 and contacts[2] == 1)
				assert(scene:Plan().Objective.Metadata.Progression.Node.Name == "Outer Space" and #scene.Teleports == 0 and scene.Blows == 0)
				firetouchinterest = original scene:Close()
			end)
		end)
	end
end)

test("Summary interval validation rejects nonfinite and too-fast intervals without changing action config", function()
	for _, value in ipairs({ 0, 4, math.huge, 0/0 }) do
		assert(not pcall(function() local controller = ConsoleController.new(config({ DIAGNOSTIC_SETTINGS = { SUMMARY_INTERVAL_SECONDS = value } })) controller:Destroy() end))
	end
	assert(not Defaults.DIAGNOSTIC_SETTINGS.ENABLE_DEBUG_LOGGING and Defaults.DIAGNOSTIC_SETTINGS.SUMMARY_INTERVAL_SECONDS == 15)
end)

print("[OC TEST] Logging-only regressions passed: " .. tostring(tests - before) .. "; total=" .. tostring(tests) .. "; owner controls already confirmed live")
end

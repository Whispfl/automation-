do
-- Formatting/diagnostic regressions only. No mocked movement is a live result.
local before = tests
local Presentation, Travel = requireOC("AccountPresentation"), requireOC("EggTravelManager")
local function fixture()
	local config = Resolver.Resolve(Defaults, { EGG_TRAVEL_SETTINGS = { MODE = "TRAVEL_ONLY", ENABLE_SELECTED_EGG_TRAVEL = true } })
	local status = { State = "RUNNING", Snapshot = { Ready = true, Balances = { Coins = 100, Gems = 50 } },
		Plan = { Objective = { Title = "Consider XL Gum", Metadata = { Cost = { Type = "Currency", Currency = "Coins", Amount = 650000 } } } },
		Farming = { Decision = { Kind = "WAIT", Reason = "Unrelated funding fallback" } },
		Pets = { Enabled = true, Decision = { Kind = "WAIT", Reason = "PROTECTED_RESERVE" },
			Hatch = { RequestedHatches = 0, VerifiedHatches = 0 }, EquipmentCommands = 0 },
		EggTravel = { Enabled = true, Mode = "TRAVEL_ONLY" } }
	local function summary() return Presentation.Summary(status, { At = 0, Balances = { Coins = 100, Gems = 50 } }, 15, config) end
	return status, summary, config
end

test("TRAVEL_ONLY summary shows retained Brain preflight blocker instead of unrelated economic WAIT", function()
	local status, summary = fixture()
	status.EggTravel.Reason = "NATIVE_EGG_LOCATION_UNVERIFIED: no trustworthy spatial association"
	status.EggTravel.LastPreflightReason = status.EggTravel.Reason
	local line = summary()
	assert(line:find("egg travel=PREFLIGHT_BLOCKED", 1, true) and line:find("blocker=" .. status.EggTravel.Reason, 1, true))
	assert(not line:find("blocker=none observed", 1, true) and not line:find("PROTECTED_RESERVE", 1, true))
	assert(not line:find("Consider XL Gum", 1, true) and not line:find("funding ETA", 1, true))
	assert(line:find("direct attempts=0 | native travel attempts=0 | hatch commands=0 | equipment commands=0 | spending=0", 1, true))
	assert(#line < 1000, "One concise diagnostic summary must not repeat full candidate evidence")
end)

test("TRAVEL_ONLY summary displays actual movement ledger without treating assignment as arrival", function()
	local status, summary = fixture()
	status.EggTravel.BrainIntent = { EggName = "Common Egg" }
	status.EggTravel.Lease = { Status = "TRAVELLING", DirectPositionAttempted = true, NativeTravelAttempted = true }
	local line = summary()
	assert(line:find("goal=TRAVEL_ONLY:Common Egg", 1, true) and line:find("egg travel=TRAVELLING", 1, true))
	assert(line:find("direct attempts=1 | native travel attempts=1", 1, true) and not line:find("ARRIVAL_OBSERVED", 1, true))
end)

test("TRAVEL_ONLY physical arrival and unverified hatch interaction appear separately", function()
	local status, summary = fixture()
	status.EggTravel.LastResult = { Status = "PHYSICAL_ARRIVAL_OBSERVED", EggName = "Common Egg", DirectPositionAttempted = true,
		HatchInteraction = "HATCH_INTERACTION_UNVERIFIED", HatchCommands = 0, Spending = 0 }
	local line = summary()
	assert(line:find("egg travel=PHYSICAL_ARRIVAL_OBSERVED", 1, true))
	assert(line:find("hatch interaction=HATCH_INTERACTION_UNVERIFIED", 1, true) and not line:find("HATCH_RANGE_OBSERVED", 1, true))
	assert(line:find("blocker=none observed", 1, true) and line:find("owner live acceptance pending", 1, true))
end)

test("TRAVEL_ONLY summary reports actual bad action counts instead of hiding them behind zero literals", function()
	local status, summary = fixture()
	status.Pets.Hatch.RequestedHatches, status.Pets.EquipmentCommands = 2, 3
	status.EggTravel.LastResult = { Spending = 4 }
	local line = summary()
	assert(line:find("hatch commands=2 | equipment commands=3 | spending=4", 1, true))
end)

test("TRAVEL_ONLY unknown account values remain unknown and signed balance changes stay accurate", function()
	local status, summary = fixture()
	status.Snapshot.Balances.Coins, status.Snapshot.Balances.Gems = 90, nil
	local line = summary()
	assert(line:find("Coins=90 (balance change -10)", 1, true) and line:find("Gems=unknown (balance change unknown)", 1, true))
end)

test("TRAVEL_ONLY resolved target clears a previous preflight blocker without hiding new failures", function()
	local status, summary = fixture()
	status.EggTravel.LastPreflightReason, status.EggTravel.Reason = nil, nil
	status.EggTravel.BrainIntent = { EggName = "Common Egg" }
	status.EggTravel.Lease = { Status = "PLANNED" }
	assert(summary():find("egg travel=PLANNED", 1, true) and summary():find("blocker=none observed", 1, true))
	status.EggTravel.Lease = nil
	status.EggTravel.LastResult = { Status = "FAILED_UNCONFIRMED", DirectPositionAttempted = true }
	status.EggTravel.Reason = "Actual position does not match requested standing location"
	assert(summary():find("blocker=" .. status.EggTravel.Reason, 1, true))
end)

test("TRAVEL_ONLY summary sanitizes a bounded blocker and preserves Pause without a new movement claim", function()
	local status, summary = fixture()
	status.State, status.EggTravel.Reason = "PAUSED", "Paused; no position restore\n" .. string.rep("x", 500)
	local line = summary()
	assert(line:sub(1, 6) == "PAUSED" and not line:find("\n", 1, true))
	assert(line:find("direct attempts=0", 1, true) and #line < 1000)
end)

local function diagnosticsFixture()
	local status, summary, config = fixture()
	local logs, ids, nextId = {}, {}, 0
	local parent = { Name = "Chunker", Parent = { Name = "Rendered" } }
	local profile = { WorldsUnlocked = { ["The Overworld"] = true }, AreasUnlocked = {}, EggsOpened = {} }
	local knowledge = { InstanceId = function(_, instance)
		if not ids[instance] then nextId += 1 ids[instance] = "I" .. tostring(nextId) end
		return ids[instance]
	end }
	local controller = { Config = config, Generation = 1, Knowledge = knowledge,
		Reader = { GetLiveProfile = function() return profile end },
		Log = function(_, kind, text) table.insert(logs, kind .. " | " .. text) end }
	local manager = Travel.new(controller)
	manager.BrainIntent = { EggName = "Common Egg", Model = {}, World = "The Overworld", Generation = 1, SelectionRevision = 0 }
	local diagnostics = {}
	for _, name in ipairs({ "Common Egg", "Spotted Egg", "Iceshard Egg", "Other Egg" }) do
		local observation = { Name = name, Count = 11, VerifiedCount = 0, LocationVerifiedCount = 1,
			Reason = "Unique physical location; hatch interaction unavailable", Candidates = {} }
		for index = 1, 11 do
			local model = { Parent = parent, GetAttribute = function() return nil end }
			table.insert(observation.Candidates, { Model = model, IdentityId = knowledge:InstanceId(model), Path = "Workspace.Rendered.Chunker." .. name,
				World = "The Overworld", LocationVerified = index == 1, Reason = "CURRENT_SCENE_ASSOCIATION",
				Root = index == 1 and { Position = { X = -10, Y = 2, Z = -30 } } or nil,
				Prompt = index == 1 and { Position = { X = -10, Y = 3, Z = -30 } } or nil })
		end
		diagnostics[name] = observation
	end
	return manager, logs, diagnostics, config, status, summary
end

test("TRAVEL_ONLY real preflight logger retains its blocker in summary and stays quiet across 1000 unchanged observations", function()
	simulated(function(clock)
		local manager, logs, _, _, status, summary = diagnosticsFixture()
		local reason = "NATIVE_EGG_LOCATION_UNVERIFIED: no trustworthy spatial association"
		for second = 0, 999 do
			clock.Time = second manager:DiagnosticTrace("PREFLIGHT_BLOCKED", nil, reason)
		end
		status.EggTravel = manager:GetStatus()
		assert(#logs == 1 and status.EggTravel.Reason == reason and status.EggTravel.LastPreflightReason == reason)
		assert(summary():find("egg travel=PREFLIGHT_BLOCKED", 1, true) and summary():find("blocker=" .. reason, 1, true))
		assert(not manager.DiagnosticConsumed and not manager.Lease and next(manager.Attempts) == nil)
		manager:DiagnosticTrace("TARGET_SELECTED", { EggName = "Common Egg", Model = {} }, "Verified physical location")
		status.EggTravel = manager:GetStatus()
		assert(not status.EggTravel.Reason and not status.EggTravel.LastPreflightReason)
	end)
end)

test("TRAVEL_ONLY normal instance diagnostics show one selected target and four candidates including signed coordinates", function()
	local manager, logs, diagnostics = diagnosticsFixture()
	manager:ReportInstanceDiagnostics(diagnostics)
	assert(#logs == 1 and logs[1]:find("egg=Common Egg", 1, true))
	assert(not logs[1]:find("Spotted Egg", 1, true) and logs[1]:find("shown=4; omitted=7", 1, true))
	assert(logs[1]:find("Root=(-10.000,2.000,-30.000)", 1, true) and logs[1]:find("Prompt=(-10.000,3.000,-30.000)", 1, true))
	local _, lines = logs[1]:gsub("\n", "\n")
	assert(lines == 4, "One header and four candidate lines bound the normal initial identity report")
end)

test("TRAVEL_ONLY same identity report is not repeated on the old observation timeout or later clock ticks", function()
	simulated(function(clock)
		local manager, logs, diagnostics = diagnosticsFixture()
		for _, second in ipairs({ 0, 1, 5, 30, 60, 300, 999 }) do
			clock.Time = second manager:ReportInstanceDiagnostics(diagnostics)
		end
		assert(#logs == 1)
		diagnostics["Common Egg"].Reason = "Native registration now observed"
		diagnostics["Common Egg"].VerifiedCount = 1
		diagnostics["Common Egg"].Candidates[1].Verified = true
		manager:ReportInstanceDiagnostics(diagnostics)
		assert(#logs == 2 and logs[2]:find("registered=1", 1, true))
	end)
end)

test("TRAVEL_ONLY expanded identity diagnostics require an explicit method or debug setting", function()
	local manager, logs, diagnostics, config = diagnosticsFixture()
	manager:ReportInstanceDiagnostics(diagnostics, true)
	assert(#logs == 4 and logs[1]:find("shown=11; omitted=0", 1, true))
	local secondManager, secondLogs, secondDiagnostics, secondConfig = diagnosticsFixture()
	secondConfig.DIAGNOSTIC_SETTINGS.ENABLE_DEBUG_LOGGING = true
	secondManager:ReportInstanceDiagnostics(secondDiagnostics)
	assert(#secondLogs == 4 and not config.DIAGNOSTIC_SETTINGS.ENABLE_DEBUG_LOGGING)
end)

print("[OC TEST] " .. (tests - before) .. " egg-location summary regressions passed; owner live acceptance remains pending")
end

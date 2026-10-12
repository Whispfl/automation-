do
-- Synthetic logging regressions exercise real selection/preflight transitions;
-- no native movement, spending or gameplay result is claimed.
local before = tests
local Travel = requireOC("EggTravelManager")
local function fixture()
	local s = { Logs = {}, Blocker = "AMBIGUOUS_NATIVE_EGG_MODEL: indistinguishable originals", Model = {} }
	s.Config = Resolver.Resolve(Defaults, {
		HATCH_SETTINGS = { EGG_SELECTION_MODE = "MANUAL", SELECTED_EGGS = { "Common Egg" } },
		EGG_TRAVEL_SETTINGS = { MODE = "TRAVEL_ONLY", ENABLE_SELECTED_EGG_TRAVEL = true },
	})
	s.Controller = { Config = s.Config, Generation = 1, State = "RUNNING", Reader = { Player = { UserId = 1 } },
		Log = function(_, kind, message) table.insert(s.Logs, kind .. " | " .. message) end }
	s.Manager = Travel.new(s.Controller)
	s.Intent = { Kind = "EGG_TRAVEL", Scope = "TRAVEL_ONLY", DecisionSource = "BRAIN_TRAVEL_DIAGNOSTIC", SelectionMode = "MANUAL",
		EggName = "Common Egg", Model = s.Model, World = "The Overworld", Generation = 1, SelectionRevision = 0, Reason = "Read-only target" }
	s.Manager.Resolve = function()
		if s.Blocker then return nil, s.Blocker end
		return { EggName = "Common Egg", Model = s.Model, World = "The Overworld", Generation = 1,
			SelectionKey = "Common Egg:0", InRange = true, Range = 6.5, Distance = 2, NeedsNativeTravel = false }
	end
	function s:Select() return self.Manager:Select({}, self.Intent) end
	return s
end

test("TRAVEL_ONLY repeated unresolved preflight prints one blocker and never consumes movement permission", function()
	simulated(function(clock)
		local s = fixture()
		for second = 0, 24 do
			clock.Time = second
			local selected, decision = s:Select()
			assert(not selected and decision.Kind == "WAIT" and decision.Reason == s.Blocker)
		end
		assert(#s.Logs == 1 and s.Logs[1]:find("PREFLIGHT_BLOCKED", 1, true))
		assert(s.Logs[1]:find("direct attempts=0; native travel attempts=0; hatch commands=0; spending=0", 1, true))
		assert(s.Logs[1]:find("preflight unresolved; no arrival claimed", 1, true))
		assert(not s.Manager.DiagnosticConsumed and not s.Manager.Lease and next(s.Manager.Attempts) == nil)
		clock.Time = 30 s:Select()
		assert(#s.Logs == 2, "An unchanged blocker can emit only one bounded 30-second reminder")
	end)
end)

test("TRAVEL_ONLY changed blocker target resolution and cancellation are immediate distinct events", function()
	simulated(function()
		local s = fixture() s:Select()
		local original = s.Blocker
		s.Blocker = "Native access disappeared" s:Select()
		s.Blocker = original s:Select()
		assert(#s.Logs == 2, "A new blocker is immediate while A/B/A alternation cannot defeat per-key throttling")
		s.Blocker = nil
		local selected, decision = s:Select()
		assert(selected and decision.Kind == "EGG_TRAVEL" and #s.Logs == 3)
		assert(s.Logs[3]:find("TARGET_SELECTED", 1, true) and s.Manager.DiagnosticConsumed)
		s.Manager:DiagnosticTrace("PREFLIGHT_BLOCKED", nil, original)
		assert(#s.Logs == 4, "A blocker recurrence after real target resolution is immediately visible")
		s.Controller.State = "PAUSED" s.Manager:Halt(false)
		assert(#s.Logs == 5 and s.Logs[5]:find("TRAVEL_BLOCKED", 1, true))
		assert(s.Logs[5]:find("direct attempts=0; native travel attempts=0", 1, true))
		s.Controller.State = "RUNNING" s:Select()
		local count = #s.Logs
		for _ = 1, 20 do s:Select() end
		assert(#s.Logs == count and s.Manager.DiagnosticEnded and not s.Manager.Lease)
		assert(next(s.Manager.Attempts) == nil, "Logging must not invent an adapter movement attempt")
	end)
end)

test("TRAVEL_ONLY stable report keys ignore distance drift and keep candidate diagnostics bounded", function()
	simulated(function()
		local s = fixture() s.Manager.BrainIntent = s.Intent
		local record = { EggName = "Common Egg", Model = s.Model, World = "The Overworld", Generation = 1, Range = 6.5 }
		for distance = 1, 20 do
			record.Distance = distance
			s.Manager:DiagnosticTrace("PREFLIGHT_BLOCKED", record, "Same unresolved model identity")
			s.Manager:Report("Unchanged read-only candidate details", "CANDIDATE:one")
		end
		assert(#s.Logs == 2, "Interleaved candidate reports and harmless distance drift cannot defeat blocker dedup")
		record.Model = {} s.Manager:DiagnosticTrace("PREFLIGHT_BLOCKED", record, "Same unresolved model identity")
		assert(#s.Logs == 3, "An actual target instance change remains observable")
		for index = 1, 40 do s.Manager:Report("Candidate " .. index, "CANDIDATE:" .. index) end
		local keys = 0 for _ in pairs(s.Manager.ReportTimes) do keys += 1 end
		assert(keys == 32 and #s.Manager.ReportOrder == 32, "Diagnostic cache cannot grow without bound")
	end)
end)

test("NORMAL travel keeps one useful raw preflight report while repeated plans are quiet", function()
	simulated(function()
		local s = fixture() s.Config.EGG_TRAVEL_SETTINGS.MODE = "NORMAL"
		for _ = 1, 20 do s.Manager:Select({}, nil) end
		assert(#s.Logs == 1 and s.Logs[1]:find(s.Blocker, 1, true) and not s.Logs[1]:find("PREFLIGHT_BLOCKED", 1, true))
		s.Blocker = "Native access disappeared" s.Manager:Select({}, nil)
		assert(#s.Logs == 2 and s.Logs[2]:find(s.Blocker, 1, true))
	end)
end)

test("TRAVEL_ONLY attempted-stage reports read the lease ledger rather than a fresh geometry record", function()
	simulated(function()
		local s = fixture() s.Blocker = nil
		local selected, decision = s:Select() assert(selected)
		s.Manager.Lease.DirectPositionAttempted = true
		local fresh = { EggName = "Common Egg", Model = s.Model, World = "The Overworld", Generation = 1, Distance = 2, Range = 6.5 }
		s.Manager:DiagnosticTrace("DIRECT_POSITION_ATTEMPTED", fresh, "Synthetic adapter attempted; geometry record has no ledger flags")
		assert(s.Logs[#s.Logs]:find("direct attempts=1; native travel attempts=0", 1, true))
		s.Manager.Lease.NativeTravelAttempted = true
		s.Manager:DiagnosticTrace("AREA_TRAVEL_REQUESTED", fresh, "Synthetic dispatch")
		assert(s.Logs[#s.Logs]:find("direct attempts=1; native travel attempts=1", 1, true))
		s.Manager:Release("Synthetic uncertain adapter failure", true)
		assert(s.Logs[#s.Logs]:find("direct attempts=1; native travel attempts=1", 1, true))
		s.Manager:DiagnosticTrace("ARRIVAL_UNCONFIRMED", fresh, "Lease released; retained actual ledger")
		assert(s.Logs[#s.Logs]:find("direct attempts=1; native travel attempts=1", 1, true))
	end)
end)

print("[OC TEST] " .. (tests - before) .. " travel logging regressions passed; native movement remains owner pending")
end

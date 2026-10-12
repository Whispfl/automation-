do
-- Same foreground stationary collector at an owned egg. Synthetic native facts
-- prove dispatch serialization; live pickup/hatch acceptance remains owner tested.
local before = tests
local Manager = requireOC("PetManager")
local token = { CheckCancelled = function() return false end }
local function fixture(currency, excluded)
	local s = stationaryFixture({ PICKUP_SETTINGS = { STATIONARY_ISOLATED_TEST = false },
		PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = true, OBJECTIVE_CURRENCY = "Gems" },
		HATCH_SETTINGS = { SELECTED_EGGS = { "Test Egg" }, ENABLE_BACKGROUND_PICKUPS = true, MAXIMUM_EGG_COST = 10,
			MAXIMUM_SESSION_COST = 30, MAXIMUM_SESSION_HATCHES = 3 }, FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false } })
	if excluded then s.Area.Name, s.Area.Key = "The Overworld", "The Overworld/The Overworld" end
	s.Profile.EggsOpened = { ["Test Egg"] = 0 }
	s.Controller.Plan = { Objective = { Metadata = { Requirement = { Type = "Currency", Currency = currency, Required = 999 } } } }
	s.Hatching, s.Auto, s.NativeEligible = false, nil, true
	s.Dependencies.ProximityPrompt = { Visible = 0 }
	s.Dependencies.HatchPresentation = { IsHatching = function() return s.Hatching end }
	local auto = { IsA = function(_, kind) return kind == "BindableFunction" end,
		Invoke = function() if s.OnNativeGuard then s.OnNativeGuard() end return s.Auto end }
	s.Controller.Reader.Player = { UserId = 123, FindFirstChild = function()
		return { FindFirstChild = function() return { FindFirstChild = function() return auto end } end }
	end }
	s.Controller.Farming, s.Controller.Knowledge = s.Coordinator, s.Coordinator.Knowledge
	local part = { Position = s.Root.Position + Vector3.new(2,0,0), IsA = function(_, kind) return kind == "BasePart" end }
	s.Egg = { Name = "Test Egg", Parent = true, IsDescendantOf = function() return true end,
		FindFirstChild = function(_, name) return name == "Root" and part or {} end,
		GetAttribute = function(_, name) if name == "Unlocked" then return true end end }
	s.Dependencies.Eggs = { ["Test Egg"] = { World = "The Overworld", Island = not excluded and "The Void" or nil } }
	registerNativeEggFixture(s.Controller.Knowledge, s.Egg, s)
	s.Controller.Knowledge.EggModels = function() return { s.Egg } end
	s.Manager = Manager.new(s.Controller) s.Controller.Pets = s.Manager
	s.Manager.Hatch.Location = { EggName = "Test Egg", Model = s.Egg, World = "The Overworld", Island = not excluded and "The Void" or nil }
	s.Manager.Hatch.StartedAt = 0
	local originalCluster = s.Coordinator.Tracker.Cluster
	s.Coordinator.Tracker.Cluster = function(tracker, selectedCurrency)
		s.SelectedClusterCurrency = selectedCurrency
		return originalCluster(tracker, selectedCurrency)
	end
	function s:Collect(t) return self.Manager:CollectBackground(t or token) end
	return s
end

test("Phase4 optional same-egg pickups use actual Coins or Gems objective without relocation", function()
	simulated(function()
		for _, currency in ipairs({ "Coins", "Gems" }) do
			local s = fixture(currency,true) local record = s:Add("target-" .. currency,currency) local other = s:Add("other",currency == "Coins" and "Gems" or "Coins")
			local original = s.Root.Position s.OnDispatch = function(id)
				local receivedCurrency = id == record.Id and record.Currency or other.Currency
				s.Profile[receivedCurrency] += 7
			end
			local result = s:Collect()
			assert(result.Verified and #s.Calls == 2 and s.SelectedClusterCurrency == currency and record.Model.Destroyed and other.Model.Destroyed,
				"Target " .. currency .. "; calls=" .. #s.Calls .. "; reason=" .. tostring(result.Reason))
			assert(not s.Coordinator.Stationary.LastResult.Contaminated and result.Gains.Coins == 7 and result.Gains.Gems == 7)
			assert(#s.Teleports == 0 and s.Root.Position == original and s.Manager.BackgroundPickup == nil) s:Close()
		end
	end)
end)

test("Phase4 pending pet acknowledgement presentation auto-hatch uncertainty and transaction block pickups", function()
	simulated(function()
		for _, kind in ipairs({ "pending hatch", "pending equipment", "presentation", "auto", "fault", "transaction", "ended", "disabled" }) do
			local s = fixture("Coins",true) local record = s:Add("blocked")
			if kind == "pending hatch" then s.Manager.Hatch.Pending = {} elseif kind == "pending equipment" then s.Manager.PendingEquip = {}
			elseif kind == "presentation" then s.Hatching = true elseif kind == "auto" then s.Auto = "Test Egg"
			elseif kind == "fault" then s.Manager.Fault = "Synthetic unresolved result" elseif kind == "transaction" then s.Manager.Transaction = {}
			elseif kind == "ended" then s.Manager.Hatch.EndReason = "Session consumed"
			else s.Controller.Config.HATCH_SETTINGS.ENABLE_BACKGROUND_PICKUPS = false end
			assert(s:Collect() == nil and #s.Calls == 0 and not record.Model.Destroyed) s:Close()
		end
	end)
end)

test("Phase4 no Coins or Gems objective never substitutes a fixed pickup currency", function()
	simulated(function()
		for _, currency in ipairs({ "Bubbles", "Tickets", "Pearls" }) do
			local s = fixture(currency,true) s:Add("no-target")
			assert(s:Collect() == nil and #s.Calls == 0 and #s.Teleports == 0) s:Close()
		end
	end)
end)

test("Phase4 late objective or cancellation change cannot fall back to ordinary Void pickups", function()
	simulated(function()
		for _, kind in ipairs({ "objective", "cancel", "generation", "lease" }) do
			local s = fixture("Coins",false) local record = s:Add("stale") local cancelled = false
			local guarded = { CheckCancelled = function() return cancelled end }
			s.Coordinator.Mechanics.Guard = function()
				if kind == "objective" then s.Controller.Plan.Objective.Metadata.Requirement.Currency = "Gems"
				elseif kind == "cancel" then cancelled = true elseif kind == "generation" then s.Controller.Generation += 1
				else s.Manager.Hatch.Location = nil end
				return true,nil,s.Root
			end
			s:Collect(guarded)
			assert(#s.Calls == 0 and not record.Model.Destroyed and #s.Teleports == 0 and s.Manager.BackgroundPickup == nil) s:Close()
		end
	end)
end)

test("Phase4 native guard objective change before pickup scope creates no stale request", function()
	simulated(function()
		local s = fixture("Coins",true) local record = s:Add("stale-native")
		s.OnNativeGuard = function() s.Controller.Plan.Objective.Metadata.Requirement.Currency = "Tickets" end
		assert(s:Collect() == nil and #s.Calls == 0 and not record.Model.Destroyed) s:Close()
	end)
end)

test("Phase4 manual range departure stops the same pickup batch and discards its credit window", function()
	simulated(function()
		local s = fixture("Gems",false) s:Add("first","Gems") local second = s:Add("second","Gems")
		s.OnDispatch = function() s.Profile.Gems += 7 s.Root.Position += Vector3.new(500,0,0) end
		s:Collect()
		assert(#s.Calls == 1 and not second.Model.Destroyed and #s.Teleports == 0)
		assert(s.Coordinator.Stationary.LastResult.Cancelled and not s.Coordinator.Stationary.LastResult.CreditObserved) s:Close()
	end)
end)

test("Phase4 late native hatch presentation cancels pickup attribution without overlapping spend", function()
	simulated(function()
		local s = fixture("Coins",true) s:Add("first") local second = s:Add("second")
		s.OnDispatch = function() s.Profile.Coins += 7 s.Hatching = true end
		s:Collect()
		assert(#s.Calls == 1 and not second.Model.Destroyed and s.Coordinator.Stationary.LastResult.Cancelled)
		assert(not s.Coordinator.Stationary.LastResult.CreditObserved and s.Manager.Hatch.RequestCost == 0) s:Close()
	end)
end)

test("Phase4 absent or expired selected arrival lease cannot authorize background pickups", function()
	simulated(function()
		for _, kind in ipairs({ "missing", "expired", "wrong model", "not arrived" }) do
			local s = fixture("Coins",false) s:Add("lease-only") s.Controller.Config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL = true
			local lease = { Status = "ARRIVED", Model = s.Egg, EggName = "Test Egg", Deadline = 50, SelectionKey = "test" }
			if kind == "missing" then lease = nil elseif kind == "expired" then lease.Deadline = 0
			elseif kind == "wrong model" then lease.Model = {} else lease.Status = "TRAVELING" end
			s.Controller.EggTravel = { Lease = lease, Blocked = {} }
			assert(s:Collect() == nil and #s.Calls == 0 and #s.Teleports == 0) s:Close()
		end
	end)
end)

test("Phase4 a hatch or equipment dispatch never shares a slice with pickup requests", function()
	simulated(function()
		for _, kind in ipairs({ "HATCH", "TEAM", "TEAM_ADD" }) do
			local s = fixture("Coins",true) s:Add("must-wait") local actions = 0
			s.Manager.Select = function() return true,{ Kind = kind } end
			s.Coordinator.Mechanics.PetAction = function() actions += 1 return true,"Synthetic pet action dispatched" end
			s.Manager:Definition({Kind=kind},s.Controller.Generation).Execute(token)
			assert(actions == 1 and #s.Calls == 0 and #s.Teleports == 0) s:Close()
		end
	end)
end)

print("[OC TEST] " .. tostring(tests-before) .. " optional serialized same-egg pickup regressions passed; live owner verification pending.")
end

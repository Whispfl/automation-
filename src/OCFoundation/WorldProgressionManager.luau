--!nonstrict
-- Builds observations for OCBrain and executes its decision under the existing OC_GAMEPLAY lease.
local WorldProgressionManager = {}
WorldProgressionManager.__index = WorldProgressionManager

function WorldProgressionManager.new(controller)
	local self = setmetatable({ Controller = controller, Mechanics = controller.Farming.Mechanics, TravelFailures = {}, TravelRetryAt = {} }, WorldProgressionManager)
	self.Mechanics.ProgressionGoalProvider = function()
		local goal = controller.Plan and controller.Plan.Objective
		local progression = goal and goal.Metadata and goal.Metadata.Progression
		return controller.State == "RUNNING" and progression and progression.Node or nil
	end
	self.Mechanics.ProgressionReserveProvider = function()
		-- Fresh graph facts, independent of which competing blocker currently holds the objective.
		local graph = controller.Reader:GetSnapshot().ProgressionGraph
		local node = graph and graph.Next
		return node and node.Kind == "WORLD" and (node.State == "READY" or node.State == "FUNDING") and node.Cost or nil
	end
	return self
end

function WorldProgressionManager:Select(plan)
	local controller, mechanics = self.Controller, self.Mechanics
	if not controller.Config.WORLD_SETTINGS.ENABLE_WORLD_PROGRESSION then self.Economics = nil return false end
	if mechanics.PendingPickupCleanup or controller.Farming.ReturnKey then
		self.Decision, self.Economics = nil, nil return false -- Finish already-dispatched Phase 2 cleanup/saved sell-return through its existing scheduler path.
	end
	local goal = plan.Objective and plan.Objective.Metadata and plan.Objective.Metadata.Progression
	if not goal then
		local graph = controller.Reader:GetSnapshot().ProgressionGraph
		if graph and graph.Complete and not self.ReportedComplete then
			controller:Log("WORLD][GRAPH", "Selected permanent world/island flags already complete; no unlock replay. Other game systems and Phase 3 live approval remain separate.")
			self.ReportedComplete = true
		end
		self.Decision, self.Economics = nil, nil return false
	end
	self.ReportedComplete = false
	local now, current = os.clock(), controller.Farming.Tracker.Current
	local snapshot = table.clone(controller.Reader:GetSnapshot())
	-- Use the existing verified balance reader and approved sample ledger, not pickup face values.
	snapshot.Balances = controller.Reader:ReadBalances()
	self.Economics = controller.Brain:ProgressionEconomics(snapshot, plan, {
		Now = now, Current = current,
		Rate = current and controller.Farming:_pickupRates(current.Key, now).STATIONARY or nil,
	})
	local economics = self.Economics
	if economics then
		local signature = economics.GoalId .. ":" .. economics.Status .. ":" .. tostring(economics.Island)
		if signature ~= self.LastEconomicSignature or now - (self.LastEconomicLogAt or -math.huge) >= controller.Config.WORLD_SETTINGS.ECONOMIC_LOG_INTERVAL_SECONDS then
			self.LastEconomicSignature, self.LastEconomicLogAt = signature, now
			controller:Log("WORLD][ECONOMY", string.format("%s | status=%s | cost=%.0f %s | balance=%.0f | reserve=%.0f | shortage=%.0f | island=%s | rate=%s/min | sample=%ss | age=%ss | ETA=%s | horizon=%.1fh (diagnostic only) | %s",
				economics.World, economics.Status, economics.Cost, economics.Currency, economics.Balance, economics.Reserve, economics.Deficit,
				tostring(economics.Island or "unmeasured"), economics.PerMinute and string.format("%.2f", economics.PerMinute) or "unknown",
				economics.SampleSeconds and string.format("%.1f", economics.SampleSeconds) or "unknown", economics.SampleAgeSeconds and string.format("%.1f", economics.SampleAgeSeconds) or "unknown",
				economics.ETADays and string.format("%.2f days / %.1f hours", economics.ETADays, economics.ETAHours) or (economics.Status == "FUNDED" and "funded" or "unknown"),
				economics.HorizonHours, economics.Assumption))
			if economics.Status == "BOTTLENECK" then
				controller:Log("WORLD][BOTTLENECK", "Estimated funding time exceeds the configured horizon; earning-power review needed. Native pickup multiplier=" .. tostring(economics.NativePickupMultiplier or "unknown") .. " | equipped pets=" .. tostring(economics.EquippedPets or "unknown") .. " | " .. table.concat(economics.Recommendations, " | "))
			end
		end
	end
	local name = goal.Node and goal.Node.Name
	local gate, blocker
	if name and goal.Node.Kind == "WORLD" and goal.Node.State == "READY" then gate, blocker = mechanics:WorldGate(name) end
	local discovery
	if goal.Node and goal.Node.Kind == "ISLAND" and controller.Config.WORLD_SETTINGS.AUTO_DISCOVER_ISLANDS then
		discovery, blocker = mechanics:IslandDiscovery(goal.Node)
		if controller.Config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST then discovery, blocker = nil, "Isolated pickup test blocks island discovery" end
	end
	local permitted, guardReason = mechanics:Guard(gate and gate.InRange and "World " .. tostring(gate.Order) or nil)
	local decision = controller.Brain:PlanProgression(controller.Reader:GetSnapshot(), plan, {
		Discovery = discovery, DiscoveryAttempts = goal.Node and mechanics.IslandDiscoveryAttempts[goal.Node.Id] or 0,
		DiscoveryBackoff = (goal.Node and not mechanics:Available("DISCOVER:" .. goal.Node.Id) or false)
			or os.clock()-mechanics.LastDiscoveryAt < controller.Config.WORLD_SETTINGS.ISLAND_DISCOVERY_INTERVAL_SECONDS,
		Gate = gate, Blocker = blocker or guardReason, CanInteract = permitted,
		SessionRequests = mechanics.SessionUnlockRequests or 0, UnlockAttempts = name and (mechanics.UnlockAttempts or {})[name] or 0,
		UnlockBackoff = name and not mechanics:Available("UNLOCK:" .. name) or false,
		TravelBackoff = (name and os.clock() < (self.TravelRetryAt[name] or 0) or false)
			or (gate and gate.DestinationPath and not mechanics:Available("TRAVEL:" .. gate.DestinationPath) or false)
			or os.clock() - mechanics.LastTravelAt < controller.Config.ISLAND_SETTINGS.TRAVEL_COOLDOWN_SECONDS,
		TravelFailures = name and self.TravelFailures[name] or 0,
	})
	self.Decision = decision
	if not decision then return false end
	local description = decision.Kind .. " | " .. plan.Objective.Id .. " | " .. decision.Reason
	if description ~= self.LastDescription then
		self.LastDescription = description controller:Log("WORLD][DECISION", description)
		if decision.GateApproach then controller:Log("WORLD][GATE_APPROACH", decision.Reason) end
	end
	return true, decision
end

function WorldProgressionManager:Definition(decision, generation)
	if not decision or decision.Kind == "WAIT" then return nil end
	local controller = self.Controller
	return { Id = "OC_GAMEPLAY", Owner = "WORLD_PROGRESSION", Priority = 100, Generation = generation,
		TimeoutSeconds = math.max(controller.Config.ISLAND_SETTINGS.TRAVEL_CONFIRMATION_TIMEOUT_SECONDS,
			decision.Kind == "DISCOVER_ISLAND" and (controller.Config.WORLD_SETTINGS.ISLAND_DISCOVERY_CONFIRMATION_TIMEOUT_SECONDS
				+ controller.Config.WORLD_SETTINGS.ISLAND_DISCOVERY_CONTACT_SECONDS+1) or 0,
			controller.Config.WORLD_SETTINGS.UNLOCK_CONFIRMATION_TIMEOUT_SECONDS) + 2,
		CanRun = function() return controller.State == "RUNNING" and controller.Generation == generation
			and controller.Plan and controller.Plan.Objective.Id == decision.GoalId end,
		Execute = function(token)
			if token:CheckCancelled() or controller.State ~= "RUNNING" or controller.Generation ~= generation
				or not controller.Plan or controller.Plan.Objective.Id ~= decision.GoalId then return nil end
			controller.Farming:Halt(true) -- Release Phase 2 measurement/observer ownership, retaining native ID deduplication.
			local ok, reason, evidence
			if decision.Kind == "UNLOCK_WORLD" then ok, reason, evidence = self.Mechanics:UnlockWorld(decision.Node.Name, token)
			elseif decision.Kind == "DISCOVER_ISLAND" then
				local succeeded, output = xpcall(function() return table.pack(self.Mechanics:DiscoverIsland(decision.Node, token)) end, debug.traceback)
				self.Mechanics:EndIslandContact()
				if succeeded then ok, reason, evidence = table.unpack(output, 1, output.n) else ok, reason = false, tostring(output) end
			elseif decision.Kind == "TRAVEL_GATE_ISLAND" then
				local name = decision.Node.Name
				local requestsBefore = self.Mechanics.ProgressionTravelRequests or 0
				-- Install backoff before dispatch so Pause/Stop cannot erase an uncertain travel attempt.
				self.TravelRetryAt[name] = os.clock() + controller.Config.ISLAND_SETTINGS.TRAVEL_RETRY_COOLDOWN_SECONDS
				ok, reason, evidence = self.Mechanics:TravelForProgression(name, token)
				if not ok and (self.Mechanics.ProgressionTravelRequests or 0) > requestsBefore then self.TravelFailures[name] = (self.TravelFailures[name] or 0) + 1
				else self.TravelRetryAt[name] = nil end
			end
			return { Verified = ok, Reason = reason, Evidence = evidence, Kind = decision.Kind, Name = decision.Node.Name }
		end,
		IsComplete = function(result) return type(result) == "table" end }
end

function WorldProgressionManager:Halt()
	self.Mechanics:EndIslandContact() -- Release an existing simulated contact; no new attempt.
	self.Decision = nil -- Cancellation belongs to TaskScheduler. Request/backoff ledgers deliberately survive controls.
	self.Economics = nil -- A stopped/paused estimate must not appear current; existing samples survive for reevaluation.
end

function WorldProgressionManager:Completed(status, result, reason)
	self.Controller:Log("WORLD][RESULT", status .. " | " .. tostring(result and result.Name or "") .. " | " .. tostring(result and result.Reason or reason))
end

function WorldProgressionManager:GetStatus()
	return { Decision = self.Decision, Economics = self.Economics, SessionUnlockRequests = self.Mechanics.SessionUnlockRequests or 0,
		UnlockAttempts = table.clone(self.Mechanics.UnlockAttempts or {}), TravelFailures = table.clone(self.TravelFailures),
		IslandDiscoveryAttempts = table.clone(self.Mechanics.IslandDiscoveryAttempts), DiscoveryCapability = self.Mechanics:IslandDiscoveryCapability() }
end

return WorldProgressionManager

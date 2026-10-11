--!nonstrict
-- Pure Phase 3 action policy, called only by OCBrain. No character control or commands.
local TravelPlanner = {}

function TravelPlanner.Decide(config, snapshot, plan, context)
	local goal = plan and plan.Objective and plan.Objective.Metadata and plan.Objective.Metadata.Progression
	if not goal then return nil end -- Phase 2 retains its own approved decision path.
	local decision = { Kind = "WAIT", GoalId = plan.Objective.Id, Reason = goal.Reason, Node = goal.Node }
	if not goal.Node then return decision end
	local fresh = snapshot.ProgressionGraph and snapshot.ProgressionGraph.Next
	if not fresh or not goal.Node or fresh.Id ~= goal.Node.Id or fresh.Kind ~= goal.Node.Kind then
		decision.Reason = "Progression state changed; waiting for a fresh Brain objective" return decision
	end
	decision.Node = fresh
	if fresh.Kind == "ISLAND" and config.WORLD_SETTINGS.AUTO_DISCOVER_ISLANDS then
		if not context.CanInteract then decision.Reason = context.Blocker or "Native interaction guard blocks discovery"
		elseif not context.Discovery then decision.Reason = context.Blocker or "Loaded island discovery hitbox unavailable"
		elseif context.DiscoveryAttempts >= config.WORLD_SETTINGS.MAXIMUM_ISLAND_DISCOVERY_ATTEMPTS then decision.Reason = "Island contact attempt limit reached; no confirmed account discovery"
		elseif context.DiscoveryBackoff then decision.Reason = "Island discovery retry/global pacing; actual account flags still observed"
		else decision.Kind, decision.Reason = "DISCOVER_ISLAND", "Experimental runtime contact with the genuine island UnlockHitbox; awaiting correct LocalData acknowledgement" end
		return decision
	end
	if fresh.State == "BLOCKED" then decision.Reason = fresh.Blocker return decision end
	if fresh.State == "FUNDING" then
		if config.WORLD_SETTINGS.AUTO_FARM_UNLOCK_REQUIREMENTS then return nil end -- Existing goal-driven stationary collector.
		decision.Reason = "Actual world-cost shortage; AUTO_FARM_UNLOCK_REQUIREMENTS=false" return decision
	end
	if fresh.State ~= "READY" then return decision end
	local settings, cost = config.WORLD_SETTINGS, fresh.Cost
	if not settings.AUTO_UNLOCK_WORLDS then decision.Reason = "World affordable; AUTO_UNLOCK_WORLDS=false (no farming or spending)" return decision end
	if not table.find(settings.ALLOWED_UNLOCK_CURRENCIES, cost.Currency) or cost.Amount > settings.MAXIMUM_WORLD_UNLOCK_COST then
		decision.Reason = "World affordable; native cost/currency exceeds explicit unlock authorization" return decision
	end
	if context.SessionRequests >= settings.MAXIMUM_SESSION_WORLD_UNLOCKS then decision.Reason = "Controller lifetime unlock request limit reached" return decision end
	if context.UnlockAttempts >= settings.MAXIMUM_UNLOCK_ATTEMPTS then decision.Reason = "Per-world unlock request limit reached" return decision end
	if context.UnlockBackoff then decision.Reason = "World unlock request in retry backoff; actual acknowledgement still observed" return decision end
	if not context.Gate then decision.Reason = context.Blocker or "Live native gate unavailable" return decision end
	if not context.CanInteract then decision.Reason = context.Blocker or "Native interaction guard blocks progression" return decision end
	if context.Gate.InRange then decision.Kind, decision.Reason = "UNLOCK_WORLD", "Actual funds available and native gate activation range observed"
	elseif context.Gate.AtOriginIsland then decision.Reason = "At discovered gate island, outside native Activation.Root range; manual gate approach required; automatic walking is unsupported"
	elseif not settings.AUTO_TRAVEL_FOR_PROGRESSION then decision.Reason = "World affordable; native gate-island travel requires AUTO_TRAVEL_FOR_PROGRESSION=true"
	elseif context.TravelBackoff then decision.Reason = "Progression portal travel in retry backoff"
	elseif context.TravelFailures >= settings.MAXIMUM_TRAVEL_ATTEMPTS then decision.Reason = "Progression travel failure limit reached; manual travel required"
	elseif not context.Gate.Spawn and (not context.Gate.DestinationPath or #context.Gate.Zones == 0) then decision.Reason = "Native discovered-island portal arrival geometry unavailable; no unverified travel"
	else decision.Kind, decision.Reason = "TRAVEL_GATE_ISLAND", "Travel through the native portal to the already-discovered gate island" end
	return decision
end

return TravelPlanner

--!nonstrict
-- Session ledger and received-inventory verification; no timer, remote or task authority.
local PetPolicy = require(script.Parent.PetPolicy)
local HatchManager = {}
HatchManager.__index = HatchManager

function HatchManager.new(controller)
	return setmetatable({ Controller = controller, RequestedHatches = 0, RequestCost = 0, VerifiedHatches = 0,
		Once = controller.Config.HATCH_SETTINGS.HATCH_ONE_EGG_ONCE }, HatchManager)
end

function HatchManager:Ended()
	local settings = self.Controller.Config.HATCH_SETTINGS
	return self.EndReason ~= nil or self.Once and self.RequestedHatches >= 1
		or self.RequestedHatches >= settings.MAXIMUM_SESSION_HATCHES or self.RequestCost >= settings.MAXIMUM_SESSION_COST
		or (self.StartedAt ~= nil and os.clock() - self.StartedAt >= settings.MAXIMUM_SESSION_SECONDS)
end

function HatchManager:Observe(raw)
	local pending = self.Pending
	if not pending then return end
	local inv = PetPolicy.Inventory(raw)
	local gained, changes = 0, {}
	if inv then
		for id, pet in pairs(inv.ById) do
			local before = pending.Before[id]
			if pending.Pool[pet.Name] and (not before or before.Name == pet.Name and (before.Shiny == true) == (pet.Shiny == true)
				and (before.Mythic == true) == (pet.Mythic == true) and (before.XL == true) == (pet.XL == true)
				and PetPolicy.Equal(before.Super or false, pet.Super or false)) then
				local delta = (pet.Amount or 1) - (before and (before.Amount or 1) or 0)
				if delta > 0 then
					local variants = {} for _, flag in ipairs({ "Super", "XL", "Shiny", "Mythic" }) do if pet[flag] then table.insert(variants, flag) end end
					gained += delta
					table.insert(changes, { Id = id, Name = pet.Name, Quantity = delta, Variant = #variants > 0 and table.concat(variants, " ") or "Normal",
						Shiny = pet.Shiny == true, Mythic = pet.Mythic == true, XL = pet.XL == true, Super = pet.Super, ExistingStack = before ~= nil })
				end
			end
		end
	end
	table.sort(changes, function(a, b) return a.Id < b.Id end)
	local counter = raw and type(raw.EggsOpened) == "table" and raw.EggsOpened[pending.EggName] or nil
	local delta = PetPolicy.Finite(counter) and counter % 1 == 0 and counter - pending.Counter or nil
	local balances = {}
	for currency, before in pairs(pending.BeforeBalances or {}) do
		local after = raw and raw[currency]
		balances[currency] = { Before = before, After = after, Delta = PetPolicy.Finite(after) and after - before or nil }
	end
	pending.Observed = { CounterDelta = delta, MatchedQuantity = gained, Changes = changes, Balances = balances }
	local confirmed = delta ~= nil and delta >= pending.Count and gained >= pending.Count
	if confirmed or os.clock() >= pending.Deadline then
		-- Keep the detached native projection privately. It contains the exact
		-- pre-request owned-team benchmark; status exposes only its evidence.
		self.ResultBaseline = pending.UsefulnessBaseline
		self.LastResult = { Status = confirmed and "INVENTORY_GAIN_OBSERVED" or "UNCONFIRMED", EggName = pending.EggName,
			OwnerAllowance = pending.OwnerAllowance,
			Quantity = gained, RequestedQuantity = pending.Count, CounterBefore = pending.Counter, CounterAfter = counter, CounterDelta = delta, Changes = changes,
			BeforeBalance = pending.BeforeBalance, AfterBalance = raw and raw[pending.Currency], Balances = balances,
			TeamBefore = pending.TeamBefore, TeamAfter = inv and table.clone(inv.Team), TeamIndexBefore = pending.TeamIndex,
			TeamIndexAfter = inv and inv.TeamIndex, OCEquipmentCommands = 0,
			UsefulnessBaselineScore = pending.UsefulnessBaseline and pending.UsefulnessBaseline.Score,
			UsefulnessBaselineIds = pending.UsefulnessBaseline and table.clone(pending.UsefulnessBaseline.Ids),
			UsefulnessCurrency = pending.UsefulnessBaseline and pending.UsefulnessBaseline.Currency,
			UsefulnessSearchBoundReached = pending.UsefulnessBaseline and pending.UsefulnessBaseline.SearchBoundReached,
			UsefulnessProjectionFailures = pending.UsefulnessBaseline and pending.UsefulnessBaseline.ProjectionFailures,
			UsefulnessEvidence = "Frozen pre-hatch best feasible owned-team native projection; bounded greedy estimate, global optimum/server modifiers unverified",
			Attribution = "Matching received counter/inventory observations; external/manual activity cannot be excluded; balance change is separate evidence" }
		if confirmed then
			self.VerifiedHatches += pending.Count
			if delta ~= pending.Count or inv.TeamIndex ~= pending.TeamIndex or not PetPolicy.SameTeam(inv.Team, pending.TeamBefore) then
				self.Fault = "Hatch counter/team changed beyond the frozen request; external activity unresolved. No automatic continuation or retry"
				self.LastResult.Reason = self.Fault self.EndReason = self.Fault
			end
		else
			self.Fault = "Hatch acknowledgement timed out; rejection/delay/delivery unresolved. No automatic retry; request budget retained"
			self.LastResult.Reason = self.Fault self.EndReason = self.Fault
		end
		self.Pending = nil
		if self.Once and pending.OwnerAllowance then self.EndReason = self.EndReason or "Owner one-hatch allowance consumed; normal world reserve restored; no further spending" end
		if self.Once then self.EndReason = self.EndReason or "Single request consumed; hatch result observed; no further spending/equipment" end
	end
end

function HatchManager:ResultText()
	local r = self.LastResult
	if not r then return "No hatch result" end
	local pets, balances = {}, {}
	for _, change in ipairs(r.Changes or {}) do
		table.insert(pets, string.format("%s %s [%s] +%d%s; usefulness=%s; native gain=%s", change.Variant, change.Name, change.Id, change.Quantity,
			change.ExistingStack and " (existing stack)" or "", change.Usefulness or "UNKNOWN", tostring(change.ActualIncrement or "UNKNOWN")))
	end
	for _, currency in ipairs({ "Coins", "Gems", "Tickets", "Pearls" }) do
		local value = r.Balances and r.Balances[currency]
		if value then table.insert(balances, currency .. " net=" .. (value.Delta ~= nil and string.format("%+.3f", value.Delta) or "UNKNOWN")) end
	end
	local owner = r.OwnerAllowance
	local allowanceText = owner and string.format(" | owner allowance consumed; exact requested price=%s Coins; world reserve draw=%s; net debit=%s (attribution UNKNOWN); %s",
		tostring(owner.RequestedPrice), tostring(owner.WorldReserveBorrowed), tostring(owner.Result and owner.Result.ObservedNetDebit or "UNKNOWN"), tostring(owner.Persistence)) or ""
	return string.format("%s | %s | requested=%s; matching inventory +%s; egg counter delta=%s | baseline=%s %s pre-hatch owned-team estimate | %s | observed %s (net, attribution unknown) | OC equipment commands during hatch=0 | %s%s",
		r.EggName, r.Status, tostring(r.RequestedQuantity), tostring(r.Quantity), tostring(r.CounterDelta or "UNKNOWN"),
		tostring(r.UsefulnessBaselineScore or "UNKNOWN"), tostring(r.UsefulnessCurrency or "UNKNOWN"),
		#pets > 0 and table.concat(pets, "; ") or "No matching received pet", #balances > 0 and table.concat(balances, ", ") or "balances UNKNOWN",
		r.Reason or "Received hatch verified; an upgrade is not guaranteed. Request ledger retained", allowanceText)
end

function HatchManager:GetStatus()
	return { RequestedHatches = self.RequestedHatches, RequestCost = self.RequestCost, VerifiedHatches = self.VerifiedHatches,
		Pending = self.Pending and { EggName = self.Pending.EggName, Count = self.Pending.Count, Deadline = self.Pending.Deadline, Observed = self.Pending.Observed },
		Location = self.Location, Fault = self.Fault, LastResult = self.LastResult, BestHatch = self.BestHatch,
		SingleHatch = self.Once, Ended = self:Ended(), EndReason = self.EndReason }
end

return HatchManager

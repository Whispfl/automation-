--!nonstrict
-- Session ledger and received-inventory verification; no timer, remote or task authority.
local PetPolicy = require(script.Parent.PetPolicy)
local HatchManager = {}
HatchManager.__index = HatchManager

function HatchManager.new(controller)
	return setmetatable({ Controller = controller, RequestedHatches = 0, RequestCost = 0, VerifiedHatches = 0 }, HatchManager)
end

function HatchManager:Ended()
	local settings = self.Controller.Config.HATCH_SETTINGS
	return self.RequestedHatches >= settings.MAXIMUM_SESSION_HATCHES or self.RequestCost >= settings.MAXIMUM_SESSION_COST
		or (self.StartedAt ~= nil and os.clock() - self.StartedAt >= settings.MAXIMUM_SESSION_SECONDS)
end

function HatchManager:Observe(raw)
	local pending = self.Pending
	if not pending then return end
	local inv = PetPolicy.Inventory(raw)
	if inv then
		local gained, changes = 0, {}
		for id, pet in pairs(inv.ById) do
			local before = pending.Before[id]
			local amount = pet.Amount or 1
			if pending.Pool[pet.Name] and (not before or before.Name == pet.Name and before.Shiny == pet.Shiny
				and before.Mythic == pet.Mythic and before.XL == pet.XL and before.Super == pet.Super) then
				local delta = amount - (before and (before.Amount or 1) or 0)
				if delta > 0 then gained += delta table.insert(changes, { Id = id, Name = pet.Name, Quantity = delta }) end
			end
		end
		-- Inventory delta plus corresponding received hatch counter; manual/native
		-- actions can still contribute, so attribution remains qualified.
		local counter = type(raw.EggsOpened) == "table" and raw.EggsOpened[pending.EggName]
		if type(counter) == "number" and counter >= pending.Counter + pending.Count and gained >= pending.Count then
			self.VerifiedHatches += pending.Count
			self.LastResult = { Status = "INVENTORY_GAIN_OBSERVED", EggName = pending.EggName, Quantity = gained, Changes = changes,
				BeforeBalance = pending.BeforeBalance, AfterBalance = raw[pending.Currency], Attribution = "Matching received counter/inventory delta; external/manual activity cannot be excluded" }
			self.Pending = nil
			self.Controller:Log("PET][VERIFIED", pending.EggName .. " | actual inventory +" .. tostring(gained) .. "; hatch counter advanced; equipment unchanged by hatch verification")
			return
		end
	end
	if os.clock() >= pending.Deadline then
		self.Fault = "Hatch acknowledgement timed out; delivery/result unknown. No automatic retry; request budget retained"
		self.LastResult = { Status = "UNCONFIRMED", EggName = pending.EggName, Reason = self.Fault }
		self.Pending = nil self.Controller:Log("PET][BLOCKER", self.Fault)
	end
end

function HatchManager:GetStatus()
	return { RequestedHatches = self.RequestedHatches, RequestCost = self.RequestCost, VerifiedHatches = self.VerifiedHatches,
		Pending = self.Pending and { EggName = self.Pending.EggName, Count = self.Pending.Count, Deadline = self.Pending.Deadline },
		Location = self.Location, Fault = self.Fault, LastResult = self.LastResult, BestHatch = self.BestHatch }
end

return HatchManager

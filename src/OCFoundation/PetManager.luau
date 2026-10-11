--!nonstrict
-- Cooperative Phase 4 coordinator. Observations and action slices use the existing
-- Brain/scheduler; no hatching timer, movement loop or alternate account reader.
local Policy = require(script.Parent.PetPolicy)
local HatchManager = require(script.Parent.HatchManager)
local ProgressionGraph = require(script.Parent.ProgressionGraph)
local PetManager = {}
PetManager.__index = PetManager

local function cloneRecords(inv)
	local result = {}
	for id, pet in pairs(inv.ById) do result[id] = table.clone(pet) end
	return result
end

function PetManager.new(controller)
	local self = setmetatable({ Controller = controller, Config = controller.Config, EquipCommands = 0 }, PetManager)
	self.Hatch = HatchManager.new(controller)
	controller.Farming.Mechanics.HatchLocationProvider = function(area) return self:AtOwnedLocation(area) end
	controller.Farming.Mechanics.PetLocationOwnerProvider = function() return self.Hatch.Location ~= nil end
	return self
end

function PetManager:Fresh()
	local c = self.Controller
	local snapshot = c.Reader:GetSnapshot()
	local raw = c.Reader:GetLiveProfile()
	if raw then
		snapshot.Balances = c.Reader:ReadBalances()
		snapshot.UnlockedWorlds, snapshot.UnlockedIslands = raw.WorldsUnlocked, raw.AreasUnlocked
		-- Reserve all permanent progression definitions, independently of selected
		-- travel destinations or whether progression execution is enabled.
		local config = table.clone(self.Config) config.WORLD_SETTINGS = table.clone(config.WORLD_SETTINGS)
		config.WORLD_SETTINGS.SELECTED_WORLDS = {}
		snapshot.ProgressionGraph = ProgressionGraph.Build(config, snapshot, c.Knowledge:Get("Worlds"), snapshot.AvailableProgression)
	end
	local context = c.Knowledge:PetContext(snapshot, c.Plan, c.Farming.Tracker)
	return snapshot, context
end

function PetManager:Uncertain(reason)
	self.Fault = reason
	self.Controller:Log("PET][BLOCKER", reason)
end

function PetManager:Observe()
	local raw = self.Controller.Reader:GetLiveProfile()
	self.Hatch:Observe(raw) -- A missing profile must still expire an outstanding acknowledgement deadline.
	if self.Hatch.LastResult and self.Hatch.LastResult ~= self.LastHatchEvaluated and self.Hatch.LastResult.Changes then
		self.LastHatchEvaluated = self.Hatch.LastResult
		local _, context = self:Fresh()
		for _, change in ipairs(self.Hatch.LastResult.Changes) do
			local pet = context.Inventory and context.Inventory.ById[change.Id]
			local score = pet and context.PetScore and context.PetScore(pet)
			if Policy.Finite(score) and (not self.Hatch.BestHatch or self.Hatch.BestHatch.Currency ~= context.Currency or score > self.Hatch.BestHatch.Score) then
				self.Hatch.BestHatch = { Id = change.Id, Name = change.Name, Score = score, Currency = context.Currency,
					Quantity = change.Quantity, Evidence = "Native score of actually received inventory gain; attribution qualified" }
			end
		end
	end
	if self.Hatch.Fault then self.Fault = self.Hatch.Fault end
	if self.Transaction and not self.PendingEquip and os.clock() >= self.Transaction.Deadline then
		self:Uncertain("Equipment replacement continuation expired; inspect the actual partial team. No automatic restoration or retry")
		self.Transaction = nil
	end
	local pending = self.PendingEquip
	if not pending then return end
	local inv = Policy.Inventory(raw)
	if inv and inv.TeamIndex == pending.TeamIndex and Policy.SameTeam(inv.Team, pending.ExpectedIds) then
		self.PendingEquip = nil
		self.LastEquipment = { Status = "EQUIPPED_IDS_OBSERVED", Command = pending.Command, Id = pending.Id,
			BeforeIds = pending.BeforeIds, AfterIds = table.clone(inv.Team), TeamIndex = inv.TeamIndex,
			Attribution = "Exact received multiplicity observed; manual/external activity cannot be excluded" }
		self.Controller:Log("PET][VERIFIED", pending.Command .. " | actual equipped IDs acknowledged; team=" .. tostring(inv.TeamIndex))
		if pending.Command == "EquipPet" then self.Transaction = nil end
		return
	end
	if os.clock() >= pending.Deadline then
		self:Uncertain("Equipment acknowledgement timed out; team result unknown. No retry; command budget retained")
		self.LastEquipment = { Status = "UNCONFIRMED", Command = pending.Command, Id = pending.Id }
		self.PendingEquip, self.Transaction = nil, nil
	end
end

function PetManager:State()
	return { Pending = self.Hatch.Pending or self.PendingEquip, Fault = self.Fault, Location = self.Hatch.Location,
		SessionEnded = self.Hatch:Ended(), RequestCost = self.Hatch.RequestCost, RequestedHatches = self.Hatch.RequestedHatches,
		EquipCommands = self.EquipCommands, EquipmentContinuation = self.Transaction and not self.PendingEquip
			and { Kind = "TEAM_ADD", Transaction = self.Transaction, OwnsLocation = self.Hatch.Location ~= nil } or nil }
end

function PetManager:Analyze(force)
	local snapshot, context = self:Fresh()
	if force or not self.Report or os.clock() - (self.AnalysisAt or -math.huge) >= self.Config.PET_SETTINGS.ANALYSIS_INTERVAL_SECONDS then
		self.Report = self.Controller.Brain:AnalyzePets(snapshot, context)
		self.Report.Account = { Name = self.Controller.Reader.Player and self.Controller.Reader.Player.Name,
			UserId = self.Controller.Reader.Player and self.Controller.Reader.Player.UserId }
		self.AnalysisAt = os.clock()
		local team, egg = self.Report.Team, self.Report.RecommendedEgg
		local message = team.Status == "ESTIMATE" and string.format("%s team: %d records / %d pets; equipped=%d; native score %.3f -> %.3f (estimate)",
			tostring(team.Currency), team.RecordCount, team.Quantity, team.EquippedCount, team.CurrentScore, team.ProjectedScore)
			or "Team analysis UNKNOWN: " .. tostring(team.Reason)
		if egg then
			message ..= egg.Status == "ESTIMATE" and string.format(" | %s: %s %s; expected gain %.4f; useful base odds %.4f%% (client estimate); final odds/pity UNKNOWN",
				egg.Name, tostring(egg.Cost.Amount), egg.Cost.Currency, egg.ExpectedIncrement, egg.ClientImprovementProbability * 100)
				or " | " .. egg.Name .. ": UNKNOWN (" .. tostring(egg.Reason) .. ")"
			message ..= " | hatch cycle=" .. tostring(egg.EffectiveCycleSeconds or "UNKNOWN") .. "s; total time UNKNOWN"
		else
			message ..= " | No useful affordable egg estimate; native models=" .. tostring(#self.Report.Eggs)
			if self.Report.Eggs[1] then message ..= "; " .. tostring(self.Report.Eggs[1].Reason) end
		end
		message ..= " | hatch=" .. tostring(self.Config.PET_SETTINGS.AUTO_HATCH) .. "; equip=" .. tostring(self.Config.PET_SETTINGS.AUTO_EQUIP)
		if self.LastAnalysisMessage ~= message then self.Controller:Log("PET][ANALYSIS", message) self.LastAnalysisMessage = message end
	end
	return context
end

function PetManager:Select(plan)
	if not self.Config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE then return false end
	self:Observe()
	if self.Hatch:Ended() and not self.Hatch.Pending then
		local presentation = self.Controller.Knowledge:Get("HatchPresentation")
		local ok, active = pcall(function() return presentation:IsHatching() end)
		if self.Hatch.Location and (not ok or active ~= false) and os.clock() - self.Hatch.StartedAt < self.Config.HATCH_SETTINGS.MAXIMUM_SESSION_SECONDS then
			self.Decision = { Kind = "OBSERVE", OwnsLocation = true, Reason = "Bounded session ended; waiting for native hatch presentation before releasing location" }
			return true, self.Decision
		end
		self.Hatch.Location = nil
	end
	self:Analyze(false)
	if not self.Config.PET_SETTINGS.AUTO_HATCH and not self.Config.PET_SETTINGS.AUTO_EQUIP then
		self.Decision = { Kind = "WAIT", OwnsLocation = false, Reason = "Read-only pet intelligence; hatch/equipment disabled" }
		return false, self.Decision
	end
	-- Action recommendations always use fresh native projections, not cached diagnostics.
	local snapshot, context = self:Fresh()
	local report = self.Controller.Brain:AnalyzePets(snapshot, context)
	local decision = self.Controller.Brain:PlanPets(report, context, self:State())
	if decision.Kind == "HATCH" then
		self.Hatch.StartedAt = self.Hatch.StartedAt or os.clock()
		for _, egg in ipairs(context.Eggs) do
			if egg.Name == decision.EggName then self.Hatch.Location = self.Hatch.Location or
				{ EggName = egg.Name, Model = egg.Model, World = egg.World, Island = egg.Island } break end
		end
	end
	self.Decision = decision
	if decision.Kind == "WAIT" and not decision.OwnsLocation and not self.PendingEquip then self.Hatch.Location = nil end
	if decision.Reason and (decision.OwnsLocation or self.Config.PET_SETTINGS.AUTO_HATCH or self.Config.PET_SETTINGS.AUTO_EQUIP) then
		if self.LastReason ~= decision.Reason then self.Controller:Log("PET][BLOCKER", decision.Reason) self.LastReason = decision.Reason end
	end
	return decision.Kind ~= "WAIT" or decision.OwnsLocation, decision
end

function PetManager:AtOwnedLocation(area)
	local location = self.Hatch.Location
	if not location or not area or self.Controller.State ~= "RUNNING" or not self.Config.PET_SETTINGS.AUTO_HATCH
		or not self.Config.HATCH_SETTINGS.ENABLE_BACKGROUND_PICKUPS or self.Hatch:Ended() and not self.Hatch.Pending then return false end
	-- Manual movement updates eligible current area; never reposition the character.
	local model, root = location.Model, self.Controller.Farming.Tracker:Root()
	local part = model and model.Parent and model:IsDescendantOf(workspace) and model:FindFirstChild("Root")
	return part ~= nil and part:IsA("BasePart") and root ~= nil and (part.Position - root.Position).Magnitude <= 16
		and (location.Island or location.World) == area.Name and location.World == area.World
		and self.Controller.Farming.Mechanics:Unlocked(area.World, area.Name)
end

function PetManager:Prepare(decision, token)
	local config, c = self.Config, self.Controller
	if self.Fault or self.PendingEquip or self.Hatch.Pending then return nil, nil, nil, "Pending or uncertain result blocks dispatch" end
	if not config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE or not config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS
		or config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST then return nil, nil, nil, "Pet execution disabled" end
	local snapshot, context = self:Fresh()
	local inv = context.Inventory
	if not inv then return nil, nil, nil, context.Error end
	local function allowed()
		return c.State == "RUNNING" and (not token or not token:CheckCancelled())
	end
	if decision.Kind == "TEAM" or decision.Kind == "TEAM_ADD" then
		if not config.PET_SETTINGS.AUTO_EQUIP then return nil, nil, nil, "Team changes disabled" end
		local transaction = decision.Kind == "TEAM_ADD" and self.Transaction or decision
		if not transaction or inv.TeamIndex ~= transaction.TeamIndex then return nil, nil, nil, "Active team changed" end
		local expected = table.clone(transaction.BeforeIds)
		if decision.Kind == "TEAM_ADD" and transaction.RemoveId then table.remove(expected, table.find(expected, transaction.RemoveId)) end
		if not Policy.SameTeam(inv.Team, expected) then
			if self.Transaction then self:Uncertain("Manual/external equipment change interrupted replacement; no further command") self.Transaction = nil end
			return nil, nil, nil, "Equipped team changed; recompute before action"
		end
		local add, remove = inv.ById[transaction.AddId], inv.ById[transaction.RemoveId]
		if not add or add.Super or not (context.Pets or {})[add.Name] or not context.Pets[add.Name].Rarity then return nil, nil, nil, "Unsupported or unavailable replacement" end
		local final = transaction.AfterIds
		local score = context.ScoreTeam and context.ScoreTeam(final)
		local originalScore = context.ScoreTeam and context.ScoreTeam(transaction.BeforeIds)
		if not Policy.Finite(score) or not Policy.Finite(originalScore) or score <= originalScore + 1e-6 then return nil, nil, nil, "Replacement benefit no longer supported" end
		local counts = Policy.Counts(final)
		for id, count in pairs(counts) do if not inv.ById[id] or count > (inv.ById[id].Amount or 1) then return nil, nil, nil, "Owned replacement quantity changed" end end
		if not Policy.Finite(context.MaxEquipped) or #final > context.MaxEquipped then return nil, nil, nil, "Native team capacity changed" end
		local command, id, after = "EquipPet", add.Id, table.clone(final)
		if decision.Kind == "TEAM" and transaction.RemoveId then
			if not remove or remove.Super or Policy.Protected(config, remove) then return nil, nil, nil, "Protected pet cannot be removed" end
			command, id, after = "UnequipPet", remove.Id, table.clone(inv.Team)
			table.remove(after, table.find(after, remove.Id))
		end
		local needed = command == "UnequipPet" and 2 or 1
		if self.EquipCommands + needed > config.PET_SETTINGS.MAXIMUM_SESSION_EQUIP_COMMANDS then return nil, nil, nil, "Equipment command budget exhausted" end
		if not allowed() then return nil, nil, nil, "Cancelled before dispatch" end
		local guarded, guardReason = c.Farming.Mechanics:Guard()
		if not guarded or not allowed() then return nil, nil, nil, guardReason or "Cancelled before dispatch" end
		self.EquipCommands += 1
		if command == "UnequipPet" then
			transaction.Deadline = os.clock() + 2 * config.PET_SETTINGS.EQUIP_CONFIRMATION_TIMEOUT_SECONDS
			self.Transaction = transaction
		end
		self.PendingEquip = { Command = command, Id = id, BeforeIds = table.clone(inv.Team), ExpectedIds = after,
			TeamIndex = inv.TeamIndex, Deadline = os.clock() + config.PET_SETTINGS.EQUIP_CONFIRMATION_TIMEOUT_SECONDS }
		return command, id
	end
	if decision.Kind ~= "HATCH" or not config.PET_SETTINGS.AUTO_HATCH or self.Hatch:Ended() then return nil, nil, nil, "Hatch authorization/session ended" end
	local report = c.Brain:AnalyzePets(snapshot, context)
	local fresh = c.Brain:PlanPets(report, context, self:State())
	if fresh.Kind ~= "HATCH" or fresh.EggName ~= decision.EggName then return nil, nil, nil, "Fresh useful hatch/budget decision unavailable" end
	local egg for _, candidate in ipairs(context.Eggs) do if candidate.Name == decision.EggName then egg = candidate break end end
	if not egg or not egg.InRange then return nil, nil, nil, "Manual approach within native 16-stud egg range required; location retained without teleport" end
	local settings = config.HATCH_SETTINGS
	local count = math.min(decision.Count, fresh.Count)
	if egg.Unlocked ~= true then count = math.min(count, 1) end -- Native first hatch is one egg.
	local time, presentation = c.Knowledge:Get("Time"), c.Knowledge:Get("HatchPresentation")
	local scripts = c.Reader.Player and c.Reader.Player:FindFirstChild("PlayerScripts")
	local client = scripts and scripts:FindFirstChild("ClientScript")
	local status = client and client:FindFirstChild("GetAutoHatchStatus")
	if not time or type(time.now) ~= "function" or not presentation or type(presentation.IsHatching) ~= "function"
		or not status or not status:IsA("BindableFunction") then return nil, nil, nil, "Native hatch/time/auto-hatch guards unavailable" end
	local okAuto, active = pcall(function() return status:Invoke() end)
	local okHatch, hatching = pcall(function() return presentation:IsHatching() end)
	local okTime, now = pcall(time.now)
	local nextAt = c.Reader.Player:GetAttribute("NextEggOpenAt")
	if not okAuto or active ~= nil or not okHatch or hatching ~= false then return nil, nil, nil, "Native auto hatch/presentation active or unknown; no competing hatch command" end
	if not okTime or not Policy.Finite(now) or nextAt ~= nil and not Policy.Finite(nextAt)
		or nextAt and nextAt > now or os.clock() < (self.Hatch.NextRequestAt or 0) then return nil, nil, nil, "Native/session hatch cooldown or unknown time" end
	-- Refresh again after the native BindableFunction; it may yield. Re-evaluate
	-- current modifiers, native cost, free space, balances and progression reserve.
	snapshot, context = self:Fresh()
	inv = context.Inventory
	report = c.Brain:AnalyzePets(snapshot, context)
	fresh = c.Brain:PlanPets(report, context, self:State())
	if not inv or fresh.Kind ~= "HATCH" or fresh.EggName ~= egg.Name then return nil, nil, nil, "Account/authorization changed during native hatch guards" end
	local currentEgg for _, candidate in ipairs(context.Eggs) do if candidate.Name == egg.Name then currentEgg = candidate break end end
	if not currentEgg or currentEgg.Model ~= egg.Model or not currentEgg.InRange then return nil, nil, nil, "Native egg location changed during guards" end
	egg, count = currentEgg, math.min(count, fresh.Count)
	local raw = c.Reader:GetLiveProfile()
	if not raw or type(raw.EggsOpened) ~= "table" then return nil, nil, nil, "Native egg counter map unavailable" end
	local counter = raw.EggsOpened[egg.Name] or 0
	if not Policy.Finite(counter) then return nil, nil, nil, "Native egg counter unavailable" end
	local names = {} for _, entry in ipairs(egg.Pool) do names[entry.Item.Name] = true end
	if not allowed() then return nil, nil, nil, "Cancelled before dispatch" end
	local guarded, guardReason = c.Farming.Mechanics:Guard()
	if not guarded or not allowed() then return nil, nil, nil, guardReason or "Cancelled before dispatch" end
	-- A yielding native guard must not leave stale funds/inventory at dispatch.
	if not Policy.SameTeam((Policy.Inventory(raw) or {}).Team, inv.Team) or raw[egg.Cost.Currency] ~= snapshot.Balances[egg.Cost.Currency]
		then return nil, nil, nil, "Account changed during native hatch guards" end
	self.Hatch.RequestedHatches += count self.Hatch.RequestCost += egg.Cost.Amount * count
	self.Hatch.NextRequestAt = os.clock() + math.max(settings.MINIMUM_REQUEST_INTERVAL_SECONDS, egg.Duration)
	self.Hatch.Pending = { Before = cloneRecords(inv), Pool = names, Count = count, Counter = counter,
		EggName = egg.Name, Currency = egg.Cost.Currency, BeforeBalance = raw[egg.Cost.Currency], Deadline = os.clock() + settings.CONFIRMATION_TIMEOUT_SECONDS }
	return "HatchEgg", egg.Name, count
end

function PetManager:Definition(decision, generation)
	local c = self.Controller
	return { Id = "OC_GAMEPLAY", Owner = "PETS", Generation = generation, Priority = 60,
		CanRun = function() return c.State == "RUNNING" and generation == c.Generation end,
		Execute = function(token)
			if token:CheckCancelled() then return nil end
			local owns, fresh = self:Select(c.Plan)
			if not owns then return { Reason = "Pet intent ended" } end
			if fresh.Kind == "HATCH" or fresh.Kind == "TEAM" or fresh.Kind == "TEAM_ADD" then
				local sent, reason = c.Farming.Mechanics:PetAction(self, fresh, token)
				self.LastAction = { Requested = sent, Reason = reason }
				if not sent and self.LastDispatchBlocker ~= reason then c:Log("PET][BLOCKER", reason) self.LastDispatchBlocker = reason end
			end
			self:Observe()
			local area = c.Farming.Tracker.Current
			if self:AtOwnedLocation(area) and c.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS then
				local cluster = c.Farming.Tracker:Cluster("Coins")
				if cluster then
					c.Farming.Stationary:Collect({ Mode = "HATCH_PICKUPS", Cluster = cluster, HatchSpending = self.Hatch.Pending ~= nil }, token,
						function() return self:AtOwnedLocation(c.Farming.Tracker.Current) end)
				end
			end
			if not token:CheckCancelled() then task.wait(1) end -- Cooperative slice; prevents an unconfirmed/approach hot loop.
			return { Reason = "Pet observation/action slice; results require received account changes" }
		end,
		IsComplete = function(result) return type(result) == "table" end }
end

function PetManager:Completed() self:Observe() end
function PetManager:Halt()
	self.Hatch.Location = nil -- Pause/Stop release the lease, never reset request/command ledgers.
	if self.Transaction and not self.PendingEquip then self.Transaction = nil end
end
function PetManager:GetStatus()
	return { Enabled = self.Config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE, Analysis = self.Report, Decision = self.Decision,
		Hatch = self.Hatch:GetStatus(), EquipmentCommands = self.EquipCommands, PendingEquipment = self.PendingEquip,
		LastEquipment = self.LastEquipment, LastAction = self.LastAction, Fault = self.Fault,
		DestructiveActions = "OFF", ActionVerification = "OWNER_LIVE_PENDING" }
end
return PetManager

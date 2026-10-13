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

local function copyFacts(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copyFacts(entry) end
	return result
end

local function receivedProjection(baseline, change, inventory)
	if not baseline or not inventory or type(baseline.ScoreTeam) ~= "function" or not Policy.Finite(baseline.Score) then
		return nil, "Pre-hatch owned-team/native projection unavailable"
	end
	local pet, original = inventory.ById[change.Id], baseline.ById[change.Id]
	if not pet or pet.Name ~= change.Name or pet.Super or not (baseline.Definitions or {})[pet.Name]
		or not baseline.Definitions[pet.Name].Rarity or table.find(baseline.Config.PET_SETTINGS.PROTECTED_PET_IDS, pet.Id) then
		return nil, "Actual received pet is unavailable/unsupported/protected"
	end
	-- Replace only this received record in the detached PRE-hatch inventory.
	-- Unrelated later pets/stacks cannot make this hatch appear useful.
	local pets, candidate = copyFacts(baseline.Pets), copyFacts(pet)
	candidate.Amount = (original and (original.Amount or 1) or 0) + change.Quantity
	if candidate.Amount > (pet.Amount or 1) then return nil, "Received stack quantity changed during evaluation" end
	local found = false
	for index, record in pairs(pets) do if record.Id == pet.Id then pets[index] = candidate found = true break end end
	if not found then table.insert(pets, candidate) end
	local unchanged = baseline.ScoreTeam(baseline.Ids, pets)
	if not Policy.Finite(unchanged) or math.abs(unchanged - baseline.Score) > 1e-6 then
		return nil, "Original owned-team native score changed with received record; marginal hatch attribution UNKNOWN"
	end
	local best = unchanged
	if (Policy.Counts(baseline.Ids)[pet.Id] or 0) >= candidate.Amount then return best end
	for slot = 1, #baseline.Ids + (#baseline.Ids < baseline.MaxEquipped and 1 or 0) do
		local old = baseline.ById[baseline.Ids[slot]]
		local definition = old and (baseline.Definitions or {})[old.Name]
		if old and (old.Super or Policy.Protected(baseline.Config, old, definition) or not definition or not definition.Rarity) then continue end
		local ids = table.clone(baseline.Ids) ids[slot] = pet.Id
		local value = baseline.ScoreTeam(ids, pets)
		if not Policy.Finite(value) then return nil, "Actual received native team projection failed" end
		best = math.max(best, value)
	end
	return best
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
	local lease = c.EggTravel and c.EggTravel.Lease
	local retainedModel = lease and lease.Model or self.Hatch.Location and self.Hatch.Location.Model
	if not retainedModel and (self.Config.EGG_TRAVEL_SETTINGS.MODE or "NORMAL") == "TRAVEL_ONLY"
		and c.EggTravel and c.EggTravel.LastResult and c.EggTravel.LastResult.PhysicalArrivalVerified then
		retainedModel = c.EggTravel.BrainIntent and c.EggTravel.BrainIntent.Model
	end
	local context = c.Knowledge:PetContext(snapshot, c.Plan, c.Farming.Tracker, retainedModel)
	return snapshot, context
end

function PetManager:Uncertain(reason)
	self.Fault = reason
	if self.Controller.HatchTestAllowance then self.Controller.HatchTestAllowance:Uncertain(reason) end
	self.Controller:Log("PET][BLOCKER", reason)
	if self.Attempt and not self.Attempt.Ended then self:FinishAttempt("PARTIAL_OR_UNCONFIRMED", reason) end
end

function PetManager:FinishAttempt(status, reason)
	local attempt = self.Attempt
	if not attempt or attempt.Ended then return end
	attempt.Ended, attempt.Status, attempt.Reason = true, status, reason
	local _, context = self:Fresh()
	local inv = context.Inventory
	attempt.ActualTeamIndex, attempt.AfterIds = inv and inv.TeamIndex, inv and table.clone(inv.Team)
	attempt.AfterScore = inv and context.ScoreTeam and context.ScoreTeam(inv.Team) or nil
	attempt.ConfirmedTarget = inv ~= nil and inv.TeamIndex == attempt.TeamIndex and Policy.SameTeam(inv.Team, attempt.TargetIds or {})
	attempt.ActualPets = inv and context.ScoreTeam and Policy.Describe(self.Config, context, inv.Team) or nil
	attempt.Attribution = "Received LocalData membership/native client total; manual/external changes cannot be excluded; earnings gain unmeasured"
	self.Controller:Log("PET][EQUIP_RESULT", string.format("%s | team=%s -> %s | before IDs=%s | received IDs=%s | predicted %s -> %s; received native score=%s | commands=%d | %s | no more equip requests; earnings impact unmeasured",
		status, tostring(attempt.TeamIndex), tostring(attempt.ActualTeamIndex), table.concat(attempt.BeforeIds or {}, ","),
		attempt.AfterIds and table.concat(attempt.AfterIds, ",") or "UNKNOWN", tostring(attempt.BeforeScore or "UNKNOWN"), tostring(attempt.ProjectedScore or "UNKNOWN"),
		tostring(attempt.AfterScore or "UNKNOWN"), self.EquipCommands, reason))
end

function PetManager:PrintTeam()
	if not self.Config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE then return false, "Pet intelligence disabled" end
	self:Analyze(true)
	self.Controller:Log("PET][TEAM_DETAILS", Policy.TeamText(self.Report.Team, true), true)
	return true
end

function PetManager:Observe()
	local raw = self.Controller.Reader:GetLiveProfile()
	local player = self.Controller.Reader.Player
	if self.Controller.HatchTestAllowance then self.Controller.HatchTestAllowance:AccountValid() end
	if self.Hatch.UserId and (not player or player.UserId ~= self.Hatch.UserId) then
		if not self.Fault then self:Uncertain("Hatch account identity changed; received result belongs to an unknown account; no continuation") end
		raw = nil -- Preserve the outstanding ledger/deadline without attributing another account's inventory.
	end
	self.Hatch:Observe(raw) -- A missing profile must still expire an outstanding acknowledgement deadline.
	if self.Hatch.LastResult and self.Hatch.LastResult ~= self.LastHatchEvaluated then
		self.LastHatchEvaluated = self.Hatch.LastResult
		local _, context = self:Fresh()
		local inv = context.Inventory
		local result, baseline = self.Hatch.LastResult, self.Hatch.ResultBaseline
		result.UsefulReceivedCopies = 0
		for _, change in ipairs(result.Changes or {}) do
			local pet = context.Inventory and context.Inventory.ById[change.Id]
			local score = baseline and baseline.Currency == context.Currency and pet and context.PetScore and context.PetScore(pet)
			local received, reason
			if result.Status == "INVENTORY_GAIN_OBSERVED" then received, reason = receivedProjection(baseline, change, inv) end
			if Policy.Finite(received) and baseline then
				change.ActualIncrement = math.max(0, received - baseline.Score)
				change.UsefulnessEvaluatedCopies = 1 -- One native marginal, never multiply it by duplicate quantity.
				change.Usefulness = change.ActualIncrement > 1e-6 and "USEFUL_NATIVE_TEAM_ESTIMATE" or "NO_CURRENT_TEAM_IMPROVEMENT"
				if change.ActualIncrement > 1e-6 then result.UsefulReceivedCopies += 1 end
			else change.Usefulness, change.UsefulnessReason = "UNKNOWN", reason or "Received hatch confirmation unavailable" end
			if result.Status == "INVENTORY_GAIN_OBSERVED" and Policy.Finite(score)
				and (not self.Hatch.BestHatch or self.Hatch.BestHatch.Currency ~= context.Currency or score > self.Hatch.BestHatch.Score) then
				self.Hatch.BestHatch = { Id = change.Id, Name = change.Name, Score = score, Currency = context.Currency,
					Quantity = change.Quantity, Variant = change.Variant, ActualIncrement = change.ActualIncrement,
					Usefulness = change.Usefulness, Evidence = "Native score of actually received inventory gain; attribution qualified" }
			end
		end
		result.Continuation = (self.Fault or self.Hatch.Fault) and "BLOCKED_UNCERTAIN" or self.Hatch.Once and "SINGLE_HATCH_ENDED_EQUIPMENT_OFF"
			or result.UsefulReceivedCopies > 0 and self.Config.PET_SETTINGS.AUTO_EQUIP and "FRESH_OWNED_TEAM_REPLAN_REQUIRED"
			or self.Hatch:Ended() and "BOUNDED_HATCH_SESSION_ENDED" or "FRESH_BOUNDED_HATCH_REPLAN_REQUIRED"
		if self.Controller.HatchTestAllowance then
			self.Controller.HatchTestAllowance:Observe(result)
			if result.OwnerAllowance then result.OwnerAllowance = self.Controller.HatchTestAllowance:GetStatus().Record end
		end
		self.Controller:Log("HATCH_RESULT", self.Hatch:ResultText())
	end
	if self.Hatch.Fault then self.Fault = self.Hatch.Fault end
	local attempt = self.Attempt
	if attempt and not attempt.Ended then
		local inv = Policy.Inventory(raw)
		if os.clock() >= attempt.Deadline then self:Uncertain("One-time equipment wall-clock deadline expired; inspect partial/unknown team; no retry")
		elseif inv and (inv.TeamIndex ~= attempt.TeamIndex or not self.PendingEquip and not Policy.SameTeam(inv.Team, attempt.ExpectedIds)) then
			self:Uncertain("Manual/external team mismatch; frozen one-time plan abandoned")
		elseif not self.Config.PET_SETTINGS.AUTO_EQUIP or self.Config.PET_SETTINGS.AUTO_HATCH
			or not self.Config.PET_SETTINGS.EQUIP_OWNED_TEAM_ONCE then self:Uncertain("One-time equipment authorization changed; no further commands") end
	end
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
		self.Controller:Log("PET][VERIFIED", pending.Command .. " [" .. pending.Id .. "] | received IDs=" .. table.concat(inv.Team, ",") .. "; team=" .. tostring(inv.TeamIndex))
		if pending.Command == "EquipPet" then self.Transaction = nil end
		if attempt and not attempt.Ended then
			attempt.ExpectedIds = table.clone(inv.Team)
			if pending.Command == "EquipPet" then attempt.Step += 1 end
			if Policy.SameTeam(inv.Team, attempt.TargetIds) then self:FinishAttempt("TARGET_MEMBERSHIP_OBSERVED", "Frozen target multiplicity confirmed in LocalData") end
		end
		return
	end
	if attempt and not attempt.Ended and inv and (inv.TeamIndex ~= pending.TeamIndex
		or not Policy.SameTeam(inv.Team, pending.BeforeIds)) then
		self:Uncertain("Unexpected received equipment result/multiplicity; no retry or restoration")
		self.LastEquipment = { Status = "MISMATCH", AfterIds = table.clone(inv.Team), TeamIndex = inv.TeamIndex }
		self.PendingEquip, self.Transaction = nil, nil return
	end
	if os.clock() >= pending.Deadline then
		self:Uncertain("Equipment acknowledgement timed out; team result unknown. No retry; command budget retained")
		self.LastEquipment = { Status = "UNCONFIRMED", Command = pending.Command, Id = pending.Id }
		self.PendingEquip, self.Transaction = nil, nil
	end
end

function PetManager:State()
	return { Pending = self.Hatch.Pending or self.PendingEquip, Fault = self.Fault, Location = self.Hatch.Location,
		HatchPreflight = self.HatchPreflight,
		HatchOnce = self.Hatch.Once,
		SessionEnded = self.Hatch:Ended(), RequestCost = self.Hatch.RequestCost, RequestedHatches = self.Hatch.RequestedHatches,
		EquipCommands = self.EquipCommands, Attempt = self.Attempt, EquipmentContinuation = self.Transaction and not self.PendingEquip and not self.Fault and not (self.Attempt and self.Attempt.Ended)
			and { Kind = "TEAM_ADD", Transaction = self.Transaction, OwnsLocation = self.Hatch.Location ~= nil } or nil }
end

function PetManager:Analyze(force)
	local snapshot, context = self:Fresh()
	if force or not self.Report or os.clock() - (self.AnalysisAt or -math.huge) >= self.Config.PET_SETTINGS.ANALYSIS_INTERVAL_SECONDS then
		self.Report = self.Controller.Brain:AnalyzePets(snapshot, context)
		self.Report.Account = { Name = self.Controller.Reader.Player and self.Controller.Reader.Player.Name,
			UserId = self.Controller.Reader.Player and self.Controller.Reader.Player.UserId }
		self.AnalysisAt = os.clock()
		local team = self.Report.Team
		local message = team.Status == "ESTIMATE" and string.format("%s team: %d records / %d pets; equipped=%d; native score %.3f -> %.3f (estimate)",
			tostring(team.Currency), team.RecordCount, team.Quantity, team.EquippedCount, team.CurrentScore, team.ProjectedScore)
			or "Team analysis UNKNOWN: " .. tostring(team.Reason)
		message ..= " | hatch=" .. tostring(self.Config.PET_SETTINGS.AUTO_HATCH) .. "; equip=" .. tostring(self.Config.PET_SETTINGS.AUTO_EQUIP)
		if self.LastAnalysisMessage ~= message then self.Controller:Log("PET][ANALYSIS", message) self.LastAnalysisMessage = message end
		local eggPlan = Policy.EggPlanText(self.Config, self.Report, false)
		if self.LastEggPlan ~= eggPlan then
			self.Controller:Log("EGG_PLAN", eggPlan)
			if self.Config.HATCH_SETTINGS.LOG_EGG_DETAILS then self.Controller:Log("EGG_DETAILS", Policy.EggPlanText(self.Config, self.Report, true), true) end
			self.LastEggPlan = eggPlan
		end
		local teamMessage = Policy.TeamText(team, false)
		local details = Policy.TeamText(team, true)
		if self.LastTeamPlan ~= details then
			self.Controller:Log("PET][TEAM_PLAN", teamMessage)
			if self.Config.PET_SETTINGS.LOG_TEAM_DETAILS then self.Controller:Log("PET][TEAM_DETAILS", details, true) end
			self.LastTeamPlan = details
		end
	end
	return context, snapshot
end

-- Read-only readiness after the preserved physical travel test. This report
-- neither authorizes an action nor changes the Brain, travel lease or budgets.
function PetManager:ReportHatchPreflight(snapshot, context)
	local c, settings = self.Controller, self.Config
	local travel, result = c.EggTravel, c.EggTravel and c.EggTravel.LastResult
	if (settings.EGG_TRAVEL_SETTINGS.MODE or "NORMAL") ~= "TRAVEL_ONLY" or not result or result.PhysicalArrivalVerified ~= true then return end
	local intent = travel.BrainIntent
	if not intent or intent.EggName ~= "Common Egg" or not intent.Model then return end
	local player = c.Reader.Player
	local accountId, character = player and player.UserId, player and player.Character
	local raw = c.Reader:GetLiveProfile()
	local root = c.Farming.Tracker:Root()
	local eligible, native, nativeReason = c.Knowledge:NativeEggRangeEligible({ Model = intent.Model }, root, true)
	local registration
	if type(c.Knowledge.NativeEggRegistrationDiagnostics) == "function" then
		local ok, record = pcall(function() return c.Knowledge:NativeEggRegistrationDiagnostics(intent.Model) end)
		if ok and type(record) == "table" then registration = record end
	end
	local egg for _, value in ipairs(context and context.Eggs or {}) do
		if value.Name == intent.EggName and value.Model == intent.Model then egg = value break end
	end
	-- Native pricing is a read-only account/catalog quote. Missing registration
	-- must not disguise an available quote, and a quote grants no interaction proof.
	local definitions, stats = c.Knowledge:Get("Eggs"), c.Knowledge:Get("StatsUtil")
	local definition = type(definitions) == "table" and definitions[intent.EggName]
	local price, priceReason
	if not raw or not snapshot or snapshot.Ready ~= true then priceReason = "NATIVE_PRICE_ACCOUNT_UNAVAILABLE"
	elseif type(definition) ~= "table" then priceReason = "NATIVE_PRICE_DEFINITION_UNAVAILABLE"
	elseif not definition.World or definition.Event or definition.ProductId or definition.IsAdminEgg
		or intent.EggName == "Infinity Egg" or type(definition.Cost) ~= "table"
		or definition.Cost.Type ~= "Currency" or definition.Cost.Currency ~= "Coins"
		or not Policy.Finite(definition.Cost.Amount) or definition.Cost.Amount <= 0 then priceReason = "NATIVE_PRICE_UNSUPPORTED_DEFINITION"
	elseif not stats or type(stats.GetEggCost) ~= "function" then priceReason = "NATIVE_PRICE_HELPER_UNAVAILABLE"
	else
		local ok, quote = pcall(function() return stats:GetEggCost(player, copyFacts(raw), intent.EggName) end)
		if not ok then priceReason = "NATIVE_PRICE_HELPER_FAILED"
		elseif type(quote) ~= "table" or quote.Type ~= "Currency" or quote.Currency ~= "Coins"
			or not Policy.Finite(quote.Amount) or quote.Amount <= 0 then priceReason = "NATIVE_PRICE_INVALID_QUOTE"
		else price, priceReason = quote, "NATIVE_STATSUTIL_QUOTE" end
	end
	local coins = raw and raw.Coins
	local opened = raw and type(raw.EggsOpened) == "table" and (raw.EggsOpened[intent.EggName] or 0)
	local nextAt = player and player:GetAttribute("NextEggOpenAt")
	local time = c.Knowledge:Get("Time")
	local timeOK, now = pcall(function() return time and time.now() end)
	local free = context and Policy.Finite(context.StorageCapacity) and Policy.Finite(context.StorageUsed)
		and context.StorageCapacity - context.StorageUsed or nil
	local reason
	if settings.PET_SETTINGS.AUTO_HATCH or settings.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_HATCH_TEST_ALLOWANCE
		or self.Hatch.RequestedHatches > 0 or self.Hatch.RequestCost > 0 then reason = "Preflight requires hatch and exceptional allowance OFF; zero requests and spending"
	elseif not player or player.UserId ~= travel.BrainUserId then reason = "Current account differs from the physically arrived selection; readiness invalidated"
	elseif not snapshot or snapshot.Ready ~= true or not raw then reason = "Current account LocalData unavailable"
	elseif not eligible then reason = nativeReason or "Selected native hatch interaction unverified"
	elseif not egg then reason = "Exact selected native egg price/storage analysis unavailable"
	elseif not price or price.Type ~= "Currency" or price.Currency ~= "Coins" or not Policy.Finite(price.Amount)
		or price.Amount <= 0 or price.Amount > 10 then reason = "Current native Common Egg Coins price unavailable or above the prepared 10-Coin ceiling"
	elseif not Policy.Finite(coins) or coins < price.Amount then reason = "Insufficient actual Coins for the prepared one-egg price"
	elseif not Policy.Finite(opened) or opened % 1 ~= 0 then reason = "Current account egg-opened counter unavailable"
	elseif not context or context.InventoryFull ~= false or type(context.DigitalStorage) ~= "boolean"
		or not Policy.Finite(context.MaxHatches) or context.MaxHatches < 1
		or not context.DigitalStorage and (free == nil or free < 1) then reason = "Native inventory space or one-egg capacity unavailable/full"
	elseif not context.AutoDeleteKnown or context.AutoDeleteActive then reason = "Native auto-delete settings unknown or active; OC does not modify them"
	elseif not timeOK or not Policy.Finite(now) or nextAt ~= nil and not Policy.Finite(nextAt)
		or nextAt and nextAt > now then reason = "Native hatch cooldown active or time/cooldown unavailable"
	elseif not self:NativeHatchIdle() then reason = "Native hatch presentation or auto-hatch active/unavailable"
	else reason = "Ready for separately authorized ONE Common Egg request; allowance remains OFF; normal reserve unchanged; no spending permission" end
	local ready = reason:sub(1, 5) == "Ready"
	if ready and (c.Reader.Player ~= player or player.UserId ~= accountId or player.Character ~= character
		or c.Farming.Tracker:Root() ~= root or not Policy.Equal(c.Reader:GetLiveProfile(), context.AccountFacts)) then
		ready, reason = false, "Current account/character/profile changed during read-only native readiness guards"
	end
	local status = ready and "HATCH_PREFLIGHT_READY_ALLOWANCE_OFF" or "HATCH_PREFLIGHT_BLOCKED"
	local receiverSummary = registration and registration.ReceiverObservationSummary
	local before = { AccountId = accountId, InstanceId = native and native.IdentityId or intent.IdentityId or registration and registration.SelectedInstanceId,
		NativePrice = price and price.Amount, PriceReason = priceReason, Coins = coins, StorageUsed = context and context.StorageUsed,
		StorageCapacity = context and context.StorageCapacity, FreeStorage = free, DigitalStorage = context and context.DigitalStorage,
		EggsOpened = opened, NextEggOpenAt = nextAt, InteractionMode = native and native.InteractionMode,
		RegistrationReason = registration and (registration.Stage or registration.Reason) or "REGISTRATION_DIAGNOSTICS_UNAVAILABLE",
		RegistrationSummary = type(receiverSummary) == "string" and receiverSummary:match("^[^\n]+")
			or registration and registration.Summary or "native registration diagnostic unavailable" }
	self.HatchPreflight = { Status = status, Reason = reason, Before = before, Registration = registration, SpendingPermission = false }
	local message = string.format("%s | egg=%s; selected instance=%s; account=%s; native price=%s Coins (%s); current Coins=%s; storage=%s/%s; free=%s; digital=%s; EggsOpened=%s; NextEggOpenAt=%s; interaction=%s | %s | registration=%s; %s | hatch requests=%s; requested spending=%s",
		status, intent.EggName, tostring(before.InstanceId or "UNKNOWN"), tostring(before.AccountId or "UNKNOWN"),
		tostring(before.NativePrice or "UNKNOWN"), tostring(before.PriceReason), tostring(before.Coins or "UNKNOWN"), tostring(before.StorageUsed or "UNKNOWN"),
		tostring(before.StorageCapacity or "UNKNOWN"), tostring(before.FreeStorage or "UNKNOWN"), tostring(before.DigitalStorage),
		tostring(before.EggsOpened or "UNKNOWN"), tostring(before.NextEggOpenAt or "ABSENT"), tostring(before.InteractionMode or "UNKNOWN"), reason,
		tostring(before.RegistrationReason), tostring(before.RegistrationSummary),
		tostring(self.Hatch.RequestedHatches), tostring(self.Hatch.RequestCost))
	-- A new readiness/blocker/identity/quote appears immediately. Routine balance
	-- and capacity churn is coalesced under the existing diagnostic interval.
	local semantic = table.concat({ status, reason, tostring(before.InstanceId), tostring(before.AccountId),
		tostring(before.NativePrice), priceReason, tostring(before.InteractionMode), tostring(before.RegistrationReason) }, "|")
	local nowAt = os.clock()
	if self.LastHatchPreflightMessage ~= message and (self.LastHatchPreflightSemantic ~= semantic
		or nowAt - (self.LastHatchPreflightAt or -math.huge) >= settings.DIAGNOSTIC_SETTINGS.MINIMUM_LOG_INTERVAL_SECONDS) then
		c:Log("HATCH_PREFLIGHT", message)
		self.LastHatchPreflightMessage, self.LastHatchPreflightSemantic, self.LastHatchPreflightAt = message, semantic, nowAt
	end
	-- Candidate inventory is evidence only, including receivers that the trusted
	-- registry rejected. A changed completion/membership result appears once;
	-- native call-count churn uses the existing bounded reporting interval.
	if type(receiverSummary) == "string" and receiverSummary ~= "" then
		local receiverKey = tostring(registration.ReceiverObservationKey or registration.Stage or registration.Reason)
			.. "|complete=" .. tostring(registration.ReceiverObservationComplete == true)
		if self.LastEggReceiverObservationSummary ~= receiverSummary and (self.LastEggReceiverObservationKey ~= receiverKey
			or nowAt - (self.LastEggReceiverObservationAt or -math.huge) >= settings.DIAGNOSTIC_SETTINGS.MINIMUM_LOG_INTERVAL_SECONDS) then
			c:Log("NATIVE_EGG_RECEIVER_OBSERVATION", receiverSummary)
			self.LastEggReceiverObservationSummary, self.LastEggReceiverObservationKey, self.LastEggReceiverObservationAt = receiverSummary, receiverKey, nowAt
		end
	end
end

function PetManager:NativeHatchIdle()
	local c = self.Controller
	local presentation = c.Knowledge:Get("HatchPresentation")
	local scripts = c.Reader.Player and c.Reader.Player:FindFirstChild("PlayerScripts")
	local client = scripts and scripts:FindFirstChild("ClientScript")
	local status = client and client:FindFirstChild("GetAutoHatchStatus")
	local ok, idle = pcall(function()
		return presentation and type(presentation.IsHatching) == "function" and presentation:IsHatching() == false
			and status and status:IsA("BindableFunction") and status:Invoke() == nil
	end)
	return ok and idle == true
end

function PetManager:Select(plan)
	if not self.Config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE then return false end
	self:Observe()
	-- Received inventory can precede the native reveal. Retain the same location
	-- through this bounded idle observation before any new target/equipment plan.
	if self.Hatch.RequestedHatches > 0 and not self.Hatch.Pending and not self:NativeHatchIdle() then
		if os.clock() - (self.Hatch.StartedAt or os.clock()) >= self.Config.HATCH_SETTINGS.MAXIMUM_SESSION_SECONDS then
			if not self.Fault then self:Uncertain("Native hatch presentation/auto-hatch did not become idle within the bounded session; no continuation or movement") end
			self.Hatch.EndReason = self.Fault
			self.Decision = { Kind = "WAIT", OwnsLocation = self.Hatch.Location ~= nil, Reason = self.Fault }
		else self.Decision = { Kind = "OBSERVE", OwnsLocation = self.Hatch.Location ~= nil,
			Reason = "Received hatch confirmed; waiting for native presentation/auto-hatch idle before replanning" } end
		return true, self.Decision
	end
	if self.Hatch:Ended() and not self.Hatch.Pending then
		local presentation = self.Controller.Knowledge:Get("HatchPresentation")
		local ok, active = pcall(function() return presentation:IsHatching() end)
		if self.Hatch.Location and (not ok or active ~= false) and os.clock() - self.Hatch.StartedAt < self.Config.HATCH_SETTINGS.MAXIMUM_SESSION_SECONDS then
			self.Decision = { Kind = "OBSERVE", OwnsLocation = true, Reason = "Bounded session ended; waiting for native hatch presentation before releasing location" }
			return true, self.Decision
		end
		self.Hatch.Location = nil
	end
	local preflightContext, preflightSnapshot = self:Analyze(false)
	self:ReportHatchPreflight(preflightSnapshot, preflightContext)
	if not self.Config.PET_SETTINGS.AUTO_HATCH and not self.Config.PET_SETTINGS.AUTO_EQUIP then
		self.Decision = { Kind = "WAIT", OwnsLocation = false, Reason = "Read-only pet intelligence; hatch/equipment disabled" }
		return false, self.Decision
	end
	-- Action recommendations always use fresh native projections, not cached diagnostics.
	local snapshot, context = self:Fresh()
	local report = self.Controller.Brain:AnalyzePets(snapshot, context)
	local decision = self.Controller.Brain:PlanPets(report, context, self:State())
	if decision.Kind == "TEAM_ATTEMPT_START" or decision.Kind == "TEAM_ATTEMPT_END" then
		local team = report.Team
		self.Attempt = { Steps = decision.Steps or {}, Step = 1, TeamIndex = context.Inventory.TeamIndex,
			BeforeIds = table.clone(context.Inventory.Team), ExpectedIds = table.clone(context.Inventory.Team),
			TargetIds = table.clone(team.ProposedIds), BeforeScore = team.CurrentScore, ProjectedScore = team.ProjectedScore,
			Currency = context.Currency, MaxEquipped = context.MaxEquipped, BeforePets = team.CurrentPets,
			UserId = self.Controller.Reader.Player and self.Controller.Reader.Player.UserId,
			Deadline = os.clock() + self.Config.PET_SETTINGS.MAXIMUM_EQUIP_ATTEMPT_SECONDS }
		if decision.Kind == "TEAM_ATTEMPT_END" then self:FinishAttempt("NO_ACTION", decision.Reason)
		else self.Controller:Log("PET][TEAM_PLAN", "One authorized frozen owned-team attempt | commands required=" .. decision.RequiredCommands .. "; each result must be observed; no hatching/spending") end
		decision = self.Controller.Brain:PlanPets(report, context, self:State())
	end
	if decision.Kind == "HATCH" then
		self.Hatch.StartedAt = self.Hatch.StartedAt or os.clock()
		self.Hatch.UserId = self.Hatch.UserId or self.Controller.Reader.Player.UserId
		for _, egg in ipairs(context.Eggs) do
			if egg.Name == decision.EggName then
				local location = self.Hatch.Location
				if not location or location.EggName ~= egg.Name or location.Model ~= egg.Model then
					self.Hatch.Location = { EggName = egg.Name, Model = egg.Model, World = egg.World, Island = egg.Island,
						Currency = decision.Currency, SelectionMode = decision.SelectionMode }
				end
				break
			end
		end
	end
	self.Decision = decision
	if decision.Kind == "WAIT" and not decision.OwnsLocation and not self.PendingEquip then self.Hatch.Location = nil end
	if decision.Reason and (decision.OwnsLocation or self.Config.PET_SETTINGS.AUTO_HATCH or self.Config.PET_SETTINGS.AUTO_EQUIP) then
		if self.LastReason ~= decision.Reason then self.Controller:Log("PET][BLOCKER", decision.Reason) self.LastReason = decision.Reason end
	end
	return decision.Kind ~= "WAIT" or decision.OwnsLocation, decision
end

function PetManager:PickupCurrency()
	local metadata = self.Controller.Plan and self.Controller.Plan.Objective and self.Controller.Plan.Objective.Metadata
	if not metadata then return nil end
	local requirement = metadata.Requirement
	local currency = requirement and requirement.Currency or not requirement and metadata.Cost and metadata.Cost.Type == "Currency" and metadata.Cost.Currency
	return (currency == "Coins" or currency == "Gems") and currency or nil
end

function PetManager:BackgroundScopeValid(area, scope)
	local c, config, location = self.Controller, self.Config, self.Hatch.Location
	if not location or not area or c.State ~= "RUNNING" or not config.PET_SETTINGS.AUTO_HATCH
		or not config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE or not config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS
		or not config.HATCH_SETTINGS.ENABLE_BACKGROUND_PICKUPS or not config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS
		or self.Hatch:Ended() or self.Hatch.Once or self.Hatch.Pending or self.PendingEquip or self.Transaction
		or self.Fault or self.Hatch.Fault or not self:PickupCurrency() then return false end
	if self.Hatch.UserId and (not c.Reader.Player or c.Reader.Player.UserId ~= self.Hatch.UserId) then return false end
	if scope and (location ~= scope.Location or self:PickupCurrency() ~= scope.Currency or area.Key ~= scope.AreaKey
		or c.Generation ~= scope.Generation) then return false end
	if (location.Island or location.World) ~= area.Name or location.World ~= area.World
		or not c.Farming.Mechanics:Unlocked(area.World, area.Name) then return false end
	if config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL then
		local lease = c.EggTravel and c.EggTravel.Lease
		if not lease or lease.Status ~= "ARRIVED" or lease.Model ~= location.Model or lease.EggName ~= location.EggName
			or not lease.Deadline or os.clock() >= lease.Deadline or c.EggTravel.Blocked and c.EggTravel.Blocked[lease.SelectionKey] then return false end
	end
	local eligible = type(c.Knowledge.NativeEggRangeEligible) == "function"
		and c.Knowledge:NativeEggRangeEligible({ Model = location.Model }, c.Farming.Tracker:Root())
	return eligible == true
end

function PetManager:AtOwnedLocation(area)
	local scope = self.BackgroundPickup
	if not self:BackgroundScopeValid(area, scope) or not self:NativeHatchIdle() then return false end
	-- Native idle guards may yield. Recheck the actual objective/location last;
	-- a changed lease cannot fall back to ordinary Void/Zen collection.
	return self:BackgroundScopeValid(self.Controller.Farming.Tracker.Current, scope)
end

function PetManager:CollectBackground(token)
	local c, area = self.Controller, self.Controller.Farming.Tracker.Current
	if token:CheckCancelled() or not self:AtOwnedLocation(area) then return nil end
	local currency = self:PickupCurrency()
	local cluster = currency and c.Farming.Tracker:Cluster(currency)
	if not cluster then return nil end
	local scope = { Currency = currency, Location = self.Hatch.Location, AreaKey = area.Key, Generation = c.Generation }
	self.BackgroundPickup = scope
	-- The shared adapter's ordinary Void/Zen path must not become a fallback if
	-- its late provider check loses egg ownership. This scoped cancellation check
	-- remains inside the same foreground collector and its existing paced slice.
	local guardedToken = { CheckCancelled = function()
		return token:CheckCancelled() or not self:NativeHatchIdle() or not self:BackgroundScopeValid(c.Farming.Tracker.Current, scope)
	end }
	local ok, result = pcall(function()
		return c.Farming.Stationary:Collect({ Mode = "HATCH_PICKUPS", Currency = currency, Cluster = cluster, HatchSpending = false }, guardedToken,
			function() return self:AtOwnedLocation(c.Farming.Tracker.Current) end)
	end)
	self.BackgroundPickup = nil
	if not ok then error(result) end
	return result
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
	local function receivedHatchIdle()
		if self.Hatch.RequestedHatches == 0 then return true end -- Preserve the owner-tested owned-team-only path.
		local presentation = c.Knowledge:Get("HatchPresentation")
		local scripts = c.Reader.Player and c.Reader.Player:FindFirstChild("PlayerScripts")
		local client = scripts and scripts:FindFirstChild("ClientScript")
		local status = client and client:FindFirstChild("GetAutoHatchStatus")
		local ok, idle = pcall(function()
			return presentation and type(presentation.IsHatching) == "function" and presentation:IsHatching() == false
				and status and status:IsA("BindableFunction") and status:Invoke() == nil
		end)
		return ok and idle == true
	end
	if decision.Kind == "TEAM" or decision.Kind == "TEAM_ADD" then
		if self.Hatch.Once then return nil, nil, nil, "Isolated single-hatch controller never authorizes equipment" end
		if not config.PET_SETTINGS.AUTO_EQUIP then return nil, nil, nil, "Team changes disabled" end
		if not receivedHatchIdle() then return nil, nil, nil, "Received hatch presentation/native auto-hatch active or unknown; equipment waits" end
		if config.PET_SETTINGS.EQUIP_OWNED_TEAM_ONCE and os.clock() < (self.NextEquipAt or -math.huge) then return nil, nil, nil, "OC equipment request pacing; no native server cooldown assumed" end
		if config.PET_SETTINGS.EQUIP_OWNED_TEAM_ONCE then
			local attempt = self.Attempt
			if not attempt or attempt.Ended then return nil, nil, nil, "One-time equipment attempt not active" end
			if os.clock() >= attempt.Deadline or context.Currency ~= attempt.Currency or context.MaxEquipped ~= attempt.MaxEquipped
				or c.Reader.Player.UserId ~= attempt.UserId or config.PET_SETTINGS.AUTO_HATCH then
				self:Uncertain("Account/objective/capacity/authorization changed during one-time attempt") return nil, nil, nil, self.Fault
			end
			local step = attempt.Steps[attempt.Step]
			if decision.Kind == "TEAM" and decision ~= step or decision.Kind == "TEAM_ADD" and self.Transaction ~= step then return nil, nil, nil, "Stale equipment step" end
			local desired = Policy.Counts(attempt.TargetIds)
			for id, count in pairs(desired) do
				local pet = inv.ById[id]
				if not pet or count > (pet.Amount or 1) then self:Uncertain("Frozen target ownership/quantity changed") return nil, nil, nil, self.Fault end
			end
		end
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
		if table.find(config.PET_SETTINGS.PROTECTED_PET_IDS, add.Id) then self:Uncertain("Explicitly protected candidate cannot be touched") return nil, nil, nil, self.Fault end
		local final = transaction.AfterIds
		local score = context.ScoreTeam and context.ScoreTeam(final)
		local originalScore = context.ScoreTeam and context.ScoreTeam(transaction.BeforeIds)
		if not Policy.Finite(score) or not Policy.Finite(originalScore) or score <= originalScore + 1e-6 then return nil, nil, nil, "Replacement benefit no longer supported" end
		local counts = Policy.Counts(final)
		for id, count in pairs(counts) do if not inv.ById[id] or count > (inv.ById[id].Amount or 1) then return nil, nil, nil, "Owned replacement quantity changed" end end
		if not Policy.Finite(context.MaxEquipped) or #final > context.MaxEquipped then return nil, nil, nil, "Native team capacity changed" end
		local command, id, after = "EquipPet", add.Id, table.clone(final)
		if decision.Kind == "TEAM" and transaction.RemoveId then
			if not remove or remove.Super or Policy.Protected(config, remove, (context.Pets or {})[remove.Name]) then
				if self.Attempt then self:Uncertain("Protected pet cannot be removed: " .. tostring(remove and Policy.Protection(config, remove, context.Pets[remove.Name]))) end
				return nil, nil, nil, "Protected pet cannot be removed"
			end
			command, id, after = "UnequipPet", remove.Id, table.clone(inv.Team)
			table.remove(after, table.find(after, remove.Id))
		end
		local needed = command == "UnequipPet" and 2 or 1
		if self.EquipCommands + needed > config.PET_SETTINGS.MAXIMUM_SESSION_EQUIP_COMMANDS then return nil, nil, nil, "Equipment command budget exhausted" end
		if not allowed() then return nil, nil, nil, "Cancelled before dispatch" end
		local guarded, guardReason = c.Farming.Mechanics:Guard()
		if not guarded or not allowed() then return nil, nil, nil, guardReason or "Cancelled before dispatch" end
		if not receivedHatchIdle() or not allowed() then return nil, nil, nil, "Hatch presentation/authorization changed before equipment dispatch" end
		-- Guards/helpers may yield. Compare the actual account records and membership
		-- again, with no yield between this final check, ledger creation and dispatch.
		local live = c.Reader:GetLiveProfile()
		local liveInv = Policy.Inventory(live)
		local attempt = self.Attempt
		local authorizationChanged = not config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE or not config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS
			or Policy.Currency(config, c.Plan) ~= context.Currency
			or config.PICKUP_SETTINGS.STATIONARY_ISOLATED_TEST or not config.PET_SETTINGS.AUTO_EQUIP
			or table.find(config.PET_SETTINGS.PROTECTED_PET_IDS, add.Id) ~= nil
			or command == "UnequipPet" and Policy.Protected(config, remove, context.Pets[remove.Name])
			or self.EquipCommands + needed > config.PET_SETTINGS.MAXIMUM_SESSION_EQUIP_COMMANDS
			or attempt and (attempt.Ended or os.clock() >= attempt.Deadline or not config.PET_SETTINGS.EQUIP_OWNED_TEAM_ONCE
				or config.PET_SETTINGS.AUTO_HATCH or c.Reader.Player.UserId ~= attempt.UserId
				or Policy.Currency(config, c.Plan) ~= attempt.Currency)
		if not liveInv or liveInv.TeamIndex ~= inv.TeamIndex or not Policy.SameTeam(liveInv.Team, inv.Team)
			or not Policy.Equal(live, context.AccountFacts) or authorizationChanged or not allowed() then
			if self.Attempt then self:Uncertain("Account/equipment/protection changed during final native guards") end
			return nil, nil, nil, "Actual account changed before equipment dispatch"
		end
		self.EquipCommands += 1
		self.NextEquipAt = os.clock() + config.PET_SETTINGS.MINIMUM_EQUIP_COMMAND_INTERVAL_SECONDS
		if command == "UnequipPet" then
			transaction.Deadline = os.clock() + 2 * config.PET_SETTINGS.EQUIP_CONFIRMATION_TIMEOUT_SECONDS
			self.Transaction = transaction
		end
		self.PendingEquip = { Command = command, Id = id, BeforeIds = table.clone(inv.Team), ExpectedIds = after,
			TeamIndex = inv.TeamIndex, Deadline = os.clock() + config.PET_SETTINGS.EQUIP_CONFIRMATION_TIMEOUT_SECONDS }
		return command, id
	end
	if decision.Kind ~= "HATCH" or not config.PET_SETTINGS.AUTO_HATCH or self.Hatch:Ended() then return nil, nil, nil, "Hatch authorization/session ended" end
	if self.Hatch.Once then
		local reason = Policy.HatchIsolation(config)
		if reason then return nil, nil, nil, reason end
	end
	local authorization = copyFacts(config)
	local accountId = c.Reader.Player.UserId
	local dispatchCharacter = c.Reader.Player.Character
	local dispatchRoot = c.Farming.Tracker:Root()
	if not dispatchRoot then return nil, nil, nil, "Current character root unavailable before hatch guards; no request" end
	if self.Hatch.UserId and self.Hatch.UserId ~= accountId then return nil, nil, nil, "Hatch account changed; no dispatch" end
	local report = c.Brain:AnalyzePets(snapshot, context)
	local fresh = c.Brain:PlanPets(report, context, self:State())
	if fresh.Kind ~= "HATCH" or fresh.EggName ~= decision.EggName or not decision.Model or fresh.Model ~= decision.Model then
		return nil, nil, nil, "Fresh useful hatch/budget/exact selected egg decision unavailable"
	end
	local egg for _, candidate in ipairs(context.Eggs) do
		if candidate.Name == decision.EggName and candidate.Model == decision.Model then egg = candidate break end
	end
	if not egg or not egg.InRange then return nil, nil, nil, "Manual approach within native egg range required (unopened 6.5/opened 16 studs); location retained without teleport" end
	local ownerSettings = config.OWNER_ONE_HATCH_TEST_SETTINGS
	if ownerSettings and ownerSettings.OWNER_ONE_HATCH_TEST_ALLOWANCE then
		local allowance = c.HatchTestAllowance
		if not allowance then return nil, nil, nil, "Owner allowance ledger/service unavailable; no request" end
		local eligible, allowanceReason = allowance:Eligibility(egg.Name, egg.Cost.Amount, snapshot, snapshot.Balances.Coins, accountId)
		if not eligible then return nil, nil, nil, allowanceReason end
	end
	local settings = config.HATCH_SETTINGS
	local count = math.min(decision.Count, fresh.Count)
	if egg.Opened ~= true then count = math.min(count, 1) end -- Native first hatch is one egg.
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
	if not inv or fresh.Kind ~= "HATCH" or fresh.EggName ~= egg.Name or fresh.Model ~= egg.Model then
		return nil, nil, nil, "Account/authorization/exact egg changed during native hatch guards"
	end
	local currentEgg for _, candidate in ipairs(context.Eggs) do
		if candidate.Name == egg.Name and candidate.Model == egg.Model then currentEgg = candidate break end
	end
	if not currentEgg or currentEgg.Model ~= egg.Model or not currentEgg.InRange then return nil, nil, nil, "Native egg location changed during guards" end
	egg, count = currentEgg, math.min(count, fresh.Count)
	local raw = c.Reader:GetLiveProfile()
	if not raw or type(raw.EggsOpened) ~= "table" then return nil, nil, nil, "Native egg counter map unavailable" end
	local counter = raw.EggsOpened[egg.Name] or 0
	if not Policy.Finite(counter) or counter % 1 ~= 0 then return nil, nil, nil, "Native egg counter unavailable" end
	local names = {} for _, entry in ipairs(egg.Pool) do names[entry.Item.Name] = true end
	if not allowed() then return nil, nil, nil, "Cancelled before dispatch" end
	local guarded, guardReason = c.Farming.Mechanics:Guard()
	if not guarded or not allowed() then return nil, nil, nil, guardReason or "Cancelled before dispatch" end
	-- Recheck native guards/cost after the general guard, which may yield. No
	-- invocation, animation or cost deduction is accepted as a received pet.
	local finalAutoOK, finalAuto = pcall(function() return status:Invoke() end)
	local finalHatchOK, finalHatch = pcall(function() return presentation:IsHatching() end)
	local finalTimeOK, finalTime = pcall(time.now)
	local stats = c.Knowledge:Get("StatsUtil")
	local worldUtil = c.Knowledge:Get("WorldUtil")
	local costOK, finalCost = pcall(function() return stats:GetEggCost(c.Reader.Player, copyFacts(context.AccountFacts), egg.Name) end)
	local worldOK, finalWorld = pcall(function() return worldUtil:GetPlayerWorld(c.Reader.Player) end)
	local capacityOK, capacityAllows = pcall(function()
		local digital = stats:HasDigitalStorage(copyFacts(context.AccountFacts))
		local free = stats:GetMaxPetStorage(copyFacts(context.AccountFacts)) - stats:GetUsedPetStorage(copyFacts(context.AccountFacts))
		local maxHatches = stats:GetMaxEggHatches(copyFacts(context.AccountFacts))
		return stats:IsInventoryFull(copyFacts(context.AccountFacts)) == false and type(digital) == "boolean" and Policy.Finite(maxHatches) and maxHatches >= count
			and (digital and count == 1 or not digital and free >= count)
	end)
	local live = c.Reader:GetLiveProfile()
	local finalNextAt = c.Reader.Player:GetAttribute("NextEggOpenAt")
	local part = egg.Model.Parent and egg.Model:IsDescendantOf(workspace) and egg.Model:FindFirstChild("Root")
	local root = c.Farming.Tracker:Root()
	if not allowed() or self.Hatch:Ended() or self.Hatch.Pending or self.PendingEquip or self.Fault
		or not Policy.Equal(config, authorization) or c.Reader.Player.UserId ~= accountId
		or c.Reader.Player.Character ~= dispatchCharacter or root ~= dispatchRoot
		or not live or not Policy.Equal(live, context.AccountFacts) or live[egg.Cost.Currency] ~= snapshot.Balances[egg.Cost.Currency]
		then return nil, nil, nil, "Account/authorization changed during final hatch guards; no request" end
	if not capacityOK or capacityAllows ~= true then return nil, nil, nil, "Native inventory capacity changed during final guards; no request" end
	if not costOK or not Policy.Equal(finalCost, egg.Cost) or not worldOK or finalWorld ~= egg.World
		or not part or not part:IsA("BasePart") or not root
		or egg.Model:GetAttribute("Unlocked") ~= egg.Unlocked then return nil, nil, nil, "Native egg/cost/range changed during final guards; approach manually" end
	if not finalAutoOK or finalAuto ~= nil or not finalHatchOK or finalHatch ~= false
		or not finalTimeOK or not Policy.Finite(finalTime) or finalNextAt ~= nil and not Policy.Finite(finalNextAt)
		or finalNextAt and finalNextAt > finalTime then return nil, nil, nil, "Native hatch/cooldown changed during final guards; no request" end
	if decision.Model and decision.Model ~= egg.Model or fresh.Model and fresh.Model ~= egg.Model then
		return nil, nil, nil, "Brain-selected egg identity changed; no request"
	end
	local nativeEligible, nativeReason
	if type(c.Knowledge.NativeEggRangeEligible) == "function" then
		local nativeRecord
		nativeEligible, nativeRecord, nativeReason = c.Knowledge:NativeEggRangeEligible(egg, dispatchRoot, true)
	end
	if nativeEligible ~= true then return nil, nil, nil, nativeReason or "Fresh exact native hatch interaction eligibility unavailable; no request" end
	if config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL then
		local eligible, rangeReason
		if c.EggTravel then eligible, rangeReason = c.EggTravel:HatchEligible(egg) end
		if not eligible then return nil, nil, nil, rangeReason or "Selected egg arrival lease/native range unavailable; no request" end
	end
	if self.Hatch.Once and (count ~= 1 or Policy.HatchIsolation(config)) then return nil, nil, nil, "Single hatch authorization changed" end
	-- Arrival/range observation can call native helpers. Preserve the final
	-- account/config/cancellation barrier after that observation as well.
	if not allowed() or c.Reader.Player.UserId ~= accountId or not Policy.Equal(authorization, config)
		or c.Reader.Player.Character ~= dispatchCharacter or c.Farming.Tracker:Root() ~= dispatchRoot
		or Policy.Currency(config, c.Plan) ~= context.Currency
		or not Policy.Equal(c.Reader:GetLiveProfile(), context.AccountFacts) then
		return nil, nil, nil, "Account/budget/authorization changed during final arrival observation; no request"
	end
	local team = report.Team
	if not team or team.Status ~= "ESTIMATE" or not Policy.Finite(team.ProjectedScore) or not team.ProposedIds
		or not context.ScoreTeam then return nil, nil, nil, "Pre-hatch best feasible owned-team benchmark unavailable; no request" end
	local usefulnessBaseline = { Ids = table.clone(team.ProposedIds), Score = team.ProjectedScore, Currency = context.Currency,
		MaxEquipped = context.MaxEquipped, TeamIndex = inv.TeamIndex, Pets = copyFacts(context.AccountFacts.Pets),
		ById = cloneRecords(inv), Definitions = context.Pets, Config = { PET_SETTINGS = copyFacts(config.PET_SETTINGS) },
		ScoreTeam = context.ScoreTeam, SearchBoundReached = team.SearchBoundReached, ProjectionFailures = team.ProjectionFailures }
	local diagnosticBefore = { AccountId = accountId, InstanceId = egg.IdentityId,
		Coins = live.Coins, NativePrice = egg.Cost.Amount, RequestedCost = egg.Cost.Amount * count, Currency = egg.Cost.Currency,
		InventoryRecords = inv.Records, InventoryQuantity = inv.Quantity, StorageUsed = context.StorageUsed,
		StorageCapacity = context.StorageCapacity, DigitalStorage = context.DigitalStorage, NativeMaxHatches = context.MaxHatches,
		EggsOpened = counter, Opened = egg.Opened == true, NextEggOpenAt = finalNextAt, NativeNow = finalTime }
	local allowanceRecord
	if ownerSettings and ownerSettings.OWNER_ONE_HATCH_TEST_ALLOWANCE then
		local beforeInventory = {}
		for id, pet in pairs(inv.ById) do beforeInventory[id] = { Name = pet.Name, Amount = pet.Amount or 1,
			Shiny = pet.Shiny == true, Mythic = pet.Mythic == true, XL = pet.XL == true, Super = copyFacts(pet.Super) } end
		local consumed, allowanceReason, record = c.HatchTestAllowance:Consume(egg.Name, egg.Cost.Amount, snapshot, live.Coins, accountId,
			{ EggCounter = counter, Inventory = beforeInventory, PoolNames = copyFacts(names), TeamIndex = inv.TeamIndex,
				DiagnosticBefore = copyFacts(diagnosticBefore),
				TeamIds = table.clone(inv.Team), OwnedBenchmarkIds = table.clone(team.ProposedIds), OwnedBenchmarkScore = team.ProjectedScore,
				Balances = { Coins = live.Coins, Gems = live.Gems }, ConfirmationDeadline = os.clock() + settings.CONFIRMATION_TIMEOUT_SECONDS })
		if not consumed then return nil, nil, nil, allowanceReason end
		allowanceRecord = record -- Consumption is irrevocable in this client VM, including invocation failure.
	end
	self.Hatch.UserId = accountId
	self.Hatch.StartedAt = self.Hatch.StartedAt or os.clock()
	self.Hatch.RequestedHatches += count self.Hatch.RequestCost += egg.Cost.Amount * count
	self.Hatch.NextRequestAt = os.clock() + math.max(settings.MINIMUM_REQUEST_INTERVAL_SECONDS, egg.Duration)
	local balances = {} for _, currency in ipairs({ "Coins", "Gems", "Tickets", "Pearls" }) do if Policy.Finite(live[currency]) then balances[currency] = live[currency] end end
	self.Hatch.Pending = { Before = cloneRecords(inv), Pool = names, Count = count, Counter = counter,
		DiagnosticBefore = diagnosticBefore,
		UsefulnessBaseline = usefulnessBaseline,
		OwnerAllowance = allowanceRecord,
		EggName = egg.Name, Currency = egg.Cost.Currency, BeforeBalance = live[egg.Cost.Currency], BeforeBalances = balances,
		TeamBefore = table.clone(inv.Team), TeamIndex = inv.TeamIndex, Deadline = os.clock() + settings.CONFIRMATION_TIMEOUT_SECONDS }
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
			local actionSent = false
			if fresh.Kind == "HATCH" or fresh.Kind == "TEAM" or fresh.Kind == "TEAM_ADD" then
				local sent, reason = c.Farming.Mechanics:PetAction(self, fresh, token)
				actionSent = sent == true
				self.LastAction = { Requested = sent, Reason = reason }
				if sent == true and fresh.Kind == "HATCH" and self.Hatch.Pending
					and self.LastLoggedHatchRequest ~= self.Hatch.RequestedHatches then
					self.LastLoggedHatchRequest = self.Hatch.RequestedHatches
					-- Emit only after the real shared adapter returns. Captured BEFORE
					-- facts are not a claim of server acceptance or successful delivery.
					pcall(function()
						local pending = self.Hatch.Pending
						local before = pending.DiagnosticBefore or {}
						local free = Policy.Finite(before.StorageCapacity) and Policy.Finite(before.StorageUsed)
							and before.StorageCapacity - before.StorageUsed or nil
						c:Log("HATCH_BEFORE_SNAPSHOT", string.format("Captured before invocation | account=%s; egg=%s; selected instance=%s; native price=%s %s; Coins=%s; inventory=%s records/%s pets; storage=%s/%s; free=%s; digital=%s; native batch capacity=%s; EggsOpened=%s; NextEggOpenAt=%s",
							tostring(before.AccountId or "UNKNOWN"), pending.EggName, tostring(before.InstanceId or "UNKNOWN"),
							tostring(before.NativePrice or "UNKNOWN"), tostring(before.Currency or "UNKNOWN"), tostring(before.Coins or "UNKNOWN"),
							tostring(before.InventoryRecords or "UNKNOWN"), tostring(before.InventoryQuantity or "UNKNOWN"),
							tostring(before.StorageUsed or "UNKNOWN"), tostring(before.StorageCapacity or "UNKNOWN"), tostring(free or "UNKNOWN"),
							tostring(before.DigitalStorage), tostring(before.NativeMaxHatches or "UNKNOWN"), tostring(before.EggsOpened or "UNKNOWN"),
							tostring(before.NextEggOpenAt or "ABSENT")))
						c:Log("HATCH_REQUEST_ATTEMPTED", string.format("Native HatchEgg invocation attempted | egg=%s; selected instance=%s; count=%s; requested total=%s; requested cost=%s %s | %s | acceptance/delivery await received current-account LocalData; no uncertain retry",
							pending.EggName, tostring(before.InstanceId or "UNKNOWN"), tostring(pending.Count), tostring(self.Hatch.RequestedHatches),
							tostring(before.RequestedCost or "UNKNOWN"), tostring(before.Currency or "UNKNOWN"), tostring(reason)))
					end)
				end
				if not sent and self.LastDispatchBlocker ~= reason then c:Log("PET][BLOCKER", reason) self.LastDispatchBlocker = reason end
			end
			self:Observe()
			if not actionSent then self:CollectBackground(token) end
			if not token:CheckCancelled() then task.wait(1) end -- Cooperative slice; prevents an unconfirmed/approach hot loop.
			return { Reason = "Pet observation/action slice; results require received account changes" }
		end,
		IsComplete = function(result) return type(result) == "table" end }
end

function PetManager:Completed() self:Observe() end
function PetManager:Halt(stopped)
	self.Hatch.Location = nil -- Pause/Stop release the lease, never reset request/command ledgers.
	if self.Controller.HatchTestAllowance then self.Controller.HatchTestAllowance:Halt(stopped) end
	if stopped and self.Config.PET_SETTINGS.EQUIP_OWNED_TEAM_ONCE then
		self.Attempt = self.Attempt or { BeforeIds = {}, TargetIds = {} }
		self:FinishAttempt("STOPPED", "Owner stopped equipment test; any dispatched request may still be received; no automatic continuation")
	end
	if stopped and self.Hatch.Once then self.Hatch.EndReason = "Owner stopped single-hatch test; no new request; dispatched request cannot be recalled" end
	if self.Transaction and not self.PendingEquip and not self.Attempt then self.Transaction = nil end
end
function PetManager:GetStatus()
	return { Enabled = self.Config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE, Analysis = self.Report, Decision = self.Decision,
		Hatch = self.Hatch:GetStatus(), EquipmentCommands = self.EquipCommands, PendingEquipment = self.PendingEquip,
		LastEquipment = self.LastEquipment, LastAction = self.LastAction, Fault = self.Fault,
		EquipmentAttempt = self.Attempt,
		DestructiveActions = "OFF", ActionVerification = "OWNER_LIVE_PENDING" }
end
return PetManager

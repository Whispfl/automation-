--!nonstrict
-- Selected-location ledger and scene observation. Only the existing scheduler
-- executes its task; native transport/direct transforms stay in GameMechanics.
local EggTravelManager = {}
EggTravelManager.__index = EggTravelManager
local Standing = require(script.Parent.EggStandingGeometry)

local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
local function vector(v) return v ~= nil and finite(v.X) and finite(v.Y) and finite(v.Z) end
local function live(part)
	return part ~= nil and part.Parent ~= nil and part:IsA("BasePart") and part:IsDescendantOf(workspace)
end
local function child(parent, name) return parent and parent:FindFirstChild(name) end
local function selected(config, intent)
	local names = config.HATCH_SETTINGS and config.HATCH_SETTINGS.SELECTED_EGGS
	local mode = config.HATCH_SETTINGS and config.HATCH_SETTINGS.EGG_SELECTION_MODE or "MANUAL"
	if intent then
		local diagnostic = (config.EGG_TRAVEL_SETTINGS.MODE or "NORMAL") == "TRAVEL_ONLY"
		local contract = diagnostic and intent.Kind == "EGG_TRAVEL" and intent.Scope == "TRAVEL_ONLY"
			and intent.DecisionSource == "BRAIN_TRAVEL_DIAGNOSTIC"
			or not diagnostic and intent.Kind == "HATCH" and intent.DecisionSource == "BRAIN" and intent.Scope ~= "TRAVEL_ONLY"
		if not contract or intent.SelectionMode ~= mode
			or type(intent.EggName) ~= "string" or intent.EggName == "" then return nil, "Fresh Brain hatch destination unavailable or stale" end
		if mode == "MANUAL" and not table.find(names or {}, intent.EggName) then return nil, "Manual egg authorization changed" end
		return intent.EggName
	end
	if (config.EGG_TRAVEL_SETTINGS.MODE or "NORMAL") == "TRAVEL_ONLY" then return nil, "TRAVEL_ONLY requires a read-only Brain destination" end
	if mode == "AUTO" then return nil, "AUTO travel requires an actual useful affordable Brain decision; no random destination" end
	if type(names) ~= "table" or #names ~= 1 or type(names[1]) ~= "string" or names[1] == "" then
		return nil, "Egg travel requires exactly one explicitly selected egg"
	end
	return names[1]
end

function EggTravelManager.new(controller)
	return setmetatable({ Controller = controller, Attempts = {}, Blocked = {}, Sequence = 0 }, EggTravelManager)
end

function EggTravelManager:Settings() return self.Controller.Config.EGG_TRAVEL_SETTINGS end
function EggTravelManager:Report(message, key, force)
	-- Planning may revisit an unchanged preflight blocker every second. Keep a
	-- bounded set of report keys so interleaved messages cannot defeat dedup.
	local now = os.clock()
	self.ReportTimes, self.ReportOrder = self.ReportTimes or {}, self.ReportOrder or {}
	key = key or message
	local previous = self.ReportTimes[key]
	if not force and previous and now - previous < 30 then return false end
	if previous == nil then
		table.insert(self.ReportOrder, key)
		if #self.ReportOrder > 32 then self.ReportTimes[table.remove(self.ReportOrder, 1)] = nil end
	end
	self.ReportTimes[key], self.LastReport = now, message
	if type(self.Controller.Log) == "function" then self.Controller:Log("EGG_TRAVEL", message) end
	return true
end
function EggTravelManager:DiagnosticTrace(event, record, reason)
	if (self:Settings().MODE or "NORMAL") ~= "TRAVEL_ONLY" then return end
	if event == "PREFLIGHT_BLOCKED" then
		self.Reason, self.LastPreflightReason = reason, reason
	elseif event == "TARGET_SELECTED" then
		self.Reason, self.LastPreflightReason = nil, nil
	end
	local intent = self.BrainIntent or {}
	local distance = record and finite(record.Distance) and string.format("%.2f", record.Distance) or "UNKNOWN"
	if record and record.LocationOnly and record.StandingDestination and vector(record.CharacterRoot.Position) and vector(record.TargetRoot.Position) then
		distance = string.format("%.2f horizontal; %.2f 3D", Vector3.new(record.CharacterRoot.Position.X - record.TargetRoot.Position.X, 0, record.CharacterRoot.Position.Z - record.TargetRoot.Position.Z).Magnitude,
			(record.CharacterRoot.Position - record.TargetRoot.Position).Magnitude)
	end
	local name, world = tostring(record and record.EggName or intent.EggName or "UNSELECTED"), tostring(record and record.World or intent.World or "UNKNOWN")
	local island = tostring(record and record.Island or intent.Island or "surface/UNKNOWN")
	local generation = tostring(record and record.Generation or intent.Generation or self.Controller.Generation or "UNKNOWN")
	local revision = tostring(intent.SelectionRevision or self:Settings().SELECTION_REVISION)
	reason = reason or "Observation pending; server acceptance unverified"
	local model = record and record.Model or intent.Model
	local identity = record and record.IdentityId
	if not record then identity = intent.IdentityId end
	if identity == nil and model ~= nil then
		-- Instance tostring/GetFullName do not distinguish duplicate names/paths.
		-- This fallback is a local logging ID only, never target authorization.
		self.DiagnosticModelIds = self.DiagnosticModelIds or setmetatable({}, { __mode = "k" })
		if self.DiagnosticModelIds[model] == nil then
			self.DiagnosticModelSequence = (self.DiagnosticModelSequence or 0) + 1
			self.DiagnosticModelIds[model] = self.DiagnosticModelSequence
		end
		identity = "LOCAL_MODEL_" .. tostring(self.DiagnosticModelIds[model])
	end
	-- Different blocker/candidate messages remain independently throttled. Only
	-- a real non-blocked stage transition permits an immediate blocker recurrence.
	if event ~= "PREFLIGHT_BLOCKED" and event ~= "TRAVEL_BLOCKED" and event ~= self.LastDiagnosticStage then
		self.DiagnosticReportEpoch = (self.DiagnosticReportEpoch or 0) + 1
	end
	self.LastDiagnosticStage = event
	local key = table.concat({ tostring(self.DiagnosticReportEpoch or 0), event, name, world, island, generation, revision, tostring(identity or "UNRESOLVED"), reason }, "|")
	self.DiagnosticEventKeys = self.DiagnosticEventKeys or {}
	if self.DiagnosticEventKeys[event] == key then return end
	self.DiagnosticEventKeys[event] = key
	-- Fresh geometry records do not carry the lease's adapter-attempt ledger.
	local attempted = self.Lease or self.LastResult or record
	local direct = event ~= "PREFLIGHT_BLOCKED" and attempted and attempted.DirectPositionAttempted == true
	local native = event ~= "PREFLIGHT_BLOCKED" and attempted and attempted.NativeTravelAttempted == true
	local evidence = record and (record.LocationOnly and "access=LocalData unlock membership; location=verified native physical original Root; physical radius is diagnostic policy, hatch eligibility separate"
		or "access=LocalData unlock membership + resolved native egg; geometry=actual Root/Prompt; clearance/arrival verified separately")
		or "access/instance/standing geometry=preflight unresolved; no arrival claimed"
	if record and record.LocationOnly and record.StandingDestination then evidence ..= "; radius is horizontal near-Root; verified support/standing height required" end
	self:Report(string.format("%s | egg=%s; instance=%s | world=%s; island=%s | generation=%s; revision=%s | distance=%s; %s radius=%s | %s | %s | direct attempts=%d; native travel attempts=%d; hatch commands=0; spending=0",
		event, name, tostring(identity or "UNRESOLVED"), world, island, generation, revision, distance, record and record.LocationOnly and "physical policy" or "native", tostring(record and record.Range or "UNKNOWN"), evidence, reason,
		direct and 1 or 0, native and 1 or 0), "DIAGNOSTIC:" .. key)
end
function EggTravelManager:Key()
	local name, reason = selected(self.Controller.Config, self.BrainIntent)
	if not name then return nil, reason end
	local prefix = self.BrainIntent and self.BrainIntent.SelectionMode == "AUTO" and "AUTO:" or ""
	return prefix .. name .. ":" .. tostring((self:Settings() or {}).SELECTION_REVISION or 0), nil, name
end

function EggTravelManager:ReportInstanceDiagnostics(diagnostics, expandedRequested)
	if (self:Settings().MODE or "NORMAL") ~= "TRAVEL_ONLY" then return end
	local knowledge = self.Controller.Knowledge
	local expanded = expandedRequested == true or self.Controller.Config.DIAGNOSTIC_SETTINGS.ENABLE_DEBUG_LOGGING == true
	local diagnosticScope = expanded and "EXPLICIT_EXPANDED" or "UNSELECTED_DIAGNOSTIC_SAMPLE"
	local function position(part)
		return part and vector(part.Position) and string.format("(%.3f,%.3f,%.3f)", part.Position.X, part.Position.Y, part.Position.Z) or "ABSENT/UNKNOWN"
	end
	local names = {} for name in pairs(diagnostics or {}) do table.insert(names, name) end table.sort(names)
	if not expanded then
		local selectedName = self.BrainIntent and self.BrainIntent.EggName
		if not selectedName and self.Controller.Config.HATCH_SETTINGS.EGG_SELECTION_MODE == "MANUAL" then
			selectedName = self.Controller.Config.HATCH_SETTINGS.SELECTED_EGGS[1]
		end
		if selectedName and diagnostics and diagnostics[selectedName] then diagnosticScope = "SELECTED_TARGET" end
		-- A blocked Brain may have no selected target. One clearly labelled sample
		-- exposes the evidence gap without turning a diagnostic name into authority.
		selectedName = selectedName and diagnostics and diagnostics[selectedName] and selectedName or names[1]
		names = selectedName and diagnostics and diagnostics[selectedName] and { selectedName } or {}
	end
	self.InstanceDiagnosticReports = self.InstanceDiagnosticReports or {}
	self.InstanceDiagnosticReportOrder = self.InstanceDiagnosticReportOrder or {}
	for index, name in ipairs(names) do
		if index > 40 then break end
		local observation, lines = diagnostics[name], {}
		local candidates = table.clone(observation.Candidates or {})
		if not expanded then
			table.sort(candidates, function(a, b)
				local function rank(candidate) return candidate.LocationVerified and 3 or candidate.Verified and 2 or candidate.Root and 1 or 0 end
				if rank(a) ~= rank(b) then return rank(a) > rank(b) end
				return tostring(a.IdentityId) < tostring(b.IdentityId)
			end)
		end
		for candidateIndex, candidate in ipairs(candidates) do
			if candidateIndex > (expanded and 20 or 4) then break end
			local model, ancestry, attrs = candidate.Model, {}, {}
			local ancestor = model and model.Parent
			if expanded then
				for _ = 1, 8 do
					if not ancestor or not ancestor.Name then break end
					table.insert(ancestry, ancestor.Name .. "[" .. knowledge:InstanceId(ancestor) .. "]") ancestor = ancestor.Parent
				end
				for _, key in ipairs({ "World", "Island", "Unlocked", "Offset", "Size", "BonusLuck" }) do
					local value = model and model:GetAttribute(key)
					if value ~= nil then table.insert(attrs, key .. "=" .. tostring(value)) end
				end
			end
			local engine = candidate.NativePrompt
			local interface = candidate.Verified and "REGISTERED" or candidate.LocationVerified and "LOCATION_VERIFIED; HATCH_INTERACTION_UNVERIFIED" or "UNVERIFIED/EXCLUDED"
			local raw = self.Controller.Reader:GetLiveProfile()
			local opened = raw and type(raw.EggsOpened) == "table" and raw.EggsOpened[name] ~= nil and model:GetAttribute("Unlocked") == true
			local interaction = opened and "opened Root<=16; global Visible=0; nearest registered check still required"
				or "initial native cached Prompt required; range<=6.5"
			local worldAccess = raw and type(raw.WorldsUnlocked) == "table" and candidate.World and raw.WorldsUnlocked[candidate.World] ~= nil
			local islandAccess = candidate.Island == nil or raw and type(raw.AreasUnlocked) == "table" and raw.AreasUnlocked[candidate.Island] ~= nil
			local promptEligible = engine and engine.Parent == candidate.Prompt and engine.Enabled == true and engine.RequiresLineOfSight == false
				and finite(engine.MaxActivationDistance) and engine.MaxActivationDistance > 0 and candidate.PromptCacheMember == true
			local interfaceEligible = candidate.Verified and worldAccess and islandAccess and (opened or promptEligible)
			if expanded then
				table.insert(lines, string.format("id=%s; path=%s; parents=%s; attrs={%s}; Root=%s; Prompt=%s; world=%s; island=%s; eligibility=%s (%s); cached prompt=%s; prompt enabled=%s; max distance=%s; %s",
					tostring(candidate.IdentityId), tostring(candidate.Path or "UNKNOWN"), table.concat(ancestry, " <- "), table.concat(attrs, ","),
					position(candidate.Root), position(candidate.Prompt), tostring(candidate.World or "UNKNOWN"), tostring(candidate.Island or "surface/UNKNOWN"),
					interface, tostring(candidate.LocationEvidence or candidate.LocationReason or candidate.IdentityEvidence or candidate.Reason), tostring(candidate.PromptCacheMember == true), tostring(engine and engine.Enabled),
					tostring(engine and engine.MaxActivationDistance), interaction .. "; interface/access eligible=" .. tostring(interfaceEligible == true) .. "; actual stable range pending"))
			else
				local parent = model and model.Parent
				local parentLabel = parent and parent.Name and (parent.Name .. "[" .. knowledge:InstanceId(parent) .. "]") or "UNKNOWN"
				local nativeState = candidate.Verified and "VERIFIED" or tostring(candidate.Reason):find("PENDING", 1, true) and "PENDING" or "UNVERIFIED"
				table.insert(lines, string.format("id=%s%s; parent=%s; Root=%s; Prompt=%s; location=%s; registered=%s; access=%s; native=%s",
					tostring(candidate.IdentityId), self.BrainIntent and self.BrainIntent.Model == model and " SELECTED" or "", parentLabel,
					position(candidate.Root), position(candidate.Prompt), tostring(candidate.LocationVerified == true),
					tostring(candidate.Verified == true), tostring(worldAccess and islandAccess or false), nativeState))
			end
		end
		local selectedId = self.BrainIntent and self.BrainIntent.EggName == name and self.BrainIntent.Model and knowledge:InstanceId(self.BrainIntent.Model) or "UNSELECTED"
		local message = string.format("INSTANCE_DIAGNOSTIC_READ_ONLY | scope=%s; egg=%s; selected=%s; matching Models=%d; location verified=%d; registered=%d; shown=%d; omitted=%d | %s\n%s",
			diagnosticScope, name, selectedId, observation.Count or 0, observation.LocationVerifiedCount or observation.LocationCount or 0, observation.VerifiedCount or 0, #lines,
			math.max(0, #candidates - #lines), tostring(observation.Reason), table.concat(lines, "\n"))
		-- Full evidence forms the key: changed membership/ancestry/geometry prints
		-- immediately; unchanged observations remain silent between summaries.
		local previous = self.InstanceDiagnosticReports[name]
		if not previous or previous.Message ~= message then
			if not previous then
				table.insert(self.InstanceDiagnosticReportOrder, name)
				if #self.InstanceDiagnosticReportOrder > 64 then self.InstanceDiagnosticReports[table.remove(self.InstanceDiagnosticReportOrder, 1)] = nil end
			end
			self.InstanceDiagnosticReports[name] = { Message = message, At = os.clock() }
			self:Report(message, "INSTANCES:" .. name, true)
		end
	end
end

function EggTravelManager:RevalidateIntent()
	local intent, c = self.BrainIntent, self.Controller
	if not intent then return true end -- Preserve separately authorized manual travel-only tests.
	if intent.Scope == "TRAVEL_ONLY" then
		local blocker = c.Brain:TravelDiagnosticBlocker()
		if blocker then return false, blocker end
		if not c.Reader.Player or c.Reader.Player.UserId ~= self.BrainUserId then return false, "Travel diagnostic account identity changed" end
		local goalId = c.Plan and c.Plan.Objective and c.Plan.Objective.Id or "TRAVEL_ONLY_DIAGNOSTIC"
		if intent.GoalId ~= goalId then return false, "Acquired diagnostic Brain goal changed; no stale travel" end
		if not c.Pets or type(c.Pets.Fresh) ~= "function" then return false, "Fresh native egg observations unavailable" end
		local snapshot, context = c.Pets:Fresh()
		local fresh = c.Brain:PlanEggTravelDiagnostic(snapshot, context, c.Knowledge:Get("Eggs"), c.Knowledge:Get("Worlds"), intent)
		if not fresh or fresh.Kind ~= "EGG_TRAVEL" or fresh.EggName ~= intent.EggName or fresh.Model ~= intent.Model
			or fresh.World ~= intent.World or fresh.Island ~= intent.Island then
			return false, fresh and fresh.Reason or "Fresh accessible diagnostic destination changed; no travel"
		end
		return true
	end
	if not c.Config.PET_SETTINGS.AUTO_HATCH or not c.Config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE
		or not c.Reader.Player or c.Reader.Player.UserId ~= self.BrainUserId then return false, "Brain hatch authorization/account changed" end
	if not c.Pets or type(c.Pets.Fresh) ~= "function" or type(c.Pets.State) ~= "function" then return false, "Fresh pet decision interface unavailable" end
	local snapshot, context = c.Pets:Fresh()
	if not snapshot or not snapshot.Ready or context.Currency ~= intent.Currency then return false, "Brain currency objective or account readiness changed" end
	-- Received results/presentation retain location without re-authorizing movement.
	if self.Lease and self.Lease.Status == "ARRIVED" then return true end
	local report = c.Brain:AnalyzePets(snapshot, context)
	local fresh = c.Brain:PlanPets(report, context, c.Pets:State())
	if not fresh or fresh.Kind ~= "HATCH" or fresh.EggName ~= intent.EggName or fresh.Model ~= intent.Model
		or fresh.Currency ~= intent.Currency then return false, fresh and fresh.Reason or "Fresh useful hatch/reserve decision changed; no travel" end
	return true
end

function EggTravelManager:HatchInteractionAt(record, position, force)
	-- This read-only question is deliberately separate from physical travel.
	-- Exact current registration plus real initial/opened range semantics remain
	-- mandatory before reporting a hatch-range observation, even with AUTO_HATCH off.
	local c = self.Controller
	local identity, reason = c.Knowledge:ResolveEggInstance(record.EggName, force, record.Model)
	if not identity then return false, reason or "Exact native egg interaction identity unavailable" end
	if identity.Model ~= record.Model or identity.Root ~= record.TargetRoot then return false, "Native interaction anchor differs from selected physical original" end
	local profile = c.Reader:GetLiveProfile()
	if not profile or type(profile.EggsOpened) ~= "table" then return false, "Native egg opened-state facts unavailable; physical location remains separate" end
	local prompt = child(record.Model, "Prompt")
	local native = table.clone(record)
	native.LocationOnly = false
	native.Opened = profile and type(profile.EggsOpened) == "table" and profile.EggsOpened[record.EggName] ~= nil
		and record.Model:GetAttribute("Unlocked") == true
	native.RangeOrigin, native.Range = record.TargetRoot, 16
	if native.Opened then
		local prompts = c.Knowledge:Get("ProximityPrompt")
		if type(prompts) ~= "table" or prompts.Visible ~= 0 then return false, "Native opened-egg prompt visibility unavailable/blocked" end
	else
		if identity.PromptCacheMember ~= true then return false, "Exact initial native prompt registration is unverified; physical location remains separate" end
		if not live(prompt) or not vector(prompt.Position) then return false, "Actual native initial egg Prompt geometry unavailable" end
		local engine = prompt:FindFirstChildOfClass("ProximityPrompt")
		if not engine or engine.Parent ~= prompt or engine.Enabled ~= true or engine.RequiresLineOfSight ~= false
			or not finite(engine.MaxActivationDistance) or engine.MaxActivationDistance <= 0 then
			return false, "Native initial egg prompt eligibility unavailable/disabled"
		end
		native.RangeOrigin, native.Range = prompt, math.min(6.5, engine.MaxActivationDistance)
	end
	local eligible, blocker = self:RangeEligibleAt(native, position, force)
	return eligible, blocker or "Exact native interaction identity and actual range observed", native
end

function EggTravelManager:Resolve(force)
	local c, settings = self.Controller, self:Settings()
	local diagnostic = (settings and settings.MODE or "NORMAL") == "TRAVEL_ONLY"
	if self.Destroyed or not settings or not settings.ENABLE_SELECTED_EGG_TRAVEL then return nil, "Selected-egg travel disabled" end
	local key, reason, name = self:Key()
	if not key then return nil, reason end
	local permitted, blocker = self:RevalidateIntent()
	if not permitted then return nil, blocker end
	local profile, snapshot = c.Reader:GetLiveProfile(), c.Reader:GetSnapshot()
	if not profile or not snapshot or not snapshot.Ready or type(profile.WorldsUnlocked) ~= "table"
		or type(profile.AreasUnlocked) ~= "table" or not diagnostic and type(profile.EggsOpened) ~= "table" then return nil, "Fresh account world/island/egg access unavailable" end
	local root, humanoid = c.Farming.Tracker:Root()
	local character = c.Reader.Player and c.Reader.Player.Character
	if not character or not root or not humanoid or not vector(root.Position) then return nil, "Living character unavailable" end
	local definitions, worlds = c.Knowledge:Get("Eggs"), c.Knowledge:Get("Worlds")
	local def = type(definitions) == "table" and definitions[name]
	if type(def) ~= "table" then return nil, "Selected egg definition unavailable" end
	if def.Event or def.ProductId or def.IsAdminEgg or name == "Infinity Egg" then
		return nil, "Special/event/premium egg availability has no verified current adapter; manual approach required, no event chase"
	end
	local world = def.World
	local worldDef = type(worlds) == "table" and worlds[world]
	if type(world) ~= "string" or type(worldDef) ~= "table" or worldDef.Removed
		or profile.WorldsUnlocked[world] == nil then return nil, "Selected egg world/access unknown, removed or locked; manual approach required" end
	local worldUtil = c.Knowledge:Get("WorldUtil")
	local okWorld, currentWorld = pcall(function() return worldUtil:GetPlayerWorld(c.Reader.Player) end)
	if not okWorld or type(currentWorld) ~= "string" then return nil, "Native current-world observation unavailable" end
	local identity, identityReason, observations
	if diagnostic then
		identity, identityReason, observations = c.Knowledge:ResolveEggLocation(name, force, self.BrainIntent and self.BrainIntent.Model, root)
	else
		identity, identityReason, observations = c.Knowledge:ResolveEggInstance(name, force, self.BrainIntent and self.BrainIntent.Model)
	end
	if observations then self:ReportInstanceDiagnostics({ [name] = observations }) end
	if not identity then return nil, identityReason end
	local model, part = identity.Model, identity.Root
	if not live(part) or not vector(part.Position) then return nil, "Selected physical egg Root geometry unavailable" end
	if diagnostic and identity.LocationVerified ~= true then return nil, "Selected native physical egg location is unverified; no travel" end
	if diagnostic and identity.World ~= world then return nil, "Verified physical egg world differs from the selected native definition" end
	local bestDistance = (part.Position - root.Position).Magnitude
	local island = identity.Island or model:GetAttribute("Island") or def.Island
	if island ~= nil and (type(island) ~= "string" or profile.AreasUnlocked[island] == nil) then
		return nil, "Selected egg island access locked or unknown; no discovery or purchase"
	end
	local opened = model:GetAttribute("Unlocked") == true and type(profile.EggsOpened) == "table" and profile.EggsOpened[name] ~= nil
	local prompt = child(model, "Prompt")
	if not diagnostic and (not live(prompt) or not vector(prompt.Position)) then return nil, "Actual egg Prompt geometry unavailable" end
	local rangeOrigin, range, nativePrompt, visible = part, 16
	if diagnostic then
		-- A conservative near-Root travel policy is not native hatch-range proof.
		-- Missing registration/Prompt state must not block an evidenced location.
		range = 6.5
	elseif opened then
		local prompts = c.Knowledge:Get("ProximityPrompt")
		visible = type(prompts) == "table" and prompts.Visible
		if not finite(visible) or visible < 0 or visible % 1 ~= 0 then return nil, "Native opened-egg prompt visibility unavailable" end
		if visible ~= 0 then return nil, "A visible native proximity prompt blocks the opened-egg scan" end
	else
		nativePrompt = prompt:FindFirstChildOfClass("ProximityPrompt")
		if not nativePrompt or nativePrompt.Parent ~= prompt or nativePrompt.Enabled ~= true
			or nativePrompt.RequiresLineOfSight ~= false or not finite(nativePrompt.MaxActivationDistance)
			or nativePrompt.MaxActivationDistance <= 0 then return nil, "Native initial egg prompt eligibility unavailable/disabled" end
		rangeOrigin, range = prompt, math.min(6.5, nativePrompt.MaxActivationDistance)
	end
	local worldModel = child(child(workspace, "Worlds"), world)
	local destination, path, known
	if island then
		for _, entry in ipairs(worldDef.Islands or {}) do if entry.Name == island then known = true break end end
		if known then
			local islandModel = child(child(child(worldModel, "Islands"), island), "Island")
			destination = child(child(islandModel, "Portal"), "Spawn")
			path = "Workspace.Worlds." .. world .. ".Islands." .. island .. ".Island.Portal.Spawn"
		end
	else
		destination = child(child(worldModel, "FastTravel"), "Spawn")
		if live(destination) then path, known = destination:GetFullName(), true end
	end
	if not live(destination) then destination = nil end
	local record = { SelectionKey = key, EggName = name, Model = model, IdentityId = identity.IdentityId, IdentityEvidence = identity.IdentityEvidence,
		LocationOnly = diagnostic, LocationVerified = diagnostic and identity.LocationVerified == true or identity.Verified == true,
		LocationEvidence = identity.LocationEvidence, PhysicalRange = diagnostic and range or nil,
		TargetRoot = part, PromptPart = prompt, NativePrompt = nativePrompt,
		TargetPosition = part.Position, Character = character, CharacterRoot = root, Humanoid = humanoid,
		World = world, Island = island, CurrentWorld = currentWorld, Range = range, Opened = opened,
		RangeOrigin = rangeOrigin, RangeOriginPosition = rangeOrigin.Position, PromptPosition = live(prompt) and vector(prompt.Position) and prompt.Position or nil, PromptVisible = visible,
		Distance = (rangeOrigin.Position - root.Position).Magnitude, RootDistance = bestDistance,
		-- Surface eggs also require their native area arrival when coming from an
		-- island. Absence of an Island annotation cannot authorize a vertical jump.
		NeedsNativeTravel = currentWorld ~= world or math.abs(root.Position.Y - part.Position.Y) > 16,
		Destination = destination, DestinationPath = path, NativeAreaKnown = known == true }
	if self.Lease and self.Lease.Model == model then record.StandingDestination = self.Lease.StandingDestination end
	local eligible, rangeBlocker = self:RangeEligibleAt(record, root.Position)
	record.InRange, record.RangeBlocker = currentWorld == world and eligible, rangeBlocker
	if diagnostic then
		local interaction, interactionReason = self:HatchInteractionAt(record, root.Position, force)
		record.InteractionVerified, record.InteractionReason = currentWorld == world and interaction, interactionReason
	end
	return record
end

function EggTravelManager:RangeEligibleAt(record, position, force)
	if not vector(position) or not live(record.RangeOrigin) then return false, "Native range geometry unavailable" end
	local distance = (position - record.RangeOrigin.Position).Magnitude
	if record.LocationOnly then
		if record.LocationVerified ~= true or record.RangeOrigin ~= record.TargetRoot or not finite(record.PhysicalRange)
			or record.PhysicalRange <= 0 then return false, "Physical egg location identity/anchor unavailable" end
		if record.StandingDestination then
			local proof = record.StandingDestination
			local valid, reason = Standing.CheckProof(record, proof)
			if not valid then return false, reason end
			local horizontal = Vector3.new(position.X - record.TargetRoot.Position.X, 0, position.Z - record.TargetRoot.Position.Z).Magnitude
			if horizontal > record.PhysicalRange then return false, "PHYSICAL_HORIZONTAL_RANGE_EXCEEDED" end
			if math.abs(position.Y - proof.Position.Y) > 0.5 then return false, "PHYSICAL_STANDING_HEIGHT_UNOBSERVED" end
			return true
		end
		if distance <= record.PhysicalRange then return true end
		return false, "Outside diagnostic physical arrival radius; native hatch eligibility is separate"
	end
	if distance > record.Range then return false, "Outside the actual native egg range origin" end
	if record.Opened then
		local prompts = self.Controller.Knowledge:Get("ProximityPrompt")
		if type(prompts) ~= "table" or prompts.Visible ~= 0 or record.Model:GetAttribute("Unlocked") ~= true then return false, "Native opened-egg scan eligibility unavailable/blocked" end
		-- Match the native nearest-unlocked selection conservatively using original
		-- loaded models; never read the private client registration table.
		for _, model in ipairs(self.Controller.Knowledge:InteractiveEggModels(force)) do
			local root = model ~= record.Model and model.Parent and model:IsDescendantOf(workspace) and child(model, "Root") or nil
			if live(root) and model:GetAttribute("Unlocked") == true and vector(root.Position)
				and (root.Position - position).Magnitude <= distance + 0.05 then return false, "Another or equally near unlocked egg owns the native nearest-egg scan" end
		end
	end
	return true
end

function EggTravelManager:Validate(record, token, force)
	local lease = self.Lease
	if not lease or not record or record.LeaseId ~= lease.LeaseId or self.Controller.State ~= "RUNNING"
		or lease.Generation ~= nil and lease.Generation ~= self.Controller.Generation
		or token and token:CheckCancelled() then return nil, "Egg location task cancelled or stale" end
	local fresh, reason = self:Resolve(force)
	if not fresh then return nil, reason end
	-- A first authorized hatch can change the native initial-prompt interface to
	-- the opened scanner. Refresh observed range only; never reposition on it.
	if not lease.LocationOnly and lease.Status == "ARRIVED" and not lease.Opened and fresh.Opened and self.Controller.Pets
		and (self.Controller.Pets.Hatch.RequestedHatches or 0) > 0 then
		lease.Opened, lease.NativePrompt, lease.RangeOrigin, lease.Range = fresh.Opened, fresh.NativePrompt, fresh.RangeOrigin, fresh.Range
		lease.RangeOriginPosition, lease.PromptVisible = fresh.RangeOriginPosition, fresh.PromptVisible
	end
	if fresh.SelectionKey ~= lease.SelectionKey or fresh.Model ~= lease.Model or fresh.TargetRoot ~= lease.TargetRoot
		or fresh.LocationOnly ~= lease.LocationOnly or fresh.LocationOnly and fresh.LocationVerified ~= true
		or not lease.LocationOnly and (fresh.PromptPart ~= lease.PromptPart or fresh.NativePrompt ~= lease.NativePrompt or fresh.Opened ~= lease.Opened)
		or fresh.RangeOrigin ~= lease.RangeOrigin or fresh.Range ~= lease.Range
		or fresh.Character ~= lease.Character or fresh.CharacterRoot ~= lease.CharacterRoot
		or fresh.World ~= lease.World or fresh.Island ~= lease.Island then return nil, "Selection, target, access or character changed; no position restoration" end
	if (fresh.TargetPosition - lease.TargetPosition).Magnitude > 0.5 then return nil, "Selected egg moved; new geometry requires explicit rearm" end
	if not lease.LocationOnly and (fresh.PromptPosition - lease.PromptPosition).Magnitude > 0.5
		or (fresh.RangeOriginPosition - lease.RangeOriginPosition).Magnitude > 0.5 then return nil, "Egg location/prompt geometry changed; explicit rearm required" end
	local movement = fresh.Humanoid.MoveDirection
	if lease.Status == "TRAVELING" and vector(movement) and movement.Magnitude > 0.05 then
		return nil, "Manual movement during arrival; explicit rearm required"
	end
	if os.clock() >= lease.Deadline then return nil, "Egg location lease expired" end
	fresh.LeaseId = lease.LeaseId
	if lease.StandingDestination then
		local frame, standingReason = self:ResolveStanding(fresh)
		if not frame then return nil, standingReason end
	end
	return fresh
end

function EggTravelManager:ResolveStanding(record)
	local report = { Model = record.Model, IdentityId = record.IdentityId, Root = record.TargetRoot and record.TargetRoot.Position,
		Prompt = record.PromptPart and record.PromptPart.Position, Candidates = {}, ReadOnly = true }
	local ok, frameOrReason, resolvedProof = pcall(function()
		local root, target = record.CharacterRoot, record.RangeOrigin
		if not live(target) or not vector(target.Position) or not finite(record.Range) or record.Range <= 0 then return "TARGET_GEOMETRY_UNAVAILABLE" end
		if type(workspace.Raycast) ~= "function" or type(workspace.GetPartBoundsInBox) ~= "function"
			or not RaycastParams or not OverlapParams or not CFrame then return "STANDING_RUNTIME_UNAVAILABLE" end
		local avatar, avatarReason, partialAvatar = Standing.Avatar(record)
		report.Avatar = avatar or partialAvatar
		if not avatar then return avatarReason end
		if avatar.SupportIntersection then return "AVATAR_SOLID_BELOW_SUPPORTED_FEET:bottom=" .. tostring(avatar.ClearanceBottom) end
		local prior = record.StandingDestination
		if prior then
			local valid, reason = Standing.CheckProof(record, prior)
			if not valid then return reason end
			if math.abs(avatar.Height - prior.AvatarHeight) > 0.5 then return "AVATAR_STANDING_HEIGHT_CHANGED" end
		end
		local ray, overlap = RaycastParams.new(), OverlapParams.new()
		ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide, ray.CollisionGroup = Enum.RaycastFilterType.Exclude, { record.Character }, true, avatar.CollisionGroup
		overlap.FilterType, overlap.RespectCanCollide, overlap.CollisionGroup = Enum.RaycastFilterType.Exclude, true, avatar.CollisionGroup
		local up, down = Standing.SearchDepth(record, avatar)
		if prior then up, down = prior.RayUp, prior.RayDown end
		local pos, radius = target.Position, math.min(4, record.Range / 2)
		local offsets = prior and { Vector3.new(prior.Position.X - pos.X, 0, prior.Position.Z - pos.Z) }
			or { Vector3.new(0, 0, 0), Vector3.new(radius, 0, 0), Vector3.new(-radius, 0, 0), Vector3.new(0, 0, radius), Vector3.new(0, 0, -radius) }
		for index, offset in ipairs(offsets) do
			local horizontal = pos + offset
			local candidate = { Id = index, X = horizontal.X, Z = horizontal.Z, RayStartY = pos.Y + up, RayEndY = pos.Y - down,
				BlockingParts = {}, RangeEligible = false }
			table.insert(report.Candidates, candidate)
			local result = workspace:Raycast(Vector3.new(horizontal.X, candidate.RayStartY, horizontal.Z), Vector3.new(0, -up - down, 0), ray)
			local floor = result and result.Instance
			if floor then
				candidate.Hit = Standing.Part(floor)
				candidate.Hit.PartPosition = candidate.Hit.Position
				candidate.Hit.Position, candidate.Hit.Normal = result.Position, result.Normal
			end
			local supported, supportReason = Standing.Support(floor, result and result.Normal)
			if not result then candidate.Reason = "NO_FLOOR_HIT"
			elseif not supported then candidate.Reason = supportReason
			elseif not vector(result.Position) then candidate.Reason = "SUPPORT_HIT_POSITION_UNAVAILABLE"
			elseif prior and (floor ~= prior.Support or (result.Position - prior.SupportHitPosition).Magnitude > 0.1) then candidate.Reason = "STANDING_SUPPORT_RAY_CHANGED"
			else
				local position = prior and prior.Position or Vector3.new(horizontal.X, result.Position.Y + avatar.Height, horizontal.Z)
				candidate.ProposedPosition, candidate.ProposedRootY = position, position.Y
				candidate.AnchorDistance = (position - pos).Magnitude
				candidate.HorizontalDistance = Vector3.new(position.X - pos.X, 0, position.Z - pos.Z).Magnitude
				local proof = prior or { Position = position, Model = record.Model, TargetRoot = record.TargetRoot,
					Support = floor, SupportPosition = floor.Position, SupportSize = floor.Size, SupportFrame = floor.CFrame,
					SupportHitPosition = result.Position, SupportNormal = result.Normal, AnchorPosition = record.TargetRoot.Position,
					CharacterRoot = root, AvatarHeight = avatar.Height, HorizontalRadius = record.PhysicalRange,
					RayUp = up, RayDown = down, CollisionGroup = avatar.CollisionGroup }
				local ranged = table.clone(record) ranged.StandingDestination = proof
				local eligible, rangeReason = self:RangeEligibleAt(ranged, position)
				candidate.RangeEligible = eligible == true
				if not eligible then candidate.Reason = rangeReason
				else
					local facing = Vector3.new(pos.X - position.X, 0, pos.Z - position.Z)
					if facing.Magnitude < 0.05 then
						local observed = root.CFrame.LookVector
						if not vector(observed) then return "AVATAR_FACING_UNAVAILABLE" end
						facing = Vector3.new(observed.X, 0, observed.Z)
					end
					if facing.Magnitude < 0.05 then return "AVATAR_UPRIGHT_FACING_UNAVAILABLE" end
					local frame = prior and prior.Frame or CFrame.lookAt(position, position + facing)
					overlap.FilterDescendantsInstances = { record.Character, floor }
					for _, obstacle in ipairs(workspace:GetPartBoundsInBox(frame * avatar.BodyOffset, avatar.BodySize + Vector3.new(0.3, 0.1, 0.3), overlap)) do
						if obstacle.CanCollide == true then
							candidate.BlockingCount = (candidate.BlockingCount or 0) + 1
							if #candidate.BlockingParts < 6 then table.insert(candidate.BlockingParts, Standing.Part(obstacle)) end
						end
					end
					if (candidate.BlockingCount or 0) > 0 then candidate.Reason = "AVATAR_COLLISION:" .. candidate.BlockingParts[1].Path
					else
						candidate.Reason, proof.Frame = "ACCEPTED_SUPPORTED_CLEAR_POSE", frame
						return frame, proof
					end
				end
			end
		end
		local reasons = {} for _, candidate in ipairs(report.Candidates) do table.insert(reasons, "C" .. candidate.Id .. "=" .. tostring(candidate.Reason)) end
		return "STANDING_DESTINATION_BLOCKED | " .. table.concat(reasons, "; ")
	end)
	local reason = not ok and "STANDING_OBSERVATION_FAILED:" .. tostring(frameOrReason) or type(frameOrReason) == "string" and frameOrReason or nil
	report.Reason = reason or "STANDING_DESTINATION_RESOLVED"
	self.LastStandingReport = report
	self:ReportStandingDiagnostics(record, report)
	if reason then return nil, reason end
	return frameOrReason, nil, resolvedProof
end

function EggTravelManager:ReportStandingDiagnostics(record, report)
	if (self:Settings().MODE or "NORMAL") ~= "TRAVEL_ONLY" then return end
	self.StandingReports = self.StandingReports or setmetatable({}, { __mode = "k" })
	if not record.Model or self.StandingReports[record.Model] then return end
	self.StandingReports[record.Model] = true -- Once per retained actual Instance, never every guard/tick.
	local function point(value) return vector(value) and string.format("(%.3f,%.3f,%.3f)", value.X, value.Y, value.Z) or "UNKNOWN" end
	local function part(value)
			return value and string.format("%s; hit/pos=%s; part center=%s; size=%s; anchored=%s; collide=%s; query=%s; group=%s; assembly=%s; velocity=%s/%s",
				value.Path, point(value.Position), point(value.PartPosition or value.Position), point(value.Size), tostring(value.Anchored), tostring(value.CanCollide), tostring(value.CanQuery), tostring(value.CollisionGroup), tostring(value.AssemblyRoot), point(value.LinearVelocity), point(value.AngularVelocity)) or "NO_HIT"
	end
	local avatar, lines = report.Avatar, {}
	if avatar then
		table.insert(lines, string.format("avatar aggregate=%s; offset=%s; usable=%s; offset=%s; body source=%s; HRP height=%s; group=%s; noncollidable extras=%d; solid extras=%d; unexpected shown=%d",
			point(avatar.AggregateSize), point(avatar.AggregateOffset.Position), point(avatar.BodySize), point(avatar.BodyOffset.Position), avatar.BodySource, tostring(avatar.Height), avatar.CollisionGroup,
			avatar.IgnoredNonCollidableCount, avatar.CollidableExtraCount, #avatar.UnexpectedParts))
		for _, unexpected in ipairs(avatar.UnexpectedParts) do table.insert(lines, "avatar extra: " .. part(unexpected)) end
	end
	for _, candidate in ipairs(report.Candidates) do
		table.insert(lines, string.format("C%d X/Z=(%.3f,%.3f); ray Y=%.3f->%.3f; %s; normal=%s; proposed HRP=%s; anchor distance=%s; horizontal distance=%s; range=%s; blockers=%d; result=%s",
			candidate.Id, candidate.X, candidate.Z, candidate.RayStartY, candidate.RayEndY, part(candidate.Hit), point(candidate.Hit and candidate.Hit.Normal), point(candidate.ProposedPosition),
			tostring(candidate.AnchorDistance or "NOT_COMPUTED"), tostring(candidate.HorizontalDistance or "NOT_COMPUTED"), tostring(candidate.RangeEligible), candidate.BlockingCount or 0, tostring(candidate.Reason)))
		for _, obstacle in ipairs(candidate.BlockingParts) do table.insert(lines, "C" .. candidate.Id .. " blocker: " .. part(obstacle)) end
	end
	self:Report("STANDING_DIAGNOSTIC_READ_ONLY | egg=" .. tostring(record.EggName) .. "; instance=" .. tostring(record.IdentityId)
		.. "; Root=" .. point(report.Root) .. "; Prompt=" .. point(report.Prompt) .. "; final=" .. report.Reason .. "\n" .. table.concat(lines, "\n"), "STANDING:" .. tostring(record.IdentityId), true)
end

function EggTravelManager:Release(reason, blocked)
	local lease = self.Lease
	if self.DiagnosticConsumed then self.DiagnosticEnded = true end
	if lease then
		if blocked then self.Blocked[lease.SelectionKey] = reason end
		self.LastResult = { Status = blocked and "HALTED" or "RELEASED", EggName = lease.EggName,
			Reason = reason, DirectPositionAttempted = lease.DirectPositionAttempted == true, NativeTravelAttempted = lease.NativeTravelAttempted == true,
			HatchCommands = 0, Spending = 0 }
		if self.BrainIntent and self.BrainIntent.Scope == "TRAVEL_ONLY" then self.LastResult.Scope = "TRAVEL_ONLY" end
	end
	self:DiagnosticTrace("TRAVEL_BLOCKED", lease, reason)
	self.Lease = nil
	self.Reason = reason
	if (self:Settings().MODE or "NORMAL") ~= "TRAVEL_ONLY" then
		self:Report(tostring(lease and lease.EggName or "Selected egg") .. " | " .. tostring(reason) .. " | hatch commands=0; spending=0")
	end
end

function EggTravelManager:Observe()
	if not self.Lease then return end
	if self.Controller.State ~= "RUNNING" then self:Release("Controller paused/stopped; no restore", true) return end
	local fresh, reason = self:Validate(self.Lease)
	if not fresh then self:Release(reason, true) return end
	if self.Lease.Status == "ARRIVED" and not fresh.InRange then
		self:Release("Manual departure or position correction observed; same selection will not snap back; change SELECTION_REVISION to rearm", true)
	end
end

function EggTravelManager:OwnsLocation() return self.Lease ~= nil and self.Controller.State == "RUNNING" end
function EggTravelManager:HatchEligible(egg)
	if (self:Settings().MODE or "NORMAL") == "TRAVEL_ONLY" or self.BrainIntent and self.BrainIntent.Scope == "TRAVEL_ONLY" then
		return false, "TRAVEL_ONLY never authorizes a hatch handoff"
	end
	local key, reason = self:Key()
	if not key or self.Blocked[key] then return false, self.Blocked[key] or reason end
	local lease = self.Lease
	if not lease or lease.Status ~= "ARRIVED" or not egg or egg.Name ~= lease.EggName or egg.Model ~= lease.Model then
		return false, "Selected Brain egg requires observed stable arrival of the same original model"
	end
	local fresh, blocker = self:Validate(lease)
	if not fresh or not fresh.InRange or not self:RangeEligibleAt(fresh, fresh.CharacterRoot.Position, true) then
		self:Release(blocker or "Manual departure from native range; no snap-back", true)
		return false, blocker or "Native selected egg range changed"
	end
	return true
end
function EggTravelManager:AtOwnedLocation(area)
	local lease = self.Lease
	if not lease or lease.Status ~= "ARRIVED" or not area then return false end
	local fresh = self:Validate(lease)
	return fresh ~= nil and fresh.InRange and area.World == lease.World and area.Name == (lease.Island or lease.World)
end

function EggTravelManager:Select(_plan, intent)
	local diagnostic = (self:Settings().MODE or "NORMAL") == "TRAVEL_ONLY"
	if diagnostic and self.DiagnosticConsumed and (self.DiagnosticEnded or not self.Lease) then
		if not self.LastResult or self.LastResult.PhysicalArrivalVerified ~= true then
			self:DiagnosticTrace("TRAVEL_BLOCKED", nil, "One bounded diagnostic consumed; no retry or revision rearm")
		end
		return false, { Kind = "WAIT", Reason = "One bounded TRAVEL_ONLY attempt consumed; no automatic retry or revision rearm", OwnsLocation = false }
	end
	if intent then
		local name, reason = selected(self.Controller.Config, intent)
		if not name then self:DiagnosticTrace("PREFLIGHT_BLOCKED", nil, reason) return false, { Kind = "WAIT", Reason = reason } end
		if self.Lease and self.BrainIntent and (intent.EggName ~= self.BrainIntent.EggName
			or intent.Model ~= self.BrainIntent.Model or intent.Currency ~= self.BrainIntent.Currency
			or diagnostic and (intent.GoalId ~= self.BrainIntent.GoalId or intent.Generation ~= self.BrainIntent.Generation
				or intent.SelectionRevision ~= self.BrainIntent.SelectionRevision)) then
			self:Release("Brain target/model/objective changed; no stale arrival or automatic restoration", true)
			return false, { Kind = "WAIT", Reason = self.Reason }
		end
		if not self.BrainIntent or not self.Lease then self.BrainUserId = self.Controller.Reader.Player and self.Controller.Reader.Player.UserId end
		self.BrainIntent = table.clone(intent)
	elseif (self.Controller.Config.HATCH_SETTINGS.EGG_SELECTION_MODE or "MANUAL") == "AUTO" then
		return false, { Kind = "WAIT", Reason = "AUTO travel requires a fresh Brain destination" }
	end
	self:Observe()
	local settings = self:Settings()
	if not settings or not settings.ENABLE_SELECTED_EGG_TRAVEL or self.Destroyed then return false, { Kind = "WAIT", Reason = "Selected-egg travel disabled" } end
	local key, reason = self:Key()
	if not key then self.Reason = reason self:DiagnosticTrace("PREFLIGHT_BLOCKED", nil, reason) if not diagnostic then self:Report(reason) end return false, { Kind = "WAIT", Reason = reason } end
	if self.Blocked[key] then self.Reason = self.Blocked[key] self:DiagnosticTrace("TRAVEL_BLOCKED", nil, self.Reason) if not diagnostic then self:Report(self.Reason) end return false, { Kind = "WAIT", Reason = self.Reason } end
	if self.Lease then
		local pets = self.Controller.Config.PET_SETTINGS
		if self.Lease.Status == "ARRIVED" and pets and pets.AUTO_HATCH then
			return false, { Kind = "HANDOFF", OwnsLocation = true, Reason = "Selected range observed; separate existing hatch authority decides spending" }
		end
		return true, { Kind = self.Lease.Status == "ARRIVED" and "OBSERVE" or "EGG_TRAVEL", Record = self.Lease, OwnsLocation = true }
	end
	if (self.Attempts[key] or 0) >= settings.MAXIMUM_ATTEMPTS_PER_SELECTION then return false, { Kind = "WAIT", Reason = "Selected-egg attempt limit reached; explicit revision required" } end
	local record, blocker = self:Resolve(true)
	if not record then self.Reason = blocker self:DiagnosticTrace("PREFLIGHT_BLOCKED", nil, blocker) if not diagnostic then self:Report(blocker) end return false, { Kind = "WAIT", Reason = blocker } end
	if record.NeedsNativeTravel and (not settings.ENABLE_NATIVE_ISLAND_TRAVEL or not record.NativeAreaKnown or not record.DestinationPath) then
		self.Reason = "Correct unlocked native area travel unavailable/disabled; direct positioning cannot cross unknown worlds/islands"
		self:DiagnosticTrace("PREFLIGHT_BLOCKED", record, self.Reason)
		if not diagnostic then self:Report(self.Reason) end
		return false, { Kind = "WAIT", Reason = self.Reason }
	end
	if not record.InRange and not settings.ENABLE_DIRECT_POSITIONING and not settings.ENABLE_NATIVE_ISLAND_TRAVEL then
		self.Reason = record.RangeBlocker or "Outside selected egg range; positioning and native island travel are disabled"
		self:DiagnosticTrace("PREFLIGHT_BLOCKED", record, self.Reason)
		if not diagnostic then self:Report(self.Reason) end
		return false, { Kind = "WAIT", Reason = self.Reason }
	end
	-- Consume this controller's diagnostic permission before it can enter the
	-- scheduler. Cancellation, skipped execution and uncertain movement cannot
	-- turn Pause/Resume or a selection revision into a second travel attempt.
	if diagnostic then self.DiagnosticConsumed = true self.DiagnosticEnded = false end
	self.Sequence += 1
	record.LeaseId, record.Status = self.Sequence, "PLANNED"
	record.Generation, record.Scope = self.Controller.Generation, diagnostic and "TRAVEL_ONLY" or "AUTHORIZED_HATCH_OR_MANUAL_TRAVEL"
	record.StartedAt, record.Deadline = os.clock(), os.clock() + settings.MAXIMUM_LOCATION_SECONDS
	self.Lease = record
	self:DiagnosticTrace("TARGET_SELECTED", record, self.BrainIntent and self.BrainIntent.Reason or "Exact owner-selected native destination")
	self:DiagnosticTrace("PHYSICAL_TARGET_RESOLVED", record, "Exact accessible egg Instance and native physical Root resolved; safe standing geometry is checked before assignment; hatch interaction separate")
	return true, { Kind = "EGG_TRAVEL", Record = record, OwnsLocation = true }
end

function EggTravelManager:Execute(record, token)
	local settings, c = self:Settings(), self.Controller
	local fresh, reason = self:Validate(record, token)
	if not fresh then self:Release(reason, true) return { Verified = false, Reason = reason } end
	local lease = self.Lease
	if lease.Status == "ARRIVED" then self:Observe() if not token:CheckCancelled() then task.wait(1) end return { Verified = self.Lease ~= nil, Reason = "Observing selected location; no repositioning" } end
	self.Attempts[lease.SelectionKey] = (self.Attempts[lease.SelectionKey] or 0) + 1
	lease.Status = "TRAVELING"
	if not fresh.InRange and fresh.NeedsNativeTravel and settings.ENABLE_NATIVE_ISLAND_TRAVEL and fresh.NativeAreaKnown and fresh.DestinationPath then
		lease.NativeTravelAttempted = true
		self:DiagnosticTrace("AREA_TRAVEL_ADAPTER_ATTEMPTED", fresh, "Existing native adapter attempt for " .. fresh.DestinationPath .. "; native request dispatch remains separately reported")
		local ok, why = c.Farming.Mechanics:TravelSelectedEgg(self, fresh, token)
		if not ok then self:DiagnosticTrace("ARRIVAL_UNCONFIRMED", fresh, why or "Native area arrival unconfirmed") self:Release(why or "Native selected-area travel unconfirmed", true) return { Verified = false, Reason = self.Reason } end
		fresh, reason = self:Validate(lease, token)
		if fresh and not fresh.NeedsNativeTravel then self:DiagnosticTrace("AREA_ARRIVAL_OBSERVED", fresh, "Existing adapter observed native target-area arrival; egg interaction range still pending") end
	end
	if not fresh then self:Release(reason, true) return { Verified = false, Reason = reason } end
	if fresh.NeedsNativeTravel then self:Release("Correct native target area arrival unconfirmed; no direct cross-world/island positioning", true) return { Verified = false, Reason = self.Reason } end
	-- Native area transport and final positioning each have a bounded window.
	-- A slow but valid area arrival must still leave time for hatch-range stability.
	local deadline = math.min(lease.Deadline, os.clock() + settings.ARRIVAL_TIMEOUT_SECONDS)
	if not fresh.InRange then
		if not settings.ENABLE_DIRECT_POSITIONING then self:Release("Native area reached; selected egg remains outside range; manual approach required", true) return { Verified = false, Reason = self.Reason } end
		local frame, geometryReason, proof = self:ResolveStanding(fresh)
		if not frame then self:Release(geometryReason, true) return { Verified = false, Reason = geometryReason } end
		lease.StandingDestination = proof
		self:DiagnosticTrace("STANDING_DESTINATION_RESOLVED", fresh, "Observed support ray, actual body clearance and permitted range identify one retained standing pose; no assignment yet")
		fresh, reason = self:Validate(lease, token)
		if not fresh then self:Release(reason, true) return { Verified = false, Reason = reason } end
		lease.RequestedStandingPosition = frame.Position
		local ok, why = c.Farming.Mechanics:PositionSelectedEgg(self, fresh, frame, token)
		if not ok then self:DiagnosticTrace("DIRECT_POSITION_FAILED", fresh, why or "Direct assignment failed/unconfirmed") self:Release(why or "Direct positioning failed/unconfirmed", true) return { Verified = false, Reason = self.Reason } end
	end
	local stableAt, stablePosition
	while os.clock() < deadline do
		fresh, reason = self:Validate(lease, token)
		if not fresh then self:Release(reason, true) return { Verified = false, Reason = reason } end
		local position = fresh.CharacterRoot.Position
		local move = fresh.Humanoid.MoveDirection
		if vector(move) and move.Magnitude > 0.05 then self:Release("Manual movement during arrival; explicit rearm required", true) return { Verified = false, Reason = self.Reason } end
		local requestedPositionObserved = not lease.RequestedStandingPosition or (position - lease.RequestedStandingPosition).Magnitude <= 0.5
		if fresh.InRange and requestedPositionObserved and (not stablePosition or (position - stablePosition).Magnitude <= 0.35) then
			stableAt, stablePosition = stableAt or os.clock(), stablePosition or position
			if os.clock() - stableAt >= settings.STABILITY_SECONDS then
				local guardOK, allowed, blocker = pcall(function()
					if type(c.Farming.Mechanics.LocalFeatureGuard) ~= "function" then return false, "Foreground presentation guard unavailable" end
					return c.Farming.Mechanics:LocalFeatureGuard()
				end)
				if not guardOK or not allowed then self:Release(blocker or "Foreground presentation eligibility unavailable", true) return { Verified = false, Reason = self.Reason } end
				fresh, reason = self:Validate(lease, token)
				if not fresh or not fresh.InRange or (fresh.CharacterRoot.Position - stablePosition).Magnitude > 0.35 then
					self:Release(reason or "Actual arrival eligibility changed during final guards", true) return { Verified = false, Reason = self.Reason }
				end
				lease.Status, lease.ArrivedAt = "ARRIVED", os.clock()
				local diagnostic = self.BrainIntent and self.BrainIntent.Scope == "TRAVEL_ONLY"
				self.LastResult = { Status = diagnostic and "PHYSICAL_ARRIVAL_OBSERVED" or "HATCH_RANGE_OBSERVED", EggName = fresh.EggName, Distance = fresh.Distance, Range = fresh.Range,
					StabilitySeconds = settings.STABILITY_SECONDS, DirectPositionAttempted = lease.DirectPositionAttempted == true,
					NativeTravelAttempted = lease.NativeTravelAttempted == true, HatchCommands = 0, Spending = 0,
					RangeOrigin = fresh.Opened and "EGG_ROOT" or "INITIAL_PROMPT", PromptVisible = fresh.PromptVisible,
					Reason = "Observed stable native range/interaction guards; separate hatch budget/capacity/cooldown and server acceptance remain required" }
				if diagnostic then
					local interaction, interactionReason, native = self:HatchInteractionAt(fresh, fresh.CharacterRoot.Position, true)
					local physical, physicalReason = self:Validate(lease, token, true)
					if not physical or not physical.InRange or (physical.CharacterRoot.Position - stablePosition).Magnitude > 0.35
						or lease.RequestedStandingPosition and (physical.CharacterRoot.Position - lease.RequestedStandingPosition).Magnitude > 0.5 then
						self:Release(physicalReason or "Physical arrival changed during final interaction observation", true)
						return { Verified = false, Reason = self.Reason }
					end
					self.LastResult.Status, self.LastResult.Scope = "PHYSICAL_ARRIVAL_OBSERVED", "TRAVEL_ONLY"
					self.LastResult.World, self.LastResult.Island = fresh.World, fresh.Island
					self.LastResult.PhysicalArrivalVerified, self.LastResult.InteractionVerified = true, interaction == true
					self.LastResult.IdentityId = fresh.IdentityId
					if lease.StandingDestination then
						self.LastResult.RootDistance = fresh.Distance
						self.LastResult.Distance = Vector3.new(fresh.CharacterRoot.Position.X - fresh.TargetRoot.Position.X, 0, fresh.CharacterRoot.Position.Z - fresh.TargetRoot.Position.Z).Magnitude
						self.LastResult.StandingPosition = lease.StandingDestination.Position
						self.LastResult.SupportPath = Standing.Path(lease.StandingDestination.Support)
					end
					self.LastResult.HatchInteraction = interaction and "HATCH_RANGE_OBSERVED" or "HATCH_INTERACTION_UNVERIFIED"
					self.LastResult.InteractionReason = interactionReason
					self.LastResult.NativeRange = native and native.Range
					self.LastResult.RangeOrigin = lease.StandingDestination and "VERIFIED_PHYSICAL_EGG_ROOT; horizontal 6.5-stud policy + observed support/standing height"
						or "VERIFIED_PHYSICAL_EGG_ROOT; diagnostic 6.5-stud policy"
					self.LastResult.Reason = "Stable physical arrival near the exact verified egg Root observed; native hatch eligibility is a separate read-only result; owner live acceptance still required"
					self.Reason, self.LastPreflightReason = nil, nil
					self.DiagnosticEnded, self.Lease = true, nil
					self:DiagnosticTrace("PHYSICAL_ARRIVAL_OBSERVED", fresh, "Actual character position stable near the exact physical original; no hatch/equipment/pickups or spending")
					self:DiagnosticTrace(self.LastResult.HatchInteraction, fresh, interactionReason)
				end
				self:Report(string.format("%s | %s | distance=%.2f/%s; stability=%ss; direct attempt=%s; native travel attempt=%s; hatch commands=0; spending=0",
					fresh.EggName, self.LastResult.Status, self.LastResult.Distance, tostring(fresh.Range), tostring(settings.STABILITY_SECONDS), tostring(lease.DirectPositionAttempted == true), tostring(lease.NativeTravelAttempted == true)))
				return { Verified = true, Reason = self.LastResult.Reason }
			end
		else stableAt, stablePosition = nil, nil end
		task.wait(0.1)
	end
	local arrivalReason = record.LocationOnly and "Stable physical arrival at the requested standing destination unconfirmed; no retry or old-position restore"
		or "Stable hatch-range arrival unconfirmed; no retry or old-position restore"
	self:DiagnosticTrace("ARRIVAL_UNCONFIRMED", fresh, arrivalReason)
	self:Release(arrivalReason, true)
	return { Verified = false, Reason = self.Reason }
end

function EggTravelManager:Definition(decision, generation)
	local c, record = self.Controller, decision.Record
	return { Id = "OC_GAMEPLAY", Owner = "EGG_TRAVEL", Generation = generation, Priority = 65,
		TimeoutSeconds = ((self:Settings() or {}).ARRIVAL_TIMEOUT_SECONDS or 12) * 2 + 2,
		CanRun = function() return c.State == "RUNNING" and generation == c.Generation and self.Lease == record end,
		Execute = function(token) return self:Execute(record, token) end,
		IsComplete = function(result) return type(result) == "table" end }
end

function EggTravelManager:Completed(status, _result, reason)
	if self.DiagnosticConsumed and not self.DiagnosticEnded and status and status ~= "COMPLETED" then
		self:Release(reason or "Travel diagnostic task did not complete; no retry", true)
	end
	self:Observe()
end
function EggTravelManager:Halt(stopped) self:Release(stopped and "Stopped; no position restore or automatic retry" or "Paused; explicit revision required before another movement attempt", true) end
function EggTravelManager:Destroy() if self.Destroyed then return end self:Halt(true) self.Destroyed = true end
function EggTravelManager:GetStatus()
	return { Enabled = self:Settings() and self:Settings().ENABLE_SELECTED_EGG_TRAVEL == true,
		Lease = self.Lease, OwnsLocation = self:OwnsLocation(), Attempts = table.clone(self.Attempts),
		LastResult = self.LastResult, Reason = self.Reason, LastPreflightReason = self.LastPreflightReason, BrainIntent = self.BrainIntent, LastStandingReport = self.LastStandingReport,
		Mode = (self:Settings() or {}).MODE or "NORMAL", DiagnosticConsumed = self.DiagnosticConsumed == true, DiagnosticEnded = self.DiagnosticEnded == true,
		HatchPermission = "SEPARATE", LiveVerification = "OWNER_PENDING" }
end

return EggTravelManager

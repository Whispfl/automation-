--!nonstrict
-- Selected-location ledger and scene observation. Only the existing scheduler
-- executes its task; native transport/direct transforms stay in GameMechanics.
local EggTravelManager = {}
EggTravelManager.__index = EggTravelManager

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
		if intent.Kind ~= "HATCH" or intent.DecisionSource ~= "BRAIN" or intent.SelectionMode ~= mode
			or type(intent.EggName) ~= "string" or intent.EggName == "" then return nil, "Fresh Brain hatch destination unavailable or stale" end
		if mode == "MANUAL" and not table.find(names or {}, intent.EggName) then return nil, "Manual egg authorization changed" end
		return intent.EggName
	end
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
function EggTravelManager:Report(message)
	if message == self.LastReport then return end
	self.LastReport = message
	if type(self.Controller.Log) == "function" then self.Controller:Log("EGG_TRAVEL", message) end
end
function EggTravelManager:Key()
	local name, reason = selected(self.Controller.Config, self.BrainIntent)
	if not name then return nil, reason end
	local prefix = self.BrainIntent and self.BrainIntent.SelectionMode == "AUTO" and "AUTO:" or ""
	return prefix .. name .. ":" .. tostring((self:Settings() or {}).SELECTION_REVISION or 0), nil, name
end

function EggTravelManager:RevalidateIntent()
	local intent, c = self.BrainIntent, self.Controller
	if not intent then return true end -- Preserve separately authorized manual travel-only tests.
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

function EggTravelManager:Resolve()
	local c, settings = self.Controller, self:Settings()
	if self.Destroyed or not settings or not settings.ENABLE_SELECTED_EGG_TRAVEL then return nil, "Selected-egg travel disabled" end
	local key, reason, name = self:Key()
	if not key then return nil, reason end
	local permitted, blocker = self:RevalidateIntent()
	if not permitted then return nil, blocker end
	local profile, snapshot = c.Reader:GetLiveProfile(), c.Reader:GetSnapshot()
	if not profile or not snapshot or not snapshot.Ready or type(profile.WorldsUnlocked) ~= "table"
		or type(profile.AreasUnlocked) ~= "table" or type(profile.EggsOpened) ~= "table" then return nil, "Fresh account world/island/egg access unavailable" end
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
	local model, part, bestDistance
	for _, candidate in ipairs(c.Knowledge:EggModels()) do
		if candidate.Name == name and candidate.Parent and candidate:IsDescendantOf(workspace) then
			local candidateRoot = child(candidate, "Root")
			if live(candidateRoot) and vector(candidateRoot.Position) and child(candidate, "Prompt")
				and child(candidate, "Plate") and child(candidate, "Cost") then
				local distance = (candidateRoot.Position - root.Position).Magnitude
				if finite(distance) and (not bestDistance or distance < bestDistance) then model, part, bestDistance = candidate, candidateRoot, distance end
			end
		end
	end
	if not model then return nil, "Selected original egg model is not loaded; no force-load or event chase" end
	if self.BrainIntent and model ~= self.BrainIntent.Model then return nil, "Brain selected original egg model changed; no stale travel" end
	local island = model:GetAttribute("Island") or def.Island
	if island ~= nil and (type(island) ~= "string" or profile.AreasUnlocked[island] == nil) then
		return nil, "Selected egg island access locked or unknown; no discovery or purchase"
	end
	local opened = model:GetAttribute("Unlocked") == true and type(profile.EggsOpened) == "table" and profile.EggsOpened[name] ~= nil
	local prompt = child(model, "Prompt")
	if not live(prompt) or not vector(prompt.Position) then return nil, "Actual egg Prompt geometry unavailable" end
	local rangeOrigin, range, nativePrompt, visible = part, 16
	if opened then
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
	local record = { SelectionKey = key, EggName = name, Model = model, TargetRoot = part, PromptPart = prompt, NativePrompt = nativePrompt,
		TargetPosition = part.Position, Character = character, CharacterRoot = root, Humanoid = humanoid,
		World = world, Island = island, CurrentWorld = currentWorld, Range = range, Opened = opened,
		RangeOrigin = rangeOrigin, RangeOriginPosition = rangeOrigin.Position, PromptPosition = prompt.Position, PromptVisible = visible,
		Distance = (rangeOrigin.Position - root.Position).Magnitude, RootDistance = bestDistance,
		-- Surface eggs also require their native area arrival when coming from an
		-- island. Absence of an Island annotation cannot authorize a vertical jump.
		NeedsNativeTravel = currentWorld ~= world or math.abs(root.Position.Y - part.Position.Y) > 16,
		Destination = destination, DestinationPath = path, NativeAreaKnown = known == true }
	local eligible, rangeBlocker = self:RangeEligibleAt(record, root.Position)
	record.InRange, record.RangeBlocker = currentWorld == world and eligible, rangeBlocker
	return record
end

function EggTravelManager:RangeEligibleAt(record, position, force)
	if not vector(position) or not live(record.RangeOrigin) then return false, "Native range geometry unavailable" end
	local distance = (position - record.RangeOrigin.Position).Magnitude
	if distance > record.Range then return false, "Outside the actual native egg range origin" end
	if record.Opened then
		local prompts = self.Controller.Knowledge:Get("ProximityPrompt")
		if type(prompts) ~= "table" or prompts.Visible ~= 0 or record.Model:GetAttribute("Unlocked") ~= true then return false, "Native opened-egg scan eligibility unavailable/blocked" end
		-- Match the native nearest-unlocked selection conservatively using original
		-- loaded models; never read the private client registration table.
		for _, model in ipairs(self.Controller.Knowledge:EggModels(force)) do
			local root = model ~= record.Model and model.Parent and model:IsDescendantOf(workspace) and child(model, "Root") or nil
			if live(root) and model:GetAttribute("Unlocked") == true and vector(root.Position)
				and (root.Position - position).Magnitude <= distance + 0.05 then return false, "Another or equally near unlocked egg owns the native nearest-egg scan" end
		end
	end
	return true
end

function EggTravelManager:Validate(record, token)
	local lease = self.Lease
	if not lease or not record or record.LeaseId ~= lease.LeaseId or self.Controller.State ~= "RUNNING"
		or token and token:CheckCancelled() then return nil, "Egg location task cancelled or stale" end
	local fresh, reason = self:Resolve()
	if not fresh then return nil, reason end
	-- A first authorized hatch can change the native initial-prompt interface to
	-- the opened scanner. Refresh observed range only; never reposition on it.
	if lease.Status == "ARRIVED" and not lease.Opened and fresh.Opened and self.Controller.Pets
		and (self.Controller.Pets.Hatch.RequestedHatches or 0) > 0 then
		lease.Opened, lease.NativePrompt, lease.RangeOrigin, lease.Range = fresh.Opened, fresh.NativePrompt, fresh.RangeOrigin, fresh.Range
		lease.RangeOriginPosition, lease.PromptVisible = fresh.RangeOriginPosition, fresh.PromptVisible
	end
	if fresh.SelectionKey ~= lease.SelectionKey or fresh.Model ~= lease.Model or fresh.TargetRoot ~= lease.TargetRoot
		or fresh.PromptPart ~= lease.PromptPart or fresh.NativePrompt ~= lease.NativePrompt or fresh.Opened ~= lease.Opened
		or fresh.RangeOrigin ~= lease.RangeOrigin or fresh.Range ~= lease.Range
		or fresh.Character ~= lease.Character or fresh.CharacterRoot ~= lease.CharacterRoot
		or fresh.World ~= lease.World or fresh.Island ~= lease.Island then return nil, "Selection, target, access or character changed; no position restoration" end
	if (fresh.TargetPosition - lease.TargetPosition).Magnitude > 0.5 then return nil, "Selected egg moved; new geometry requires explicit rearm" end
	if (fresh.PromptPosition - lease.PromptPosition).Magnitude > 0.5
		or (fresh.RangeOriginPosition - lease.RangeOriginPosition).Magnitude > 0.5 then return nil, "Egg prompt/range geometry changed; explicit rearm required" end
	local movement = fresh.Humanoid.MoveDirection
	if lease.Status == "TRAVELING" and vector(movement) and movement.Magnitude > 0.05 then
		return nil, "Manual movement during arrival; explicit rearm required"
	end
	if os.clock() >= lease.Deadline then return nil, "Egg location lease expired" end
	fresh.LeaseId = lease.LeaseId
	return fresh
end

function EggTravelManager:ResolveStanding(record)
	local ok, frameOrReason = pcall(function()
		local root, humanoid, target = record.CharacterRoot, record.Humanoid, record.RangeOrigin
		if not live(target) or not vector(root.Size) or not finite(humanoid.HipHeight) or humanoid.HipHeight < 0 then
			return "Avatar/target geometry unavailable"
		end
		if type(workspace.Raycast) ~= "function" or type(workspace.GetPartBoundsInBox) ~= "function"
			or not RaycastParams or not OverlapParams or not CFrame then return "Standing-surface or clearance runtime unavailable" end
		if type(record.Character.GetBoundingBox) ~= "function" or not root.CFrame then return "Full observed avatar clearance unavailable" end
		local bodyFrame, bodySize = record.Character:GetBoundingBox()
		if not bodyFrame or not vector(bodySize) or bodySize.X <= 0 or bodySize.Y <= 0 or bodySize.Z <= 0 then
			return "Full observed avatar bounds unavailable"
		end
		local bodyOffset = root.CFrame:ToObjectSpace(bodyFrame)
		if not vector(bodyOffset.Position) or not vector(bodyOffset.RightVector) or not vector(bodyOffset.UpVector)
			or not vector(bodyOffset.LookVector) then return "Full avatar/root orientation unavailable" end
		-- Candidate root is upright. Transform the observed full avatar box relative
		-- to that root; include legs/head/accessories rather than only HRP.Size.
		local halfVertical = (math.abs(bodyOffset.RightVector.Y) * bodySize.X + math.abs(bodyOffset.UpVector.Y) * bodySize.Y
			+ math.abs(bodyOffset.LookVector.Y) * bodySize.Z) / 2
		local height = math.max(humanoid.HipHeight + root.Size.Y / 2, halfVertical - bodyOffset.Position.Y) + 0.15
		local ray = RaycastParams.new()
		ray.FilterType = Enum.RaycastFilterType.Exclude
		ray.FilterDescendantsInstances = { record.Character }
		ray.RespectCanCollide = true
		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Exclude
		overlap.RespectCanCollide = true
		local radius = math.min(4, record.Range / 2)
		local pos = target.Position
		for _, offset in ipairs({ Vector3.new(radius, 0, 0), Vector3.new(-radius, 0, 0), Vector3.new(0, 0, radius), Vector3.new(0, 0, -radius) }) do
			local horizontal = pos + offset
			local result = workspace:Raycast(horizontal + Vector3.new(0, record.Range, 0), Vector3.new(0, -record.Range * 2, 0), ray)
			local floor = result and result.Instance
			if live(floor) and floor.CanCollide == true and floor.Anchored == true and vector(result.Position)
				and vector(result.Normal) and result.Normal.Y >= 0.98 then
				local standing = Vector3.new(horizontal.X, result.Position.Y + height, horizontal.Z)
				if (standing - pos).Magnitude <= record.Range - 0.25 and self:RangeEligibleAt(record, standing) then
					local frame = CFrame.lookAt(standing, Vector3.new(pos.X, standing.Y, pos.Z))
					overlap.FilterDescendantsInstances = { record.Character, floor }
					local blocked = false
					for _, obstacle in ipairs(workspace:GetPartBoundsInBox(frame * bodyOffset, bodySize + Vector3.new(0.3, 0.1, 0.3), overlap)) do
						if obstacle.CanCollide == true then blocked = true break end
					end
					if not blocked then return frame end
				end
			end
		end
		return "No supported floor and clear full avatar volume within native hatch range; manual approach required"
	end)
	if not ok then return nil, "Standing-geometry observation failed: " .. tostring(frameOrReason) end
	if type(frameOrReason) == "string" then return nil, frameOrReason end
	return frameOrReason
end

function EggTravelManager:Release(reason, blocked)
	local lease = self.Lease
	if lease then
		if blocked then self.Blocked[lease.SelectionKey] = reason end
		self.LastResult = { Status = blocked and "HALTED" or "RELEASED", EggName = lease.EggName,
			Reason = reason, DirectPositionAttempted = lease.DirectPositionAttempted == true, NativeTravelAttempted = lease.NativeTravelAttempted == true,
			HatchCommands = 0, Spending = 0 }
	end
	self.Lease = nil
	self.Reason = reason
	self:Report(tostring(lease and lease.EggName or "Selected egg") .. " | " .. tostring(reason) .. " | hatch commands=0; spending=0")
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
	if intent then
		local name, reason = selected(self.Controller.Config, intent)
		if not name then return false, { Kind = "WAIT", Reason = reason } end
		if self.Lease and self.BrainIntent and (intent.EggName ~= self.BrainIntent.EggName
			or intent.Model ~= self.BrainIntent.Model or intent.Currency ~= self.BrainIntent.Currency) then
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
	if not key then self.Reason = reason self:Report(reason) return false, { Kind = "WAIT", Reason = reason } end
	if self.Blocked[key] then self.Reason = self.Blocked[key] self:Report(self.Reason) return false, { Kind = "WAIT", Reason = self.Reason } end
	if self.Lease then
		local pets = self.Controller.Config.PET_SETTINGS
		if self.Lease.Status == "ARRIVED" and pets and pets.AUTO_HATCH then
			return false, { Kind = "HANDOFF", OwnsLocation = true, Reason = "Selected range observed; separate existing hatch authority decides spending" }
		end
		return true, { Kind = self.Lease.Status == "ARRIVED" and "OBSERVE" or "EGG_TRAVEL", Record = self.Lease, OwnsLocation = true }
	end
	if (self.Attempts[key] or 0) >= settings.MAXIMUM_ATTEMPTS_PER_SELECTION then return false, { Kind = "WAIT", Reason = "Selected-egg attempt limit reached; explicit revision required" } end
	local record, blocker = self:Resolve()
	if not record then self.Reason = blocker self:Report(blocker) return false, { Kind = "WAIT", Reason = blocker } end
	if record.NeedsNativeTravel and (not settings.ENABLE_NATIVE_ISLAND_TRAVEL or not record.NativeAreaKnown or not record.DestinationPath) then
		self.Reason = "Correct unlocked native area travel unavailable/disabled; direct positioning cannot cross unknown worlds/islands"
		self:Report(self.Reason)
		return false, { Kind = "WAIT", Reason = self.Reason }
	end
	if not record.InRange and not settings.ENABLE_DIRECT_POSITIONING and not settings.ENABLE_NATIVE_ISLAND_TRAVEL then
		self.Reason = record.RangeBlocker or "Outside selected egg range; positioning and native island travel are disabled"
		self:Report(self.Reason)
		return false, { Kind = "WAIT", Reason = self.Reason }
	end
	self.Sequence += 1
	record.LeaseId, record.Status = self.Sequence, "PLANNED"
	record.StartedAt, record.Deadline = os.clock(), os.clock() + settings.MAXIMUM_LOCATION_SECONDS
	self.Lease = record
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
		local ok, why = c.Farming.Mechanics:TravelSelectedEgg(self, fresh, token)
		if not ok then self:Release(why or "Native selected-area travel unconfirmed", true) return { Verified = false, Reason = self.Reason } end
		fresh, reason = self:Validate(lease, token)
	end
	if not fresh then self:Release(reason, true) return { Verified = false, Reason = reason } end
	if fresh.NeedsNativeTravel then self:Release("Correct native target area arrival unconfirmed; no direct cross-world/island positioning", true) return { Verified = false, Reason = self.Reason } end
	-- Native area transport and final positioning each have a bounded window.
	-- A slow but valid area arrival must still leave time for hatch-range stability.
	local deadline = math.min(lease.Deadline, os.clock() + settings.ARRIVAL_TIMEOUT_SECONDS)
	if not fresh.InRange then
		if not settings.ENABLE_DIRECT_POSITIONING then self:Release("Native area reached; selected egg remains outside range; manual approach required", true) return { Verified = false, Reason = self.Reason } end
		local frame, geometryReason = self:ResolveStanding(fresh)
		if not frame then self:Release(geometryReason, true) return { Verified = false, Reason = geometryReason } end
		fresh, reason = self:Validate(lease, token)
		if not fresh then self:Release(reason, true) return { Verified = false, Reason = reason } end
		lease.DirectPositionAttempted = true -- Retain even on uncertain adapter error; no automatic repeat.
		local ok, why = c.Farming.Mechanics:PositionSelectedEgg(self, fresh, frame, token)
		if not ok then self:Release(why or "Direct positioning failed/unconfirmed", true) return { Verified = false, Reason = self.Reason } end
	end
	local stableAt, stablePosition
	while os.clock() < deadline do
		fresh, reason = self:Validate(lease, token)
		if not fresh then self:Release(reason, true) return { Verified = false, Reason = reason } end
		local position = fresh.CharacterRoot.Position
		local move = fresh.Humanoid.MoveDirection
		if vector(move) and move.Magnitude > 0.05 then self:Release("Manual movement during arrival; explicit rearm required", true) return { Verified = false, Reason = self.Reason } end
		if fresh.InRange and (not stablePosition or (position - stablePosition).Magnitude <= 0.35) then
			stableAt, stablePosition = stableAt or os.clock(), stablePosition or position
			if os.clock() - stableAt >= settings.STABILITY_SECONDS then
				local guardOK, allowed, blocker = pcall(function()
					if type(c.Farming.Mechanics.LocalFeatureGuard) ~= "function" then return false, "Native interaction guard unavailable" end
					return c.Farming.Mechanics:LocalFeatureGuard()
				end)
				if not guardOK or not allowed then self:Release(blocker or "Native interaction eligibility unavailable", true) return { Verified = false, Reason = self.Reason } end
				fresh, reason = self:Validate(lease, token)
				if not fresh or not fresh.InRange or (fresh.CharacterRoot.Position - stablePosition).Magnitude > 0.35 then
					self:Release(reason or "Actual native range eligibility changed during final guards", true) return { Verified = false, Reason = self.Reason }
				end
				lease.Status, lease.ArrivedAt = "ARRIVED", os.clock()
				self.LastResult = { Status = "HATCH_RANGE_OBSERVED", EggName = fresh.EggName, Distance = fresh.Distance, Range = fresh.Range,
					StabilitySeconds = settings.STABILITY_SECONDS, DirectPositionAttempted = lease.DirectPositionAttempted == true,
					NativeTravelAttempted = lease.NativeTravelAttempted == true, HatchCommands = 0, Spending = 0,
					RangeOrigin = fresh.Opened and "EGG_ROOT" or "INITIAL_PROMPT", PromptVisible = fresh.PromptVisible,
					Reason = "Observed stable native range/interaction guards; separate hatch budget/capacity/cooldown and server acceptance remain required" }
				self:Report(string.format("%s | HATCH_RANGE_OBSERVED | distance=%.2f/%s; stability=%ss; direct attempt=%s; native travel attempt=%s; hatch commands=0; spending=0",
					fresh.EggName, fresh.Distance, tostring(fresh.Range), tostring(settings.STABILITY_SECONDS), tostring(lease.DirectPositionAttempted == true), tostring(lease.NativeTravelAttempted == true)))
				return { Verified = true, Reason = self.LastResult.Reason }
			end
		else stableAt, stablePosition = nil, nil end
		task.wait(0.1)
	end
	self:Release("Stable hatch-range arrival unconfirmed; no retry or old-position restore", true)
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

function EggTravelManager:Completed() self:Observe() end
function EggTravelManager:Halt(stopped) self:Release(stopped and "Stopped; no position restore or automatic retry" or "Paused; explicit revision required before another movement attempt", true) end
function EggTravelManager:Destroy() if self.Destroyed then return end self:Halt(true) self.Destroyed = true end
function EggTravelManager:GetStatus()
	return { Enabled = self:Settings() and self:Settings().ENABLE_SELECTED_EGG_TRAVEL == true,
		Lease = self.Lease, OwnsLocation = self:OwnsLocation(), Attempts = table.clone(self.Attempts),
		LastResult = self.LastResult, Reason = self.Reason, BrainIntent = self.BrainIntent,
		HatchPermission = "SEPARATE", LiveVerification = "OWNER_PENDING" }
end

return EggTravelManager

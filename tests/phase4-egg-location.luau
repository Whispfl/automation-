do
-- Current native-shaped physical originals, world/island geometry and registration
-- are modeled separately. These tests cannot certify owner gameplay acceptance.
local before = tests
local Knowledge, Travel, Policy = requireOC("GameKnowledge"), requireOC("EggTravelManager"), requireOC("PetPolicy")
local nativeTypeof = typeof
typeof = function(value) return type(value) == "table" and value.SyntheticLocationInstance and "Instance" or nativeTypeof(value) end

local function fixture()
	local previousWorkspace, previousDelay = workspace, task.delay
	local s = { Models = {}, Definitions = {}, Logs = {}, Commands = {}, Delayed = {}, Character = {}, CurrentWorld = "The Overworld" }
	s.Workspace = { Name = "Workspace" }
	s.Rendered = { Name = "Rendered", Parent = s.Workspace }
	s.Folder = { Name = "Chunker", Parent = s.Rendered, IsA = function(_, kind) return kind == "Folder" end }
	s.Generic = { Name = "Generic", Parent = s.Rendered, IsA = function(_, kind) return kind == "Folder" end }
	s.Profile = { Coins = 100, Gems = 50, WorldsUnlocked = { ["The Overworld"] = true }, AreasUnlocked = { Zen = true, ["The Void"] = true }, EggsOpened = {} }
	s.WorldDefinitions = { ["The Overworld"] = { Islands = { { Name = "The Void", Height = 500 }, { Name = "Zen", Height = 1000 } } },
		Next = { Order = 2, Islands = {}, UnlockCost = { Type = "Currency", Currency = "Coins", Amount = 1000000000 } } }
	s.Worlds, s.WorldRows, s.Pivots, s.Spawns = {}, {}, {}, {}
	for name, definition in pairs(s.WorldDefinitions) do
		local world = { Name = name, Parent = s.Worlds }
		local x = name == "The Overworld" and -5 or 10000
		local spawn = { Parent = world, Position = Vector3.new(x, 0, -5), IsA = function(_, kind) return kind == "BasePart" end }
		s.Spawns[name] = spawn
		local islandRows, islands = {}, {}
		for _, entry in ipairs(definition.Islands) do
			local pivot = { Position = Vector3.new(x, entry.Height, -5) }
			s.Pivots[entry.Name] = pivot
			local island = { GetPivot = function() return pivot end, FindFirstChild = function() return nil end }
			islandRows[entry.Name] = { FindFirstChild = function(_, child) return child == "Island" and island or nil end }
		end
		islands.FindFirstChild = function(_, child) return islandRows[child] end
		world.FindFirstChild = function(_, child) if child == "Spawn" then return spawn elseif child == "Islands" then return islands end end
		s.Worlds[name] = world table.insert(s.WorldRows, world)
	end
	s.Worlds.GetChildren = function() return s.WorldRows end
	s.Worlds.FindFirstChild = function(_, name) return s.Worlds[name] end
	s.Workspace.FindFirstChild = function(_, name) if name == "Rendered" then return s.Rendered elseif name == "Worlds" then return s.Worlds end end
	s.Workspace.GetDescendants = function() return s.Models end
	workspace = s.Workspace
	task.delay = function(seconds, callback) table.insert(s.Delayed, { Seconds = seconds, Callback = callback }) return coroutine.create(callback) end
	s.Config = Resolver.Resolve(Defaults, {
		PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = false, AUTO_EQUIP = false },
		HATCH_SETTINGS = { EGG_SELECTION_MODE = "MANUAL", SELECTED_EGGS = { "Common Egg" }, MAXIMUM_EGG_COST = 0, MAXIMUM_SESSION_COST = 0, ENABLE_BACKGROUND_PICKUPS = false },
		EGG_TRAVEL_SETTINGS = { MODE = "TRAVEL_ONLY", ENABLE_SELECTED_EGG_TRAVEL = true, ENABLE_DIRECT_POSITIONING = true, ENABLE_NATIVE_ISLAND_TRAVEL = false,
			STABILITY_SECONDS = 1, ARRIVAL_TIMEOUT_SECONDS = 3 },
		WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false, AUTO_UNLOCK_WORLDS = false, AUTO_TRAVEL_FOR_PROGRESSION = false,
			AUTO_FARM_UNLOCK_REQUIREMENTS = false, MAXIMUM_WORLD_UNLOCK_COST = 0 },
		FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false }, ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
		PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false, STATIONARY_ISOLATED_TEST = false },
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
		UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false, ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false },
	})
	s.Root = { Parent = s.Character, Position = Vector3.new(-10, 0, -130), Size = Vector3.new(2, 2, 1) }
	s.Humanoid = { HipHeight = 2, MoveDirection = Vector3.new(0, 0, 0) }
	s.Character.FindFirstChild = function(_, name) return name == "HumanoidRootPart" and s.Root or nil end
	s.Player = { UserId = 123, Character = s.Character }
	s.Prompts = { Visible = 0, _cache = {} }
	s.Class = { Update = function(_, ...) return "native-existing-state", table.pack(...) end }
	s.NativeUpdate = s.Class.Update
	s.Dependencies = { Eggs = s.Definitions, Worlds = s.WorldDefinitions, Chunker = s.Class, ProximityPrompt = s.Prompts,
		WorldUtil = { GetPlayerWorld = function() return s.CurrentWorld end } }
	s.Reader = { Config = s.Config, Player = s.Player, _dependency = function(_, name) return s.Dependencies[name] end,
		GetLiveProfile = function() return s.Profile end, GetSnapshot = function() return { Ready = true } end }
	s.Knowledge = Knowledge.new(s.Reader) s.Knowledge.EggObservationFinished = true
	function s:Add(name, position, visual, island)
		self.Definitions[name] = { World = "The Overworld", Island = island, Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } }
		local model = { Name = name, Parent = visual and self.Generic or self.Folder, SyntheticLocationInstance = true, Attributes = { Unlocked = true, Island = island }, Children = {} }
		function model:IsA(kind) return kind == "Model" end
		function model:IsDescendantOf(ancestor)
			local current = self.Parent while current do if current == ancestor then return true end current = current.Parent end return false
		end
		function model:GetAttribute(key) return self.Attributes[key] end
		function model:GetFullName() return "Workspace.Rendered." .. self.Parent.Name .. "." .. self.Name end
		function model:FindFirstChild(key) return self.Children[key] end
		local function part(key, pos)
			local value = { Name = key, Parent = model, Position = pos, SyntheticLocationInstance = true }
			function value:IsA(kind) return kind == "BasePart" or kind == "Part" end
			function value:IsDescendantOf(ancestor) return self.Parent ~= nil and self.Parent:IsDescendantOf(ancestor) end
			function value:FindFirstChildOfClass(kind) return kind == "ProximityPrompt" and self.Engine or nil end
			return value
		end
		if visual then model.Children.Hitbox = part("Hitbox", position) model.Attributes.Offset, model.Attributes.Size = 1.5, Vector3.new(3, 4, 3)
		else
			model.Children.Root, model.Children.Prompt = part("Root", position), part("Prompt", position + Vector3.new(2.5, 1.4, 0))
			model.Children.Plate, model.Children.Cost = part("Plate", position), part("Cost", position)
			self.Profile.EggsOpened[name] = 0
		end
		table.insert(self.Models, model) return model
	end
	function s:Receiver(models)
		local receiver = { Mode = "3D", _chunkSize = 128, RenderDistance = 2, _folder = self.Folder, _chunks = { current = models }, _loaded = { current = true },
			Remove = function() error("Travel observation cannot mutate the native receiver") end }
		function receiver:IsValueLoaded(model) return self._loaded.current == true and table.find(self._chunks.current, model) ~= nil end
		return receiver
	end
	function s:Register(models)
		self.Receiver = self:Receiver(models) self.Knowledge.NativeEggChunkers = { [self.Receiver] = true } return self.Receiver
	end
	function s:Controller()
		local c = { Config = self.Config, State = "RUNNING", Generation = 1, Reader = self.Reader, Knowledge = self.Knowledge, Brain = Brain.new(self.Config),
			Log = function(_, kind, text) table.insert(s.Logs, kind .. " | " .. text) end,
			Farming = { Tracker = { Root = function() return s.Root, s.Humanoid end }, Mechanics = {} },
			Plan = { Objective = { Id = "PHYSICAL_ONLY_NATIVE_TEST" } } }
		c.Pets = { Fresh = function()
			local locations, diagnostics = self.Knowledge:EggLocationCandidates("Common Egg", true)
			for _, row in ipairs(locations) do row.Name, row.Loaded, row.Accessible = "Common Egg", true, true row.Distance = (row.Root.Position - self.Root.Position).Magnitude end
			return { Ready = true, UnlockedWorlds = self.Profile.WorldsUnlocked, UnlockedIslands = self.Profile.AreasUnlocked },
				{ EggLocations = locations, EggLocationDiagnostics = { ["Common Egg"] = diagnostics }, AccountId = self.Player.UserId }
		end }
		c.EggTravel = Travel.new(c) self.Manager, self.ControllerObject = c.EggTravel, c
		self.Token = { CheckCancelled = function() return self.Cancelled == true end }
		c.Farming.Mechanics.LocalFeatureGuard = function() return true end
		self.Manager.ResolveStanding = function(_, record) return { Position = record.RangeOriginPosition + Vector3.new(2, 0, 0) } end
		c.Farming.Mechanics.PositionSelectedEgg = function(_, manager, record, frame, token)
			local fresh, reason = manager:Validate(record, token) if not fresh then return false, reason end
			table.insert(self.Commands, "DIRECT_POSITION")
			if self.AssignmentFailure then return false, "Synthetic assignment failure" end
			self.Root.Position = self.CorrectedPosition or frame.Position return true, "Synthetic assignment; observation pending"
		end
		return c
	end
	function s:Close() self.Knowledge:Destroy() workspace, task.delay = previousWorkspace, previousDelay end
	return s
end

test("Native physical originals accept negative XYZ while economic amounts remain nonnegative", function()
	local s = fixture() s.Spawns["The Overworld"].Position = Vector3.new(-5, -100, -5)
	local original = s:Add("Common Egg", Vector3.new(-10, -100, -79)) s:Register({ original })
	local physical = s.Knowledge:ResolveEggLocation("Common Egg", true)
	assert(physical and physical.Model == original and physical.LocationVerified)
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true).Model == original)
	assert(not Policy.Finite(-10) and Policy.Finite(10), "Geometry fix cannot change financial validation") s:Close()
end)

test("Nonfinite native coordinates cannot authorize a physical location", function()
	for _, component in ipairs({ 0/0, math.huge, -math.huge }) do
		local s = fixture() s:Add("Common Egg", Vector3.new(component, 0, -79))
		assert(not s.Knowledge:ResolveEggLocation("Common Egg", true)) s:Close()
	end
end)

test("Multiple Generic visuals and same-name Chunker originals yield distinct physical targets", function()
	local s = fixture() local first = s:Add("Common Egg", Vector3.new(-10, 0, -79)) local second = s:Add("Common Egg", Vector3.new(-80, 0, 6))
	for index = 1, 9 do s:Add("Common Egg", Vector3.new(index, 0, 0), true) end
	s:Register({ first, second }) local locations, observed = s.Knowledge:EggLocationCandidates("Common Egg", true)
	assert(#locations == 2 and observed.Count == 11 and observed.LocationCount == 2 and observed.VerifiedCount == 2)
	assert(locations[1].IdentityId ~= locations[2].IdentityId and first:GetFullName() == second:GetFullName())
	assert(not s.Knowledge:ResolveEggInstance("Common Egg", true), "Paid native identity stays independently ambiguous")
	assert(s.Knowledge:ResolveEggLocation("Common Egg", true, second).Model == second) s:Close()
end)

test("An existing original registry is read without waiting for a new registration callback", function()
	local s = fixture() local original = s:Add("Common Egg", Vector3.new(-10, 0, -79)) s:Register({ original })
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true).Model == original and #s.Delayed == 0)
	assert(s.Knowledge:ResolveEggLocation("Common Egg", true).RegistrationVerified) s:Close()
end)

test("Passive Update reads preexisting signed-coordinate original membership after OC starts", function()
	simulated(function()
		local s = fixture() local original = s:Add("Common Egg", Vector3.new(-10, 0, -79)) local receiver = s:Receiver({ original })
		s.Knowledge.EggObservationFinished = nil s.Knowledge:ObserveEggChunker()
		assert(s.Class.Update ~= s.NativeUpdate and #s.Delayed == 1)
		assert(s.Class.Update(receiver, s.Root.Position) == "native-existing-state")
		task.wait(5) s.Knowledge:ObserveEggChunker()
		assert(s.Knowledge:ResolveEggInstance("Common Egg", true).Model == original and s.Class.Update == s.NativeUpdate) s:Close()
	end)
end)

test("A missed passive observation does not hide a verified physical original location", function()
	simulated(function()
		local s = fixture() local original = s:Add("Common Egg", Vector3.new(-10, 0, -79))
		s.Knowledge.EggObservationFinished = nil s.Knowledge:ObserveEggChunker() task.wait(5) s.Knowledge:ObserveEggChunker()
		assert(not s.Knowledge:ResolveEggInstance("Common Egg", true))
		local location = s.Knowledge:ResolveEggLocation("Common Egg", true)
		assert(location and location.Model == original and not location.RegistrationVerified and s.Class.Update == s.NativeUpdate) s:Close()
	end)
end)

test("Generic Hitboxes and decor originals cannot establish native spatial association", function()
	for _, kind in ipairs({ "VISUAL", "DECOR" }) do
		local s = fixture() local model = s:Add("Common Egg", Vector3.new(-10, 0, -79), kind == "VISUAL")
		if kind == "DECOR" then model.Parent = s.Generic end
		local location, reason = s.Knowledge:ResolveEggLocation("Common Egg", true)
		assert(not location and reason:find(kind == "VISUAL" and "INTERFACE_UNAVAILABLE" or "SOURCE_ASSOCIATION_UNVERIFIED", 1, true)) s:Close()
	end
end)

test("Native physical location remains blocked by locked worlds or undiscovered islands", function()
	for _, kind in ipairs({ "WORLD", "ISLAND" }) do
		local s = fixture() s:Add("Common Egg", Vector3.new(-10, 1000, -79), false, "Zen")
		if kind == "WORLD" then s.Profile.WorldsUnlocked["The Overworld"] = nil else s.Profile.AreasUnlocked.Zen = nil end
		assert(not s.Knowledge:ResolveEggLocation("Common Egg", true)) s:Close()
	end
end)

test("Legitimately unlocked islands require matching live native island geometry", function()
	local s = fixture() local original = s:Add("Common Egg", Vector3.new(-10, 1000, -79), false, "Zen")
	assert(s.Knowledge:ResolveEggLocation("Common Egg", true).Model == original)
	s.Pivots.Zen.Position = Vector3.new(-5, 2000, -5)
	local location, reason = s.Knowledge:ResolveEggLocation("Common Egg", true)
	assert(not location and reason:find("ISLAND_SPATIAL_MISMATCH", 1, true)) s:Close()
end)

test("Wrong native world placement and vertically unannotated island copies stay blocked", function()
	for _, position in ipairs({ Vector3.new(10000, 0, -79), Vector3.new(-10, 1000, -79) }) do
		local s = fixture() s:Add("Common Egg", position)
		local location, reason = s.Knowledge:ResolveEggLocation("Common Egg", true)
		assert(not location and reason:find("SPATIAL_MISMATCH", 1, true)) s:Close()
	end
end)

test("Missing world Spawn and ambiguous world or island geometry cannot authorize travel", function()
	for _, kind in ipairs({ "SPAWN", "WORLD_TIE", "AREA_TIE" }) do
		local s = fixture() s:Add("Common Egg", Vector3.new(-10, 0, -79))
		if kind == "SPAWN" then s.Spawns.Next.Position = Vector3.new(math.huge, 0, 0)
		elseif kind == "WORLD_TIE" then s.Spawns.Next.Position = s.Spawns["The Overworld"].Position
		else s.Pivots.Zen.Position = s.Spawns["The Overworld"].Position end
		assert(not s.Knowledge:ResolveEggLocation("Common Egg", true)) s:Close()
	end
end)

test("Streamed or replaced same-path originals cannot replace an exact retained physical target", function()
	local s = fixture() local first = s:Add("Common Egg", Vector3.new(-10, 0, -79)) local replacement = s:Add("Common Egg", Vector3.new(-10, 0, -79))
	assert(first:GetFullName() == replacement:GetFullName()) first.Parent = nil
	local location, reason = s.Knowledge:ResolveEggLocation("Common Egg", true, first)
	assert(not location and reason:find("SELECTED_INSTANCE_UNAVAILABLE", 1, true))
	assert(s.Knowledge:ResolveEggLocation("Common Egg", true, replacement).Model == replacement) s:Close()
end)

test("Physical arrival without hatch registration sends one movement and reports interaction unverified", function()
	simulated(function()
		local s = fixture() local original = s:Add("Common Egg", Vector3.new(-10, 0, -79)) local c = s:Controller()
		local owner, decision = c.Brain:SelectLocalFeature(c, c.Plan, false, { Kind = "WAIT" })
		assert(owner == "EGG_TRAVEL" and decision.Record.Model == original and c.EggTravel.BrainIntent.Model == original)
		local result = c.EggTravel:Definition(decision, 1).Execute(s.Token)
		assert(result.Verified and c.EggTravel.LastResult.PhysicalArrivalVerified and not c.EggTravel.LastResult.InteractionVerified)
		assert(c.EggTravel.LastResult.HatchInteraction == "HATCH_INTERACTION_UNVERIFIED" and #s.Commands == 1 and s.Commands[1] == "DIRECT_POSITION")
		assert(c.EggTravel.LastResult.HatchCommands == 0 and c.EggTravel.LastResult.Spending == 0 and s.Profile.Coins == 100 and s.Profile.Gems == 50)
		assert(table.concat(s.Logs, "\n"):find("PHYSICAL_ARRIVAL_OBSERVED", 1, true) and not table.concat(s.Logs, "\n"):find("HATCH_RANGE_OBSERVED", 1, true))
		assert(c.Brain:SelectLocalFeature(c, c.Plan, false, { Kind = "WAIT" }) == "PHASE4_WAIT" and #s.Commands == 1) s:Close()
	end)
end)

test("A corrected actual position inside the physical radius still fails requested standing arrival", function()
	simulated(function()
		local s = fixture() local original = s:Add("Common Egg", Vector3.new(-10, 0, -79)) local c = s:Controller()
		s.CorrectedPosition = original:FindFirstChild("Root").Position + Vector3.new(5, 0, 0)
		local owner, decision = c.Brain:SelectLocalFeature(c, c.Plan, false, { Kind = "WAIT" }) assert(owner == "EGG_TRAVEL")
		assert(not c.EggTravel:Definition(decision, 1).Execute(s.Token).Verified and #s.Commands == 1 and c.EggTravel.DiagnosticEnded)
		assert(not c.EggTravel.LastResult or not c.EggTravel.LastResult.PhysicalArrivalVerified)
		assert(c.Brain:SelectLocalFeature(c, c.Plan, false, { Kind = "WAIT" }) == "PHASE4_WAIT" and #s.Commands == 1) s:Close()
	end)
end)

test("Physical-only preflight blockers stay in manager status and do not consume movement permission", function()
	local s = fixture() s:Add("Common Egg", Vector3.new(-10, 0, -79), true) local c = s:Controller()
	local owner, decision = c.Brain:SelectLocalFeature(c, c.Plan, false, { Kind = "WAIT" })
	assert(owner == "PHASE4_WAIT" and decision.Reason:find("INTERFACE_UNAVAILABLE", 1, true))
	assert(c.EggTravel.Reason == decision.Reason and not c.EggTravel.DiagnosticConsumed and #s.Commands == 0)
	assert(c.EggTravel:GetStatus().Reason == decision.Reason) s:Close()
end)

typeof = nativeTypeof
print("[OC TEST] " .. tostring(tests - before) .. " egg location/interaction separation checks passed; owner gameplay remains unverified")
end

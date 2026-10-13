do
-- Actual GameKnowledge identity/resolver/observer over explicit native-shaped
-- fixtures. No fixture establishes live registry, transport, or hatch acceptance.
local before = tests
local Knowledge = requireOC("GameKnowledge")
local nativeTypeof = typeof
typeof = function(value)
	return type(value) == "table" and value.SyntheticEggInstance and "Instance" or nativeTypeof(value)
end

local function fixture()
	local s = { Models = {}, Definitions = {}, Profile = { EggsOpened = {} }, Time = 100, Delayed = {} }
	local oldWorkspace, oldClock, oldDelay = workspace, os.clock, task.delay
	local oldReplicatedFind = services.ReplicatedStorage.FindFirstChild
	s.Workspace = { Name = "Workspace" }
	s.Rendered = { Name = "Rendered", Parent = s.Workspace }
	s.Folder = { Name = "Chunker", Parent = s.Rendered, SyntheticEggInstance = true, IsA = function(_, kind) return kind == "Folder" end }
	s.Generic = { Name = "Generic", Parent = s.Rendered }
	s.Workspace.FindFirstChild = function(_, name) return name == "Rendered" and s.Rendered or nil end
	s.Workspace.GetDescendants = function() return s.Models end
	workspace = s.Workspace
	os.clock = function() return s.Time end
	task.delay = function(delay, callback)
		table.insert(s.Delayed, { At = s.Time + delay, Callback = callback })
		return coroutine.create(callback)
	end
	s.Prompts = { Visible = 0, _cache = {} }
	s.VisualAssets = {}
	s.EggAssets = { FindFirstChild = function(_, name) return s.VisualAssets[name] end }
	s.Assets = { FindFirstChild = function(_, name) return name == "Eggs" and s.EggAssets or nil end }
	services.ReplicatedStorage.FindFirstChild = function(_, name) return name == "Assets" and s.Assets or nil end
	s.NativeUpdateCalls = {}
	s.Class = { Update = function(receiver, ...)
		table.insert(s.NativeUpdateCalls, { Receiver = receiver, Args = table.pack(...) })
		if s.OnNativeUpdate then s.OnNativeUpdate(receiver) end
		return "native-result", nil, 73, false
	end }
	s.Class.__index = s.Class
	s.OriginalUpdate = s.Class.Update
	s.Dependencies = { Eggs = s.Definitions, ProximityPrompt = s.Prompts, Chunker = s.Class }
	s.Reader = { Config = Resolver.Resolve(Defaults, { PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true } }),
		_dependency = function(_, name) return s.Dependencies[name] end,
		GetLiveProfile = function() return s.Profile end }
	s.Knowledge = Knowledge.new(s.Reader)
	s.Knowledge.EggObservationFinished = true
	function s:Add(name, position, visual)
		self.Definitions[name] = { World = "The Overworld", Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } }
		self.VisualAssets[name] = self.VisualAssets[name] or { Name = name, IsA = function(_, kind) return kind == "Model" end }
		local model = { Name = name, Parent = visual and self.Generic or self.Folder,
			SyntheticEggInstance = true, Attributes = { Unlocked = true }, Children = {} }
		function model:IsA(kind) return kind == "Model" end
		function model:IsDescendantOf(ancestor)
			local current = self.Parent
			while current do if current == ancestor then return true end current = current.Parent end
			return false
		end
		function model:GetFullName() return "Workspace.Rendered." .. self.Parent.Name .. "." .. self.Name end
		function model:GetAttribute(name) return self.Attributes[name] end
		function model:FindFirstChild(name) return self.Children[name] end
		if visual then
			model.Attributes.Offset, model.Attributes.Size = 1.5, Vector3.new(3, 4, 3)
			model.Children.Hitbox = { Parent = model }
		else
			local function part(partName)
				local value = { Name = partName, Parent = model, Position = position, SyntheticEggInstance = true }
				function value:IsA(kind) return kind == "BasePart" or kind == "Part" end
				function value:FindFirstChildOfClass(kind) return kind == "ProximityPrompt" and self.Engine or nil end
				return value
			end
			model.Children.Root, model.Children.Prompt = part("Root"), part("Prompt")
			model.Children.Plate, model.Children.Cost = part("Plate"), part("Cost")
			self.Profile.EggsOpened[name] = 0
		end
		table.insert(self.Models, model)
		return model
	end
	function s:Receiver(models)
		local receiver = { Mode = "3D", _chunkSize = 128, RenderDistance = 2, _folder = self.Folder,
			_chunks = { current = models }, _loaded = { current = true },
			Remove = function() error("Identity observation must not call native Remove") end }
		function receiver:IsValueLoaded(value)
			for coord in pairs(self._loaded) do if table.find(self._chunks[coord] or {}, value) then return true end end
			return false
		end
		return setmetatable(receiver, self.Class)
	end
	function s:Register(models)
		local receiver = self:Receiver(models)
		self.Knowledge.NativeEggChunkers = { [receiver] = true }
		return receiver
	end
	function s:Engine(model, member)
		local prompt = model:FindFirstChild("Prompt")
		local engine = { Parent = prompt, Enabled = true, RequiresLineOfSight = false, MaxActivationDistance = 6.5 }
		prompt.Engine = engine self.Prompts._cache[engine] = member
		return engine
	end
	function s:BeginObservation()
		self.Knowledge.EggObservationFinished = nil
		self.Knowledge:ObserveEggChunker()
		assert(self.Class.Update ~= self.OriginalUpdate)
	end
	function s:FinishObservation()
		self.Time += 5
		self.Knowledge:ObserveEggChunker()
	end
	function s:Close()
		self.Knowledge:Destroy()
		workspace, os.clock, task.delay = oldWorkspace, oldClock, oldDelay
		services.ReplicatedStorage.FindFirstChild = oldReplicatedFind
	end
	return s
end

test("Identity resolver excludes native visual clones while retaining distinct candidate diagnostics", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(20, 0, 0))
	local visual = s:Add("Common Egg", Vector3.new(0, 0, 0), true)
	s:Register({ original })
	local record, reason, observed = s.Knowledge:ResolveEggInstance("Common Egg", true)
	assert(record and record.Model == original and reason == nil and observed.Count == 2 and observed.VerifiedCount == 1)
	assert(not s.Knowledge:ObserveEggModel(visual).Verified)
	assert(s.Knowledge:ObserveEggModel(visual).Reason:find("NON_INTERACTIVE_REPRESENTATION", 1, true))
	s:Close()
end)

test("Duplicate names remain ambiguous without an exact retained Instance while verified expected identity never retargets", function()
	local s = fixture()
	local nearer = s:Add("Common Egg", Vector3.new(1, 0, 0))
	local farther = s:Add("Common Egg", Vector3.new(100, 0, 0))
	s:Register({ nearer, farther })
	assert(nearer:GetFullName() == farther:GetFullName() and nearer.Parent == farther.Parent)
	assert(s.Knowledge:InstanceId(nearer) ~= s.Knowledge:InstanceId(farther))
	local unresolved, reason, observed = s.Knowledge:ResolveEggInstance("Common Egg", true)
	assert(not unresolved and reason:find("AMBIGUOUS_NATIVE_EGG_MODEL", 1, true) and observed.VerifiedCount == 2)
	for _, expected in ipairs({ nearer, farther }) do
		local record, exactReason, exactObserved = s.Knowledge:ResolveEggInstance("Common Egg", true, expected)
		assert(record and record.Model == expected and exactReason == nil and exactObserved.VerifiedCount == 2)
	end
	local playerRoot = { Position = Vector3.new(0, 0, 0) }
	assert(s.Knowledge:NativeEggRangeEligible({ Model = nearer }, playerRoot, true))
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = farther }, playerRoot, true))
	s:Close()
end)

test("Opened native selection identifies the exact selected Common original at 2.01 despite a distant same-name registration", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(2.01, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	s:Register({ selected, other })
	local eligible, range = s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true)
	assert(eligible and range.Model == selected and range.IdentityId == s.Knowledge:InstanceId(selected))
	assert(range.Mode == "OPENED_NEAREST" and range.Range == 16 and math.abs(range.Distance - 2.01) < 1e-6)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = other }, { Position = Vector3.new(0, 0, 0) }, true))
	s:Close()
end)

test("Opened native selection rejects nearer registered eggs and distance ties across all names", function()
	for _, name in ipairs({ "Common Egg", "Spotted Egg" }) do
		for _, distance in ipairs({ 1, 5, 5.04 }) do
			local s = fixture()
			local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
			local competitor = s:Add(name, Vector3.new(-distance, 0, 0))
			s:Register({ selected, competitor })
			assert(s.Knowledge:ResolveEggInstance("Common Egg", true, selected).Model == selected)
			assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
			s:Close()
		end
	end
end)

test("Opened native selection ignores locked registered eggs and unregistered or decorative nearer copies", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local locked = s:Add("Spotted Egg", Vector3.new(1, 0, 0)) locked.Attributes.Unlocked = false
	s:Add("Common Egg", Vector3.new(0.5, 0, 0))
	s:Add("Common Egg", Vector3.new(0.25, 0, 0), true)
	s:Register({ selected, locked })
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
	s:Close()
end)

test("Opened native range uses Root with a strict 16-stud ceiling and requires native prompt visibility zero", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(16, 0, 0))
	selected.Children.Prompt.Position = Vector3.new(100, 0, 0)
	s:Register({ selected })
	local root = { Position = Vector3.new(0, 0, 0) }
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	selected.Children.Root.Position = Vector3.new(16.001, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	selected.Children.Root.Position = Vector3.new(2.01, 0, 0) s.Prompts.Visible = 1
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	s.Prompts.Visible = nil
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	s:Close()
end)

test("First-time native interaction uses the exact cached Prompt rather than Root or opened-egg radius", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(30, 0, 0))
	selected.Attributes.Unlocked = false s.Profile.EggsOpened["Common Egg"] = nil
	selected.Children.Prompt.Position = Vector3.new(6.5, 0, 0)
	local engine = s:Engine(selected, true) s:Register({ selected })
	local root = { Position = Vector3.new(0, 0, 0) }
	local eligible, range = s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true)
	assert(eligible and range.Mode == "INITIAL_PROMPT" and range.RangeOrigin == selected.Children.Prompt and range.Range == 6.5)
	selected.Children.Prompt.Position = Vector3.new(6.501, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	selected.Children.Prompt.Position = Vector3.new(2, 0, 0) engine.MaxActivationDistance = 1.5
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	engine.MaxActivationDistance = 100 selected.Children.Prompt.Position = Vector3.new(7, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	s:Close()
end)

test("First-time native interaction fails closed when exact prompt cache or engine eligibility is stale", function()
	for _, mutate in ipairs({ function(s, e) s.Prompts._cache[e] = nil end,
		function(_, e) e.Enabled = false end, function(_, e) e.RequiresLineOfSight = true end,
		function(_, e) e.Parent = {} end, function(_, e) e.MaxActivationDistance = 0 end }) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(2, 0, 0))
		selected.Attributes.Unlocked = false s.Profile.EggsOpened["Common Egg"] = nil
		local engine = s:Engine(selected, true) s:Register({ selected })
		assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		mutate(s, engine)
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		s:Close()
	end
end)

test("Overlapping first-time eligible Prompts remain blocked while a far same-name Prompt does not cause ambiguity", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(2, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	selected.Attributes.Unlocked, other.Attributes.Unlocked = false, false s.Profile.EggsOpened["Common Egg"] = nil
	s:Engine(selected, true) s:Engine(other, true) s:Register({ selected, other })
	local root = { Position = Vector3.new(0, 0, 0) }
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	other.Children.Prompt.Position = Vector3.new(6, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	s:Close()
end)

test("Native eligibility cannot transfer to a replacement or retain an unloaded selected original", function()
	for _, replacement in ipairs({ false, true }) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(2.01, 0, 0))
		local receiver = s:Register({ selected })
		assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		if replacement then
			local new = s:Add("Common Egg", Vector3.new(2.01, 0, 0))
			selected.Parent = nil receiver._chunks.current = { new }
		else receiver._loaded.current = nil end
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		s:Close()
	end
end)

test("Opened native competition includes every loaded registered original even when its name is absent from the egg catalog", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local uncatalogued = s:Add("New Native Egg", Vector3.new(1, 0, 0))
	s.Definitions[uncatalogued.Name] = nil
	s:Register({ selected, uncatalogued })
	assert(#s.Knowledge:EggModels(true) == 1, "Catalog discovery deliberately cannot expose this competitor")
	local registered = s.Knowledge:NativeRegisteredEggModels()
	assert(registered and #registered == 2 and table.find(registered, uncatalogued))
	local root = { Position = Vector3.new(0, 0, 0) }
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	uncatalogued.Children.Root.Position = Vector3.new(12, 0, 0)
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	uncatalogued.Children.Root.Position = Vector3.new(1, 0, 0) uncatalogued.Attributes.Unlocked = false
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	s:Close()
end)

test("Complete native registration observation rejects malformed loaded arrays and coordinate disagreement", function()
	for _, mutate in ipairs({
		function(s, r, target) r._chunks.current = { target, extra = target } end,
		function(s, r, target) r._chunks.current = { [0] = target } end,
		function(s, r, target) r._chunks.current = { [1.5] = target } end,
		function(s, r) r._chunks.current = "unavailable" end,
		function(s, r) r._chunks.current = false end,
		function(s, r) r._loaded.current = false end,
		function(s, r) table.insert(r._chunks.current, "not an Instance") end,
		function(s, r) table.insert(r._chunks.current, { SyntheticEggInstance = true, IsA = function() return false end }) end,
	}) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		local receiver = s:Register({ selected }) mutate(s, receiver, selected)
		local models, reason = s.Knowledge:NativeRegisteredEggModels()
		assert(not models and type(reason) == "string")
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		s:Close()
	end
end)

test("Native Remove holes preserve the complete current exact loaded registration set", function()
	-- Chunker:Remove (66-75) sets an array member to nil. Native Update and
	-- IsValueLoaded enumerate surviving entries rather than requiring 1..#array.
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local removed = s:Add("Spotted Egg", Vector3.new(1, 0, 0))
	local receiver = s:Register({ removed, selected, removed, removed, other })
	for _, index in ipairs({ 1, 3, 4 }) do receiver._chunks.current[index] = nil end
	removed.Parent = nil
	local models = s.Knowledge:NativeRegisteredEggModels()
	assert(models and #models == 2 and table.find(models, selected) and table.find(models, other))
	assert(not table.find(models, removed))
	-- The owner approved only generic exact-Instance enumeration here. Native
	-- Remove holes must neither hide the retained original nor weaken identity.
	local identity = s.Knowledge:ResolveEggInstance("Common Egg", true, selected)
	assert(identity and identity.Model == selected and identity.RegisteredReceivers == 1)
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(diagnostic.SelectedFound and diagnostic.SelectedLoaded and diagnostic.SelectedObservedFound)
	assert(diagnostic.Stage == "CURRENT_EXACT_REGISTRATION_OBSERVED")
	s:Close()
end)

test("Native sparse loaded chunks deduplicate repeated exact identities without ignoring other names", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Spotted Egg", Vector3.new(100, 0, 0))
	local receiver = s:Register({ [2] = selected, [5] = other })
	receiver._chunks.second, receiver._loaded.second = { [4] = selected, [8] = other }, true
	local models = s.Knowledge:NativeRegisteredEggModels()
	assert(models and #models == 2 and table.find(models, selected) and table.find(models, other))
	local identity = s.Knowledge:ResolveEggInstance("Common Egg", true, selected)
	assert(identity and identity.Model == selected and identity.RegisteredReceivers == 1, "Repeated chunk memberships must count once per actual receiver")
	local root = { Position = Vector3.new(0, 0, 0) }
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	other.Children.Root.Position = Vector3.new(1, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	other.Children.Root.Position = Vector3.new(5, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	s:Close()
end)

test("Sparse native removal preserves the selected Instance and rejects same-parent same-path replacements", function()
	local s = fixture()
	local removed = s:Add("Spotted Egg", Vector3.new(100, 0, 0))
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local receiver = s:Receiver({ removed, selected, other })
	s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
	local root = { Position = Vector3.new(0, 0, 0) }
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	-- This fixture models the native Remove assignment; OC does not invoke it.
	receiver._chunks.current[1] = nil
	removed.Parent = nil
	assert(receiver._chunks.current[1] == nil and receiver._chunks.current[2] == selected, "A native array hole must leave the surviving exact Instance at its original index")
	local afterRemoval = s.Knowledge:ResolveEggInstance("Common Egg", true, selected)
	assert(afterRemoval and afterRemoval.Model == selected and afterRemoval.RegisteredReceivers == 1)
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	local replacement = s:Add("Common Egg", Vector3.new(5, 0, 0))
	assert(replacement ~= selected and replacement.Parent == selected.Parent and replacement:GetFullName() == selected:GetFullName())
	receiver._chunks.current[2] = replacement
	assert(not s.Knowledge:ResolveEggInstance("Common Egg", true, selected))
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(diagnostic.Stage == "SELECTED_EXACT_INSTANCE_ABSENT_FROM_OBSERVED_CHUNKS")
	assert(not diagnostic.SelectedFound and diagnostic.SelectedDiagnosticId == s.Knowledge:EggDiagnosticId(selected))
	assert(diagnostic.SelectedInstanceId == afterRemoval.IdentityId)
	assert(#s.NativeUpdateCalls == 1 and receiver._chunks.current[2] == replacement and selected.Parent == s.Folder)
	s:Close()
end)

test("Sparse surviving competitors still participate in opened selection across all egg names", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Spotted Egg", Vector3.new(100, 0, 0))
	s:Register({ [1] = selected, [5] = other })
	local root = { Position = Vector3.new(0, 0, 0) }
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	other.Children.Root.Position = Vector3.new(1, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true), "A surviving closer different-name original must not disappear at a hole")
	other.Children.Root.Position = Vector3.new(5, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true), "Sparse surviving competitor must still block a tie")
	s:Close()
end)

test("Complete native registration requires coherent current original geometry and bounded observation", function()
	for _, mutate in ipairs({
		function(s, r, other) other.Parent = s.Generic end,
		function(s, r, other) other.Parent = nil end,
		function(s, r, other) other.Children.Prompt.Parent = {} end,
		function(s, r, other) other.Children.Root.Position = Vector3.new(0/0, 0, 0) end,
		function(s, r, other) other.SyntheticEggInstance = nil end,
		function(s, r, other) for _ = 1, 512 do table.insert(r._chunks.current, other) end end,
	}) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		local other = s:Add("Spotted Egg", Vector3.new(100, 0, 0))
		local receiver = s:Register({ selected, other }) mutate(s, receiver, other)
		local models, reason = s.Knowledge:NativeRegisteredEggModels()
		assert(not models and type(reason) == "string")
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		s:Close()
	end
end)

test("Complete native registration deduplicates actual Instance identity across dense loaded chunks", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local receiver = s:Register({ selected, other })
	receiver._chunks.second, receiver._loaded.second = { selected, other }, true
	local models = s.Knowledge:NativeRegisteredEggModels()
	assert(models and #models == 2 and table.find(models, selected) and table.find(models, other))
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
	s:Close()
end)

test("Initial native competition includes an unrelated cached BasePart or Attachment Prompt at its actual native radius", function()
	for _, attachment in ipairs({ false, true }) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(2, 0, 0))
		selected.Attributes.Unlocked = false s.Profile.EggsOpened[selected.Name] = nil
		s:Engine(selected, true) s:Register({ selected })
		local parent = { Position = Vector3.new(12, 0, 0), WorldPosition = Vector3.new(12, 0, 0),
			IsA = function(_, kind) return kind == (attachment and "Attachment" or "BasePart") end }
		local engine = { Parent = parent, Enabled = true, RequiresLineOfSight = true, MaxActivationDistance = 20 }
		s.Prompts._cache[engine] = true
		local root = { Position = Vector3.new(0, 0, 0) }
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true), "Non-egg Prompt uses its own radius, not the egg 6.5 limit")
		engine.Enabled = false
		assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
		engine.Enabled = true parent.Position, parent.WorldPosition = Vector3.new(21, 0, 0), Vector3.new(21, 0, 0)
		assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
		s.Prompts._cache[engine] = false parent.Position, parent.WorldPosition = Vector3.new(1, 0, 0), Vector3.new(1, 0, 0)
		assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
		s:Close()
	end
end)

test("Unknown enabled cached Prompt geometry or radius fails closed while removed prompts are ignored", function()
	for _, mutate in ipairs({
		function(parent, e) parent.Position = nil end,
		function(parent, e) parent.Position = Vector3.new(math.huge, 0, 0) end,
		function(parent, e) parent.IsA = function() return false end end,
		function(parent, e) e.MaxActivationDistance = nil end,
		function(parent, e) e.MaxActivationDistance = 0 end,
	}) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(2, 0, 0))
		selected.Attributes.Unlocked = false s.Profile.EggsOpened[selected.Name] = nil
		s:Engine(selected, true) s:Register({ selected })
		local parent = { Position = Vector3.new(100, 0, 0), IsA = function(_, kind) return kind == "BasePart" end }
		local engine = { Parent = parent, Enabled = true, MaxActivationDistance = 6.5 } s.Prompts._cache[engine] = true
		mutate(parent, engine)
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		engine.Parent = nil
		assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		s:Close()
	end
end)

test("An exact observed receiver excludes a stale structural copy without choosing the nearest", function()
	local s = fixture()
	local registered = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local stale = s:Add("Common Egg", Vector3.new(1, 0, 0))
	s:Register({ registered })
	local record, reason = s.Knowledge:ResolveEggInstance("Common Egg", true)
	assert(record and record.Model == registered and reason == nil)
	assert(not s.Knowledge:ObserveEggModel(stale).Verified)
	assert(s.Knowledge:ObserveEggModel(stale).RegisteredReceivers == 0)
	s:Close()
end)

test("A changed Instance at the same path never replaces the Brain's retained original", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(10, 0, 0))
	local receiver = s:Register({ original })
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true, original))
	local replacement = s:Add("Common Egg", Vector3.new(10, 0, 0))
	local originalPath = original:GetFullName()
	original.Parent = nil receiver._chunks.current = { replacement }
	assert(replacement:GetFullName() == originalPath)
	local record, reason = s.Knowledge:ResolveEggInstance("Common Egg", true, original)
	assert(not record and reason:find("no name/path replacement", 1, true))
	s:Close()
end)

test("An initial prompt requires exact native cache membership and exact parent association", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(5, 0, 0))
	original.Attributes.Unlocked = false s.Profile.EggsOpened[original.Name] = nil
	local engine = s:Engine(original, false)
	assert(not s.Knowledge:ResolveEggInstance("Common Egg", true))
	s.Prompts._cache[engine] = true
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true).Model == original)
	engine.Parent = {} -- A cache member for a different interface cannot certify this original.
	assert(not s.Knowledge:ResolveEggInstance("Common Egg", true))
	s:Close()
end)

test("One cached prompt cannot hide another unresolved structural original without a complete receiver", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(50, 0, 0))
	s:Engine(original, true)
	s:Add("Common Egg", Vector3.new(1, 0, 0))
	local record, reason = s.Knowledge:ResolveEggInstance("Common Egg", true)
	assert(not record and reason:find("IDENTITY_UNVERIFIED", 1, true))
	s:Close()
end)

test("Malformed receiver metadata cannot exclude unknown duplicates or authorize prompt fallback", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(50, 0, 0))
	s:Engine(original, true)
	s:Add("Common Egg", Vector3.new(1, 0, 0))
	local malformed = { Mode = "3D", _chunkSize = 128, _chunks = "unavailable", _loaded = {}, _folder = s.Folder }
	s.Knowledge.NativeEggChunkers = { [malformed] = true }
	local record, reason = s.Knowledge:ResolveEggInstance("Common Egg", true)
	assert(not record and reason:find("IDENTITY_UNVERIFIED", 1, true))
	s:Close()
end)

test("Opened range scan ignores unregistered structural copies and rejects a registered nearer competitor", function()
	local s = fixture()
	local target = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Spotted Egg", Vector3.new(1, 0, 0))
	local receiver = s:Register({ target })
	local playerRoot = { Position = Vector3.new(0, 0, 0) }
	assert(s.Knowledge:NativeEggRangeEligible({ Model = target }, playerRoot, true))
	table.insert(receiver._chunks.current, other)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = target }, playerRoot, true))
	s:Close()
end)

test("Exact loaded membership is revoked when the native receiver unloads the model", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local receiver = s:Register({ original })
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true))
	receiver._loaded.current = nil
	assert(not s.Knowledge:ResolveEggInstance("Common Egg", true))
	s:Close()
end)

test("Passive observation preserves native arguments and all return values and reads only after native Update", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local receiver = s:Receiver({ original }) receiver._loaded.current = nil
	s:BeginObservation()
	s.OnNativeUpdate = function(received)
		assert(received == receiver)
		assert(not s.Knowledge.NativeEggChunkers)
		received._loaded.current = true
	end
	local returns = table.pack(s.Class.Update(receiver, "first", nil, "third", false))
	assert(returns.n == 4 and returns[1] == "native-result" and returns[2] == nil and returns[3] == 73 and returns[4] == false)
	local forwarded = s.NativeUpdateCalls[1]
	assert(forwarded.Receiver == receiver and forwarded.Args.n == 4 and forwarded.Args[1] == "first"
		and forwarded.Args[2] == nil and forwarded.Args[3] == "third" and forwarded.Args[4] == false)
	assert(s.Knowledge.NativeEggChunkers and s.Knowledge.NativeEggChunkers[receiver])
	s:FinishObservation()
	assert(s.Class.Update == s.OriginalUpdate and s.Knowledge:ResolveEggInstance("Common Egg", true).Model == original)
	s:Close()
end)

test("Already initialized native receiver remains observable through its own later Update", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(6.21, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local receiver = s:Receiver({ selected, other })
	-- This call models initialization performed by the game before OC exists.
	s.Class.Update(receiver)
	assert(#s.NativeUpdateCalls == 1 and not s.Knowledge.NativeEggChunkers)
	s:BeginObservation()
	local waiting = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(waiting.DependencyReady and waiting.Installed and waiting.Active)
	assert(waiting.Stage == "WAITING_FOR_NATIVE_UPDATE" and waiting.UpdateCalls == 0 and waiting.CandidateReceivers == 0)
	s.Class.Update(receiver)
	s:FinishObservation()
	assert(#s.NativeUpdateCalls == 2 and s.Knowledge.NativeEggChunkers[receiver])
	local observed = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(observed.Stage == "CURRENT_EXACT_REGISTRATION_OBSERVED" and observed.UpdateCalls == 1)
	assert(observed.CompletedUpdates == 1)
	assert(observed.CandidateReceivers == 1 and observed.StructureMatched == 1 and observed.QualifyingReceivers == 1 and observed.RejectedReceivers == 0)
	assert(observed.SelectedFound and observed.SelectedLoaded and observed.SelectedObservedFound and not observed.Active)
	assert(observed.SelectedDiagnosticId == s.Knowledge:EggDiagnosticId(selected))
	local identity = s.Knowledge:ResolveEggInstance("Common Egg", true, selected)
	assert(identity and identity.Model == selected and identity.RegisteredReceivers == 1)
	assert(not s.Knowledge:ResolveEggInstance("Common Egg", true), "An explicit selected Instance is still required for duplicates")
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
	s:Close()
end)

test("No native Update during the first passive window remains a timed out blocker even for initialized eggs", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(6.21, 0, 0))
	local receiver = s:Receiver({ selected })
	s.Class.Update(receiver)
	s:BeginObservation()
	local pending, pendingReason = s.Knowledge:ResolveEggInstance("Common Egg", true, selected)
	assert(not pending and pendingReason:find("PENDING", 1, true))
	s:FinishObservation()
	local missing, missingReason = s.Knowledge:ResolveEggInstance("Common Egg", true, selected)
	assert(not missing and missingReason:find("IDENTITY_UNVERIFIED", 1, true))
	assert(s.Knowledge.EggObservationFinished and not s.Knowledge.NativeEggChunkers)
	assert(s.Class.Update == s.OriginalUpdate and #s.NativeUpdateCalls == 1)
	local timedOut = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(timedOut.Stage == "TIMED_OUT_BEFORE_ANY_NATIVE_UPDATE" and timedOut.UpdateCalls == 0)
	assert(timedOut.CompletedUpdates == 0)
	assert(timedOut.DependencyReady and timedOut.Installed and not timedOut.Active and timedOut.CandidateReceivers == 0)
	-- ObserveEggChunker is frozen: an external late native call must not be
	-- mistaken for an observed registration, nor silently restart observation.
	s.Class.Update(receiver)
	s.Knowledge:ObserveEggChunker()
	assert(#s.NativeUpdateCalls == 2 and s.Class.Update == s.OriginalUpdate)
	assert(not s.Knowledge.NativeEggChunkers and not s.Knowledge:ResolveEggInstance("Common Egg", true, selected))
	assert(s.Knowledge:NativeEggRegistrationDiagnostics(selected).UpdateCalls == 0)
	s:Close()
end)

test("Unloaded original chunks do not confuse exact loaded membership and incomplete originals remain blockers", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(6.21, 0, 0))
	local other = s:Add("Spotted Egg", Vector3.new(1000, 0, 0))
	other.Parent = nil
	local receiver = s:Receiver({ selected })
	receiver._chunks.distant = { other }
	s:BeginObservation()
	s.Class.Update(receiver)
	s:FinishObservation()
	assert(s.Knowledge.NativeEggChunkers[receiver])
	local models = s.Knowledge:NativeRegisteredEggModels()
	assert(models and #models == 1 and models[1] == selected)
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true, selected).Model == selected)
	-- A native coordinate claiming loaded while its original is unparented is
	-- inconsistent live evidence. Reading it must block, not repair the scene.
	receiver._loaded.distant = true
	assert(not s.Knowledge:NativeRegisteredEggModels())
	assert(other.Parent == nil and receiver._loaded.distant == true)
	s:Close()
end)

test("Read-only registration diagnostics distinguish missing dependency from an uninstalled observer", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local notInstalled = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(notInstalled.DependencyReady and not notInstalled.Installed and notInstalled.UpdateCalls == 0)
	assert(notInstalled.Stage == "OBSERVER_NOT_INSTALLED" and #s.NativeUpdateCalls == 0)
	s.Dependencies.Chunker = nil
	local unavailable = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(not unavailable.DependencyReady and unavailable.Stage == "CHUNKER_DEPENDENCY_UNAVAILABLE")
	assert(s.Class.Update == s.OriginalUpdate and #s.NativeUpdateCalls == 0)
	s:Close()
end)

test("Native Update entry is reported even when the native function raises and its error is preserved", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local receiver = s:Receiver({ selected })
	s.OnNativeUpdate = function() error("synthetic native Update failure") end
	s:BeginObservation()
	local ok, message = pcall(s.Class.Update, receiver, "native argument", nil, 7)
	assert(not ok and tostring(message):find("synthetic native Update failure", 1, true))
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(diagnostic.UpdateCalls == 1 and diagnostic.CompletedUpdates == 0 and diagnostic.CandidateReceivers == 0)
	assert(diagnostic.Stage == "NATIVE_UPDATE_ENTERED_WITHOUT_COMPLETED_OBSERVATION")
	assert(not s.Knowledge.NativeEggChunkers and #s.NativeUpdateCalls == 1)
	local forwarded = s.NativeUpdateCalls[1].Args
	assert(forwarded.n == 3 and forwarded[1] == "native argument" and forwarded[2] == nil and forwarded[3] == 7)
	s:FinishObservation()
	assert(s.Knowledge:NativeEggRegistrationDiagnostics(selected).Stage == "NATIVE_UPDATE_ENTERED_WITHOUT_COMPLETED_OBSERVATION")
	assert(s.Class.Update == s.OriginalUpdate)
	s:Close()
end)

test("Loaded Chunker module with unavailable Update interface is distinct from missing dependency", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	s.Class.Update = nil
	s.Knowledge.EggObservationFinished = nil
	s.Knowledge:ObserveEggChunker()
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(diagnostic.ModuleLoaded and not diagnostic.DependencyReady and not diagnostic.Installed)
	assert(diagnostic.Stage == "CHUNKER_UPDATE_INTERFACE_UNAVAILABLE" and diagnostic.UpdateCalls == 0 and diagnostic.CompletedUpdates == 0)
	assert(#s.NativeUpdateCalls == 0 and not s.Knowledge.ChunkerObserver)
	s:Close()
end)

test("Read-only receiver and coordinate limits terminate reporting without altering registration evidence", function()
	for _, limit in ipairs({ "receivers", "coordinates" }) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		s:BeginObservation()
		if limit == "receivers" then
			for _ = 1, 65 do s.Class.Update(s:Receiver({})) end
			local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
			assert(diagnostic.Stage == "READ_ONLY_DIAGNOSTIC_LIMIT_EXCEEDED")
			assert(diagnostic.UpdateCalls == 65 and diagnostic.CompletedUpdates == 65 and diagnostic.CandidateReceivers == 64)
			assert(#s.NativeUpdateCalls == 65 and not s.Knowledge.NativeEggChunkers)
		else
			local receiver = s:Receiver({ selected })
			for coordinate = 1, 1001 do receiver._chunks[coordinate] = {} end
			s.Class.Update(receiver)
			local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
			assert(diagnostic.Stage == "NATIVE_UPDATES_OBSERVED_NO_QUALIFYING_EGG_RECEIVER")
			assert(diagnostic.UpdateCalls == 1 and diagnostic.CompletedUpdates == 1 and diagnostic.CandidateReceivers == 1)
			assert(diagnostic.Reason:find("COORDINATE_LIMIT_EXCEEDED", 1, true))
			assert(not s.Knowledge.NativeEggChunkers, "The approved queue classifier must enforce its coordinate bound")
			assert(receiver._loaded.current and receiver._chunks.current[1] == selected and selected.Parent == s.Folder)
		end
		s:Close()
	end
end)

test("Selected original geometry changes remain independently diagnosed and blocked after registration", function()
	for _, mutate in ipairs({
		function(selected) selected.Children.Prompt = nil end,
		function(selected) selected.Children.Root.Position = Vector3.new(0/0, 0, 0) end,
		function(selected) selected.Children.Prompt.Parent = {} end,
	}) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		local receiver = s:Receiver({ selected })
		s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
		mutate(selected)
		local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
		assert(diagnostic.Stage:find("SELECTED_ORIGINAL_GEOMETRY_CHANGED:", 1, true))
		assert(diagnostic.SelectedFound and diagnostic.SelectedLoaded and not diagnostic.SelectedGeometryAvailable)
		assert(diagnostic.SelectedDiagnosticId == s.Knowledge:EggDiagnosticId(selected) and #s.NativeUpdateCalls == 1)
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		s:Close()
	end
end)

test("Compact registration diagnostics put retained original first and count decorative same-name copies", function()
	local s = fixture()
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	for _ = 1, 23 do s:Add("Common Egg", Vector3.new(0, 0, 0), true) end
	local selected = s:Add("Common Egg", Vector3.new(6.21, 0, 0))
	local receiver = s:Receiver({ selected, other })
	s.Knowledge:EggModels(true) -- Existing planner cache supplies formatting observations.
	s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(diagnostic.PhysicalOriginals == 2 and diagnostic.ExcludedRepresentations == 23 and #diagnostic.Originals == 2)
	assert(diagnostic.Originals[1].Selected and diagnostic.Originals[1].InstanceId == s.Knowledge:EggDiagnosticId(selected))
	assert(not diagnostic.Originals[2].Selected and diagnostic.Originals[2].InstanceId == s.Knowledge:EggDiagnosticId(other))
	assert(diagnostic.Summary:find("original-shaped=2; excluded representations=23", 1, true))
	assert(diagnostic.Summary:find(s.Knowledge:EggDiagnosticId(selected) .. " SELECTED", 1, true))
	assert(not diagnostic.Summary:find("Generic", 1, true))
	assert(#s.NativeUpdateCalls == 1 and s.Knowledge:ResolveEggInstance("Common Egg", true, selected).Model == selected)
	s:Close()
end)

test("Passive diagnostics never allocate into original selection identity order or refresh Workspace models", function()
	local s = fixture()
	local first = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local second = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local receiver = s:Receiver({ second, first }) -- Native iteration sees a different order from the Brain.
	assert(s.Knowledge.InstanceIds == nil and s.Knowledge.InstanceSequence == nil and s.Knowledge.NativeEggModels == nil)
	s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(first)
	assert(diagnostic.Stage == "CURRENT_EXACT_REGISTRATION_OBSERVED")
	assert(diagnostic.SelectedInstanceId:sub(1, 1) == "D" and diagnostic.PhysicalOriginals == 0)
	assert(s.Knowledge.InstanceIds == nil and s.Knowledge.InstanceSequence == nil)
	assert(s.Knowledge.NativeEggModels == nil and s.Knowledge.LastEggScan == nil, "Reporting must not initiate an original Workspace scan")
	local cached = s.Knowledge:EggModels(true)
	local scanTime = s.Knowledge.LastEggScan
	local secondDiagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(first)
	assert(secondDiagnostic.PhysicalOriginals == 2 and secondDiagnostic.Originals[1].Selected)
	assert(s.Knowledge.InstanceIds == nil and s.Knowledge.InstanceSequence == nil)
	assert(s.Knowledge.NativeEggModels == cached and s.Knowledge.LastEggScan == scanTime)
	local firstObservation = s.Knowledge:ObserveEggModel(first)
	local secondObservation = s.Knowledge:ObserveEggModel(second)
	assert(firstObservation.IdentityId == "I0001" and firstObservation.ParentId == "I0002" and secondObservation.IdentityId == "I0003")
	local ids, sequence = s.Knowledge.InstanceIds, s.Knowledge.InstanceSequence
	local known = s.Knowledge:NativeEggRegistrationDiagnostics(first)
	assert(known.SelectedInstanceId == firstObservation.IdentityId, "A previously established physical ID may be reused without allocation")
	assert(known.SelectedDiagnosticId == diagnostic.SelectedDiagnosticId, "The reporting identifier remains stable after the Brain assigns its separate physical ID")
	assert(s.Knowledge.InstanceIds == ids and s.Knowledge.InstanceSequence == sequence and sequence == 3)
	s:Close()
	-- Reference fixture performs the same original observations without observer
	-- instrumentation. Its physical ID sequence must match exactly.
	local baseline = fixture()
	local baselineFirst = baseline:Add("Common Egg", Vector3.new(5, 0, 0))
	local baselineSecond = baseline:Add("Common Egg", Vector3.new(100, 0, 0))
	baseline:Register({ baselineSecond, baselineFirst })
	assert(baseline.Knowledge:ObserveEggModel(baselineFirst).IdentityId == firstObservation.IdentityId)
	assert(baseline.Knowledge:ObserveEggModel(baselineSecond).IdentityId == secondObservation.IdentityId)
	assert(baseline.Knowledge.InstanceSequence == sequence)
	baseline:Close()
end)

test("Read-only counters separate unrelated receiver interface and structure rejections from native calls", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local missingRemove = s:Receiver({ selected }) missingRemove.Remove = nil
	local missingLoaded = s:Receiver({ selected }) missingLoaded.IsValueLoaded = nil
	local wrongMode = s:Receiver({ selected }) wrongMode.Mode = "2D"
	local wrongSize = s:Receiver({ selected }) wrongSize._chunkSize = 256
	local wrongDistance = s:Receiver({ selected }) wrongDistance.RenderDistance = 3
	local receivers = { missingRemove, missingLoaded, wrongMode, wrongSize, wrongDistance }
	s:BeginObservation()
	for _, receiver in ipairs(receivers) do
		assert(s.Class.Update(receiver) == "native-result")
	end
	local waiting = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(waiting.Stage == "NATIVE_UPDATES_OBSERVED_NO_QUALIFYING_EGG_RECEIVER")
	assert(waiting.UpdateCalls == 5 and waiting.CandidateReceivers == 5 and waiting.StructureMatched == 0 and waiting.RejectedReceivers == 5 and waiting.QualifyingReceivers == 0)
	for _, reason in ipairs({ "MISSING_REMOVE_INTERFACE", "MISSING_IS_VALUE_LOADED_INTERFACE", "MODE=2D", "CHUNK_SIZE=256", "RENDER_DISTANCE=3" }) do
		assert(waiting.Reason:find(reason, 1, true), "Exact rejected receiver reason missing: " .. reason)
	end
	s:FinishObservation()
	assert(s.Knowledge:NativeEggRegistrationDiagnostics(selected).Stage == "TIMED_OUT_WITHOUT_QUALIFYING_EGG_RECEIVER")
	assert(#s.NativeUpdateCalls == 5 and s.Class.Update == s.OriginalUpdate and not s.Knowledge.NativeEggChunkers)
	s:Close()
end)

test("Several source-shaped non-egg receivers cannot replace an observed exact egg receiver", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local eggReceiver = s:Receiver({ selected })
	local pickup = { Name = "Pickup", SyntheticEggInstance = true, IsA = function(_, kind) return kind == "Model" end,
		FindFirstChild = function() return nil end }
	local pickupReceiver = s:Receiver({ pickup })
	local animatedReceiver = s:Receiver({ { Model = selected } })
	s:BeginObservation()
	s.Class.Update(pickupReceiver) s.Class.Update(animatedReceiver) s.Class.Update(eggReceiver) s.Class.Update(pickupReceiver)
	s:FinishObservation()
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(diagnostic.Stage == "CURRENT_EXACT_REGISTRATION_OBSERVED")
	assert(diagnostic.UpdateCalls == 4 and diagnostic.CandidateReceivers == 3 and diagnostic.StructureMatched == 3)
	assert(diagnostic.RejectedReceivers == 2 and diagnostic.QualifyingReceivers == 1)
	assert(diagnostic.Reason:find("ORIGINAL_INTERFACE_OR_GEOMETRY_INCOMPLETE", 1, true) and diagnostic.Reason:find("ENTRY_NOT_INSTANCE", 1, true))
	assert(s.Knowledge.NativeEggChunkers[eggReceiver] and not s.Knowledge.NativeEggChunkers[pickupReceiver] and not s.Knowledge.NativeEggChunkers[animatedReceiver])
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true, selected).Model == selected)
	assert(#s.NativeUpdateCalls == 4 and s.Class.Update == s.OriginalUpdate)
	s:Close()
end)

test("Read-only diagnostics retain exact malformed chunk rejection with coordinate and load state", function()
	for _, entry in ipairs({
		{ Kind = "values", Expected = "CHUNK_VALUES_NOT_TABLE" },
		{ Kind = "value", Expected = "ENTRY_NOT_INSTANCE" },
		{ Kind = "interface", Expected = "ORIGINAL_INTERFACE_OR_GEOMETRY_INCOMPLETE" },
	}) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		local other = s:Add("Spotted Egg", Vector3.new(1000, 0, 0))
		other.Parent = nil
		local receiver = s:Receiver({ selected })
		receiver._chunks.distant = { other }
		if entry.Kind == "values" then receiver._chunks.distant = "unavailable"
		elseif entry.Kind == "value" then receiver._chunks.distant = { "not an Instance" }
		elseif entry.Kind == "interface" then other.Children.Prompt = nil
		else s.Definitions[other.Name] = nil end
		s:BeginObservation()
		s.Class.Update(receiver)
		local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
		assert(diagnostic.UpdateCalls == 1 and diagnostic.CandidateReceivers == 1 and diagnostic.StructureMatched == 1)
		assert(diagnostic.RejectedReceivers == 1 and diagnostic.QualifyingReceivers == 0)
		assert(diagnostic.Reason:find(entry.Expected, 1, true) and diagnostic.Reason:find("coord=distant", 1, true))
		if entry.Kind ~= "values" then assert(diagnostic.Reason:find("loaded=nil", 1, true)) end
		if entry.Kind == "interface" then assert(diagnostic.Reason:find(s.Knowledge:EggDiagnosticId(other), 1, true)) end
		assert(not s.Knowledge.NativeEggChunkers and not s.Knowledge:ResolveEggInstance("Common Egg", true, selected))
		s:Close()
	end
end)

test("Current exact diagnostic distinguishes receiver mutation unloaded coordinate and replaced original", function()
	for _, mutate in ipairs({
		{ Stage = "OBSERVED_RECEIVER_STRUCTURE_CHANGED", Change = function(s, receiver) receiver.Mode = "2D" end },
		{ Stage = "SELECTED_INSTANCE_UNLOADED", Change = function(s, receiver, selected) selected.Parent = nil end },
		{ Stage = "SELECTED_EXACT_INSTANCE_COORDINATE_UNLOADED_OR_ANCESTRY_CHANGED", Change = function(s, receiver) receiver._loaded.current = nil end },
		{ Stage = "SELECTED_EXACT_INSTANCE_ABSENT_FROM_OBSERVED_CHUNKS", Change = function(s, receiver) receiver._chunks.current = { s:Add("Common Egg", Vector3.new(5, 0, 0)) } end },
	}) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		local receiver = s:Receiver({ selected })
		s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
		local initial = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
		assert(initial.Stage == "CURRENT_EXACT_REGISTRATION_OBSERVED" and initial.SelectedFound and initial.SelectedLoaded)
		mutate.Change(s, receiver, selected)
		local changed = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
		assert(changed.Stage == mutate.Stage, changed.Stage)
		assert(changed.SelectedDiagnosticId == s.Knowledge:EggDiagnosticId(selected) and #s.NativeUpdateCalls == 1)
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		s:Close()
	end
end)

test("Shared size settings cannot identify a pickup or mixed-object receiver as the egg receiver", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local receiver = s:Receiver({ original, { Name = "Pickup", SyntheticEggInstance = true } })
	s:BeginObservation()
	s.Class.Update(receiver, Vector3.new(0, 0, 0))
	assert(not s.Knowledge.NativeEggChunkers)
	s:FinishObservation()
	assert(not s.Knowledge:ResolveEggInstance("Common Egg", true) and s.Class.Update == s.OriginalUpdate)
	s:Close()
end)

test("Egg and pickup discovery share one observer and preserve both exact receivers", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local eggReceiver = s:Receiver({ original })
	local pickup = { Name = "Synthetic pickup", Parent = s.Folder, SyntheticEggInstance = true,
		IsA = function(_, kind) return kind == "Model" end, FindFirstChild = function() return nil end }
	local pickupReceiver = s:Receiver({ pickup })
	s.Dependencies.Tutorial = { _activePickups = { pickup } }
	s:BeginObservation()
	local sharedObserver = s.Class.Update
	assert(not s.Knowledge:PickupChunker())
	assert(s.Class.Update == sharedObserver)
	s.Class.Update(eggReceiver)
	s.Class.Update(pickupReceiver)
	assert(s.Knowledge.NativePickupChunker == pickupReceiver and s.Knowledge.NativeEggChunkers[eggReceiver])
	assert(s.Class.Update == sharedObserver, "Pickup discovery must retain pending egg observation")
	s:FinishObservation()
	assert(s.Class.Update == s.OriginalUpdate and s.Knowledge:PickupChunker() == pickupReceiver)
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true).Model == original)
	s:Close()
end)

test("Native Coming Soon sentinels may identify the receiver but cannot become selected egg definitions", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local sentinel = s:Add("Coming Soon", Vector3.new(8, 0, 0))
	sentinel.Attributes.Unlocked = false
	s.Definitions["Coming Soon"] = nil
	local receiver = s:Receiver({ original, sentinel })
	s:BeginObservation()
	s.Class.Update(receiver)
	s:FinishObservation()
	assert(s.Knowledge.NativeEggChunkers[receiver])
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(original)
	assert(diagnostic.QualifyingReceivers == 1 and diagnostic.Receivers[1].CatalogOriginals == 1 and diagnostic.Receivers[1].Sentinels == 1)
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true).Model == original)
	assert(not s.Knowledge:ResolveEggInstance("Coming Soon", true))
	local models = s.Knowledge:NativeRegisteredEggModels()
	assert(models and #models == 2 and table.find(models, sentinel))
	sentinel.Children.Root.Position = Vector3.new(1, 0, 0)
	assert(s.Knowledge:NativeEggRangeEligible({ Model = original }, { Position = Vector3.new(0, 0, 0) }, true), "Native Coming Soon is registered but locked, so cannot own nearest interaction")
	s:Close()
end)

test("Multiple observed egg receivers preserve ambiguity instead of preferring folder or call order", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local receiver = s:Receiver({ original })
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local second = s:Receiver({ other })
	second._folder = { Name = "Chunker", Parent = s.Rendered, SyntheticEggInstance = true, IsA = function(_, kind) return kind == "Folder" end }
	other.Parent = second._folder
	s:BeginObservation()
	s.Class.Update(receiver) s.Class.Update(second)
	s:FinishObservation()
	local record, reason = s.Knowledge:ResolveEggInstance("Common Egg", true)
	assert(not record and reason:find("IDENTITY_UNVERIFIED", 1, true))
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(original)
	assert(diagnostic.Stage == "MULTIPLE_QUALIFYING_EGG_RECEIVERS" and diagnostic.UpdateCalls == 2 and diagnostic.CandidateReceivers == 2)
	assert(diagnostic.StructureMatched == 2 and diagnostic.QualifyingReceivers == 2 and diagnostic.RejectedReceivers == 0)
	assert(diagnostic.Receivers[1].Id ~= diagnostic.Receivers[2].Id and diagnostic.Receivers[1].FolderId ~= diagnostic.Receivers[2].FolderId)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = original }, { Position = Vector3.new(0, 0, 0) }, true))
	s:Close()
end)

test("Bounded observer timeout restores the native method without discovering or moving an egg", function()
	local s = fixture()
	s:Add("Common Egg", Vector3.new(5, 0, 0))
	s:BeginObservation()
	assert(#s.Delayed == 1 and #s.NativeUpdateCalls == 0)
	s.Time += 5 s.Delayed[1].Callback()
	assert(s.Knowledge.EggObservationFinished and s.Class.Update == s.OriginalUpdate and not s.Knowledge.NativeEggChunkers)
	assert(not s.Knowledge:ResolveEggInstance("Common Egg", true))
	s:Close()
end)

test("Observer release preserves a newer native wrapper and a destroyed observer cannot record late receivers", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local receiver = s:Receiver({ original })
	s:BeginObservation()
	local captured = s.Class.Update
	local newer = function() return "newer-native-wrapper" end
	s.Class.Update = newer
	s.Knowledge:Destroy()
	assert(s.Class.Update == newer)
	assert(captured(receiver) == "native-result")
	assert(not s.Knowledge.NativeEggChunkers, "Destroyed observation must not add a captured receiver")
	s.Delayed[1].Callback()
	assert(s.Class.Update == newer, "Late timeout must not overwrite a newer wrapper")
	s:Close()
end)

local function capturedReceiverScene(includeCommon)
	local s = fixture()
	s.Selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	s.Other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	for _ = 1, 21 do s:Add("Common Egg", Vector3.new(0, 0, 0), true) end
	s.Unsupported = s:Add("Egg", Vector3.new(1000, 0, 0))
	s.Definitions[s.Unsupported.Name] = nil s.Unsupported.Parent = nil
	s.EggLike = s:Receiver(includeCommon and { s.Selected, s.Other } or {})
	s.EggLike._chunks.unloaded = { s.Unsupported }
	local function bare(name)
		return { Name = name, SyntheticEggInstance = true, IsA = function(_, kind) return kind == "Model" end,
			FindFirstChild = function() return nil end }
	end
	local pickup = s:Receiver({ bare("synthetic pickup") })
	local animated = s:Receiver({ { Model = s.Selected } })
	local twoD = s:Receiver({}) twoD.Mode, twoD._chunkSize = "2D", 256
	local portal = s:Receiver({ bare("synthetic portal") })
	for _, receiver in ipairs({ pickup, animated, twoD, portal }) do receiver._folder = { Name = "Chunker", Parent = s.Rendered } end
	s.Receivers = { pickup, s.EggLike, animated, twoD, portal }
	s.Knowledge:EggModels(true) -- Existing discovery cache, no reporting-triggered scan.
	return s
end

local function capturedRow(s, diagnostic, receiver)
	for _, row in ipairs(diagnostic.CapturedReceivers) do
		if row.Id == s.Knowledge:EggDiagnosticId(receiver) then return row end
	end
	error("Expected captured exact receiver missing from diagnostic")
end

test("85 native updates accept a source-backed queue containing a noncatalog original without authorizing that target", function()
	local s = capturedReceiverScene(true)
	s:BeginObservation()
	local earlyKey
	for index = 1, 85 do
		s.Class.Update(s.Receivers[(index - 1) % #s.Receivers + 1])
		if index == 29 then
			local early = s.Knowledge:NativeEggRegistrationDiagnostics(s.Selected)
			assert(early.UpdateCalls == 29 and early.CompletedUpdates == 29 and early.CandidateReceivers == 5)
			assert(early.CapturedSelectedFound and early.CapturedOtherOriginalFound and early.SelectedFound)
			earlyKey = early.ReceiverObservationKey
		end
	end
	local active = s.Knowledge:NativeEggRegistrationDiagnostics(s.Selected)
	assert(active.ReceiverObservationKey == earlyKey, "An unchanged receiver snapshot must not log again merely because native call counts increase")
	s:FinishObservation()
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(s.Selected)
	assert(diagnostic.UpdateCalls == 85 and diagnostic.CompletedUpdates == 85 and diagnostic.CandidateReceivers == 5)
	assert(diagnostic.StructureMatched == 4 and diagnostic.RejectedReceivers == 4 and diagnostic.QualifyingReceivers == 1)
	assert(diagnostic.Stage == "CURRENT_EXACT_REGISTRATION_OBSERVED" and diagnostic.ReceiverObservationComplete and diagnostic.FullCandidateInspectionComplete)
	assert(diagnostic.CurrentCandidateReceiversCount == 5 and diagnostic.CapturedSelectedFound and diagnostic.CapturedOtherOriginalFound and diagnostic.OtherOriginalsFound == 1)
	assert(diagnostic.SelectedFound and diagnostic.SelectedLoaded and diagnostic.SelectedObservedFound)
	local row = capturedRow(s, diagnostic, s.EggLike)
	assert(row.StructureMatched and row.CatalogReady and row.ContentSourceCompatible and row.AcceptedReceiver and row.LastObserverQualified)
	assert(row.ChunkCoordinates == 2 and row.LoadedCoordinates == 1 and row.Values == 3 and row.Instances == 3 and row.Models == 3)
	assert(row.FullOriginalInterfaces == 3 and row.CatalogOriginals == 2 and row.MissingCatalog == 1 and row.Sentinels == 0)
	assert(row.SelectedFound and row.SelectedLoaded and row.SelectedParentEqualsFolder and row.OtherOriginalsFound == 1)
	assert(row.LastObserverReason:find("SOURCE_MATCHING_ORIGINAL_QUEUE_OBSERVED", 1, true))
	assert(table.concat(row.Issues, ","):find("MISSING_CATALOG_DEFINITION=1", 1, true) and #row.Examples <= 2)
	assert(diagnostic.ExcludedRepresentations == 21 and diagnostic.ReceiverObservationSummary:find("exact selected in ANY captured=true", 1, true))
	assert(s.Knowledge.NativeEggChunkers[s.EggLike] and s.Knowledge:NativeEggRangeEligible({ Model = s.Selected }, { Position = Vector3.new(0, 0, 0) }, true))
	assert(not s.Knowledge:ResolveEggInstance(s.Unsupported.Name, true, s.Unsupported), "Queued noncatalog originals must not become catalog-selected hatch targets")
	assert(s.Class.Update == s.OriginalUpdate and #s.NativeUpdateCalls == 85)
	s:Close()
end)

test("85 unrelated native updates never establish that the actual egg receiver invocation was observed", function()
	local s = capturedReceiverScene(false)
	s:BeginObservation()
	for index = 1, 85 do s.Class.Update(s.Receivers[(index - 1) % #s.Receivers + 1]) end
	s:FinishObservation()
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(s.Selected)
	assert(diagnostic.UpdateCalls == 85 and diagnostic.CompletedUpdates == 85 and diagnostic.QualifyingReceivers == 0)
	assert(diagnostic.CurrentCandidateReceiversCount == 5 and diagnostic.FullCandidateInspectionComplete and diagnostic.ReceiverObservationComplete)
	assert(not diagnostic.CapturedSelectedFound and not diagnostic.CapturedOtherOriginalFound and not diagnostic.SelectedFound)
	assert(diagnostic.ReceiverObservationSummary:find("exact selected in ANY captured=false", 1, true))
	assert(diagnostic.ReceiverUpdateAttribution == "UNVERIFIED" and diagnostic.ReceiverObservationSummary:find("egg receiver Update attribution=UNVERIFIED", 1, true))
	assert(capturedRow(s, diagnostic, s.EggLike).SelectedParentEqualsFolder, "Matching a folder alone must not invent exact membership")
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = s.Selected }, { Position = Vector3.new(0, 0, 0) }, true))
	assert(s.Class.Update == s.OriginalUpdate and #s.NativeUpdateCalls == 85)
	s:Close()
end)

test("A genuine exact egg receiver among unrelated 3D receivers remains independently verified", function()
	local s = capturedReceiverScene(true)
	s.EggLike._chunks.unloaded = nil
	s:BeginObservation()
	for index = 1, 85 do s.Class.Update(s.Receivers[(index - 1) % #s.Receivers + 1]) end
	s:FinishObservation()
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(s.Selected)
	assert(diagnostic.UpdateCalls == 85 and diagnostic.CandidateReceivers == 5 and diagnostic.StructureMatched == 4)
	assert(diagnostic.RejectedReceivers == 4 and diagnostic.QualifyingReceivers == 1 and diagnostic.SelectedFound and diagnostic.SelectedLoaded)
	assert(diagnostic.ReceiverUpdateAttribution == "SOURCE_MATCHING_ACCEPTED_RECEIVER_OBSERVED")
	assert(diagnostic.CapturedSelectedFound and diagnostic.CapturedOtherOriginalFound and diagnostic.FullCandidateInspectionComplete)
	local row = capturedRow(s, diagnostic, s.EggLike)
	assert(row.AcceptedReceiver and row.LastObserverQualified and row.SelectedFound and row.OtherOriginalsFound == 1 and #row.Issues == 0)
	local identity = s.Knowledge:ResolveEggInstance("Common Egg", true, s.Selected)
	assert(identity and identity.Model == s.Selected and identity.RegisteredReceivers == 1)
	assert(s.Knowledge:NativeEggRangeEligible({ Model = s.Selected }, { Position = Vector3.new(0, 0, 0) }, true))
	s.Other.Children.Root.Position = Vector3.new(5, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = s.Selected }, { Position = Vector3.new(0, 0, 0) }, true))
	s:Close()
end)

test("Full candidate diagnostics preserve sparse loaded originals and legitimate unloaded sentinel entries", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local distant = s:Add("Spotted Egg", Vector3.new(1000, 0, 0)) distant.Parent = nil
	local sentinel = s:Add("Coming Soon", Vector3.new(1000, 0, 0)) sentinel.Parent = nil sentinel.Attributes.Unlocked = false
	s.Definitions[sentinel.Name] = nil
	local receiver = s:Receiver({ [2] = selected, [5] = other })
	receiver._chunks.unloaded = { [3] = distant, [8] = sentinel }
	s.Knowledge:EggModels(true)
	s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	local row = capturedRow(s, diagnostic, receiver)
	assert(row.InspectionComplete and row.ContentSourceCompatible and row.Values == 4 and row.Instances == 4 and row.FullOriginalInterfaces == 4)
	assert(row.ChunkCoordinates == 2 and row.LoadedCoordinates == 1 and row.CatalogOriginals == 3 and row.Sentinels == 1 and row.MissingCatalog == 0)
	assert(#row.Issues == 0 and row.SelectedFound and row.SelectedLoaded and row.OtherOriginalsFound == 1)
	assert(diagnostic.SelectedFound and diagnostic.CapturedSelectedFound and diagnostic.CapturedOtherOriginalFound and diagnostic.QualifyingReceivers == 1)
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true, selected).Model == selected)
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
	s:Close()
end)

test("Catalog becoming ready within the passive window requires another native observed Update", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local receiver = s:Receiver({ selected, other })
	s.Knowledge:EggModels(true)
	s.Dependencies.Eggs = nil
	s:BeginObservation() s.Class.Update(receiver)
	local missing = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	local row = capturedRow(s, missing, receiver)
	assert(not row.CatalogReady and row.MissingCatalog == 2 and row.CatalogOriginals == 0)
	assert(table.concat(row.Issues, ","):find("CATALOG_NOT_READY=2", 1, true))
	assert(missing.CapturedSelectedFound and missing.CapturedOtherOriginalFound and not missing.SelectedFound and missing.QualifyingReceivers == 0)
	s.Dependencies.Eggs = s.Definitions
	local nowReady = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(capturedRow(s, nowReady, receiver).CatalogReady and nowReady.QualifyingReceivers == 0 and not s.Knowledge.NativeEggChunkers)
	s.Class.Update(receiver) s:FinishObservation()
	local observed = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(observed.UpdateCalls == 2 and observed.CompletedUpdates == 2 and observed.QualifyingReceivers == 1 and observed.SelectedFound)
	assert(capturedRow(s, observed, receiver).MissingCatalog == 0 and #capturedRow(s, observed, receiver).Issues == 0)
	s:Close()
end)

test("Catalog readiness after the window does not retroactively qualify a rejected captured receiver", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local receiver = s:Receiver({ selected })
	s.Knowledge:EggModels(true)
	s.Dependencies.Eggs = nil
	s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
	s.Dependencies.Eggs = s.Definitions
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	local row = capturedRow(s, diagnostic, receiver)
	assert(row.CatalogReady and row.ContentSourceCompatible and row.CatalogOriginals == 1 and row.MissingCatalog == 0)
	assert(not row.LastObserverQualified and not row.AcceptedReceiver and diagnostic.CapturedSelectedFound and not diagnostic.SelectedFound)
	assert(diagnostic.ReceiverObservationComplete and diagnostic.QualifyingReceivers == 0 and diagnostic.Stage == "TIMED_OUT_WITHOUT_QUALIFYING_EGG_RECEIVER")
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
	assert(s.Class.Update == s.OriginalUpdate and #s.NativeUpdateCalls == 1)
	s:Close()
end)

test("Partial or bounded candidate inspection reports UNKNOWN rather than claiming originals absent", function()
	for _, kind in ipairs({ "invalid chunk", "value limit", "coordinate limit" }) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		local unsupported = s:Add("Egg", Vector3.new(1000, 0, 0)) s.Definitions[unsupported.Name] = nil unsupported.Parent = nil
		local receiver = s:Receiver({ unsupported })
		if kind == "invalid chunk" then receiver._chunks.unavailable = "unavailable"
		elseif kind == "value limit" then for index = 2, 1001 do receiver._chunks.current[index] = unsupported end
		else for coordinate = 1, 1001 do receiver._chunks[coordinate] = {} end end
		s.Knowledge:EggModels(true)
		s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
		local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
		assert(not diagnostic.FullCandidateInspectionComplete and not diagnostic.CapturedSelectedFound)
		assert(diagnostic.ReceiverObservationSummary:find("exact selected in ANY captured=UNKNOWN", 1, true))
		assert(not capturedRow(s, diagnostic, receiver).InspectionComplete and not diagnostic.SelectedFound)
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		s:Close()
	end
end)

test("Full candidate inspection preserves observer lifecycle exact identity namespace and native invocation count", function()
	local s = capturedReceiverScene(true)
	s:BeginObservation()
	local wrapper = s.Class.Update
	s.Knowledge:ObserveEggChunker() s.Knowledge:ObserveEggChunker()
	assert(s.Class.Update == wrapper and #s.Delayed == 1 and s.Knowledge.InstanceIds == nil)
	s.Class.Update(s.EggLike)
	local models, scanned = s.Knowledge.NativeEggModels, s.Knowledge.LastEggScan
	local first = s.Knowledge:NativeEggRegistrationDiagnostics(s.Selected)
	local second = s.Knowledge:NativeEggRegistrationDiagnostics(s.Selected)
	assert(first.CapturedSelectedFound and second.CapturedSelectedFound and first.ReceiverObservationKey == second.ReceiverObservationKey)
	assert(s.Knowledge.InstanceIds == nil and s.Knowledge.InstanceSequence == nil and s.Knowledge.NativeEggModels == models and s.Knowledge.LastEggScan == scanned)
	assert(s.Class.Update == wrapper and #s.NativeUpdateCalls == 1)
	s.Knowledge:Destroy()
	assert(s.Class.Update == s.OriginalUpdate and not s.Knowledge.NativeEggChunkers)
	local late = wrapper(s.EggLike)
	assert(late == "native-result" and #s.NativeUpdateCalls == 2)
	local stopped = s.Knowledge:NativeEggRegistrationDiagnostics(s.Selected)
	assert(stopped.UpdateCalls == 1 and stopped.CompletedUpdates == 1 and stopped.Stage == "OBSERVER_DESTROYED")
	s.Delayed[1].Callback()
	assert(s.Class.Update == s.OriginalUpdate and #s.Delayed == 1)
	s:Close()
end)

test("Native final-member removal leaves a valid empty loaded coordinate without hiding other originals", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local removed = s:Add("Spotted Egg", Vector3.new(1000, 0, 0))
	local receiver = s:Receiver({ selected, other })
	receiver._chunks.last, receiver._loaded.last = { removed }, true
	s.Knowledge:EggModels(true)
	s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
	assert(#s.Knowledge:NativeRegisteredEggModels() == 3)
	-- Chunker.Remove:73-75 clears an empty _chunks bucket without clearing
	-- _loaded. This fixture models that native assignment; OC calls no Remove.
	receiver._chunks.last[1] = nil
	assert(next(receiver._chunks.last) == nil)
	receiver._chunks.last = nil
	removed.Parent = nil
	local models = s.Knowledge:NativeRegisteredEggModels()
	assert(models and #models == 2 and table.find(models, selected) and table.find(models, other))
	assert(not table.find(models, removed) and receiver._loaded.last == true)
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	local row = capturedRow(s, diagnostic, receiver)
	assert(row.InspectionComplete and row.ChunkCoordinates == 1 and row.LoadedCoordinates == 2 and row.EmptyLoadedCoordinates == 1)
	assert(row.SelectedFound and row.SelectedLoaded and diagnostic.SelectedFound and diagnostic.FullCandidateInspectionComplete)
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true, selected).Model == selected)
	local root = { Position = Vector3.new(0, 0, 0) }
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	other.Children.Root.Position = Vector3.new(1, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	other.Children.Root.Position = Vector3.new(5, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	assert(#s.NativeUpdateCalls == 1)
	s:Close()
end)

test("An absent loaded bucket is distinct from present malformed contents or inconsistent loaded flags", function()
	for _, kind in ipairs({ "false values", "string values", "false loaded", "coordinate limit" }) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		local receiver = s:Register({ selected })
		receiver._loaded.empty = true
		assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		if kind == "false values" then receiver._chunks.empty = false
		elseif kind == "string values" then receiver._chunks.empty = "unavailable"
		elseif kind == "false loaded" then receiver._loaded.empty = false
		else for coordinate = 1, 1001 do receiver._loaded[coordinate] = true end end
		local models, reason = s.Knowledge:NativeRegisteredEggModels()
		assert(not models and type(reason) == "string")
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		s:Close()
	end
end)

test("An emptied selected bucket cannot transfer identity to another loaded same-name original", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	local receiver = s:Register({ selected })
	receiver._chunks.other, receiver._loaded.other = { other }, true
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true, selected).Model == selected)
	receiver._chunks.current[1] = nil
	receiver._chunks.current = nil
	local models = s.Knowledge:NativeRegisteredEggModels()
	assert(models and #models == 1 and models[1] == other)
	assert(not s.Knowledge:ResolveEggInstance("Common Egg", true, selected))
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
	assert(receiver._loaded.current == true and selected.Parent == other.Parent)
	s:Close()
end)

test("Read-only receiver metadata distinguishes inherited public Update from a cached own function", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local receiver = s:Receiver({ selected })
	s.Class.__index = s.Class setmetatable(receiver, s.Class)
	s.Knowledge:EggModels(true)
	s:BeginObservation()
	receiver:Update()
	local inherited = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	local inheritedRow = capturedRow(s, inherited, receiver)
	assert(inheritedRow.ClassMetatableMatches and not inheritedRow.HasOwnUpdate and inheritedRow.ResolvedUpdateMatchesPublicClass)
	assert(inheritedRow.FolderParentName == "Rendered" and inheritedRow.FolderParentId == s.Knowledge:EggDiagnosticId(s.Rendered))
	assert(inherited.UpdateCalls == 1 and inherited.CompletedUpdates == 1 and #s.NativeUpdateCalls == 1)
	-- A fixture-native cache assignment can bypass a future class wrapper. The
	-- diagnostic reads that fact and must never replace/intercept this method.
	receiver.Update = s.OriginalUpdate
	receiver:Update()
	local own = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	local ownRow = capturedRow(s, own, receiver)
	assert(ownRow.ClassMetatableMatches and ownRow.HasOwnUpdate and not ownRow.ResolvedUpdateMatchesPublicClass)
	assert(own.UpdateCalls == 1 and own.CompletedUpdates == 1 and #s.NativeUpdateCalls == 2)
	assert(receiver.Update == s.OriginalUpdate and getmetatable(receiver) == s.Class and s.Knowledge.InstanceIds == nil)
	s:FinishObservation()
	assert(s.Class.Update == s.OriginalUpdate and receiver.Update == s.OriginalUpdate)
	local restored = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	assert(capturedRow(s, restored, receiver).ResolvedUpdateMatchesPublicClass)
	s:Close()
end)

test("Approved native queue classification accepts the exact 55 catalog 21 sentinel 60 noncatalog original mixture", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local other = s:Add("Common Egg", Vector3.new(100, 0, 0))
	s.Profile.EggsOpened["Common Egg"] = 2
	local receiver = s:Receiver({ selected, other })
	local unloadedIndex, removable = 0, nil
	local function queuedUnloaded(model)
		unloadedIndex += 1 model.Parent = nil
		local coord = "unloaded" .. tostring((unloadedIndex - 1) % 59 + 1)
		receiver._chunks[coord] = receiver._chunks[coord] or {}
		table.insert(receiver._chunks[coord], model)
	end
	for index = 1, 53 do
		local model = s:Add("Synthetic catalog original " .. tostring(index), Vector3.new(1000 + index, 0, 0))
		if index <= 4 then receiver._chunks["loaded" .. index], receiver._loaded["loaded" .. index] = { model }, true
		else queuedUnloaded(model) removable = model end
	end
	for _ = 1, 21 do
		local model = s:Add("Coming Soon", Vector3.new(1000, 0, 0))
		model.Attributes.Unlocked = false queuedUnloaded(model)
	end
	s.Definitions["Coming Soon"] = nil
	local unknowns = {}
	for _ = 1, 60 do
		local model = s:Add("Egg", Vector3.new(1000, 0, 0))
		table.insert(unknowns, model) queuedUnloaded(model)
	end
	s.Definitions.Egg, s.VisualAssets.Egg = nil, nil
	for _ = 1, 21 do s:Add("Common Egg", Vector3.new(0, 0, 0), true) end
	s.Knowledge:EggModels(true)
	s:BeginObservation() s.Class.Update(receiver)
	local first = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	local row = capturedRow(s, first, receiver)
	assert(row.Values == 136 and row.Instances == 136 and row.Models == 136 and row.FullOriginalInterfaces == 136)
	assert(row.CatalogOriginals == 55 and row.Sentinels == 21 and row.MissingCatalog == 60 and row.ChunkCoordinates == 64 and row.LoadedCoordinates == 5)
	assert(row.AcceptedReceiver and row.LastObserverQualified and row.SelectedFound and row.SelectedLoaded and row.SelectedParentEqualsFolder and row.OtherOriginalsFound == 1)
	assert(first.QualifyingReceivers == 1 and first.ExcludedRepresentations == 21 and first.SelectedFound)
	assert(first.Receivers[1].CatalogOriginals == 55 and first.Receivers[1].Sentinels == 21 and first.Receivers[1].NonCatalogOriginals == 60)
	for _, values in pairs(receiver._chunks) do
		for index, value in pairs(values) do if value == removable then values[index] = nil end end
	end
	s.Class.Update(receiver)
	local second = s.Knowledge:NativeEggRegistrationDiagnostics(selected)
	local updated = capturedRow(s, second, receiver)
	assert(updated.Values == 135 and updated.FullOriginalInterfaces == 135 and updated.CatalogOriginals == 54 and updated.Sentinels == 21 and updated.MissingCatalog == 60)
	assert(updated.AcceptedReceiver and updated.SelectedFound and updated.SelectedLoaded and updated.OtherOriginalsFound == 1)
	s:FinishObservation()
	local identity = s.Knowledge:ResolveEggInstance("Common Egg", true, selected)
	assert(identity and identity.Model == selected and identity.RegisteredReceivers == 1)
	assert(not s.Knowledge:ResolveEggInstance("Common Egg", true), "Two same-name originals still require an exact retained selection")
	local eligible, range = s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true)
	assert(eligible and range.InteractionMode == "OPENED_NEAREST" and range.Model == selected)
	for _, unknown in ipairs(unknowns) do assert(not s.Knowledge:ResolveEggInstance(unknown.Name, true, unknown)) end
	assert(#s.NativeUpdateCalls == 2 and s.Class.Update == s.OriginalUpdate)
	s:Close()
end)

test("Noncatalog queue originals require no name whitelist and an ordinary loaded catalog anchor need not be Common", function()
	for _, unknownName in ipairs({ "Egg", "Synthetic future original", "Uncatalogued native placeholder" }) do
		local s = fixture()
		local selected = s:Add("Spotted Egg", Vector3.new(5, 0, 0))
		local unknown = s:Add(unknownName, Vector3.new(1000, 0, 0)) unknown.Parent = nil
		s.Definitions[unknownName], s.VisualAssets[unknownName] = nil, nil
		local receiver = s:Receiver({ selected }) receiver._chunks.unloaded = { [8] = unknown }
		s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
		assert(s.Knowledge.NativeEggChunkers[receiver])
		assert(s.Knowledge:ResolveEggInstance("Spotted Egg", true, selected).Model == selected)
		assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		assert(not s.Knowledge:ResolveEggInstance(unknownName, true, unknown))
		s:Close()
	end
end)

test("Approved queue classification rejects wrong class folder schemas ancestry flags and bounds", function()
	for _, mutate in ipairs({
		function(s, receiver) setmetatable(receiver, nil) end,
		function(s, receiver) setmetatable(receiver, { __index = s.Class }) end,
		function(s) s.Folder.SyntheticEggInstance = nil end,
		function(s) s.Folder.IsA = function() return false end end,
		function(s) s.Folder.Parent = s.Generic end,
		function(s, receiver) receiver._loaded.current = false end,
		function(s, receiver) receiver._chunks.current = "unavailable" end,
		function(s, receiver, selected) receiver._chunks.current = { selected, unsupported = selected } end,
		function(s, receiver, selected) receiver._chunks.current = { [0] = selected } end,
		function(s, receiver, selected) receiver._chunks.current = { [1.5] = selected } end,
		function(s, receiver) table.insert(receiver._chunks.current, "not an Instance") end,
		function(s, receiver) table.insert(receiver._chunks.current, { Model = receiver._chunks.current[1] }) end,
		function(s, receiver) table.insert(receiver._chunks.current, s:Add("Common Egg", Vector3.new(0, 0, 0), true)) end,
		function(s, receiver, selected) selected.Children.Root.Position = Vector3.new(0/0, 0, 0) end,
		function(s, receiver, selected) selected.Parent = s.Generic end,
		function(s, receiver) receiver._loaded.current = nil end,
		function(s, receiver, selected) for index = 2, 1001 do receiver._chunks.current[index] = selected end end,
		function(s, receiver) for coordinate = 1, 1001 do receiver._chunks[coordinate] = {} end end,
		function(s, receiver) for coordinate = 1, 1001 do receiver._loaded[coordinate] = true end end,
	}) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		local receiver = s:Receiver({ selected })
		mutate(s, receiver, selected)
		s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
		assert(not s.Knowledge.NativeEggChunkers or not s.Knowledge.NativeEggChunkers[receiver])
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		assert(#s.NativeUpdateCalls == 1 and s.Class.Update == s.OriginalUpdate)
		s:Close()
	end
end)

test("A queue containing only noncatalog originals cannot establish its positive native catalog anchor", function()
	local s = fixture()
	local unknown = s:Add("Synthetic unknown original", Vector3.new(5, 0, 0))
	s.Definitions[unknown.Name] = nil
	local receiver = s:Receiver({ unknown })
	s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
	local diagnostic = s.Knowledge:NativeEggRegistrationDiagnostics(unknown)
	assert(not s.Knowledge.NativeEggChunkers and diagnostic.QualifyingReceivers == 0)
	assert(diagnostic.Reason:find("NO_LOADED_CATALOG_ORIGINAL_ANCHOR", 1, true))
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = unknown }, { Position = Vector3.new(0, 0, 0) }, true))
	s:Close()
end)

test("A later invalid native observation revokes a formerly qualifying queue", function()
	for _, mutate in ipairs({
		function(s, receiver) receiver._loaded.current = false end,
		function(s, receiver) receiver._chunks.current[0] = receiver._chunks.current[1] end,
		function(s, receiver) receiver._chunks.unloaded = { { Constructor = "not an original" } } end,
		function(s, receiver) local unknown = s:Add("Unknown", Vector3.new(1000, 0, 0)); s.Definitions.Unknown = nil; receiver._chunks.unloaded = { unknown } end,
	}) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		local receiver = s:Receiver({ selected })
		s:BeginObservation() s.Class.Update(receiver)
		assert(s.Knowledge.NativeEggChunkers[receiver])
		mutate(s, receiver) s.Class.Update(receiver)
		assert(not s.Knowledge.NativeEggChunkers[receiver])
		s:FinishObservation()
		assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true))
		assert(#s.NativeUpdateCalls == 2 and s.Class.Update == s.OriginalUpdate)
		s:Close()
	end
end)

test("Queue membership cannot bypass the selected native visual asset prerequisite", function()
	for _, wrongAsset in ipairs({ "missing", "not a Model" }) do
		local s = fixture()
		local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
		local receiver = s:Receiver({ selected })
		s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
		assert(s.Knowledge:ResolveEggInstance("Common Egg", true, selected).Model == selected)
		if wrongAsset == "missing" then s.VisualAssets["Common Egg"] = nil
		else s.VisualAssets["Common Egg"] = { IsA = function() return false end } end
		local eligible, _, reason = s.Knowledge:NativeEggRangeEligible({ Model = selected }, { Position = Vector3.new(0, 0, 0) }, true)
		assert(not eligible and reason:find("private interaction registration unverified", 1, true))
		assert(s.Knowledge.NativeEggChunkers[receiver], "Interaction failure must not fabricate loss of valid queue membership")
		s:Close()
	end
end)

test("Loaded unknown queued originals remain conservative competitors across native egg names", function()
	local s = fixture()
	local selected = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local unknown = s:Add("Uncatalogued native original", Vector3.new(100, 0, 0))
	s.Definitions[unknown.Name], s.VisualAssets[unknown.Name] = nil, nil
	local receiver = s:Receiver({ [2] = selected, [5] = unknown })
	s:BeginObservation() s.Class.Update(receiver) s:FinishObservation()
	assert(s.Knowledge.NativeEggChunkers[receiver] and s.Knowledge:ResolveEggInstance("Common Egg", true, selected).Model == selected)
	assert(not s.Knowledge:ResolveEggInstance(unknown.Name, true, unknown))
	local root = { Position = Vector3.new(0, 0, 0) }
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	unknown.Children.Root.Position = Vector3.new(1, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true), "Unverified private interaction cannot be silently excluded as a closer competitor")
	unknown.Children.Root.Position = Vector3.new(5, 0, 0)
	assert(not s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	unknown.Attributes.Unlocked = false
	assert(s.Knowledge:NativeEggRangeEligible({ Model = selected }, root, true))
	s:Close()
end)

typeof = nativeTypeof
print("[OC TEST] " .. tostring(tests-before) .. " native egg identity checks passed; synthetic observations only")
end

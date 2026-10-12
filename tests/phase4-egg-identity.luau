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
	s.Workspace = { Name = "Workspace" }
	s.Rendered = { Name = "Rendered", Parent = s.Workspace }
	s.Folder = { Name = "Chunker", Parent = s.Rendered, IsA = function(_, kind) return kind == "Folder" end }
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
	s.NativeUpdateCalls = {}
	s.Class = { Update = function(receiver, ...)
		table.insert(s.NativeUpdateCalls, { Receiver = receiver, Args = table.pack(...) })
		if s.OnNativeUpdate then s.OnNativeUpdate(receiver) end
		return "native-result", nil, 73, false
	end }
	s.OriginalUpdate = s.Class.Update
	s.Dependencies = { Eggs = s.Definitions, ProximityPrompt = s.Prompts, Chunker = s.Class }
	s.Reader = { Config = Resolver.Resolve(Defaults, { PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true } }),
		_dependency = function(_, name) return s.Dependencies[name] end,
		GetLiveProfile = function() return s.Profile end }
	s.Knowledge = Knowledge.new(s.Reader)
	s.Knowledge.EggObservationFinished = true
	function s:Add(name, position, visual)
		self.Definitions[name] = { World = "The Overworld", Cost = { Type = "Currency", Currency = "Coins", Amount = 10 } }
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
		return receiver
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

test("Two same-name same-parent same-path registered originals stay ambiguous regardless of distance or expected Instance", function()
	local s = fixture()
	local nearer = s:Add("Common Egg", Vector3.new(1, 0, 0))
	local farther = s:Add("Common Egg", Vector3.new(100, 0, 0))
	s:Register({ nearer, farther })
	assert(nearer:GetFullName() == farther:GetFullName() and nearer.Parent == farther.Parent)
	assert(s.Knowledge:InstanceId(nearer) ~= s.Knowledge:InstanceId(farther))
	for _, expected in ipairs({ nearer, farther }) do
		local record, reason, observed = s.Knowledge:ResolveEggInstance("Common Egg", true, expected)
		assert(not record and reason:find("AMBIGUOUS_NATIVE_EGG_MODEL", 1, true) and observed.VerifiedCount == 2)
	end
	s:Close()
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
	assert(not record and reason:find("exact egg Instance changed", 1, true))
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
	s.Definitions["Coming Soon"] = nil
	local receiver = s:Receiver({ original, sentinel })
	s:BeginObservation()
	s.Class.Update(receiver)
	s:FinishObservation()
	assert(s.Knowledge.NativeEggChunkers[receiver])
	assert(s.Knowledge:ResolveEggInstance("Common Egg", true).Model == original)
	assert(not s.Knowledge:ResolveEggInstance("Coming Soon", true))
	s:Close()
end)

test("Multiple observed egg receivers preserve ambiguity instead of preferring folder or call order", function()
	local s = fixture()
	local original = s:Add("Common Egg", Vector3.new(5, 0, 0))
	local receiver = s:Receiver({ original })
	local second = s:Receiver({ original })
	s:BeginObservation()
	s.Class.Update(receiver) s.Class.Update(second)
	s:FinishObservation()
	local record, reason = s.Knowledge:ResolveEggInstance("Common Egg", true)
	assert(not record and reason:find("IDENTITY_UNVERIFIED", 1, true))
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

typeof = nativeTypeof
print("[OC TEST] " .. tostring(tests-before) .. " native egg identity checks passed; synthetic observations only")
end

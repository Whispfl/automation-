--!nonstrict
-- ReplicatedStorage knowledge facade. Reuses the approved reader's dependency cache;
-- it neither loads future systems nor executes actions or substitutes account/world facts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameKnowledge = {}
GameKnowledge.__index = GameKnowledge

local pickupContract = table.freeze({
	DefinitionSource = "ReplicatedStorage.Shared.Data.Worlds",
	ZoneInterface = "ReplicatedStorage.Shared.Utils.GetPickupZones",
	AssetSource = "ReplicatedStorage.Assets.Pickups",
	SpawnSource = "ReplicatedStorage.Remotes.Pickups.SpawnPickups",
	ClientEvidence = "StarterPlayer.StarterPlayerScripts.ClientScript:1134-1344",
	InitialRenderPath = "Workspace.Rendered.Pickups",
	RenderedPath = "Workspace.Rendered.Chunker (all native folders with this name)",
	ActiveRegistry = "ReplicatedStorage.Client.Tutorial._activePickups",
	RegistryEvidence = "ClientScript:1137-1140,1255-1279; Client.Tutorial:44,522",
	ParentEvidence = "ReplicatedStorage.Shared.Utils.Chunker:33-55,118-167",
	PositionSource = "Actual Model:GetPivot().Position; spawn payload contains Root/Visual/Id, not an exact position",
	IdOrigin = "Received SpawnPickups payload Id; generation is server-side/unavailable",
	ExistingPickupSync = "Read current native registry; past spawn events are not replayed",
	RenderedClass = "Model",
	RangeMethod = "StatsUtil:GetPickupRange(profile)",
	CollectionOwner = "Native radius collector plus scheduler-owned stationary ID batches; per-ID server acceptance unknown",
	OwnerEvidence = "Owner reports continuous stationary batches earning actual Coins/Gems; cleanup and automatic travel await live results; individual request acceptance is not established",
	CleanupEvidence = "ClientScript:1243-1279 destroys Models and calls native Chunker.Remove; OC removes the native chunk and matching registry entry only after dispatch",
	IslandWideBatchFound = false,
	Evidence = "CLIENT_SOURCE_INSPECTED; execution requires owner verification",
	ServerValidation = "UNAVAILABLE",
})

function GameKnowledge.new(reader) return setmetatable({ Reader = reader }, GameKnowledge) end

function GameKnowledge:Get(name)
	-- Returning the same native dependency avoids competing discovery/require loops.
	return self.Reader:_dependency(name)
end

function GameKnowledge:Assets(name)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	return assets and assets:FindFirstChild(name)
end

function GameKnowledge:PickupContract() return pickupContract end

function GameKnowledge:ActivePickups()
	local tutorial = self:Get("Tutorial")
	if type(tutorial) ~= "table" then
		local dependency = (self.Reader.Dependencies or {}).Tutorial
		return nil, "Client.Tutorial " .. tostring(dependency and dependency.Status or "not loaded") .. (dependency and dependency.Error and ": " .. dependency.Error or "")
	end
	if type(tutorial._activePickups) ~= "table" then return nil, "Client.Tutorial loaded but _activePickups is absent or not a table" end
	return tutorial._activePickups, "Client.Tutorial._activePickups available"
end

function GameKnowledge:GetStatus()
	local dependencies = {}
	for name, entry in pairs(self.Reader.Dependencies or {}) do
		dependencies[name] = { Status = entry.Status, Source = "ReplicatedStorage." .. entry.Path, Error = entry.Error }
	end
	return { Dependencies = dependencies, PickupAssetsAvailable = self:Assets("Pickups") ~= nil,
		Pickup = table.clone(pickupContract), ServerOnlyRules = "UNAVAILABLE" }
end

function GameKnowledge:ReleaseChunkerObserver()
	if self.ChunkerClass and self.ChunkerClass.Update == self.ChunkerObserver then self.ChunkerClass.Update = self.OriginalChunkerUpdate end
	self.ChunkerClass, self.ChunkerObserver, self.OriginalChunkerUpdate, self.CleanupRegistry = nil, nil, nil, nil
end

function GameKnowledge:PickupChunker()
	if self.NativePickupChunker then return self.NativePickupChunker end
	if self.ChunkerObserver and os.clock() - self.ChunkerObserverAt >= 5 then
		self:ReleaseChunkerObserver() self.ChunkerRetryAt = os.clock() + 5
	end
	if os.clock() < (self.ChunkerRetryAt or 0) then return nil, "Native pickup Chunker observation is in backoff" end
	if not self.ChunkerObserver then
		local class, registry = self:Get("Chunker"), self:ActivePickups()
		if not class or type(class.Update) ~= "function" or not registry then return nil, "Native Chunker/registry dependency unavailable" end
		self.ChunkerClass, self.OriginalChunkerUpdate, self.CleanupRegistry = class, class.Update, registry
		local original = class.Update
		self.ChunkerObserver = function(chunker, ...)
			-- Observe the real receiver; preserve native Update arguments/results and never choose an action here.
			local result = table.pack(original(chunker, ...))
			pcall(function() -- Observation failures must never interrupt the game's Update.
				if type(chunker) == "table" and type(chunker.Remove) == "function" and type(chunker.IsValueLoaded) == "function" then
					for _, pickup in pairs(self.CleanupRegistry or {}) do
						if pickup.Parent and pickup.Parent == chunker._folder and chunker:IsValueLoaded(pickup) then
							self.NativePickupChunker = chunker self:ReleaseChunkerObserver() break
						end
					end
				end
			end)
			return table.unpack(result, 1, result.n)
		end
		local ok = pcall(function() class.Update = self.ChunkerObserver end)
		if not ok then self:ReleaseChunkerObserver() return nil, "Native Chunker receiver observation unavailable" end
		self.ChunkerObserverAt = os.clock()
	end
	return nil, "Waiting for native pickup Chunker receiver; no request or visual mutation yet"
end

function GameKnowledge:Destroy()
	self:ReleaseChunkerObserver() self.NativePickupChunker = nil
end

return GameKnowledge

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
	CollectionOwner = "Native radius collector plus bounded scheduler-owned stationary ID experiment; server credit unverified",
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
	return tutorial._activePickups, "Client.Tutorial._activePickups available (read-only)"
end

function GameKnowledge:GetStatus()
	local dependencies = {}
	for name, entry in pairs(self.Reader.Dependencies or {}) do
		dependencies[name] = { Status = entry.Status, Source = "ReplicatedStorage." .. entry.Path, Error = entry.Error }
	end
	return { Dependencies = dependencies, PickupAssetsAvailable = self:Assets("Pickups") ~= nil,
		Pickup = table.clone(pickupContract), ServerOnlyRules = "UNAVAILABLE" }
end

return GameKnowledge

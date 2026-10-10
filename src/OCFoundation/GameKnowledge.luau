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
	RenderedPath = "Workspace.Rendered.Pickups",
	RenderedClass = "Model",
	RangeMethod = "StatsUtil:GetPickupRange(profile)",
	CollectionOwner = "Native client collector; per ID within actual radius",
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

function GameKnowledge:GetStatus()
	local dependencies = {}
	for name, entry in pairs(self.Reader.Dependencies or {}) do
		dependencies[name] = { Status = entry.Status, Source = "ReplicatedStorage." .. entry.Path, Error = entry.Error }
	end
	return { Dependencies = dependencies, PickupAssetsAvailable = self:Assets("Pickups") ~= nil,
		Pickup = table.clone(pickupContract), ServerOnlyRules = "UNAVAILABLE" }
end

return GameKnowledge

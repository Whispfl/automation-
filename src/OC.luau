--!nonstrict
-- The compiled bundle returns this initializer. It creates no Script or ModuleScript instances.
local Defaults = require(script.Parent.OCFoundation.OCConfig)
local ConfigResolver = require(script.Parent.OCFoundation.ConfigResolver)
local OCController = require(script.Parent.OCFoundation.OCController)
local OCInterface = require(script.Parent.OCFoundation.OCInterface)

return function(customConfig)
	local config = ConfigResolver.Resolve(Defaults, customConfig)
	assert(config.GENERAL_SETTINGS.OC_ENABLED, "[OC] OC_ENABLED=false; initialization is disabled")
	assert(game:GetService("RunService"):IsClient(), "[OC] OC requires a client runtime; server loadstring cannot read client LocalData")
	local players = game:GetService("Players")
	local player = players.LocalPlayer
	assert(player, "[OC] Players.LocalPlayer is unavailable; run after joining your authorized client test environment")
	local playerGui
	if config.STATUS_UI_SETTINGS.ENABLE_STATUS_UI then
		playerGui = player:WaitForChild("PlayerGui", config.ACCOUNT_SETTINGS.MODULE_LOAD_TIMEOUT_SECONDS)
		assert(playerGui, "[OC] PlayerGui did not load before the configured timeout")
	end
	local controller = OCController.new(config, player)
	local ok, result = xpcall(function()
		controller.Interface = OCInterface.new(controller, playerGui)
		controller:Log("INIT", "Phase " .. tostring(controller:GetStatus().Phase) .. " initialized | PlaceId=" .. tostring(game.PlaceId) .. " | build=__OC_BUILD_ID__ | Overworld discovery owner-confirmed in session; rejoin persistence and world purchases pending")
		controller:Log("SCOPE", "One Brain/scheduler: configured progression and actual-shortage stationary Coins/Gems farming on The Void/Zen; bubbles require a real bubble objective.")
		controller:Log("FARM][BULK", "Paced genuine loaded registry IDs, up to " .. tostring(config.PICKUP_SETTINGS.STATIONARY_MAXIMUM_BATCH_SIZE) .. " per stationary batch; distances observed, server validation unchanged; only LocalData balances verify credit.")
		if config.GENERAL_SETTINGS.AUTO_START then
			local started, reason = controller:Start()
			if not started then controller.Error = reason controller:Log("CONTROL", reason) controller:_notify() end
		end
		return controller
	end, debug.traceback)
	if not ok then controller:Destroy() error("[OC] Initialization failed: " .. tostring(result), 0) end
	-- A repeated user-run loader cleans up only a previous OC instance from this registry.
	if type(shared) == "table" then
		local previous = shared.__OC_PHASE1_INSTANCE
		if previous and previous ~= controller and type(previous.Destroy) == "function" then previous:Destroy() end
		shared.__OC_PHASE1_INSTANCE = controller
	end
	return result
end

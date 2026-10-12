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
		if config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE then controller:Log("SCOPE", "Phase 4: actual owned-team/native egg estimates; hatch and equipment require separate Config authorization; destructive actions OFF; final odds/total time may remain UNKNOWN.") end
		if config.PET_SETTINGS.ENABLE_PET_INTELLIGENCE then
			controller:Log("SCOPE", "Egg mode=" .. config.EGG_TRAVEL_SETTINGS.MODE .. " | OWNER_ONE_HATCH_TEST_ALLOWANCE="
				.. tostring(config.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_HATCH_TEST_ALLOWANCE)
				.. " | normal world goal unchanged; exceptional one-request consumption persists only in this client VM")
		end
		if config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL or config.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME
			or config.MYSTERY_BOX_SETTINGS.AUTO_OPEN_MYSTERY_BOXES or config.ANTIAFK_SETTINGS.ENABLE_ANTI_AFK then
			controller:Log("SCOPE", string.format("Local scoped features | selected-egg travel=%s; playtime=%s; owned ordinary box=%s; guarded ScrollLock anti-AFK=%s | no additional hatch/spend permission; owner live verification pending",
				tostring(config.EGG_TRAVEL_SETTINGS.ENABLE_SELECTED_EGG_TRAVEL), tostring(config.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME),
				tostring(config.MYSTERY_BOX_SETTINGS.AUTO_OPEN_MYSTERY_BOXES), tostring(config.ANTIAFK_SETTINGS.ENABLE_ANTI_AFK)))
		end
		controller:Log("FARM][BULK", "Paced genuine loaded registry IDs, up to " .. tostring(config.PICKUP_SETTINGS.STATIONARY_MAXIMUM_BATCH_SIZE) .. " per stationary batch; distances observed, server validation unchanged; only LocalData balances verify credit.")
		-- Release the previous action authority before starting this instance.
		if type(shared) == "table" then
			local previous = shared.__OC_PHASE1_INSTANCE
			if previous and previous ~= controller and type(previous.Destroy) == "function" then previous:Destroy() end
			local oldMechanics = previous and previous.Farming and previous.Farming.Mechanics
			if oldMechanics and oldMechanics.AntiAFKHeldInput then
				local releasedOK, released, reason = pcall(oldMechanics.ReleaseAntiAFKInput, oldMechanics)
				assert(releasedOK and released == true and oldMechanics.AntiAFKHeldInput == nil,
					"Prior tracked ScrollLock release remains uncertain; replacement/start blocked: " .. tostring(releasedOK and reason or released))
			end
			shared.__OC_PHASE1_INSTANCE = controller
		end
		if config.GENERAL_SETTINGS.AUTO_START then
			local started, reason = controller:Start()
			if not started then controller.Error = reason controller:Log("CONTROL", reason) controller:_notify() end
		end
		return controller
	end, debug.traceback)
	if not ok then controller:Destroy() error("[OC] Initialization failed: " .. tostring(result), 0) end
	return result
end

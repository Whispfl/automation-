-- Owner-operated READ-ONLY preflight for the existing immutable wheel candidate.
-- This loader cannot claim. Separate explicit one-claim authorization is required.
local Config = {
	FREE_WHEEL_TICKET_SETTINGS = { ENABLE_FREE_WHEEL_TICKET_CLAIM = false, AUTHORIZED_ACCOUNT_ID = 0,
		AUTHORIZED_TEST_ID = "", OWNER_CONFIRMED_WHEEL_IDLE = false },
	GENERAL_SETTINGS = { OC_ENABLED = true, AUTO_START = false, ENABLE_RECOMMENDATIONS = false },
	STATUS_UI_SETTINGS = { ENABLE_STATUS_UI = false },
	ACCOUNT_SETTINGS = { ENABLE_ACCOUNT_READER = true, SNAPSHOT_REFRESH_SECONDS = 2 },
	REWARD_INTELLIGENCE_SETTINGS = { ENABLE_REWARD_INTELLIGENCE = true },
	MASTERY_SETTINGS = { ENABLE_MASTERY_INTELLIGENCE = true },
	BRAIN_SETTINGS = { ENABLE_EARNING_RECOMMENDATIONS = false, ENABLE_WORLD_RECOMMENDATIONS = false,
		ENABLE_MASTERY_RECOMMENDATIONS = false, ENABLE_INVENTORY_RECOMMENDATIONS = false },
	PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = false, AUTO_HATCH = false, AUTO_EQUIP = false,
		EQUIP_OWNED_TEAM_ONCE = false, AUTO_DELETE_PETS = false, AUTO_CRAFT_SHINY = false, AUTO_FUSE_PETS = false },
	HATCH_SETTINGS = { EGG_SELECTION_MODE = "MANUAL", SELECTED_EGGS = { "Common Egg" }, HATCH_ONE_EGG_ONCE = false,
		MAXIMUM_EGG_COST = 0, MAXIMUM_SESSION_COST = 0, MAXIMUM_SESSION_HATCHES = 1,
		MAXIMUM_BATCH_HATCHES = 1, PRESERVE_PROGRESSION_RESERVE = true, ENABLE_BACKGROUND_PICKUPS = false },
	OWNER_ONE_HATCH_TEST_SETTINGS = { OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST = false,
		OWNER_ONE_HATCH_TEST_ALLOWANCE = false, AUTHORIZED_ACCOUNT_ID = 0,
		MAXIMUM_COIN_ALLOWANCE = 0, MAXIMUM_EGG_COST = 0 },
	EGG_TRAVEL_SETTINGS = { MODE = "NORMAL", OWNER_DIRECT_EGG_TELEPORT_TEST = false,
		ENABLE_SELECTED_EGG_TRAVEL = false, ENABLE_NATIVE_ISLAND_TRAVEL = false, ENABLE_DIRECT_POSITIONING = false },
	WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false,
		AUTO_UNLOCK_WORLDS = false, AUTO_TRAVEL_FOR_PROGRESSION = false,
		AUTO_FARM_UNLOCK_REQUIREMENTS = false, MAXIMUM_WORLD_UNLOCK_COST = 0 },
	FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false },
	ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
	PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false, STATIONARY_ISOLATED_TEST = false, ENABLE_CONTINUOUS_SCANNING = false },
	BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false,
		AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
	UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false,
		ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false, MAXIMUM_PURCHASE_COST = 0 },
	PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = false },
	MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = false, ENABLE_AUTOMATIC_CONTINUATION = false },
	ANTIAFK_SETTINGS = { ENABLE_ANTI_AFK = false },
	FALL_EVENT_SETTINGS = { ENABLE_FALL_EVENT = false, AUTO_REBIRTH = false,
		AUTO_BUY_REBIRTH_UPGRADES = false, AUTO_USE_FALL_ELIXIRS = false, AUTO_BUY_AUTUMN_SHOP_ITEMS = false },
	DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false, ENABLE_DEBUG_LOGGING = false },
}

-- Do not replace an active OC or interrupt retained receipt reconciliation.
-- This is a read of the existing shared ledger, never a reset or rearm.
local function priorBarrier()
	if type(shared) ~= "table" then return "Shared runtime ledger unavailable" end
	local previous = shared.__OC_PHASE1_INSTANCE
	if previous and (previous.State ~= "STOPPED" or previous.Rewards and previous.Rewards:AttributionBlocked()) then
		return "An existing OC or reward operation is active; stop unrelated OC and reconcile any uncertain claim"
	end
	local root = shared.__OC_LOCAL_REWARD_LEDGER
	if root == nil then return nil end
	if type(root) ~= "table" or root.Version ~= 1 or type(root.Accounts) ~= "table" then return "Unknown retained reward ledger; no reset or retry" end
	local player = game:GetService("Players").LocalPlayer
	if not player then return "Local account unavailable" end
	local ledger = root.Accounts[tostring(player.UserId)]
	if ledger == nil then return nil end
	if type(ledger) ~= "table" or ledger.UserId ~= player.UserId then return "Retained account ledger mismatch" end
	if ledger.Pending ~= nil or ledger.UnresolvedAttribution == true then return "Retained reward receipt unresolved; no retry" end
	local extension = ledger.FreeWheelTicket
	if extension == nil then return nil end
	if type(extension) ~= "table" or extension.Version ~= 1 or type(extension.Tests) ~= "table" then return "Unknown retained wheel ledger; no reset or retry" end
	for _, record in pairs(extension.Tests) do
		if type(record) ~= "table" or record.Attempts ~= 0 then return "Free-wheel attempt consumed or uncertain; no new test ID or retry" end
	end
	return nil
end
local priorOK, priorReason = pcall(priorBarrier)
if not priorOK or priorReason then
	print("[OC][WHEEL_PREFLIGHT] BLOCKED | " .. (priorOK and priorReason or "Prior runtime observation unavailable"))
	print("[OC][WHEEL_PREFLIGHT] claim permission=OFF | requests issued by this loader=0 | existing runtime preserved")
	return nil
end

local OC = loadstring(game:HttpGet("https://raw.githubusercontent.com/Whispfl/automation-/phase5-free-wheel-ticket-668d0af6f157/dist/OC.lua"))()(Config)

-- Only the existing knowledge reader receives this detached observation argument.
-- Its gate enables reviewed dependency reads, NOT controller/manager authorization.
-- Actual OC.Config remains false/account0/test-empty/idle-false throughout.
local ObservationSettings = { ENABLE_FREE_WHEEL_TICKET_CLAIM = true, MAXIMUM_ACCOUNT_AGE_SECONDS = 10 }

local function readPreflight()
	local s, manager, reader = OC.Config.FREE_WHEEL_TICKET_SETTINGS, OC.Rewards, OC.Reader
	local report = { Status = "BLOCKED", Permission = "OFF", QueueState = "UNKNOWN",
		OwnerIdleConfirmation = "REQUIRED_BEFORE_AUTHORIZED_CLAIM", SnapshotOnly = true }
	local function block(reason) report.Blocker = reason return report end
	local function ownsLedger(identity)
		local root = type(shared) == "table" and shared.__OC_LOCAL_REWARD_LEDGER
		return type(root) == "table" and root.Version == 1 and type(root.Accounts) == "table"
			and root.Accounts[tostring(identity)] == manager.Ledger
	end
	if OC.Destroyed or OC.State ~= "STOPPED" or OC.Scheduler.Active ~= nil then
		return block("Preflight requires a stopped controller with no active scheduler task")
	end
	if s.ENABLE_FREE_WHEEL_TICKET_CLAIM ~= false or s.AUTHORIZED_ACCOUNT_ID ~= 0
		or s.AUTHORIZED_TEST_ID ~= "" or s.OWNER_CONFIRMED_WHEEL_IDLE ~= false then
		return block("Claim authorization must remain fully OFF")
	end
	if not manager or manager.Destroyed or manager.UnknownBarrier or not manager.Ledger then
		return block(manager and manager.Blocker or "Exact-account reward ledger unavailable")
	end
	local snapshot = reader:GetSnapshot()
	local identity = snapshot.Identity and snapshot.Identity.UserId
	if identity == nil or not reader.Player or identity ~= reader.Player.UserId or identity ~= manager.UserId
		or manager.Ledger.UserId ~= identity or not ownsLedger(identity) then return block("Exact-account observations disagree or are unavailable") end
	if manager:AttributionBlocked() or OC:RewardAttributionBlocked() then
		return block("An existing reward operation or unresolved attribution must be reconciled; no retry")
	end
	local extension = manager.Ledger.FreeWheelTicket
	-- Missing extension means no wheel history, not a fabricated inventory/claim fact.
	-- Existing malformed history was rejected by the original manager constructor.
	if extension ~= nil and manager:_freeWheelCharged() then
		return block("Free-wheel attempt already consumed or uncertain; no new test ID or retry")
	end
	local context = OC.Knowledge:FreeWheelTicketContext(snapshot, os.clock(), ObservationSettings)
	if type(context) ~= "table" or context.Fresh ~= true then
		return block(type(context) == "table" and context.Blocker or "Fresh native wheel observations unavailable")
	end
	-- Read the existing base guard. LocalFeatureGuard additionally requires RUNNING;
	-- this preflight never fakes that state or obtains an execution lease.
	local allowed, reason = OC.Farming.Mechanics:Guard()
	if not allowed then return block(reason or "Native interaction guard unavailable") end
	if game:GetService("UserInputService"):GetFocusedTextBox() ~= nil then return block("Typing owns input") end
	local hatch = reader:_dependency("HatchPresentation")
	if not hatch or type(hatch.IsHatching) ~= "function" or hatch:IsHatching() ~= false then
		return block("Native hatch presentation active or unavailable")
	end
	local scripts = reader.Player:FindFirstChild("PlayerScripts")
	local client = scripts and scripts:FindFirstChild("ClientScript")
	local auto = client and client:FindFirstChild("GetAutoHatchStatus")
	-- Native BindableFunction getter, not a remote command or hatch invocation.
	if not auto or not auto:IsA("BindableFunction") or auto:Invoke() ~= nil then
		return block("Native auto-hatch active or unavailable")
	end
	if OC.Pets and (OC.Pets.PendingEquip or OC.Pets.Hatch.Pending) then return block("Pending pet operation owns presentation") end
	-- Getters may yield; reread using the preserved coherent native observer.
	context = OC.Knowledge:FreeWheelTicketContext(reader:GetSnapshot(), os.clock(), ObservationSettings)
	if type(context) ~= "table" or context.Fresh ~= true or context.AccountId ~= identity then
		return block(type(context) == "table" and context.Blocker or "Wheel facts changed during preflight")
	end
	if OC.Destroyed or OC.State ~= "STOPPED" or OC.Scheduler.Active ~= nil
		or s ~= OC.Config.FREE_WHEEL_TICKET_SETTINGS or s.ENABLE_FREE_WHEEL_TICKET_CLAIM ~= false
		or s.AUTHORIZED_ACCOUNT_ID ~= 0 or s.AUTHORIZED_TEST_ID ~= "" or s.OWNER_CONFIRMED_WHEEL_IDLE ~= false then
		return block("Stopped preflight or disabled authorization changed during observation")
	end
	if reader.Player.UserId ~= identity or manager ~= OC.Rewards or manager.UserId ~= identity
		or manager.Ledger.UserId ~= identity or not ownsLedger(identity) or manager:AttributionBlocked() or OC:RewardAttributionBlocked()
		or manager.Ledger.FreeWheelTicket ~= nil and manager:_freeWheelCharged() then
		return block("Account or retained reward barrier changed during observation; no retry")
	end
	if context.Due ~= true then return block("Free ticket timer is not due; wait for normal eligibility") end
	report.Status, report.Due, report.AutoClaimSpin, report.ActiveGifts = "READY_FOR_SEPARATE_AUTHORIZATION", true, false, 0
	report.ClaimRequestsThisLoader = 0
	return report
end

-- Bounded dependency-read window only; never Start/Select/Prepare/dispatch/rearm.
-- Unknown data stays blocked. No baseline account, balance or inventory is printed.
print("[OC][WHEEL_PREFLIGHT] build=668d0af6f157 | READ_ONLY | controller=STOPPED | claim authorization=OFF")
local report
for observation = 1, 15 do
	local ok, value = pcall(readPreflight)
	report = ok and value or { Status = "BLOCKED", Blocker = "Native read-only preflight failed; observation unavailable" }
	if report.Status == "READY_FOR_SEPARATE_AUTHORIZATION" or OC.Destroyed or OC.State ~= "STOPPED" then break end
	if observation < 15 then task.wait(1) end
end
print("[OC][WHEEL_PREFLIGHT] " .. report.Status .. " | " .. (report.Blocker or "due=true; canonical ticket data=verified; AutoClaimSpin=false; active gifts=0; interaction observations=idle"))
print("[OC][WHEEL_PREFLIGHT] claim permission=OFF | requests issued by this loader=0 | wheel queue=UNKNOWN | owner idle confirmation + separate ONE-claim approval required")
print("[OC][WHEEL_PREFLIGHT] Snapshot only; execution rechecks all guards after approval. No spin, consumption, movement or spending.")
OC.WheelPreflightReport = report
return OC

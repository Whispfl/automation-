-- Synthetic read-only reward fixtures. Every account, timestamp, price and
-- inventory quantity here is invented; no owner data or gameplay action is used.
local Defaults, Resolver = requireOC("OCConfig"), requireOC("ConfigResolver")
local Reader, Knowledge = requireOC("AccountStateReader"), requireOC("GameKnowledge")
local Brain, Policy, Controller = requireOC("OCBrain"), requireOC("RewardPolicy"), requireOC("OCController")
local audits, clock = 0, 100
os.clock = function() return clock end
local function audit(name, callback)
	callback()
	audits += 1
	print("[OC PHASE5 REWARDS SYNTHETIC] " .. name .. " passed")
end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copy(entry) end
	return result
end
local function equal(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for key, value in pairs(a) do if not equal(value, b[key]) then return false end end
	for key in pairs(b) do if a[key] == nil then return false end end
	return true
end
local function item(currency, amount) return { Type = "Currency", Currency = currency, Amount = amount } end
local function fixture()
	local config = Resolver.Resolve(Defaults, {
		GENERAL_SETTINGS = { AUTO_START = false, ENABLE_RECOMMENDATIONS = false },
		DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false },
		REWARD_INTELLIGENCE_SETTINGS = { ENABLE_REWARD_INTELLIGENCE = true, MAXIMUM_ACCOUNT_AGE_SECONDS = 10 },
		MASTERY_SETTINGS = { ENABLE_MASTERY_INTELLIGENCE = false },
		RESOURCE_SETTINGS = { COIN_RESERVE = 50, GEM_RESERVE = 20 },
	})
	local raw = { Coins = 1000, Gems = 100, Bubbles = 20,
		WorldsUnlocked = { ["The Overworld"] = true }, AreasUnlocked = { ["The Void"] = true },
		MasteryLevels = {}, MasteryUpgrades = { { Type = "Playtime" } },
		PlaytimeRewards = { Start = 1800000000, Claimed = {} },
		DailyRewards = { LastDay = 20833, LastStreak = 1, Claimed = false, Stars = 0 },
		WorldRewards = { ["The Overworld"] = { Progress = 0 } },
		Cooldowns = { ["Synthetic Chest"] = 1800000900 }, ClaimedPrizes = {},
		Quests = { { Id = "synthetic-quest", Tasks = { { Type = "Bubbles", Amount = 20 } }, Progress = { 20 }, Rewards = { item("Coins", 5) } } },
		QuestsCompleted = {},
		ChallengePass = { Points = 20, Rewards = { item("Gems", 5), item("Gems", 10) }, Claimed = {} },
		Powerups = { ["Mystery Box"] = 2, ["Golden Key"] = 1 }, Potions = { { Name = "Coins", Level = 1, Amount = 3 } },
		Pets = {}, Teams = { { Pets = {} } }, TeamEquipped = 1,
	}
	local catalogs = {
		Worlds = { ["The Overworld"] = {} },
		Playtime = { Gifts = { { Time = 120, Luck = 1 }, { Time = 1800, Luck = 5 } }, Prizes = { { Item = item("Coins", 100), Chance = 100 } } },
		DailyRewards = { { item("Coins", 5) }, { item("Gems", 6) } },
		WorldRewards = { ["The Overworld"] = { Currency = "Coins", Levels = {
			{ Cost = item("Coins", 100), Reward = item("Coins", 1) },
			{ Cost = item("Coins", 200), Reward = { Type = "Pet", Name = "Synthetic Pet" } },
		} } },
		Chests = { ["Synthetic Chest"] = { Cooldown = 900, Rolls = 1, Reward = { item("Coins", 5) }, Pool = {} } },
		Prizes = { meta = {}, data = { BubblePrize = { Key = "synthetic-prize", Type = "Bubbles", Requirement = 20, Reward = item("Coins", 5) } } },
		Powerups = { ["Mystery Box"] = {}, ["Golden Key"] = {} }, Potions = { Coins = {} }, WheelSpin = {}, Seasons = {},
		ChallengePass = { Id = "synthetic-pass", FinalTier = 2, FinishTime = { UnixTimestamp = 1800002000 },
			GetTier = function(_, points) return points >= 20 and 2 or 1 end },
	}
	local scene = { Config = config, Raw = raw, Catalogs = catalogs, Now = 100, NativeNow = 1800001000 }
	local reader = Reader.new(config, { UserId = 101 })
	scene.Reader = reader
	reader.Dependencies.LocalData = { Status = "READY", Value = {
		IsReady = function() return scene.Ready ~= false end, Get = function() return scene.Raw end,
	} }
	for name, value in pairs(catalogs) do reader.Dependencies[name] = { Status = "READY", Value = value } end
	reader.Dependencies.Time = { Status = "READY", Value = {
		now = function() if scene.OnTime then scene.OnTime() end return scene.NativeNow end,
		getAbsoluteDay = function() return math.floor(scene.NativeNow / 86400) end,
	} }
	reader.Dependencies.Constants = { Status = "READY", Value = { DailyRewardsStarsPerDay = 10, DailyRewardsStarCap = 200 } }
	reader.Dependencies.StatsUtil = { Status = "LOADING" }
	reader.Dependencies.IsTradingPlaza = { Status = "READY", Value = function() return false end }
	reader.Dependencies.QuestUtil = { Status = "READY", Value = {
		GetRequirement = function(_, task) if scene.OnQuest then scene.OnQuest() end return task.Amount end,
	} }
	reader.Dependencies.PrizesUtil = { Status = "READY", Value = {
		GetProgress = function(_, facts) return facts.Bubbles end,
	} }
	reader.Dependencies.ItemUtil = { Status = "READY", Value = {
		GetOwnedAmount = function(_, facts, descriptor)
			if descriptor.Type == "Powerup" then return facts.Powerups and facts.Powerups[descriptor.Name] or 0 end
			if descriptor.Type == "Potion" then
				for _, potion in pairs(facts.Potions or {}) do if potion.Name == descriptor.Name and potion.Level == descriptor.Level then return potion.Amount end end
				return 0
			end
			return nil
		end,
	} }
	reader.Dependencies.Remote = { Status = "READY", Value = {
		FireServer = function() error("Read-only reward intelligence attempted transport") end,
		InvokeServer = function() error("Read-only reward intelligence attempted transport") end,
	} }
	scene.Knowledge, scene.Brain = Knowledge.new(reader), Brain.new(config)
	function scene:Sync()
		self.Reader.Revision = 1
		self.Snapshot = { Ready = true, Revision = 1, ReadAt = self.Now, Identity = { UserId = 101 },
			Balances = { Coins = self.Raw.Coins, Gems = self.Raw.Gems },
			Upgrades = { MasteryLevels = copy(self.Raw.MasteryLevels), MasteryUpgrades = copy(self.Raw.MasteryUpgrades) },
			UnlockedWorlds = copy(self.Raw.WorldsUnlocked), UnlockedIslands = copy(self.Raw.AreasUnlocked),
			ProgressionGraph = { Next = { Kind = "WORLD", Name = "Synthetic next", Cost = item("Coins", 500), State = "READY" } },
		}
		self.Reader.Snapshot = self.Snapshot
		return self
	end
	function scene:Context() return self.Knowledge:RewardContext(self.Snapshot, self.Now, self.Config.REWARD_INTELLIGENCE_SETTINGS) end
	function scene:Report(context) return Policy.Analyze(self.Config, self.Snapshot, context or self:Context()) end
	function scene:BrainReport(extra)
		extra = extra or {} extra.Now = self.Now
		return self.Brain:AnalyzeRewards(self.Snapshot, self.Knowledge, extra)
	end
	function scene:Close() self.Reader:Destroy() end
	return scene:Sync()
end

local function row(report, family, key)
	for _, entry in ipairs(report.Rows or {}) do
		if entry.Family == family and (key == nil or entry.Key == family .. ":" .. tostring(key)) then return entry end
	end
	error("Missing synthetic reward row " .. family .. ":" .. tostring(key))
end
local function assertReadonly(report)
	assert(report.ReadOnly == true and report.ActionsEnabled == false and report.ActionAuthorization == "NONE")
	assert(report.Recommendation.ExecutionAuthorized == false and report.Recommendation.ActionAuthorization == "NONE")
	for _, entry in ipairs(report.Rows or {}) do
		assert(entry.ExecutionAuthorized == false and entry.ActionAuthorization == "NONE")
		assert(entry.PossibleBenefit.ActualGrant == "UNKNOWN" and entry.PossibleBenefit.EarningGain == "UNKNOWN")
	end
end
local function masteryIncomplete()
	return { ReadOnly = true, ActionAuthorization = "NONE", Status = "READ_ONLY_REPORT",
		ObtainableRemainingCategories = 1, UnresolvedCategories = 0 }
end

audit("native context and policy detach accounts/catalogs without actions or mutation", function()
	local s = fixture() local beforeRaw, beforeCatalog = copy(s.Raw), copy(s.Catalogs)
	local pending = #queue local context = s:Context() local report = s:Report(context)
	assert(context.Fresh == true and context.NativeNow == 1800001000 and context.AccountId == 101)
	assert(report.Status == "READ_ONLY_REPORT" and #queue == pending)
	assertReadonly(report)
	assert(equal(s.Raw, beforeRaw) and equal(s.Catalogs, beforeCatalog))
	context.Raw.PlaytimeRewards.Claimed["1"] = true context.Catalogs.Playtime.Gifts[1].Time = 99999
	assert(s.Raw.PlaytimeRewards.Claimed["1"] == nil and s.Catalogs.Playtime.Gifts[1].Time == 120)
	s:Close()
end)

audit("native Unix time makes a due gift while os.clock remains unrelated", function()
	local s = fixture() local first, second = row(s:Report(), "FREE_PLAYTIME", 1), row(s:Report(), "FREE_PLAYTIME", 2)
	assert(first.Status == "DUE" and first.DueAt == 1800000120 and first.SecondsUntilDue == 0)
	assert(second.Status == "AVAILABLE" and second.SecondsUntilDue == 800 and os.clock() == 100)
	assert(first.PossibleBenefit.Randomized == true and first.PossibleBenefit.ActualGrant == "UNKNOWN")
	s:Close()
end)

audit("a false-valued exact string playtime claim key is already claimed", function()
	local s = fixture() s.Raw.PlaytimeRewards.Claimed["1"] = false
	assert(row(s:Report(), "FREE_PLAYTIME", 1).Status == "CLAIMED") s:Close()
end)
audit("unsupported numeric playtime key does not substitute for the native exact string key", function()
	local s = fixture() s.Raw.PlaytimeRewards.Claimed[1] = true
	assert(row(s:Report(), "FREE_PLAYTIME", 1).Status == "UNKNOWN") s:Close()
end)
for _, fault in ipairs({
	{ Name = "whole state absent", Apply = function(s) s.Raw.PlaytimeRewards = nil end },
	{ Name = "whole claim map absent", Apply = function(s) s.Raw.PlaytimeRewards.Claimed = nil end },
	{ Name = "scalar claim map", Apply = function(s) s.Raw.PlaytimeRewards.Claimed = false end },
	{ Name = "missing cycle start", Apply = function(s) s.Raw.PlaytimeRewards.Start = nil end },
	{ Name = "cycle start ahead of native now", Apply = function(s) s.Raw.PlaytimeRewards.Start = 1800001100 end },
}) do
	audit("missing/unsupported playtime facts stay UNKNOWN: " .. fault.Name, function()
		local s = fixture() fault.Apply(s)
		assert(row(s:Report(), "FREE_PLAYTIME", 1).Status == "UNKNOWN") s:Close()
	end)
end
audit("known missing Playtime capability locks rather than grants a reward", function()
	local s = fixture() s.Raw.MasteryUpgrades = {} s:Sync()
	assert(row(s:Report(), "FREE_PLAYTIME", 1).Status == "LOCKED") s:Close()
end)
audit("unavailable Playtime capability stays UNKNOWN", function()
	local s = fixture() s.Raw.MasteryUpgrades = nil s:Sync()
	assert(row(s:Report(), "FREE_PLAYTIME", 1).Status == "UNKNOWN") s:Close()
end)
audit("native Trading Plaza restriction locks the playtime family", function()
	local s = fixture() s.Reader.Dependencies.IsTradingPlaza.Value = function() return true end
	assert(row(s:Report(), "FREE_PLAYTIME", 1).Status == "LOCKED") s:Close()
end)
audit("unobservable native server time is never replaced with os.clock", function()
	local s = fixture() s.Reader.Dependencies.Time.Status = "LOADING"
	assert(s:Context().NativeNow == nil and row(s:Report(), "FREE_PLAYTIME", 1).Status == "UNKNOWN") s:Close()
end)

audit("daily current native day and explicit false boolean can be due", function()
	local s = fixture() local r = row(s:Report(), "FREE_DAILY", "STARS")
	assert(r.Status == "DUE" and r.NativeDay == 20833 and r.DayIndex == 1)
	assertReadonly(s:Report()) s:Close()
end)
audit("daily explicit current-day true boolean is claimed", function()
	local s = fixture() s.Raw.DailyRewards.Claimed = true
	assert(row(s:Report(), "FREE_DAILY", "STARS").Status == "CLAIMED") s:Close()
end)
for _, fault in ipairs({
	{ Name = "whole daily state missing", Apply = function(s) s.Raw.DailyRewards = nil end },
	{ Name = "boolean absent", Apply = function(s) s.Raw.DailyRewards.Claimed = nil end },
	{ Name = "claim scalar zero", Apply = function(s) s.Raw.DailyRewards.Claimed = 0 end },
	{ Name = "streak unavailable", Apply = function(s) s.Raw.DailyRewards.LastStreak = nil end },
	{ Name = "native day ahead in profile", Apply = function(s) s.Raw.DailyRewards.LastDay += 1 end },
}) do
	audit("daily does not reinterpret absent or unsupported facts: " .. fault.Name, function()
		local s = fixture() fault.Apply(s)
		assert(row(s:Report(), "FREE_DAILY", "STARS").Status == "UNKNOWN") s:Close()
	end)
end
audit("prior-day daily state does not simulate rollover/recovery", function()
	local s = fixture() s.Raw.DailyRewards.LastDay -= 1
	assert(row(s:Report(), "FREE_DAILY", "STARS").Status == "LOCKED") s:Close()
end)

audit("paid World Reward reports only the exact next sequential tier", function()
	local s = fixture() local r = row(s:Report(), "PAID_WORLD_REWARD", "The Overworld")
	assert(r.Status == "AVAILABLE" and r.NextTier == 1 and r.CompletedTiers == 0)
	assert(r.Cost.Amount == 100 and r.PossibleBenefit.Items.Amount == 1)
	assert(r.Cost.Type == "Currency" and r.Cost.Amount > 0 and r.ExecutionAuthorized == false)
	s.Raw.WorldRewards["The Overworld"].Progress = 1
	r = row(s:Report(), "PAID_WORLD_REWARD", "The Overworld")
	assert(r.NextTier == 2 and r.Cost.Amount == 200 and r.Status == "UNKNOWN")
	s:Close()
end)
audit("all received sequential World Reward tiers remain claimed", function()
	local s = fixture() s.Raw.WorldRewards["The Overworld"].Progress = 2
	assert(row(s:Report(), "PAID_WORLD_REWARD", "The Overworld").Status == "CLAIMED") s:Close()
end)
for _, value in ipairs({ false, 0, "unlocked" }) do
	audit("World Reward unlock requires true rather than entry presence: " .. tostring(value), function()
		local s = fixture() s.Raw.WorldsUnlocked["The Overworld"] = value s:Sync()
		assert(row(s:Report(), "PAID_WORLD_REWARD", "The Overworld").Status == "LOCKED") s:Close()
	end)
end
for _, fault in ipairs({
	{ Name = "whole progress map missing", Apply = function(s) s.Raw.WorldRewards = nil end },
	{ Name = "track missing", Apply = function(s) s.Raw.WorldRewards["The Overworld"] = nil end },
	{ Name = "progress missing", Apply = function(s) s.Raw.WorldRewards["The Overworld"].Progress = nil end },
	{ Name = "progress fractional", Apply = function(s) s.Raw.WorldRewards["The Overworld"].Progress = 0.5 end },
	{ Name = "progress outside catalog", Apply = function(s) s.Raw.WorldRewards["The Overworld"].Progress = 9 end },
	{ Name = "native next price missing", Apply = function(s) s.Catalogs.WorldRewards["The Overworld"].Levels[1].Cost = nil end },
	{ Name = "sparse native tiers", Apply = function(s) s.Catalogs.WorldRewards["The Overworld"].Levels[1] = nil end },
	{ Name = "whole world access map missing", Apply = function(s) s.Raw.WorldsUnlocked = nil s:Sync() end },
}) do
	audit("World Reward unknown prerequisites are not invented: " .. fault.Name, function()
		local s = fixture() fault.Apply(s)
		assert(row(s:Report(), "PAID_WORLD_REWARD", "The Overworld").Status == "UNKNOWN") s:Close()
	end)
end
audit("World Reward respects the explicit currency reserve", function()
	local s = fixture() s.Raw.Coins = 120 s:Sync()
	local r = row(s:Report(), "PAID_WORLD_REWARD", "The Overworld")
	assert(r.Status == "LOCKED" and r.Shortage == 30 and r.Reserve == 50)
	assert(r.PossibleBenefit.ActualGrant == "UNKNOWN") s:Close()
end)
for _, fault in ipairs({
	{ Name = "world definition absent", Apply = function(s) s.Catalogs.Worlds["The Overworld"] = nil end, State = "UNKNOWN" },
	{ Name = "world catalog unavailable", Apply = function(s) s.Reader.Dependencies.Worlds.Status = "LOADING" end, State = "UNKNOWN" },
	{ Name = "world removed", Apply = function(s) s.Catalogs.Worlds["The Overworld"].Removed = true end, State = "LOCKED" },
	{ Name = "retained event without active evidence", Apply = function(s) s.Catalogs.Worlds["The Overworld"].Event = "synthetic-retained-event" end, State = "UNKNOWN" },
}) do
	audit("paid World Reward needs current native world availability: " .. fault.Name, function()
		local s = fixture() fault.Apply(s)
		assert(row(s:Report(), "PAID_WORLD_REWARD", "The Overworld").Status == fault.State) s:Close()
	end)
end
for _, eligible in ipairs({ false, true }) do
	audit("paid pet reward storage is an independent observation: " .. tostring(eligible), function()
		local s = fixture() s.Raw.WorldRewards["The Overworld"].Progress = 1
		local context = s:Context() context.WorldRewardObservations["The Overworld"].StorageEligible = eligible
		assert(row(s:Report(context), "PAID_WORLD_REWARD", "The Overworld").Status == (eligible and "AVAILABLE" or "LOCKED")) s:Close()
	end)
end

audit("achievement false-valued exact claim key is present and claimed", function()
	local s = fixture() s.Raw.ClaimedPrizes["synthetic-prize"] = false
	assert(row(s:Report(), "ACHIEVEMENT_PRIZE", "synthetic-prize").Status == "CLAIMED") s:Close()
end)
audit("achievement whole missing claim map is UNKNOWN, never empty", function()
	local s = fixture() s.Raw.ClaimedPrizes = nil
	assert(row(s:Report(), "ACHIEVEMENT_PRIZE", "synthetic-prize").Status == "UNKNOWN") s:Close()
end)
audit("native achievement threshold allows a due review but no fabricated receipt", function()
	local s = fixture() local r = row(s:Report(), "ACHIEVEMENT_PRIZE", "synthetic-prize")
	assert(r.Status == "DUE" and r.Current == 20 and r.Required == 20)
	assert(r.PossibleBenefit.ActualGrant == "UNKNOWN") s.Raw.Bubbles = 19
	assert(row(s:Report(), "ACHIEVEMENT_PRIZE", "synthetic-prize").Status == "LOCKED") s:Close()
end)

audit("ordinary quest exact progress equality is completion, not receipt", function()
	local s = fixture() local r = row(s:Report(), "QUEST", "synthetic-quest")
	assert(r.Status == "DUE" and r.Tasks[1].Current == r.Tasks[1].Required)
	assert(r.PossibleBenefit.ActualGrant == "UNKNOWN" and r.Eligibility == "COMPLETION_OBSERVED_GRANT_UNKNOWN")
	s.Raw.Quests[1].Progress[1] = 21
	assert(row(s:Report(), "QUEST", "synthetic-quest").Status == "AVAILABLE") s:Close()
end)
for _, fault in ipairs({
	{ Name = "progress map missing", Apply = function(s) s.Raw.Quests[1].Progress = nil end },
	{ Name = "task requirement helper unavailable", Apply = function(s) s.Reader.Dependencies.QuestUtil.Status = "LOADING" end },
	{ Name = "task progress absent", Apply = function(s) s.Raw.Quests[1].Progress[1] = nil end },
	{ Name = "duplicate identity", Apply = function(s) s.Raw.Quests[2] = copy(s.Raw.Quests[1]) end },
}) do
	audit("ordinary quest unknown evidence cannot fabricate completion: " .. fault.Name, function()
		local s = fixture() fault.Apply(s)
		assert(row(s:Report(), "QUEST", "synthetic-quest").Status == "UNKNOWN") s:Close()
	end)
end
audit("quest completion history false does not prove current reward delivery", function()
	local s = fixture() s.Raw.QuestsCompleted["synthetic-quest"] = false
	local r = row(s:Report(), "QUEST", "synthetic-quest")
	assert(r.Status == "DUE" and r.CompletionHistory == false and r.PossibleBenefit.ActualGrant == "UNKNOWN") s:Close()
end)

audit("chest exact native cooldown distinguishes due time from location eligibility", function()
	local s = fixture() local r = row(s:Report(), "CHEST", "Synthetic Chest")
	assert(r.Status == "DUE" and r.SecondsUntilDue == 0 and r.Eligibility == "UNKNOWN")
	assert(#r.Unknowns > 0 and r.PossibleBenefit.ActualGrant == "UNKNOWN")
	s.Raw.Cooldowns["Synthetic Chest"] = 1800001100
	assert(row(s:Report(), "CHEST", "Synthetic Chest").Status == "AVAILABLE") s:Close()
end)
audit("missing chest cooldown does not mean due or never claimed", function()
	local s = fixture() s.Raw.Cooldowns = nil
	assert(row(s:Report(), "CHEST", "Synthetic Chest").Status == "UNKNOWN") s:Close()
end)
audit("observed locked chest access remains locked despite overdue cooldown", function()
	local s = fixture() local context = s:Context()
	context.ChestObservations["Synthetic Chest"] = { Loaded = true, Access = false, Interaction = "UNKNOWN" }
	assert(row(s:Report(context), "CHEST", "Synthetic Chest").Status == "LOCKED") s:Close()
end)

audit("a due free wheel ticket is separate from consuming a spin", function()
	local s = fixture() s.Raw.NextWheelSpin = 1800000900
	local context = s:Context() context.WheelQueuePending = false
	local r = row(s:Report(context), "FREE_WHEEL_TICKET", "TICKET")
	assert(r.Status == "DUE" and r.PossibleBenefit.Item == "Spin Ticket" and r.ExecutionAuthorized == false)
	s.Raw.NextWheelSpin = nil
	assert(row(s:Report(), "FREE_WHEEL_TICKET", "TICKET").Status == "UNKNOWN") s:Close()
end)

audit("retained unresolved playtime operation stays pending and cannot retry", function()
	local s = fixture() local context = s:Context()
	context.PendingObservation = { Pending = { Kind = "PLAYTIME", Index = 1, Status = "UNRESOLVED", Deadline = 1 } }
	local r = s:Report(context)
	assert(row(r, "FREE_PLAYTIME", 1).Status == "PENDING" and r.Recommendation.Kind == "OBSERVE_PENDING")
	assertReadonly(r) s:Close()
end)
audit("unmatched pending operation retains an explicit global barrier", function()
	local s = fixture() local context = s:Context()
	context.PendingObservation = { Pending = { Kind = "OTHER", Status = "UNRESOLVED", Deadline = 1 } }
	local r = s:Report(context)
	assert(row(r, "PENDING_RECEIPT", "RETAINED").Status == "PENDING" and r.PendingBarrier)
	assert(r.Recommendation.Kind == "OBSERVE_PENDING") s:Close()
end)
audit("wheel queue pending cannot authorize a ticket collection or consumed spin", function()
	local s = fixture() s.Raw.NextWheelSpin = 1800000900
	local context = s:Context() context.WheelQueuePending = true
	assert(row(s:Report(context), "FREE_WHEEL_TICKET", "TICKET").Status == "PENDING")
	assert(s:Report(context).Recommendation.Kind == "OBSERVE_PENDING") s:Close()
end)

audit("paid progression defers and consumable compatibility remains unknown for Mastery", function()
	local s = fixture() local context = s:Context() context.MasteryReport = masteryIncomplete()
	local r = s:Report(context)
	assert(r.MasteryPriority == "INCOMPLETE")
	assert(row(r, "PAID_WORLD_REWARD", "The Overworld").InterruptsMastery == "YES")
	assert(row(r, "CONSUMABLE").InterruptsMastery == "UNKNOWN" and r.Recommendation.ExecutionAuthorized == false)
	assert(row(r, "CONSUMABLE").PolicyDeferral == "CONSUMPTION_COMPATIBILITY_AND_SEPARATE_AUTHORIZATION_REQUIRED")
	assert(r.Recommendation.InterruptsMastery == nil or r.Recommendation.InterruptsMastery == "UNKNOWN") s:Close()
end)
audit("missing Mastery evidence cannot imply completion or harmless interruption", function()
	local s = fixture() local r = s:Report()
	assert(r.MasteryPriority == "UNKNOWN" and row(r, "PAID_WORLD_REWARD", "The Overworld").InterruptsMastery == "UNKNOWN") s:Close()
end)
audit("format is concise and discloses unknown receipt and all action permissions OFF", function()
	local s = fixture() local text = Policy.Format(s:Report())
	assert(text:find("READ_ONLY", 1, true) and text:find("spending OFF", 1, true) and text:find("unverified", 1, true))
	assert(#text < 1600) s:Close()
end)

audit("Challenge Pass sparse claimed value membership does not use array position", function()
	local s = fixture() s.Raw.ChallengePass.Claimed = { [8] = 1 }
	assert(row(s:Report(), "CHALLENGE_PASS", 1).Status == "CLAIMED")
	assert(row(s:Report(), "CHALLENGE_PASS", 2).Status == "DUE") s:Close()
end)
audit("Challenge Pass matching index with another value is not a claim", function()
	local s = fixture() s.Raw.ChallengePass.Claimed = { [1] = 2 }
	assert(row(s:Report(), "CHALLENGE_PASS", 1).Status == "DUE")
	assert(row(s:Report(), "CHALLENGE_PASS", 2).Status == "CLAIMED") s:Close()
end)
audit("Challenge Pass whole missing claim map remains UNKNOWN", function()
	local s = fixture() s.Raw.ChallengePass.Claimed = nil
	assert(row(s:Report(), "CHALLENGE_PASS", 1).Status == "UNKNOWN") s:Close()
end)
audit("Challenge Pass native deadline expiry wins over retained catalog availability", function()
	local s = fixture() s.Catalogs.ChallengePass.FinishTime.UnixTimestamp = 1800000999
	assert(row(s:Report(), "CHALLENGE_PASS", 1).Status == "EXPIRED")
	assertReadonly(s:Report()) s:Close()
end)
audit("Challenge Pass unsupported deadline stays UNKNOWN", function()
	local s = fixture() s.Catalogs.ChallengePass.FinishTime = nil
	assert(row(s:Report(), "CHALLENGE_PASS", 1).Status == "UNKNOWN") s:Close()
end)
audit("Challenge Pass incomplete tier stays locked without a skip or reset", function()
	local s = fixture() s.Raw.ChallengePass.Points = 0
	assert(row(s:Report(), "CHALLENGE_PASS", 1).Status == "DUE")
	assert(row(s:Report(), "CHALLENGE_PASS", 2).Status == "LOCKED") s:Close()
end)
audit("unscoped Season Index and Milestone contracts remain UNKNOWN", function()
	local s = fixture() local r = s:Report()
	for _, family in ipairs({ "SEASON_PASS", "INDEX", "MILESTONE" }) do assert(row(r, family).Status == "UNKNOWN") end
	s:Close()
end)

audit("owned native potion record and powerup stay consumables, not free claims", function()
	local s = fixture() local r = s:Report()
	local potion, powerup = row(r, "CONSUMABLE", "Potions:Coins:1"), row(r, "CONSUMABLE", "Powerups:Mystery Box:none")
	assert(potion.Owned == 3 and powerup.Owned == 2 and potion.Status == "AVAILABLE")
	assert(potion.Cost.Type == "CONSUMPTION" and potion.ClaimState == "NOT_A_FREE_CLAIM")
	assertReadonly(r) s:Close()
end)
audit("sparse native potion records retain exact Name Level Amount ownership", function()
	local s = fixture() s.Raw.Potions = { [9] = { Name = "Coins", Level = 1, Amount = 3 } }
	assert(row(s:Report(), "CONSUMABLE", "Potions:Coins:1").Owned == 3) s:Close()
end)
audit("optional potion level stays native-unspecified without inventing level one", function()
	local s = fixture() s.Raw.Potions[1].Level = nil
	local r = row(s:Report(), "CONSUMABLE", "Potions:Coins:none")
	assert(r.Owned == 3 and r.Level == nil and r.Status == "AVAILABLE") s:Close()
end)
for _, fault in ipairs({
	{ Name = "legacy nested map", Apply = function(s) s.Raw.Potions = { Coins = { [1] = 3 } } end },
	{ Name = "duplicate Name Level records", Apply = function(s) s.Raw.Potions[2] = copy(s.Raw.Potions[1]) end },
	{ Name = "negative amount", Apply = function(s) s.Raw.Potions[1].Amount = -1 end },
	{ Name = "whole inventory missing", Apply = function(s) s.Raw.Potions = nil end },
	{ Name = "native ItemUtil helper unavailable", Apply = function(s) s.Reader.Dependencies.ItemUtil.Status = "LOADING" end },
}) do
	audit("unsupported consumable stock remains unknown, never a free reward: " .. fault.Name, function()
		local s = fixture() fault.Apply(s)
		local context, r = s:Context(), s:Report()
		assert(context.InventoryObservations.Potions["Coins:1"] == nil
			or context.InventoryObservations.Potions["Coins:1"].Amount == nil)
		for _, entry in ipairs(r.Groups.CONSUMABLE or {}) do assert(entry.ClaimState == "NOT_A_FREE_CLAIM" or entry.Status == "UNKNOWN") end
		assertReadonly(r) s:Close()
	end)
end

for _, fault in ipairs({
	{ Name = "account snapshot not ready", Apply = function(s) s.Snapshot.Ready = false end },
	{ Name = "snapshot stale", Apply = function(s) s.Snapshot.ReadAt = 89 end },
	{ Name = "snapshot future dated", Apply = function(s) s.Snapshot.ReadAt = 101 end },
	{ Name = "snapshot age unknown", Apply = function(s) s.Snapshot.ReadAt = nil end },
	{ Name = "reader revision changed", Apply = function(s) s.Reader.Revision = 2 end },
	{ Name = "account changed", Apply = function(s) s.Reader.Player.UserId = 202 end },
	{ Name = "identity absent", Apply = function(s) s.Snapshot.Identity = nil end },
	{ Name = "profile not ready", Apply = function(s) s.Ready = false end },
	{ Name = "received balance differs", Apply = function(s) s.Raw.Coins = 999 end },
}) do
	audit("actual native account adapter rejects stale/mismatched facts: " .. fault.Name, function()
		local s = fixture() fault.Apply(s)
		assert(s:Context().Fresh == false and s:Report().Status == "UNKNOWN")
		assert(s:Report().Recommendation.Kind == "WAIT") s:Close()
	end)
end

for _, fault in ipairs({
	{ Name = "account identity", Apply = function(s) s.Reader.Player.UserId = 202 end },
	{ Name = "snapshot revision", Apply = function(s) s.Reader.Revision = 2 end },
	{ Name = "raw claim facts", Apply = function(s) s.Raw.ClaimedPrizes["synthetic-prize"] = false end },
	{ Name = "native catalog", Apply = function(s) s.Catalogs.Playtime.Gifts[1].Time = 121 end },
}) do
	audit("native helper changes invalidate the final read-only observation: " .. fault.Name, function()
		local s = fixture() s.OnQuest = function() fault.Apply(s) end
		assert(s:Context().Fresh == false) s:Close()
	end)
end
audit("snapshot becoming stale across a yielding native helper is revalidated", function()
	local s = fixture() s.OnQuest = function() coroutine.yield("synthetic read wait") end
	local context local thread = coroutine.create(function() context = s:Context() end)
	assert(coroutine.resume(thread)) clock = 111 assert(coroutine.resume(thread)) clock = 100
	assert(context.Fresh == false and context.Blocker:find("stale", 1, true)) s:Close()
end)
audit("input policy report and formatting never mutate detached native facts", function()
	local s = fixture() local context = s:Context() local before = copy(context)
	local snapshotBefore = copy(s.Snapshot) local r = s:Report(context) Policy.Format(r)
	assert(equal(context, before) and equal(s.Snapshot, snapshotBefore)) s:Close()
end)
for _, full in ipairs({ false, true }) do
	audit("actual native paid pet storage helper is observed independently: full=" .. tostring(full), function()
		local s = fixture() s.Raw.WorldRewards["The Overworld"].Progress = 1
		s.Reader.Dependencies.StatsUtil = { Status = "READY", Value = {
			IsInventoryFull = function(_, facts) facts.StorageProbe = true return full end,
		} }
		local context = s:Context()
		assert(context.Fresh and context.WorldRewardObservations["The Overworld"].StorageEligible == not full)
		assert(s.Raw.StorageProbe == nil and context.Raw.StorageProbe == nil)
		assert(row(s:Report(context), "PAID_WORLD_REWARD", "The Overworld").Status == (full and "LOCKED" or "AVAILABLE")) s:Close()
	end)
end
audit("native storage helper failure remains UNKNOWN rather than inferred available", function()
	local s = fixture() s.Raw.WorldRewards["The Overworld"].Progress = 1
	s.Reader.Dependencies.StatsUtil = { Status = "READY", Value = { IsInventoryFull = function() error("Synthetic unknown storage") end } }
	local context = s:Context()
	assert(context.WorldRewardObservations["The Overworld"].StorageEligible == nil)
	assert(row(s:Report(context), "PAID_WORLD_REWARD", "The Overworld").Status == "UNKNOWN") s:Close()
end)
audit("native storage helper account change invalidates all reward evidence", function()
	local s = fixture() s.Raw.WorldRewards["The Overworld"].Progress = 1
	s.Reader.Dependencies.StatsUtil = { Status = "READY", Value = { IsInventoryFull = function() s.Reader.Player.UserId = 202 return false end } }
	assert(not s:Context().Fresh and s:Report().Recommendation.Kind == "WAIT") s:Close()
end)
audit("row bound discloses omitted reward evidence rather than claiming completeness", function()
	local s = fixture() s.Config.REWARD_INTELLIGENCE_SETTINGS.MAXIMUM_REPORT_ROWS = 2
	local r = s:Report()
	assert(#r.Rows == 2 and r.OmittedRows > 0 and #r.Unknowns > 0) assertReadonly(r) s:Close()
end)
audit("disabled Brain reward intelligence performs no native observation", function()
	local s = fixture() s.Config.REWARD_INTELLIGENCE_SETTINGS.ENABLE_REWARD_INTELLIGENCE = false
	s.Knowledge.RewardContext = function() error("Disabled feature must not observe native data") end
	local r = s:BrainReport()
	assert(r.Status == "DISABLED" and r.Recommendation.Kind == "WAIT") assertReadonly(r) s:Close()
end)

local function controllerFixture(scene)
	local held = { Pending = { Kind = "PLAYTIME", Index = 1, Status = "UNRESOLVED" } }
	local controller = setmetatable({ Config = scene.Config, Reader = scene.Reader, Knowledge = scene.Knowledge,
		Brain = scene.Brain, State = "STOPPED", Scheduler = { Submit = function() error("Report attempted scheduling") end },
		Rewards = { UserId = 101, GetStatus = function() return held end, Prepare = function() error("Report attempted reward preparation") end,
			Observe = function() error("Report attempted action observation") end, Select = function() error("Report attempted action selection") end },
		Log = function(self, kind, text) self.LastLog = { Kind = kind, Text = text } end,
	}, Controller)
	return controller, held
end
audit("actual Controller Get/Print use retained status without refresh dispatch or scheduler", function()
	local s = fixture() local controller, held = controllerFixture(s)
	s.Reader.Refresh = function() error("Report attempted refresh") end
	s.Reader.Read = function() error("Report attempted account read") end
	local queued, beforeRaw = #queue, copy(s.Raw)
	local r = controller:GetRewardPlan()
	assert(r.Recommendation.Kind == "OBSERVE_PENDING" and #queue == queued)
	local printed = controller:PrintRewardPlan()
	assert(printed.Recommendation.Kind == "OBSERVE_PENDING" and controller.LastLog.Kind == "REWARD_INTELLIGENCE")
	assert(equal(s.Raw, beforeRaw) and held.Pending.Status == "UNRESOLVED" and controller.State == "STOPPED") s:Close()
end)
audit("destroyed Controller does not observe reward dependencies", function()
	local s = fixture() local controller = controllerFixture(s) controller.Destroyed = true
	s.Knowledge.RewardContext = function() error("Destroyed Controller must not observe") end
	assert(controller:GetRewardPlan().Recommendation.Kind == "WAIT") s:Close()
end)
for _, managerId in ipairs({ false, 202 }) do
	audit("Controller rejects unbound or other-account pending manager status: " .. tostring(managerId), function()
		local s = fixture() local controller = controllerFixture(s)
		controller.Rewards.UserId = managerId
		controller.Rewards.GetStatus = function() error("Other-account status must not be read") end
		local r = controller:GetRewardPlan()
		assert(r.PendingBarrier == true and r.Recommendation.Kind == "OBSERVE_PENDING") s:Close()
	end)
end
audit("Controller missing retained manager observation stays behind an unknown barrier", function()
	local s = fixture() local controller = controllerFixture(s) controller.Rewards = nil
	local r = controller:GetRewardPlan()
	assert(r.PendingBarrier == true and r.Recommendation.Kind == "OBSERVE_PENDING") s:Close()
end)
audit("actual complete reward loader Config remains STOPPED and grants no actions or budgets", function()
	local config = Resolver.Resolve(Defaults, phase5RewardLoaderOverrides())
	assert(config.GENERAL_SETTINGS.AUTO_START == false and config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS == false)
	assert(config.REWARD_INTELLIGENCE_SETTINGS.ENABLE_REWARD_INTELLIGENCE == true)
	for group, keys in pairs({
		BRAIN_SETTINGS = { "ENABLE_EARNING_RECOMMENDATIONS", "ENABLE_WORLD_RECOMMENDATIONS", "ENABLE_MASTERY_RECOMMENDATIONS", "ENABLE_INVENTORY_RECOMMENDATIONS" },
		PET_SETTINGS = { "ENABLE_PET_INTELLIGENCE", "AUTO_HATCH", "AUTO_EQUIP", "EQUIP_OWNED_TEAM_ONCE", "AUTO_DELETE_PETS", "AUTO_CRAFT_SHINY", "AUTO_FUSE_PETS" },
		HATCH_SETTINGS = { "HATCH_ONE_EGG_ONCE", "ENABLE_BACKGROUND_PICKUPS" },
		OWNER_ONE_HATCH_TEST_SETTINGS = { "OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST", "OWNER_ONE_HATCH_TEST_ALLOWANCE" },
		EGG_TRAVEL_SETTINGS = { "OWNER_DIRECT_EGG_TELEPORT_TEST", "ENABLE_SELECTED_EGG_TRAVEL", "ENABLE_NATIVE_ISLAND_TRAVEL", "ENABLE_DIRECT_POSITIONING" },
		WORLD_SETTINGS = { "ENABLE_WORLD_PROGRESSION", "AUTO_DISCOVER_ISLANDS", "AUTO_UNLOCK_WORLDS", "AUTO_TRAVEL_FOR_PROGRESSION", "AUTO_FARM_UNLOCK_REQUIREMENTS" },
		FARMING_SETTINGS = { "AUTO_RESOURCE_FARM", "AUTO_FARM_FALLBACK" },
		ISLAND_SETTINGS = { "AUTO_TRAVEL_BEST_ISLAND", "AUTO_EXPLORE_UNLOCKED_ISLANDS" },
		PICKUP_SETTINGS = { "BULK_COLLECT_PICKUPS", "STATIONARY_ISOLATED_TEST", "ENABLE_CONTINUOUS_SCANNING" },
		BUBBLE_SETTINGS = { "AUTO_BLOW_BUBBLES", "AUTO_SELL_BUBBLES", "AUTO_BUY_GUM", "AUTO_BUY_FLAVORS", "ENABLE_SIMULTANEOUS_BLOWING" },
		UPGRADE_SETTINGS = { "ENABLE_SMART_UPGRADES", "ENABLE_CAPACITY_UPGRADES", "ENABLE_FLAVOR_UPGRADES", "AUTO_EQUIP_OWNED_UPGRADES" },
		PLAYTIME_SETTINGS = { "AUTO_CLAIM_PLAYTIME" },
		MYSTERY_BOX_SETTINGS = { "AUTO_OPEN_MYSTERY_BOXES", "ENABLE_AUTOMATIC_CONTINUATION" },
		ANTIAFK_SETTINGS = { "ENABLE_ANTI_AFK" },
		FALL_EVENT_SETTINGS = { "ENABLE_FALL_EVENT", "AUTO_REBIRTH", "AUTO_BUY_REBIRTH_UPGRADES", "AUTO_USE_FALL_ELIXIRS", "AUTO_BUY_AUTUMN_SHOP_ITEMS" },
	}) do for _, key in ipairs(keys) do assert(config[group][key] == false, group .. "." .. key .. " must stay OFF") end end
	for group, keys in pairs({
		HATCH_SETTINGS = { "MAXIMUM_EGG_COST", "MAXIMUM_SESSION_COST" },
		OWNER_ONE_HATCH_TEST_SETTINGS = { "AUTHORIZED_ACCOUNT_ID", "MAXIMUM_COIN_ALLOWANCE", "MAXIMUM_EGG_COST" },
		WORLD_SETTINGS = { "MAXIMUM_WORLD_UNLOCK_COST" }, UPGRADE_SETTINGS = { "MAXIMUM_PURCHASE_COST" },
	}) do for _, key in ipairs(keys) do assert(config[group][key] == 0, "No paid or account permission may be set") end end
	local controller = Controller.new(config)
	assert(controller.State == "STOPPED" and controller.Scheduler.Enabled == false and #controller.Scheduler.Queue == 0)
	assertReadonly(controller:GetRewardPlan())
	controller:Destroy()
end)

assert(audits == 102, "All 102 read-only reward regressions must execute")
print("[OC PHASE5 REWARDS] REWARD_SUITE_COUNT " .. tostring(audits) .. "; actual-source synthetic fixtures only; no live actions or acceptance claimed")

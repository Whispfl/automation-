-- Synthetic Phase 5 offline fixtures only. Every account, balance, tier price and
-- rate below is invented for testing; none is a live observation or action approval.
local Defaults, Resolver = requireOC("OCConfig"), requireOC("ConfigResolver")
local Reader, Knowledge = requireOC("AccountStateReader"), requireOC("GameKnowledge")
local Brain, Policy, Controller = requireOC("OCBrain"), requireOC("MasteryPolicy"), requireOC("OCController")
os.clock = function() return 100 end -- Synthetic deterministic clock, never bundled.
local audits = 0
local function audit(name, callback)
	callback()
	audits += 1
	print("[OC PHASE5 SYNTHETIC] " .. name .. " passed")
end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copy(entry) end
	return result
end
local function equal(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for key, entry in pairs(a) do if not equal(entry, b[key]) then return false end end
	for key in pairs(b) do if a[key] == nil then return false end end
	return true
end
local function price(currency, amount) return { Type = "Currency", Currency = currency, Amount = amount } end
local function tier(currency, amount, upgrades)
	return { Cost = price(currency, amount), Upgrades = upgrades or {} }
end
local function category(report, name)
	for _, row in ipairs(report.Categories or {}) do if row.Name == name then return row end end
	error("Missing synthetic category " .. name)
end
local function fixture(overrides)
	local config = Resolver.Resolve(Defaults, {
		GENERAL_SETTINGS = { AUTO_START = false },
		DIAGNOSTIC_SETTINGS = { ENABLE_CONSOLE_LOGGING = false },
		MASTERY_SETTINGS = { ENABLE_MASTERY_INTELLIGENCE = true, MAXIMUM_ACCOUNT_AGE_SECONDS = 10,
			MAXIMUM_RATE_AGE_SECONDS = 30, MINIMUM_RATE_SAMPLE_SECONDS = 15,
			CATEGORY_ORDER = { "Pets", "Buffs", "Shops", "Minigames", "Rifts" } },
		ISLAND_SETTINGS = { SELECTED_ISLANDS = { "The Void", "Zen" } },
	})
	for group, fields in pairs(overrides or {}) do
		for key, value in pairs(fields) do config[group][key] = value end
	end
	local raw = { MasteryLevels = { Pets = 0 }, MasteryUpgrades = {},
		WorldsUnlocked = { ["The Overworld"] = true },
		AreasUnlocked = { ["Outer Space"] = true, ["The Void"] = true, Zen = true },
		Coins = 1000, Gems = 1000 }
	local catalog = { Types = {}, Upgrades = {
		Pets = { LayoutOrder = 1, Levels = {
			[1] = tier("Coins", 100, { { Type = "Equips", Buff = { Type = "Value", Value = 1 } } }),
			[2] = tier("Gems", 200, { { Type = "Equips", Buff = { Type = "Value", Value = 2 } } }),
		} },
	} }
	local reader = Reader.new(config, { UserId = 101 }) -- Invented fixture identity only.
	local scene = { Config = config, Raw = raw, Catalog = catalog, Reader = reader, Now = 100 }
	reader.Dependencies.LocalData = { Status = "READY", Value = {
		IsReady = function() return scene.Ready ~= false end,
		Get = function() return scene.Raw end,
	} }
	reader.Dependencies.Mastery = { Status = "READY", Value = catalog }
	reader.Dependencies.Remote = { Status = "READY", Value = {
		FireServer = function() error("Read-only Mastery attempted transport") end,
		InvokeServer = function() error("Read-only Mastery attempted transport") end,
	} }
	scene.Knowledge, scene.Brain = Knowledge.new(reader), Brain.new(config)
	function scene:Sync()
		self.Reader.Revision = 1
		self.Snapshot = { Ready = true, Revision = 1, ReadAt = self.Now, Identity = { UserId = 101 },
			Balances = { Coins = self.Raw.Coins, Gems = self.Raw.Gems },
			Upgrades = { MasteryLevels = copy(self.Raw.MasteryLevels), MasteryUpgrades = copy(self.Raw.MasteryUpgrades) },
			UnlockedWorlds = copy(self.Raw.WorldsUnlocked), UnlockedIslands = copy(self.Raw.AreasUnlocked),
			ProgressionGraph = { Next = { Kind = "WORLD", Id = "WORLD:Synthetic next", Name = "Synthetic next",
				State = "READY", Cost = price("Coins", 500) } },
			Inventory = { Pets = {}, EquippedIds = {} } }
		self.Reader.Snapshot = self.Snapshot
		return self
	end
	function scene:Context()
		return self.Knowledge:MasteryContext(self.Snapshot, self.Now, self.Config.MASTERY_SETTINGS)
	end
	function scene:Report(rate)
		local context = self:Context()
		context.Rate = rate
		return Policy.Analyze(self.Config, self.Snapshot, context)
	end
	function scene:BrainReport(rate)
		return self.Brain:AnalyzeMastery(self.Snapshot, self.Knowledge, { Now = self.Now, StationaryRate = rate })
	end
	function scene:Close() self.Reader:Destroy() end
	return scene:Sync()
end
local function knownRate(currency, rate)
	return { Currency = currency or "Coins", ScopeVerified = true, Ready = true, Seconds = 20,
		LastAt = 100, PerMinute = rate or 60, Scope = "Synthetic stationary sample" }
end

audit("actual native Types/Upgrades shape and exact next tier are read without mutation", function()
	local scene = fixture()
	local beforeRaw, beforeCatalog = copy(scene.Raw), copy(scene.Catalog)
	local context = scene:Context()
	assert(context.Fresh and context.Catalog.Pets.Levels[1].Cost.Amount == 100)
	assert(context.CategoryObservations.Pets.NativePrice.Amount == 100)
	local report, row = scene:Report(), category(scene:Report(), "Pets")
	assert(row.CurrentTier == 0 and row.NextTier == 1 and #row.CompletedTiers == 0)
	assert(report.Recommendation.Kind == "MASTERY_REVIEW" and report.Recommendation.Category == "Pets")
	assert(equal(scene.Raw, beforeRaw) and equal(scene.Catalog, beforeCatalog))
	scene:Close()
end)

audit("completed tiers use received level and next current-plus-one only", function()
	local scene = fixture() scene.Raw.MasteryLevels.Pets = 1 scene:Sync()
	local row = category(scene:Report(), "Pets")
	assert(row.CurrentTier == 1 and row.NextTier == 2 and #row.CompletedTiers == 1 and row.CompletedTiers[1] == 1)
	assert(row.NextPrice.Currency == "Gems" and row.NextPrice.Amount == 200)
	scene:Close()
end)

audit("fully completed permanent branch has no invented next price", function()
	local scene = fixture() scene.Raw.MasteryLevels.Pets = 2 scene:Sync()
	local report, row = scene:Report(), category(scene:Report(), "Pets")
	assert(row.Status == "COMPLETE" and row.NextPrice == nil and row.NextTier == nil)
	assert(report.Recommendation.Kind == "WORLD_GATE_REVIEW")
	scene:Close()
end)

audit("missing sparse Mastery level is UNKNOWN rather than zero", function()
	local scene = fixture() scene.Raw.MasteryLevels.Pets = nil scene:Sync()
	local report, row = scene:Report(), category(scene:Report(), "Pets")
	assert(row.Status == "UNKNOWN" and row.CurrentTier == nil and row.NextTier == nil)
	assert(report.Recommendation.Kind ~= "WORLD_GATE_REVIEW")
	scene:Close()
end)

for _, value in ipairs({ -1, 0.5, 3, math.huge, 0/0 }) do
	audit("invalid or out-of-catalog current tier stays UNKNOWN: " .. tostring(value), function()
		local scene = fixture() scene.Raw.MasteryLevels.Pets = value scene:Sync()
		local report = scene:Report()
		if value ~= value then
			assert(report.Recommendation.Kind == "WAIT" and not scene:Context().Fresh)
		else assert(category(report, "Pets").Status == "UNKNOWN") end
		scene:Close()
	end)
end

audit("sparse level catalog cannot skip an absent prerequisite tier", function()
	local scene = fixture()
	scene.Catalog.Upgrades.Pets.Levels[2] = nil
	scene.Catalog.Upgrades.Pets.Levels[3] = tier("Gems", 400)
	local report, row = scene:Report(), category(scene:Report(), "Pets")
	assert(row.Status == "UNKNOWN" and report.Recommendation.Kind ~= "WORLD_GATE_REVIEW")
	scene:Close()
end)

audit("locked category is reported separately and cannot be declared complete", function()
	local scene = fixture() scene.Catalog.Upgrades.Pets.ShouldShow = function() return false end
	local row = category(scene:Report(), "Pets")
	assert(row.Status == "LOCKED" and row.Status ~= "COMPLETE")
	assert(scene:Context().CategoryObservations.Pets.Visibility == "LOCKED")
	scene:Close()
end)

for _, result in ipairs({ "throws", "nonboolean" }) do
	audit("uncertain native category visibility blocks eligible inference: " .. result, function()
		local scene = fixture()
		scene.Catalog.Upgrades.Pets.ShouldShow = function()
			if result == "throws" then error("Synthetic predicate failure") end
			return "not a boolean"
		end
		assert(scene:Context().CategoryObservations.Pets.Visibility == "UNKNOWN")
		assert(category(scene:Report(), "Pets").Status == "UNKNOWN")
		scene:Close()
	end)
end

audit("native Minigames visibility preserves exact non-nil membership semantics", function()
	local scene = fixture()
	scene.Raw.MasteryLevels.Minigames = 0
	scene.Catalog.Upgrades.Minigames = { LayoutOrder = 4, Levels = { tier("Gems", 15) },
		ShouldShow = function(account) return account.WorldsUnlocked["Synthetic game world"] ~= nil end }
	scene:Sync()
	assert(category(scene:Report(), "Minigames").Status == "LOCKED")
	scene.Raw.WorldsUnlocked["Synthetic game world"] = false scene:Sync()
	assert(scene:Context().CategoryObservations.Minigames.Visibility == "VISIBLE")
	assert(category(scene:Report(), "Minigames").Status == "REVIEW")
	scene:Close()
end)

audit("locked seasonal catalog does not join permanent completion obligation", function()
	local scene = fixture() scene.Raw.MasteryLevels.Pets = 2
	scene.Catalog.Upgrades.SyntheticSeason = { LayoutOrder = 9, ShouldShow = function() return false end,
		Levels = { tier("SyntheticCurrency", 999) } }
	scene:Sync()
	local report = scene:Report()
	assert(report.Recommendation.Kind == "WORLD_GATE_REVIEW")
	assert(report.Recommendation.Category ~= "SyntheticSeason")
	scene:Close()
end)

audit("native early unlock yields exact free Coins price and retains catalog provenance", function()
	local scene = fixture()
	scene.Catalog.Upgrades.Pets.Levels[1].UnlockEarly = function() return true end
	local context, row = scene:Context(), category(scene:Report(), "Pets")
	assert(context.CategoryObservations.Pets.EarlyUnlock == true)
	assert(row.NextPrice.Type == "Currency" and row.NextPrice.Currency == "Coins" and row.NextPrice.Amount == 0)
	assert(scene.Catalog.Upgrades.Pets.Levels[1].Cost.Amount == 100)
	scene:Close()
end)

audit("false early unlock preserves native tier price", function()
	local scene = fixture()
	scene.Catalog.Upgrades.Pets.Levels[1].UnlockEarly = function() return false end
	assert(category(scene:Report(), "Pets").NextPrice.Amount == 100)
	scene:Close()
end)

for _, result in ipairs({ "throws", "nonboolean" }) do
	audit("uncertain early-unlock predicate does not fabricate a free or paid quote: " .. result, function()
		local scene = fixture()
		scene.Catalog.Upgrades.Pets.Levels[1].UnlockEarly = function()
			if result == "throws" then error("Synthetic early failure") end
			return "unknown"
		end
		local row = category(scene:Report(), "Pets")
		assert(row.Status == "UNKNOWN" and row.NextPrice == nil)
		scene:Close()
	end)
end

local badPrices = {
	{ Name = "missing", Apply = function(level) level.Cost = nil end },
	{ Name = "numeric product", Apply = function(level) level.Cost = 123456 end },
	{ Name = "premium", Apply = function(level) level.Cost = { Type = "Gamepass", Id = 123456 } end },
	{ Name = "negative", Apply = function(level) level.Cost.Amount = -1 end },
	{ Name = "infinite", Apply = function(level) level.Cost.Amount = math.huge end },
	{ Name = "NaN", Apply = function(level) level.Cost.Amount = 0/0 end },
	{ Name = "missing currency", Apply = function(level) level.Cost.Currency = nil end },
	{ Name = "function", Apply = function(level) level.Cost = function() error("Price function must not be called") end end },
}
for _, item in ipairs(badPrices) do
	audit("unavailable native price cannot authorize recommendation: " .. item.Name, function()
		local scene = fixture() item.Apply(scene.Catalog.Upgrades.Pets.Levels[1])
		local report = scene:Report()
		if item.Name == "NaN" then assert(report.Recommendation.Kind == "WAIT" and not scene:Context().Fresh)
		else local row = category(report, "Pets") assert(row.Status == "UNKNOWN" and row.NextPrice == nil) end
		scene:Close()
	end)
end

audit("unknown required balance remains unknown rather than zero", function()
	local scene = fixture() scene.Raw.Coins = nil scene:Sync()
	local row = category(scene:Report(), "Pets")
	assert(row.Affordability == "UNKNOWN" and row.Shortage == nil)
	scene:Close()
end)

audit("insufficient currency creates bounded funding recommendation without a purchase", function()
	local scene = fixture() scene.Raw.Coins = 40 scene:Sync()
	local report, row = scene:Report(), category(scene:Report(), "Pets")
	assert(row.Status == "FUNDING" and row.Shortage == 60)
	assert(report.Recommendation.Kind == "MASTERY_FUNDING" and report.Recommendation.Amount == 100)
	assert(scene.Raw.Coins == 40)
	scene:Close()
end)

audit("configured currency reserve is preserved in affordability and shortage", function()
	local scene = fixture({ RESOURCE_SETTINGS = { COIN_RESERVE = 950 } })
	local row = category(scene:Report(), "Pets")
	assert(row.Status == "FUNDING" and row.Shortage == 50)
	assert(scene.Config.RESOURCE_SETTINGS.COIN_RESERVE == 950 and scene.Raw.Coins == 1000)
	scene:Close()
end)

audit("Coins and Gems prerequisite-package costs remain separate", function()
	local scene = fixture()
	local row = category(scene:Report(), "Pets")
	assert(row.RemainingPackage.Status == "OBSERVED")
	assert(row.RemainingPackage.Costs.Coins == 100 and row.RemainingPackage.Costs.Gems == 200)
	assert(row.RemainingPackage.Costs.Total == nil)
	scene.Raw.MasteryLevels.Pets = 1 scene.Raw.Gems = 100 scene.Raw.Coins = 1000000 scene:Sync()
	assert(category(scene:Report(), "Pets").Shortage == 100)
	scene:Close()
end)

audit("unknown later price is explicit but does not invalidate known immediate tier", function()
	local scene = fixture() scene.Catalog.Upgrades.Pets.Levels[2].Cost = nil
	local row = category(scene:Report(), "Pets")
	assert(row.Status == "REVIEW" and row.RemainingPackage.Status == "UNKNOWN")
	assert(row.NextPrice.Amount == 100)
	scene:Close()
end)

audit("Mastery-first prioritizes obtainable permanent tier before affordable paid world", function()
	local scene = fixture()
	local report = scene:Report()
	assert(report.Recommendation.Kind == "MASTERY_REVIEW" and report.Recommendation.Category == "Pets")
	assert(scene.Snapshot.ProgressionGraph.Next.Cost.Amount == 500 and scene.Raw.Coins == 1000)
	scene:Close()
end)

audit("unfunded obtainable permanent Mastery still prevents premature world gate", function()
	local scene = fixture() scene.Catalog.Upgrades.Pets.Levels[1].Cost.Amount = 2000
	local report = scene:Report()
	assert(report.Recommendation.Kind == "MASTERY_FUNDING")
	assert(report.Recommendation.Kind ~= "WORLD_GATE_REVIEW")
	scene:Close()
end)

audit("configured category order breaks comparable choices without invented ROI", function()
	local scene = fixture()
	scene.Raw.MasteryLevels.Buffs = 0
	scene.Catalog.Upgrades.Buffs = { LayoutOrder = 2, Levels = { tier("Coins", 50) } }
	scene:Sync()
	assert(scene:Report().Recommendation.Category == "Pets")
	scene.Config.MASTERY_SETTINGS.CATEGORY_ORDER = { "Buffs", "Pets", "Shops", "Minigames", "Rifts" }
	assert(scene:Report().Recommendation.Category == "Buffs")
	assert(scene:Report().Recommendation.ExpectedIncomeGain == "UNKNOWN")
	scene:Close()
end)

audit("locked future-world category remains a separate prerequisite obligation", function()
	local scene = fixture() scene.Raw.MasteryLevels.Pets = 2 scene.Raw.MasteryLevels.Minigames = 0
	scene.Catalog.Upgrades.Minigames = { LayoutOrder = 4, Levels = { tier("Gems", 10) },
		ShouldShow = function(account) return account.WorldsUnlocked["Synthetic game world"] ~= nil end }
	scene:Sync()
	local report = scene:Report()
	assert(category(report, "Minigames").Status == "LOCKED")
	assert(report.Recommendation.Kind == "WORLD_GATE_REVIEW")
	scene.Raw.WorldsUnlocked["Synthetic game world"] = true scene:Sync()
	assert(scene:Report().Recommendation.Kind == "MASTERY_REVIEW")
	scene:Close()
end)

audit("received effective upgrades are not fabricated by summing historical tier effects", function()
	local scene = fixture() scene.Raw.MasteryLevels.Pets = 1
	scene.Raw.MasteryUpgrades = { [7] = { Type = "Equips", Buff = { Type = "Value", Value = 1 } } }
	scene:Sync()
	local context, row = scene:Context(), category(scene:Report(), "Pets")
	assert(equal(context.EffectiveUpgrades, scene.Raw.MasteryUpgrades))
	assert(row.Effects[1].Buff.Value == 2 and row.ExpectedIncomeGain == "UNKNOWN")
	assert(scene.Raw.MasteryUpgrades[7].Buff.Value == 1)
	scene:Close()
end)

for _, fault in ipairs({
	{ Name = "stale snapshot", Apply = function(scene) scene.Snapshot.ReadAt = 89 end },
	{ Name = "future snapshot", Apply = function(scene) scene.Snapshot.ReadAt = 101 end },
	{ Name = "missing timestamp", Apply = function(scene) scene.Snapshot.ReadAt = nil end },
	{ Name = "stale revision", Apply = function(scene) scene.Reader.Revision = 2 end },
	{ Name = "changed account", Apply = function(scene) scene.Reader.Player.UserId = 102 end },
	{ Name = "changed balance", Apply = function(scene) scene.Raw.Coins = 999 end },
	{ Name = "changed Mastery level", Apply = function(scene) scene.Raw.MasteryLevels.Pets = 1 end },
	{ Name = "changed effective upgrades", Apply = function(scene) scene.Raw.MasteryUpgrades[1] = { Type = "Playtime" } end },
	{ Name = "unready LocalData", Apply = function(scene) scene.Ready = false end },
}) do
	audit("stale or mismatching account evidence remains UNKNOWN: " .. fault.Name, function()
		local scene = fixture() fault.Apply(scene)
		local context = scene:Context()
		assert(not context.Fresh and context.Blocker ~= nil)
		assert(scene:Report().Recommendation.Kind == "WAIT")
		scene:Close()
	end)
end

audit("state changed during native visibility check invalidates otherwise fresh observation", function()
	local scene = fixture()
	scene.Catalog.Upgrades.Pets.ShouldShow = function() scene.Raw.Coins = 990 return true end
	local context = scene:Context()
	assert(not context.Fresh and context.Blocker ~= nil)
	scene:Close()
end)

audit("yielding native predicate receives detached state and rejects resumed changed profile", function()
	local scene = fixture()
	scene.Catalog.Upgrades.Pets.ShouldShow = function(account)
		account.Coins = 1 -- Native predicate cannot alter the original read-only input.
		coroutine.yield("synthetic visibility wait")
		return true
	end
	local context
	local thread = coroutine.create(function() context = scene:Context() end)
	local ok, yielded = coroutine.resume(thread)
	assert(ok and yielded == "synthetic visibility wait" and scene.Raw.Coins == 1000)
	scene.Raw.MasteryLevels.Pets = 1
	assert(coroutine.resume(thread))
	assert(not context.Fresh and context.Blocker ~= nil)
	scene:Close()
end)

audit("valid measured stationary currency sample produces conditional funding ETA only", function()
	local scene = fixture() scene.Raw.Coins = 40 scene:Sync()
	local recommendation = scene:Report(knownRate("Coins", 60)).Recommendation
	assert(recommendation.Kind == "MASTERY_FUNDING" and recommendation.FundingETASeconds == 60)
	assert(recommendation.ExpectedIncomeGain == "UNKNOWN")
	scene:Close()
end)

for _, fault in ipairs({
	{ Name = "no observed rate", Apply = function() return nil end },
	{ Name = "unverified scope", Apply = function(rate) rate.ScopeVerified = false return rate end },
	{ Name = "other currency", Apply = function(rate) rate.Currency = "Gems" return rate end },
	{ Name = "unready", Apply = function(rate) rate.Ready = false return rate end },
	{ Name = "short sample", Apply = function(rate) rate.Seconds = 1 return rate end },
	{ Name = "stale", Apply = function(rate) rate.LastAt = 69 return rate end },
	{ Name = "future", Apply = function(rate) rate.LastAt = 101 return rate end },
	{ Name = "zero rate", Apply = function(rate) rate.PerMinute = 0 return rate end },
	{ Name = "infinite rate", Apply = function(rate) rate.PerMinute = math.huge return rate end },
	{ Name = "NaN rate", Apply = function(rate) rate.PerMinute = 0/0 return rate end },
}) do
	audit("funding ETA stays unknown for invalid or missing measured income: " .. fault.Name, function()
		local scene = fixture() scene.Raw.Coins = 40 scene:Sync()
		local recommendation = scene:Report(fault.Apply(knownRate())).Recommendation
		assert(recommendation.Kind == "MASTERY_FUNDING" and recommendation.FundingETASeconds == nil)
		assert(recommendation.ExpectedIncomeGain == "UNKNOWN")
		scene:Close()
	end)
end

audit("Brain owns read-only Mastery analysis without changing its existing objective", function()
	local scene = fixture() scene.Brain.Previous = { Id = "SYNTHETIC_EXISTING_OBJECTIVE" }
	local selectedAt = scene.Brain.SelectedAt
	local report = scene:BrainReport()
	assert(report.Recommendation.Kind == "MASTERY_REVIEW")
	assert(scene.Brain.Previous.Id == "SYNTHETIC_EXISTING_OBJECTIVE" and scene.Brain.SelectedAt == selectedAt)
	scene:Close()
end)

audit("repeated analyses are pure and do not queue actions or consume balances", function()
	local scene = fixture()
	local beforeRaw, beforeConfig, beforeQueue = copy(scene.Raw), copy(scene.Config), #queue
	for _ = 1, 5 do assert(scene:BrainReport().Recommendation.Kind == "MASTERY_REVIEW") end
	assert(equal(scene.Raw, beforeRaw) and equal(scene.Config, beforeConfig) and #queue == beforeQueue)
	assert(scene.Raw.Coins == 1000 and scene.Raw.Gems == 1000)
	scene:Close()
end)

audit("formatted recommendation explains read-only costs, blockers and uncertain benefit", function()
	local scene = fixture()
	local text = Policy.Format(scene:Report())
	assert(type(text) == "string" and text:find("Pets", 1, true) and text:find("Coins", 1, true))
	assert(text:find("UNKNOWN", 1, true))
	scene:Close()
end)

audit("unobserved Mastery HUD prerequisite produces a prerequisite recommendation without travel", function()
	local scene = fixture() scene.Raw.AreasUnlocked["Outer Space"] = nil scene:Sync()
	local context, report = scene:Context(), scene:Report()
	assert(context.Access.Visibility == "LOCKED" and context.Access.PhysicalEligibility == "UNKNOWN")
	assert(report.Recommendation.Kind == "MASTERY_PREREQUISITE")
	assert(report.Recommendation.ActionAuthorization == "NONE")
	scene:Close()
end)

audit("unreviewed visible category is not silently assumed permanent", function()
	local scene = fixture() scene.Raw.MasteryLevels.Pets = 2 scene.Raw.MasteryLevels.SyntheticFuture = 0
	scene.Catalog.Upgrades.SyntheticFuture = { LayoutOrder = 8, Levels = { tier("Coins", 1) } }
	scene:Sync()
	local report, row = scene:Report(), category(scene:Report(), "SyntheticFuture")
	assert(row.Permanence == "UNKNOWN" and row.Status == "UNKNOWN")
	assert(report.Recommendation.Kind ~= "WORLD_GATE_REVIEW")
	scene:Close()
end)

audit("native early-unlock predicates are evaluated separately for later package tiers", function()
	local scene = fixture()
	scene.Catalog.Upgrades.Pets.Levels[2].UnlockEarly = function() return true end
	local row = category(scene:Report(), "Pets")
	assert(row.NextPrice.Amount == 100 and row.RemainingPackage.Status == "OBSERVED")
	assert(row.RemainingPackage.Costs.Coins == 100 and (row.RemainingPackage.Costs.Gems or 0) == 0)
	scene:Close()
end)

audit("disabled Mastery intelligence emits no native observation or actions", function()
	local scene = fixture({ MASTERY_SETTINGS = { ENABLE_MASTERY_INTELLIGENCE = false } })
	scene.Knowledge.MasteryContext = function() error("Disabled feature must not observe") end
	local report = scene:BrainReport()
	assert(report.Status == "DISABLED" and report.ActionAuthorization == "NONE")
	scene:Close()
end)

local function controllerFixture(scene)
	local sample = { Ready = true, Seconds = 20, LastAt = 100, PerMinute = { Coins = 60, Gems = 120 } }
	local controller = setmetatable({ Config = scene.Config, Reader = scene.Reader, Knowledge = scene.Knowledge,
		Brain = scene.Brain, Scheduler = { Submit = function() error("Read-only report must not schedule") end },
		Farming = { Tracker = { Current = { World = "The Overworld", Name = "The Void", Key = "The Overworld/The Void" } },
			_pickupRates = function() return { STATIONARY = sample,
				BUBBLES = { Ready = true, Seconds = 30, LastAt = 100, PerMinute = { Coins = 9999999 } } } end },
		Rewards = { AttributionBlocked = function() return false end },
		Log = function(self, kind, text) self.LastLog = { Kind = kind, Text = text } end,
	}, Controller)
	return controller, sample
end

audit("actual Controller report uses measured Void Coins and performs no refresh or dispatch", function()
	local scene = fixture() scene.Raw.Coins = 40 scene:Sync()
	local controller = controllerFixture(scene)
	scene.Reader.Read = function() error("Explicit read-only report must reuse snapshot") end
	scene.Reader.Refresh = function() error("Explicit read-only report must not trigger refresh") end
	local before = #queue
	local report = controller:GetMasteryPlan()
	assert(report.Recommendation.FundingETASeconds == 60 and #queue == before)
	assert(report.Recommendation.ActionAuthorization == "NONE" and scene.Raw.Coins == 40)
	local printed = controller:PrintMasteryPlan()
	assert(printed.Recommendation.FundingETASeconds == 60 and controller.LastLog.Kind == "MASTERY")
	scene:Close()
end)

audit("actual Controller report uses measured Zen Gems without Coins conversion", function()
	local scene = fixture() scene.Raw.MasteryLevels.Pets = 1 scene.Raw.Gems = 80 scene:Sync()
	local controller = controllerFixture(scene)
	controller.Farming.Tracker.Current = { World = "The Overworld", Name = "Zen", Key = "The Overworld/Zen" }
	local report = controller:GetMasteryPlan()
	assert(report.Recommendation.Currency == "Gems" and report.Recommendation.Shortage == 120)
	assert(report.Recommendation.FundingETASeconds == 60)
	scene:Close()
end)

for _, fault in ipairs({
	{ Name = "unselected island", Apply = function(scene) scene.Config.ISLAND_SETTINGS.SELECTED_ISLANDS = { "Zen" } end },
	{ Name = "locked island", Apply = function(scene) scene.Raw.AreasUnlocked["The Void"] = nil scene:Sync() end },
	{ Name = "locked world", Apply = function(scene) scene.Raw.WorldsUnlocked["The Overworld"] = nil scene:Sync() end },
	{ Name = "unsupported island", Apply = function(_, controller) controller.Farming.Tracker.Current.Name = "Synthetic Other" end },
	{ Name = "other world", Apply = function(_, controller) controller.Farming.Tracker.Current.World = "Synthetic Other" end },
	{ Name = "no current area", Apply = function(_, controller) controller.Farming.Tracker.Current = nil end },
	{ Name = "pending reward attribution", Apply = function(_, controller) controller.Rewards.AttributionBlocked = function() return true end end },
	{ Name = "no stationary sample", Apply = function(_, controller) controller.Farming._pickupRates = function()
		return { BUBBLES = { Ready = true, Seconds = 30, LastAt = 100, PerMinute = { Coins = 9999999 } } }
	end end },
}) do
	audit("Controller funding remains unmeasured rather than inventing income: " .. fault.Name, function()
		local scene = fixture() scene.Raw.Coins = 40 scene:Sync()
		local controller = controllerFixture(scene) fault.Apply(scene, controller)
		local report = controller:GetMasteryPlan()
		assert(report.Recommendation.Kind == "MASTERY_FUNDING" and report.Recommendation.FundingETASeconds == nil)
		scene:Close()
	end)
end

audit("destroyed Controller does not inspect native dependencies", function()
	local scene = fixture()
	local controller = controllerFixture(scene) controller.Destroyed = true
	scene.Knowledge.MasteryContext = function() error("Destroyed controller must not observe") end
	assert(controller:GetMasteryPlan().Recommendation.Kind == "WAIT")
	scene:Close()
end)

audit("locked category retains actual completed progress without declaring itself eligible", function()
	local scene = fixture() scene.Raw.MasteryLevels.Pets = 1
	scene.Catalog.Upgrades.Pets.ShouldShow = function() return false end scene:Sync()
	local row = category(scene:Report(), "Pets")
	assert(row.Status == "LOCKED" and row.CurrentTier == 1 and row.NextTier == 2)
	assert(#row.CompletedTiers == 1 and row.CompletedTiers[1] == 1 and not row.CompletionObserved)
	scene:Close()
end)

for _, fault in ipairs({
	{ Name = "noninteger index", Apply = function(levels) levels[1.5] = tier("Coins", 1) end },
	{ Name = "zero index", Apply = function(levels) levels[0] = tier("Coins", 1) end },
	{ Name = "text index", Apply = function(levels) levels.Extra = tier("Coins", 1) end },
	{ Name = "nontable tier", Apply = function(levels) levels[2] = "invalid" end },
}) do
	audit("malformed native tier sequence remains UNKNOWN: " .. fault.Name, function()
		local scene = fixture() fault.Apply(scene.Catalog.Upgrades.Pets.Levels)
		assert(category(scene:Report(), "Pets").Status == "UNKNOWN")
		scene:Close()
	end)
end

audit("missing native catalog cannot fabricate default tiers", function()
	local scene = fixture() scene.Reader.Dependencies.Mastery.Status = "LOADING"
	assert(not scene:Context().Fresh and scene:Report().Recommendation.Kind == "WAIT")
	scene:Close()
end)

audit("missing effective upgrade records remain UNKNOWN rather than reconstructed", function()
	local scene = fixture() scene.Raw.MasteryUpgrades = nil scene:Sync()
	local row = category(scene:Report(), "Pets")
	assert(row.EffectiveUpgrades == nil and row.EffectiveUpgradeState == "UNKNOWN")
	assert(row.ExpectedIncomeGain == "UNKNOWN")
	scene:Close()
end)

audit("currency absent from selected snapshot is read from actual native price and profile", function()
	local scene = fixture() scene.Raw.Tickets = 70
	scene.Catalog.Upgrades.Pets.Levels[1].Cost = price("Tickets", 60)
	local context, row = scene:Context(), category(scene:Report(), "Pets")
	assert(context.Balances.Tickets == 70 and row.NextPrice.Currency == "Tickets")
	assert(row.Affordability == "AFFORDABLE" and row.FundingETASeconds == nil)
	scene:Close()
end)

audit("snapshot becoming stale across a yielding native predicate invalidates observation", function()
	local scene = fixture()
	local clock = 100 os.clock = function() return clock end
	scene.Catalog.Upgrades.Pets.ShouldShow = function() coroutine.yield("synthetic wait") return true end
	local context
	local thread = coroutine.create(function() context = scene:Context() end)
	assert(coroutine.resume(thread)) clock = 111 assert(coroutine.resume(thread))
	os.clock = function() return 100 end
	assert(not context.Fresh and context.Blocker:find("stale", 1, true))
	scene:Close()
end)

audit("actual merged Phase 5 loader Config leaves every gameplay action and budget OFF", function()
	local config = Resolver.Resolve(Defaults, phase5LoaderOverrides())
	assert(config.GENERAL_SETTINGS.AUTO_START == false and config.GENERAL_SETTINGS.ENABLE_RECOMMENDATIONS == false)
	assert(config.MASTERY_SETTINGS.ENABLE_MASTERY_INTELLIGENCE == true)
	for group, keys in pairs({
		PET_SETTINGS = { "AUTO_HATCH", "AUTO_EQUIP", "EQUIP_OWNED_TEAM_ONCE", "AUTO_DELETE_PETS", "AUTO_CRAFT_SHINY", "AUTO_FUSE_PETS" },
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
	}) do
		for _, key in ipairs(keys) do assert(config[group][key] == false, group .. "." .. key .. " must be OFF") end
	end
	for group, keys in pairs({
		HATCH_SETTINGS = { "MAXIMUM_EGG_COST", "MAXIMUM_SESSION_COST" },
		OWNER_ONE_HATCH_TEST_SETTINGS = { "AUTHORIZED_ACCOUNT_ID", "MAXIMUM_COIN_ALLOWANCE", "MAXIMUM_EGG_COST" },
		WORLD_SETTINGS = { "MAXIMUM_WORLD_UNLOCK_COST" }, UPGRADE_SETTINGS = { "MAXIMUM_PURCHASE_COST" },
	}) do for _, key in ipairs(keys) do assert(config[group][key] == 0, "Spending or account authorization must be zero") end end
	local controller = Controller.new(config)
	assert(controller.State == "STOPPED" and controller.Scheduler.Enabled == false and #controller.Scheduler.Queue == 0)
	assert(controller:GetMasteryPlan().Recommendation.Kind == "WAIT")
	controller:Destroy()
end)

audit("unavailable Trading Plaza helper is explicitly UNKNOWN in report and blockers", function()
	local scene = fixture()
	local report, row = scene:Report(), category(scene:Report(), "Pets")
	assert(report.TradingPlazaStatus == "UNKNOWN" and row.TradingPlazaStatus == "UNKNOWN")
	assert(report.Access.PhysicalEligibility == "UNKNOWN" and report.Access.ServerEligibility == "UNKNOWN")
	assert(table.concat(row.Blockers, " | "):find("Trading Plaza condition UNKNOWN", 1, true))
	assert(report.Recommendation.ActionAuthorization == "NONE")
	scene:Close()
end)

audit("native false Trading Plaza observation reports INACTIVE without inventing eligibility", function()
	local scene = fixture()
	scene.Reader.Dependencies.IsTradingPlaza = { Status = "READY", Value = function() return false end }
	local report, row = scene:Report(), category(scene:Report(), "Pets")
	assert(report.TradingPlazaStatus == "INACTIVE" and row.TradingPlazaStatus == "INACTIVE")
	assert(report.Access.Visibility == "VISIBLE" and report.Access.ServerEligibility == "UNKNOWN")
	assert(not table.concat(row.Blockers, " | "):find("Trading Plaza condition UNKNOWN", 1, true))
	assert(report.Recommendation.Kind == "MASTERY_REVIEW" and report.Recommendation.ActionAuthorization == "NONE")
	scene:Close()
end)

audit("native true Trading Plaza observation locks HUD and creates a prerequisite recommendation", function()
	local scene = fixture()
	scene.Reader.Dependencies.IsTradingPlaza = { Status = "READY", Value = function() return true end }
	local report, row = scene:Report(), category(scene:Report(), "Pets")
	assert(report.TradingPlazaStatus == "ACTIVE" and row.TradingPlazaStatus == "ACTIVE")
	assert(report.Access.Visibility == "LOCKED" and row.Status == "PREREQUISITE")
	assert(report.Recommendation.Kind == "MASTERY_PREREQUISITE")
	assert(table.concat(row.Blockers, " | "):find("Trading Plaza", 1, true))
	assert(report.Recommendation.ActionAuthorization == "NONE")
	scene:Close()
end)

do
	local ready = fixture()
	print("[OC PHASE5 SYNTHETIC EXAMPLE] " .. Policy.Format(ready:Report()))
	ready:Close()
	local funding = fixture() funding.Raw.Coins = 40 funding:Sync()
	print("[OC PHASE5 SYNTHETIC EXAMPLE] " .. Policy.Format(funding:Report(knownRate("Coins", 60))))
	funding:Close()
	local blocked = fixture() blocked.Raw.AreasUnlocked["Outer Space"] = nil blocked:Sync()
	print("[OC PHASE5 SYNTHETIC EXAMPLE] " .. Policy.Format(blocked:Report()))
	blocked:Close()
end
assert(audits == 90, "All 90 Phase 5 synthetic regression groups must execute")
print("[OC PHASE5] " .. tostring(audits) .. " synthetic read-only Mastery audits passed; no owner gameplay verification or action approval claimed")

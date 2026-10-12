# Mastery/rewards/vendors/quests/transport source ledger

Research2026-10-11. Root researcher fetched complete sources for52 distinct paths listed in `catalogs/SOURCE_COVERAGE_ROOT.jsonl`. Review is explicitly TARGETED_DEEP: core system definitions,math,eligibility,request and result behavior; incidental rendering/monetization and every sub-function are not claimed fully audited. Economics/navigation/specialty/fishing ledgers contribute independent deeper or overlapping scopes. Combined counts deduplicate paths.

| Native family | Reviewed core | Saved analysis |
|---|---|---|
| Shared.Data.Mastery;Shared.Utils.Stats.MasteryUtil;Client.Gui.Frames.Mastery | category/level/cost/effect definitions,next-tier/early unlock,received upgrades,reconstruction caveat | MASTERY_AND_UPGRADES |
| Shared.Data.Gum/Flavors | item-shaped vs numeric Cost,base Storage/Bubbles,objective-specific payback model | MASTERY_AND_UPGRADES |
| Shared.Data.Playtime/DailyRewards/Chests/WorldRewards and respective client frames | eligibility/claimed/timer/next-tier/cost/space,principal individual/bulk calls and actual-result limits | REWARDS_QUESTS_AND_EVENTS;NATIVE_ACTION_CONTRACTS |
| Shared.Data.Builders.LootPoolBuilder/WorldRewardsBuilder | pool representation,no normalization;rounded arithmetic-progression costs | REWARDS_QUESTS_AND_EVENTS |
| Shared.Data.Shops;Shared.Utils.ShopUtil;ShopBuilder/ShopItemBuilder;Client.Gui.Frames.ItemShop | static catalogs,predicates,stock seed,slot mastery,sale/refresh/free quotas,single/all calls | SHOPS_QUESTS_AND_CONSUMABLES |
| Client.Gui.Frames.Shop | imports/network leads;code redemption vs monetization classification | targeted only;not a full paid/social/gifting UI audit |
| Shared.Data.Potions/Powerups/Buffs;Client.Gui.Frames.Potions;Shared.Data.Builders.PromptBuilder | queued durations,crafting ingredients/cost/level;bulk use/gift/exclusive/count caps | SHOPS_QUESTS_AND_CONSUMABLES;DATA_SCHEMAS |
| QuestBuilder/QuestTaskBuilder;Shared.Utils.Stats.QuestUtil;Shared.Data.Quests.GenieQuest/SeasonChallenges;Client.Gui.Frames.Quests/GemGenie | task schemas,requirements/filter/complete/add/compare,seeded offers/deadline/change/reroll,achievement vs ordinary quest claim | SHOPS_QUESTS_AND_CONSUMABLES |
| Shared.Data.WheelSpin;Client.Gui.Frames.WheelSpin | literal weights,owned ticket spin result,queue/free claims,actual timer and presentation | REWARDS_QUESTS_AND_EVENTS |
| Shared.Utils.IndexUtil;Client.Gui.Frames.Index/Index.XLIndex | history vs owned inventory,mode keys,completion defects,principal claim args,XL progress | REWARDS_QUESTS_AND_EVENTS |
| Shared.Data.Milestones/MilestoneBuffs;Shared.Utils.MilestoneUtil;Client.Gui.Frames.Milestones | catalog categories/selected thresholds,QuestId/current progress/latest numeric vs retained special buffs,paid skip lead | REWARDS_QUESTS_AND_EVENTS;all-tier normalization unfinished |
| Shared.Data.DailyPerks;Shared.Utils.DailyPerkUtil;Shared.Framework.Utilities.Math.Time | weekday UTC mapping,value descriptors/native use,server-time and local-DateTime distinctions | REWARDS_QUESTS_AND_EVENTS |
| Shared.Data.Seasons/ChallengePass;Shared.Utils.Stats.SeasonUtil;Client.Gui.Frames.Season/ChallengePass | date/ID/threshold/XP/perk/seed/cache schemas,infinite defects,ordinary/infinite/claim/reset paths | REWARDS_QUESTS_AND_EVENTS;SHOPS_QUESTS_AND_CONSUMABLES |
| Client.Framework.Services.LocalData;Shared.Framework.Network.Remote | complete received-state/sequence transport logic,readiness,baseline/delta validation,dispatch shape | DATA_SCHEMAS;SYSTEM_DEPENDENCIES |
| Shared.Constants | cost/cap/base timer/fishing/perk constants relevant to reviewed consumers | exact cited callers govern meaning;not every constant establishes a usable capability |

Paths in the table are relative to ReplicatedStorage. All native anchors inside the analysis are returned one-based Studio lines, not embedded original-line decompiler comments. Full source/bytecode was transient and was not written to files. No code was required/executed. Account/server testing remains unavailable. Independent economic review corrected exact symbol names,field ownership,slot formulas and category-specific gift capacity; notes are saved in ECONOMY_REVIEW_NOTES.md.

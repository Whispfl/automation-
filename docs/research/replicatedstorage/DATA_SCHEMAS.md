# Data schemas and evidence ownership

Date2026-10-11. This is a semantic reference, not a full game source copy, generated account, or executable adapter. Paths starting Shared/Client below are relative to ReplicatedStorage. All structures reflect fields read by saved native callers; optionality, server validation and a complete universal account type are not inferred. No personal account contents are persisted.

## Evidence envelope for future knowledge

HYPOTHESIS — proposed documentation/knowledge shape, not an existing game type:

`{system, key, sourcePath, sourceSymbol, sourceLines, evidenceStatus, sourceFidelity, observedAt, accountRevision, worldObservationRevision, validityDeadline, value, uncertainty, ownerVerificationRef}`.

Keep static definition provenance apart from effective account calculations and observed outcomes. A static timestamp is not an account revision. Unknown cost, location, availability or probability remains unknown; do not coerce it to zero/free/unlocked. Object paths are not guaranteed unique: the inventory preserves duplicate names and dot-name path ambiguity.

## Native data and received state

| System | Source-supported definition / interface | Received account fields used by native callers | Evidence detail |
|---|---|---|---|
| Item | discriminator Type; Currency+Amount for currency; Name+optional Level/Amount for potion; Name+variant flags for pet; Type-specific rod/bait/rune fields | exact currency/inventory keys resolved by ItemUtil | Shared.Utils.Stats.ItemUtil; individual builders; economy ledger |
| Buff | `{Type="Value" or "Percent",Value}` inside Data.Buffs descriptor; descriptor carries Stat | ActiveBuffs records `{Name,Level,Expiry={Type,Duration}}`; ActivePotions[name] has Queue/Active, not a direct Stat field | BuffUtil48–50/64–71/127–181/330–342; resolves Stat through potion/buff definitions; Percent adds Value/100 to base |
| Egg | catalog Cost, Pool[], World and variant/rift/season flags; runtime scene annotation Island, not a catalog Area field | currency, storage, passes, MasteryUpgrades, EggsOpened, timers and buffs | EggBuilder166–178,Data.Eggs531–539; EGG_FACTS.jsonl + EGGS_AND_PETS; catalog Chance is not final probability |
| Pet definition | Rarity, base Stats by output, Images/variant support, Egg and specialized fields; catalog enchant Metadata describes lifetime | owned records with Id,Name,variants,XP,locks and enchant entries `{Id,Level,Extra}`; Teams/TeamEquipped | EnchantUtil384–388/77–96; PET_BASE_STATS.jsonl is definition facts, not personal inventory or effective stats |
| Team | IDs refer to owned records; actual full-team modifiers require PetUtil/StatsUtil | Teams,TeamEquipped,PetEquips/Super limits via helpers | repeated IDs can represent multiple stack units (Inventory.stackWindow214–244); general utility must preserve quantities; PetUtil deduplication is specific to team-enchant calculation |
| Rune | named family with Tiers[{Buff,Amount}], Recipe.Duration/Items, optional MaxAmount, Craftable | ActiveRunes[name]={Tier,Amount}; RuneCraft={Name,Tier,Amount,Start}; owned rune descriptor Type/Name/Tier | RuneUtil19–50/60–72, Data.Runes52–227, RuneCrafting83–106; Amount is remaining uses, craft finish is Start+Duration*Amount; expiry/depletion/server grant not inferred |
| Fragment | four colors and Scalar; per-color threshold250, total1000 | Fragments[color] or0 | FragmentUtil12–35/59–81; completion requires each color>=250; server cap and permanence unavailable |
| Super | coefficients/enchants resolved from equipped Super=true pets; distinct units and capacity | equipped-team IDs, Super flags, enchant entries and milestone capacity bonus | SuperUtil23–33/98–200, Constants52–53, StatsUtil429–439; shared frame cache cannot certify isolated hypothetical-team results |
| Guild | levels/per-stat unlocks, season/time/quest/reward definitions | Guild.Id/Guild.Level used by stat consumers; Stats.Bubbles used for UI unlock; separate received guild snapshot has seasonId | GuildUtil383–435 takes max perk per stat; Guilds UI217–246/2798–2856 gates snapshot season and cumulative Bubbles>=1m; source fields do not establish membership/XP earning/server season acceptance |
| Mastery | `{Types,Upgrades}`; category Levels with Cost, Upgrades and optional UnlockEarly/ShouldShow | MasteryLevels,MasteryUpgrades; legacy OGData.Passes for early unlock | Shared.Data.Mastery273–276; MasteryUtil.GetUpgrade197–209; level catalog alone cannot replace received upgrades |
| Gum/Flavor | Gum Storage/Area/Cost; Flavor Bubbles/Area/Cost; number Cost can identify gamepass | owned/equipped Gum/Flavor, unlocks/passes through native client/helpers | Data.Gum10–29,Flavors39–54; numeric product ID is not a currency amount |
| Vendor | shop fields DisplayName,Rerollable,RerollDuration,IsTemporary,SlotCount,PermanentItems,RandomItems,Unlocked; item Stock,Product,Cost | Shops[id] with Period,Began,Bought,FreeRerolls.Used; received MasteryUpgrades Type ShopSlots/InstantRestock and milestone/perk effects | ShopBuilder82–106,ShopItemBuilder41–50,ShopUtil74–106/108–223,ItemShop70–101/280–327 |
| Quest | Id,Tasks[],Progress[],Rewards[],HUD,Action,DisplayName,Icon | Quests[],QuestsCompleted; special GemGenie Seed/Next | QuestBuilder12–72; QuestUtil37–52/340–352; task requirements differ by type |
| Playtime | Gifts[{Time,Luck}], Prizes pool | PlaytimeRewards.Start,Claimed[string index] | Data.Playtime37–40; Client.Playtime99–135; sparse claimed map cannot be counted as next index |
| Daily | seven-day reward catalog plus daily shop items | DailyRewards.LastDay,LastStreak,Claimed,Stars | DailyRewards UI411–473;10 stars/day,cap200 Constants88–89; server streak policy unknown |
| Chest | Rolls,Cooldown,Reward[],Pool[],DevProduct | Cooldowns[chestName] absolute deadline,AreasUnlocked and native mastery | Data.Chests13–56; PhysicalItem/WorldMap contract; base cooldown differs from account timer |
| World Rewards | `{Currency,Levels[{Cost,Reward}]}` | WorldRewards[world].Progress,WorldsUnlocked | WorldRewardsBuilder54–79; next-tier transaction is paid |
| Index | egg/world pools, mode/variant discovery rules, XLIndexTasks | Discovered,IndexClaimed/Egg claimed-mode keys through UI,XLIndexClaimed[] | IndexUtil + Index/XLIndex; discovered history distinct from current inventory |
| Milestone | categories have QuestId,Tiers,Levels with Task,Items,Buffs,Title,Removed/event flags | QuestsCompleted[milestone-QuestId-level] | Data.Milestones; MilestoneUtil25–38/106–174; latest numeric tier vs cumulative Special flags |
| Challenge Pass | FinalTier,Id,FinishTime,RewardsPool,GetPointsForTier,GetTier,GetResetCost | ChallengePass.Points,Rewards[],Claimed[],FreeSkips,GemResets,LastInviteBonus | ChallengePass Data11–84/UI; separate from Season |
| Season Pass | Seasons[{ID,Start,Finish,Points,Pool,Track{Free,Premium}}],Challenges | Season.ID,Seed,Level,Points,Premium,IsInfinite,InfinityTiers,LastCost,LastCostIndex,InfinityLuckLevel,Challenges,InfinitySkipsBought | Seasons1583–1589; SeasonUtil143–155/208–458; generated grant math has fidelity limits |
| Rift/seasonal | type-specific catalog plus expiry/attributes | received mastery,keys/fragments/charms,seasonal upgrade/rebirth state | SPECIALTY_AND_SEASONAL_SYSTEMS; Workspace spawned instance supplies identity/position/deadline |
| Fishing/minigame | area/rod/bait/fish/enchant and difficulty/prize definitions | rods,baits,fish state,cooldowns,quests; exact native schemas in focused document | FISHING_AND_MINIGAMES; definition alone does not provide a completed catch/game |

Some account field names have different shapes or prefixes across client modes. Use the precise native caller in each document instead of interpreting this table as a single complete type declaration.

## LocalData is received state, not a source of fabricated balances

SOURCE_CONFIRMED — `Client.Framework.Services.LocalData:14–44`: IsReady tests its received table nonnil; DidLoadFail reflects PlayerDataFailed; Get returns the table. `PlayerDataLoaded.OnClientEvent:107–132` sets it once; `PlayerDataChanged:132–158` replaces a top-level field and fires listeners. ConnectDataChanged accepts one key or a list, returns a disconnect callback and immediately schedules the subscriber when ready (`45–81`). DataReady/Changed are events (`88–91`). None of these were invoked during research.

SOURCE_CONFIRMED — pet state uses an additional sequence protocol (`LocalData:161–604`): GetPetById returns nil until pet baseline is valid (`176–179`). PetsChanged can carry `{Full=true,Added={},Changed={},Removed={}}` (`334`) or a delta change set (`499–503`). Delta message fields include Kind,Seq,Count,Added[],Changed[],Removed[]; full includes Pets[]. Exact contiguous array/unique nonempty ID checks are in191–303. Added must not already exist; Changed/Removed must exist; operations cannot repeat the same ID (`466–486`). Result count must equal `oldCount-removed+added` (`487`). A valid delta requires the expected Seq (`533`) and advances to Seq+1 (`497–498`). A full snapshot must be newer than the accepted Seq and match Count (`556–569`).

Missing/out-of-order/invalid delta initiates native RequestPetsResync. Several saved task.delay(5,function()end) callbacks are empty (`267,365,399,543,554,598`); one reconstructed callback resets u9 at583. Do not certify throttle/retry behavior from those empty reconstructions. The research did not send a resync. Future OC should read the verified existing service/cache and require consistent baseline/IDs, rather than attach a second competing pet cache or fabricate updates.

HYPOTHESIS — verification snapshot should record task-correlated before/after revisions and distinguish mutation from unrelated farming/claims. A nonnil LocalData.Get proves availability, not freshness of all fields or completion of every pending delta. Recompute effective-team estimates after valid pet delta, TeamEquipped/Teams, mastery, buff or global-effect changes, with a bounded event-driven invalidation strategy.

## Resource boundaries

ReplicatedStorage supplies definitions and native client behaviors. LocalData supplies actual received player/account facts. Workspace supplies current spawned objects, geometry, ranges and physical availability. Research Edit-mode scene observations are saved-scene facts; no account snapshot or current live spawn proof was collected. Server-only rules must remain UNAVAILABLE unless the owner observes and verifies them later.

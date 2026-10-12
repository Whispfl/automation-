# Shops, quests and consumables — batch 4

Research only; no gameplay requests were sent. Source locations below are the numbered lines returned by Studio `script_read`, not the original-line numbers inside decompiler comments. SOURCE_CONFIRMED means the saved client/Shared source contains the behavior; it does not establish server acceptance. Prices and timers require fresh LocalData before any future decision. No live account facts were collected.

## Currency vendors and stock

The currency vendor frame is `ReplicatedStorage.Client.Gui.Frames.ItemShop`. The separate `Client.Gui.Frames.Shop` primarily handles monetization, gifting and code redemption; its name alone is insufficient to classify a purchase as an in-game currency action.

SOURCE_CONFIRMED: `Shared.Data.Builders.ShopBuilder:11–106` builds `DisplayName`, `Rerollable`, `RerollDuration`, `IsTemporary`, `SlotCount`, `PermanentItems`, `RandomItems` and an optional `Unlocked(account)` predicate. Random item `ItemChance` defaults to 1 (`65–71`). `ShopItemBuilder:9–50` builds `Stock` (integer or NumberRange), `Product` (Item descriptor) and `Cost={Type="Currency",Currency,Amount}`. A catalog predicate is client knowledge, not proof that it is the complete server requirement.

| Exact shop ID | Catalog name | Base refresh seconds | Base slots | Explicit catalog eligibility |
|---|---|---:|---:|---|
| alien-shop | Alien Shop | 1,200 | 2 | `AreasUnlocked.Zen ~= nil` |
| shard-shop | Blackmarket | 21,600 | 2 | received `MasteryUpgrades` contains Type Blackmarket |
| dice-shop | Dice Merchant | 7,200 | 2 | `WorldsUnlocked["Minigame Paradise"] ~= nil` |
| traveling-merchant | Traveling Merchant | 28,800 | 2 | UI additionally handles weekend availability |
| fishing-shop | Fishing Shop | 21,600 | 2 | no additional predicate established here |
| shadow-shop | Shadow Shop | 28,800 | 2 | no additional predicate established here |
| shadowrift-shop | Dark Rift Shop | 7,200 | 2 | temporary physical rift availability remains separate |
| corruptshadow-shop | Corrupt Rift Shop | 14,400 | 2 | temporary physical rift availability remains separate |
| hw26rebirth-shop | Halloween Rebirth Shop | 345,600 | 14 | Rerollable=false; active season and physical availability unverified |
| spooky-shop | Spooky Shop | 86,400 | 12 | Rerollable=false; active season and physical availability unverified |
| temp-shop | Test Shop | temporary | 3 | test definition; not a live opportunity |

Table evidence: `Shared.Data.Shops:14–30,32–63,65–80,82–103,104–146,148–182,184–224,226–266,268–294,296–318,319–324`. The saved catalog includes Halloween and historical event definitions; existence does not establish activity.

Examples of SOURCE_CONFIRMED base investments: Alien permanent Golden Key costs 3,000 Gems for product amount 1 and base stock 3 (`Shops:13–14`). Its random Mystery Box costs 15,000 Gems, base stock 5 (`15–16`). Blackmarket has level-6 Lucky/Coins potions at 1.1m Gems and level-6 Mythic/Speed at 1.25m (`31–38`); these are expensive relative to early progression reserves. Halloween Rebirth Shop Eerie Pumpkin XL costs 11,111 HalloweenShards (`293–294`); Spooky Shop Creepy Hydra costs 500b Candycorn26 (`317–318`). These are separate currencies, not interchangeable Coin equivalents.

### Reconstructing a displayed offer

SOURCE_CONFIRMED: `ReplicatedStorage.Shared.Utils.ShopUtil:GetItemsData:108–223` uses `Random.new(bit32.bxor(player.UserId % 2^32, account.Shops[id].Period))` at `123`, clones the candidate lists and selects random items without replacement (`181–199`). Equal weights use uniform index selection; otherwise the weighted helper is used. NumberRange stock uses NextInteger (`203–205`). Thus the catalog pool is not the player's current offer: received Period, Bought and mastery upgrades matter. Never save player identity merely to reproduce this research.

`GetUnlockedSlots:74–89` returns `generatedItemCount-(maximumCatalogShopSlotsBonus-currentReceivedMasteryShopSlotsBonus)`. Generation includes base slots plus the maximum catalog bonus (`126`); the actual received MasteryUpgrades Type ShopSlots selects the unlocked portion, not an account.ShopSlots[id] field. `GetMaxFreeRerolls:91–106` adds received InstantRestock upgrades and milestone free refreshes. `ItemShop:update:280–327` caches generation with relevant fields and deducts received `Shops[id].Bought[slot]` from generated stock (`324`). Re-read state immediately before a future purchase; old slot numbers can target a different product after a refresh.

Sale eligibility is tested at `ShopUtil:138`; catalog categories listed in `18–52` use special handling. The sale reduction uses `Constants.ShopSaleMasteryDiscount` (25%, `Constants:95`) in `140–168`. Ordinary shop discounts additionally use ShopDay and milestone discounts and are capped at 95% (`162–163`); final price is rounded (`166`). Do not turn a Percent buff's additive representation into a multiplicative percentage without consulting BuffUtil.

SOURCE_CONFIRMED formula in `GetRerollDuration:224–242`: `round(baseDuration / (masteryFasterRestockScalar + milestoneShopRefreshCooldown))`. A displayed 100% improvement is not necessarily a 100% reduction in elapsed time. CLIENT_ESTIMATE reconstruction must use this helper and received state.

UNAVAILABLE fidelity issue: stock expression at `220` appears to include two baseline stock scalars (`v22 + v25 + milestoneStock`) before multiplying the daily perk. This may be a decompilation defect. Do not silently replace it with an assumed intended formula or treat generated stock as server-confirmed.

### Vendor action contracts

| Native call | Source | Established client checks | Verification and stops |
|---|---|---|---|
| `FireServer("BuyShopItem", shopId, slotIndex, false)` | ItemShop:365–373 | loaded account, selected shop, displayed affordability; pet-space check | fresh Bought delta plus product inventory increase and currency debit; stop on refresh/stock exhaustion/state loss |
| `FireServer("BuyShopItem", shopId, slotIndex, true)` | ItemShop:409–417 | displayed full-stack cost and pet-space check | boolean requests all; no desired quantity argument established; reserve-safe arbitrary quantities unavailable |
| `FireServer("ShopFreeReroll", shopId)` | ItemShop:590 | selected shop; UI uses Used/max quota at 70–101 | new received Period/Began/offer state plus FreeRerolls usage; stop when quota is exhausted |
| `FireServer("SetShopRerollTarget", shopId)` followed by product purchase prompt | ItemShop:649–650 | paid refresh flow | monetary purchase; excluded from automatic proposals |

`getBuyAllData:226–239` displays `max(1,min(floor(balance/unitCost),stock))`; it can allocate the entire available currency balance. It is not a protected spending budget. Single and all purchase callbacks include stale captured account variables in portions of their checks; future OC should use fresh verified LocalData and require deltas. No local pacing constant found in these callbacks establishes a server rate limit. ItemShop:744–773 additionally checks Blackmarket mastery for shard-shop. Physical vendor binding and any server proximity requirement remain separate from the frame contract.

HYPOTHESIS for later ROI: a consumable offer is worthwhile only when expected additional earnings or objective progress during usable duration exceeds its currency opportunity cost, travel/time cost and reserve impact. A free reroll can still be bad if it replaces a valuable current offer. Protect named currencies independently; do not infer a fixed Gems/Coins/Pearls exchange rate.

## Quest schemas and progress

SOURCE_CONFIRMED: `Shared.Data.Builders.QuestBuilder:12–72` produces `Id`, `Icon`, `Rewards`, `Tasks`, `HUD`, optional `Action`, `DisplayName`, and a zero-filled Progress array. `QuestTaskBuilder` exposes Bubbles, Sell, Playtime, Collect, Hatch (including filters), HatchGroup, ShrineDonation, ShrineDonationItemAmount, GenieQuest, Minigame, Enchant, Chest, EnchantRod, CatchFish, ShopBuy, UsePotion, Obby, VisitCabins, CollectPresents and UseRebirthMachine constructors. These are task descriptors; constructors do not themselves advance an account.

`Shared.Utils.Stats.QuestUtil:GetRequirement:37–52` uses ItemUtil's item amount for Collect, otherwise task Amount or 1. `ValidateTask:243–324` checks definitions for egg/pet/group/difficulty/chest/fish mutation/area/rarity/item. `FindById:340–352` searches received `account.Quests`. `Add:382–420` creates a missing quest and can pre-credit existing purchases/unlocks. `CompareTask:422–532` compares action/filter semantics; it is useful for overlap research but not proof that a new quest will credit historical activity.

Fidelity warnings: `IsComplete:325–338` requires exact equality for each Progress entry, not `>=`; strict Sell comparison at `477–481` appears inverted. Keep those saved-source observations separate from presumed server intent. `Client.Gui.Frames.Quests:updateQuests:571–637` renders received progress and displays currency reward as `ceil(base * StatsUtil.GetCurrencyMultiplier(account,currency,true))`. Rendering a scaled reward is a CLIENT_ESTIMATE until the account receives it.

`Quests:103–126` sends `FireServer("ClaimPrize", prizeKey)` for achievement prizes, with a 0.25-second local busy window and immediate particles. This is not a general `ClaimQuest` call. Ordinary quest HUD rendering at `543–708` exposes progress but no generic claim call was established. Quest completion/automatic reward timing is UNAVAILABLE; verify Quests, QuestsCompleted, inventories and balances together. Cosmetic confetti cannot confirm a grant.

### Gem Genie

SOURCE_CONFIRMED: `Shared.Data.Quests.GenieQuest:17–18` defines weighted reward-count choices 1/2/3/4 with weights 40/35/20/5 and task-count choices 2/3 with weights 60/40. It uses a seeded Random (`61`), base Gem range rounded to 250 with milestone reward factor (`65–66`), then ItemUtil combined rewards (`119`). UI builds three offers from `GemGenie.Seed + index - 1` (`Client.Gui.Frames.GemGenie:238–245`).

The saved `QuestsCompleted["gem-genie"] < -1` branch (`GenieQuest:68`) is suspicious for ordinary nonnegative counts. Treat special new-account branch eligibility as UNAVAILABLE. The regular branch requests native hourly challenge candidates and scales task amounts by 3, with specified-egg hatches by 2 (`96–107`).

| Call | Source | Known restrictions | Confirmation |
|---|---|---|---|
| `StartGenieQuest(offerIndex)` | GemGenie:349,412 | index 1–3 chosen from received Seed; UI active quest/deadline checks at 214–216 | matching gem-genie quest appears with tasks/rewards; index alone does not identify a stable offer |
| `ChangeGenieQuest()` | GemGenie:469 | confirmation flow | active quest/task replacement; lost progress is an opportunity cost |
| `RerollGenie()` | GemGenie:580,602 | affordability, confirmation, Green Fragment task warning 539–598 | Seed changes and item debit; protect fragments and existing task progress |

`Constants:17` defines 3,600-second base Genie cooldown; `Constants:19–20` defines Reroll Orb and amount 20. The UI uses received `GemGenie.Next - Time.now()` (`214`), so do not assume every account has a fixed one-hour timer. LocalData plus quest completion is required to verify a reward.

### Seasonal challenge generation

SOURCE_CONFIRMED: `Shared.Data.Quests.SeasonChallenges:29–87` exports weighted Hourly and Daily task pools; dynamically adds eligible non-Removed world eggs unless ChallengeIgnore, and rarity tasks except Secret. Example hourly rewards use Points amount 800; daily mostly 8,000 with a 100m-Gem Collect entry at 8,050 (`67`). Retained data is not active-season proof.

`Shared.Utils.Stats.SeasonUtil:GetRandomChallenges:459–520` avoids semantic duplicate tasks, excludes specific eggs absent from account.EggsOpened (`496–497`), and scales Amount for accounts with total Bubbles <250,000 AND Playtime <7,200 (`468,502–508`): divide by 100 generally or 5 for Hatch, rounded up. Named-pet hatch filtering at `485–495` has an apparent always-true temporary, so that sub-branch is UNAVAILABLE. The repeat loop has no evident finite fallback if candidates cannot satisfy filters; future planner should not reproduce an unbounded sampling loop.

`RefreshChallenges:522–556` chooses UTC server-time hour/day period, removes old prefix-matched quests, uses Random(period), creates three tasks with Points rewards and saves the period. This helper mutates supplied account data; it was read, never executed. Read received quests instead of trying to simulate reward grants.

HYPOTHESIS overlap objective: estimate marginal completion time for tasks whose filters match an already authorized action. Score each candidate from joint progress deltas; avoid counting the same currency reward twice. Expiring tasks should account for remaining time, interruption/travel cost and probability of completion. Trading or social verification is outside this research's action scope.

## Potions, gifts and powerups

SOURCE_CONFIRMED: `Shared.Data.Potions` describes standard Lucky/Speed/Coins/Mythic/Tickets as queued-duration buffs. Duration levels refer to `Constants.PotionDuration:70`: 120/180/300/600/900/1,200/1,800 seconds. Infinity Elixir=300 seconds (`Potions:35`), Secret Elixir=600 (`36`), Egg Elixir=1,200 (`37`), Ultra Infinity Elixir=600 (`42`). Native StatsUtil is required to interpret actual effects and stacking. Historical IsEvent descriptors do not identify an active event.

Potion crafting: `Client.Gui.Frames.Potions:193,209` sends `FireServer("CraftPotion", name, targetLevel, allBoolean)`. Cost comes from `CraftingCosts[targetLevel-1]` (`253`); eligible previous-tier stock is read at `239`, maximum displayed crafts is `min(floor(Gems/gemCost),floor(previousTierStock/requiredCount))` (`294`). UI gates level through `StatsUtil.GetPotionCraftLevel` (`363`) and stock/cost (`299–326`). Decompiler self-call at `246–247` and unresolved variable around updateDetails require source-fidelity caution. Success requires previous-tier consumption, Gem debit and target-tier increment. Boolean all is not an explicit protected count.

Single potion use: `Client.Gui.Frames.Inventory:4503,4512` sends `UsePotion(name,level)`; Mythic use checks DarkArts mastery at `4515–4523`, then sends at `4550,4559`. The 0.25-second guard in that area concerns sound presentation, not a proven server cooldown. Bulk path at `Inventory:3441–3445` calls `Shared.Data.Builders.PromptBuilder.fromMultiPotion` after MultiPotion mastery gating (`3209–3226,3346–3361`). The helper (`PromptBuilder:526–553`) sends `FireServer("UsePotion",name,level,count)`; `multiUse:201–224` clamps the displayed range to 1..min(owned,cap). `Constants.MultiPotionMaxAmount:99` is 250, in conflict with historical Mastery description text saying 10 (`Mastery:50`). Native call-site constant wins for the documented client range; actual server cap remains UNAVAILABLE.

Gift use: `PromptBuilder.fromGift:297–383` sends `UseGift(name,count)` (`324,375`), checks `GetPhysicalItems("Gift") >= Constants.MaxSpawnableLimit` (`327`) and shows a limited multi-use UI (`345`). It does not clearly subtract currently spawned gifts from the remaining capacity; do not infer more permissive capacity. Native auto-gift code `Client.Gui.Frames.Inventory:221–261` additionally checks account/powerup state and range to existing active gifts (`237–255`) before sending `min(owned,MaxSpawnableLimit)`. Gift activation creates physical work: verify inventory debit, physical gifts and eventual account grant separately. These guards count Gift objects specifically; a shared gift/pickup capacity limit is UNAVAILABLE.

`PromptBuilder:555–580` similarly exposes `UseGoldenOrb(count)`, using the same MultiPotionMaxAmount cap. `fromExclusiveEgg:464–524` exposes `HatchPowerupEgg(name,count)`; this differs from proximity-based currency egg hatching and needs its own inventory/space/season guards. These are confirmed client argument shapes, not owner-tested mechanics.

HYPOTHESIS consumable ROI: for a duration T seconds, account-relevant incremental earning value is the integral of `(boostedRate(t)-baselineRate(t))` over usable productive time, with effect uncertainty and travel/verification downtime. Do not buy or use a boost when its duration will be spent in travel, UI lock, unavailable features or a mismatched currency objective. Duration queued/paused/overlap details must come from active potion fields and native helpers, with owner-verified balance deltas.

## Batch limits

Deep review covers builders, ShopUtil, ItemShop, QuestUtil, GenieQuest/UI, seasonal challenge generator and principal craft/use call sites. It does not prove server stock, grants, timer policies, physical vendor distances, live seasonal activity or general quest auto-claim behavior. Complete monetization/social/trading UI analysis is intentionally not a core farming contract. Additional specialty/event evidence is in the separate batch 5 documents.

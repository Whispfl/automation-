# Reward, shop and quest strategies

Stage 2, 2026-10-11. Documentation-only analysis. Native request shape is not live acceptance; external advice does not authorize purchases, claims, rerolls, destructive resets or interactions with other people.

## Native baseline

Due free claims, paid World Rewards, currency shop purchases, randomized offer refreshes, ingredient crafting, timed/use-count consumables, quest progress and seasonal pass resets are separate decisions. Preserve actual received claimed maps, cooldowns, offer Period/slots/Bought, exact currencies and task filters. World Rewards are sequential paid transactions; native BuyAll/CraftAll booleans do not supply arbitrary protected quantities. Genie seed/index identifies offers only within a fresh received state. A free refresh can destroy a useful offer, and a quest change can forfeit progress.

Conditional strategy uses additional usable reward/goal progress divided by total effective time, with hard reserves, committed costs, location ownership, inventory capacity, deadlines and unknown grants explicitly represented. Native field/argument references are in ../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md, SHOPS_QUESTS_AND_CONSUMABLES.md and NATIVE_ACTION_CONTRACTS.md.

## Source access and precedence — batch M2

Actual [Daily Rewards](https://bgs-infinity.fandom.com/wiki/Daily_Rewards), [Playtime](https://bgs-infinity.fandom.com/wiki/Playtime) and [Wheel Spin](https://bgs-infinity.fandom.com/wiki/Wheel_Spin) article bodies/tables were read by the parent browser on2026-10-11 and relayed with scopes. [World Rewards](https://bgs-infinity.fandom.com/wiki/World_Rewards) body and its Overworld tab were read; other listed tabs were not yet inspected in that checkpoint. Revision metadata was unavailable. These are external comparisons, not native server rules. Search snippets never count as body reads.

The World Rewards page rounds prices and lists2GoldenKeys at tier2; saved native has5 (`Shared.Data.WorldRewards:14`). The Daily page's seven gifts have older names/quantities: day1StPatricksI1 versus native UltraInfinity1, days2–6mostly1 versus native10/3/3/3/3, and day7three of each versus native10each. The page's24-item Star shop agrees with shared prices but omits four native fragment rows; saved StarsShop has28entries. All mismatches remain version conflicts rather than an inferred live upgrade. Release/update dates in articles are feature chronology, not publication/revision metadata.

## Paid World Rewards: every native tier and the complete burden

`ReplicatedStorage.Shared.Data.WorldRewards:11–40,41–70` defines two30-tier tracks. The native builder54–79 uses minimum100m and nominal sum2trillion for each. For N30,a100m,S2trillion, `d=2*(S-N*a)/(N*(N-1))`; tier i=`50*ceil((a+(i-1)*d)/50)`. The following prices/cumulative prices are **exact rational arithmetic derivations** from those inputs, rounded by the described rule; native binary arithmetic/server pricing must still be checked at purchase time. Both tracks use the same numbers with different currencies. Total rounded cost is2,000,000,000,600 (S+600). Integer arithmetic produced the table without executing any game module.

| Tier | Price:Coins or Tickets | Cumulative fromzero | Overworld native reward | Minigame Paradise native reward |
|---:|---:|---:|---|---|
| 1 | 100,000,000 | 100,000,000 | 100 Coins | 500 Gems |
| 2 | 4,690,804,600 | 4,790,804,600 | Golden Key5 | 1000 Gems |
| 3 | 9,281,609,200 | 14,072,413,800 | Mystery Box2 | LuckyV2 |
| 4 | 13,872,413,800 | 27,944,827,600 | Royal Key3 | Dice Key3 |
| 5 | 18,463,218,400 | 46,408,046,000 | Spin Ticket3 | Golden Dice3 |
| 6 | 23,054,023,000 | 69,462,069,000 | Mystery Box5 | MythicV2 |
| 7 | 27,644,827,600 | 97,106,896,600 | MythicV5 | SpeedV2 |
| 8 | 32,235,632,200 | 129,342,528,800 | SpeedV5 | LuckyV3 |
| 9 | 36,826,436,800 | 166,168,965,600 | Royal Key5 | Super Ticket3 |
| 10 | 41,417,241,400 | 207,586,207,000 | Infinity Elixir1 | Infinity Elixir1 |
| 11 | 46,008,046,000 | 253,594,253,000 | Mystery Box15 | Dice Key5 |
| 12 | 50,598,850,600 | 304,193,103,600 | MythicV2 | Golden Dice5 |
| 13 | 55,189,655,200 | 359,382,758,800 | SpeedV2 | SpeedEvolved3 |
| 14 | 59,780,459,800 | 419,163,218,600 | LuckyV3 | LuckyEvolved3 |
| 15 | 64,371,264,400 | 483,534,483,000 | Spin Ticket10 | Super Ticket5 |
| 16 | 68,962,069,000 | 552,496,552,000 | Mystery Box25 | LuckyEvolved1 |
| 17 | 73,552,873,600 | 626,049,425,600 | Royal Key10 | TicketsEvolved1 |
| 18 | 78,143,678,200 | 704,193,103,800 | CoinsEvolved3 | Golden Dice5 |
| 19 | 82,734,482,800 | 786,927,586,600 | LuckyEvolved3 | Dice Key10 |
| 20 | 87,325,287,400 | 874,252,874,000 | Infinity Elixir2 | Infinity Elixir2 |
| 21 | 91,916,092,000 | 966,168,966,000 | MythicEvolved3 | Super Ticket10 |
| 22 | 96,506,896,600 | 1,062,675,862,600 | CoinsEvolved3 | MythicEvolved2 |
| 23 | 101,097,701,150 | 1,163,773,563,750 | SpeedEvolved3 | SpeedEvolved2 |
| 24 | 105,688,505,750 | 1,269,462,069,500 | Mystery Box50 | LuckyEvolved3 |
| 25 | 110,279,310,350 | 1,379,741,379,850 | Infinity Elixir3 | Infinity Elixir3 |
| 26 | 114,870,114,950 | 1,494,611,494,800 | Royal Key25 | Dice Key15 |
| 27 | 119,460,919,550 | 1,614,072,414,350 | SpeedEvolved5 | Golden Dice10 |
| 28 | 124,051,724,150 | 1,738,124,138,500 | MythicEvolved5 | MythicEvolved5 |
| 29 | 128,642,528,750 | 1,866,766,667,250 | LuckyEvolved5 | LuckyEvolved5 |
| 30 | 133,233,333,350 | 2,000,000,000,600 | Cerberus1 | Security System1 |

Reward summaries preserve native quantities; level6means Evolved. Stage1 [reward evidence](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md) and native `WorldRewards:157–178,267–305` establish the next-tier-only cost/space/world=true UI guards and `ClaimWorldReward(worldName)` shape. There is no arbitrary target-tier argument and no free collect-all interpretation. Actual `Progress` determines which rows remain. A tier30pet is useful only if the resulting best feasible owned team improves after its complete remaining package; a player already owning stronger eligible pets can receive no earning gain.

For a fresh account still saving for native Minigame Paradise1bCoins, the first World Reward costs100mCoins and declares a base100Coins reward, with no direct earning capability in that row. Actual server/account reward scaling is unknown. If actual supported creditedCoins remain below100m and no separate package benefit applies, paying it delays the world target and has negative immediate currency return. Tier2 alone costsabout4.691bCoins plus tier1; five keys need their own useful opportunity/pool/entry costs to justify this. Later consumables may have value for an advanced account, but ownership of a large balance does not make their marginal return positive. The corresponding Minigame track spends Tickets, not Coins; do not invent a currency exchange rate.

Paid tier evaluation: `packageCost=sum(unowned tier prices)`, `packageBenefit=useful reward utility + supported earning/time benefit + explicit milestone/quest overlap`. Do not value nominal reward counts as liquid currency. A final pet's fixed catalog label is not an upgrade over best-owned inventory. Protect the next useful world, known upgrade costs and finite consumable budgets first.

## Daily gifts and scarce Stars

Native `Shared.Data.DailyRewards:8–14` after the full gap reread:

| Day | Native saved gift |
|---:|---|
|1|Ultra Infinity Elixir1|
|2|Infinity Elixir10|
|3|Lucky level7 quantity3|
|4|Speed level7 quantity3|
|5|Mythic level7 quantity3|
|6|Secret Elixir3|
|7|Infinity Elixir10 + Secret Elixir10 + Egg Elixir10|

Received `DailyRewards.LastDay,LastStreak,Claimed,Stars` and native absolute day/midnight calculations411–473 govern UI status. `DailyRewardClaimStars()` at542, `DailyRewardsBuyItem(itemKey)` at376 and `DailyRewardsForfeitStreak()` at530 are distinct actions. The wiki agrees with UTC-midnight and10*streak Stars capped200/day, but its exact24-hour missed-login/recovery59Robux description is **EXTERNAL_ONLY**; server rollover and recovery were not verified. Streak forfeit is destructive and not part of routine research or claim policy.

The full native `Shared.Data.StarsShop:8–35` has28entries:

| Native offer group | Exact Stars cost | Source lines |
|---|---:|---|
|Mystery Box1|20|8|
|Reroll Orbs5; Golden Key1|10each offer|9–10|
|Royal Key1|40|11|
|Lucky/Speed/Coins/Mythic IV1each|10each|12–15|
|Lucky/Speed/Coins/Mythic V1each|30each|16–19|
|Lucky/Speed/Coins/Mythic Evolved1each|100each|20–23|
|Lucky/Speed/Coins/Mythic Infinity1each|500each|24–27|
|Infinity/Secret/Egg Elixir1each; Shadow Crystal1|750each|28–31|
|Green Fragment1|2,000|32|
|Blue Fragment1; Purple Fragment1|2,500each|33–34|
|Rainbow Fragment1|3,500|35|

Item labels do not imply equal usefulness. Compare supported boost magnitude, duration after Mastery/milestones, compatibility, current family queue, objective, available eggs/spend/storage, and loss of future Star access. A10Star SpeedIV potion is attractive only if hatch throughput is the binding objective; a coin potion needs real measurable collectible/sell activity during its window. Fragment marginal value requires current used counts/caps and completion perks; no fragment is assumed fresh/needed. A key needs a live corresponding chest and a useful pool. Claiming due Stars has little resource cost; buying with them is a separate scarcity decision.

## Playtime: nine due gifts, no certified final odds

Native `Shared.Data.Playtime:37–40` gives `(seconds,displayLuck)`120/1,180/1,240/1,300/1,450/5,900/5,1800/5,3600/20,5400/20, corroborated by the actual article. Early2/3/4/5minute gifts need no marginal hatching investment beyond actual Playtime capability. Last two gifts are60/90minutes. A session with90minutes naturally planned can collect more opportunities; staying solely for an unknown reward requires an explicit horizon comparison.

Claim index is a string-keyed claimed map, not count+1 (`Client.Gui.Frames.Playtime:99–135`). The individual call is `ClaimPlaytime(index)` Invoke at369–376; bulk `ClaimAllPlaytime()` Fire446 has a UI visibility threshold of at least4eligible gifts191. This does not prove a server minimum. Trading Plaza disables this module41–44. UI returned spinner filler and article probabilities are not final grants. Native display luck affects only Legendary/Secret items223–240; other account bonuses/currency scaling and server draw rules remain unresolved.

A later claim recommendation should require fresh Start/Claimed, exact due index, inventory room if relevant, no conflicting reward presentation, and actual claimed+reward delta. Article pool changes in updates22and53 demonstrate version drift; their dates are chronology only. Received deadlines and maps take precedence over a remembered schedule/reset assumption.

## Free area chests versus key-consuming Rift chests

Native `Shared.Data.Chests:13,23,31,41,55–56` base definitions:

| Name | Base seconds | Rolls | Declared base currency |
|---|---:|---:|---|
|Giant|900|3|500Coins|
|Void|2400|4|3,000Gems|
|Ticket|1800|4|3,000Tickets|
|Peppermint|900|4|75,000Snowflakes|
|Halloween|5400|10|500,000Candycorn26|
|Infinity|600|5|750Coins; empty built pool|

A claim's final return can differ from base values; retained event names do not establish live spawning. Use actual `Cooldowns[chestName]`, AreasUnlocked and Workspace spawned object/range. Physical `ClaimChest(name)` and map `ClaimChest(name,true)` have different native paths. Map quick collection is a Mastery convenience; it does not itself increase credit or create availability. Travel/setup lost farming can exceed a small base reward. Halloween must be supported by actual event object/state, not a Fall/Christmas table. Key-consuming chest evaluations include scarce key price/opportunity cost, useful reward distribution and rift lifetime; larger batching capacity is not a reward multiplier.

## Wheel tickets: claim and redemption are separate

Actual article agrees with the saved8reward labels/weights and one Spin Ticket per play, but presents percent-looking numbers that sum99. Native `Shared.Data.WheelSpin:8–15` has45,20,14,10,4,3,2.9,.1. Under a hypothetical normalized literal-weight draw, coin expectation=(45*200+20*450)/99≈181.818Coins, pet chance=.1/99, and expected returned tickets=5*2.9/99≈.146465. These are conditional derivations; article display percentages do not certify server odds. The missing1weight remains unresolved.

Native `WheelSpin:358–375,400–412,595–609` separates due free-ticket collection (`ClaimFreeWheelSpin`) from paid ticket redemption (`WheelSpin()` Invoke266) and queue settlement (`ClaimWheelSpinQueue()` Fire106). Base free cooldown1,200s is only a catalog constant; received NextWheelSpin controls actual due state. Minigames3auto-claims free tickets as convenience, without making spins free to redeem or increasing rewards. Queue result/actual credit must be verified;6second animation is not server cooldown or proof of grant. Never purchase Robux tickets as a default research strategy.


## Vendors: buy useful demand, not catalog stock — batch M3

Actual parent-browser [Shops](https://bgs-infinity.fandom.com/wiki/Shops) body and Overworld table corroborate6hBlackmarket,20minAlien,8hTravelingMerchant and8hShadow base timers. Other world/event tabs were not fully reviewed; this is not an exhaustive live shop registry. [Stage1 shop research](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md) adds exact IDs/predicates, dice/fishing/temporary rift vendors and Halloween catalogs. Article item counts are catalog breadth, not current stock.

| Native candidate | Entry knowledge | Scarcity and stop conditions |
|---|---|---|
|alien-shop|Zen nonnil area;20min base; GoldenKey3kGems / MysteryBox15k examples|Actual slots/live access/fresh Period/Bought/demand; key still needs chest|
|shard-shop:Blackmarket|Pets9received upgrade;6h base;EvolvedLucky/Coins1.1mGems,Mythic/Speed1.25m|Compare owned potion queue, Star alternatives and protected Gems; price is not earning gain|
|traveling-merchant|8h base; native UI weekend handling inUTC|Actual availability/offer; local weekday differs fromUTC|
|dice-shop|Minigame nonnil world predicate;2h base|World access/productive authorized plan/exact Tickets budget|
|fishing-shop|6h base|SevenSeas/area/level/path; useful fishing materials;Pearls separate|
|shadowrift/corruptshadow-shop|2h/4h base; temporary rift|Live lifetime/entry/setup/remaining stock|
|hw26rebirth/spooky-shop|4days/1day base;14/12slots;Rerollablefalse|Live Halloween/native schemas;distinctHalloweenShards/Candycorn26 reserves;reset protected|

Native ShopUtil108–223 uses Period, upgrade state and identity-seeded offer construction. No identity/seed values were recorded. ItemShop324subtracts Bought from stock. Compare actual product/cost to a protected budget and useful quantity. BuyShopItem(id,slot,false) is the single path; true requests all, with no supported custom quantity. BuyAll affordability226–239can consume the entire balance. Reconcile Bought/currency/product deltas before any future retry.

Free-reroll quota uses received InstantRestock and milestone refreshes (ShopUtil91–106). Free does not imply positive value: refreshing destroys current offers. Preserve wanted finite stock and current progress; unknown new-offer distributions cannot justify a confident reroll advantage. Paid restock prompts are separate and excluded.

The ordinary discount estimate is round(basePrice*(sale?.75:1)*(1-min(dayDiscount+milestoneDiscount,.95))), with category-specific handling18–52/163–164. Native refresh is round(base/(masteryScalar+milestoneRefresh)). Stock220appears to add two baselines; keep it a fidelity limit. Actual stock/deadlines outrank an optimistic forecast. Buying unwanted cheap items merely to gain future milestone discounts incurs their full opportunity cost.

## Genie: choose useful overlapping offers

Actual [Gem Genie](https://bgs-infinity.fandom.com/wiki/Gem_Genie) and [Quests](https://bgs-infinity.fandom.com/wiki/Quests) bodies were read by the parent. Three offers/chooseone/20Orb reroll/2–3objectives corroborate native UI/constants. Basehour and example task amounts are not current account offers; actual Next/Seed/tasks/filters govern. Loot labels are not final server odds. A milestone cooldown100% does not establish zero server wait.

GenieQuest17–18,61–119 defines taskcount2/3weights60/40 and additional-reward-count1/2/3/4weights40/35/20/5, plus base Gem reward. Under literal normalized choices the means are2.4tasks and1.9additional picks; those means do not rank actual offers. UI238–245generates Seed+index−1. Suspicious completion-count<−1branch68 is not repaired into a fresh-account policy.

Choose by remaining effort and total effective time, not largest displayed Gems. Currency collection may align with the protected farm goal; bubbles with an already authorized workflow; filtered hatches require exact rarity/name/egg/variant, cost and safe room. Obby/minigame/fishing tasks need actual entry/level/cooldown and authorization. Task times are neither automatically additive nor automatically overlapping: construct a feasible schedule with exclusive travel/presentation and compatible counter progress.

A reusable comparison is incremental useful reward + supported milestone increment − spend/materials − lost goal earnings − sacrificed progress. Reroll value is expected best newoffer − current bestoffer −20Orbs opportunity value − setup/progress loss. No known distribution here supports a numeric positive reroll value. ChangeGenieQuest can replace progress; RerollGenie includes GreenFragment-task warnings. A stale offerindex after Seed changes identifies a different candidate.

No arbitrary general ClaimQuest contract was established. Achievement Prize is distinct from ordinary completion. Verify task completion plus actual Gem/item credit and Next, rather than a local completed bar.

## Milestones: latest buffs and exact native suffixes

Actual [Milestones](https://bgs-infinity.fandom.com/wiki/Milestones) body, full visibleBubbling table and top two published tiers across all16category tabs were reviewed by the parent. Every wiki row was **not** read. Four native categories were additionally reviewed completely for64thresholds: Hatching86–152,Genie153–179,Playtime218–301,Shops420–496. Native includes OmegaIII beyond the published comparisons.

Tables normalize thresholds/declared numeric buffs only; item/title rewards can add separate useful value. MilestoneUtil125–174 retains special flags/titles but selects each category's latest numeric buffs; do not sum old rows. QuestUtil37–52 returns raw Amount; Playtime builder29–38 does not multiply it and FormatTask149–150 uses real-time formatting. Server counting/grant/skip acceptance remains unverified.

### Hatching native thresholds

| Requirement | Declared numeric buff fields | Returned line |
|---:|---|---:|
| 500 | Luck=5 | 88 |
| 1,500 | Luck=5; HatchSpeed=5 | 88 |
| 7,500 | Luck=10; HatchSpeed=5 | 89 |
| 25,000 | Luck=15; HatchSpeed=10; EggCost=5 | 93 |
| 50,000 | Luck=20; HatchSpeed=15; EggCost=5 | 94 |
| 75,000 | Luck=25; HatchSpeed=15; EggCost=10 | 95 |
| 150,000 | Hatches=1; Luck=35; HatchSpeed=20; EggCost=15 | 98 |
| 350,000 | Hatches=1; Luck=50; HatchSpeed=25; EggCost=15 | 99 |
| 500,000 | Hatches=1; Luck=75; HatchSpeed=30; EggCost=20 | 100 |
| 2,500,000 | Hatches=2; Luck=150; HatchSpeed=35; EggCost=25 | 101 |
| 5,000,000 | Hatches=2; Luck=175; HatchSpeed=40; EggCost=30 | 105 |
| 7,500,000 | Hatches=2; Luck=225; HatchSpeed=50; EggCost=35 | 115 |
| 15,000,000 | PetEquips=1; Hatches=3; Luck=300; HatchSpeed=75; EggCost=50 | 125 |
| 40,000,000 | PetEquips=1; Hatches=3; Luck=350; HatchSpeed=100; EggCost=60 | 135 |
| 100,000,000 | PetEquips=1; Hatches=3; Luck=400; HatchSpeed=125; EggCost=65 | 141 |
| 200,000,000 | PetEquips=1; SuperLegendaryEquips=1; Hatches=3; Luck=450; HatchSpeed=140; EggCost=70 | 147 |

### GemGenie native thresholds

| Requirement | Declared numeric buff fields | Returned line |
|---:|---|---:|
| 1 | GemGenieCooldown=5 | 155 |
| 3 | GemGenieRewards=10; GemGenieCooldown=5 | 156 |
| 5 | GemGenieRewards=25; GemGenieCooldown=10 | 160 |
| 8 | GemGenieRewards=50; GemGenieCooldown=15 | 161 |
| 12 | GemGenieRewards=75; GemGenieCooldown=20 | 165 |
| 15 | GemGenieRewards=100; GemGenieCooldown=25 | 166 |
| 25 | GemGenieRewards=125; GemGenieCooldown=30 | 168 |
| 75 | GemGenieRewards=150; GemGenieCooldown=45 | 170 |
| 150 | GemGenieRewards=200; GemGenieCooldown=60 | 171 |
| 250 | GemGenieRewards=300; GemGenieCooldown=75 | 173 |
| 500 | GemGenieRewards=350; GemGenieCooldown=85 | 176 |
| 1,000 | GemGenieRewards=375; GemGenieCooldown=100 | 177 |
| 2,500 | GemGenieRewards=400; GemGenieCooldown=100 | 178 |

### Shops native thresholds

| Requirement | Declared numeric buff fields | Returned line |
|---:|---|---:|
| 25 | ShopRefreshCooldown=5; ShopItemDiscount=5 | 422 |
| 50 | ShopRefreshCooldown=5; ShopItemDiscount=10 | 423 |
| 75 | ShopRefreshCooldown=7.5; ShopItemDiscount=10 | 424 |
| 125 | ShopRefreshCooldown=10; ShopItemDiscount=12.5; ShopStock=5 | 427 |
| 150 | ShopRefreshCooldown=12.5; ShopItemDiscount=15; ShopStock=5 | 428 |
| 175 | ShopRefreshCooldown=15; ShopItemDiscount=17.5; ShopStock=7.5 | 429 |
| 225 | ShopRefreshCooldown=17.5; ShopItemDiscount=20; ShopStock=7.5 | 432 |
| 250 | ShopRefreshCooldown=20; ShopItemDiscount=20; ShopStock=7.5 | 433 |
| 300 | ShopRefreshCooldown=20; ShopItemDiscount=25; ShopStock=10; ShopFreeRefreshes=1 | 440 |
| 500 | ShopRefreshCooldown=25; ShopItemDiscount=25; ShopStock=15; ShopFreeRefreshes=1 | 449 |
| 750 | ShopRefreshCooldown=25; ShopItemDiscount=30; ShopStock=20; ShopFreeRefreshes=2 | 459 |
| 2,000 | ShopRefreshCooldown=35; ShopItemDiscount=35; ShopStock=25; ShopFreeRefreshes=3 | 469 |
| 7,500 | ShopRefreshCooldown=50; ShopItemDiscount=50; ShopStock=25; ShopFreeRefreshes=4 | 479 |
| 10,000 | ShopRefreshCooldown=60; ShopItemDiscount=60; ShopStock=30; ShopFreeRefreshes=4 | 485 |
| 20,000 | ShopRefreshCooldown=70; ShopItemDiscount=70; ShopStock=30; ShopFreeRefreshes=5 | 491 |

### Playtime native thresholds

| Requirement | Declared numeric buff fields | Returned line |
|---:|---|---:|
| 1,800 seconds | Currency=5 | 220 |
| 5,400 seconds | Currency=10 | 221 |
| 10,080 seconds | Currency=15 | 222 |
| 28,800 seconds | Currency=20; SeasonPassPoints=5 | 225 |
| 36,000 seconds | Currency=25; SeasonPassPoints=5 | 226 |
| 48,000 seconds | Bubbles=5; Currency=35; SeasonPassPoints=5 | 227 |
| 57,600 seconds | Bubbles=10; Currency=40; SeasonPassPoints=10 | 230 |
| 86,400 seconds | Bubbles=15; Currency=45; SeasonPassPoints=10 | 231 |
| 97,920 seconds | Bubbles=20; Currency=50; SeasonPassPoints=10 | 232 |
| 129,600 seconds | Bubbles=25; Currency=65; SeasonPassPoints=15 | 235 |
| 172,800 seconds | Hatches=1; Bubbles=25; Currency=75; SeasonPassPoints=15 | 236 |
| 216,000 seconds | Hatches=1; Bubbles=30; Currency=100; SeasonPassPoints=20 | 237 |
| 259,200 seconds | Hatches=1; Bubbles=35; Currency=125; SeasonPassPoints=22.5 | 242 |
| 302,400 seconds | Hatches=1; Bubbles=40; Currency=135; SeasonPassPoints=25 | 248 |
| 345,600 seconds | Hatches=1; Bubbles=45; Currency=150; SeasonPassPoints=30 | 254 |
| 691,200 seconds | Hatches=1; Bubbles=50; Currency=175; SeasonPassPoints=35 | 264 |
| 1,382,400 seconds | Hatches=2; Bubbles=75; Currency=200; SeasonPassPoints=50 | 274 |
| 2,500,000 seconds | Hatches=2; Bubbles=90; Currency=250; SeasonPassPoints=60 | 284 |
| 4,000,000 seconds | Hatches=2; Bubbles=100; Currency=275; SeasonPassPoints=65 | 290 |
| 7,000,000 seconds | Hatches=2; Bubbles=120; Currency=300; SeasonPassPoints=65 | 296 |

Hatching100m'sHatches3/Luck400/Speed125/Cost65 agrees with publishedOmegaII, but native200maddsOmegaIII147–149. Genie1000'sRewards375/Cooldown100 agrees, but native2500addsRewards400 at177–178. Shops10k'srefresh4/cooldown60/discount60/stock30 agrees, but native20khasrefresh5/cooldown70/discount70 at485–493. NativePlaytimeOmegaI2.5mseconds≈28.94days/Currency250;OmegaII4m≈46.30days/Currency275;OmegaIII7m≈81.02days/Currency300 (284–298). WikiOmegaII92days/Currency175 is a version conflict, not a negative native upgrade. Blank top-tier tasks inFishing/Obby/Fusing are unknown requirements.

A close milestone's value is the difference from current latestbuff + useful rewards − full remaining task cost/time. Native150kHatches opensHatches1/Luck35/Speed20/Cost15; this does not justify150kpaid eggs for every fresh player. EggCost divides by1+field thenceil (StatsUtil197–225), so65%field means≈39.39% lower isolated base price, not65% subtraction. Actual GenieNext governs unknown server cooldowns. Shop perks need useful demand; Playtime during otherwise useful time has less incremental cost than extending a session solely for its reward.

## Index: selective completion and discovered history

Actual [Index](https://bgs-infinity.fandom.com/wiki/Index) body describes traded pets not counting, normalcompletionLuck50/Shiny50 and shinycompletionMythic50 for listed world eggs, with separateMythic/XL rewards. The final cross-ledger review resolved the numeric input gap: [E-C043](evidence/EGG_CLAIMS.jsonl) records Constants66's50Percent fields and StatsUtil803–807/1270–1272/1970–1972 consumers attaching normal completion to Shiny/Luck and Shiny completion to Mythic, with a Christmas exception in the first two. These are NATIVE_CORROBORATED inputs;50Percent is not50percentage points of final probability. Exact eligible egg/world scope, final server application and traded discovery-credit rules remain unresolved. Native IndexUtil13–45,47–75,97–139 establishes discovery distinct from current ownership. Its reconstructed counter34is damaged; exclude-Secret requirements versus found counting need caution.

EggPrizeClaim(eggName,isShiny)391, ClaimEventPrize(eventName,mode)534, ClaimIndex(worldOrEventName,mode)2351 and ClaimXLIndexRewards(taskKey)inXLIndex292 have separate argument/key schemas. Preserve optional claimedprefixes and XL claimedarray. A guessed Shared.Utils.GetIndexReward path was not found and supplied no evidence; do not infer a missing system or contract from it.

First evaluate genuinely completed/unclaimed rewards. Then prioritize cheap missing discoveries that also serve a useful hatch/team/quest goal. A removed-event set or rare lastmissing pet can dominate remaining cost. Under verified independent missing probabilities p_j, expected attempts for a missing set are sum over nonempty subsets A of (−1)^(|A|+1)/(sum(j inA)p_j), the nonuniform coupon-collector expression. Final probabilities are unavailable here, so it is an explanatory model, not a personalized estimate. Raw percentage complete is not remaining expense. Duplicates may serve team/recipe/quest goals; no trading/social actions are proposed.

## Challenge tracks and finite horizons

Exact /Challenge_Pass body was unavailable; no article fact came from snippets or an inferred title. Native ChallengePassautumn ends2026-10-02UTC (Data11–27), expired relative to researchdate. Its15thresholds use50*round(20000*(tier/15)^2/50)43; final20kPoints. Reset min(2^GemResets*10m,200m)60–67 is protected spend, separate from claim. Owner-reported Halloween does not make this retained track active.

The Quests body lists historical limited systems and a LikeGamecard/prose inconsistency200vs500likes. These do not establish executable contracts or authorize invites/likes/groups/Discord. SeasonPass/challenge/activequest/event currencies remain separate. A feasible finite plan includes remaining taskspend/time/points/expiry; if completion cannot fit, skip. Reward and earning overlap must use one counterfactual, avoiding duplicated value claims.

## Infinity chest: effective composite differs from base

New full native GetInfinityChest1–69 starts base600s/Rolls5/750Coins, enumerates actual Rendered.Chests excludingInfinity26–35, includes names withoutIsland or with unlockedAreasUnlocked[Island], divides sourcePoolChance by1+includednames44, appends rewards46–48, sumsRolls and takes maximum basecooldown49, combinesRewards65. LootPoolViewer980–982actuallyuses this helper.

Thus wiki34minutes cannot be flatly contradicted by bare600s. Composite state and downstream perks/server deadlines matter;34minutes is VERSION_DEPENDENT/NEEDS_LIVE_VERIFICATION. Includednames can contain a name later lacking catalog data, so do not repair the count or treat resulting labels as final normalized odds. Fresh Cooldowns and actual credits govern later eligibility/return; no VIP purchase was proposed.

## Conditional priorities and central ownership

| Situation | Useful next assessment | Skip/defer trigger |
|---|---|---|
|Fresh/world saving|Best-owned equip correction; freePets1; alreadydueDaily/Playtime/freewheel with low interruption|Paid tier/vendor delays world; access/claim unknown|
|Middle/farming|Due nearby/mapchests; filteredGenie already advanced by actualgoal; useful Stars potion timed to activity|Travel/lost earning too high; queue/incompatibility/budget; wantedstock lost|
|Advanced/suffix milestone|Remaining threshold effort versus latestbuffdelta/rewards; bounded vendor/Index package|Unknown odds/rare lastpet; strong ownedteam/no neededitem; short horizon|
|Timed event|Actual registry/deadline/currency/spawnedfacility; authorized overlaps|Historicaltable/unknownactivity/expiry/protectedreset|
|Any|Fresh receipt/reconciliation after later economic action|Animation-only success/stalePeriodSeed/no debitgrant/orphaned queue|

Mastery/rewardsPhase5; vendor/quest/consumablePhase6; Rift/board/fishingPhase7; seasonPhase8; hybrid overlapPhase9. Research changes no runtime ownership. GameKnowledge/readercache, LocalData, world observations, mechanics verification and OCBrain/TaskScheduler own eventual integration. No competing loops or spending approval were created.

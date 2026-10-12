# Mastery and equipment research — batch 3
Research date 2026-10-11. Native paths below start at `ReplicatedStorage`. All confirmed claims refer to saved, decompiled source, not a live server test. No purchases or module execution performed.

## Mastery schema and selection
`SOURCE_CONFIRMED`: `Shared.Data.Mastery:18–77,78–276` returns `{Types, Upgrades}`. Category entries have `LayoutOrder, Icon, Levels` and optional `ShouldShow(account)`; each indexed level has an item-shaped `Cost`, `Upgrades[]`, optional `UnlockEarly(account)`. Effects discriminate by `Type`, with `Buff={Type="Value"|"Percent",Value}`, `Level`, `Amount`, `Every` or `Action`. Named types are not scalar currency multipliers by themselves.

`SOURCE_CONFIRMED`: `Client.Gui.Frames.Mastery:539–568,602` reads `LocalData:Get()`, selects `Upgrades[category].Levels[(MasteryLevels[category] or 0)+1]`, optionally replaces its price with free Coins when `UnlockEarly` returns true, checks owned amount against item cost and then calls the network facade `FireServer("UpgradeMastery", category)`. There is no tier/index/cost argument. The client selects the next tier; server sequencing, location and validation remain `UNAVAILABLE`. Visibility uses `ShouldShow` in the UI at 257 onward; this does not prove server eligibility.

`SOURCE_CONFIRMED`: `Shared.Utils.Stats.MasteryUtil:197–209` retrieves a matching upgrade from received `account.MasteryUpgrades`; this is preferable to adding every historical catalog tier. `GetUpgrades:45–79` traverses purchased tiers and early unlocks but its reconstructed replacement logic does not update stored `Level` when replacing an upgrade (68–70). Order-dependent outcomes in the decompiled helper are therefore uncertain. Treat catalog values as tier replacement candidates until the effective native helper/received upgrades verifies semantics.

## Selected high-value catalog tiers
Every row is `SOURCE_CONFIRMED` static definition; no claim of currently affordable/unlocked/beneficial.

| Category/tier | Native cost | Effect | Returned source line |
|---|---:|---|---:|
| Pets 1 | 0 Coins | Playtime capability | Mastery:125 |
| Pets 2 | 10,000 Coins | GoldenEgg Every=0; describes shiny ability | 126 |
| Pets 3 | 85,000 Coins | Equips Value=1; PetXP Percent=5 | 127 |
| Pets 4 | 250,000 Coins | GoldenEgg Every=75; Lucky II for 120s | 128 |
| Pets 6 | 1,000 Gems | DarkArts | 130 |
| Pets 7 | 2,500 Gems | StatEgg; Team Value=1 | 131 |
| Pets 8 | 5,000 Gems | Storage Value=150; PetXP Percent=20 | 132 |
| Pets 9 | 15,000 Gems | Blackmarket; WorldMap | 133 |
| Pets 10 | 75,000 Gems; early legacy pass predicate | MultiEgg Value=1 | 110–123,134 |
| Pets 11 | 175,000 Gems | Equips=2, Storage=300, Lucky III for 300s | 135 |
| Pets 12 | 450,000 Gems | HatchSpeed Percent=10; PetXP Percent=35 | 136 |
| Pets 14 | 2,500,000 Gems | Equips=3; Storage=500 | 138 |
| Pets 15 | 7,500,000 Gems | MultiEgg Value=2 | 139 |
| Buffs 6 | 1,250,000 Coins | PotionCrafting Level=3; PotionDuration Percent=15 | 87 |
| Buffs 14 | 1,250,000 Gems | PotionDuration Percent=25; MultiPotion | 95 |
| Buffs 15 | 2,500,000 Gems | QuickCollect Action=Single; ItemCrate Level=3; AutoMysteryBox | 96 |
| Buffs 16/20/25 | 15m/100m/1.25b Gems | MultiChest Amount=5/10/25 | 97,101,106 |
| Buffs 17 | 45m Gems | EfficientOrbs Percent=10; RiftNotification | 98 |
| Buffs 21 | 250m Gems | AutoClaimChest (Rift description) | 102 |
| Shops 5 | 40,000 Gems | ShopSlots=1; InstantRestock=1 | 158 |
| Shops 10 | 2m Gems | InstantRestock=3; Sale Percent=100 | 163 |
| Shops 11 | 5m Gems | BuyAll | 164 |
| Rifts 1/2/3/4 | 5m/35m/125m/1b Gems | Summon/Shards; +25% shard luck; radar levels1/2 | 190–193 |

`SOURCE_CONFIRMED`: native categories include Buffs (25 tiers), Pets (23), Shops (11), Minigames (8), Rifts (4), Christmas (14), Easter (15), Summer (15), from Mastery:78–276. Seasonal `ShouldShow()` returns false for Christmas/Easter/Summer at 197–203,222–228,248–254. They must not be candidates based on catalog presence. Minigames `ShouldShow(account)` tests `WorldsUnlocked["Minigame Paradise"] ~= nil` at 178–184; preserve the exact non-nil source test rather than pretending it is proof of travel access.

## Equipment definitions and economic meaning
`SOURCE_CONFIRMED`: `Shared.Data.Gum:10–29` entries carry `Storage, Area, Cost`; some `Cost` values are numeric gamepass IDs, others item-shaped Currency costs. `Shared.Data.Flavors:39–54` entries carry `Bubbles, Area, Cost`, plus visual fields. Never parse a numeric product/pass ID as a currency price.

Examples: Stretchy Gum costs25 Coins for45 storage (Gum:13), Cosmic Gum125,000 Coins for12,500 (19), Experiment #52 costs1b Coins for1.5m (25), Void Gum95b Coins for10m (26). Blueberry flavor25 Coins for3 Bubbles (Flavors:41), Donut1.5m Coins for400 (49), Molten350m Coins for1,450 (51). These are base definitions, not measured per-minute income.

`HYPOTHESIS` mathematical model for a required bubble objective: let actual fill throughput b be bubbles/s, capacity K, verified travel/sell latency s, and verified sell return m currency/bubble. Continuous cycle earning rate is approximately `m*K/(K/b+s)` currency/s before other bottlenecks. Increasing capacity helps only by reducing overhead; increasing flavor may help b but is diluted by pets/other bonuses. With stationary pickup-only farming and no bubble goal, neither capacity nor base flavor is evidence of increased pickup income. Do not enable bubbling solely to justify an upgrade.

## Payback and prerequisite budgeting
`HYPOTHESIS`: an upgrade package's price is the sum of all unowned prerequisite tier costs by currency, not just the attractive target tier. Re-evaluate after each received `MasteryLevels/MasteryUpgrades` delta. Where rates are stable, same-currency net payback is `packageCost/(newNetRate-oldNetRate)`; undefined/nonpositive differences are not a finite payback. Include travel, setup, buff lifetime, future unlock utility and lost goal progress in a horizon model. Do not convert Coins/Gems/Tickets/Pearls at an invented exchange rate.

Equip increases are high potential value when the best feasible owned team has strong unused pets; extra slots with no useful pets can have little immediate return. Hatch speed/multi-eggs accelerate expenditure as well as outcomes. Storage is valuable at a real capacity bottleneck. Magnet upgrades cannot be assumed to improve the owner-tested stationary ID collector merely because they improve ordinary pickup range.

No reserve overrides designed or implemented. Any future reserve exception needs owner authorization, verified costs, supported marginal benefit and a protected budget.

## Verification and limits
Recommended verification (`HYPOTHESIS`, future owner testing): exact category level rises one expected tier; currency/item cost changes consistently; received upgrade matches its type; effective relevant helper changes; subsequent comparable earning/hatch measurements establish real benefit. Purchase particles/animation are not success: Mastery UI starts effects before FireServer at569–602.

Unknown: authoritative station/proximity requirements, server rate limits, live category visibility, server discount/legacy entitlement processing, cumulative vs replacement behavior where decompilation is ambiguous, true marginal earnings on this account. Physical access is documented separately by navigation research. No owner live test of these actions was performed this session.


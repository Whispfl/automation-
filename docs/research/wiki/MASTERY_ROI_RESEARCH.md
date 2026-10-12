# Mastery ROI research

Stage 2, 2026-10-11. This document compares accessed external page bodies with saved native evidence and derives conditional investment strategies. Phase approval, actual account choices and live verification remain separate. Version conflicts and protected resource commitments are retained.

## Native baseline and decision rule

Stage 1 supports eight Mastery branches: Buffs25 tiers, Pets23, Shops11, Minigames8, Rifts4, Christmas14, Easter15, Summer15. The three seasonal branches have ShouldShow=false in the saved native definition. Minigames visibility requires a nonnil received Minigame Paradise unlock; UI visibility is not server/travel eligibility. Native purchase requests only the category and selects the next tier from actual MasteryLevels. Native costs and received MasteryUpgrades govern a later decision; do not sum every historical replacement buff. See ../replicatedstorage/MASTERY_AND_UPGRADES.md and ROOT_SOURCE_LEDGER.md.

Evaluate all unowned prerequisites as a currency-separated package. Compare marginal best-feasible-owned-team utility, reachable newly opened capabilities, measured rate improvement, claim convenience and total effective time against saving for the next useful world. A tier can be unaffordable, irrelevant, dominated or unable to repay within its usable horizon. Increasing hatch count/speed increases potential spending; extra equips need worthwhile unused owned pets. Pickup magnetism has no demonstrated rate benefit for the preserved stationary collector. No reserve exception or universal purchase order follows from catalog descriptions.

External source/claim registries and completed batches are linked below.

## Evidence and reconciliation — batch M1

Actual modern [Mastery article](https://bgs-infinity.fandom.com/wiki/Mastery) body and all eight tab tables were read by the parent browser on 2026-10-11 (M-S005; parent relay, revision date unavailable). My browser surface was unavailable and the web reader returned402. Two older [data pages](https://bgs-infinity.fandom.com/wiki/Bubble_Gum_Simulator_INFINITY_Wiki:Data/Mastery) were directly read through the web reader, which reported a roughly1.5-year crawl age. Their tier counts are historical. Search-result excerpts are discovery only. Source and claim records are in [MASTERY_SOURCES.jsonl](evidence/MASTERY_SOURCES.jsonl) and [MASTERY_CLAIMS.jsonl](evidence/MASTERY_CLAIMS.jsonl).

A complete read-only reread of `ReplicatedStorage.Shared.Data.Mastery:1–276` supplied all115 tier costs and effect fields below. These tables summarize the saved native definitions, not the wiki article or server acceptance. Exact amounts take precedence over shorthand external prices. A repeated effect is a replacement candidate; do not add every row together. Actual received `MasteryUpgrades` and matching native consumers are necessary to resolve effective values (`Shared.Utils.Stats.MasteryUtil:45–79,197–209`; Stage1 Mastery document).

| Conflict/limit | External body | Saved native evidence | Decision |
|---|---|---|---|
| Pets3 | Modern/old article75,500 Coins | Mastery127:85,000 | CONTRADICTED_BY_NATIVE for this saved version; budget85,000 |
| Buffs6/14 prices | Modern shorthand1.2m | Mastery87/95:1,250,000 | Precision/version ambiguity; never substitute the shorthand amount |
| Buffs16 | Modern/old article capacity2 | Mastery97:Amount5 | CONTRADICTED_BY_NATIVE for this saved client capacity |
| Older Buffs20 | Cached data page capacity3 | Mastery101:10; modern article10 | Historical stale body; modern body corroborates native |
| Older Pets8/11/14 | Cached storage50/150/325 | Mastery132/135/138:150/300/500; modern body agrees | Historical values; do not use the stale table |
| MultiPotion | Modern article and native description say10 | Mastery50 versus Constants99/PromptBuilder201–224,526–553:client cap250 | Description/caller mismatch; actual server limit unknown |
| Pets15 wording | Article says an additional1 egg | Mastery139:MultiEgg Value2 versus tier10 Value1 | Potentially consistent as a marginal step; do not call this a contradiction or add1+2 |
| Old branch counts | Cached body20/15/10 | Native25/23/11; modern matches all8branches | VERSION_DEPENDENT, not proof that later tiers are currently eligible |

## All permanent branch tiers — native costs and conditional value

Amounts below are exact currency quantities. Each row's source is `ReplicatedStorage.Shared.Data.Mastery` at the listed returned line. Recommendation columns are **analytical hypotheses**, not owner approval or observed returns. Sequential purchase shape is `UpgradeMastery(category)`, selecting actual level+1; no target-tier or custom-cost argument (`Client.Gui.Frames.Mastery:539–568,602`). UI particles precede the request and cannot verify success.

### Buffs

| Tier | Native price | Native effect field | Conditional marginal value | Line |
|---:|---:|---|---|---:|
| 1 | 0 Coins | Walkspeed5%; free | Little stationary income value; free UI unlock | 82 |
| 2 | 5,000 Coins | Magnet5% | Low value unless measured reachable credits rise | 83 |
| 3 | 75,500 Coins | Walkspeed10% | Route convenience; prerequisite tax for later package | 84 |
| 4 | 150,000 Coins | Friendship5% per friend; Magnet8% | Zero friendship benefit with no friends; radius still unmeasured | 85 |
| 5 | 400,000 Coins | ItemCrate level1 | Only value actually reachable spawned crates; rate unknown | 86 |
| 6 | 1,250,000 Coins | CraftingIII; PotionDuration15% | Useful if compatible potion use/crafting is real, not merely planned | 87 |
| 7 | 950 Gems | Magnet12%; Walkspeed15% | Often prerequisite cost; movement remains activity-specific | 88 |
| 8 | 5,000 Gems | Friendship10% per friend | Same friend-count dependence; compare against other Gems uses | 89 |
| 9 | 15,500 Gems | CraftingIV | Requires ingredients, useful recipe and crafted result | 90 |
| 10 | 55,000 Gems | ItemCrate level2 | Do not price undefined extra crate chance as certain income | 91 |
| 11 | 95,000 Gems | CraftingV | Requires useful TierV recipe and consumable budget | 92 |
| 12 | 150,000 Gems | PotionDuration20% | Duration step is marginal; no benefit without useful potions | 93 |
| 13 | 350,000 Gems | Magnet12%; Walkspeed25% | Magnet is still12; only displayed walk step changes | 94 |
| 14 | 1,250,000 Gems | PotionDuration25%; MultiPotion | Duration and use convenience; no x10 power; client bulk cap differs | 95 |
| 15 | 2,500,000 Gems | QuickCollect Single; ItemCrate3; AutoMysteryBox | Potential travel savings for due chests; neither extra chest credit nor faster cooldown proven | 96 |
| 16 | 15,000,000 Gems | MultiChest Amount5 | Batching capacity; consumes more keys per action, no higher per-key value proven | 97 |
| 17 | 45,000,000 Gems | EfficientOrbs10%; RiftNotification | Orb preservation and notifications need actual use/horizon; eligibility/pool still matter | 98 |
| 18 | 75,000,000 Gems | Special enchant capability | Useful only with eligible pet and bounded enchant budget | 99 |
| 19 | 95,000,000 Gems | AutoRoll capability | Convenience/cancellation, no improved draw quality proven | 100 |
| 20 | 100,000,000 Gems | AutoEnchant; MultiChest Amount10 | Targeted auto capability+batch10; protect existing enchant value | 101 |
| 21 | 250,000,000 Gems | AutoClaimChest | Convenience if actual Rift chest use; no free keys/drop multiplier | 102 |
| 22 | 300,000,000 Gems | AutoBubble | May duplicate existing authorized bubble workflow; no new power buff | 103 |
| 23 | 400,000,000 Gems | CraftingVI | Ingredients, useful TierVI recipe and horizon must justify enormous package | 104 |
| 24 | 1,000,000,000 Gems | Atlas menu capability | Menu access convenience; no earning multiplier | 105 |
| 25 | 1,250,000,000 Gems | MultiChest Amount25 | Key batching convenience only; scarcity/expiry may make capacity useful | 106 |

### Pets

| Tier | Native price | Native effect field | Conditional marginal value | Line |
|---:|---:|---|---|---:|
| 1 | 0 Coins | Playtime capability; free | Take free capability only when native eligibility is verified; claim maps govern rewards | 125 |
| 2 | 10,000 Coins | GoldenEgg Every0; shiny ability description | Variant eligibility; avoids pretending every hatch becomes shiny | 126 |
| 3 | 85,000 Coins | Equips Value1; XP5% | Strong candidate if valuable owned pet is currently excluded by cap | 127 |
| 4 | 250,000 Coins | GoldenEgg Every75; LuckyII120s | Only useful with hatching; treat final guarantee/count/order as server limit | 128 |
| 5 | 500,000 Coins | XP10% | XP helps only a relevant unmaxed best-owned pet | 129 |
| 6 | 1,000 Gems | DarkArts | Potential variant option; unknown final probability cannot certify ROI | 130 |
| 7 | 2,500 Gems | StatEgg; Teams Value1 | Team switching/menu information; free equip improvement comes first | 131 |
| 8 | 5,000 Gems | XP20%; Storage Value150 | Storage if constrained; XP if useful unmaxed pet remains | 132 |
| 9 | 15,000 Gems | Blackmarket; WorldMap | Vendor+map unlock is optional future opportunity, not immediate income | 133 |
| 10 | 75,000 Gems | MultiEgg Value1; legacy entitlement predicate | Potential throughput increases spend too; balance/storage/max12 bind | 111 |
| 11 | 175,000 Gems | Equips2; Storage300; LuckyIII300s | Best-team extra slot plus storage/luck package; use received replacement semantics | 135 |
| 12 | 450,000 Gems | HatchSpeed10%; XP35% | Speed increment relative to existing factor, not universal ten-percent rate | 136 |
| 13 | 950,000 Gems | Teams Value2 | Extra saved team is primarily convenience | 137 |
| 14 | 2,500,000 Gems | Equips3; Storage500 | Extra marginal equip/storage; evaluate next-best owned pet | 138 |
| 15 | 7,500,000 Gems | MultiEgg Value2 | Capacity step is from effective1 to2, not summed to3 | 139 |
| 16 | 50,000,000 Gems | Teams3 | Saved team convenience only; do not invent raw stat gain | 140 |
| 17 | 200,000,000 Gems | Teams4 | Saved team convenience only | 141 |
| 18 | 500,000,000 Gems | Teams5 | Saved team convenience only | 142 |
| 19 | 750,000,000 Gems | Teams6 | Saved team convenience only | 143 |
| 20 | 1,000,000,000 Gems | Teams8 | Saved team convenience only | 144 |
| 21 | 2,000,000,000 Gems | Teams10 | Saved team convenience only | 145 |
| 22 | 3,000,000,000 Gems | Storage750 | Storage only at demonstrable bottleneck; expensive prerequisites | 146 |
| 23 | 4,000,000,000 Gems | Storage1000 | Storage only at demonstrable bottleneck; compare free cleanup/protection | 147 |

### Shops

| Tier | Native price | Native effect field | Conditional marginal value | Line |
|---:|---:|---|---|---:|
| 1 | 2,500 Gems | Sale chance10% | Expected sale benefit only on bought eligible offers | 154 |
| 2 | 6,500 Gems | Restock Percent10% | More frequent opportunity only if checked and needed | 155 |
| 3 | 7,500 Gems | Stock20% | Extra stock only if would otherwise run out | 156 |
| 4 | 15,500 Gems | Sale chance25% | Probability change, not25% off every item | 157 |
| 5 | 40,000 Gems | Slots+1; free restocks1 | Extra offer and reroll option can broaden useful access; do not refresh desired stock | 158 |
| 6 | 75,000 Gems | Restock20% | Native divisor shortens cooldown conditionally; not direct20% subtraction | 159 |
| 7 | 150,000 Gems | Stock30% | Demand/currency-bound stock can have zero realized benefit | 160 |
| 8 | 350,000 Gems | Sale chance50%; Restock35% | Sale+refresh package; measure useful purchases/opportunities | 161 |
| 9 | 750,000 Gems | Stock50%; free restocks2 | Stock and extra reroll option; preserve current wanted offer | 162 |
| 10 | 2,000,000 Gems | Free restocks3; Sale chance100% | Always eligible sale chance does not mean free items; discounts capped | 163 |
| 11 | 5,000,000 Gems | BuyAll capability | Convenience; boolean buys entire remaining slot, may violate bounded spend | 164 |

### Minigames

| Tier | Native price | Native effect field | Conditional marginal value | Line |
|---:|---:|---|---|---:|
| 1 | 20,000,000 Tickets | Cooldown Percent10% | Useful only after actual world access and repeated eligible play | 169 |
| 2 | 50,000,000 Tickets | Drops Value1 | Extra drops only if compatible minigame/reward consumer supports it | 170 |
| 3 | 100,000,000 Tickets | AutoClaimSpin | Convenience; due free-spin deadline still governs | 171 |
| 4 | 350,000,000 Tickets | Cooldown15% | Repeated play horizon; cooldown denominator and account perks matter | 172 |
| 5 | 750,000,000 Tickets | Drops Value2 | Marginal drop change uses effective received upgrades | 173 |
| 6 | 2,500,000,000 Tickets | AutoDiceRoll | Roll convenience; finite dice/budget must govern | 174 |
| 7 | 9,000,000,000 Tickets | Cooldown25% | Very costly package; no benefit in stationary-only session | 175 |
| 8 | 20,000,000,000 Tickets | Drops Value3 | Drop capacity/per-play value requires actual consumer and reward verification | 176 |

### Rifts

| Tier | Native price | Native effect field | Conditional marginal value | Line |
|---:|---:|---|---|---:|
| 1 | 5,000,000 Gems | UnlockRiftSummon/shards | New activity access plus shard capability; excludes summon/entry costs | 190 |
| 2 | 35,000,000 Gems | ShardLuck25% | Meaningful only with actual shard-eligible hatches | 191 |
| 3 | 125,000,000 Gems | Radar level1 | Information/location convenience; no rate gain from icon alone | 192 |
| 4 | 1,000,000,000 Gems | Radar level2; teleport description | Travel time saving if live rift exists and usable life remains | 193 |

Minigames visibility uses the exact nonnil `WorldsUnlocked["Minigame Paradise"]` test at178–184; this is weaker than WorldRewards' explicit true test and does not establish live travel or server eligibility. Rifts1's5m Gems entry price is not a summon's material/egg cost; use Stage1 specialty definitions and fresh live lifetime/location before any later recommendation.

## Every seasonal tier — retained, hidden definitions

`Christmas`, `Easter`, `Summer` have `ShouldShow()=false` at197–203,222–228,248–254. All44retained tiers are catalog knowledge only; their currency and corresponding egg group do not prove a live event. Owner-reported Halloween is not authorization to revive these branches. Native rows204–218,229–244,255–270 give:

| Tier | Christmas Snowflakes:cost / effect | Easter EasterEggs:cost / effect | Summer TropicalSeashells:cost / effect |
|---:|---|---|---|
| 1 | 10,000,000 / ordinary egg luck5% (L205) | 10,000,000 / ordinary egg luck5% (L230) | 10,000,000 / ordinary egg luck5% (L256) |
| 2 | 75,000,000 / ordinary egg luck10% (L206) | 75,000,000 / ordinary egg luck10% (L231) | 75,000,000 / ordinary egg luck10% (L257) |
| 3 | 350,000,000 / ordinary egg luck15% (L207) | 350,000,000 / ordinary egg luck15% (L232) | 350,000,000 / ordinary egg luck15% (L258) |
| 4 | 1,000,000,000 / ordinary egg luck20% (L208) | 1,000,000,000 / ordinary egg luck20% (L233) | 1,000,000,000 / ordinary egg luck20% (L259) |
| 5 | 2,000,000,000 / ordinary egg luck25% (L209) | 2,000,000,000 / ordinary egg luck25% (L234) | 2,000,000,000 / ordinary egg luck25% (L260) |
| 6 | 4,000,000,000 / ordinary egg luck30% (L210) | 4,000,000,000 / ordinary egg luck30% (L235) | 4,000,000,000 / ordinary egg luck30% (L261) |
| 7 | 10,000,000,000 / Secret luck1% (L211) | 10,000,000,000 / Secret luck1% (L236) | 10,000,000,000 / Secret luck1% (L262) |
| 8 | 25,000,000,000 / Secret luck2% (L212) | 25,000,000,000 / Secret luck2% (L237) | 25,000,000,000 / Secret luck2% (L263) |
| 9 | 50,000,000,000 / Secret luck3% (L213) | 50,000,000,000 / Secret luck3% (L238) | 50,000,000,000 / Secret luck3% (L264) |
| 10 | 75,000,000,000 / Secret luck4% (L214) | 75,000,000,000 / Secret luck4% (L239) | 75,000,000,000 / Secret luck4% (L265) |
| 11 | 100,000,000,000 / Secret luck5% (L215) | 100,000,000,000 / Secret luck5% (L240) | 100,000,000,000 / Secret luck5% (L266) |
| 12 | 150,000,000,000 / Infinity luck1% (L216) | 150,000,000,000 / Infinity luck1% (L241) | 150,000,000,000 / Infinity luck1% (L267) |
| 13 | 200,000,000,000 / Infinity luck2% (L217) | 250,000,000,000 / Infinity luck2% (L242) | 250,000,000,000 / Infinity luck2% (L268) |
| 14 | 250,000,000,000 / Infinity luck3% (L218) | 500,000,000,000 / Infinity luck3% (L243) | 500,000,000,000 / Infinity luck3% (L269) |
| 15 | — | 750,000,000,000 / Infinity luck4% (L244) | 750,000,000,000 / Infinity luck5% (L270) |

Those percentages are declared effect fields, not certified final rarity probabilities. In particular Summer's last Infinity value is5% whereas Easter's is4%; Christmas ends3% at14. No seasonal tier is a current candidate from this evidence.

## Prerequisite packages and totals

For actual category level q and target t, cost vector `I[c]=sum(cost[i,c], i=q+1..t)`, adjusted only for a received, verified entitlement/discount. For Pets10 the native legacy predicate110–123 checks `OGData.Passes` for Multi Egg; do not assume this entitlement exists or that any page-reader account owns it. From zero, nominal packages with ordinary prices are:

| Target | Coins committed | Gems committed | Main option acquired; prerequisite burden |
|---|---:|---:|---|
| Pets3 |95,000|0|first extra equip; includes shiny tier10k |
| Pets9 |845,000|23,500|Blackmarket/map; includes XP/variant/team/storage steps |
| Pets10 |845,000|98,500|first multi-egg capacity |
| Pets11 |845,000|273,500|effective equip2/storage300/luckIII candidates |
| Pets12 |845,000|723,500|hatch speed10% plus XP35% |
| Pets14 |845,000|4,173,500|equip3/storage500, including950k team tier |
| Pets15 |845,000|11,673,500|effective multi-egg2 candidate |
| Buffs6 |1,880,500|0|craftIII/duration15%; includes radius/walk/friend/crate taxes |
| Buffs14 |1,880,500|1,921,450|duration25%/bulk use |
| Buffs15 |1,880,500|4,421,450|map collection/crate3/auto mystery |
| Buffs20 |1,880,500|334,421,450|auto enchants and batch10 |
| Shops5 |0|72,000|extra offer slot/free restock1 |
| Shops10 |0|3,397,000|always sale eligibility/free restock3 |
| Shops11 |0|8,397,000|BuyAll convenience |
| Rifts1 |0|5,000,000|summon/shard entry capability |
| Rifts3 |0|165,000,000|radar; includes earlier40m |
| Rifts4 |0|1,165,000,000|teleport capability candidate |

Complete nominal branch sums: Buffs1,880,500 Coins+3,534,421,450 Gems; Pets845,000 Coins+11,511,673,500 Gems; Shops8,397,000 Gems; Minigames32,770,000,000 Tickets; Rifts1,165,000,000 Gems. Retained seasonal totals: Christmas867,435,000,000 Snowflakes; Easter and Summer each1,917,435,000,000 of their distinct currency. These are arithmetic sums from115native prices, not advice to buy all tiers. Coins/Gems/Tickets are not interchangeable.


## Marginal ROI and broad opportunity value — batch M3

This is a conditional mathematical decision model. It does not execute purchases, relax reserves, assume server odds or approve phases. Use the [native economic model](../replicatedstorage/ECONOMY_AND_ROI.md) and best feasible **owned** team before assigning value to anything bought.

1. Establish the next meaningful goal, hard reserve/committed cost vector, remaining session/event horizon and actually reachable activities.
2. Recompute the best feasible owned team for that objective, including ordinary/Super caps, duplicate units, locked/protected ingredients and coupled enchants. A free equip correction can dominate a Mastery purchase; an advertised extra equip with no useful unused pet gives zero immediate team gain.
3. Build every unowned prerequisite and its exact currencies into a package. Add travel/setup, materials, potion queues, missing world/area access, inventory capacity, and any needed follow-on purchases.
4. Estimate changes only in supported consumers or measured productive rate. Keep unknown RNG/grants as ranges/scenarios; a description is not a measured income gain.
5. Compare goal completion time and useful horizon against continuing current farming/saving. Reject nonpositive benefit, incomplete prerequisites, reserve violation, expiry, absent live object or unverified action. Re-evaluate after received changes.

For a same-currency stable-rate scenario, current balance B, goal G, baseline rate r0>0, package spend I, setup time d, productive background rate rb during setup, and resulting rate r1:
`Tsave=max(0,G-B)/r0`;
`Tinvest=d+max(0,G-(B-I+rb*d))/r1`.
If r1<=r0 and there is no separate goal/capability value, there is no earning payback. For r1>r0, active break-even after setup is `(I+(r0-rb)*d)/(r1-r0)`. Use consistent minutes/seconds and net attributable rate; currency labels and stat multipliers are not rates. Integrate piecewise when potions/players/events change. A useful horizon H supports earning investment only when `integral_0^H(r1-r0)dt>I+lostSetupEarnings`, in the paid currency.

Coins can buy world access while a Gems investment helps Coins output. A fixed exchange rate is unjustified: compare a **resource vector plus goal time**, requiring each paid currency to remain within its protected allocation. Native world entry prices1b/2.5bCoins (`Shared.Data.Worlds:134,147`) do not mean every unlock pays back; inspect new caps/facilities/eligible world actions and actual entry. Phase3 paid unlocks still need owner acceptance. A broad package can open multiple useful opportunities, but counting every enabled menu as income overstates value.

### Concrete marginal calculations

- **Extra owned equip:** native currency aggregation starts1 and adds each equipped unit's (stat-1), rather than multiplying pet stats (`StatsUtil:242–245`). In a synthetic uncoupled team with multiplier19 and unused eligible pet stat10, one slot changes the factor to28, a47.37% relative increase before other constraints. At a synthetic measured1000Coins/min and one-minute lost setup, the95,000Coin Pets3 package breaks even after about202.67productive minutes if the same proportional rate increase actually holds. These are invented illustration inputs, not account measurements or purchase advice. No unused useful pet means that modeled increment is zero. Coupled enchants/Super/guild factors require a whole-team recomputation.
- **Speed:** native duration is4.5/H (`StatsUtil:562–570`). A Mastery addition.1 to speed factor H increases potential throughput by .1/H, not a universal10%. At H=1 this is10%; H=3 gives3.33%. Affordability/storage/server pacing can reduce realized gain to zero.
- **Multi-eggs:** if actual effective capacity rises k→k+1 and no other bottleneck binds, potential hatch throughput increases1/k while spend/time also rises1/k. The12cap (`StatsUtil:571–612`) and exact received effect govern. Fixed session spend buys roughly the same number of ordinary paid hatches; capacity can save time or fit more into an expiring window, but is not cheaper useful outcomes by itself.
- **Potion duration:** under the narrow model with only mastery scalar,15%→20% duration is1.20/1.15−1≈4.35% additional timer per potion;20%→25% is≈4.17%. Actual `BuffUtil:80` multiplies native mastery scalar, milestone factor and count before rounding. Existing queue, active family, useful productive window, expiry and budget can erase the theoretical gain. Bulk use does not make each potion stronger.
- **Refresh:** native D/(1+m+other) gives base→10% scalar a9.09% shorter interval; mastery10%→20% gives8.33% shorter interval when other=0. More opportunities have value only if a useful purchasable offer is actually checked and consumed. Fixed periodic checks or lack of demand can bind before the nominal refresh rate.
- **Sale chance:** in the restricted client model, sale probability q gives25% off eligible items (`ShopUtil:130–168`). With no other discounts/rounding, expected saving is .25*q times future eligible base-price spending. Shops1's2500Gems at q=.10 needs100,000Gems of otherwise-planned eligible purchases to recover its own cost in expectation. q=.10→.25 adds3.75percentage points of expected saving; this is not a25% discount on every item. From zero the3,397,000Gem Shops10 package would need13,588,000Gems of eligible purchases to repay through the25% sale side alone, before accounting for earlier sale benefits, refresh/stock options, time or other discounts. This calculation does not establish server offer probabilities and must not induce unnecessary spending merely to claim savings.
- **Convenience:** batch keys, auto-spin claims, Atlas, saved teams and auto-bubble can save interaction/travel time without changing draw quality or stat power. If existing authorized behavior already supplies the convenience, its marginal benefit can be nearzero. A15mGem batching tier is not justified by labeling its button automatic.

### Fresh, middle and advanced conditional choices

| Situation | Candidate package worth evaluating | Skip/defer condition |
|---|---|---|
| Fresh; Playtime capability absent | Free Pets1, then genuinely due gifts with room/claim evidence | Native eligibility unavailable or no due unclaimed gift |
| Fresh; useful owned pet excluded by equip cap | Pets3:95kCoins fromzero, or exact missing suffix | No useful unused pet; reserve/goal-time loss; unverified equip consumer |
| Fresh; stationary collector, no potion/hatch plan | Free Buffs1 can be harmless convenience; expensive radius/crate/craft chain waits | Magnet/walk label offers no measured new reachable credits; no compatible potion demand |
| Fresh; saving first useful world | Keep native1bCoins target/capability prerequisites protected; compare only bounded supported acceleration | First WorldReward delays saving if its actual credited Coins remain below its100m price and no separate package benefit compensates; the100Coins catalog amount is a base, not a verified receipt |
| Middle; actual Pets9 and serious bounded hatching |9→11cost250kGems combines capacity/equip/storage/streak;9→12cost700k adds speed/XP | No useful spare pet, already enough storage, cap/budget/expiry binds; blanket hatching approval absent |
| Middle; actual Pets12, need extra equip/storage |12→14cost3.45mGems including950kteam step;12→15cost10.95m including multi-eggs | Team convenience alone or no capacity shortage cannot justify the whole chain |
| Middle; shop demand already established | Shops5suffix for slot/reroll; later10for eligible sale/refresh package | Current wanted offer would be destroyed; no demand; currency allocation unavailable |
| Advanced; eligible T3Legendary/Secret and real enchant goal | Buffs18Special with complete suffix and bounded orb/Gem loss model | Best-owned team already strong; valuable enchant protection; unknown odds cannot justify large reserve loss |
| Advanced; extensive key-chest activity | Buffs16/20/25batching or21auto-chest only if time/capacity scarcity matters | Same finite keys would be redeemed anyway with little time loss; no live compatible chest |
| Advanced; only more saved teams/storage remains | Pets16–23 are convenience/capacity, totaling11.5bGems after15 | No constrained inventory or team-management burden; free safe organization dominates |
| Any; timed Rift/fishing/minigame objective | Native eligible entry package plus live travel/lifetime/material budget | No approved Phase7 activity; preserve owner-tested Phase1 and approved Phase2 stationary scope |
| Any; retained seasonal branch | Catalog comparison only | All three native ShouldShowfalse; no activity/expiry/implementation authorization |

A useful entry package can help several goals: Pets9opens map/vendor access, Buffs15may reduce repeated due-chest travel, and Shops5opens one moreoffer and a free-refresh option. Their **option value** is the best additional feasible future plan, not the sum of hypothetical profits from every enabled system. Avoid double-counting the same potion's earning benefit, the resulting quest reward, and spending saved by a discount when those values derive from one alternative comparison.

## Ownership and phase boundary

Mastery/rewards belong to roadmapPhase5; pet selection/hatching investments connect toPhase4; vendors/quests/consumablesPhase6; rifts/minigames/fishingPhase7; eventsPhase8; joint idle-farm overlap/scoringPhase9. All new implementation remains unapproved in this assignment. This research changes no runtime ownership.

ReplicatedStorage/GameKnowledge supplies catalog/interfaces; verified LocalData supplies current levels, upgrades, balances and inventory; Workspace supplies actually spawned objects, travel positions and opportunity lifetime. Existing reader dependency cache, world observations, mechanics verification, OCBrain and TaskScheduler are the integration owners. There is no new scheduler, competing automation loop or automatic reserve exception. The minimum later evidence is a fresh before/after level+upgrade+debit receipt, compatible native consumer change and attributable productive-rate/goal result under owner testing.

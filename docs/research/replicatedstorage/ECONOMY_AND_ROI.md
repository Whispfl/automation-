# Economy and ROI — native formulas and decision mathematics

Research date:2026-10-11. Research only. No spend, hatch, equip, reserve override, or automation change was performed. All live effective odds/earnings remain unmeasured in this batch.

## Start from the best feasible owned team

`HYPOTHESIS` — future decision mathematics, not an implemented contract:

Let `P` be the actual owned inventory with multiplicities and protections, `F(P)` all feasible teams under native equip/Super/stack rules, and `U_c(T)` the supported effective utility for current objective c. Define `U*_c(P)=max(T in F(P)) U_c(T)`. The hatch outcome x has marginal benefit `Delta_c(x)=U*_c(P plus x)-U*_c(P)`. Never compare a new pet with a weaker manually equipped baseline. First account for any free improvement from equipping already-owned pets.

For additive independent currency contributions and fixed equip count, select the best eligible contributions; coupled Team Up/Determination or Super bonuses require evaluating the complete candidate team. `PetUtil`74–102 deduplicates team IDs, sorts inventory positions and folds team enchants; GetStats148–152 only grants its team factor to equipped pets with a qualifying enchant. Native generic `GetPower` is not established currency-per-minute utility and has a returned decompile anomaly.

SOURCE_CONFIRMED — duplicate stack units matter: Inventory.stackWindow214–215/244 counts repeated equipped IDs against Amount. StatsUtil's equipped helper preserves each entry; only the Team Up enchant fold deduplicates IDs. The native currency UI comparator SortPetsList122–140 prioritizes Void before stat and calculates stats without account context. A future optimizer must maximize the actual objective with multiplicities/coupling, not select the first visible N records.

PetUtil.getTeamMultiplier61–72 uses the first matching Team Up or Determination enchant. Its fold starts1 and adds matching Percent value/100 for each distinct qualifying equipped record95–102. All qualifying equipped pets receive that resulting team factor148–152, while unqualified pets do not. In the narrow text-supported model, two Team UpV records give factor1.5 to those qualifying records, not1.25*1.25 to every pet. Variant/stat fidelity caveats still apply. A proposed replacement can remove both its own contribution and its buff to other qualifying pets.

`SOURCE_CONFIRMED` — `StatsUtil:GetCurrencyMultiplier`242–245 starts at1 and adds `(petStat[c]-1)` for every resolved equipped pet. It does **not** multiply all pet currency stats together. Example under the narrow no-other-bonus model: two 10x coin pet stats give1+9+9=19, not100. Actual later buffs and ceil alter the effective result (247–355). Missing pet currency stat contributes nothing. Gems and other currency roles must be evaluated separately.

`SOURCE_CONFIRMED` — `StatsUtil:GetBubblePower`131–174 adds Flavor.Bubbles to all pet Bubbles, then applies conditional day/shrine/milestone/rune/global/Infinity/guild changes and ceil. Bubble output, pet currency multiplier, pickup credit rate and sale rate are distinct quantities. Do not assume bubble utility drives stationary pickup earnings.

## Buff arithmetic matters

`SOURCE_CONFIRMED` — `Stats.BuffUtil:GetValue`330–342 adds `Buff.Value * count` for Type Value; Percent adds `Buff.Value/100 * count` to the supplied number. It does **not** multiply that supplied number by `(1+percent/100)`. Example GetValue(2,{Percent,50})=2.5, not3. Callers may multiply the final factor separately. Preserve native application order.

`BuffUtil:UseBuffs`127–181 reads unexpired ActivePotions and ActiveBuffs by Stat; Uses expiry is decremented unless its final preview flag is truthy, removes depleted records, and calls Update. A helper that appears to calculate a stat can mutate its input snapshot. Future estimates should use an isolated account copy and verified preview semantics; never mutate the authoritative LocalData table while merely estimating alternatives. Update183–263 advances highest-level queued potions; queues and active buffs have different timer representation.

## Hatch throughput and effective cost

`SOURCE_CONFIRMED` — `StatsUtil:GetHatchDuration`562–570 returns `4.5 / GetHatchSpeed`. HatchSpeed471–560 starts1, applies first mastery HatchSpeed, infinite-season perk, active HatchSpeed buffs, Infinity*2, global Hatching+2, FastHatch+0.5, HatchDay/shrine/milestone/Blue fragment/Super additions, then guild multiplication. This is a client-derived duration, not proven server request rate.

`GetMaxEggHatches`571–612 starts1, applies permanent Extra Hatch and first MultiEgg mastery, TripleHatch+2, HatchDay/milestone additions and active Egg buff+1; clamp1..12. Maximum requested capacity is not necessarily affordable count or free storage.

`GetEggCost`197–225 selects catalog cost, resolves Infinity Egg dynamically, then divides currency Amount by `1+milestone EggCost` and ceil. Unknown/default fallback is Coins1e14; it is a guard value, not evidence that an unavailable egg costs that. Required cost should be recalculated at task start and after account/buff changes.

## Probability, expected useful cost and uncertainty

`HYPOTHESIS` — conditional planning model once actual per-outcome probabilities are established:

`E[Delta per hatch]=sum_x p_x * Delta(x)`; `q=sum_{Delta(x)>0} p_x`.

With independent stationary outcomes, `E[hatches until first useful]=1/q`; cost per first useful result≈`costPerHatch/q`; probability of at least one useful result in n hatches=`1-(1-q)^n`. These assumptions fail when pity, pool rotation, auto-delete, variant eligibility, inventory overflow, expiring buffs, or existing team improvements change q. Best team value over n hatches is **not generally** n times the initial E[Delta]; useful outcomes replace marginal slots and can saturate. Recompute sequentially or use a distribution over resulting inventory.

Count duplicates as useful only when they improve a free team slot, replace a weaker pet, enable a demonstrably beneficial recipe, or progress an explicit Index/quest goal. Multiply variant conditional probabilities only when native independence and eligibility are supported. No final server hatch odds were accessed.

HYPOTHESIS — finite investment risk needs more than a mean. The ratio E[cost]/E[rate gain] is not E[payback time]; if some outcomes give zero gain, payback can be infinite on those outcomes. Compare a bounded strategy's probability of improvement, probability of reaching the protected target by a deadline, and expected/quantile time-to-goal. Recompute after each meaningful inventory/buff/eligibility change; stop when the best feasible team already dominates available useful outcomes or the remaining horizon cannot repay setup/cost.

## Payback includes time and reserves

`HYPOTHESIS` — compare like currency only. If baseline measured net rate r0>0, post-investment measured/supported rate r1>r0, paid currency I and unproductive switch/travel/hatch/verification time d, break-even active time after completion is `(I+r0*d)/(r1-r0)`. If compatible background farming earns rb during d, replace lost earnings r0*d by `(r0-rb)*d`. Negative/zero delta means no finite payback. Use a horizon no longer than buff/egg/event validity; piecewise integrate changing rates rather than annualize a temporary buff.

Time-to-goal comparison is often stronger: with current balance B and target reserve G, direct≈max(0,G-B)/r0; investment≈d+max(0,G-(B-I+rb*d))/r1. A higher multiplier can still lose when travel/cost exceeds the remaining time saved. Currency rates require observed balance deltas with spends/rewards separated, not stat labels. Coins/Gems/Pearls/Tickets have no assumed fixed exchange rate.

Protected budget feasibility: `spendable[c]=max(0,balance[c]-hardReserve[c]-otherCommitted[c])`; hatch allocation≤explicit session budget, affordable count, safe inventory capacity, expiry window. A soft-reserve exception would need verified cost, supported benefit, explicit owner authorization and a protected bounded allocation. This research implements no exception and grants no spending permission.

## Currency and output role separation

SOURCE_CONFIRMED — Shared.Data.Currency11–59 has49 distinct currency keys. Coins/Gems/Tickets/Pearls and many events have CanBeMultiplied=true; legacy Seashells14 and TropicalSeashells46 do not set it. StatsUtil still explicitly applies TropicalSeashells active buffs287–303, while generalized day/shrine/pass/Infinity branches313–348 require CanBeMultiplied. GameTickets has a separate Double Currency branch349–350; Points353 can return a SeasonPassPoints factor. Never equate display labels to keys: Candycorn18 and Candycorn2658 share a display name; CompetitiveScore36 shares "Stars" with Stars32; several keys display "Points".

Keep pet stats, pickup base amount/respawn opportunity, sale station factor, travel time, and bubble production/storage separate. For a stationary collector, an earning-rate hypothesis can be written sum(pickup-type spawn/credit opportunities per time * base amount * supported currency factor), bounded by the existing collector's reachable geometry and cadence. Increasing pickup radius may affect accessible opportunities; it does not justify moving toward items. A bubble-sale hypothesis requires actual Bubble.Amount credit, the selected station's observed factor/currency, and travel/interaction time. This file has no authoritative server sell amount formula. World research owns fresh station attributes and native SellBubble guards; do not turn stale station annotations into ROI inputs.

## Ordinary luck arithmetic and specialization

SOURCE_CONFIRMED — StatsUtil.GetLuckMultiplier1908–2478 starts primary factor A=1, adds normal-index bonus outside Christmas1970–1972, first LuckyEgg mastery1974–1978, compatible specialized potion/shrine contributions1980–2359, Lucky buff2360–2373, equipped high/ultra-roller bonuses2374–2382, and infinite-season perk excess2384–2386.

It separately starts B=0 (2388). Infinity, Double Luck and global Lucky add2 each2389–2405. Day/shrine/milestone/rune and eligible event-upgrade bonuses add to A2407–2445. Green fragment, Super luck and player Luck Event add to B2432–2449. Only when B>1 does A multiply by B2451–2453; otherwise B is not applied in the returned expression. Then BonusLuck, Friendship excess and Board server luck add2454–2461; guild factor multiplies2474 and all-fragments completion multiplies1.252475–2477. This exact order differs from independently multiplying every advertised "2x".

SOURCE_CONFIRMED — GetSecretLuck1706–1794 and GetSecretLuckMultiplier2480–2522 are different interfaces. The former includes egg-specific additions, special events, rune/milestone/Purple fragment, consumable Secret, Dreamer/global/guild factors. The latter omits several of those. GetInfinityLuck1819–1883 has its own restricted UltraInfinity/mastery branch for Constants.ULTRAINFEGGS, Super/egg-specific/Rainbow/special/global branches. General luck, Secret luck and Infinity luck are separate transformed-pool inputs; don't use one as a substitute for the others.

Several long helper chains delegate eligibility/value to specialized potion/shrine modules. A full StatsUtil fetch is not full verification of each delegated helper. Source decompile anomalies and server visibility are explicit limits.

## Temporary boosts and variants as an investment

SOURCE_CONFIRMED — BuffUtil.GivePotion53–125 uses round(baseDuration * masteryPotionDurationScalar * (1+milestonePotionDuration) * count) at80 (milestone factor defaults1, count defaults1); active potion expiry is absolute, queued duration is relative. Update183–263 selects the highest queued level. The same potion family is not an assumed set of simultaneously independent levels. Joining265–283 and Leaving285–313 convert offline timing. Timers and Uses need separate horizons and depletion models.

GetShinyChance803–1220 starts factor1, applies specialized branches, +Super boost1188–1189, +player Shiny Event.25 at1190–1192, equipped shiny-seeker via GetValue1193–1202, +globalShiny.25 at1204–1205, Infinity factor2 at1216, then base2.5 at1219. GetMythicChance1222–1704 likewise ends base1 times its factor. Neither shown function clamps the final percentage. The server's ceiling/eligibility/draw order is unknown; do not allow an estimator to convert an unchecked >100 into probability.

SOURCE_CONFIRMED — Secret Elixir tradeoff is implemented in GetMythicChance1676–1703: suppression divisor starts5 (earlier function initialization), Infinity doubles both the Mythic factor and suppression divisor1686–1687, and active Secret divides factor by that divisor1700. Relative to the current Infinity-boosted no-Secret Mythic estimate, the suppression is10x when Infinity is active and5x otherwise. Relative to the original no-Infinity/no-Secret estimate, both active buffs give one-fifth. This distinction matters for a mixed Mythic/Secret objective. Buff description Shared.Data.Buffs13/147 promises Secret or Infinity luck2x; GetSecretLuck1779 supplies2x, but GetInfinityLuck1819–1883 shows no Secret branch. Resolve this discrepancy with an authoritative hatch consumer/live owner evidence before valuing the Infinity side.

SinisterPotion.applyBuff44–78 limits current Halloween26 eggs and applies level1..4 Luck75/100/150/250%, Shiny25/50/75/150%, Mythic25/50/75/150% using additive GetValue semantics. Constants.Halloween26Eggs221 names Skelly/Vampire/Creaking/4x Creaking. Potions74 defines base durations240/360/480/720seconds. SinisterPotion.getLevel28–33 has an empty callback and returns no captured level; use its actual applyBuff evidence, not an invented repair. All event availability remains saved-source evidence.

HYPOTHESIS — temporary buff value is sum of supported marginal utility/earnings over effective active time, minus acquisition cost and time. Let d be travel/setup and T remaining timer; useful window is max(0,T-d), further bounded by available eggs/budget/storage and reserve goals. A hatch-capacity potion can increase spend rate without increasing benefit per currency. A speed potion increases potential hatches per time, but budget/storage/server cadence can bind first. Starting a potion before travel can waste its best time; research should compare activation timing without invoking it.

## Enchant eligibility, actions and diminishing returns

SOURCE_CONFIRMED — EnchantUtil.getEligiblePool201–248 uses saved pet rarity/tier and actual received MasteryUpgrades: Special requires Special mastery and Secret or tier>=3 Legendary; IsSecretOnly requires Secret; Super pets get only IsSuperOnly entries, ordinary pets exclude them. GetUnusedEnchant282–307 excludes existing IDs and both base/plus partners. Shiny has two enchant slots, ordinary one351–369.

Catalog Shared.Data.Enchants15–41 defines28 IDs. Ordinary weights: Team Up1, Gleaming2.5, Looter10, Bubbler10. Special weights include High Roller.015, Infinity.02, Magnetism.02, Ultra Roller.004, Shiny Seeker.01, Secret Hunter.004, Determination.0075. Super pairs use separate weights and SuperUtil buff values; Buffs Percent0 in their catalog is not their actual utility.

EnchantUtil.GetRandomLevel321–322 uses ceil(m*U^4) clamped1..m. For independent uniform U, P(level=k)=(k/m)^(1/4)-((k-1)/m)^(1/4). With m=5, level5 conditional probability is about.05426, not20%. GetChanceFromWeightSum335 multiplies this by Weight/sum. Eligible/excluded/luck-adjusted weight sum must be correct before using it.

Fidelity limitations: GetPossibleEnchants172–199 calculates but ignores Special mastery eligibility for ordinary pets; GetChance337–349 uses that list. GetRandomEnchant259 passes an empty filter to ApplyMultiplierToPool, applying no Special enchant luck; GetUnusedEnchant307 has the proper Special predicate. FillPetEnchants411–415 allocates the table but fills nothing; MakeEnchant384–388 Extra expression can be boolean or0. These are source observations, not verified runtime bugs. Do not use the UI chance display as certified server probability.

Client.Gui.Frames.Enchants.getEnchantCost162–177 reads Constants.EnchantsRerollAllGemCosts91: Common150, Unique200, Rare300, Epic500, tier1 EasyLegendary750, other Legendary20,000, Secret50,000. EnchantDay and milestone discounts use integer division. .25second UI cooldown142–160/Constants93 is native pacing, not a recommended send rate.

Single-slot action980–1045 guards account, selected record, cooldown, enough one Reroll Orb and CheckInventorySpace, then FireServer("RerollEnchant",id,slot)1026. Whole-pet Gems action1583–1625 guards account, record, native cost, inventory and safeReroll before InvokeServer("RerollEnchants",id,"Gems",lockedSlot)1619, receiving a possibly new ID1623. Treat record identity as mutable across rerolls.

safeReroll875–947 skips the locked slot and warns before replacing level5 or Special enchants. Native auto433 receives new ID/enchant list, retries "toofast" after.1seconds434–436, stops on no result438–439, desired matching nonlocked slot441–445 or unaffordability451–468. It uses cooldown+.05 pacing432–449. UI AutoRoll visibility requires mastery1292–1311; closing Enchants1314–1336 cancels the auto coroutine. The returned loop's reused/shadowed v23 naming is another reason not to certify retry identity semantics from decompiled text alone. Selection1777–1827 cancels existing auto and excludes Super pets in this normal UI.

HYPOTHESIS — evaluate reroll utility against the whole best feasible owned team after replacement, including the lost enchant, preserved locked slot, remaining Metadata uses, hatch/earning objective, and future recipe protections. Repeated Team Up/Determination has coupled team effects; a low-stat enchanted pet can raise several other qualifying pets while occupying a slot. Looter and Gems have different native branches. Magnetism's value requires spawn geometry; a larger label alone is not measured extra earnings. High/Ultra Roller and Infinity enchants have finite Metadata, with Celestial/Infinity-specific durations77–96; do not value them as permanent.

For a verified stationary draw with useful probability q and cost c per roll, expected cost until first useful is c/q, and bounded n-roll cost is n*c with success probability1-(1-q)^n. An actual reroll destroys the current value, so include loss/failure states; two slots use exclusions and cannot be assumed independent identical draws. Gems and Reroll Orbs need separate budgets and opportunity costs, not an invented exchange rate. An auto-roll-until-perfect policy is unbounded unless protected by explicit roll/spend/time caps and valuable-enchant preservation.

## Decision evidence required before a future investment

1. Verified LocalData snapshot: balance by exact currency key; inventory IDs/multiplicities/variants/XP/locks/enchant levels/Extra; actual received mastery upgrades, passes, teams, timers and event account state.
2. Best feasible owned team under ordinary and Super caps for the chosen earning/hatching objective; account for a free equip improvement before valuing a purchase.
3. Native action eligibility/cost and actual spawned object/range, candidate pool and compatible buffs, safe capacity, next-open timing and cancellation.
4. Outcome distributions labelled by source quality, with lower/upper or scenario estimates where final server behavior is unknown. Unknown final odds cannot support a confident reserve override.
5. Measured baseline earning rate with balance deltas partitioned into farm, sale, reward, spend and unrelated grants; conservative compatible background rate during travel/hatching.
6. Total paid cost, consumed items/ingredients, setup/switch/travel/verification time, temporary expiry, bounded session allocation and protected future world/upgrade reserves.
7. After-action account deltas: debit plus expected new IDs/amounts/variants; team IDs after equip; result record plus ingredient removal after craft; new record/enchant state after reroll. Local animation, prompt close or timeout is not success.

No action, reserve override, numeric account recommendation or gameplay verification was performed. The model and native evidence are reusable research; Phase4/Phase9 implementation remains outside this assignment.

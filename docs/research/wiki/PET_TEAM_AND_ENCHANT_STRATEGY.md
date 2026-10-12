# Pet team and enchant strategy: Stage 2 research

Date: 2026-10-11. Local documentation only. Native Stage1 evidence is preserved; actual community-body findings are forwarded from root's readable browser with explicit provenance. This file proposes reusable mathematics and evidence checks, not gameplay actions or implementation.

External source/claim details are in [EGG_SOURCES](evidence/EGG_SOURCES.jsonl) and [EGG_CLAIMS](evidence/EGG_CLAIMS.jsonl). Root reviewed actual bodies; this child has not independently read full external pages. No fresh owner account/team/earning observations exist. E-C007–009 and E-C013–026/E-C042/E-C048 reconcile capacity, variants, coupled effects, roll costs/probabilities, finite metadata and recipes. Nine actual article bodies were read by root, with Index limited to its visible body rather than all world/event tabs; this agent received findings and retains that provenance.

## Establish an owned-team benchmark before spending

The correct baseline is `max_{feasible owned T}U_c(T)`, with objective c named explicitly. Current equipped utility and best owned utility are separate. A free equip improvement must not be sold as egg investment benefit. Rarity, native display sorting and combined generic power cannot replace currency-specific utility.

Stage1 [team facts](../replicatedstorage/EGGS_AND_PETS.md#team-and-inventory-facts) records native paths `StatsUtil98–112,404–439`, `PetInventory55–119`, `PetStackUtil12–52`, `Inventory.stackWindow214–215/244`. Count owned units as record Amount or1, with repeated team IDs representing units. Protections constrain allowed changes and consumption; they do not automatically erase a protected pet's existing utility or eligibility for a permitted equip. Keep required protected team units fixed where policy demands it, and subtract reserved units only from the quantity available for the proposed action. Preserve unit counts when summing stats; do not deduplicate the whole team because the Team Up fold separately deduplicates record IDs.

For an ordinary uncoupled currency objective, native `StatsUtil242–245` starts1 and adds each equipped currencyStat-1. With two10x pet stats and no other boosts it gives19, not100. Missing objective-currency stats do not contribute. Bubble output sums pet bubbles plus flavor before different multipliers; Gems, sale output and stationary pickup earnings are distinct objectives.

Super capacity is separate from total equip capacity. An owned Super that increases several other team effects may beat a higher individual stat; respect actual received cap and enchant state. Valuable variants, locked/favorite/configured protected pets, active teams and future ingredients constrain candidate changes. Research does not remove protections.

## Coupled team effects and bounded-search uncertainty

Native `PetUtil61–102,148–152` folds the first qualifying Team Up/Determination enchant per distinct record into a shared factor, then applies it to qualifying equipped pets. Two Team UpV records in the narrow returned model create1.5 shared factor, not independently compounded1.25×1.25 for every pet. A replacement removes its own stats and may also lower other pets' factor. Score the whole resulting team, including multiplicity and recorded eligibility.

A globally optimal search may be impractical for many units/coupled effects. A documented feasible candidate gives lower bound L on best utility, not a proof of optimality. If an upper bound U is available, a hypothetical acquisition's true marginal gain lies between `L_after-U_before` and `U_after-L_before`. A positive greedy before/after difference alone cannot certify improvement over a stronger unseen owned team. Report search budget, objective, protections and optimality gap rather than rename a greedy result best.

Local Stage1 audit shows existing policy uses current equipped baseline and bounded greedy search; [LOCAL_ARCHITECTURE_EVIDENCE](../replicatedstorage/LOCAL_ARCHITECTURE_EVIDENCE.md#mathematical-review-of-current-pet-estimates) records this as a later reconciliation candidate. No local code was changed.

## Evaluate acquisition and conversion with lost ingredients

Outcome x matters through `Δ_c(x)=U*_c(P+x)-U*_c(P)`. A same-name duplicate can improve another slot or an approved recipe; it can also have zero present marginal utility. Recipe value must include all ingredients removed, not just the resulting pet's label.

Native Shiny recipes require Common/Unique16, Rare/Epic12, Legendary10, Secret8; XL8 (`Constants54–55`, `ShinyUtil11–47`). Native CanUse excludes Shiny/Locked only; that is less protective than the required owner policy. Selection prioritizes the requested source, lower XP and no enchant (`ShinyUtil49–100`); protected team units/enchants/future variants must remain protected even if the native predicate allows them.

A stronger result can lower team utility when many productive copies are consumed. Illustrative two-slot uncoupled team with exactly ten10x copies: utility19 before; if all ten are consumed to produce one hypothetical15x result with no replacement, utility15 after. The1.5 stat ratio in this example is hypothetical; damaged PetUtil variant nesting means it is not certified as the saved helper's runtime Shiny formula. Evaluate actual result and replacement inventory, then consider lost hatch boosts/metadata/XP. Native preview and .5second timeout do not establish transfer success.

## Enchant acquisition is replacement risk

Native cost/call/guard evidence is in [Stage1 enchant economics](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns). `EnchantUtil201–248` gates eligible pools using received Special mastery, rarity/tier/Secret/Super state; `GetUnusedEnchant282–307` excludes current IDs and paired Super IDs; ordinary/Shiny slot rules351–369 matter. The wiki's categorical names cannot replace received native eligibility.

The target distribution must condition on pet, slots, locks, existing IDs, mastery, discounts and current generator. Native catalog weight is not final enchant chance. For the returned level generator `L=clamp(ceil(mU^4),1,m)`, uniform independent U gives:

`P(L=k)=(k/m)^(1/4)-((k-1)/m)^(1/4)`

For m5, conditional level5 probability≈0.05426, not0.2. Multiply by eligible adjusted ID weight/sum only if those are the actual generator's inputs. GetRandomEnchant's empty predicate, GetPossibleEnchants' unused eligibility and other saved-source defects prevent treating a UI table as certified server odds.

Single slot RerollEnchant(id,slot) uses one Reroll Orb; whole-pet RerollEnchants(id,"Gems",lockedSlot) can return a new ID. Native safeReroll warns before replacing valuable level5/Special records and skips locked slot. Actual server locked-slot/cost/identity behavior remains unknown. Request timeout does not authorize a duplicate reroll.

For a constant verified stationary target chance q and roll cost c, independent roll limit n has success `1-(1-q)^n`; expected cost c/q is an unbounded geometric expectation, not a budget. Replacement outcomes can destroy existing utility; expected improvement is `Σ_y p_y[U*_c(P with old removed/new added)-U*_c(P)]`, retaining negative states. Two slots have exclusions; they are not identical independent draws.

A bounded stopping policy requires protected valuable enchants, explicit roll/item/currency/time ceilings, and target utility threshold. No auto-roll-until-perfect policy or spending authority is created here.

## Actual article comparisons and cost interpretation

The reconciliations E-C020–026/E-C042 refer to [Enchants](https://bgs-infinity.fandom.com/wiki/Enchants). The resolved20K TierII/III table cell spans two rows, while50K spans the Secret-family labels. Native agrees at the base coefficient level; the earlier flattened-table reading does **not** establish a TierIII cost conflict.

| External comparison | Native result and planning implication |
|---|---|
| Team Up/Determination stacking | First qualifying enchant per record; distinct records still couple through shared factor |
| Gem versus Orb | Whole-pet versus one slot, with locked-slot and mutable resulting ID |
| Special/secret prerequisites | Actual received mastery plus native Rarity/Tier/secret-only predicates |
| Super permanence | Normal UI excludes Super selection; universal server immutability unknown |
| LevelV probabilities | Normal-only weights with biased levels plausibly explain table; actual exclusions/pools matter |
| Ultra Roller coefficient | Saved20 differs from article25; preserve version conflict |
| Shiny Seeker | Saved2 Percent and1.5M ordinary metadata differ from older table; family metadata overrides matter |

These are source relationships, not permission to reroll. Before any later implementation, actual received pet/slot/lock/mastery state must establish eligibility and preservation, and result verification must join the returned ID with LocalData.

For a **hypothetical normal-only first slot**, weights sum23.5. `P(levelV)=1−0.8^(1/4)=0.054258391`. Then Looter/BubblerV probability≈0.023088677 and TeamUpV≈0.002308868 (about1in433.113). The fit is E-C025 NATIVE_CORROBORATED for the formula, UNKNOWN_SERVER_RULE for the real draw. If Gleaming or another ID is already present, GetUnusedEnchant exclusions change the denominator; if Special eligibility applies, additional adjusted weights enter. A shiny two-slot result is therefore not two identical independent copies of this example.

Cost normalization matters when comparing slots. One Orb rerolls one slot; a Gem request rerolls the whole pet except locked-slot handling. Do not compare their label costs as if they buy identical lottery trials. Include the existing slot utility lost and the value of the unused slot/output states.

## Benchmarking bubble, currency and hatch teams

Use separate utility outputs for a named task: bubbles per action, currency multiplier, measured currency per minute, hatch duration/capacity and objective-specific rare/variant factors. A pet can improve one objective while hurting another. A hatch team consumes equip capacity that could otherwise earn currency, so funding rate and hatch rate may require separate bounded schedule alternatives.

[Pets](https://bgs-infinity.fandom.com/wiki/Pets) variant claims are E-C013–019. Its differences from saved XL values and inconsistent Mythic totals prevent treating a catalog variant ratio as a personalized marginal utility multiplier. Native level XP curve, actual record XP/enchants and recipe ingredients are prerequisites.

Candidate comparison should retain a vector of benefits when no verified common conversion rate exists. If a single objective is chosen, state that choice; otherwise show nondominated feasible teams and the tradeoff. Do not invent a Coins-to-Gems/event-currency value or combine luck percentages with earnings into an arbitrary score.

The Super and fragment coefficients from [Stats](https://bgs-infinity.fandom.com/wiki/Stats) are reconciled by E-C008–009. A listed percent is not uniformly a final multiplicative benefit. Bubble Plus discrepancy remains version dependent; Green fragment threshold and different Super consumers require their actual accumulator order. Burst has no inspected final duplication consumer.

## Uses and team effects are horizon-limited

High/Ultra Roller, Shiny Seeker, Secret Hunter and Infinity carry finite metadata (`Data.Enchants19–24`; `EnchantUtil77–96` selects Celestial/Infinity durations). Metadata is future-use capacity, not permanent earnings. Use-count timing must be based on actual eligible usage; equipped status and remaining Extra are account facts.

SuperUtil23–109 counts enchants across equipped Super records. Native paired coefficients enter different accumulators; Plus Bubble discrepancy E-C008 must remain unresolved against the external table. Burst threshold/duplication consumers are unavailable, and the module cache may be shared across hypothetical account/team evaluations. [Stage1 Super limits](../replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md#supers-existing-complete-review-explicit-units-and-limits) provides exact paths and fidelity limits.

Temporary potions and runes can amplify hatch throughput while consuming a funding budget sooner. Secret/Mythic tradeoffs E-C006 need an explicit objective and comparison baseline. A boost with expired useful window or no eligible candidate pool has no proven realized benefit. Queue duration, strongest active level, timer versus uses and craft opportunity costs belong in the plan.

## Rates, opportunity cost and preserved ownership

Pet stats are not currency/minute. Stationary pickup geometry/respawn/server credit and selling travel/storage differ. A candidate's positive stat marginal must be connected to supported or measured rate gain before claiming numeric payback. Maintain currency/item reserves and future world/mastery costs; no assumed exchange rate between Gems and Reroll Orbs.

Any future analysis uses the existing GameKnowledge/reader cache, detached projections, OCBrain and one TaskScheduler/mechanics adapter. Wiki strategies grant no phase approval, native action authority or new automation loop. Verification requires correlated received IDs/amounts/variants/team/enchants and debits, not animation or prompt closure.

## Remaining comparisons

Nine actual article bodies were reviewed by root and their forwarded findings reconciled into48claims; Index world/event tabs remain incomplete. Paid-egg/name-ambiguity/release follow-ups remain discovery only. Authoritative final rolls, recipe transfers, equip/Super caps on this account, owner objective and measured earnings remain unavailable regardless of wiki access.


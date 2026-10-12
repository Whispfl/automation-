# Future unified ROI decision framework

Research design, 2026-10-11. No engine or gameplay changes were implemented. Native authority: [Stage 1 economy](../replicatedstorage/ECONOMY_AND_ROI.md), [contracts](../replicatedstorage/NATIVE_ACTION_CONTRACTS.md), [dependencies](../replicatedstorage/SYSTEM_DEPENDENCIES.md) and [local architecture audit](../replicatedstorage/LOCAL_ARCHITECTURE_EVIDENCE.md). External motivation and caveats: [Stats](https://bgs-infinity.fandom.com/wiki/Stats), [Mastery](https://bgs-infinity.fandom.com/wiki/Mastery), [Infinity Egg](https://bgs-infinity.fandom.com/wiki/Infinity_Egg), [Shops](https://bgs-infinity.fandom.com/wiki/Shops), [Board Game](https://bgs-infinity.fandom.com/wiki/Board_Game). These pages were inspected on 2026-10-11; unknown revisions and hidden server rules remain explicit in the ledgers.

## Decision objective and state

Use the owner's goal and horizon, such as minimizing time to a verified world unlock, improving stable Gems/min, or completing a specific collection. A rarity, nominal multiplier or expensive shop item has no intrinsic universal utility. Keep a vector of distinct resources: Coins, Gems, Tickets, Pearls, Stars, protected consumables and year-specific event keys. Do not add unrelated quantities or assign a permanent Coins:Gems exchange rate.

Definitions belong to GameKnowledge through the existing reader dependency cache. Player/account facts belong to ready LocalData observations. Workspace supplies spawned objects, reachable positions and interaction geometry. A prediction is a separate model with its own revision and assumptions; it must never be written back as an account fact. Missing is not zero. Scene existence is not permission or live availability. An official current-season advertisement can inform version identity but cannot fill a missing account prerequisite.

The baseline is the best **feasible already-owned** team for the objective, respecting quantity, protected IDs, valid equip count, allowed variants and native coupled effects. It is not the current equipped team. Define `U0 = max_T U(T, objective, state)` over legal owned teams. Report exact optimum, bounded search or heuristic status honestly. A candidate hatch outcome's gain is `max(0, U(best_owned_after_outcome) - U0)`; never credit a pet that cannot displace or improve the optimum. Separate short-term collection reward, permanent stat improvement and collector preference. Shiny crafting/fusion additionally removes inputs; reoptimize the entire remaining inventory.

## Candidate record

| Field | Required meaning |
|---|---|
| Identity and authority | Native subsystem, external claim IDs, model version, evidence classification |
| Eligibility | Profile readiness; prerequisite levels/unlocks; active event/version; actual facility; policy limits; protected scope; relevant owner verification |
| Cost vector | Exact native currency keys and current prices/stock; chosen quantity semantics; consumed pets/items; uncertain or paid costs block automatic spending |
| Reserve vector | Major-world goal reserve, emergency operating reserve, protected inventories, intended future crafts; reserve may exceed today's deficit |
| Incremental benefit | Difference from the free owned-team optimum; temporary/permanent effects; unlock-expanded opportunities; conservative range |
| Chance of benefit | Conditional model, target set and variant eligibility; measured or unknown hazard; no invented final server odds |
| Time | Active completion, travel/approach, waiting, cooldown, hatch cadence, crafting serial time and verification latency |
| Availability | Absolute stock refresh, cooldown, expiry and event boundary; freshness/scene revision |
| Opportunity cost | Goal delay, displaced earning rate, consumed rare items, forfeited event currency or pet utility |
| Confirmation | Account debit/credit/unlock/claimed state and relevant object changes; timeout reconciliation before retry |
| Reevaluate | Next material inventory/stat change, result, stock refresh, cooldown readiness, expiry margin or model invalidation |

Candidates include free team equip, measured farming, egg pursuit, a prerequisite Mastery package, world saving/unlock, ready claims, a quest package, stock-limited purchase and a temporary opportunity. Claiming a reward and buying a paid World Reward are different actions. A recipe label is insufficient to identify pet-consuming or event-reset actions.

## Measured rate versus native multiplier

Native currency scaling is `1 + sum(pet_currency_stat - 1)` across valid equipped units, followed by the appropriate inspected effects. That describes potential credit scaling, not travel time, spawn density, collection throughput or actual currency/min. Use actual credited deltas with a window, location, team, active buffs and exclusions for transfers/claims/purchases. Evaluate steady state and startup separately. Do not attribute a one-time chest award to repeatable farming rate.

For an owner-verified bubbling cycle with capacity `K`, bubble production `b` per second, sell yield `s` per bubble and round-trip sell overhead `tau`, a simplified rate is `r = s*K/(K/b + tau)`. It assumes filling capacity, no interruption and a valid selling route. Capacity has diminishing value when overhead is negligible; doubling capacity does not generally double rate. Recalculate the full cycle for flavor, capacity, pet or selling-location changes. Rate windows should exclude unrelated credits and retain confidence/variance. Preserve owner-tested Phase1 bubbling/selling/teleportation and approved Phase2 stationary collection; these formulas authorize no new pickup movement or hybrid farming.

Use conservative recent rate intervals `[r_low,r_high]`, a minimum meaningful observation duration and an explicit unavailable state. Account revisions alone need not invalidate all rates; the native dependency delta (team, boosts, route, world) determines relevance. Predictions after a change are provisional until compared with owner-operated observations.

## Goal-time economics

For a single-currency goal with cost `G`, additional nonoverlapping reserve `R`, available balance `B` and stable positive rate `r`, `T_save = max(0,G+R-B)/r`. R must exclude the same goal commitment already represented by G; count each reserve obligation once. This is conditional on the verified prerequisite route and no other spending. A zero deficit does not prove the gate is usable.

An upgrade costing `C`, taking `t` minutes and changing the goal-currency rate to `r'` has `T_upgrade = t + max(0,G+R-(B-C+r_setup*t))/r'`, provided it is affordable and all reserves are honored. Here r_setup is the credited goal-currency rate during setup; use zero when setup fully interrupts earning. Recompute prerequisites/package costs and compare complete routes. The conventional payback `C/(r'-r)` is useful only when C and the improvement are in the same currency and `r'>r`; it need not match the earliest world-unlock time. Let H be the total available evaluation window including setup and ensuing operation, with rates/time in consistent units. Gross positive operating gain is `max(0,r'-r)*max(0,H-t)`; it is not net profit. With C paid at the start and constant rates, signed same-currency net gain relative to continued farming is `(r'-r)*max(0,H-t) - C - (r-r_setup)*min(t,H)`. This preserves negative rate changes and bounds setup loss within H. Planned interruptions need their own time/rate model. Permanent does not mean profitable within the owner's horizon.

Illustrative inputs, **not account observations**: `G=1b Coins`, `B=400m`, `C=100m`, `r=10m/min`, `r'=15m/min`, `t=2min`, additional reserve zero and setup earning zero. Saving takes60min. Upgrade path takes`2+700/15 =48.667min`, improving the goal time11.333min; simple payback20min. If instead `r'=11m/min`, the path takes65.636min and saving wins. Any travel downtime, affordability reserve or uncertainty can reverse the result.

A Gems upgrade that improves Coins cannot use a fabricated exchange rate. Compare feasibility and resulting Coin goal time while retaining the Gems debit and Gems-goal delay separately. It may be worthwhile if spare Gems have no nearer protected use; it may lose if those Gems unlock another opportunity. Present Pareto alternatives when objectives disagree. Conditional shadow prices can be derived from the owner's current constrained goal, but must be labeled state-specific and recalculated, never stored as a universal exchange table.

## Hatch investment and uncertainty

For known, constant independent useful-outcome probability `p`, first useful hatch count has expectation`1/p`, variance`(1-p)/p^2`, and success after`n` trials `1-(1-p)^n`. A batched hatch with `b` independent draws has useful-success probability `q=1-(1-p)^b`. Expected first-success **batch time** is `cycle/q`; `cycle/(b*p)` is an arrival-rate approximation and understates batch completion delay when p is large. Expected resource cost includes the full paid batch and cadence/caps, not only the winning pet. See [egg research](EGG_PROBABILITY_RESEARCH.md).

Use all eligible useful outcomes and joint variants; do not multiply Shiny/Mythic/XL probabilities without an established joint-order/independence rule. Native Golden75 and Burst100/75 counter/helper definitions would create state-dependent hazards if their final server application is established; the Burst consumer remains unavailable. For independent but varying conditional hazards `p_i`, failure through n is `product(1-p_i)`; for server-dependent/pity histories use the conditional survival hazards actually established. An advertised Shiny guarantee is not a guarantee of a useful pet or target rarity.

Expected projected gain per draw is `sum_j p_j * deltaU_j`, under the explicitly chosen outcome model. It is a local estimate: after a hit, the best team and subsequent marginal gains change. Expected first success, probability of a useful outcome and expected magnitude of improvement are separate outputs. Include a fixed budget/time cap and the probability of zero benefit. Do not label expected spending a guarantee.

When p is unknown, display symbolic results or honest bounds. Zero rare drops in a short owner-run sample is not p=0 and cannot validate billion-scale odds. Under an IID Bernoulli model, zero successes in n trials gives a one-sided95% upper bound `1 - 0.05^(1/n)`; it supplies no positive lower bound. If the pessimistic bound loses to saving and the optimistic bound wins, explain the unresolved decision instead of inventing precision. Protected purchases and pet consumption must abstain when eligibility or irreversible effect is unknown.

## Temporary and repeatable opportunities

For an available buff with replacement value/cost `C`, travel/use overhead `t` and useful duration`D`, credited same-currency benefit is the integral of `r_boost(t)-r_base(t)` over time actually operating under the buff. Cap by remaining event/goal time. Include cooldown or duration already active, multiplicative/additive ordering, objective mismatch (Secret Elixir reduces Mythic factor), and displaced baseline time. Do not consume a rare potion just because its timer is ready.

A quest package should track simultaneous objectives and count each earning/reward event once. Incidental completion during already-chosen farming can have low incremental time; a rare-rarity hatch requirement can make an otherwise generous quest impractical. Reward-pool weights and server rolls are distinct. If expected payout cannot be established, use guaranteed documented components or defer.

The renewal rate of an activity with mean reward`V` is bounded by useful reward per feasible critical-path cycle. Let t be active time, c be cooldown and a be mandatory sequential overhead outside active time. For a start-triggered cooldown, cycle is at least `max(c,t+a)` under those constraints; overhead that fits inside cooldown must not be added again. For a completion-triggered cooldown, the cooldown-only floor is `t+c`; include travel/verification and other prerequisites according to their actual overlap rather than a universal sum. Inspect received timer semantics. Reward selection, difficulty extras, failure probability and restart resource consumption must be included. Robot Claw's1.4 reward weight does not by itself establish enough Super Tickets to replay forever. Board dice are weighted landing windows, not a uniform random walk over tiles.

Temporary rifts require expiry minus travel/approach/verification to exceed a conservative useful operating duration. Use live spawned expiry/luck observations; a catalog or wiki10minute label is insufficient. Keep reserved keys and Rift Charms/Shards distinct. Treat shrine donations and serial rune crafts as resource allocation with opportunity costs, not free permanent buffs. Event rebirth is a protected reset: include all forfeited currency, remaining event time and confirmed marginal upgrade effect. Never merge old Leaves and new Candycorn keys.

## Authority, abstention and scheduling

Feed every candidate into the existing central OCBrain and TaskScheduler. Reuse the shared GameKnowledge/reader cache, mechanics adapter, world observations, verification and current lifecycle cancellation. Do not add per-feature decision loops. Native timers may be read as observations; they do not become competing OC authorities.

Use evidence tiers and hard feasibility gates before optimization. Preserve an explicit reason when the Brain chooses SAVE, FARM, WAIT or MANUAL_REQUIRED. Account/profile stale, missing prices, unknown action contract, ambiguous gate, unverified server acceptance, unavailable route, protected scope or inconsistent event identity can each make a candidate ineligible. A known free equip improvement may dominate speculative spending; its action still needs owner verification before automation exists.

Explain the choice in plain terms: goal; best owned baseline; eligible alternatives; exact cost/reserve; measured rates and horizon; conditional odds; expected gain/range; travel/time; source confidence; why rejected alternatives lose; result verification; next reevaluation. Reevaluate on material account outcomes, known timer readiness, pool/version changes or expiry approach. Use switch margin/minimum dwell and bounded failures so uncertain estimates cannot cause oscillation. A remote return, animation or scheduler COMPLETED status is insufficient to record successful gameplay.

## Phase ownership

Phase4 supplies owned-team/probability/inventory models after explicit approval; Phase5 supplies Mastery/reward packages; Phase6 supplies quest/stock/consumable allocation; Phase7 supplies validated rift/minigame/fishing/course candidates and reachable activities; Phase8 supplies event identity/expiry/protected resets; Phase9 arbitrates cross-system ROI, uncertainty, measured rates and explainability. Phase3 existing progression reserves and owner-tested Phase1–2 behaviors remain the foundation. This file is a future design specification, not authorization to implement any phase.

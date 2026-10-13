# Phase 5 — read-only Mastery intelligence

The owner authorized this independent component after the isolated Common Egg hatch and direct movement milestones. It implements the first scope from [the entry plan](PHASE5-ENTRY-PLAN.md). Phase 4 acceptance and universal movement remain separate. No purchase, claim, hatch, equipment, movement or spending is authorized or performed.

## Existing support reused

- `AccountStateReader` supplies received Mastery levels/effective upgrades, balances, unlocks, revision and observation time, plus its verified LocalData profile accessor.
- `GameKnowledge` reuses the dependency cache for the current native `Mastery.Upgrades` catalog. The historical reader's catalog path does not match that native shape. Its protected method is preserved; the new `MasteryContext` provides the correct read path separately.
- `OCBrain:AnalyzeMastery` owns the new pure `MasteryPolicy` report. `OCController:GetMasteryPlan` and `PrintMasteryPlan` expose it explicitly. Existing Brain planning, action arbitration, TaskScheduler and all gameplay methods remain unchanged. These report calls neither enqueue actions nor create an automation loop.
- The existing stationary metrics and `_pickupRates` exclusions supply qualified current Void Coins or Zen Gems observations. No bubble income assumption, pickup request, farming start or travel is added.

## Planning contract

The default `MASTERY_SETTINGS.ENABLE_MASTERY_INTELLIGENCE` is false. The separate read-only example opts into reports while keeping OC controls STOPPED and every gameplay action OFF.

Each report lists received current/completed tiers, the next sequential tier, native fixed cost or observed early-unlock free price, currency balance, explicit reserve, shortage, declared effects, access requirements and blockers. Remaining prerequisite packages retain separate currency totals. Prices and entitlement predicates must be reobserved after account changes.

Known obtainable permanent Mastery stays ahead of the next paid world gate, including unfunded tiers. Affordable tiers precede funding/access reviews; observed free tiers lead, then configured category order and comparable native cost break ties. This is a deterministic completion policy, not an optimal ROI claim. No low-benefit permanent tier is discarded. Locked future-world or hidden seasonal categories remain explicit and are not declared complete. An unfamiliar visible category has UNKNOWN permanence and prevents a claim that all obtainable Mastery is complete.

Missing levels are UNKNOWN, not zero. Sparse catalogs do not permit skipped prerequisites. Failed predicates, unavailable costs/balances, stale/future snapshots, changed account facts or catalog definitions invalidate the relevant recommendation. Native optional visibility and early-unlock callbacks receive detached profile copies. Unverified callable prices are never executed.

Declared effects and actual received effective upgrades are separate; historical tier effects are not added together. Current stationary income can estimate shortage funding time only with verified scope, recent pickup evidence, adequate sample duration and a fresh same-currency rate. Future income gain, payback and optimal ordering remain UNKNOWN. Net balance samples can include external credits; ETA assumes an unchanged rate and is not guaranteed.

The report evaluates the native Outer Space HUD prerequisite and category visibility. Physical station requirements and server purchase acceptance remain UNKNOWN. `MASTERY_REVIEW` means an advisory review, never permission to buy. The report does not change ordinary world reserves, existing execution policy or any action budget.

The native Trading Plaza HUD restriction is reported separately. An unavailable helper remains UNKNOWN with an explicit prerequisite/blocker; Outer Space alone is not proof of full HUD or purchase eligibility.

## Synthetic examples

These values are invented offline fixtures, not native production prices or owner account facts.

| Synthetic observation | Read-only recommendation |
|---|---|
| Pets tier 0; next tier costs 100 Coins; balance 1,000; paid world costs 500 | `MASTERY_REVIEW`, Pets tier 1 before paid world review; earning benefit UNKNOWN |
| Same tier; balance 40; verified stationary sample 120 Coins/minute | `MASTERY_FUNDING`, shortage 60 Coins, conditional funding ETA 30 seconds; no farming started |
| Pets tier 1; next tier costs 200 Gems; balance 80; verified Zen sample 120 Gems/minute | `MASTERY_FUNDING`, shortage 120 Gems, conditional ETA 60 seconds; Coins do not substitute |
| Missing Pets level or a hole in native tier definitions | `WAIT`, precise UNKNOWN level/catalog blocker; no inferred tier zero or skipped tier |
| Permanent branches completed; Minigames hidden by its native world predicate | Review the observed paid world gate separately; locked Minigames remains a carried prerequisite obligation |

## Evidence and limits

Implementation reuses the completed libraries, with current runtime native values taking priority:

- [Native Mastery and upgrades](research/replicatedstorage/MASTERY_AND_UPGRADES.md): catalog shape, sequential tiers, visibility, early-unlock pricing, permanent/seasonal scope and effective-upgrade ambiguity.
- [Native account schemas](research/replicatedstorage/DATA_SCHEMAS.md), [system dependencies](research/replicatedstorage/SYSTEM_DEPENDENCIES.md) and [navigation evidence](research/replicatedstorage/WORLD_AND_NAVIGATION.md): received fields and Outer Space HUD prerequisite; no invented physical purchase route.
- [Mastery comparison](research/wiki/MASTERY_ROI_RESEARCH.md) and [native/wiki conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md): historical price/effect conflicts and conditional benefit estimates. No wiki price is hardcoded into this planner.
- [Action contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS.md), [reward state](research/replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md) and [reward distinctions](research/wiki/REWARDS_SHOPS_AND_QUEST_STRATEGIES.md): Mastery, free rewards, paid World Rewards and consumables remain distinct.
- [Knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md) and [future improvements](research/wiki/FUTURE_OC_IMPROVEMENTS.md): server acceptance and actual marginal earnings require future evidence; the latest roadmap's Mastery completion priority supersedes older conditional ROI omission advice.

Offline fixtures validate the component; they do not verify a live Mastery purchase. Live intelligence requires a ready, matching LocalData snapshot and current native catalog, received Mastery fields/unlocks/balances, and any separately existing qualified stationary sample. This task requires no new owner gameplay test.

The next smallest Phase 5 milestone is a separately scoped read-only reward eligibility report: audit existing RewardsManager first, distinguish free due/unclaimed rewards from paid World Rewards and consumable stock/use, and test sparse claims, freshness and pending receipts. An executor or claim needs separate authorization. Full Phase 5 is not complete.

## Verified offline delivery

- Build `60e794e0fe87`, immutable candidate tag `phase5-mastery-60e794e0fe87`.
- `node scripts/build.mjs`: function-returning public bundle and embedded local distribution regenerated; only the new Mastery loader is repinned. Historical examples remain unchanged.
- `node scripts/test.mjs`: PASS. Official Luau compilation; all 684 baseline regressions; all 90 new synthetic Mastery audit groups; existing receipt, native registration, pricing, allowance, movement and standing safety suites; complete loader isolation and distribution integrity checks.
- [Separate source preservation record](PHASE5-READ-ONLY-SOURCE-PRESERVATION.json) and [append-only diff](PHASE5-READ-ONLY-ADDITIONS.patch): one new pure module and four exact additions. Every existing production byte projects back to the published baseline; no existing protected method changed. Historical approval hashes are not rewritten.
- The owner-confirmed first hatch `100f2c1907ae`, isolated direct movement `1d27e2a74ae5`, Test A and prior standing/receiver milestones remain immutable. The latest complete raw owner log and its private commit remain local and outside publication ancestry.

The [complete read-only loader](../examples/Phase5MasteryReadOnly.luau) keeps hatching, equipment, purchases, claims, pickups, farming, bubbles, movement and all spending OFF. It prints an advisory report only; missing live dependencies yield UNKNOWN. The default feature flag remains false in ordinary OC configuration. This is code/offline verification, not live Mastery acceptance or phase completion.

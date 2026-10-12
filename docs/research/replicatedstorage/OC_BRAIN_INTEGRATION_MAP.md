# OC Brain knowledge integration map

Research date: 2026-10-11. This document describes future consumers of research and the existing local integration boundary. It authorizes no implementation, reserve override, gameplay request or phase advancement.

Evidence labels: `SOURCE_CONFIRMED (LOCAL_OC)` for inspected repository code; `HYPOTHESIS` for recommendations; native evidence remains in the corresponding library documents. A local adapter is not proof of server acceptance.

The owner-required flow remains:

```text
Native definitions + actual account snapshot + live world observations
  -> shared GameKnowledge / evidence
  -> goal, prerequisite and ROI evaluation
  -> existing OCBrain
  -> existing TaskScheduler foreground lease
  -> existing GameMechanics adapter
  -> received account/world acknowledgement
  -> replan
```

## Roadmap scope and phase gates

Fully read complete returned Notion content for the master roadmap and Phases 1, 2, 3, 7, 8 and 9. Metadata described fetched pages as unverified; no assertion of inaccessible comments or unsupported blocks follows. Parent research reads Phases 4–6. This file summarizes requirements without copying entire pages.

| Roadmap | Requirement relevant to this library | Gate/boundary |
| --- | --- | --- |
| [Master](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349) | Native definitions + actual LocalData + world observations; progress per effective time, reserves, overlap, uncertainty and deadlines; one authority. | Research does not authorize future executors. Current research-only/no-sync request overrides generic delivery text. |
| [Phase 1](https://app.notion.com/p/3f53d7e9278d81d58924c7f8b54feff9) | Preserve approved reader/control interface. Future typed snapshots, capabilities and diff-based explanations. | Preserve historical owner-tested behavior; no rewrite. |
| [Phase 2](https://app.notion.com/p/3f53d7e9278d8145a85aff38d5497e12) | Genuine native IDs, paced stationary collection, received credit, useful currency goals, protected spend. | Approved stationary scope. No pickup movement or independent farm loop. |
| [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10) | Reach, discovery, paid unlock and travel distinct; fresh-account next useful gate; conditional funding ETA and earning upgrades. | Authorized with live purchase/persistence gaps. No automatic gate approach without native verified support. |
| [Phase 7](https://app.notion.com/p/3f53d7e9278d81ea9ba7ef232227ab4a) | Timed Rift/XL/bounty opportunity queue; costs/keys/materials; entry/travel/setup/usable lifetime; target dice, quest/FishDex fishing and special worlds. Distinct reusable obby start/checkpoint/finish/reward capability. Rift gift notification is an interface lead requiring scoped IDs and receipt verification. | Not started; requires Phases 1–6 and explicit approval. Obby movement only while that distinct activity owns movement, never pickup pathfinding. No summon/claim command inferred from Flame or wiki. |
| [Phase 8](https://app.notion.com/p/3f53d7e9278d81edb9ebe55869c90488) | Dynamic event registry with active state, end time, exact currency/schema/facilities, finite stock, buffs, quests, pass/board, cooldowns and reset effects. Expiry-aware value and graceful removal. Existing UI should expose goal/why/action/world/currency/rate/buffs/time/module/result. | Historical Fall 2026 prose/Leaves26 snapshots are version-specific, not current Halloween eligibility. Destructive rebirth/fusion needs explicit permission and verified effects. No event catalog enables automation. |
| [Phase 9](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358) | Observation/Planning/Execution/Verification/Recovery/Delivery; one planner/scheduler; goal-first plus preemptible optional idle farming; hysteresis, safe cancellation, reserves, budgets, stale result handling and low-noise logs. | Deferred until explicit approval. Preserve tested stationary collector; hybrid overlap, timed location ownership and new cross-system optimizer are research recommendations. |

## Current local ownership and future consumers

All existing implementation entries are `SOURCE_CONFIRMED (LOCAL_OC)`. Future consumers are `HYPOTHESIS` until phase approval and native result contracts are established.

| Knowledge family | Existing consumer / line anchors | Future extension at the same boundary | Required eligibility/result |
| --- | --- | --- | --- |
| Account facts | AccountStateReader `254-405,407-427`; presentation `AccountPresentation:89-146` | Typed fields for buffs, quests, claim states, stock, timed opportunities; explicit unknown/readiness. | Actual received LocalData; never synthetic totals or defaults for missing ownership. |
| Catalog/cache | AccountStateReader `78-118,430-465`; GameKnowledge `33-43,239-273` | Versioned immutable definitions, source/evidence metadata, shared currency/feature registry. | Native module provenance/load status, separate active/eligible flags. |
| World capabilities | ProgressionGraph `11-113`; TravelPlanner `5-50`; WorldProgressionManager `22-124` | Dependency graph for Mastery/rewards/shops/world facilities and time-sensitive entry. | Actual unlock membership, live scene entry, native guards, no catalog-only access. |
| Pets/eggs | GameKnowledge `89-236`; PetPolicy `139-309`; OCBrain `36-145`; PetManager `185-453` | Best feasible owned-team benchmark, probability scenario bounds, target overlap and travel/verification-adjusted ROI. | Quantity/protected IDs, native full-team stats, actual capacity/budget, received equip/hatch changes; final odds unknown until support. |
| Income/upgrades | FarmingPolicy `355-444`; UpgradePolicy `10-100`; OCBrain `152-240` | Reusable measured goal-currency methods and permanent upgrade payback candidates. | Native cost/effect, actual deficit, protected reserves, measured eligible earnings, total action time. Historical CompareIncome is not active selection. |
| Live pickups/location | PickupTracker `131-351,368-515`; GameMechanics `104-180,216-320` | Reuse registry/geometry/arrival and one location lease. Timed activities/obbies need separate supported navigation capabilities. | Genuine loaded objects/IDs, ambiguity rejection, actual unlock, arrival; no fabricated collection IDs. |
| Timed specialty/events | No Rift/event executor in current Controller | GameKnowledge catalog helpers + Reader/account event fields + world observations → Brain opportunity → scheduler definition → existing Mechanics extension. | Current event/Rift instance, expiry/time source, access, budget/materials, exact native command and received result. |
| Verification | FarmingCoordinator `409-545,652-665`; HatchManager `19-64`; WorldProgressionManager `122-124` | Shared structured result ledger with pre/post evidence and attribution confidence. | Invocation alone never success. Scheduler COMPLETED separate from Verified/uncertain/expired. |
| Control/scheduling | OCController `138-211,345-444`; TaskScheduler `28-109` | Capability records and one comparative opportunity scorer inside current Brain/Controller; generation/revision-aware cancellation. | One active lease, cooperative release, resource/location ownership, safe resume/replan. |
| UI/logs | OCInterface `90-169`; OCController `218-283` | Extend existing status with evidence, expiry, blockers and meaningful result deltas. | No private account dump, credentials or second timer/action controller. |

## Proposed knowledge records

These are documentation-level interface recommendations, not new modules or runtime schema claims.

1. **Definition:** stable native ID, source path/line/read date, category, exact currency/item units, prerequisites, effects, native helper references, evidence label and known unknowns.
2. **Observation:** account revision, observation time/freshness, live object identity/position/availability, event/Rift expiry, relevant ownership/cooldown/stock, unavailable fields and scene confidence.
3. **Capability:** action owner, `CanExecute` reasons, cost vector, hard and soft reserves, location/movement lease, earliest start/deadline, total-time estimate, result channel, cancellation checkpoints, protected/destructive authorization.
4. **Opportunity:** goal contribution distribution, target overlap, cost in each currency/material, probability confidence/scenarios, duration including travel/setup/execute/verification/return, switching cost, repeat/expiry/stock limit and failure/stop criteria.
5. **Result:** request ID/generation, profile/object preconditions, request timestamp, observed acknowledgement, Verified/uncertain/failure reason, cost/reward deltas and external-change attribution limits.

Definitions should be shared/cached; only mutable account/world observations refresh. Never load the same native module through competing caches. Use current Reader revision and Controller Generation (`OCController:178-180`) while adding finer invalidation only where needed.

## Goal economics and reserves

For goal `G`, evaluate feasible action `a` with useful expected progress `E[ΔG_a]`, native resource cost vector `C_a`, and total effective time `T_a = travel + setup + execution + verification + necessary return`. Rank only after access, protected resources, location ownership, expiry and explicit configuration authorization pass. A useful comparison is `E[ΔG_a]/T_a`, with uncertainty and interruption penalties stated; it is not a universal scalar exchange rate between Coins, Gems, Pearls, tickets, keys and limited consumables.

Protected spendable funds remain `max(0, actual balance - hard reserve - active goal reservation - committed request cost)`. Proposed soft-reserve exceptions would need native value/benefit evidence and explicit owner policy; this session implements no override. Cross-module reservations must be deduplicated by goal/request identity to avoid both double reservation and double commitment.

Use best feasible owned-team score as pet baseline. Compare candidate equipment/eggs with that same goal/currency score and active limits. Hatching pools are client estimates until final odds supported; publish bounds/scenarios rather than a false exact answer. Full-team effects can be nonlinear, so independent per-pet sum is insufficient. A greedy feasible team is a documented lower bound, not global optimality proof.

Expiry feasibility requires `now + travel + setup + useful work + verification safety margin < expiry`, with a known synchronized native time reference. Cost is committed at dispatch even if acknowledgement times out. Pause/Stop must release location authority while retaining cost/attempt ledgers. Expired/stale opportunities disappear from the queue and trigger replan rather than repeat claims.

## Ten later architecture improvements, ranked by dependency/value

1. **Evidence-qualified currency/feature registry:** consistent units, native source, availability and capability blockers, extending GameKnowledge/cache. Prevent catalog-as-live mistakes before enabling new tasks.
2. **Unified reserve/commitment view:** reconcile current world, pet and upgrade policy reservations; protect keys/materials and finite stock alongside balances, with no implicit overrides.
3. **Best feasible owned-team benchmark:** repair future research/implementation ROI comparison and explicitly state search quality/native helper limits before spending on eggs.
4. **Structured verified result ledger:** separate scheduler completion, command dispatch, received acknowledgement and causality. Reuse existing manager ledgers rather than replace working verification.
5. **Versioned material state deltas:** invalidate relevant plans on actual balance/unlock/team/buff/stock/expiry changes; preserve ready/loading/unknown distinctions and generation checks.
6. **Complete effective-time accounting:** include travel, presentation/setup, cancellation, acknowledgement and required return; split observed medians from client duration estimates and unknown components.
7. **Timed opportunity feasibility:** expiry-aware Rift/event/reward queue with synchronized clock, access/stock/material guards and bounded stop criteria, owned by current scheduler.
8. **Robust scoped rate model:** enough sample time, contaminated-window rejection, robust rate distribution/confidence and explicit external reward ambiguity; no false causal precision.
9. **Single comparative scorer with hysteresis:** evolve current fixed-priority and ordered manager arbitration inside Brain/Controller; preserve one foreground lease and safe preemption. Do not enable Phase 9 hybrid farming through helper availability.
10. **Actionable low-noise status:** extend existing UI with goal reason, blockers, evidence/unknowns, conditional ETA/expiry and last received result; never expose private values/credentials in reusable research logs.

## Acceptance gates for later implementation

Each feature requires its relevant Assets/Client/Remotes/Shared source inspection, native argument schema and guards, actual account prerequisites, live scene availability, resource/location policy, expected result channel, bounded retry/cancel/expiry behavior, offline decision verification, and explicit phase approval. The owner alone supplies live acceptance. Rejoin persistence, world spending, pet equip/hatch, and all new specialty/event actions retain their existing evidence gaps until owner reports actual outcomes.

No implementation, configuration, build, release or synchronization is part of this research batch. Batch C saved: source-linked architecture map complete.


# Local OC architecture evidence

Research date: 2026-10-11. Scope: local source inspection only. No gameplay source, configuration, bundle, or Git history changed; no builds, tests, publishing, or synchronization performed.

## Evidence boundary

`SOURCE_CONFIRMED (LOCAL_OC)` means that a claim is supported by this repository's implementation. It does not mean a native game contract, a current account value, or live server acceptance. Native findings in the companion library must retain their own provenance. `OWNER_LIVE_VERIFIED` below can only refer to owner attestations in previously saved documentation; this audit does not reproduce those tests. Future design recommendations are `HYPOTHESIS` until native interfaces and owner acceptance establish them.

## Roadmap read before analysis

The master roadmap and complete fetched content of Phase 1, Phase 2, and Phase 3 were read through the Notion connector. Page metadata describes each as `unverified`; `truncated` and `unknown_block_count` were not supplied. The returned content includes closing page tags. This verifies what was read, not every possible inaccessible Notion block or comment.

- [Master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349): owner ReplicatedStorage-first research, one Brain/scheduler, ROI, phase gates, research optimization notes, and delivery requirements.
- [Phase 1](https://app.notion.com/p/3f53d7e9278d81d58924c7f8b54feff9): V2 preservation guidance, full checklists, and explicit user approval log dated 2026-10-10. No account balances copied into this research.
- [Phase 2](https://app.notion.com/p/3f53d7e9278d8145a85aff38d5497e12): V2 and final farming revision, evidence-qualified bulk collection, no per-pickup movement, genuine credit verification, protected spending and owner testing.
- [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10): V2 fresh-account priorities, deferred higher-value selling/rewards, discovery research, paid-unlock distinction, and owner verification gates.

Current user instructions supersede the roadmap's generic implementation delivery checklist: this session is research-only during GitHub suspension. No build/push permission follows from reading those pages.

## Batch status

- Batch A saved: roadmap and architecture boundary captured.
- Batches B/C complete: dependency ownership, snapshots, plans, scheduler leases, actions, verification, policy source mapping and future integration map saved.

## Batch B: dependency, account, Brain and scheduler ownership

All rows in this section are `SOURCE_CONFIRMED (LOCAL_OC)`.

| Component | Exact local evidence | Existing behavior | Implication for later research use |
| --- | --- | --- | --- |
| Shared dependency cache | `src/OCFoundation/AccountStateReader.luau:78-118,430-465`; `GameKnowledge.luau:33-43` | Reader asynchronously loads selected native modules, tracks LOADING/MISSING/READY/ERROR/TIMED_OUT and exposes READY values. Knowledge.Get delegates to this same cache; Assets uses ReplicatedStorage lookup. | A new research-backed feature should extend this cache/facade, not create a second loader. READY is a load result, not a gameplay acceptance result. |
| Account readiness and truth | `AccountStateReader.luau:254-378,407-427` | LocalData.IsReady/Get establish the received profile; errors/loading/partial fields remain explicit. Current balances use numeric fields; bubble effective stats use StatsUtil; inventories/teams/unlocks are copies in snapshots. GetLiveProfile returns the actual received table for internal read-only consumers. | Keep account facts separate from definitions and predictions. Do not put synthetic pet/team projections into LocalData. |
| Snapshot refresh | `AccountStateReader.luau:97-105,380-405,469-484` | LocalData Changed/DataReady/PetsChanged queue a coalesced refresh; periodic refresh is also present. GetSnapshot deep-copies the stored snapshot. Revision increments on reads; errors become READER_ERROR. | Reader's observation loop is not a second task authority. Material-delta/revision handling can extend here later. |
| Narrow native task reader | `AccountStateReader.luau:55-75,281-288` | Received quest Tasks/Progress plus QuestUtil.GetRequirement expose unfinished Coins/Gems Collect, Bubbles, Sell tasks. Other task types are excluded. No quests accepted/claimed. | Existence of QuestUtil does not imply full quest automation. Later quest research needs other requirements and result contracts. |
| Catalog/account/world join | `AccountStateReader.luau:135-251` | Permanent Worlds definitions joined with scene-present worlds/gates/islands; duplicate gates flagged ambiguous; costs and unlock membership recorded. Gum/Flavors access and ownership knownness separate. Mastery next tier only if current level exists. | These catalogs are partial scene observations, not complete knowledge coverage or availability proof. |
| Central construction | `OCController.luau:138-157` | One Reader, Knowledge, Brain, Scheduler, FarmingCoordinator, WorldProgressionManager and PetManager. World/Pet managers share the Farming Mechanics/Tracker objects. | Preserve this integration boundary. |
| Central action arbitration | `OCController.luau:165-211` | Completed analysis calls Pets.Select first, then WorldProgression.Select, otherwise Farming.Select. All managers create OC_GAMEPLAY definitions; dispatch goes through Scheduler.Submit. Completion routes by Owner, refreshes Reader and replans. | Existing arbitration is ordered ownership, not a universal cross-system ROI maximizer. Future opportunities must enter this authority, not start their own loop. |
| Stale/lifecycle defenses | `OCController.luau:178-180,345-366,369-444` | Analysis snapshot revision and controller Generation checked; Start idempotent while running; Pause/Stop cancel schedule, halt managers; Resume refreshes account. Reader remains available while stopped. | State/model revision, task generation and actual action acknowledgement must remain separate. |
| Scheduler lease | `TaskScheduler.luau:28-65,68-109` | Single Active task. Queue priority descending, equal-priority FIFO. Timeouts cancel cooperatively. Active released only when Execute returns; CanRun and IsComplete checked; pending same IDs replaced. Pause/Stop clear queue/cancel token. | No foreground overlap during a yielding cancellation. Scheduler COMPLETED means task-return contract, not automatic game-success proof. |
| Knowledge evidence contracts | `GameKnowledge.luau:9-31,45-55,239-273` | Pickup, pet, progression contract tables contain source-reference strings, owner-status qualifiers and unavailable server validation. | These are historical implementation claims. Reinspect cited native sources before carrying them into this audit's SOURCE_CONFIRMED native results. |
| Pickup observer lifecycle | `GameKnowledge.luau:275-314` | Runtime observer wraps shared Chunker.Update preserving original call, captures matching native receiver, restores on success/timeouts/destroy. | This describes existing runtime behavior only. No such code is run in Studio during this research. New research needs no observer installation. |

## Batch B: progression and protected spending

`SOURCE_CONFIRMED (LOCAL_OC)`:

- `ProgressionGraph.luau:11-35` builds selected permanent-world graph and actual gate-origin dependencies. `36-81` separates world unlocked, island discovered, physical reached, scene-present and travel-available facts. Heights are ordering observations, not asserted server prerequisites.
- `ProgressionGraph.luau:44-59` blocks missing/ambiguous gates, unknown origin/discovery prerequisites, invalid nonpremium cost or unavailable balance. Funding deficit is `max(0, nativeCost + currencyReserve - actualBalance)`.
- `ProgressionGraph.luau:84-108` gives remaining Overworld discoveries priority when configured, then READY worlds, then FUNDING worlds, then remaining blocked nodes. `109-113` exposes narrow Mastery/WorldFacilities capability records; this is not a universal feature/prerequisite graph.
- `OCBrain.luau:265-439` creates recommendation candidates with fixed numeric priorities, family tie-breaks and objective hold/switch margin. MajorUnlockReservation carries a ready/funding world's native cost independently of which objective wins. Stage labels are descriptive from inventory/unlock/Mastery counts (`243-263`), not prerequisites.
- `TravelPlanner.luau:5-50` is pure policy: stale goal waits, discoveries remain bounded/capability-qualified, funding returns to existing collector, paid unlocks require explicit settings/currency/cost/session limits, and outside-range gate approach stays manual. No navigation toward pickups exists (`GameMechanics.luau:322-327`).
- `WorldProgressionManager.luau:6-18` shares existing Mechanics and exposes current goal/reserve providers. `22-90` defers to pending pickup cleanup/sell return and passes fresh observations to Brain. `93-124` uses the same OC_GAMEPLAY lease; `127-130` preserves request/backoff ledgers through controls.
- `OCBrain.luau:152-225` funding economics estimates deficit/rate only with fresh qualified stationary sample at selected unlocked Void/Zen. It labels extrapolation and possible external credit. Recommendations list native equipment/sell facts without buying or changing activities. ETA is conditional, not a promise.

## Batch B: action verification boundaries

`SOURCE_CONFIRMED (LOCAL_OC)`:

| Action | Local verification boundary | Important limitation |
| --- | --- | --- |
| Pickup | `GameMechanics.luau:104-160` checks genuine registry/model IDs and dispatches paced request; native cleanup in `162-180` removes visuals only after dispatch. | Invocation and visual cleanup are not credit proof. Server distance/ID validation remains unknown. Existing runtime mutation must not be confused with research operations. |
| Island travel | `GameMechanics.luau:216-257,259-320` verifies stable proximity to destination or target island/zone geometry. | Arrival is a world-position result, not a new discovery/unlock flag. |
| Gum/flavor purchase or equip | `GameMechanics.luau:330-397` rechecks real funds/reserves; purchase needs received ownership plus observed deduction, owned equip needs actual Bubble equipment field. | Concurrent earnings can mask deduction; no unsupported result inferred from FireServer. |
| Island discovery | `GameMechanics.luau:399-500` checks runtime contact capability, genuine hitbox, native definition/order, goal freshness, retry cap, contact cleanup and received AreasUnlocked presence. | In-session presence does not establish rejoin persistence. Runtime capability is not a Studio API. |
| Paid world unlock | `GameMechanics.luau:503-562,643-698` checks actual gate/prerequisites/range and authorization, records dispatch ledger, accepts only received WorldsUnlocked absent→present. | Balance delta is separate supporting evidence; server-only gates and live purchase acceptance remain unavailable/pending. |
| Scheduler completion | `WorldProgressionManager.luau:122-124` returns a table with Verified/Reason; scheduler IsComplete only requires a table. | OC_GAMEPLAY COMPLETED may contain Verified=false. Logs/status consumers must inspect the result, not equate scheduler completion with success. |
| Earnings sample | `ResourceMetrics.luau:11-35,59-77,80-95` uses observed balance changes, rejects intervals with detected spending, groups by mode/scope, and calculates sums/minute after enough seconds. | Attribution is partial; external credits/jackpots can affect totals. This is aggregate-rate logic, not robust median/EWMA or action-correlated causal proof. |

## Batch C: pets, hatching and native projections

All implementation claims here are `SOURCE_CONFIRMED (LOCAL_OC)`, not freshly inspected native game behavior.

| Component | Exact local evidence | Existing behavior and boundary |
| --- | --- | --- |
| Detached projections | `GameKnowledge.luau:58-70,89-160` | Copies received profile/teams before invoking native stats helpers. Proposed team score and synthetic normal XP-zero pet are projections. Actual received variants/XP/enchants have their own scoring path. Live LocalData is never the projection destination. |
| Egg catalog/context | `GameKnowledge.luau:72-87,162-236` | Joins Eggs definitions, original loaded models, costs, world membership, live luck helpers, inventory capacity, hatch time and presentation. Missing selected eggs report unloaded; no model is manufactured or force-loaded. |
| Quantity and protection | `PetPolicy.luau:22-60,70-86` | Validates record IDs, Amount and team multiplicity separately; protects configured IDs, favorite/locked records and valuable variants/rarities. Full-team native removal marginal includes interacting team effects. |
| Owned-team search | `PetPolicy.luau:139-204`; `OCBrain.luau:36-70` | Bounded greedy full-team helper search, then serial remove/add plan with native score improvement and protections. This is a feasible improvement search, not a proof of the globally best owned team. |
| Current hatch ROI baseline | `PetPolicy.luau:264-309` | Uses actual `team.BeforeIds` / `team.CurrentScore`, explicitly excluding hypothetical better-owned-team score. Chance is normalized client pool weight; final server odds UNKNOWN. Native stat gain per currency cost and per hatch time are estimates, not observed earnings/minute. |
| Reserve and eligibility | `PetPolicy.luau:112-137,229-262`; `PetManager.luau:30-45` | Objective currency selected separately. Configured reserve plus earliest locked permanent-world cost is protected; missing graph/cost blocks. Fresh pet context rebuilds permanent graph independent of selected world goals. Only currencies with explicit budget mappings can fund supported purchases. |
| Bounded pet authority | `OCBrain.luau:72-141`; `PetManager.luau:185-244,427-453` | Brain chooses; manager holds one OC_GAMEPLAY lease/location for bounded slices. Explicit one-time owned-team test is frozen; hatch requires native egg range, configured budgets, capacity and safe auto-delete. No automatic egg travel. |
| Equip acknowledgement | `PetManager.luau:77-145,246-335`; `GameMechanics.luau:702-715` | Fresh full profile checked again after yielding guards; ledgers precede command dispatch. Exact expected team ID multiplicity must appear. External changes/timeouts fault rather than retry blindly. |
| Hatch ledger | `HatchManager.luau:7-64`; `PetManager.luau:336-424` | Records requested count/cost/deadline before dispatch. Counter increase plus received inventory amount increase and pool-compatible records qualify result. Balance delta separate; manual/external hatch attribution cannot be excluded. Timeout keeps spent/requested ledger and ends automatic retries. |
| Stop behavior | `PetManager.luau:456-470` | Releases location authority; preserves request/session ledgers and consumes one-time authorization. Craft/delete/fuse remain off. |

### Mathematical review of current pet estimates

`PetPolicy.luau:293-307` computes client pool probabilities `p_i = w_i / sum(w)`, positive full-team marginal `g_i`, expected gain `sum(p_i * max(0,g_i))`, EV/cost, and EV/sec. These are client estimates. The missing server pity/rarity transform, boost timing, travel, verification and re-equipping time prevent an exact final economic ROI claim.

For a constant independent per-hatch useful chance `p`, batch size `b`, and cycle time `T`, the current `T/(b*p)` expression is a useful-outcome arrival-rate approximation. First useful batch waiting time instead uses `q = 1-(1-p)^b` and `E[time] = T/q`; finite `n` independent hatches give success probability `1-(1-p)^n`. Neither identity establishes independence in this game. The owner's research baseline is the **best feasible owned team**: current equipped-team EV can exaggerate egg value when better pets are already owned. A later analysis should score all candidate gains against a documented feasible owned-team benchmark, while acknowledging bounded search optimality limits. No change is implemented here.

## Batch C: active stationary farming and rates

- `OCBrain.luau:228-240` calls `FarmingPolicy.Decide`, whose active route is `355-444`. It farms a genuine unfinished task or actual positive cost shortage, uses confirmed Void/Zen access, retains a same-currency target, and stops without a useful need. It does not call the retained `CompareIncome` (`FarmingPolicy.luau:50-327`) or its `UpgradePolicy` route (`319`). The retained upgrade execution branch (`FarmingCoordinator.luau:636-644`) does not establish an active planner choice.
- `UpgradePolicy.luau:10-100` retains a pure conservative bubble-income projection: reserve and budgets checked; native projected power/capacity plus observed fill/sell overhead estimate gain; projected incremental income multiplied by 0.5; payback uses measured income. This is a heuristic under fixed cycle assumptions, not a source-confirmed game income formula or current global optimizer.
- `FarmingCoordinator.luau:19-35,243-315,340-398` owns the existing Mechanics/Tracker/Metrics/Stationary objects and supplies observed context to Brain. Its recurring observer updates facts, rather than selecting an independent gameplay objective. `_background` returns false (`68-70`). Hybrid farming remains deferred.
- `FarmingCoordinator.luau:421-443` rechecks fresh world funding balance between paced requests; `445-545` requires actual unfinished bubble task and verifies bubble reduction plus matching currency gain on sale. Automatic sell activation/native travel is observed, not a fabricated Sell request. Travel/activation/acknowledgement timing is measured; return cost is not universally included.
- `PickupTracker.luau:131-247,249-351,368-481` joins definitions, zones, original native registry IDs/models, current geometry and known visual metadata. Pool face-value yield is a configured expectation, not observed currency/minute; scene presence is distinct from genuine account unlock. Ambiguous identity is rejected. Observed respawn delay may include streaming latency.
- `StationaryExperiment.luau:16-36,39-164` keeps per-ID/model dedup across slices, paces bounded requests, retains invoked-ID ledgers on cancellation, and samples actual Coins/Gems. Root/area changes, known spending, bubble decreases or sale sequence contaminate samples. Credit qualification remains partial when external rewards occur. Distance is observed; no server distance bypass is claimed.
- `ResourceMetrics.luau:59-77` computes total scoped gains / total sample seconds. Minimum duration and freshness guards qualify rates, but no robust median, confidence interval, EWMA or action-correlated reward acknowledgement is present.

## Configuration, bootstrap and presentation

- `OCConfig.luau:46-63,77-81,188-222` defaults paid world controls, bubble/sell/buy, pet intelligence/equip/hatch and destructive pet controls to off, with spending budgets/ceilings zero. Resource farming is goal-driven when enabled. Default-off code existence is not phase approval.
- `OCController.luau:14-136` validates finite controls, arrays, currency/cost limits, mutually exclusive diagnostics, one-time equipment test and explicit hatch budgets. Unsupported destructive/event AUTO settings are rejected.
- `ConfigResolver.luau:12-48` copies defaults, validates known categories/keys/types, replaces whole arrays, converts legacy stationary method, and forces cluster movement off. Existing UPPER_SNAKE_CASE interface stays central.
- `src/OC.luau:8-40` is the function-returning custom-Config entry point, client-only, creating one Controller/interface. Prior shared controller is destroyed before the new one starts. Initialization logs describe historical owner claims; they are not current MCP live evidence.
- `AccountPresentation.luau:89-146` and `OCInterface.luau:90-169` format actual fields, unavailable states and qualified rates/ETA. Interface subscribes to Controller; it supplies no independent gameplay loop. Full account-print methods exist, but this research saves no personal values.

## Mismatches requiring later reconciliation, not fixes in this session

1. `docs/ARCHITECTURE.md:25` says phases 4–9 have no executors, while `98,112-120` describes Phase 4 authorization and existing bounded pet executor. The current user AGENTS directive and research-only request require fresh explicit Phase 4 approval before implementation/activation. Preserve these as differing historical documentation, not permission inferred by this audit.
2. Phase 3 Notion discovery-testing notes lag local architecture owner attestations (`15-23`). In-session discovery/funding confirmation differs from rejoin persistence and world-purchase acceptance. Do not collapse these states.
3. Current pet EV baseline (`PetPolicy.luau:276`) is actually equipped; this assignment asks best feasible owned-team baseline. Native nonlinear team effects plus bounded greedy search prevent silently calling the proposal globally optimal.
4. Current active farming (`OCBrain.luau:228-240`) does not execute the historical rate-comparison/upgrade policy. Smart upgrades and global ROI remain future integration work even when helpers or config labels exist.
5. Ordered Pets→World→Farming arbitration (`OCController.luau:190-204`) and fixed Brain priorities are narrower than Phase 9's universal opportunity ranking. They preserve existing action ownership; adding another loop would not solve this gap.
6. Scheduler success (`TaskScheduler.luau:53-63`) and manager result verification are different contracts. Result consumers must preserve `Verified=false` and uncertain attribution.
7. Pet policy currency support (`PetPolicy.luau:112-137`) and controller accepted objective set (`OCController.luau:91`) do not yet form a complete currency registry. Event currencies, keys, materials, spending reservations and goal reservation sources need an explicit shared future policy.
8. `PetManager.luau:234-244,437-443` contains gated hatch-location stationary pickup support, while current owner scope defers advanced hybrid farming to Phase 9. Do not activate this by assuming dormant code proves authorization.
9. Reader snapshots expose useful current fields, but do not implement a complete typed/versioned state-delta model for every reward, quest, buff and timed opportunity. Missing fields are not zero/not-owned.
10. Native source-reference strings in GameKnowledge are historical local evidence. This session's separate native ledger must independently establish actual module lines, gates and result channels.
11. Legacy Fall catalogs/config (`OCConfig.luau:177-185`) and old Notion seasonal prose are not active-event evidence. The owner reports Halloween; eligibility must join actual active flags, account state and world facilities.

## Completed local read scope

Read `docs/ARCHITECTURE.md`, `src/OC.luau`, and every OCFoundation module: AccountPresentation, AccountStateReader, ConfigResolver, FarmingCoordinator, FarmingPolicy, GameKnowledge, GameMechanics, HatchManager, OCBrain, OCConfig, OCController, OCInterface, PetManager, PetPolicy, PickupTracker, ProgressionGraph, ResourceMetrics, StationaryExperiment, TaskScheduler, TravelPlanner, UpgradePolicy, WorldProgressionManager. Exact ranges above are representative anchors within full-file reads, not claims that only those ranges were read. No source/build/bundle changes or live gameplay verification were performed.

Batch C saved: local audit complete. Native specialty/seasonal research is recorded separately and cannot retroactively turn these local claims into game-native or owner-live evidence.


# ReplicatedStorage-first architecture across every phase

This is the owner's global architecture instruction. Phase 1 is owner-approved;
Phase 2 bubbles, selling and island teleportation have owner-observed success.
Pickup collection/respawns and repeated real credit are now owner-verified. Movement
recovery, combined farming, upgrades and Phase 2 approval remain pending. Phases 3–9 remain plans and have
no new executors in this build.

## Sources and reusable layers

| Layer | Source / existing module | Responsibility and limits |
| --- | --- | --- |
| Definitions and catalogs | ReplicatedStorage.Shared.Data, Shared.Utils; GameKnowledge over AccountStateReader's existing dependency cache | Native worlds, pools, upgrade catalogs and stat helpers. Assets in ReplicatedStorage.Assets identify visuals. Missing data stays unknown. Catalog existence is not live availability. |
| Native interfaces and capabilities | ReplicatedStorage.Client, Remotes and Shared.Framework; GameKnowledge contract/status and GameMechanics | Inspect client behavior, argument shape, guards, cooldowns and result channels. Pickup contract records client source evidence and unknown server validation; no batch capability is invented. Dependency READY means loaded, not an action verified. |
| Live account | AccountStateReader using Client.Framework.Services.LocalData | Actual balances, ownership/equipment, inventory, Mastery and unlock membership. No profile replacement or fabricated progress. Phase 1's approved reader/loader remains intact. |
| Live world | PickupTracker / existing scene adapters | Rendered objects, native zone geometry, character location, interaction positions and changing availability. Resolve scene observations against definitions instead of deriving rewards from object names. |
| Supported actions | GameMechanics, leased by OCBrain through TaskScheduler / OCController | Only inspected supported commands and ordinary movement. Shared controls and guards apply. No independent action-choice loops. Working blow/sell/teleport adapters are preserved. |
| Action verification | FarmingCoordinator and ResourceMetrics, received LocalData updates | Observed arrival, disappearance plus matching balance credit, bubble changes, purchase ownership **and** currency deduction, owned-equipment changes. Combined rates require growth/credit/sale evidence. Timeouts/backoff and unconfirmed outcomes. External rewards remain an attribution limitation; source inspection/offline tests do not prove execution. |

GameKnowledge introduces no second module loader, discovery loop or action loop.
It exposes the same game dependencies already cached by the approved reader,
ReplicatedStorage asset access, read-only native active pickup registry access, and an evidence-qualified pickup contract. The
pickup tracker now consumes that shared facade; legacy working adapters continue
using the same underlying cache. Future features extend this facade after their
native interfaces are inspected, rather than replacing working modules wholesale.

`controller.Knowledge:GetStatus()` and
`controller:GetStatus().Farming.GameKnowledge` expose source/load status and the
pickup contract. `ServerOnlyRules` remains `UNAVAILABLE`. The Brain receives native
definitions through existing account progression catalogs and world observations;
executors never choose independent objectives.

`UpgradePolicy` is a pure, reusable catalog/economics evaluator called only by the
existing FarmingPolicy/Brain. It returns candidate facts and explicit blockers;
it neither requests actions nor creates another loop. Native stat helpers project
equipment in detached tables; the live profile remains the source for verification.

## Research and implementation order

For every future feature: inspect the relevant Assets, Client, Remotes and Shared
sources first; record the native definition/interface, arguments, guard/access
requirements, cooldowns, observable result and cancellation/stop criteria. Only
then join actual account and Workspace observations, add a Brain decision and
bounded scheduled action, and add offline contract/decision regressions. Publish
the bundle for the owner's execution. Absent or uncertain server contracts are
documented; do not guess commands or mark a feature verified from a successful call.

## Remaining phase review

The following are research entry points, not approved APIs or completed features.
Exact command names/argument schemas must be inspected in the corresponding phase.
Permanent and event definitions may persist after gameplay is unavailable.

| Phase | ReplicatedStorage research first | Account/world facts and required verification |
| --- | --- | --- |
| 1: Account intelligence / Brain | Verified Client.Framework.Services.LocalData; Shared.Data.Worlds/Gum/Flavors/Mastery and StatsUtil | Preserve owner-approved account reading/goals. Definitions describe possibilities; actual LocalData records describe progress. |
| 2: Farming / bubbles / selling / upgrades | Shared.Utils.GetPickupZones, Shared.Data.Worlds/Gum/Flavors, Assets.Pickups, Remotes.Pickups, Client HUD/Activation/GumShop/WorldMap and Remote wrapper | Actual spawn IDs, radius, positions, discovered access, arrival and balance credit. Pickup-first cooperative blowing, bounded optional isolation, selected-island execution and sell-return cycles; owner must verify these fixes. |
| 3: Island / world progression | Shared.Data.Worlds, Shared.Utils.WorldUtil and native WorldMap/gate client behavior | Distinguish discovered areas from world access; inspect exact progression commands/requirements before implementing. Verify received unlock membership and destination arrival. Not started. |
| 4: Pets / eggs / inventory | Shared.Data.Pets/Eggs, Assets, GetEggPool/GetPetModel/EnchantUtil and relevant Client/remotes | Actual inventory/equipped IDs, capacity, affordability and ownership changes. Confirm native hatch/equip/craft contracts; consuming/deleting requires explicit enabled configuration. Not started. |
| 5: Mastery / rewards | Shared.Data.Mastery/DailyRewards/Playtime/WorldRewards and related Client/remotes | Actual level, claim availability, costs and received level/reward changes. No assumption that a catalog tier is purchasable. Not started. |
| 6: Quests / shops / consumables | Shared.Data.Quests/Shops/Powerups/Potions, ShopUtil, related Client/remotes | Actual objective/stock/ownership, budgets, cooldowns and confirmed claims/purchases/consumption. Not started. |
| 7: Rifts / advanced eggs / minigames / worlds | Shared.Data.Rifts/Minigames/RiftSummonCosts/Eggs; XLEggUtil/FragmentUtil/ShadowRealmUtil and relevant Client/remotes | Verify live availability, prerequisites, native command schemas, exclusive activity/movement constraints and actual rewards; no unsupported batch/skip interfaces. Research names found are not execution proof. Not started. |
| 8: Seasonal events / status UI | Shared.Data.Events/SpecialEvents/Seasons and event-specific Client/Shared utilities/assets | Live event availability and account event fields must both support the task. Retained catalogs do not enable unavailable events. Extend the existing UI rather than create competing controls. Not started. |
| 9: One-Click integration / reliability | Previously inspected interfaces shared through GameKnowledge and existing adapters | Reconcile goals, reserves, task leases, lifecycle, respawns/streaming, stale results and rate attribution. Validate each owner-tested flow and regressions; no unverified feature promoted merely by integration. Not started. |

## Delivery rules

Studio remains unchanged and read-only. All sources and the generated bundle live
in ryanrooflead-source/OCscript. Central OCConfig naming and custom Config entry
remain unchanged. Each fix rebuilds, compiles/tests, commits/pushes and verifies the
public raw URL. The owner runs the loader and reports results; phase approval is
explicit. Phase 3 cannot begin until Phase 2 is approved.

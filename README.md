# BGSI OC — automation- migration

Current destination: **[Whispfl/automation-](https://github.com/Whispfl/automation-)**, branch **main**. The trailing hyphen is part of the repository name. Migration preserves the existing main ancestry, unpublished source/tests/configuration, both completed research libraries, and build **005f77211830**. No gameplay implementation or default setting was changed for migration.

Start with **[examples/MigrationVerify.luau](examples/MigrationVerify.luau)** in the owner's already-supported client runtime. It provides an editable Config with all gameplay actions OFF and spending budgets zero, then loads the matching immutable `migration-005f77211830` bundle without tokens or authentication. Older farming/equipment examples are opt-in action configurations; they are not the default migration check.

**[dist/OC.local.lua](dist/OC.local.lua)** still embeds the entire matching bundle and downloads no code. Its initial `TEST_MODE = "NONE"` leaves all actions OFF; the previously authorized A/B/C/D isolated presets remain available without being enabled by migration. [Local instructions and limitations](docs/LOCAL_FEATURES.md), [original delivery record](docs/LOCAL_FEATURES_DELIVERY.json), and [migration coverage/exclusions](docs/MIGRATION.md) preserve the existing evidence.

The owner reports **playtime auto-claim failure, awaiting investigation**. Owned-team success remains accepted; hatch/travel/reward/anti-AFK gameplay verification and Phase 3 limitations remain open. Migration completes no development phase and grants no new actions. Roblox Studio was untouched.

The implementation and acceptance history below is retained. Current Notion phase gates and the owner's explicit instructions control any future work.

# Preserved implementation and owner acceptance record

Phase 4 development is authorized. The owner confirmed the owned-team equipment
milestone at commit `d64b6c8a303d43a2eedd9846dcbeb8c630c1a15b`, build
`90ce16e63ccd`: Test A showed correct lineups; Test B acknowledged all 12 commands,
retained team 1 and protected Shiny Ice Kitty, and reached the frozen seven-pet
membership with stack copies. Native score changed **117 -> 1586** (about 13.6x).
The owner also observed the in-game Coin multiplier enter the **1k** range.
Coins/Gems stayed unchanged during the equipment test, and one-time authorization
ended without repeated swaps. This verifies multiplier improvement, not a precise
Coins-per-minute rate. The optimizer and equipment adapter are preserved.

The next slice explains loaded eggs against the **actual current equipped team**,
separating access, native cost, funds, protected reserves, configuration and
probability/stat evidence. It completes an isolated single-hatch ledger and
verifies the real inventory/counter result, including stacks, variants and native
usefulness. A non-improving pet can verify a hatch without being a useful upgrade.

Start with [examples/EggAnalysis.luau](examples/EggAnalysis.luau): analysis ON,
all actions OFF, zero spending budgets and no preselected egg or assumed unlocks.
EGG_PLAN reports actual Minigame Paradise access from LocalData, loaded available
affordable Coins eggs, the best evaluated eligible recommendation, where to stand,
current native price and required one-hatch budget with progression reserves.
Manually approach the recommendation; native models/proximity and account facts
refresh through the existing analysis interval. Unknown evidence remains UNKNOWN.
Hatching stays OFF until the owner explicitly authorizes a spending test after
reviewing the actual report. [examples/HatchOnceTest.luau](examples/HatchOnceTest.luau)
is an inactive template, with no selected egg and zero budgets. It supersedes the
earlier fixed-egg example. Both new examples pin the matching tested bundle release.

The analysis and eventual separately authorized first hatch keep equipment, pickups, farming, travel, bubbles, selling and
purchases OFF. Native auto-hatch must be inactive and native auto-delete empty;
OC does not change these settings. Pause preserves evidence and budgets; Stop
permanently ends this controller's one-hatch authorization. An uncertain result
never triggers another request. Reloading creates a new budget, so do not reload
the active test merely to retry. [Phase 4 evidence and test checks](docs/PHASE4.md)
records scope, limitations and the owner-confirmed final equipment lineup.

`OC:PrintPetTeam()` retains the detailed owned-team comparison. Existing
[analysis](examples/Pets.luau) and [equipment-only](examples/PetEquipTest.luau)
examples remain available. Do not repeat the equipment test as a prerequisite to
the hatch milestone. Final server odds, variants, pity and total-time ROI remain
UNKNOWN; destructive actions remain OFF. The full Phase 4 checklist is open.

Phase 1 and Phase 2's agreed stationary farming scope are owner-approved. Phase 3
is explicitly authorized; the owner confirmed all five Overworld discoveries through
actual AreasUnlocked updates in build 78b2a278c20d (approximately 41 seconds). Rejoin
persistence and actual world purchases remain pending. The owner also confirmed the
integrated discovery-skip -> actual world shortage -> Void travel -> credited stationary
farming handoff in build fdda549304a0. The approved baseline remains available
with [examples/Progression.luau](examples/Progression.luau)
and [Phase 3 evidence, controls and live checks](docs/PHASE3.md). Progression spending
and progression travel default OFF; the current Phase 3 example enables actual
world-cost shortage farming and native farming-island travel. It connects
sequential Overworld discovery through genuine UnlockHitboxes using the runtime's
optional `firetouchinterest` to the approved stationary collector. A world funding
batch stops new dispatches as soon as received balances satisfy its objective; an
affordable world waits with purchases disabled. Server-only validation rules remain
unknown, despite the owner's confirmed discovery acknowledgements.
No climbing, physics changes or movement fallback is added; correct LocalData flags
are mandatory, and a live rejoin test must establish persistence.

Phase 3 now reports measured funding rates, conditional time-to-afford and economic
bottlenecks, with native upgrade/selling recommendations that enable no actions.
Gate travel rechecks live affordability and authorization immediately before dispatch;
unsupported gate approach reports actual distance and retains the manual blocker.
See [economic findings, completion gaps and next test](docs/PHASE3-ECONOMICS.md).
The owner confirmed Pause/Resume/Stop and in-game economic diagnostics. Console
defaults to a compact summary about every 15 seconds, with immediate meaningful
events. Set DIAGNOSTIC_SETTINGS.ENABLE_DEBUG_LOGGING=true to restore detail under
the existing LOG_* flags. See [Phase 3 acceptance review](docs/PHASE3-ACCEPTANCE.md):
paid world unlocking, automatic gate approach and actual leave/rejoin persistence
remain open; no Phase 3 approval or scope deferral is inferred.

The existing Phase 2 configuration remains available below.
Stationary pickup requests now use the Flame reference's genuine-ID approach in
the existing Brain/scheduler. Only its pickup mechanism is used.

Run [examples/StationaryOnly.luau](examples/StationaryOnly.luau). The Brain's active
**Coins** requirement prefers **The Void**; **Gems** prefers **Zen**. OC checks actual
LocalData unlocks and uses native island teleportation in **The Overworld**, followed
by stable arrival. An unavailable preferred island permits only the other selected,
unlocked island, with an explicit limitation and a matching native currency pool.
[Loader.luau](examples/Loader.luau) and [PickupOnly.luau](examples/PickupOnly.luau)
contain the same complete goal-driven configuration. OC blowing, selling, exploration,
purchases and equipment changes are disabled for this currency run. With no verified
active resource need, OC waits; it does not invent a perpetual currency or bubble goal.

## Public loader

The example supplies an editable Config and this unauthenticated entry:

```lua
local OC = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Whispfl/automation-/migration-005f77211830/dist/OC.lua"
))()(Config)
```

The single dist/OC.lua returns an initializer accepting Config. Settings remain
centralized in OCConfig.luau with UPPER_SNAKE_CASE names. No tokens or headers are
required. shared.__OC_PHASE1_INSTANCE exposes controls and status; PrintAccount(100)
retains the Phase 1 account report.

## Continuous batches

- At most 32 real, classified Coins/Gems registry IDs per task, at least 50 ms
  between requests, then a confirmation window and one-second batch cooldown.
  Remaining IDs and new spawns continue in subsequent scheduled tasks.
- Fresh registry identity, current allowed island and actual LocalData unlocks
  are checked before each request. Chunker-only objects cannot fabricate IDs.
- Normally invoked IDs remain deduplicated while active. Only transport errors
  retry after backoff, at most twice per ID. Pause/Stop cancel the remaining batch.
  A genuine replacement Model or new native ID starts a fresh lifecycle.
- Distance and radius are logged, with no OC pickup distance limit. The native
  registry covers loaded pickups; OC does not force unloaded IDs into existence.
- No lifetime quota, expiry or permanent position invalidation. Old quota/time/
  drift settings are deprecated no-ops. Manual position changes permit continued
  farming once new eligible IDs are available.
- After successful dispatch, OC calls the actual native pickup Chunker's Remove,
  clears only the matching registry entry, and destroys that local visual Model.
  Failed dispatches retain their pickups. Cleanup failure holds further dispatches
  and retries cleanup with backoff; no hidden Model store is created.
- No walking, pathfinding, pickup repositioning or movement fallback. Native
  teleportation is for selected-island travel only. Already on the selected island
  means no repeated teleport; locked islands are never unlocked automatically.

STATIONARY_RESULT prints actual Coins/Gems gains, before/after balances, batch size,
processing/window times, visuals cleaned and matching-credit or inconclusive outcomes. Matching balance
increases are required for observed credit; invocation and disappearance never
establish collection success. Native collection and other rewards can contribute.
The owner confirms continuous stationary collection, cleanup and native island travel
at commit 2ac673d; the owner subsequently approved the goal-driven Phase 2 scope. Each batch
still verifies balances; individual server acceptance remains
unknown and the implementation does not assume all requests succeed.

See [test instructions and evidence limits](docs/STATIONARY_TEST.md).
[CombinedFarming.luau](examples/CombinedFarming.luau) is retained as a compatibility
filename and now supplies the same goal-driven configuration. Background blowing is
disabled even with older combined-mode settings. Full bubbles and measured bubble
income cannot select blowing or selling for a currency goal.

The reader recognizes already-received unfinished `LocalData.Quests.Tasks/Progress`
requirements through native `QuestUtil:GetRequirement`: Coins/Gems collection,
`Bubbles`, and `Sell`. It accepts or claims no quests. Bubble actions default off;
explicitly enabling their existing permission toggles still requires an active,
matching unfinished native bubble task at dispatch. Unsupported milestones or
prerequisites remain unknown and cannot trigger bubbles. Required native selling
retains the original farming island for return, including when that task finishes.

Studio tools are strictly read-only. Source inspection, offline tests and bundle
verification are not live gameplay verification. The owner-confirmed saved session
is Game; MCP cannot independently expose its actual PlaceId. See the
[ReplicatedStorage-first architecture](docs/ARCHITECTURE.md).

## Build and publication

```powershell
node scripts/build.mjs
node scripts/test.mjs
node scripts/verify-public.mjs
```

Tests compile source, examples and the function-returning bundle, retain Phase 1/2
regressions and check batching, currency evidence, deduplication, cancellation,
continuous new IDs and absence of pickup navigation. Publication compares raw main
and exact commit bytes with the rebuilt local bundle.

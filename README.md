# OCscript — approved stationary farming and Phase 3 progression candidate

Phase 1 and Phase 2's agreed stationary farming scope are owner-approved. Phase 3
is explicitly authorized; its new actions await owner live verification. Phase 4
is not authorized. Start with [examples/Progression.luau](examples/Progression.luau)
and [Phase 3 evidence, controls and live checks](docs/PHASE3.md). Progression spending
and progression travel default OFF; actual world-cost shortages may use the unchanged
stationary collector when explicitly enabled. Fresh-account ascent is blocked until
a supported discovery route is established; no fake discovery or physics bypass.

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
    "https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"
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

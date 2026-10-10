# OCscript — Phase 2 stationary pickup farming

Phase 1 remains owner-approved. Phase 2 remains unapproved; Phase 3 has not started.
Stationary pickup requests now use the Flame reference's genuine-ID approach in
the existing Brain/scheduler. Only its pickup mechanism is used.

Run [examples/StationaryOnly.luau](examples/StationaryOnly.luau) after manually
standing on unlocked **The Void** or **Zen** in **The Overworld**.
[Loader.luau](examples/Loader.luau) and [PickupOnly.luau](examples/PickupOnly.luau)
contain the same complete continuous configuration. This test disables OC blowing,
selling, exploration, travel, purchases and equipment changes to isolate balances.

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
- No lifetime quota, expiry or permanent position invalidation. Old quota/time/
  drift settings are deprecated no-ops. Manual position changes permit continued
  farming once new eligible IDs are available.
- OC never destroys pickup Models, edits the game registry, walks, pathfinds,
  repositions the character or enables a movement fallback.

STATIONARY_RESULT prints actual LocalData Coins/Gems before/after. Matching balance
increases are required for observed credit; invocation and disappearance never
establish collection success. Native collection and other rewards can contribute.
**Distant collection remains unverified pending owner gameplay results.**

See [test instructions and evidence limits](docs/STATIONARY_TEST.md).
[CombinedFarming.luau](examples/CombinedFarming.luau) preserves cooperative background
blowing in the same lease. Native selling and island teleportation remain separately
configurable; purchase toggles stay disabled in farming examples.

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

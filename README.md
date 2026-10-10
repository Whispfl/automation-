# OCscript — Phase 2 stationary-only experiment

Phase 1 remains owner-approved. Phase 2 remains unapproved; Phase 3 has not started.
The owner's latest instruction removes movement-based pickup farming and its fallback.
Prior movement-based pickup credit is historical evidence, not stationary verification.

Use [examples/StationaryOnly.luau](examples/StationaryOnly.luau) for the next test.
[Loader.luau](examples/Loader.luau) and [PickupOnly.luau](examples/PickupOnly.luau)
contain the same isolated configuration. Manually stand on an unlocked **The Void**
or **Zen**, both in **The Overworld**, before loading OC. The initial test disables
all OC travel, exploration, blowing, selling, purchases and equipment changes.

OC sends bounded single-ID stationary requests through its existing Brain/scheduler.
It preserves the native registry, all Chunker discovery, dynamic IDs, currency
identification, verified LocalData reader, account intelligence and controls.
Walking/pathfinding/repositioning and the movement collector are removed. Old
ENABLE_CLUSTER_ROUTING=true overrides are forced false. Failed stationary requests
never enable a movement fallback.

Read [the stationary test and evidence limits](docs/STATIONARY_TEST.md) and the
[ReplicatedStorage-first architecture](docs/ARCHITECTURE.md). Studio stays strictly
read-only; all source and the generated standalone bundle live in this repository.
No scripts/objects are installed or modified in Studio and no play state is changed.
The owner-confirmed saved workspace is Game; MCP cannot independently expose its
actual PlaceId. Retained event catalogs do not establish live event availability.

## Public loader

The complete test file contains an editable Config and this unauthenticated entry:

```lua
local OC = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"
))()(Config)
```

The single dist/OC.lua returns an initializer accepting custom Config. Settings
remain centralized in OCConfig.luau with UPPER_SNAKE_CASE names. No tokens, headers
or authentication are required. The controller remains available through
shared.__OC_PHASE1_INSTANCE; GetStatus().Farming.Stationary exposes experiment
counts, limits, observed credit windows and the last Coins/Gems before/after values.
PrintAccount(100) retains the detailed Phase 1 account report.

## Experiment bounds and success evidence

- One genuine currently registered ID per scheduled attempt; actual unlocks and
  allowed island/world membership are rechecked immediately before dispatch.
- Three-second global request cooldown, fifteen-second per-ID retry backoff,
  at most two attempts per ID, 24 attempts per controller and 120 elapsed seconds
  from first dispatch. Pause/Stop retain the budget and deduplication history.
- Continuous discovery includes existing and new loaded pickups; a Chunker-only
  object without the matching native registry entry cannot dispatch a request.
- Positive matching LocalData Coins/Gems changes are required for observed credit.
  Invocation success, Model destruction/disappearance or registry removal are
  never proof. OC does not destroy Models or edit the game registry.
- Position/island change, missing balances, observed spending, sale evidence or
  cancellation discard credit attribution. No-credit results report acceptance
  as unknown; no walking, unlocking, forced loading or validation bypass follows.

Outside-native-radius requests are explicitly **experimental**. Server validation
is unavailable, and a positive balance window may include native collection or
external rewards. Distant collection is not declared working before owner evidence.
Offline tests and source inspection are not live gameplay verification.

## Owner checks

Observe a short stationary native baseline, then run the isolated configuration
without moving, claiming rewards or manually blowing/selling. Send INIT,
PICKUP/SOURCES, STATIONARY_REQUEST and STATIONARY_RESULT logs with actual Coins/Gems
changes and distances/radius. Verify new IDs participate without a toggle, no OC
walking/teleportation occurs, limits stop requests, and Pause/Stop cancel attempts.
An already dispatched request may settle later; the game-owned native collector
continues independently. Test the other accessible selected island in a separate
manually positioned reload. Compare Coins and Gems separately.

[CombinedFarming.luau](examples/CombinedFarming.luau) preserves a later cooperative
stationary/blowing comparison with isolation explicitly disabled. It still disables
selling and travel. Future native island/selling travel must be separately configured
and never introduces pickup walking. The upgrade example remains deferred and is
not part of the initial experiment. No unrelated code from the old reference is used.

## Build and publication

```powershell
node scripts/build.mjs
node scripts/test.mjs
node scripts/verify-public.mjs
```

Tests compile the modules, examples and function-returning bundle, preserve relevant
Phase 1/Phase 2 regressions, and verify stationary scope, ID freshness, credit,
request bounds, cancellation and absence of automatic navigation. Each fix publishes
source and rebuilt bundle, then compares public raw main and commit bytes locally.
Earlier implementation history remains in docs/PHASE2.md, PICKUP_FIRST.md and
STATIONARY_PICKUP_RESEARCH.md, marked as superseded where appropriate.

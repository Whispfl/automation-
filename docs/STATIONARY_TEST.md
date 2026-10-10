# Stationary-only Phase 2 experiment

The owner's latest instruction removes movement-based pickup farming. This build
implements a controlled stationary experiment, not a verified distant collector.
Phase 2 remains unapproved and Phase 3 is not implemented.

## Runtime behavior

The existing OCBrain selects a pickup task and TaskScheduler grants the normal
single foreground lease. StationaryExperiment chooses one classified Coins/Gems
record. GameMechanics rechecks actual LocalData unlocks, The Void or Zen in The
Overworld, configured selection, current island, the genuine native registry key,
live Model and native radius, then invokes CollectPickup with that key. The
request's server acceptance remains unknown.

Outside-native-range probing is an explicit experimental setting. It changes no
position, native radius, validation, ID or game data. Server rules remain in force.
The registry covers loaded Models, not every island pickup. Chunker-only objects
without a matching registry entry cannot dispatch. GameKnowledge, the reader cache,
registry/Chunker discovery, spawn metadata, currency identification and central
controls remain in use. Spawn listeners observe data and never send requests.

Walking/pathfinding and the movement collector have been removed. The old Walk
entry point rejects calls; ENABLE_CLUSTER_ROUTING is forced false even if an old
Config passes true. Legacy route timing keys remain accepted but have no navigation
effect. No runtime MoveTo, pathfinding or repositioning call exists. Future selling
can use separately configured native travel/activation, never pickup walks.

## Limits and controls

The initial Config permits one ID per scheduled attempt, a three-second global
cooldown, fifteen seconds between retries of an uncredited ID, two attempts per
ID, and 24 dispatched attempts per controller. Credit windows are bounded by the
existing action slice/confirmation timeout and the session deadline. The experiment
expires after 120 elapsed seconds from first dispatch. Budgets never refill
automatically and exhaustion never enables movement.

Per-ID state deduplicates repeated scans; new spawns enter the same candidate set.
Observed-credit IDs are not retried. Invocation errors consume an attempt because
delivery can be uncertain. Invalid IDs, locked islands and missing data do not send.

Pause/Stop immediately cancel the foreground token. No further OC request or
cooperative blow follows cancellation, and the credit window is discarded. An
already dispatched request cannot be recalled; the native game collector continues
independently. Retry counts and session limits survive Pause/Stop. Position/island
change after first dispatch invalidates the experiment. After manual repositioning,
explicitly reload for a new test.

## Credit evidence and its limits

Results print actual LocalData Coins/Gems before and after, ID, distance, native
radius and whether that target was outside the radius at dispatch. Positive
matching currency change is required for creditObserved=true. Invocation success,
Model disappearance and registry removal cannot establish credit. OC never destroys
pickup Models, clears the game registry, fabricates IDs or forces Chunker loading.

Missing balances, observed spending, bubble decrease/sale evidence, root drift over
0.5 studs, island change or cancellation invalidate the credit window. Explicit
stationary samples include cooldown/idle time between windows and do not double
count observer snapshots. Combined rates still require actual growth, pickup credit,
sale and return; an unsold background blow cannot produce a currency income rate.

Even matching currency credit cannot identify one request's contribution when the
native collector or external rewards contributed. Status keeps server acceptance
UNKNOWN and the method experimental. An outside-range target plus a positive balance
window alone does not prove distant collection. No-credit results cannot distinguish
server rejection from delayed/missing credit; they report acceptance as unknown.

## Initial owner test

Use the complete examples/StationaryOnly.luau Config and public raw loader.
Loader.luau and PickupOnly.luau contain the same isolated test.

1. Manually stand on unlocked The Void or Zen in The Overworld, away from sell/
   teleport activations. Record Coins/Gems and observe a short stationary native
   baseline first. Do not manually collect, blow, sell, claim rewards or purchase.
2. Run OC and check INIT build ID and PICKUP/SOURCES discovery. Automatic island
   selection/exploration/travel, blowing, selling, upgrades and equipment changes
   are disabled. Executor isolation also blocks stale non-pickup tasks.
3. Let the bounded test run without moving. Send STATIONARY_REQUEST and
   STATIONARY_RESULT logs, including distances/radius and actual Coins/Gems deltas.
   Check new IDs enter without toggling. Persistent Models with no currency gain
   are not successful collection.
4. Test Pause/Stop during a window. Confirm no later OC attempt until explicit
   resume/start and no request-counter reset. Drift, expiry and budget exhaustion
   must leave collection inactive.
5. Stop, manually position on the other accessible selected island and reload for
   a separate experiment. Never unlock automatically. Compare actual Coins/Gems
   deltas and durations separately; no island winner is claimed before owner data.

CombinedFarming.luau retains a later stationary/background-blowing comparison with
isolation explicitly disabled. It still disables selling and travel. Use the
isolated configuration first. Future selling/travel requires separate configuration
and uses the existing guarded native adapter. The upgrade example remains deferred.

## Verification boundary

Native source inspection, compilation, static checks, offline regressions and
public byte comparison validate implementation behavior. They cannot verify live
stationary credit or distant server acceptance. Studio remains strictly read-only;
the owner performs gameplay testing.

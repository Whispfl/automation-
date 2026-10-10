# Continuous stationary pickup farming — Phase 2 candidate

Phase 2 remains unapproved. Phase 3 is not implemented. Studio remains read-only;
the owner performs live gameplay tests.

## Collection

The Flame reference's pickup mechanism iterates Tutorial._activePickups and sends
each real key to Remotes.Pickups.CollectPickup. OC uses this ID/request approach
only, including the owner's newly authorized post-dispatch visual cleanup. It does
not import the reference UI, other automation, bulk registry clearing or fragile
Rendered:GetChildren()[14] listener.

The existing GameKnowledge, reader cache, registry/Chunker discovery and currency
classification feed the existing Brain and single foreground scheduler task.
Spawn listeners only observe metadata. Each task sends at most 32 classified,
currently registered Coins/Gems IDs, paced at least 0.05 seconds apart. Remaining
IDs and newly detected spawns enter subsequent batches after the confirmation
window and a one-second batch cooldown. Each dispatch rechecks the genuine
registry key/Model, actual LocalData unlocks and selected current-island identity.
Only The Void and Zen in The Overworld are eligible. No native bulk remote is
invented: a batch consists of individual native CollectPickup requests.

Normally invoked IDs are deduplicated even if their Models persist and no currency
arrives. Invocation success is not collection success. Only transport errors may
retry, after 15 seconds and at most two attempts per ID; delivery is uncertain.
Deduplication follows ID and Model identity: a genuine replacement Model starts a
fresh lifecycle, while the same Model unloading/reloading stays deduplicated. New
native IDs are eligible after normal pacing. Deduplication survives Pause/Stop and
short Chunker unload/reload cycles. OC prunes
its own retired-ID history after 60 seconds absent from the native registry.
Model references in diagnostics are weak. It never changes character position
or native range; selected-island travel uses only the native Teleport command.

## Post-dispatch visual cleanup

Read-only Studio inspection found that ClientScript shares its ID/Model table with
Tutorial._activePickups and adds native spawns to a private Chunker. Its native
collector destroys the Model and calls Chunker.Remove; the Chunker's Unloaded
handler clears registry and animation references. Destroying the Model and clearing
the registry alone would leave native chunk references that could later reload.

OC uses the cached Shared.Utils.Chunker module and temporarily observes the real
receiver of native Update calls. Original arguments/results are preserved and no
action is chosen there. The observer restores Update immediately on capture, after
a bounded observation timeout, or on Pause/Stop/Destroy. Folder identity and real
registered loaded Models identify the pickup Chunker. No getgc/upvalue access or
separate automation loop is introduced. Missing receiver evidence blocks dispatch
with an explicit reason rather than destroying objects with unknown native owners.

After an adapter invocation succeeds, the same foreground task calls native Remove,
clears only the matching registry entry if still present, destroys that local Model
and releases tracker/metadata references. No hidden-model store is used. A failed
invocation leaves the pickup intact. A cleanup failure holds at most one pending
record, blocks further dispatches and retries cleanup with the existing 15-second
backoff without sending that ID again. A conflicting replacement registry entry is
preserved and reported as a blocker. Expired absent spawn metadata is reclaimed.

Local cleanup cannot establish credit. The collector keeps actual LocalData checks
before/after each batch and logs visualsCleaned separately from Coins/Gems gained.

## Automatic island travel

The ready configuration enables AUTO_SELECT_BEST_ISLAND and AUTO_TRAVEL_BEST_ISLAND,
with PREFERRED_FARMING_ISLAND = "Zen" and SELECTED_ISLANDS = {"The Void", "Zen"}.
The existing policy checks actual LocalData world/island access before selecting
Zen or The Void. If neither has confirmed access, it reports the blocker and never
requests an unlock or invalid teleport. A missing preferred island can fall back
to the other approved catalog island. It does not farm the main world or other islands.

Native WorldMap.TeleportTo/WorldUtil evidence establishes the Teleport command and
Workspace.Worlds.<world>.Islands.<island>.Island.Portal.Spawn argument. OC reuses
that adapter path, waits for observed island/character arrival, then applies the
existing three-second pickup arrival grace. It does not teleport again when already
on the selected island, or switch because pickups are temporarily absent. Failed
requests/unconfirmed arrival back off using the existing travel cooldown settings.
Pause/Stop prevent new teleports and collection. This is island travel only; there
is no per-pickup travel, walking, jumping, pathfinding or repositioning fallback.
When selling is separately enabled later, the existing origin/return state is retained.

There is no lifetime request quota, test expiry or original-position anchor.
The old quota/duration/drift settings remain accepted as deprecated no-ops for
existing Configs. STATIONARY_EXPERIMENT is accepted as an old method name and
normalized to STATIONARY. Position changes never permanently disable collection.
An island change or missing root discards only the current credit window; the
scheduler can resume with new eligible IDs once the character is on an allowed,
unlocked island. Outside the allowed islands OC sends no pickup requests.

Pause/Stop cancel the foreground token. Cancellation is checked before every
dispatch, during pacing waits and during credit observation. No remaining batch
requests or cooperative blows follow cancellation. Dispatched requests cannot be
recalled, and the game's own native collector runs independently.

## Balance evidence

STATIONARY_REQUEST logs genuine IDs, currency, distance and native radius when
available. Distance/radius are always diagnostic and never prevent real-ID requests.
The old STATIONARY_ALLOW_OUTSIDE_NATIVE_RANGE setting is a deprecated no-op; even
false does not add an OC distance limit. Server validation remains in force.
STATIONARY_RESULT logs batch size, dispatch processing seconds, full balance window
seconds, actual Coins/Gems before/after and signed gains, plus an explicit matching-
credit or inconclusive outcome. Cancelled batches also log final available balances
and timing, but do not establish credit or add an earnings sample.

Invocation success, Model disappearance and registry removal never establish
credit. Missing balances, observed spending, bubble sale evidence, island/root
change or cancellation discard the window's attribution. Actual positive matching
balances are recorded without attributing credit to individual batch IDs. Native
collection, manual movement and external rewards can contribute. The owner reports
continuous stationary batches earning actual Coins and Gems, following earlier Zen
outside-native-radius balance observations. This is
live balance evidence, not proof that every distant request succeeds or that all
server distance rules are known. Each batch still checks actual LocalData changes.
Repeated no-credit windows are reported honestly; no movement fallback or server
validation bypass exists.

## Ready-to-run owner configuration

Use examples/StationaryOnly.luau. Loader.luau and PickupOnly.luau contain the same
complete configuration and public dist/OC.lua loader. This is continuous farming
with isolated balance logging: blowing, selling, exploration, purchases
and equipment changes are disabled for this run. Isolation is optional and does
not impose a session limit.

1. Run the configuration with Zen or The Void unlocked. Confirm one native trip
   to Zen (or The Void if Zen is locked), or no trip if already there. Wait for
   stable arrival before the first pickup batch. Do not claim rewards or sell.
2. Check INIT build, PICKUP/SOURCES, genuine STATIONARY_REQUEST IDs and batch
   STATIONARY_RESULT Coins/Gems deltas and visualsCleaned. Requested local Models
   and registry entries should retire rather than accumulate; new spawns must enter
   without toggling. Actual currency gains remain the success check.
3. Let farming continue beyond two minutes and 24 requests if enough new IDs spawn.
   Manual repositioning must not require a reload; no OC movement should occur.
4. Pause during a batch, then resume; test Stop and Start too. Remaining requests
   must cancel, and previously dispatched IDs must stay deduplicated.
5. Test Zen locked with The Void unlocked, then both locked: fallback should use
   only The Void; neither unlocked should produce a blocker and no travel. To test
   manually later, explicitly disable AUTO_TRAVEL_BEST_ISLAND in a separate run.

CombinedFarming.luau preserves cooperative background blowing in the same task,
with isolation disabled. Selling remains separately configurable. Pickup walking/
pathfinding and automatic movement fallback are absent. Cleanup and startup travel
in this build still require owner gameplay results; Phase 2 remains unapproved.

Build/compiler checks, offline regressions and public byte comparison verify the
implementation and publication. They are not live gameplay verification.

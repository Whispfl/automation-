# Continuous stationary pickup farming — Phase 2 candidate

Phase 2 remains unapproved. Phase 3 is not implemented. Studio remains read-only;
the owner performs live gameplay tests.

## Collection

The Flame reference's pickup mechanism iterates Tutorial._activePickups and sends
each real key to Remotes.Pickups.CollectPickup. OC uses this ID/request approach
only. It does not import the reference UI, other automation, Model destruction,
registry clearing or fragile Rendered:GetChildren()[14] listener.

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
its own retired-ID history after 60 seconds absent from the native registry. It
never changes the game's registry, Models, character position or native range.

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
actual Zen currency increases during some outside-native-radius requests. This is
live balance evidence, not proof that every distant request succeeds or that all
server distance rules are known. Each batch still checks actual LocalData changes.
Repeated no-credit windows are reported honestly; no movement fallback or server
validation bypass exists.

## Ready-to-run owner configuration

Use examples/StationaryOnly.luau. Loader.luau and PickupOnly.luau contain the same
complete configuration and public dist/OC.lua loader. This is continuous farming
with isolated balance logging: blowing, selling, travel, exploration, purchases
and equipment changes are disabled for this run. Isolation is optional and does
not impose a session limit.

1. Manually stand on unlocked The Void or Zen. Observe a short native baseline,
   then run the configuration without claiming rewards or manually selling.
2. Check INIT build, PICKUP/SOURCES, genuine STATIONARY_REQUEST IDs and batch
   STATIONARY_RESULT Coins/Gems deltas. New spawns must enter without toggling.
3. Let farming continue beyond two minutes and 24 requests if enough new IDs spawn.
   Manual repositioning must not require a reload; no OC movement should occur.
4. Pause during a batch, then resume; test Stop and Start too. Remaining requests
   must cancel, and previously dispatched IDs must stay deduplicated.
5. Stop and manually test the other unlocked selected island. Compare actual Coins
   and Gems per minute separately. No winner or distant credit is claimed in advance.

CombinedFarming.luau preserves cooperative background blowing in the same task,
with isolation disabled. Existing native selling/teleportation remain separately
configurable. Pickup walking/pathfinding and automatic movement fallback are absent.

Build/compiler checks, offline regressions and public byte comparison verify the
implementation and publication. They are not live gameplay verification.

# Stationary pickup research — approval pending

Historical report: the owner subsequently approved a controlled stationary
experiment and removed movement fallback. See [STATIONARY_TEST.md](STATIONARY_TEST.md)
for the current implementation and test. Distant credit remains unverified.

Research date: 2026-10-10. No stationary collector has been implemented. The
movement-based native-radius collector and the central Brain/scheduler remain
intact. Studio was inspected in Edit mode using only read-only tools. No Luau was
executed, no collection request was sent, and no Studio object/play state changed.
Phase 2 remains unapproved; Phase 3 and purchases are outside this work.

## Finding

The native client already checks loaded pickups every 0.1 seconds without requiring
movement. Its supported client path requests collection when a Model's actual
three-dimensional distance from the character root is within the profile-derived
pickup radius. A stationary character can therefore trigger the native path when
pickups are in range. Continuous discovery does not make distant pickups in range.

The old reference requests every registry ID without that distance check. Its
local deletion and remote call do not establish that the server awarded currency.
The owner reports stationary success, but this attachment has no before/after
LocalData balances, distances, or request outcomes. Actual stationary currency
credit, particularly outside the native radius, remains unverified here. The
server handler/validation contract is unavailable. No island-wide collection or
supported validation bypass is established by the remote's existence.

## Reference examined: pickups only

Only the pickup toggle callback (attachment lines 86–99) and pickup ChildAdded
callback (200–207) were analyzed. No other old-script feature was integrated.

- The initial scan iterates `Client.Tutorial._activePickups`, destroys each Model,
  clears the registry entry, and sends `CollectPickup:FireServer(id)`.
- That scan runs on the toggle transition, rather than on a scheduled repeated
  reconciliation. New collection depends on the separate ChildAdded callback.
- The callback selects `workspace.Rendered:GetChildren()[14]`. An ordinal child
  is not a stable pickup-container identity. It can miss existing pickups, later
  containers and other Chunker folders, or attach to an unrelated container.
- The callback destroys the new object before sending its name as an ID. It
  supplies no validation of source, currency, island, native range or actual credit.
- Destruction/registry edits can suppress native processing while hiding whether
  the server accepted the request. They must never become success evidence.

## Inspected native evidence and OC comparison

| Evidence | Native behavior / existing OC |
| --- | --- |
| `ReplicatedStorage.Remotes.Pickups` | Contains `SpawnPickups` and `CollectPickup` RemoteEvents. Existence alone does not verify server acceptance. |
| `ReplicatedStorage.Assets.Pickups` | Contains currency Models used for visual identification, including duplicate Gem names. An asset is not a live pickup or proof of active event availability. |
| `ClientScript:1134–1155` | Shares its active ID-to-Model table with Tutorial; constructs a 3D Chunker; computes radius through StatsUtil using LocalData. |
| `ClientScript:1234–1253,1344` | Requires root/profile, tests actual radius, locally destroys/removes the Model, then sends its ID. Runs every 0.1 seconds. Native disappearance also precedes server credit. |
| `ClientScript:1255–1325` | Loaded/Unloaded events maintain the registry. Spawn payloads carry Root/Visual/Id; positions are chosen on the client and Models are added to Chunker. |
| `Shared.Utils.Chunker:33–55,118–167` | Loaded Models are parented to the Chunker's folder; unloading removes their parent and fires Unloaded. The registry covers currently loaded pickups, not the entire island. |
| `Shared.Utils.Stats.StatsUtil:2524–2568` | Derives actual range from DefaultPickupRadius and the current profile's applicable modifiers/buffs. No movement requirement is present in the collection test. |
| `GameKnowledge:ActivePickups` | Reuses the verified reader dependency cache to expose this registry read-only. |
| `PickupTracker:_discover/_hookSpawn/_scan` | Reconciles existing registry entries, every same-name Chunker folder and legacy folder; deduplicates ID/Model sources; observes new spawn metadata continuously. No fragile numeric child selection. |
| `FarmingCoordinator:_collection` | Schedules movement through the existing mechanics adapter, stops when real radius is reached, and requires matching live currency increase for credit evidence. It never destroys pickups or sends CollectPickup itself. |
| `AccountStateReader:ReadBalances` | Reads a ready native LocalData profile; unavailable balances remain unknown. |

Existing continuous discovery already addresses the reference's one-time-scan and
container-index shortcomings. Adding an independent listener that performs actions
would compete with the native collector and OC scheduler. Nothing found justifies
replacing the verified movement fallback.

## Only The Void and Zen in The Overworld

The published next-test Config uses `SELECTED_ISLANDS = { "The Void", "Zen" }`
and `BRAIN_SETTINGS.SELECTED_WORLDS = { "The Overworld" }`. The pickup-only and
general farming examples use the same restriction. Empty compatibility defaults
are overridden by these test Configs. Farming and exploration exclude Floating
Island, Outer Space and main Overworld. Every travel request rechecks actual
LocalData world/area unlocks; there is no automatic unlocking. Selling excursions
retain a selected-island return intent.

`Shared.Data.Worlds:40–68,81–92` establishes the two islands' membership and base
currency pickup definitions:

| Island | Base coin pickup amounts | Base gem pickup amounts |
| --- | --- | --- |
| The Void | 75, 100, 150, 225 | 10, 25, 45 |
| Zen | 300, 475 | 15, 30, 50, 125 |

These are definition rewards before applicable account multipliers, not measured
credit or earnings per minute. Higher nominal amounts do not prove Zen is better:
currency mix, live availability, movement, travel, failures and selling affect yield.
OC compares the current goal currency separately using adequate observed samples,
with labeled definition estimates while evidence is insufficient. Coins and Gems
are not added together into an arbitrary score. Pickup-activity samples exclude
sale/return overhead; complete combined-cycle samples include that time. The next
owner run must establish the actual better-performing accessible island.

Any future stationary experiment is limited to these two unlocked islands too.

## Continuous process considered, not implemented

If the owner approves further work, start with observation of the existing native
stationary path. Reuse GameKnowledge/PickupTracker and the reader; let spawn events
mark observations dirty, then reconcile in the existing observer. A Brain-selected
bounded stationary observation task would hold the normal scheduler lease and
issue no movement or duplicate pickup requests. Pause/Stop and stale generations
must terminate action work, and the movement collector remains available afterward.

Only if actual evidence and a supported contract justify another action adapter
should it be considered. It would need the same allowed-island/unlock checks,
fresh server-issued IDs, live Models, native profile/radius guards, per-ID lifecycle
deduplication, bounded attempts/backoff and cancellation. It must not fabricate IDs,
edit the native registry, destroy Models, force Chunker loading, change position or
relax server validation. A direct request path may add no benefit inside the radius
because the native client already handles it. Outside-radius request flooding is
not a supported continuous design established by this research.

## Evidence needed before any replacement decision

This is a proposed owner-run experiment, not code or a test executed here:

1. Verify actual unlocks and arrive on The Void or Zen. Record island, character
   root position, current native radius, live pickup IDs/distances and actual
   LocalData Coins/Gems. Test each accessible selected island separately.
2. Establish a stationary native baseline with no OC movement or pickup requests;
   observe existing in-range pickups and later spawns while the root stays fixed.
3. Use an isolated interval without blowing/selling, purchases, manual collection
   or reward claims. Record delayed before/after balances and any other reward or
   spending event; invalidate attribution when a competing source exists.
4. Positive matching LocalData currency increases are required. Model destruction,
   registry removal, animation and a successful FireServer call are not credit.
   A currency increase alone still cannot identify a particular request if other
   sources contributed. Compare deltas with native reward possibilities and
   observed pickup events; stop at a bounded timeout rather than infer success.
5. Separately document whether all observed targets were inside native radius.
   In-range stationary success cannot establish distant-ID acceptance. No direct
   outside-radius experiment or collector is implemented/authorized in this work.

Studio read-only inspection and offline regression tests cannot supply these live
measurements. The current combined-farming test remains the implementation handoff;
stationary research awaits explicit owner approval before any method changes.

# Phase 2 — Intelligent Island Farming, Bulk Currency Collection, Bubble Farming and Upgrades

Phase 1 is owner-tested and approved. Phase 2 is an implementation candidate, **not an owner-approved gameplay pass**. The definitive input is the user's final pasted specification and [updated Notion revision](https://app.notion.com/p/3f53d7e9278d8145a85aff38d5497e12). Older requests to install/test code through Studio are superseded: all code is maintained in this repository, Studio tools are read-only, and the owner executes the published bundle.

## Latest follow-up: stationary-only experiment

The owner's critical instruction supersedes movement-based collection and fallback
requirements below. See [STATIONARY_TEST.md](STATIONARY_TEST.md). Walking/pathfinding
have been removed, genuine-ID requests are bounded through the existing scheduler,
and the initial test is manually positioned on unlocked The Void or Zen with all
other OC earning/travel actions disabled. Distant credit remains unverified.

## Earlier follow-up: pickup-first farming

See [PICKUP_FIRST.md](PICKUP_FIRST.md) for the earlier strategy, selected-island
execution, sell-return behavior, measurement rules and owner test. The following
sections retain earlier implementation history; full bubbles now interrupt active
isolated trials, and complete combined rates require return as well as sale evidence.
The separate upgrade gameplay test remains deferred. Phase 2 approval remains pending.

## Earlier follow-up: movement, combined farming and controlled upgrades

The owner now confirms pickup-only collection, respawns, repeated matching credit
(Coins413,649 →417,929) and Outer Space selection using actual observed income.
Preserve that implementation. The following additions await owner execution;
historical pending-pickup reports below describe earlier builds.

Research used the owner-confirmed `Game` session and current ReplicatedStorage
catalogs/native clients. The `.rbxl` launch filename identifies the intended saved
workspace; MCP does **not** independently expose its actual PlaceId. See the
[current reference](WORKSPACE_REFERENCE.md#current-native-research-for-movement-combined-farming-and-upgrades).
The owner reports Halloween, with inactive Leaves. Retained Fall catalogs/flags
are not active-event evidence; no event-specific automation is added.

Movement checks actual proximity, floor/root height and cumulative forward
progress rather than a fixed three-second waypoint cutoff. Normal MoveTo is
refreshed during progress. A stall, failed MoveTo or ahead-of-route blockage can
recompute from actual position within the original task deadline; exhausted
routes retain the working per-ID temporary backoff. Path/event resources and
OC-owned movement are released on every exit, including cancellation. Target
disappearance ends stale navigation; it still cannot verify currency credit.

The Brain compares goal-currency pickup-only, bubble-only and combined trials.
Combined readiness additionally requires observed bubble growth, matching pickup
credit without a mixed sale, and a completed sale within the rate window. Walking,
waiting and selling time count toward the activity measurement. A full bubble
normally sells first; brief continued collection needs measured pickup opportunity
cost exceeding estimated sale value and cannot exceed the configured full-bubble
movement delay. No further blowing occurs at the sell threshold. Confirmation
waits can finish afterward without further gameplay actions. These estimates are
decision inputs, not fabricated payouts or proof of combined profitability.

UpgradePolicy, called by the existing Brain, evaluates all catalog candidates and
returns actual blockers. MINIMUM_BLOWS_PER_FILL indicates urgency instead of
prohibiting useful intermediate gum. Fixed resource reserves remain intact;
optional goal reservation is capped to a configurable fraction of remaining
funds so a distant goal cannot silently consume the entire upgrade budget.
Both existing upgrade-name filters apply. Paid upgrades require a complete
measured bubble-income trial, explicit currency authorization, affordable cost,
native effective-stat projection and discounted estimated payback. Contrast's
base flavor gain does not multiply effective pet power. If pickups win, projected
bubble benefit must justify leaving that strategy. Shortest qualified payback
determines upgrade priority; price alone does not.

One native purchase request is issued. Verification requires **new received
ownership and observed currency deduction at least equal to native cost**; a
zero-cost catalog item requires ownership. Ownership alone or a balance decrease
alone stays unconfirmed. Owned equip requires the actual equipment field to
change. Failed verification uses existing retry backoff; successful changes clear
old efficiency samples. Concurrent rewards can conceal deductions, conservatively
leaving a real purchase unconfirmed; unrelated spending can affect attribution.
The owner must compare before/after balances and equipment in the controlled test.

### Additional configuration rules

| Setting | Effect on decisions | Prerequisites | Stop/limit |
| --- | --- | --- | --- |
| FARMING_SETTINGS.MAXIMUM_COMBINED_SELL_DELAY_SECONDS | Limit continued collection while the bubble is at its sell threshold | Combined enabled, useful live targets; Brain deferral additionally needs measured opportunity cost greater than estimated sale value | Timer ends movement; threshold blocks more blowing; native credit confirmation is read-only |
| PICKUP_SETTINGS.WAYPOINT_STALL_SECONDS | Recompute when no forward progress lasts this long | Normal path and current root/humanoid; at least1s | Original slice and recompute count bound recovery |
| PICKUP_SETTINGS.MINIMUM_WAYPOINT_PROGRESS_STUDS | Require cumulative distance improvement to refresh progress time | Actual root-to-waypoint distances; positive number | Jitter or moving away does not reset stall detection |
| PICKUP_SETTINGS.MOVE_REISSUE_SECONDS | Refresh ordinary MoveTo while a route is progressing | Same alive character and noncancelled task; at least1s | Arrival, guards, cancellation or slice deadline ends commands |
| PICKUP_SETTINGS.MAXIMUM_PATH_RECOMPUTES | Bound extra attempts after stall/block/failure | Recoverable route and remaining slice | Integer0–3; default1; zero means no recovery; exhausted IDs back off |
| UPGRADE_SETTINGS.MAXIMUM_GOAL_RESERVE_BALANCE_FRACTION | Cap distant goal savings at this fraction of post-resource-reserve funds | Goal reservation enabled, same-currency nonupgrade goal | In[0,1];1 protects all available needed goal funds; budget still applies after both reserves |
| UPGRADE_SETTINGS.ALLOWED_PURCHASE_CURRENCIES | Explicit whitelist for actual spending, default Coins only | Native nonpremium Currency cost and all economic checks | Empty denies all purchases; Robux always excluded; no Gems/Tickets/Pearls without opt-in |
| DIAGNOSTIC_SETTINGS.LOG_MOVEMENT_DIAGNOSTICS | Explain recovery and temporary skipped IDs | Console enabled and actual route issue | No new movement; bounded recovery messages and task outcome |
| DIAGNOSTIC_SETTINGS.LOG_UPGRADE_DIAGNOSTICS | Print CANDIDATE/EVALUATION/REJECTED facts for available upgrade candidates | Catalog/account evaluation and console enabled | Changed blocking conditions logged with interval/entry bounds; purchase/verification logs remain action evidence |
| ACCOUNT_SETTINGS.SELECTED_CURRENCIES | Current defaults include Candycorn26/HalloweenShards instead of retired Fall names | Actual received numeric balance | Missing remains unavailable; selecting a name does not activate an event; live pool discoveries can register further names |

PATH_TIMEOUT_SECONDS bounds computing a route only; movement uses the slice,
progress and stall limits. Purchases/equips remain disabled in central defaults
and normal farming examples. The reserved FALL_EVENT_SETTINGS names remain for
configuration compatibility, with no enabled event executor.

### Owner test packet

1. Run [CombinedFarming.luau](../examples/CombinedFarming.luau) for several minutes.
   Check isolated trial results and eventual COMBINED trials, actual bubble
   growth while walking, pickup credit, completed sales and measured strategy
   changes. A valid better bubble/pickup strategy may win. Check stall recovery,
   skipped IDs and new spawns. No purchases or equips are enabled.
2. Pause during movement and Stop during travel/collection. No new OC route,
   blow, teleport or purchase requests should follow cancellation. A previously
   sent native command may finish server-side; native radius collection and
   automatic selling can continue without OC. Statistics remain live.
3. Run [UpgradeTest.luau](../examples/UpgradeTest.luau) separately. It explicitly
   permits only Unreal Gum and Contrast using Coins, caps each at45,000, preserves
   25,000 resource Coins plus bounded goal funds, and allows a7200s estimated
   payback for this test (central default remains300s). Both named purchases may
   qualify separately. Obtain a bubble-only fill/sell sample first. Inspect
   every REJECTED reason or PURCHASE/VERIFIED ownership-and-deduction evidence;
   equipped stats should refresh after native equip. This is not a forced buy.
4. Send logs/screenshots, actual equipment/balance changes and any remaining
   movement issue. Phase 2 stays unapproved; Phase 3 is not started.

Offline checks:60 synthetic behavior tests (9 foundation,30 existing Phase 2,
21 new regressions), source/bundle compilation, static constraints, custom Config
examples and actual bundled initializer. This does not prove new live behavior.

## Island discovery follow-up, October 10, 2026

The owner verified bubble blowing and automatic selling (Coins 43,714 → 78,466; approximately 18,000 Coins/min reported). The owner subsequently confirmed island teleportation to Floating Island and Outer Space. Pickup farming and upgrade purchases remain unverified. The original candidate silently filtered off-island rows when `Portal.Spawn` was not a local part; it also omitted unknown yields and could permanently prefer measured bubbles over untested islands. Read-only inspection found correct separate native Areas: Floating Island's `Island.Pickup` Folder has Count5; Outer Space's `Island.Pickups` holds four Pickup Parts with Count2 each. Neither inspected island has `Island.Portal.Spawn`. These are configured spawn counts, not available pickup counts or measured income.

The follow-up keeps catalog islands visible with explicit reasons, associates native spawn metadata with physical island ancestry, and retains the native reward pool's Area separately. A mismatch is diagnosed/excluded rather than silently borrowing another pool. Native `WorldMap.TeleportTo` sends WorldUtil's exact path without resolving a local part; island-only travel now follows that interface for real catalog islands with live mapped zones and fresh unlock membership. It requires stable observed target identity, actual height and nearby pickup geometry before reporting arrival. Missing server destinations still time out/back off. No alternate Input-part path, CFrame move, unsupported batch request, artificial reward, or new unlock is invented.

OCBrain schedules bounded isolated PICKUPS probes for eligible current/off-island candidates after dwell, with no simultaneous blowing during that measurement. High measured bubble income cannot suppress an untested island probe. Successful arrival starts the probe; a sufficient sample plus an attempted collection and confirmed matching currency credit ends it, or timeout/location loss ends it as unverified. Failed/empty trials receive per-island/currency retry suppression. A full bubble is handled before starting a trial when selling is enabled; active isolated trials suppress unnecessary OC selling. An externally observed native bubble sale invalidates potentially mixed pickup samples; ordinary BUBBLES/COMBINED fill/sell behavior is preserved. Mode holds and exploration timestamps reset by actual island scope. Unknown rates remain unknown, and off-island availability remains unknown until observation. Configuration filters, backoff, pending sweeps and unfinished bubble samples still constrain exploration.

## Technical plan and final architecture

1. Preserve the approved account reader, profile snapshots, goal classification, controls and single-entry Config interface. Extend dependency loading to accept the actual callable `GetPickupZones` interface and discover currency names from live pools.
2. Observe native zone geometry, current location, all rendered pickup models and `SpawnPickups` metadata. Match existing models to a prefab only if its geometry signature uniquely identifies it. Skip ambiguous/noncurrency rewards rather than assume every object is a coin.
3. Let OCBrain derive the unmet useful currency goal, rank unlocked scene-present islands, compare measured activity rates, reserve important goal funds and choose exactly one action. Score one currency at a time; there is no arbitrary coin/gem exchange rate.
4. Put supported travel, radius-cluster collection, bubble production, native selling and currency upgrade/equip requests behind the existing foreground scheduler. Retain a cancelled lease until task exit; no independent gameplay loops compete for movement or spending.
5. Verify arrival and island identity, actual balance deltas, bubble changes and ownership/equipment records. Back off empty islands, failed routes, unconfirmed travel and unconfirmed purchases. Replan after each slice, account update and scene observation.
6. Extend the existing UI and console with actual activity/area/currency, candidate evidence, native collection limitation, sample duration, earning rates and confirmed/unconfirmed outcomes. Rebuild, compile, test, publish, verify the public bytes, then wait for the owner's observations.

| Module | Responsibility | Stop/completion behavior |
| --- | --- | --- |
| AccountStateReader | Original profile reader plus function-valued native dependencies and discovered balances | Missing remains unavailable; no raw-profile writes; Destroy disconnects and cancels loads/refreshes |
| PickupTracker | Live zones, unlock membership, current height/area, spawn metadata, identity, scene scans and radius coverage | No collection remotes/model removal; expired metadata/backoff pruned; ambiguous records skipped; Destroy disconnects |
| ResourceMetrics | Area/mode-specific observed positive currency deltas and elapsed time | Spending intervals excluded; old samples expire; no mode = no attributed earnings; missing values never become zero |
| FarmingPolicy / OCBrain | Goal currency, candidate scoring, mode trials/hysteresis, prerequisites, reserves and upgrade economics | Pure decision functions; configuration/access/availability filter all candidates; no side effects |
| GameMechanics | Native guards, supported Teleport/BlowBubble/shop commands and normal pathfinding | Native cooldowns, live unlock/funds checks, cooperative cancellation, bounded travel/path/confirmation waits; releases only OC-owned movement |
| FarmingCoordinator | Read-only observation and execution of the Brain's selected scheduler definition | Each action has a bounded slice/wait; Pause/Stop end attribution and movement; no autonomous action-choice loop |
| TaskScheduler / OCController | Approved queue/lifecycle with per-task timeout and generation metadata | One foreground lease; stale generation/revision rejected; pending duplicate IDs replaced; Stop/Pause cancel future work |
| OCInterface / AccountPresentation | Original statistics and controls plus farming, candidates, rates and discovered currencies | Unknown values shown unavailable; each display category can be hidden without changing task eligibility |

## Verified interfaces and limits

The native client collects one ID at a time within its actual `GetPickupRange`. No island-wide batch endpoint was found in the available client code, and the inspected server containers provide no additional contract. `BULK_COLLECT_PICKUPS` therefore enables an explicitly named **native radius cluster fallback**, not an instant sweep or array of IDs masquerading as a batch. Every scan considers the live native Tutorial._activePickups registry, all Rendered.Chunker folders and the supplemental initial Pickups folder, then qualifies current-island currency models. A cluster groups all eligible currency types inside its coverage radius; normal movement visits coverage positions and native ClientScript performs its own collection calls. If coverage includes the whole island, OC need not move between items. Otherwise multiple radius visits are necessary. OC never teleports per pickup or increases the native collection radius.

Spawn metadata binds IDs to actual root/visual definitions. Existing models may be recognized through a native-pool-qualified prefab fingerprint; otherwise they remain unidentified and are skipped until observable metadata/new spawns make identification possible. The native collector can still pick up other nearby rewards or currencies regardless of OC routing filters. Disappearance may mean collection, unloading or despawn, so it never proves currency credit. An isolated pickup cycle succeeds only when targeted models disappear and a matching received numeric currency balance increases, without an observed bubble sale; unrelated game rewards can still affect attribution and are identified as a measurement limitation.

Each supported fallback sweep freezes the currently eligible currency set. Coverage per movement time ranks its positions; goal-currency value breaks ties without converting currencies. Bounded pair midpoints can cover multiple models with one movement; remaining gems/other currency groups are still considered after the goal-currency groups disappear. New spawns join the next sweep, so they cannot indefinitely starve the old set. Failed/unavailable IDs leave the pending set and receive backoff. An executed sweep with a reachable remaining cluster is finished before ordinary best-island switching; urgent selling and actual availability failures can interrupt it. `[BULK]` logs expose sweep ID, total/pending set and each radius visit rather than claiming a single island-wide action.

Accessible island candidates require real unlock membership, a live mapped zone, a supported native destination for off-island travel and relevant currency definitions. Definitions with missing geometry/tags still appear in discovery diagnostics but are excluded from farming. Generic live special zones can be farmed at the player's current location; no special-event/fishing/VIP travel permissions are inferred. Seven Seas has no verified currency pickup pool. Streaming/missing geometry can make an otherwise unlocked island unavailable to this client observation. No new islands/worlds are unlocked in Phase 2. `AreasUnlocked[name] ~= nil` is the game's discovered-island membership; world unlocks and physical presence are recorded separately. Presence permits current-location observation, not another world's travel permission.

Selling candidates mirror native HUD's direct world Sell and unlocked `Islands.<Area>.Island.Sell` locations. Currency and Multiplier come from live attributes; missing defaults match the native interface. No nested VIP/event facility with unknown access is used. Normal travel uses the inspected Teleport command to existing eligible spawn/root paths, never a CFrame relocation. Native activation sells within its real horizontal/vertical range; OC does not duplicate SellBubble calls. Movement and blowing stop when guard modules are absent, game frames/prompts, trading, fishing, races, transitions or character death conflict with them.

Storage upgrades mean **bubble capacity through gum**. No currency purchase interface for pet inventory storage was found. Premium numeric costs, pet management, fishing, minigames, rewards, Rifts, Mastery buying, rebirths and event shops/consumables are not implemented.

## Measurement and economic decisions

`observed currency/minute = positive received balance changes × 60 / activity seconds`. Rates stay sampling until the minimum duration; each currency retains its own units. Measurements are separated by area and PICKUPS/BUBBLES/COMBINED. Combined income is reported as combined, never attributed entirely to one component. Idle availability waits and selling overhead inside a mode reduce its measured yield. Explicit travel to a different farming island ends the old mode; island ranking adds observed/estimated travel overhead separately.

Bubble trial time includes filling and selling; bubble amount alone is not income. Native automatic sales are also observed. A pending balance update gets a bounded credit confirmation wait. An incomplete bubble probe is held briefly to obtain a genuine sale cycle, bounded by the probe timeout. Complete bubble-income evidence is required for paid upgrades. Purchases reset rate samples because earning power changed.

Unmeasured island yield is an explicit estimate: weighted native pool values × zone Count × real account currency multiplier, divided by observed respawn spacing or configured unknown-cycle estimate. Travel overhead is discounted. Actual prior pickup rates supersede the estimate; current empty areas reduce availability. Respawn observations are disappearance/new-model spacing, **not an authoritative fixed server respawn timer**. Unseen off-island availability remains unknown until arrival.

Upgrade projection calls the existing capacity/power helpers with a detached profile and the proposed catalog equipment field. It never mutates or replaces the actual account snapshot. A modeled fill/sell cycle compares effective current/projected capacity and power plus observed/estimated sell travel and the native 2s sell interval. Projected incremental yield is discounted by 50%; cost divided by that gain is an **estimated payback**, not a guaranteed outcome. Base gain, capacity bottleneck, actual ownership/access, absolute cap, balance fraction and explicit goal reserves must also pass. An upgrade can be skipped even if affordable, particularly when pickup farming wins or no isolated bubble-income measurement exists.

## Configuration execution rules

All defaults are centralized in `src/OCFoundation/OCConfig.luau`. Partial overrides preserve all omitted settings; arrays replace rather than append. Configuration is fixed for a running instance: edit Config and rerun to change it. Unknown keys/types fail before actions. Existing Phase 1 settings retain their reader/goal/control semantics; historical details are in [PHASE1.md](PHASE1.md). Every new or changed Phase 2 option is covered below. All actions additionally require RUNNING controls, enabled account reading/scheduler/recommendations, real profile data and applicable native guards. Pause/Stop cancel the action lease. `false` disables OC's associated feature; it does not disable the game's own native collector or automatic sell activation.

### FARMING_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| AUTO_RESOURCE_FARM | Enable Phase 2 observation and Brain-selected actions | Approved runtime and real account | False retains Phase 1 analysis only; no farming dependencies/observation started |
| ENABLE_EFFICIENCY_COMPARISON | Use observed goal-currency mode yields and probe alternatives | Eligible supported modes | False uses eligible combined/fallback mode rather than rate comparisons |
| ENABLE_ACTIVITY_SWITCHING | Allow efficiency-based changes to a viable mode | Current mode and alternatives | False holds viable mode; unavailable modes/full bubble still need fallback/selling |
| AUTO_FARM_FALLBACK | Allow a different eligible mode when the previous mode disappears | Alternative supports the useful currency | False waits when previous mode is unavailable; selling safety still applies |
| OBSERVATION_INTERVAL_SECONDS | Sample scene/profile and request coalesced replanning | Resource farming enabled | At least1s; observer never executes gameplay |
| ACTION_SLICE_SECONDS | Bound foreground collection movement/blowing before another Brain decision | Selected farming task | Deadline ends slice; sale/purchase/travel confirmations have separate bounds |
| MINIMUM_RATE_SAMPLE_SECONDS | Require enough measured activity time before trusting per-minute yield | Balance observations for one mode/area | Below duration remains sampling |
| RATE_WINDOW_SECONDS | Keep recent efficiency evidence | Observed samples | Expire samples older than window; must cover minimum sample |
| EXPLORATION_INTERVAL_SECONDS | Retest a different eligible mode to detect changed economics | Minimum activity hold expired | No probe until interval; oldest alternative tested first |
| MINIMUM_ACTIVITY_HOLD_SECONDS | Prevent rapid viable-mode switching | Mode remains eligible | Hold expires or availability/safety invalidates mode |
| ACTIVITY_SWITCH_GAIN_RATIO | Require a fractional measured earning advantage | Comparable same-currency rates | Smaller improvements retain viable current mode; bounded probes are still possible |
| EARNINGS_CONFIRMATION_TIMEOUT_SECONDS | Wait for delayed balance credit after collection/sale | Actual pre-operation balances | Timeout reports unconfirmed; never fills in rewards |
| BUBBLE_PROBE_TIMEOUT_SECONDS | Bound initial unsold bubble-rate trial | Bubble mode, increased bubble and supported sell route | Confirmed sale or timeout permits another mode; unsold bubbles are not income |
| CURRENCY_PRIORITIES | Order fallback earning currencies | No unmet known currency goal | Stop at first supported eligible source; never merge different units |

### ISLAND_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| AUTO_EXPLORE_UNLOCKED_ISLANDS | Test unmeasured eligible islands despite high measured bubble income; prioritize a current-island trial, then oldest untested destinations | Collection, comparison, switching, native access/geometry/guards, completed dwell; no pending sweep or unfinished bounded bubble probe | False disables island exploration; active probe ends at actual sample, timeout, location/currency change or required selling |
| ISLAND_EXPLORATION_RETRY_SECONDS | Suppress repeated island/currency attempts, including failure/empty outcomes | Timestamp set when the selected action actually executes | No new exploration before interval; current observed samples also suppress unnecessary trials |
| PICKUP_PROBE_TIMEOUT_SECONDS | Bound waiting for a useful isolated PICKUPS observation after arrival or local trial start | Brain-selected probe and real current island | Enough sample ends earlier; timeout records unverified result and resumes normal decisions |
| AUTO_SELECT_BEST_ISLAND | Rank off-island unlocked currency sources and allow exploration destinations | Live mapped pool and supported native destination; missing yield remains unknown | False evaluates current farming island only |
| AUTO_TRAVEL_BEST_ISLAND | Authorize supported island/sell teleport requests | Fresh world/area membership; existing part or exact native island-only catalog destination with live zones | False uses current-island walking/in-range collection; no cross-island teleport |
| SELECTED_ISLANDS | Restrict farming destinations by actual name | Verified candidate | Empty allows all; excluded islands never selected for farming |
| MIN_ISLAND_GAIN_ADVANTAGE_PERCENT | Require net improvement before leaving useful current island | Same target currency and candidate estimates/rates | Smaller gain keeps current; unavailable island can fall back |
| MIN_ISLAND_DWELL_SECONDS | Stay on a viable island after arrival | Current area supports goal currency | Expiry or explicit availability failure allows switch; empty clusters alone do not cause immediate ping-pong |
| TRAVEL_COOLDOWN_SECONDS | Space native travel requests | Last request time | No request before interval |
| TRAVEL_CONFIRMATION_TIMEOUT_SECONDS | Bound expected arrival wait | A native request was sent | Timeout/cancellation produces no arrival success |
| TRAVEL_RETRY_COOLDOWN_SECONDS | Back off failed spawn/destination | Unconfirmed arrival/identity | Expiry allows reevaluation |
| ARRIVAL_DISTANCE_STUDS | Require actual character proximity to native destination | Alive character and existing part | Stable proximity plus matching island identity completes farming travel |
| UNMEASURED_TRAVEL_OVERHEAD_SECONDS | Estimate unknown travel cost for ranking/economics | No observed duration | Replaced by actual measured destination duration; always labeled estimate |
| UNMEASURED_COLLECTION_CYCLE_SECONDS | Estimate unknown pickup routing/respawn cycle duration | Native pool/count/multiplier; no prior cycle observation | Replaced by observed spacing/rates; not presented as measured profit |
| EMPTY_ISLAND_CONFIRMATION_SECONDS | Observe an empty arrived area before rejecting its pickup availability | No eligible pickup models on current area | New eligible model resets timer; expiry marks unavailable |
| EMPTY_ISLAND_RETRY_SECONDS | Avoid repeated visits to observed empty islands | Confirmed observation timeout | Backoff expires; newly observed eligible spawn clears it early |

### PICKUP_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| BULK_COLLECT_PICKUPS | Enable full pickup scans and native radius-cluster collection fallback | Real rendered models, identity, live area and helper radius | False removes pickup/combined tasks; no unsupported batch endpoint is called |
| ENABLE_CLUSTER_ROUTING | Add dense coverage positions beyond current character position | Normal same-height path possible | False considers current-position native radius only |
| FARM_CURRENCY_TYPES | Filter relevant route/scan currencies by actual name | Native item Type=Currency | Empty includes every detected currency; native collector may still pick up other nearby types |
| COLLECTION_REFRESH_SECONDS | Space full scans and subsequent cycles | Spawn/rendered scene available | At least1s; new state handled in subsequent scans rather than remote spam |
| ZONE_REFRESH_SECONDS | Refresh active zone geometry/definitions | Callable native GetPickupZones | Cached between refreshes; removed scene roots ignored |
| MAXIMUM_ROUTE_DISTANCE_STUDS | Limit same-island walk candidates and computed path length | Actual positions | Excessive direct/path distance rejected |
| MAXIMUM_VERTICAL_DIFFERENCE_STUDS | Prevent current-area/routing confusion across island levels | Zone Height and actual character Y | Other heights rejected; path leaving band rejected |
| MAXIMUM_CLUSTER_CANDIDATES | Bound coverage-center search cost | All models have already been scanned | Samples centers while still evaluating all records for coverage |
| COLLECTION_SETTLE_SECONDS | Wait in radius after arrival for native collection | Successful route | Time/cancellation ends wait |
| UNREACHABLE_RETRY_SECONDS | Back off IDs in failed/stalled paths | A failed attempt, not an invented unreachable flag | Expiry/new identity permits retry |
| COLLECTION_RETRY_SECONDS | Avoid instantly retrying unconsumed clusters or unfinished slices | No disappearance or slice deadline | Expiry permits another decision |
| PATH_TIMEOUT_SECONDS | Bound computation/waypoint progress waits | PathfindingService and live humanoid | Failure/timeout/cancellation releases owned movement |
| MAXIMUM_PATH_DETOUR_RATIO | Avoid long routes to apparently nearby groups | Successful computed path | Excessive path/direct ratio rejects route |

### BUBBLE_SETTINGS additions/changed executors

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| AUTO_BLOW_BUBBLES | Permit native BlowBubble in selected bubble/combined task | HUD/character/profile/lock/fishing/plaza/GUI guards pass | Full threshold, guard conflict, disabled toggle or task cancellation stops requests |
| AUTO_SELL_BUBBLES | Select accessible sell when at capacity threshold | Actual bubble amount/capacity, eligible Sell root | Real reduction and positive received balance verify sale; timeout backs off |
| AUTO_BUY_GUM | Explicit opt-in to currency gum purchases | Smart/capacity toggle, useful stat gain, bottleneck, measured payback and budget | False never purchases gum; ownership/access/funds changes cancel eligibility |
| AUTO_BUY_FLAVORS | Explicit opt-in to currency flavor purchases | Smart/flavor toggle, useful projected yield and measured payback/budget | False never purchases flavors; confirmation/backoff prevent resends |
| ENABLE_SIMULTANEOUS_BLOWING | Add combined mode and tick blow requests within pickup task | Both pickup and bubble modes independently eligible | Disabled/guard conflict removes blowing during collection; no separate action loop |
| SELL_AT_CAPACITY_RATIO | Prioritize selling as bubble occupancy reaches configured ratio | Numeric actual amount/capacity | Must be in(0,1]; reduction clears urgency |
| BLOW_COOLDOWN_SECONDS | Bound blow request frequency | Native blow permitted | At least0.5s; unknown/full capacity cannot be overridden |
| SELL_CONFIRMATION_TIMEOUT_SECONDS | Wait for native sell activation/profile update | Real activation range reached | Timeout reports failure and backs off |
| SELL_RETRY_COOLDOWN_SECONDS | Avoid repeated failed station attempts | Unavailable/unconfirmed station | Expiry reevaluates; other station/farming may be selected |

### UPGRADE_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| ENABLE_SMART_UPGRADES | Evaluate currency gum/flavor purchase or owned equip | Earning/bubble recommendations, actual accessible catalog and ownership | False submits no upgrade task |
| AUTO_EQUIP_OWNED_UPGRADES | Explicitly apply better owned gum/flavor | Supported kind toggle, actual ownership, meaningful improvement | Actual equipment change verifies completion; no purchase needed |
| ENABLE_CAPACITY_UPGRADES | Permit gum as bubble-storage improvement | Useful gain and economic checks; a small fill ratio increases urgency | False excludes gum equip/purchase; no pet-storage API invented |
| ENABLE_FLAVOR_UPGRADES | Permit flavor production improvement | Actual higher base/effective output and useful bubble mode | False excludes flavor equip/purchase |
| SELECTED_UPGRADES | Restrict purchase/equip names beyond BRAIN_SETTINGS filter | Actual verified currency-only entry | Empty allows verified candidates; excluded names never actioned |
| MAXIMUM_PURCHASE_COST | Absolute per-purchase currency cap | Real native cost table | Larger costs rejected even if balance permits |
| MAXIMUM_PAYBACK_SECONDS | Economic threshold from observed bubble yield and projected effective stats | Complete bubble-income evidence; valid native helper projections | Missing evidence/nonpositive gain/excessive estimate skips purchase |
| PURCHASE_CONFIRMATION_TIMEOUT_SECONDS | Wait for new ownership and payment, or owned equipment change | One native command issued | Timeout reports unconfirmed with ownership/deduction facts; no synthetic ownership/stat mutation |
| PURCHASE_RETRY_COOLDOWN_SECONDS | Space unconfirmed purchase/equip attempts | Command issued or confirmation pending | Backoff prevents retry storm; fresh state rechecked after expiry |
| ENABLE_GOAL_RESERVATION | Preserve selected/resource world or Mastery cost before buying secondary equipment | Goal metadata has same currency and is not that upgrade | Reserved funds excluded from both planning and actual affordability check |

### Existing budgets and new displays

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| RESOURCE_SETTINGS.COIN_RESERVE / GEM_RESERVE / TICKET_RESERVE / PEARL_RESERVE | Deduct same-currency preserved funds before pricing goals and upgrades | Numeric real corresponding balance | Purchase fails live recheck when post-reserve budget is insufficient |
| RESOURCE_SETTINGS.MAXIMUM_UPGRADE_BALANCE_FRACTION | Bound each purchase to fraction of post-reserve funds; grow upgrade savings target accordingly | In(0,1] and actual cost/funds | Cost above current fraction budget skipped |
| BRAIN_SETTINGS.MINIMUM_UPGRADE_GAIN_RATIO | Require meaningful catalog stat improvement | Current actual base/equipment definition and new definition | Insufficient gain excluded from both recommendation and executor selection |
| BRAIN_SETTINGS.MINIMUM_BLOWS_PER_FILL | Identify bubble storage bottleneck for gum | Actual effective capacity and power | Large enough fill ratio removes capacity-upgrade urgency |
| STATUS_UI_SETTINGS.SHOW_FARMING | Show activity, area, native method, counts and outcome | UI enabled | False hides this section; does not authorize/disable actions |
| STATUS_UI_SETTINGS.SHOW_FARMING_RATES | Show per-mode/per-currency rate and sample duration | Observations available | False hides rates; unavailable/sample-only remains clearly labeled |
| STATUS_UI_SETTINGS.SHOW_ISLAND_CANDIDATES | Show candidate scores and evidence | Candidate analysis available | False hides list; entries bounded by existing display limit |
| DIAGNOSTIC_SETTINGS.LOG_ISLAND_DISCOVERY | Explain catalog/zone identity, discovered vs world-unlocked/current, configured/visible/eligible/unknown counts, native destination and every exclusion | Console logging enabled and a farming decision with a goal currency | False omits discovery/zone detail; existing rate-limited decision/earnings logs remain; rows obey log-entry limit |

The existing reader toggles are also prerequisites: unavailable unlock maps block off-island travel, unavailable upgrade ownership blocks purchase/equip, and disabled account reader prevents Start. Existing UPPER_SNAKE_CASE UI/account/diagnostic settings remain supported. Future PET/FALL automation toggles still throw a clear unimplemented-feature error if enabled; generic currency pickup observation does not imply those gameplay modules exist.

## Verification and delivery status

Local checks compile every module and the standalone bundle using the official Luau CLI, check deterministic output/central configuration/no Script insertion/no client authentication/no OC pickup remote calls, run 39 synthetic foundation/farming tests, and execute the actual bundled initializer with missing-account handling and custom Config. Example Config is validated and compiled too. Regression fixtures cover inspected island topology/counts, absent local spawn paths, unknown yields, per-island probes/filters/holds, timeout/arrival evidence and keeping bubble sale credit out of isolated pickup measurement. These checks do not verify native travel, pickup matching/pathfinding, game commands, observed yield or rendered UI in the owner's runtime.

GitHub publication, exact commit/build identifiers and public-byte verification are reported at handoff. For the next pickup-isolation test the owner runs [examples/PickupOnly.luau](../examples/PickupOnly.luau) (the normal combined example remains [examples/Loader.luau](../examples/Loader.luau)) in the same runtime that passed Phase 1, then follows the [README checklist](../README.md#owner-run-verification). The phase stays **READY FOR USER TEST** until the owner confirms actual results; fixes rebuild and republish to the same repository. No Phase 3 work is authorized yet.

## Pickup collection follow-up and new settings

The owner reports verify both island teleports but no observed OC pickup collection. Native currency pickups are Models initially parented under Workspace.Rendered.Pickups, then reparented by Chunker as detailed below; IDs bind to spawn metadata and native collection is radius-only. Both Studio Edit view and the owner's runtime report show an empty initial folder, which cannot establish absence of pickups. Four same-name Gem prefab Models exist. Cold-start identification accepts duplicate same visual identities and qualifies matches through the actual native reward pool; different ambiguous visuals remain rejected. Late prefabs refresh; same-island overlapping zones share a classification, while cross-area overlap requires native metadata.

Stage nodes tagged Area=Floating Island are around Y1675–2019 and Area=Outer Space around Y5695–5996, far above those islands' surface zones (about Y420 and Y2660). Native world definitions resolve these permanent Area identities, but stage geometry is transit and excluded from island surface currency candidates, counts, estimated yields and routing. Logs show bounded summaries instead of repeated full zone lists. Normal path waypoint completion now allows the character-root offset above floor waypoints without removing horizontal/vertical safeguards.

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| ISLAND_SETTINGS.ARRIVAL_PICKUP_GRACE_SECONDS | Scan during a bounded loading grace before isolated measurement; foreground INSPECT avoids movement/blowing/selling | Confirmed native arrival or current-island probe | Grace expires; then collect eligible targets or inspect until bounded probe timeout; must be smaller than timeout |
| PICKUP_SETTINGS.ENABLE_CONTINUOUS_SCANNING | Enable all-rendered-object refresh and pickup actions, including models predating loader | Farming/collection enabled; actual native zone definitions | False prevents pickup routing/trials; no scan action; game-owned native collector is unaffected |
| PICKUP_SETTINGS.PREFAB_REFRESH_SECONDS | Rebuild live native asset identity indexes and invalidate old failed matches after delayed replication | ReplicatedStorage.Assets.Pickups exists | At least one second between refreshes; no independent loop; identity caches removed when models disappear |
| PICKUP_SETTINGS.ZONE_MATCH_TOLERANCE_STUDS | Small border tolerance for native polygon membership when metadata is unavailable | Compatible native zone height and nonambiguous area/pool | Zero means strict distance-zero containment; maximum two studs; mismatched areas still rejected |
| PICKUP_SETTINGS.PICKUP_RANGE_MARGIN_STUDS | Keep coverage anchors slightly inside actual GetPickupRange | Real profile/helper and classified eligible records | Never expands native radius; too-large margin makes coverage unavailable rather than extending range |
| DIAGNOSTIC_SETTINGS.LOG_PICKUP_DIAGNOSTICS | Log SCAN/DETECTED/CLASSIFIED/REJECTED/COLLECTION/RESULT with actual range, counts and balance evidence | Console logging enabled | Scan summaries at least five seconds apart and respect MINIMUM_LOG_INTERVAL_SECONDS; action results tied to bounded cycles |
| DIAGNOSTIC_SETTINGS.LOG_PICKUP_DETAIL_PATHS | Include paths only for rejected objects or problem zones | Diagnostic issue and console logging | At most three paths per summary; false omits paths; unchanged zone-count summaries are deduplicated |

Current empty untested areas remain UNKNOWN, not an observed 0 Coins/min. Isolated rates require disappearance plus matching credit evidence, an actual attempt and sufficient activity duration. Combined gains are labeled combined and do not verify isolated pickup income. External game rewards can still affect attribution; the owner must compare logs with observed collection. Pickup-only Config is compiled and validated to keep every bubble purchase/blow/sell and upgrade/equip option disabled. The global architecture and remaining-phase research plan are in [ARCHITECTURE.md](ARCHITECTURE.md).

## Empty initial folder: native discovery correction

The latest owner run still showed zero legacy-folder objects despite visible pickups and confirmed native per-ID collection during manual movement. Full ReplicatedStorage.Shared.Utils.Chunker inspection establishes actual reparenting into Rendered.Chunker; Client.Tutorial._activePickups exposes the native loaded ID→Model table assigned by ClientScript. This corrects the earlier incomplete spawn-parent interpretation. See [exact source trace](WORKSPACE_REFERENCE.md#native-pickup-registry-and-chunker-trace-live-empty-folder-report). Native ID origin is received SpawnPickups data; server generation/validation remains unavailable.

Discovery now reads the current registry each scan, enumerates every same-name Chunker folder, deduplicates Models/IDs across sources, rejects stale/malformed entries and reports missing sources accurately. Registry snapshots synchronize already-loaded pickups with no event replay. Model pivots supply actual positions; Root/Visual/Id spawn metadata alone cannot create a target position. Native unload/island changes invalidate targets; events/new loaded Models add subsequent targets. The tracker never edits the registry, reconstructs UUIDs, creates visuals or fires collection requests. Movement into actual StatsUtil range invokes the game-owned radius collector.

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| PICKUP_SETTINGS.ENABLE_NATIVE_REGISTRY_DISCOVERY | Prefer live ID→Model observations from Client.Tutorial._activePickups; load the already-used Tutorial module through the reader cache | Farming, collection and continuous scans enabled; Tutorial dependency READY and field is a table | False prevents registry loading/reads for discovery; missing/wrong schema stays unavailable; no mutation or action loop |
| PICKUP_SETTINGS.ENABLE_CHUNKER_DISCOVERY | Observe every actual Rendered.Chunker folder as an additional model/ID source; require native metadata or UUID-shaped native model names plus pool/geometry identity | Continuous scans and pickup collection enabled; actual loaded Chunker folders | False excludes those folders; no generic whole-Workspace crawl, position synthesis or arbitrary-ID requests |

[SOURCES] separates registry status/entries/active IDs, Chunker folder/object counts, legacy folder counts and observed spawn events/records/metadata lacking a model. [DETECTED] separates ID candidates/sources, actual positions, current-island counts and unloaded/stale entries. [CLASSIFIED]/[REJECTED] retain native pool/type evidence and precise failure reasons. [COLLECTION] reports numbered bounded radius visits, selected position/range and zero OC remote calls; native outbound call count remains unobserved. [RESULT] requires target disappearance and matching actual balance credit. UI displays registry/position/Chunker counts. Unchanged island/zone diagnostics and repeated identical fallback messages are deduplicated/rate-limited. The pickup-only example suppresses unrelated discovery rows.

Offline regression fixtures explicitly reproduce an empty legacy folder with populated native registry/Chunker, preexisting IDs without events, same-name chunk folders, unrelated chunked Models, registry replacement/unload, malformed ID-key mappings, events without exact positions and source toggles. Static checks also forbid replacing _activePickups. This proves OC logic on fixtures, not that these native sources are available in the owner's runtime. Phase 2 remains pending owner collection/credit verification; Phase 3 remains unstarted.

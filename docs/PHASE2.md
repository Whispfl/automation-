# Phase 2 — Intelligent Island Farming, Bulk Currency Collection, Bubble Farming and Upgrades

Phase 1 is owner-tested and approved. Phase 2 is an implementation candidate, **not an owner-approved gameplay pass**. The definitive input is the user's final pasted specification and [updated Notion revision](https://app.notion.com/p/3f53d7e9278d8145a85aff38d5497e12). Older requests to install/test code through Studio are superseded: all code is maintained in this repository, Studio tools are read-only, and the owner executes the published bundle.

## Island discovery follow-up, October 10, 2026

The owner verified bubble blowing and automatic selling (Coins 43,714 → 78,466; approximately 18,000 Coins/min reported). Pickup farming, island travel and upgrade purchases remain unverified. The original candidate silently filtered off-island rows when `Portal.Spawn` was not a local part; it also omitted unknown yields and could permanently prefer measured bubbles over untested islands. Read-only inspection found correct separate native Areas: Floating Island's `Island.Pickup` Folder has Count5; Outer Space's `Island.Pickups` holds four Pickup Parts with Count2 each. Neither inspected island has `Island.Portal.Spawn`. These are configured spawn counts, not available pickup counts or measured income.

The follow-up keeps catalog islands visible with explicit reasons, associates native spawn metadata with physical island ancestry, and retains the native reward pool's Area separately. A mismatch is diagnosed/excluded rather than silently borrowing another pool. Native `WorldMap.TeleportTo` sends WorldUtil's exact path without resolving a local part; island-only travel now follows that interface for real catalog islands with live mapped zones and fresh unlock membership. It requires stable observed target identity, actual height and nearby pickup geometry before reporting arrival. Missing server destinations still time out/back off. No alternate Input-part path, CFrame move, unsupported batch request, artificial reward, or new unlock is invented.

OCBrain schedules bounded isolated PICKUPS probes for eligible current/off-island candidates after dwell, with no simultaneous blowing during that measurement. High measured bubble income cannot suppress an untested island probe. Successful arrival starts the probe; a sufficient actual pickup activity sample ends it, or timeout/location loss ends it as unverified. Failed/empty trials receive per-island/currency retry suppression. Explicit selling interrupts isolated pickup attribution so bubble sale credit is not counted as pickup income; ordinary BUBBLES/COMBINED fill/sell behavior is preserved. Mode holds and exploration timestamps reset by actual island scope. Unknown rates remain unknown, and off-island availability remains unknown until observation. Configuration filters, backoff, pending sweeps and unfinished bubble samples still constrain exploration.

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

The native client collects one ID at a time within its actual `GetPickupRange`. No island-wide batch endpoint was found in the available client code, and the inspected server containers provide no additional contract. `BULK_COLLECT_PICKUPS` therefore enables an explicitly named **native radius cluster fallback**, not an instant sweep or array of IDs masquerading as a batch. Every scan considers all rendered currency models on the current island. A cluster groups all eligible currency types inside its coverage radius; normal movement visits coverage positions and native ClientScript performs its own collection calls. If coverage includes the whole island, OC need not move between items. Otherwise multiple radius visits are necessary. OC never teleports per pickup or increases the native collection radius.

Spawn metadata binds IDs to actual root/visual definitions. Existing models may be recognized through a unique prefab fingerprint; otherwise they remain unidentified and are skipped until observable metadata/new spawns make identification possible. The native collector can still pick up other nearby rewards or currencies regardless of OC routing filters. Disappearance may mean collection, unloading or despawn, so it never proves currency credit. A cycle succeeds only when a received numeric balance increases; unrelated game rewards can still affect attribution and are identified as a measurement limitation.

Each supported fallback sweep freezes the currently eligible currency set. Goal-currency value ranks its first coverage positions; remaining gems/other currency groups are still considered after the goal-currency groups disappear. New spawns join the next sweep, so they cannot indefinitely starve the old set. Failed/unavailable IDs leave the pending set and receive backoff. An executed sweep with a reachable remaining cluster is finished before ordinary best-island switching; urgent selling and actual availability failures can interrupt it. `[BULK]` logs expose sweep ID, total/pending set and each radius visit rather than claiming a single island-wide action.

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
| ENABLE_CAPACITY_UPGRADES | Permit gum as bubble-storage improvement | Small actual capacity/power fill ratio and gain threshold | False excludes gum equip/purchase; no pet-storage API invented |
| ENABLE_FLAVOR_UPGRADES | Permit flavor production improvement | Actual higher base/effective output and useful bubble mode | False excludes flavor equip/purchase |
| SELECTED_UPGRADES | Restrict purchase/equip names beyond BRAIN_SETTINGS filter | Actual verified currency-only entry | Empty allows verified candidates; excluded names never actioned |
| MAXIMUM_PURCHASE_COST | Absolute per-purchase currency cap | Real native cost table | Larger costs rejected even if balance permits |
| MAXIMUM_PAYBACK_SECONDS | Economic threshold from observed bubble yield and projected effective stats | Complete bubble-income evidence; valid native helper projections | Missing evidence/nonpositive gain/excessive estimate skips purchase |
| PURCHASE_CONFIRMATION_TIMEOUT_SECONDS | Wait for received ownership/equipment | One native command issued | Timeout reports unconfirmed; no synthetic ownership/stat mutation |
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

Local checks compile every module and the standalone bundle using the official Luau CLI, check deterministic output/central configuration/no Script insertion/no client authentication/no OC pickup remote calls, run 26 synthetic foundation/farming tests, and execute the actual bundled initializer with missing-account handling and custom Config. Example Config is validated and compiled too. Regression fixtures cover inspected island topology/counts, absent local spawn paths, unknown yields, per-island probes/filters/holds, timeout/arrival evidence and keeping bubble sale credit out of isolated pickup measurement. These checks do not verify native travel, pickup matching/pathfinding, game commands, observed yield or rendered UI in the owner's runtime.

GitHub publication, exact commit/build identifiers and public-byte verification are reported at handoff. The owner runs [examples/Loader.luau](../examples/Loader.luau) in the same runtime that passed Phase 1, then follows the [README checklist](../README.md#owner-run-verification). The phase stays **READY FOR USER TEST** until the owner confirms actual results; fixes rebuild and republish to the same repository. No Phase 3 work is authorized yet.

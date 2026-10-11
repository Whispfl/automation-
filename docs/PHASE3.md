# Phase 3 progression candidate — evidence and owner testing

Phase 2's agreed stationary farming scope is owner-approved. The attached Phase 3
request explicitly authorizes this work. These source inspections and synthetic
regressions are not live world-purchase verification or Phase 3 approval. The owner
confirmed all five Overworld discoveries through actual `LocalData.AreasUnlocked`
changes in build `78b2a278c20d`, approximately 41 seconds from a fresh zero-Coin
account. The log then selected Minigame Paradise, native cost 1,000,000,000 Coins,
with that full actual shortage; its isolated configuration correctly waited.
The owner subsequently confirmed the integrated discovery-skip -> native Void travel ->
stationary world-funding flow in build `fdda549304a0`, with actual gains of 1,300 Coins
and 25 Gems. See [economic diagnostics and remaining completion gaps](PHASE3-ECONOMICS.md)
for the latest delivery, native earning-power research and gate-travel correction.
The owner has now explicitly confirmed Pause, Resume and Stop, and ECONOMY/BOTTLENECK
diagnostics in-game. See [clean logging and final acceptance review](PHASE3-ACCEPTANCE.md)
for the current summary-mode delivery and the still-open acceptance items.
Discovery persistence after rejoining remains pending. Phase 4 remains
blocked; future reward, egg, Mastery, event and hybrid executors are not implemented.

## Implemented behavior

`AccountStateReader` builds `ProgressionGraph` from its existing native Worlds cache,
received LocalData unlock maps and live Workspace observations. Native world-gate
origins are dependency edges. Island height order identifies an exploration frontier;
it is **not** asserted to be a server-enforced prior-island requirement.

`OCBrain` prioritizes attainable progression above ordinary earning recommendations,
while retaining account consistency/inventory blockers. It calls the pure
`TravelPlanner`; `WorldProgressionManager` executes only that selected decision
under the existing `OC_GAMEPLAY` foreground lease. No new action loop or scheduler.

- Already-unlocked worlds and discovered islands are skipped from actual account flags.
- Only known native gate prerequisites and an actual finite currency shortage create
  a resource goal. Coins use The Void; Gems use Zen, with the existing verified fallback rules.
- Affordable worlds stop resource farming. Disabled spending, insufficient authorization,
  unknown access or unsupported traversal produce WAIT with an explicit reason.
- A selected major unlock reserves its native cost against unrelated upgrade spending,
  independently of the upgrade reservation fraction. Configured currency reserves remain.
- Authorized progression travel uses the existing native portal destination shape for an
  **already-discovered** gate island. It requires real origin-world/area flags, the live
  portal Spawn or existing verified island-zone arrival geometry, observed stable
  arrival, cooldown and bounded failures. Server-only destination paths follow the
  same inspected WorldMap/WorldUtil contract used by the approved collector. It skips travel
  when location observations already put the character on the gate island.
- Unlock dispatch rechecks the active Brain goal, native gate and activation range,
  actual funds, reserves, nonpremium currency authorization and explicit spending cap.
  It sends the observed native world identifier once, then waits for LocalData.
- Native world-unlock flags, rather than a successful invocation, payment alone,
  gate animations or destroyed visuals, confirm progression. Balances and observed
  deduction are logged separately because other game sources may affect them.
- Account state refreshes after acknowledgement. Pause/Stop cancel the scheduler token;
  Resume rereads actual state. A sent server request cannot be recalled. Per-world
  attempt limits, uncertainty/backoff and controller-lifetime request limits survive controls.
- Pending Phase 2 pickup cleanup and saved sell-return work finish through their existing
  path before progression takes ownership. Discovery, pickup discovery, batching,
  cleanup, pacing, deduplication and native teleportation are preserved. The integration
  adds a funding check before starting farming travel and between pickup requests:
  received balances satisfying the active world objective stop new dispatches, even
  before the next planning refresh. Missing balance evidence or a changed goal also
  holds new dispatches. Already-sent requests cannot be recalled; their actual balance
  observation window still completes. No second executor or automation loop is added.

## Native evidence inspected through read-only Studio

| Contract/fact | Native evidence | Limit |
| --- | --- | --- |
| Permanent world identifiers, order, islands, definition heights, costs | `ReplicatedStorage.Shared.Data.Worlds:6-152` | Retained Event/Removed catalogs excluded. Runtime native definitions determine costs. |
| Minigame Paradise gate | `Workspace.Worlds.The Overworld.Islands.Zen.Island.Decoration.Gate`, World attribute `Minigame Paradise` | Origin world and Zen discovery must be received in LocalData. |
| Seven Seas gate | `Workspace.Worlds.Minigame Paradise.Islands.Hyperwave Island.Island.Gate`, World attribute `Seven Seas` | Hyperwave Island is the observed prerequisite location; Zen alone does not authorize this gate. |
| World purchase | `ClientScript:2138-2326`: `UnlockCost`, command `UnlockWorld` with destination name, `WorldsUnlocked` subscription | Current saved definitions show 1,000,000,000 Coins for Minigame Paradise and 2,500,000,000 for Seven Seas; code does not hardcode those costs. Server-only rules unavailable. |
| Command wrapper | `Shared.Framework.Network.Remote:90-98` | Adapter delegates through the existing cached native module. |
| Gate activation | `Client.Activation:357-360`: horizontal distance <= Root.Size.Y / 2 and vertical difference <= 10 | Zen gate Root.Size.Y=12.167879 (approximately 6.084 studs horizontal). Its Root.CanTouch=false; the world purchase panel is distance-activated, unlike island UnlockHitbox contact. No remote requests outside this observed native interaction range. |
| Native gate UI | `Client.Gui.Unlock:16,88-90`, `GuiFrame:170-198` | Only the expected `World <Order>` Unlock panel may coexist with the request; other prompts, trading, races, fishing and WorldMap block it. |
| Island teleport | `WorldMap:168-198`, `WorldUtil:110-115`, `ClientScript:1440-1530` | Requires discovery. No invented discovery remote or locked-island teleport. |
| World identification | `WorldUtil:18-47`; scene island Height attributes as in native HUD | Position observations do not establish discovery; missing character stays unknown. |
| Bubble/jump mechanics | `Client.Effects.Physics:6-142,259-278` | Bubble amount/settings affect native physics; OC does not alter gravity, JumpPower, velocity or settings. No safe ascent route or bubble minimum verified. |
| Mastery capability | `ClientScript:2010` checks Outer Space discovery; scene Mastery model on Outer Space | Capability exposure only; purchases/rewards deferred to Phase 5. |
| Egg/chest locations | Native `Shared.Data.Eggs`, `Shared.Data.Chests`; actual island Eggs/Chests containers | Scene containers may be empty. Container/model observations do not prove an active collectible or authorize execution. |
| Higher selling facilities | Twilight Sell has observed Multiplier=5 (native default Coins); Robot Factory Sell has Multiplier=0.2, Currency=Tickets | Actual scene attributes are exposed in island Facilities; no automatic selling enabled or payout claimed. |

Definitions in the inspected permanent catalog: Overworld islands Floating Island,
Outer Space, Twilight, The Void, Zen; Minigame Paradise islands Dice Island,
Minecart Forest, Robot Factory, Hyperwave Island. Seven Seas has no islands in this
Worlds definition; its fishing-area progression/native fast travel is a separate
contract and remains deferred. No currently inspected permanent world uses Gems for
its unlock cost; Gems routing is tested with an explicitly synthetic native-definition
fixture, not presented as a live Gems-world requirement. Code enumerates the runtime definitions rather than
embedding this list as a fake universal progression chain.

## Specific unsupported portions

**Automatic ascent is not implemented.** The owner redirected work to the stationary
hitbox experiment below before climbing was published. No walking/jumping, physics
modification or automatic climbing fallback ships. Bubble capacity is not asserted
to be a prerequisite of simulated contact; server discovery rules remain unavailable.

**Gate approach is not automated.** Portal travel may land outside the native
Activation.Root range. OC reports the exact blocker and waits for the owner to use
normal game movement into the gate activation area. No pickup walking, pathfinding,
character repositioning or jump automation is present. Future movement/hatching
coordination is not implemented. Native portal travel and gate unlocking are the
independently supported native Phase 3 actions in this candidate; the runtime
contact feature remains runtime-specific rather than a normal native discovery API.
The owner has confirmed its five Overworld account acknowledgements in a live session;
that evidence does not establish durable saves or every server validation rule.

## Stationary island discovery experiment

Read-only inspection confirmed all five actual Overworld structures expose an
anchored, noncolliding, touch-enabled `Island.UnlockHitbox` Part (512 x 30 x 512).
The inspected Y centers are Floating Island 404.565, Outer Space 2642.522,
Twilight 6844.028, The Void 10123.126 and Zen 15954.402. Code resolves each actual
Part; it does not hardcode these positions or move the character there.

`Shared.Data.Worlds` gives native array order **Floating Island -> Outer Space ->
Twilight -> The Void -> Zen**. The discovery experiment selects the first missing
actual account flag in that order, even if scene child order/heights differ or
another world is affordable. It does not assert that this order is a server rule.
When those discoveries finish, the existing resource/world policy takes over.
Pickup farming destinations remain only The Void and Zen.

The saved workspace's `ServerScriptService` has no exposed discovery handler;
script searches found no client UnlockHitbox handler or native discovery command.
`Client.Framework.Services.LocalData:107-157` receives PlayerDataLoaded and
PlayerDataChanged, replacing received fields and publishing change events.
`Client.Gui.HUD:1678-1700` renders discovered-island notifications from AreasUnlocked;
`ClientScript:1614-1636` updates portal unlocks from those same flags. **Neither the
server's contact validation nor its durable save operation can be established by
this client inspection.** A touch-enabled Part alone is not a verified contract.

The owner's reference calls `firetouchinterest(root, hitbox, 0)`, waits 0.1 seconds,
then calls phase 1. This is a runtime-specific facility, not normal Studio Luau.
No such global was found in inspected game scripts. We did not execute code in
Studio or the owner's test runtime. The adapter checks the actual global's type
at execution and exposes `WorldProgression.DiscoveryCapability` in GetStatus.
Availability means callable, not that its implementation replicates a contact or
that the game will accept it. Missing capability produces explicit WAIT.

Only `GameMechanics` invokes this optional facility. WorldProgressionManager leases
one Brain-selected island through `OC_GAMEPLAY`; no second loop or scheduler exists.
It requires actual origin-world access, actual Overworld location, a live root,
the exact native definition/model/hitbox and normal interaction guards. It skips
received discovery flags, rechecks identities before dispatch and never edits
LocalData, a hitbox, the character or a portal. Contact calls are not purchases or
world unlock commands. Failed calls are unconfirmed.

Each attempt has one begin and one cleanup end, at least ten seconds between begins
globally, thirty-second per-island retry backoff, and at most two attempts per island
per controller lifetime. A ten-second confirmation window rereads real LocalData.
Only the **correct island** changing from absent to present acknowledges discovery.
Other island flags, visuals, balances and normally returning contact calls do not.
Pause/Stop cancel waiting and prevent another begin; an already-started contact gets
one cleanup end. Attempts/backoff survive controls. A late received discovery is
skipped on Resume. Cleanup failures are reported, without retaining hidden objects.

Relevant settings under WORLD_SETTINGS:

| Setting | Default / published discovery test | Meaning |
| --- | --- | --- |
| AUTO_DISCOVER_ISLANDS | false / true | Explicit experimental discovery opt-in; no automatic ascent fallback |
| ISLAND_DISCOVERY_CONTACT_SECONDS | 0.1 | Reference phase separation, validated within 0.05–0.5 seconds |
| ISLAND_DISCOVERY_CONFIRMATION_TIMEOUT_SECONDS | 10 | Bounded actual correct-flag wait, validated within 1–30 seconds |
| ISLAND_DISCOVERY_INTERVAL_SECONDS | 10 | Global attempt pacing; minimum ten seconds |
| ISLAND_DISCOVERY_RETRY_COOLDOWN_SECONDS | 30 | Per-island uncertain-attempt backoff; minimum ten seconds |
| MAXIMUM_ISLAND_DISCOVERY_ATTEMPTS | 2 | Positive integer lifetime per-island request limit |

Live checks for this discovery delivery:

1. Start the published Progression example while your character is in The Overworld.
   No physical climb, minimum bubble amount or real balance is invented.
2. Expect `WORLD][DECISION] DISCOVER_ISLAND` and `ISLAND][ATTEMPT] The Overworld/Floating Island`.
   Missing runtime capability, game UI/interaction blockers or absent hitboxes yield WAIT.
3. Require `ISLAND][VERIFIED] Floating Island | LocalData.AreasUnlocked: absent -> present`.
   This confirms the current received account flag, **not durable save persistence**.
   The line also reports characterDelta and explicitly requires a rejoin test.
4. Subsequent goals should follow native order, skipping any already discovered islands.
   `Discovery unconfirmed` is a failed/unconfirmed attempt, followed by bounded backoff.
5. Pause/Resume/Stop during a pending attempt. No additional begin should occur while
   paused/stopped. A cleanup end may finish an existing contact. On Resume the next
   task uses current account flags, not a fabricated success record.
6. Stop OC, rejoin on the same account, then reload it and inspect actual AreasUnlocked.
   Retained discoveries should be skipped. If flags vanish, report failed persistence;
   this implementation cannot force a save. Send ATTEMPT, VERIFIED, RESULT, CONTROL
   and post-rejoin account lines. Phase 3 remains pending owner verification.

`Reached` is a current proximity observation when portal geometry and character are
available. `Discovered` and `NativePortalUnlocked` use the native AreasUnlocked flag;
the inspected client maps that discovery flag to portal unlock. World unlock uses
WorldsUnlocked separately. `TravelAvailable` records the supported native destination
contract plus discovery/access; `DestinationPartObserved` separately records local
Spawn replication. Actual travel additionally needs a local Spawn or verified live
island-zone arrival geometry. Historical reach and server-only island states remain unknown.

## One integrated initial configuration

Use [examples/Progression.luau](../examples/Progression.luau). It contains the full
editable Config and direct unauthenticated bundle loader. Stationary discovery is
enabled using the owner-confirmed mechanism. World spending and
progression portal travel are OFF, maximum world spending is 0, bubbles/selling/
upgrades/equipment changes are OFF. AUTO_FARM_UNLOCK_REQUIREMENTS, AUTO_RESOURCE_FARM
and AUTO_TRAVEL_BEST_ISLAND are ON, connecting completed discovery to actual-shortage
stationary farming and native farming-island travel. AUTO_DISCOVER_ISLANDS separately
controls discovery; AUTO_TRAVEL_FOR_PROGRESSION separately controls gate-island travel;
AUTO_UNLOCK_WORLDS and MAXIMUM_WORLD_UNLOCK_COST separately authorize world spending.
The initial gate-travel setting is false: disabled spending does not require a gate visit.
Farming destinations remain only The Void and Zen in The Overworld.

Developed account: completed flags are skipped; its first unfinished attainable
world becomes the objective. If affordable, OC waits with spending disabled; if its
known cost exceeds the actual balance, the existing shortage policy can farm when
the three farming/travel controls are enabled. With no
remaining progression/resource requirement it waits. It never spends on startup
under this configuration. Fresh/partial account: the first missing Overworld island
is tested in native order if runtime capability and live guards permit it. There is
no movement fallback. After those discoveries, an actual Coins shortage travels
natively to The Void; an actual Gems shortage prefers Zen. Farming continues through
the existing scheduler until received balances meet native cost plus any configured
reserve, Pause/Stop, or a real blocker. An affordable world waits with spending OFF.
There is no requirement to earn a billion Coins for this live integration check:
confirm discovery skips, GOAL, Void arrival and repeated credited batches, then stop.
The expensive affordability/purchase branches are covered offline.

For **one explicitly authorized live unlock**, edit the same Config before reloading:
choose the intended `WORLD_SETTINGS.SELECTED_WORLDS`, set `AUTO_UNLOCK_WORLDS=true`
and an explicit `MAXIMUM_WORLD_UNLOCK_COST` at least the logged native cost. Enable
`AUTO_TRAVEL_FOR_PROGRESSION` separately if desired. Gate-origin dependencies are
included automatically. Use your real balance/discoveries; do not change LocalData.
The initial limit is one unlock request per loaded controller, including uncertain
outcomes. A larger retry/session allowance requires an explicit Config edit; Stop
and Resume do not reset these limits. Reloading creates a new controller/ledger but
still skips every unlock actually confirmed by LocalData.

1. Run initial Config; confirm `[OC][INIT] Phase 3` and inspect actual account and goal.
2. Check `[OC][GOAL] PROGRESSION:...` and `[OC][WORLD][DECISION] WAIT ...` for affordable,
   disabled or unsupported actions. Real shortage goals retain Phase 2 `[FARM]` routing
   and `STATIONARY_RESULT` balance checks. No requirement means no earning actions.
3. For an authorized affordable gate, travel natively or position on its discovered
   origin island. If OC reports outside activation range, use normal manual movement
   into the native gate area. The matching native Unlock panel may open.
4. A dispatch prints `[OC][WORLD][REQUEST] <world> | UnlockWorld | cost=... | before=...
   | unlockBefore=false`. This line alone proves **no** unlock.
5. Confirmation must print `[OC][WORLD][VERIFIED] <world> | LocalData.WorldsUnlocked:
   false -> true | Coins before=... after=... deduction=...`, followed by
   `[OC][WORLD][RESULT] COMPLETED ... Actual LocalData world unlock confirmed; account
   refreshed` and a fresh objective excluding that completed world. No acknowledgement
   produces `Unlock unconfirmed` and backoff, not success.
6. Pause/Resume/Stop are owner-confirmed. The current logging-only delivery needs
   a summary-readability check, not another full controls test. Send SUMMARY and
   meaningful event lines; explicit debug mode retains the detailed evidence.

## Validation and changed files

`node scripts/build.mjs` and `node scripts/test.mjs` compile the source, actual bundled
initializer and all examples, enforce command isolation/no navigation/no authentication,
and run **227 deterministic regressions**: the original 175, 11 integrated
progression cases, 25 economic/gate cases and 16 logging-only cases. The economics cases cover conditional
ETA, unknown/stale/wrong-currency samples, native recommendation eligibility,
diagnostic throttling and stale gate-travel authorization/funds.
Logging comparisons preserve requests, pacing, balance reads, cleanup, cancellation,
discovery and gate verification across modes; interval changes use one balance
baseline and unknown/stale rates cannot supply a guaranteed ETA.
Fresh/partial/developed states, shortages/affordability, unknown prerequisites,
unsupported ascent, native range/UI guards, failed travel/unlock, actual flag refresh,
reserves, request limits, cancellation and 32-ID collector compatibility are covered.
Runtime capability absence, native discovery order, wrong-island updates, contact
errors, no-acknowledgement/backoff, controls, stale character identities, no movement
and explicit unverified persistence are covered. All profiles, clocks, geometry and
server responses in these tests are synthetic. The added scenarios cover a complete
five-island discovery-to-billion-Coin funding handoff, new IDs in subsequent batches,
Coins/Void and hypothetical Gems/Zen routing, permitted fallback and missing rewards,
affordability during a batch or before travel, delayed credit, changed objectives,
missing balances, Pause/Resume/Stop and billion-Coin purchase authorization/flag proof.
`scripts/verify-public.mjs` compares public main and exact-commit bundle and both
stationary/progression examples byte-for-byte after publishing.

Files changed for the previous integrated delivery (`41664a1`, historical):

- `README.md`, `docs/ARCHITECTURE.md`, `docs/PHASE3.md`
- `src/OC.luau` (corrected obsolete radius/startup scope logs)
- `src/OCFoundation/FarmingCoordinator.luau`, `StationaryExperiment.luau` (funding completion checks)
- new `tests/integration.luau`
- `examples/Progression.luau`, `scripts/test.mjs`, `dist/OC.lua`

`PickupTracker`, `GameMechanics`, `WorldProgressionManager`, `ProgressionGraph`,
`FarmingPolicy`, `TaskScheduler`, the existing Phase 2 examples and their regression fixtures are
unchanged in that previous delivery. The current economic/gate delivery updates the
Brain, manager, gate adapter/policy, evidence metadata and Config, retaining all
collector and scheduler code. Studio received read-only calls only; no live account was modified or
native command executed by these development tools.

# Phase 3 progression candidate — evidence and owner testing

Phase 2's agreed stationary farming scope is owner-approved. The attached Phase 3
request explicitly authorizes this work. These source inspections and synthetic
regressions are not live unlock verification or Phase 3 approval. Phase 4 remains
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
  path before progression takes ownership. Collector modules are unchanged.

## Native evidence inspected through read-only Studio

| Contract/fact | Native evidence | Limit |
| --- | --- | --- |
| Permanent world identifiers, order, islands, definition heights, costs | `ReplicatedStorage.Shared.Data.Worlds:6-152` | Retained Event/Removed catalogs excluded. Runtime native definitions determine costs. |
| Minigame Paradise gate | `Workspace.Worlds.The Overworld.Islands.Zen.Island.Decoration.Gate`, World attribute `Minigame Paradise` | Origin world and Zen discovery must be received in LocalData. |
| Seven Seas gate | `Workspace.Worlds.Minigame Paradise.Islands.Hyperwave Island.Island.Gate`, World attribute `Seven Seas` | Hyperwave Island is the observed prerequisite location; Zen alone does not authorize this gate. |
| World purchase | `ClientScript:2138-2326`: `UnlockCost`, command `UnlockWorld` with destination name, `WorldsUnlocked` subscription | Current saved definitions show 1,000,000,000 Coins for Minigame Paradise and 2,500,000,000 for Seven Seas; code does not hardcode those costs. Server-only rules unavailable. |
| Command wrapper | `Shared.Framework.Network.Remote:90-98` | Adapter delegates through the existing cached native module. |
| Gate activation | `Client.Activation:357-360`: horizontal distance <= Root.Size.Y / 2 and vertical difference <= 10 | No remote requests outside this observed native interaction range. |
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
contract and remains deferred. Code enumerates the runtime definitions rather than
embedding this list as a fake universal progression chain.

## Specific unsupported portions

**Fresh-account automatic ascent is not implemented.** Client source confirms that
discovery gates island portals, and that normal physics depend on bubbles. It does
not establish a safe OC ascent route, a required bubble threshold or a native island
discovery command. A fresh account reports its earliest undiscovered island and the
unverified traversal requirement. It does not assume access to The Void/Zen, invent
a bubble objective, farm at the main world or bypass discovery. Manual native
discovery followed by a fresh account snapshot advances that graph branch.

**Gate approach is not automated.** Portal travel may land outside the native
Activation.Root range. OC reports the exact blocker and waits for the owner to use
normal game movement into the gate activation area. No pickup walking, pathfinding,
character repositioning or jump automation is present. Future movement/hatching
coordination is not implemented. Native portal travel and gate unlocking are the
independently supported Phase 3 actions in this candidate.

`Reached` is a current proximity observation when portal geometry and character are
available. `Discovered` and `NativePortalUnlocked` use the native AreasUnlocked flag;
the inspected client maps that discovery flag to portal unlock. World unlock uses
WorldsUnlocked separately. `TravelAvailable` records the supported native destination
contract plus discovery/access; `DestinationPartObserved` separately records local
Spawn replication. Actual travel additionally needs a local Spawn or verified live
island-zone arrival geometry. Historical reach and server-only island states remain unknown.

## One initial configuration

Use [examples/Progression.luau](../examples/Progression.luau). It contains the full
editable Config and direct unauthenticated bundle loader. World spending and
progression portal travel are OFF, maximum world spending is 0, bubbles/selling/
upgrades/equipment changes are OFF. Stationary farming is permitted only for actual
verified shortages; set `AUTO_FARM_UNLOCK_REQUIREMENTS=false` for a pure planning run.
Farming destinations remain only The Void and Zen in The Overworld.

Developed account: completed flags are skipped; its first unfinished attainable
world becomes the objective. If affordable, OC waits with spending disabled; if its
known cost exceeds the actual balance, the enabled shortage policy can farm. With no
remaining progression/resource requirement it waits. It never spends on startup
under this configuration. Fresh/partial account: unsupported discovery prerequisites
are reported, independently attainable world actions remain eligible, and native
access flags prevent invalid travel/farming.

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
6. Test Pause/Resume/Stop during waiting, farming and (if explicitly enabled) travel.
   Send the account, GOAL, WORLD and STATIONARY_RESULT lines for owner verification.

## Validation and changed files

`node scripts/build.mjs` and `node scripts/test.mjs` compile the source, actual bundled
initializer and all examples, enforce command isolation/no navigation/no authentication,
and run **157 deterministic regressions**: the existing 132 plus 25 Phase 3 cases.
Fresh/partial/developed states, shortages/affordability, unknown prerequisites,
unsupported ascent, native range/UI guards, failed travel/unlock, actual flag refresh,
reserves, request limits, cancellation and 32-ID collector compatibility are covered.
All profiles, clocks, geometry and server responses in these tests are synthetic.
`scripts/verify-public.mjs` compares public main and exact-commit bundle and both
stationary/progression examples byte-for-byte after publishing.

Changed files for this delivery:

- `AGENTS.md`, `README.md`, `docs/ARCHITECTURE.md`, `docs/STATIONARY_TEST.md`, `docs/PHASE3.md`
- `src/OC.luau`, `src/OCFoundation/OCConfig.luau`, `OCController.luau`, `OCBrain.luau`, `OCInterface.luau`
- `src/OCFoundation/AccountStateReader.luau`, `GameKnowledge.luau`, `GameMechanics.luau`, `UpgradePolicy.luau`
- New `src/OCFoundation/ProgressionGraph.luau`, `TravelPlanner.luau`, `WorldProgressionManager.luau`
- `tests/progression.luau`, `examples/Progression.luau`, `scripts/test.mjs`, `scripts/verify-public.mjs`, `dist/OC.lua`

`PickupTracker`, `StationaryExperiment`, `FarmingCoordinator`, `FarmingPolicy`,
`TaskScheduler`, the existing Phase 2 examples and their regression fixtures are
unchanged. Studio received read-only calls only; no live account was modified or
native command executed by these development tools.

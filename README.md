# OCscript — Phase 2 test candidate

**Phase 1: USER APPROVED PASS. Phase 2: PARTIAL OWNER VERIFICATION; overall approval pending.** The owner confirmed statistics/goals, bubble blowing/selling, island travel and now pickup collection/respawns with repeated real credit (for example Coins 413,649 → 417,929). The new movement recovery, combined farming and upgrade changes await owner testing. No Phase 3 executors are added.

Intelligent Island Farming, Bulk Currency Collection Fallback, Bubble Farming and Upgrades extend the existing account reader, configuration, OCBrain, foreground scheduler, controls and status panel. All source and the generated single-file entry live in this public [OCscript repository](https://github.com/ryanrooflead-source/OCscript). Development uses Roblox Studio only as a read-only reference. No Studio objects or scripts are installed or modified.

## Pickup fix and global architecture

Use [examples/CombinedFarming.luau](examples/CombinedFarming.luau) for the next test: it selects `PICKUP_FIRST`, cooperative background blowing and only The Void/Zen in The Overworld, with purchases/equips disabled. Travel rechecks actual unlocks and selling excursions return to an eligible selected island. The separate upgrade gameplay test is deferred until the owner evaluates combined farming. Central defaults retain `EFFICIENCY` for compatibility; the explicit strategy selects the new behavior.

Read the [latest pickup-first behavior and owner checks](docs/PICKUP_FIRST.md). Farming restrictions now apply to current-island execution; selling saves a return intent. Full bubbles interrupt isolated probes. Progressing routes can continue across bounded slices, and complete combined measurements include selling/return overhead. These changes await owner gameplay verification.

Read-only research used the owner-confirmed Studio session `Game`, launched with `place 85896571713843 Bubble Gum Simulator INFINITY.rbxl`. MCP does not expose the actual PlaceId, so it was **not independently verified**. The latest native currency catalog includes Candycorn26/HalloweenShards; old Fall catalogs and event flags remain retained and cannot establish current availability. Default balance names now reflect the current catalog; missing balances stay unavailable, and Phase 2 adds no event-specific executors.

The working native registry/Chunker discovery and collection remain intact. Movement now checks actual waypoint progress, refreshes normal MoveTo while progressing, recomputes at most once by default, and backs off unreachable targets. Combined income is trusted only after actual bubble growth, pickup credit and a completed sale with enough sample time. Full bubbles have a bounded collection delay, justified only by measured opportunity cost; selling otherwise keeps priority. Upgrade diagnostics expose every actual rejection, native effective-stat projections, reserves and estimated payback. New ownership **and** the expected currency deduction are required to verify a purchase; equipping owned gear requires actual equipment change.

The global [ReplicatedStorage-first architecture](docs/ARCHITECTURE.md) applies to every phase. GameKnowledge reuses the approved dependency cache; LocalData supplies account facts, Workspace supplies live state, and the existing Brain/scheduler selects and verifies tasks. No Phase 3 executors are added.

## Run the single entry

Copy [examples/Loader.luau](examples/Loader.luau) into your already approved testing runtime, which supports `loadstring` and `game:HttpGet`. It contains one editable Config and one public download:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"
))()(Config)
```

There is no GitHub authentication in client code. Partial overrides preserve UPPER_SNAKE_CASE category/setting names; omitted keys inherit [OCConfig.luau](src/OCFoundation/OCConfig.luau). Purchases and owned-upgrade equips default to **false** in the module and standard farming examples. Only the separate controlled upgrade example explicitly enables them with caps, payback evaluation and goal reserves.

## What this candidate implements

- Real Phase 1 account observations and goals, plus dynamically discovered live currency balances.
- Goal-currency island ranking from unlocked scene zones, real pickup definitions, native stat multipliers and observed rates. Unknown availability, travel or respawn overhead is labeled **estimated**.
- Native travel to supported unlocked island destinations and accessible selling roots, with arrival checks, dwell thresholds, cooldowns and failed/empty-destination backoff. Island travel follows WorldMap's exact destination path even if its Portal.Spawn is absent locally; that request is not proof the server accepts it.
- Explicit discovery/exclusion logs for every defined permanent island, including missing geometry/tags and unknown yields, plus bounded isolated pickup trials before settling on measured bubbles.
- Native active ID-to-Model registry observations, all same-name Chunker folders, spawn metadata, native-pool-qualified prefab matching for preexisting pickups (duplicate assets with the same visual are accepted), fair frozen-set sweeps, cluster coverage and normal Humanoid pathfinding.
- Pickup, bubble and combined activity measurements; no conversion that treats a coin as equal to a gem or event token.
- Guarded `BlowBubble`, native activation selling, currency-only gum/flavor purchase/equip commands, live affordability checks and ownership-plus-payment/equipment confirmation.
- Farming, area, rates, island evidence, real balances and confirmed/unconfirmed outcomes in the existing UI and `[OC]` logs.

**Collection limitation:** the inspected native client exposes `CollectPickup(id)` and collects every pickup within `StatsUtil:GetPickupRange(profile)`. No genuine island-wide batch interface was found. OC does not send per-item collection remotes or disguise them as a batch. It groups live currency pickups into coverage clusters and walks to dense reachable positions; the native collector performs the actual per-ID calls. A cluster covering the whole island requires no per-item navigation. Other islands require multiple radius visits. This candidate cannot promise an unsupported instant sweep.

Bubble **storage** is purchased through gum. No verified pet-storage purchase interface was found. Seven Seas definitions have no currency pickup pool; fishing, hatching, unlocking new islands/worlds, Mastery spending, Rifts, rebirths and event shops/consumables remain outside this build. Live event currency pickups are observable only where actual scene zones exist; unverified special-event travel is not invented.

## Owner-run verification

1. Check `[OC][INIT]` build ID and dependency statuses; compare all Phase 1 account statistics and goals against the game.
2. Check `[OC][FARM][DISCOVERY]`, `[ZONES]` and `[ISLANDS]`: Floating Island and Outer Space should appear individually, either eligible or with an explicit exclusion. In the reference scene their configured Counts are 5 and 8 respectively; these are not live available counts. Confirm real world/discovery membership, actual loaded zone roots, target currency and unknown/estimated/observed evidence.
3. Confirm `[TRAVEL]` reports arrival at the selected island, with no rapid ping-pong travel.
4. Check [PICKUP][SOURCES] registry/Chunker/spawn counters and [DETECTED] live IDs/resolved positions. Then check [COLLECTION] eligible/cluster counts and the declared native radius fallback. Confirm actual before/after balances increase in `[EARNINGS]`; model disappearance alone is not success.
5. Let pickups respawn. Confirm new cycles occur without duplicate OC collection calls or repeated unreachable targets.
6. Allow 5–10 minutes for repeated cycles. Match `[BACKGROUND]` requests and actual bubble growth with pickup disappearance/credit during the same visits. `[CYCLE] complete=true` requires an empty initial bubble, growth, pickup evidence, sale credit and completed return; insufficient sample time still prevents a published rate. `PICKUP_ACTIVITY` rates exclude sale/return overhead and are distinct from complete combined-cycle rates. Isolated probes are opt-in under pickup-first.
7. Check `[SELL_TIMING]` dispatch age, matching station-currency credit and `[RETURN]` confirmed arrival. No deliberately routed pickups should occur on excluded Overworld; incidental native collection during selling transit can still occur. Purchases and equips must remain disabled.
8. Pause/Stop must halt OC movement and future commands; statistics keep updating. Set feature toggles false and rerun to verify exclusions. Check that rerunning leaves one hosted panel.

Send `[OC]` logs/screenshots and any mismatch. **Phase 2 remains pending until you explicitly approve it. No Phase 3 work begins before that approval.** The controller remains available at `shared.__OC_PHASE1_INSTANCE` for compatibility; `:PrintAccount(100)` prints longer account lists and `:GetStatus()` includes farming state. The initializer also returns the controller.

## Source and verification

`node scripts/build.mjs` builds deterministic private module factories into `dist/OC.lua`; game ModuleScript require stays native. `node scripts/test.mjs` checks configuration/bundle constraints, compiles all Luau sources and runs synthetic offline tests plus the actual bundled initializer. Tests require the official [Luau CLI](https://github.com/luau-lang/luau/releases), configured by `LUAU_BIN`/`LUAU_COMPILE_BIN` or ignored `.tools/luau/` binaries. Node uses no third-party packages.

See [Phase 2 plan and each configuration setting](docs/PHASE2.md), [read-only workspace interface evidence](docs/WORKSPACE_REFERENCE.md), and [historical Phase 1 architecture](docs/PHASE1.md). Static checks and synthetic tests are not live gameplay verification. The raw public artifact is downloaded without authentication and compared byte-for-byte before handoff.

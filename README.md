# OCscript — Phase 2 test candidate

**Phase 1: USER APPROVED PASS.** The owner confirmed live statistics, account progression and Brain goals in their authorized runtime on October 10, 2026. **Phase 2: READY FOR USER TEST after publication; in-game approval pending.**

Intelligent Island Farming, Bulk Currency Collection Fallback, Bubble Farming and Upgrades extend the existing account reader, configuration, OCBrain, foreground scheduler, controls and status panel. All source and the generated single-file entry live in this public [OCscript repository](https://github.com/ryanrooflead-source/OCscript). Development uses Roblox Studio only as a read-only reference. No Studio objects or scripts are installed or modified.

## Run the single entry

Copy [examples/Loader.luau](examples/Loader.luau) into your already approved testing runtime, which supports `loadstring` and `game:HttpGet`. It contains one editable Config and one public download:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua"
))()(Config)
```

There is no GitHub authentication in client code. Partial overrides preserve UPPER_SNAKE_CASE category/setting names; omitted keys inherit [OCConfig.luau](src/OCFoundation/OCConfig.luau). Purchases and owned-upgrade equips default to **false** in the module. The test example explicitly enables them with caps, payback evaluation and goal reserves. Set either purchase toggle to false to test farming without that spending.

## What this candidate implements

- Real Phase 1 account observations and goals, plus dynamically discovered live currency balances.
- Goal-currency island ranking from unlocked scene zones, real pickup definitions, native stat multipliers and observed rates. Unknown availability, travel or respawn overhead is labeled **estimated**.
- Native travel to supported unlocked island spawns and accessible selling roots, with arrival checks, dwell thresholds, cooldowns and failed/empty-destination backoff.
- Full rendered-pickup scans, spawn metadata, unique prefab matching for preexisting pickups, fair frozen-set sweeps, cluster coverage and normal Humanoid pathfinding.
- Pickup, bubble and combined activity measurements; no conversion that treats a coin as equal to a gem or event token.
- Guarded `BlowBubble`, native activation selling, useful currency-only gum/flavor purchase/equip commands, live affordability checks and ownership/equipment confirmation.
- Farming, area, rates, island evidence, real balances and confirmed/unconfirmed outcomes in the existing UI and `[OC]` logs.

**Collection limitation:** the inspected native client exposes `CollectPickup(id)` and collects every pickup within `StatsUtil:GetPickupRange(profile)`. No genuine island-wide batch interface was found. OC does not send per-item collection remotes or disguise them as a batch. It groups live currency pickups into coverage clusters and walks to dense reachable positions; the native collector performs the actual per-ID calls. A cluster covering the whole island requires no per-item navigation. Other islands require multiple radius visits. This candidate cannot promise an unsupported instant sweep.

Bubble **storage** is purchased through gum. No verified pet-storage purchase interface was found. Seven Seas definitions have no currency pickup pool; fishing, hatching, unlocking new islands/worlds, Mastery spending, Rifts, rebirths and event shops/consumables remain outside this build. Live event currency pickups are observable only where actual scene zones exist; unverified special-event travel is not invented.

## Owner-run verification

1. Check `[OC][INIT]` build ID and dependency statuses; compare all Phase 1 account statistics and goals against the game.
2. Check `[OC][FARM][GOAL]` and `[ISLANDS]`: target currency, unlocked candidates, evidence and switch reason must make sense. Confirm locked islands are excluded.
3. Confirm `[TRAVEL]` reports arrival at the selected island, with no rapid ping-pong travel.
4. Check `[BULK]` eligible/cluster counts and the declared native radius fallback. Confirm actual before/after balances increase in `[EARNINGS]`; model disappearance alone is not success.
5. Let pickups respawn. Confirm new cycles occur without duplicate OC collection calls or repeated unreachable targets.
6. Allow at least one full bubble fill/sale and several activity samples. Confirm relevant measured currency/minute, fallback decisions and simultaneous blowing where permitted.
7. Check sell-station currency/multiplier, real bubble decrease, affordable useful upgrades, ownership/equipment changes and reserves. Purchases can be intentionally skipped when no measured payback or budget supports them.
8. Pause/Stop must halt OC movement and future commands; statistics keep updating. Set feature toggles false and rerun to verify exclusions. Check that rerunning leaves one hosted panel.

Send `[OC]` logs/screenshots and any mismatch. **Phase 2 remains pending until you explicitly approve it. No Phase 3 work begins before that approval.** The controller remains available at `shared.__OC_PHASE1_INSTANCE` for compatibility; `:PrintAccount(100)` prints longer account lists and `:GetStatus()` includes farming state. The initializer also returns the controller.

## Source and verification

`node scripts/build.mjs` builds deterministic private module factories into `dist/OC.lua`; game ModuleScript require stays native. `node scripts/test.mjs` checks configuration/bundle constraints, compiles all Luau sources and runs synthetic offline tests plus the actual bundled initializer. Tests require the official [Luau CLI](https://github.com/luau-lang/luau/releases), configured by `LUAU_BIN`/`LUAU_COMPILE_BIN` or ignored `.tools/luau/` binaries. Node uses no third-party packages.

See [Phase 2 plan and each configuration setting](docs/PHASE2.md), [read-only workspace interface evidence](docs/WORKSPACE_REFERENCE.md), and [historical Phase 1 architecture](docs/PHASE1.md). Static checks and synthetic tests are not live gameplay verification. The raw public artifact is downloaded without authentication and compared byte-for-byte before handoff.

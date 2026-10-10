# OCscript — Phase 2 test candidate

**Phase 1: USER APPROVED PASS.** The owner confirmed live statistics, account progression and Brain goals in their authorized runtime on October 10, 2026. **Phase 2: PARTIAL OWNER VERIFICATION; island pickup farming and overall approval pending.** The owner confirmed blowing and automatic selling: Coins increased from 43,714 to 78,466, with approximately 18,000 Coins/min reported. The owner subsequently confirmed travel to Floating Island and Outer Space. Pickup collection and upgrades remain unverified.

Intelligent Island Farming, Bulk Currency Collection Fallback, Bubble Farming and Upgrades extend the existing account reader, configuration, OCBrain, foreground scheduler, controls and status panel. All source and the generated single-file entry live in this public [OCscript repository](https://github.com/ryanrooflead-source/OCscript). Development uses Roblox Studio only as a read-only reference. No Studio objects or scripts are installed or modified.

## Pickup fix and global architecture

Use [examples/PickupOnly.luau](examples/PickupOnly.luau) for the next isolated test: it targets Floating Island/Outer Space, scans every second, and disables OC blowing, selling and all upgrade/equip tasks. The live native Client.Tutorial._activePickups registry is now the primary ID source; all actual Rendered.Chunker folders complement it. The previous build missed native Chunker reparenting, explaining the empty initial Pickups folder despite visible objects. Existing models, same-name duplicate Gem prefabs, overlapping same-island zones and late assets are handled. Stage jump-course zones use native world/area definitions but cannot inflate island surface yields or become island navigation targets. Arrival gets a bounded loading grace; unconfirmed empty scans do not become measured zero income. Detailed pickup diagnostics summarize counts and rejection reasons without dumping hundreds of paths.

The global [ReplicatedStorage-first architecture](docs/ARCHITECTURE.md) applies to every phase. GameKnowledge reuses the approved dependency cache; LocalData supplies account facts, Workspace supplies live state, and the existing Brain/scheduler selects and verifies tasks. No Phase 3 executors are added.

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
- Native travel to supported unlocked island destinations and accessible selling roots, with arrival checks, dwell thresholds, cooldowns and failed/empty-destination backoff. Island travel follows WorldMap's exact destination path even if its Portal.Spawn is absent locally; that request is not proof the server accepts it.
- Explicit discovery/exclusion logs for every defined permanent island, including missing geometry/tags and unknown yields, plus bounded isolated pickup trials before settling on measured bubbles.
- Native active ID-to-Model registry observations, all same-name Chunker folders, spawn metadata, native-pool-qualified prefab matching for preexisting pickups (duplicate assets with the same visual are accepted), fair frozen-set sweeps, cluster coverage and normal Humanoid pathfinding.
- Pickup, bubble and combined activity measurements; no conversion that treats a coin as equal to a gem or event token.
- Guarded `BlowBubble`, native activation selling, useful currency-only gum/flavor purchase/equip commands, live affordability checks and ownership/equipment confirmation.
- Farming, area, rates, island evidence, real balances and confirmed/unconfirmed outcomes in the existing UI and `[OC]` logs.

**Collection limitation:** the inspected native client exposes `CollectPickup(id)` and collects every pickup within `StatsUtil:GetPickupRange(profile)`. No genuine island-wide batch interface was found. OC does not send per-item collection remotes or disguise them as a batch. It groups live currency pickups into coverage clusters and walks to dense reachable positions; the native collector performs the actual per-ID calls. A cluster covering the whole island requires no per-item navigation. Other islands require multiple radius visits. This candidate cannot promise an unsupported instant sweep.

Bubble **storage** is purchased through gum. No verified pet-storage purchase interface was found. Seven Seas definitions have no currency pickup pool; fishing, hatching, unlocking new islands/worlds, Mastery spending, Rifts, rebirths and event shops/consumables remain outside this build. Live event currency pickups are observable only where actual scene zones exist; unverified special-event travel is not invented.

## Owner-run verification

1. Check `[OC][INIT]` build ID and dependency statuses; compare all Phase 1 account statistics and goals against the game.
2. Check `[OC][FARM][DISCOVERY]`, `[ZONES]` and `[ISLANDS]`: Floating Island and Outer Space should appear individually, either eligible or with an explicit exclusion. In the reference scene their configured Counts are 5 and 8 respectively; these are not live available counts. Confirm real world/discovery membership, actual loaded zone roots, target currency and unknown/estimated/observed evidence.
3. Confirm `[TRAVEL]` reports arrival at the selected island, with no rapid ping-pong travel.
4. Check [PICKUP][SOURCES] registry/Chunker/spawn counters and [DETECTED] live IDs/resolved positions. Then check [COLLECTION] eligible/cluster counts and the declared native radius fallback. Confirm actual before/after balances increase in `[EARNINGS]`; model disappearance alone is not success.
5. Let pickups respawn. Confirm new cycles occur without duplicate OC collection calls or repeated unreachable targets.
6. Allow several minutes for dwell, native travel cooldowns and any pending bubble fill/sale. Look for `[EXPLORE]` and a `PICKUPS` trial (no blowing during isolation), then `[BULK]` actual before/after credit and subsequent observed rates. A trial ends after an adequate sample plus actual collection/credit evidence, or at the 45s default timeout after loading grace; repeats wait 300s by default. If native arrival fails or no tagged zones exist, send that explicit reason; manually visiting an unlocked island lets the reader reassess its geometry without inventing a route. Bubbles may legitimately win after real pickup measurement. Combined activity is evaluated separately.
7. Check sell-station currency/multiplier, real bubble decrease, affordable useful upgrades, ownership/equipment changes and reserves. Purchases can be intentionally skipped when no measured payback or budget supports them.
8. Pause/Stop must halt OC movement and future commands; statistics keep updating. Set feature toggles false and rerun to verify exclusions. Check that rerunning leaves one hosted panel.

Send `[OC]` logs/screenshots and any mismatch. **Phase 2 remains pending until you explicitly approve it. No Phase 3 work begins before that approval.** The controller remains available at `shared.__OC_PHASE1_INSTANCE` for compatibility; `:PrintAccount(100)` prints longer account lists and `:GetStatus()` includes farming state. The initializer also returns the controller.

## Source and verification

`node scripts/build.mjs` builds deterministic private module factories into `dist/OC.lua`; game ModuleScript require stays native. `node scripts/test.mjs` checks configuration/bundle constraints, compiles all Luau sources and runs synthetic offline tests plus the actual bundled initializer. Tests require the official [Luau CLI](https://github.com/luau-lang/luau/releases), configured by `LUAU_BIN`/`LUAU_COMPILE_BIN` or ignored `.tools/luau/` binaries. Node uses no third-party packages.

See [Phase 2 plan and each configuration setting](docs/PHASE2.md), [read-only workspace interface evidence](docs/WORKSPACE_REFERENCE.md), and [historical Phase 1 architecture](docs/PHASE1.md). Static checks and synthetic tests are not live gameplay verification. The raw public artifact is downloaded without authentication and compared byte-for-byte before handoff.

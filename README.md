# OCscript — Phase 1

Read-only account intelligence for the inspected BGSI client structure. The single `dist/OC.lua` bundle returns an initializer: `loadstring(source)()(Config)`. No Script, LocalScript, or ModuleScript is installed by the bundle. Development uses Studio exclusively as a read-only reference; the owner runs every in-game test.

Implemented: AccountStateReader, one centralized OCConfig, OCBrain recommendations, one foreground TaskScheduler, Start/Pause/Resume/Stop controls, detailed status panel, and `[OC]` diagnostics. No gameplay executors are implemented. The reader reports missing fields as unavailable and never creates a player profile or substitutes zero for a missing statistic.

## First test build

This repository is **private**. Its actual raw path is:

`https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua`

An unauthenticated `game:HttpGet` cannot download this private file. [GitHub's contents API](https://docs.github.com/en/rest/repos/contents#get-repository-content) supports authenticated raw-file responses. Use [examples/PrivateLoader.luau](examples/PrivateLoader.luau), enter a read-only token **only in your local runtime input**, and edit its Config table. A fine-grained token should be restricted to this repository with Contents: read. No credential is included in this repository, OCConfig, or the generated bundle.

The example expects a client testing runtime with `loadstring` and a header-capable `request`, `http_request`, or `http.request` function. These are runtime-specific capabilities, not a promise of ordinary LocalScript compatibility. Standard Roblox `loadstring` is server-only and disabled by default; a server entry cannot inspect a client's LocalData or PlayerGui. See [Roblox's loadstring documentation](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#loadstring).

For a runtime that compiles client Luau but cannot send authenticated HTTP headers: sign into GitHub, download `dist/OC.lua`, and supply that one file as source using your authorized runtime's file/source input. If it supports `readfile`, the entry is:

```lua
local Config = { GENERAL_SETTINGS = { AUTO_START = true } }
local OC = loadstring(readfile("OC.lua"))()(Config)
```

This does not require adding scripts to the Studio project. A normal LocalScript-only runtime has no compatible dynamic client entry for this design; report your runtime capabilities so the entry can be adapted without claiming it works.

## In-game verification checklist

1. Join the authorized client test environment, allow the game's account to load, then run the loader. Capture the `[OC][INIT]` build ID and all `[OC][DEPENDENCY]` messages.
2. Compare exact coins, gems, bubbles, effective capacity, and bubble power against the game's account UI. Missing seasonal balances should show unavailable, not zero.
3. Compare the active team IDs, equipped pet records, inventory, potions/powerups, unlocked worlds/islands, owned gum/flavors, and Mastery levels. Displays/logs show up to 30 entries per list by default; `OC:GetStatus().Snapshot` retains the complete received tables. Use `OC:PrintAccount(100)` for a larger diagnostic listing.
4. Check that a next goal and its reason/prerequisites appear. Progression categories are transparent heuristics from received unlock/pet/Mastery counts; they are not the game's official level/rank.
5. Pause, change a balance/team manually, then Resume. The account view should refresh and recommendations should resume. Stop clears the goal; Start recomputes. Stop/Pause leave the read-only reader available. `OC:Destroy()` closes the panel and removes reader subscriptions.
6. Re-run the loader and check that only one hosted OC panel/reader remains. Existing legacy Studio installations are not modified by development tools or assumed to be this hosted instance.

Return screenshots, `[OC]` console output, and any mismatched values. **Real player-statistics reading, game-module require compatibility, rendered UI, and controls in the user's actual runtime remain unverified.** Do not approve Phase 2 until this test passes.

## Build and local checks

```text
node scripts/build.mjs
node scripts/test.mjs
```

Node uses no external npm dependencies. Tests additionally need the official [Luau CLI](https://github.com/luau-lang/luau/releases). Set `LUAU_BIN` and `LUAU_COMPILE_BIN`, or place executables in ignored `.tools/luau/`. The build is deterministic and packages all OC modules as private function factories, replacing OC imports without creating ModuleScripts or overriding the game's native require.

Local verification: all modules and the bundle compile with Luau 0.742; nine offline tests cover configuration replacement/validation, unknown account handling, disabled features, resource-aware recommendation eligibility, scheduler priorities/completion/cancellation, and controller lifecycle/stale-result rejection. Test fixtures are explicitly synthetic, live outside `dist/`, and do not verify any real account data.

See [Phase 1 architecture and each setting's execution rules](docs/PHASE1.md) and [observed interfaces and limitations](docs/WORKSPACE_REFERENCE.md).

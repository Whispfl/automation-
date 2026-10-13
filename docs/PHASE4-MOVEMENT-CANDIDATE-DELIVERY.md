# Phase 4 bounded movement candidate — owner live acceptance pending

2026-10-13. Build **`fec9bed3bd3f`**, immutable candidate tag **`phase4-travel-fec9bed3bd3f`** on `codex/phase4-test-b`. The implementation commit is the commit referenced by this new tag; the exact SHA accompanies the owner handoff. This record captures passing pre-publication checks; anonymous publication verification is recorded separately in `.test-output/phase4-movement-public-verification.json` after push. This is not owner-live acceptance or full Phase 4 completion.

- [Pinned bundle](https://raw.githubusercontent.com/Whispfl/automation-/phase4-travel-fec9bed3bd3f/dist/OC.lua): 701243 bytes, SHA256 `ceb20c7731ecd386596f4d6c907c1e908592377847d8da28283c91ebf73bdde0`.
- [Complete ready-to-run owner loader](../examples/Phase4MovementOnly.luau): SHA256 `ca6c62bfc4b9caf96c14766c68a58b7ecc5e6b6a3b98d284e1cb5abfce75fe60`.
- Local distribution: 705545 bytes, SHA256 `3a6fac022d06af8e76ce05ba0d56a1de04932e31a4e9d08eca888e450dec26a1`. Its historical local-feature Config is unchanged; **use only the movement loader for this owner test**.

## Three exact approvals and preserved behavior

| Approved artifact | Exact SHA256 | Permitted difference |
|---|---|---|
| `PHASE4-UNIVERSAL-MOVEMENT-STANDING-PROPOSED.patch` | `b1131059a5b151fb699b04bbf1ae50365cbeddc9a6d2faa222d28edd42d3207f` | Append four diagonals within the same radius, after the five original samples |
| `PHASE4-UNIVERSAL-MOVEMENT-FOOTPRINT-PROPOSED.patch` | `e812a4acdad9a75877dbaaa175db9fb4b5be948f8369c570366e20b6768d1c36` | Require complete padded projected avatar bounds on one verified level solid Block, edge margin 0.15 |
| `PHASE4-FINAL-STANDING-RECHECK-PROPOSED.patch` | `1d5259f1d8e9593f616546eb345c5c6efd8c7064f025530b2682fbec156eec4d` | Four-line final same-frame standing recheck after final destination validation, before the original one-attempt ledger/assignment |

Only `EggTravelManager:ResolveStanding` and `GameMechanics:PositionSelectedEgg` differ from the first-hatch production baseline. All 25 other production files, 12 historical approval/live-hatch records and 104 completed research files remain unchanged. Original proposals/approvals and release tags are retained; the separate [standing approval](PHASE4-APPROVED-STANDING-SUPPORT.json) and [final adapter approval](PHASE4-APPROVED-FINAL-STANDING-RECHECK.json) record exact differences rather than claiming identical Test A methods.

Standing file/method after SHA256: `15bd589ea9ff1e81354dbe536b347a2a852f59efa4780681234d82ee0540cf3b` / `b00f2cf4bf49e91fc7cda952293c6b04c119b7809b0567bad24177ec28f32db6`.

Adapter file/method after SHA256: `d51154114e6309dd9042de250cbd8757ce1f61e146858960d7745397e14ab531` / `e049e8c5c459c40502813312219bd2ca59b87be6a93fcf347297edd9b1396a6a`.

Original floor raycast, avatar height/OBB computation, native range and access, exact Instance identity, account/lease/cancellation, CFrame assignment, scheduler ownership, stable arrival and recovery policy are retained. All existing hatch/receiver/registration/price/auto-delete/storage/allowance/receipt guards remain unchanged. No transport request, retry, snap-back, extra movement loop or paid authorization is added.

## Required verification

`node scripts/build.mjs` and complete `node scripts/test.mjs` succeeded on the exact implemented source. The complete test log is `.test-output/phase4-final-movement-regressions.log`, SHA256 `49f6bf631f69977fff11287ca60be92a2907f53f0e45a034757a5fc9f65bf003`.

| Gate | Result |
|---|---|
| Official Luau compiler, production source, bundle and loaders | PASS |
| All 684 baseline regressions, explicitly enforced count | PASS |
| Native egg identity / guarded Test B | PASS, 67 / 69 existing checks |
| Functional / standing / final-recheck approval preservation | PASS, 28 / 28 / 22 groups |
| Actual final standing safety gate | PASS, 34 groups, no bounded-contract fault |
| Historical controls | Preserved: 3 × 22 safety groups plus 34-group frozen adapter reproducing seven known validation/frame faults |
| All 10 historical Test A hashes | PASS, six unchanged checks and four separately approved exact differences |
| Actual merged loader, controller constructor and wrong-account rejection | PASS; official compilation, no gameplay executed |
| Deterministic distribution / source-to-bundle integrity | PASS in complete suite |

Dedicated safety log `.test-output/phase4-final-approved-standing-safety-gate.log`: SHA256 `b88d66f38214619fb769daffadd11751af36c11d188fe36bc8c0125cfde8a7b4`. Historical failed outputs remain locally preserved; their failure is not erased or relabeled.

The actual-source gate includes real coroutine suspension in final Validate with support removal/shrink, tiny/edge/unsupported platforms, large accessories, shifted/rotated bounds, collisions, invalid access/root/identity, changed elevation/orientation, and a new alternative landing point. Missing support or any different final full CFrame blocks assignment rather than substituting a point. All five original and four diagonal winners are unchanged under identical valid observations; no extra attempt is added. Cancellation/ownership/config guards after observation remain pure local checks.

## Bounded safety contract and limitations

The last full standing observation now follows all potentially yielding destination validation. After it returns, only exact CFrame equality, pure local guards, the existing attempt ledger and direct setter remain. This closes the demonstrated DURING-Validate gap.

Workspace queries and assignment are non-atomic. Geometry can change after the last query/returned observation or after assignment. The distinct setter-entry mutation fixture documents that unavoidable boundary; it is not falsely described as guaranteed cancellation. Requested-position, range and stable-arrival observation remain required. Offline tests do not prove universal avatar movement or establish the cause of the owner's older standing failure.

Terrain, MeshParts, unions, sloped/complex or multi-piece support remain unverified and fail closed, including legitimate locations. The owner does not need to change avatars. If this main avatar is blocked, preserve the exact observed reason without guessing its cause or weakening collision safety.

## One owner-run movement test

1. Use the main account `10864747620` with only OC running. Already be on The Overworld ground area, more than 6.5 studs from Common Egg. This loader disables native island/world transitions, so it cannot move from another area.
2. Paste the complete [movement loader](../examples/Phase4MovementOnly.luau) once in the already owner-used supported runtime. Keep movement controls idle and do not click Buy.
3. Confirm build `fec9bed3bd3f`, exact selected Instance ID and `PHYSICAL_TARGET_RESOLVED`. A safe standing preflight must precede the permitted direct attempt. Observe whether the character actually moves and remains at the exact target; assignment/attempt logs alone are not arrival.
4. Expected successful end: one `DIRECT_POSITION_ATTEMPTED`, `PHYSICAL_ARRIVAL_OBSERVED`, stable arrival for one second, native travel attempts 0, hatch commands 0 and equipment commands 0; no OC spending. The diagnostic permission is consumed and there is no automatic retry. An already-in-range start cannot verify actual movement.
5. Stop with `shared.__OC_PHASE1_INSTANCE:Stop()`. Return the console result and your movement/stability observation. If blocked, return its exact reason and optionally the read-only `shared.__OC_PHASE1_INSTANCE:PrintEggLocations("Common Egg")` output. Do not reload, change selection revision or repeat the test without another owner decision.

Pause/Resume/Stop retain consumed permission within this controller; reloading creates a new controller and is not a retry authorized by this test. The loader rejects wrong/missing accounts before downloading or initializing. Native range/registration interaction reporting remains read-only; it never permits a hatch. A balance change can include external game rewards and is not automatically attributable to OC.

All hatch/equip/purchase/pickup/farming/bubble/world/reward/event/anti-AFK actions are OFF; every monetary spending budget and owner hatch allowance is zero/false. Dormant hatch/session/batch/equipment **count ceilings remain 1 because the existing controller schema requires positive integers**. They grant no action permission with the action flags OFF and currency budgets zero. The build script now pins only this movement candidate; historical Test A and hatch example pins are unchanged.

## After the owner result

The next step is this live movement result, not more speculative timing fixtures or another Common Egg hatch. Phase 4 remains partially verified: the first controlled Common Egg receipt and historical brother-account travel passed, while main-avatar candidate movement remains pending. Other eggs, economic auto-hatching/equipment and broader traversal are not declared accepted.

After the result, assess a concise Phase 4 checklist: exact physical target, safely supported same-frame candidate, at most one attempt, actual movement plus stable arrival, zero unauthorized actions, correct bounded failure/cancellation, and preserved receipt/protection evidence. A successful single approach establishes that scenario only.

Phase 5 can independently begin **read-only planning/eligibility work after its scope is approved**: actual Mastery levels and next-tier/prerequisite packages, sparse reward claimed/due state, account-specific reserve planning, and offline receipt/cancellation contracts. Those do not require egg movement or another hatch. Mastery purchases, reward claims and spins need their own implementation/action approval; none are enabled by this candidate. Existing playtime code does not imply all Phase 5 is approved.

## Reused evidence

Freshly reconfirmed Notion [master](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363), [Phase 9](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358). No broad research was repeated; native evidence takes precedence over wiki conflicts.

Exact supporting files: [native navigation contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md), [world/elevation behavior](research/replicatedstorage/WORLD_AND_NAVIGATION.md), [LocalData contracts](research/replicatedstorage/DATA_SCHEMAS.md), [wiki conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [navigation gaps](research/wiki/KNOWLEDGE_GAPS.md), [future architecture](research/wiki/FUTURE_OC_IMPROVEMENTS.md), [Mastery source](research/replicatedstorage/MASTERY_AND_UPGRADES.md), [Mastery planning](research/wiki/MASTERY_ROI_RESEARCH.md), [reward contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS.md), [reward strategy](research/wiki/REWARDS_SHOPS_AND_QUEST_STRATEGIES.md).

## Immutable live evidence

- First hatch: `phase4-hatch-100f2c1907ae`, commit `aae628d9ac8f1941f9b0b92aaedc365be22fa6af`, original bundle SHA256 `14da5d26f543c0c1d3e9d51e946f21baafe78379502cc05e9954de864ef161e0`. Original [console archive](evidence/PHASE4-FIRST-LIVE-HATCH-100f2c1907ae-CONSOLE.txt) SHA256 `0765815d70c439d9857d9ee3a3fa6390e346a9d65ff2bee7e9c8c1d900dd7df5`; one Common Egg/Normal Doggy receipt, counter +1, net Coins -10, equipment0, consumed allowance/no retry. Owner approached manually.
- Historical Test A: `phase4-travel-0d5caa499c8c`, commit `25890f224f0448f148d009e65514c129aeb4f59c`; original movement and hash record remain immutable.
- Registration preflight: `phase4-hatch-f4e10f71c317`, commit `55bf4cf437cccd826180519c482bdc6edbbbb51b`; unchanged.

No existing tag is overwritten. No Roblox Studio object, script or play state was changed, and no game request was executed during implementation or verification.

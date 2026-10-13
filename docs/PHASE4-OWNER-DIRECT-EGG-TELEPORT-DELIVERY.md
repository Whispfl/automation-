# Owner-only direct Common Egg Root experiment

2026-10-13. Build **`1d27e2a74ae5`**, immutable tag **`phase4-direct-1d27e2a74ae5`**, existing development branch `codex/phase4-test-b`. The implementation commit is the commit referenced by this new tag and accompanies the owner handoff. Publication verification follows the push; live movement/physics/native interaction results remain pending.

[Pinned raw bundle](https://raw.githubusercontent.com/Whispfl/automation-/phase4-direct-1d27e2a74ae5/dist/OC.lua): **710918 bytes**, SHA256 `47a28e33abdb74c4d87936bade2bb89401a3286c0ffad8694aa0dea6edb7beba`.

[Full ready-to-run loader](../examples/Phase4OwnerDirectEggTeleport.luau): SHA256 `53185da6b52e560b0f789077fa9cb9aa7e38f2b8346a9e118d38152d97f71de5`. It checks main account `10864747620` before downloading and sets `OWNER_DIRECT_EGG_TELEPORT_TEST=true`; the central default remains false. Other accounts and ordinary movement configurations cannot enter this isolated adapter.

## Latest observed blocker — no positioning failure inferred

The exact owner-supplied `fec9bed3bd3f` [console file](evidence/PHASE4-MOVEMENT-FEC9-OWNER-CONSOLE.txt) is preserved byte-for-byte: 9782 bytes, SHA256 `5111a74a01958367095c2244017082642de592d7c3ecaee06ccb3df3a7c2379e`. It reports the verified physical Common Egg at 73.68 studs, then `No supported floor and clear full avatar volume within diagnostic physical radius; manual approach required`, direct attempts0, native travel0, hatch/equipment/spending0. This demonstrates standing preflight rejection before assignment. It does not establish a physics failure or its cause. Logged Instance `I0011` is session-local evidence, never a code constant.

The owner explicitly authorized an isolated overlap/physics experiment. No new platform search, geometry proof or avatar change is required for this test.

## Smallest source delta and preserved ordinary methods

[Exact implementation diff](PHASE4-OWNER-DIRECT-EGG-TELEPORT-APPROVED.patch), SHA256 `129a893e4cf0c23d0740004bb15d4160101b6dd6ade5323984c37e5d7a6df2c2`.

Only three source files differ from published movement commit `e939f07f7ae898f3491e089615da802d7a07b9e5`:

1. `OCConfig`: one false-by-default commented option in `EGG_TRAVEL_SETTINGS`.
2. `EggTravelManager:Execute`: three-line early delegation only when that option is true.
3. `GameMechanics`: one separately appended `ExecuteOwnerDirectEggTeleportTest` method for scope checks, the sole diagnostic setter, bounded observation and truthful result cleanup. No new runtime module or scheduler is added.

The core assignment is:

```luau
local directFrame = CFrame.new(position) -- Exact freshly observed physical Common Egg Root.
-- Final pure account/scheduler/cancellation/scope checks and consumed attempt ledger.
local ok, err = pcall(function() fresh.CharacterRoot.CFrame = directFrame end)
```

No `ResolveStanding`, raycast, footprint, avatar bounding-box or clearance call occurs in this path. The existing `ResolveStanding` method remains SHA256 `b00f2cf4bf49e91fc7cda952293c6b04c119b7809b0567bad24177ec28f32db6`; ordinary `PositionSelectedEgg` remains `e049e8c5c459c40502813312219bd2ca59b87be6a93fcf347297edd9b1396a6a`, byte-for-byte identical to the prior movement release. False-default ordinary behavior retains all its safeguards.

The [separate approval record](PHASE4-OWNER-DIRECT-EGG-TELEPORT-APPROVAL.json) records the current direct behavioral authorization and the exact implemented diff afterwards; it does not claim the owner reviewed this new SHA before implementation. All historical approvals, method hashes, release pins and first-hatch evidence are preserved.

## Guarded scope and one attempt

The isolated method requires actual matching Player/Reader identity and captured Brain account `10864747620`; `TRAVEL_ONLY`, MANUAL one Common Egg, exact retained Model/Root, verified loaded location, The Overworld and actual access/current world. It retains scheduler owner/token/generation/lease, cancellation, idle presentation and existing native identity/access validation. Native island/world transport is OFF. Any altered account, target, scope, positive action permission or spending budget blocks assignment.

One attempt is consumed before the setter, including setter errors and uncertain delivery. Logging follows assignment so no logging callback separates the last pure guards from the setter. Existing diagnostic consumption plus the mechanics ledger prevents retries, revision rearm, Pause/Resume repeats and snap-back within this controller. Reloading creates another controller and is not authorized by this single test.

All hatch/equipment/purchase/pickup/farming/bubble/world/reward/event/anti-AFK actions are OFF; owner hatch flags are false, paid account ID0, currency budgets0. Dormant count ceilings1 are required by the existing validator and grant no action permission. No native transport, HatchEgg or other gameplay request is called by the experiment.

## Arrival versus interaction and accepted limitations

The observer uses the existing 12-second arrival bound and configured one-second stable-position requirement. It tolerates displacement from the assigned Root in this exception, reports final/maximum displacement and retains manual-input/cancellation checks. It never corrects position. Displacement cause stays UNKNOWN: physics, replication or external correction are possible, not guaranteed.

Exact native `HatchInteractionAt` and `RangeEligibleAt` remain read-only. They retain registry, initial Prompt or opened Root16 range, visibility and nearest-eligible-egg rules. Native range may be observed beyond the separate physical diagnostic6.5 radius. Physical proximity alone never proves native registration or hatch eligibility. Post-query actual position is used; native rejection reasons are retained.

- `OWNER_DIRECT_NATIVE_ARRIVAL_OBSERVED`: stable actual arrival and positive native interaction evidence.
- `OWNER_DIRECT_PHYSICAL_ARRIVAL_OBSERVED`: stable physical proximity, while native interaction remains unverified/blocked; the exact native reason is reported.
- `OWNER_DIRECT_ARRIVAL_UNCONFIRMED`: escaped/fell, timed out, cancelled, changed identity/access or other observed blocker; no retry.

This experiment can overlap geometry or fall. Workspace/native observations and assignment are non-atomic; there is no universal movement, guaranteed physics escape or server acceptance claim. No platform-geometry redesign is included.

## Validation

`node scripts/build.mjs` and complete `node scripts/test.mjs` PASS on the exact current production source. Full log `.test-output/phase4-owner-direct-full-regressions.log`, SHA256 `aad4f068d9d385978e794784e82237f6b14be6f845a7efb0a90e88c42b0006b2`.

- Official Luau compilation, all **684 baseline** regressions, native identity67 and guarded Test B69 checks PASS.
- **20 direct-test audit groups** PASS: no geometry queries, exact owner/target/world, one setter including errors, cancelled/yielded guards, changed identity/account/lease, zero actions, native/physical range, query-time escape/fall and no snap-back/retry.
- Actual merged Config and controller constructor tests PASS for new and historical loaders; missing/wrong account rejects before download, false central default verified.
- Existing ordinary standing safety gate and all historical approval/receipt/membership/classification checks PASS; both ordinary protected methods remain frozen.
- **24 separate direct approval preservation groups** PASS, including source-set/tampering negatives. The final three extra negative tests were added after the full run and executed separately; no production changed. Log `.test-output/phase4-owner-direct-preservation.log`, SHA256 `48b70773afad1a001a2e93663621d2f00b973fedb10f6d3d815b066ca4d63d64`.
- All24 other production files and24 historical approval/evidence files unchanged; all104 completed native/wiki files unchanged. Test A hashes and first-hatch records remain preserved.

Anonymous public Git tree/tag/raw-byte and historical release verification is performed after push by `node scripts/verify-public-owner-direct.mjs`; result recorded in `.test-output/phase4-owner-direct-public-verification.json`. No live game action is performed during these checks.

## One owner-run test and next step

Use only OC on main account10864747620, already on The Overworld ground, outside Common Egg6.5studs. Paste the full loader once; leave controls idle and do not click Buy. Look for `OWNER_DIRECT_EXCEPTION`, one `OWNER_DIRECT_POSITION_ATTEMPTED`, then the terminal `OWNER_DIRECT_RESULT`. Personally observe actual movement/physics displacement and whether the character remains near the egg. Report the terminal result and native interaction reason. Stop via `shared.__OC_PHASE1_INSTANCE:Stop()`; do not reload/rearm or change avatar if blocked.

One teleport, one observed result. No further Common Egg hatch is requested. Phase4 remains partial; other eggs/equipment/economic automation are not declared accepted. After the result, use a concise acceptance checklist and separately scope independent Phase5 read-only Mastery tiers/prerequisite packages and reward eligibility. No Phase5 action implementation or spending is authorized by this experiment.

## Reused source evidence

Freshly reconfirmed Notion [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363), [Phase9](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358). Completed research reused, without broad repeats: [native eggs/prompt/nearest behavior](research/replicatedstorage/EGGS_AND_PETS.md), [world and scene identity](research/replicatedstorage/WORLD_AND_NAVIGATION.md), [navigation contract](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md), [wiki conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [native/server and live geometry gaps](research/wiki/KNOWLEDGE_GAPS.md), [future shared architecture](research/wiki/FUTURE_OC_IMPROVEMENTS.md). Native game evidence takes priority over historical wiki claims.

First hatch `phase4-hatch-100f2c1907ae` / commit `aae628d9ac8f1941f9b0b92aaedc365be22fa6af`, historical Test A `phase4-travel-0d5caa499c8c` / commit `25890f224f0448f148d009e65514c129aeb4f59c`, and prior movement `phase4-travel-fec9bed3bd3f` / commit `e939f07f7ae898f3491e089615da802d7a07b9e5` remain immutable. No Studio object/script/play state was changed.

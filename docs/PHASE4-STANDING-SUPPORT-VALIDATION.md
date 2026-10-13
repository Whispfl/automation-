# Exact combined standing implementation — local validation, release withheld

2026-10-13. The owner's direct approval authorized both reviewed patches, exclusively inside `EggTravelManager:ResolveStanding`. The latest master roadmap, Phase 3/4/9 owner instructions and both completed native/wiki libraries were reconfirmed before applying them. Existing native evidence, conflicts, geometry gaps and deferred shared-navigation instructions were reused; no research library was changed.

Both exact patches are applied in the local workspace. **The required safety gate still fails, so no implementation commit, immutable tag, public candidate or live-test loader has been published.** HEAD and the remote development branch remain at review commit `78b97d11f34e245f31e41ff6fac10cbd795f03da`. The approved edits and validation files are retained locally, uncommitted. The existing public first-hatch build remains available at its original pin.

## Exact implementation and preservation

| Artifact | Verified value |
|---|---|
| Diagonal patch SHA256 | `b1131059a5b151fb699b04bbf1ae50365cbeddc9a6d2faa222d28edd42d3207f` |
| Footprint patch SHA256 | `e812a4acdad9a75877dbaaa175db9fb4b5be948f8369c570366e20b6768d1c36` |
| Standing file before | `7fd14d19e3befc895f3446f41d4882394d12eebc7bc555e5e8b05dd864e4cb8c` |
| Standing file after | `15bd589ea9ff1e81354dbe536b347a2a852f59efa4780681234d82ee0540cf3b` |
| Method before | `4996169eb8641b238ac1e52b3784c57a9b690ddf3e47993ddbddb9e2b2fec09a` |
| Method after | `b00f2cf4bf49e91fc7cda952293c6b04c119b7809b0567bad24177ec28f32db6` |
| Local, untagged build | `e2dbe7414c6a` |
| Local dist/OC.lua | 700800 bytes, SHA256 `ca07cf6a2f88d3eff8005b16f15581b024a88800b41eefe6e3bca8db203986a1` |

The [new approval record](PHASE4-APPROVED-STANDING-SUPPORT.json) and [exact verifier](../scripts/verify-phase4-approved-standing.mjs) apply both immutable patch hunks independently against first-hatch commit `aae628d9ac8f1941f9b0b92aaedc365be22fa6af`. They verify complete before/after file and method hashes, unchanged text outside the method, **all 26 other production source files** and **12 historical/live-hatch records**. New tampering tests reject extra source changes, one-patch-only implementation, altered patch bytes, expanded approval metadata and rewritten history.

Historical Test A hashes remain intact: 7 current checks retain exact bytes; standing, sparse-membership and PlanPets differences are each separately approved and verified. This does not relabel the modified standing method as identical to Test A. GameMechanics/PositionSelectedEgg, CFrame assignment, account/lease/token/cancellation, Brain/scheduler/native transport, target selection and registration, arrival/stability, retry/recovery, hatch receipt, pricing, inventory, equipment and spending code are unchanged.

`node scripts/build.mjs` rebuilt both local distributions and mechanically updated three disabled example pins to the untagged local build. They have not been published or handed out for execution. No activated loader or new account permission was created; the draft movement-only loader remains ignored/local and is withheld.

## Validation results

| Check | Result |
|---|---|
| Official Luau compilation | PASS, source/distributions/existing examples; 32 KLOC main compilation |
| `node scripts/test.mjs` | PASS, 684 main regressions and full existing distribution/config/example checks |
| Native identity/registration and Test B | PASS, existing 67 identity checks, 69 guarded Test B checks and receiver/membership/classification preservation |
| Functional and standing approval negatives | PASS, 28 existing functional checks plus 28 new exact-standing preservation groups |
| All 10 historical Test A hashes | PASS, original history retained; three exact differences recorded separately |
| Required expanded standing safety gate | **FAIL, exit 1**, 22 groups for each historical release / diagonal-only / actual combined variant |

Full local regression log: [.test-output/phase4-combined-standing-regressions.log](../.test-output/phase4-combined-standing-regressions.log), SHA256 `db69aa6041dedbd31eefc11fc7dae0054f784a626aecc76641a57c9f394d5531`.

Required gate output: [.test-output/phase4-combined-standing-safety-gate.log](../.test-output/phase4-combined-standing-safety-gate.log), SHA256 `7de30b5bd983f686c4bf4e1686b962c2a317dc3840e6ceea242db6161a0617df`. Matching audit expectations is not a passing publication gate.

The actual combined method now rejects the earlier tiny-platform, edge/unsupported-footprint, shifted/yaw/roll-bound and accessory cases. It rejects Terrain, MeshPart, unions, non-blocks, tilted or incorrect-top-plane observations and several individually insufficient support pieces. A same-height floor shrink **before the adapter's final standing observation** now invalidates support. All five original samples retain their order/coordinates under identical proven broad support; all four diagonal positions have the same original horizontal radius. Explicit padded-box plus 0.15-stud edge-margin boundary cases pass. Original collision rejection, one lease assignment and repeated-dispatch rejection remain intact.

The positive legacy fixtures now describe a real broad Block support with Size/CFrame/Shape rather than an incomplete floor stub. Their collision/unknown-avatar assertions remain, and bounded fallback query count changes from five to nine. Separate rigid-transform fixtures cover rotation/shift/accessories and avoid claiming an axis-aligned mock establishes rotated physics.

## Exact remaining failure and stop

One preserved fixture removes the supporting floor **inside the third/final Validate call, after PositionSelectedEgg has completed its last ResolveStanding call**. The adapter's final identity/access recheck does not inspect that support again, so it still performs its existing single synthetic CFrame assignment. The new footprint guard correctly certifies each observation, but cannot make support immutable after the last observation.

No test was removed, reclassified as a pass, or weakened to allow publication. The frozen adapter and other protected methods have not been changed to close this interval. Under the owner's “If any required gate fails, STOP without publishing” instruction, this failure withholds the candidate and any live test.

This is a deliberately injected synchronous mutation in an isolated fixture, **not proof of real concurrent engine timing, actual falling or the owner's live failure cause**. Read-only native inspection found direct `LocalData:IsReady/Get` state reads and non-waiting `WorldUtil:GetPlayerWorld`; `StatsUtil` has no explicit wait but delegates native helpers. The local call chain cannot certify every native dependency as non-yielding/side-effect-free. That uncertainty is reported rather than used to bypass the retained gate. A separate owner decision is needed for any further scope; no additional change is implemented here.

Legitimate complex, sloped, multipart or unknown support may remain blocked by the conservative one-level-Block proof. No universal teleportation, owner-avatar arrival or live safety is claimed. No owner movement repeat or paid hatch is requested while this required gate fails.

## Original live milestones remain preserved

- First hatch: `100f2c1907ae`, tag `phase4-hatch-100f2c1907ae`, implementation commit `aae628d9ac8f1941f9b0b92aaedc365be22fa6af`, original bundle SHA256 `14da5d26f543c0c1d3e9d51e946f21baafe78379502cc05e9954de864ef161e0`. Exact archived console and submission bytes remain unchanged.
- Test A: `0d5caa499c8c`, original tag/commit/hash records unchanged. Registration milestone `f4e10f71c317` remains unchanged too.
- Historical approval/proposal records are immutable as-of evidence. The new approval record describes this separate local method difference without rewriting earlier approvals or release pins.

Supporting reused research: [native navigation contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md), [world and elevation evidence](research/replicatedstorage/WORLD_AND_NAVIGATION.md), [native/server-only uncertainty](research/replicatedstorage/UNKNOWN_AND_SERVER_ONLY_RULES.md), [wiki conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md) and [future reliability improvements](research/wiki/FUTURE_OC_IMPROVEMENTS.md). Current native data and owner evidence retain precedence over wiki history.

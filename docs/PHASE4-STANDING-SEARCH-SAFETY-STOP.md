# Approved diagonal search — safety stop before implementation

2026-10-13. The owner approved only the exact four-diagonal patch SHA256 `b1131059a5b151fb699b04bbf1ae50365cbeddc9a6d2faa222d28edd42d3207f`, reviewed at commit `c456485ed793e08d0098411ec460474e5bf2adae`. This approval is recorded here separately; the historical proposal/hash records are unchanged. **No production patch has been applied and no movement candidate is published.**

The owner's explicit stop condition was: “If an unsafe case is exposed that requires another protected-method correction, STOP and present a separate minimal proposal.” The new required safety fixtures exposed unsupported standing acceptance, so this condition controls delivery. No new loader, hatch, paid request, equipment action or owner live test is activated.

## Exact failure evidence

The [reproducible runner](../scripts/test-phase4-standing-safety-gate.mjs) applies the approved patch **in memory only**. The [fixtures](../tests/phase4-standing-safety-gate.luau) use complete rigid transforms, bounded flat floors and independent projected-support/sole-contact checks. They call the actual released `ResolveStanding` and unchanged `GameMechanics:PositionSelectedEgg`; ready identity/presentation/account context is stubbed to isolate geometry. This is synthetic geometry, not Roblox physics, live interaction certification or the cause of the owner's earlier failure.

| Fixture | Released resolver | Approved diagonal overlay |
|---|---|---|
| Broad flat supporting slab | Center accepted; original position retained | Same center and coordinates retained |
| 0.8 by 0.8 ledge under 4 by 4 projected body | Accepted despite unsupported footprint and both synthetic sole centers | Same unsupported acceptance |
| Hole away from center, shifted or 45-degree rotated bounds | Unsupported projection accepted in the corresponding fixtures | Same gap |
| Large 10-stud accessory/body bounds over 4.2-stud slab | Full box queried for clearance, support projection unverified | Same gap; accessories were not ignored |
| Only a 0.8 by 0.8 slab at a diagonal offset | Five original rays miss support; blocked | Candidate 6 accepted, with neither synthetic sole center nor projected full bounds supported |
| Same support object shrinks from broad slab to ledge without changing top Y | Existing adapter re-observes the same standing point and assigns | Same missing support verification |
| Support disappears or top elevation changes before adapter re-observation | Assignment blocked | Assignment blocked |
| Collidable obstruction intersects rotated/shifted full box | Blocked | Blocked |

The source checks one downward ray per candidate and then excludes the entire supporting floor Instance from clearance (`EggTravelManager` lines 457–476). It neither checks the floor extent beneath the avatar nor proves continuous support. The diagonal samples undergo the same existing checks, including this limitation; they expand the set of accepted sites without fixing support proof.

The same-height shrink case is especially relevant to final revalidation: the adapter recomputes standing and compares the resulting root positions within 0.25 studs. Changed support extent can preserve the exact position and therefore pass that comparison. No adapter/CFrame code was modified to demonstrate this.

A separate deliberately injected mutation after the last standing observation and before final identity validation also shows that observation does not make geometry immutable. This synthetic case establishes no actual engine timing or owner failure, and the supplemental footprint proposal does not claim to fix post-observation changes or provide atomic physics guarantees. Current observed stable arrival remains necessary.

## Verification and preserved scope

- `node scripts/test.mjs`: PASS on the unchanged release, official Luau compilation, 684 main regressions, 67 native identity checks, 69 Test B checks, existing receiver/membership/classification/functional and historical Test A preservation. Full local log: `.test-output/standing-approval-baseline-tests.log`.
- `node scripts/test-phase4-standing-proposal.mjs`: official compilation and eight focused groups per released/proposed-in-memory variant pass, including all five original winning locations and exact query order. These earlier checks do not establish footprint support.
- `node scripts/test-phase4-standing-safety-gate.mjs`: both temporary source variants compile officially; 13 audit groups per variant reproduce the expected observations. **Publication gate FAIL, exit 1**. Matching known-fault expectations is not safe acceptance. [Original audit output](verification/phase4-standing-diagonal-safety-gate.txt), SHA256 `2383b92074d1402978eba4380127ef912ccafe3e029105b462027860d54376a2`.
- All 47 runtime/source/bundle/loader files remain byte-identical to first-hatch commit `aae628d9ac8f1941f9b0b92aaedc365be22fa6af`; completed native/wiki libraries, historical approval records, first-hatch archives and original release tags are unchanged.
- Existing first-hatch `100f2c1907ae` / `phase4-hatch-100f2c1907ae` remains pinned to that implementation commit. Bundle SHA256 remains `14da5d26f543c0c1d3e9d51e946f21baafe78379502cc05e9954de864ef161e0`. Original Test A `0d5caa499c8c` and registration milestone `f4e10f71c317` pins remain preserved.

No `node scripts/build.mjs` or candidate release was produced because the conditional safety gate failed before implementation. Compilation/regression success on the preserved baseline is not reported as success of an implemented movement repair.

## Separate minimal proposal for review

The [exact supplemental footprint patch](PHASE4-UNIVERSAL-MOVEMENT-FOOTPRINT-PROPOSED.patch) and [before/after hash/scope manifest](PHASE4-UNIVERSAL-MOVEMENT-FOOTPRINT-PROPOSED.json) are **unapproved and unapplied**. They depend on the approved diagonal enumeration overlaid in memory. Neither patch is applied to production source.

Supplemental patch SHA256: `e812a4acdad9a75877dbaaa175db9fb4b5be948f8369c570366e20b6768d1c36`. The approved diagonal overlay method hash is `8d3129ec4a04c80964f36a0e5f15dc8bf83656618567e9b1a197ee409b893dda`; the separately proposed method hash is `b00f2cf4bf49e91fc7cda952293c6b04c119b7809b0567bad24177ec28f32db6`. The current released method still has hash `4996169eb8641b238ac1e52b3784c57a9b690ddf3e47993ddbddb9e2b2fec09a`.

The [supplemental in-memory audit](../scripts/test-phase4-footprint-proposal.mjs) compiles both overlays officially and checks 16 groups per variant: all five original choices on proven broad support, same-radius diagonal choice, narrow/edge support, large accessories, shifted/yaw/roll bounds, yaw-rotated supporting block, floor shrink before the adapter recheck, unknown/round/tilted geometry and collision rejection. [Original proposal audit output](verification/phase4-standing-footprint-proposal.txt) preserves those observations. Expectations reproduce the diagonal-only gap and the supplemental guard's conservative behavior. This is not a completed candidate's full regression suite or live support acceptance.

The supplemental change is confined to `ResolveStanding`: after forming the existing candidate frame, require one observed, numerically level solid Part/Block top face to contain the entire existing padded full-avatar box's projected footprint, with a 0.15-stud edge margin. It leaves the original height/bounds calculations, floor raycasts and anchor/slope filters, collision query, range/nearest checks, candidate order, identity, lease, adapter, CFrame assignment and arrival behavior intact. The existing adapter's second resolver call repeats this support check.

This is deliberately stricter. MeshParts, unions, Terrain, non-block or tilted Parts, and support assembled from several pieces remain unverified by that proof and may be rejected even when legitimately traversable. The current owner-live floor's shape/topology has not been established. This proposal does not promise to preserve every previously accepted site: an unsafe/unproven site can be rejected; the original five valid choices on a fully proven broad slab must retain their ordering and coordinates. It supplies no walking engine, new transport, extra attempt or retry.

Corner containment proves the projected volume lies inside a **known convex solid rectangle**; sparse center/corner/perimeter rays cannot establish continuous support over arbitrary holed/concave geometry. The selected Part is never whitelisted by name or path. Current native support and avatar collision behavior still require live observation; universal movement is not claimed.

## Authority and evidence reused

Freshly fetched applicable [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363) and [Phase 9 owner notes](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358) preceded this work. The Phase 9 shared LocationResolver/NavigationManager directive remains deferred; no new framework is implemented.

Existing [native navigation contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md), [world/navigation evidence](research/replicatedstorage/WORLD_AND_NAVIGATION.md), [server-only gaps](research/replicatedstorage/UNKNOWN_AND_SERVER_ONLY_RULES.md), [wiki/native conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md) and [future improvements](research/wiki/FUTURE_OC_IMPROVEMENTS.md) were reused. No completed game research was repeated or changed.

A narrow previously unresolved engine-geometry question was checked against primary Roblox documentation: [Part.Shape](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/Part.yaml) distinguishes primitive Block geometry and custom mesh/solid-modeling shapes; [GetPartBoundsInBox](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/WorldRoot.yaml) queries bounding boxes rather than actual occupied volumes. These support the conservative shape boundary; they do not establish the current game floor or server physics.

Separate owner approval is required before implementing this additional protected-method guard. Until then the original working build remains intact, publication is withheld and no live movement or hatch repeat is requested.

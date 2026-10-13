# Phase 4 standing-position evidence

Investigation date: 2026-10-12. Owner-tested build `0d5caa499c8c`, commit `25890f224f0448f148d009e65514c129aeb4f59c`. This is a focused continuation of the completed libraries, not a new game deep dive. Studio inspection was strictly read-only against saved Edit workspace **Game**, studio `bbe2d8d8-d973-46af-861a-dde5eef21a7f`. No Luau was executed, no objects were changed and no play state was changed. Saved scene observations do not substitute for the owner's actual runtime raycast, avatar or arrival result.

## Owner observation and exact limit of the old report

The owner log confirms that OC retained Common Egg session Instance `I0020`, resolved its physical original Root `(-10.255,7.736,-79.812)` and Prompt `(-7.755,9.136,-79.812)`, and failed **inside standing resolution before dispatch**. Direct attempts, native travel attempts, hatch requests and spending were all zero. Duplicate discovery is no longer the reported blocker.

The old `EggTravelManager:ResolveStanding` merged no ray hit, invalid support, steep normal, excessive proposed height/range and collidable overlap into one final string. The supplied log does not contain any per-candidate hit, avatar bounds, blocking parts or exact rejection. It therefore cannot establish which particular condition rejected every candidate. Claiming that the live floor was missed, an accessory enlarged the box, or a particular part blocked the avatar would exceed the recorded evidence.

The resolver's independently demonstrable limitations are a floor-search interval coupled to a physical interaction radius, use of the complete observed Model bounding box as physical standing height and clearance, no observed character collision-group selection for scene queries, only five horizontal candidates, and the loss of each candidate's actual rejection reason. These are code observations, not proof of which occurred in this live session.

## Fresh saved Common Egg support geometry

Read-only `inspect_instance` independently matched the owner's selected original by its exact Root and Prompt geometry. Its saved Model ID is `35fcc9fe-43c4-a8c8-0adc-1d0d00001057`; that ID is evidence for this saved snapshot, not a durable live identifier. Root and Prompt are anchored, noncollidable, queryable Parts. The second same-name original remains a separate Instance and is not substituted for the selected one.

The relevant supporting objects occur under `Workspace.Worlds.The Overworld.Decoration.Eggs.EggPlatformSpawn`. All five returned `Part` matches have identity rotation, `Anchored=true`, `CanCollide=true`, `CanQuery=true`, `CollisionGroup=Default` and zero assembly linear/angular velocity. Their exact distinct saved IDs and dimensions are:

| Saved ID suffix | Center | Size | Top Y |
|---|---|---|---:|
| `0000881a` | `(-14.4321709,6.5999994,-68.9692535)` | `(1,1,30)` | 7.0999994 |
| `0000881b` | `(-7.9321718,6.3499999,-68.9692535)` | `(12,0.5,30)` | 6.5999999 |
| `0000881c` | `(-8.1821718,5.8499994,-68.9692535)` | `(13.5,0.5,32)` | 6.0999994 |
| `0000881d` | `(-8.1821718,6.5999994,-84.4692535)` | `(13.5,1,1)` | 7.0999994 |
| `0000881e` | `(-8.1821718,6.5999994,-53.4692535)` | `(13.5,1,1)` | 7.0999994 |

The rectangular slab `0000881b` covers X `[-13.9321718,-1.9321718]` and Z `[-83.9692535,-53.9692535]`. The selected Root's X/Z lies inside that slab. Its geometric top is Y **6.5999999**, about **1.1361 studs below the Root**. This is a normal rectangular Part, so its top follows directly from the returned identity rotation, center and Size; it does not rely on assuming that a mesh bounding box is its actual collision surface.

For this saved Common placement, the old ray from Root Y + 6.5 to Root Y - 6.5 spans **14.2361164 down to 1.2361164**, which includes that slab's top. Consequently, the saved geometry does **not** prove a too-short-ray explanation for this specific Common Egg. No raycast was run through Studio. The actual live first hit and normal must be reported by the owner-run client diagnostic. The floor strategy still needs to handle genuinely elevated anchors without reusing a 6.5-stud interaction radius as the vertical floor limit.

`Workspace.Worlds.The Overworld.Decoration.Ground.Ground` returned four distinct MeshParts. One identity-oriented broad ground mesh has center `(19.3178291,5.0999999,-4.9692531)`, size `(421.0740051,1,340.9689941)`, anchored/collidable/queryable Default flags and a bounding top Y 5.5999999. Its X/Z bounds include the selected anchor. A MeshPart's bounding top is only an extent observation, not proof of its exact raycast collision surface. The three other returned Ground meshes have different extents and positions.

Common's `Decoration` has four meshes whose names contain a literal dot, such as `Meshes/Egg Stand Chains3_Cube.029`. The hierarchy read confirms these children, but `inspect_instance`'s dot-path parser did not resolve those names. Their collision flags and exact surface geometry were not independently obtained in this investigation. The new runtime collision diagnostic is necessary to identify any actual blocking decoration; this document does not assert those meshes are clear or obstructing.

These coordinates are evidence only. They must not become hardcoded destinations or special-case floor rules.

## Focused native avatar and collision interfaces

| Exact native source and returned lines | Supported behavior | Implementation implication |
|---|---|---|
| `ReplicatedStorage.Shared.Framework.Utilities.CharacterUtil:35-56` | `GetRig` enumerates and validates 16 direct R15 body Parts: Head, UpperTorso, LowerTorso, HumanoidRootPart, both upper/lower arms and hands, and both upper/lower legs and feet; it also requires a Humanoid. Accessories are not in this rig list. | The native game distinguishes actual rig body from every descendant's visual bounds. Body geometry can be measured directly without treating every noncollidable attached visual as standing support or occupied collision volume. The list is source evidence for R15; it is not permission to guess missing body geometry or require that every possible avatar match this exact saved format. |
| `CharacterUtil:58-90` | Native root and Humanoid lookups require the expected direct children and BasePart/Humanoid types. | Retain actual root/Humanoid identity, alive state and cancellation guards; no synthetic character or guessed root. |
| `ReplicatedStorage.Shared.Framework.Services.CollisionGroup:30-59` | `AddModel` assigns all descendant BaseParts and future added BaseParts to the specified group. | Read observed collision-group properties for queries; do not mutate the character or scene groups. |
| `CollisionGroup:124-128,142-154` | The saved source creates `Characters`, disables `Characters` versus `Characters`, and assigns existing player characters and CharacterAdded models to that group. | A default-group overlap query can disagree with the native character's collision behavior, especially around other players. The resolver should use observed body collision groups rather than infer that every CanCollide result is physically blocking the selected character. This saved initialization is not proof that every current live Part still has that group. |
| `CollisionGroup:172-175` | Its client branch reads registered group names; it does not create the groups there. | Do not invoke group creation/assignment helpers for diagnostics. Keep the observation read-only. |

The native modules inspected here do not define a universal ordinary-egg standing offset, requirement to remain outside the visual, `Anchored=true` requirement for every usable welded assembly, exact flatness threshold of 0.98, or a universal vertical floor search distance. Those are OC policies and must be justified and reported as such. A moving/dynamic/unsupported surface is distinct from a stable support whose own Anchored property is false because it belongs to an anchored assembly. Current scene geometry, assembly and collision observations are needed before accepting it. A noncollidable visual is not a floor and is not automatically a collision obstacle.

A narrow engine-interface check supplements the existing game research: Roblox's [RaycastParams reference](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams/RespectCanCollide) defines collision-group filtering and use of CanCollide over CanQuery; its [OverlapParams reference](https://create.roblox.com/docs/reference/engine/datatypes/OverlapParams) exposes the matching CollisionGroup and RespectCanCollide query fields. This check verifies the newly used query interface; it does not repeat either completed game deep dive or establish the owner's actual physics results.

## Reused completed research

- [EGGS_AND_PETS.md](research/replicatedstorage/EGGS_AND_PETS.md): original/native Prompt versus opened-egg Root ranges and source-fidelity limitations.
- [WORLD_AND_NAVIGATION.md](research/replicatedstorage/WORLD_AND_NAVIGATION.md): saved versus live geometry; `WorldUtil:12-38` world correspondence; exact native island/surface destination distinction and unavailable server acceptance.
- [NAVIGATION_SOURCE_LEDGER.md](research/replicatedstorage/NAVIGATION_SOURCE_LEDGER.md): exact navigation source paths, returned lines and prerequisites.
- [UNKNOWN_AND_SERVER_ONLY_RULES.md](research/replicatedstorage/UNKNOWN_AND_SERVER_ONLY_RULES.md): no inferred server contract from a remote or saved object.
- [NATIVE_VS_WIKI_CONFLICTS.md](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md): current native evidence takes precedence over historical public mechanics.
- [KNOWLEDGE_GAPS.md](research/wiki/KNOWLEDGE_GAPS.md): exact teleport approach, live geometry and arrival remain owner verification gaps.
- [FUTURE_OC_IMPROVEMENTS.md](research/wiki/FUTURE_OC_IMPROVEMENTS.md): separate purchase, travel, approach and achieved result; one existing Brain/scheduler and preserved phase boundaries.
- [PHASE4-EGG-LOCATION-EVIDENCE.md](PHASE4-EGG-LOCATION-EVIDENCE.md): completed original-Instance provenance, Chunker lifecycle, signed-coordinate fix and physical location versus native hatch registration. The standing correction preserves that now-owner-observed location discovery.

## Implemented standing correction

The change is confined to the existing egg travel path and the read-only helper `src/OCFoundation/EggStandingGeometry.luau`. Original Instance discovery, access facts, Brain selection, native area travel, and the sole positioning assignment in `GameMechanics:PositionSelectedEgg` remain the same responsibilities.

The helper records the complete character Model bounding box and its offset for diagnostics. For an observed R15 rig it measures the direct body Parts supported by the native `CharacterUtil` list; for an observed R6 Torso it uses a compatibility body list. The R6 list is OC compatibility behavior, not a claim that the inspected game's `GetRig` supports R6. A recognized rig with a missing body Part is blocked with that exact Part name. If no supported rig shape is recognizable, the full Model box remains a conservative fallback rather than inventing an avatar envelope.

Actual body feet and `Humanoid.HipHeight + HRP.Size.Y / 2` determine standing height, with the existing 0.15-stud clearance margin. Noncollidable extra Parts are counted and shown but do not enlarge recognized-rig collision clearance. Collidable extra Parts still enlarge clearance; an extra extending below the supported feet is explicitly rejected before a query can hide its intersection with the excluded support. More than 512 character descendants, unavailable bounds, unsupported standing height and collidable Parts with a different observed collision group are exact blockers. Raycast and overlap queries use the observed HRP group. No Part, group, CanCollide property or avatar is changed.

The vertical ray interval is derived independently for each candidate: upward and downward extents begin at physical/native Range plus measured avatar standing height. The original selected Model's observed lower extent can justify additional downward search; actual raycast support still decides the destination. Each direction is capped at 128 studs. This cap and margin are explicit OC bounds, not native egg-mechanics constants. The center and four existing cardinal candidates remain bounded; there is no expanding search loop or blind fallback to a fixed coordinate.

Support must be a real currently loaded collidable BasePart with an actual observed hit position. The existing `Normal.Y >= 0.98` flat-surface policy is retained and now identified as OC policy in a rejection. A Part can be supported by its own Anchored state or a real anchored AssemblyRootPart. A nonanchored Part requires finite observed assembly motion; observed linear or angular magnitude above 0.05 blocks it. Support Instance, dimensions, position, orientation, normal and hit are retained in a standing proof and rechecked before dispatch and during arrival. An original-model extent never authorizes an arbitrary below-map CFrame.

For **TRAVEL_ONLY with this verified standing proof**, physical range means no more than the existing 6.5-stud horizontal distance from the exact original Root, with the actual HRP Y within 0.5 studs of the one proved supported standing height. This corrects the mismatch between an elevated egg anchor and a floor-derived character height. It is explicitly a diagnostic physical policy; it is not a larger native hatch distance. The proof retains the exact Model, target Root, character Root, support, anchor, selected collision group and single requested position. **NORMAL native hatch 3D range and independent initial-prompt/opened-scanner eligibility remain unchanged.** Before a standing proof exists, the existing diagnostic physical 3D check remains the initial in-range observation.

Final guards re-raycast and recheck clearance at that **same retained pose**; they do not select a different support/candidate after resolution. The dispatch adapter receives that exact position, validates the same proof and range, marks one actual direct attempt and makes its existing single guarded HRP CFrame assignment. Arrival requires the actual HRP to remain within 0.5 studs of the requested position and satisfy the existing stability window, manual movement, identity, access and cancellation checks. Server correction can therefore leave arrival unconfirmed; successful assignment alone cannot complete the travel test.

The one-report guard keys the retained actual egg Instance, so the detailed standing report prints once even though observational final guards continue to check current support. `LastStandingReport` remains available through status. Reports preserve candidate start/end ray heights, hit properties, proposed HRP height, body and aggregate bounds, range results, up to six observed unexpected Parts and up to six blocking Parts per candidate, with actual blocker counts and each exact reason. The existing one consumed TRAVEL_ONLY action prevents another teleport after success, failure, cancellation or Resume.

## Required runtime evidence and acceptance boundary

One bounded report for the retained exact target must contain observed original Root/Prompt, original full Model box and offsets, measured body/physical dimensions and selected collision-group semantics, each candidate's X/Z and vertical ray interval, actual hit Instance identity/path/properties/position/normal, support acceptance or exact rejection, proposed root height and actual distance/range result, actual blocking parts and final rejection. A single generic string is inadequate. This report must not recur every scheduler tick.

Successful destination computation is `STANDING_DESTINATION_RESOLVED`. An actual guarded adapter dispatch is `DIRECT_POSITION_ATTEMPTED`. Only stable observation of the real character, retained exact target, accessible world/island and supported range can produce `PHYSICAL_ARRIVAL_OBSERVED`. Assignment success alone is not arrival. Independently unresolved native hatch registration remains `HATCH_INTERACTION_UNVERIFIED`.

All logs and geometry are observational. No scene deletions, prompt activation, hatch requests, spending, equipment, purchases, unlocks, pickups, additional movement loops or automatic repeat are authorized. One bounded TRAVEL_ONLY action remains controlled by the existing OCBrain, TaskScheduler and `GameMechanics:PositionSelectedEgg`. Pause/Resume/Stop, respawn/manual-movement cancellation and consumed-attempt behavior remain requirements. Phase 4 and Test B remain held until the owner verifies actual gameplay.

## Candidate build and validation

Build `79273e3c1cc9`, release pin `phase4-travel-79273e3c1cc9`. `node scripts/build.mjs` and `node scripts/test.mjs` pass: deterministic bundle/static checks, official Luau compilation, **592 main-suite regressions**, all existing example/entry/Config isolation checks, **23 new real standing-geometry cases** and **11 new actual adapter/arrival cases**. Additional official compilation covers both new test files and the full pinned Common Egg loader. All 104 completed native/wiki research files remain byte-identical to the pre-edit backup.

Tests reproduce synthetic missed-floor intervals separately from the saved Common slab at Y 6.6, plus body/cosmetic bounds, collidable extras and floor penetration, group-aware other-avatar filtering, mixed solid-group rejection, rejected oversized fallback diagnostics, stationary anchored assembly, free/moving support, native versus physical range, exact duplicate Instance identity, moved support, one bounded report, actual single guarded dispatch, assignment failure, correction, stable arrival, cancellation and no repeat/other commands. These are offline checks. The exact rejecting condition in the old owner runtime remains unavailable because that build did not record it; the next owner-run report supplies that evidence. Public artifact verification is a separate publication check, never a gameplay result.

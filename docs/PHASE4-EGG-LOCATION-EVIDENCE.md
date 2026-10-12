# Phase 4 egg location and hatch interaction evidence

Authored focused follow-up, 2026-10-12. The owner tested `a0ee412ac828` and reported **no character movement**, `loaded=0`, eleven Common Egg observations and zero accepted registrations. The direct positioning adapter therefore has no owner gameplay result in that test. This document does not approve Phase 4 or start Test B.

The root refreshed and read the [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363), and [Phase 9](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358) before edits. The October 12 Mastery-first owner directive remains the future progression policy; this isolated zero-spend location fix implements no Mastery or global ROI feature.

## Completed research reused

- [EGGS_AND_PETS.md](research/replicatedstorage/EGGS_AND_PETS.md): native catalog versus physical availability, registered-original identity, initial Prompt 6.5-stud and opened Root 16-stud interaction semantics, account access and hidden server uncertainty.
- [NATIVE_ACTION_CONTRACTS_NAVIGATION.md](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md) and [WORLD_AND_NAVIGATION.md](research/replicatedstorage/WORLD_AND_NAVIGATION.md): world surface versus island travel, LocalData access, current geometry, intentional egg location ownership and arrival distinct from a request.
- [NAVIGATION_SOURCE_LEDGER.md](research/replicatedstorage/NAVIGATION_SOURCE_LEDGER.md) and [UNKNOWN_AND_SERVER_ONLY_RULES.md](research/replicatedstorage/UNKNOWN_AND_SERVER_ONLY_RULES.md): returned source-line numbering, saved/decompiled fidelity, Edit-mode scene limits and owner-operated live acceptance.
- [NATIVE_VS_WIKI_CONFLICTS.md](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [KNOWLEDGE_GAPS.md](research/wiki/KNOWLEDGE_GAPS.md), [COVERAGE_REVIEW.md](research/wiki/COVERAGE_REVIEW.md), and [FUTURE_OC_IMPROVEMENTS.md](research/wiki/FUTURE_OC_IMPROVEMENTS.md): native/current scene precedence, historical wiki layouts are not coordinates, sampling and navigation remain separately uncertain, one existing Brain/cache/scheduler, and no later-phase implementation implied by a research proposal.
- [Prior identity evidence](PHASE4-EGG-IDENTITY-EVIDENCE.md): exact original-key registration and duplicate saved objects. This follow-up corrects an implementation error and the former travel/hatch coupling; it does not rewrite the completed libraries.

Only the specific lifecycle, observer and location questions below required fresh native inspection. No broad wiki research or extraction was repeated. All requested native paths in this focused read were accessible. No private runtime registry, server implementation, live owner account, actual gameplay PlaceId or gameplay success is claimed exposed by Studio.

## Demonstrated local root cause

In the failed build, `GameKnowledge`'s `point` helper passed X, Y and Z into `PetPolicy.Finite`. That financial/inventory helper deliberately requires `value >= 0`. Coordinate validity instead requires signed finite numbers: negative X, Y or Z is valid geometry.

`eggParts` rejected the entire original interface if either position had a negative component. Thus the diagnostic printed both Root and Prompt as absent/unknown even when those children existed. The passive observer also applied `eggParts` to every registered original and rejected its receiver when a valid egg had negative coordinates. This explains the observed zero accepted models and zero accepted receiver without establishing a native movement failure or proving that an Update timing window was missed.

The correction belongs in geometry validation; the nonnegative financial/inventory contract remains intact. Valid signed geometry now exposes the existing original parts. Nonfinite or incomplete forms are rejected, and their detailed diagnostic still identifies that the complete supported interface is unavailable rather than granting a destination from an arbitrary child.

## Owner-verified positioning reference

The owner's additional October 12 report explicitly confirms that the reference's lookup of `Workspace.SummonedEgg.EggPlatformSpawn` and direct `HumanoidRootPart.CFrame` assignment with its geometry-specific +5-stud offset placed the character correctly in the live Nostalgia Egg area. Visible egg overlap was intentional and worked for that specific target. This is owner-reported live evidence, not an offline inference, and it supports the existing direct-assignment mechanism in that environment.

It does not establish ordinary-egg coordinates, a universal +5 offset, arbitrary-first-descendant identity, ordinary registration or OC travel success. The reference returns true even when its protected assignment fails; OC must preserve the actual protected-assignment result and observe actual stable position afterward. Previous OC logs show zero direct attempts, so they did not test or disprove that mechanism.

The useful adaptation is location first: find a source-associated physical anchor, derive a standing CFrame from actual scene support and avatar dimensions, assign it once through the existing scheduler-controlled adapter, then observe arrival. A visible noncolliding egg is not automatically an obstacle. Safe candidates may share the anchor's horizontal position when actual floor support and collidable full-avatar clearance permit it; an outside-the-visual offset is not a universal rule. Root/Prompt/Plate/Cost describe this inspected ordinary original form and its provenance, not a requirement that every possible egg destination in every feature use those child names. No trustworthy alternative link from an ordinary Generic-only visual or arbitrary PrimaryPart to a specific original was exposed by the inspected source, so those forms remain precisely blocked rather than guessed. This focused correction adds no Rift/Nostalgia automation, external key system, UI, return teleport or unrelated reference loops.

## Current native source lifecycle

All source numbers below are returned `script_read` line numbers, not embedded decompiler original-line comments. Studio was refreshed through `list_roblox_studios` and returned owner-confirmed saved `Game`, ID `bbe2d8d8-d973-46af-861a-dde5eef21a7f`. Reads and hierarchy inspection were strictly read-only: no Luau execution, require invocation, object mutation or play-state change.

| Native source and returned lines | Actual behavior and consequence |
|---|---|
| `StarterPlayer.StarterPlayerScripts.ClientScript:374-376` | Private `tbl_upv_7` is created, with egg receiver `Chunker.new(128, 2)` in 3D mode. Receiver size/mode/folder name alone do not identify an egg registry. |
| `ClientScript:639-674,747-767` | `createFromModel` processes exact tagged original Models. It accesses their direct `Root`, `Prompt`, `Plate.SurfaceGui` and `Cost.SurfaceGui` interfaces, removes their Egg tag at 674, and passes the exact original to `u12:Add(original:GetPivot().Position, original)` at 747. Originals are not reconstructed from rendered Hitboxes. |
| `ReplicatedStorage.Shared.Utils.Chunker:17-20,33-55` | Each receiver creates its own same-named Chunker Folder. Add stores exact values in `_chunks[coord]`; loaded exact Instances are parented to that receiver's folder and unloaded Instances to nil. It does not clone them. |
| `Chunker:99-117,118-167` | Exact loaded membership is searched through `_loaded` coordinates and `_chunks` arrays. Native Update reparents exact original Instances on load/unload and fires Loaded/Unloaded. Multiple same-path objects remain different values. |
| `ClientScript:532-555,628-637` | `create(original)` finds `ReplicatedStorage.Assets.Eggs[original.Name]`, clones that visual, scales it, writes Offset, parents it to Generic, stores `tbl_upv_7[original] = {Model, Prompt, VisualLock}`, then positions the visual from original.Root. The registry key is the original Instance, not its name/path. |
| `ClientScript:379-394,471-489` | Visual pivot includes model Size, time phase and random Offset; animation repeatedly derives it from original.Root. A Generic visual's current center is not the original Root position. Offset/Size do not independently prove an original association. |
| `ClientScript:395-451` | `updateUnlocked` requires a registry entry, checks account egg/island state, deliberately detaches the engine prompt for an already opened egg or inaccessible island, and updates original.Unlocked. Absence of an attached engine prompt is expected for opened eggs; the physical Prompt Part remains separate. Unlocked alone does not expose current registry membership. |
| `ClientScript:453-469` | Unloading destroys the associated visual and engine prompt and removes the private original-key registry entry. Source does not remove or rename the original Root/Prompt Parts when creating a visual. |
| `ClientScript:568-616` | Initial native engine prompt uses 6.5-stud MaxActivationDistance and account, cost and storage guards before one HatchEgg dispatch. Travel-only never triggers this prompt or sends that command. |
| `ClientScript:790-809` | Initial and recurring `u12:Update(actualRoot.Position)` calls use ordinary class method lookup; recurring call occurs every 0.25 seconds when a character Root exists. A passive observer after OC starts can inspect a receiver containing registrations made earlier. It is not limited to newly added eggs. |
| `ClientScript:869-885` | Opened-egg selection scans exact keys of private `tbl_upv_7`, requires Unlocked, root distance at most 16, and global native prompt visibility zero, then chooses nearest among those registered originals. This does not authorize arbitrary nearest Generic copies or establish paid eligibility from geometry alone. |
| `ReplicatedStorage.Shared.Utils.WorldUtil:12-38` | Native player-world correspondence uses actual world Spawn positions and horizontal distance. Missing character Root returns an Overworld fallback; OC must preserve missing-root uncertainty. The equivalent spatial comparison can corroborate a catalog-backed original's world location, independently of hatch registration. |
| `WorldUtil:110-115` | Native island destination is the exact world/island Portal.Spawn path. Surface travel remains a distinct native destination, as documented in the completed navigation research. |
| `ReplicatedStorage.Client.Effects.RenderAnimatedObject:16-17,98-106` | Another receiver shares 128/2/3D settings but stores constructor records instead of egg original Instances. Settings and same-named folder are insufficient receiver proof. |

The public Chunker class is a constructor/method table; this source exposes no global list of existing receiver Instances. The private egg registry has no verified exported accessor in the inspected source. The correction does not invent getgc, upvalue introspection, tags that have already been removed, or a speculative registry interface. A bounded passive native Update observation can strengthen hatch registration evidence, but travel location must not depend exclusively on receiving a future callback.

## Fresh saved scene observations

Fresh `inspect_instance` confirms **two** Common Egg original-shaped Models at `Workspace.Rendered.Chunker.Common Egg`, each with Decoration, Root, Prompt, Plate and Cost children and Unlocked=true. Each Plate and Cost has a SurfaceGui. Their matching full path and parent folder do not make them the same Instance. Neither has an Island/World attribute in this saved scene; current native definition and spatial world corroboration remain necessary.

| Saved original ID | Root position | Physical Prompt position |
|---|---|---|
| `35fcc9fe-43c4-a8c8-0adc-1d0d00001057` | `(-10.2552786, 7.7361164, -79.8115845)` | `(-7.7552800, 9.1361122, -79.8115845)` |
| `35fcc9fe-43c4-a8c8-0adc-1d0d0000115e` | `(-80.8732147, 8.2289152, 5.9610152)` | `(-82.3071518, 9.6289091, 3.9131444)` |

These positions and saved IDs are evidence only. They are not copied into movement code or treated as stable live identifiers. Both originals have negative X; the first also has negative Z. The incorrect nonnegative coordinate test therefore rejects both.

Fresh inspection also confirms **nine** Generic Common Egg Models, each with only a Hitbox MeshPart and Offset/Size attributes. `ReplicatedStorage.Assets.Eggs.Common Egg` similarly contains only a Hitbox. These visuals do not satisfy the original interface. The native animation formula and exact private original-key registry are necessary to relate a particular visual to an original; matching name, parent, Offset/Size or proximity alone is inadequate.

Actual saved surface Spawn positions are Overworld `(53.5104561, 6.6963253, -98.8041611)`, Minigame Paradise `(9859.8173828, 24.1498051, 199.4156647)`, and Seven Seas `(-23663.4003906, 7.8403697, 4.4231544)`. They corroborate these Common originals' Overworld placement when applying the native horizontal-world rule. Runtime code must reread actual live Spawn objects rather than use these constants. Island placement additionally requires actual accessible island geometry and the appropriate catalog/model Island identity; nearest-world alone cannot identify a vertically stacked island.

## Separate verification questions

For **travel location**, retain an exact physical original Instance whose source-supported original interface, current loaded ancestry, signed finite Root/Prompt geometry, native permanent catalog definition, actual world Spawn correspondence, model/catalog island identity and accessible island/surface geometry agree. Check received LocalData world and island membership independently. If multiple such originals remain legitimate physical placements, a location decision must explicitly rank those already verified alternatives and retain the exact selected Instance; it must not silently replace a Brain selection by name/path or apply a nearest display fallback.

For **hatch interaction**, retain the stronger current registration/engine-prompt/native proximity conditions. Native initial Prompt and opened Root ranges have separate semantics. A successful physical travel observation with unresolved registry/prompt state reports `HATCH_INTERACTION_UNVERIFIED`; it cannot report `HATCH_RANGE_OBSERVED` based solely on the source-shaped physical anchor.

Both paths recheck the selected exact Model, original structural form, exact Root, world/island and access after native area travel, before direct positioning and during stable arrival. Physical arrival does not require an unchanged engine prompt or hatch registration. Native hatch-range reporting separately checks exact prompt identity/provenance and its range or the opened scanner. No generic/decor-only fallback, locked-world bypass, synthetic instance, hardcoded destination, receiver mutation, model deletion, future phase or independent movement loop was added.

Safe standing support and full-avatar collision clearance remain required. An assigned CFrame is a request/attempt, not arrival. The observer must check the actual current character position and stable identity/geometry over the bounded arrival window. One authorized travel attempt, Pause/Resume/Stop and respawn cancellation remain in the central scheduler. TRAVEL_ONLY keeps hatch, spending, equipment, purchases, pickup/bubble farming, rewards and the one-hatch allowance disabled; the progression reserve remains untouched.

## Unresolved owner acceptance

The owner must still confirm actual character movement, the correct real accessible egg destination, stable physical arrival and the corresponding native interaction observation or precise unresolved interaction blocker. Saved source/scene and synthetic tests cannot provide that acceptance. Server egg registration, proximity acceptance, stream state and avatar-specific collision in the owner's live session remain independent limits. Test B remains held and Phase 4 remains open.

## Implementation and offline verification

Candidate build **`0d5caa499c8c`**, tag **`phase4-travel-0d5caa499c8c`**. `node scripts/build.mjs` produces the function-returning bundle; `node scripts/test.mjs` passes official Luau compilation, **558 main-suite cases**, artifact equivalence and complete test Config isolation. New checks cover signed coordinates, unchanged nonnegative finance validation, registration before OC startup, missed observer fallback to a verified physical original, eleven duplicate observations/two physical placements, locked/spatially mismatched content, streamed targets, exact-instance retention, actual adapter assignment, server-corrected positions, independent hatch uncertainty, collision/visual overlap and bounded logging. The approved equipment and stationary pickup regressions remain in the suite.

TRAVEL_ONLY uses current scene location evidence immediately; its independent interaction observer remains bounded to five seconds. No timeout extension, perpetual polling, private-state enumeration or extra movement loop was added. Normal output is one chosen target, at most four compact candidate rows, material state changes and a concise 15-second summary. Expanded ancestry/attributes/prompt evidence requires an explicit diagnostic method or debug setting.

All **104 completed research files** remain byte-identical to the existing pre-edit recovery snapshot. The failed `a0ee412ac828` pin and all earlier pins are preserved; the prepared Test B pin is unchanged. Public branch/tag/raw-byte verification is performed after publication and reported separately. These checks are source/publication evidence, not a live OC travel PASS.

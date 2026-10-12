# Phase 4 egg identity follow-up

Authored investigation, 2026-10-12. This resolves a specific gap exposed by the owner's travel-only test of build `141b7608bedf`; it does not repeat the completed research libraries or approve Phase 4. Studio was inspected read-only in the owner-confirmed saved `Game` workspace, connected ID `bbe2d8d8-d973-46af-861a-dde5eef21a7f`. No Luau was executed, object changed, or play state changed. Saved object observations cannot establish the owner's current live registration table or gameplay success.

The [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349) and [Phase 4 page](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363) were freshly read, including the October 12 Mastery-first owner override. That future policy does not authorize broader phases or paid actions in this zero-spend travel retest. Comment retrieval returned no discussion content and `suggested_edits_status=not_enabled`; unavailable suggestions are not claimed reviewed.

The owner log for `141b7608bedf` confirms benchmark convergence in **66 native comparisons**, current and feasible score **1,752**, then a repeated Common Egg ambiguity. No movement, hatch request, spending or equipment change occurred. This is the latest owner evidence; no precise income rate or global optimum is inferred.

## Existing research used

- [Native eggs and pets](research/replicatedstorage/EGGS_AND_PETS.md), especially the native physical egg contract: registered originals, the initial 6.5-stud prompt, opened-egg 16-stud nearest scan, account access, and server uncertainty.
- [World and navigation](research/replicatedstorage/WORLD_AND_NAVIGATION.md), especially intentional egg travel, distinct world/island destinations, and presentation objects that are reparented by native chunkers.
- [Navigation source ledger](research/replicatedstorage/NAVIGATION_SOURCE_LEDGER.md): returned source-line numbering and the distinction between saved reconstructed client code and live acceptance.
- [Unknown and server-only rules](research/replicatedstorage/UNKNOWN_AND_SERVER_ONLY_RULES.md): saved Edit-mode state, source fidelity, unknown server rules, and owner-operated verification.
- [Native versus wiki conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md), and [future OC improvements](research/wiki/FUTURE_OC_IMPROVEMENTS.md): native interfaces take priority, navigation availability is observed, and a single Brain/scheduler retains evidence and uncertainty. No historical wiki layout is used to choose an instance.

## Exact native registration and rendering evidence

The following are returned `script_read` line numbers, not the decompiler's embedded original-line comments.

| Native path and lines | Observed contract | Identity consequence |
|---|---|---|
| `StarterPlayer.StarterPlayerScripts.ClientScript:375-376` | The egg system creates `Chunker.new(128, 2)` and sets `Mode` to `3D`. | Settings alone do not identify its receiver: pickups at 1140-1141, portals at 1417-1418, and `Client.Effects.RenderAnimatedObject:16-17` use the same settings. |
| `ClientScript:504,790-809`; `Shared.Utils.Chunker:8,20` | Character-added and initial observations call `u12:Update(root.Position)`; the recurring native callback calls `u12:Update(v47.Position)` at 807 and is registered with `every(0.25, update_2)` at 809. Receiver construction uses the shared class as its metatable, whose `__index` is that class. | These are ordinary method lookups on the actual receiver, not a cached bound Update function. The existing central class-method observer can see the game's own Update calls without calling Update or adding an automation loop. |
| `ClientScript:532-555,628-635` | Rendering finds `ReplicatedStorage.Assets.Eggs[original.Name]`, clones that asset, adds `Offset`, parents the visual to `Workspace.Rendered.Generic`, and records `tbl_upv_7[original] = {Model, Prompt, VisualLock}`. | The registry is keyed by the original Instance. Generic visuals are separate objects; identical names or paths do not associate a visual with a particular original. |
| `ClientScript:395-452` | `updateUnlocked` first requires the original to be in `tbl_upv_7` at 409-412. It checks catalog/account access, attaches the engine prompt to the exact original `Prompt` part only for an eligible unopened egg at 438-445, and writes original `Unlocked` at 451. | A runtime engine prompt attached to the exact original is useful positive evidence. An inherited or saved `Unlocked` attribute alone is not direct proof of current registry membership. |
| `ClientScript:639-748,750-767` | Tagged Egg originals are passed individually to `createFromModel`; it removes the `Egg` tag at 674 and passes the exact original Instance to `u12:Add` at 747. | A missing Egg tag is expected after initialization. Do not require that tag forever, select a tag's first result, or treat the native chunker as cloning originals. |
| `ClientScript:869-885` | The opened-egg selection loop scans keys of private `tbl_upv_7`, requires `Unlocked`, excludes distance above 16, and chooses the nearest registered original. | This is a final native interaction check among registered originals, not permission for OC to select any nearest same-name Workspace model. There is no exported egg-registry accessor established by this source. |
| `ReplicatedStorage.Client.Gui.ProximityPrompt:13,21-51` | `_cache` is keyed by exact engine ProximityPrompt Instances; `new` adds a newly created prompt and destruction removes it. | `_cache[prompt] == true` together with `prompt.Parent == original.Prompt` can support an initial prompt's native provenance. Opened eggs detach that prompt, so a detached cache entry cannot be associated with an original merely by `ActionText`. |
| `ReplicatedStorage.Shared.Data.Eggs:45-48` | Common Egg costs 10 Coins and Spotted Egg costs 110 Coins; both explicitly belong to `The Overworld`. | Native catalog world is retained. Neither definition establishes one canonical placement among multiple originals. |
| `ReplicatedStorage.Shared.Utils.WorldUtil:12-38` | Native player-world detection compares the player's horizontal position with cached world Spawn positions. | It is a player-world helper, not an egg-registration or original-model identity service. |

### Native Chunker receiver fields

`ReplicatedStorage.Shared.Utils.Chunker` was read in full (168 returned lines). Its `new:9-20` returns `Mode`, `_chunks`, `_loaded`, `_chunkSize`, `_folder`, `Loaded`, `Unloaded`, and `RenderDistance`. It creates a fresh same-named `Chunker` folder under `Workspace.Rendered` for every receiver. `_folder` is the actual folder Instance, not a unique path string.

`ToCoord:22-32` creates a rounded Vector3 coordinate; `2D` zeroes its Y component. `Add:33-55` stores an array of exact passed values in `_chunks[coordinate]`, prevents adding the same Instance twice to that coordinate, and parents an Instance to `_folder` only when `_loaded[coordinate]` is non-nil. It does not clone that Instance. `IsValueLoaded:99-117` searches the arrays indexed by `_loaded` keys and returns true only for an exact matching value. `Update:118-167` loads coordinates and reparents exact Instances to `_folder`, or unloads them and reparents them to nil.

A bounded passive observation of the actual native `Update` receiver can therefore expose exact runtime membership without private-upvalue introspection. A receiver must be identified by catalog-backed original egg values, their native interfaces, and membership; its name, size settings, or arbitrary folder order are insufficient. Multiple verified same-name registered originals remain ambiguous. An observation must preserve native arguments and results, never call `Add`, `Remove`, `Update` itself, or mutate Workspace, and must share the existing GameKnowledge observer/cache. Native membership does not establish server hatch acceptance or live travel success.

## Saved duplicate observations

`search_game_tree` independently found **eleven Common Egg models**: nine under Generic and two under Chunker. It also confirmed the owner's **four Spotted Egg models**: two under Generic and two under Chunker. Every match was subsequently inspected.

All nine Generic Common models and both Generic Spotted models have only a `Hitbox` MeshPart, plus `Offset` and `Size` attributes. `ReplicatedStorage.Assets.Eggs.Common Egg` also has only its `Hitbox`. These are visual forms, with no Root/Prompt/Plate/Cost interface, and are excluded from interactive-original selection. The two Common visuals aligned horizontally with the two observed original Roots do not make either original canonical.

`Workspace.Rendered` has **five distinct folders named Chunker**. Its egg-model folder has saved unique ID `35fcc9fe-43c4-a8c8-0adc-1d0d00000f8f`; both Common and both Spotted originals are children of that same exact folder. The inspection API returns all matches for a duplicate path. A path or `FindFirstChild("Chunker")` is not an identity.

| Egg original saved unique ID | Model path | Root position | Prompt position | Additional observation |
|---|---|---|---|---|
| Common `35fcc9fe-43c4-a8c8-0adc-1d0d00001057` | `Workspace.Rendered.Chunker.Common Egg` | `(-10.2552786, 7.7361164, -79.8115845)` | `(-7.7552800, 9.1361122, -79.8115845)` | Prompt has a Tutorial Attachment |
| Common `35fcc9fe-43c4-a8c8-0adc-1d0d0000115e` | `Workspace.Rendered.Chunker.Common Egg` | `(-80.8732147, 8.2289152, 5.9610152)` | `(-82.3071518, 9.6289091, 3.9131444)` | Prompt has no children |
| Spotted `35fcc9fe-43c4-a8c8-0adc-1d0d00001041` | `Workspace.Rendered.Chunker.Spotted Egg` | `(-10.2552786, 7.7361174, -68.8115845)` | `(-7.7552800, 9.1361141, -68.8115845)` | Prompt has a Tutorial Attachment |
| Spotted `35fcc9fe-43c4-a8c8-0adc-1d0d00001149` | `Workspace.Rendered.Chunker.Spotted Egg` | `(-91.7780075, 8.2289152, 12.3185453)` | `(-92.8345490, 9.6289091, 10.0527849)` | Prompt has no children |

Every listed original has Decoration, Root, Prompt, Plate, and Cost children and an `Unlocked=true` attribute. No original has a World or Island attribute in this saved observation. Roots are anchored, transparent, non-colliding Parts with size `(1.2, 0.2, 1.2)`; Prompts are anchored, transparent, non-colliding Parts with size `(0.8, 0.6, 0.6)`. Both Common Plates and Costs have SurfaceGui children. The Root/Prompt geometry clearly distinguishes the actual Instances but does not choose a privileged placement.

The coordinates and saved IDs above are diagnostic evidence only. They must not be copied into movement code or treated as stable live identifiers. `ClientScript:562-566` uses the Tutorial Attachments to set tutorial references, but the ordinary native egg-selection loop does not use them. Tutorial presence is therefore not a justified tie-breaker.

## Integration and remaining limits

Brain candidate analysis and travel preflight must use the same resolver and exact Instance reference. Native originals and visuals should be classified consistently; access remains separately checked against received LocalData and native definitions. Preflight must revalidate the retained original, Root, Prompt, world/island identity, and native interaction conditions before any movement. No name/path/nearest/first-match fallback may substitute another Instance.

The saved observations do not prove that just one of the two Common originals is currently registered in the owner's live egg receiver. If live native registration cannot distinguish a single eligible original, selection must remain blocked and explain that unresolved state. If two originals are both verified, the current conservative policy also remains blocked. That is a preflight rejection, with zero movement attempts consumed or dispatched. A repeated identical state should produce one diagnostic followed by material state changes or the regular summary, not alternate raw and structured lines every second.

Test A remains travel-only: one bounded permission once actual preflight succeeds, no hatch requests, no spending, no equipment changes, and stable arrival plus Pause/Resume/Stop preserved. Test B is not started and Phase 4 is not marked approved. Only the owner's next live travel result can verify the resulting gameplay behavior.

## Candidate delivery

Build **`a0ee412ac828`**, release pin **`phase4-travel-a0ee412ac828`**, is produced by `node scripts/build.mjs`. `node scripts/test.mjs` passes official Luau compilation, **527 main-suite cases**, complete Config isolation and bundle equivalence. The suite includes sixteen actual-knowledge identity/observer checks, five logging checks, and two actual Knowledge/Brain/travel integration checks. Mock receivers and geometry are synthetic evidence only.

Both completed research libraries remain byte-identical across all **104 files** to the pre-edit recovery snapshot. Earlier migration, Phase 4 AUTO, and `phase4-tests-141b7608bedf` pins are retained. Only the current travel-only example receives the new pin; the prepared hatch example remains historical and held. Public branch/tag/raw-byte verification follows commit/push and is reported separately; it is not live gameplay verification.

## Offline regression scope

[The identity regression file](../tests/phase4-egg-identity.luau) contains 16 checks against the actual GameKnowledge implementation and independently passed using a fresh bundle library with the official Luau CLI. Its synthetic fixtures cover same-name/same-parent/same-path ambiguity, distinct Instance IDs, registered-versus-stale copies, exact retained-instance replacement rejection, engine prompt cache/parent provenance, unresolved and malformed receivers, registered opened-range competitors, unloaded membership, native argument/multiple-result forwarding after Update, mixed receivers, shared egg/pickup observation, Coming Soon exclusion, multiple receiver ambiguity, bounded cleanup, and stale callbacks after destruction. These checks verify local behavior over modeled interfaces; they do not verify the owner's live egg receiver, any character movement, server acceptance, or gameplay outcome.

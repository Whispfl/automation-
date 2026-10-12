# Inventory method and coverage

`SOURCE_CONFIRMED (HIERARCHY ONLY)`. ReplicatedStorage inspection reported 50,632 descendants in five direct roots. Full trees read with maximum depth 10 and head limit 100,000. Assets initially had 31 depth-boundary nodes; re-rooting at Normal/Shiny Carnival Ferris Wheel Mythic and Normal Overworld Basket Mythic expanded all 60 omitted ParticleEmitters. Final returned entries reconcile exactly with root descendant counts. No remaining depth boundaries were reported.

| Root | Descendants | Inventory rows including root |
|---|---:|---:|
| Assets | 49,294 | 49,295 |
| Client | 760 | 761 |
| Shared | 567 | 568 |
| Remotes | 6 | 7 |
| FastFlags | 0 | 1 |
| Total | 50,627 below the five roots | 50,632 |

The service itself is the additional 50,633rd object. `inventory/*.jsonl` contains exact reported name/type/path/parent, boundary metadata if any, and an observation index. This is metadata, not copied native source.

Duplicate sibling names mean some dot paths are non-unique. Preserve duplicate rows; never deduplicate to claim exact object coverage. Observation indices are local row identifiers, not Roblox object IDs. Literal dots in some MeshPart names may be ambiguous to path readers. No individual unique ID was requested for every object. Thus complete count/path coverage does not promise uniquely addressable objects.

Purpose, schema, dependencies and exports require native contents. Assets are templates/visual resources until a native caller proves an interaction role. Phase/category in MODULE_INDEX are explicit name-based triage hypotheses. Source ledgers distinguish contents read, targeted excerpts reviewed, deep reviewed, blocked and not yet reviewed. No module is represented as deeply audited merely for appearing in this inventory.

Inspection observed saved decompiled text with bytecode comments. Bytecode/full modules are not persisted. Returned tool line numbers are reference anchors; embedded decompiler original-line comments are a different numbering system. Saved source can be damaged, outdated or unlike current server implementation.

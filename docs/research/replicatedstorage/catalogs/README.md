# Economic catalog facts

Extracted2026-10-11 from the owner's connected saved workspace in Edit mode, using complete read-only module source. These normalized fact records are documentation data, not executable game source, final server odds, live active-event state, or the owner's actual account inventory.

| File | Rows | Native source |
|---|---:|---|
| EGG_FACTS.jsonl | 218 | ReplicatedStorage.Shared.Data.Eggs1–552 |
| PET_BASE_STATS.jsonl | 2,166 | ReplicatedStorage.Shared.Data.Pets1–2177 |
| CURRENCY_FACTS.jsonl | 49 | ReplicatedStorage.Shared.Data.Currency1–60 |
| ECONOMY_SOURCE_COVERAGE.jsonl | 50 | Economic module fetch/review ledger, including five root-document cross-review sources and nine stat-extension sources |

Each record's sourceLine is the exact returned one-based source line containing that definition, not a decompiler original-line comment. Egg entries spanning several lines use the start line. Unicode decimal-byte string escapes were decoded consistently in both egg and pet names. All egg pool names resolve to the pet catalog; no unresolved cost argument or inherited builder remained.

EGG_FACTS: name, sourceLine, normalized cost, world/event/ProductId, pet name/catalogWeight pool, computed catalogWeightSum, optional normal/shiny reward, ignoreInfinityEgg/challengeIgnore/isAdminEgg/alwaysAllowXL flags, optional riftSummonCost and inheritedMetadataSourceLine. Five inherited builder chains were merged. Fourteen inline scalar cost tables were resolved. Sixty-four defaults are explicitly marked builderDefault; a default Coins1 does not establish purchase availability. Six ProductId eggs require a paid path and must be excluded without owner authorization.

PET_BASE_STATS: name, sourceLine, rarity, exact base stats and explicit Infinity/Celestial/Void/Limited/TerminalHidden/ChannelIgnore values when present. The builder's default rarity is Common. These records omit images/render details and later mutable Egg/Chance/Tier annotations; use a particular egg pool for outcome weights. Base stats exclude level, Shiny/Mythic/XL/Super, enchant, team, mastery, potion, pass and world effects.

CURRENCY_FACTS: exact native key, display label (native key fallback), sourceLine, layoutOrder and booleans for explicit CanBeMultiplied/InventoryDisplay=true. A false boolean means that true property was absent in the definition; it is not an independently tested prohibition. Equal display labels do not alias native currency keys.

catalogWeightSum is ordinary numeric summation of source weight values, with floating-point rounding. It is not an asserted100 total. Normalize only for a clearly labelled conditional weighted-sampler model; preserve all outcome weights including UI-hidden entries. Native transforms and source-fidelity limits are documented in ../EGGS_AND_PETS.md and ../ECONOMY_AND_ROI.md.

Validation here was structural fact extraction and cross-reference inspection, not running Roblox game code or OC tests. Source scripts/bytecode were never written to this catalog directory.

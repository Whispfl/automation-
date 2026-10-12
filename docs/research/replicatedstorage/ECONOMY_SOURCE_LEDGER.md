# Economics source ledger

Research date:2026-10-11. Connected saved workspace, Studio 5528d459-f21f-4304-aa34-0f2deff5a197 in Edit mode. Only read-only Studio source reads/grep were used. No Luau execution, object edit, play-state change, gameplay code edit, build/test, commit, push, upload, purchase, hatch or equip occurred.

## Coverage accounting

50 unique sources were fetched complete in this economic sub-research, independent documentation review and stat extension. Of these, 38 had their complete filtered executable/data bodies reviewed; 2 had systematic complete catalog fact extraction; 10 had targeted deep review within the complete fetched body. "Fetched complete" alone does not mean every function/consumer/dependency was semantically audited. This is category/module coverage, not coverage of all 701 scripts in the full ReplicatedStorage inventory. The first economic checkpoint comprised36 sources; five independent checks of root research are detailed in ECONOMY_REVIEW_NOTES.md; nine additional fetches are documented in STAT_DEPENDENCY_EXTENSIONS.md.

Original source and bytecode stayed in transient tool memory. Numbered lines3/4 bytecode and decompiler comment blocks were removed only from displayed excerpts. Long executable/catalog lines were retained. Local files contain summaries, selected interface names/formulas and normalized factual data, not full scripts or bytecode. All references use MCP-returned one-based source lines, not original-line metadata embedded in decompiler comments.

| Exact source path | Complete source range fetched | Review depth |
|---|---|---|
| ReplicatedStorage.Shared.Data.Builders.EggBuilder | 1–181 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Builders.PetBuilder | 1–136 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Builders.LootPoolBuilder | 1–35 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Builders.EnchantBuilder | 1–155 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Enchants | 1–42 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Buffs | 1–153 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Currency | 1–60 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.GetEggPool | 1–130 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.ApplyMultiplierToPool | 1–46 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.Stats.PetUtil | 1–243 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.PetInventory | 1–405 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.PetStackUtil | 1–68 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.PetLevelUtil | 1–135 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.ShinyUtil | 1–102 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.EnchantUtil | 1–440 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.Stats.BuffUtil | 1–344 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.SuperUtil | 1–202 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.XLEggUtil | 1–84 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.GetInfinityEgg | 1–199 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.SinisterPotion | 1–120 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Framework.Utilities.Math.GetRandomWeightedItem | 1–29 | complete filtered body reviewed |
| ReplicatedStorage.Client.Gui.Utils.CheckInventorySpace | 1–51 | complete filtered body reviewed |
| ReplicatedStorage.Client.Gui.Frames.Shiny | 1–435 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Eggs | 1–552 | systematic complete catalog fact extraction |
| ReplicatedStorage.Shared.Data.Pets | 1–2177 | systematic complete catalog fact extraction |
| ReplicatedStorage.Shared.Utils.Stats.StatsUtil | 1–2585 | targeted deep review; complete source fetched |
| ReplicatedStorage.Shared.Constants | 1–222 | targeted deep review; complete source fetched |
| ReplicatedStorage.Shared.Data.Potions | 1–79 | targeted deep review; complete source fetched |
| ReplicatedStorage.Client.Gui.Frames.Inventory | 1–5595 | targeted deep review; complete source fetched |
| ReplicatedStorage.Client.Gui.LootPoolViewer | 1–1733 | targeted deep review; complete source fetched |
| ReplicatedStorage.Client.Gui.Frames.Enchants | 1–1902 | targeted deep review; complete source fetched |
| StarterPlayer.StarterPlayerScripts.ClientScript | 1–3323 | targeted egg subsystem deep review; complete source fetched |
| ReplicatedStorage.Client.Gui.Utils.GetPetRenderList | 1–116 | complete filtered body reviewed |
| ReplicatedStorage.Client.Gui.Frames.Inventory.stackWindow | 1–523 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.SortPetsList | 1–231 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Framework.Utilities.Math.Time | 1–241 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.ShopUtil | 1–244 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Builders.WorldRewardsBuilder | 1–86 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.Stats.SeasonUtil | 1–602 | targeted deep review; complete source fetched |
| ReplicatedStorage.Shared.Data.DailyPerks | 1–93 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.WheelSpin | 1–25 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.RuneUtil | 1–74 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Runes | 1–228 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.FragmentUtil | 1–83 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Utils.Stats.GuildUtil | 1–437 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Guilds | 1–206 | complete filtered body reviewed |
| ReplicatedStorage.Client.Gui.Frames.RuneCrafting | 1–469 | complete filtered body reviewed |
| ReplicatedStorage.Client.Gui.Frames.Buffs | 1–665 | complete filtered body reviewed |
| ReplicatedStorage.Shared.Data.Powerups | 1–974 | targeted deep review; complete source fetched |
| ReplicatedStorage.Client.Gui.Frames.Guilds | 1–3044 | targeted deep review; complete source fetched |

## Deep review details and boundaries

- Core builders and catalogs: explicit defaults/costs/rewards/world/event/product/flags, pet rarity/base stat/variant-family flags, currency keys/multiplier/inventory flags. Eggs/Pets data was extracted without executing its postprocessing. Island/Tier/Egg/Chance mutations are described separately in EGGS_AND_PETS; normalized fact files do not pretend these runtime annotations are stable.
- GetEggPool/ApplyMultiplier/GetRandomWeightedItem: full transform/donor/clamp behavior and conditional normalization; separate final server draw remains unknown.
- Pet identity/count/merge/XP/Shiny: complete helpers and native Shiny UI guards, quantities, preview, event/timeout distinction.
- StatsUtil: all filtered statements traversed; economic functions98–754, specialized Shiny754–1220/Mythic1222–1704, Secret1706–1794, Super1796–1818, Infinity1819–1883, currency cap1885–1906, ordinary Luck1908–2478, SecretLuckMultiplier2480–2522 and Pickup/Walkspeed2524–2585 inspected. Specialized potion/shrine dependencies were not all independently deep-reviewed; many retain separate delegated eligibility semantics.
- ClientScript: egg registration/unlock/cost prompts and nearest/auto/manual subsystem395–1066. Remaining bubble/world/general behavior was not counted as a full client audit in this ledger.
- Inventory: equip/unequip/team selection2121–2192/2606–2900, PowerupEgg2941–2977, and selected consumable references. UI sorting/favorites/trade/delete/general inventory paths remain outside this category's deep audit.
- LootPoolViewer: pool filtering496–529, ordinary egg566–670, product egg672–770, Infinity771–845 and Chance rendering424. Gift/chest/remaining viewer paths are not all deeply reviewed.
- Enchants UI: native cost142–177, specific auto348–470, preservation875–947, slot action980–1045, AutoRoll/close1292–1336, reroll1583–1625 and selection1777–1827. Remaining tooltip/rendering/currency selection details not claimed complete.
- Constants: economy/baseline/variant/recipe/storage41–66, enchant91–93, relevant restricted egg sets195/221. Potions: core and current Sinister durations; root category research owns full consume/craft/shop contracts.
- Additional inventory helpers: complete stackWindow/GetPetRenderList/SortPetsList bodies reviewed. Duplicate equipped IDs versus stack quantity, visual cell padding and native sort precedence do not define a currency-optimal team.
- Stat dependency extension: complete RuneUtil/Runes/FragmentUtil/GuildUtil/Guilds/RuneCrafting/Buffs bodies reviewed; Powerups954–974 and Guilds UI208–249/2299–2321/2785–2882/2901–3044 targeted within complete fetches. Exact rune recipes and serial time, active-use guards, fragment count/per-color cap semantics, Super units/cache limits and guild maximum-per-stat factors are documented in STAT_DEPENDENCY_EXTENSIONS.md. Inventory4304–4489 and StatsUtil caller review was extended without counting duplicate sources.

## Evidence labels

SOURCE_CONFIRMED: exact saved source definition/control flow.
CLIENT_ESTIMATE: client helper/display derived output, including uncertainty from source fidelity.
HYPOTHESIS: proposed reusable mathematical model or planning implication, not implementation.
UNVERIFIED: no authoritative/live/owner evidence available.
Definitions in the connected saved workspace are not proof of active event availability. Owner reports Halloween; retained Fall/older catalogs stay separate from that live claim.

## Material limitations

PetUtil162–163 undefined variable,171 possible nil,126/40 variant nesting and214–230 discarded Seashells flag; StatsUtil253 discarded VIP,365–371 possible nil storage factor,640 discarded More Storage and752 literal PetXP return1; EnchantUtil259 empty predicate,172–199 unused eligibility,384 Extra type and411–415 empty filler; XLEggUtil66–72 inverse-looking chance scaling; SinisterPotion28–33 empty callback; Enchants auto433 reused/shadowed ID naming. These saved decompile anomalies are not certified live bugs. Their presence limits confident reconstruction and calls for owner native display/helper/account comparisons before implementation.

No authoritative server hatch draw/variants/pity/refunds/auto-delete/storage batch, final enchant locking/cost/selection or craft inheritance handler was accessed. These rules remain unavailable in this evidence set. No actual verified LocalData account snapshot or live earning-rate measurement was obtained by this economic batch. Native requests are call-site contracts, not blanket permission to spend.

## Required context read

Notion master 3f53d7e9278d81c5a6cacfe227eb4349, Phase4 3f53d7e9278d81a796a9d3c505076363 and Phase9 3f53d7e9278d81e7a631d19062ab3358 were each fetched and read in full before native economic research. Current user instruction supersedes historic build/push rules: research/documentation only and no GitHub synchronization during suspension.

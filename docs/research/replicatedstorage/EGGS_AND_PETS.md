# Eggs and pets — native evidence research

Research date: 2026-10-11. Documentation only; Phase 4 remains unapproved. Connected saved workspace was read in Edit mode. Catalog membership does not establish current availability, server acceptance, or live event state. The owner reports Halloween; retained Fall entries are historical/conditional until observed.

## Evidence and source quality

`SOURCE_CONFIRMED` means a statement is supported by the exact returned saved-workspace source. Many sources explicitly identify a saved/decompiled copy. Returned line numbers below are MCP source lines, **not** `line:` numbers inside decompiler comments. No Luau was executed. Source evidence alone is not owner gameplay verification.

Decompiler anomalies are material: `Stats.PetUtil` lines 162–163 use an undefined `v16`; the bubbler level variable can remain nil (155–171); shiny scaling is nested inside a Mythic branch (126); `GetChance` has variant conditions nested under Super (40); `GetPower` sets a discarded local instead of its Seashells flag (214–230). These are observations of the returned text, not demonstrated live bugs. Do not silently repair these expressions into confident formulas. Prefer owner comparison of the native runtime helper's returned values with displayed stats before implementing economics.

## Catalog schemas

`SOURCE_CONFIRMED` — `ReplicatedStorage.Shared.Data.Builders.EggBuilder`:

| Field | Meaning / source |
|---|---|
| `Pool` | Array of `{Chance, Item={Type="Pet",Name}}`; Pet builder method 27–38, Build 153–166 |
| `Cost` | Item-shaped cost; default `{Type="Currency",Currency="Coins",Amount=1}` (25), explicit Cost stored 40–53 |
| `World`, `Event` | Catalog annotations (66–75,96–103,169,172), not access confirmation |
| `ProductId` | Developer-product annotation 77–86,171; must exclude unauthorized Robux paths |
| `Reward` | `{Normal,Shiny}` reward annotations 88–94,170 |
| `RiftSummonCost` | 104–110,173; eligibility/pacing requires separate native client evidence |
| Flags | `IgnoreInfinityEgg`, `IsAdminEgg`, `AlwaysAllowXL`, `ChallengeIgnore` (112–141,174–178) |
| `LayoutOrder` | Builder call order (152,177); not economic ranking |

`LootPoolBuilder` lines 20–33 inserts Chance unchanged and returns the pool unchanged. A Chance is a weight-like field; this builder neither normalizes nor asserts a total of 100.

`SOURCE_CONFIRMED` — `ReplicatedStorage.Shared.Data.Builders.PetBuilder` defaults to Common, Bubbles=1, unknown images (21). It exports `Chance=100`, `Tag`, `Rarity`, `Images`, `Stats`, `Limited`, `Infinity`, `Void`, `Celestial`, `TerminalHidden`, `ChannelIgnore`, `LayoutOrder` (114–134). Stats are role-specific named values, not a single rarity score.

`Eggs` 495–530 later mutates each referenced pet's `Egg`, `Chance`, and Legendary/Secret `Tier`; it skips `4x Luck Creaking Egg` (497–499). A pet appearing in multiple eggs can receive traversal-dependent annotations. Always retain the candidate **egg's own pool**, rather than use a pet's global Chance/Egg annotation as that egg's odds. `Eggs` 531–539 derives `Island` from tagged Egg instances' Island attribute; absence is unavailable location evidence. `Eggs` 541–550 attaches pools/images to Powerup definitions whose Type is Egg.

## Team and inventory facts

`SOURCE_CONFIRMED` — `Stats.StatsUtil` 98–112 reads equipped IDs from `Teams[TeamEquipped].Pets` and resolves records through `PetInventory:Get(Pets,id)`. Inventory records, quantities, and equipped IDs are different units.

`PetInventory` builds a weak-key per-array ID index (55–72); count mismatch invalidates it, and stale ID-position lookup rebuilds it (93–119). It exposes Find/Get/GetByName and managed mutation helpers, plus Invalidate (121–403). Reuse the existing OC dependency cache; do not add another reader cache. A same-length replacement requires ID validation/invalidation, so future snapshot diffing must not rely on record count alone.

`PetStackUtil:CanMergePet` 12–19 permits unlocked, XP=0, no-enchant, non-Secret records. FindMergePet additionally matches Name/Shiny/Mythic/XL/Super and selects the earliest matching inventory position (29–52). `Amount` can represent several pets in one record.

`StatsUtil:GetUsedPetStorage` 667–682 sums `Amount or 1` normally, but for Digital Storage returns JSON-encoded byte length (650–676), cached for five seconds. `GetMaxPetStorage` 624–648 uses 1,000,000 for Digital Storage or a clamped ordinary cap up to 3,000. BasePetStorage is 350 (`Constants`45). Its More Storage buff is calculated into discarded `_` at 640, a fidelity limitation. Do not infer digital free hatch count from bytes as if each pet were one slot.

`StatsUtil:GetMaxPetsEquipped` 404–427 begins at Constants.BasePetsEquipped=4 (`Constants`46), applies first Equips mastery, permanent Pet Equips, Extra Equips +3, milestone PetEquips, minimum1. Teams begin at1 (`Constants`47; StatsUtil373–388). `GetMaxSupersEquipped`429–439 uses its own limit plus milestone; team feasibility must respect it.

## Shiny crafting economics and protections

`SOURCE_CONFIRMED` — `ShinyUtil:GetRequiredCount` 11–22 uses Constants.ShinyCountRequired by rarity, or8 for XL. Constants54–55: Common/Unique16, Rare/Epic12, Legendary10, Secret8; XL8. CanUse (24–29) excludes Shiny and Locked only. Counts require matching Name/Mythic/XL/Super and sum Amount (31–47). Selection (49–100) puts the requested source record first, then lower XP, then no-enchant before enchanted, then ID. It returns `{Id,Item}` quantities until the required count is reached.

Native selection is not an OC preservation policy: equipped pets, valuable enchantments, targeted variants, and future duplicate utility need explicit protection. Compute utility after removing all ingredients and adding the result. A stronger individual shiny can still make the best feasible team weaker by consuming several useful duplicate slots. No recipe was invoked; success and exact result transfer (XP/enchant retention), mastery gate, server validation remain unverified here.

## Pet level curve

`SOURCE_CONFIRMED` — `PetLevelUtil`27,70–90 gives cumulative XP:

`XP(L) = clamp(5 * ceil(((L-1)/(Lmax-1))^2 * XPmax / 5), 0, XPmax)`.

Level lookup finds the highest L whose cumulative threshold is at most XP (29–55). Marginal level XP is the difference of adjacent thresholds (83–90). XP awards cap at rarity XPmax (102–112). Constants59 gives XPmax: Common10,000, Unique15,000, Rare20,000, Epic75,000, Legendary400,000, Secret1,000,000. This is a quadratic progression curve rounded upward to5 XP, not linear XP per level.

`CLIENT_ESTIMATE` — PetUtil126 expresses a level contribution up to +0.35 to a multiplier, XL multiplies by2.5 (127–129; Constants50), but Mythic/Shiny nesting and nil-variable anomalies prevent certifying all variants' runtime formulas from the returned decompile. Native displayed/helper output needs owner comparison. No unseen server formulas are inferred.

## Catalog fact extraction checkpoint

Normalized factual tables are saved in catalogs/EGG_FACTS.jsonl (218 eggs), PET_BASE_STATS.jsonl (2,166 pets), and CURRENCY_FACTS.jsonl (49 currencies). Every egg pool pet name resolves to the pet table; all explicit scalar costs, including 14 inline cost tables and five inherited builder chains, were resolved. These are definitions with source lines, not original scripts, account facts, or availability claims. The catalog has 6 ProductId eggs, 64 eggs retaining builder-default cost, 89 IgnoreInfinityEgg entries, and 9 IsAdminEgg entries. A Coins1 default must never turn a reward/powerup/product egg into an assumed purchasable world egg.

Pet rarity counts: Common134, Unique27, Rare182, Epic123, Legendary633, Secret1,067. Flags overlap: Infinity143, Celestial168, Void17, Limited1,917. Thirteen base-stat keys occur: Bubbles, Coins, Gems, Tickets, Pearls, Candycorn, Petals, Clovers, EasterEggs, TropicalSeashells, CarnivalCoins, Leaves26, Candycorn26. Missing currency stats are meaningful. A retained Leaves/Candycorn pet is not automatically valuable for Leaves26/Candycorn26.

## Luck transforms and why a displayed chance is not final odds

SOURCE_CONFIRMED — GetEggPool13–128 accepts egg name, world, ordinary luck, optional Secret luck, optional Infinity luck, and optional account data. Its world parameter is unused in the shown body. Order is:

1. Multiply Epic entries by min(4, ordinary luck), with Legendary/Secret excluded from donor subtraction (24–54).
2. Multiply Legendary and Secret entries by ordinary luck (55–72).
3. If supplied and above1, multiply Secret entries by Secret luck (73–91).
4. If supplied and above1, multiply ItemUtil:IsInfinityRarity entries by Infinity luck (92–109).
5. For an infinite Season account, multiply pets with a nonnil Celestial field by the Season CelestialLuck perk (110–126).

ApplyMultiplierToPool14–44 clones weights. Target weights become m*w; extra mass D=sum((m-1)*w) is subtracted evenly from donor entries only when an exclusion callback exists. Donors require both target=false and exclusion=false. Donors clamp at0. Without an exclusion callback, donor selection is empty (30–35), so the total increases. For m<1, D<=0 and no subtraction occurs. Clamping can also make the total increase even in the Epic stage. This source does not maintain a universal 100 total.

The saved weighted sampler GetRandomWeightedItem14–25 draws against sum of weights. IF that sampler and this transformed pool govern an outcome, conditional probability is w/sum(w). No authoritative server hatch handler was accessed; a final server draw, variants, pity, rerolls, exclusions, or clamp policy cannot be certified by this helper.

Client.Gui.LootPoolViewer.fromEgg566–670 calls GetLuckMultiplier609 and then GetEggPool613 with separate Secret/Infinity inputs nil. Sparkletime is forced to luck1 (610–612). The viewer hides Secret entries in its pool wrapper496–529 and egg callback629–631, and renderPage424 formats Chance directly as a percentage. Its display therefore is incomplete evidence for final effective hatch odds. UI-hidden entries must not be removed from a denominator in a mathematical model unless the actual draw excludes them.

SOURCE_CONFIRMED example — Eggs492/494 defines Creaking Egg at5,000 Candycorn26 and 4x Luck Creaking Egg at10,000. Their weight sums are about99.0015200841 and99.00608025628. Under the narrow unbuffed normalized-weight model:

| Outcome | Premium/base catalog weight | Conditional useful probability per currency ratio |
|---|---:|---:|
| Shadow Phoenix / Shadow Squire | 4 | about2 |
| Unholy Bell | 3 | about1.5 |
| Balemoon Nevermare / Sinister Lord2.0 | 4 | about2 |
| VOID SINISTER LORD | 1 | about0.5 |
| Common/Rare entries | 1 | about0.5 |

This is a conditional calculation from saved definitions, not a live recommendation. The egg title does not make every outcome4x. If only the unchanged Void outcome improves the best owned team, the premium egg is worse per currency in this restricted model. Recompute with the complete useful-outcome set, actual transforms, variants, throughput, and availability.

## Native physical egg contract

SOURCE_CONFIRMED — StarterPlayer.StarterPlayerScripts.ClientScript requires the native network wrapper and LocalData (24–25). updateUnlocked395–451 checks catalog Island against AreasUnlocked, previously opened EggsOpened, or the native special Infinity/no-Island/no-World conditions; it writes a local Unlocked attribute. This client eligibility is not proof of server unlock acceptance.

The initial prompt is MaxActivationDistance6.5 (568), with account, affordability and CheckInventorySpace guards before FireServer("HatchEgg", eggName,1)616. The separate nearest-egg scanner869–885 requires alive/root/account, the global ProximityPrompt.Visible value equal0, a registered egg, 3D root-position distance<=16, and Unlocked=true; it picks the nearest. Read actual tagged scene Egg models and their attributes/positions. Static Island definitions locate an intended destination, but do not prove an egg is spawned there.

The .1-second client polling loop840–1066 is not a verified .1-second hatch cadence. It observes the character NextEggOpenAt attribute926–931, native max hatch capacity and inventory checks. Auto mode stops if the entire current batch is unaffordable (890–924); manual multi-hatch decrements the requested count until affordable (995–1002); one input path forces1. Catalog ProductId opens a product purchase path1007–1010 and is excluded from OC without owner Robux authorization. Ordinary final calls931/1025 use ("HatchEgg",name,count).

Cancellation includes no character/root, death or missing account1056–1063, changing nearest egg1054–1055, insufficient full-batch funds890–924, full inventory932–934, and eligibility/visibility changes through nearest scanning. These are native stop conditions to preserve under the central scheduler; this research starts no new loop. Client.Gui.Utils.CheckInventorySpace30–49 checks already-full storage, not whether every next batch result fits. Safe planning must conservatively account for multiplicities, possible variants/nonmergeable records, and Digital Storage bytes.

Inventory2941–2977 has a separate PowerupEgg auto task. It checks positive powerup quantity and inventory space, waits NextEggOpenAt, then FireServer("HatchPowerupEgg",name,min(12,owned))2974. Do not infer that this action shares ordinary world-egg price, location, luck or capacity semantics.

## Equip, team switch and shiny action interfaces

SOURCE_CONFIRMED — Inventory2121–2173 requires an existing account/team, selection, and native equip capacity; it resolves a selected display ID to the first36 characters2163 and calls FireServer("EquipPet",id)2164. UnequipPet2192 takes the same ID. EquipBestPets2900/5394 takes no objective argument, so its name does not establish that it optimizes the desired currency or farm method.

trySwitchToTeam2606–2637 requires the requested account team index to exist and sends EquipTeam(index). Keybind2658–2666 excludes multi-delete, trading, prompts, missing account and already-equipped team. UI suffix/selection changes are local feedback. Confirm Teams[TeamEquipped].Pets IDs after server/account data updates before treating an equip task as successful.

Inventory.stackWindow214–215 counts repeated IDs in the equipped team and244 subtracts that count from Amount or1. Repeated team IDs can represent multiple equipped units of a stack; deduplicating the entire team would undercount native stat contribution. PetUtil.GetTeamUpMultiplier84–88 deduplicates only its enchant fold, while StatsUtil's equipped helper98–112 retains each team entry. Preserve these different semantics. Server maximum available copies/split/result-ID acceptance still needs account delta verification.

SortPetsList40–47 exposes currency sort options, but compare122–124 prioritizes Void status before the currency stat125–140. Its GetStats128/134 omits account/team context. Infinity/Celestial/Secret and locked/rarity/power ordering provide later precedence. UI order is a display comparator, not a solved best team. GetPetRenderList10–116 allocates grid placeholders for larger visual entries and padding; visual cells are not inventory/equip counts.

Client.Gui.Frames.Shiny218–318 guards frame/selection/inflight state, account ownership and enough matching ingredients for requested craft count240. It listens MadePetShiny285–298 for the selected source ID, calls MakePetShiny(id,count)300, and releases its UI after .5seconds301–314. A timeout release is not craft success. The result preview189–193 is XP0 Shiny with the same Name/Mythic/XL/Super; preview does not certify actual server enchant/XP transfer. Multiple crafting uses floor(owned/required)341–359. Preserve protected ingredients even when the native CanUse predicate would allow them.

## Variants and timer boundaries

SOURCE_CONFIRMED — Constants41–53 defines base Shiny2.5%, Mythic1%, Super0.1%, XL multiplier2.5, max Supers3, and rarity-specific XL values. These constants are input definitions, not blanket outcome probabilities. ShinyChance754–1220 and MythicChance1222–1704 have index, specialized egg-potion/shrine, Super, special/global event, active buff and Infinity branches; no universal variant eligibility or independence was established.

XLEggUtil24–32 chooses two distinct eggs using Random.new(Time.getAbsoluteDay()) from Constants.XLEggs; IsActive43–55 also accepts Global XL, IsAdminEgg or AlwaysAllowXL. Next rotation uses Time.untilMidnight82. The Time dependency31/68–83 reads workspace:GetServerTimeNow(), computes floor(timestamp/86400) and the next epoch-aligned midnight boundary. This supports a UTC daily seed/rotation in the saved helper, not the owner's local calendar or a twelve-hour rotation. Which two eggs are actually active was not observed. GetChances66–72 divides rarity values by a factor and applies milestone XL only nested under player XL Event; this conflicts with an intuitive "increase odds" interpretation. Record the text, do not invert it into a guessed live rule.

GetInfinityEgg56–150 is dynamic: uses account InfinityEggIndex to select a nonremoved world's currency, then tagged eggs matching that currency, excluding Infinity Egg, IgnoreInfinityEgg, ProductId and noncurrency costs85–98. Base cost is max(1,floor(max eligible egg cost/2))133, reduced by equipped Infinity enchants110–124, rounded/clamped150. Snowflakes has separate constants135–137. It builds rarity weights60/20/13/6.5/.5/SecretRarity134 and combines eligible egg pools by rarity143–147, preserving duplicates. The cloned EggsOpened73 is discarded in this returned source; do not claim only previously opened eggs are included. Cache key uses the first three characters of egg names plus reduction125–132; collisions and live tag refresh are unverified limitations.

Infinity viewer771–845 uses the dynamic structure and normal luck on Legendary/Secret rarity weights. A two-stage rarity/pet estimator would require both normalized rarity weights and normalized within-rarity weights, plus an empty-rarity policy; server empty pools/selection were not inspected.

SuperUtil16–33 selects active-team records flagged Super. Counts every matching enchant90–109. Luck/Shiny/HatchSpeed/Bubble/Mythic/Infinity boosts111–192 sum count*(Base or Plus/100). Burst127–146 activates when a hatch batch crosses an absolute Hatches threshold100/75; its returned expression adds10/15 if at least one corresponding enchant exists, not count*10/15. DuplicationChance193–200 returns percentage units2.5/10 per matching enchant. Do not multiply these as final variant probabilities without a verified hatch consumer.

## Coverage and open questions

The economic core, pool transforms, normalized catalogs, native hatch/equip/shiny guards, eligibility/roll mathematics and main buff chains are inspected. Complete fetched modules and targeted/deep review are distinguished in ECONOMY_SOURCE_LEDGER.md. Specialized potion and shrine helpers called by StatsUtil are not all semantically audited by this file; see other category research and the ledger.

Still unknown: authoritative server hatch/variant draw order, pity and ceilings, final paid/powerup variant restrictions, hatch result/deletion/refund handling, Super eligibility, Digital Storage per-batch acceptance, exact server recipe result transfers and reroll locks/cost outcomes. Live success requires owner account/UI delta observations. No gameplay verification or economic action was performed.

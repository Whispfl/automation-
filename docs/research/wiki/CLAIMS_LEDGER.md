# Cross-referenced claim ledger

153 claim records extend the immutable [Stage 1 native library](../replicatedstorage/README.md). They preserve external statements, native comparisons and unresolved server/live boundaries. [Source index](SOURCE_INDEX.md) supplies exact access dates, versions and actual read scopes; each source ID below links to that record.

A corroborated definition or client caller does not certify hidden server validation, final hatch odds, successful requests, durable saves or current account availability. Derived calculations remain conditional on their stated assumptions. Multiple classifications can apply to one claim; the labels are not mutually exclusive.

| Classification | Meaning | Claims carrying label |
|---|---|---|
| `NATIVE_CORROBORATED` | A narrow statement agrees with inspected native definitions or client/shared behavior. | 71 |
| `OWNER_LIVE_CORROBORATED` | Relevant behavior/context was reported or confirmed by the owner; scope remains explicit. | 5 |
| `EXTERNAL_ONLY` | Externally stated; matching native or owner evidence is insufficient. | 21 |
| `CONTRADICTED_BY_NATIVE` | Inspected native evidence conflicts with the external wording or coefficient; runtime/version resolution may remain open. | 28 |
| `HISTORICAL_OR_REMOVED` | Evidence belongs to earlier content/version or explicitly removed content. | 10 |
| `VERSION_DEPENDENT` | Version, calendar, counting scope or current availability changes interpretation. | 51 |
| `UNKNOWN_SERVER_RULE` | Authoritative validation, sampling, update or grant behavior was unavailable. | 45 |
| `NEEDS_LIVE_VERIFICATION` | Owner-operated live evidence is required to settle the stated behavior or account result. | 50 |

Primary ledgers: [egg](evidence/EGG_CLAIMS.jsonl), [Mastery](evidence/MASTERY_CLAIMS.jsonl), [world](evidence/WORLD_CLAIMS.jsonl), [root](evidence/ROOT_CLAIMS.jsonl). The [normalized aggregate](evidence/ALL_CLAIMS.jsonl) merges primary and secondary labels into one array without overwriting the original workstream records. Claim IDs make changes and review findings traceable.

## Eggs, pets and probability

| Claim | Statement | Classifications |
|---|---|---|
| [E-C001](#e-c001) | Wiki uses direct ordinary-luck multiplication. | `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE` |
| [E-C002](#e-c002) | Wiki warns Debug Luck can misrepresent Index eligibility. | `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [E-C003](#e-c003) | Wiki applies Secret Luck to Secret and Infinity. | `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION` |
| [E-C004](#e-c004) | Wiki baseline Shiny1/40 and Mythic1/100. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [E-C005](#e-c005) | Wiki gives conflicting Shiny Seeker increments. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT` |
| [E-C006](#e-c006) | Wiki says Secret Elixir overrides Infinity's Mythic boost. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [E-C007](#e-c007) | Wiki base equip capacity4. | `NATIVE_CORROBORATED` |
| [E-C008](#e-c008) | Wiki Super Bubble Machine+ is200%; other listed paired stat coefficients match. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT` |
| [E-C009](#e-c009) | Wiki fragment increments Green3%, Blue0.75%, Purple/Rainbow0.08%. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [E-C010](#e-c010) | Wiki Golden Egg guarantees Shiny every75th hatch at Pets Mastery4. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [E-C011](#e-c011) | Wiki Pets Mastery unlocks Shiny and Mythic capabilities. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [E-C012](#e-c012) | Wiki lists pet equip and multi-hatch improvements by mastery tier. | `NATIVE_CORROBORATED`, `VERSION_DEPENDENT` |
| [E-C013](#e-c013) | Wiki level/variant totals contain a Mythic inconsistency. | `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [E-C014](#e-c014) | Wiki XL scaling is weaker than the saved coefficient. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT` |
| [E-C015](#e-c015) | Wiki Secret XL is 1/500. | `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE` |
| [E-C016](#e-c016) | Wiki XL eggs rotate daily at 00:00 UTC. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [E-C017](#e-c017) | Wiki XL eligibility list is narrower than the saved catalog. | `VERSION_DEPENDENT`, `HISTORICAL_OR_REMOVED` |
| [E-C018](#e-c018) | Wiki says low rarities are unaffected by Luck. | `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE` |
| [E-C019](#e-c019) | Wiki pet count differs from the saved definition count. | `VERSION_DEPENDENT` |
| [E-C020](#e-c020) | Wiki Team Up/Determination do not stack. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [E-C021](#e-c021) | Wiki distinguishes whole-pet Gem and single-slot Orb rolls. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [E-C022](#e-c022) | Wiki Special and Secret enchant prerequisites. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [E-C023](#e-c023) | Wiki Super enchants are permanent and cannot reroll. | `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION` |
| [E-C024](#e-c024) | Wiki rarity-based Gem roll costs. | `NATIVE_CORROBORATED`, `VERSION_DEPENDENT` |
| [E-C025](#e-c025) | Wiki ordinary level-V odds fit a biased-level model. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [E-C026](#e-c026) | Wiki Ultra Roller gives 25%. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT` |
| [E-C027](#e-c027) | Wiki Infinity Egg uses a two-stage rarity/pet draw. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [E-C028](#e-c028) | Wiki Infinity Egg costs half the highest unlocked egg. | `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE` |
| [E-C029](#e-c029) | Wiki Infinity Secret odds have competing attributions. | `NATIVE_CORROBORATED`, `EXTERNAL_ONLY`, `UNKNOWN_SERVER_RULE` |
| [E-C030](#e-c030) | Wiki Infinity Egg excludes Index bonuses. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [E-C031](#e-c031) | Wiki recommends Infinity Egg for nonspecific Mythics. | `EXTERNAL_ONLY`, `NEEDS_LIVE_VERIFICATION` |
| [E-C032](#e-c032) | Wiki inventory eggs usually exclude Luck. | `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE` |
| [E-C033](#e-c033) | Wiki Rift luck spans 5–25x. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [E-C034](#e-c034) | Wiki Eggs and Pets rarity lists differ over VOID. | `VERSION_DEPENDENT` |
| [E-C035](#e-c035) | Wiki Secret Bounty refreshes daily; published waves are historical. | `NATIVE_CORROBORATED`, `HISTORICAL_OR_REMOVED`, `NEEDS_LIVE_VERIFICATION` |
| [E-C036](#e-c036) | Wiki Secret Bounty also appears in Infinity Egg. | `EXTERNAL_ONLY`, `UNKNOWN_SERVER_RULE` |
| [E-C037](#e-c037) | Wiki lists eligible permanent bounty eggs. | `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [E-C038](#e-c038) | Wiki Infinity potion makes all buffs twice as effective. | `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE` |
| [E-C039](#e-c039) | Wiki Ultra Infinity factor is 1.5x. | `NATIVE_CORROBORATED`, `VERSION_DEPENDENT` |
| [E-C040](#e-c040) | Wiki Coins Infinity values conflict internally. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [E-C041](#e-c041) | Wiki Secret Elixir boosts Secret or Infinity. | `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION` |
| [E-C042](#e-c042) | Wiki Shiny Seeker duration table and trivia disagree. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT` |
| [E-C043](#e-c043) | Wiki Index completion gives context-specific Luck/Shiny/Mythic bonuses. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [E-C044](#e-c044) | Wiki traded pets do not count toward Index. | `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION` |
| [E-C045](#e-c045) | Wiki Mythic Index rewards: TierI5boxes; II2SpeedV+5boxes; III1SpeedEvolved+10boxes, doubled ShinyMythic. | `EXTERNAL_ONLY`, `UNKNOWN_SERVER_RULE` |
| [E-C046](#e-c046) | Wiki rare families inherit multiple luck categories. | `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION` |
| [E-C047](#e-c047) | Wiki Shiny broadly eligible; Mythic has exceptions. | `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION` |
| [E-C048](#e-c048) | Wiki rare-family Shiny recipe requires eight copies. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |

### E-C001

Wiki uses direct ordinary-luck multiplication.

Classification: `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S002](SOURCE_INDEX.md#e-s002) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.GetEggPool`, lines 24–126; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#luck-transforms-and-why-a-displayed-chance-is-not-final-odds).
- `ReplicatedStorage.Shared.Utils.ApplyMultiplierToPool`, lines 14–44; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#luck-transforms-and-why-a-displayed-chance-is-not-final-odds).
- `ReplicatedStorage.Shared.Framework.Utilities.Math.GetRandomWeightedItem`, lines 14–25; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#luck-transforms-and-why-a-displayed-chance-is-not-final-odds).

Reason: A universal exact final-probability formula is not supported: native has Epic cap4, target/donor stages and possibly changed total mass. Under a explicitly hypothetical normalized sampler, target weights must be divided by the transformed sum.

Limits: Wiki formula can approximate very small target mass under limited assumptions; no final hatch handler or final probability validation.

### E-C002

Wiki warns Debug Luck can misrepresent Index eligibility.

Classification: `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S002](SOURCE_INDEX.md#e-s002) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)).

Native comparison:

- `ReplicatedStorage.Client.Gui.LootPoolViewer`, lines 609–613; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#luck-transforms-and-why-a-displayed-chance-is-not-final-odds).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 1970–1978; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#ordinary-luck-arithmetic-and-specialization).

Reason: Stage1 shows context-dependent inputs and an incomplete viewer. The exact Debug implementation was not independently audited; generic caution is consistent, not a verified Debug-specific contract.

Limits: Display and world/egg-specific bonus must be compared with fresh owner evidence.

### E-C003

Wiki applies Secret Luck to Secret and Infinity.

Classification: `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S002](SOURCE_INDEX.md#e-s002) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.GetEggPool`, lines 73–109; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#luck-transforms-and-why-a-displayed-chance-is-not-final-odds).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 1706–1883; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#ordinary-luck-arithmetic-and-specialization).

Reason: Native receives separate Secret and Infinity factors; Secret stage targets Rarity Secret while Infinity stage uses ItemUtil:IsInfinityRarity. Some rare-family definitions are still Secret with flags. Exact overlapping classification/final server consumer cannot be inferred from the wiki label.

Limits: Do not equate all Infinity-family chance to GetSecretLuck or discard the separate GetInfinityLuck.

### E-C004

Wiki baseline Shiny1/40 and Mythic1/100.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S002](SOURCE_INDEX.md#e-s002) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 41–44; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 1219–1220,1703–1704; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#temporary-boosts-and-variants-as-an-investment).

Reason: Ordinary baseline constants2.5% and1% match. Paid-egg constants10% and4% are separate; eligibility, conditional dependence, ceilings and server draws remain unresolved.

Limits: Baseline inputs are not unconditional probabilities for every egg/pet/variant combination.

### E-C005

Wiki gives conflicting Shiny Seeker increments.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`.

External evidence: [E-S002](SOURCE_INDEX.md#e-s002) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)); [E-S005](SOURCE_INDEX.md#e-s005) ([Enchants](https://bgs-infinity.fandom.com/wiki/Enchants)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Enchants`, lines 23; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 1193–1202; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#temporary-boosts-and-variants-as-an-investment).

Reason: Root read body0.2% direct versus table1% stacks. Saved enchant buff2 is passed through additive Percent arithmetic before multiplying base ShinyChance. In a single-entry otherwise-fixed model this contributes0.05 percentage points, not either wiki wording.

Limits: Body/table inconsistency and native reconstruction require live comparison; no fixes or spending authorization.

### E-C006

Wiki says Secret Elixir overrides Infinity's Mythic boost.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S002](SOURCE_INDEX.md#e-s002) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)); [E-S006](SOURCE_INDEX.md#e-s006) ([Potions](https://bgs-infinity.fandom.com/wiki/Potions)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 1273,1686–1703; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#temporary-boosts-and-variants-as-an-investment).

Reason: Returned source doubles both Mythic factor and suppression divisor with Infinity; combined versus original unboosted gives0.2, while combined versus Infinity-only gives0.1. Wiki table0.2 alone omits the comparison baseline.

Limits: Exact multiplication ordering and actual active potion eligibility must be verified.

### E-C007

Wiki base equip capacity4.

Classification: `NATIVE_CORROBORATED`.

External evidence: [E-S002](SOURCE_INDEX.md#e-s002) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 46; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#team-and-inventory-facts).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 404–439; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#team-and-inventory-facts).

Reason: Native base is4 with additional account-dependent equip boosts and a separate Super cap.

Limits: Do not use4 as the actual received account capacity or omit stack counts.

### E-C008

Wiki Super Bubble Machine+ is200%; other listed paired stat coefficients match.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`.

External evidence: [E-S002](SOURCE_INDEX.md#e-s002) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.SuperUtil`, lines 11,118–200; [Stage 1 comparison](../replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md#supers-existing-complete-review-explicit-units-and-limits).

Reason: Saved Plus Bubble coefficient250 disagrees with wiki200. Native paired Luck100/200, Shiny10/15, Mythic10/15, Hatch75/100, Infinity7.5/15 agree at the coefficient level.

Limits: Agreement of coefficients does not establish final effect composition, Burst consumer or runtime cache behavior.

### E-C009

Wiki fragment increments Green3%, Blue0.75%, Purple/Rainbow0.08%.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S002](SOURCE_INDEX.md#e-s002) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.FragmentUtil`, lines 12–20,75; [Stage 1 comparison](../replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md#fragments-permanent-looking-counts-and-precise-placement).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 2388–2477; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#ordinary-luck-arithmetic-and-specialization).

Reason: Scalars match native but enter different accumulators; Green's returned B>1 threshold prevents assuming each recorded use multiplies final luck by1.03.

Limits: Server count/cap/reset and final probabilities remain unknown.

### E-C010

Wiki Golden Egg guarantees Shiny every75th hatch at Pets Mastery4.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S013](SOURCE_INDEX.md#e-s013) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 126,128; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md#selected-high-value-catalog-tiers).
- `ReplicatedStorage.Client.Gui.Frames.Buffs`, lines 164–200; [Stage 1 comparison](../replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md#exact-modules-and-review-depth).

Reason: Native catalog defines GoldenEgg Every75 and UI reads effective received MasteryUpgrades, computes75-(Hatches%75). This corroborates the counter/capability definition, not authoritative batch assignment or guaranteed variant server handler.

Limits: Every0 atPets2 is different from the active counter; all-hatch vs eligible egg counting, per-batch golden assignment and result remain unknown.

### E-C011

Wiki Pets Mastery unlocks Shiny and Mythic capabilities.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S013](SOURCE_INDEX.md#e-s013) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 126,130; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md#selected-high-value-catalog-tiers).
- `ReplicatedStorage.Shared.Utils.Stats.MasteryUtil`, lines 197–209; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md#mastery-schema-and-selection).

Reason: Saved definitions Pets2GoldenEggEvery0 andPets6DarkArts match capability catalog. Received upgrades are preferable to summing historical tier descriptions.

Limits: Exact egg/pet variant eligibility and server results not established by capability names.

### E-C012

Wiki lists pet equip and multi-hatch improvements by mastery tier.

Classification: `NATIVE_CORROBORATED`, `VERSION_DEPENDENT`.

External evidence: [E-S013](SOURCE_INDEX.md#e-s013) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 127,134–139; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md#selected-high-value-catalog-tiers).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 404–439,571–612; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#team-and-inventory-facts).

Reason: Catalog/effective first-matching upgrade paths support these capabilities. Some successive wiki descriptions say additional while native catalog stores replacement-typeValues1,2,3; count actual received upgrade value rather than sum every row.

Limits: GetUpgrades replacement fidelity ambiguity; actual capacity includes other received boosts, clamp and separate Super limit.

### E-C013

Wiki level/variant totals contain a Mythic inconsistency.

Classification: `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S003](SOURCE_INDEX.md#e-s003) ([Pets](https://bgs-infinity.fandom.com/wiki/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.Stats.PetUtil`, lines 126–129; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#pet-level-curve).
- `ReplicatedStorage.Shared.Utils.PetLevelUtil`, lines 27,29–55,70–90; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#pet-level-curve).

Reason: Wiki gives a 35% level-25 bonus; Mythic tab and level total do not agree arithmetically. Native has a +0.35 level term but Shiny/Mythic nesting anomalies. Linear bonus per level must not be confused with linear bonus per XP; native cumulative XP is quadratic and rounded.

Limits: Returned PetUtil cannot certify all runtime variant multipliers; native display/helper owner comparison required.

### E-C014

Wiki XL scaling is weaker than the saved coefficient.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`.

External evidence: [E-S003](SOURCE_INDEX.md#e-s003) ([Pets](https://bgs-infinity.fandom.com/wiki/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.Stats.PetUtil`, lines 126–129; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#pet-level-curve).
- `ReplicatedStorage.Shared.Constants`, lines 49–51; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).

Reason: Wiki XL +100%, level-25 +140% implies a base ×2 multiplier. Saved Constants50 and PetUtil127–129 instead use ×2.5. If the level term alone applies, normal level25 ×1.35 followed by XL ×2.5 would be ×3.375; this is a conditional expression, not a certified full variant stat.

Limits: Do not silently choose a wiki/runtime formula; variants and decompiler nesting need owner validation.

### E-C015

Wiki Secret XL is 1/500.

Classification: `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S003](SOURCE_INDEX.md#e-s003) ([Pets](https://bgs-infinity.fandom.com/wiki/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 49–51; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).
- `ReplicatedStorage.Shared.Utils.XLEggUtil`, lines 66–72; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).

Reason: Saved Secret threshold0.4 in a percent interpretation corresponds to 1/250, not 1/500. The rarity table is not the hatch sampler; returned GetChances divides thresholds by an event-derived factor.

Limits: Only coefficient/display-unit comparison is established, not final conditional XL odds.

### E-C016

Wiki XL eggs rotate daily at 00:00 UTC.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S003](SOURCE_INDEX.md#e-s003) ([Pets](https://bgs-infinity.fandom.com/wiki/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.XLEggUtil`, lines 24–32,43–55,75–82; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).
- `ReplicatedStorage.Shared.Framework.Utilities.Math.Time`, lines 31,68–83; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).

Reason: Native chooses two distinct configured eggs using the absolute server day and next UTC boundary. Global XL, IsAdminEgg and AlwaysAllowXL bypass rotation; actual current selections were not observed.

Limits: No actual live egg availability/rotation snapshot was collected.

### E-C017

Wiki XL eligibility list is narrower than the saved catalog.

Classification: `VERSION_DEPENDENT`, `HISTORICAL_OR_REMOVED`.

External evidence: [E-S003](SOURCE_INDEX.md#e-s003) ([Pets](https://bgs-infinity.fandom.com/wiki/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 49–51; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).

Reason: Saved Constants51 contains nine Halloween, Rift and other retained names; older listed release eggs do not form an exhaustive current eligibility set. Retained catalogs likewise do not prove today's active content.

Limits: Treat both lists as versioned definitions; require actual tagged egg and runtime account/scene eligibility.

### E-C018

Wiki says low rarities are unaffected by Luck.

Classification: `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S003](SOURCE_INDEX.md#e-s003) ([Pets](https://bgs-infinity.fandom.com/wiki/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.GetEggPool`, lines 24–126; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#luck-transforms-and-why-a-displayed-chance-is-not-final-odds).
- `ReplicatedStorage.Shared.Utils.ApplyMultiplierToPool`, lines 14–44; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#luck-transforms-and-why-a-displayed-chance-is-not-final-odds).

Reason: The statement is valid only if it means these rarities are not directly targeted for positive boosting. Native donor weights and transformed total can change their final normalized probability. Untargeted weight is not proof of unchanged final chance.

Limits: Final authoritative draw/denominator unknown.

### E-C019

Wiki pet count differs from the saved definition count.

Classification: `VERSION_DEPENDENT`.

External evidence: [E-S003](SOURCE_INDEX.md#e-s003) ([Pets](https://bgs-infinity.fandom.com/wiki/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Pets`, lines 11–2176; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#catalog-fact-extraction-checkpoint).

Reason: Wiki2069 versus native extracted2166 suggests version/count-scope differences. It does not establish missing pets: variants, removed entries and display exclusions may use different counting units.

Limits: No one-to-one wiki pet inventory comparison completed.

### E-C020

Wiki Team Up/Determination do not stack.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S005](SOURCE_INDEX.md#e-s005) ([Enchants](https://bgs-infinity.fandom.com/wiki/Enchants)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.Stats.PetUtil`, lines 61–102,148–152; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#start-from-the-best-feasible-owned-team).

Reason: Narrow same-record interpretation is supported: getTeamMultiplier uses the first qualifying enchant. Across distinct equipped records, the native fold adds qualifying values to a shared factor. The wording must not suppress legitimate cross-record team coupling.

Limits: Decompile/stat fidelity prevents certifying every runtime combined result.

### E-C021

Wiki distinguishes whole-pet Gem and single-slot Orb rolls.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S005](SOURCE_INDEX.md#e-s005) ([Enchants](https://bgs-infinity.fandom.com/wiki/Enchants)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.Enchants`, lines 980–1045,1583–1625; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).

Reason: Native sends RerollEnchant(id,slot) using one Orb or RerollEnchants(id,"Gems",lockedSlot) and may receive a new ID. Locked-slot preservation is material to costs and risks.

Limits: Dispatch/timeout is not success; final deduction and resulting IDs require account delta verification.

### E-C022

Wiki Special and Secret enchant prerequisites.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S005](SOURCE_INDEX.md#e-s005) ([Enchants](https://bgs-infinity.fandom.com/wiki/Enchants)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.EnchantUtil`, lines 201–248,282–307; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).

Reason: Native requires received Special mastery for Special IDs and Secret or tier≥3 Legendary; secret-only IDs additionally require Secret. Display family flags/tier and actual received capabilities must be joined, rather than infer eligibility from labels alone.

Limits: Saved GetPossibleEnchants ignores some computed eligibility, so UI odds cannot substitute for authoritative eligibility.

### E-C023

Wiki Super enchants are permanent and cannot reroll.

Classification: `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S005](SOURCE_INDEX.md#e-s005) ([Enchants](https://bgs-infinity.fandom.com/wiki/Enchants)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.EnchantUtil`, lines 75,201–248; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).
- `ReplicatedStorage.Client.Gui.Frames.Enchants`, lines 1777–1827; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).

Reason: Normal selection UI excludes Super pets, but generic IsEnchantable returns true in the saved source. That does not establish a server immutability rule. Super-only eligible pool branches also exist.

Limits: No reroll invoked; native UI exclusion is not proof that every possible interface is permanently forbidden.

### E-C024

Wiki rarity-based Gem roll costs.

Classification: `NATIVE_CORROBORATED`, `VERSION_DEPENDENT`.

External evidence: [E-S005](SOURCE_INDEX.md#e-s005) ([Enchants](https://bgs-infinity.fandom.com/wiki/Enchants)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 91; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).
- `ReplicatedStorage.Client.Gui.Frames.Enchants`, lines 162–177; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).

Reason: Actual table rowspans associate20K with both TierII/III and50K with Secret-family labels. Saved base costs agree for represented tiers; effective native discounts and locked slot behavior remain separate.

Limits: Root checked rowspans explicitly; no TierIII50K conflict exists. Cost table labels must be mapped to actual saved Rarity/Tier fields.

### E-C025

Wiki ordinary level-V odds fit a biased-level model.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S005](SOURCE_INDEX.md#e-s005) ([Enchants](https://bgs-infinity.fandom.com/wiki/Enchants)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Enchants`, lines 15–18; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).
- `ReplicatedStorage.Shared.Utils.EnchantUtil`, lines 321–335; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).

Reason: Under normal-only weights1,2.5,10,10 and independent uniform U, levelV probability1−0.8^(1/4) gives Looter/Bubbler≈2.309% and TeamUp≈1/433.1. This plausibly explains the wiki table, but eligibility, exclusions and adjusted sums can change it.

Limits: A mathematical fit is not observed server distribution; existing enchant IDs/two slots alter candidate sums.

### E-C026

Wiki Ultra Roller gives 25%.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`.

External evidence: [E-S005](SOURCE_INDEX.md#e-s005) ([Enchants](https://bgs-infinity.fandom.com/wiki/Enchants)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Enchants`, lines 22; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).

Reason: Saved coefficient is20 Percent. Which revision/runtime value applies requires native owner comparison; finite metadata and additive Percent composition are distinct from an unlimited final multiplier.

Limits: Community table does not prove active runtime coefficient.

### E-C027

Wiki Infinity Egg uses a two-stage rarity/pet draw.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S004](SOURCE_INDEX.md#e-s004) ([Infinity Egg](https://bgs-infinity.fandom.com/wiki/Infinity_Egg)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.GetInfinityEgg`, lines 56–150; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).
- `ReplicatedStorage.Client.Gui.LootPoolViewer`, lines 771–845; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).

Reason: Dynamic native structure has rarity weights and combined within-rarity pools. A compatible conditional estimator normalizes both stages, preserves repeated occurrences and must specify empty-rarity handling.

Limits: Final server draws, empty-rarity policy, duplicate treatment and authoritative transform order not inspected.

### E-C028

Wiki Infinity Egg costs half the highest unlocked egg.

Classification: `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S004](SOURCE_INDEX.md#e-s004) ([Infinity Egg](https://bgs-infinity.fandom.com/wiki/Infinity_Egg)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.GetInfinityEgg`, lines 73–98,125–150; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).

Reason: Saved source clones EggsOpened but discards it; visible selection filters tagged currency eggs in the selected world's currency and applies floor(maxCost/2), reductions then rounding. No opened/unlocked test is visible. Half-price currency mechanism is supported; the unlock qualifier is not.

Limits: Live tagged objects may themselves encode access indirectly; no authoritative unlocked-only contract proved.

### E-C029

Wiki Infinity Secret odds have competing attributions.

Classification: `NATIVE_CORROBORATED`, `EXTERNAL_ONLY`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S004](SOURCE_INDEX.md#e-s004) ([Infinity Egg](https://bgs-infinity.fandom.com/wiki/Infinity_Egg)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 48; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).
- `ReplicatedStorage.Shared.Utils.GetInfinityEgg`, lines 133–147; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).

Reason: Saved SecretRarity2.5e−6 percent-like weight matches the unboosted1/40M scale. The wiki's unlinked official1/50M attribution has no inspected primary source. Normalize the entire rarity table if hypothetically sampled; raw weight is not exact final odds.

Limits: No independently verified official developer statement or final sampling consumer.

### E-C030

Wiki Infinity Egg excludes Index bonuses.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S004](SOURCE_INDEX.md#e-s004) ([Infinity Egg](https://bgs-infinity.fandom.com/wiki/Infinity_Egg)).

Native comparison:

- `ReplicatedStorage.Client.Gui.LootPoolViewer`, lines 831–845; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 1970–1978,803–807,1270–1273; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#ordinary-luck-arithmetic-and-specialization).

Reason: Infinity viewer uses ordinary luck context"None", consistent with excluding a selected world's ordinary Index bonus from that display. This is narrower than establishing all Shiny/Mythic/server Index exclusions.

Limits: Variant and final server consumers unresolved; index completion is an account fact, not inferred.

### E-C031

Wiki recommends Infinity Egg for nonspecific Mythics.

Classification: `EXTERNAL_ONLY`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S004](SOURCE_INDEX.md#e-s004) ([Infinity Egg](https://bgs-infinity.fandom.com/wiki/Infinity_Egg)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.GetInfinityEgg`, lines 56–150; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 1222–1704; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#temporary-boosts-and-variants-as-an-investment).

Reason: Advice cannot become a universal economic ranking. Compare conditional useful-outcome mass against best feasible owned team, pool dilution, currency cost, variants, timers and measurable throughput. Targeting a specific pet differs from targeting any useful pet.

Limits: No owner account snapshot, verified server odds or actual cycle/earning rates to personalize recommendation.

### E-C032

Wiki inventory eggs usually exclude Luck.

Classification: `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S008](SOURCE_INDEX.md#e-s008) ([Eggs](https://bgs-infinity.fandom.com/wiki/Eggs)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Builders.EggBuilder`, lines 25,40–53,77–94,112–141; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#catalog-schemas).
- `ReplicatedStorage.Shared.Utils.GetEggPool`, lines 24–126; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#luck-transforms-and-why-a-displayed-chance-is-not-final-odds).

Reason: Usually is a qualified observation, not a blanket exception. Saved reward/product/powerup/admin eggs have differing costs/flags and native contracts. A category name alone does not establish the omitted or included luck inputs.

Limits: Final per-egg ordinary/Secret/variant/speed consumers require source or owner evidence.

### E-C033

Wiki Rift luck spans 5–25x.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S008](SOURCE_INDEX.md#e-s008) ([Eggs](https://bgs-infinity.fandom.com/wiki/Eggs)).

Native comparison:

- `ReplicatedStorage.Shared.Data.RiftSummonCosts`, lines 14–15; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md#batch-e-rift-definitions-costs-and-lifecycle).

Reason: Saved summon options contain5,10,15,20,25. Native options are not fresh spawned Rift attributes or proof of multiplying every rarity's final odds.

Limits: Rift lifetime, actual object, eligible egg and transform inputs required.

### E-C034

Wiki Eggs and Pets rarity lists differ over VOID.

Classification: `VERSION_DEPENDENT`.

External evidence: [E-S008](SOURCE_INDEX.md#e-s008) ([Eggs](https://bgs-infinity.fandom.com/wiki/Eggs)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Builders.PetBuilder`, lines 114–134; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#catalog-schemas).

Reason: Saved definitions use base Rarity plus overlapping Infinity/Celestial/Void flags. A UI/community rarity label must not be substituted for a disjoint native categorical distribution.

Limits: No complete cross-wiki taxonomy normalization completed.

### E-C035

Wiki Secret Bounty refreshes daily; published waves are historical.

Classification: `NATIVE_CORROBORATED`, `HISTORICAL_OR_REMOVED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S007](SOURCE_INDEX.md#e-s007) ([Secret Bounty](https://bgs-infinity.fandom.com/wiki/Secret_Bounty)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.Stats.SecretBountyUtil`, lines 16–17,83–134; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md#secret-versus-mythic-bounty).

Reason: Native daily seed/interval supports UTC rotation. Published latestJune26–July24 2026 wave cannot identify the target onOctober11. Saved Get selects a Halloween array, while historical arrays remain retained.

Limits: No current target observed; saved definitions do not establish live current event.

### E-C036

Wiki Secret Bounty also appears in Infinity Egg.

Classification: `EXTERNAL_ONLY`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S007](SOURCE_INDEX.md#e-s007) ([Secret Bounty](https://bgs-infinity.fandom.com/wiki/Secret_Bounty)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.Stats.SecretBountyUtil`, lines 16–17,83–134; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md#secret-versus-mythic-bounty).
- `ReplicatedStorage.Shared.Utils.GetInfinityEgg`, lines 56–150; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).

Reason: Saved bounty definitions/postprocessing and Infinity's combined pools make this plausible, but the complete authoritative target injection and Infinity draw consumer are unavailable. Catalog mutation is not proof of hatch inclusion.

Limits: Do not invent ClaimSecretBounty or a guaranteed target inclusion/weight.

### E-C037

Wiki lists eligible permanent bounty eggs.

Classification: `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S007](SOURCE_INDEX.md#e-s007) ([Secret Bounty](https://bgs-infinity.fandom.com/wiki/Secret_Bounty)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.Stats.SecretBountyUtil`, lines 74,94–128; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md#secret-versus-mythic-bounty).

Reason: Native seed candidates and supported Rift additions are dynamic; a published list is not an exhaustive scene list or unlock proof. Treat eligibility separately from navigation, active target and account result.

Limits: No direct live bounty board/egg comparison.

### E-C038

Wiki Infinity potion makes all buffs twice as effective.

Classification: `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S006](SOURCE_INDEX.md#e-s006) ([Potions](https://bgs-infinity.fandom.com/wiki/Potions)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Buffs`, lines 12; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#temporary-boosts-and-variants-as-an-investment).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 313–348,1686–1703,2388–2405,2451–2453; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#buff-arithmetic-matters).

Reason: Broad text also occurs in native description, but inspected consumers have separate additive/multiplicative branches and do not prove universal doubling of every final stat. A description is not the arithmetic contract.

Limits: Inspect a named stat's actual chain; no blanket2× assumption for ROI.

### E-C039

Wiki Ultra Infinity factor is 1.5x.

Classification: `NATIVE_CORROBORATED`, `VERSION_DEPENDENT`.

External evidence: [E-S006](SOURCE_INDEX.md#e-s006) ([Potions](https://bgs-infinity.fandom.com/wiki/Potions)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 195; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#ordinary-luck-arithmetic-and-specialization).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 1842–1864; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#ordinary-luck-arithmetic-and-specialization).
- `ReplicatedStorage.Shared.Data.Buffs`, lines 14; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#temporary-boosts-and-variants-as-an-investment).

Reason: Saved consumer applies×1.5 only within ULTRAINFEGGS membership, currently four Halloween names; Super additive term follows. It is not a1.5 multiplier of the entire final factor for every egg.

Limits: Buff active state, set membership and runtime version must be checked.

### E-C040

Wiki Coins Infinity values conflict internally.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S006](SOURCE_INDEX.md#e-s006) ([Potions](https://bgs-infinity.fandom.com/wiki/Potions)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Buffs`, lines 51–57; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#buff-arithmetic-matters).

Reason: Root identified article750 versus DailyShop625. Saved Coins level7 Buff.Value625 matches the latter coefficient; native Percent addition must still be evaluated in its named currency chain. Community agreement alone is not the arithmetic contract.

Limits: DailyShop body not independently reviewed by this child; do not treat shop label as verified formula.

### E-C041

Wiki Secret Elixir boosts Secret or Infinity.

Classification: `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S006](SOURCE_INDEX.md#e-s006) ([Potions](https://bgs-infinity.fandom.com/wiki/Potions)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Buffs`, lines 13,147; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#temporary-boosts-and-variants-as-an-investment).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 1779,1819–1883; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#temporary-boosts-and-variants-as-an-investment).

Reason: Native description agrees, and GetSecretLuck has the2× branch; inspected GetInfinityLuck has no corresponding Secret branch. Final shared-pool targeting may partly overlap family flags, so neither universal Infinity2× nor zero Infinity impact is established.

Limits: Resolve the actual hatch consumer and family classification before valuing the Infinity benefit.

### E-C042

Wiki Shiny Seeker duration table and trivia disagree.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`.

External evidence: [E-S005](SOURCE_INDEX.md#e-s005) ([Enchants](https://bgs-infinity.fandom.com/wiki/Enchants)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Enchants`, lines 22–24; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).
- `ReplicatedStorage.Shared.Utils.EnchantUtil`, lines 77–96; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#enchant-eligibility-actions-and-diminishing-returns).

Reason: Saved ordinary Metadata1.5M matches trivia rather than older1.25M table; Celestial3M and Infinity6M are selected by actual pet family flags. Remaining Extra is an account fact, not the original maximum duration.

Limits: Use depletion counter/eligible-use semantics unavailable; do not price as a permanent bonus.

### E-C043

Wiki Index completion gives context-specific Luck/Shiny/Mythic bonuses.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S009](SOURCE_INDEX.md#e-s009) ([Index](https://bgs-infinity.fandom.com/wiki/Index)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 66; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#ordinary-luck-arithmetic-and-specialization).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 803–807,1270–1272,1970–1972; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md#ordinary-luck-arithmetic-and-specialization).
- `ReplicatedStorage.Client.Gui.LootPoolViewer`, lines 831–845; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).

Reason: Saved consumers use IndexBuffs for normal completion Luck/Shiny and Shiny completion Mythic, with world inputs and a Christmas exception for the former two. Infinity viewer uses contextNone. The wiki's listed-egg restriction and all final variant exclusions remain a narrower unresolved contract.

Limits: Exact eligible world/egg sets, record completion and server probability consumers require verification.

### E-C044

Wiki traded pets do not count toward Index.

Classification: `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S009](SOURCE_INDEX.md#e-s009) ([Index](https://bgs-infinity.fandom.com/wiki/Index)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.IndexUtil`, lines 13–75,102–104; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md#index).

Reason: Native completion reads discovered history rather than owned pet inventory. This supports the ownership/discovery distinction but does not prove the unseen trade/hatch update rules that add discovered keys.

Limits: No trades performed and no server discovery update handler inspected.

### E-C045

Wiki Mythic Index rewards: TierI5boxes; II2SpeedV+5boxes; III1SpeedEvolved+10boxes, doubled ShinyMythic.

Classification: `EXTERNAL_ONLY`, `UNKNOWN_SERVER_RULE`.

External evidence: [E-S009](SOURCE_INDEX.md#e-s009) ([Index](https://bgs-infinity.fandom.com/wiki/Index)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.Index`, lines 875–879,2351; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md#index).

Reason: Forwarded visible article distinguishes TierI/II/III bundles and doubled ShinyMythic rewards. Native shows a mode-sensitive ClaimIndex contract and Mythic descriptor, not a verified full reward catalog for those exact bundles.

Limits: No complete world/event tab audit; server claim trigger, grant and duplicates unavailable.

### E-C046

Wiki rare families inherit multiple luck categories.

Classification: `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S003](SOURCE_INDEX.md#e-s003) ([Pets](https://bgs-infinity.fandom.com/wiki/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.GetEggPool`, lines 55–126; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#luck-transforms-and-why-a-displayed-chance-is-not-final-odds).
- `ReplicatedStorage.Shared.Data.Builders.PetBuilder`, lines 114–134; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#catalog-schemas).

Reason: Native ordinary then Secret then Infinity stages use distinct predicates. The Season Celestial stage tests Pets[name].Celestial~=nil exactly, not Celestial==true and not a general advertised CelestialLuck input. The wiki family inheritance cannot substitute for these actual fields/predicates.

Limits: ItemUtil:IsInfinityRarity and family field defaults were not independently reread in Stage2; no universal Void/Celestial overlap formula proved.

### E-C047

Wiki Shiny broadly eligible; Mythic has exceptions.

Classification: `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S003](SOURCE_INDEX.md#e-s003) ([Pets](https://bgs-infinity.fandom.com/wiki/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 41–44; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#variants-and-timer-boundaries).
- `ReplicatedStorage.Shared.Data.Mastery`, lines 126,130; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md#selected-high-value-catalog-tiers).
- `ReplicatedStorage.Shared.Utils.Stats.PetUtil`, lines 40; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#evidence-and-source-quality).

Reason: Mastery capabilities and baseline constants do not establish all final variant/pet/egg eligibility. Native GetChance's nested saved representation cannot certify all conditional draws.

Limits: Do not multiply all baseline variant constants onto every rarity.

### E-C048

Wiki rare-family Shiny recipe requires eight copies.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [E-S003](SOURCE_INDEX.md#e-s003) ([Pets](https://bgs-infinity.fandom.com/wiki/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 54–55; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#shiny-crafting-economics-and-protections).
- `ReplicatedStorage.Shared.Utils.ShinyUtil`, lines 11–47; [Stage 1 comparison](../replicatedstorage/EGGS_AND_PETS.md#shiny-crafting-economics-and-protections).

Reason: Native bases count on catalog Rarity: Secret8, with XL8 override. Celestial/Infinity family flags commonly overlap Secret definitions; map the actual base Rarity, not a community label. Matching Name/Mythic/XL/Super and quantities/protection remain required.

Limits: Actual server recipe/result transfer unavailable; no craft invoked.

## Mastery, rewards and shops

| Claim | Statement | Classifications |
|---|---|---|
| [M-C001](#m-c001) | Eight branches have115declared tiers:25/23/11/8/4/14/15/15. | `NATIVE_CORROBORATED` |
| [M-C002](#m-c002) | Older cached data body lists20Buffs/15Pets/10Shops. | `VERSION_DEPENDENT` |
| [M-C003](#m-c003) | Pets3 wiki75,500 Coins conflicts with native85,000. | `CONTRADICTED_BY_NATIVE` |
| [M-C004](#m-c004) | Buffs6/14 wiki shorthand1.2m does not preserve native exact1,250,000. | `VERSION_DEPENDENT` |
| [M-C005](#m-c005) | Buffs16 article2keys differs from native MultiChest Amount5. | `CONTRADICTED_BY_NATIVE` |
| [M-C006](#m-c006) | Older Pets storage50/150/325 differs from native150/300/500; modern body agrees with native. | `NATIVE_CORROBORATED`, `HISTORICAL_OR_REMOVED` |
| [M-C007](#m-c007) | Modern/native MultiPotion description says10 but native client bulk-use cap is250. | `NEEDS_LIVE_VERIFICATION` |
| [M-C008](#m-c008) | Pets15 additional-one wording can be consistent with a replacement MultiEgg Value2 after tier10 Value1. | `NEEDS_LIVE_VERIFICATION` |
| [M-C009](#m-c009) | Seasonal44tiers remain hidden by ShouldShow=false. | `HISTORICAL_OR_REMOVED` |
| [M-C010](#m-c010) | Buffs complete nominal tier-cost register and effect fields. | `NATIVE_CORROBORATED` |
| [M-C011](#m-c011) | Pets complete nominal tier-cost register and effect fields. | `NATIVE_CORROBORATED` |
| [M-C012](#m-c012) | Shops complete nominal tier-cost register and effect fields. | `NATIVE_CORROBORATED` |
| [M-C013](#m-c013) | Minigames complete nominal tier-cost register and effect fields. | `NATIVE_CORROBORATED` |
| [M-C014](#m-c014) | Rifts complete nominal tier-cost register and effect fields. | `NATIVE_CORROBORATED` |
| [M-C015](#m-c015) | Christmas complete nominal tier-cost register and effect fields. | `NATIVE_CORROBORATED` |
| [M-C016](#m-c016) | Easter complete nominal tier-cost register and effect fields. | `NATIVE_CORROBORATED` |
| [M-C017](#m-c017) | Summer complete nominal tier-cost register and effect fields. | `NATIVE_CORROBORATED` |
| [M-C018](#m-c018) | Shop restock improvements use a divisor, not direct subtraction of advertised percent. | `NATIVE_CORROBORATED` |
| [M-C019](#m-c019) | All unowned prerequisites must enter the target package cost by currency. | `NATIVE_CORROBORATED` |
| [M-C020](#m-c020) | Wiki seven-day gifts differ from full native catalog names/quantities. | `CONTRADICTED_BY_NATIVE` |
| [M-C021](#m-c021) | Daily Stars shop common24offers' price groups agree with native. | `NATIVE_CORROBORATED` |
| [M-C022](#m-c022) | Native StarsShop has28entries including four fragments absent in24-item wiki shop. | `VERSION_DEPENDENT`, `NATIVE_CORROBORATED` |
| [M-C023](#m-c023) | UTCday status and10*streak Stars capped200 are source-supported. | `NATIVE_CORROBORATED` |
| [M-C024](#m-c024) | Wiki claims missing login within24hours of last login resets streak and59Robuxrestores it. | `EXTERNAL_ONLY` |
| [M-C025](#m-c025) | Nine Playtime gifts have native2/3/4/5/7.5/15/30/60/90minute thresholds and luck1/1/1/1/5/5/5/20/20. | `NATIVE_CORROBORATED` |
| [M-C026](#m-c026) | Playtime advertised pool chance and gift luck do not establish final server draw odds. | `UNKNOWN_SERVER_RULE` |
| [M-C027](#m-c027) | World Rewards Overworld tier2wikiGoldenKeys2 conflicts with native5. | `CONTRADICTED_BY_NATIVE` |
| [M-C028](#m-c028) | Both permanent World Rewards tracks have30prices derived from minimum100m and total2T; rounded sum2,000,000,000,600. | `NATIVE_CORROBORATED` |
| [M-C029](#m-c029) | All60native World Rewards item summaries saved:OverworldCoins/Cerberus;MinigameTickets/SecuritySystem. | `NATIVE_CORROBORATED` |
| [M-C030](#m-c030) | Wheel eight literal Chance values sum99, matching actual wiki labels. | `NATIVE_CORROBORATED` |
| [M-C031](#m-c031) | Wheel expectedCoins181.818 and returnedtickets.146465 apply only if literal99totalweights normalize. | `UNKNOWN_SERVER_RULE` |
| [M-C032](#m-c032) | Free wheel ticket claim, ticket-consuming Invoke and queue settlement are distinct. | `NATIVE_CORROBORATED` |
| [M-C033](#m-c033) | In a conditional first-world saving model, firstWorldReward delays goal if actual creditedCoins<100m price and no separate package benefit. | `NATIVE_CORROBORATED` |
| [M-C034](#m-c034) | WorldReward base data needs possible account/server scaling before certifying debit-versus-credit dominance. | `UNKNOWN_SERVER_RULE` |
| [M-C035](#m-c035) | Four Overworld wiki vendor base refresh intervals corroborate saved native6h/20min/8h/8h. | `NATIVE_CORROBORATED` |
| [M-C036](#m-c036) | Native current shop offers require actual Period/Bought/upgrades; catalog item count is not current stock. | `NATIVE_CORROBORATED` |
| [M-C037](#m-c037) | BuyAll boolean cannot express a protected arbitrary desired quantity; free reroll can erase useful offers. | `NATIVE_CORROBORATED` |
| [M-C038](#m-c038) | Genie3offers/choose1/20Orbs/2–3tasks match native, while actualNext/Seed/filters govern. | `NATIVE_CORROBORATED` |
| [M-C039](#m-c039) | Literal Genie task/reward-count means are2.4tasks and1.9additionalpicks, conditional on normalized catalogcountweights. | `NATIVE_CORROBORATED` |
| [M-C040](#m-c040) | Four complete native milestone categories have64threshold records normalized. | `NATIVE_CORROBORATED` |
| [M-C041](#m-c041) | Native Hatching200m/Genie2500/Shops20000OmegaIII exceed published milestone comparisons. | `VERSION_DEPENDENT`, `NATIVE_CORROBORATED` |
| [M-C042](#m-c042) | Wiki PlaytimeOmegaII92days/Currency175 differs from native4mseconds/Currency275; nativeOmegaIII7m/Currency300 exists. | `CONTRADICTED_BY_NATIVE` |
| [M-C043](#m-c043) | Milestone numeric buffs are latest percategory rather than cumulative over every tier. | `NATIVE_CORROBORATED` |
| [M-C044](#m-c044) | Wiki says traded pets do not add Index discovery credit; the server update rule remains externally stated. | `EXTERNAL_ONLY` |
| [M-C045](#m-c045) | Indexclaimed map/array and argument mode differences prevent generic claim-by-petcount. | `NATIVE_CORROBORATED` |
| [M-C046](#m-c046) | Native GetInfinityChest dynamically combines included rendered/unlocked chest rewards/rolls/maxcooldown; LootPoolViewer actually calls it. | `NATIVE_CORROBORATED` |
| [M-C047](#m-c047) | WikiInfinity34minutes cannot be judged by bare600second nativebase; actual composite/perks/deadline matter. | `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [M-C048](#m-c048) | Wiki noLuckeffect on chestloot is not certified serverRNG rule. | `UNKNOWN_SERVER_RULE` |
| [M-C049](#m-c049) | DedicatedChallenge_Pass article body unavailable; nativeautumnFinishOct2isexpired for researchdate. | `HISTORICAL_OR_REMOVED` |
| [M-C050](#m-c050) | Quests LikeGamecard200vsprose500likes is an external inconsistency, not a usable contract. | `EXTERNAL_ONLY` |
| [M-C051](#m-c051) | BubblePassarticle/enddate belongs to a separate season schema, not ChallengePass/eventactivity. | `VERSION_DEPENDENT` |
| [M-C052](#m-c052) | Marginal package ROI uses all unowned prerequisites, best-owned team, attributable rates, setup/background time and separate currencies. | `NEEDS_LIVE_VERIFICATION` |
| [M-C053](#m-c053) | Index50Percent native inputs attach normal completion to Luck/Shiny and Shiny completion to Mythic in inspected context-specific consumers. | `NATIVE_CORROBORATED` |

### M-C001

Eight branches have115declared tiers:25/23/11/8/4/14/15/15.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 78–276; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Complete native catalog reread; modern all-tab article body independently lists same counts.

Limits: Catalog counts do not prove live visibility, availability, approval or server acceptance.

### M-C002

Older cached data body lists20Buffs/15Pets/10Shops.

Classification: `VERSION_DEPENDENT`.

External evidence: [M-S002](SOURCE_INDEX.md#m-s002) ([Wiki Data/Mastery](https://bgs-infinity.fandom.com/wiki/Bubble_Gum_Simulator_INFINITY_Wiki:Data/Mastery)); [M-S003](SOURCE_INDEX.md#m-s003) ([Wiki Data/Mastery/Pets](https://bgs-infinity.fandom.com/wiki/Bubble_Gum_Simulator_INFINITY_Wiki:Data/Mastery/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 78–276; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Older directly read cached article is incomplete relative to native and modern body.

Limits: Crawl age is not a revision date; no archive timestamp identified.

### M-C003

Pets3 wiki75,500 Coins conflicts with native85,000.

Classification: `CONTRADICTED_BY_NATIVE`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)); [M-S003](SOURCE_INDEX.md#m-s003) ([Wiki Data/Mastery/Pets](https://bgs-infinity.fandom.com/wiki/Bubble_Gum_Simulator_INFINITY_Wiki:Data/Mastery/Pets)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 127; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Both modern parent-body and direct historical body report75.5k; native exact Amount85000.

Limits: Saved version precedence; no claim of current server price.

### M-C004

Buffs6/14 wiki shorthand1.2m does not preserve native exact1,250,000.

Classification: `VERSION_DEPENDENT`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)); [M-S002](SOURCE_INDEX.md#m-s002) ([Wiki Data/Mastery](https://bgs-infinity.fandom.com/wiki/Bubble_Gum_Simulator_INFINITY_Wiki:Data/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 87,95; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Rounding/precision ambiguity retained rather than repaired.

Limits: Shorthand may be presentation approximation, not necessarily a different rule.

### M-C005

Buffs16 article2keys differs from native MultiChest Amount5.

Classification: `CONTRADICTED_BY_NATIVE`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)); [M-S002](SOURCE_INDEX.md#m-s002) ([Wiki Data/Mastery](https://bgs-infinity.fandom.com/wiki/Bubble_Gum_Simulator_INFINITY_Wiki:Data/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 97; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Native capacity field is5; both bodies report2.

Limits: Client capacity definition does not verify server use count or reward odds.

### M-C006

Older Pets storage50/150/325 differs from native150/300/500; modern body agrees with native.

Classification: `NATIVE_CORROBORATED`, `HISTORICAL_OR_REMOVED`.

External evidence: [M-S002](SOURCE_INDEX.md#m-s002) ([Wiki Data/Mastery](https://bgs-infinity.fandom.com/wiki/Bubble_Gum_Simulator_INFINITY_Wiki:Data/Mastery)); [M-S003](SOURCE_INDEX.md#m-s003) ([Wiki Data/Mastery/Pets](https://bgs-infinity.fandom.com/wiki/Bubble_Gum_Simulator_INFINITY_Wiki:Data/Mastery/Pets)); [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 132,135,138; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Modern body matches exact current saved fields; historical bodies retained separately.

Limits: Effective replacement semantics still rely on received upgrades.

### M-C007

Modern/native MultiPotion description says10 but native client bulk-use cap is250.

Classification: `NEEDS_LIVE_VERIFICATION`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 50,95; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).
- `ReplicatedStorage.Shared.Constants`, lines 99; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).
- `ReplicatedStorage.Shared.Data.Builders.PromptBuilder`, lines 201–224,526–553; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).

Reason: Native call-site cap250 takes precedence over description for documented client range.

Limits: Server maximum and final timer stacking are unavailable.

### M-C008

Pets15 additional-one wording can be consistent with a replacement MultiEgg Value2 after tier10 Value1.

Classification: `NEEDS_LIVE_VERIFICATION`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 112,139; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).
- `ReplicatedStorage.Shared.Utils.Stats.MasteryUtil`, lines 45–79,197–209; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Do not sum1+2 or declare contradiction solely from marginal wording.

Limits: Reconstructed replacement helper has stored-Level anomaly; received effective value needed.

### M-C009

Seasonal44tiers remain hidden by ShouldShow=false.

Classification: `HISTORICAL_OR_REMOVED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 197–203,222–228,248–254; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Native returned predicates explicitlyfalse; modern table existence alone is catalog evidence.

Limits: No authoritative live event activity or future reactivation inferred.

### M-C010

Buffs complete nominal tier-cost register and effect fields.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 82–106; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: All native prices independently read and normalized; external comparison excludes explicitly conflicting amounts.

Limits: No free entitlements assumed; no current account/affordability/effective buff/server grants.

### M-C011

Pets complete nominal tier-cost register and effect fields.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 110–147; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: All native prices independently read and normalized; external comparison excludes explicitly conflicting amounts.

Limits: No free entitlements assumed; no current account/affordability/effective buff/server grants.

### M-C012

Shops complete nominal tier-cost register and effect fields.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 154–164; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: All native prices independently read and normalized; external comparison excludes explicitly conflicting amounts.

Limits: No free entitlements assumed; no current account/affordability/effective buff/server grants.

### M-C013

Minigames complete nominal tier-cost register and effect fields.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 169–184; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: All native prices independently read and normalized; external comparison excludes explicitly conflicting amounts.

Limits: No free entitlements assumed; no current account/affordability/effective buff/server grants.

### M-C014

Rifts complete nominal tier-cost register and effect fields.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 190–193; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: All native prices independently read and normalized; external comparison excludes explicitly conflicting amounts.

Limits: No free entitlements assumed; no current account/affordability/effective buff/server grants.

### M-C015

Christmas complete nominal tier-cost register and effect fields.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 204–218; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: All native prices independently read and normalized; external comparison excludes explicitly conflicting amounts.

Limits: No free entitlements assumed; no current account/affordability/effective buff/server grants.

### M-C016

Easter complete nominal tier-cost register and effect fields.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 229–244; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: All native prices independently read and normalized; external comparison excludes explicitly conflicting amounts.

Limits: No free entitlements assumed; no current account/affordability/effective buff/server grants.

### M-C017

Summer complete nominal tier-cost register and effect fields.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 255–270; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: All native prices independently read and normalized; external comparison excludes explicitly conflicting amounts.

Limits: No free entitlements assumed; no current account/affordability/effective buff/server grants.

### M-C018

Shop restock improvements use a divisor, not direct subtraction of advertised percent.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.ShopUtil`, lines 224–242; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).

Reason: Native round(base/(masteryScalar+milestoneCooldown)) governs estimate.

Limits: Cooldown start and actual received Period/account state determine next availability.

### M-C019

All unowned prerequisites must enter the target package cost by currency.

Classification: `NATIVE_CORROBORATED`.

External evidence: .

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 78–276; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).
- `ReplicatedStorage.Client.Gui.Frames.Mastery`, lines 539–568,602; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Sequential next-tier client action plus exact prices supports arithmetic package derivation.

Limits: Server discounts/entitlements cannot be assumed; analysis grants no spending permission.

### M-C020

Wiki seven-day gifts differ from full native catalog names/quantities.

Classification: `CONTRADICTED_BY_NATIVE`.

External evidence: [M-S017](SOURCE_INDEX.md#m-s017) ([Daily Rewards](https://bgs-infinity.fandom.com/wiki/Daily_Rewards)).

Native comparison:

- `ReplicatedStorage.Shared.Data.DailyRewards`, lines 8–14; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: ArticleDay1StPatricksI1 vs nativeUltraInfinity1; day2Infinity1vs10; days3–6onevs3; day7threeeachvs10each.

Limits: Unknown exact revision/current server grants; native saved catalog precedence.

### M-C021

Daily Stars shop common24offers' price groups agree with native.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S017](SOURCE_INDEX.md#m-s017) ([Daily Rewards](https://bgs-infinity.fandom.com/wiki/Daily_Rewards)).

Native comparison:

- `ReplicatedStorage.Shared.Data.StarsShop`, lines 8–31.

Reason: Full native gap read and actual article shop table show10/30/100/500/750Star potion tiers and key/orb/box prices.

Limits: Offer utility/timing/server acceptance not established; article missing additional4nativeentries.

### M-C022

Native StarsShop has28entries including four fragments absent in24-item wiki shop.

Classification: `VERSION_DEPENDENT`, `NATIVE_CORROBORATED`.

External evidence: [M-S017](SOURCE_INDEX.md#m-s017) ([Daily Rewards](https://bgs-infinity.fandom.com/wiki/Daily_Rewards)).

Native comparison:

- `ReplicatedStorage.Shared.Data.StarsShop`, lines 32–35.

Reason: Green2000,Blue2500,Purple2500,Rainbow3500 appear in saved native catalog.

Limits: Catalog presence is not currently available stock; current use/caps/complete-set value need account facts.

### M-C023

UTCday status and10*streak Stars capped200 are source-supported.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S017](SOURCE_INDEX.md#m-s017) ([Daily Rewards](https://bgs-infinity.fandom.com/wiki/Daily_Rewards)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.DailyRewards`, lines 411–473; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).
- `ReplicatedStorage.Shared.Constants`, lines 88–89; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Article body agrees with native day/star UI and constants.

Limits: Server missed-login rollover/recovery exact window unknown.

### M-C024

Wiki claims missing login within24hours of last login resets streak and59Robuxrestores it.

Classification: `EXTERNAL_ONLY`.

External evidence: [M-S017](SOURCE_INDEX.md#m-s017) ([Daily Rewards](https://bgs-infinity.fandom.com/wiki/Daily_Rewards)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.DailyRewards`, lines 411–473,530; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Actual article states this; native client day calculations do not verify authoritative eligibility/recovery.

Limits: Do not execute forfeits or paid restores; timezone-boundary/window ambiguity unresolved.

### M-C025

Nine Playtime gifts have native2/3/4/5/7.5/15/30/60/90minute thresholds and luck1/1/1/1/5/5/5/20/20.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S006](SOURCE_INDEX.md#m-s006) ([Playtime](https://bgs-infinity.fandom.com/wiki/Playtime)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Playtime`, lines 37–40; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Actual parent browser article agrees with saved native definitions.

Limits: Actual Start/Claimed/TradingPlaza/current session state controls availability.

### M-C026

Playtime advertised pool chance and gift luck do not establish final server draw odds.

Classification: `UNKNOWN_SERVER_RULE`.

External evidence: [M-S006](SOURCE_INDEX.md#m-s006) ([Playtime](https://bgs-infinity.fandom.com/wiki/Playtime)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.Playtime`, lines 183–186,223–240,261–264,323; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Client transforms display pool/currency and presents probabilities; authoritative server drawing unavailable.

Limits: Search/body/UI probability labels may be version dependent; no RNG execution or grant observation.

### M-C027

World Rewards Overworld tier2wikiGoldenKeys2 conflicts with native5.

Classification: `CONTRADICTED_BY_NATIVE`.

External evidence: [M-S012](SOURCE_INDEX.md#m-s012) ([World Rewards](https://bgs-infinity.fandom.com/wiki/World_Rewards)).

Native comparison:

- `ReplicatedStorage.Shared.Data.WorldRewards`, lines 14; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Actual Overworld tab comparison with exact savednativequantity.

Limits: Other tabs not inspected yet; no authoritative server grant inferred.

### M-C028

Both permanent World Rewards tracks have30prices derived from minimum100m and total2T; rounded sum2,000,000,000,600.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S012](SOURCE_INDEX.md#m-s012) ([World Rewards](https://bgs-infinity.fandom.com/wiki/World_Rewards)).

Native comparison:

- `ReplicatedStorage.Shared.Data.WorldRewards`, lines 11–70; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).
- `ReplicatedStorage.Shared.Data.Builders.WorldRewardsBuilder`, lines 54–79; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Exact rational arithmetic on native parameters produces all30prices; articleOverworldbroadshorthand corroborates schedule.

Limits: Derived math is not executed native/server pricing; otherwiki tabs not yetread.

### M-C029

All60native World Rewards item summaries saved:OverworldCoins/Cerberus;MinigameTickets/SecuritySystem.

Classification: `NATIVE_CORROBORATED`.

External evidence: .

Native comparison:

- `ReplicatedStorage.Shared.Data.WorldRewards`, lines 11–70; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Full native1–74reread; values normalized without executingbuilder.

Limits: Reward usefulness versus bestowned team and server receipt remainunknown.

### M-C030

Wheel eight literal Chance values sum99, matching actual wiki labels.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S018](SOURCE_INDEX.md#m-s018) ([Wheel Spin](https://bgs-infinity.fandom.com/wiki/Wheel_Spin)).

Native comparison:

- `ReplicatedStorage.Shared.Data.WheelSpin`, lines 8–15; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Full catalog read and full article pool agree on45/20/14/10/4/3/2.9/.1.

Limits: Percent-looking labels are not automatically normalized probabilities; missing1weight unexplained.

### M-C031

Wheel expectedCoins181.818 and returnedtickets.146465 apply only if literal99totalweights normalize.

Classification: `UNKNOWN_SERVER_RULE`.

External evidence: [M-S018](SOURCE_INDEX.md#m-s018) ([Wheel Spin](https://bgs-infinity.fandom.com/wiki/Wheel_Spin)).

Native comparison:

- `ReplicatedStorage.Shared.Data.WheelSpin`, lines 8–15; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Conditional expected-value derivation, not certified final probability.

Limits: No authoritative RNG/grants; other utility/cost/time not monetized.

### M-C032

Free wheel ticket claim, ticket-consuming Invoke and queue settlement are distinct.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S018](SOURCE_INDEX.md#m-s018) ([Wheel Spin](https://bgs-infinity.fandom.com/wiki/Wheel_Spin)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.WheelSpin`, lines 106,266,358–375,400–412,595–609; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Action paths/deadline/queue reviewed inStage1; articleMini3convenience consistent.

Limits: No requests sent; deadline/actionreceipt/servercooldownunknown.

### M-C033

In a conditional first-world saving model, firstWorldReward delays goal if actual creditedCoins<100m price and no separate package benefit.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S012](SOURCE_INDEX.md#m-s012) ([World Rewards](https://bgs-infinity.fandom.com/wiki/World_Rewards)).

Native comparison:

- `ReplicatedStorage.Shared.Data.WorldRewards`, lines 11–12; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).
- `ReplicatedStorage.Shared.Data.Worlds`, lines 81–152; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).

Reason: Native base reward100Coins and price100m support possible negative return; authoritative reward scaling may differ. Compare actual supported credit, not unscaled catalog label.

Limits: Actual server credit/scaling and delayed package benefit unavailable; no owner account recommendation. Worldgoal1bCoins is native definition.

### M-C034

WorldReward base data needs possible account/server scaling before certifying debit-versus-credit dominance.

Classification: `UNKNOWN_SERVER_RULE`.

External evidence: [M-S012](SOURCE_INDEX.md#m-s012) ([World Rewards](https://bgs-infinity.fandom.com/wiki/World_Rewards)).

Native comparison:

- `ReplicatedStorage.Shared.Data.WorldRewards`, lines 11–12; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Catalog100Coins is baseamount; actual reward transform/credit unavailable.

Limits: Freshaccount strategy remains explicitly conditional; receipt must verify cost+credited amount.

### M-C035

Four Overworld wiki vendor base refresh intervals corroborate saved native6h/20min/8h/8h.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S007](SOURCE_INDEX.md#m-s007) ([Shops](https://bgs-infinity.fandom.com/wiki/Shops)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Shops`, lines 14–103,148–182; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).

Reason: Actual articleOverworldtable versus native catalog.

Limits: Otherworld/eventtabs notfullread; actualPeriod/deadline/stock/demand differ.

### M-C036

Native current shop offers require actual Period/Bought/upgrades; catalog item count is not current stock.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S007](SOURCE_INDEX.md#m-s007) ([Shops](https://bgs-infinity.fandom.com/wiki/Shops)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.ShopUtil`, lines 74–106,108–223; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).
- `ReplicatedStorage.Client.Gui.Frames.ItemShop`, lines 280–327; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).

Reason: Reviewed deterministic construction and received purchase subtraction.

Limits: Stock220two-baseline fidelity issue; noaccountidentity/personal values recorded.

### M-C037

BuyAll boolean cannot express a protected arbitrary desired quantity; free reroll can erase useful offers.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S007](SOURCE_INDEX.md#m-s007) ([Shops](https://bgs-infinity.fandom.com/wiki/Shops)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.ItemShop`, lines 226–239,365–373,409–417,590; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).

Reason: Single/all/refresh actualcall shapes and displayallocation reviewed.

Limits: Server accepts no customquantity contract proven; receipts/reconciliation required.

### M-C038

Genie3offers/choose1/20Orbs/2–3tasks match native, while actualNext/Seed/filters govern.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S008](SOURCE_INDEX.md#m-s008) ([Gem Genie](https://bgs-infinity.fandom.com/wiki/Gem_Genie)); [M-S021](SOURCE_INDEX.md#m-s021) ([Quests](https://bgs-infinity.fandom.com/wiki/Quests)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.GemGenie`, lines 214–245,349,412,469,539–602; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).
- `ReplicatedStorage.Shared.Constants`, lines 17,19–20; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).

Reason: Fullbody agreements with native interface/constants.

Limits: Articlebasehour/taskexamples are not actual accountoffer; authoritative cooldownrule unknown.

### M-C039

Literal Genie task/reward-count means are2.4tasks and1.9additionalpicks, conditional on normalized catalogcountweights.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S008](SOURCE_INDEX.md#m-s008) ([Gem Genie](https://bgs-infinity.fandom.com/wiki/Gem_Genie)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Quests.GenieQuest`, lines 17–18,61–119; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).

Reason: Arithmetic on defined choices; not a final rewardprobability or offer ranking.

Limits: Seed-generated currentoffers and useful objectiveeffort must be evaluated separately.

### M-C040

Four complete native milestone categories have64threshold records normalized.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S016](SOURCE_INDEX.md#m-s016) ([Milestones](https://bgs-infinity.fandom.com/wiki/Milestones)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Milestones`, lines 86–179,218–301,420–496; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Fresh targetedfullbranch gapreads:16Hatching/13Genie/15Shops/20Playtime.

Limits: Other12wiki categoryrows onlytop2/fullBubbling; notwholemilestoneaudit; servercounter/grants unavailable.

### M-C041

Native Hatching200m/Genie2500/Shops20000OmegaIII exceed published milestone comparisons.

Classification: `VERSION_DEPENDENT`, `NATIVE_CORROBORATED`.

External evidence: [M-S016](SOURCE_INDEX.md#m-s016) ([Milestones](https://bgs-infinity.fandom.com/wiki/Milestones)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Milestones`, lines 147–149,178,491–493; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Exact new native branches compared with rootpublished top2scopes.

Limits: Article incomplete versus native; currentlivecompletion and rewards notinferred.

### M-C042

Wiki PlaytimeOmegaII92days/Currency175 differs from native4mseconds/Currency275; nativeOmegaIII7m/Currency300 exists.

Classification: `CONTRADICTED_BY_NATIVE`.

External evidence: [M-S016](SOURCE_INDEX.md#m-s016) ([Milestones](https://bgs-infinity.fandom.com/wiki/Milestones)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Milestones`, lines 284–298; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).
- `ReplicatedStorage.Shared.Data.Builders.QuestTaskBuilder`, lines 29–38; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).
- `ReplicatedStorage.Shared.Utils.Stats.QuestUtil`, lines 37–52,149–150; [Stage 1 comparison](../replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md).

Reason: Native taskAmount/real-time formatting and scalar reviewed; wiki apparent regression notnativepolicy.

Limits: Server counting/timegrant still unverified; exact article revisionunknown.

### M-C043

Milestone numeric buffs are latest percategory rather than cumulative over every tier.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S016](SOURCE_INDEX.md#m-s016) ([Milestones](https://bgs-infinity.fandom.com/wiki/Milestones)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.MilestoneUtil`, lines 125–174; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Native aggregation preserves specialflags but latestnumericbuffs.

Limits: Taskgrant/currentcategory state required; descriptorPercent downstreamformula differs.

### M-C044

Wiki says traded pets do not add Index discovery credit; the server update rule remains externally stated.

Classification: `EXTERNAL_ONLY`.

External evidence: [M-S019](SOURCE_INDEX.md#m-s019) ([Index](https://bgs-infinity.fandom.com/wiki/Index)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.IndexUtil`, lines 13–45,47–75,97–139; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Actual article body read; history helper establishes discovery distinct from ownership but does not prove trade/hatch update rules. Numeric buff inputs are separately reconciled in M-C053.

Limits: Counter34 damaged; unseen server discovery-update binding unresolved; no trade actions.

### M-C045

Indexclaimed map/array and argument mode differences prevent generic claim-by-petcount.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S019](SOURCE_INDEX.md#m-s019) ([Index](https://bgs-infinity.fandom.com/wiki/Index)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.Index`, lines 391,534,740–742,875–883,2351; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).
- `ReplicatedStorage.Client.Gui.Frames.Index.XLIndex`, lines 262–296,322–346; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Stage1actualnativeactions/claimedcontainers retained.

Limits: Reconstructedcompletionguard/callback anomalies; actual grants/servereligibility unavailable.

### M-C046

Native GetInfinityChest dynamically combines included rendered/unlocked chest rewards/rolls/maxcooldown; LootPoolViewer actually calls it.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S014](SOURCE_INDEX.md#m-s014) ([Chests](https://bgs-infinity.fandom.com/wiki/Chests)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.GetInfinityChest`, lines 1–69.
- `ReplicatedStorage.Client.Gui.LootPoolViewer`, lines 947–1023.

Reason: New fullhelper69lines+targetedactualconsumer980–982 read.

Limits: Display/composite formula not finalserverdraw/grant; namescountcanincludeuncatalogednames.

### M-C047

WikiInfinity34minutes cannot be judged by bare600second nativebase; actual composite/perks/deadline matter.

Classification: `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [M-S014](SOURCE_INDEX.md#m-s014) ([Chests](https://bgs-infinity.fandom.com/wiki/Chests)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Chests`, lines 56; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).
- `ReplicatedStorage.Shared.Utils.GetInfinityChest`, lines 22–49,64.

Reason: Base and dynamiccomposite differ; actualsource maxsupports state-dependenttiming.

Limits: Noauthoritative34minuteconstant established; freshCooldowns/liveverification needed.

### M-C048

Wiki noLuckeffect on chestloot is not certified serverRNG rule.

Classification: `UNKNOWN_SERVER_RULE`.

External evidence: [M-S014](SOURCE_INDEX.md#m-s014) ([Chests](https://bgs-infinity.fandom.com/wiki/Chests)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Chests`, lines 1–57; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Actualarticle assertion retained; no authoritative chest sampler available.

Limits: Native catalog/display alone cannot prove final modifierindependence.

### M-C049

DedicatedChallenge_Pass article body unavailable; nativeautumnFinishOct2isexpired for researchdate.

Classification: `HISTORICAL_OR_REMOVED`.

External evidence: [M-S020](SOURCE_INDEX.md#m-s020) ([Challenge Pass (requested path; title unverified)](https://bgs-infinity.fandom.com/wiki/Challenge_Pass)).

Native comparison:

- `ReplicatedStorage.Shared.Data.ChallengePass`, lines 11–27,43–67; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: NativeIsActive source/date; noexternalarticlebody facts inferred.

Limits: Live replacement track/serverclaim/reset ruleunknown; ownerHalloween notreactivationproof.

### M-C050

Quests LikeGamecard200vsprose500likes is an external inconsistency, not a usable contract.

Classification: `EXTERNAL_ONLY`.

External evidence: [M-S021](SOURCE_INDEX.md#m-s021) ([Quests](https://bgs-infinity.fandom.com/wiki/Quests)).

Native comparison:

- No source-path corroboration claimed; see the scoped external/native comparison and limits.

Reason: Actualarticlebody internally disagrees.

Limits: No social action authorized/proposed; native/server rule unknown.

### M-C051

BubblePassarticle/enddate belongs to a separate season schema, not ChallengePass/eventactivity.

Classification: `VERSION_DEPENDENT`.

External evidence: [M-S022](SOURCE_INDEX.md#m-s022) ([Bubble Pass](https://bgs-infinity.fandom.com/wiki/Bubble_Pass)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Seasons`, lines 1517–1518; [Stage 1 comparison](../replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md).

Reason: Root fullbody reports rollingSeasonAutumn/Oct15; nativeSeason25/event calendars differ and remain separate.

Limits: No wikiLastUpdated/currentarticledate proves live pass availability; root owns fullerpass sourceledger.

### M-C052

Marginal package ROI uses all unowned prerequisites, best-owned team, attributable rates, setup/background time and separate currencies.

Classification: `NEEDS_LIVE_VERIFICATION`.

External evidence: [M-S005](SOURCE_INDEX.md#m-s005) ([Mastery](https://bgs-infinity.fandom.com/wiki/Mastery)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 197–245,471–612; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md).
- `ReplicatedStorage.Shared.Data.Mastery`, lines 78–193; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Conditional analyticalmodels saved inMasteryROI; syntheticexample notaccountmeasurement.

Limits: No finalodds/rates/accountvalues/reserveoverride; phaseapproval remainsseparate.

### M-C053

Index50Percent native inputs attach normal completion to Luck/Shiny and Shiny completion to Mythic in inspected context-specific consumers.

Classification: `NATIVE_CORROBORATED`.

External evidence: [M-S019](SOURCE_INDEX.md#m-s019) ([Index](https://bgs-infinity.fandom.com/wiki/Index)).

Native comparison:

- `ReplicatedStorage.Shared.Constants`, lines 66; [Stage 1 comparison](../replicatedstorage/ECONOMY_SOURCE_LEDGER.md).
- `ReplicatedStorage.Shared.Utils.Stats.StatsUtil`, lines 803–807,1270–1272,1970–1972; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md).

Reason: Final cross-ledger QA joins economy source evidence and E-C043 to resolve the earlier numeric input gap; Christmas exception applies to normal Luck/Shiny expressions. These native reads belong to the economy research coverage, not additional complete source reads by this agent.

Limits: 50Percent is an input to a factor, not50percentage points of final probability. Exact eligible egg/world scope, Infinity final variant exclusion and authoritative server consumer remain unresolved; trade credit is M-C044.

Cross-ledger references: ["E-C043"].

## Worlds, seasonal opportunities and activities

| Claim | Statement | Classifications |
|---|---|---|
| [W-C001](#w-c001) | The nine public rod base-attribute records match the nine saved native FishingRods records; ownership, prices and current acquisition remain separate. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [W-C002](#w-c002) | Wiki bait labels match native catch-speed/crate/Legendary/mutation effect values. A +10% mutation label is an effect value, not verified +10 percentage points of catch odds. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [W-C003](#w-c003) | Wiki Stats captions list maximum Obby cooldown reduction75%/time increase75% and minigame cooldown reduction90%/additional drops17; treat these as external progression leads. | `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [W-C004](#w-c004) | The current developer Roblox description says Halloween is active, corroborating the owner's Halloween report; retained Fall/Autumn catalogs or Notion Fall2026 are not current-season evidence. | `OWNER_LIVE_CORROBORATED`, `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [W-C005](#w-c005) | The Worlds article's three permanent worlds match the saved Worlds catalog. Its approximate Overworld/Minigame island heights generally track saved scene heights or contact centers, rather than exact catalog Height fields. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [W-C006](#w-c006) | The Worlds article's limited-event index is historical/version-dependent and cannot establish October2026 availability: it lists earlier2025/2026 updates but omits Fall26/Halloween26 despite the current official Halloween description. | `VERSION_DEPENDENT`, `OWNER_LIVE_CORROBORATED` |
| [W-C007](#w-c007) | Worlds wiki Rift percentages remain external spawn/distribution statements, not verified final server or account-specific odds. | `UNKNOWN_SERVER_RULE`, `EXTERNAL_ONLY`, `VERSION_DEPENDENT` |
| [W-C008](#w-c008) | Wiki Secret Bounty daily00:00UTC rotation agrees with saved daily interval and epoch/server-time seed. Its InfinityEgg eligibility statement is a planning lead requiring current native/result eligibility. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [W-C009](#w-c009) | Secret Bounty's latest displayed wave through July24,2026 is historical evidence, not the October11 current target list; saved native targets are Halloween-themed. | `VERSION_DEPENDENT`, `HISTORICAL_OR_REMOVED`, `NEEDS_LIVE_VERIFICATION` |
| [W-C010](#w-c010) | Wiki selling conversions agree with the four saved station multipliers: Overworldsurface2/Twilight5Coins per bubble and MinigameParadisesurface0.1/RobotFactory0.2Tickets per bubble. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [W-C011](#w-c011) | MinigameParadise article confirms Zen and1BCoins for normal access; its old10Bcost is explicitly historical, changedMay25,2025. | `NATIVE_CORROBORATED`, `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE` |
| [W-C012](#w-c012) | SevenSeas wiki2.5BCoins matches native price, but its Zen access statement differs from the saved normal physical gate on HyperwaveIsland in MinigameParadise. | `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION` |
| [W-C013](#w-c013) | Zen's public Gem15=10% and Comet=.002% statements differ from conditional probabilities obtained by normalizing saved Zenweights30 and.0002 over100.0002. | `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE`, `VERSION_DEPENDENT` |
| [W-C014](#w-c014) | TheShadowRealm wiki describes a permanent2026hub with50KGems entry, distinct from the separately named2025ShadowRealm event; hubavailability/entrycontract remain externally sourced. | `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`, `HISTORICAL_OR_REMOVED` |
| [W-C015](#w-c015) | Rifts article's summoned≤30minute limit conflicts with native45/60minute choices and anotherwiki summon-option table that includes those choices. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE` |
| [W-C016](#w-c016) | BubbleShrine wiki12h/1000itemcap and42.3sec increment disagree with saved durationhelper's24h/500itemcap and171sec-per-item increase from15min baseline. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE` |
| [W-C017](#w-c017) | Fishingoverview level50at10mXP and9rods/6baits agree with saved catalogs; ordinary cratepercentage table omits nativeClassiccrate and does not match normalized rawweights. | `CONTRADICTED_BY_NATIVE`, `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`, `VERSION_DEPENDENT` |
| [W-C018](#w-c018) | PetMatch wiki entry5kTickets,base5mincooldown and1SuperTicket cooldownreset match saved catalog/client skipdefinitions. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [W-C019](#w-c019) | PetMatch Medium12cards means six pairs in nativeconfig; wiki's fourpairs is internally inconsistent and contradicted bynative. | `CONTRADICTED_BY_NATIVE` |
| [W-C020](#w-c020) | RobotClaw wiki30mincooldown differs from saved native20min;2.5mTicketprice/60secbasetime/1SuperTicketskip agree. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE` |
| [W-C021](#w-c021) | PetMatch andRobotClaw loot labels corroborate native reward families/rawvalues but cannot be read as complete finalpercentages or self-funding play. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [W-C022](#w-c022) | Board wiki weighted6/10/1dicewindows agree with sharedhelper; GoldenDice is nextnode in thathelper, not an arbitrarychosen destination. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [W-C023](#w-c023) | Boardwiki87tiles differs from88savedphysicalnumericnodes; this is a counting/version discrepancy, without proof everyphysicalnode equals one wiki gameplaytile. | `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [W-C024](#w-c024) | Boardarticle trivia suggests concurrenthatching afterwalkingaway; this is an externalplayer tip, not a verified OCcoordination/actioncontract. | `EXTERNAL_ONLY`, `NEEDS_LIVE_VERIFICATION` |
| [W-C025](#w-c025) | Obbysarticle matches threeClassicIslandactivities with baseEasy/Medium/Hardcooldowns3/5/10minutes; fishingaccess and coursecompletion remain separate. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [W-C026](#w-c026) | FishDex's seven20-fish tables and all seven islandcompletionrewardsets agree with nativeFishingAreas; multiple listed rewards belong to one completionclaim, nottiers. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [W-C027](#w-c027) | FishingRods article names OldSailorquests andFishDex as acquisitionroutes; no savedrodprice implies all rods can be purchased from fishing-shop catalog. | `NATIVE_CORROBORATED`, `EXTERNAL_ONLY`, `NEEDS_LIVE_VERIFICATION` |
| [W-C028](#w-c028) | CartEscape wiki200kTickets/15minbasecooldown/1SuperTicketskip agree with native;fourprogressivedifficultiesdo notprove everyadvertisedbonusdrop. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [W-C029](#w-c029) | HyperDarts wiki15mincooldown conflicts with saved native20min;5mTickets/1SuperTicketskip matchnative. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE` |
| [W-C030](#w-c030) | OldSailor article describes random objectives after the initial chain and bonuses at5quests (1Infinity+1PurpleFragment),10 (1Secret),25 (3Infinity),50 (10Secret),250 (Cthulhu) and500 (AbyssalSeaDragon); external pending native quest comparison. | `EXTERNAL_ONLY`, `NEEDS_LIVE_VERIFICATION` |
| [W-C031](#w-c031) | Fish article's conditionalmutationweights/value/XP agree with saved FishMutations; its base5% correspondshelperconstant, not certified finalcatch mutationodds. | `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE` |
| [W-C032](#w-c032) | Events article's NO ACTIVE EVENTS statement conflicts with currentdeveloper Halloween description andownerreport, despite havingan Autumn2026 row endingOctober10. | `VERSION_DEPENDENT`, `OWNER_LIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [W-C033](#w-c033) | Autumn2026 article explicitly marksSeptember26–October10event removed, whileAutumn2025article marksSeptember26–October17,2025removed. Neitheris a currentHalloween guide. | `HISTORICAL_OR_REMOVED`, `VERSION_DEPENDENT` |
| [W-C034](#w-c034) | Autumn2026 main period starts September26 while HarvestEgg subsection starts September20; the differing scope may reflect Part1 versus Update74Part2, and placeholder pool text limits detailed odds evidence. | `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [W-C035](#w-c035) | Autumn event removal and Autumn BubblePass deadline are distinct public calendar statements; neither supplies current Halloween expiry. | `VERSION_DEPENDENT`, `EXTERNAL_ONLY`, `NEEDS_LIVE_VERIFICATION` |
| [W-C036](#w-c036) | Visible wiki Changelog latest October3 Update75 predates official October11 Halloween description; missing newer entries are a coverage gap, not evidence Halloween is absent. | `VERSION_DEPENDENT`, `OWNER_LIVE_CORROBORATED` |

### W-C001

The nine public rod base-attribute records match the nine saved native FishingRods records; ownership, prices and current acquisition remain separate.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S011](SOURCE_INDEX.md#w-s011) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)).

Native comparison:

- `ReplicatedStorage.Shared.Data.FishingRods`, lines 11–19; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Root reviewed actual wiki Stats body/tables; native catalog independently supplies same numerical fields.

Limits: Published/revised timestamps unavailable. Saved data does not prove current rod ownership/acquisition or fishing server result.

### W-C002

Wiki bait labels match native catch-speed/crate/Legendary/mutation effect values. A +10% mutation label is an effect value, not verified +10 percentage points of catch odds.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S011](SOURCE_INDEX.md#w-s011) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)).

Native comparison:

- `ReplicatedStorage.Shared.Data.FishingBait`, lines 22–27; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Shared.Utils.Stats.BuffUtil`, lines 330–343; [Stage 1 comparison](../replicatedstorage/ECONOMY_AND_ROI.md).
- `ReplicatedStorage.Shared.Utils.FishingUtil`, lines 538–596; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Shared effect values match wiki tables; final RollFish modifier branches have reconstruction limits.

Limits: No proven final catch odds, consumption, supply economics or server sampler.

### W-C003

Wiki Stats captions list maximum Obby cooldown reduction75%/time increase75% and minigame cooldown reduction90%/additional drops17; treat these as external progression leads.

Classification: `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S011](SOURCE_INDEX.md#w-s011) ([Stats](https://bgs-infinity.fandom.com/wiki/Stats)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Obbys`, lines 12–90; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Shared.Data.Minigames`, lines 12–75; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Actual wiki table captions read by root. These base catalog references do not independently establish player-modified caps.

Limits: Caption is not account eligibility, applied final multiplier or certified cooldown/drop output; native milestone consumer would be required.

### W-C004

The current developer Roblox description says Halloween is active, corroborating the owner's Halloween report; retained Fall/Autumn catalogs or Notion Fall2026 are not current-season evidence.

Classification: `OWNER_LIVE_CORROBORATED`, `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S012](SOURCE_INDEX.md#w-s012) ([[🎃] Bubble Gum Simulator INFINITY](https://www.roblox.com/games/85896571713843/Bubble-Gum-Simulator-INFINITY)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Events`, lines 163–164,214–230; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).
- `ReplicatedStorage.Shared.Data.Halloween26Upgrades`, lines 11–14; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).
- `ReplicatedStorage.Shared.Utils.HalloweenRebirthUtil`, lines 12; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).

Reason: Owner report and current developer public description agree; saved Halloween26 client schema independently supports the feature family. Both Active flags remain insufficient alone.

Limits: Public title/description does not prove account unlocks, inventory, event end date, spawned interaction range, server acceptance or Studio PlaceId.

### W-C005

The Worlds article's three permanent worlds match the saved Worlds catalog. Its approximate Overworld/Minigame island heights generally track saved scene heights or contact centers, rather than exact catalog Height fields.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S002](SOURCE_INDEX.md#w-s002) ([Worlds](https://bgs-infinity.fandom.com/wiki/Worlds)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Worlds`, lines 81–152; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).
- `Workspace.Worlds.The Overworld.Islands`, lines saved inspect_instance observations, not script lines; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).
- `Workspace.Worlds.Minigame Paradise.Islands`, lines saved inspect_instance observations, not script lines; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).

Reason: The Overworld/MinigameParadise/SevenSeas same three permanent non-Removed definitions. Approximate wiki heights410/2640/6845/10125/15955 and2860/7625/13355/20030 align more closely with saved geometry than definition thresholds.

Limits: Public height labels and saved scene are not minimum bubble requirements, safe routes, current account discoveries or accepted server travel.

### W-C006

The Worlds article's limited-event index is historical/version-dependent and cannot establish October2026 availability: it lists earlier2025/2026 updates but omits Fall26/Halloween26 despite the current official Halloween description.

Classification: `VERSION_DEPENDENT`, `OWNER_LIVE_CORROBORATED`.

External evidence: [W-S002](SOURCE_INDEX.md#w-s002) ([Worlds](https://bgs-infinity.fandom.com/wiki/Worlds)); [W-S012](SOURCE_INDEX.md#w-s012) ([[🎃] Bubble Gum Simulator INFINITY](https://www.roblox.com/games/85896571713843/Bubble-Gum-Simulator-INFINITY)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Events`, lines 163–164,214–230; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).

Reason: Historical limited world rows include Halloween2025Update25–28, Christmas25Update32–37, Spring26Update45–46, StPatrick46–48, Easter48–51, Tropical54–59, FireIce59–61 and Carnival61. Developer current page supplies stronger current-season evidence.

Limits: Missing wiki row does not prove an event absent; old update numbers do not supply this event's end date or this account's access.

### W-C007

Worlds wiki Rift percentages remain external spawn/distribution statements, not verified final server or account-specific odds.

Classification: `UNKNOWN_SERVER_RULE`, `EXTERNAL_ONLY`, `VERSION_DEPENDENT`.

External evidence: [W-S002](SOURCE_INDEX.md#w-s002) ([Worlds](https://bgs-infinity.fandom.com/wiki/Worlds)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Rifts`, lines 11–125; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).

Reason: Actual wiki body lists Egg15%,Gift10%,Golden100%,Royal1/100,Super1/500,Gum1/200; raw native Weight fields and generated mappings do not expose the authoritative complete spawn sampler/eligibility.

Limits: No independent/conditional denominator, attempt cadence, eligible area sampling, live boost transform or current final probability verified. Values must not drive certified ETA/expected payout.

### W-C008

Wiki Secret Bounty daily00:00UTC rotation agrees with saved daily interval and epoch/server-time seed. Its InfinityEgg eligibility statement is a planning lead requiring current native/result eligibility.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S013](SOURCE_INDEX.md#w-s013) ([Secret Bounty](https://bgs-infinity.fandom.com/wiki/Secret_Bounty)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.Stats.SecretBountyUtil`, lines 16,74–112,114–128; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).
- `ReplicatedStorage.Shared.Framework.Utilities.Math.Time`, lines 31,65–83; [Stage 1 comparison](../replicatedstorage/SPECIALTY_SOURCE_LEDGER.md).

Reason: Daily boundary corroborates the helper clock. Public page says bounty can also hatch from InfinityEgg, but target insertion/final odds/actual hatching eligibility are distinct.

Limits: No account-specific daily target, accepted hatch outcome, final odds, reward entitlement or InfinityEgg currentavailability established.

### W-C009

Secret Bounty's latest displayed wave through July24,2026 is historical evidence, not the October11 current target list; saved native targets are Halloween-themed.

Classification: `VERSION_DEPENDENT`, `HISTORICAL_OR_REMOVED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S013](SOURCE_INDEX.md#w-s013) ([Secret Bounty](https://bgs-infinity.fandom.com/wiki/Secret_Bounty)); [W-S012](SOURCE_INDEX.md#w-s012) ([[🎃] Bubble Gum Simulator INFINITY](https://www.roblox.com/games/85896571713843/Bubble-Gum-Simulator-INFINITY)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.Stats.SecretBountyUtil`, lines 17–73,94–112; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).

Reason: Wiki latest wave endsmonths before current research; retained historical arrays and current client-selected Halloween array differ byversion.

Limits: Do not choose a target from the latest wiki row. Actual daily account/clientdisplay andfresh relevantobjects needed.

### W-C010

Wiki selling conversions agree with the four saved station multipliers: Overworldsurface2/Twilight5Coins per bubble and MinigameParadisesurface0.1/RobotFactory0.2Tickets per bubble.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S003](SOURCE_INDEX.md#w-s003) ([The Overworld](https://bgs-infinity.fandom.com/wiki/The_Overworld)); [W-S004](SOURCE_INDEX.md#w-s004) ([Minigame Paradise](https://bgs-infinity.fandom.com/wiki/Minigame_Paradise)).

Native comparison:

- `Workspace.Worlds.The Overworld`, lines saved sell-model attributes; not script lines; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).
- `Workspace.Worlds.Minigame Paradise`, lines saved sell-model attributes; not script lines; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).
- `ReplicatedStorage.Client.Activation`, lines 334–384; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).

Reason: Public ratios match physical saved attributes; SellBubble no station argument means actual location remains significant.

Limits: Matching baseratios do not establish petbuffcomposition, credited payout or profit over full fill/travel/sell/return cycle.

### W-C011

MinigameParadise article confirms Zen and1BCoins for normal access; its old10Bcost is explicitly historical, changedMay25,2025.

Classification: `NATIVE_CORROBORATED`, `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S004](SOURCE_INDEX.md#w-s004) ([Minigame Paradise](https://bgs-infinity.fandom.com/wiki/Minigame_Paradise)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Worlds`, lines 81–152; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).
- `StarterPlayer.StarterPlayerScripts.ClientScript`, lines 2088–2326; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).
- `Workspace.Worlds.The Overworld.Islands.Zen.Island.Decoration.Gate`, lines saved World attribute and Activation.Root observation; not script lines; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).

Reason: Price/current normal gate agree with saved data andscene; historicalcost explains stale guides.

Limits: Nativeclientgate/affordability are not independentserver validation, accountunlock orpersistentpurchase receipt.

### W-C012

SevenSeas wiki2.5BCoins matches native price, but its Zen access statement differs from the saved normal physical gate on HyperwaveIsland in MinigameParadise.

Classification: `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S005](SOURCE_INDEX.md#w-s005) ([Seven Seas](https://bgs-infinity.fandom.com/wiki/Seven_Seas)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Worlds`, lines 81–152; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).
- `StarterPlayer.StarterPlayerScripts.ClientScript`, lines 2088–2326; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).
- `Workspace.Worlds.Minigame Paradise.Islands.Hyperwave Island.Island.Gate`, lines saved World=SevenSeas attribute and Activation.Root observation; not script lines; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).

Reason: Cost agrees; discovered normalgate location differs. Therefore do notplan directZen→SevenSeasnormal purchase from wiki alone.

Limits: The saved client/physicalgate location does not prove server independentlyenforces Hyperwavediscovery on everyUnlockWorld request. Map/trampoline travel after unlock are distinct.

### W-C013

Zen's public Gem15=10% and Comet=.002% statements differ from conditional probabilities obtained by normalizing saved Zenweights30 and.0002 over100.0002.

Classification: `CONTRADICTED_BY_NATIVE`, `UNKNOWN_SERVER_RULE`, `VERSION_DEPENDENT`.

External evidence: [W-S006](SOURCE_INDEX.md#w-s006) ([Zen](https://bgs-infinity.fandom.com/wiki/Zen)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Worlds`, lines 18–80,94–138; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).
- `ReplicatedStorage.Shared.Framework.Utilities.Math.GetRandomWeightedItem`, lines 14–25; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).

Reason: Conditional nativeGem15≈29.99994%;Comet≈.0001999996%, after weightnormalization. Nativeweight is not directly a probability.

Limits: Actualserver pickup sampler, attempt rate, eligibility andboosttransform remain unknown. Neither publicchance nor conditionalbaseweight yields Gems/minute.

### W-C014

TheShadowRealm wiki describes a permanent2026hub with50KGems entry, distinct from the separately named2025ShadowRealm event; hubavailability/entrycontract remain externally sourced.

Classification: `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`, `HISTORICAL_OR_REMOVED`.

External evidence: [W-S007](SOURCE_INDEX.md#w-s007) ([The Shadow Realm](https://bgs-infinity.fandom.com/wiki/The_Shadow_Realm)); [W-S008](SOURCE_INDEX.md#w-s008) ([Shadow Realm](https://bgs-infinity.fandom.com/wiki/Shadow_Realm)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Worlds`, lines 81–152,209–222,288–300; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).

Reason: Actualpermanent2026hubarticle andexplicitlyremoved2025mini-event aredistinct. SecondaryOverworldhub liesoutsideWorldsregistryentries; absencedoesnotdisprovewiki.

Limits: No verifiednativeentrycaller, unlockedflag, paymentresult orcurrenteventwithinhub. Do notreuse removed2025egg/cost/rewards orassume noHalloween anywhere.

### W-C015

Rifts article's summoned≤30minute limit conflicts with native45/60minute choices and anotherwiki summon-option table that includes those choices.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S009](SOURCE_INDEX.md#w-s009) ([Rifts](https://bgs-infinity.fandom.com/wiki/Rifts)); [W-S014](SOURCE_INDEX.md#w-s014) ([Bubble Shrine](https://bgs-infinity.fandom.com/wiki/Bubble_Shrine)).

Native comparison:

- `ReplicatedStorage.Shared.Data.RiftSummonCosts`, lines 14–15; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).
- `ReplicatedStorage.Client.Gui.Frames.RiftSummon`, lines 69–100,415–523,607; [Stage 1 comparison](../replicatedstorage/SPECIALTY_SOURCE_LEDGER.md).

Reason: Saved chooser defines10/15/30/45/60minuteoptions with1/2/4/8/16durationShards. BubbleShrinewiki table matches it;Riftsprose is notuniform evidence.

Limits: Visible chooser options do notprove servercurrentlyaccepts everyindex oractualDespawnAt; naturalspawnlifetimealso requiresactualobject.

### W-C016

BubbleShrine wiki12h/1000itemcap and42.3sec increment disagree with saved durationhelper's24h/500itemcap and171sec-per-item increase from15min baseline.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S014](SOURCE_INDEX.md#w-s014) ([Bubble Shrine](https://bgs-infinity.fandom.com/wiki/Bubble_Shrine)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.ShrineUtil`, lines 109–125; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).

Reason: D(a)=floor(60*(15+1425*clamp(a,0,500)/500));a1=1071sec,a100=18000sec,a500=86400sec. Itemamount drivesduration, itemtype controlsXP separately.

Limits: Saved helper notexecuted; received blessingexpiry/itemdeduction needed. Wiki initialitemwording and baseline should not be silently mappedonto native formula.

### W-C017

Fishingoverview level50at10mXP and9rods/6baits agree with saved catalogs; ordinary cratepercentage table omits nativeClassiccrate and does not match normalized rawweights.

Classification: `CONTRADICTED_BY_NATIVE`, `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`, `VERSION_DEPENDENT`.

External evidence: [W-S015](SOURCE_INDEX.md#w-s015) ([Fishing](https://bgs-infinity.fandom.com/wiki/Fishing)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.FishingUtil`, lines 33–54,538–596; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Shared.Data.FishingRods`, lines 11–19; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Shared.Data.FishingBait`, lines 22–27; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Progression/catalogcounts agree, but ordinary rawcrateweights60/35/10/5sum110;wiki6/3.5/.5percent omitsClassic. GalaxyBaitexplicithelperbranchselectsGalaxycrate.

Limits: Finalcratechance, batchrollcount, buffapplication, paidAutoFishingprice/ownership andactualcatchresults remain unverified; reconstruction limits preventcertified final odds.

### W-C018

PetMatch wiki entry5kTickets,base5mincooldown and1SuperTicket cooldownreset match saved catalog/client skipdefinitions.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S010](SOURCE_INDEX.md#w-s010) ([Pet Match](https://bgs-infinity.fandom.com/wiki/Pet_Match)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Minigames`, lines 12–75; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.Frames.Minigames`, lines 343–389,444–459; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Costandbasecooldown correspond native; SuperTicket is anitem separate fromTicketcurrency.

Limits: Actualmodifiedcooldown, debit, permission,difficultyunlock andwin/fail payout requirefresh acceptedresults.

### W-C019

PetMatch Medium12cards means six pairs in nativeconfig; wiki's fourpairs is internally inconsistent and contradicted bynative.

Classification: `CONTRADICTED_BY_NATIVE`.

External evidence: [W-S010](SOURCE_INDEX.md#w-s010) ([Pet Match](https://bgs-infinity.fandom.com/wiki/Pet_Match)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.Minigames.Pet Match`, lines 197; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: 12cards/2=6pairs; nativegrids6/12/16/24cards yield3/6/8/12pairs.

Limits: Onlysourceconfig/arithmetic corrected; no legitimate play result orcurrentserverdifficultyverification.

### W-C020

RobotClaw wiki30mincooldown differs from saved native20min;2.5mTicketprice/60secbasetime/1SuperTicketskip agree.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S020](SOURCE_INDEX.md#w-s020) ([Robot Claw](https://bgs-infinity.fandom.com/wiki/Robot_Claw)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Minigames`, lines 12–75; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.Frames.Minigames`, lines 444–459; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.Frames.Minigames.Robot Claw`, lines 663–676; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: SavedCooldown1200seconds versus public30minutes. BaseDuration60 andcostagree; receivedFinishAtcontrols actualsessiontimer.

Limits: Neitherbasecatalog norwiki certifies currentaccountcooldown, modifications, success/bonuscount or finalserverpayout.

### W-C021

PetMatch andRobotClaw loot labels corroborate native reward families/rawvalues but cannot be read as complete finalpercentages or self-funding play.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S010](SOURCE_INDEX.md#w-s010) ([Pet Match](https://bgs-infinity.fandom.com/wiki/Pet_Match)); [W-S020](SOURCE_INDEX.md#w-s020) ([Robot Claw](https://bgs-infinity.fandom.com/wiki/Robot_Claw)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Minigames`, lines 12–75; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Shared.Data.Builders.LootPoolBuilder`, lines 25–33; [Stage 1 comparison](../replicatedstorage/SPECIALTY_SOURCE_LEDGER.md).

Reason: PetMatchpooltotal98.5,Robot95.91. Perpooldraw interpretation requiresnormalization plusactual acceptedrollcount/bonusdistribution.

Limits: Higherdifficulty'sadditionalitemsandMythicbonus descriptions are notcreditreceipts. Noverified perpetualClaw loop follows from1.4rawSuperTicketweight.

### W-C022

Board wiki weighted6/10/1dicewindows agree with sharedhelper; GoldenDice is nextnode in thathelper, not an arbitrarychosen destination.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S019](SOURCE_INDEX.md#w-s019) ([Board Game](https://bgs-infinity.fandom.com/wiki/Board_Game)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.BoardUtil`, lines 24–57,75–114; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.Frames.Board`, lines 839–844,1017,1076–1077; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Knownnodeweights override some savedrawweights. NativeRollDice passes onlydicename and receivesresolvedRoll/Tile.

Limits: Serverselection/consumption/currentnode topology remain unverified. No targetface/tile argumentor guaranteedserverluck grant established.

### W-C023

Boardwiki87tiles differs from88savedphysicalnumericnodes; this is a counting/version discrepancy, without proof everyphysicalnode equals one wiki gameplaytile.

Classification: `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S019](SOURCE_INDEX.md#w-s019) ([Board Game](https://bgs-infinity.fandom.com/wiki/Board_Game)).

Native comparison:

- `Workspace.Worlds.Minigame Paradise.Board.Nodes`, lines savedinspect_instance88nodes; notscriptlines; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Shared.Utils.BoardUtil`, lines 24–57,77–114; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Helperuses allsortedphysicalnodes; currentcatalogscenehas88. Starttile/inclusionconvention orversioncouldexplainpublic87.

Limits: Liveboard registry andaccountTile needed. Do nothardcode87/88orwarp toadvanceclaims.

### W-C024

Boardarticle trivia suggests concurrenthatching afterwalkingaway; this is an externalplayer tip, not a verified OCcoordination/actioncontract.

Classification: `EXTERNAL_ONLY`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S019](SOURCE_INDEX.md#w-s019) ([Board Game](https://bgs-infinity.fandom.com/wiki/Board_Game)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.Board`, lines 484–520,1292,1316,1902; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.HUD`, lines 1831–1835; [Stage 1 comparison](../replicatedstorage/SPECIALTY_SOURCE_LEDGER.md).

Reason: NativeUI/auto/locationconditions andinflightrolls require coherentforeground ownership; publictrivia doesnot establish safe scheduler semantics.

Limits: Noownerliveverificationofconcurrency;Phase9deferred. Noautotravel, pickupchasing, independentloops orimplementationauthorized.

### W-C025

Obbysarticle matches threeClassicIslandactivities with baseEasy/Medium/Hardcooldowns3/5/10minutes; fishingaccess and coursecompletion remain separate.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S018](SOURCE_INDEX.md#w-s018) ([Obbys](https://bgs-infinity.fandom.com/wiki/Obbys)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Obbys`, lines 12–90; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Shared.Data.FishingAreas`, lines 159–182; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.Frames.Obbys`, lines 95–103,158,221,246–259,634–643; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Catalogcooldowns180/300/600seconds andactualClassicbindingsagree. Classicfishingarea level25 is an independentnativeaccess prerequisite.

Limits: Noowner-testedroute/checkpoint/timer;Complete labeloptimistic untilacceptedresponse. Chestkey/opening remainseparatecost.

### W-C026

FishDex's seven20-fish tables and all seven islandcompletionrewardsets agree with nativeFishingAreas; multiple listed rewards belong to one completionclaim, nottiers.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S021](SOURCE_INDEX.md#w-s021) ([FishDex](https://bgs-infinity.fandom.com/wiki/FishDex)).

Native comparison:

- `ReplicatedStorage.Shared.Data.FishingAreas`, lines 13–182; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.Frames.Fishing.FishingJournal.FishingJournalIndex`, lines 52–64,209–235,346–378; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Publicrewardsets matchnativeGolden/Blizzard/Lotus/Molten/Tridentrods,pet/elixirrewards;Journaliterateseveryitem before oneareaIdclaim.

Limits: UIreconstructionlimits andservereligibilityremain. ActualClaimedFishIslandRewards plusallitemdeltas required; lastmissingrarefishcan dominatecompletiontime.

### W-C027

FishingRods article names OldSailorquests andFishDex as acquisitionroutes; no savedrodprice implies all rods can be purchased from fishing-shop catalog.

Classification: `NATIVE_CORROBORATED`, `EXTERNAL_ONLY`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S017](SOURCE_INDEX.md#w-s017) ([Fishing Rods](https://bgs-infinity.fandom.com/wiki/Fishing_Rods)); [W-S021](SOURCE_INDEX.md#w-s021) ([FishDex](https://bgs-infinity.fandom.com/wiki/FishDex)).

Native comparison:

- `ReplicatedStorage.Shared.Data.FishingRods`, lines 11–30; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Shared.Data.FishingAreas`, lines 13–182; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: NativeFishDex rewards corroborate specifiedrodroute androdcataloghas no purchaseprice. OldSailorroute is externalhere unless itsdedicatednativequestscopeconfirms it.

Limits: Currentownership, acquiredqueststage, limitedrodavailability andmissing nativevendor call remain unknown.

### W-C028

CartEscape wiki200kTickets/15minbasecooldown/1SuperTicketskip agree with native;fourprogressivedifficultiesdo notprove everyadvertisedbonusdrop.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S023](SOURCE_INDEX.md#w-s023) ([Cart Escape](https://bgs-infinity.fandom.com/wiki/Cart_Escape)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Minigames`, lines 12–75; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.Frames.Minigames.Cart Escape`, lines 66–69,854–893,990–1068; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.Frames.Minigames`, lines 444–459; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Price/CD/configagree;receivedStart/Finish andacceptedinput outcome controlrealactivity.

Limits: InsaneMythicMagmas/+3description needsactualbonuscount/output. Crash/cleanupFinish call is notproof ofwin.

### W-C029

HyperDarts wiki15mincooldown conflicts with saved native20min;5mTickets/1SuperTicketskip matchnative.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S024](SOURCE_INDEX.md#w-s024) ([Hyper Darts](https://bgs-infinity.fandom.com/wiki/Hyper_Darts)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Minigames`, lines 12–75; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.Frames.Minigames`, lines 444–459; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Client.Gui.Frames.Minigames.Hyper Darts`, lines 63–76,275–322,939–997; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: SavedCooldown1200seconds; public15minutes. Nativegoalpoints100/250/750/1000 andreceivedFinishAt determineplay, notgenericautoclickadvice.

Limits: Currentaccountmodifiedcooldown andscore/bonusacceptedoutcomes unavailable. Noautoclickormacroimplementationauthorized.

### W-C030

OldSailor article describes random objectives after the initial chain and bonuses at5quests (1Infinity+1PurpleFragment),10 (1Secret),25 (3Infinity),50 (10Secret),250 (Cthulhu) and500 (AbyssalSeaDragon); external pending native quest comparison.

Classification: `EXTERNAL_ONLY`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S022](SOURCE_INDEX.md#w-s022) ([Old Sailor](https://bgs-infinity.fandom.com/wiki/Old_Sailor)).

Native comparison:

- `ReplicatedStorage.Shared.Data.FishingAreas`, lines 13–35; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: CatalogPointOfInterest supportsstarterOldSailorfacility only, notquestobjectives ormilestonegrantlogic.

Limits: Noaccountquestprogress/nativeMilestoneconsumer reviewedin thisspecialtyscope. Do notinventrodunlock/deadline orautoquestexecutor.

### W-C031

Fish article's conditionalmutationweights/value/XP agree with saved FishMutations; its base5% correspondshelperconstant, not certified finalcatch mutationodds.

Classification: `NATIVE_CORROBORATED`, `UNKNOWN_SERVER_RULE`.

External evidence: [W-S025](SOURCE_INDEX.md#w-s025) ([Fish](https://bgs-infinity.fandom.com/wiki/Fish)).

Native comparison:

- `ReplicatedStorage.Shared.Data.FishMutations`, lines 10–41; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Shared.Data.Fish`, lines 8–147; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).
- `ReplicatedStorage.Shared.Utils.FishingUtil`, lines 33–54,538–596; [Stage 1 comparison](../replicatedstorage/FISHING_AND_MINIGAMES.md).

Reason: Weights5/3/1/.5sum9.5 yieldrounded52.6/31.6/10.5/5.3percent conditionalonmutation;value/XPmultipliers match.

Limits: Mutationtest/XPassignmentsdamaged in reconstructedsaved helper; buffs/environment/server maychangefinaljointprobability. Do notapplyconditionalsharetoeverycatch.

### W-C032

Events article's NO ACTIVE EVENTS statement conflicts with currentdeveloper Halloween description andownerreport, despite havingan Autumn2026 row endingOctober10.

Classification: `VERSION_DEPENDENT`, `OWNER_LIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S026](SOURCE_INDEX.md#w-s026) ([Events](https://bgs-infinity.fandom.com/wiki/Events)); [W-S012](SOURCE_INDEX.md#w-s012) ([[🎃] Bubble Gum Simulator INFINITY](https://www.roblox.com/games/85896571713843/Bubble-Gum-Simulator-INFINITY)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Events`, lines 163–164,214–230; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).

Reason: ActualarticlebodyisnewerthanFireIce searchsnippet butnotupdated consistently forHalloween launch. Primarydevelopercurrentdescription+ownerreportcarrymoreweight.

Limits: Wikiindex is notauthoritativecurrenteventavailability; noexactHalloween26enddateoraccounteligibility follows.

### W-C033

Autumn2026 article explicitly marksSeptember26–October10event removed, whileAutumn2025article marksSeptember26–October17,2025removed. Neitheris a currentHalloween guide.

Classification: `HISTORICAL_OR_REMOVED`, `VERSION_DEPENDENT`.

External evidence: [W-S027](SOURCE_INDEX.md#w-s027) ([Autumn Event 2026](https://bgs-infinity.fandom.com/wiki/Autumn_Event_2026)); [W-S028](SOURCE_INDEX.md#w-s028) ([Autumn Event 2025](https://bgs-infinity.fandom.com/wiki/Autumn_Event_2025)); [W-S012](SOURCE_INDEX.md#w-s012) ([[🎃] Bubble Gum Simulator INFINITY](https://www.roblox.com/games/85896571713843/Bubble-Gum-Simulator-INFINITY)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Events`, lines 163–164,214–230; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).
- `ReplicatedStorage.Shared.Utils.GetPickupZones`, lines 43–60; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).

Reason: Year/date/removalmarkers differ; savedFallcatalogcurrencyLeaves26 andcurrentHalloweenCandycorn26schema are notinterchangeable.

Limits: Publicremovalclaimis historicalsecondaryevidence,notserverstate test. RetainedActivefields do notdisprove removal orprove currenteligibleevent.

### W-C034

Autumn2026 main period starts September26 while HarvestEgg subsection starts September20; the differing scope may reflect Part1 versus Update74Part2, and placeholder pool text limits detailed odds evidence.

Classification: `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S027](SOURCE_INDEX.md#w-s027) ([Autumn Event 2026](https://bgs-infinity.fandom.com/wiki/Autumn_Event_2026)); [W-S030](SOURCE_INDEX.md#w-s030) ([Changelog](https://bgs-infinity.fandom.com/wiki/Changelog)).

Native comparison:

- No source-path corroboration claimed; see the scoped external/native comparison and limits.

Reason: Root actual body dates differ; Changelog calls Update74 FallPart2. Preserve phase/version ambiguity instead of automatically declaring either date false.

Limits: No exact egg phase boundary/final pool odds adopted. Historical opportunity only; neither date is current Halloween deadline.

### W-C035

Autumn event removal and Autumn BubblePass deadline are distinct public calendar statements; neither supplies current Halloween expiry.

Classification: `VERSION_DEPENDENT`, `EXTERNAL_ONLY`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [W-S027](SOURCE_INDEX.md#w-s027) ([Autumn Event 2026](https://bgs-infinity.fandom.com/wiki/Autumn_Event_2026)); [W-S029](SOURCE_INDEX.md#w-s029) ([Bubble Pass](https://bgs-infinity.fandom.com/wiki/Bubble_Pass)).

Native comparison:

- `ReplicatedStorage.Shared.GlobalEvent`, lines 38–58; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).
- `ReplicatedStorage.Shared.Utils.SpecialEventUtil`, lines 26,35,80–90; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).

Reason: Wiki AutumnEvent removed October10, pass listing through October15. Separate feature clocks can have different windows.

Limits: Native references illustrate boost/schedule clocks, not pass verification. Dedicated root pass research required. Current Halloween end unknown.

### W-C036

Visible wiki Changelog latest October3 Update75 predates official October11 Halloween description; missing newer entries are a coverage gap, not evidence Halloween is absent.

Classification: `VERSION_DEPENDENT`, `OWNER_LIVE_CORROBORATED`.

External evidence: [W-S030](SOURCE_INDEX.md#w-s030) ([Changelog](https://bgs-infinity.fandom.com/wiki/Changelog)); [W-S012](SOURCE_INDEX.md#w-s012) ([[🎃] Bubble Gum Simulator INFINITY](https://www.roblox.com/games/85896571713843/Bubble-Gum-Simulator-INFINITY)).

Native comparison:

- No source-path corroboration claimed; see the scoped external/native comparison and limits.

Reason: Developer public description and owner context supersede incomplete wiki index for current season.

Limits: No exact Halloween launch/end patch number derived. Older Changelog months not read; access date is not a revision timestamp.

## Identity, community and synthesis

| Claim | Statement | Classifications |
|---|---|---|
| [R-C001](#r-c001) | Public developer listing advertises Halloween at research access; this supports owner Halloween report, not automatic event/account eligibility. | `OWNER_LIVE_CORROBORATED`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [R-C002](#r-c002) | Launch guides classify Overworld islands as separate numbered worlds. | `CONTRADICTED_BY_NATIVE`, `HISTORICAL_OR_REMOVED` |
| [R-C003](#r-c003) | Guide describes Mastery as three branches purchased with Coins. | `HISTORICAL_OR_REMOVED`, `CONTRADICTED_BY_NATIVE` |
| [R-C004](#r-c004) | Surface and Twilight sell ratios2 and5 Coins per bubble appear in the guide. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [R-C005](#r-c005) | Fan guide recommends Pets-first, Buffs-second, Shops-last. | `EXTERNAL_ONLY`, `VERSION_DEPENDENT` |
| [R-C006](#r-c006) | Fan guide describes universal five-matching-Secret pet conversion. | `CONTRADICTED_BY_NATIVE`, `NEEDS_LIVE_VERIFICATION` |
| [R-C007](#r-c007) | Community discovery lead: Pets-first and Gems | `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [R-C008](#r-c008) | Community discovery lead: Coin team versus mythic boxes | `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [R-C009](#r-c009) | Community discovery lead: Team Up versus Looter | `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [R-C010](#r-c010) | Community discovery lead: Gamepass opinions | `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [R-C011](#r-c011) | Community discovery lead: Event pet advice challenged | `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [R-C012](#r-c012) | Community discovery lead: Zen Gems anecdote | `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [R-C013](#r-c013) | Wiki Guilds no-active-season/Season1endedOct10'26 differs from retained nativeSeason2windowOct9–Nov8 and six-day weeks. | `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |
| [R-C014](#r-c014) | Wiki Rune Crafting overstates several retained ingredient costs, while nominal tier durations agree. | `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT` |
| [R-C015](#r-c015) | Wiki recipe times are per recipe; native selected-amount craft finish uses serial Duration times Amount. | `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION` |
| [R-C016](#r-c016) | Wiki Currency38keys and generic/year-specific displaynames do not fully cover current49native keys. | `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION` |

### R-C001

Public developer listing advertises Halloween at research access; this supports owner Halloween report, not automatic event/account eligibility.

Classification: `OWNER_LIVE_CORROBORATED`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S004](SOURCE_INDEX.md#r-s004) ([[Halloween] Bubble Gum Simulator INFINITY](https://www.roblox.com/games/85896571713843/Bubble-Gum-Simulator-INFINITY)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.HalloweenRebirth`, lines 24,39–78,118,129,145; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md#halloween26-facilities-upgrades-and-rebirth).

Reason: OfficiallistingactualbodyUpdated2026-10-11+ownerreport+savedHalloween26schema. Accountactions/enddatesnotverified.

Limits: NoStudioPlaceIddisclosure orliveaccountprerequisiteproof.

### R-C002

Launch guides classify Overworld islands as separate numbered worlds.

Classification: `CONTRADICTED_BY_NATIVE`, `HISTORICAL_OR_REMOVED`.

External evidence: [R-S005](SOURCE_INDEX.md#r-s005) ([INFINITY Beginner Guide — PGG](https://progameguides.com/roblox/bubble-gum-simulator-infinity-beginners-guide-items-pets-enchants/)); [R-S006](SOURCE_INDEX.md#r-s006) ([INFINITY Beginner Guide — Theria](https://theriagames.com/guide/roblox-bubble-gum-simulator-infinity-guide/)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Worlds`, lines 81–152; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md).

Reason: Currentnativeworldandislandidentitiesseparate;OuterSpaceisanOverworldisland,notMinigameParadiseWorld2.

Limits: Guideislandheightsmayalsobedatedapproximate;noneusedasroute.

### R-C003

Guide describes Mastery as three branches purchased with Coins.

Classification: `HISTORICAL_OR_REMOVED`, `CONTRADICTED_BY_NATIVE`.

External evidence: [R-S005](SOURCE_INDEX.md#r-s005) ([INFINITY Beginner Guide — PGG](https://progameguides.com/roblox/bubble-gum-simulator-infinity-beginners-guide-items-pets-enchants/)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 1–276; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Savednative115tiersacross8branchesusesCoins/Gems/Tickets/seasoncurrencies. Launchdescriptionnotcurrent.

Limits: Featurereleaseversusguideupdatepreserved.

### R-C004

Surface and Twilight sell ratios2 and5 Coins per bubble appear in the guide.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S006](SOURCE_INDEX.md#r-s006) ([INFINITY Beginner Guide — Theria](https://theriagames.com/guide/roblox-bubble-gum-simulator-infinity-guide/)).

Native comparison:

- `Workspace selling model Multiplier/Currency attributes`, no script-line assertion; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md#selling-stations-and-intentional-egg-travel); PROPERTY_SUMMARY_FROM_STAGE1.
- `ReplicatedStorage.Client.Activation`, lines 265–300,334–384; [Stage 1 comparison](../replicatedstorage/WORLD_AND_NAVIGATION.md#selling-stations-and-intentional-egg-travel).

Reason: Nativeselllocationratioscorroborate;actualcreditedrateincludesaccountmodifiers/cycletime.

Limits: Nominalyieldnotautomaticbestincomeorreachabletravel. NativeattributeevidenceisStage1propertysummary,notexact-instance-source-lineproof.

### R-C005

Fan guide recommends Pets-first, Buffs-second, Shops-last.

Classification: `EXTERNAL_ONLY`, `VERSION_DEPENDENT`.

External evidence: [R-S007](SOURCE_INDEX.md#r-s007) ([Mastery and Rebirth Guide — unofficial fan site](https://bubblegumsimulatorinfinity.wiki/guides/mastery-and-rebirth/)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Mastery`, lines 1–276; [Stage 1 comparison](../replicatedstorage/MASTERY_AND_UPGRADES.md).

Reason: Priorityisopinion;nativecostpackages/spareownedunits/horizon/reservescanreverseit.

Limits: Noaccountstateormeasuredrateinsession;nopurchaseauthorization.

### R-C006

Fan guide describes universal five-matching-Secret pet conversion.

Classification: `CONTRADICTED_BY_NATIVE`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S007](SOURCE_INDEX.md#r-s007) ([Mastery and Rebirth Guide — unofficial fan site](https://bubblegumsimulatorinfinity.wiki/guides/mastery-and-rebirth/)).

Native comparison:

- `ReplicatedStorage.Shared.Utils.RebirthMachineUtil`, lines 185–228,237–244; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md#native-pet-conversion--fusing).
- `ReplicatedStorage.Client.Gui.Frames.RebirthMachine`, lines 195–208,426–428,742; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md#native-pet-conversion--fusing).

Reason: Somecombinationrecipesheterogeneous;clientmatchingShiny/Mythicvariantisdistinctfromnames. Ownership/consumption/resultserververificationmissing.

Limits: Recipeinsufficientalone;protectequipped/locked/XL/valuableinputs.

### R-C007

Community discovery lead: Pets-first and Gems

Classification: `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S008](SOURCE_INDEX.md#r-s008) ([Pets-first and Gems](https://www.reddit.com/r/BubbleGumSimulator/comments/1khdv4o)).

Native comparison:

- No source-path corroboration claimed; see the scoped external/native comparison and limits.

Reason: Onlysearch-returnedexcerptavailable. Strategytestedagainstnativepreconditions inCOMMUNITY_STRATEGIES;notacceptedcurrentmechanic.

Limits: Fullthreadunavailable;anecdoteteam/rate/accountcontextnotverified.

### R-C008

Community discovery lead: Coin team versus mythic boxes

Classification: `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S009](SOURCE_INDEX.md#r-s009) ([Coin team versus mythic boxes](https://www.reddit.com/r/BubbleGumSimulator/comments/1lb8zhf)).

Native comparison:

- No source-path corroboration claimed; see the scoped external/native comparison and limits.

Reason: Onlysearch-returnedexcerptavailable. Strategytestedagainstnativepreconditions inCOMMUNITY_STRATEGIES;notacceptedcurrentmechanic.

Limits: Fullthreadunavailable;anecdoteteam/rate/accountcontextnotverified.

### R-C009

Community discovery lead: Team Up versus Looter

Classification: `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S010](SOURCE_INDEX.md#r-s010) ([Team Up versus Looter](https://www.reddit.com/r/BubbleGumSimulator/comments/1kcol7j)).

Native comparison:

- No source-path corroboration claimed; see the scoped external/native comparison and limits.

Reason: Onlysearch-returnedexcerptavailable. Strategytestedagainstnativepreconditions inCOMMUNITY_STRATEGIES;notacceptedcurrentmechanic.

Limits: Fullthreadunavailable;anecdoteteam/rate/accountcontextnotverified.

### R-C010

Community discovery lead: Gamepass opinions

Classification: `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S011](SOURCE_INDEX.md#r-s011) ([Gamepass opinions](https://www.reddit.com/r/BubbleGumSimulator/comments/1u2helz/bgsi_gamepasses_worth/)).

Native comparison:

- No source-path corroboration claimed; see the scoped external/native comparison and limits.

Reason: Onlysearch-returnedexcerptavailable. Strategytestedagainstnativepreconditions inCOMMUNITY_STRATEGIES;notacceptedcurrentmechanic.

Limits: Fullthreadunavailable;anecdoteteam/rate/accountcontextnotverified.

### R-C011

Community discovery lead: Event pet advice challenged

Classification: `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S012](SOURCE_INDEX.md#r-s012) ([Event pet advice challenged](https://www.reddit.com/r/BubbleGumSimulator/comments/1vljk38/stuck/)).

Native comparison:

- No source-path corroboration claimed; see the scoped external/native comparison and limits.

Reason: Onlysearch-returnedexcerptavailable. Strategytestedagainstnativepreconditions inCOMMUNITY_STRATEGIES;notacceptedcurrentmechanic.

Limits: Fullthreadunavailable;anecdoteteam/rate/accountcontextnotverified.

### R-C012

Community discovery lead: Zen Gems anecdote

Classification: `EXTERNAL_ONLY`, `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S013](SOURCE_INDEX.md#r-s013) ([Zen Gems anecdote](https://www.reddit.com/r/BubbleGumSimulator/comments/1k36368)).

Native comparison:

- No source-path corroboration claimed; see the scoped external/native comparison and limits.

Reason: Onlysearch-returnedexcerptavailable. Strategytestedagainstnativepreconditions inCOMMUNITY_STRATEGIES;notacceptedcurrentmechanic.

Limits: Fullthreadunavailable;anecdoteteam/rate/accountcontextnotverified.

### R-C013

Wiki Guilds no-active-season/Season1endedOct10'26 differs from retained nativeSeason2windowOct9–Nov8 and six-day weeks.

Classification: `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S014](SOURCE_INDEX.md#r-s014) ([Guilds](https://bgs-infinity.fandom.com/wiki/Guilds)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Guilds`, lines 206; [Stage 1 comparison](../replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md).
- `ReplicatedStorage.Shared.Utils.Stats.GuildUtil`, lines 208–219; [Stage 1 comparison](../replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md).

Reason: Wikiweekly/season1textvsnativeWeekDuration518400andSeason2catalog. AccountmatchedsnapshotUIgateandserveractiveunknown;neitheraloneprovesliveactivation.

Limits: Independentguild/event/passcalendars;noguildXPmechanicsormembershipactioninferred.

### R-C014

Wiki Rune Crafting overstates several retained ingredient costs, while nominal tier durations agree.

Classification: `CONTRADICTED_BY_NATIVE`, `VERSION_DEPENDENT`.

External evidence: [R-S015](SOURCE_INDEX.md#r-s015) ([Rune Crafting](https://bgs-infinity.fandom.com/wiki/Rune_Crafting)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Runes`, lines 52–188; [Stage 1 comparison](../replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md).
- `ReplicatedStorage.Shared.Utils.RuneUtil`, lines 60–72; [Stage 1 comparison](../replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md).

Reason: LuckIwiki50Rerollvsnative25;II75/10Power vs50/5;III150/25Powervs100/15;Secret20/40/80SuperTicketsvsnative10/20/40. Durations45/120/240Luck,60/120/300Secret,60/120/240Bubblesagree.

Limits: Actualdebit/craftgrantsunknown;protectingredientreserves.

### R-C015

Wiki recipe times are per recipe; native selected-amount craft finish uses serial Duration times Amount.

Classification: `NATIVE_CORROBORATED`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S015](SOURCE_INDEX.md#r-s015) ([Rune Crafting](https://bgs-infinity.fandom.com/wiki/Rune_Crafting)).

Native comparison:

- `ReplicatedStorage.Client.Gui.Frames.RuneCrafting`, lines 83–106,183,205,276; [Stage 1 comparison](../replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md).

Reason: Nominaldurationsagree;selectedbulkbatchtimecannotbeoneDuration. NativeactiveRuneusestillremainingusesnotsimpleexpiry.

Limits: Serveratomicity/grant/actualprogressnotverified.

### R-C016

Wiki Currency38keys and generic/year-specific displaynames do not fully cover current49native keys.

Classification: `VERSION_DEPENDENT`, `NEEDS_LIVE_VERIFICATION`.

External evidence: [R-S016](SOURCE_INDEX.md#r-s016) ([Currency](https://bgs-infinity.fandom.com/wiki/Currency)).

Native comparison:

- `ReplicatedStorage.Shared.Data.Currency`, lines 1–60; [Stage 1 comparison](../replicatedstorage/DATA_SCHEMAS.md).
- `ReplicatedStorage.Client.Gui.Frames.HalloweenRebirth`, lines 39–78; [Stage 1 comparison](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md).

Reason: AutumnLeaves26versusoldLeavesdisplaydistinctionuseful;genericCandycorndoesnotidentifyCandycorn26/HalloweenShards. Nativekeycountdifferent,retainedkeysnotallactive.

Limits: Useexactprofilekeysandseasonreadiness;nofixedcrosscurrencyconversion.



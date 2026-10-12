# BGSI OC — Stage 2 evidence and strategy library

Research snapshot: **2026-10-11**. This library extends the immutable [Stage 1 native knowledge library](../replicatedstorage/README.md) for **Bubble Gum Simulator INFINITY**, the sequel. Research and design proposals were saved locally. No gameplay implementation, purchasing, release rebuild or GitHub synchronization was performed.

## Executive findings

1. **Free owned-team optimization comes first.** Prospective egg, enchant and Mastery gains must be compared with the best feasible team the account already owns, respecting quantities, protected pets, equip limits, Super limits and coupled enchants. A weak equipped team can manufacture apparent hatch ROI. The session had no fresh owner account snapshot or earning-rate sample, so it does not identify this account's actual optimum. [Team strategy](PET_TEAM_AND_ENCHANT_STRATEGY.md).
2. **A raw weight or advertised Luck value is not a final probability.** Native luck transformations, rarity-first Infinity pools, variants, paid exceptions and counters require distinct models. Expected hatches, confidence, full-batch cost and improvement utility can be calculated conditionally; authoritative server odds remain unavailable. An IID target with probability p has mean 1/p, but about a 63.2% chance of appearing by that mean, rather than a guarantee. [Probability research](EGG_PROBABILITY_RESEARCH.md).
3. **Mastery is a prerequisite package and horizon decision.** All 115 native tiers across eight branches are documented. Extra capacity needs useful additional owned units; replacement-style perks must not be summed as independent bonuses. Compare the entire unowned package, actual credited rate gain, setup/travel, protected reserves and time to the world goal. A blanket Pets-first order can be wrong for a particular account. [Mastery ROI](MASTERY_ROI_RESEARCH.md).
4. **Rewards and temporary opportunities can beat farming when eligibility and incremental time support it.** Ready claims, incidental objectives, Index/FishDex completion and shops deserve evaluation. Paid World Rewards, scarce keys, rolls, cooldowns, travel and collection tails are separate costs. The two permanent World Rewards tracks each have 30 exact prices totaling 2,000,000,000,600 in their respective currency. Base reward values do not certify actual credited payout. [Rewards and shops](REWARDS_SHOPS_AND_QUEST_STRATEGIES.md).
5. **Several external numbers conflict with inspected native coefficients.** XL ×2 versus ×2.5; Ultra Roller 25 versus 20; Bubble Machine+ 200 versus 250; shrine 12h/1,000 versus helper 24h/500; Robot Claw and Hyper Darts cooldowns; Daily/World Rewards; rune ingredients. The Seven Seas price agrees, but the wiki Zen prerequisite differs from the saved normal physical gate on Hyperwave Island. These comparisons do not prove every current server rule. [Conflict register](NATIVE_VS_WIKI_CONFLICTS.md).
6. **Current-season identity needs stronger evidence than a retained catalog.** The official Rumble Studios experience description advertises Halloween and agrees with the owner's report. Wiki Events says no active events and marks Autumn 2026 removed. Fall 2025, Fall 2026 and Halloween 2026 retain separate keys and calendars. This does not establish this account's access, an exact Halloween deadline or the connected Studio PlaceId. [Events](RIFTS_EVENTS_AND_OPPORTUNITIES.md).
7. **The future Brain should compare feasible, verified candidates through one authority.** Keep separate resource vectors, measure credited rates, charge opportunity/switching costs, carry uncertainty and abstain when an unresolved prerequisite determines the decision. Reuse the existing GameKnowledge, reader cache, mechanics adapter, OCBrain, TaskScheduler and verification architecture. [Decision framework](ROI_DECISION_FRAMEWORK.md).

## Evidence scope

| Measure | Final scope |
|---|---|
| Public/external source-access records | 83, preserving repeated URLs and failed attempts |
| Distinct external URLs | 72 |
| URLs with actual body/table/section evidence | 53, represented by 61 access records; includes two historical cached wiki data pages and three guide section reads |
| Discovery/inaccessible URLs without body evidence | 19 |
| Cross-referenced claim records | 153 |
| Claims carrying CONTRADICTED_BY_NATIVE | 28; includes historical and unresolved runtime cases |
| Fresh Notion context pages | Master and Phase 3–9, eight pages; relevant actual read scopes recorded separately |
| Stage 1 preserved scope | 60 files; 184 distinct native sources reviewed in Stage 1, with 443 metadata-only scripts and 75 inaccessible source reads still documented |
| Protected release/source baseline | 50 gameplay, bundle, scripts, tests and example files |

These are scoped reads, not 53 exhaustively audited articles. Specialists received the parent's actual browser findings where their own access failed. The Mastery specialist also read two cached historical data bodies and made 15 targeted read-only native path inspections (six complete bodies and nine ranges); overlapping paths are not added to Stage 1's 184-source total. No full Reddit body, video/transcript or private Discord announcement was obtained. Publication/revision dates absent from the accessed surface remain null. Roblox's experience Updated date is separately labeled.

[Source index](SOURCE_INDEX.md) provides exact URLs, dates, versions, quality and access provenance. [Claim ledger](CLAIMS_LEDGER.md) supplies classifications, native paths/line ranges, reasons and limits. [Machine-readable counts](evidence/RESEARCH_COUNTS.json), [all sources](evidence/ALL_SOURCES.jsonl) and [all claims](evidence/ALL_CLAIMS.jsonl) support reuse without duplicating the native catalogs. Classification counts overlap.

## Coverage by topic

| Topic | Substantive saved coverage | Limits / next source work |
|---|---|---|
| Eggs, luck, hatching, variants | Stats, Eggs, Pets, Infinity Egg, Bounty, Mastery and Potions bodies; conditional pool/batch/tail math; ordinary/premium/inventory distinctions | No exhaustive per-egg/pet wiki comparison; Sparkletimes, The Golden Egg and Update 34 dedicated pages remain discovery leads; server sampler/counter assignment unknown |
| Teams, enchants, shiny combinations | Best-owned-team baseline, quantities/protections/Super/coupled effects; Enchants body, rowspans, costs and biased-level math; recipes and lost-input value | Variant reconstruction and server eligibility/durable reroll outcomes require owner verification |
| Mastery | All eight published branch tables; 115 native tiers, costs/effects, dependency packages and temporary/permanent comparisons | Seasonal visibility and account-specific marginal rates/accepted purchases unavailable |
| Worlds/islands/selling | Three permanent worlds, saved gate graph and four station ratios, Zen pickups, permanent versus removed Shadow Realm | External heights are not verified routes; Seven Seas server prerequisite and new purchase/discovery/travel/approach actions require owner testing |
| Currencies, shops, quests | Currency body, Overworld shop table, Genie, Quests, Stars shop, refresh/stock/all-buy/reserve semantics and overlapping objectives | Other world/event shop tabs not exhaustive; current slots/account state and accepted progress unknown |
| Daily/playtime/rewards/chests/wheel | Seven-day/day-shop bodies, Playtime and Wheel table, 60 native World Reward entries and all prices, composite Infinity Chest helper/consumer | External World Rewards and chest tables limited to Overworld; final odds, reward scaling, streak persistence and actual cooldown unresolved |
| Milestones, Index, passes/challenges | Visible Bubbling and top two tiers across 16 milestone categories; 64 native thresholds in four normalized categories; visible Index and Bubble Pass | Not every milestone row or Index/world/event tab; Challenge_Pass has no usable dedicated article body; grant/update/trade-credit rules remain unknown |
| Rifts, shrine, runes, guilds | Actual bodies, summons/expiry model, exact shrine duration, recipe cost conflicts, serial craft timing and independent calendars | Final spawn/claim/craft/grant rules, active guild/account season and actual deadlines unavailable |
| Fishing, FishDex, rods, Sailor | Fishing/Rods/Fish bodies; nine native rod attributes, 140 fish, seven 20-fish completion tables, all reward sets; conditional mutations, means and collection tails | Fish_Index has no article text; no full Old Sailor native quest-chain comparison, server catch sampler or legitimate shore/action verification |
| Minigames, board, obbies | Pet Match, Cart Escape, Robot Claw, Hyper Darts, Board Game, Obbys; costs/cooldowns, reward weights and renewal economics | Unknown accepted roll counts/bonuses, cooldown start semantics and legitimate input/course results |
| Seasonal/changelog | Autumn 2025/2026 removed pages, Events, visible latest Changelog, Bubble Pass, public current Halloween listing plus owner/native context | Visible Changelog ends October 3 Update 75; historical months/newer pages not exhaustive; Halloween expiry/rebirth forfeiture not verified |
| Community strategies | Three guides' actual mechanics sections; eight dated Reddit discovery leads including two world-opportunity threads | Full threads unavailable through cache misses/CAPTCHA; no challenges performed; anecdotes remain hypotheses |

[Independent coverage review](COVERAGE_REVIEW.md) and [knowledge gaps](KNOWLEDGE_GAPS.md) retain the incomplete scopes and reasons. Major topic families have substantive comparisons; exhaustive historical, community and server coverage remains unfinished.

## Research documents

| Purpose | File |
|---|---|
| Mathematical egg/probability economics | [EGG_PROBABILITY_RESEARCH](EGG_PROBABILITY_RESEARCH.md) |
| Owned teams, variants, enchant and consumption strategy | [PET_TEAM_AND_ENCHANT_STRATEGY](PET_TEAM_AND_ENCHANT_STRATEGY.md) |
| Complete Mastery packages and account stages | [MASTERY_ROI_RESEARCH](MASTERY_ROI_RESEARCH.md) |
| Rewards, shops, quests, milestones and claim boundaries | [REWARDS_SHOPS_AND_QUEST_STRATEGIES](REWARDS_SHOPS_AND_QUEST_STRATEGIES.md) |
| World goals, gates and navigation distinctions | [WORLD_PROGRESSION_STRATEGIES](WORLD_PROGRESSION_STRATEGIES.md) |
| Rifts, shrine and event economics | [RIFTS_EVENTS_AND_OPPORTUNITIES](RIFTS_EVENTS_AND_OPPORTUNITIES.md) |
| Fishing, minigames, board and legitimate obbies | [FISHING_MINIGAMES_AND_OBBY_STRATEGIES](FISHING_MINIGAMES_AND_OBBY_STRATEGIES.md) |
| Guild calendars, rune recipes and currency-year reconciliation | [GUILD_RUNE_AND_CURRENCY_RECONCILIATION](GUILD_RUNE_AND_CURRENCY_RECONCILIATION.md) |
| Evaluated community advice | [COMMUNITY_STRATEGIES](COMMUNITY_STRATEGIES.md) |
| Unified future decision model | [ROI_DECISION_FRAMEWORK](ROI_DECISION_FRAMEWORK.md) |
| Ranked proposals and Phase 4–9 map | [FUTURE_OC_IMPROVEMENTS](FUTURE_OC_IMPROVEMENTS.md) |
| Missing contracts and 12 prioritized owner tests | [KNOWLEDGE_GAPS](KNOWLEDGE_GAPS.md) |
| Notion prerequisite read evidence | [NOTION_ACCESS](NOTION_ACCESS.md) |
| Batch checkpoints | [RESEARCH_PROGRESS](RESEARCH_PROGRESS.md), [egg](EGG_PROGRESS.md), [Mastery](MASTERY_PROGRESS.md), [world](WORLD_PROGRESS.md) |

## Ranked future development and phase ownership

The full [15-improvement table](FUTURE_OC_IMPROVEMENTS.md) provides impact, confidence, prerequisites, live acceptance and phase ownership. In rank order: best-owned-team comparison; evidence/version metadata; credited-rate measurement; protected goal/package reserves; ready reward claims; conditional useful-outcome/batch models; full Mastery package ROI; overlapping objectives; shop stock/all-buy safety; world facility/travel value; event identity/expiry/reset; Index/crafting collection loss; enchant/shrine/rune investment; validated activity renewal models; explainable material-delta replanning.

| Phase | Future integration |
|---|---|
| 4 | Pet/team/protection/hatch/variant models; explicit approval required before implementation |
| 5 | Full Mastery packages, ready rewards, completion/effective buffs and verified claims |
| 6 | Shops, quests, consumables, stock/restock and protected allocations |
| 7 | Advanced worlds, rifts, minigames, fishing and legitimate obby contracts |
| 8 | Year-specific seasonal availability, deadlines and protected rebirth economics |
| 9 | One explainable ROI Brain with uncertainty, measured rates and verified outcomes; hybrid farming remains deferred |

Preserve owner-tested Phase 1 bubbling, selling and teleportation and approved Phase 2 stationary farming. Phase 3's new unlock/travel gaps remain pending live verification. Research does not authorize Phase 4 implementation or new gameplay actions.

## Validation, preservation and backup

[Quality review](QUALITY_REVIEW.md) records independent review scopes and repaired conclusions. [Mathematics checks](MATH_VALIDATION.md) are offline arithmetic checks of conditional/illustrative models. [Primary evidence checks](PRIMARY_EVIDENCE_VALIDATION.md) and [documentation validation](DOCUMENTATION_VALIDATION.json) cover traceability and local links where possible. They are not OC builds/tests or live gameplay verification.

[Preservation report](PRESERVATION_REPORT.json) compares all 60 Stage 1 hashes and 50 protected-file hashes with the initial baseline and verifies Git HEAD `114caa4e18e05ba8881a4a93e83470b993273ecc`. Stage 2 authorship is confined to this directory. Roblox Studio was used only for the logged targeted source inspections; no Luau execution, object/script mutation or play-state change occurred. No GitHub network operation, Notion write or publishing occurred.

The completed local library is also backed up outside the repository; the exact archive path, hash and verification are recorded in [BACKUP_MANIFEST](BACKUP_MANIFEST.json). Unavailable source bodies and hidden server/live questions remain explicitly open for future research and owner-operated tests.

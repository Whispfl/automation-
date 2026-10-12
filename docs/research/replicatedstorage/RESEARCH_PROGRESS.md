# BGSI research progress and resume checkpoint

Research date: 2026-10-11. This checkpoint concludes the saved research batches below, with explicit access and source-fidelity limits. It does **not** certify a complete semantic audit of all 701 scripts or any live gameplay result.

## Constraints and preservation

- Studio remained read-only: hierarchy, property and source reads. No Luau execution, gameplay calls, object edits, installation or play-state changes.
- All authored work is local research documentation, derived catalogs, source metadata and saved-scene observations under this directory. No full third-party script or bytecode was saved.
- No OC gameplay/configuration/release changes, build, OC test run, commit, push, GitHub/Vercel synchronization or upload occurred.
- Initial local HEAD: `114caa4e18e05ba8881a4a93e83470b993273ecc`. Initial `git status --short` was empty. Read-only preservation checks retain this HEAD and show only the new `docs/research/` directory.
- The 50 existing source, bundle, script, test and example files in [PRESERVATION_BASELINE.json](PRESERVATION_BASELINE.json) were SHA-256 checked with zero changes. Documentation validation is recorded separately in [DOCUMENTATION_VALIDATION.json](DOCUMENTATION_VALIDATION.json); it is not an OC build/test or owner gameplay verification.
- Connected Studio label: `place 85896571713843 Bubble Gum Simulator INFINITY.rbxl`; Studio ID `5528d459-f21f-4304-aa34-0f2deff5a197`, Edit mode. This saved-workspace label is not independent proof of actual PlaceId, live event or current account state.

## Batch checklist

“Saved” means the stated research scope is preserved with source references and limits; it does not mean every dependency, alternate mode or catalog entry has a complete semantic audit.

| Batch | Status | Completed scope / outputs | Explicit remaining boundary |
|---|---|---|---|
| 0: owner instructions and Notion | Saved | Complete returned master, Phase 4 and Phase 9 text read first; relevant Phases 1–3 and 5–8 read with their systems; README and local architecture audit record application | Unsupported/unreturned Notion content cannot be asserted read; current session authorization controls |
| 1: complete ReplicatedStorage inventory | Saved | 50,632 descendants; 701 scripts; five child-root inventories, depth-boundary expansion and count reconciliation; MODULE_INDEX and INVENTORY_METHOD | Duplicate names and dot-containing names limit unique path addressing; hierarchy does not establish behavior |
| 2: eggs, pets, native stats and ROI | Saved | 218 eggs, 2,166 base pet definitions, 49 exact currency keys; builders, variants, enchants, equipped stacks, stat/luck/hatch/team consumers and conditional ROI; economic source ledger | Final server RNG, damaged PetUtil expressions, personalized best-team utility and measured income/time remain unavailable |
| 3: world progression and navigation | Saved | World/area prerequisites, unlock vs travel/discovery/approach, portal/trampoline behavior, sell/egg/chest/facility geometry and source caller contracts; saved-scene observations | New world unlock/travel acceptance, physical availability and persistence require future owner verification; no individual-pickup navigation |
| 4: Mastery, upgrades and rewards | Saved | Mastery categories, selected important tiers and received effects; Gum/Flavors; Playtime, Daily, Chest, paid WorldRewards, Wheel, Index, Milestone, UTC perks and distinct pass mechanisms | All-tier/all-alternate-wheel/prize/stock normalization is unfinished; reward credit, resets and bulk behavior remain server-only |
| 5: shops, quests and consumables | Saved | Vendor stock/slots/refresh/cost, Genie and seasonal builders, potion crafting and single/bulk use, gifts, argument/count limits, reserves and result boundaries | Generic quest claiming, damaged stock/task branches, physical server ranges and partial bulk outcomes remain unavailable |
| 6A: Rift and seasonal specialty | Saved | Rift types/lifecycle/summon/travel/keyed chest/gifts, XL and bounty rotation, event registry, Halloween upgrades/rebirth/TrickOrTreat, Shrine donation and normal/Admin pet conversion | Active catalog flags do not prove availability; server effects, reset/consumption results and Crystal binding remain unresolved |
| 6B: fishing, minigames, board and Obbys | Saved | 140 fish, seven pools, rods/bait/enchants, native fishing FSM and journal; four minigames, weighted 88-node board, Obby entry/completion/keyed chest; focused document and source ledger | Damaged probability/modifier branches, dynamic fishing keys, authoritative win/grants/cancellation, safe shore/course routes and live timings remain unavailable |
| 6C: stat dependency extensions | Saved | Rune recipes, serial craft queue, use counts and native guards; fragment units/per-color completion; equipped Super effects/cache limits; guild max-per-stat effects, level/time/snapshot rules | Rune expiry/depletion, fragment cap/reset, Super Burst/duplication consumers, guild XP earning/reward-band fidelity and server outcomes remain unresolved |
| 7: architecture and dependency mapping | Saved | All 22 local foundation modules plus bootstrap/config/docs reviewed; 4,116 native require references, LocalData pet integrity, Remote multiplexing and existing Brain/cache/scheduler consumers | Peripheral animation/render/social/trading/monetization/framework semantics are not fully audited; no competing Brain/cache/loop or implementation introduced |
| 8: cross-review and reconciliation | Saved | Economic schema/action/math corrections, specialty caller/name corrections, stat factor notation and schema additions; deduplicated coverage and exact remaining-source list | Review remains bounded by saved reconstructed source and absent live/server evidence |

## Exact source coverage

[SOURCE_COVERAGE.jsonl](SOURCE_COVERAGE.jsonl) contains 702 distinct records: all 701 ReplicatedStorage script paths plus `StarterPlayer.StarterPlayerScripts.ClientScript`, reviewed as an external native caller. Four batch manifests contribute 222 review records, deduplicated to **184 substantively reviewed sources**: 183 in ReplicatedStorage and one external caller. These counts exclude the separate 22-module local OC audit.

| Highest recorded review level | ReplicatedStorage | External caller | Meaning |
|---|---:|---:|---|
| COMPLETE_BODY_REVIEW | 38 | 0 | Explicit complete filtered body review recorded by the economic researcher |
| SYSTEMATIC_CATALOG_FACTS | 2 | 0 | Complete selected catalog fact extraction, not every generated behavior or server interpretation |
| DEEP_CORE_REVIEW | 88 | 0 | Substantive system/data/core-function review; contribution scopes and omitted rendering/dependencies still apply |
| TARGETED_REVIEW | 55 | 1 | Specific functions or system scopes reviewed; incidental functionality not fully audited |
| METADATA_ONLY | 443 | 0 | Full source fetched for signature/dependency extraction, no substantive semantic review recorded |
| UNAVAILABLE_SOURCE | 75 | 0 | Attempt failed through the current dot-path API; hierarchy existence separately confirmed |
| **Total** | **701** | **1** | Inventory, retrieval and semantic review remain distinct |

All 701 source reads were attempted: 626 yielded metadata and 75 were unavailable. The 518 paths without substantive review are listed in [inventory/REMAINING_SEMANTIC_REVIEW.jsonl](inventory/REMAINING_SEMANTIC_REVIEW.jsonl): 443 metadata-only and 75 inaccessible. [SOURCE_COVERAGE_METHOD](SOURCE_COVERAGE_METHOD.md) explains union labels; [SOURCE_COVERAGE_SUMMARY.json](SOURCE_COVERAGE_SUMMARY.json) provides totals. A higher union label does not erase an individual contribution's limits.

## Remaining research, in useful order

1. Resolve source fidelity with future owner comparisons: PetUtil variants/stats, fishing probability/mutation/XP, Green fragment Luck threshold, guild reward-band overwrites, index/quest completion and season infinite rewards. Do not “repair” the saved source in documentation or certify an inferred formula.
2. Normalize remaining high-value catalogs: all Mastery tiers; milestone/prize/XL/daily offers and alternate wheels; current mechanism-specific season rewards. Existing reviews supply semantics but not complete machine-readable facts for each tier or offer.
3. Trace unresolved consumers/interfaces: Super Burst/duplication granularity, guild XP earning, generic quest completion/grant, Rift-generated egg references, Crystal activation and missing alternate reward paths. Use existing coverage and dependencies before rereading.
4. Review remaining modules by relevance, beginning with dependencies of those uncertainties. The remaining-path list prevents counting metadata-only work as deep review. Full trading/social/monetization/animation/framework audits remain outside completed batches.
5. Retry inaccessible dot-name modules only if a permitted read-only addressing method becomes available. Most are numbered changelogs, plus Patriotic Robot2.0 animation sources. Never resolve access by inserting scripts, executing Luau or changing Studio state.
6. Collect owner-live evidence later, after appropriate approval and when the owner chooses to test: eligibility, costs/consumption/grants, final probabilities, cooldown/expiry/persistence, earning/action time and legitimate navigation. [Unknown matrix](UNKNOWN_AND_SERVER_ONLY_RULES.md) records minimal correlated evidence. No owner tests occurred in this session.

## Resume procedure

Read current owner/session instructions, this checkpoint and the relevant subject document. Locate the exact source path in combined coverage and inspect contribution scopes. Choose an unfinished question rather than repeating a finished catalog or source fetch. Keep definitions, received account facts, saved/live scene facts, client estimates and server rules separate. Save a new scoped ledger entry and update coverage after each batch. Research findings do not initiate implementation.

Phase 4 still requires explicit approval; Phase 3 new unlock/travel actions remain pending live verification; advanced hybrid farming stays deferred to Phase 9. Owner-tested foundation, bubbles, selling, teleportation and approved stationary farming remain preserved.

## Evidence vocabulary

- `SOURCE_CONFIRMED`: exact accessible native or clearly labeled local OC source supports the claim; reconstructed control flow can still have fidelity limits.
- `ACCOUNT_OBSERVED`: an actual permitted received-account observation, unavailable in this Edit-mode audit.
- `OWNER_LIVE_VERIFIED`: explicit owner test with scope/provenance; historical records are not fresh verification here.
- `CLIENT_ESTIMATE`: calculation/display made by native client; not authoritative server sampling or credited rate.
- `HYPOTHESIS`: proposed model, derived planning relationship or untested architecture.
- `UNAVAILABLE`: missing access, unreadable source, unobserved live/account state or server-only rule. Some batch prose uses “unverified” for this same missing evidence; it never means an accepted contract.

Hierarchy-only evidence cannot establish purpose, schema, probability or action acceptance. No final balance, hatch, catch, travel, reward or reset outcome is live-verified by this audit.

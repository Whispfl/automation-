# BGSI Game Knowledge Library

Research date: 2026-10-11. Local, read-only research deliverable. No OC gameplay/configuration/release changes, build, commit, push, upload, Studio code execution, gameplay requests or play-state changes were made.

## Executive summary

The complete ReplicatedStorage hierarchy is preserved as an inventory: **50,632 descendants, including 701 script objects**. Every script has a source-read attempt: 626 yielded dependency/signature metadata and 75 failed through the dot-path API. Focused research covers **184 distinct native sources**, including 183 in ReplicatedStorage and one external client caller, across economics, progression, claims, vendors, quests, fishing, minigames, Rifts, seasonal systems and stat dependencies. **A complete inventory is not a complete deep audit.** There are still 443 scripts with metadata-only review; exact review scopes, access failures and unfinished work are recorded separately.

The most important economic distinction is between base pet stats, native effective multipliers, actual earning rates and probability-weighted improvement over the **best feasible already-owned team**. Team stacks, coupled enchants, additive buff arithmetic, different currency units, travel/presentation/verification time and protected reserves all affect that comparison. The library preserves exact native argument shapes and warns where reconstructed source cannot establish a formula or server contract.

No actual player balance, live reward grant, hatch distribution or earning rate was observed. Current eligibility, authoritative server odds/validation and persistence remain UNAVAILABLE. Saved catalogs retain historical events; the owner's Halloween report is retained, and Fall definitions do not override it. Research findings grant no phase implementation or reserve-override permission.

## What was read first

The complete returned Notion text for the [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363) and [Phase9](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358) was successfully read before the inventory/deep batches. Relevant Phases1–3 and5–8 were subsequently fully read with their systems. Notion metadata marks pages unverified; no claim is made that unavailable comments/unsupported content was read. Session instructions take precedence over historical implementation/publication checklists. Phase4's current explicit-approval gate, deferred Phase9 hybrid farming and research-only scope remain in force.

## Library guide

| Read | Purpose |
|---|---|
| [MODULE_INDEX](MODULE_INDEX.md),[INVENTORY_METHOD](INVENTORY_METHOD.md),[inventory](inventory/) | complete paths/types/count reconciliation; triage separated from actual source metadata |
| [DATA_SCHEMAS](DATA_SCHEMAS.md),[SYSTEM_DEPENDENCIES](SYSTEM_DEPENDENCIES.md) | native definition/received-state shapes;4,116 require references; transport and ownership boundaries |
| [EGGS_AND_PETS](EGGS_AND_PETS.md),[ECONOMY_AND_ROI](ECONOMY_AND_ROI.md),[catalogs](catalogs/README.md) |218 eggs,2,166 pet base-stat definitions,49 exact currency keys; native math and conditional ROI |
| [STAT_DEPENDENCY_EXTENSIONS](STAT_DEPENDENCY_EXTENSIONS.md) | rune recipes/use counts/serial crafting; fragment per-color units; equipped Super effects; guild stat/progression/time factors |
| [WORLD_AND_NAVIGATION](WORLD_AND_NAVIGATION.md),[travel contracts](NATIVE_ACTION_CONTRACTS_NAVIGATION.md) |worlds/islands/portals/eggs/sell and facility paths; travel,unlock,discovery and approach are distinct |
| [MASTERY_AND_UPGRADES](MASTERY_AND_UPGRADES.md) | tier prerequisites/costs/effects,received upgrade semantics,gum/flavor economics |
| [REWARDS_QUESTS_AND_EVENTS](REWARDS_QUESTS_AND_EVENTS.md) |playtime,daily,chests,paid world rewards,wheel,index,milestones,daily perks and passes |
| [SHOPS_QUESTS_AND_CONSUMABLES](SHOPS_QUESTS_AND_CONSUMABLES.md) |stock/refresh/discount logic,Genie/task schemas,craft/use/gift action shapes |
| [SPECIALTY_AND_SEASONAL_SYSTEMS](SPECIALTY_AND_SEASONAL_SYSTEMS.md) |Rifts/XL/bounties,season mechanisms,Halloween,Shrine and protected pet conversions |
| [FISHING_AND_MINIGAMES](FISHING_AND_MINIGAMES.md) |fishing pools/rods/effects/FSM/journal,board/minigames/Obbys and mathematical limits |
| [NATIVE_ACTION_CONTRACTS](NATIVE_ACTION_CONTRACTS.md) |central action register with prerequisites,arguments,pacing,results,conflicts and stop/unknown rules |
| [OC_BRAIN_INTEGRATION_MAP](OC_BRAIN_INTEGRATION_MAP.md),[local audit](LOCAL_ARCHITECTURE_EVIDENCE.md) |all22 foundation modules reviewed; future consumers in existing Brain/cache/scheduler/mechanics |
| [UNKNOWN_AND_SERVER_ONLY_RULES](UNKNOWN_AND_SERVER_ONLY_RULES.md),[RESEARCH_PROGRESS](RESEARCH_PROGRESS.md) |future owner checks,source fidelity,access limits,remaining work and resume checkpoints |

Source ledgers accompany the economic, navigation, fishing and specialty batches. [SOURCE_COVERAGE.jsonl](SOURCE_COVERAGE.jsonl) retains every module's review contributions; [coverage method](SOURCE_COVERAGE_METHOD.md) and [summary](SOURCE_COVERAGE_SUMMARY.json) separate complete-body, catalog, core and targeted reviews from metadata-only inspection. No full game script/bytecode or private account snapshot is saved.

## Category coverage

| Category | Completed depth | Material remaining |
|---|---|---|
| Entire ReplicatedStorage |complete hierarchy,count reconciliation,701 source attempts;626 metadata extractions |75 failed dot-path reads; metadata-only scripts still need semantic review if relevant |
| Eggs/pets/currencies |systematic normalized218/2166/49 catalogs;core native cost/stat/luck/variant/enchant/team/stack/hatch/equip review |authoritative final RNG/variant order,recipe inheritance,outcome credit and live earning samples |
| Worlds/navigation |native world/area/cost/travel/trampoline/portal/sell/pickup geometry;focused physical scene observations |live unlock/travel/persistence acceptance,changing physical access,actual timings |
| Mastery/equipment |category schemas/all category counts,selected important tiers,native next-tier/cost/received effects,gum/flavor math |full machine-readable tier normalization,station/server guard and measured marginal benefit |
| Rewards |principal claim paths,timers,WorldRewards arithmetic,wheel,index,milestone/perk/pass semantics |all alternate wheels/prizes/XL task/daily stock normalization,server grants and resets |
| Quests/vendors/consumables |builders,Genie/seasonal task generation,stock/discount/refresh,currency purchase,craft/single+bulk use |generic quest completion/grant timing,physical server vendor range,damaged stock sub-expression,all item/offer catalogs |
| Rifts/seasonal/specialty |Rift lifecycle/summon/chest/gift,XL/bounty,event mechanisms,Halloween upgrade/rebirth,TrickOrTreat,Shrine/conversion |live event deadline/eligibility,server effects/bulk semantics and protected reset/consumption results |
| Fishing/minigames/board/Obbys |focused catalog/helper/client-FSM/claim/geometry research |damaged probability/modifier branches,live completion/consumption/XP/reward behavior and actual timings |
| Runes/fragments/Supers/guilds | rune recipes/queue/counts; exact fragment accumulator positions/completion; team Super coefficients; guild max-per-stat factors and time/snapshot conditions | server expiry/caps/reset/craft grants, Green Luck threshold, Burst/duplication consumers, guild XP earning and reward-band fidelity |
| Architecture |complete local22-module foundation audit plus bootstrap/config/docs;native LocalData/Remote and dependency map |approved implementation design/tests,semantic invalidation and owner acceptance later |
| Peripheral UI/framework/assets/history |every object inventoried;source metadata where readable;relevance triage |not a complete animation/render/social/trading/monetization/framework deep audit |

## Most valuable confirmed findings

1. Native team currency composition starts at1 and adds each equipped unit's `(petStat-1)`; general team utility must retain stack quantities. Percent BuffUtil adds `Value/100` to the supplied base. Multiplying every pet/buff label independently is wrong for these helpers. [Economic evidence](ECONOMY_AND_ROI.md)
2. Premium egg labels do not guarantee a uniform proportional useful-outcome advantage. Creaking variants have unequal outcome changes; the correct comparison depends on the desired result and cost. Catalog weights and client transformed odds still differ from authoritative sampling. [Pet evidence](EGGS_AND_PETS.md)
3. Native vendor BuyAll and potion CraftAll use booleans, with no confirmed arbitrary chosen-quantity purchase/craft interface. Bulk UsePotion separately supports an explicit count and250 client cap. A future budget cannot blindly wrap these actions. [Contracts](SHOPS_QUESTS_AND_CONSUMABLES.md)
4. Playtime claims use a sparse string-indexed claimed map; paid WorldRewards use next Progress+1 and cost increasingly large currency amounts. A function named Claim does not mean free. [Reward evidence](REWARDS_QUESTS_AND_EVENTS.md)
5. Rendered physical gift IDs go to ClaimGift; Rift model names go to ClaimRiftGift. Likewise unlocked travel,paid world unlock,island discovery and approach are separate contracts. [Specialty](SPECIALTY_AND_SEASONAL_SYSTEMS.md),[navigation](WORLD_AND_NAVIGATION.md)
6. LocalData has received-state and pet-sequence integrity behavior; metadata/animation/request dispatch cannot replace consistent account results. Native Remote multiplexes labels through its child event/function. [Schemas](DATA_SCHEMAS.md),[dependencies](SYSTEM_DEPENDENCIES.md)
7. Current OC egg comparison uses the equipped-team baseline; current active farming uses goal-first Decide rather than historical CompareIncome. These are local-source research findings and future correction candidates only. [Local evidence](LOCAL_ARCHITECTURE_EVIDENCE.md)
8. Rune bonuses, fragment counts, Super effects and guild perks enter different native accumulators. Guild perks take the maximum unlocked factor per stat; rune crafting time scales with count; all four fragment colors must reach 250 for the completion helper. Saved Green Luck and guild reward-band branches have fidelity limits. [Stat dependency evidence](STAT_DEPENDENCY_EXTENSIONS.md)

## Ten promising future improvements

Ranked qualitatively by potential value,evidence quality and enabling value; no personalized numeric return is asserted. “Strong source” means definition/caller evidence,not live server acceptance. Each proposal needs the indicated approval and owner checks.

| Rank | Improvement / potential value | Evidence quality and critical limit | Later consumer/phase |
|---:|---|---|---|
|1|Best feasible owned-team benchmark before pet spend: capture free equip gains, preserve stacks, model coupled enchants/equipped Supers and caps |strong team/caller evidence; some PetUtil math damaged; candidate-team cache isolation and received guild factors matter; [stat dependencies](STAT_DEPENDENCY_EXTENSIONS.md) |PetPolicy/GameKnowledge;Phase4 explicit approval |
|2|Evidence-qualified capability and verified-result ledger: prevent catalog-as-live,animation-as-grant and uncertain spend retries |strong native/local data/dispatch/state evidence;server acceptance unknown |existing reader/cache,Brain,scheduler/mechanics;incremental Phase1–9 approvals |
|3|Selective Mastery prerequisite packages: free Playtime/equips/map/craft/claim capabilities can improve several goals |strong tier costs/UI/received effect schema;no account ROI measured |UpgradePolicy/Brain;Phase5 approval |
|4|Due reward scheduling by actual eligibility and interruption cost: sparse Playtime,daily,wheel,chests/index |strong principal claim shapes and deadlines;partial/bulk server results unknown |existing scheduler;Phase5 approval |
|5|Goal-time investment evaluation with hard reserves and committed costs: include cheap acceleration without unbounded spending |source-supported costs/stat inputs plus rigorous conditional math;actual rates/soft override policy missing |UpgradePolicy/FarmingPolicy;Phases3/5,explicit exception authorization |
|6|Egg selection by marginal useful improvement and full action time: compare owned-best baseline,conditional probabilities,travel and verification |systematic catalogs/native throughput;final RNG,team optimizer quality,live time missing |PetPolicy/HatchManager;Phase4;hybrid overlap deferred Phase9 |
|7|Quest overlap planning: favor filtered tasks already advanced by authorized actions,with deadlines and no double-counted rewards |strong builder/progress/caller evidence;completion/grant semantics partly unavailable |Brain/TaskScheduler;Phase6 approval |
|8|Boost/vendor/enchant/rune budgets timed to productive use: protect offers, use-count horizons, serial craft time and fragment completion thresholds |strong count/cost/guard/queue evidence; stock/odds fidelity and server cap/reset/depletion limits; [stat dependencies](STAT_DEPENDENCY_EXTENSIONS.md) |Upgrade/Pet policies,existing mechanics;Phases4/6 approval |
|9|Expiry-aware Rift/XL/bounty opportunity queue: only reachable eligible targets with enough productive lifetime/material budget |strong lifecycle/summon/key/rotation call sites;server odds/access/results unknown |GameKnowledge+world observations→Brain/scheduler;Phase7 approval |
|10|Fishing/journal and seasonal progression objectives: separate currencies/FSM/location ownership,active registry and protected resets |focused catalogs/callers;damaged catch math and reset server effects unknown |same Brain/scheduler;Phases7/8 approval |

The integration document additionally ranks architecture dependencies. This table ranks overall opportunity candidates. Neither list starts implementation.

## Phase-by-phase application later

| Phase | Apply this knowledge | Approval / acceptance boundary |
|---:|---|---|
|1|typed received facts,evidence/provenance and readiness;cache/verification clarity |preserve owner-tested foundation;future changes require scoped tests/approval |
|2|currency units,reachable stationary pickup observations and attribution-aware rates |approved stationary farming preserved;no movement toward pickups |
|3|native prerequisite graph,paid unlock vs unlocked travel,goal-time funding models |owner authorized progression;new unlock/travel still need live verification |
|4|best-owned teams,stacks/enchant utility,egg probabilities,cost/storage/timing/intentional location |explicit approval still required;this research changes nothing |
|5|meaningful Mastery packages and actually eligible rewards;new-account benefit/reserves |not initiated;explicit implementation approval and owner results required |
|6|quest overlaps,stock/refresh,currency budgets,craft/use timing and safe contracts |not initiated;requires approved prerequisites and acceptance |
|7|timed Rift/XL/bounty,fishing/minigame/board/Obby opportunities |not initiated;exact access/result/location/cancellation contracts verified first |
|8|mechanism-specific seasonal registry,deadline/buffs/facilities,protected reset decisions |owner reports Halloween;catalog dates/Active flags insufficient;destructive actions separately authorized |
|9|comparative opportunity scorer,total-time budgets,hysteresis,preemption and optional hybrid overlap |advanced hybrid farming deferred until explicit approval;one Brain/scheduler |

## Unfinished research and owner evidence

The complete deep audit of every script has **not** been claimed. The 75 inaccessible paths, 443 metadata-only reviews and decompilation defects remain explicit. Remaining semantic/catalog work is listed by category above and in [progress](RESEARCH_PROGRESS.md); [exact remaining paths](inventory/REMAINING_SEMANTIC_REVIEW.jsonl) support resuming without repeating completed inspections. Authoritative server formulas, live eligibility, actual credit/consumption, cooldowns/persistence and measured earning/action times require future owner testing. [Unknowns and future verification matrix](UNKNOWN_AND_SERVER_ONLY_RULES.md) specify the missing evidence.

Preservation validation and final coverage totals are recorded in RESEARCH_PROGRESS.md. Everything is saved under `docs/research/replicatedstorage/` in the existing local project. No GitHub/Vercel synchronization was attempted.

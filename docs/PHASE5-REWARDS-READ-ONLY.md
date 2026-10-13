# Phase 5 — read-only reward intelligence

This is the next owner-authorized independent component from [the entry plan](PHASE5-ENTRY-PLAN.md). It preserves the published Mastery planner `60e794e0fe87` and every existing production method. No claim, item use, purchase, movement, hatch, equipment change, farming or spending is authorized or executed.

## Reuse and integration

The existing `RewardsManager` coordinates only playtime and ordinary Mystery Box operations. Its methods, receipt ledger and execution guards remain unchanged. New intelligence reads only its exact-account `GetStatus()` pending/attribution observation; zero local counters never establish native unclaimed state, and unresolved timeouts never permit a retry.

`GameKnowledge:RewardContext()` reuses the existing reader's verified LocalData accessor, snapshot/revision checks and dependency cache. It requests only missing static Shared definitions and reviewed pure getters through the existing cache lifecycle, without enabling action flags or loading client reward frames, effects or remotes. Catalogs still loading remain UNKNOWN. Detached facts and native getter observations are rechecked for identity, revision, age, profile and definition changes.

The new pure `RewardPolicy` is owned by `OCBrain:AnalyzeRewards()`. Explicit `OCController:GetRewardPlan()` and `PrintRewardPlan()` APIs expose it. Existing Mastery methods, Brain gameplay arbitration and TaskScheduler are untouched; the report submits no task and starts no competing loop. `REWARD_INTELLIGENCE_SETTINGS.ENABLE_REWARD_INTELLIGENCE` defaults false. The separate safe loader enables intelligence while keeping controls STOPPED and all gameplay flags/budgets OFF.

## What the report distinguishes

Every row includes family, observed status, eligibility, claim state, prerequisites, cost, possible benefit, uncertainty and Mastery interruption. `DUE` can mean an observed client deadline or completed requirement while interaction/grant eligibility remains UNKNOWN. It is never execution permission.

| Family | Supported intelligence and limits |
|---|---|
| Free playtime | Native gifts, received cycle and exact string-index claim map, received capability, Trading Plaza restriction and native elapsed time. False-but-present keys are claimed. Missing maps, malformed absent-key inference or clocks remain UNKNOWN. |
| Free daily Stars | Explicit received claim boolean, current native UTC day and streak state. Prior-day lost streak is LOCKED with recovery UNKNOWN. Catalog day gifts are associated descriptions, not proof that the Stars action grants them. No rollover or forfeit simulation. |
| Free wheel ticket | Explicit received deadline against native time. Free ticket collection is separate from consuming tickets, spinning and settling the wheel queue. Queue state remains UNKNOWN. |
| Achievement prizes | Native key/requirement/reward, exact received claim map and reviewed native progress getter. These are separate from ordinary quests. Missing progress baselines stay UNKNOWN. |
| Paid World Rewards | Received sequential progress, current native world definition, strict true unlock, next fixed price, explicit currency reserve and native pet-space observation. Removed worlds are LOCKED; event activity/missing definitions remain UNKNOWN. No paid track completion or purchase permission. |
| Chests | Received cooldown deadline, native location representation and map-area access observations. Physical registration/interaction stays UNKNOWN. Catalog presence or a location part is not an interactive chest; composite cooldown/payout is not invented. |
| Ordinary quests | Received tasks/progress and native exact-equality requirements. History is separate from current completion and credited grants. There is no established generic ordinary quest claim; activity cost and interruption remain UNKNOWN. |
| Consumables | Explicit Powerups map and native Potions records/owned-amount getter. Optional potion level stays exact; it is never replaced by an invented level. Stock is separate from use/queue/effect eligibility and is never a free claim. |
| Challenge Pass | Native catalog identity/deadline, received rewards, exact sparse claimed tier values and native point threshold where observed. Expired definitions are distinguished from unresolved pending operations. Reset, skip, premium and receipt rules remain separate. |
| Season, Index, milestones | Explicit UNKNOWN coverage rows until their complete track/mode/grant contracts are separately normalized. Discovered history is not owned inventory or proven reward receipt. |

Statuses are AVAILABLE, LOCKED, DUE, CLAIMED, EXPIRED, PENDING and UNKNOWN. Missing whole claim data is never interpreted as unclaimed. Report bounds explicitly count omitted rows; omitted rewards are not declared ineligible or complete. The native server clock drives deadlines and UTC day, while monotonic snapshot time drives freshness; they are not substituted for each other.

Possible benefits retain declared native items/pools with actual payout, final odds, marginal earning gain and receipt UNKNOWN. No wiki amount, fabricated rate, currency conversion or guaranteed reward value is inserted. Incomplete permanent Mastery keeps paid World Rewards deferred. Free due rewards may complement it, but setup/presentation interruption remains UNKNOWN without evidence. Consumable compatibility can also be UNKNOWN rather than inherently harmful; ownership alone supplies no use authorization.

## Evidence reused

- [Native rewards](research/replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md), [quests/consumables](research/replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md), [account schemas](research/replicatedstorage/DATA_SCHEMAS.md), [action contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS.md) and [navigation contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md).
- [Reward strategy/distinctions](research/wiki/REWARDS_SHOPS_AND_QUEST_STRATEGIES.md), [native/wiki conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md) and [future improvements](research/wiki/FUTURE_OC_IMPROVEMENTS.md).
- [Narrow native schema addendum](PHASE5-REWARD-NATIVE-GAP-ADDENDUM.md) records exact source ranges and excerpt hashes for actual unresolved daily/prize/pass/inventory/chest gaps. Broad research was not restarted; no original native extract or private live account data is published.

## Offline verification and preservation

Build `7d374c2879a3`, immutable candidate tag `phase5-rewards-7d374c2879a3`.

`node scripts/build.mjs` and `node scripts/test.mjs` PASS: official Luau compilation, all 684 baseline regressions, all 90 preserved Mastery audits and 102 new actual-source synthetic reward cases. Coverage includes all report states, absent/malformed/sparse claims, false presence, clock/account/revision races, genuinely yielding getters, world access/price/reserve/storage, native potion shape, pending non-retry barriers, interruption uncertainty and the full STOPPED zero-action loader. Existing native receiver, pricing, allowance, hatch receipt, movement, standing safety and distribution suites remain passing.

The [separate source preservation record](PHASE5-REWARDS-SOURCE-PRESERVATION.json) and [exact source additions](PHASE5-REWARDS-READ-ONLY-ADDITIONS.patch) pin one new pure module and four exact append-only blocks against commit `7e833f94a1d2ff4011be3bdc74fcea0d10e30efc`. Removing those additions reproduces every existing production byte. Mastery source/evidence, its complete loader, all 90 fixtures and historical approval records remain exact. The Mastery and five prior hatch/movement/receiver release pins remain immutable. The latest raw owner log/private commit remain local and excluded from publication ancestry.

The [complete safe loader](../examples/Phase5RewardsReadOnly.luau) reports facts only. An initial call may return UNKNOWN while dependencies load; explicit later report calls reuse the cache. This delivery requests no new gameplay test and does not claim live reward acceptance or full Phase 5 completion.

Next smallest milestone: separately scope a dry-run eligibility/authorization/receipt contract for one free reward family, with fresh claim-plus-grant correlation, cancellation and unresolved-pending stop conditions. Preserve the existing coordinator rather than treating each family as a generic claim. Any actual claim or consumption still needs separate authorization.

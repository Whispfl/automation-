# Approved Common Egg functional exception — disabled candidate

Build **100f2c1907ae**, immutable candidate tag **phase4-hatch-100f2c1907ae**, development branch `codex/phase4-test-b`. This implements the owner's exact reviewed patch and remains **disabled for paid activation**. No native hatch, settings, inventory, equipment or spending action was executed during development. Actual pet receipt and full Phase 4 acceptance remain owner-pending.

## Authority and exact implementation

On October 13, 2026 the owner explicitly approved `docs/PHASE4-FUNCTIONAL-HATCH-EXCEPTION-PROPOSED.patch`, SHA256 `4dc7fc10a1532a2c6be2d7ef5c5e5f9fffc97fd699185098f985bc4da6d65e9d`, at review commit `56c8e7eba1653929edaa4b2c87683961879aef23`. This approval permits implementation/publication of the disabled exception, **not the paid hatch**.

Fresh Notion fetches reconfirmed the [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363), and [Phase 9/testing](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358). Latest returned edit times remain `2026-10-12T19:05:43.587Z`, `19:06:12.841Z`, `19:05:47.249Z`, and `19:05:51.517Z`. Mastery-first future priorities do not authorize additional systems or general reserve/economic changes here.

Both completed libraries were reused, not regenerated: [native eggs/pets](research/replicatedstorage/EGGS_AND_PETS.md), [native economics](research/replicatedstorage/ECONOMY_AND_ROI.md), [native source ledger](research/replicatedstorage/ECONOMY_SOURCE_LEDGER.md), [Common Egg facts](research/replicatedstorage/catalogs/EGG_FACTS.jsonl), [pet base stats](research/replicatedstorage/catalogs/PET_BASE_STATS.jsonl), [wiki/native conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md), and [ROI framework](research/wiki/ROI_DECISION_FRAMEWORK.md). They support complete pool projection, feasible owned-team comparison, quantity/stack/native storage rules and explicit server/outcome uncertainty. The [first-hatch audit](PHASE4-FIRST-HATCH-PREPARATION.md), [native Test B evidence](PHASE4-TEST-B-NATIVE-EVIDENCE.md), [classification delivery](PHASE4-RECEIVER-CLASSIFICATION-DELIVERY.md), and [historical auto-delete audit](PHASE4-NATIVE-AUTODELETE-RESOLUTION.md) remain unchanged history.

The owner-live-confirmed `f4e10f71c317` milestone remains preserved at commit `55bf4cf437cccd826180519c482bdc6edbbbb51b` and its original tag. Owner report: full read-only Common Egg preflight passed at 09:41:25 on October 13, native receiver/nearest registration was verified, physical arrival was 3.41 studs, and the current observed client auto-delete map was empty after the owner's manual preferences change. Those observations are not paid authorization or permanent account/session constants.

`git apply` applied only the exact reviewed patch. New [separate approval record](PHASE4-APPROVED-FUNCTIONAL-EXCEPTION.json) records the original patch text/hash, immutable review baseline, four reviewed method hashes, the new helper and these three whole-file differences:

| Runtime file | Before SHA256 | Approved after SHA256 |
|---|---|---|
| OCConfig | `0e252124807c0f853ec5badcf29621653a9e7a52f510b9c680c825d2f896d2f6` | `572779a5762093608b27a0517b8b3b544e28eb2ddf5ca44e8a6008871fe866cd` |
| PetPolicy | `2f7cbbf27bea3aed356b2b10397f05ad5b168a6c7d5cf17c1448b9bfe059614f` | `74d569e58cad6306bf54a3ba69861feadfcb13901faffc7eff7e1e34a410d441` |
| OCBrain | `65395cdde2c8d9260a92047a5b1c7c572a667a77af70ddba907dfeead4b99c61` | `4c106958fa68cd9d006d9a2c273e5dedae9ecac54f69c71b77e04ff72d3696ca` |

No additional runtime changes were needed. All **24 other source files** remain byte-identical to the review commit: GameKnowledge, every movement/arrival method, full PetManager/Prepare, HatchManager, allowance accounting/ledger, native transport, scheduler and reader are unchanged.

## Behavior and safety scope

`OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST` defaults false. When false, normal usefulness, owned alternatives, reserves, budgets and all existing economic decisions remain unchanged. The positive/zero marginal values, pool probabilities and benchmark are not rewritten to make this test appear useful.

Only a separately activated, authorized account-bound test may bypass the supported zero-gain rejection: one loaded/accessible ordinary Common Egg in The Overworld, native Coins price >0 and <=10, one count/request, all four explicit price/session/allowance ceilings >0 and <=10, complete finite supported team/pool projections, unconsumed isolated allowance and current funding/capacity/duration evidence. Invalid explicit functional scope blocks even a positive-gain candidate.

Exact selected Instance, current receiver membership/loaded state, independent native interaction and visual prerequisite, all-name nearest rules, native auto-delete disabled, fresh account/profile/config equality, native pricing, digital storage, cooldown/presentation, reserves, cancellation and final guard rechecks remain mandatory. The exception does not select a model by its name/path, grant interaction to noncatalog originals, change a quote, or create another transport/scheduler.

Actual owner economic ExpectedIncrement remains unproven: Common Egg retains rare King Doggy/Timberdoodle in the full native pool. This exception permits a bounded functional purpose where supported marginal gain is zero; it does not claim that this account necessarily has zero gain, useful income improvement, or final server odds.

The existing same-VM allowance is consumed before invoking the existing adapter. Confirmed receipt requires both selected egg counter growth and matching received inventory/stack quantity growth. Invocation, animation, counter alone or net Coins change alone is not successful receipt. Uncertain transport or timeout retains consumption and permits no retry. Equipment remains disabled after receipt. The hatch session ends, while the controller may continue read-only status/analysis. Restart/rejoin may lose the shared ledger; durable persistence is not claimed.

## Validation

- `node scripts/build.mjs`: generated the two standalone bundles and matching candidate pins; deterministic distribution checks pass.
- Candidate `dist/OC.lua` SHA256: `14da5d26f543c0c1d3e9d51e946f21baafe78379502cc05e9954de864ef161e0` (699111 bytes). All **104 completed research files** also compare byte-identical against the earlier recovery snapshot.
- `node scripts/test.mjs`: official Luau compilation, all **684 main regressions**, **69 guarded Test B checks**, and **11 functional groups / 73 targeted scenarios** pass on the implemented candidate.
- Tests cover positive and zero gain, flag-OFF ordinary policy, wrong account/egg/world/currency, invalid isolation/counts, >10 ceilings, incomplete estimates, missing registration/assets, ties/nearer eggs, active/missing/malformed auto-delete, native capacity/cooldown/idle/price changes, cancellations/final races, stacks, uncertainty, consumed same-VM allowance and no repeat/equipment.
- The complete disabled loader is compiled and exercised through actual defaults/controller/planner merge with all action permissions false, account ID zero and monetary budgets zero. The existing validator requires positive equipment command-count limits; its inactive limit is 1 while both equipment permissions remain false. No validator or gameplay change was made to accommodate the loader.
- **28 new exact-approval preservation checks** reject broader source edits, changes to frozen modules, forged/expanded approval metadata, changed patch bytes and rewritten historical records. Three whole-file transforms/four reviewed methods/new helper match exactly.
- **All ten historical Test A hashes verify**: eight current checks unchanged, with the previous membership correction and newly approved exact PlanPets difference recorded separately. Original historical records and release tags were not overwritten to claim byte identity.
- Existing **13 membership**, **18 exact classification**, **seven receiver/price preservation areas**, and **67 native identity** checks pass.
- The separate historical review harness reconstructs review commit `56c8e7e`, reapplies the approved patch in memory, passes **684 cases**, and proves all **29 current runtime/bundle files** unchanged by that offline test. It is not live gameplay evidence.

Logs remain local/ignored: `.test-output/phase4-approved-functional-tests.log`, `.test-output/phase4-approved-functional-historical.log` and preservation/public verification reports. Completed research and prior approval/proposal documents remain byte-identical. Public verification checks the actual commit/tag/raw bytes anonymously after publication, including the preserved `f4e10f71c317` and earlier pins; the final handoff provides its result and implementation commit.

## Disabled distribution and next checkpoint

[Full disabled candidate Config + loader](../examples/Phase4CommonFunctionalDisabled.luau) uses [the pinned bundle](https://raw.githubusercontent.com/Whispfl/automation-/phase4-hatch-100f2c1907ae/dist/OC.lua). It explicitly sets the functional flag, allowance, AUTO_HATCH and AUTO_EQUIP false, account ID 0, hatch/allowance/session spending ceilings 0, and all unrelated automatic actions off. Travel/positioning is also disabled in this loader. Central general farming defaults are preserved by the exact patch and overridden off here.

This is a reviewable disabled candidate, not an instruction to repeat the already-passed registration test or enable a paid loader manually. The existing prepared OneHatch example remains flag=false/account=0 and is also disabled. Historical original tags retain their own artifacts.

**Next owner checkpoint:** separately and explicitly authorize one Common Egg request/count=1, at most 10 Coins, on a specified account after reviewing this disabled delivery. Only then can an account-bound activation loader be prepared. No automatic activation or paid hatch is authorized now; Phase 4 is not complete.

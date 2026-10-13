# First real Common Egg hatch — preparation and conditional approval proposal

Date: 2026-10-13. **Preparation only. No paid activation, native request, settings change, equipment action or spending occurred.** Production source, bundles and existing loaders remain unchanged. There is no new runtime release.

## Authority and owner-live milestone

The latest owner directive is attachment `C:\Users\rmger\.codex\attachments\8b220962-512e-4a9b-998e-0079e06d1261\Pasted text.txt`, titled `OC PHASE 4 — FIRST REAL HATCH PREPARATION`, SHA256 `c26495bd4b0e86c044e9dbf052090875bb167c9d0e250dcd94f1c292a6c93b48`. It authorizes review, offline fixtures and preparation; actual paid activation and economic-policy changes require separate owner approval.

Freshly reconfirmed [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363), and [Phase 9/testing](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358) retain the latest returned October 12 owner notes. Mastery-first future policy does not expand this isolated test into world/Mastery work. One Brain/scheduler, owner-only live testing and read-only Studio remain required.

The owner reports a full live preflight pass at **09:41:25, October 13**, on runtime commit `55bf4cf437cccd826180519c482bdc6edbbbb51b`, build `f4e10f71c317`, tag `phase4-hatch-f4e10f71c317`:

- `HATCH_PREFLIGHT_READY_ALLOWANCE_OFF`, Common Egg native price 10 Coins, storage 1926/1000000, digital true, EggsOpened 2, cooldown attribute absent.
- Exact native `CURRENT_EXACT_REGISTRATION_OBSERVED` / `OPENED_NEAREST`, 87 updates entered/completed, one qualifying receiver and trusted selected membership. Physical arrival was 3.41 studs.
- The owner manually disabled three native deletion rules and observed a ready AutoDelete table with zero entries. OC did not change those preferences. Future preparation still checks current settings again.
- Zero hatch requests and spending. Session ID `I0036` and balance 7267071 are observations, not constants.

**Read-only preflight is OWNER-LIVE-PASSED. Actual hatch receipt is not tested.** This new evidence supersedes the earlier missing-field observation limit without rewriting the historical [auto-delete audit](PHASE4-NATIVE-AUTODELETE-RESOLUTION.md).

## Reused research and exact decision evidence

No full registration investigation or research cycle was repeated. The following completed files support the decisions:

- [Native eggs/pets](research/replicatedstorage/EGGS_AND_PETS.md), particularly GetEggPool/Secret display separation, native account/storage/stack rules, physical identity, and server-only limits.
- [Native economy/ROI](research/replicatedstorage/ECONOMY_AND_ROI.md) and [source ledger](research/replicatedstorage/ECONOMY_SOURCE_LEDGER.md): use the feasible owned benchmark and native full-team projections; client estimates are not final server odds or income.
- [Common Egg catalog facts](research/replicatedstorage/catalogs/EGG_FACTS.jsonl), source line 46, and [pet base stats](research/replicatedstorage/catalogs/PET_BASE_STATS.jsonl): retain every pool entry, including rare Secrets.
- [Wiki conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md), [future ROI framework](research/wiki/ROI_DECISION_FRAMEWORK.md): historical/UI descriptions cannot certify the account's marginal gain or server receipt.
- [Test B native contracts](PHASE4-TEST-B-NATIVE-EVIDENCE.md), [receiver classification delivery](PHASE4-RECEIVER-CLASSIFICATION-DELIVERY.md), original Test A manifest, and both separately approved correction records: preserve identity, opened all-name nearest, native price and movement.

## Usefulness audit: readiness and permission are separate

| Owner question | Verified code behavior |
|---|---|
| Will the existing workflow hatch with zero Common Egg improvement? | **No.** `PetPolicy.EggBlocker:489` returns `NO_USEFUL_IMPROVEMENT` for ExpectedIncrement <= 1e-6. `OCBrain:PlanPets:114–118` applies that blocker and an additional increment/target check. |
| Does the allowance override usefulness? | **No.** `OwnerHatchTestAllowance.EffectiveFunds:92–137` and `PetPolicy.FundEgg:360–365` change only capped currently held future-world Coins availability. Configured resource reserves and other guards remain. |
| Can READY coexist with WAIT? | **Yes.** `ReportHatchPreflight:293–315` checks native interaction/basic readiness, not economic usefulness or reserve authorization. Both are necessary separately before paid execution. |
| Can a forced or stale HATCH decision bypass this? | **No.** `PetManager:Prepare:610–617,649–655` recomputes the actual Brain decision twice from fresh account context. |
| Did earlier positive tests model this owner? | **No.** Earlier fixtures use weak synthetic teams and an artificial guaranteed improving pool. The new seven-pet fixtures test both zero and positive marginal outcomes explicitly. |
| Does the reported current score 1752 establish NO_USEFUL_IMPROVEMENT? | **No.** It gives neither individual protected/team records nor actual current native projections for every full-pool outcome. |
| Could enabling the old loader yield no hatch? | **Yes**, if marginal gain is <=1e-6 or another independent guard fails. There is no fallback or automatic retry. |

Common Egg is not only its ordinary displayed pets. Its saved native pool is Doggy 40, Kitty 30, Bunny 25, Bear 5, **King Doggy 0.000001**, and **Timberdoodle 0.00000001**. Native base Coins are respectively 1.1, 1.1, 1.2, 1.5, **3300**, and 2. GetEggPool retains Secrets; LootPoolViewer hides them for display (`EGGS_AND_PETS` GetEggPool section, native viewer 496–529/629–631). OC does not copy that display exclusion into its pool.

`GameKnowledge:PetContext:504–519` projects replacements/additions using current native full-account/team helpers, respecting protected/Super membership. `PetPolicy.Egg:403–443` evaluates every nonzero-weight outcome against the feasible owned benchmark. King Doggy can make the conditional estimate positive; inaccessible replacement slots or native account projections can still make it zero. No actual owner ExpectedIncrement was supplied, so **an exception is not a confirmed required repair**. Neither a beginner label nor total team score alone proves this.

The new catalog-shaped mocked seven-pet test retains all six entries. Its explicitly synthetic additive score produces a tiny positive estimate above the existing threshold and the unchanged workflow permits one mock request. A separate complete zero-projection fixture reaches READY_ALLOWANCE_OFF yet returns WAIT. These prove both code branches, not this account's live result or final server probabilities.

## Conditional usefulness exception — NOT APPLIED

[Exact proposed patch](PHASE4-FUNCTIONAL-HATCH-EXCEPTION-PROPOSED.patch), SHA256 `4dc7fc10a1532a2c6be2d7ef5c5e5f9fffc97fd699185098f985bc4da6d65e9d`, and [before/after file and method hashes](PHASE4-FUNCTIONAL-HATCH-EXCEPTION-PROPOSED-HASHES.json) are review artifacts only. `git apply --check` verifies applicability without applying it.

It introduces the explicit false-default `OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST` and a pure predicate in PetPolicy. The proposed exception requires all of:

- Existing allowance explicitly enabled for the authorized current account, unconsumed same-VM ledger and existing isolated MANUAL one-hatch configuration.
- One ordinary, accessible, loaded Common Egg in The Overworld; native Currency/Coins price >0 and <=10; each explicit per-egg/session/allowance ceiling >0 and <=10; count/session/batch limits exactly one.
- Complete supported finite owned-team/pool estimate, no bounded-search/projection gaps, affordable authorized funds, native capacity available and valid duration.
- All unchanged fresh exact Instance, registration, opened nearest, visual, auto-delete, storage, cooldown/presentation, full account/config equality, cancellation, arrival, price and consumption checks in Prepare/transport.

Only the zero-usefulness rejection and duplicate Brain increment condition would admit this separately authorized functional purpose. Estimated gain stays zero where it was zero. An invalid explicit functional-test scope blocks even a positive-gain egg, and the false default leaves regular economics unchanged. One reporting expression names functional-test purpose rather than falsely calling zero gain useful.

Proposed source differences are limited to OCConfig, `PetPolicy.Egg`, `EggBlocker`, the new predicate, one `EggPlanText` expression, and the single economic condition in `OCBrain:PlanPets`. **Prepare, Allowance accounting, HatchManager, GameKnowledge, movement and transport are untouched even in this proposal.** No proposed setting is added to an active loader here.

This is an economic/protected-method change and requires owner approval before implementation. It also changes the whole-file OCBrain historical hash: any later approved implementation must record the precise method difference separately and add a narrowly bounded verification rule. The original Test A manifest and earlier sparse/classification approvals must not be rewritten or weakened. The supplied hashes are proposed differences, not approvals or new release identifiers.

There are two separate future gates: **approval to implement this contingency**, if desired, then **explicit account-bound paid activation** after the disabled implementation is reviewed. Approving this preparation does neither. The contingency can avoid a wasted functional acceptance session if real marginal gain is zero; it is unnecessary when current normal economic analysis already permits the hatch.

## Request, receipt and termination

The existing path already provides bounded result verification:

1. Prepare captures verified account/exact original/native price, current balances and counter, detached pet IDs/Amount/variant records, storage, equipped team membership, baseline and allowance evidence (`PetManager:720–757`).
2. The same-VM allowance is consumed and the one-request/cost ledger increments **before** the approved adapter invokes `HatchEgg("Common Egg",1)`. An exception or uncertain transport keeps that opportunity consumed.
3. `HatchManager:Observe:19–49` reads received LocalData and requires both the selected egg counter increment and matching full-pool inventory/stack growth. Animation, invocation, Coins debit, counter alone or inventory alone cannot confirm receipt.
4. New pet records and increased Amount on compatible existing stacks are both recognized. Results retain variants, counter deltas, before/after net balances and equipped team/index comparison. Excess counter movement or changed equipped membership faults continuation.
5. The default receipt timeout is 15 seconds. Missing/ambiguous receipt becomes UNCONFIRMED; there is no retry or reopening the request ledger after late data. The single request ends the hatch authorization permanently in that controller/VM ledger, with equipment disabled even after receipt.

| Requested category | Existing implemented evidence |
|---|---|
| `INVENTORY_GAIN_OBSERVED` | Actual HatchManager result: both matching inventory and counter growth. |
| `UNCONFIRMED` | Actual HatchManager result after timeout without both required observations. |
| `INVOCATION_UNCERTAIN` | Allowance record state plus retained uncertainty reason; it is not a separate HatchManager LastResult status. Later timeout can produce UNCONFIRMED. |
| `NO_REQUEST_GUARD_BLOCKED` | Conceptual description only: existing WAIT/blocker or LastAction.Requested=false, zero requested count/cost and unconsumed allowance. No new status name is invented. |

The adapter's boolean reports an **attempt**, not acceptance. `INVENTORY_GAIN_OBSERVED` also does not prove a useful improvement or exclude simultaneous external activity. Net Coins change is reported separately; concurrent credits/spending prevent certifying exactly 10 Coins was charged.

After the bounded hatch session ends, the controller can remain RUNNING for read-only status/analysis. It does not automatically call whole-controller Stop. No second hatch, equipment or unrelated action is permitted by the isolated configuration. Stop/Pause cancellation remains unchanged.

Before-storage evidence is captured; after-storage measurements are not retained in LastResult. Current reader/context can observe them separately, with the native digital-storage helper's five-second cache limitation. No new post-result storage field or fabricated instantaneous byte delta is added by this preparation.

Same-VM bundle reload cannot restore a consumed/unresolved allowance. Client restart/rejoin may lose the shared ledger; no durable persistence is claimed. An uncertain or consumed test must not be reactivated after restart on an assumption that no pet arrived.

## Verification and preserved distribution

The full current implementation passes official Luau compilation and **673 main-suite regressions**, including **58 Test B cases**: **12 new tests** over the previous 661 baseline. They cover zero/positive full-pool strong-team scenarios, reserve-only allowance, stale/target bypass attempts, final price/capacity/cooldown/presentation/stop changes, stacks, insufficient isolated receipt evidence, delayed/uncertain invocation, same-VM replay and account attribution. Existing identity/nearest/auto-delete/cancellation tests remain.

All **13 membership checks**, **18 exact classification checks**, **seven receiver/price preservation areas**, and original **ten Test A hashes** pass. The historical sparse-array exception remains separately recorded. Runtime/source/loaders/scripts/approval/research bytes are compared against the frozen commit; full regression checks also verify deterministic distribution integrity.

The **unapplied proposal** was separately tested by `node scripts/test-phase4-functional-hatch-proposal.mjs`. That review-only script applies exact hashed hunks to strings in memory, compiles three proposed module copies and an isolated mock harness under ignored `.test-output`, and never writes production source or a distributed bundle. All **673 current main cases** pass with the new flag off, plus **11 proposed-mode tests across 72 scenarios**: **684 total in that separate harness**. These are not an implemented release's results.

The proposed-mode matrix confirms exactly one mock request for zero-gain Common within the explicit scope; false/off, consumed, wrong-account/egg/world/currency/count, >10 ceilings, malformed/incomplete baseline/pool, unavailable registration/assets, ties/nearer other eggs, final nearer Common, auto-delete/storage/cooldown/presentation/price, cancellation and final permission/account/range changes remain blocked. Receipt and uncertain invocation retain no retry/equipment. [The targeted cases](../tests/phase4-functional-hatch-proposal.luau) and [reproducible review script](../scripts/test-phase4-functional-hatch-proposal.mjs) are published only as offline proof. All **29 production source/bundle files** hash unchanged before/after this script.

The broader preservation audit compares **161 frozen files**, including **104 completed research files**, against runtime commit `55bf4cf`; all are byte-identical. The previous auto-delete evidence document also remains identical to its earlier audit commit. The proposed patch passes `git apply --check` without being applied; its recorded before/after hashes match the exact reviewed texts.

`node scripts/build.mjs` reproduces build `f4e10f71c317` without byte changes. Bundle SHA256 stays `1ac819487fd763554caf659a3d299b8cfe83b7629ca98f6739c2519cacbdd1b4`. The immutable runtime release remains:

- Build `f4e10f71c317`.
- Tag `phase4-hatch-f4e10f71c317`.
- Runtime commit `55bf4cf437cccd826180519c482bdc6edbbbb51b`.
- [Complete pinned raw bundle](https://raw.githubusercontent.com/Whispfl/automation-/phase4-hatch-f4e10f71c317/dist/OC.lua).
- [Complete prepared disabled Config + loader](../examples/Phase4TestBOneHatch.luau), also available as [pinned public source](https://raw.githubusercontent.com/Whispfl/automation-/phase4-hatch-f4e10f71c317/examples/Phase4TestBOneHatch.luau).

That existing loader retains `OWNER_APPROVED_ONE_COMMON_HATCH=false`, `AUTHORIZED_ACCOUNT_ID=0`, hatch/allowance off, zero budgets and all other actions off. It contains **no functional exception** and must not be advertised as guaranteed to hatch a zero-gain team. No account ID is populated or automatically inferred. It is provided for review, not an instruction to activate or repeat the passed preflight.

Any publication for this request contains tests, the offline review script and review documents only. Public Git tree/raw-byte and historical-pin checks distinguish that review commit from the unchanged runtime release. Offline mock requests and receipts do not count as owner-live acceptance.

## Owner handoff

The first request/receipt machinery is prepared, but **the actual current Common Egg economic gate remains unproven**. Existing allowance cannot cure a real zero-gain blocker. The next single owner decision, if a functional test must proceed independently of marginal gain, is whether to approve the exact contingent patch for implementation. That approval would still leave paid activation for a separate subsequent decision; no spending is requested now.

Actual owner-live acceptance later requires a consumed single request plus newly received matching inventory/stack quantity and Common Egg counter delta, with unchanged equipped membership, no second request and no unrelated commands. Net Coins evidence is supplementary. Until that result exists, paid Test B and Phase 4 remain unapproved.

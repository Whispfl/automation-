# First owner-confirmed automated Common Egg hatch

Recorded on 2026-10-13 from the owner's direct report and subsequently supplied original console text. The supplied log begins at 10:56:33 and records receipt at 10:56:41 on October 13 (owner-specified date; console time zone not stated). This is a successful, isolated functional receipt test, not approval of ordinary economic hatching or completion of Phase 4.

## Evidence and immutable release

The [original owner-supplied console text](evidence/PHASE4-FIRST-LIVE-HATCH-100f2c1907ae-CONSOLE.txt) is archived unchanged as received: UTF-8, no BOM, no line reflow or added newline, 19627 bytes, SHA256 `0765815d70c439d9857d9ee3a3fa6390e346a9d65ff2bee7e9c8c1d900dd7df5`. The [complete original submission](evidence/PHASE4-FIRST-LIVE-HATCH-100f2c1907ae-ORIGINAL-SUBMISSION.txt), including its original delimiter and owner instructions, is also preserved: 20298 bytes, SHA256 `3be2f4e5be9c79f4054706f179e5d1b1a4ded5d92d0b74bf236e6d85e848451f`. The [archive manifest](evidence/PHASE4-FIRST-LIVE-HATCH-100f2c1907ae-ARCHIVE.json) records provenance and representation. These hashes certify the exact supplied text archives; no separate pre-upload filesystem attachment or original encoding was exposed. The original text was extracted from the direct human reply, not reconstructed from the result summary. No repeated hatch is requested.

The initial [verbatim owner report excerpt](evidence/PHASE4-FIRST-LIVE-HATCH-100f2c1907ae-OWNER-REPORT.txt) is retained separately (SHA256 `02f479fb58f3088266bb97a63c425c8baee6eba950af977bc7ce68a0102c5b10`). It is not substituted for the console archive.

| Observed result | Owner-confirmed value |
|---|---|
| Receipt state | `INVENTORY_GAIN_OBSERVED` |
| Request | Exactly one Common Egg, count=1 |
| Received inventory | Normal Doggy: +1 to an existing stack |
| Selected egg opened counter | +1 |
| Coins | Observed net change -10 |
| Equipment commands | 0 |
| Allowance/session | One-hatch allowance consumed; session ended without retry |
| Final approach | Owner manually approached Common Egg before the paid hatch |

The console independently reports `requested=1`, matching inventory +1, counter delta=1, selected session Instance `I0032`, expected price=10 Coins and observed net debit=10. At 10:56:43 it reports the bounded hatch authorization ended without retry. At 10:56:48 the controller is still `RUNNING` / `WAIT`, with hatches `1/1 received/requested`; **hatch session ended** does not mean the entire controller stopped. Later analysis reports 63 pets versus 62 before, the same 1752 native team estimate, and the consumed account allowance restoring ordinary reserves. The received Normal Doggy is explicitly `NO_CURRENT_TEAM_IMPROVEMENT`, native gain=0.

Actual logged test overrides were `AUTO_HATCH=true`, allowance=true, MANUAL Common Egg and egg/session budgets 10/10; equipment=false. They describe that consumed owner-run test, not current disabled publication defaults or renewed permission. A full activation Config was not included. The transient startup `NOT_LOADED` state cleared before receipt; it is not a current failure or a reason to rerun registration/hatching.

| Immutable artifact | Preserved value |
|---|---|
| Build | `100f2c1907ae` |
| Implementation commit | `aae628d9ac8f1941f9b0b92aaedc365be22fa6af` |
| Existing tag | `phase4-hatch-100f2c1907ae` |
| Bundle | [Pinned public dist/OC.lua](https://raw.githubusercontent.com/Whispfl/automation-/phase4-hatch-100f2c1907ae/dist/OC.lua) |
| Bundle SHA256 | `14da5d26f543c0c1d3e9d51e946f21baafe78379502cc05e9954de864ef161e0` |
| Bundle size | 699111 bytes; anonymous public HTTP 200/hash verification repeated for this record |

The original disabled publication, exact exception approval and before/after hashes remain in [the delivery record](PHASE4-FUNCTIONAL-EXCEPTION-DELIVERY.md) and [separate approval manifest](PHASE4-APPROVED-FUNCTIONAL-EXCEPTION.json). The release was published disabled; this later owner-run result does not rewrite that history. The assistant did not activate a loader or send a native hatch request.

## Action limits and receipt requirements retained

The approved functional exception is one explicitly authorized account, one ordinary Common Egg in The Overworld, one native request with count=1, at most 10 Coins, and an isolated allowance. It bypasses only the supported zero-gain rejection for this functional purpose. It does not turn Common Egg into an ordinary economic investment or grant further requests.

All other guards remain required: exact selected Instance; positive native receiver membership and loaded state; independent interaction/visual-asset verification; native nearest rules across eligible egg names; fresh account/profile/config and cancellation checks; native auto-delete disabled; independent price, affordability/reserves, storage, cooldown and idle presentation; allowance consumption before transport; and matching received inventory confirmation. Equipment is disabled. Uncertain dispatch or receipt consumes the allowance without retry. The same-VM ledger is not durable restart/rejoin persistence.

Receipt requires **both** selected-egg counter growth and matching name/variant inventory quantity or stack growth. Request return, animation, counter alone or Coins alone is insufficient. Source: `HatchManager:Observe` (lines 27–49), `PetManager` final guards and allowance consumption (lines 647–758), `GameMechanics:HatchEgg`, and [first-hatch preparation](PHASE4-FIRST-HATCH-PREPARATION.md). The reported Normal Doggy stack increase and counter increase satisfy this receipt criterion according to the owner report. Net -10 is an observed balance change, not independent server accounting excluding external credits/debits.

All distributed defaults remain disabled: `OWNER_ONE_COMMON_EGG_FUNCTIONAL_TEST=false`, `OWNER_ONE_HATCH_TEST_ALLOWANCE=false`, `AUTO_HATCH=false`, `AUTO_EQUIP=false`, account ID zero and spending budgets zero in [the disabled loader](../examples/Phase4CommonFunctionalDisabled.luau). This milestone authorizes no additional paid hatch, equipment command, purchase or claim.

## What passed and what remains

The first controlled Common Egg hatch receipt passed on this reported account/session/build. Earlier owner-live registration preflight `f4e10f71c317` and successful Test A movement `0d5caa499c8c` remain their own preserved milestones. The latest owner distinguishes successful travel on the brother's account from prior safe-standing failures on the owner's account. The previously withdrawn failed log is not evidence of failure in the successful Test A run.

The paid hatch used **manual approach**. It does not prove universal teleportation, an automatic approach on this account, arbitrary avatars, other surfaces/elevations, another egg, another world, or future rift/chest/shop interaction. Normal Doggy receipt does not prove a useful team improvement, best-team equipment acceptance, measured income gain, final server odds or ordinary hatch ROI. Full Phase 4 acceptance and later phases remain pending.

Next priority: the [universal movement reliability plan](UNIVERSAL-MOVEMENT-RELIABILITY-PLAN.md), with separate approval for any protected-method repair. No runtime/bundle/Config/release tag was changed to record this milestone, and no new gameplay build is issued. The [preservation report](verification/phase4-live-hatch-movement-plan-preservation.txt) checks all 47 runtime/source/bundle/loader files, 104 completed research files and 23 historical Phase 4 records against the release baseline and verifies the original milestone tags and console archive hashes.

## Sources reconfirmed

Latest accessible [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363) and [Phase 9 owner notes](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358) were freshly fetched before this work. Latest returned edit times were respectively `2026-10-12T19:05:43.587Z`, `19:06:12.841Z`, `19:05:47.249Z`, `19:05:51.517Z`. The new direct owner result supersedes older pending-receipt status, not the remaining checklists.

Existing research reused: [native egg/pet contracts](research/replicatedstorage/EGGS_AND_PETS.md), [native navigation/approach contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md), [wiki/native conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md), [ROI framework](research/wiki/ROI_DECISION_FRAMEWORK.md), and [future OC improvements](research/wiki/FUTURE_OC_IMPROVEMENTS.md). Current native behavior and owner results take precedence over historical wiki statements. Neither completed library was regenerated or modified.

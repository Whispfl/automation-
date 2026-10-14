# Owner wheel-ticket test handoff

Reuses the unchanged **668d0af6f157** bundle, immutable tag `phase5-free-wheel-ticket-668d0af6f157`, implementation commit `f4c495e2c3d313ed6666ff94dd34c384cc8a0631`. Bundle SHA256 `8746a146a17c51114e1e56349b09f79b48cf90f7191f86f3a593b34c87738090`. No replacement gameplay build or protected-method change.

Owner handoff pin: `phase5-wheel-preflight-668d0af6f157`. Build and official Luau compilation PASS; complete suite retains all **684** baseline regressions, **90** Mastery, **102** reward-intelligence and **100** wheel contract checks, plus **49** new actual-loader/pinned-source preflight checks. These prove offline behavior only. Exact source/bundle preservation and anonymous publication checks are required before delivery.

The [complete preflight loader](../examples/Phase5FreeWheelTicketPreflight.luau) is runnable now in the owner's existing supported client runtime. It keeps OC **STOPPED**, has no Start button, and leaves claim permission false, account authorization zero, test ID empty and idle authorization false. All other actions and spending ceilings are OFF/zero. It will not replace an active OC or unresolved reward operation.

It reads the existing GameKnowledge wheel context and native interaction getters, with at most 15 readiness observations. A detached observation argument opens the knowledge reader's existing read gate; it never changes actual Config permission or invokes reward selection/preparation/transport. Existing native getters may yield. Complete coherent ticket data, native due deadline, absence of AutoClaimSpin, zero active gifts, idle presentation, exact account/ledger ownership and an unused attempt barrier must be observed. Missing facts remain blocked. It prints no account ID, balances or inventory baseline.

## Run now: observation only

1. Stop other automation. If any earlier claim is uncertain, keep its ledger and report that uncertainty; do not reload to evade it.
2. Manually stand at the normal Overworld wheel. Close game menus; do not hatch, fish, open gifts, spin, claim or consume anything during this check.
3. Run the complete preflight loader once. Wait for `READY_FOR_SEPARATE_AUTHORIZATION` or `BLOCKED`. The character should stay still; the ticket count and free timer should not change because of OC.
4. Send the three `[OC][WHEEL_PREFLIGHT]` result lines, any error, and whether the native free-ticket timer is ready and the wheel is idle. A blocker needs diagnosis, not an uncertain claim retry. No command recapture is requested.

## Separate authorization checkpoint

`READY_FOR_SEPARATE_AUTHORIZATION` is a snapshot of observed prerequisites, **not** claim permission, a scheduler lease, server-proximity proof or proof of an empty native wheel queue. The owner must confirm wheel idleness and separately authorize **one `ClaimFreeWheelSpin` request on the chosen account**, with no spin, ticket consumption, paid purchase, other reward claim or movement.

After that approval, provide the account-bound activated loader using this same immutable implementation and its fixed single-attempt ledger. It rechecks all original guards through the existing Brain/scheduler. Authorization is consumed before transport; no retry or new test ID can rearm an uncertain operation in the same client runtime. Restart/rejoin persistence is not claimed. No activated loader is supplied here.

Expected authorized result: `CLAIM_AND_GRANT_OBSERVED`, the **actual** ticket increase and a received deadline advanced beyond native time. A single state change, animation or issued request is insufficient. Send the result/status and visible timer/ticket change; ambiguity, interruption or timeout stays pending and must not be retried. Known competing evidence blocks correlation; indistinguishable external grants and non-atomic observations remain limitations.

## Evidence and next tests

Reconfirmed Notion master and Phase 5/3/4/9 notes; reused the [entry plan](PHASE5-ENTRY-PLAN.md), [owner capture delta](PHASE5-OWNER-REMOTE-EVIDENCE-2026-10-14.md) at `83cae91dc2ffc69ae243fbdd5de58bde98270ce6`, [candidate contract](PHASE5-FREE-WHEEL-TICKET.md), native `REWARDS_QUESTS_AND_EVENTS.md` / `NATIVE_ACTION_CONTRACTS.md` / `DATA_SCHEMAS.md`, and wiki `REWARDS_SHOPS_AND_QUEST_STRATEGIES.md` / `NATIVE_VS_WIKI_CONFLICTS.md` / `KNOWLEDGE_GAPS.md` / `FUTURE_OC_IMPROVEMENTS.md`. Current received/native evidence has priority. Capture lists do not authorize actions.

After the wheel result, the next small authorized test is one eligible Playtime index, recording its return (or NOT_OBSERVED), claimed-index transition and matching received grant/cycle. Chests need physical eligibility and cooldown-plus-grant verification. The captured `DailyRewardsBuyItem` is a **paid Stars-shop action**, not a free daily claim; free daily claim acceptance remains unverified. Mastery testing requires a separate bounded purchase approval and level/effect-plus-debit verification. Existing command captures need not be repeated.

All historical hatch, movement, Mastery and reward pins/evidence remain preserved. No live operation has been performed by Codex and neither Phase 4 nor Phase 5 is declared complete.

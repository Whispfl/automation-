# Phase 5 free wheel ticket — protected integration proposal

Status: **UNAPPLIED / separate protected-method approval required**. Baseline: `701eafb1c2cfaaa73237235d0c255b59b2a3ef52`. This proposal is not an implemented or released candidate. No gameplay authorization or activated loader is supplied.

The owner authorized implementation and offline tests for `ClaimFreeWheelSpin`, subject to this explicit condition: **"If existing protected methods must change, provide the exact proposed diff and stop for separate approval."** That condition applies: existing reward construction rejects a wheel pending kind, observation routes non-playtime operations into Mystery Box handling, selection ignores the new family, and the adapter rejects its intent.

## Exact approval target

[The unapplied patch](PHASE5-FREE-WHEEL-PROTECTED-PROPOSAL.patch) changes exactly four existing methods in two files. It contains only the existing-method integration hooks. The referenced new helpers are intentionally not implemented yet; this patch alone is not a runnable candidate.

| Existing method | Exact proposed change |
|---|---|
| `RewardsManager.new` | Validate `FREE_WHEEL_TICKET` pending state through its own new validator, retain the existing validation for Playtime/Mystery Box, and validate/initialize the new account-ledger extension. Malformed state is preserved and blocks dispatch. |
| `RewardsManager:Select` | Call the new narrow selector before the legacy path. A nil ownership result delegates to unchanged legacy behavior. |
| `RewardsManager:Observe` | Route an attempted wheel pending record to its new read-only receipt observer before the legacy reward-delta/box handling. |
| `GameMechanics:RewardAction` | After existing scheduler, cancellation, interaction and transport guards, route only `FREE_WHEEL_TICKET` to the new native adapter. Preserve the old intent/command allowlists. |

New helper names in this exact patch are `ValidateFreeWheelTicketPending`, `InitializeFreeWheelTicketLedger`, `SelectFreeWheelTicket`, `ObserveFreeWheelTicket`, and `ClaimFreeWheelTicket`. No existing method will be replaced or overridden at runtime. New methods will be appended to the existing classes after approval.

The existing OCBrain already selects RewardsManager; OCController already submits its definition to the central TaskScheduler. Their methods, TaskScheduler, AccountStateReader, legacy reward preparation/dispatch/settlement, movement, hatching, selling and farming need no source changes for these hooks.

## Implementation contract after approval

- Append central `FREE_WHEEL_TICKET_SETTINGS`: action enablement false, authorized account 0, authorized test ID empty, owner idle confirmation false. A fixed one-attempt ceiling cannot be increased by Config. Missing or invalid authorization blocks execution.
- Add a narrow GameKnowledge observation method reusing `RewardContext`, verified LocalData and the existing dependency cache. Load only missing reviewed guard/transport dependencies once through that cache; loading remains UNKNOWN. Do not load the WheelSpin frame, invent a queue getter, force another action flag on, or add an observer loop.
- Require a coherent fresh account snapshot, due finite `NextWheelSpin`, validated native ticket inventory baseline and explicit absence of `AutoClaimSpin` in a fully valid received Mastery map. Unknown required state blocks. Native item getter and received Powerups must agree; an absent whole inventory never becomes zero.
- Use the existing account ledger's single `Pending` barrier. Retain a validated test-ID charge in a versioned ledger extension. A new test ID cannot bypass an unresolved operation. Disabled initialization with no wheel history leaves the legacy ledger unchanged. Unknown extension schemas are preserved rather than reset.
- Defer to an existing Playtime/Mystery Box pending operation. Block a wheel claim on existing unresolved attribution, known gifts/hatch/spin/other conflicting activity, invalid authorization, or unconfirmed owner idle conditions.
- Prepare detached before-facts, deadline, ticket baseline, account identity, coherent reader revision, definition/interface identity and known interference observations. Recheck exact scheduler token, generation, manager and pending identity after any yielding preflight.
- Charge the one-attempt authorization and mark the request attempted before the adapter calls exactly `remote:FireServer("ClaimFreeWheelSpin")`, with no arguments. No spin, queue settlement, ticket consumption, purchase, other claim or movement command is allowed.
- Confirm a receipt only when one fresh final context simultaneously shows a deadline advanced above its baseline and final native time, plus canonical ticket stock above its baseline. Record the actual positive quantity; no guaranteed amount is assumed. Either update may arrive first and remains incomplete until both are observed.
- Known competing grant/claim observations, ticket consumption, contradictory deadline state or attribution-epoch interference make correlation sticky and unresolved. A ticket gain alone does not prove an external source; a gain greater than one is not automatically interference.
- Pause/Stop already call Halt then Observe. The new observer detects controller state/generation, a unique manager-lifetime epoch, authorization revocation and scheduler cancellation. Tokens remain transient manager state, never shared ledger handles. Normal completion of a scheduler slice is not cancellation.
- Attempted interruption, ambiguity or timeout retains Pending with scheduler-compatible `Status="UNCONFIRMED"` and a specific receipt reason, preventing hot task cycles and every automatic retry. Later read-only paired observations are labeled separately and do not rearm authorization or erase interruption.
- Expose an appended privacy-safe receipt status method and narrow result logs. Do not include account identifiers, baseline balances/inventory, original native source or private console logs in published evidence.

The existing generic reward Definition can run these bounded slices through the same adapter. Its existing UNCONFIRMED guard suppresses new tasks while the real pending barrier remains. Legacy Halt/Destroy, AttributionBlocked, Prepare, MarkDispatched, DispatchReturned, `_finish`, `_report` and GetStatus remain unchanged; wheel helpers handle their own receipt/result record.

## Native and attribution limits

Reconfirmed the Notion master and applicable Phase 5/4/9 notes on October 14, 2026. Their current returned edit times remain October 13 for master/5/4 and October 12 for Phase 9. Latest read-only intelligence and isolated Common Egg milestones remain preserved; Phase 9 integration is not approved.

Reused [native action contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS.md), [reward evidence](research/replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md), [schema addendum](PHASE5-REWARD-NATIVE-GAP-ADDENDUM.md) and the completed wiki library. The preceding narrow saved-source reads established the free callback (`WheelSpin:595`, due display `:400`), native auto-claim (`:373,412`) and canonical Powerup ownership (`ItemUtil:466`). The Spin Ticket descriptor at WheelSpin:55 is also used for spin consumption; its Amount does not prove the free payout quantity.

Queue state and server proximity remain unproven. A later owner-live trial requires owner-confirmed idle conditions and manual approach to the normal wheel, with native frames closed for the preserved interaction guard. Implementation approval does not supply that confirmation or permit a live claim. These are bounded trial conditions, not universal gameplay acceptance.

Paired received changes are stronger evidence than invocation or animation. They cannot exclude an unobserved concurrent external gain with identical state changes. Tests must distinguish detectable competing evidence from observationally indistinguishable concurrency; neither is proof of authoritative transaction attribution.

## Verification and delivery boundary

[The hash record](PHASE5-FREE-WHEEL-PROTECTED-PROPOSAL.json) pins the baseline, patch, proposed file bytes and all four before/proposed method hashes. Every other method in those two files remains exact in the proposed projection.

Completed now: exact baseline comparison, `git apply --check` without application, official Luau compilation of the temporary proposed hook files, and current Mastery/reward source-preservation checks with immutable milestone pins. Production source and bundles remain untouched.

Not performed: implementation of the new helpers, a candidate build, full regressions against a changed implementation, new receipt/lifecycle tests, publication or any gameplay. Syntax validation of hooks is not receipt verification.

After approval: implement the bounded helpers and disabled candidate; run official compilation, `node scripts/build.mjs`, `node scripts/test.mjs`, new paired/split/deadline-only/stock-only/known-external-gain/unknown-attribution, auto-claim enabled/unknown, stale/racing state, authorization debit, duplicate/test-ID bypass, Pause/Stop/reload/cancel/timeout tests, and historical preservation. Preserve existing release pins and records under a separately recorded exact projection. Publish only after all required offline checks pass. Prepare the one-claim live test for a further approval; do not provide an activated loader during implementation delivery.

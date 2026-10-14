# Phase 5 — one native wheel spin

Implemented for a separately authorized owner trial. Defaults remain OFF, the published loader performs read-only preflight, and no live spin was run during development. Full Phase 5 acceptance remains pending.

Release: `phase5-wheel-spin-646b0df72fed`. [Pinned bundle](https://raw.githubusercontent.com/Whispfl/automation-/phase5-wheel-spin-646b0df72fed/dist/OC.lua), [complete disabled loader](https://raw.githubusercontent.com/Whispfl/automation-/phase5-wheel-spin-646b0df72fed/examples/Phase5WheelSpinDisabled.luau). Bundle SHA-256: `910d444a416ebca6243771689a3249d73425928d7cbd551a8c33c16353f429c0`.

The owner confirmed the preceding free-ticket collection increased stock from 1 to 2 and reset its timer. Preserve build `668d0af6f157`: its automatic receipt was unconfirmed, even though the owner verified the collection. The new spinner neither repeats that claim nor clears an unresolved reward ledger.

## Implementation

Reuse GameKnowledge, the verified LocalData reader/cache, RewardsManager, GameMechanics, OCBrain and the single TaskScheduler. One charged allowance persists in the same client VM; changing test IDs, Pause/Resume or reloading cannot authorize another attempt. Rejoining can lose client history and never renews human authorization.

The exact native Spin button's public `Pressed` interface starts the game's existing callback. Scoped public Remote wrappers capture its returned pool index and permit one native settlement after the normal animation. There is no second spin/queue call, replacement renderer, movement, purchase or fallback. Valid returned data identifies an expected catalog item; actual received changes establish the observed reward.

Receipt policy handles currency, Powerups, potion Name/Level records and exact pet IDs/variants. A complete coherent inventory, one-ticket debit, matching grant and completed native settlement emission are all required. Missing, interrupted, contradictory or partial evidence stays pending without retry. A five-ticket prize requires a separately observed debit; net +4 alone is insufficient. Currency gains are actual received deltas, with external/server attribution explicitly uncertain.

The executor stops the existing controller after one bounded attempt. Pause/Stop suppress later OC-authorized transport. An already consumed ticket cannot be undone. Cancellation before release retains an armed press and pending barrier rather than risking another callback; native UI reconciliation may be needed.

## Native evidence reused and verified

- Completed [reward research](research/replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md), [contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS.md), [schemas](research/replicatedstorage/DATA_SCHEMAS.md), [targeted reward addendum](PHASE5-REWARD-NATIVE-GAP-ADDENDUM.md), [owner RemoteSpy evidence](PHASE5-OWNER-REMOTE-EVIDENCE-2026-10-14.md), [wiki reward distinctions](research/wiki/REWARDS_SHOPS_AND_QUEST_STRATEGIES.md) and [knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md).
- Current read-only Studio inspection: `Client.Gui.Frames.WheelSpin:235–288,736` starts `WheelSpin`, receives an index and waits for its native six-second tween. `66–111` displays the expected item and then emits `ClaimWheelSpinQueue`; the module exports an empty table at `804–805`.
- `Client.Gui.Utils.ClickableButton:14–23,224–297` identifies the direct/contained control and implements public press/release attributes. `Client.Gui.GuiFrame:54–64,170–198` exposes ordinary wheel ownership. `Client.Activation:348–363` supplies observed horizontal/vertical activation geometry. `ItemUtil:466–474` separates Powerup maps from potion record arrays. `Shared.Data.WheelSpin:8–25` supplies the current eight-entry pool; its weights and base amounts are not verified server grant odds or multipliers.

Native queue contents have no reviewed public getter. An idle native interface, no retained pending operation, and separate owner confirmation are required; queue state is still UNKNOWN. The native callback has a no-ticket purchase-prompt branch. OC never purchases or accepts that prompt; fresh positive stock is checked before release and RPC. External data can change after an observation, so an absolute atomic stock/UI guarantee is not claimed.

## Preservation and verification

The separately approved [five-hook patch](PHASE5-WHEEL-SPIN-PROTECTED-PROPOSED.patch) remains pinned by its exact checksum. New helpers and the pure policy are recorded separately in [source preservation](PHASE5-WHEEL-SPIN-SOURCE-PRESERVATION.json). Existing free-ticket helpers, Brain/scheduler, reader, ordinary guards and all movement/hatch methods retain their prior bytes. Historical approval records, evidence and release tags are preserved.

Run `node scripts/build.mjs` and `node scripts/test.mjs`. The complete suite requires 684 baseline regressions, existing Mastery/reward/free-ticket/preflight tests, movement and hatch preservation, and new actual-source receipt, native observer, deferred-button bridge, manager and disabled-loader checks. Offline fixtures are not live acceptance.

Passed official Luau compilation and the complete suite: 684 baseline, 90 Mastery, 102 reward intelligence, 100 free-ticket and 49 historical preflight cases, all historical preservation/safety gates, and 23 new preservation checks. New wheel suites passed 81 receipt, 56 knowledge, 67 manager and 26 complete-loader cases. The final targeted bridge run passed 17 cases, including substitution of a contained control during the press yield. All 245 historical evidence/loader/fixture files and 19 prior immutable tags remain preserved.

## Next owner test

1. Use the new immutable disabled loader. Manually reach the ordinary Floating Island wheel and open its native interface. Have at least one Spin Ticket; do not click Spin, Skip, free claim or purchases.
2. The loader remains STOPPED and reports READY or the exact blocker, with zero spin/queue requests and no consumption. Send the preflight lines.
3. Only after a separate explicit ONE-spin authorization, use an account-bound test loader. Expect one ticket-consuming request, the normal animation, one guarded native settlement, the actual reward report and STOPPED.
4. Send the complete wheel result, starting/ending ticket count and observed reward. PENDING means do not rerun, clear the ledger or spin again to resolve uncertainty.

No paid purchase, Robux operation, free-ticket claim, unrelated consumption, hatch, equipment change, farming or movement is authorized by this candidate. Subsequent free-ticket/spin chaining and other reward families remain separate milestones.

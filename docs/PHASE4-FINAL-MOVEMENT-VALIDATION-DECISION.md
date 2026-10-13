# Final movement validation — bounded contract and exact proposal

2026-10-13. **One final same-frame support recheck closes the identified fixture.** The proposed adapter change is four added lines, tested in memory and not applied to production. Current local standing build `e2dbe7414c6a` remains unpublished; no loader, new movement loop or paid action is activated.

The latest applicable Notion [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363) and [Phase 9](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358) were freshly fetched before this investigation. The owner's latest instruction defines a realistic finite-observation contract; earlier audit outputs remain as-of history. Both completed libraries and existing search/footprint/safety evidence were reused without restarting research.

## Current operation order and yield boundary

| Current adapter step | GameMechanics line | Yield evidence / significance |
|---|---|---|
| Own scheduler task and direct-position setting | 804–805 | Local table/state reads |
| First destination/account/lease Validate | 806 | Resolve/RevalidateIntent/Pets:Fresh/PetContext delegate native helpers; may yield |
| LocalFeatureGuard | 808 | Native presentation/guard helpers; `GetAutoHatchStatus:Invoke()` at line 736 is explicitly potentially yielding |
| Second Validate | 810 | Same delegated validation boundary |
| Native-area and already-in-range checks | 812–814 | Field checks; already nearby returns without assignment |
| First adapter ResolveStanding | 815 | Existing geometry/range/footprint observation; precedes final destination validation |
| Compare initial standing point, retain cleared frame | 817–818 | Existing 0.25-stud early tolerance unchanged by proposal |
| Finite geometry, range and forced nearest eligibility | 819–824 | Physical TRAVEL_ONLY branch is local identity/distance; normal opened-egg branch observes cached registry/Workspace |
| Existing per-lease attempt check | 825 | Local ledger read |
| Third/final forced Validate | 826 | **Current gap:** a yielding or reentrant validation can change support after line 815 |
| Character/area, cancellation/ownership/config and nearby checks | 827–830 | Preserve every existing rejection/zero-assignment return |
| Mark attempt and sole CFrame assignment | 831–832 | Local ledger write and guarded direct setter; assignment is not arrival confirmation |

`pcall` does not make a callee non-yielding. LocalData `IsReady/Get` are documented direct received-state reads, and native WorldUtil's player-world lookup reads root/world state. The full validation chain also invokes native statistics/pool/world helpers; it must be treated as potentially yielding without proving every delegated body. LocalFeatureGuard has a concrete BindableFunction invocation, so the final physical observation belongs after that work too.

Inside `ResolveStanding`, TRAVEL_ONLY `RangeEligibleAt` is direct identity/range arithmetic. The normal opened-egg scan follows cached data, exact membership and Workspace observation; current OC source has no explicit wait there, and passive `task.delay` scheduling does not await. Native/account validation helpers are not called again after the proposed last recheck. The actual scheduler token's `CheckCancelled` (TaskScheduler lines 37–39) reads only `self.Cancelled`; `owns()` and the Config check are local reads.

## Minimum exact proposed change — separate approval required

[Exact patch](PHASE4-FINAL-STANDING-RECHECK-PROPOSED.patch), SHA256:

`1d5259f1d8e9593f616546eb345c5c6efd8c7064f025530b2682fbec156eec4d`

Immediately after final destination validation and its existing guards/nearby return, before the existing attempt ledger:

```diff
+	local latestFrame, latestReason = manager:ResolveStanding(final)
+	if not latestFrame then return false, latestReason end
+	if latestFrame ~= frame then return false, "Standing geometry changed after final destination validation; explicit rearm required" end
+	if token:CheckCancelled() or not owns() or not self.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING then return false, "Cancelled or selected-egg scheduler ownership changed" end
```

This requires the full freshly verified CFrame to equal the retained selected CFrame. It does **not** assign `latestFrame`, choose another safe sample, move to a nearby alternative, or accept a different orientation. Exact equality is intentionally conservative: even small translation/orientation jitter can block instead of silently changing the chosen landing transform. Identical valid observations produce identical original choices.

The repeated pure cancellation/ownership/config guard preserves interruption if the observation itself reenters or yields. Original destination/account/lease/native access checks, attempt consumption and the exact `fresh.CharacterRoot.CFrame = frame` setter remain unchanged. No subsequent Validate, LocalFeatureGuard, forced range helper or other potentially yielding native validation call is added between the last returned observation and assignment.

The extra recheck performs at most nine existing candidate queries. There remain zero movement actions during observation and at most one dispatched assignment. Including manager preflight and the two adapter observations, the normal full search is bounded at up to 27 ray candidates. There is no retry, rearm, position restoration or new loop.

| Hash | Before | Proposed only |
|---|---|---|
| GameMechanics file | `a2f1a3d6ab3483db3d91e9a50975e159a5107dbdf78a26e70f9765d5e1d19f87` | `d51154114e6309dd9042de250cbd8757ce1f61e146858960d7745397e14ab531` |
| PositionSelectedEgg method | `cb8f2973810e11daaaab948e3ae0303c0bbb3ce9bea9624b6ce57b4b9d542c7a` | `e049e8c5c459c40502813312219bd2ca59b87be6a93fcf347297edd9b1396a6a` |

[Scope/hash manifest](PHASE4-FINAL-STANDING-RECHECK-PROPOSED.json) records this additional protected-method difference separately. `git apply --check` passes. The actual GameMechanics file still has its original before hash; no adapter edit is implemented. The already approved standing file remains exactly `15bd589ea9ff1e81354dbe536b347a2a852f59efa4780681234d82ee0540cf3b`.

## Approval-specific test evidence

`node scripts/test-phase4-final-standing-proposal.mjs` uses the actual local approved standing source and either the frozen adapter or the four-line patch applied **only in memory**. Official Luau compilation passes for both variants. [Runner](../scripts/test-phase4-final-standing-proposal.mjs) and [fixtures](../tests/phase4-final-standing-validation.luau) execute 34 audit groups per variant, including the retained 22 safety groups and 12 focused operation-order/timing groups.

Recorded output: `.test-output/phase4-final-standing-proposal.log`, 8950 bytes, SHA256 `759602c9c3fb345035f15fa51c20ac95272b700b3a0f6a5391d1df4dc2462ae4`. The runner and fixture checksums are respectively `61c8e360ba2704778d34358494774fca7a02d82eeb3f20257de8ed9e18ae75d8` and `9c0190daef699cb13fc2937ed16687d7c3f7e0c4b223ee25080cedd0a8c72e69`.

- Frozen adapter reproduces seven known validation/changed-frame faults; the proposed bounded contract has zero such failures in these fixtures.
- Real coroutine suspension/resumption during the third Validate allows floor removal or shrink while validation is suspended. On resume, the proposal rejects before attempt consumption/assignment.
- Missing/insufficient support, new collidable obstruction, 0.1-stud elevation change, orientation change and newly available alternative safe point are rejected. The original frame is never substituted.
- All five original and four same-radius diagonal choices retain coordinates/order with identical valid observations; geometry, native access/identity, cancellation, ownership, already-in-range and one-attempt cases remain covered.
- Cancellation, ownership loss or disabled direct positioning during the last recheck are rejected by the repeated pure guard. Instrumentation rejects any Validate/presentation/range-helper call after that observation and counts a single setter.
- Semantic CFrame comparison in the fixture includes translation and orientation, using complete rigid transforms rather than table-reference equality.

These are offline source/fixture results, not a full regression pass on an implemented adapter, real physics certification or owner movement acceptance. Existing full-suite results for the unchanged local standing candidate remain in [its validation report](PHASE4-STANDING-SUPPORT-VALIDATION.md). All hatching, equipment, purchases and spending remain unauthorized; the tests invoke no actual game action.

## Mitigated interval versus unavoidable external change

**Mitigated:** support or selected standing geometry that becomes missing/insufficient/different **during final destination validation** is observed afterwards and cancels assignment. This includes the exact prior failing fixture. The last same-frame observation is followed only by native CFrame equality, known pure local guards, the existing ledger write and the direct setter; no potentially yielding application/helper operation remains in that suffix.

**Unavoidable boundary:** Workspace reads and CFrame assignment are not an atomic transaction. External geometry may change after the last support/clearance query, after the recheck returns or after assignment. A separate fixture deliberately removes support at setter entry and demonstrates this limit; it is not falsely labeled a guaranteed cancellation. Requiring geometry to remain unchanged forever, or adding repeated observations indefinitely, is outside the owner's bounded contract.

Existing requested-position/native-range and stable-arrival observation remains mandatory after the one attempted assignment. An assignment or adapter return alone never certifies successful arrival. Cancellation/timeout/manual departure remain bounded failures with no retry or snap-back. Legitimate complex/multipart/tilted support can remain blocked by the approved conservative Block proof. No universal movement or root cause of the owner's older failure is claimed.

## Exact requirements before candidate publication

After separate approval of this exact four-line patch:

1. Apply only the approved adapter delta; add a separate exact-approval record/verifier against its fixed preimage. Preserve all original standing/Test A/first-hatch approvals and pins; no historical hash is rewritten.
2. Run official compilation, `node scripts/build.mjs`, complete `node scripts/test.mjs`, all native receiver/registration/price/receipt/allowance checks, exact method/file preservation and distribution integrity.
3. Run the final-validation gate on **actual implemented source**. Removal/shrink during final validation must reject without assignment. Preserve all retained unsafe geometry/access/cancellation/collision cases; keep after-last-observation mutation as the explicitly documented non-atomic limitation authorized by this bounded contract. Do not delete the earlier DURING-Validate failure evidence.
4. Verify all nine landing choices, same radius, exact same-frame comparison, single attempt, no substitution/retry, and unchanged stable-arrival executor. Compile/resolve the full zero-spend TRAVEL_ONLY loader with every unrelated action OFF.
5. Only if those checks pass, commit/push one immutable movement candidate and verify its anonymous public raw bytes. Then provide one bounded owner-avatar approach test, beginning outside Common Egg radius, with zero hatch/equipment/spending. No hatch repeat is required.

**Decision:** the current local movement work can proceed to that validation/publication checkpoint once this protected adapter proposal is separately approved. The four-line in-memory experiment closes the current testable gap; publication remains conditional on the implemented full suite and owner live movement result. No further hypothetical timing patches are implied by this decision.

Exact reused sources: [native navigation contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md), [navigation source ledger](research/replicatedstorage/NAVIGATION_SOURCE_LEDGER.md), [LocalData schemas](research/replicatedstorage/DATA_SCHEMAS.md), [native/server-only gaps](research/replicatedstorage/UNKNOWN_AND_SERVER_ONLY_RULES.md), [wiki/native conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), [knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md), [future reliability improvements](research/wiki/FUTURE_OC_IMPROVEMENTS.md), and existing [search/footprint safety-stop evidence](PHASE4-STANDING-SEARCH-SAFETY-STOP.md).

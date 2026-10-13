# Phase 4 Test B — prepared candidate, spending OFF

Owner-approved Test A is build `0d5caa499c8c`, commit `25890f224f0448f148d009e65514c129aeb4f59c`, pin `phase4-travel-0d5caa499c8c`. Its corrected owner log and direct observation confirm one Common Egg teleport, 83.10 → 2.01 studs, one second of stable arrival and no hatch/equipment/spending. The withdrawn floor-error log is not a defect in that successful test.

This candidate is build `59c475d125c2`, pin `phase4-hatch-59c475d125c2`, on `codex/phase4-test-b`, starting from the exact approved commit. The mistaken standing overhaul (`3844cf8`, build `79273e3c1cc9`) remains isolated in its existing history/pin and is not incorporated. No history or release pin was reset or overwritten.

## Test A preservation

The complete `EggTravelManager.luau`, `GameMechanics.luau`, `OCBrain.luau` and `TaskScheduler.luau` files, and the historical Test A example, match the approved bytes. This preserves ResolveStanding, CFrame assignment, floor rays, collisions, native transport, timing, movement ownership, stable arrival, one-attempt handling and controls. GameKnowledge's EggModels, ObserveEggModel, EggLocationCandidates, ResolveEggLocation and ObserveEggChunker methods also match. The [preservation manifest](PHASE4-TEST-A-PRESERVATION.json) and `node scripts/verify-test-a-preservation.mjs` enforce all ten hashes. Existing farming/collection and pet policy modules are unchanged.

## Native interaction correction

Exact registered identity and current interaction eligibility are separate. Two registered originals with the same name no longer reject a positively verified retained Model simply because the other exists. Without a retained exact Model, global same-name identity remains ambiguous. The original is never replaced through a full-path/name-only match.

Opened interaction verifies the uniquely nearest eligible loaded original across all names, within native Root 3D distance 16, with Unlocked and known Prompt Visible=0. It enumerates the identified receiver's exact loaded values, including catalog-unknown competitors; malformed/incomplete registration evidence blocks. Initial interaction requires the exact cached/enabled engine Prompt attached to the selected original, within its actual radius capped at 6.5. Other enabled cached prompts, including non-egg prompts, are checked conservatively. Unknown active-prompt geometry or a competing usable prompt blocks rather than inventing engine active selection.

The paid path refreshes this evidence even when an unchanged arrival lease is enabled. Native cost, storage, cooldown on LocalPlayer, profile, character/root, account, permissions and budget must still pass. The actual remote sends `HatchEgg(name,1)`; it does not send an Instance. Server instance/proximity validation remains unavailable. Full source references and reused native/wiki files are in [the native evidence](PHASE4-TEST-B-NATIVE-EVIDENCE.md). No Studio object/script, play state or gameplay was changed.

## Two complete configurations

- [Phase4TestBPreflight.luau](../examples/Phase4TestBPreflight.luau): Common Egg, existing TRAVEL_ONLY travel, AUTO_HATCH=false, exceptional allowance=false, zero cost/session/exception budgets and all unrelated actions OFF. Copy the complete file. It verifies native interaction and reports mechanical readiness without spending permission.
- [Phase4TestBOneHatch.luau](../examples/Phase4TestBOneHatch.luau): prepared NORMAL one-request configuration. It is also disabled in the published file. `OWNER_APPROVED_ONE_COMMON_HATCH=false` and `AUTHORIZED_ACCOUNT_ID=0`; hatch, allowance and travel flags stay OFF and budgets stay zero. **Only after separate explicit owner approval** set that flag true and enter the approved current account's numeric ID. Both are required. Activated scope is one Common Egg, Coins only, native price at most 10, total request cost at most 10 and future-world reserve draw at most 10. The existing travel adapter is allowed if necessary; it observes an already in-range lease without an unnecessary teleport.

The normal progression/resource protections and ordinary usefulness policy remain. Mechanical preflight readiness is not a guarantee that a paid planner decision will pass; an already strong account can reject Common as non-useful. An empty current-account inventory is valid and is not replaced with another account's inventory. No account ID, previous balance or live inventory is prefilled.

An explicit account-bound allowance cannot migrate to another current account or silently expand through changed configured identity. Consumption is recorded before even uncertain transport; the existing per-account shared ledger prevents another allowance request after a same-client-VM reload. **Client restart/rejoin durability is unavailable**: the in-memory shared record can be lost. No automatic rejoin, rearming or durable one-request guarantee is implemented. Do not reuse an activated configuration after restarting/rejoining as an uncertain retry.

## Owner console checklist

1. Confirm `[OC][INIT]` build `59c475d125c2` and the actual test account. Do not manually hatch or click Buy concurrently if the outcome is to be attributable to this test.
2. Preflight should retain one selected Instance, observe `PHYSICAL_ARRIVAL_OBSERVED` when travel is needed, then independently report `HATCH_RANGE_OBSERVED` or a precise `HATCH_INTERACTION_UNVERIFIED` blocker. `HATCH_PREFLIGHT_READY_ALLOWANCE_OFF` includes account, selected ID, live price, Coins, storage, EggsOpened, cooldown and interaction mode. Hatch requests/requested spending must remain zero.
3. After separate owner authorization and account-ID configuration, `HATCH_BEFORE_SNAPSHOT` reports facts captured before invocation. `HATCH_REQUEST_ATTEMPTED` records exactly count=1 and requested total=1 after the existing adapter returns. It explicitly does not claim server delivery.
4. `[OC][PET][HATCH_RESULT]` must show received pool-matching pet/quantity gain and egg-counter change. Coins comparison shows the actual signed net change, expected native price and NET_MATCH/NET_DISCREPANCY/UNKNOWN. Presentation is supplementary; net balance attribution and server charge timing can remain uncertain.
5. A timeout, uncertain invocation, stale account/character/Instance, nearer competitor, full storage, insufficient funds or unsupported native condition stops further requests. Check no second hatch, no equipment/deletion/crafting/fusion, pickups, farming or world purchase. Pause/Stop retain the dispatched request allowance; no snap-back or second movement is introduced.

Test B requires owner-observed real received results. No live hatch success is claimed. Test A is owner-approved; Phase 4 as a whole remains open, and Mastery/Phase 9 implementation remains deferred.

## Verification

`node scripts/build.mjs` and `node scripts/test.mjs` pass deterministic bundle/config/static checks, official Luau compilation, **599 main-suite regressions** and complete example activation/isolation checks. The additions include 14 native-identity cases, six allowance/account/result cases and 21 Common Egg Test B cases. All 104 completed native/wiki research files remain byte-identical to the original backup. Publication verification compares the candidate branch, immutable pin, full tree hashes, anonymous raw bytes, both new examples and the untouched approved Test A pin; it is not gameplay verification.

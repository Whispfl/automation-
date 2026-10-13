# Phase 4 zero-receiver diagnostic preflight

Build: `6dfccccdf6cf`. New immutable pin: `phase4-hatch-6dfccccdf6cf`. Development branch: `codex/phase4-test-b`.

The actual native egg receiver remains unidentified from the owner's 85-Update trace. Those calls establish five captured receivers, not an egg-specific call. The demonstrated reporting defect was that exact selected membership was searched only in already accepted receivers. With qualifying=0 that answer was necessarily false, even if a rejected receiver contained the selected original. The previous log therefore cannot distinguish a rejected genuine receiver from an uncaptured one.

[The evidence record](PHASE4-ZERO-RECEIVER-EVIDENCE.md) lists the freshly reviewed Notion pages, both reused research libraries and exact native source references. The full-interface member named Egg remains unidentified. No name is whitelisted and receiver classification is unchanged.

## Changed methods and files

- `GameKnowledge:ReadObservedEggReceiver` is a new bounded read-only inventory of every captured receiver, including rejected ones. It compares selected and other cached physical originals by exact Instance equality, reports structure, method-reference and folder facts, contents, loaded state and rejection evidence. It calls no native method and grants no registration.
- `GameKnowledge:NativeEggRegistrationDiagnostics` reports all-candidate membership separately from the existing trusted membership. Partial reads use UNKNOWN; completed observation and scan completeness are separate facts.
- `GameKnowledge:NativeRegisteredEggModels` skips only a nil bucket marked loaded=true, matching native Remove/IsValueLoaded/Update behavior. Present malformed values and nontrue loaded flags remain blockers, and coordinate reads are bounded. This independent reader correction cannot explain zero qualifying receivers because the unchanged classifier iterates present `_chunks` entries.
- `PetManager:ReportHatchPreflight` and the `OCController:Log` category filter expose the receiver snapshot in the ordinary console with debug OFF. Stable semantic keys and the existing five-second minimum throttle prevent Update-count-only changes from flooding the console.
- Targeted identity/interaction tests and seven exact preservation checks were added. Source and single-file bundles were rebuilt; the two existing Test B examples point to the new pin while retaining their Config values. The prepared one-hatch example remains unauthorized and is not the next live-test instruction.

No additional protected method was changed. The prior approved `ObserveEggModel` exact pairs membership correction is preserved. The native observer, classification, lifecycle/cleanup, native price quote, paid Prepare guard, physical selection and working movement system remain unchanged. Historical releases, the original preservation manifest and the separate approved correction record are retained.

## Verification

`node scripts/build.mjs` completed. `node scripts/test.mjs` passed official Luau compilation and 637 main-suite regressions, including 60 identity and 29 Test B interaction cases. Thirteen approved-membership checks and seven exact observer/price/paid-guard preservation areas passed. Historical ten-method movement preservation passes with the original nine unchanged methods and sole separately approved membership difference. All 104 research files are unchanged. Whitespace validation passed.

The public verifier compares the published Git tree and anonymous branch/commit/tag raw bytes. It additionally checks the preserved `0d5caa499c8c`, `59c475d125c2` and `926bc78d88af` releases. Publication results and full commit SHA are reported in the final delivery after these checks complete. Compilation and fixtures do not establish live native registration, a successful hatch or Phase 4 completion.

## Owner's next live test

Use the complete Config and loader in [Phase4TestBPreflight.luau](../examples/Phase4TestBPreflight.luau). Its anonymous pinned bundle URL is:

`https://raw.githubusercontent.com/Whispfl/automation-/phase4-hatch-6dfccccdf6cf/dist/OC.lua`

Run only OC, using this safe preflight without enabling other action settings. The existing one-attempt TRAVEL_ONLY positioning is unchanged. If already in range, zero movement attempts remains the correct result. AUTO_HATCH, AUTO_EQUIP and the one-hatch allowance are false; authorized account ID and all spending budgets remain zero. Do not click Buy or enable ONE_HATCH for this diagnostic.

Wait approximately 20–30 seconds after START so initialization, the existing five-second observation window and stable arrival can finish. Return:

1. The final `NATIVE_EGG_RECEIVER_OBSERVATION` header, preferably `observation complete=true`, and all candidate rows printed with it.
2. The final `HATCH_PREFLIGHT_BLOCKED` or `HATCH_PREFLIGHT_READY_ALLOWANCE_OFF` line, native price and blocker/reason.
3. Physical arrival status, direct/native attempt counts, hatch requests and requested spending.

If observation does not complete, return its precise observer state instead. If the selected original is present in a rejected receiver, that exact membership and rejection explain the next investigation. If absent after a complete scan, that establishes absence only from the captured receivers. UNKNOWN means a bounded/current read was incomplete. Even READY_ALLOWANCE_OFF authorizes no hatch. Keep the paid test off and wait for review of this live trace.

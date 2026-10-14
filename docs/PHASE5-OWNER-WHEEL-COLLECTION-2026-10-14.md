# First owner-live free wheel-ticket collection

On October 14, the owner ran the separately authorized **one free wheel-ticket claim** using immutable build `668d0af6f157`, tag `phase5-free-wheel-ticket-668d0af6f157`, implementation commit `f4c495e2c3d313ed6666ff94dd34c384cc8a0631`. The owner reports: **“it worked collected a ticket.”**

- **Owner-observed ticket collection: LIVE CONFIRMED for this isolated test.**
- **Automated paired receipt: NOT_CONFIRMED.** The console progressed from one charged attempt / AWAITING_RECEIPT to sticky AMBIGUOUS with pending retained, then STOPPED. A charged attempt is not independent proof of a native invocation or server acknowledgment.
- The authorization is consumed. No retry, ledger reset, replacement test ID or new claim is approved. All unrelated gameplay permissions and spending budgets were OFF/zero; the supplied console does not independently establish balance deltas or a renewed deadline.
- Actual native deadline-plus-ticket observations and the first retained observer blocker remain to be read. Do not replace the ambiguous automated result with invented `CLAIM_AND_GRANT_OBSERVED`, assume a particular granted quantity from the console, or declare full Phase 5 complete.

The complete owner-supplied console transcription and account-bound loader stay local. The original loader is preserved byte-for-byte with SHA256 `2f3a094bfd6672386735eaf38174878a19e5b9805213bfd4ad7ab92fa74a846a`; public source, bundles, tags and historical evidence are unchanged.

## Confirmed reporting defect

The private wrapper used `ok and reason or "Native observations unavailable"`. A successful warmup returns `reason=nil`, so the fallback was retained and later printed ahead of the manager's actual blocker. This **diagnostic masking** is confirmed offline; it does not establish the cause of the live AMBIGUOUS state.

The smallest diagnostic correction assigns the context as before, then sets the blocker with explicit `if ok then blocker = reason else ... end`. Official compilation and 18 synthetic actual-loader cases pass with that correction applied **in memory only**. No corrected activated loader is issued; the used original remains archived and authorization remains consumed.

The protected manager also collapses unsuccessful knowledge observations to a generic unavailable/changed/stale reason. Raw received data preceding the reader snapshot is one possible source-supported path; other missing, stale, changed-interface or conflicting facts can also block. **The live cause is unproven.** No protected method, receipt safeguard or movement code was changed.

Next action: read the stopped manager's retained receipt status once, without Start, Observe, transport, new initialization or claim. Use its first blocker and paired observation flags to scope any necessary correction. Existing contracts and owner RemoteSpy requests need no recapture. Preserve the unresolved barrier while investigating; Playtime/chest/daily/Mastery action tests require their own authority and must not bypass it.

# Independent economic review of Stage 2 synthesis

Reviewer: economy research agent. Date: 2026-10-11. Documentation review only; no gameplay requests, Studio calls, native source execution, code/config/bundle edits, Stage1 edits, builds/tests or Git operations. Authors' files were not edited by this reviewer.

## Scope and method

The reviewer read the complete available text of:

- [ROI_DECISION_FRAMEWORK](ROI_DECISION_FRAMEWORK.md)
- [FUTURE_OC_IMPROVEMENTS](FUTURE_OC_IMPROVEMENTS.md)
- [RIFTS_EVENTS_AND_OPPORTUNITIES](RIFTS_EVENTS_AND_OPPORTUNITIES.md)
- [FISHING_MINIGAMES_AND_OBBY_STRATEGIES](FISHING_MINIGAMES_AND_OBBY_STRATEGIES.md)

Changed final paragraphs were reread after authors applied corrections. Cross-checks used the previously deep-reviewed economic helpers, full relevant Stage1 documents, specialty/fishing source ledgers, preserved fish numeric inputs, and the Stage2 Infinity Chest correction/claim records. No new native body fetch was performed for this review. Infinity Chest's newly reviewed helper is evaluated through the author's explicit summarized source contract and references; this reviewer does not claim an independent full-body read of that new helper.

Arithmetic was recomputed locally from preserved inputs. These are documentation checks, not OC tests or gameplay verification. Search excerpts were not elevated to body evidence; root-body/child-forwarded provenance remains distinct from independent article reading.

## Findings and repair verification

| ID | Finding and exact review location | Required correction | Status |
|---|---|---|---|
| E-R001 | ROI:53 asserted Golden75/Burst100/75 create hazard changes. Saved counters/helpers do not establish final server application; SuperUtil Burst consumer is unavailable. | Qualify the mechanisms as counter/helper definitions with conditional server application; retain missing consumer. | RESOLVED: reread text says they would create state-dependent hazards if final application is established; advertised Shiny guarantee remains separate from useful-pet guarantee. |
| E-R002 | ROI:43 used H−t while calling H useful operating minutes, and showed only clipped positive rate benefit. Setup earning and signed cost/loss needed explicit treatment. | Define total elapsed window; include setup earning, exact paid cost, signed rate change and bounded setup loss. | RESOLVED: H includes setup+operation; goal formula includes r_setup*t; signed net formula retains negative states and uses min(t,H). |
| E-R003 | Fishing/minigames:64 subtracted currency/items/time directly from useful reward value, without consistent units. | Preserve resource/time cost vectors independently; convert only through an explicit state-specific goal utility model. | RESOLVED: reread paragraph separates utility from Ticket/item/time vectors and forbids fixed exchange assumptions. |
| E-R004 | ROI:35 called stationary collection the only authorized farming behavior, potentially excluding owner-tested Phase1 bubbling/selling/teleport. | Preserve Phase1 and approved Phase2 scope explicitly; authorize no new movement/hybrid behavior. | RESOLVED: reread final paragraph names Phase1 behavior and Phase2 stationary collection. |
| E-R005 | ROI:65 added travel/verification to max(activity,start-triggered cooldown) as if all overhead must be nonoverlapping. Overhead may fit inside cooldown, so that additive expression is not always a lower bound. | Use a critical-path cycle, counting each segment once. Start-triggered cycle is at least max(c,t+a) for active time t and mandatory sequential overhead a; additional overhead is added only when it cannot overlap. For completion-triggered cooldown, inspect timer start and overlapping segments separately. | RESOLVED: reread final paragraph uses max(c,t+a), forbids double-counting overhead inside cooldown, and scopes completion-triggered t+c to the cooldown-only floor. |

All five repairs were made by the authors and verified by this reviewer. A reference to CLAIMS_LEDGER.md was still awaiting aggregate creation during an intermediate read; root was notified to seal final links. That is a deliverable/link dependency, not a game mechanic finding.

## Mathematical checklist

- [x] Goal-time illustrations: saving60minutes; upgrade15m/min path48.6667minutes; upgrade11m/min path65.6364minutes; simple payback20minutes. Inputs are explicitly synthetic, reserve/setup assumptions named.
- [x] Goal reserve is now additional/nonoverlapping with G; no duplicate commitment is counted.
- [x] Signed net gain after repair is dimensionally consistent: rate×time, cost and setup loss in the same goal currency. Full paid-at-start C is retained even when H<t.
- [x] Bubble-cycle expression uses capacity/bubble-production time plus travel overhead; rate is per the time unit used in production. Seconds-based and minute-based formulas require conversion before being combined. Capacity does not automatically double output.
- [x] Geometric/binomial/batch formulas are conditional. Full successful-batch costs matter; parent framework states this, and companion egg document now gives b*c/[1−(1−q)^b].
- [x] Variant independence, target usefulness, Golden/Burst application and unknown server probabilities are not certified by constants or counters.
- [x] Zero-success95% one-sided Bernoulli upper bound is1−0.05^(1/n), conditional on actual IID accepted trials. It creates no positive lower bound.
- [x] Raw fishing mean XP and rare-entry mean draws were recomputed from every saved area pool and fish record. All seven rounded table values agree; no mutation/rod/modifier or server multiplier was inserted.
- [x] Starter rare tail: p=0.2/100.532 gives502.66mean draws and1505draws for95% chance. This does not establish full FishDex completion or a guarantee.
- [x] Mutation conditional weights5/3/1/0.5 normalize to52.63/31.58/10.53/5.26%; these are conditional on mutation, not every catch.
- [x] Pet Match expected Dice Keys per raw draw=2×15/98.5≈0.3045685; Cart≈0.2024291. Draws are not plays.
- [x] Robot Claw raw Super Ticket expectation=1.4/95.91≈0.014597 per draw; replacing one skip through that channel needs68.507expected draws. Unknown rolls/bonus cannot prove self-funding.
- [x] Board node weights total4.65; published rounded conditional probabilities agree. Golden one-node behavior is explicitly scoped to the inspected helper.
- [x] Renewal/cooldown critical-path wording was reread after E-R005 repair; overlapping overhead is counted once.

## Counterexamples that must remain preserved

### Shrine duration is not item XP or a fifteen-minute increment

[Native specialty evidence](../replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md#bubble-shrine), ShrineUtil109–125, gives D(a)=floor(60*(15+1425*clamp(a,0,500)/500)). Recomputed one/100/500 item durations are1071/18000/86400seconds. The world document correctly states17m51s/5h/24h, a15minute baseline and171seconds per item. Item type determines XP separately; active-time extension caps remaining duration. This agrees with the saved helper and explicitly conflicts with the wiki12h/1000-item/42.3second version. It does not prove a live donation receipt or permit donating protected items.

### Infinity Chest base is not the effective composite

[Stage2 correction](REWARDS_SHOPS_AND_QUEST_STRATEGIES.md#infinity-chest-effective-composite-differs-from-base), M-C046–047, records GetInfinityChest1–69 and actual LootPoolViewer980–982 consumer. The base600second/5roll/750Coin definition does not establish the full accessible composite: included rendered/unlocked names add pools/rewards/rolls and maximum cooldown. The reviewer found no remaining flat600second-versus34minute rejection in the four synthesis targets. Fresh received cooldowns and credits remain authoritative; source summary is not server normalization or a confirmed34minute constant.

### Halloween thresholds are conditional accounting

World document's331Shard nominal total is sourced to saved upgrade definitions, not a live shopping plan. Under its stated331threshold-exact rebirth assumptions, sum_{k=0}^{330}(20b+0.25b*k)=20.27375trillion Candycorn; the170b cap is not reached in those331steps. Recomputed arithmetic agrees. Resets/grants, extra currency forfeiture, other shard sources, useful upgrades and event expiry remain unverified or additional inputs.

## Authority, provenance and coverage checklist

- [x] Best feasible already-owned team is the baseline; current equipment alone is insufficient.
- [x] Stack quantities, coupled enchants, Super/equip limits and post-consumption reoptimization are required.
- [x] Protected IDs/items/goal reserves constrain actions; a lock/protection does not automatically erase the pet's existing utility.
- [x] Saved native catalogs, scene objects, public current-season description and owner account access are separate evidence.
- [x] Halloween identity corroboration supplies neither owner eligibility nor an end date; historical Fall/Challenge/Pass dates are not substituted.
- [x] Shrine donation, pet conversion and event rebirth remain distinct irreversible cost contracts.
- [x] Rifts require fresh object/expiry/geometry/materials; tagged/catalog rarity is not reachability.
- [x] Native action shape/animation/timeout/scheduler status is not a verified debit/grant/arrival.
- [x] Normal milestone completion/effective buffs and possible grants are not an invented ClaimMilestone interface; latest Phase5 wording retains unknown timing.
- [x] Future ranking is a research priority estimate. The115tier claim is supported by the Mastery agent's explicitly complete saved-catalog reread; it is not115verified runtime effects.
- [x] Explicit Phase4 approval, later owner action verification, central Brain/scheduler ownership, deferred hybrid farming and suspension/research-only boundaries are preserved.
- [x] No automated trading, Robux purchase, macro, bypass, pickup chasing, independent loops or current implementation authority is introduced.
- [ ] Final aggregate ledger link creation/validation is to be sealed by root; the timing repair is complete.

## Remaining limits

This review cannot verify server RNG, batch variant allocation, empty Infinity rarity policy, payment/refund semantics, claim eligibility, expiry, current account facts or actual earning/catch/activity rates. Saved decompiler defects remain material. Current public body review does not imply complete event/world tabs or a primary developer mechanic specification.

All five identified substantive/precision findings are resolved in the reread text. Apart from final aggregate link creation/validation, no additional substantive arithmetic, evidence-boundary or authority-scope defect was found. The review certifies documentation consistency within these limits, not gameplay correctness.

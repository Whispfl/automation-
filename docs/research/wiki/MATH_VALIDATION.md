# Offline math validation

Date: 2026-10-11. **124 arithmetic assertions passed; zero numerical errors found** in the reviewed final examples and table sums. This is documentation validation, not an OC build/test, gameplay observation, native execution or source/body-coverage audit.

The machine-readable [MATH_VALIDATION.json](MATH_VALIDATION.json) preserves each assertion's inputs, formula, result, expected value, rounding tolerance, units and assumptions, plus SHA256 snapshots of seven reviewed documents. No authors' documents were edited by this QA task.

| Area | Verified result / boundary |
|---|---|
| Geometric and batch example | q=1e−6: mean1m hatches; median693,147;95% budget2,995,731; batch12 success≈0.000011999934; first successful batch≈375,002.063s |
| Endpoints and prepaid cost | q=0 has no finite positive-confidence budget; q=1 first trial succeeds; r=1 needs infinitely many trials when0<q<1. Full prepaid batch mean is b*c/[1−(1−q)^b], versus stoppable per-hatch c/q |
| Synthetic goal time | Saving60min; upgrade48.667min at15m/min or65.636min at11m/min; simple same-currency payback20productive minutes |
| Reserve/setup and horizon | Added validation fixture with100m additional reserve and10m/min setup earning gives54min; signed horizon expression agrees with direct end-balance comparison, including H<t |
| Shrine counts |1/100/500items produce1071/18000/86400s under the saved formula; slope171s/item plus900s baseline, with cap |
| Wheel raw weights | Sum99; conditional baseCoins≈181.818/draw, returned SpinTickets≈0.146465/draw, pet probability0.1/99. Missing1weight is not filled |
| Claw/Match/Cart | Claw0.014597SuperTickets/raw draw and68.507mean replacement draws; Match/Cart expectedDiceKeys≈0.3045685/0.2024291 per raw draw |
| Biased enchant level | P(levelV)≈0.054258391; normal-only Looter/BubblerV≈0.023088677; TeamUpV≈1/433.113 |
| Mastery marginal examples |19→28team factor≈47.37%; Pets3 synthetic break-even≈202.67productive minutes; speed/duration/refresh/sale examples agree |
| Mastery tables |17nominal prerequisite packages, five permanent branch totals, three seasonal sums and115printed tier rows reproduce the documented arithmetic |
| Fishing | All seven raw meanXP and rare-entry means agree with preserved pool/fish inputs; starter95%rare-tail budget1505draws |
| Mutation/Board/coupon model | Conditional mutation weights normalize correctly; Board hypothetical window totals4.65; two-missing coupon inclusion-exclusion agrees with a first-hit recurrence |
| Halloween threshold sum |331exact-threshold rebirths sum20.27375trillionCandycorn under the stated one-shard/no-other-source assumptions |
| Cycle models | Bubble-cycle units are consistent; start-triggered cooldown fixture max(300,60+20)=300s counts overlapping overhead once |

The goal, rate, probability and paid-cost fixtures are synthetic. Mastery sums were recalculated from the **printed documentation tables**; this QA did not independently re-read native scripts or validate their transcription. Fish calculations reuse preserved numeric records. No fresh external article body was read.

Probability results require their stated stationary/independent eligible-draw model, useful-outcome definition, complete normalization and actual batch-payment semantics. Raw draw expectation is not reward per play, observed payout or a self-funding loop. Temporary windows, server cadence, paid costs, compound variants, protected reserves and owner facts remain separate evidence.

**No math repairs requested.** Earlier wording/assumption findings and verified author repairs remain in [INDEPENDENT_ECONOMY_REVIEW](INDEPENDENT_ECONOMY_REVIEW.md). This arithmetic result grants no implementation or spending authority.

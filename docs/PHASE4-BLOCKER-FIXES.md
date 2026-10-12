# Phase 4 blocker fixes and separate travel/hatch acceptance

This delivery continues the existing worktree after the owner's blocker-fix
request and positioning-reference addendum. It does not restart Phase 4 or
replace the accepted equipment, account reader, collector or central scheduler.
The master roadmap, Phase 3, Phase 4 and Phase 9 reference pages/returned owner
notes were read, and both completed research libraries were reused. **Phase 4
remains open; new gameplay acceptance is pending.**

Candidate build **`141b7608bedf`**, pin `phase4-tests-141b7608bedf`, passes
`node scripts/build.mjs`, official Luau compilation and **504 main-suite offline
cases** through `node scripts/test.mjs`. Both complete new Configs pass isolation
after default merging; the exceptional allowance is OFF/zero in both. Public
commit/tag/raw-byte verification is performed after publication and reported in
the delivery. All 104 completed research files remain byte-identical to the
pre-fix recovery snapshot. Offline/publication checks are not gameplay proof.

## What the owner actually observed

The owner ran immutable build `890d4713edad`, release
`phase4-auto-890d4713edad`. Initialization and account/egg analysis worked, but
the program stayed in WAIT. The account had 24 pet records/59 units, seven
equipped pets, a current native Coins score of 4 and a bounded owned estimate of
1,752. The 1,000-evaluation search limit was reached. The next world remained
locked with a one-billion-Coins reserve, leaving zero normal spendable Coins.
No OC egg travel, hatch, equipment change or spending was observed.

That observation establishes a correct reserve/uncertainty stop. It does not
verify the movement adapter, arrival, hatch dispatch or received results. The
older migration build's successful actions-OFF initialization/account reads and
the earlier owned-team equipment acceptance retain their separate evidence.
The existing `Phase4AutoOnce.luau` release pin is historical and is not rewritten.

## Why the owned benchmark reached its cap

The old steepest single-swap search evaluated every candidate record against
every equipped slot repeatedly, replacing a weak seven-pet team one unit per
round. It rescored self swaps, alternative slots holding identical stack IDs and
previously visited ordered teams. A finite native comparison cap can therefore
be exhausted by redundant work even after finding a much stronger feasible team.
The live log alone cannot establish which particular protected/variant/enchant
records caused each comparison; private inventory IDs are not published here.

`PetPolicy.Team` now builds a quantity-correct rank seed while retaining protected
equipped units, explicit protected IDs and existing Super constraints. The seed
is accepted only when a native full-team projection improves the current team.
It is a search hint, not an additive-stat or global-optimum proof. The algorithm
then completes the supported single-swap neighborhood from the stronger native
baseline. It skips self swaps and equivalent removals of identical base-ID stack
copies. Exact ordered-ID memoization is scoped to one detached analysis; failed
native probes remain failures, never zero scores.

The cap remains 1,000. New diagnostics separate unique native comparisons,
cache hits, redundant swaps, rounds, native seed result, genuine denied uncached
probes and missing inputs. Merely finishing at the exact cap is not truncation
when the supported neighborhood was fully evaluated. A converged bounded
heuristic remains distinct from a proved global optimum. Unknown owned
definitions/rarities/stats, failed native projections, actual truncation and
unsupported unused Super configurations still block paid ROI.

An offline synthetic fixture reproduces the observed **24-record/59-unit/seven-slot
shape**, not the owner's actual inventory. Its prior loop reaches the 1,000 cap;
the revised search uses **46 unique native projections**, skips 110 redundant
stack swaps and completes one neighborhood round with score **4 → 1,752**.
These synthetic numbers demonstrate the algorithm correction and do not claim
the owner's new live benchmark or measured income.

`GameKnowledge` now detaches the account and pet inputs independently for every
native helper comparison. Native BuffUtil-backed helpers can decrement uses or
advance queues even while calculating an estimate. One comparison must not
mutate the live profile or contaminate the next candidate's immutable benchmark.
Native reconstruction/shared-cache/server fidelity limits remain explicit.

## Test A: TRAVEL_ONLY

[examples/Phase4TravelOnly.luau](../examples/Phase4TravelOnly.luau) selects
`EGG_TRAVEL_SETTINGS.MODE="TRAVEL_ONLY"`. AUTO asks the same Brain for a
read-only physical diagnostic destination: one actually loaded, supported,
unlocked permanent egg. Its rule prioritizes an ordinary native cost interface,
then observed proximity with deterministic name ties. The reason identifies
this as a **travel diagnostic**, not the best economic hatch investment.

This mode has zero hatch/allowance/world-purchase budgets and disables paid
hatching, equipment, pickups, farming, bubbles/selling, rewards, events and
anti-AFK. It does not require paid affordability or a completed owned-team ROI
benchmark because it spends nothing. It still requires fresh account access,
the exact original model, supported native world/island destinations and valid
interaction/standing geometry. Unknown, locked, ambiguous or unloaded targets
wait. An owner may instead configure MANUAL with one exact native name; that
diagnostic name is still checked against live account/model evidence.

The existing Brain, EggTravelManager, GameMechanics and TaskScheduler carry one
structured target through selection, native area travel, final positioning and
observed stable arrival. Target identity includes name, original model, world,
island, selection mode, reason, goal/generation/revision and diagnostic/hatch
scope. A TRAVEL_ONLY target
never becomes a hatch authorization or handoff. One bounded diagnostic attempt
is reserved before the task enters the scheduler; cancellation, completion or
failure does not automatically rearm it or
permit another attempt by increasing a selection revision.

An acquired diagnostic target is retained through its own movement. Newly loaded
or newly closer eggs do not rerank the active trip. Fresh checks still reject
changed goal/generation/revision/manual selection, access, model identity or
geometry. Multiple valid originals with the same selected name are ambiguous
and blocked; decorative models lacking the native structure are excluded.

Already in valid range means no position assignment. Otherwise, permitted native
area travel precedes a needed final positioning attempt. Native island
`Portal.Spawn`, ordinary surface `FastTravel.Spawn` and portal-return
`PortalSpawn` are distinct contracts. Missing geometry or an unsupported route
does not permit a guessed fallback. The prior build already included the
surface-height/native-area guard; this delivery does not claim that as a new fix.

Unopened interaction is measured from the actual Prompt with a maximum of
6.5 studs/the native prompt's configured limit. Opened interaction uses Root
within 16 studs, zero visible native prompts and the selected egg's nearest
unlocked-egg eligibility. Floor, slope, finite destination and full-avatar
collision clearance are observed before a guarded transform. Stable real
character position and unchanged native eligibility must establish arrival.
Assignment without error is only a positioning dispatch result.

Manual movement, respawn, invalidated target/access, cancellation or position
correction aborts without repeated snapping or restoration of an old CFrame.
Pause/Stop prevent stale movement. The diagnostic ends after its observed result;
success enables no hatch, equipment or collection action. Logs distinguish
`TARGET_SELECTED`, `AREA_TRAVEL_REQUESTED`, `AREA_ARRIVAL_OBSERVED`,
`DIRECT_POSITION_ATTEMPTED`, `DIRECT_POSITION_FAILED`, `ARRIVAL_UNCONFIRMED`,
`HATCH_RANGE_OBSERVED` and `TRAVEL_BLOCKED`. Its terminal result retains
TRAVEL_ONLY scope, zero hatch commands and zero spending.

## Reference comparison: useful mechanism, existing OC safeguards

The user-provided local `bgsi (1).lua` was read as data at lines 389–510 and its
Heartbeat hatch call site near line 632. It was not executed or uploaded. This
document records authored findings; the third-party script is not redistributed.

| Reference function/call | Finding and OC treatment |
| --- | --- |
| `moveTo(targetCFrame,duration)` | Defines a linear HRP tween, but the event egg's active path calls direct positioning. No tween controller is imported. |
| `teleportTo(position)` | Assigns HRP CFrame inside `pcall`, then returns true regardless of assignment error. Existing OC returns the actual assignment outcome and separately verifies arrival. |
| `getPartForInstance(inst)` | Accepts a BasePart, PrimaryPart or first BasePart descendant. The generic fallback cannot identify native egg interaction geometry; OC resolves the original Root/Prompt structure. |
| `checkNostalgiaEgg()` | Reads a summoned event platform and adds a fixed five-stud height. OC uses the selected supported native egg and observed floor/avatar/native-range geometry; this event offset is not a general standing point. |
| `goToNostalgiaEgg()` | Saves old position and replaces selection with a hardcoded event egg. OCBrain owns destination selection; no event-name priority or catalog-only destination is copied. |
| `returnToOriginalPosition()` | Restores an old CFrame/selection after event disappearance. OC releases stale authority and respects manual movement/current objectives without restoration. |
| `startNostalgiaEggMonitor()` | Creates an independent Heartbeat event chase. OC retains one scheduler owner and bounded attempts; no per-frame positioning loop is added. |
| Heartbeat hatch call near 632 | Repeatedly sends HatchEgg through a deferred flag without OC budgets/result evidence. The existing paced one-request/verification path is retained. |

The useful positioning operation was already present in
`GameMechanics:PositionSelectedEgg`; the reference does not prove it succeeds in
the owner's runtime. Existing OC already checked scheduler ownership, access,
target/character identity, finite transforms, standing clearance, cancellation
and stable Prompt/Root arrival. The demonstrated blocker was lack of an
executable paid intent, not an observed CFrame assignment failure. The genuine
new integration separates physical travel diagnostics from paid selection,
keeps structured scope/identity synchronized and exposes meaningful movement
stages/results without replacing that guarded adapter.

The existing adapter now rechecks its exact scheduler token, generation and
foreground lease after guards/dependency loading, refreshes the final original
model scan and skips positioning if the character entered native range during
those checks. Its actual `pcall` assignment path is exercised by regressions:
failure consumes the attempt and returns failure, while successful assignment
still reports observed arrival pending. Native area request logging occurs at
the adapter's actual dispatch site; preliminary adapter attempts are distinct.

## Test B: prepared one-hatch, ordinary reserve intact

[examples/Phase4OneHatchPrepared.luau](../examples/Phase4OneHatchPrepared.luau)
is an AUTO, one-egg/one-batch candidate in NORMAL mode. Per-egg and session
ceilings are **1,000 Coins**. All travel, equipment, pickups and unrelated actions
are OFF. No egg is hardcoded. The exceptional owner allowance remains
**OFF with zero allowance ceilings**. If a useful eligible egg is normally
affordable after full reserves and is already in native range, it can request
one hatch. With the owner's reported locked world/zero spendable Coins, an
honest reserve WAIT is expected; this template does not make a paid test happen.

Normal AUTO still reads current native cost, objective, complete owned benchmark,
storage/capacity, access/range, cooldown, native auto-hatch/presentation and all
ordinary spending limits. The native world cost and configured reserves are not
changed. Final server odds/variant/pity remain UNKNOWN; a zero-cost world egg is
not invented from a retained default or unsupported free/reward catalog entry.
No verified zero-cost native world-hatch adapter is delivered by this slice.

## Separate explicit OWNER_ONE_HATCH_TEST_ALLOWANCE

The optional category is default OFF:

```lua
OWNER_ONE_HATCH_TEST_SETTINGS = {
    OWNER_ONE_HATCH_TEST_ALLOWANCE = false,
    MAXIMUM_COIN_ALLOWANCE = 0,
    MAXIMUM_EGG_COST = 0,
}
```

Enabling it requires a separate owner-approved exact MANUAL egg name, Coins
objective/currency, one requested egg, positive explicit allowance and per-egg
ceilings, and the existing hatch/session ceilings. World reserve protection
stays ON. All travel actions remain OFF: Test A establishes physical approach
independently, and the allowance test dispatches only when already in range.
Incomplete owned inputs/ROI, inaccessible or unsupported eggs, native conflicts,
unknown price/reserve evidence and missing inventory capacity remain blockers.

This exception can draw only a capped portion of **currently held** Coins
earmarked toward the next native world. It preserves the configured resource
reserve and never changes the world's actual cost/goal. It does not subtract
the allowance from an unfunded one-billion requirement and assume the remaining
hundreds of millions exist. The planner reports normal reserve/spendable funds,
held world-goal funds, explicit additional spendable allowance and the requested
native price separately.

The actual exceptional draw is the portion of the requested price exceeding
normal spendable Coins. It cannot exceed the explicit allowance or currently
held world-goal Coins. The one account allowance is consumed before invoking the
paid command, including uncertain delivery. The shared ledger survives
Pause/Resume and OC script reloads **within the same client VM**; its scope is
not durable cross-client persistence. Client restart/rejoin can lose it. OC does
not claim otherwise or advise restarting to retry. Missing/corrupt ledger
evidence blocks the exception.

After consumption the exception cannot authorize another request; normal reserve
policy applies again. Actual received inventory and egg-counter observations
are required. Requested native price and observed net Coins debit are recorded
separately because native/manual/external earnings or spending can obscure the
exact server charge. An unresolved outcome remains consumed and stops; there is
no automatic retry or second hatch.

The delivered loaders do not opt into this exception. Before a later paid test,
the owner must approve the exact loaded egg, its refreshed native Coin price,
the requested exceptional Coin cap and whether to permit that limited draw from
held future-world funds. A separately reviewed MANUAL Config can then express
that approval. No general reserve overhaul or economic reinvestment policy is
implemented here.

## Owner checklist and evidence still needed

For Test A, check the displayed build, diagnostic scope and exact native target.
Observe any needed native area move, at most one guarded final-position attempt,
actual Prompt/Root proximity and stable arrival. Check zero hatch/equipment/
collection commands and no OC spending. Manual departure should produce no
snap-back. Return target, movement-stage and final arrival/blocker logs.

For prepared Test B, inspect benchmark completion/input status, native price,
normal reserve/spendable funds and its native range before requesting a later
allowance approval. A reserve WAIT with zero requests is valid. A later approved
MANUAL one-hatch test must show exactly one requested egg and matching actual
counter/inventory result, or a consumed inconclusive outcome with no retry.
Original equipped membership and all unrelated actions remain unchanged by OC.

Final compilation/regression count, new build/commit and anonymous public-byte
verification are recorded in the release delivery after checks finish. Offline
fixtures, reference/source inspection and mock positioning/counter evidence are
not live gameplay success. New owned-benchmark diagnostics, travel/standing,
result attribution, later useful equipment/continuation and compatible stationary
collection still require their applicable owner tests. Paid world/rejoin limits
remain open. Playtime, Mystery Boxes, anti-AFK, Mastery, events, Rifts and Phase 9
are excluded. Studio remains strictly read-only.

## Exact research reused

All completed research files are preserved. Their original research-only gates
and evidence scopes remain historical; current explicit instructions authorize
these fixes without upgrading source inspection into live acceptance.

| Research file | Finding applied |
| --- | --- |
| [native EGGS_AND_PETS](research/replicatedstorage/EGGS_AND_PETS.md) | Record/unit/equipped multiplicity, full-team coupling, variants/caps, actual egg structures, Prompt/Root range and result/storage interfaces. |
| [native ECONOMY_AND_ROI](research/replicatedstorage/ECONOMY_AND_ROI.md) | Owned benchmark; BuffUtil use/queue mutation requires isolated projections; real currency/reserve/time distinctions. |
| [native LOCAL_ARCHITECTURE_EVIDENCE](research/replicatedstorage/LOCAL_ARCHITECTURE_EVIDENCE.md) | Existing reader cache, one Brain/scheduler, mechanics adapter and serial verification are reused. |
| [native STAT_DEPENDENCY_EXTENSIONS](research/replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md) | Super coupled effects/shared-cache fidelity prevent unsupported unused-Super benchmark claims. |
| [native NATIVE_ACTION_CONTRACTS](research/replicatedstorage/NATIVE_ACTION_CONTRACTS.md) | Call prerequisites, dispatch, results and stop conditions remain separate; a remote name/return is not proof. |
| [native NATIVE_ACTION_CONTRACTS_NAVIGATION](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md) | Actual island, world-map surface, return and selected-egg contracts; missing geometry/unknown routes block. |
| [native WORLD_AND_NAVIGATION](research/replicatedstorage/WORLD_AND_NAVIGATION.md) | World/island access and observed physical destinations outrank static names; surface/return paths stay distinct. |
| [native UNKNOWN_AND_SERVER_ONLY_RULES](research/replicatedstorage/UNKNOWN_AND_SERVER_ONLY_RULES.md) | Source fidelity, hidden server validation and live account/geometry limits remain explicit. |
| [wiki README](research/wiki/README.md) | Existing substantive library and native-first owned/probability/authority conclusions are reused. |
| [wiki COVERAGE_REVIEW](research/wiki/COVERAGE_REVIEW.md) | Scoped research completion is not exhaustive source coverage, server validation or gameplay proof. |
| [wiki PET_TEAM_AND_ENCHANT_STRATEGY](research/wiki/PET_TEAM_AND_ENCHANT_STRATEGY.md) | Quantities/protections and native coupled-team utility constrain ranked seeds; heuristic bounds are not global optima. |
| [wiki EGG_PROBABILITY_RESEARCH](research/wiki/EGG_PROBABILITY_RESEARCH.md) | Conditional useful outcomes, normalized client weights, duplicate saturation and batch timing remain estimates. |
| [wiki NATIVE_VS_WIKI_CONFLICTS](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md) | Native/live access/coefficients take priority; wiki/decompiler conflicts are retained rather than silently repaired. |
| [wiki KNOWLEDGE_GAPS](research/wiki/KNOWLEDGE_GAPS.md) | Final sampler, variants, server routes/results and total-time/rate evidence remain open. |
| [wiki FUTURE_OC_IMPROVEMENTS](research/wiki/FUTURE_OC_IMPROVEMENTS.md) | Ranks 1/2/4/6/15 inform efficient owned benchmarking, confidence, reserves, conditional math and bounded replanning through one authority; general Phase 9 work stays deferred. |

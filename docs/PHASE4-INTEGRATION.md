# Phase 4 integration: AUTO selection, controlled arrival and one hatch

The owner authorized this implementation on 2026-10-12. The first gameplay
candidate is [examples/Phase4AutoOnce.luau](../examples/Phase4AutoOnce.luau):
automatic egg/team analysis, a Brain-selected destination, controlled travel,
at most one paid hatch and received-result verification. **Owner acceptance is
pending; Phase 4 is not complete.** The existing owned-team equipment acceptance
in [PHASE4.md](PHASE4.md) remains valid.

The owner-operated migration log confirmed build `005f77211830` loaded and read
actual Coins/Gems while remaining idle with gameplay actions OFF. That proves the
hosted migration baseline, not this new travel/hatch integration. The recovery
baseline, both completed research libraries and historical acceptance records
are preserved. The reported playtime auto-claim failure remains a separate,
excluded issue.

Release validation for build **`890d4713edad`**: `node scripts/build.mjs` and
`node scripts/test.mjs` pass official Luau compilation, **463 main-suite offline
cases**, deterministic bundle/initializer checks and merged Config isolation.
The first example pins `phase4-auto-890d4713edad`. All **104 research files** were
compared byte-for-byte with the complete pre-edit recovery backup and remain
unchanged. Public commit/tag/raw-byte checks are performed after publication and
reported in the owner's delivery; none of these checks proves live gameplay.

## First acceptance Config

The editable example enables `ENABLE_PET_INTELLIGENCE`, a Coins objective,
`AUTO_HATCH`, `EGG_SELECTION_MODE="AUTO"` and `HATCH_ONE_EGG_ONCE`. It needs no
manually selected egg name. Per-egg and session ceilings are **1,000,000 Coins**;
session and batch limits are **one egg**. A ceiling authorizes a maximum, not an
instruction to spend it. The 120-second session window includes travel and
pauses after location ownership starts.

The next native world cost and configured reserve remain protected.
Equipment, stationary pickups, ordinary farming, bubbles/selling, gum/flavor
purchases, world discovery/purchases, rewards, event actions and anti-AFK are
OFF. Selected-egg native island travel and guarded direct positioning are ON,
but cannot select a destination independently of a useful, affordable Brain
decision. An incomplete benchmark or unavailable reserve means WAIT with no
movement or spending.

The example uses the public function-returning `dist/OC.lua`, accepts custom
Config and needs no tokens, headers or authentication. Its generated release pin
must identify the matching published bundle. Final commit/build and public-byte
verification belong to the release delivery record; this document does not
assert publication before those checks finish.

## Owned inventory is the purchase benchmark

`GameKnowledge` reuses the verified reader dependency cache and detached
LocalData facts. `PetPolicy.Team` evaluates native full-team scores for the
actual objective with received IDs, XP, variants, enchants and `Amount` quantities.
Repeated equipped IDs retain their native stack-copy meaning. The existing
optimizer and equipment executor preserve protected equipped membership and
native total equip capacity; they do not add or replace Super copies.

Egg outcomes now use the strongest feasible owned lineup found by that bounded
search, rather than a weak manually equipped lineup. Current equipped score and
owned benchmark are shown separately. The search is a supported single-swap
heuristic, **not a proof of global optimality**, especially with coupled enchants.
The first Config permits up to 1,000 native team evaluations. Reaching the bound,
a native owned projection failure or an unknown owned definition/rarity makes
the paid baseline incomplete. Unequipped owned Super units require a supported
native Super-capacity/coupled-team benchmark and produce
`UNSUPPORTED_OWNED_SUPER_CONFIGURATION`. Advisory estimates can remain visible;
paid AUTO and MANUAL candidates are blocked.

For a supported base outcome, the existing native helper projects one normal
XP-zero acquisition through its best supported addition or single replacement
from the owned benchmark. It does not invent a received pet ID or change the
inventory. Useful duplicate outcomes can fill another slot; saturated copies
can have zero utility. No Index, recipe or rare-variant benefit is invented to
justify an otherwise unhelpful hatch.

## Selection, evidence and reserves

AUTO ranks actually loaded, accessible permanent native egg models joined to
definitions and current account access. Premium, event, admin and special egg
paths remain unsupported. Retained Assets/catalogs do not prove current live
availability. Analysis coverage is bounded and disclosed; it is not a guarantee
of the best egg across the entire game.

Within an authorized currency, useful native score gain per unit of cost is the
primary comparison and single-draw gain per cycle is the secondary comparison.
Native duration, hatch capacity, ordinary/digital storage, current price,
configured ceilings and protected spendable balance constrain eligibility.
Currency groups use the configured order without an invented exchange rate;
each paid session authorizes exactly one currency. MANUAL restricts actions to
`SELECTED_EGGS`; legacy isolated MANUAL hatching still requires exactly one name.
No useful eligible candidate produces a clear WAIT, never a random or
hardcoded-egg fallback. AUTO re-ranks after material account/result changes;
pending requests keep observation authority before any new selection.

Prices come from current native `StatsUtil:GetEggCost`, not a guessed catalog
fallback. `PetManager:Fresh` rebuilds the native progression graph independently
of whether world execution is enabled. The earliest locked world's known
currency cost is added to its configured currency reserve. Missing graph/cost/
currency evidence blocks affordability. Minigame Paradise's historical
one-billion-Coins requirement is not assumed as a fresh account goal or unlock.
Its current LocalData map entry and native graph are read again. OC does not
release a world reserve or purchase a world, Mastery or gum to make this test run.

Client weights are normalized conditionally as `p_i=w_i/sum(w)` using the
inspected native pool/sampler model. Expected single-draw gain is the weighted
sum of positive gains over the owned benchmark. Applicable client ordinary-luck
inputs are retained; final effective server odds, separate Secret/Infinity
transformations, joint variants and pity remain UNKNOWN. A client percentage is
not a certified server probability.

Single-draw time efficiency uses `EV/cycle`; multiplying this by batch size would
overvalue duplicate saturation. Batch team EV remains UNKNOWN. The reported
first-useful-batch estimate is `cycle/[1-(1-q)^b]`, conditional on independent,
stationary client base draws. It is neither measured gameplay time nor a
guarantee. Travel, presentation, verification overhead and actual earning-rate
ROI remain unmeasured.

## One scheduler owns the handoff

1. OCBrain makes a fresh useful and financially eligible HATCH decision, naming
   the original model, objective and selection mode. The same Brain passes that
   intent to `EggTravelManager`; the travel manager does not choose another egg.
2. Travel rechecks the selected identity, unlocked world/island, real native area
   destination and financial intent before moving. No world discovery/purchase,
   force-loading, pickup navigation or guessed route is introduced.
   A surface egg approached from an island also requires native area transport
   through the observed exact `FastTravel.Spawn`; an absent island annotation or
   unrelated `PortalSpawn` cannot authorize a direct vertical jump.
3. The existing `GameMechanics` adapter performs a permitted native area move
   and, where enabled, at most one direct positioning attempt supported by
   observed floor and full-avatar clearance. Direct positioning is a guarded
   transform, not a claimed native egg teleport. Unknown geometry/routes wait.
4. Continuous observed stability must establish actual native interaction range:
   unopened Prompt origin at no more than 6.5 studs/the actual native prompt
   distance, or opened Root origin at 16 studs with zero visible native prompts
   and the selected model owning the nearest unlocked-egg scan.
5. Stable arrival hands the existing `OC_GAMEPLAY` authority to PetManager and
   HatchManager. Fresh account/model/world/range, native cost, reserve, storage,
   native auto-hatch/presentation and cooldown guards must still permit dispatch.
   Guards that may yield are followed by final Config/account/cancellation checks.
6. Requested count/cost are recorded before the one `HatchEgg(name,count)`
   command. The existing scheduler then observes the result. A first-open request
   is always one egg. No second movement controller or hatch loop is created.

Manual movement or a changed target/access/character/geometry invalidates the
lease without snapping back. Attempts remain consumed; an explicit selection
revision is needed to rearm an interrupted attempt. A fresh AUTO target can
release stale destination authority; it never dispatches a stale paid hatch.
After arrival, ongoing range observation does not repeatedly reposition.
Ordinary world-map surface `FastTravel.Spawn`, island `Portal.Spawn` and native
portal-return `PortalSpawn` are distinct contracts. Missing surface fast-travel
geometry does not authorize substituting a return spawn or a wiki route.

## Received result, equipment and compatible pickups

A matching received `EggsOpened[name]` increase and compatible inventory quantity
gain are both required. Invocation, animation or balance reduction alone is not
a pet result. New IDs and existing stacks retain actual names, quantities,
XP/variants/enchants and separate balance observations. Counter/team changes
beyond the frozen request end continuation because external activity is unresolved.

Usefulness is measured against the frozen pre-hatch owned benchmark using the
actual received record, rather than later unrelated acquisitions or a newly
weakened equipped team. Unknown native attribution/stats stay UNKNOWN. A confirmed
non-improving pet is a successful hatch with no useful upgrade. An inconclusive
result or uncertain transport retains its requested budget and halts without
retry; late observations do not reopen authorization.

The preserved incremental equipment executor can replan from real received
inventory in a separately configured later session. Equipment has its own
authorization, command budget, native idle guards and exact received membership/
score checks. The one-hatch candidate forbids equipment changes and ends after
its single request/result.

Compatible stationary pickups are a separate, later acceptance setting. They use
the existing collector and genuine loaded eligible Coins/Gems at the owned egg
location. The current Coins/Gems objective selects the cluster; the approved
collector retains its existing handling of eligible mixed Coins/Gems IDs.
Serialized eligibility/idle checks
keep collection away from pending hatch/equipment/native presentation and from
the same hatch-dispatch slice. Existing pacing, ID deduplication, visual cleanup,
balance verification and cancellation remain in the collector. The hatch task
holds its location; farming preference cannot relocate it to The Void or Zen.
The first Config disables this feature, and advanced hybrid farming remains
deferred to Phase 9.

Pause/Resume preserve ledgers and deadlines; Stop ends the one-hatch authorization
and releases location without recalling an already sent request. Reloading creates
a new controller/budget and must not be used to retry an uncertain hatch.

## Owner acceptance and remaining work

Run the pinned first candidate in the owner's supported client runtime and keep
the compact 15-second summaries. Return these observations:

1. INIT build/account read and EGG_PLAN's objective, current equipped score, owned
   benchmark/status, selection explanation, native price, reserve and spendable funds.
2. With an eligibility/reserve/baseline blocker, zero OC movement and paid requests.
   A blocked first test is an accurate result; the reserve must remain intact.
3. If eligible, the selected model/area, any travel/position attempt and the
   `HATCH_RANGE_OBSERVED` stable native arrival. Manual movement should halt it.
4. At most one requested egg, followed by counter and actual inventory evidence
   in HATCH_RESULT, or an honest UNCONFIRMED result with no retry.
5. Original equipped membership remains unchanged and unrelated actions stay OFF.
   Pause/Resume/Stop retain their expected controls and spent/requested ledger.

Offline compilation/regressions and public artifact checks are separate release
validation. They cannot establish these gameplay observations. Further owner
acceptance is needed for controlled arrival, native hatch guards/cadence/debit,
actual variants/stacks, later useful-pet equipment, repeated bounded replanning
and compatible stationary collection. Native unused-Super benchmarking, stronger
search quality, measured total-time/rate economics and server-only odds remain
gaps. Phase 3 paid unlock/approach/rejoin limits and the playtime issue remain
open. No Phase 5 debugging, seasonal/Rift execution or Phase 9 implementation is
included. Roblox Studio tools remain strictly read-only.

## Existing research used for these decisions

Both completed libraries were reviewed and retained without rewriting their
historical research-only gates or source/claim ledgers. Current explicit owner
authorization permits this incremental slice, not new evidence or phase completion.
Fresh account/geometry and inspected native call contracts take precedence over
public strategy labels. Documented native/wiki disagreements remain visible;
damaged saved/decompiled expressions remain uncertain rather than being silently
repaired from a wiki coefficient.

| Exact research file | Decision carried into this slice |
| --- | --- |
| [replicatedstorage/EGGS_AND_PETS.md](research/replicatedstorage/EGGS_AND_PETS.md) | Native quantities, full-team stats, cap/protection boundaries, client pools, physical hatch/equip/storage interfaces and decompiler limitations. |
| [replicatedstorage/NATIVE_ACTION_CONTRACTS.md](research/replicatedstorage/NATIVE_ACTION_CONTRACTS.md) | Call shape, prerequisite, result and stop-condition evidence remain separate; a remote name alone is not a contract or success. |
| [replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md) | Selected-egg approach, island/map/return contracts, stable arrival and explicit unknown server-route limits. |
| [replicatedstorage/WORLD_AND_NAVIGATION.md](research/replicatedstorage/WORLD_AND_NAVIGATION.md) | Actual island Portal.Spawn and surface FastTravel.Spawn are distinct from PortalSpawn; nearest-world/height observations cannot prove access or occupancy. |
| [replicatedstorage/ECONOMY_AND_ROI.md](research/replicatedstorage/ECONOMY_AND_ROI.md) | Feasible owned baseline, useful acquisition value, currency separation, protected reserve and time/rate distinctions. |
| [replicatedstorage/LOCAL_ARCHITECTURE_EVIDENCE.md](research/replicatedstorage/LOCAL_ARCHITECTURE_EVIDENCE.md) | Corrects its documented equipped-baseline and `T/(b*q)` gaps while preserving one authority, reader cache, existing collector and verification. |
| [replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md](research/replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md) | Super coupled effects/cap and shared-cache fidelity prevent treating unused Supers or all boosts as confidently solved. |
| [replicatedstorage/UNKNOWN_AND_SERVER_ONLY_RULES.md](research/replicatedstorage/UNKNOWN_AND_SERVER_ONLY_RULES.md) | Saved workspace/source evidence cannot prove owner account state, live routes, final RNG or server acceptance. |
| [wiki/PET_TEAM_AND_ENCHANT_STRATEGY.md](research/wiki/PET_TEAM_AND_ENCHANT_STRATEGY.md) | Owned utility, quantities, protections and coupled-search limits; a feasible heuristic is not a global optimum. |
| [wiki/EGG_PROBABILITY_RESEARCH.md](research/wiki/EGG_PROBABILITY_RESEARCH.md) | Conditional useful sets, duplicate saturation, normalized weights and first-useful-batch math. Advertised egg labels are not universal odds. |
| [wiki/CLAIMS_LEDGER.md](research/wiki/CLAIMS_LEDGER.md) | Retains native/community conflicts and source quality; no wiki value silently repairs damaged native variant/XL/luck branches. |
| [wiki/NATIVE_VS_WIKI_CONFLICTS.md](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md) | Preserves ordinary luck/variant/XL and route disagreements; native inputs plus fresh observations outrank attractive public recommendations without certifying hidden server rules. |
| [wiki/KNOWLEDGE_GAPS.md](research/wiki/KNOWLEDGE_GAPS.md) | Server sampler, joint variants, Golden/Burst, live travel and result attribution remain owner/source verification needs. |
| [wiki/FUTURE_OC_IMPROVEMENTS.md](research/wiki/FUTURE_OC_IMPROVEMENTS.md) | Ranks 1/2/4/6 support the owned benchmark, uncertainty, reserve and conditional batch corrections; rank 15 informs explained bounded replanning through one authority. Later cross-system proposals remain deferred. |

The master roadmap, Phase 4, Phase 3 and Phase 9 reference pages and their returned
owner notes were read before this integration. A returned page body is not a
claim that inaccessible discussions or hidden comments were read. No Notion
completion checkbox or Phase 4 acceptance status is changed by this delivery.

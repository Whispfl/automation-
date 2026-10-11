# Phase 4: account-aware pets and bounded native actions

The owner explicitly authorized Phase 4 development in this task. Before planning
or coding, read the complete [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349),
[Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10),
[Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363), and latest
owner notes. The new explicit development authorization supersedes older deferral
notes. It does not authorize hatch spending or equipment changes in the first test.
No Notion checkboxes or completion claims were changed.

Validation: `node scripts/build.mjs` and `node scripts/test.mjs` pass **259 offline
regressions** (227 preserved + 32 initial Phase 4 cases), official Luau compilation, all
existing example Config checks, the new action-disabled pet Config, and the actual
single-bundle custom initializer. Public artifact verification is required after
publishing; these checks do not establish live gameplay results.

## Owned-team visibility and one-time equipment candidate

Owner feedback on build `56ba58b6d0d7`, commit `30b3bca`: analysis-only loader
ran on the **main account**, reading 19 records / 34 pets, seven equipped, native
Coins score estimate 117 -> 1,324. Coins 5,731,381 and Gems 906,870 stayed unchanged;
equip/hatch flags were false. This is analysis evidence only. It neither verifies
equipment nor establishes an 11.3x earning-rate increase.

The owner subsequently authorized the attached smart owned-pet team/equip-only
assignment. Master, complete Phase 4 and Phase 3 pages/owner notes were reread;
comments returned only `suggested_edits_status=not_enabled`, with no discussion
content. No Notion checkboxes were changed. Phase 3 carryovers below remain open.

This candidate passes **281 offline regressions** (259 prior + 22 new owned-team
cases), official compilation, both complete test Configs and the custom bundle
initializer. This remains **CODE PUBLISHED / READY FOR USER TEST** after push/raw
verification, not live equipment PASS or complete Phase 4.

- `[OC][PET][TEAM_PLAN]` prints the native equip limit, actual names/base IDs,
  variants, before/after estimate, record/quantity counts and bounded-search status.
  Optional `[OC][PET][TEAM_DETAILS]` shows each current/proposed native role stat,
  contextual removal marginal, stack copies, protection, each accepted full-team
  search improvement, unresolved definitions/helper failures and uncertainty.
  `PET_SETTINGS.LOG_TEAM_DETAILS` enables it once per changed report;
  `OC:PrintPetTeam()` requests detail. Both test Configs enable initial detail.
- Native `PetUtil:GetStats(pet, projectedProfile)` uses the proposed team too,
  including native XP, Shiny/Mythic/XL, enchants and team dependencies. Native
  `StatsUtil:GetCurrencyMultiplier` is the full-account client total. Per-pet
  marginals can overlap: never add them into an invented earning-rate claim.
- Test A is the default `examples/Pets.luau`: analytics ON, all actions OFF.
  Test B is separately selected `examples/PetEquipTest.luau`: AUTO_EQUIP=true
  and EQUIP_OWNED_TEAM_ONCE=true. The latter validates Coins-only, zero hatch
  budgets, hatching/background pickups OFF and all other gameplay actions OFF.
- The existing Brain preflights one fixed complete target before any request,
  checks budget for every necessary command and requires supported improving
  intermediate swaps. It fills free capacity before removing anything. The one
  existing scheduler/mechanics adapter executes single native commands and waits
  for exact received team-index/ID multiplicity. No bulk equip or team switch.
- Protect existing Locked, target, owner favorite/valuable IDs, Secret/Infinity and
  Shiny/Mythic/XL/Super copies from removal. Explicit PROTECTED_PET_IDS are excluded
  from new equips as well. Unknown definitions/rarities are preserved. Received
  favorite markers, if any, are conservatively preserved, but no native pet-favorite
  contract was found: owner favorites must be supplied in FAVORITE_PET_IDS.
  No lock/unlock, delete, trade, craft, fusion, consumption or hatch is issued.
- Recheck native objective, account identity/capacity, target ownership/protection,
  active membership and native benefit before each command. Compare actual received
  account facts again after potentially yielding guards, immediately before dispatch.
  Guard blocks do not charge a request; uncertain invocation does charge its ledger.
- Conservative one-second OC pacing is not a claim of verified server cooldown.
  Native Inventory:2140-2192 checks max equips then sends EquipPet/UnequipPet(baseId);
  stack UI appends selection suffixes but dispatches the same real base ID. Team
  switching exists at Inventory:2615-2637, but the test preserves TeamEquipped.
  Locked is inspected at Inventory:2229. ClickableButton has no demonstrated equip
  server cooldown. Server handlers/validation remain unavailable.
- `[OC][PET][EQUIP_RESULT]` records original and received membership, predicted
  old/new score, received native client total and command count. Exact target
  membership ends permanently for that controller. No improvement/budget block
  sends zero requests. Partial/mismatch/timeout results freeze without retries or
  automatic restoration. Received results cannot exclude manual/external actions.
- Pause prevents dispatch and retains pending evidence/continuation, deadlines and
  budgets. Resume rechecks facts. Stop consumes the one-time authorization permanently;
  an already sent command cannot be recalled. Re-running B creates a new attempt.

Owner test: run A first and inspect the real lineup/protections; then run B only
when deliberately authorizing equipment. Close trading/prompts/game frames, preserve
the same active team, and watch per-command `[PET][VERIFIED]` plus final EQUIP_RESULT.
Return TEAM_PLAN, detailed lineup, final result and actual equipped inventory.
No earning-rate comparison is part of this test; no hatch/egg-approach test required.

## Transition and verification scope

Preserve accepted summary build `150749dc7fb0` and all 227 prior regressions.
The owner accepted the 15-second summaries showing arrival at The Void, Coins
18,800 -> 19,550 and Gems 885 -> 955, with Unlock Minigame Paradise still active.
Those observations do not verify complete world progression.

Phase 3 remains open for **actual paid world unlock**, **automatic versus manual
gate approach**, **explicit leave/rejoin persistence**, and **unsupported later
island routes**. Starting Phase 4 is an explicit development transition carrying
these gaps forward, not Phase 3 completion or verification.

This delivery is the first incremental Phase 4 candidate. Offline fixtures are
synthetic. Native hatch/equip results, live guards, location coordination and
account-specific estimates still need owner-operated testing. Studio inspection
was read-only; no scripts, objects, Luau execution or play-state changes there.
The owner supplies PlaceId 85896571713843; the connected saved Game workspace
cannot independently establish its actual PlaceId.

## Native evidence inspected before implementation

| Source | Supported observation / limit |
| --- | --- |
| Shared.Data.Eggs/Pets and their native builders; Assets.Eggs/Pets | Native pool weights, pet definitions, cost/world/island/event/product fields. Retained event definitions do not establish a live event. |
| Shared.Utils.Stats.PetUtil:GetStats; StatsUtil:GetCurrencyMultiplier/GetBubblePower/GetMaxPetsEquipped | Account-aware stats including existing variants/modifiers. Helpers run on detached projections. Errors stay UNKNOWN; no fabricated multiplier fallback. |
| Client.Gui.LootPoolViewer:601-613; Shared.Utils.GetEggPool/ApplyMultiplierToPool/GetRandomWeightedItem | Reproduce client UI world/luck pool arguments and normalized weights. Additional server Secret/Infinity odds, variants, pity and final effective odds remain UNKNOWN. |
| StatsUtil:GetEggCost/GetLuckMultiplier/GetMaxEggHatches/GetHatchDuration | Actual account cost, native hatch capacity/duration and modifier-aware client estimates; not a server guarantee. |
| StatsUtil:GetUsedPetStorage/GetMaxPetStorage/HasDigitalStorage/IsInventoryFull:615-714 | Ordinary storage counts Amount; Digital Storage counts JSON bytes. Native fullness checks apply; digital requests limited to one egg, never bytes converted to slots. |
| ClientScript:616,879,926-931,986-1025; GetAutoHatchStatus:819 | HatchEgg(name,count), original Root range <=16, one initial hatch, NextEggOpenAt/native time, native auto-hatch conflict guard. Manual approach is required; no assumed egg-travel contract. |
| Client.Effects.HatchEgg:IsHatching:1796-1815; Shared.Framework.Utilities.Math.Time | Presentation/queue guard and native server clock; preserve native animations/speed. |
| Client.Gui.Frames.Inventory:2140-2192; Shared.Framework.Network.Remote | EquipPet/UnequipPet with real base inventory ID; duplicate equipped IDs represent copies from Amount stacks. No bulk swap API guessed. |
| LootPoolViewer AutoDelete reads; LocalData.Pets/Teams/TeamEquipped/EggsOpened | Native deletion entries must be empty before hatching. Received equipped multiplicity and egg-counter plus matching inventory delta verify observations; manual/external activity cannot be excluded. |
| Workspace.Rendered.Chunker original egg Models (Root/Prompt/Plate/Cost) | Native client removes Egg tags; interface-based loaded-scene observation excludes Generic visual clones. No hidden/unloaded egg availability assumed. |

Server handlers and server-only validation remain unavailable. Successful command
invocation and hatch animation are not verification of inventory/equipment.

## Implemented first slice

- Opt-in native pet/egg dependencies reuse the reader cache and GameKnowledge.
  Inspect the current account afresh; previous test accounts are not a baseline.
- Count distinct pet records and actual stack quantities separately. Evaluate the
  active team first by Coins/Gems/Bubbles or another configured supported role.
  Native full-team greedy search considers stacked copies, enchants and modifiers.
  It preserves locked/protected/target and unknown-definition pets and existing
  Supers; new Super equips are deferred. Bounded search is not a global optimum.
- Compare loaded, accessible permanent eggs by expected *incremental* base-pet
  team benefit after owned-team improvements, client useful-outcome/target-name
  probabilities, native cost and hatch cycle. Cost efficiency has no invented
  cross-currency conversion. Total travel/verification time remains UNKNOWN;
  cycle-time estimates are not total-time guarantees.
- Bounded hatching requires explicit AUTO_HATCH, selected egg names, one allowed
  nonpremium currency, positive per-egg/session cost caps and count/time budgets.
  Protect configured currency reserves plus the full next permanent world cost
  independently of selected travel destinations. Unknown reserves/space block
  spending. Count uncertain requests against the lifetime ledger; no retry on
  unknown delivery or acknowledgement timeout. Pause/Stop cannot reset budgets.
- Explicit AUTO_EQUIP uses one improvement at a time. A full team needs budget
  for both commands; acknowledge the exact unequip result before adding its
  replacement. Recheck current inventory/team/capacity/native benefit first.
  Timeouts or unexpected manual changes stop the transaction without retry.
- One existing OC_GAMEPLAY scheduler lease owns pet actions and observation slices.
  Authorized hatch ownership blocks stale farming/progression teleports. Manual
  movement never triggers position correction. Leaving native egg range pauses
  dispatch; bounded session time includes manual approach and pauses.
- Reuse the stationary collector and native cleanup for classified current-area
  Coins/Gems while the owned egg is in native range and area access/geometry is
  known. Pickup walking is absent. Pending hatch spending contaminates income
  samples, so net gains cannot invent pickup ROI. Missing native guards keep
  concurrent collection blocked honestly.
- Report received inventory gains, equipped IDs and best observed hatch using
  native role stats. No automatic crafting/deletion/fusing/consumable use or
  native auto-hatch toggling. Existing compact summaries and controls remain.

## First owner test

Run the complete [examples/Pets.luau](../examples/Pets.luau) configuration. It sets
pet intelligence ON and hatch/equip OFF, with zero hatch cost budgets. Progression,
farming, travel, bubbles, selling and upgrade actions are OFF for this inspection
test. This disables actions only in that supplied test configuration; it does not
remove the approved baseline or modify examples/Progression.luau.

Check the Phase 4 INIT build, PET ANALYSIS owned counts/team scores, and egg costs
and estimates. Walk manually near a permanent egg if scene streaming requires it.
Balances and equipped IDs should remain unchanged by OC. Native/manual gameplay
can still change the account. UNKNOWN values are blockers/evidence limits, not
estimates replaced with guesses. `OC:GetStatus().Pets.Analysis` exposes each egg's
outcomes, reserve, per-cost/per-cycle estimates, unknowns and current account ID.
Use existing Pause/Resume/Stop; no repeat control approval is inferred or demanded.

A later owner-selected action test must explicitly edit AUTO_EQUIP or AUTO_HATCH
and hatch name/currency/budgets in one complete Config, then observe actual result
acknowledgements. Re-running the loader creates a new controller and therefore a
new session budget; this is not a durable cross-loader spending ledger.

## Remaining Phase 4 and excluded phases

Continue incrementally after native/account diagnostics and owner live results:
broader goal-specific Index/quest/variant target reasoning, measured approach and
verification overhead for total time, better bounded team-search economics,
special/Super equip contracts, and safe optional crafting/deletion/fast-hatch
options require their own inspected interfaces and explicit owner configuration.
Current destructive flags are rejected if true, rather than silently enabled.
Existing selected base-pet name probability is an estimate, not a full Index,
rarity/variant guarantee or quest completion executor. Unknown server/pity rules
remain unknown. This delivery does **not** complete the full Phase 4 checklist.

Mastery purchasing, Rift/event execution, Bounty/XL execution and the complete
cross-system Phase 9 optimizer remain outside this slice/phase. Preserve the
working Brain/scheduler and approved collector as this work develops.

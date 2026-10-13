# Universal movement reliability — evidence and approval plan

Planning delivery dated 2026-10-13. **No runtime movement change is applied or published.** The current `100f2c1907ae` bundle, original successful Test A and later approved registration/functional exceptions remain intact. All spending, hatching, equipment and unrelated gameplay actions must be OFF in any later movement-only test. This plan grants no paid action or automatic retry.

## Acceptance boundary and evidence

The [first live hatch record](PHASE4-FIRST-LIVE-HATCH-MILESTONE.md) proves a controlled Common Egg receipt with manual approach on the owner's account. The owner reports movement succeeded on the brother's account and prior safe-standing failures on the owner's account. Successful Test A `0d5caa499c8c` observed 83.10 → 2.01 studs and one-second stable arrival, one direct attempt, no hatch/equip/spending. The previously withdrawn failed log is not used to diagnose that successful run. Neither this earlier success nor the manually approached paid hatch establishes universal travel.

Latest accessible Notion [master](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363) and [Phase 9 owner instructions](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358) were freshly reconfirmed before this investigation. Mastery-first policy does not authorize movement rewrites or paid actions. Existing libraries were reused without another broad research pass or modification.

| Implementation decision | Exact supporting evidence |
|---|---|
| One Brain/scheduler/adapter and current reader cache | [Architecture](ARCHITECTURE.md), [native/local architecture evidence](research/replicatedstorage/LOCAL_ARCHITECTURE_EVIDENCE.md), `TaskScheduler` cooperative cancellation ownership |
| Separate native area transport, physical arrival, discovery and purchases | [Native navigation contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md) sections A–I; [world/navigation evidence](research/replicatedstorage/WORLD_AND_NAVIGATION.md) |
| Carry the selected exact physical Instance through final approach | [Egg identity evidence](PHASE4-EGG-IDENTITY-EVIDENCE.md), [egg location evidence](PHASE4-EGG-LOCATION-EVIDENCE.md), `EggTravelManager:Validate`, `GameMechanics:PositionSelectedEgg` |
| Native interaction regions cannot be generalized into one egg radius | Native navigation contracts section I (`Activation` first eligible binding, horizontal `Root.Size.Y/2`, vertical <=10); [egg contracts](research/replicatedstorage/EGGS_AND_PETS.md); [native reward contracts](research/replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md), [existing local-feature source recheck](LOCAL_FEATURES_STUDIO_RECHECK.md) |
| Rifts need their own Instance/expiry/transport contract | [Native specialty/seasonal systems](research/replicatedstorage/SPECIALTY_AND_SEASONAL_SYSTEMS.md), [source ledger](research/replicatedstorage/SPECIALTY_SOURCE_LEDGER.md), [existing rift strategy](research/wiki/RIFTS_EVENTS_AND_OPPORTUNITIES.md) |
| Catalog height, world access and XZ zone membership do not prove floor/arrival | World/navigation evidence; native navigation contracts; `WorldStateTracker` and actual selected-root/standing observation |
| Do not substitute historical wiki gate/route/lifetime claims | [Native versus wiki conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), especially Seven Seas gate location and rift lifetime conflicts |
| Geometry, final approach and recovery remain evidence gaps | [Knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md), native navigation contracts section I, [future OC improvements](research/wiki/FUTURE_OC_IMPROVEMENTS.md) ranks 10/14 and later-phase acceptance |

## Current shared behavior and limitations

`OCBrain` selects the destination, `TaskScheduler` owns the foreground task, and `GameMechanics` is the sole action adapter. `TravelPlanner` handles progression policy; `WorldStateTracker` supplies observed area state. `EggTravelManager` combines egg-specific identity/access/range predicates with full-avatar standing geometry and a bounded lease. Automatic `Walk` remains deliberately unsupported. Reuse these boundaries; do not introduce another movement loop or restore pickup pursuit.

Current `EggTravelManager:ResolveStanding` (lines 422–482) already observes root size, Humanoid HipHeight, full character bounding box and its root-relative position/orientation, including accessories. Root height is `max(HipHeight + HRP.Size.Y/2, transformed avatar lower bound) + 0.15`; a fixed avatar-height workaround is unsupported. An upright candidate is checked with the full observed box, padded by `(0.3, 0.1, 0.3)`.

It samples the selected anchor center followed by four cardinal X/Z offsets at `min(4, range/2)`. Each downward ray spans target Y +/- range, excludes the current character and respects collision. Support must be a live collidable anchored BasePart with normal Y >=0.98. Standing must lie within `range - 0.25`, pass the existing destination/native nearest rule and have no collidable obstacle in the full-avatar overlap query. Collidable rendered geometry remains observable; folder/name is not a collision authority.

These conservative checks create explicit limitations:

- Five sampled sites do not cover the admissible standing region. A safe diagonal can be missed even while every retained guard passes at that point. This is demonstrated offline below.
- A single center support ray does not independently prove support under the whole avatar footprint or exclude an edge fall. The observed supporting floor is excluded from the overlap query. Footprint support and complicated floor geometry require further evidence; expanding samples does not resolve this safety question.
- Large/offset/rotated avatar bounds may genuinely make a small interaction sphere infeasible. Ignoring accessories or shrinking the body to force a pass would weaken the current clearance requirement.
- Terrain, unanchored/moving platforms and steep slopes are not supported by the present floor policy. No relaxation is proposed.
- Floor elevations outside the finite ray window remain unsupported. XZ-only island zone membership cannot certify vertical arrival. Correct native world/island arrival precedes final approach; no cross-world CFrame fallback is permitted.

`GameMechanics:PositionSelectedEgg` (lines 797–833) repeats current standing observation after other guards, rejects a changed destination beyond 0.25 studs, rechecks selected identity/access/range/lease/token and performs the sole CFrame assignment. Arrival observes actual root position within 0.5 studs of the requested point, variation <=0.35 studs and the configured stable interval (normally one second), with fresh guards. Request/assignment logs do not certify arrival.

Recovery deliberately halts after manual movement, respawn, changed target/geometry, canceled ownership or uncertain arrival. It neither restores an old position nor repeatedly snaps the character back. A consumed travel-only attempt stays bounded. Loading may permit read-only observation/revalidation before dispatch; it is not authorization to resend after an uncertain action.

## Prioritized implementation plan

| Priority | Work and completion evidence | Approval boundary |
|---|---|---|
| 0 | Preserve the new hatch receipt, original supplied console text/checksums, exact runtime pin and earlier milestones. Keep hatch/equip/spend OFF. | Completed documentation only; no new gameplay release |
| 1 | Review the demonstrated standing-search gap and exact proposal below. If approved, append four same-radius diagonal samples after the preserved five choices. Keep all eligibility/geometry/execution guards. | Separate approval of this protected `ResolveStanding` difference before implementation |
| 2 | Establish the owner's actual avatar and surface failure reason, then make only a supported correction. Capture full bounds, root-relative offset/orientation, HRP size/HipHeight/rig/scale, selected native range, each support result/normal/elevation, floor identity and overlap blockers, without modifying Workspace. Treat support, clearance, native range and unavailable observations separately. No claim that diagonal coverage caused the live failure. | Read-only inspection may reuse available sources/Studio reads; any runtime diagnostic edit needs a concrete scoped proposal; no diagnostic-only gameplay release |
| 3 | Prove avatar-footprint support and destination elevation handling using a representative offline matrix. Decide whether a separate support correction is necessary; show its exact minimum diff and preserve successful samples. Unsupported geometry remains blocked/manual. | Separate protected-method approval; no current footprint, height, raycast or clearance change |
| 4 | Specify a shared final-approach contract for later destinations, using current ownership, adapter and pure geometry boundaries. Add destination adapters only under their phase approvals; avoid a wholesale extraction/refactor of frozen working methods. | Design here; implementation outside this narrow proposal is not approved |
| 5 | Owner validates one bounded approach on the current avatar, then separately another avatar/scale and an elevated already-accessible destination. Broaden only after each result; future rifts/chests/shops/islands need their own native contract and approval. | Zero-spend movement only after the required code/test approval, not another Common Egg hatch |

The minimum shared contract should retain the exact destination Instance/session ID, anchor and world/area evidence, legitimate account access, native transition identity, destination-specific admissibility predicate, avatar/geometry observation, expected presentation, cancellation/lease generation, action limit and independent arrival evidence. A destination that changes identity/expiry or cannot establish these fields stays blocked. Shared geometry is reusable; a destination-specific eligibility predicate and native transition remain necessary.

| Destination | Native transition / final approach distinctions |
|---|---|
| Ordinary eggs | Already-selected physical original; initial Prompt versus opened Root ranges, exact loaded receiver membership, visual provenance and all-name nearest interaction rules |
| Islands / world surface | Catalog-supported island `Teleport(path)` versus native Spawn/FastTravel/PortalSpawn contracts; observed correct area AND final elevation/location; discovery is separate |
| World trampoline | Distinct `WorldTeleport(worldName)` behavior and transition/presentation; it is not an island path |
| Seven Seas fishing areas | DisplayName-based native fishing-area Spawn, access/level and final shoreline evidence |
| Future rifts | Actual registered rift model, live expiry/access/capability and verified `TeleportToRift(model)` contract; stop if target expires |
| Future chests | Exact registered chest and its own nearest/range/presentation contract; arrival grants no claim request |
| Future shops/facilities | Native `Activation` selects the first eligible binding, not the nearest egg; overlapping facility volumes can be ambiguous. Entering a volume may open its panel automatically, so expected UI and exact bound target must be verified separately; arrival grants no purchase |

The current shared GUI guard must not be relaxed to make facilities work. A future destination adapter needs an explicitly verified expected-presentation contract. None of these future actions is implemented or authorized by this plan.

## Exact minimal proposed protected-method change

The [exact patch](PHASE4-UNIVERSAL-MOVEMENT-STANDING-PROPOSED.patch) and [scope/hash manifest](PHASE4-UNIVERSAL-MOVEMENT-STANDING-PROPOSED.json) are **PROPOSED_UNAPPROVED_NOT_APPLIED** against runtime commit `aae628d9ac8f1941f9b0b92aaedc365be22fa6af` / build `100f2c1907ae`.

Patch SHA256: `b1131059a5b151fb699b04bbf1ae50365cbeddc9a6d2faa222d28edd42d3207f`.

Only the offset enumeration in `EggTravelManager:ResolveStanding` differs:

```diff
-		for _, offset in ipairs({ Vector3.new(0, 0, 0), Vector3.new(radius, 0, 0), Vector3.new(-radius, 0, 0), Vector3.new(0, 0, radius), Vector3.new(0, 0, -radius) }) do
+		local diagonal = radius / math.sqrt(2)
+		for _, offset in ipairs({ Vector3.new(0, 0, 0), Vector3.new(radius, 0, 0), Vector3.new(-radius, 0, 0), Vector3.new(0, 0, radius), Vector3.new(0, 0, -radius),
+			Vector3.new(diagonal, 0, diagonal), Vector3.new(diagonal, 0, -diagonal), Vector3.new(-diagonal, 0, diagonal), Vector3.new(-diagonal, 0, -diagonal) }) do
```

Original sample coordinates/order remain first, so a previously valid choice remains unchanged under the same observations. Added samples lie at the **same horizontal radius**, not farther out. Each still passes the identical floor/range/nearest/clearance checks. No coordinates, egg names, destinations, height formulas, collision filters, native travel, adapter, scheduler, arrival thresholds, retry policy or permissions change.

Search increases from at most five to nine candidates per resolver call. There are still zero assignments while searching and only the existing single guarded assignment on dispatch. The adapter's second observation also uses the resolver, so the two normal searches are bounded at up to eighteen ray candidates rather than ten. Changed geometry between those observations still blocks. This is limited coverage improvement, not exhaustive navigation or a guarantee that any avatar fits any site.

| Hash | Released before | Proposed after |
|---|---|---|
| `ResolveStanding` method | `4996169eb8641b238ac1e52b3784c57a9b690ddf3e47993ddbddb9e2b2fec09a` | `8d3129ec4a04c80964f36a0e5f15dc8bf83656618567e9b1a197ee409b893dda` |
| Whole EggTravelManager file | `7fd14d19e3befc895f3446f41d4882394d12eebc7bc555e5e8b05dd864e4cb8c` | `125fb8125a32c998ceb58e4bfa649d6d982e7f6a41da25ef3f8ac08064ecff20` |

`git apply --check` passes without applying it. The current file still has the released-before hash. If approved later, record this exact difference separately; never alter original Test A records to pretend the modified method is identical to the old release.

## Offline results, required coverage and preservation

The existing `node scripts/test.mjs` suite and official Luau compilation passed on the unchanged release during this task. This includes existing receipt/allowance/functional exception, receiver classification/registration/identity, travel guards/arrival, disabled-loader and historical preservation checks. The bundle is current and deterministic; no rebuild/release change was required to save documentation. The [preservation report](verification/phase4-live-hatch-movement-plan-preservation.txt) verifies all **47 runtime/source/bundle/loader files**, **104 research files** and **23 historical Phase 4 records** byte-identical to the current release baseline, with all three milestone tags unchanged and the console archives' hashes correct.

The new reproducible [offline standing proposal audit](../scripts/test-phase4-standing-proposal.mjs) compiles the actual released resolver and a proposal applied **in memory only** using official Luau. Eight audit groups passed per variant: all five original winner coordinates/query order; a supported diagonal missed by the released search; full collidable obstruction; R6-shaped lower bounds with zero HipHeight; tall-avatar legitimate range refusal; unanchored floor; steep slope; and unavailable observation runtime. It invokes no Studio/runtime game action and establishes no real physics acceptance. The complete regression suite has not been claimed to pass on an implemented proposal; implementation remains prohibited pending approval.

Before any approved movement publication, require:

1. Run official compilation and the complete regression suite, all receipt/registration/nearest/visual guards, distribution integrity and historical Test A movement preservation. Update only the affected synthetic query-count expectation (5 ->9) if the proposal is approved; retain baseline fixtures/hash records and verify old winners rather than rewriting history.
2. Add meaningful fixtures for R6/R15-like dimensions, changed HipHeight/root sizes, shifted/rotated full bounds, large accessories, elevated anchors, negative coordinates, stacked XZ-overlapping islands, absent/late support, normal threshold boundaries, noncollidable decoration versus solid obstructions, unsupported Terrain/moving platforms, edges/footprint support and geometry changes between preflight and adapter recheck. Mark simulated geometry as simulation.
3. Executor coverage: already in range yields zero assignment; native area arrival first; stale account/access/identity, nearer or tied eggs, native unavailable state, generation/token/lease mismatch, manual input, respawn and changed support block; one attempted assignment; requested position/stability must be actually observed; timeout/uncertainty never retries or restores an old position.
4. Instrument mocked action adapters to fail on hatch, equip, settings writes, purchases, claims, pickups, bubbles, selling or unrelated input. Require zero such calls throughout movement tests.
5. Compare all runtime files against `100f2c1907ae`; only the separately approved difference may change. Preserve `PHASE4-TEST-A-PRESERVATION.json`, prior membership/classification/functional approval records, all completed research bytes and original tags. Keep GameMechanics, target discovery/selection, Brain/scheduler ownership and arrival checks unchanged for the candidate-search proposal.

## Smallest next owner-run live test — conditional, not activated

After separate explicit approval of the exact protected-method proposal and all required offline/preservation checks, prepare one **TRAVEL_ONLY** approach on the owner's current avatar to the already-accessible, exact selected Common Egg from a nearby known safe starting location outside range. No hatch, equipment, allowance, spend, purchase, reward, pickup, bubble, selling, anti-AFK or other automatic action is enabled. Account-bound paid permissions remain false; monetary budgets stay zero. Keep one bounded travel attempt and no retry/snap-back. This is an approach test, not another hatch test.

Capture the exact candidate release pin, current avatar bounds/HipHeight/root geometry, exact selected Instance, support/clearance/range evidence and actual before/after position. Pass only on observed requested standing position, native physical range and stable arrival, followed by owner confirmation that the character stays correctly placed. A blocker records its precise available evidence; it does not trigger a new request or a weaker check. Pause/Stop must prevent dispatch; any manual departure ends the lease without restoration. Resume is not authority to repeat a consumed attempt.

If the owner's actual failure is not covered by the demonstrated search limitation, leave it unresolved and submit a different evidence-backed minimal proposal. Do not represent a diagonal improvement as the proven cause or universal fix. No new loader or diagnostic-only gameplay build is issued with this planning delivery.

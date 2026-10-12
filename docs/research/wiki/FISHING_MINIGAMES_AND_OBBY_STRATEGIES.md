# Fishing, minigames, board and Obby strategies

Research date: October 11, 2026. Public source records and classified comparisons are in [WORLD_SOURCES.jsonl](evidence/WORLD_SOURCES.jsonl) and [WORLD_CLAIMS.jsonl](evidence/WORLD_CLAIMS.jsonl). Root read actual article bodies and published tables; this specialist received focused findings. Direct Fandom/Reddit opens and this specialist's browser were unavailable. Search extracts are discovery only. Publication/revision metadata remains null where absent.

The saved native baseline is [FISHING_AND_MINIGAMES](../replicatedstorage/FISHING_AND_MINIGAMES.md) and its source ledger. These strategies compare opportunities; no fishing loop, macro, travel, completion bypass, OC code or gameplay request was introduced.

## Fishing: identify the actual bottleneck

The actual [Stats](https://bgs-infinity.fandom.com/wiki/Stats) tables match nine native rod base records and six bait effect definitions (W-C001–002). Those attributes are different objectives: catch speed changes waiting, power changes wall taps, reel speed changes holding, and luck changes selective pool weights. Higher displayed luck does not necessarily minimize level-unlock time or failed catches.

Native bite delay is uniform from3seconds to max(5/[baseCatch*(1+catchEffect/100)],3). Once baseCatch*(1+catchEffect/100)≥5/3, additional catch-speed upgrades no longer reduce that helper's waiting time. Reel speed is0.175*baseReel*(1+reelEffect/100); power is ceil(basePower*(1+powerEffect/100)). Actual reeling walls, local input, failures and received results still determine cycle time.

The [Fishing](https://bgs-infinity.fandom.com/wiki/Fishing) overview corroborates level50 at10million XP and the catalog counts, but its ordinary crate percentages omit Classic Crate and differ from normalized native raw weights (W-C017). Bait labels are effect values, not verified percentage-point increases. Galaxy Bait has an explicit Galaxy Crate helper branch; ownership, consumption and credited crate outcomes remain separate. The paid AutoFishing quote is an external catalog statement, not verified current price or purchase authorization.

For remaining XP D, measured accepted XP per fish x and productive time T per accepted fish, D*T/x is a rough funding-like estimate. Include failures, area changes, acquisition/setup and capped XP. A raw catalog expectation can explain a bottleneck, but cannot substitute for measured XP/time.

| Area | Required level | Total XP threshold | Raw mean base XP per one fish draw | Expected draws for its rarest raw pool entry |
| --- | ---: | ---: | ---: | ---: |
| Fisher's Island | Starter | — | 60.35 | 502.66 |
| Blizzard Hills | 2 | 225 | 363.51 | 3,328.03 |
| Poison Jungle | 8 | 47,425 | 1,676.57 | 6,668.60 |
| Infernite Volcano | 10 | 94,655 | 5,492.70 | 33,327.00 |
| Lost Atlantis | 15 | 319,020 | 9,240.50 | 67,512.67 |
| Dream Island | 20 | 738,815 | 9,228.85 | 101,165.50 |
| Classic Island | 25 | 1,404,565 | 9,212.37 | 201,423.00 |

These are independent calculations from saved FishingAreas/Fish, not public promises or server odds. Raw meanXP=sum(weight*baseXP)/totalWeight; rare expected draws=totalWeight/rarestWeight. Rod luck, mutations, modifiers, XP effects, success, multi-fish casts and altered pools are excluded. The reproducible numeric inputs are [FISHING_CATALOG_FACTS](../replicatedstorage/observations/FISHING_CATALOG_FACTS.json). Better accessible areas may advance XP much faster than completing the previous index, while similar late-area mean XP does not imply identical difficulty or useful rewards.

## Index completion, rods and quest opportunity cost

Actual [FishDex](https://bgs-infinity.fandom.com/wiki/FishDex) body and all seven tables corroborate20names per island and the seven native reward sets (W-C026). Every listed item belongs to one completed-island claim, not reward tiers. The starter/Blizzard/Jungle/Volcano/Atlantis completions offer different rods; Dream and Classic have different pet/elixir objectives. Full reward quantities are already preserved in the native document.

For independent unchanged raw probabilities p_i, expected missing entries after n accepted fish draws is sum((1-p_i)^n). This distinguishes broad collection progress from the expensive final entry. For example, native starter Lemon Shark weight0.2/total100.532 gives conditional mean502.66draws and about1505draws for95% chance of at least one. This is not a guaranteed Golden Rod completion time; all other entries, failures and modifiers still matter. Later raw rare entries can make index completion much slower than reaching the next level.

[Fish](https://bgs-infinity.fandom.com/wiki/Fish)'s mutation table agrees with native value/XP multipliers and rounded conditional shares (W-C031). The52.6/31.6/10.5/5.3% shares normalize weights5/3/1/0.5 after a mutation; they do not apply to every catch. Base5% is a helper constant. Damaged reconstructed mutation/XP assignments and uninspected final server sampling prohibit a confident final joint probability.

[Fishing Rods](https://bgs-infinity.fandom.com/wiki/Fishing_Rods) names quest and FishDex acquisition routes (W-C027). The rod base catalog has no vendor prices, and the saved fishing shop exposes bait/potions/powerups rather than a verified rod purchase contract. Do not budget a nonexistent purchase action.

[Old Sailor](https://bgs-infinity.fandom.com/wiki/Old_Sailor) describes random objectives after the initial chain and milestone rewards (W-C030). Those quest-specific milestones are external in this specialist's scope, requiring the dedicated quest native comparison. Compare remaining quest effort and received progress with index effort and the desired rod/item; unrelated quest stock or public milestones are not current account eligibility.

## Fishing action and result boundaries

World purchase, fishing level, area travel, shoreline geometry, registry-derived areaKey, owned equipped rod/bait, readiness and inventory are distinct prerequisites. Public area names do not replace the native registry key; its dynamic Id/UUID reconstruction inconsistency remains documented.

FinishCastCharge(areaKey,Vector3) carries the native target; precision is local, not an extra request argument. Local completion sends Reel(successBoolean). Received ReelFinished and fish/XP/bait/crate deltas establish results. Local success, bobber animation and journal display alone do not.

World/equipment/UI changes, death or cancellation can interrupt state and waste setup. A future scheduler must retain attribution for delayed results, stop future dispatches, release location and refresh actual native state on resume. Near-full inventory, failed catches and timer boundaries need owner observation. Journal sale previews have a missing Amount factor; use received Pearls delta rather than trusting a per-stack display.

## Minigames: entry currency, skip items and verified rewards

The actual activity articles and native definitions produce the following comparison:

| Activity | Saved Ticket price | Saved base cooldown | Public cooldown | Evidence |
| --- | ---: | ---: | ---: | --- |
| [Pet Match](https://bgs-infinity.fandom.com/wiki/Pet_Match) | 5,000 | 5 minutes | 5 minutes | W-C018 agrees; wiki Medium pair count is wrong (W-C019). |
| [Cart Escape](https://bgs-infinity.fandom.com/wiki/Cart_Escape) | 200,000 | 15 minutes | 15 minutes | W-C028 agrees on cost/cooldown; accepted win/bonus needs results. |
| [Robot Claw](https://bgs-infinity.fandom.com/wiki/Robot_Claw) | 2,500,000 | 20 minutes | 30 minutes | W-C020 is a version/source conflict. |
| [Hyper Darts](https://bgs-infinity.fandom.com/wiki/Hyper_Darts) | 5,000,000 | 20 minutes | 15 minutes | W-C029 is a version/source conflict. |

All four have a native one-SuperTicket cooldown skip. That consumed item is separate from Ticket currency affordability; skipping does not waive the entry price. Cooldown completion, remaining horizon, actual duration and failed runs bound usable attempts. Received account cooldown and StartMinigame FinishAt override stale public timing.

Pet Match grids6/12/16/24cards give3/6/8/12pairs; twelve cards cannot form four pairs. Cart stages/input windows and Claw GUID ownership require actual native state; Darts score goals and received timers cannot be replaced by generic spam/autoclick advice. Public highest-difficulty bonus descriptions are not verified drop receipts.

For a desired reward, conditional expected utility/run is actualRollCount*sum(rawNormalizedP_i*usefulValue_i)+acceptedBonusValue under an explicit utility/outcome model. Keep Ticket debit, consumed items and displaced earning-time vectors separate from this utility; subtract them only after defining a state-specific goal conversion with consistent units, never a fixed currency exchange. Unknown roll counts, failure rates and bonus distributions prevent a certified ROI. Compare a cheaper activity that supplies goal-relevant keys with a costly activity whose reward pool largely duplicates already-owned utility.

## Pet Match → Dice Key → Rift and the Claw funding myth

Native Pet Match DiceKey2 weight15/98.5 gives0.3045685expected keys per unchanged ordinary pool draw; Cart's equivalent is0.2024291. This can explain a player-facing reward-chain lead, but it is not keys per play. Each later Dice Rift opening adds current access, a correct key, possible summon costs, expiry, interaction and accepted payout. An elixir reward is worth only its marginal useful productive benefit.

Robot Claw SuperTicket1 weight1.4/95.91 gives0.014597ticket per unchanged raw draw. It would take68.507expected draws per consumed skip ticket to replace that item through this one raw pool channel. Actual accepted bonus mechanisms can change the result, but are unestablished. These weights do not prove an infinitely self-funding loop or refund after leaving.

Relevant Reddit leads were found, but both actual thread opens failed and no bodies were read (W-S031–032). Their search excerpts are not mechanics evidence. Historical nerfs, account milestones and unknown roll counts prevent transferring old self-funding claims. No macro recommendation was adopted.

## Board: weighted landing and foreground ownership

Actual [Board Game](https://bgs-infinity.fandom.com/wiki/Board_Game) corroborates weighted Dice/GiantDice/GoldenDice windows6/10/1 (W-C022). Its87tiles versus88savednumericnodes is a counting/version discrepancy; Start-node inclusion or topology may explain it (W-C023). The future runtime should read actual nodes rather than hardcode either number.

The shared helper overrides some raw node weights by type. From hypothetical native node1, ordinaryDice sees next-node weights[0.1,1,0.3,0.25,1.5,1.5], giving probabilities about2.15/21.51/6.45/5.38/32.26/32.26%. GoldenDice has only the next node in this helper. Choose the owned die type based on current recorded tile/window, item scarcity and goal; no native chosen-face/destination argument exists.

RollDice(diceName) returns Start/Roll/Tile, then native presentation leads to ClaimTile(). Received Board.Tile/TimesRolled and dice/reward deltas are result candidates. Stop prevents new rolls, while a dispatched roll may settle. Closing the UI neither proves a refund nor cancels in-flight ClaimTile.

The article's walk-away concurrent-hatching trivia remains external and owner-unverified (W-C024). Phase9 coordination is deferred. A future approved design must reconcile location, UI, active Board state, native timers and hatch ownership in one scheduler, with no separate loops or pickup movement.

## Obbys: access, legitimate completion and keyed chest

[Obbys](https://bgs-infinity.fandom.com/wiki/Obbys) corroborates the three Classic Island activities and base cooldowns (W-C025). Classic requires fishing level25 in the saved area catalog; entry, legitimate course completion and chest opening are separate.

Native Easy/Medium/Hard reward rolls1/2/3 and raw pool totals97.75/109.106/100.00006 are definitions, not guaranteed credited rolls or literal percentages. The native course timer, hazards, route/checkpoints and accepted completion need owner tests. End coordinates do not establish safe traversal. The local Complete label is optimistic.

Chest approach requires the actual Prompt within15studs and the corresponding owned key. ClaimObbyChest(keybind==3) selects a native single/multi control branch; exact server bulk cost/count is unknown. Opening animation is not payment/reward proof. No finish teleport, direct completion bypass, invulnerability or macro is inferred.

Wiki Stats caption caps for Obby/minigame timing/drops are external progression leads (W-C003), requiring native applied consumers and received account milestones before timing or ROI use.

## Required observations before any future execution

Record one legitimate action's current eligibility, price/skip cost, accepted start, timing, success/failure/cancellation, actual reward counts and account deltas. For fishing, additionally verify mutation/XP, stack sale and bait/crate consumption. For indices, confirm all completion items and claim flags. For Board, observe a roll settling after stop. For Obbys, establish a legitimate route and separate completion/key-chest receipts.

Missing server proximity, rate rules, roll independence, entitlement, refunds and persistence stay unknown. Reuse the central Brain/TaskScheduler, GameKnowledge cache, mechanics adapter, WorldObservation and verified LocalData service. No later-phase implementation was authorized by this research.

# World progression strategies

Research date: October 11, 2026. This is documentation, with no implementation or gameplay execution. Public evidence is recorded in [WORLD_SOURCES.jsonl](evidence/WORLD_SOURCES.jsonl); classified comparisons and exact native references are in [WORLD_CLAIMS.jsonl](evidence/WORLD_CLAIMS.jsonl). Root reviewed actual browser articles and forwarded focused findings; this specialist did not independently read those complete bodies. Article publication/revision dates were unavailable and remain null.

## Permanent progression and the gate conflict

The actual [Worlds](https://bgs-infinity.fandom.com/wiki/Worlds) article corroborates the three permanent worlds. Its approximate island heights track saved geometry more closely than the native catalog's Height fields (W-C005). Definition height, folder height and discovery contact center are different measurements; none establishes a minimum bubble amount or safe ascent route.

| Objective | Saved native cost and normal gate | Public comparison | Interpretation |
| --- | --- | --- | --- |
| Minigame Paradise | 1 billion Coins; Zen gate | [Minigame Paradise](https://bgs-infinity.fandom.com/wiki/Minigame_Paradise) agrees. Its earlier 10-billion price is historical. | W-C011: current saved cost corroborated; stale guides can delay a goal by budgeting the old price. |
| Seven Seas | 2.5 billion Coins; Hyperwave Island gate in Minigame Paradise | [Seven Seas](https://bgs-infinity.fandom.com/wiki/Seven_Seas) gives the same price but says Zen access. | W-C012: normal physical gate differs. Plan from verified saved client/scene evidence, then require fresh owner observations. |
| Seven Seas areas | Fishing levels 2/8/10/15/20/25 after the starter area | Seven surface fishing islands are described publicly. | World purchase, fishing level, area access, travel and casting are separate prerequisites. |

The Seven Seas disagreement concerns the normal saved physical gate. It does not prove the server independently checks Hyperwave discovery on every UnlockWorld request. The native caller sends a world name; the inaccessible server handler determines acceptance. Neither a familiar public location nor remote existence validates a direct purchase/travel call.

Native island discovery, world purchase, already-unlocked travel and interaction within a destination are separate actions. The map, island portal and world trampoline also have different argument shapes. Their guards, receipt boundaries and decompile limitations remain in [WORLD_AND_NAVIGATION](../replicatedstorage/WORLD_AND_NAVIGATION.md) and [NATIVE_ACTION_CONTRACTS_NAVIGATION](../replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md). Public height labels do not authorize replacing owner-tested teleportation.

## Funding the goal without spending its reserve

Let G be the purchase price, R an additional protected reserve excluding the same commitment already represented by G, B the actual balance and r a measured stationary net rate in the same currency. Count each obligation once. Conditional funding time is:

remainingTime = max(0, G + R - B) / r, for r > 0.

Coins unlock reserves are separate from Tickets and Pearls activity budgets. Balance is not gross production: hatching, potions, shops and other spending must be attributed. A guide's reported billions per hour cannot supply r for this account.

For an acceleration costing I, with unproductive setup/travel/verification time d and a supported new rate r1, compare:

directTime = max(0, G + R - B) / r0  
investmentTime = d + max(0, G + R - (B - I)) / r1.

For a continuing objective, the lost opportunity cost is I + r0*d. A demonstrated rate improvement r1-r0 repays it only after (I+r0*d)/(r1-r0) productive seconds, when r1>r0. Temporary boosts, event expiry, inventory limits or an already-funded goal can prevent repayment. Optimizing the best feasible team from already-owned pets may provide free gains first; native pet currency contributions are additive in their inner composition, so multiplying displayed pet labels is invalid. See [ECONOMY_AND_ROI](../replicatedstorage/ECONOMY_AND_ROI.md).

Before spending, record goal utility, cost currency/items, hard reserve, benefit horizon, credible rate change, setup cost and a received-result check. Unmeasured boosts can be hypotheses; they cannot be certified accelerations.

## Facilities, selling and stationary farming

Permanent discoveries open useful facilities: Outer Space enables the Mastery HUD; Twilight has a higher Coins selling factor; The Void has enchant/chest facilities; Zen has Shrine, potions, Genie and the next world gate. Hyperwave has the Seven Seas gate and a Shrine binding. Source access is separate from account eligibility and item affordability.

The actual [Overworld](https://bgs-infinity.fandom.com/wiki/The_Overworld) and [Minigame Paradise](https://bgs-infinity.fandom.com/wiki/Minigame_Paradise) selling ratios agree with saved station attributes (W-C010). Those base ratios do not prove final credited earnings. Native SellBubble passes no station argument, so actual location and unavailable server station selection matter.

Compare a station using the complete cycle: fill, approach/travel, accepted sale, return and any missed productive time. A larger sale multiplier need not win over that cycle. Protected Phase 1/2 behavior remains stationary Void for Coins and Zen for Gems; no pickup chasing or new selling route is implemented.

[Zen](https://bgs-infinity.fandom.com/wiki/Zen) has a material public/native pickup discrepancy (W-C013). Its Gem15 and Comet labels do not match conditional normalized saved weights. The native Zen total is 100.0002, so a weight30 Gem15 gives about 29.99994%, while the Comet weight0.0002 gives about 0.0001999996%, if the shared weighted selector is the unchanged server sampler. That condition is unverified. Saved zone Count is not a spawn rate, and neither conditional probability nor expected base amount gives Gems per minute.

## Shadow Realm naming and cost boundaries

[The Shadow Realm](https://bgs-infinity.fandom.com/wiki/The_Shadow_Realm) describes a permanent 2026 secondary hub with a 50,000-Gems entrance. [Shadow Realm](https://bgs-infinity.fandom.com/wiki/Shadow_Realm) instead explicitly describes a removed 2025 mini-event (W-C014). Its old egg/currency cannot be reused for the permanent hub.

The new hub is not one of the Worlds registry's five records; absence from that registry does not disprove a secondary zone. Native entry argument, payment result, unlocked flag and current hub event remain unverified here. A 50,000-Gems external entry quote also spends a different budget from Coins world purchases. It must be freshly checked before any future authorized spending.

## Future owner verification and coordination

A useful recommendation needs fresh actual world/area flags, live destination objects, the correct price/item currency, protected commitments and measured net rates. No personalized best route is asserted without those inputs.

The owner would separately verify island persistence, normal gate purchase and debit, received WorldsUnlocked, map/portal/trampoline arrival, accessible fishing-area travel, and sale balance/bubble deltas. A gate animation or map closure is not a receipt. Server order, proximity, destination whitelist, rate limits and refunds remain unknown.

Any later approved implementation must reuse GameKnowledge and its reader cache, WorldObservation, mechanics adapter and central Brain/TaskScheduler. Intentional egg travel requires a location lease through approach and hatch results; compatible stationary collection must not create a Void/Zen return oscillation. Phase 4 approval and Phase 9 coordination remain separate from this research.

# Phase 2 pickup-first test candidate

Phase 1 remains approved. Native pickup collection/respawns, blowing, selling and
island travel have owner evidence. The latest changes, reliable recovery, combined
profitability, upgrades and overall Phase 2 approval remain pending. No Phase 3 work
is implemented. The owner performs gameplay tests; offline tests are not live proof.

## Source evidence and diagnosis

The excerpt spans 15:02:50–15:04:04 and starts mid-run. Nine successful pickup
results show 11 disappearing targets and matching gains totaling 10,165 Coins.
Floating Island arrival is confirmed. At 15:03:23, selling reduced 1,750 bubbles
to zero and credited 7,000 Coins. Later ten blow requests filled the bubble. No
combined operation or Pause verification is demonstrated. Stop was logged.

The old isolated probe suppressed selling until it ended at 15:03:20. Sell was
selected at 15:03:21 and confirmed two seconds later. This explains much of the
29-second interval after the first full-bubble snapshot without proving scheduler
starvation. Island selection only filtered rankings, so visits 30–32 targeted the
excluded Overworld after selling. All three failed without credit. Movement
recomputes/backoff appeared, but successful recovery was not demonstrated.

Read-only native research covered ReplicatedStorage HUD blowing guards/selling
teleports, WorldMap destination calls, GetPickupZones, Assets.Pickups, pickup remotes
and the native active registry/client collector. No Luau was executed and no Studio
objects or play state changed. The saved Game session is owner-confirmed; actual
PlaceId and server validation remain unavailable.

## Behavior and compatibility

`FARMING_SETTINGS.FARMING_STRATEGY` accepts `PICKUP_FIRST` or `EFFICIENCY`. Central
defaults retain EFFICIENCY for compatibility. The next-test example explicitly uses
PICKUP_FIRST: eligible pickups are primary; native-guarded blowing cooperates inside
the same collection lease. Blocked blowing does not stop pickup work. Bubble-only
fallback remains available when pickups are unavailable. Island exploration remains
bounded by dwell/retry settings and does not introduce isolated arrival probes unless
`ISOLATED_PICKUP_PROBES` is true. No second scheduler or action loop is added.

Selected island/world restrictions gate actual pickup execution, including the
current island and stale queued work. Names and qualified world/island keys are
accepted. Empty selection retains unrestricted eligible-island behavior. Native
auto-collection during transit is incidental, not deliberately routed OC farming.

Selling may travel outside the farming selection. It preserves the eligible origin
as return intent. Return/enforcement precedes dwell, active sweeps and income
comparisons. A failed origin can fall back to another eligible destination; unavailable
travel remains explicit. Pause discards incomplete measurements/routes while retaining
return intent. Stop clears intent. Neither control produces new gameplay commands.

The stable sell-threshold clock survives mode changes. Full bubbles preempt optional
probes/travel and end pickup movement at the configured discretionary-delay deadline.
`MAXIMUM_COMBINED_SELL_DELAY_SECONDS` does not promise completed selling in six seconds:
native cooldown, travel, activation and credit verification have separate limits.
Confirmation waits during pickup work are shortened at that deadline. Missing stations
or native guards leave a clearly logged pending sale rather than hidden pickup delay.

Navigation can stop inside actual 3D native collection range instead of demanding
exact pivot arrival. Real progress permits yielding/replanning from actual position
across slices, bounded by `ROUTE_CONTINUATION_SECONDS` (24 seconds). Stalls retain
bounded recomputation and per-ID backoff. Late MoveTo failure events have no request
identity; geometry/progress determines failure. Native radius and movement remain
unchanged; no position/speed manipulation or direct pickup calls are added.

## Measurements and limits

Combined rate samples are added once after an empty-start fill/sale/return cycle,
with actual growth during pickup activity, matching pickup credit and sale evidence.
Time includes failures, waits, selling and return. Pre-existing bubbles, incomplete
cycles, observed spending and cancelled work cannot publish a complete combined rate.
Adequate sample time and current evidence remain required. Pickup activity samples
include failed collection attempts but exclude selling/return; their labels distinguish
them from complete-cycle rates. External rewards remain an attribution limitation.

Replenishment observations measure depletion-to-next-observed-model latency. Loading
or streaming can contribute. They do not establish a native respawn timer and no
longer inflate definition-based estimates. Unknown availability stays unknown.
Final decision reasons cite the final mode, not a candidate's discarded score.

## Next owner test

Run `examples/CombinedFarming.luau` for 5–10 minutes with purchases/equips disabled.
The separate upgrade gameplay test remains deferred. Send logs covering:

1. `[FARM][BACKGROUND]` actual growth and requests while pickup visits are active;
   `[PICKUP][TARGETS]` visit/cycle/IDs and matching disappearance/balance evidence.
2. `[FARM][SELL_TIMING]` threshold/dispatch age, native blockers and confirmed sale.
3. `[FARM][RETURN]` confirmed eligible arrival before deliberate pickup work resumes.
4. `[FARM][CYCLE]` completed and incomplete cycles. A first partial bubble is expected
   to be excluded; verify later empty-start cycles and adequate measured samples.
5. No deliberately routed pickups on excluded Overworld. Incidental collection while
   moving to or from the sell station remains native game behavior.
6. `[MOVE][CONTINUE]`, bounded recovery/backoff, replenishment and alternate-island
   decisions without repeated unproductive routes or rapid island oscillation.
7. Pause/Resume during movement and sell-return, then Stop. Read-only statistics can
   continue; OC movement and command production must cease until resumed/restarted.

Public loader behavior and the function-returning custom Config entry are unchanged.
Build/test and public-byte verification must precede each owner handoff.

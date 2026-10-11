# Phase 3 economic diagnostics and remaining completion gaps

Before code inspection and implementation, successfully reread the owner's
[Master OC Roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349),
including its latest Brain/ROI research notes, and
[Phase 3 page](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10).
No Notion status or approval was changed. Phase 4, Phase 5 and Phase 9 remain deferred.
Subsequent owner confirmation covers Pause/Resume/Stop and in-game economic
diagnostics. The [latest acceptance review](PHASE3-ACCEPTANCE.md) records these and
the default summary mode; detailed ECONOMY/BOTTLENECK output is available with
DIAGNOSTIC_SETTINGS.ENABLE_DEBUG_LOGGING=true. Persistence and paid purchases stay open.

## Evidence and economic finding

The owner confirmed five Overworld island discoveries in session, and in build
`fdda549304a0` confirmed discovery skips, the native billion-Coin Minigame Paradise
goal, native Void arrival, continuous stationary batches, visual cleanup and
actual LocalData gains from 0 to 1,300 Coins and 25 Gems. The 24.1-second observed
sample reported 2,858.87 Coins/minute. The remaining 999,998,700 Coins would take
approximately **5,829.8 hours / 242.91 days** at that unchanged rate. This is a
conditional extrapolation from a short sample, not a guaranteed earning rate,
per-request attribution, or evidence that the owner should complete that grind.
Other native collection/rewards may contribute to balance increases.

ReplicatedStorage definitions and client interfaces were inspected read-only
before the economic changes. Workspace observations describe facilities and
geometry; LocalData alone supplies account access, ownership and balances.

| Native evidence | Finding | Interpretation and boundary |
| --- | --- | --- |
| `Shared.Data.Worlds:127-152` | Minigame Paradise costs 1,000,000,000 Coins; Seven Seas costs 2,500,000,000 Coins | Runtime definitions supply costs; no cheaper unlock or fabricated shortage substituted. No inspected permanent world has a Gems cost; Gems regressions are hypothetical fixtures. |
| `Shared.Data.Gum:6-30`; `StatsUtil:GetBubbleStorage` | Stretchy Gum: 45 base storage for 25 Coins; Chewy: 125 for 250 Coins; Epic: 550 for 1,500 Coins | Capacity improvements belong to bubble production. They do not appear in the inspected pickup currency multiplier. Access/ownership/current base must be known before recommending a candidate. No purchase. |
| `Shared.Data.Flavors:39-55`; `StatsUtil:GetBubblePower` | Blueberry: 3 base bubbles for 25 Coins; Cherry: 8 for 500 Coins; Pizza: 22 for 1,500 Coins | Flavor improves bubble output. Effective power includes native modifiers and equipped pet stats; base values are not projected live income. No blowing or purchasing. |
| `StatsUtil:GetCurrencyMultiplier:227-356` | Uses equipped-pet currency stats and native buffs/modifiers; gum storage and flavor output are absent | The empty equipped team in the owner's log is a relevant earning-power limitation. Pet/hatching analytics and execution await Phase 4. No inferred pet yield or recommended egg purchase. |
| `Shared.Data.Mastery` | Buffs tiers include pickup range/walk speed; Pets tier 3 includes an extra equip slot, native cost 85,000 Coins | This may affect future capabilities, not verified stationary pickup income. Missing account levels remain unknown, not zero. Mastery eligibility/ROI and purchases await Phase 5. No Mastery action. |
| `Client.Gui.HUD:273-297`; Workspace Sell attributes | Overworld surface sell multiplier 2; discovered Twilight island sell multiplier 5, native default Coins | At equal eligible bubble amount, the native station factors differ by 2.5x. Net earnings, fill time, travel, return and actual payout remain unmeasured. This does not multiply pickup income. A separate authorized bubble/sell test is required. |
| `UpgradePolicy.Evaluate` | Existing upgrade logic requires observed bubble-sale income, effective native stat projections and resource/goal reserves | It already rejects pickup-only upgrade benefits. Economic recommendations add no purchase authority and do not replace this policy. |

The useful next research direction is earning-power improvement. The current
Phase 3 collector alone is not shown to fund the next world in a practical time.
Cross-system income optimization remains Phase 9. Automatic bubble actions,
selling, upgrade purchases/equipment changes, hatching and Mastery stay OFF.

## Added diagnostics, without another executor

`OCBrain:ProgressionEconomics` analyzes only its active, matching native world
goal. `WorldProgressionManager` calls it during existing scheduler planning,
using the approved LocalData balance reader and FarmingCoordinator's existing
stationary metrics and credit-evidence ledger. No new timer, loop or scheduler.

`[OC][WORLD][ECONOMY]` reports currency, native cost, fresh balance, reserve,
shortage, current permitted island, measured rate, sample duration/age and
conditional ETA. Insufficient, stale, nonfinite or wrong-currency samples leave
ETA unknown. It does not use pickup face values, bubble-sale income, another
island's historical rate or a hypothetical improved earning rate. Funding
completion is `FUNDED`; zero measured income has no infinite ETA. Existing
funding cancellation and the stationary collector are unchanged.

`[OC][WORLD][BOTTLENECK]` explains excessive ETA, the observed native pickup
multiplier if available, equipped-team count, and bounded read-only native
recommendations. It labels gum/flavor candidates as bubble-only, with pickup ROI
unverified. Accessible discovered island Sell attributes may be described, with
net yield/travel explicitly unmeasured. No recommendation changes a task.

Three UPPER_SNAKE_CASE `WORLD_SETTINGS` keys:

- `ENABLE_ECONOMIC_DIAGNOSTICS=true` enables these read-only estimates.
- `FUNDING_HORIZON_HOURS=24` is an adjustable diagnostic practicality threshold,
  **not** a game requirement, action permission, experiment timeout or farming cap.
- `ECONOMIC_LOG_INTERVAL_SECONDS=30` throttles repeated estimates. Goal/status/
  island changes can log earlier; the interval must be at least five seconds.

Latest analysis is available at `OC:GetStatus().WorldProgression.Economics`.
Pause/Stop clear the displayed estimate; Resume reevaluates the retained bounded
sample ledger with its actual age.

## Gate research, correction and limitation

Native `WorldMap:150-200` and `WorldUtil:110-115` support discovered-island portal
destinations and ordinary world fast travel. They do not expose a verified direct
destination at the world gate's Activation.Root. Searching the native client found
no supported gate-approach command. Wheel notification TeleportId usage does not
establish a world-gate contract. Zen's saved scene lacks a locally replicated
Portal.Spawn; prior owner-tested native island teleportation remains supported
with existing conservative arrival observations. Scene decoration/geometry alone
does not establish a safe walk/landing/return route. No Studio code was executed.

The Minigame gate is on Zen. Native `Client.Activation:357-360` requires horizontal
distance <= Root.Size.Y/2 (about 6.084 studs in the inspected scene) and vertical
difference <= 10. Its Root.CanTouch=false. Island UnlockHitbox contact is not a
world-purchase or gate-approach substitute. The existing manual-approach blocker
is retained. For an affordable, authorized objective already on its gate island,
`[OC][WORLD][GATE_APPROACH]` now reports the actual horizontal/vertical distances
and native limits. No walking, pathfinding, jumping or character repositioning.

A deterministic regression reproduced an actual adapter defect: selected gate
travel could dispatch after funds or purchase authorization changed. The adapter
now rechecks active Brain objective, progression/travel/spending switches, currency,
ceiling, actual funds plus reserves, request budgets/backoff and native guards,
including after dependency access and immediately before teleport dispatch.
Arrival still needs the existing bounded native geometry/stabilization proof.
World unlocking still requires correct `LocalData.WorldsUnlocked` acknowledgement;
payment, a request, contact or animation cannot prove it.

## Validation and completion gaps

The economic/gate delivery passed **211 deterministic offline regressions** (all
186 existing plus 25 economics/gate cases). The later logging-only delivery retains
these and adds 16, for **227**. `node scripts/build.mjs` and `node scripts/test.mjs`
also check official Luau source,
bundle and example compilation, public-example Config isolation and the actual
function-returning initializer. Fixtures, balances, geometry, timestamps and
server responses are synthetic. They are not live purchase or saved-state proof.
Public main and exact-commit bundle and examples are compared byte-for-byte by
`scripts/verify-public.mjs` after push.

Still pending:

- Owner confirmation of discovery persistence after an actual rejoin.
- Real affordable, explicitly authorized world purchase and correct account flag.
- Automatic physical gate approach: unsupported; explicit manual blocker retained.
- Later-world undiscovered-island navigation where the existing graph reports an
  unverified route; the tested contact discovery scope remains Overworld only.
- Owner's explicit Phase 3 approval. No later phase starts from this delivery.

## Owner-operated next test

Use the complete [Progression Config](../examples/Progression.luau): discovery,
actual-shortage farming and native farming travel ON; world spending OFF with
zero ceiling; gate-island progression travel, bubbles, selling and upgrades OFF.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/examples/Progression.luau"))()
```

1. Confirm existing received discoveries are skipped, `[OC][GOAL]` selects the
   genuine world requirement and `[OC][FARM][TRAVEL]` confirms Void arrival for Coins.
2. In current summary mode, observe `[OC][SUMMARY]` for actual balance changes,
   sample/age, shortage, estimated ETA and bottleneck. Enable debug explicitly to
   capture per-batch STATIONARY_RESULT and detailed ECONOMY/BOTTLENECK lines. Initial
   unknown estimates are expected. No billion-Coin grind is needed.
3. Pause, Resume and Stop are now owner-confirmed; this presentation-only change
   does not require another full controls test. A request already sent cannot be recalled.
4. Rejoin normally and capture received `AreasUnlocked` plus discovery-skip logs.
   Do not edit LocalData. This is the pending persistence test.
5. Do not enable spending for this test. If no real affordable world exists,
   gate/purchase branches remain offline-only. No `[OC][WORLD][VERIFIED]` is expected
   without an actual authorized world purchase and account acknowledgement.

# Four local OC features — owner test delivery

**2026-10-12 migration update:** the same source and both bundles now target
[Whispfl/automation-](https://github.com/Whispfl/automation-), branch `main`.
Use [MigrationVerify.luau](../examples/MigrationVerify.luau) for the default public
actions-OFF check, or retain the self-contained `OC.local.lua` with `TEST_MODE = "NONE"`.
The owner reports **playtime auto-claim failure awaiting investigation**; this task
preserves that issue without debugging it or claiming live success. The original
2026-10-11 local-only delivery statements below describe that earlier delivery.
Raw third-party source citations remain locally backed up and are excluded from
public publication; see [the evidence boundary](local-feature-studio-evidence/README.md).

Date: 2026-10-11. Build **005f77211830**. Status: **LOCAL CODE BUILT / READY FOR OWNER TEST**, not live-verified and not a completed Phase 5 or Phase 9. The explicit assignment resumes only selected-egg travel, playtime claims, owned ordinary Mystery Boxes and anti-AFK. GitHub access remains suspended. No fetching, pulling, pushing, publication, remote changes, Vercel work or Studio gameplay execution was performed.

## Run the one paste-ready file

Open **C:\Users\rmger\Documents\ChatGPT\roblox app\dist\OC.local.lua**. Its editable header contains Config and five selectable modes, followed by the entire matching bundle. Copy the entire file into the owner's already-supported client test runtime. It does not download code, call HttpGet/loadstring/readfile/loadfile, install game scripts, or require a public GitHub URL. The embedded bundle still returns the existing initializer accepting Config; the local wrapper invokes that same entry point.

The delivered header uses `TEST_MODE = "NONE"` so all actions start OFF. Change that one line for an isolated test. All presets keep hatching, equipment changes, stationary farming, bubbles, selling, purchases, world unlocks, crafting and destructive operations OFF, with zero hatch budgets. Omitted baseline settings retain validated central defaults; the complete action-isolation settings are explicit in the header. The source header is [LocalFeatureTests.luau](../examples/LocalFeatureTests.luau), and the normal function-returning artifact remains [OC.lua](../dist/OC.lua). Existing public examples retain their historical pinned releases; they are not the distribution path for this unpublished local build.

| Mode | Header edit and actual permission | Expected evidence |
|---|---|---|
| NONE | Leave the initial header unchanged | Read-only initialization and summaries; all four new actions OFF |
| A_TRAVEL | Set `TEST_MODE = "A_TRAVEL"` and `SELECTED_EGG` to the exact current permanent egg name shown in the native game or earlier EGG_PLAN | `[OC][EGG_TRAVEL] HATCH_RANGE_OBSERVED`, stable observed distance, no hatch commands and no spending; blocked/missing geometry reports manual approach |
| B_PLAYTIME | Set `TEST_MODE = "B_PLAYTIME"` | Eligible sparse indices only; `[OC][REWARD][RESULT] CLAIM_STATE_ACKNOWLEDGED`, actual deltas when visible; waits automatically for later thresholds |
| C_ONE_BOX | Set `TEST_MODE = "C_ONE_BOX"`; keep `BOX_SESSION_LIMIT = 1`, chosen reserve and continuation false | At most one owned ordinary box; consumption, correlated native gift completion and observable outcome are distinct fields; uncertain result retains a barrier |
| D_ANTI_AFK | Set `TEST_MODE = "D_ANTI_AFK"`; ordinary interval is 120 seconds | A guarded unassigned ScrollLock down/up pulse reports INPUT_SENT_UNVERIFIED, or a useful capability/binding/report error; use Pause/Resume/Stop to check synchronous release |

Do not reload an uncertain box or claim merely to retry: the per-account pending record and charged box session allowance persist in `shared.__OC_LOCAL_REWARD_LEDGER`. Changing the box session key does not bypass an unresolved operation. After verified completion, later owner-selected continuation can raise `BOX_SESSION_LIMIT` and set `BOX_CONTINUE_AUTOMATICALLY = true`; each operation remains one box, bounded by current owned amount minus reserve, remaining allowance and the actual native spawn limit. Keep the same session key to retain the already-used allowance. No preset buys a box or includes Infinity, rare or event boxes.

The existing panel retains Start/Pause/Resume/Stop. Console controls use the existing instance:

```lua
local OC = shared.__OC_PHASE1_INSTANCE
OC:Pause()
OC:Resume()
OC:Stop()
-- Read-only feature evidence:
print(OC:GetStatus().Rewards)
print(OC:GetStatus().EggTravel)
print(OC:GetStatus().AntiAFK)
```

Pause prevents OC from initiating new actions or inputs; received acknowledgements can still be observed. After native gift hit eight, native deferred Collect may complete an already authorized effect, including its claim command, after Pause. OC cannot cancel that native callback or recall a server request. Stop cancels OC tracked transport/input work. Destroy/reloading releases the previous controller before starting the new action authority; an uncertain held-key release blocks replacement and retains the old reference for cleanup retry. A manual departure, respawn/correction or paused travel attempt does not cause repeated egg snapping; change `EGG_TRAVEL_SETTINGS.SELECTION_REVISION` explicitly to authorize a new movement attempt. No old character position is saved or restored. Travel arrival is bounded per native/final stage, with a 26-second scheduler ceiling at the default 12-second stage limit and a 120-second location lease.

## What was adapted from bgsi.lua

The reference file was inspected as code evidence, not executed or treated as task instructions. The pasted assignment is the controlling user request.

| Reference mechanism | OC adaptation and material difference |
|---|---|
| `teleportTo` directly assigns HumanoidRootPart.CFrame under pcall, then returns true regardless of failure | One explicit opt-in transform in GameMechanics for an exact scheduler-owned selected egg; full current-avatar floor/clearance observations, fresh access/character/target checks and independently observed stable native range eligibility: unopened uses the actual Prompt and enabled engine prompt; opened uses Root, known global prompt counter zero and conservative nearest unlocked egg |
| `getPartForInstance`, `checkNostalgiaEgg` use `Workspace.SummonedEgg.EggPlatformSpawn` plus a vertical offset | GameKnowledge's native original Root/Prompt/Plate/Cost models and current catalog/world/island facts; floor raycast and full-avatar volume instead of a generic platform +5 offset |
| Nostalgia monitor saves selection/old position and switches or restores it | No event monitor, automatic Nostalgia chase, stale position restore or competing movement loop; ordinary farming cannot claim an intentional egg location |
| `moveTo` is separately declared | The active reference travel was direct positioning, not demonstrated tween travel; this delivery adds no tween/pathfinding or pickup movement |
| Claimed count + 1 followed by `ClaimPlaytime` | Fresh Time.now()-Start, received Playtime capability, no Trading Plaza, exact sparse `Claimed[tostring(index)]` and per-index eligibility; one pending claim with received acknowledgement |
| `UseGift("Mystery Box",10)` and repeated screen clicks | Native owned amount, protected reserve and persistent allowance; one box per operation. A read-only RenderGifts observer verifies public ID/name/position with reader epoch and new revision; the loaded registry maps BasePart instance to component, which has no Name field. Total registry count prevents unload-as-completion; guarded native Hit requires exact ID and InRange. No synthetic clicks or direct forced ClaimGift |
| Space plus R every 120 seconds despite “Jump only” text | Separately configurable scheduler-owned unassigned ScrollLock down/up pair. Fresh Settings collision, pending AFK report/reveal, typing/UI/camera/real input/hatch/travel and total gift guards; possible held key is tracked before dispatch and synchronously released. Native AFKReport ignores mouse movement; Space/R are not retained |

The single Playtime action uses the established InvokeServer arguments. Native `ClaimAllPlaytime()` exists, but its server eligibility/presentation semantics are insufficient to make it this implementation's automatic bulk path. No other reward, chest, code or paid World Reward is added.

## Architecture and attribution

GameKnowledge and the reader's existing dependency cache supply native definitions and received facts. The existing Brain arbitrates the feature intents; TaskScheduler owns one foreground task. GameMechanics alone dispatches commands, native gift hits and input/position operations. Managers create no independent gameplay loops. One read-only RenderGifts callback uses the existing reader cache/connection lifecycle; it dispatches no gameplay action. Playtime's one potentially yielding RPC has a tracked transport coroutine, positive lease checks before dispatch, a retained acknowledgement barrier and Stop/Destroy cancellation. Missing transport is rejected before a pending preparation; known undispatched preparations may abort, attempted uncertain requests cannot.

New ordinary rewards clear overlapping rate windows and exclude known pending/settling operations from every metrics entry point and stationary credit confirmation. A claim-state acknowledgement without observable payout keeps attribution uncertain. A 10-second postsettlement quiet window is conservative observation policy, not a proven maximum server grant delay. Later/manual/external grants can still contribute to balance changes; the existing UNPROVEN attribution language remains. The 15-second summary now identifies active local task, pending reward and attribution exclusion, selected-egg state and anti-AFK suppression/failure.

Existing equipment optimization/protections and hatch budgets remain the separate authorities. Egg travel grants no hatch permission and bypasses no world/island cost or unlock. The ordinary Void/Zen travel rules, stationary 32-ID batching/deduplication/cleanup and other approved behavior remain. Full hybrid/ROI integration, other Mastery/reward systems and unrelated gameplay changes are excluded.

## Evidence actually read and access limitation

Fresh Notion fetches requested discussion indicators and successfully returned enhanced Markdown for the master and Phases 4, 5 and 9. Owner notes and relevant feature/optimization/lifecycle requirements were read before planning/edits, with Phase 5 reread separately after combined-output truncation. This is not a claim to have read every historical footer/discussion. Pages remain marked unverified:

| Page | Returned last edit (UTC) |
|---|---|
| [Master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349) | 2026-10-11T01:03:50.410Z |
| [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363) | 2026-10-11T01:03:52.185Z |
| [Phase 5](https://app.notion.com/p/3f53d7e9278d8109bd34fb0cd2a5ea05) | 2026-10-11T01:03:53.709Z |
| [Phase 9](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358) | 2026-10-11T01:03:56.636Z |

Both completed research READMEs, relevant native source ledgers/action contracts, reward/consumable/native geometry findings and the existing architecture/source were consulted. Native references include ClientScript egg prompt/hatch ranges and WorldUtil/WorldMap, Playtime:99–135/369–376/394–404, Playtime data:37–40, PromptBuilder:297–383, Inventory:221–261, PhysicalItem:49–121/185–192/280, and PhysicalItem.Gift:156–175/206–270. [Stage 1 reward contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS.md), [reward findings](research/replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md), [gift findings](research/replicatedstorage/SHOPS_QUESTS_AND_CONSUMABLES.md), [specialty ledger](research/replicatedstorage/SPECIALTY_SOURCE_LEDGER.md) and [Stage 2 limitations](research/wiki/KNOWLEDGE_GAPS.md) retain their original evidence scope.

Initial delivery discovery returned `studios:[]`. After the owner activated MCP, it detected `681d6e17-4b4e-443e-8997-73c126b5e682`, labeled `place 85896571713843 Bubble Gum Simulator INFINITY.rbxl`, in Edit mode. Focused source and saved-scene inspection exposed and corrected gift-shape, AFK-input and egg-range gaps. The label does not independently establish the live game PlaceId or server behavior. [Follow-up source report](LOCAL_FEATURES_STUDIO_RECHECK.md) records exact scope and evidence. No Studio scripts/objects were edited, Luau executed, modules required there, inputs sent or play state changed.

Roblox documents [VirtualInputManager](https://create.roblox.com/docs/reference/engine/classes/VirtualInputManager) as an internal service, rather than a normal developer input API. This feature probes actual SendKeyEvent/ScrollLock availability and catches permission/call/release failures; it does not promise availability in ordinary LocalScripts or modify permissions/security. No literal ScrollLock binding was found in the inspected native handlers, and fresh received Settings must leave it unassigned. This is not universal Roblox/OS binding proof. API acceptance does not prove native InputBegan reception or idle disconnection prevention. Native activity can also cancel the game's already pending rejoin retry, so no absolute absence of native side effects is claimed.

## Tests actually run

`node scripts/build.mjs` produced both deterministic local artifacts. `node scripts/test.mjs` passed static checks, official Luau compilation, **409 main-suite offline cases** including **88 local-feature cases**: 17 egg-travel, 33 rewards, 25 anti-AFK and 13 integration cases. All existing 321 cases remain in the suite. The runner also validates existing example Configs, the actual function-returning entry, exact paste-artifact/header/bundle equivalence and all five selectable local Configs. The actual initializer also proves that failed tracked input cleanup blocks a replacement and a later invocation retries cleanup before assigning a new authority. [Full saved regression output](verification/local-features-studio-recheck-2026-10-11.txt) and [delivery hashes/report](LOCAL_FEATURES_DELIVERY.json) retain the final result.

New cases cover missing/locked/replaced targets, full-avatar clearance/ceiling, stable/delayed/corrected arrival, respawn/manual departure, zero travel hatch/spend, sparse/already-claimed rewards, delayed acknowledgement and cycle reset, insufficient quantities/reserves/native caps, uncertain consumption/results, gift identity ambiguity, Pause/Resume/Stop/reload budgets, cancellation/unsupported methods, positive dispatch leases, input failure/suppression/cleanup and non-pickup attribution across direct metric entry points. Fixtures are synthetic and did not run gameplay or test the owner runtime. Independent architecture review identified adapter/pacing/attribution issues; the root reconciled them before the passing run.

## Remaining owner verification

- A: actual native area travel, safe standing clearance and stable live hatch range; no costs/unlocks/hatches; manual departure/respawn/correction do not snap back. Current special/event/premium/Infinity egg eligibility has no verified travel adapter, so those targets report manual approach.
- B: received Playtime capability, synchronized Start/time, sparse exact keys, actual grants and later automatic eligibility without toggles. No server validation or durable reset/save proof follows from source tests.
- C: actual ordinary box deduction, received RenderGifts timing/identity, loaded BasePart component, native eight-hit animation and reward receipt. Fresh source now establishes the public representation, but live runtime acceptance and server result remain owner tests. Missing/malformed/conflicting identity, old revision/reader epoch, unloaded gifts or a mismatched component block input/continuation. After an acknowledged debit, outcome can remain uncertain and manual native completion may be needed; no repeated consumption is inferred. Automatic continuation requires consumption, previously correlated gift disappearance from the total registry and observable outcome. External/manual rewards cannot be categorically excluded.
- D: actual ScrollLock input/down/up permission, native input reception and long-duration anti-idle effectiveness. Check mapped-key, pending AFK report/reveal, typing, UI/gift/hatch/travel, locked-camera, real-input and unloaded-gift suppression. A possible key-down is tracked before the API call; release runs on completion/failure and every cancellation. An uncertain release prevents another key-down and controller replacement.
- Combined: selected-egg ownership against existing hatching and stationary collection, pending gift UI against hatch/input, cancellation/repeated loading, and account credit attribution. Existing hatch enablement, budgets and protection settings must be separately approved/configured; the isolated presets do not grant them.

Both research libraries are preserved byte-for-byte. The recoverable external baseline archive and exact changed-file list are recorded in LOCAL_FEATURES_DELIVERY.json. Git HEAD remains unchanged; all source/release changes are local and uncommitted.

# Phase 5 read-only reward schema addendum

This narrow source audit reuses the completed native/wiki libraries. Read-only `script_read` excerpts from the existing saved Studio workspace resolved specific schema gaps needed by reward intelligence. No source code was executed, Studio objects changed, player data collected, or gameplay request made. These are saved native client contracts; they do not establish current server acceptance or credited rewards.

Existing evidence: `docs/research/replicatedstorage/REWARDS_QUESTS_AND_EVENTS.md`, `SHOPS_QUESTS_AND_CONSUMABLES.md`, `DATA_SCHEMAS.md`, `NATIVE_ACTION_CONTRACTS_NAVIGATION.md`; `docs/research/wiki/REWARDS_SHOPS_AND_QUEST_STRATEGIES.md`, `NATIVE_VS_WIKI_CONFLICTS.md`, `KNOWLEDGE_GAPS.md`, `FUTURE_OC_IMPROVEMENTS.md`.

## Clarifications

- `ReplicatedStorage.Client.Gui.Frames.DailyRewards:411–415` reports a lost streak when `LastDay` precedes the native absolute UTC day. Login visibility requires no lost streak and a false claim value. The intelligence adapter requires an explicitly received boolean; a missing value remains UNKNOWN. `:470–473` derives the seven-day position and bounded Stars display. Prior-day state is a recovery blocker, not permission to invent rollover or forfeit. `DailyRewardClaimStars`, the paid Stars shop, and streak forfeit remain distinct.
- `ReplicatedStorage.Client.Gui.Frames.Quests:202–208,255–269` checks achievement prizes with `ClaimedPrizes[definition.Key] ~= nil` and `Requirement <= PrizesUtil:GetProgress(profile, definition.Type)`. False-but-present claim entries count as claimed. `ReplicatedStorage.Shared.Utils.PrizesUtil:12–40` reads Stats and received prize-baseline metadata. Missing baselines or failed getters remain UNKNOWN. Achievement prizes are separate from ordinary active quests.
- `ReplicatedStorage.Client.Gui.Frames.ChallengePass:451–464` searches an array of claimed tier-number values and reads received `Rewards[tier]`. Read-only membership inspects exact values with `pairs`, including sparse entries. `ReplicatedStorage.Shared.Data.ChallengePass:16–27` exposes the catalog ID and `FinishTime.UnixTimestamp`; expiry uses that current runtime definition and the native clock, with no hardcoded historical deadline.
- `ReplicatedStorage.Shared.Utils.Stats.ItemUtil:419–498` is a reviewed read-only owned-amount getter. Powerups use the received name map (`:466`); Potions use records containing Name, optional Level and Amount (`:468–474`). This is different from the historical nested potion shape used by the existing RewardsManager facts helper. That protected execution helper remains unchanged. New intelligence normalizes the native record schema independently and reports duplicate, malformed or unsupported records as UNKNOWN.
- `ReplicatedStorage.Client.Gui.Frames.WorldRewards:268,276,296–302` requires strict true world-unlock values and uses `WorldRewards[world].Progress`; only `Progress+1` is the next paid tier. Missing progress is not zero. Native Cost/Reward definitions and existing reader storage observations are reported separately from permission and server grant-space requirements.
- `ReplicatedStorage.Shared.Utils.Stats.QuestUtil:325–338` corroborates exact-equality completion. Missing progress is not zero. Sequential task shape is required before declaring the native client requirement complete; ordinary reward delivery and generic claim timing remain UNKNOWN.
- `ReplicatedStorage.Client.Effects.PhysicalItem:92–121` exposes a chest count, while the exact public loaded registry getter is gifts-only. Chest interaction still uses a private registry and nearest/range/animation checks (`:197–257`). Native `Rendered.Chests` location representations are insufficient to verify physical interaction identity. The adapter reports location/access observations with interaction UNKNOWN.
- `ReplicatedStorage.Client.Gui.Frames.WheelSpin:66–111` keeps spin presentation and queue settlement separate. The inspected source provides no received wheel-queue schema. Missing queue information is UNKNOWN, not proof of an idle or settled operation.

## Excerpt integrity

These SHA-256 values cover the exact UTF-8 text returned by `script_read`, including its displayed line numbers and any tool note. They are excerpt hashes, not full original-module hashes. No original source extract or private owner console data is included in this document.

| Source excerpt | SHA-256 |
|---|---|
| DailyRewards UI 400–548 | `ee789b20c99820f9df763aa35d33d153d974578c854c8d9fe362c02809925058` |
| Quests achievement UI 165–330 | `ee2adf96ed06a67b1af750186ef31d1bdbbd88da6004058fae32fff774bed698` |
| PrizesUtil complete source 1–105 | `d0baa05425f543f7ff60d8ecbd18e84330d5c220bf9cd7233821c9cc42d017c4` |
| ChallengePass catalog 8–84 | `36bf4cb5c2e84c596c07432828a01150c773ddcf586adb6b9f77303cc12e2613` |
| ChallengePass UI 430–475 | `5a9142d18f0d9a4a03f19d140594ceb9dd2518da9255b1ad45f2398af8751e10` |
| PhysicalItem 90–260 | `ed26baf492b88fa081b59ee8f918509d9692b7b54f04a0268ed8f4fffff3f6c9` |
| WheelSpin 66–111 | `7e0844a5eceda0f8cf8922c3627585c114eb4300f948bad605c3c604565b7775` |

Historical wiki gift quantities, World Reward quantities and flat Infinity Chest cooldown statements remain version-dependent. Runtime native definitions and fresh received state take precedence. Catalog benefit labels and pool weights are possible outcomes, not realized payouts, final odds, measured income, or permission to claim or consume.

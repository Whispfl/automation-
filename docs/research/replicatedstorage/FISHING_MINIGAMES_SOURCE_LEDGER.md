# Fishing/minigame source ledger

2026-10-11 read-only saved source audit. Reconstructed source line numbers below are returned Studio script_read references, not upstream repository line numbers. Bytecode comments filtered; complete third-party source not persisted. Full Notion Phase 7 (`3f53d7e9278d81ea9ba7ef232227ab4a`) read after master, Phase 3 and Phase 9. Current research-only user instructions supersede historic implement/publish checklists.

## Batch 1: complete shared context reviewed

| Full native path under ReplicatedStorage | Returned lines | Evidence ranges |
| --- | --- | --- |
| Shared.Data.Fish | 148 | 140 records8–147; metadata inconsistencies122/128–147 |
| Shared.Data.FishMutations | 41 | records10–13, id/weight construction14–40 |
| Shared.Data.FishingAreas | 190 | pools13–181; gates/rewards35/58/81–90/113/136/159/182 |
| Shared.Data.FishingBait | 28 | effects22–27 |
| Shared.Data.FishingLevels | 61 | titles1–50 at10–59 |
| Shared.Data.FishingRods | 31 | attributes11–19, maxima20–30 |
| Shared.Data.FishingRodEnchants | 149 | effects/weights15–65; normalizedchance66–83; labels85–148 |
| Shared.Data.FishingRodEnchants.Poseidon | 37 | full visual effect lifecycle reviewed; no numerical modifiers; not invoked |
| Shared.Data.FishingWorldBuffs | 17 | stat schema11–16 |
| Shared.Data.FishingWorldWeather | 20 | Clear/Rainy11–12, weights13–19 |
| Shared.Data.FishingWorldTime | 10 | Day/Night8–9 |
| Shared.Data.FishingBobbers | 20 | sole Test Bobber19 |
| Shared.Data.Builders.FishingBuffBuilder | 113 | Stat10–72, mutation73–82, rarity83–92, conditionals93–112 |
| Shared.Utils.FishingUtil | 1009 | constants33–54; pool126–409; helpers410–537; roll538–596; buffs597–845; area848–873; mutation874–915; inventory916–954; time955–986; visualmodel987–1008 |
| Shared.Utils.FishingAreasUtil | 129 | Id validation/Zone/uuid55–97; registrysignals124–128 |
| Shared.Utils.BoardUtil | 211 | saved physical Nodes24–57; weighted tables59–75; routing77–114; items115–145; serverluck199–210 |
| Shared.Data.Minigames | 79 | costs/duration/cooldown/rewards12–75; suspicious flagtarget76–78 |
| Shared.Data.Obbys | 91 | Easy12–32, Medium33–59, Hard60–90 |

ExperienceUtil and native local fishing lifecycle have now been reviewed and documented in Batch 2 below. Fetching/metadata alone is not considered a fully analyzed action contract.

Known reconstruction limitations: FishingUtil GenerateFishPool duplicated flow/nil weight assignments; RollFish discarded mutation/XP assignments and reversed-looking New flag; GetAcquiredMutations resets its index to nil at883. Do not convert them into claimed runtime behavior. Wrong initial attempted ExperienceUtil path under Framework.Utilities.Math was absent; dependency established correct path Shared.Utils.ExperienceUtil and fetched it. No live server handlers available through these sources.

## Batch 2: native actions, timing, journal, board and Obby callers

ReviewDepth describes semantic review depth, not permission to execute anything. DEEP_CORE means all accessible core source context, dependencies and relevant mechanics were reviewed; visual loops were read but not necessarily proven exhaustive. TARGETED means the listed behavior/ranges only. Machine-readable NAVIGATION_FISHING_SOURCE_COVERAGE.jsonl consolidates80 unique reviewed sources across navigation and this specialty, with contentsFetched, sourceContentExtent, reviewDepth, functionsScopesReviewed and docRef. The team's 701-module metadata inventory is a separate wider source fetch, not equivalent to80 deep audits.

| Full path | Returned line count | ReviewDepth | Reviewed scopes |
| --- | --- | --- | --- |
| ReplicatedStorage.Shared.Data.FishingAreas | 190 | DEEP_CORE | 35 starter,58 blizzard,81-90 jungle,113 lava,136 atlantis,159 dream,182 classic;183-189 fish references validated; 7Pools20names each; gates and one-island multiple-item CompletionRewards13–182; reference validation |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingWorldIslands | 138 | DEEP_CORE | 27-77 buttons;83-107 level UI;121-137 Activation; Physical IslandTeleport binding121–137; destination64–70; levelvisibility94–104; Spawn dereference |
| ReplicatedStorage.Client.Gui.Frames.Minigames | 879 | DEEP_CORE | 271-287 Activation tagged Minigame attr; Entry/difficulty/cost235–389; skip444–459; cancel502–524; Start payload547–596; receivedFinish640–723; StateChanged742; cooldown789–795; native cleanup anomaly802–813 |
| ReplicatedStorage.Shared.Data.Fish | 148 | DEEP_CORE | 140 catalog records8–147; XP/Value/Rarity/Area/Preferences; field mismatches |
| ReplicatedStorage.Shared.Data.FishMutations | 41 | DEEP_CORE | Mutation ids/relative weights/value/XP/shrine factors, validation14–41 |
| ReplicatedStorage.Shared.Data.FishingBait | 28 | DEEP_CORE | Effect values22–27; acquisition/consumption unavailable |
| ReplicatedStorage.Shared.Data.FishingLevels | 61 | DEEP_CORE | All50title/color records10–59; no extra XP bonuses |
| ReplicatedStorage.Shared.Data.FishingRods | 31 | DEEP_CORE | All9rod attributes11–19; derived maxima20–30 |
| ReplicatedStorage.Shared.Data.FishingRodEnchants | 149 | DEEP_CORE | Effect families/tiers, weightedpool15–65; chance66–83; noWeight exclusions; presentation85–148 |
| ReplicatedStorage.Shared.Data.FishingRodEnchants.Poseidon | 37 | DEEP_CORE | Full rainbow Highlight visual effect lifecycle; no hidden numerical effect |
| ReplicatedStorage.Shared.Data.FishingWorldBuffs | 17 | DEEP_CORE | Stat schema11–16 |
| ReplicatedStorage.Shared.Data.FishingWorldWeather | 20 | DEEP_CORE | Clear/Rainy metadata, relative weights, Queueable=false, emptyEffects |
| ReplicatedStorage.Shared.Data.FishingWorldTime | 10 | DEEP_CORE | Day/Night identifiers |
| ReplicatedStorage.Shared.Data.FishingBobbers | 20 | DEEP_CORE | OnlyTestBobber19; empty effect collection |
| ReplicatedStorage.Shared.Data.Builders.FishingBuffBuilder | 113 | DEEP_CORE | Stat/ExtraMutationChance/FishRarityChance/Conditional builder schemas |
| ReplicatedStorage.Shared.Data.Builders.LootPoolBuilder | 35 | DEEP_CORE | new/Add/Build store raw relative weights; no normalization |
| ReplicatedStorage.Shared.Utils.ApplyMultiplierToPool | 46 | DEEP_CORE | Multiplier predicate, optional compensation; total-weight change without fourth predicate |
| ReplicatedStorage.Shared.Utils.ExperienceUtil | 66 | DEEP_CORE | Threshold/level/progress/capped XP;5-step ceiling; L50 edge |
| ReplicatedStorage.Shared.Utils.FishingUtil | 1009 | DEEP_CORE | Constants33–54; GenerateFishPool126–409; rolls538–596; stats448–537; buffsources697–845; mutation874–915; inventory916–954; time955–986; model987–1008 |
| ReplicatedStorage.Shared.Utils.FishingAreasUtil | 129 | DEEP_CORE | Tagged registration/Zone/UUID53–97; Added.Id vs registryUUID96; exported area lookup/removal |
| ReplicatedStorage.Shared.Utils.BoardUtil | 211 | DEEP_CORE | All node overrides/scene dependencies, weighted window77–114, rewards/Rift/chance arrays, ServerLuck199–210 |
| ReplicatedStorage.Shared.Data.Minigames | 79 | DEEP_CORE | All costs/durations/cooldowns/raw reward tables; Darts key mismatch76–78; MetadataScore0–100 |
| ReplicatedStorage.Shared.Data.Obbys | 91 | DEEP_CORE | All3cost/key/cooldown/completion/reward catalogs; raw sums and rolls |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingAreas | 103 | DEEP_CORE | Raycast include-filter, Root→UUID/id mapping69–84, remove87–101; corrupted multiplier visual50–62 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingInput | 6 | DEEP_CORE | Native mouse/touch/ButtonR2 action set |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingTypes | 11 | DEEP_CORE | Dependencies/type-only returnnil; no action contract |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods | 148 | DEEP_CORE | Existing-player world creation/teardown75–102; empty onAdded112; ForceCancelCast116–134; Update136 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods.RodComponent | 285 | DEEP_CORE | State/event transitions76–131; CharacterAdded148–156; equipped attributes187–239; teardown |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods.FishingEvent | 6 | DEEP_CORE | Native event identifiers |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods.FishingState | 6 | DEEP_CORE | Native state identifiers |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods.RodComponent.States.Local.Idle | 388 | DEEP_CORE | Account/inventory/GUI guards90–113; raycast127; manualBeginCastCharge210–231; native auto gate258–344; cleanup |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods.RodComponent.States.Local.Charge | 312 | DEEP_CORE | Precision/target91–139; autorelease172; cancellation206; raycast225–246; OnLogic270; cleanup |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods.RodComponent.States.Local.Casting | 109 | DEEP_CORE | Anchor48–50; marker55/.75fallback68; transition/bobber103–104 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods.RodComponent.States.Local.Waiting | 100 | DEEP_CORE | ReelReady(_,fish)59–67; native auto pass84; cleanup98 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods.RodComponent.States.Local.Reeling | 601 | DEEP_CORE | Rarity/power/reel186–194; Reel(bool)289; ReelFinished333–372; auto/input423–470; countdown495; cleanup525 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods.RodComponent.States.Shared.Unequipped | 82 | DEEP_CORE | Stop animations57; unanchor61; HUD/auto63–67 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingPlayerRods.RodComponent.States.Local.Reeling.ReelMinigame | 256 | DEEP_CORE | Wall difficulty/health/positions46–88, inputgate/damage167–198, progress/decay/failure216–248 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingWorldAutoFish | 100 | DEEP_CORE | Localtoggle/event, purchase prompt, nativeWorld visibility; no paid purchase invoked |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingHotbar | 213 | DEEP_CORE | FSM/HUD/GUI selection guards49–59; Equip/Unequip143–145; journal159; world reset201 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingJournal | 172 | DEEP_CORE | UI mounts Items/Rods/Index/Info; frame tab lifecycle |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingJournal.FishingJournalRods | 306 | DEEP_CORE | Owned RodInventory277–289; selectionSetEquippedRod103/guard114; Favorite128; no purchase cost |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingJournal.FishingJournalIndex | 507 | DEEP_CORE | Pool-based denominator52–64; globalclaim99; allislandrewarditems209–220; areaClaim235; collection/mutation flags and corrupted update315–353 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingLevel | 104 | DEEP_CORE | XP/level/progress display39–59; passmultiplier70; bait inventory82–91; worldvisibility101 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingWorldWeather | 143 | DEEP_CORE | Actual Workspace attribute observe127–139, currentweather35, visual lifecycle; no schedule mutation |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingWorldWeatherFrame | 117 | DEEP_CORE | Normalized odds61; forecast300s epoch seeded windows77–90; WeatherMachine Activation106–115 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingWorldTimeOfDay | 58 | DEEP_CORE | 600s day/nighttime31–38; native lighting presentation; worldcleanup51–55 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingRodEnchant | 540 | DEEP_CORE | EnchantRod()invoke/debounce; oneStone/currentRod89/322–356; rarityconfirm225–286; exclusiontypo55–56; probabilitydisplay489–511; physicalbinding528–537 |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingJournal.FishingJournalItems | 871 | TARGETED | SelectionId48; bait245–248; fishlock432–446; unlockedsale476–514; inventory UI675–871; omitted unrelated item rendering |
| ReplicatedStorage.Client.Gui.Frames.Fishing.FishingJournal.FishingJournalInfo | 209 | TARGETED | Mutation chance displays58; TotalFishCaught71; HighestCatchStreak118; FishCatchStreak129; update38–209 |
| ReplicatedStorage.Shared.Utils.Stats.BuffUtil | 344 | TARGETED | GetValue330–343 adds PercentValue/100; Format314–328; no complete independent stats audit |
| ReplicatedStorage.Shared.Framework.Utilities.Math.Time | 241 | TARGETED | now26–32 Workspace:GetServerTimeNow; epoch boundary/classification dependencies |
| ReplicatedStorage.Client.Gui.Frames.Minigames.Pet Match | 381 | DEEP_CORE | Cards/pairs/grid197, shuffling148–171; actualinputguards302; match243–257; finish225/257; cleanup363–378 |
| ReplicatedStorage.Client.Gui.Frames.Minigames.Cart Escape | 1102 | TARGETED | Config66–69; progress/input/reset694–751854–1102; not exhaustive rail generation/projection |
| ReplicatedStorage.Client.Gui.Frames.Minigames.Robot Claw | 718 | TARGETED | Config/setup1–105; toy/cycle104–330; cleanup/items430–718; middle input330–429 not exhaustive |
| ReplicatedStorage.Client.Gui.Frames.Minigames.Hyper Darts | 997 | TARGETED | Difficulty/layers1–76; finish275–322; input439–473; score/splitting/bonus607–737; timer/cleanup939–997; collision/projection only metadata |
| ReplicatedStorage.Client.Gui.Frames.Board | 1908 | DEEP_CORE | Weighted previews195–281; activity entry/cleanup484–520; RollDice839–844; resolved visuals/ClaimTile858–1077; auto1117/1316/1902; piece move1553; LocalData Board1826–1872; no exhaustive visual timing proof |
| ReplicatedStorage.Client.Gui.Frames.Obbys | 725 | DEEP_CORE | Entry/cooldown95–221; physicalbindings246–259; LeaveTeleport394–403; chest480–537; nativehazards/complete597–643; receivedBegan/End662–708; visuals290–353 also reviewed |
| ReplicatedStorage.Client.Gui.LootPoolViewer | 1733 | TARGETED | fromObbyChest1117–1203; MultiChest/keybind labels1184–1202; numericactivation1399–1415,1552–1570; other specialty pools not comprehensively audited |

### Deliberately unreviewed dependent behavior

The full team inventory fetched metadata for all exposed scripts; this specialist did not deeply review the following related visual/multiplayer/helper modules. Their existence is not validation and no source completeness is claimed: Board.Dice/Number/Director; Fishing.FishingMultiplayer/FishingTopVisualEffects/FishingHotbar.HotbarItem; FishingWorldWeather.Clear/Rainy; RodComponent.BobberManager/RodVisual/Animations; States.Local/Multiplayer/Shared mounting modules; every States.Multiplayer.*; Local.Charge.TrajectoryBeam and Local.Reeling.FishCaught/FishNotify; FishMutations visual child modules. Director184 was fetched here but not semantically analyzed. Local state flow/actions, helpers and account observation boundaries are established by reviewed callers; omitted presentation cannot prove rewards or new server guards.

Assets and Remotes first-pass inventory/dependency references are the parent's full hierarchy/metadata inventory. Native requests use the reviewed generic Remote wrapper rather than an exposed independent gameplay handler. No server-only handler, original source restoration, live callback execution or account values were available to this audit.

### Scene batch

- All29 saved FishingArea models and Roots inspected, catalogId match and sizes/positions recorded; no runtime raycasts.
- All88 numeric Board.Nodes inspected, rawType/rawWeight and BoardUtil effective weights recorded.
- SevenSeas Temple.Activation.Root and MinigameParadise.Activation.Root inspected; their unusual thin-X Root geometry participates in generic cylinder interpretation, not standard XYZ box occupancy.
- ClassicIsland.Obbys physical portal/Activation hierarchy searched; Easy/Medium/Hard course Spawn/Complete/KillBricks/Chest/Chest.Prompt inspected and saved.
- Search beneath MinigameParadise at depth8 found only world/merchant/Hyperwave Gate/Shrine Activations; Rendered keyword search for Match/Claw/Darts/Minecart found no match. This targeted absence does not prove the whole game's activity interactables are absent; names/tags, dynamic registration or unloaded/chunked objects may differ. No geometry-based minigame reachability contract was asserted.

Source anomalies are preserved in FISHING_AND_MINIGAMES.md: fish metadata vs Pools; UUID vs Id dynamic registration; duplicated/nil GenerateFishPool; discarded mutation/XP assignments; reverse-looking New; GetAcquiredMutations nil index; sale preview missing Amount factor; Abyssla Rod typo; enchants original denominator; Darts wrong disable key; Board rift total71.3/raw percentage labels; cleanup/finish timing uncertainty. All server rules remain unknown until supported owner observation.


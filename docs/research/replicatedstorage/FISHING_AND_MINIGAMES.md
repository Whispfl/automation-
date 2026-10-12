# Fishing, board, minigames, and Obbys research

Research date: 2026-10-11. Scope: accessible saved native source and saved scene only. Studio was read-only; no gameplay calls, module execution, play-state changes, OC edits, builds, tests, Git operations, or publication. Full Phase 7 planning page was read; its historic implementation/publication checklist does not authorize implementation in this research assignment. Phase 7 and advanced Obby behavior remain future work requiring owner approval and live verification.

This document records native shared catalogs, mathematical helpers, local rod lifecycle, journal and activity contracts, and saved scene observations. Static catalogs do not demonstrate that an activity is active, reachable, or accepted for an account. LocalData alone supplies player facts; no personal account values are recorded. Full source was fetched for core modules; targeted review and unreviewed visual dependencies are listed in the source ledger and coverage JSONL.

## Catalog structure and fishing progression

`Shared.Data.FishingAreas:13–182` contains seven area pools of 20 entries each. Every entry has `Item` and relative `Chance`, not a guaranteed percentage. Native areas are starter/Fisher's Island (no RequiredLevel), blizzard/Blizzard Hills (2), jungle/Poison Jungle (8), lava/Infernite Volcano (10), atlantis/Lost Atlantis (15), dream/Dream Island (20), and classic/Classic Island (25). See navigation documentation for actual destination resolution and independent world access. CompletionRewards lists multiple items for one island claim: the native JournalIndex iterates every item (209–220) and sends one ClaimFishingIndexRewards(areaId) (235). They are not reward tiers.

| Area | Completion rewards in catalog order |
| --- | --- |
| starter | Golden Rod; 5 Infinity Elixirs; 3 Secret Elixirs |
| blizzard | Blizzard Rod; 10 Infinity; 5 Secret |
| jungle | Lotus Rod; 12 Infinity; 7 Secret |
| lava | Molten Rod; 20 Infinity; 15 Secret |
| atlantis | Trident Rod; Bermuda Triangle pet; 15 Secret |
| dream | 30 Infinity; 25 Secret (two items) |
| classic | Classic Dogcat; 50 Egg Elixir; 50 Secret |

`Shared.Data.Fish:8–147` has 140 records, each with base XP, Value, Rarity, Icon, Area, and empty Preferences. No record in this saved catalog sets Requirements or Bonuses. Preserve source inconsistencies: Sky Lionfish says Area=atlantis despite dream pool; all classic fish are marked dream except Classic Clown Clownfish marked atlantis. `FishingUtil.GetFishForArea:848–873` filters the Fish.Area field, while catching uses FishingAreas.Pool. JournalIndex builds its fish lists from Pools (52–64), giving a verified native display denominator of 140 distinct names and 20 per island. These views can disagree; do not silently repair catalog fields or equate the journal display with verified server claim acceptance.

## Rods, effects, mutation and environment catalogs

Rod base attribute order below is CatchSpeed, RodPower, ReelSpeed, RodLuck (`FishingRods:11–19`).

| Rod | Base attributes |
| --- | --- |
| Wooden | 1, 1, 1, 1 |
| Steel | 1.2, 2, 1.5, 1.25 |
| Golden | 1.5, 3, 1.5, 1.5 |
| Blizzard | 2.5, 5, 2.5, 1.75 |
| Lotus | 1.5, 3, 1.5, 3.5 |
| Molten | 2, 8, 2, 3 |
| Trident | 2.5, 10, 2, 3.25 |
| Galaxy | 2.5, 8, 2.5, 3.5 |
| Abyssal | 3, 10, 2.75, 4 |

MaximumAttributeValues is derived by scanning the catalog (20–30), not an account cap or server upgrade rule. This module contains no purchase prices. Higher luck does not dominate every objective because bite speed, wall power, and reel speed differ.

`FishingBuffBuilder` produces three scalar effect types: Stat (`Stat`, `Value`), FishRarityChance (`Rarity`, `Value`), and ExtraMutationChance (`Mutation`, `Value`); Conditional has weather/time predicate plus Effects. `FishingUtil:697–845` gathers rod effects, equipped rod enchant tier, equipped bait and bobber. Stat effects sum by stat; rarity/mutation category coefficients use BuffUtil.GetValue:330–343, adding Value/100 to a starting base. Thus two +20 and +10 percent effects build 1.3 from 1, rather than 1.32. Conditional effects only apply when the supplied environment matches. Generic BUFF descriptions are presentation text, not evidence of a working runtime modifier.

Baits (`FishingBait:22–27`): Normal CatchSpeed+10; Silver CatchSpeed+15/ItemCrateChance+1; Golden MutationChance+2/Legendary rarity+5; Diamond MutationChance+5/ItemCrateChance+2.5; Galaxy CatchSpeed+25/Legendary+10; Chromatic ItemCrateChance+50/MutationChance+10/Legendary+25. These are effect values, not additive percentage-point catch odds. Bobbers catalog has only Test Bobber with no effects (`FishingBobbers:19`), which does not prove acquisition or intended play availability.

Enchant weights (`FishingRodEnchants:15–65`): Power 100 with five tiers +5/+10/+15/+20/+25 RodPower; Speedy 90 with +2.5/+5/+7.5/+10/+15 ReelSpeed; Experienced 65 with same XP tiers; Corruption 45 with +1/+2/+3/+4/+5 MutationChance; Item Seeker 3.5 with +1/+2/+3/+4/+5 ItemCrateChance; Poseidon 1 with one Legendary rarity+20 tier. Each family's weight is split evenly among its tiers; total roll weight=304.5. Galaxy and Abyss enchants have effects but no Weight and are excluded from the random weights. `getChance` returns normalized matching weight but defaults to 1 for missing entries (66–83); this fallback must not be presented as a guaranteed random result. Enchant cost is one Enchant Stone (`FishingUtil:53`).

| Mutation | Id | Relative weight | Value multiplier | XP multiplier | Shrine XP multiplier |
| --- | --- | --- | --- | --- | --- |
| Prismatic | 0 | 0.5 | 2 | 1.5 | 5 |
| Huge | 1 | 1 | 1.5 | 1.25 | 2 |
| Ghostly | 2 | 3 | 1.25 | 1.25 | 3 |
| Golden | 3 | 5 | 2.5 | 1 | 4 |

Mutation ids are validated consecutive/unique, and mutation collection uses bit flags (`FishMutations:14–41`, `FishingUtil:893–915`). A fish stacks only when Name and Mutation match (945–954). Inventory size sums Amount; nominal maximum is 1,000,000 (916–943), not a proof of a server-accepted catch when near the limit.

Weather catalog: Clear weight25 and Rainy75, both Queueable=false with empty Effects. Time catalog: Day and Night. `FishingUtil:955–986` uses `Time.now()%600/600`; Day is [0.25,0.75), Night wraps [0.75,1) and [0,0.25). This is native periodic classification, not proof of weather transition cadence. Workspace FishingWorldWeather is the named weather attribute. FishingLevels has 50 title/color records and no XP bonuses in this snapshot.

## Formula evidence and decompile limits

`FishingUtil:33–54` declares XP configuration MaximumXP=10,000,000, Increment=5, MaxLevel=50, Power=2.75; finish window1.5, cast distance8–20, wall click cooldown0.1, cast timeout5, fish bite delay3–5, base reel speed0.175, base mutation chance5 and item crate chance10. These constants need their call sites to determine enforcement.

For base rod power P and summed power effect p, GetFishingPower=ceil(P*(1+p/100)), or ceil(P) without an effect (448–459). Reel speed=0.175*baseReel*(1+summedReelEffect/100) (475–486). Bite delay is uniform between 3 and max(5/[baseCatch*(1+summedCatchEffect/100)],3) (460–474), so it cannot go below 3 through this helper. Double Fishing XP changes XP multiplier1→2 (487–494). Luck Day and named active special events add their contributions to starting multiplier1 (495–526).

GenerateFishPool attempts to filter Requirements (weather/time/rod/bait) then modify weights using Bonuses, rarity buffs, base rod luck for Legendary and Secret, and optional BonusLuckMultiplier (126–409). However reconstructed control flow duplicates blocks, shadows locals, and sets weight variables to nil for some Bonus branches. Current Fish has no Requirements/Bonuses, but exact modifier composition still needs verification. RollFish (538–596) has dead local assignments for mutation/XP effects and Shrine blessings, then uses different earlier variables; its New flag reads `CollectedFish[name] ~= nil`, opposite the expected wording. Do not claim those reconstructed branches correctly implement all effects or label New semantics verified. Base formulas/catalog values are established; exact catch probability/XP after buffs is not.

RollFish attempts one weighted fish per requested bobber, mutation test and mutated XP, plus one crate decision per batch. Base crate relative weights60 Wooden/35 Steel/10 Golden/5 Classic sum110, so they are not literal percentages. Galaxy Bait explicitly selects Galaxy Crate instead of the ordinary crate test (587–594). No purchase/source/consumption rate or server result is established by this helper alone. GetFishValue multiplies base Value by the mutation multiplier (527–537); whether selling uses this helper is checked separately.

## XP thresholds and base pool mathematics

ExperienceUtil:14–29 selects the highest reached level and defines total XP threshold
`X(L)=clamp(5*ceil[10,000,000*((L-1)/49)^2.75/5],0,10,000,000)`.
The ceiling is to the next multiple of five. Area thresholds are level2=225, level8=47,425, level10=94,655, level15=319,020, level20=738,815, level25=1,404,565; level50=10,000,000. Progress uses the difference between successive total thresholds (31–46), and CalculateGiveXP caps the resulting accumulated XP at MaxXP (63). Max-level progress can encounter equal capped thresholds in the reconstructed helper; the HUD separately displays MAX (FishingLevel:39–59). These numbers establish saved definition thresholds, not an observed account's access.

For raw pool weights w_i, W=sum(w_i), one unmodified weighted draw gives p_i=w_i/W, E[base XP]=sum(p_i*XP_i), E[base Value]=sum(p_i*Value_i). The table is an offline calculation from the 140 catalog records and 7 Pools. It excludes rod luck, modifiers, mutation, XP pass, crates and catch success; it is not observed payout or XP/hour. Numeric facts and source references are preserved in observations/FISHING_CATALOG_FACTS.json.

| Area | W | E[base XP/draw] | E[base Value/draw] | Rarest entry p | Mean draws to that entry | Draws for 95% chance of ≥1 |
| --- | --- | --- | --- | --- | --- | --- |
| starter | 100.5320 | 60.351 | 6.781 | 0.1989416% | 502.7 | 1,505 |
| blizzard | 99.8410 | 363.512 | 23.212 | 0.0300478% | 3328.0 | 9,969 |
| jungle | 100.0290 | 1676.566 | 93.674 | 0.0149957% | 6668.6 | 19,976 |
| lava | 99.9810 | 5492.703 | 342.809 | 0.0030006% | 33327.0 | 99,838 |
| atlantis | 101.2690 | 9240.499 | 799.578 | 0.0014812% | 67512.7 | 202,249 |
| dream | 101.1655 | 9228.849 | 797.268 | 0.0009885% | 101165.5 | 303,064 |
| classic | 100.7115 | 9212.365 | 1009.360 | 0.0004965% | 201423.0 | 603,408 |

Rarest entries respectively: Lemon Shark, Snowdrift Wyrm, Giant Squid, Blazing Puffer, Poseidon's Relic, The Moon, Classic Jellyfish. Mean draws=1/p; P(at least one after n independent fixed-distribution draws)=1-(1-p)^n; n95=ceil(log(.05)/log(1-p)). The mean is not a deadline. Catching the rarest fish alone does not complete the 20-entry island. For a complete collection the expected missing count after n draws is sum_i(1-p_i)^n; probability of completion is not the product of independent individual-entry completion probabilities because draws share one outcome. Do not substitute these raw-pool calculations for the damaged GenerateFishPool modifier branches.

## Native local rod lifecycle and casting contract

All paths below begin Client.Gui.Frames.Fishing. FishingPlayerRods:75–102 creates/destroys rods when existing players enter/leave Seven Seas; the reconstructed onPlayerAdded callback112 is empty, so newly joined player's initialization cannot be fully reconstructed. RodComponent:76–131 owns one native state machine: Unequipped → Idle → Charge → Casting → Waiting → Reeling → Idle; any state → Unequipped when RodEquipped becomes false. It observes RodEquipped and JSON EquippedRod (187–239), rebuilds after CharacterAdded (148–156), and handles ForceCancelCast by requesting Idle (FishingPlayerRods:116–134). This is a native client lifecycle, not authorization to create another OC loop.

Hotbar selection only allows rod FSM Idle/Unequipped and appropriate HUD/no open GUI (FishingHotbar:49–59), then sends EquipRod() or UnequipRod() (143–145). Journal rod selection sends SetEquippedRod(rodName,false) when the chosen owned RodInventory entry differs, or FavoriteRod(rodName) (FishingJournalRods:103–128,277–289). Selecting an inventory rod, equipping it in the world, and owning/acquiring it are distinct facts. No native FishingRod purchase product/price was found in the reviewed rod module or vendor references; island collection rewards establish several acquisition sources. The root shop audit owns vendor costs, including bait. No paid pass purchase was invoked.

Idle checks LocalData, capacity, GUI/dialog state, and a valid cast raycast before casting (Idle:90–113,127–151,210–231). BeginCastCharge() has no arguments (230/304); it precedes a local FSM transition. The native auto-fishing path additionally requires Passes["Auto Fishing"], a valid cast, then sets local auto state (258–291). Without the pass its button opens a native purchase prompt, which is not an acquisition contract. Idle disables native auto when guards fail on returning to Idle (323). Unequipped restores the local root/unanchors, stops animation and turns off native auto (Shared.Unequipped:57–67).

Charge:91–134 measures precision as 0.5+0.5*sin(2π*(serverTime-startTime)); period is one second. Auto releases at precision≥0.8 (172). It samples ten root-forward distances 8+(12/10)*n for n=1..10, or 9.2..20 studs, downward raycasts 50 studs into included physical fishing Roots (225–246). It calls FinishCastCharge(areaKey,targetPositionVector3) (120). Precision stays in local context and is not a third argument. Invalid target returns to Idle (139); exiting Charge without target sends CancelChargeCast() (206) and cleans reticle/sounds. The shared CAST_TIMEOUT5 and BASE_FINISH_WINDOW1.5 constants do not demonstrate server enforcement: no matching complete local timeout handler was established in these states.

FishingAreas maps initial tagged registry UUIDs to Roots (69–73); dynamic additions use the Added event's first value (82–84), while FishingAreasUtil fires area.Id rather than UUID (96). This inconsistent reconstructed key path means the argument must remain "native areaKey from the actual registry," not a fabricated catalog id for every context. FishingAreasUtil constructors create Zones, rename server objects, and hide Roots; they were never executed during research.

Casting:48–104 anchors the root for the native cast presentation, completes on animation marker or 0.75-second fallback, then creates one local bobber and permits Waiting. That animation does not prove the server accepted a cast. Waiting listens for ReelReady(_,rolledFish) and moves to Reeling (59–67); it does not calculate a local guaranteed bite time. ForceCancelCast/death/equip/world exit and absence of LocalData are meaningful stop observations, but exact server cancellation refunds, bait consumption and abandoned catch behavior remain unknown.

## Reeling mathematics and accepted result boundary

Reeling:186–194 chooses the first rolled fish rarity and computes rod power/reel speed from LocalData plus current weather/time. Its local minigame starts after a roughly 2.68-second countdown (0.7 + 3*2*0.33;495). A local completion boolean sends Reel(successBoolean) (289). The server's ReelFinished response controls subsequent catch presentation: on Success it passes returned Fish to bobbers/display and receives ItemCrate (333–351); failure returns toward Idle (372). Account inventory/XP deltas, observed ReelFinished status and expected context together are stronger evidence than the local success boolean. Inventory mutation and reward persistence remain server-only.

ReelMinigame:46–88 uses wall counts Common0/Unique1/Rare2/Epic3/Legendary3/Secret5 and difficulty Common0/Unique2/Rare5/Epic8/Legendary10/Secret15 (Shared.Constants:133–134). Let D=max(1,difficulty), W=wall count, H0=floor(0.3*D^2). For W>0, each wall health=ceil(U[0.6,1.2]*H0/W). Wall positions advance from 0.1 with a random 0.5..1 share of remaining space toward 0.9; do not assume evenly spaced walls. Each eligible mash removes FishingPower health, with os.clock input guard≥0.1 seconds (167–198). Required taps for a wall of H health and P power are ceil(H/P), conditional on valid phase/input and unchanged P.

Holding progress rises by ReelSpeed*dt until a wall, where Mashing is required. Without holding, progress decays at 0.1 per second, clamped to the previous wall start. The failure line is -0.2+0.1*t; success is progress≥1 and failure when progress falls below that line (216–248). With no walls and continuous eligible holding, ideal progress time is 1/ReelSpeed: a base Wooden Rod yields 5.714 seconds. Countdowns, cast/wait, wall health, missed input, presentation and server response add time. This is a model bound, not a measured catch cycle or guaranteed success. Native auto holds during Holding and mashes in OnLogic, still subject to the same local click gate (Reeling:457–470,553).

## Journal, sale, collection and enchant actions

| Action | Observed native arguments / local guards | Result evidence / unresolved rules |
| --- | --- | --- |
| SetEquippedBait | baitName; selected itemType Bait (Items:245–248) | LocalData EquippedBait/BaitInventory change; same-name click is labelled Unequip, but server toggle semantics/consumption/cost are unavailable |
| SetFishLocked | stored fish id, new boolean; finds matching inventory Id using LocalData (Items:432–446) | FishInventory.Locked update; do not infer fish-name arguments |
| SellAllFish | no args; native confirmation explicitly refers to all unlocked fish (Items:476–514) | Pearls and inventory deltas; locks must be respected; server sell/quest reservation rules unavailable |
| ClaimFishingIndexRewards | areaId; UI complete 20 entries and not in ClaimedFishIslandRewards (Index:346–378), action235 | ClaimedFishIslandRewards and every listed item delta; damaged nil-variable update315–353 means exact inline eligibility cannot be trusted |
| ClaimAllFishingIndexRewards | no args (Index:99); UI compares all 140 pool names against CollectedFish (81–86) and FishIndexClaimedRewardV1 | flag/reward deltas; no global full-index item reward was established by this caller alone |
| EnchantRod | no args, InvokeServer; selected currently equipped rod and one stone available (RodEnchant:55–89,322–356) | nonfalse returned enchant Id is used for result UI; account equipped enchant and stone debit remain required observations |

Journal collection counts presence of CollectedFish[name], separately from mutation flags. HasCollectedMutation/SetCollectedMutation use a bitmask, but GetAcquiredMutations reconstructs a nil loop index (FishingUtil:874–891); the mutation display is not enough to repair it. Journal Index intentionally builds from pool names, avoiding the inconsistent Fish.Area metadata.

SellAllFish confirmation sums counts using stack Amount but adds GetFishValue(stack) once per stack (Items:476–491), without multiplying by Amount in that UI branch. Its preview may understate stacked fish value; the actual server sale total is unknown. GetFishValue itself supplies baseValue*mutationMultiplier. Preserve fish locks and future task reservations; do not derive automatic sale priorities from this preview.

RodEnchant uses a local debounce and asks for confirmation before rerolling high rarity enchants (225–286). It binds the actual Poison Jungle Temple.Activation (528–537). Its excluded rods list contains "Galaxy Rod" and misspelled "Abyssla Rod" (55–56), which does not prove Abyssal Rod is protected on the server. Double Enchant Luck display multiplies selected high-rarity weights but retains the original denominator (489–511). ApplyMultiplierToPool without a fourth compensating predicate does not renormalize total weight; displayed percentages can fail to sum to 100. The saved UI and shared helper are documented, not converted into accepted enchant odds.

## Fishing scene and travel

Saved Edit hierarchy contains all seven catalog DisplayName folders. Their FishingAreas contain 4/7/7/2/1/4/4 models respectively, 29 total, each with matching Id attribute and Nodes+Root. All 29 Roots were inspected: CanCollide=true, CanTouch=false, CanQuery=false, Transparency=1. These saved flags and the native include-filter raycasts are separate observations; no raycast was executed to prove a valid casting position. Each Root's exact position/size and each model path are recorded in observations/FISHING_MINIGAMES_SCENE.json. A Root center is water geometry, not a safe standing destination. Nodes define the native polygon, and a future approach needs actual safe shore/object observation, raycast validation and an owner test.

FishingWorldIslands:64–70 resolves Workspace.Worlds["Seven Seas"].Areas[DisplayName].IslandTeleport.Spawn and sends Teleport(spawn:GetFullName()). It tests the IslandTeleport object but then dereferences Spawn without a separate guard. RequiredLevel only governs button visibility using ExperienceUtil(FishingExperience) (94–104); the click callback has no inline level check. This establishes a path-shaped native request, not server eligibility. Root Fishing:20–63 binds area's FastTravel; AreasUnlocked[name] presence or Fisher's Island exception opens WorldMap, which is distinct from fishing level access.

Time.now is Workspace:GetServerTimeNow() (Shared.Framework.Utilities.Math.Time:26–32). Native weather actual state observes Workspace.FishingWorldWeather on entering Seven Seas, with default Rainy (FishingWorldWeather:127–139); leaving disconnects presentation. Forecast UI calculates half-day300-second epoch windows, seeded weighted predictions with Random.new(windowIndex) (WeatherFrame:77–90), and lists Clear25%/Rainy75% normalized (61). Forecast timing is confirmed client calculation; actual server weather schedule/overrides remain unknown. TimeOfDay:31–38 shows the 600-second period and changes local Lighting.ClockTime only while in-world. No weather or lighting objects were changed by research.

## Minigame catalog costs, reward weights and pacing

Shared.Data.Minigames:12–75 defines four catalogs. Currency is Tickets. Rewards are relative weights built by LootPoolBuilder, whose Add appends and Build returns the pool without normalizing (25–33). Sum each pool before interpreting a chance.

| Activity | Entry cost | Duration field / MinDuration | Cooldown | Reward weight sum |
| --- | --- | --- | --- | --- |
| Pet Match | 5,000 Tickets | 3 / absent | 300 sec | 98.5 |
| Cart Escape | 200,000 Tickets | 20 / absent | 900 sec | 98.8 |
| Robot Claw | 2,500,000 Tickets | 60 / absent; FinishAtTimer=true | 1,200 sec | 95.91 |
| Hyper Darts | 5,000,000 Tickets | 120 / 30; FinishAtTimer=true | 1,200 sec | 95.725 |

All ItemDelay=3. A Duration field is not necessarily the whole playable duration: Pet Match reveals/cards and match actions cannot be inferred to fit in three seconds. Actual server StartMinigame payload has FinishAt and controls activity timing. DisableDartsMinigame branch deletes table.Darts (76–78), whereas the catalog key is "Hyper Darts"; this mismatch prevents a reliable source claim about disabled availability.

Pet Match rewards: Dice1 w35, GiantDice1 w34.5, DiceKey2 w15, TicketPotion4×5 w8, TicketPotion5×1 w5, TicketPotion6×1 w1. Cart rewards: Dice2 w35, GiantDice2 w29.2, DiceKey2 w10, GoldenDice1 w5, SuperTicket1 w5, TicketPotion4×5 w8, TicketPotion5×1 w5, TicketPotion6×1 w1.5, Magmas pet w0.1. Robot rewards: Dice2 w30, GiantDice2 w29.45, DiceKey2 w9, GoldenDice1 w5; Tickets/Mythic/Speed/Lucky potion5×5 each w3 and potion6×1 each w2; SuperTicket1 w1.4, SuperKey1 w0.75, SecretElixir1 w0.1, InfinityElixir1 w0.2, DragonPlushie w0.01. Darts rewards: Dice2 w30, GiantDice2 w28, DiceKey2 w9.45, GoldenDice1 w5; same four potion5×5 each w3 and potion6×1 each w2; SuperTicket1 w2, SuperKey1 w0.25, Infinity1 w0.25, Secret1 w0.25, RiftCharm1 w0.5, StarCharm w0.025.

For example Magmas raw per-draw probability=0.1/98.8≈0.101215%; Dragon Plushie=0.01/95.91≈0.010426%; Star Charm=0.025/95.725≈0.026117%. These are raw catalog probabilities, not odds per activity attempt. Client difficulty labels show +0/+1/+2/+3 drops (Minigames:309), but actual roll counts/bonus items depend on server and accepted results. No universal reward/minute ranking is justified without success probability, actual duration, cooldown origin, bonus item validation and a user-defined value for different reward types.

## Minigame native contract and result lifecycle

Client.Gui.Frames.Minigames:271–286 binds physically tagged activity models using Minigame attribute to open its UI. Difficulty names Easy/Medium/Hard/Insane correspond to levels1..4. LocalData MinigameLevels[name] (default1) gates selectable difficulty (228). Start callback checks account data, required difficulty level (343) and ticket affordability (372) then sends StartMinigame(activityName,difficultyLabel) (389). It does not directly recheck a cooldown there; UI renders Cooldowns[name]-Time.now() and hides buttons while cooling down (789–795). Difficulty unlock, cooldown validity, price debit and location validation therefore remain server-side unknowns.

SkipMinigameCooldown(activityName) requires one owned Super Ticket in the native handler (444–459); its UI is shown for cooldowns, but the click handler itself has no full cooldown test. CancelMinigame() occurs after native Leave confirmation stating no rewards (502–524). FinishMinigame() is sent without arguments from the activities. Hyper Darts shared Metadata declares Score constrained0..100, but its native callers send no Score (289/319/964); no Score argument was fabricated.

The received StartMinigame payload names activity/difficulty and FinishAt/BonusItems (547); already active local state prevents another setup (563). The controller hides HUD and disables activation, proximity and player controls during the native activity (593), runs its function (596), then forwards MinigameStateChanged payloads to StateChanged (742). Received FinishMinigame(status,rewards) drives cleanup, home transition and the reward prompt (640–723). The prompt's Claim closes the UI/displays received items; it sends no additional reward-claim remote. Accepted status plus matching LocalData currency/inventory/cooldown/level deltas are required observations; a client win animation or closing the prompt is insufficient. Reconstructed second BindOnOpened802 disconnects cooldown polling at813, so the exact frame close/open cleanup ordering remains uncertain.

Native activity scope:
- Pet Match: parameter2.5/3.5/4/5 produces floor(parameter²), rounded to even, yielding6/12/16/24 cards or3/6/8/12 pairs (197). Source shuffles selected visual pet pairs (148–171); these are not pet rewards. Revealing all cards includes roughly1.4 seconds plus a stagger (335), pair checking waits0.5 seconds (243), and a matched animation lasts0.4 seconds (53–60). Inputs ignore busy/matched/flipped/two selected cards (302). FinishMinigame is requested after all pairs match (225/257). Full core reviewed; no bypass or direct finish invocation performed.
- Cart Escape: Easy/Medium/Hard/Insane have stage counts3/5/7/9, TimeScale1/1.2/1.4/1.7, obstacle variations6/12/14/20 (66–69). Required input comes from the current actual plank/obstacle attribute (1020–1038), with input valid through tick+1 (1037). Crash resets/rebuilds stage with roughly1.5-second pause (854–893). The native progress factor contains 3.5/distance, slope factor3^max(0,-RightVector.Y), and Difficulty.TimeScale unless a part override exists (990–1002). FinishMinigame is requested after the loop (1068), but cleanup also changes its loop condition (1084), so such a request alone is not proof of winning. Rail construction/visual motion was only targeted, not exhaustively audited; no legitimate movement route is verified.
- Robot Claw: payload BonusItems map supplies actual capsule GUIDs (554). Collected hitbox requires a ClawToyModel tag, uncollected state and a matching GUID in BonusItems before GrabMinigameItem(guid) (573–583). It optimistically marks collected before the request. StateChanged.Items drives received collection display (691–714). A claw cycle has1.5 sec down +1 close +1 up +return travel +0.3+0.5 pauses (228–274), a minimum4.3 sec plus travel; a nil reconstructed target at250 prevents reliable full timing. FinishAt countdown is displayed (676), and FinishMinigame is sent after loop end (663). Client grab collision does not demonstrate server acceptance or how many bonus rewards are awarded.
- Hyper Darts: Easy/Medium/Hard/Insane top-level bubble budgets300/500/600/700, powerup frequencies5/7/13/20, required scores100/250/750/1000 (61–65). Colored bubbles split into lower layers, with Purple HP5 spawning four White children (67–74); score increments from layer pops, not just initial bubbles. Completion additionally requires ≥30 sec elapsed (313/939/955); finish requests are spaced5 sec (285–288). Input has0.2-sec windup then0.15 reset (451–472). Projectile velocity250 is client presentation (462); no server damage rule proven. Budget ramps with clamp(elapsed/(120-10),0,1) (940), powerup chance is frequency×0.01 in its spawn path (942), and collectible GUIDs use GrabMinigameItem(guid) (731). Projectile collision/visual geometry was targeted only. No aim/pickup manipulation was performed.

## Board weights, requests and stop behavior

BoardUtil:24–57 reads the actual saved Workspace.Worlds["Minigame Paradise"].Board.Nodes, sorts numeric names, maps empty Type to basic, and overrides node Weight for known types. Overrides: chance0.25/basic1.5/basic-dice1/giant-dice1/golden-dice0.2/dice0.3/infinity0.05/super-ticket0.7/special-egg0.05/dice-key0.8/potions0.5. Rift has no fixed override and retains its actual Weight (0.1 in saved nodes). Type spelling potions vs appearance table potion is inconsistent in this source; no live repair inferred.

Dice maximum windows are Dice6, GiantDice10, GoldenDice1 (75). ResolveNodes wraps the next N nodes around all88; Roll picks a weighted offset from that window (77–114). Therefore p(offset k)=effectiveWeight(node k)/sum(window effectiveWeights); it is not a uniform face distribution. No target tile or chosen face is passed by the native request.

All88 physical nodes were inspected. Saved raw types: 20 empty,5 basic,22 chance,3 rift,4 basic-dice,7 dice,6 super-ticket,7 golden-dice,3 infinity,6 dice-key,4 special-egg,1 giant-dice. The normalized effective board therefore has25 basic nodes. Raw weights often differ from overrides. Facts and resolved effective weights are saved in FISHING_MINIGAMES_SCENE.json. Example from current node1: Dice sees nodes2–7 weights[0.1,1,0.3,0.25,1.5,1.5], total4.65, hence landing2..7 probabilities[2.1505%,21.5054%,6.4516%,5.3763%,32.2581%,32.2581%]. GoldenDice's one-node window gives next node probability1 in this shared helper. This establishes native model math; the server RollDice implementation, dice ownership/consumption and live node state still require verification.

Basic grants1,000 Tickets; node helpers expose InfinityElixir1, Dice1, GiantDice1, GoldenDice1, SuperTicket1, DiceKey2, BlueFragment1; specialized nodes can resolve other effects (115–145). DiceTile weights40 Dice2/50 GiantDice2/10 GoldenDice1. ChanceTiles sum100 and contain elixir3.9,title0.1,evos5,server-luck10,special-egg1,playtime18,potions26,high-potions18,evo-easy8,fragment1,chest-timer10. Captions claim +250% server luck5min, +15min playtime rewards and -10min giant chest timers; captions are not the server mutation handler. BoardServerLuck helper returns a250% Percent descriptor while expiry has not passed (199–210). Rift weights sum71.3, with repeated wonderland-0 (15.65 twice) and none (5 three times), plus wonderland-1/2 at10 each, wonderland-3 at5 (74). Native spinner labels use raw Chance as a percentage in a branch (Board:728), so labels are not normalized evidence of spawned rifts.

Client Board:839–844 requires a local piece not moving and selected dice, then InvokeServer("RollDice",diceName). A nonfalse return carries Start, Roll and Tile{Index,Extra}; native visuals use that received roll, set piece to Start, move to Tile.Index (1076–1077), then send ClaimTile() after extra animations (1017). Random values used during spinning are visual decoys, not reward selection or a user-chosen target. Piece walking can wait until XZ distance≤0.01 with no observed timeout (1553), so success timing cannot be guaranteed.

Board entry binds actual Minigame Paradise.Activation (1320); dialog requires LocalData, a Board.Piece and available dice, or prompts ChoosePiece(petId) (1427/1808). Native pet chooser's predicate is true, so additional server piece eligibility is unavailable. LocalData Board.Tile/TimesRolled updates render actual recorded state (1826–1872); these provide result observation candidates. Auto option requires its mastery gate (1117,1874–1889), and native quarter-second polling requests rolls only while active/auto/not moving (1902). Stop sets auto false (1316); exit restores HUD/control presentation and marks inactive (484–520,1292). Neither sends a roll cancellation remote, and an in-flight native result may still finish/claim. Exhausted selected/total dice stop/reselect/deactivate in native code (195–199,1025–1066). Do not infer that closing the UI refunds dice or prevents ClaimTile.

## Obby entry, completion, keyed chest and geometry

Shared.Data.Obbys:12–90 declares:
| Difficulty | Reward rolls | Chest key | CompletionTime | Cooldown | Reward W |
| --- | --- | --- | --- | --- | --- |
| Easy | 1 | Easy Obby Key | 90sec | 180sec | 97.75 |
| Medium | 2 | Medium Obby Key | 120sec | 300sec | 109.106 |
| Hard | 3 | Hard Obby Key | 120sec | 600sec | 100.00006 |

Easy rewards include Level5×2 and Level6×1 Lucky/Speed/Coins/Mythic potions, Level7×1 versions, InfinityElixir, MysteryBox2, PowerOrb1, GoldenKey1, SuperKey1, DiceKey1. Medium adds ClassicKingDoggy normal w0.005/mythic w0.001, ShadowCrystal, Infinity/Egg/SecretElixirs, potion tiers, RerollOrb/RoyalKey and keys. Hard adds ClassicLeviathan normal w0.00005/mythic w0.00001, more powerups/dice and potion tiers. Relative weights are not literal percentages when totals differ from100. Hard normal per raw roll is0.00005/100.00006≈1/2,000,001.2, conditional on this pool actually being used without modifiers; even three independent rolls would be 1-(1-p)^3, not a guarantee. Client definitions do not prove independence, modifiers, multi-key consumption or accepted payout.

Client.Gui.Frames.Obbys binds ClassicIsland.Obbys[difficulty].Activation (246–259). Entry handler checks LocalData.ObbyCooldowns[name] against Time.now() (95–103), asks for native confirmation and sends StartObby(difficultyName) (158/221). No chest key check was observed for entry. Received ObbyBegan(difficulty,endTime) guards already active state and initializes the native course/HUD (662–678); received EndObby cleans and may transition home (681–708).

Inside setup, native KillBricks contact by local character resets to actual course Spawn (597). Actual Complete touch sends CompleteObby() once and immediately writes client "Complete!" (634–643); this label is optimistic. No checkpoint skip, invincibility, direct completion action or route simulation was performed. Timer reads endTime-Time.now() (614), but a zero display alone is not a server loss result. Leave confirmation requests Teleport(actual ClassicHouseSpawn full path) (394–403), rather than a discovered CancelObby request; server handling/refund/state cleanup remains unknown.

Chest approach is separate: every0.25 sec requires root and distance≤15 to actual Chest.Prompt with local cooldown clear (476–486). Activation requires at least one owned relevant key (503–521); native animation starts before FireServer("ClaimObbyChest", activatedKeybind==3) (523–537). LootPoolViewer.fromObbyChest uses one-key Cost and changes controls according to MultiChest mastery (1138–1203): keybind1 is labelled Multi when mastery exists, otherwise Unlock; keybind3 is labelled Unlock and shown only with mastery. Thus the boolean selects that alternative native control, not difficulty, path or key amount. Exact server interpretation and multiple-key consumption are unverified. Chest opening animation is not payout acknowledgement.

Saved scene confirms Easy/Medium/Hard Spawn, Complete, Chest.Prompt and KillBricks folders. KillBricks has2/10/9 immediate children respectively (these are folder counts, not a proven count of lethal obstacles). All three Complete parts are44×19×28, CanCollide=false, CanTouch=true; all Spawns are4×1×4, CanCollide=false, CanTouch=true. Exact object facts/coordinates are stored in observations/OBBY_SCENE.json. Their endpoint positions do not establish a safe navigable course: no intermediate route, contact sequence, timed obstacle schedule or legitimate success criterion was owner-tested.

## Remaining unavailable rules and required owner observations

No fishing/minigame/board/Obby action was invoked. No LocalData account contents were read. Every request above is a source-confirmed native caller shape, not server verification.

Future owner tests should record accepted state and minimal relevant account deltas for one legitimate action at a time:
1. Fishing: actual world/area eligibility, shore/raycast target, owned equipped rod, successful cast→ReelReady→ReelFinished, fish/XP/bait/crate deltas; cancellation/unequip/death/world exit and near-full inventory behavior. Verify uncertain mutation/XP effects and safe maximum-level behavior.
2. Journal/enchant: a complete20-name island claim and all its listed item deltas, full140-name flag/reward, one locked-stack sale with Pearls delta, same-name bait toggle, one paid-in-stones enchant and confirmed account result. Verify native high-rarity confirmation/excluded rod typo behavior without guessing protections.
3. Minigames: accepted difficulty/cost/cooldown boundary, legitimate win vs fail/cancel, FinishAt interpretation, reward roll/bonus counts and one GUID collection acknowledgement; skip-ticket debit only when intended. UI visibility does not replace account/server guards.
4. Board: selected owned dice, received Roll/Tile and account Tile/TimesRolled/dice/reward deltas, weighted window consistency and stop with a roll in flight. Record any rift effect actually spawned; retained spinner tables are not active-event proof.
5. Obbys: legitimate course entry, actual travel, hazards/checkpoints/time limits, native completion acknowledgement, separate key/chest delta, single/multi control behavior, leave/fail cooldown semantics. Geometry and optimistic labels do not authorize a route or completion bypass.

Reuse central OCBrain/TaskScheduler, GameKnowledge and its reader cache, mechanics adapter, WorldObservation and verified LocalData boundary in any later approved phase. Preserve owner-tested Phase1/2 movement, existing selling/teleportation, stationary farming and no pickup chasing. Phase7 activities and advanced Obby routing remain unimplemented. Reusable schema/contracts and unknowns are documentation, not a travel/fishing automation design.




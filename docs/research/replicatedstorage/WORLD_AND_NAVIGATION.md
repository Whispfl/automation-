# World and navigation research

Research checkpoint: 2026-10-11, connected saved Studio Edit model. This is documentation only. No game code was executed, native action dispatched, OC source changed, build run, or GitHub synchronization attempted.

## Evidence and scope

SOURCE_CONFIRMED here means readable saved native client/data source, not current server acceptance. Workspace geometry is a saved scene observation, not a live account fact. ACCOUNT_OBSERVED was not collected. OWNER_LIVE_VERIFIED facts appear only when explicitly identified as prior owner reports in local project documentation.

Notion master roadmap, Phase 3 and Phase 9 were read in full. Their publication/checklist language is superseded for this session by the user's research-only, suspended-account instruction. Phase 9 hybrid farming remains deferred. Preserve the existing Brain, scheduler and stationary collection.

## First saved batch

Five world records occur in `ReplicatedStorage.Shared.Data.Worlds:81-152,209-222,288-300`. Three permanent worlds are non-Removed; Christmas World and Easter Paradise have `Removed=true`. World currency is separate from unlock currency.

| World | Order | Farming currency field | UnlockCost | Catalog islands |
|---|---:|---|---|---|
| The Overworld | 1 | Coins | 0 Coins | Floating Island, Outer Space, Twilight, The Void, Zen |
| Minigame Paradise | 2 | Tickets | 1,000,000,000 Coins | Dice Island, Minecart Forest, Robot Factory, Hyperwave Island |
| Seven Seas | 3 | Pearls | 2,500,000,000 Coins | Empty; fishing areas use a different catalog |
| Christmas World | 4 | Snowflakes | 2,500 Gems | Removed; Gingerbread, Frozen, Snow, Candycane islands |
| Easter Paradise | 5 | EasterEggs | 2,500 Gems | Removed; Carrot, Easter, Dark Egg, Warden islands |

SOURCE_CONFIRMED. Costs are saved catalog values and must be reread in future runtime. Removed entries cannot be considered current Gems world opportunities. All five Gravity fields equal 1; this is a coefficient, not direct proof of actual character jump behavior.

`WorldUtil:12-38` caches each saved world Spawn position and identifies the nearest spawn in the horizontal plane; without a root it returns The Overworld. A future OC observation must retain missing-root uncertainty instead of treating this fallback as positive location evidence. `WorldMap.GetLocation:443-480` then chooses the nearest island pivot/surface Spawn by absolute Y difference. Neither nearest-world nor nearest-height proves physical occupancy, account access or island discovery.

`WorldUtil.toIslandLocation:110-115` produces the island Portal.Spawn path. `WorldMap.TeleportTo:118-194` dispatches Teleport with that string for islands; ordinary world surfaces use actual FastTravel.Spawn.GetFullName; Seven Seas resolves Areas[DisplayName].IslandTeleport.Spawn. Native portal return uses PortalSpawn, a distinct surface destination (`ClientScript:1574-1587`).

Important decompile limitation: `WorldMap.isUnlocked:87-117` loses local scope: ordinary area/world v2 values are shadowed then replaced by nil. Its intended general-world return cannot be established from this reconstructed helper alone. `ClientScript:1603-1636` independently confirms that received AreasUnlocked entries drive island portal Unlocked attributes. Preserve existing owner-tested travel; do not rewrite it based on broken decompiled output.

`Client.Activation:334-384` polls every 0.2 seconds, requires an alive character/root and model parent, and checks horizontal distance <= Root.Size.Y/2 with vertical difference <=10. This is a model-specific client activation volume. It is not a universal 3D interaction range and not a discovery touch contract. Sell activation repeats with >2-second client spacing; other activations fire on target change.

`ClientScript.hookWorldGate:2088-2326` resolves gate World attribute, finds Worlds[world].UnlockCost, opens World <Order> Unlock UI through Activation, checks owned cost via ItemUtil, and sends UnlockWorld with destination world name. The subsequent client animation destroys cover/activation and displays discovery before separately observing a received account acknowledgement. Animation is not purchase success. Received WorldsUnlocked[target] is the authoritative client account confirmation candidate; persistence requires the owner to rejoin.

## Availability observations

Saved Workspace contains only three permanent folders under Worlds, with world Heights 15962.706018447876 (Overworld) and 20034.96542930603 (Minigame Paradise). Seven Seas has Areas, empty-purpose Islands/Pickups containers, and no observed Height attribute in the inspected folder.

`Workspace.Event` and `Workspace.Rendered.Eggs` did not resolve through inspect_instance. Rendered.Chests contains Halloween Chest, Infinity Chest, Ticket Chest, Giant Chest and Void Chest Parts. Rendered.Rifts contains eight saved models (including duplicate names). These are saved object observations, not proof of unexpired live rewards.

`GetPickupZones:15-23` skips Removed worlds and maps each island/world name to its pickup pool. Additional catalogs explicitly include Fall -> Leaves26 and Halloween -> Candycorn26 (:43-60), among other historical/special areas. Only tagged PickupZone objects descending from Workspace are used (:113-159), with Area and Count attributes. Unknown Area gets a 1-Coin fallback with warning. This helper schedules transparency/CanCollide writes when called; source-only inspection is appropriate for this read-only session.

## Coverage at checkpoint

Deep source reads completed: Worlds, WorldUtil, GetPickupZones, WorldMap, Activation, Unlock, Remote. Focused ClientScript portal/world gate call sites read. Navigation facility geometry and other station contracts are being researched next. Server discovery handler and server unlock/travel validation remain UNAVAILABLE; no matches for UnlockHitbox in readable script content.

Full source modules and bytecode are not persisted. Source paths, fields, formulas and returned line numbers are recorded instead.

## Island heights, discovery and gates

SOURCE_CONFIRMED by Worlds data and saved scene inspect_instance reads. Definition height, folder Height attribute and contact volume center are different quantities; none is a minimum bubble amount.

| World / island | Definition Height | Saved folder Height | Saved UnlockHitbox center Y |
|---|---:|---:|---:|
| Overworld / Floating Island | 450 | 412.868250 | 404.564575 |
| Overworld / Outer Space | 2500 | 2650.825891 | 2642.522217 |
| Overworld / Twilight | 6500 | 6852.331995 | 6844.028320 |
| Overworld / The Void | 9500 | 10131.429651 | 10123.125977 |
| Overworld / Zen | 15000 | 15962.706018 | 15954.402344 |
| Minigame / Dice Island | 2500 | 2862.838964 | 2871.988770 |
| Minigame / Minecart Forest | 7500 | 7627.570410 | 7636.720215 |
| Minigame / Robot Factory | 12500 | 13355.152929 | 13364.302734 |
| Minigame / Hyperwave Island | 20000 | 20034.965429 | 20044.115234 |

All nine observed Island.UnlockHitbox Parts are anchored, noncolliding, touch-enabled, size (512,30,512). These are contact volumes, not client activation cylinders. No readable script reference to UnlockHitbox was returned by the search. No native client discovery command is established. Prior local Phase 3 owner reports confirmed correct AreasUnlocked acknowledgements for five Overworld islands while stationary; this is OWNER_LIVE_VERIFIED only for the reported session behavior. Synthetic runtime contact is not a normal Roblox API, server validation remains UNAVAILABLE, and saved persistence after rejoin remains a separate owner test.

Two exact saved gates:

- `Workspace.Worlds.The Overworld.Islands.Zen.Island.Decoration.Gate`, World=`Minigame Paradise`.
- `Workspace.Worlds.Minigame Paradise.Islands.Hyperwave Island.Island.Gate`, World=`Seven Seas`.

Both Activation.Roots have Size.Y=12.167879104614258; native horizontal activation radius is about 6.0839395523 studs, vertical tolerance 10. The Zen Root is (-87.5577011,15968.82421875,18.2194290); Hyperwave Root is (9846.1669922,20086.103515625,228.6744690). Both Roots have CanTouch=false. Gate location gives an access/prerequisite route for normal client use; it does not prove the server independently validates Zen or Hyperwave discovery on every UnlockWorld request. The native client affordability check is explicit, but reserve protection/authorization is OC responsibility. A gate-animation duration is not an unlock acknowledgement timeout.

## Three distinct native world travel mechanisms

1. Island portal: `Teleport(destinationPath)`, for an already discovered island. `ClientScript:1423-1587` binds Display.Touched, rejects nonlocal player contacts, a portal debounce and RaceUtil.HasPlayer, then requires portal.Unlocked. Surface portals receive AreasUnlocked-driven flags. Return portals are marked unlocked and point to the world's PortalSpawn. Client waits 0.5 seconds after dispatch then schedules a one-second debounce release. This is client pacing, not a server cooldown.
2. World map: `WorldMap:118-194` reads LocalData, calls its reconstructed isUnlocked helper, and rejects TransitionGui. Island targets use WorldUtil's path string; ordinary world surfaces use actual FastTravel.Spawn; Seven Seas uses fishing area spawn. Transition closes other GUI through PlayTransition and dispatches its callback approximately 1.25 seconds after entry (`PlayTransition:19,116,144-163`). It closes the map and updates music/physics without waiting for a server acknowledgement. WorldMap closure is not proof of arrival.
3. World trampoline: `Physics.hookWorldTrampoline:286-378` filters known non-Removed world names, responds to local Bounce.Touched, requires root/humanoid and received WorldsUnlocked[world], disables controls, then sends `WorldTeleport(worldName)` in PlayWorldTransition's callback. It has a shared trampoline debounce and a 0.5-second wait. This is a distinct native world identifier contract, not an island path and not UnlockWorld. It was not dispatched during research.

Ordinary surface FastTravel on Overworld is conditional: `ClientScript:1990-2009` looks for a MasteryUpgrades element with Type=WorldMap before exposing map button/FastTravel. A separate helper (:1953-1970) also checks any non-Overworld unlock, but reconstructed update_6 does not call it. This ambiguity must not be silently resolved. In this saved snapshot the direct Overworld FastTravel is absent whereas Minigame Paradise.FastTravel exists. Source path, runtime availability, account capability and successful travel are separate evidence fields.

Portal.Spawn objects are generally absent from island hierarchy in this saved snapshot. `ClientScript:1417-1418,1547,1640-1679` registers portals in a native 3D Chunker and reparents loaded portals into Rendered.Generic or unloaded ones to nil. Local absence can be presentation/replication state rather than invalid server path. Do not create replacement parts or fake arrival geometry.

## Seven Seas fishing-area navigation

SOURCE_CONFIRMED: FishingAreas has seven keyed areas, while Worlds['Seven Seas'].Islands is empty.

| Area key | DisplayName / Workspace Areas child | DisplayOrder | Required fishing level |
|---|---|---:|---:|
| starter | Fisher's Island | 1 | No explicit field (client defaults 0) |
| blizzard | Blizzard Hills | 2 | 2 |
| jungle | Poison Jungle | 3 | 8 |
| lava | Infernite Volcano | 4 | 10 |
| atlantis | Lost Atlantis | 5 | 15 |
| dream | Dream Island | 6 | 20 |
| classic | Classic Island | 7 | 25 |

Sources: FishingAreas:35,58,81-90,113,136,159,182; WorldMap:102-114,158-168,389-430; FishingWorldIslands:27-107,121-137. The panel compares ExperienceUtil.GetLevel(FishingExperience,FishingUtil.XP_CONFIG) to RequiredLevel and toggles Teleport visibility. Button callback resolves actual DisplayName/IslandTeleport/Spawn and sends Teleport(spawn.GetFullName). It checks IslandTeleport existence, but reconstructed code does not check Spawn before GetFullName; do not copy this potential nil failure. The button callback itself does not recheck level, so UI visibility is a client guard, not server acceptance proof. The model requires normal Activation approach to open the fishing travel panel. Separate Fishing FastTravel entry (:20-61) checks AreasUnlocked[display name], except Fisher's Island is treated true, then opens WorldMap. Area key, display name and account flag string must not be conflated.

Additional navigation affordances: Old Sailor at starter, Rod Enchanting at jungle, Dreaming Fountain at dream, Obbys at classic are catalog PointOfInterest fields, not proof of currently eligible actions. FishDex completion rewards and fishing economics belong to the opportunity research, not the permanent island discovery chain.

## Native ascent physics: useful mathematics with explicit limits

SOURCE_CONFIRMED: `Physics:37,107-134,451-453` and `Curve:19-35,37-71`. Curve.Add uses cumulative segment lengths, so the native endpoints are 600, 3600, 28600, 128600 and 728600 Bubble.Amount, rather than treating the listed Length values as absolute thresholds.

| Cumulative Bubble.Amount endpoint | Gravity reduction curve | Power curve |
|---:|---:|---:|
| 0 | 0 | 0 |
| 600 | 50 | 100 |
| 3600 | 65 | 130 |
| 28600 | 85 | 200 |
| 128600 | 135 | 275 |
| 728600 | 135 | 335 |

Between endpoints the default interpolation is linear, clamped to the segment; above the last endpoint it saturates. Let b be received Bubble.Amount and s=Settings['Bubble Gravity']/100. In ordinary enabled conditions, JumpPower=50+(20+P(b))*s and Workspace gravity=originalGravity-G(b)*s. These are native client formulas, not permission for OC to change physics or settings. Physics uses Bubble.Amount, not merely gum capacity. Capacity can limit achievable b, but no exact minimum b to discover each island has been established.

Touch UI/trading or EventFreeze/TrickOrTreatFreeze can set jump/walk to zero. Trading Plaza, Seven Seas and active Obby restore jump 50, walkspeed 32 and original gravity. Race and Physics.Enabled flags affect application. A standard trampoline sets vertical velocity 75+JumpPower*max(1,PowerAttr or1.25), debounces 0.5 seconds and natively requests Bubble Gravity100; world trampoline uses 75+6*JumpPower. No automation of these actions is proposed.

CLIENT_ESTIMATE only: in a simplified constant-gravity trajectory, height gain is v_y^2/(2g) and time to apex is v_y/g. Native collision, platform spacing, physics resets and server discovery affect actual reach, so this formula cannot produce verified island prerequisites or a safe ascent path. A future route needs geometry/platform observations and owner traversal tests. The saved Stages/Trampoline models are leads, not a reviewed route.

## Pickup-zone geometry and economic limits

SOURCE_CONFIRMED: Zone.fromPointsFolder:62-100 requires at least three consecutively numbered Parts, subtracts each Part's half-height from its position, orders/triangulates a simple polygon, and stores a separate Height. Zone.fromPart:101-115 uses transformed rectangular XZ corners. IsPointInside and GetDistanceToPoint (:117-159) project into XZ; height is not included. Therefore 2D membership alone is inadequate for distinguishing vertically stacked islands or proving arrival. Existing OC observations must continue to check appropriate height/live root separately.

Saved Void has three same-named Zone folders with Area='The Void', Count=5 each; Zen has two Zone folders with Area='Zen', Count=5 each. Duplicate full paths are genuine multiple matches and must not be collapsed into one folder. Count sums of 15 and10 describe saved zone configuration only, not continuously available pickups, spawn rates, accepted batch rates or economic throughput.

Worlds pickup Chance values are weights: Void currency weights sum 110, Zen sum 100, plus the tiny secret-pet weight 0.0002. GetRandomWeightedItem:14-25 normalizes by total chance through cumulative selection, but the unavailable server spawn handler has not been verified to use this utility unchanged. Conditional calculation if these saved pools are selected by that method: base expected Coins per Void draw = (32×75 + 40×100 + 10×150 + 10×225) / 110.0002 ≈ 92.2726; Gems = (10×10 + 5×25 + 3×45) / 110.0002 ≈ 3.2727. Zen Coins = (20×300 + 20×475) / 100.0002 ≈ 154.9997; Gems = (30×15 + 15×30 + 10×50 + 5×125) / 100.0002 ≈ 20.2500. These arithmetic results were independently recomputed in JavaScript, without game execution. This is CLIENT_ESTIMATE for a pool draw, not Coins/Gems per minute, nor actual credited value after native multipliers/caps. Retain the owner's verified Void/Coins, Zen/Gems stationary policy until measured evidence supports any later approved change.

Zone constructors and GetPickupZones mutate visualization/collision flags when called; they were never called in this audit. Source inspection is the evidence.

## Selling, stations and intentional egg travel

Saved SOURCE_CONFIRMED sell model attributes: Overworld surface Multiplier=2; Twilight=5; Minigame Paradise surface Currency=Tickets/Multiplier0.1; Robot Factory Currency=Tickets/Multiplier0.2. These are newly observed saved attributes, not proof of payout. Activation calls SellBubble with no station argument; correct station depends on actual location and unavailable server selection. Price conversion/effective pet multipliers require the economics helper evidence, plus owner credited balance observations. Compare net earnings over full travel/sale/return time, and only sell for a genuinely authorized bubble objective.

Outer Space physical Mastery model exists with Shop='Overworld'; its Root is (17.0077705,2661.468994,4.4801331), Size.Y=8.9619198, touch disabled. The HUD Mastery button requires AreasUnlocked['Outer Space'] and not TradingPlaza (`ClientScript:2010`). No physical station activation binding was established from the inspected readable source; do not impose a speculative proximity requirement on UpgradeMastery just because the station model exists.

Verified interface entry locations (SOURCE_CONFIRMED client binding, action eligibility still separate):

| Facility | Native binding source | Scene/interface target |
|---|---|---|
| Gem Genie | GemGenie:756-765 | Bound GemGenie model; source variable path investigated separately |
| Potion Upgrade | Potions:413-429 | Overworld.Islands.Zen.Island.PotionUpgrade -> Potions panel |
| Bubble Shrine | Shrine:761-773 | Zen and Hyperwave Island BubbleShrine.Activation -> BubbleShrine panel |
| Enchanter | ClientScript:1921-1945 | The Void.Island.EnchanterActivation -> PromptSelectPet |
| Minigame entrance | Minigames:271-287 | Activation-tagged model's Minigame attribute -> display(id) |
| World rewards | WorldRewards:353-369 | Activation-tagged WorldRewards model -> panel for WorldUtil world |
| Fishing island travel | FishingWorldIslands:121-137 | Seven Seas.Areas children IslandTeleport -> travel panel |
| Halloween entry/return | HalloweenEvent:14-63 | Workspace.HalloweenTeleport / HalloweenEvent.Return -> Teleport(actual Spawn path) |

Egg catalog Island is annotated by scanning tagged Egg objects (`Eggs:531-539`), not an unconditional permanent location fact. Native initial hatch prompt distance is6.5 (`ClientScript:568-616`); the native nearest eligible hatch scan uses radius16 and actual unlocked object/character/account/UI state (:869-885). Exact hatching guards, full-batch affordability, cooldowns and inventory checks are detailed in the egg/pet research. An intentional chosen-egg destination is different from chasing pickup locations.

HYPOTHESIS for future phase integration only: Brain first evaluates a feasible egg objective against the best team from owned pets and protected reserves. Scheduler leases location through travel, approach and hatch verification. The existing stationary collector may request compatible pickups only if it does not require movement and the active hatch ownership permits them; no Void/Zen snap-back, new movement loop, or individual pickup navigation. Pause/Stop and respawn cancel future dispatches; Resume reads current native state. Active transactions can have delayed results after cancellation, so attribution must survive the lease.

## Owner verification needed, research not execution

1. Correct island flag and post-rejoin persistence; separate original approved Overworld contact behavior from any unverified Minigame discovery.
2. Actual native island/return/world surface destinations and live arrival geometry after each form of travel; no scene fallback created.
3. Fresh account world gate cost, prerequisites, one authorized purchase, correct WorldsUnlocked flag and actual deduction; post-rejoin persistence.
4. Map capability gating: Mastery WorldMap vs additional world unlock behavior, because the saved decompile is inconsistent.
5. Fishing level eligibility, display-name mapping and arrival for each accessible Seven Seas area.
6. Station approach and UI cancellation; Mastery via HUD vs physical station access.
7. Sell balance/bubble delta and net rate including travel/return.
8. Intentional egg ownership retaining stationary compatible collection without travel oscillation, only when later-phase integration is approved.
9. Event expiry/current activity, not only saved objects or catalog currency names.

Server-only validation for proximity, unlock order, durability, affordability race, teleport destination whitelisting, refunds and request rate limits remains UNAVAILABLE. No live gameplay PASS is claimed.



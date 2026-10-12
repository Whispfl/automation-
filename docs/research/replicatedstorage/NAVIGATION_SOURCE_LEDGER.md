# Navigation source ledger

Read-only Studio audit, 2026-10-11. Connected instance id 5528d459-f21f-4304-aa34-0f2deff5a197, available datamodel Edit. Actual PlaceId cannot be independently established through these reads. Owner identifies the saved connected game as the new workspace. Saved source includes decompiler headers/bytecode; bytecode lines were suppressed from research output and no complete source modules are persisted.

Line numbers here are script_read returned source lines, not the decompiler's embedded original line comments. “Full” means full accessible reconstructed text was inspected, including dependencies and exports. It does not mean verified original source/server code. “Focused” means only relevant call sites/binding sections were read; unrelated functions remain unaudited.

## Governance pages actually read

- Master roadmap: https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349 (full).
- Phase 3: https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10 (full).
- Phase 9: https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358 (full).

Research-only user instructions override historic publication and implementation checklists. Phase 9 stationary hybrid coordination remains deferred; Phase 4 or any new later implementation is not authorized by this audit.

## Native modules

All paths below begin ReplicatedStorage unless an explicit StarterPlayer prefix is shown.

| Source path | Coverage | Main evidence lines / exported interface | Dependencies and limits | Relevant phase |
|---|---|---|---|---|
| Shared.Data.Worlds | Full,302lines |81-152 three permanent worlds;209-222 Christmas Removed;288-300 Easter Removed; pickup weights18-80,94-138 | Shared.Types; definitions and caps, not actual account or active event |3,9 |
| Shared.Utils.WorldUtil | Full,117 |12-38 nearest horizontal Spawn;40-47 GetPlayerWorld;49-109 OnPlayerWorldChanged;110-115 toIslandLocation | CharacterUtil, Workspace.Worlds spawns; missing root defaults Overworld; reconstructed watcher appears one-shot repeat, original lifecycle uncertainty |3,9 |
| Shared.Utils.GetPickupZones | Full,163 |15-23 permanent pool mapping;43-60 Fall/Halloween currencies;100-161 function-returning zone reader | CollectionService PickupZone, Workspace, Zone; calls mutate flags; Count != throughput |2,8,9 |
| Client.Gui.Frames.WorldMap | Full,1024 |87-117 corrupted isUnlocked;118-194 TeleportTo;443-481 GetLocation;508-633 map entries;634-663 egg icons;664-708 quick chest claims;833-856 account-driven locks | Worlds, LocalData, WorldUtil, Activation, Remote, FishingAreas/Util, ExperienceUtil, Physics, PlayerControls, PlayTransition, Music; broken helper scope and empty pcall bodies prohibit interpreting omitted behavior |3,5,7,9 |
| Client.Activation | Full,385 |61-82 Bind;83-91 Remove;140-304 tagged entry mapping;334-384 model cylinder test and Sell pacing | CharacterUtil, LocalData, Remote, Worlds, GuiFrame; has presentation mutations; generic addTagged decompile has suspicious admin branch so no inferred Mastery binding |2,3,5-9 |
| Client.Gui.Unlock | Full,92 |42-91 builder-driven UI;88-90 title + Open('Unlock') | UnlockBuilder, Pool, ItemUtil, GuiFrame; visual UI only |3,4 |
| Shared.Framework.Network.Remote | Full,149 |90-98 FireServer wrapper;127-135 InvokeServer;53-89 event transport dispatch | IsServer, actual child RemoteEvent/RemoteFunction; no gameplay-specific validation handler exposed |All |
| Client.Gui.PlayTransition | Full,185 |19 start tween0.75;116 GUI close;144-163 delayed callback;179-181 cleanup | LocalData-independent presentation, Maid, GuiFrame, Worlds, WorldUtil; no server ack/no cancellation contract |3,7,8 |
| Client.Gui.GuiFrame | Full,254 |25-53 lazy initialize;66-110 Open trading guard;111-130 Close;170-198 IsOpen/IsAnyOpen | IsTrading, Frames require, PopIn/Tween, Signal; UI ownership only |All |
| Client.Effects.Physics | Full,496 |37 native curve segments;107-134 physics formula/overrides;204-285 trampoline;286-378 WorldTeleport;451-462 registration | Curve, LocalData, StatsUtil, WorldUtil, CharacterUtil, Obbys, PlayerControls, PlayWorldTransition; source explains native behavior but audit never executes it |2,3,7 |
| Shared.Framework.Utilities.Math.Curve | Full,73 |19-35 cumulative length Add;37-71 Get | TweenService default Linear/Out; Physics uses scale1; original curve endpoint exactness source-confirmed |3 |
| Shared.Framework.Utilities.Math.GetRandomWeightedItem | Full,29 |14-25 sum Chance and cumulative pick | Random; conditional normalized weights; server pickup use not verified |2,4,7,9 |
| Shared.Framework.Classes.Zone | Full,262 (segmented) |9-30 geometry construction;62-115 folder/part;117-168 XZ predicates/distances;169-207 sampling;241-260 closest points | PolygonGeometry; methods mutate Part flags at construction; no vertical occupancy in IsPointInside |2,3 |
| Shared.Data.FishingAreas | Full,190 |35 starter,58 blizzard,81-90 jungle,113 lava,136 atlantis,159 dream,182 classic;183-189 fish references validated | Fish, Logger, ItemBuilder, weighted helper; fields Pool,CompletionRewards,DisplayName,RequiredLevel,PointOfInterest |7 |
| Client.Gui.Frames.Fishing.FishingWorldIslands | Full,138 |27-77 buttons;83-107 level UI;121-137 Activation | LocalData, ExperienceUtil/FishingUtil, PlayTransition, Activation, Remote; level hidden UI not runtime callback guard; unchecked Spawn dereference |7 |
| Client.Gui.Frames.Fishing | Full,64 |20-63 FastTravel opener;40-45 AreasUnlocked/Fisher's Island exception | WorldMap, WorldUtil, LocalData, Activation; imports submodules; full fishing mechanics not covered in this file |7 |
| Client.Gui.Frames.HalloweenEvent | Full,64 |11-15 non-Plaza and actual spawn paths;16-63 entry/return Teleport | Activation, PlayTransition, Remote; no expiry/eligibility server source here |8 |
| Client.Gui.Frames.GemGenie | Focused,736-768 |756-765 Bind -> GemGenie panel | Full economic/quest action contract outside navigation coverage |6 |
| Client.Gui.Frames.Shrine | Focused,733-775 |761-773 Zen+Hyperwave bindings | Summon donation/currency costs separate audit |6,7 |
| Client.Gui.Frames.Potions | Focused,395-438 |413-429 Zen PotionUpgrade | Only facility entry here, not buy/consume contract |6 |
| Client.Gui.Frames.Minigames | Focused,235-310 |271-287 Activation tagged Minigame attr | play/earn mechanics not complete navigation coverage |7 |
| Client.Gui.Frames.WorldRewards | Focused,325-370 |353-369 Activation tagged WorldRewards | Reward eligibility/claim contract separate audit |5 |
| StarterPlayer.StarterPlayerScripts.ClientScript | Focused,1340-1640,1640-1780,1800-1935,1935-2045,2060-2360,3040-3120 |1423-1587 portals;1603-1636 flags;1640-1679 chunker reparent;1813-1877 UnlockHatchingZone;1990-2010 map/Mastery UI;2088-2326 world gate;3093-3104 exit closes GUI | Native client root with numerous dependencies; no full-module completeness claim; targeted hatch snippets delegated to economy researcher |3,4,5,7,9 |

Coverage count for this ledger: 17 full reconstructed modules,5 focused modules,1 focused ClientScript. No claim that all navigation-adjacent modules, all700+ scripts or all server mechanics have been audited.

## Scene evidence

A condensed nonpersonal saved scene record is in observations/NAVIGATION_SCENE.json. It contains paths, class, attributes, location/size/collision flags and child summaries only, not scripts or player/account facts.

Inspected: three permanent world folders; all9 permanent island folders/UnlockHitboxes;2 gates/Activation.Roots; Outer Space Mastery/Root;4 sell models; Void and Zen pickup zone folders, including duplicate names. Scene folderHeight/catalogHeight/contact-center discrepancies are explicitly tabulated in WORLD_AND_NAVIGATION.md.

Additional hierarchy observations: Seven Seas.Areas has all7 catalog DisplayNames; Rendered.Chests has five saved Parts; Rendered.Rifts has eight saved models and duplicate names. Workspace.Event and Rendered.Eggs did not resolve. Direct Overworld FastTravel/Island.Portals often absent in current hierarchy while source references them. Native chunker presentation may reparent them. Missing object is a saved availability observation, not proof server path is invalid.

## Unavailable and decompiler cautions

- Server discovery/unlock/travel handler, save persistence, strict server distance/order/whitelist/rate validation.
- Complete normal world-map eligibility helper, due lost scope in reconstructed isUnlocked.
- Physical Mastery binding; model exists, HUD Outer Space access confirmed, no speculative proximity condition.
- Safe within-island approach/ascent route and minimum bubble requirement. Native physics curve is established, route is not.
- Active event expiry/claimability and runtime destination streaming.
- Full PlayWorldTransition behavior (referenced but not deep-read in this navigation batch); only caller/callback command established.
- Fishing weather/casting contract is now documented in FISHING_AND_MINIGAMES.md and its ledger; remaining specialty facility actions are covered by other researchers. Navigation entry remains separate from gameplay eligibility.
- Source may contain stale/historical paths and empty functions. No original bytecode execution/decompilation was attempted.

## Preservation and reuse

Existing local GameKnowledge.ProgressionContract, reader dependency cache, GameMechanics travel/guards, ProgressionGraph, WorldProgressionManager, WorldObservation and TaskScheduler are the future consumers. Read-only local evidence cross-check is documented by the architecture researcher. Research findings do not authorize replacing source, extending travel, building a second cache/Brain or automating pickup movement.

Saved incremental checkpoints: initial Worlds/WorldUtil/Activation/WorldMap summary; expanded island/gate/fishing/physics/zone evidence with scene JSON; native contract ledger. Progress survives without full third-party source copies.

## Physical chest follow-up coverage

Full reconstructed source read: `ReplicatedStorage.Client.Effects.PhysicalItem` (305 lines), `ReplicatedStorage.Client.Effects.PhysicalItem.Chest` (485 lines). Relevant ranges: registry/placement 30–48; chunker visibility 134–175; physical nearest/prompt/action 197–257; LocalData Cooldowns subscription 292–303; chest LocalData cooldown-derived state 399–449; model parenting 451–483. No source was required or invoked. Printed bytecode comments were filtered, and only factual documentation was saved.

## Combined coverage and activation clarification

NAVIGATION_FISHING_SOURCE_COVERAGE.jsonl consolidates80 unique source review records across navigation and fishing/minigames, with explicit full-content vs targeted-range fetch extents. Minigames has since been upgraded from focused entry review to DEEP_CORE879 lines in the specialty audit. The counts above describe the original navigation checkpoint; use the JSONL for combined final coverage.

Activation.addTagged is an actual generic tag dispatch: outside TradingPlaza it enumerates CollectionService tag Activation305–309 and maps Shop154–176, Index177–188, Sell265–300 and a parent named AdminRebirthMachine191–203 to explicit callbacks. There is no BindToTag export in this module. AdminReturn/AdminTeleport branches205–251 are followed by an unconditional AdminWheelSpin Bind253–263 in reconstructed control flow, so their functioning travel cannot be confidently inferred. No Mastery mapping was established. This correction was independently checked with the architecture researcher; physical model/tag availability remains a separate observation.

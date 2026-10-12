# Specialty source ledger

Read date: 2026-10-11. Source line numbers are the MCP `script_read` returned numbering, not bytecode debug comments. Full source is retained only transiently in tool memory, never copied to repository. The source contains save/decompiler headers, omitted giant bytecode comments and sometimes unresolved locals: evidence is the available saved representation, not executed/runtime validated Luau.

## Initial full reads

| Native path (under ReplicatedStorage) | Read coverage | Relevant anchors | Evidence / limitation |
| --- | --- | --- | --- |
| Shared.Data.Rifts | 1–144, bytecode comment excluded from semantic reading | 14–25 type/area/special flags; 26–87 chest cost/reward weights; 90–125 generated egg Rifts; 127–142 pet Chance side effects | SOURCE_CONFIRMED catalog; generated locals/Egg=nil unresolved; not availability/probability guarantee. |
| Shared.Utils.RiftSummonUtil | 1–49 | 10 base shard drop 0.025; 16–22 and32–38 UnlockRiftSummon guard; 40–47 BetterShardLuck buff | SOURCE_CONFIRMED helper; final drop application/server unavailable. |
| Shared.Data.RiftSummonCosts | 1–103 | 14 time choices;15 luck choices;17–24 world/island map;26–85 egg eligibility and cost;86–99 chest cost | SOURCE_CONFIRMED options/formula branches, unresolved v6/v8/nil mapping expressions prevent authoritative generated mapping. |
| Shared.Utils.XLEggUtil | 1–84 | 24–32 two distinct daily seeded eggs;43–55 eligibility overrides;66–73 client chance thresholds;82 midnight | SOURCE_CONFIRMED client helpers; final rarity sampling/server unknown. |
| Shared.Utils.Stats.SecretBountyUtil | 1–135 | 16 day interval;17 active target array;18–73 retained historical targets;74 egg seeds;83 seed offset;94–112 nonrepeat selection;114–128 Rift egg additions;130–134 Pets.Chance assignment | SOURCE_CONFIRMED current client target construction; relevant ClientScript/Index displays inspected below; no separate ClaimSecretBounty action established. |
| Shared.Utils.Stats.BountyUtil | 1–72 | 14 interval;24 seed;35–36 hatch quest/rewards;46–62 refresh;64–70 candidate rules | SOURCE_CONFIRMED mythic bounty quest helper; do not call Refresh on actual profile during research. |
| Shared.Data.SpecialEvents | 1–15 | 7–14 event names, Event Ticket costs and descriptions | SOURCE_CONFIRMED definitions, not active subscription/benefit proof. |
| Shared.Data.Halloween26Upgrades | 1–16 | 11–14 Multi upgrade cost/value arrays;15 AutoRebirth single purchase | SOURCE_CONFIRMED catalog. |
| Shared.Utils.Halloween26UpgradesUtil | 1–31 | 18–29 validates name, reads received tier, BuffUtil conversion | SOURCE_CONFIRMED client helper; tier missing/nil not equivalent to zero. |
| Shared.Utils.HalloweenRebirthUtil | 1–14 | 12 capped linear threshold | SOURCE_CONFIRMED cost helper. |
| Client.Gui.Frames.HalloweenEvent | 1–64 | 11 trading-plaza exclusion;14–17 scene destinations;35/59 Teleport(path) | SOURCE_CONFIRMED client request and scene expectations; no teleport performed. |
| Client.Gui.Frames.HalloweenRebirth | 1–155 | 24 reset/reward text;39–78 profile fields/affordability;88–105 native auto loop;118 rebirth;129 toggle;145 scene binding | SOURCE_CONFIRMED native client requests; reset actual/server acceptance unavailable. |
| Client.Gui.Frames.Halloween26Upgrades | 1–253 | 35 HalloweenShards cost;53–61 max/ownership;111 BuyHalloween26Upgrade(name);123–133 actual cost guard;155–228 received UI updates;243 scene binding | SOURCE_CONFIRMED args/guards; unused helper is empty at64–72 (decompiler limitation); no purchase proof. |

## Batch E: complete specialty/event interfaces

| Native path | Deep-reviewed coverage | Relevant anchors / result boundary |
| --- | --- | --- |
| ReplicatedStorage.Client.Gui.Frames.RiftSummon | Full1–723 semantic source, bytecode excluded | 30 trading-plaza block;46 config shape;47–48 Charm/Shard items;69–100 total cost/affordability;157–224 index-based selections;415–523 option display;534–551 world exclusions/powerup refresh;569–652 confirmation, InvokeServer at607 and no-space-left failure;655–705 PlayerSummonedRift(name,type,target,world,height);707 one Charm display. No live request. |
| ReplicatedStorage.Shared.Data.Events | Full1–233 semantic source | 12–213 historical/current group catalog;163–164 Fall/Halloween26 both Active=true;214–222 Eggs.Event join;223–230 tagged scene egg can set Active=true, never clears historical true. Group/index flag is not seasonal runtime eligibility. |
| ReplicatedStorage.Shared.GlobalEvent | Full1–207 semantic source | 18–25 known boost names;38–58 Workspace expiry attribute minus native time, positive remaining for active;77–101 event signals;181–205 current visible list. Separate global boost registry, not Halloween end date. |
| ReplicatedStorage.Shared.Utils.SpecialEventUtil | Full1–109 semantic source | 14–25 alphabetic names;26 duration constants;35 epoch half-hour seed;45 seeded event;80 even seed;87–90 global scheduled event or nonnil profile timer. Presence of timer alone assumes cleanup elsewhere, which remains uninspected. |
| ReplicatedStorage.Shared.Framework.Utilities.Math.Time | Full1–241 semantic source | 31 GetServerTimeNow;42 day86400;65–83 epoch day/midnight;40 universal weekday. No helper executed in Studio. |
| ReplicatedStorage.Shared.Constants | Selected semantic constants from full fetched222-line source | 20 AutoRiftChestCooldown;32 RiftEggs;49–55 XL thresholds/multiplier/eggs/crafting count;108 old Halloween wheel cooldown;110 HalloweenEggs;221 Halloween26Eggs. No claim whole Constants deep audited by this agent. |
| StarterPlayer.StarterPlayerScripts.ClientScript | Targeted full relevant function ranges1890–1905,2328–2917,3026–3054,3239–3323 | RenderGifts receives keyed item positions;2331–2397 chest animation2.65s;2458 DespawnAt;2559–2576 ClaimRiftGift(name),10stud prompt;2670–2720 UnlockRiftChest(name,bool),10stud/key guards;2734–2771 UI modes;2786–2806 expiry changes;2830–2917 scene lifecycle;3047 percent-unit rarity display100/chance;3273–3323 Halloween house/character-freeze interface. Reconstruction `updateRift` alias and empty auto helper are explicitly uncertain. |
| ReplicatedStorage.Client.Gui.HUD | Relevant full ranges1798–1963 |1831–1835 TeleportToRift(model) requires RiftRadar Level2 and BoardHUD not visible;1888–1896 actual world/object association;1953–1960 radar visibility any RiftRadar. Arrival/server validation unavailable. |
| ReplicatedStorage.Client.Gui.LootPoolViewer | Relevant full functions1031–1116,1293–1350 and1574–1629 | Chest definition/key display;MultiChest/AutoClaimChest Mastery UI gates1095–1115;Gift items rendered at100 display weight;1624–1626 displayed shard drop BaseShardDropChance*GetShardDropLuck. No final sampling/acknowledgement. |
| ReplicatedStorage.Client.Effects.PhysicalItem | Full6–305 semantic source in incremental reads |49–90 RenderGifts keyed object rendering;109–121 active registry;185–192 only in-range Hit;248 ClaimChest separate;280 horizontal15stud Gift range. |
| ReplicatedStorage.Client.Effects.PhysicalItem.Gift | Full1–299 semantic source, bytecode excluded from semantic review |168–175 ClaimGift(model.Name) after animation;217–270 guarded hit pacing/8hits;288 visual parenting;295–297 cleanup. Local animation/removal is not reward receipt. |
| ReplicatedStorage.Shared.Data.Builders.LootPoolBuilder | Full1–35 semantic source |25 appends literal Item/Chance;33 returns pool unchanged. No normalization/final roll here. |
| ReplicatedStorage.Shared.Utils.Stats.BuffUtil | Relevant complete Format/GetValue314–344 |342 Percent adds Value/100 to base, not multiplication of base by1+percent. |
| ReplicatedStorage.Shared.Data.Mastery | Relevant Rift catalog186–195 |Rifts levels1–4 native costs5m/35m/125m/1b Gems;UnlockSummon, +25 shard luck, Radar1/2. Whole Mastery research belongs to parent/economy ledger. |
| ReplicatedStorage.Shared.Utils.Stats.StatsUtil | Relevant application branches295–311 and2430–2455 |305 Candycorn26 gets Currency upgrade;2438–2440 listed Halloween26 egg gets Luck upgrade. No confirmed SecretLuck/InfinityLuck application from these branches. |
| ReplicatedStorage.Shared.Utils.Stats.PetUtil | Relevant GetChance27–41 |40 nested/decompiled variant expression and percent scaling; do not use this expression alone as final live hatch probability. Whole PetUtil research belongs to pet/economy ledger. |
| ReplicatedStorage.Client.Gui.Frames.Index | Relevant bounty display979–1035 |Received Discovered presence;current SecretBounty egg and percent rarity display. No separate ClaimSecretBounty contract found. Whole Index/claims research belongs to parent. |

## Read-only hierarchy/properties

Studio state returned Edit only. `search_game_tree` discovered StarterPlayer.ClientScript and Workspace Halloween/Rift objects. `inspect_instance` inspected Workspace (attributes only used), Workspace.Rendered.Rifts.gift-rift, Workspace.HalloweenEvent, its Spawn, HalloweenTeleport, HalloweenRebirth, HalloweenRebirthUpg, and ReplicatedStorage.Assets.Rifts.gift-rift/golden-chest. Parent inventory provided broader Assets/Rifts catalog discovery.

The saved Edit scene contains a Gift Rift with Type=Gift, World=The Overworld, DespawnAt1791657116.714268, original Gift/Display children and observed pivot. Converted timestamp is2026-10-10T18:31:56.714Z; this does not establish a fresh eligible Rift or synchronized live server clock. Halloween folder contains ground/decorations/houses/trick-or-treat/pickups/portal/return/shop/Spawn; rebirth and upgrade objects are present. These are saved scene observations, not account eligibility or a live event deadline. No actual account values copied.

## Access/representation limits

- Server summon validation, server final draw/boost/pity rules, player-specific gift entitlement, exact bulk chest count/consumption, Halloween rebirth actual reset scope/result and current event deadline remain UNAVAILABLE.
- Rifts generated Egg=nil and SummonCosts v6/v8 unresolved locals prevent authoritative evaluated mappings. Native functions were never required to resolve them.
- Relevant ClientScript auto helper2648 is empty while a separate visible button-repeat body exists2752–2769; no invented cooldown contract follows. Constants.AutoRiftChestCooldown exists but no demonstrated use in that inspected repeat branch.
- Global script_grep results are capped50 and include saved player copies. Only StarterPlayer/reference paths are documented; absence from a capped search is not proof of absence. No usernames/personal values saved.
- Static Events.Active has retained historical groups. GlobalEvent attributes and SpecialEventTimers are different mechanisms with separate semantics; do not merge them into a current seasonal active flag.

Batch E saved: specialty/seasonal assigned source set complete, with targeted action dependencies and explicit unreviewed boundaries.

## Batch F: additional complete Shrine / conversion sources

PhysicalItem was fetched in ranges covering its complete semantic body6–305 and is classified DEEP_CORE with contentsFetched=RANGES in the machine-readable manifest. Its header/giant bytecode was not needed for semantic review; other targeted dependencies remain TARGETED rather than receiving whole-module credit.

| Exact native path | Complete semantic scope | Evidence / boundaries |
| --- | --- | --- |
| ReplicatedStorage.Shared.Utils.ShrineUtil |1–127, bytecode comment excluded |15–17 limits;18–48 scaled buffs;57 active;74–91 XP;101–107 item XP;109–125 count-duration and expiry extension. |
| ReplicatedStorage.Shared.Data.ShrineBuffs |1–11, bytecode excluded |7–10 Luck/Currency/Bubbles/HatchSpeed unlock and scaling. |
| ReplicatedStorage.Shared.Data.ShrineValues |1–58, bytecode excluded |19–39 exact potion XP;40–47 powerup type mapping and exclusions;49–57 sorting. |
| ReplicatedStorage.Client.Gui.Frames.Shrine |1–775 fetched, all semantic6–775 reviewed in sequential chunks |192–242 cooldown;245–328 donation invoke303;340–414 count selection;569–663 inventory;689–719 Rift gate;761–772 world activations. |
| ReplicatedStorage.Shared.Utils.RebirthMachineUtil |1–264, bytecode excluded |14–48 three machine definitions, Sky disabled;71–118 paid-item policy list;136–147 catalog eligibility;185–245 multiplicity/count/pool;246–264 variants. |
| ReplicatedStorage.Shared.Utils.AdminRebirthMachineUtil |1–104, bytecode excluded |14 weighted catalog;36–85 policy/count300s definition;93–102 variants. |
| ReplicatedStorage.Client.Gui.Frames.RebirthMachine |1–1013 fetched, all semantic6–1013 reviewed in chunks |195–208 filtered selection;426–440 equipped/policy;674–681 selected-ID serialization;742 UseRebirthMachine(machine,IDs);902–950 absolute cooldown;1003–1012 actual bindings. Crystal activation binding missing in this module. |
| ReplicatedStorage.Client.Gui.Frames.AdminRebirthMachine |1–795 fetched, all semantic6–795 reviewed in chunks |127–144 Admin-specific eligibility;363–377 equipped/policy;562–569 serialization;627 UseAdminRebirthMachine(IDs);718–764 cooldown. No in-module Activation binding; generic Activation follow-up below resolves native consumer shape. |

Exact attempted Shared.Utils.FusingUtil read was unavailable/not found. Visible native fusing functions were found in RebirthMachineUtil; absence of a hypothetical path is not proof that all fusing routes are absent. Underlying PetChoosePrompt, GetRandomWeightedItem, ItemUtil.Compare, Products and exact final server conversion behavior are referenced dependencies but not claimed deep-reviewed by this agent. Other agents may provide independently scoped evidence. Normal machine Chance fields sum99; displayed percentage is not a server normalization contract. All eight extra core sources preserve the same decompiler/reconstruction and read-only limitations.

## Independent consolidation QA and activation follow-up

Read complete root NATIVE_ACTION_CONTRACTS.md and SYSTEM_DEPENDENCIES.md and compared their specialty references against this ledger. No contradictory specialty argument/result assertion found; the action register links the detailed specialty document rather than reproducing every specialty command. Concrete naming correction reported to root: native frame is `Client.Gui.Frames.RiftSummon`, whereas `SummonRift` is the InvokeServer label at607; catalog is `Shared.Data.RiftSummonCosts`. Root documents were not edited by this agent.

| Additional exact native path | Complete semantic scope | Evidence |
| --- | --- | --- |
| ReplicatedStorage.Client.Activation |1–385 fetched; all semantic6–385 reviewed independently |61–82 registered model→callback;191–203 tagged AdminRebirthMachine parent→GuiFrame.Open;305–309 tag enumeration/addition outside TradingPlaza;334–384 alive/root geometry poller. |
| ReplicatedStorage.Client.Gui.GuiFrame |1–254 fetched; all semantic6–254 reviewed independently |25–53 lazy named frame Initialize with pcall(require);66–109 Open refuses trading, requires actual GUI, initializes then presents. No autonomous Crystal mapping. BindOnOpened/Closed are GUI signals, not physical activation registration. |

AdminRebirthMachine generic source binding is now resolved. SearchGameTree/InspectInstance observed the saved Edit model and Activation/Root/Ring/Border at `Workspace.Worlds.The Overworld.Islands.Floating Island.Island.AdminRebirthMachine`. Exact CollectionService tag membership is not supplied by inspected properties; no module was executed to query it. Read-only search with CrystalAltar/AdminRebirthMachine/AdminTeleport/AdminReturn keywords and depth10 returned the Admin model, not Crystal; capped/depth-filtered absence is not an absence proof. Global source grep CrystalAltar returned its setup call and util definition/cooldown name only, leaving physical Crystal binding unavailable.

Activation's AdminReturn/AdminTeleport branches205–251 contain Teleport destination strings `Workspace.AdminPortal.Spawn` / `Workspace.AdminIsland.Spawn`, but are visibly followed by same-key Bind253→AdminWheelSpin261. This suspicious reconstruction must not become a claimed working travel contract without reliable consumer/runtime evidence. The safe AdminRebirthMachine branch returns203 before that block. GuiFrame.Open visibility alone also cannot prove successful module initialization: Initialize catches load errors and warns, while Open proceeds with GUI presentation after Initialize returns. These observations preserve the distinction among source reference, actual registration, displayed UI and eligible server action.

Admin Activation.Root saved position is(-9.022233,420.264343,218.265839), Size.Y=9.73430347442627. Under the native poller, candidate volume is horizontal radius4.867151737213135 and vertical distance≤10, with alive/root/model-parent guards; CanTouch=false/CanQuery=false here does not remove that mathematical proximity poller. It is not a server conversion range or walking-route guarantee.

QA follow-up saved; all Studio calls remained source/tree/property reads. World/navigation agent independently confirmed the generic Admin mapping and reconstruction qualification.

## Focused stat-extension documentation QA

Independently read STAT_DEPENDENCY_EXTENSIONS.md, ECONOMY_SOURCE_LEDGER.md, DATA_SCHEMAS.md, ECONOMY_AND_ROI.md and README.md. This was a consistency review, not a new native source audit; no coverage records were added and root documents were not edited.

Reported one notation correction at STAT_DEPENDENCY_EXTENSIONS84: if H is pre-guild HatchSpeed and g is the unchanged guild factor, one Blue use gives ratio `(H+0.0075)/H`, while actual native duration is `4.5/(g*H)`. If H denotes final speed, the increment is instead `g*0.0075`. Other checked rune/fragment/Super/guild unit, count, timing and evidence claims are internally consistent with the referenced economics documentation; this is not independent server validation.

Reported missing schema integration for ActiveRunes[name].Tier/Amount, RuneCraft.Name/Tier/Amount/Start, Fragments[color], Guild.Id/Level and Stats.Bubbles guild-UI threshold. Recommended folding Super capacity/team/cache isolation into README rank1 and rune craft/use horizons plus per-color fragment completion into rank8; guild factors remain qualified account/stat inputs, with no inferred guild earning or management authorization. Exact native support and review scopes belong to the economy source ledger and stat extension document.

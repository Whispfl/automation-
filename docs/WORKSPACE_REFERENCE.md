# Read-only workspace reference

Current reference (October 10, 2026): the owner explicitly confirmed MCP session
`Game` as `place 85896571713843 Bubble Gum Simulator INFINITY`. The Studio launch
log references that `.rbxl` filename. Read-only MCP does not expose the actual
PlaceId; **the ID was not independently verified**. The references below include
historical inspections and must not be mistaken for current workspace identity.

Phase 1 is owner-approved. Phase 2 bubbles, selling, island travel and pickup
collection/respawns have owner verification, including repeated matching coin
credit. New movement recovery, combined farming and purchases remain unverified.

Historical reference: `74075244490179`, "logosism's Place: 10102026_1". This is the earlier workspace reference, not the current session's identity. These are observations of client source and scene definitions, not proof of a working server/account runtime.

## Current native research for movement, combined farming and upgrades

ReplicatedStorage Assets.Pickups, Client HUD/GumShop/LocalData, Remotes.Pickups and
Shared Gum/Flavors/Currency/Events/GetPickupZones/StatsUtil were inspected read-only
in the owner-confirmed Game session. Complementary ClientScript lines1134–1347
confirm the same ID registry, Chunker and native radius collector. No source was
executed or changed through Studio.

- GumShop lines792–800 use `GumShopPurchase(name)`; owned items use UpdateStorage/
  UpdateFlavor. Actual ownership comes from LocalData.Gum/Flavors membership.
- Native Gum defines Omega Gum storage1750, Unreal Gum4500 for45,000 Coins with
  Outer Space access; Flavors defines Chocolate65 and Contrast80 for35,000 Coins
  with Outer Space access. Runtime reads catalogs; these values are observations.
- StatsUtil:GetBubblePower lines114–176 adds flavor output to effective pet power
  before buffs/perks and rounding. Contrast's base improvement therefore cannot
  multiply all equipped pet output. GetBubbleStorage lines357–372 supplies the
  effective storage projection. Projected benefits remain estimates.
- HUD lines377–473 permit the guarded native BlowBubble request and contain no
  normal-walking exclusion. This supports testing simultaneous blowing during
  native-radius collection; it does not prove combined income or server acceptance.
- Currency currently includes Candycorn26 and HalloweenShards. Events retains
  both Fall and Halloween entries with Active=true; GetPickupZones retains both
  seasonal pools, and saved Workspace retains old folders. None of these alone
  proves event availability. The owner reports Halloween and inactive Leaves.
  Defaults no longer select Leaves26/RebirthShards26 balances. Live received
  balances, actual loaded models and verified credit remain required; event
  shops/rebirth executors remain outside Phase 2.

Ordinary movement uses [Roblox pathfinding](https://create.roblox.com/docs/characters/pathfinding)
and [Humanoid MoveTo/MoveToFinished](https://create.roblox.com/docs/reference/engine/classes/Humanoid).
Actual geometric progress and arrival are checked; an event result alone is not
proof of arrival. Ahead-of-route blockage, failure or stall permits bounded
recomputation. OC does not move character CFrames or modify island geometry.

| Account information | Observed source/interface | Handling |
| --- | --- | --- |
| Coins, Gems, Tickets, Pearls | Top-level profile values in LocalData | Read configured numeric keys; missing values stay nil |
| Autumn balances | Retained `Leaves26`, `RebirthShards26` keys | Display only if received; not proof that event is active |
| Bubbles, equipped gum/flavor | `profile.Bubble.Amount`, `.Gum`, `.Flavor` | Read actual received values |
| Effective capacity/power | `StatsUtil:GetBubbleStorage(profile)`, `:GetBubblePower(profile)` | Call existing helper under pcall; failure is unavailable, never substitute a base stat |
| Base equipment stats | `Shared.Data.Gum[name].Storage`, `Shared.Data.Flavors[name].Bubbles` | Separate from effective capacity/power; used only for upgrade comparisons |
| Inventory/equipped team | `profile.Pets`, `profile.Teams[profile.TeamEquipped].Pets`; pet `.Id` | Clone the tables, join IDs to records, report unresolved IDs |
| Equip/storage limits | `GetMaxPetsEquipped`, `GetMaxPetStorage`, `GetUsedPetStorage` in StatsUtil | Preserve game-defined storage units; digital storage may count serialized bytes |
| Items | `profile.Powerups`, `profile.Potions` | Read only if tables are received; absent tables are unavailable |
| Purchased equipment | `profile.Gum`, `profile.Flavors` | Read ownership maps; currency-only upgrade definitions are eligible |
| Mastery | `profile.MasteryLevels`, `profile.MasteryUpgrades`, `Shared.Data.Mastery` | Never infer missing branches as level zero; use current next-tier definitions |
| Unlocks | `profile.AreasUnlocked`, `profile.WorldsUnlocked` | Read membership maps rather than infer from currency/account age |
| Live progression | `workspace.Worlds`, its `Islands`, `WorldGate` tags/`World` attribute | Require both definitions and scene presence for permanent world/island recommendations |

Game modules are loaded at these exact ReplicatedStorage paths:

```text
Client.Framework.Services.LocalData
Shared.Utils.Stats.StatsUtil
Shared.Data.Worlds
Shared.Data.Gum
Shared.Data.Flavors
Shared.Data.Mastery
```

LocalData exposes `IsReady`, `DidLoadFail`, `Get`, `DataReady`, `Changed`, and `PetsChanged`. Its profile originates from `Remotes.PlayerDataLoaded`; updates arrive through `PlayerDataChanged` and existing pet synchronization. The reader consumes these interfaces without modifying the received profile. Phase 2's separate GameMechanics adapter uses only the inspected native commands below. Requiring an existing game module runs that module's own initialization and dependencies; their behavior is owned by the game.

Observed permanent definitions include The Overworld, Minigame Paradise, and Seven Seas. Gate prerequisites come from their scene ancestry. Minigame Paradise's gate was on Zen; Seven Seas' gate was on Hyperwave Island. Currency unlock prices are read from the current definitions, not hardcoded. Island heights prefer scene attributes. Retained Christmas/Easter event definitions do not establish event availability and are excluded.

The inspected ServerScriptService and ServerStorage were empty. Saved client source included decompiled code and missing assets/interfaces, so source inspection alone cannot establish account delivery or helper compatibility. `Shared.Types` contained no usable runtime schema. No OC account data was fabricated to work around this.

Uncertain/outside Phase 1: authoritative game level/XP, first-play date, playtime, complete lifetime statistics, every inventory category beyond the observed fields, event availability, official endgame status, farm income/payback estimates, travel routes, reward claiming, shops and remote contracts. These are not inferred or advertised as implemented.

Before the owner's read-only workflow change, legacy Phase 1 modules/bootstrap were inserted into Studio. They were left untouched after the change. Repository code is a separate hosted build. No Studio scripts are inserted, modified, removed, or installed under the current workflow.

## Phase 2 inspected interfaces

| Mechanic | Actual interface/evidence | OC use and uncertainty |
| --- | --- | --- |
| Zones and pool types | `Shared.Utils.GetPickupZones` returns a **function** mapping `PickupZone`-tagged scene roots to `{Zone, Area, Pickups, Count}`; pools use `Chance` and `{Visual, Item={Type, Currency, Amount}}` | Runtime invokes this existing native function; definitions alone do not establish an active event. Its game-owned Zone constructors hide native zone geometry in the user's runtime, as the client already does. No function is executed through Studio tools. |
| Native pickup collection | `StarterPlayerScripts.ClientScript` lines 1134–1344: `Remotes.Pickups.SpawnPickups` sends arrays `{Root, Visual, Id}`; rendered models are `Workspace.Rendered.Pickups`, name = ID; every 0.1s native distance collector calls `CollectPickup:FireServer(id)` | No batch/island-wide API in the available code. OC never calls CollectPickup, destroys pickup models, alters magnet range or claims credit from model removal. Native collector owns credit. |
| Magnet range and pickup modifiers | `StatsUtil:GetPickupRange(profile)` and `GetCurrencyMultiplier(profile,currency)` use equipped pets, Mastery, passes and active buffs | Real helpers supply radius and estimated effective pickup face value; actual rates come from balances. Failure is unavailable. |
| Current island | Zone `Height`, `IsPointInside`, `GetDistanceToPoint`, live zone `Area` and world ancestry | Requires character, nearby geometry and a compatible height. Scene streaming or overlapping geometry can leave identity uncertain. |
| Supported island travel | `Client.Gui.Frames.WorldMap.TeleportTo`, lines 136–185: checks unlock membership; `Remote:FireServer("Teleport", "Workspace.Worlds.<World>.Islands.<Area>.Island.Portal.Spawn")`; base `FastTravel.Spawn` | Native island path is sent without a local-part lookup. OC follows it for real catalog islands with mapped live zones, rechecks world/area access and requires observed target-height/location arrival. Local-part absence is diagnosed; a request with no arrival is unverified and backed off. No unlock command. |
| Return travel | `StarterPlayerScripts.ClientScript` lines 1578–1586 binds each native island portal to its world's `PortalSpawn` | Existing `PortalSpawn` is an eligible supported base return destination. Missing base spawn excludes base travel; island-only native-path handling does not invent a base fallback. Seven Seas fishing-level travel and special-event routes are not generalized. |
| Bubble blowing | `Client.Gui.HUD` lines 377–441: `Remote:FireServer("BlowBubble")`; checks Plaza, GuiFrame, HUD, gift, alive character, Intro/Prompt/Trading, Bubble Lock and active fishing rod | OC reproduces observed guards, respects a minimum 0.5s request cooldown and confirms actual amount changes. Movement/race/trading conflicts stop OC actions. |
| Selling | `Client.Activation`: Sell roots activate at XZ distance <= `Root.Size.Y/2` and vertical difference <=10; sell interval2s; native `SellBubble` command | OC walks/travels into actual activation range, lets native selling run and waits for actual bubble decrease plus positive balance delta. No duplicate SellBubble command. |
| Selling travel/multipliers | `Client.Gui.HUD` lines 236–259 teleports to best Sell root by full path; native `findBestSell` checks unlocked islands and `Multiplier` (default1) | Only direct world Sell or native `Islands.<Area>.Island.Sell` locations are considered; unverified nested VIP facilities excluded. Scene examples: Overworld multiplier2; Twilight5; Minigame Paradise multiplier0.1 and Currency=Tickets. Missing Currency defaults Coins. Payout proof still requires actual balances. |
| Gum/flavor purchase/equip | `Client.Gui.Frames.GumShop` commands `GumShopPurchase(name)`, `UpdateStorage(name)`, `UpdateFlavor(name)`; cost currency table; raw `.Gum`/`.Flavors` ownership; `.Area` absent means accessible | Recheck catalog, actual funds, budget/reserves and ownership. Numeric premium costs are excluded. Bubble storage uses gum; no pet-storage purchase interface found. |
| Future stat projections | Existing `GetBubbleStorage`/`GetBubblePower` with a detached profile/equipment table set to the proposed catalog item | An economic model only; never replaces displayed real stats or mutates LocalData. Actual new stats and earnings still require owner execution. |

Permanent pools differ materially: Overworld islands supply Coins, with Gems on Twilight/The Void/Zen; Minigame Paradise islands supply Tickets; Seven Seas has an empty pickup pool. Retained live-zone overrides include GemMine Gems and seasonal currencies such as Leaves26. A live pool may also contain pet/powerup rewards; Phase 2 routes currency records only and does not implement those acquisitions. Actual account currency keys are discovered from active zone definitions rather than a fixed coin/gem assumption.

Read-only follow-up inspection on October 10, 2026: `Workspace.Worlds.The Overworld.Islands.Floating Island.Island.Pickup` is a Folder with Area="Floating Island", Count5 and eleven point Parts. Its island Height is approximately412.87; Input.Y approximately420.56. `Outer Space.Island.Pickups` has four Pickup Parts, each Area="Outer Space", Count2, Y approximately2660.17; island Height approximately2650.83. The native pool is different for each island. Neither Island model has a Portal child in the inspected saved workspace, and Overworld.Portals is empty. Input Parts exist but no inspected native interface makes them an alternate teleport target, so OC does not use them. Live runtime tags/destinations, current visible models and collection earnings still require owner execution. `ClientScript` lines1603–1636 checks `AreasUnlocked[portal.Name] ~= nil` and labels this discovery; ordinary world membership is `WorldsUnlocked`.

Source reference: the owner's [updated Phase 02 Notion page](https://app.notion.com/p/3f53d7e9278d8145a85aff38d5497e12). Its final revision and pasted final specification supersede older implementation/install wording. Normal movement uses Roblox [PathfindingService](https://create.roblox.com/docs/characters/pathfinding); no character CFrame, flight or speed modification.

## ReplicatedStorage-first pickup follow-up

Read-only inspection again confirmed Assets.Pickups (82 children, four Gem Models), Client.Framework.Services.LocalData, Remotes.Pickups.SpawnPickups/CollectPickup, Shared.Data.Worlds and Shared.Utils.GetPickupZones. GetPickupZones reads world/island pools before joining actual tagged Workspace roots; it returns native Zone geometry/Area/Count/pools. No source function was executed via Studio. ClientScript remains necessary complementary evidence for the native collector. StatsUtil.GetPickupRange uses Constants.DefaultPickupRadius=7.5 plus actual profile modifiers; OC reads the helper rather than hardcoding that radius.

In Studio Edit view, Workspace.Rendered.Pickups has zero children. Runtime presence after arrival remains an owner test. The native collector clones Models with name=ID, rotates visuals and collects within actual radius. Geometric identity indexes accept duplicate assets bearing the same visual name, while conflicting visual/reward identities remain unknown. Stage Node Area labels refer to progression pickup pools, not those islands' surface positions; Floating/Outer stage heights are far above their island surfaces and are excluded from current-island routing/yield. World identity is taken from permanent Shared.Data.Worlds definitions before scene association.

Server-only collection validation remains unavailable. No batch API was found in inspected source, no CollectPickup calls are issued by OC, and model removal alone never confirms credit. The owner now verified native island arrival in addition to bubbles/selling; pickup collection is still unverified. See [global architecture](ARCHITECTURE.md).

## Native pickup registry and Chunker trace (live empty-folder report)

The owner tested build 753dc3905f14, saw visible pickups with Rendered.Pickups empty, and manually observed CollectPickup with one dynamically received UUID. That example ID is not embedded or reused anywhere in OC. Read-only full-source inspection of Shared.Utils.Chunker explains the discrepancy: new creates a Folder named Chunker under Rendered (lines17–20); Add reparents instances into its folder if loaded, otherwise nil (lines33–55); Update reparents loaded objects into that folder and unparents unloaded objects (lines118–167). The previous discovery implementation stopped at ClientScript's initial Parent assignment and missed this reparenting.

ClientScript lines1137–1140 creates the pickup active table and assigns it to ReplicatedStorage.Client.Tutorial._activePickups. Chunker Loaded binds Model.Name→Model (1255–1267); Unloaded removes that entry (1269–1279). Tutorial defines the field at line44, consumes it at522, and exports its module table. This is the source-confirmed registry, used even when Tutorial.Active is false. OC requires the existing cached Tutorial module through the approved dependency loader and reads the current field on every scan; it never replaces the table, changes the tutorial, hooks internals or mutates registry/model state.

SpawnPickups provides Root, Visual, Id (ClientScript1281–1327); ID generation/server validation source is unavailable. Positions are randomized by the native client using actual Zone geometry; the payload contains no exact position. OC never calls GetRandomPoint to reconstruct a pickup or guesses an ID. Existing loaded pickups synchronize through the current ID-to-Model registry and live model pivots without replaying past events. Newly observed payload metadata supplies Root/Visual identity, not a predicted position. Every actual same-name Rendered.Chunker folder is inspected as an additional source, with native ID/name, prefab/pool and geometric qualification; unrelated chunked objects remain rejected. Legacy Rendered.Pickups is supplemental only.

ReplicatedStorage.Client.Services does not exist in this reference; Client.Framework.Services contains LocalData and InputMode, not a pickup service. Searches found only ClientScript for SpawnPickups/CollectPickup, and no RequestPickups interface. No replay/resync endpoint or public all-unloaded-chunks registry is assumed. Native update runs every0.1s, checks actual 3D range, destroys/removes the collected Model and sends its current ID. OC retains native radius interaction through normal movement and issues zero collection remote requests, avoiding duplicates; exact native outgoing request counts are not instrumented or claimed. Only matching LocalData balance changes plus target disappearance qualify an isolated cycle. Unload/despawn remains indistinguishable from collection without balance evidence.

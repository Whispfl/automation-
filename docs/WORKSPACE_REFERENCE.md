# Read-only workspace reference

Phase 1 account behavior was subsequently verified and approved by the owner. Phase 2 interface observations below remain source/scene evidence; owner-run execution verification is pending.

Inspected place: `74075244490179`, "logosism's Place: 10102026_1". These are observations of client source and scene definitions, not proof of a working server/account runtime.

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
| Supported island travel | `Client.Gui.Frames.WorldMap.TeleportTo`, lines 136–185: checks unlock membership; `Remote:FireServer("Teleport", "Workspace.Worlds.<World>.Islands.<Area>.Island.Portal.Spawn")`; base `FastTravel.Spawn` | OC resolves the exact existing spawn and rechecks both world/area membership immediately before travel; no unlock command. |
| Return travel | `StarterPlayerScripts.ClientScript` lines 1578–1586 binds each native island portal to its world's `PortalSpawn` | Existing `PortalSpawn` is an eligible supported base return destination. Missing spawn = no travel candidate. Seven Seas fishing-level travel and special-event routes are not generalized. |
| Bubble blowing | `Client.Gui.HUD` lines 377–441: `Remote:FireServer("BlowBubble")`; checks Plaza, GuiFrame, HUD, gift, alive character, Intro/Prompt/Trading, Bubble Lock and active fishing rod | OC reproduces observed guards, respects a minimum 0.5s request cooldown and confirms actual amount changes. Movement/race/trading conflicts stop OC actions. |
| Selling | `Client.Activation`: Sell roots activate at XZ distance <= `Root.Size.Y/2` and vertical difference <=10; sell interval2s; native `SellBubble` command | OC walks/travels into actual activation range, lets native selling run and waits for actual bubble decrease plus positive balance delta. No duplicate SellBubble command. |
| Selling travel/multipliers | `Client.Gui.HUD` lines 236–259 teleports to best Sell root by full path; native `findBestSell` checks unlocked islands and `Multiplier` (default1) | Only direct world Sell or native `Islands.<Area>.Island.Sell` locations are considered; unverified nested VIP facilities excluded. Scene examples: Overworld multiplier2; Twilight5; Minigame Paradise multiplier0.1 and Currency=Tickets. Missing Currency defaults Coins. Payout proof still requires actual balances. |
| Gum/flavor purchase/equip | `Client.Gui.Frames.GumShop` commands `GumShopPurchase(name)`, `UpdateStorage(name)`, `UpdateFlavor(name)`; cost currency table; raw `.Gum`/`.Flavors` ownership; `.Area` absent means accessible | Recheck catalog, actual funds, budget/reserves and ownership. Numeric premium costs are excluded. Bubble storage uses gum; no pet-storage purchase interface found. |
| Future stat projections | Existing `GetBubbleStorage`/`GetBubblePower` with a detached profile/equipment table set to the proposed catalog item | An economic model only; never replaces displayed real stats or mutates LocalData. Actual new stats and earnings still require owner execution. |

Permanent pools differ materially: Overworld islands supply Coins, with Gems on Twilight/The Void/Zen; Minigame Paradise islands supply Tickets; Seven Seas has an empty pickup pool. Retained live-zone overrides include GemMine Gems and seasonal currencies such as Leaves26. A live pool may also contain pet/powerup rewards; Phase 2 routes currency records only and does not implement those acquisitions. Actual account currency keys are discovered from active zone definitions rather than a fixed coin/gem assumption.

Source reference: the owner's [updated Phase 02 Notion page](https://app.notion.com/p/3f53d7e9278d8145a85aff38d5497e12). Its final revision and pasted final specification supersede older implementation/install wording. Normal movement uses Roblox [PathfindingService](https://create.roblox.com/docs/characters/pathfinding); no character CFrame, flight or speed modification.

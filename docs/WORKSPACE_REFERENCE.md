# Read-only workspace reference

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

LocalData exposes `IsReady`, `DidLoadFail`, `Get`, `DataReady`, `Changed`, and `PetsChanged`. Its profile originates from `Remotes.PlayerDataLoaded`; updates arrive through `PlayerDataChanged` and existing pet synchronization. The OC consumes these interfaces and never fires progression remotes. Requiring an existing game module runs that module's own initialization and dependencies; their behavior is owned by the game.

Observed permanent definitions include The Overworld, Minigame Paradise, and Seven Seas. Gate prerequisites come from their scene ancestry. Minigame Paradise's gate was on Zen; Seven Seas' gate was on Hyperwave Island. Currency unlock prices are read from the current definitions, not hardcoded. Island heights prefer scene attributes. Retained Christmas/Easter event definitions do not establish event availability and are excluded.

The inspected ServerScriptService and ServerStorage were empty. Saved client source included decompiled code and missing assets/interfaces, so source inspection alone cannot establish account delivery or helper compatibility. `Shared.Types` contained no usable runtime schema. No OC account data was fabricated to work around this.

Uncertain/outside Phase 1: authoritative game level/XP, first-play date, playtime, complete lifetime statistics, every inventory category beyond the observed fields, event availability, official endgame status, farm income/payback estimates, travel routes, reward claiming, shops and remote contracts. These are not inferred or advertised as implemented.

Before the owner's read-only workflow change, legacy Phase 1 modules/bootstrap were inserted into Studio. They were left untouched after the change. Repository code is a separate hosted build. No Studio scripts are inserted, modified, removed, or installed under the current workflow.

# Supporting systems: guilds, runes and currency identity

Actual root body/table reviews2026-10-11; unknown article revisions. Sources R-S014–016 and claims R-C013–016 are in the root ledgers. This extends [Stage1 stat dependencies](../replicatedstorage/STAT_DEPENDENCY_EXTENSIONS.md) and [schemas](../replicatedstorage/DATA_SCHEMAS.md), without regenerating native catalogs.

[Guilds](https://bgs-infinity.fandom.com/wiki/Guilds) describes10members and weekly quest sets with6stages, and says no season is active after Season1endedOctober10. Native Data.Guilds206 defines Season2startingOctober9for30days and WeekDuration518400seconds (**6days**); GuildUtil208–219 calculates its conditional window. The native UI additionally requires a matching received guild snapshot. This is VERSION_DEPENDENT/NEEDS_LIVE_VERIFICATION, not proof the wiki or retained catalog establishes live activation. Guild perks use the maximum unlocked percentage per stat, not sum of historical levels; earning XP, membership acceptance and management remain server gaps. Event, Bubble Pass and guild calendars must remain independent.

[Rune Crafting](https://bgs-infinity.fandom.com/wiki/Rune_Crafting) has nine recipes. Nominal durations agree with native Runes52–188, but several ingredient costs conflict:

| Recipe | Wiki ingredient | Saved native ingredient |
|---|---|---|
| LuckI |50Reroll Orbs |25Reroll Orbs |
| LuckII |75Reroll/10Power Orbs |50Reroll/5Power Orbs |
| LuckIII |150Reroll/25Power Orbs |100Reroll/15Power Orbs |
| SecretI/II/III |20/40/80Super Tickets |10/20/40Super Tickets |

Other listed ingredient descriptors and Bubbles recipes are consistent with the Stage1 summaries. Tier times are Luck45/120/240seconds, Secret60/120/300, Bubbles60/120/240. Native client83–106 projects finish as Start+Duration×Amount; amount10takes ten recipe durations under that model, not one. Inventory/active Buffs represent remaining rune uses. Public recipe wording cannot replace consumed-count, busy-craft, reserve and result verification. Compare the value of keeping Orbs/Tickets/Shards for their other uses and exclude noncraftable retained SummerLuck. Crafting was not performed.

[Currency](https://bgs-infinity.fandom.com/wiki/Currency) lists38keys/31limited; native catalog has49keys. The article usefully distinguishes Autumn Leaves for2026from Leaves for old Fall, but generic Candycorn lacks the newer exact Candycorn26/HalloweenShards account schema. Display labels are not profile keys. Retained currencies do not prove active earning opportunities; no fixed Coins:Gems:Tickets:Pearls or seasonal exchange is implied.

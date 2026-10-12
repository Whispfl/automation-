# Independent economic documentation review

Reviewed2026-10-11 against source inventory, economic module reads and five additional complete read-only source fetches. Review targets DATA_SCHEMAS.md, SHOPS_QUESTS_AND_CONSUMABLES.md and REWARDS_QUESTS_AND_EVENTS.md. Findings were sent to the root researcher; this review did not edit those three files. The findings describe the reviewed snapshot; the root may have incorporated corrections afterward.

Concrete corrections identified:

1. Potion duration symbol is Constants.PotionDuration70 (singular); Data.Potions30–34 accesses that name. The shops document initially used PotionDurations.
2. Stat is descriptor metadata in Shared.Data.Buffs, not a received ActiveBuffs/ActivePotions record field. BuffUtil48–50 records {Name,Level,Expiry={Type,Duration}};64–71 creates ActivePotions[potionName]={Queue,Active}; queued entries89/110 contain {Level,Expiry}. UseBuffs140/152 resolves descriptor Stat through potion/buff names. Active expiry is absolute; queued duration is relative.
3. EggBuilder166–178 exports World, no Area. Eggs531–539 adds Island from tagged scene attributes. An egg schema should use World and this conditional Island annotation.
4. ShopUtil.GetUnlockedSlots74–89 returns supplied generated count minus (maximum catalog ShopSlots mastery bonus minus received current mastery bonus). ItemShop311 passes GetUnlockedSlots(account,#generatedItems). GetItemsData126 generates base SlotCount plus maximum catalog mastery bonus. This is not a direct account.ShopSlots[id] lookup in the helper.
5. Enchant record fields from EnchantUtil384–388 are Id,Level,Extra. Metadata is catalog lifetime information chosen by GetMetadata77–96; do not declare received Metadata unless a precise additional caller confirms it.
6. SeasonUtil.NewPlayerSeason150 has LastCost and LastCostIndex, plus InfinityLuckLevel. "LastCost/Index" is ambiguous in an exact field-shape reference.

Support/wording cautions:

- Time-averaged chest utility should account for execution and opportunity costs by reducing net value; a phrase adding execution cost to benefit can mislead.
- The observed gift caps count the Gift category (Inventory239–240; root PromptBuilder gift guards). A shared gift/pickup physical-object cap was not established by those guards.
- Native image fields alone should not be interpreted as universal variant eligibility; general server hatch variant contracts remain unavailable.

Independently verified calculations:

- WheelSpin8–15 sums to99, conditional base Coins=(45*200+20*450)/99=181.818..., returned Spin Tickets=2.9*5/99=.14646....
- WorldRewardsBuilder59/77 gives arithmetic-progression slope2*(S-N*a)/(N*(N-1)) and upward rounding to50. For N30,a100m,S2trillion, tier30 rounds to133,233,333,350; sum is at least S and below S+50N.
- SeasonUtil110/130 clamps XP=3*Level to0..1750 and gives perk1+MaxPercent*XP/1750/100. Requirement457 is quadratic and rounded to50; source variant/generator anomalies reported by the root are present at231,291–292,347–348.
- DailyPerks49–91 free/VIP descriptors match the root's day/value listing. Time31/68–83 uses server Unix-day boundaries.
- ShopUtil242 reroll-duration denominator and stock baseline caveat220 match the root explanation. Ordinary discounts162–166 cap at95%; event-category handling128/138/163 is separate.

Additional review source paths: Shared.Utils.ShopUtil1–244; Shared.Data.Builders.WorldRewardsBuilder1–86; Shared.Utils.Stats.SeasonUtil1–602; Shared.Data.DailyPerks1–93; Shared.Data.WheelSpin1–25. Full source stayed transient, not copied into documentation.

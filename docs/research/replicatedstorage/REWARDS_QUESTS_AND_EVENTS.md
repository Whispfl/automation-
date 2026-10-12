# Rewards research — checkpoint
Research only, saved source date 2026-10-11. Reward calculations and principal client claim paths reviewed; fidelity and live eligibility limits remain. Quests and vendors are in SHOPS_QUESTS_AND_CONSUMABLES.md; rifts/Halloween are in SPECIALTY_AND_SEASONAL_SYSTEMS.md. Static catalogs cannot prove a claim is currently available.

## Playtime
`SOURCE_CONFIRMED`: `Shared.Data.Playtime:37–40` defines nine Gifts: (seconds,luck)=(120,1),(180,1),(240,1),(300,1),(450,5),(900,5),(1800,5),(3600,20),(5400,20); exports Gifts and Prizes. Prizes are built with `LootPoolBuilder` and `Chance` entries including currencies, potions, keys, fragments and Kitsune. `LootPoolBuilder:20–33` only appends `{Item,Chance}`; it does not normalize.

`SOURCE_CONFIRMED`: `Client.Gui.Frames.Playtime:99–135` compares `Time.now()-account.PlaytimeRewards.Start` with each gift time; claimed is `Claimed[tostring(index)] ~= nil`. This is a per-index map; count+1 is not a safe index rule. `MasteryUpgrades` containing Type Playtime controls visibility at394–404; Trading Plaza disables the module at41–44.

`SOURCE_CONFIRMED`: individual button calls `Remote:InvokeServer("ClaimPlaytime", LayoutOrder)` at369–376 and only animates a truthy returned result. Busy spinner flag u1 blocks another individual click. Native bulk `FireServer("ClaimAllPlaytime")` exists at446; button visibility is at least four currently eligible unclaimed gifts (191). The bulk button has no equivalent busy check in its callback. This visibility threshold is UI policy, not a documented server minimum or returned result contract.

`CLIENT_ESTIMATE`: playRoll modifies its display pool with the gift Luck only for ItemUtil rarity Legendary/Secret (223–240), and currency displays use `ceil(baseAmount*StatsUtil:GetCurrencyMultiplier(account,currency,true))` at183–186,261–264. Random filler spinner entries are presentation, not actual grants. Final server odds and claimed reward credits remain unknown. UI text shows `1 in ceil(100/Chance)` at323; this alone is not final normalized probability.

Success needs claimed index presence plus actual inventory/currency delta, not spinner completion. Timers may reset with account/server semantics; no reset rule was executed/observed.

## Daily
`SOURCE_CONFIRMED`: `Shared.Data.DailyRewards:8–14` is a seven-day item catalog. `Client.Gui.Frames.DailyRewards:411–473` uses `DailyRewards.LastDay, LastStreak, Claimed, Stars`, `Time.getAbsoluteDay()`, `untilMidnight()`, day position `(LastStreak-1)%7+1`, capped star calculation from Constants. Action at542 is `FireServer("DailyRewardClaimStars")`. Daily shop purchase is a distinct `DailyRewardsBuyItem(itemKey)` at376. Forfeit streak is separate at530 and must never be treated as ordinary claim. Server streak rollover/recovery rules, Robux recovery and authoritative login eligibility remain unverified.

## Giant/area chests
`SOURCE_CONFIRMED`: `Shared.Data.Chests` returns entries with `Rolls,Cooldown,Reward[],Pool[],DevProduct`.
| Chest | Cooldown seconds | Rolls | Base currency reward | Source |
|---|---:|---:|---|---|
| Giant Chest |900|3|500 Coins|Chests:13|
| Void Chest |2400|4|3,000 Gems|23|
| Ticket Chest |1800|4|3,000 Tickets|31|
| Peppermint Chest |900|4|75,000 Snowflakes|41|
| Halloween Chest |5400|10|500,000 Candycorn26|55|
| Infinity Chest |600|5|750 Coins; empty built pool|56|

These base rewards are not final credited amounts, and retained Peppermint/Halloween entries do not prove current spawning. Developer-product IDs are monetization metadata, not automatic free claims. Reward/pool draws, scaling and repetitions are server-only until corroborated.

`SOURCE_CONFIRMED`: `Client.Gui.Frames.WorldMap:664–705,830,897–911` supplies `ClaimChest(chestName,true)` and native QuickCollect iterates Workspace.Rendered.Chests with0.1s spacing then2s UI debounce. UI timer is `account.Cooldowns[chestName]-Time.now()`; area gate uses received AreasUnlocked. Native UI pacing is not proof of a server minimum. Physical claims and mastery-gated map collection differ; navigation contract file provides detailed gate evidence.

## World Rewards: paid progression, not free collection
`SOURCE_CONFIRMED`: `Shared.Data.WorldRewards:12,40,42,70` has 30 levels each for The Overworld (Coins) and Minigame Paradise (Tickets), minimum100m and nominal total2trillion. Builder output `{Currency,Levels[]}` contains `Cost={Type="Currency",Currency,Amount},Reward`. Initial rewards can be small currencies; tier30 catalog pets are Cerberus/Security System.

`SOURCE_CONFIRMED`: `Shared.Data.Builders.WorldRewardsBuilder:54–79`: for N levels, min a, nominal sum S, slope `d=2*(S-N*a)/(N*(N-1))`, tier i cost `50*ceil((a+(i-1)*d)/50)`. Before rounding arithmetic progression sums to S; rounding causes total between S and S+50N (strict upper). This rounding arithmetic is a source-supported derivation, not a server price guarantee. With N30,a100m,S2trillion, final unrounded tier is133,233,333,333.33; rounded133,233,333,350.

`SOURCE_CONFIRMED`: `Client.Gui.Frames.WorldRewards:157–178` checks cost and pet inventory space, then calls `FireServer("ClaimWorldReward",worldName)` without tier argument. UI enables only `Progress+1` at296–305 and requires `WorldsUnlocked[world]==true` at267–272. Removed worlds filtered49–50,111–113. Station activation opens current world's menu353–366; it does not establish server proximity. Affordability notification sequentially subtracts ALL next prices at276–284 and has no protected reserve policy. It is an affordability count, not economic approval.

Recommended result evidence: next Progress exactly increments and correct cost/reward delta received. Decompiler caveat: Reward_upv_1 is reused across level callbacks at110,129,175; do not trust this reconstructed closure as proof of correct pet-space guard for every tier.

## Opportunity valuation
`HYPOTHESIS`: free eligible claims can have high net value if compatible with location and no meaningful delay, but “free” still has setup/travel/presentation time and opportunity cost. A repeatable chest's time-averaged value is conditional expected utility per cycle after deducting execution and opportunity costs; current claim priority should use actual eligibility and incremental interruption time. Paid World Rewards need individual next-tier and downstream-package appraisal. Never roll base Chance/catalog reward into final probability or income without the native modifier/server outcome evidence.

No in-game grants were observed; ACCOUNT_OBSERVED unavailable in Edit mode.

## Wheel

`SOURCE_CONFIRMED`: `Shared.Data.WheelSpin:8–15` is an eight-entry pool with Chance weights 45,20,14,10,4,3,2.9,0.1 (sum99, not100): Coins200, Coins450, Coins potionIII, Golden Key, Speed potionIII, Mystery Box, Spin Tickets5, Umbra. Native client uses this specific wheel (`Client.Gui.Frames.WheelSpin:44`), whose model path is `Workspace.Worlds.The Overworld.Islands.Floating Island.Island.WheelSpin` (`48`).

`CLIENT_ESTIMATE`: if the server uses these unmodified normalized weights, expected base Coins per spin are `(45*200+20*450)/99 = 181.818...`, and expected returned tickets are `2.9*5/99 = 0.14646...`. These are conditional pool calculations, not measured rewards or a profitable ticket loop. Currency multiplier, special effects, server pool and actual ticket availability can change value. Six-second animation is presentation cost (`WheelSpin:56`), not a proven server cooldown.

`SOURCE_CONFIRMED`: `spin:235–287` checks loaded account and owned Spin Ticket (`tbl_upv_2:55`, guard262), then `InvokeServer("WheelSpin")` (`266`) returns the index used for animation. `finishSpin:66–111` displays that index and sends `FireServer("ClaimWheelSpinQueue")` (`106`). Request and queue collection are separate steps. If no ticket, native UI prompts a developer-product purchase (`286`), which is not an automatic fallback.

Free collection is `FireServer("ClaimFreeWheelSpin")` in the auto helper `358–375`, gated by received Mastery Type AutoClaimSpin; received `NextWheelSpin-Time.now()` (`400–412`) determines due status. Manual free click has a local0.2-second debounce (`595–609`). `Constants.FreeWheelSpinCooldown:16` is1,200 seconds, but received deadlines govern current eligibility. Completion requires ticket/cooldown change, queue result and actual item/currency credit. Spinner finish alone is insufficient. Native animation/UI locks conflict with travel or another reward presentation; stop on missing LocalData, unresolved queue, no ticket or deadline not due.

## Index

`SOURCE_CONFIRMED`: `ReplicatedStorage.Shared.Utils.IndexUtil:GetCompleted:13–45`, `GetEggCompleted:47–75` consult discovered-history variants. They are not ownership/equipped-team queries. Secret pets are excluded from the required total (`35–36`) while found counting includes discovered variants; a reconstructed `v4=v5 and v4+1` (`34`) is type-inconsistent and cannot be treated as a reliable completion formula. Normal/Shiny/Mythic combinations are checked by `HasAny:102–104`; XL discovery uses separate keys (`200+`). Preserve discovered history after selling/deleting pets.

Native calls: `Client.Gui.Frames.Index:391` sends `EggPrizeClaim(eggName, mode=="Shiny")`; `534` sends `ClaimEventPrize(eventName,mode)`; `2351` sends `ClaimIndex(worldOrEventName,mode)`. Mode is an argument with source-specific type, not a interchangeable boolean. Egg claimed keys use optional S prefix (`740–742`); world claims optional Shiny prefix (`883`). World view uses `IndexLocked != nil` (`879`), and a Shiny reward descriptor may also set Mythic (`875–877`). Source has nil dereferences/reused temporaries around `733–734`; per-mode claim counting at `593–630` may lack the same prefix. Full eligibility should therefore remain UNAVAILABLE until corroborated.

XL UI: `Client.Gui.Frames.Index.XLIndex:262–296` binds `ClaimXLIndexRewards(taskKey)` (`292`). Received `XLIndexClaimed` is searched as an array (`322`); `IndexUtil.GetXLTaskProgress(discovered,taskKey)` supplies progress (`324`), button visible only when progress >=task.Amount and unclaimed (`328–346`). Update uses received Discovered and XLIndexClaimed (`369–375`). No callback-specific pacing/proximity proof was found. Success requires claimed-key addition plus correct rewards; a completion bar is a client estimate. `Shared.Data.XLIndexTasks` needs separate complete reward/task catalog normalization.

## Milestones

`SOURCE_CONFIRMED`: `Shared.Data.Milestones` contains Bubbles16, Hatching86, GemGenie153, Enchanting180, Playtime218, Minigames302, SecretPets359, Shops420, Potions497, Obbys528, RebirthMachine551, Fishing604, WorldEggs653 and explicitly Removed Christmas681/StPatricks737/Easter760. Entries are assembled through MilestoneBuilder/TierBuilder/BuffBuilder, keyed by category but use a distinct QuestId. Do not combine these keys casually. WorldEggs derives egg groups from catalog World (`638–651`) and has location-specific hatch tasks; world travel and egg costs remain relevant.

`ReplicatedStorage.Shared.Utils.MilestoneUtil:TIER_ORDER:16` orders Bronze/Silver/Gold/Platinum/Super/Ultimate/Infinity/Omega. `GetQuestId:25–38` constructs `milestone-<QuestId>-<level>`; `GetCurrentCategoryLevel:106–124` counts consecutive nonnil received QuestsCompleted keys. `GetMilestoneRewards:125–174` carries special flags/titles from earlier tiers but takes numeric buffs only from each category's latest completed tier, then combines categories by ValueType. Adding every historical tier's numeric buffs would overstate stats.

Examples grounded in catalog: GemGenie first completion grants cooldown5%; third completion rewards10%+cooldown5% (`Milestones:155–156`); subsequent requirement counts5/8/12/15/25/75/150/250/500/1000/2500 (`160–178`) change rewards and cooldown descriptors. Actual cooldown calculation is not established by the descriptor. Hatching150,000 includes Hatches1+Luck35%+HatchSpeed20%+EggCost15% (`98`), not an investment automatically appropriate for a new account. Potions25,000 introduces NoPotionConsume (`518`); its chance text comes from Constants (`MilestoneBuffs:49`) and needs server outcome evidence. Shop milestones add stock/discount/refresh/free-refresh buffs (`Milestones:442–493`) consumed by ShopUtil; earning those thresholds can have compound vendor value.

`Client.Gui.Frames.Milestones` exposed paid skip selection (`InvokeServer("SelectMilestoneSkip")` at1182) but no ordinary milestone claim interface was established. Automatic completion/grant timing remains UNAVAILABLE. `MilestoneUtil.CURRENT_RESET_END_DATE:13` is a saved2035 date, not verified live policy. Ordinary milestone activity should be verified through quest progress/completion and effective stat differences, never an assumed remote label.

## Daily perks and time

`SOURCE_CONFIRMED`: `Shared.Framework.Utilities.Math.Time.now:26–32` uses Workspace:GetServerTimeNow; getAbsoluteDay68–75 and untilMidnight76–84 are UTC Unix-day boundaries. Weekend is Saturday/Sunday UTC (`145–193`). These are separate from the owner's Windows local date/timezone. DailyPerkUtil uses weekday `((Time.now()//86400+4)%7)+1` (`20,55`); named days Bubble/Minigame/Hatch/Treasure/Shop/Enchant/Luck (`25–31`).

`Shared.Data.DailyPerks:44–91` gives free/VIP buff descriptors: Sunday Bubbles25/35%, Sell30/50%; Monday extra drops1/2 and cooldown15/30%; Tuesday extra hatch1 and speed15/30%; Wednesday currency15/30% and chest cooldown15/25%; Thursday discount25/50% and stock50/100%; Friday enchant cost25/45% and special chance20/35%; Saturday luck100/250% and legendary fish35/50%. `DailyPerkUtil.GetPerkValue:57–74` uses OwnsDailyPerkPremium and BuffUtil; Constant perks return the provided base value. Text such as “The Void Calls...” does not establish an extra usable mechanic. An effect's exact downstream calculation requires its consuming helper.

## Challenge Pass and Season Pass are separate

`SOURCE_CONFIRMED`: `Shared.Data.ChallengePass:11–27` defines FinalTier15, ID autumn and Finish2026-10-02UTC; IsActive compares server time to Finish. This date precedes the research session date. Treat it as a retained/expired saved definition, not evidence that an Autumn challenge opportunity is live. Formula at43: cumulative points for tier t=`50*round(20000*(t/15)^2/50)`; GetTier selects highest eligible threshold (`45–59`). Gem reset cost=`min(2^GemResets*10m,200m)` (`60–67`); resetting consumes valuable currency and is not a claim.

Challenge client calls: `ChallengePassClaimReward()` (`Client.Gui.Frames.ChallengePass:255`, no tier argument), `ChallengePassClaimAll()` (`472`), `ChallengePassFreeSkip()` (`267`) and `ChallengePassReset()` (`366`). Claim-all finds unclaimed tiers up to GetTier and checks pet space (`447–472`); reset checks affordability, UI only shows after final tier and all claimed (`651–654`); free skip UI requires next tier and FreeSkips>0 (`687–688`). Received account fields Points,Rewards[],Claimed[],FreeSkips,GemResets,LastInviteBonus matter. Paid products and invites are excluded from automatic objectives. Server reset/claim rules and live pass state remain UNAVAILABLE.

`Shared.Data.Seasons` has25 season definitions, Start/Finish, Points, Pool and Free/Premium Track; assigns numeric ID (`1582–1589`). Saved season25 spans2026-09-25..2026-10-16 (`1517–1518`) and has Fall Season Egg rewards. The catalog window conditionally includes the research date, but this is not independent active-event evidence and does not override the owner's Halloween report. Season Pass, Challenge Pass and physical event availability must be tracked independently.

`Shared.Utils.Stats.SeasonUtil:23–25,103–130` uses XP=min(max(3*Season.Level,0),1750); perk scalar `1+(maxPercent*XP/1750)/100`, with ranges HatchSpeed25%, CelestialLuck150%, Luck500%, PassLuck2500%. Its selector scans saved Start/Finish using DateTime.now and refreshes every20seconds (`559–600`); DateTime client selection differs from server-time deadline checks elsewhere. `GetRequirement:452–458` follows a quadratic points threshold rounded to50. Infinite track requires IsInfinite and has next8-tier cache (`356–388`), costs increase by2,000..2,500 rounded to50 on requirement tiers divisible by4 (`157–165,220–224`).

Infinite pool fidelity problems: tautological rarity branch (`231`), apparent downgrade of >level6 potion to<=5 (`291–292`), premium rod replacement writing the free reward variable (`347–348`). GuaranteedSecretPet600 and variant sampling at `187–204,272–282` are saved helper behavior, not a general egg pity system or authoritative server odds. Reuse received InfinityTiers for planning; do not recreate uncertain grants from this reconstruction.

Native `Client.Gui.Frames.Season` sends `ClaimSeason()` for ordinary/infinite tracks (`937,1559`), with pet-space checks and PolicyInfo restriction logic (`925–936,1544–1553`); no tier argument. Animations precede the call. Claiming an infinite free tier can permanently skip a rare premium reward; native warning is at942–944. `BeginSeasonInfinite()` (`1840`) follows a long presentation and requires completed normal track checks (`1374` and surrounding flow). These state-changing opportunities need explicit scope approval and fresh Level/Points/ID/result verification. Gift/paid-skip paths were identified but not researched as automatic farming actions.

## Remaining reward work

Complete catalog normalization for milestone levels, XLIndexTasks, achievement prizes, current pass rewards, all wheel variants and daily shop offers remains unfinished. Saved paths/source metadata make resumption possible. Full server grant, completion, stock and temporal rules cannot be established from this Edit-mode source library.


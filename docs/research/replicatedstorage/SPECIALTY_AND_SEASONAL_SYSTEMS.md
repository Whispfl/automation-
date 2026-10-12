# Specialty and seasonal systems

Research date: 2026-10-11. Read-only Studio source/hierarchy/property research after parent completed the ReplicatedStorage inventory. No native modules required/executed, remotes invoked, objects changed, play-state changes or gameplay tests performed. Full game scripts/bytecode are not saved locally. This document stores summarized knowledge and selected mathematical relationships; exact source anchors are in SPECIALTY_SOURCE_LEDGER.md.

`SOURCE_CONFIRMED` here means visible native client/shared source, including limitations of the saved/decompiled representation. It is not server acceptance. `CLIENT_ESTIMATE` qualifies client probability/value formulas. `HYPOTHESIS` identifies proposed OC usage. `UNAVAILABLE` marks missing result/server/live evidence. No private account values are recorded.

## Batch D saved: initial source findings

- Rift catalog includes Egg, Chest, Sell and Gift types, area lists, ignored special entries, chest key cost and weighted reward pools. Native catalog presence/weight does not prove a currently spawned eligible Rift.
- Summon cost options include time values 600/900/1800/2700/3600 seconds and luck values 5/10/15/20/25, each with separate costs. Full native client composition is documented below. Generated egg mappings contain unresolved/nil decompiler expressions, so do not execute or invent repaired mappings from this text.
- XL rotation source chooses two distinct configured eggs using a day-based seed and reports time until midnight, contradicting the roadmap's tentative 12-hour lead in this representation. Global XL, admin and AlwaysAllowXL flags can override rotation. Final server chance remains unavailable.
- Secret bounty source uses a day interval, deterministic nonrepeat target/egg selection, and current Halloween-themed target array; historical target arrays still exist but do not imply active target choice. Mythic bounty is a separate quest with received BountySeed/progress state.
- Halloween rebirth client describes **Candycorn reset** and one HalloweenShard reward. Cost helper is `min(20e9 + (nextRebirth-1)*250e6, 170e9)`. The actual server reset/effect/acceptance is unavailable. Treat as protected destructive spending, not a reversible ordinary currency exchange.
- Halloween upgrade catalog and client use `HalloweenShards` and `Halloween26Upgrades`; Candycorn schema is `Candycorn26`. `Leaves26`/`RebirthShards26` are different historical schemas. Upgrade definition and UI appearance alone do not prove event eligibility.

## Batch E: Rift definitions, costs and lifecycle

`SOURCE_CONFIRMED`: Rifts defines type, area lists, Weight, optional Ignore/Egg/RiftSummonCost and chest `Cost`/`Pool`; special Sell/Gift entries also exist. Explicit catalog families include Doodle/Dark/CorruptDark eggs; ignored Brainrot/Developer/OG entries; Golden/Dice/Royal/Super chest definitions; Zen Sell and Floating Island Gift. Later generated eggs use Worlds.Islands and skip Removed worlds. The saved representation has `Egg=nil` and unresolved locals in that generation path; derive no authoritative evaluated generated mapping from it.

| Chest Rift ID | Entry cost per client definition | Base summon shard cost | Reward family (definition only) |
| --- | --- | --- | --- |
| golden-chest | 1 Golden Key | 10 | Abyssal Dragon, higher keys, Mystery Boxes, Lucky/Speed/Coins/Mythic potions at levels2–4. |
| dice-rift | 1 Dice Key | 10 | Dice Split, Infinity/Secret elixirs, Dice/Giant/Golden Dice, Super Tickets, Tickets/potion rewards. |
| royal-chest | 1 Royal Key | 25 | Hacker Prism, Rift Charm, Infinity/Secret elixirs, higher potions, boxes, Reroll Orb and Golden Key. |
| super-chest | 1 Super Key | 50 | Rift Charm, Infinity/Egg/Secret elixirs, higher potions, boxes, Reroll Orbs and Golden Keys. |

LootPoolBuilder simply stores Item/Chance and returns the list unchanged. Thus raw numeric Chance is visible catalog data, not an inspected server sampler. Exact final reward distribution, boost transforms, duplicate/independent draw rules and bulk count remain `UNAVAILABLE`. A Rift's general Weight is a spawn definition, not an eligible user's probability of reward.

`SOURCE_CONFIRMED` summon options:

| Time option index | Duration seconds | Rift Shard cost |
| --- | --- | --- |
| 1 | 600 | 1 |
| 2 | 900 | 2 |
| 3 | 1800 | 4 |
| 4 | 2700 | 8 |
| 5 | 3600 | 16 |

| Luck option index | Displayed multiplier | Rift Shard cost |
| --- | --- | --- |
| 1 | 5 | 1 |
| 2 | 10 | 2 |
| 3 | 15 | 3 |
| 4 | 20 | 4 |
| 5 | 25 | 5 |

The native client computes `shards = base target cost + selected time cost + (egg only: selected luck cost)`, and requires at least1 Rift Charm. Charm display is1. For example, Golden Chest at600seconds costs11shards plus1charm; each opening separately needs its Golden Key. A one-hour duration doubles shard cost over45minutes while adding15minutes, so duration efficiency depends on how much useful work and travel actually fits; max duration is not automatically best.

SummonCosts skips Ignore entries and explicit zero summon-cost eggs. For other eggs, a visible formula branch uses an explicit Egg.RiftSummonCost if present, otherwise base1 +10perSecret pool entry +5perLegendary with tier≥3. This is `CLIENT_ESTIMATE / SOURCE_CONFIRMED branch`, not a successfully evaluated generated table because reconstructed table locals are unresolved.

RiftSummon client excludes Trading Plaza and ignores world selection changes to Seven Seas/Christmas World/Easter Paradise; available targets come from native per-world cost maps. Actual received MasteryUpgrades must contain UnlockRiftSummon for shard-drop luck helper to return nonzero. Rift Mastery catalog shows5mGems unlock,35mGems +25%shard buff,125mGems Radar1,1bGems Radar2. These are definitions, not current account levels or permission to purchase.

### Source-confirmed request schemas, never invoked here

| Native action | Arguments / client guards | Result/verification boundary |
| --- | --- | --- |
| SummonRift via Remote.InvokeServer | Config `{Type="Egg" or "Chest", Name=target, Time=option index, Luck=option index for Egg, World=selected world}`. Client has native Charm/Shard affordability and confirmation prompt. | Returns success/error; visible failure `no-space-left`. PlayerSummonedRift(name,type,target,world,height) notification is supporting evidence, not actual material deduction/new object eligibility proof. Require fresh object and received costs later. |
| TeleportToRift via Remote.FireServer | Actual rendered Rift Model instance from current-world HUD mapping. Requires MasteryUpgrades RiftRadar Level2; BoardHUD not visible. | Request dispatch ≠ arrival. Later adapter needs stable actual position/world, remaining lifetime and no conflicting location lease. |
| UnlockRiftChest via Remote.FireServer | `(rift model name, boolean mode)` after actual root within10studs of Prompt, matching chest definition/key amount. UI modes depend on MultiChest/AutoClaimChest Mastery. | Third UI activation sends boolean true; exact server bulk count/cost behavior is unavailable. Native visual animation before receipt is not reward proof. Never infer unlimited/free/batch accepted outcomes. |
| ClaimRiftGift via Remote.FireServer | `(rift model name)` from Gift Rift prompt. Prompt activation10studs; model DespawnAt and Type expected. | Prompt disabled/animation is local, not claim receipt. Current player entitlement, repeatability and server lifetime/range rules unavailable. |
| ClaimGift via Remote.FireServer | `(received gift ID/model name)` in PhysicalItem.Gift, distinct from Rift gift. RenderGifts payload is keyed `{Name,Position}`. Native input requires rendered/in-range gift;8Hit animations lead to Collect. Horizontal range≤15studs and animation guards exist. | Receiving RenderGifts is not authorization to call ClaimRiftGift on those IDs. Actual inventory/currency delta and entitlement acknowledgement still required. |

The older Flame roadmap note conflates RenderGifts IDs with ClaimRiftGift. Current native reference source uses **ClaimGift for those rendered physical gifts**, while ClaimRiftGift targets the Rift model name. Preserve Flame as a lead only; do not copy its command contract.

Rift models expose `DespawnAt`, `Type`, `World`, pivot and inner objects. ClientScript attaches timers; egg DespawnAt changes replace the timer; model destruction disconnects UI bindings; ChildAdded setup waits5seconds. Scene observation after the inventory found a saved Gift Rift whose expiry converts to2026-10-10T18:31:56.714Z. Studio reports Edit mode, so this retained object cannot establish a fresh live Rift. Native Time.now uses Workspace.GetServerTimeNow; elapsed time must be computed against that synchronized clock in an authorized future runtime.

`HYPOTHESIS` planner rule: join actual definition/object/account, subtract travel/setup/verification margin, then calculate affordable useful hatches or chest opens inside remaining lifetime. Skip missing/expired/unknown-access Rift. Reserve world-goal funds, Charm/Shard budget and correct keys before ranking reward value per total time. Cancellation/expiry releases location and clears queued opportunity, retaining dispatched costs/attempt ledgers. No current OC specialty executor exists.

## XL and bounties

### XL eligibility and estimates

`SOURCE_CONFIRMED`: XLEggUtil clones Constants.XLEggs, seeds Random from `floor(serverTime/86400)`, removes each chosen entry and returns2distinct eggs. Countdown uses the next epoch-day boundary, i.e.00:00UTC by the native Time helper. GlobalEvent XL active overrides rotation; known IsAdminEgg/AlwaysAllowXL definitions also bypass rotation. This version's visible source does not use the roadmap's tentative12hour cadence.

Constants XL table contains rarity-conditioned numeric thresholds: Common0.0002, Unique0.00028571428571428574, Rare0.0013333333333333333, Epic0.004, Legendary0.05, Secret0.4; XLMultiplier2.5 and ShinyCountRequiredXL8 exist. These names/values do not establish a final hatch distribution. PetUtil display scales variant values by100 and has nested reconstruction artifacts; no game sampler was inspected.

XLEggUtil.GetChances clones thresholds and divides by `v8`; in the visible expression `v8=1` unless PlayerHasEvent("XL Event"), then it includes applicable milestone XLChance and+0.25. The direction/meaning of this transformed table must be established at its actual sampling consumer before claiming improved final chance. Do not blindly multiply ordinary egg odds by this threshold table. Parent pet/economy ledger owns broader variant/helper evidence.

### Secret versus Mythic bounty

| Family | Definition and rotation | Objective/result boundary |
| --- | --- | --- |
| Secret bounty | Interval86400seconds; seed floor(serverTime/interval)-1. Current selection uses3Halloween-themed targets: Pumpkin Spice2e-7, Hellspawn5e-8, Guiding Light1e-8 numeric Chance fields. Seeded target/egg selection avoids immediate repeat; current base egg candidates plus supported Rift eggs. | Client sign displays `1/ceil(100/Chance)`; Chance is a percent-unit rarity field, not a unit probability. Historical array is retained but not chosen by visible Get(). Hatch-result/Discovered fields need verification; no separate ClaimSecretBounty action was established. |
| Mythic bounty | Separate `bounty-mythic` quest; daily seed floor(serverTime/86400). Candidate pets have tier<2 and an egg with World. | Hatch1ofspecifiedpet with Mythic=true; rewards2MysteryBoxes +1LuckyV5 +1SpeedV5. Refresh replaces old bounty task and BountySeed in a profile, a helper mutation not run by research. Actual quests/progress/claim interface belongs to parent quest ledger. |

SecretBountyUtil assigns defined chance values into Pets records at module initialization. That visible side effect is native implementation evidence; this research never requires the module. The client target name/egg/time display does not prove account-specific bonus eligibility or a reward claim.

`CLIENT_ESTIMATE` conversion for a raw percent field `c` is base display probability `p=c/100` if that same interpretation applies to final sampling. Under a fixed independent p, success in n hatches is `1-(1-p)^n` and expected hatch count1/p; budgets/expiry can cap n. Luck, target insertion and server draws may differ, so exact final odds/guarantees remain unavailable. Compare bounty/XL eggs against **best feasible owned-team score**, target overlap and total time, not their rarity label alone.

## Three different event mechanisms

1. **Shared.Data.Events:** index/group definition registry, reward groups and Eggs.Event membership. Both Autumn26 and Halloween26 plus many2025groups have Active=true. Tagged Egg scan only sets true. No seasonal end timestamp is exposed here. These Active fields do not establish currently active gameplay.
2. **Shared.GlobalEvent:** boost names Lucky/Hatching/Bubbling/Secret/Mythic/Shiny/XL/Infinity. Workspace attribute is an expiry timestamp; GetRemainingTime clamps(timestamp-nativeTime,0) and IsActive requires>0. These timers describe boosts, not an event island's removal date.
3. **Shared.Utils.SpecialEventUtil + SpecialEvents:** deterministic half-hour seed, event on even seed (one30minute slot per hour), sorted event-name selection; duration1800, GlobalPurchaseTime900. PlayerHasEvent returns scheduled global match or nonnil SpecialEventTimers[eventName]. Expiration cleanup of personal timers is not established by that function; inspect raw time/freshness/cleanup before treating stale presence as active.

SpecialEvents definitions list ticket costs and descriptions: Luck3, Shiny3, Mythic3, Celestial5, Secret5, Infinity10, XL5, SuperPalooza3. Description multipliers are source text; exact event purchase/currency item and all native stat applications require their own consumer evidence. Existing subscriptions are account facts; no ticket purchase was performed.

## Halloween26 facilities, upgrades and rebirth

Read-only Edit scene has HalloweenEvent folder/Spawn/Return/Houses/TrickOrTreat/Pickups/Shop and HalloweenTeleport/HalloweenRebirth/HalloweenRebirthUpg objects. Native client assumes those paths, excludes Trading Plaza and uses `Teleport(destination:GetFullName())`. Scene existence strengthens current saved-version schema evidence, while live access, event deadline and current account readiness remain unavailable.

`SOURCE_CONFIRMED` account schema expected by these clients: Candycorn26, HalloweenShards, Halloween26Rebirths, Halloween26Upgrades[name], Halloween26AutoRebirthEnabled. Missing fields must remain unavailable; do not substitute Leaves26/RebirthShards26.

| Upgrade | Type / base value | Tier values | Per-tier HalloweenShard cost | Sum from tier0 |
| --- | --- | --- | --- | --- |
| Currency | Multi/Percent/base0 |2.5,5,10,20,25,40 |1,2,4,8,12,20 |47 |
| Luck | Multi/Percent/base0 |2.5,5,10,20,25 |1,2,4,8,16 |31 |
| SecretLuck | Multi/Percent/base1 |5,10,15,20,25 |3,6,12,24,48 |93 |
| InfinityLuck | Multi/Percent/base1 |2.5,5,7.5,10,12.5 |5,10,20,40,80 |155 |
| AutoRebirth | Single boolean |native auto toggle eligibility |5 |5 |

Catalog tier Values replace the selected level's helper contribution; they are not accumulated by adding all prior Value percentages. BuffUtil.Percent returns `base + value/100`. Currency helper thus returns0.025atlevel1 and0.4atlevel6; visible StatsUtil Candycorn branch adds this to existing additive value before outer composition. Halloween Luck contribution is added only for Constants.Halloween26Eggs: Skelly/Vampire/Creaking/4xLuckCreaking. An ordinary luck upgrade is not automatically a multiplicative25%increase to every final rarity chance.

Parent economy researcher fully inspected StatsUtil1–2585 and found only the Currency/Luck Halloween helper consumers. **SecretLuck/InfinityLuck catalog descriptions lack a direct confirmed consumer there.** This does not disprove server effects; it prevents assigning a guaranteed Secret/Infinity ROI from description alone.

Native client `BuyHalloween26Upgrade(name)` checks actual owned tier/max/single ownership and ItemUtil amount of HalloweenShards against next cost. Result UI subscribes to HalloweenShards/Halloween26Upgrades. Later verification needs received tier absent→owned or level+1 and scoped shard delta; a sound animation does not qualify purchase.

### Rebirth mathematics and protected reset

Cost for next rebirth index n is `C(n)=min(20e9 + (n-1)*250e6,170e9)` Candycorn. For current count k, next threshold is `min(20e9+250e6*k,170e9)`; cap reached at current count≥600. Client text says Candycorn is reset and gives1HalloweenShard. `HalloweenRebirth()` has no args; `Halloween26ToggleAutoRebirth()` no args. Native auto loop checks owned AutoRebirth, toggle and sufficient Candycorn every1second. Research neither executes nor reproduces that loop in OC.

All listed upgrades total331shards fromtier0 includingAutoRebirth. Under the unverified assumptions of startingzero, exactly1shard/rebirth, no other shard sources and no existing shards, that would require331rebirths. Sum of threshold costs is `20e9*n +250e6*n*(n-1)/2` until cap; at331 this is20.27375trillionCandycorn. This is a conditional accounting lower bound when balances hit thresholds exactly. Resetting excess Candycorn, concurrent income, shop spending, existing upgrades and unknown server rules change the real path; it is not a recommendation to buy everything.

Rebirth must be treated as explicitly protected destructive progress/currency reset. Compare marginal confirmed upgrade benefit, remaining event time, thresholds and forfeited currency/egg/shop opportunities; respect hard reserves and user allowlists. Actual count/shard increase **and actual Candycorn reset** are required result evidence. Client text cannot prove pets/upgrades/other account fields are unaffected by server implementation.

### Trick or Treat

ClientScript exits if HalloweenEvent missing or TradingPlaza. It binds each actual house Activation, requires Active.Value and sends `TrickOrTreat(houseInstance)`. Received TrickOrTreatFreeze(state,character) only affects matching local character; respawn clears its local freeze attribute and physics updates. This establishes native location/ownership constraints, not reward amount, cooldown or always-repeat eligibility. Later planning must inspect actual house state, movement/interaction rules and received reward/cooldown before adding an executor.

## Required unknowns and future stop conditions

- `UNAVAILABLE`: event seasonal end/removal timestamp, current eligible player state, server Rift lifetime/range/mastery/material validation, final RNG/pity, summoned object identity correlation, bulk chest semantics, gift entitlement, reset/purchase actual acknowledgement and persistence.
- `SOURCE_CONFIRMED` saved scene availability and client schema only; owner reports Halloween. Historical Fall Notion/catalog and Events.Active cannot override that report or establish a date.
- `HYPOTHESIS`: future capabilities share existing GameKnowledge cache, Reader, OCBrain, TaskScheduler and GameMechanics. Require explicit Phase7/8/9 approval, exact native arguments, protected material/currency commitments, one location lease, bounded retries, deadlines, cooperative cancel and actual received result. No background executor/helper loop is added.
- Stop immediately on missing/stale object, expiry, account unreadiness, changed target/access/stock/budget, insufficient protected resources, conflicting activity, player death/respawn or uncertain result requiring reconciliation. Leave unverified reset and probabilistic rewards unknown; never retry repeatedly from appearance alone.

Batch E saved: assigned specialty/seasonal research complete. Complete/targeted read list and representation limitations are in SPECIALTY_SOURCE_LEDGER.md; no gameplay/source/build/Git changes.

## Additional batch F: Bubble Shrine and pet conversion machines

These are distinct mechanisms. Bubble Shrine consumes selected potions/powerups to increase persistent shrine XP and extend a temporary blessing. Rebirth/Crystal/Admin machines consume specifically chosen pet IDs to roll a replacement. Halloween rebirth resets Candycorn; it does not share either contract. All findings below are `SOURCE_CONFIRMED` for the saved native representation and conditional mathematics; no server action occurred.

### Bubble Shrine

`Shared.Utils.ShrineUtil15–17` defines maxlevel50, donation interval3600seconds, and a legacy blessing duration constant1800. Actual duration helper109–125 scales with **item count**, not item XP: `D(a)=floor(60*(15+1425*clamp(a,0,500)/500))` seconds. One item contributes1071seconds (17m51s),100items18000seconds (5h),500items86400seconds (24h). Existing active time is extended and capped at86400seconds; expired blessing starts at native now. Do not substitute the1800constant for the consumed-count helper. `IsBlessingActive57` requires now<`BubbleShrine.ShrineBlessingEndTime`.

XP threshold for level L is `clamp(5*ceil(5e6*((L-1)/49)^2/5),0,5e6)`; level1 requires0 and level50 requires5millionXP. `GetCurrentLevel74–82` selects the highest threshold reached. Each eligible donated item adds its matched catalog XP, so count and XP are different benefits. Client245–328 displays count-scaled XP and duration, clones the exact item descriptor with chosen Amount, and calls `InvokeServer("DonateToShrine", itemTable)` at303. The true return plays success sound; later OC verification would require the matching inventory deduction, `BubbleShrine.Experience`, `LastDonationTime`, and blessing endtime changes. Sound alone is insufficient.

| Item family | XP per item in ShrineValues | Reserve implication |
| --- | --- | --- |
| Infinity / Secret / Egg Elixir level1 |200000 /75000 /50000 |Compare actual buff/hatch value before irreversible donation. |
| Lucky/Mythic/Speed/Coins/Tickets levels1–7 |25,50,65,85,135,15000,250000 |Sharp level6/7 XP jump; preserve potion commitments and best feasible use. |
| Powerup types Egg / Generic / Key / Orb / Gift |150 /10 /5 /5 /5 |Exact named item comes from Powerups definition; key/gift summon/chest value can exceed shrine XP. |
| Fragment and Frozen Key |Excluded by builder |No donation eligibility inferred. Unmatched GetItemXPValue returns nil. |

`ShrineBuffs7–10` and ShrineUtil18–48 linearly scale unlocked percentage bonuses to level50: Luck startslevel1 with15 and reaches150; Currency starts5 with5 and reaches75; Bubbles starts10 with5 and reaches50; HatchSpeed starts20 with5 and reaches25. Helper returns `BuffUtil:GetValue(1, Percent)` and the unscaled display percentage. Final stat composition needs its StatsUtil consumer and active blessing predicate; a catalog bonus does not independently establish final hatch probability or farm rate.

Client192–242 uses `LastDonationTime+3600` for the cooldown UI and updates on BubbleShrine received changes. Inventory is read from Potions and Powerups (569–663); quantity prompt limits1..owned amount (340–414). Client761–772 binds actual activations at Overworld/Zen/BubbleShrine and Minigame Paradise/Hyperwave Island/BubbleShrine. Opening the summon tab additionally requires MasteryUpgrades.Type=UnlockRiftSummon (689–719). Server proximity, cap behavior for excess XP, exact XP/result atomicity and whether unsupported displayed inventory can be rejected remain unavailable. Future scheduler eligibility requires fresh account data, ready cooldown, actual accessible shrine, an explicit donation allowlist and hard reserves; no automatic rare-potion liquidation.

### Native pet conversion / fusing

`Shared.Utils.RebirthMachineUtil` provides the visible fusing mechanism. No separate FusingUtil module was found in the attempted exact read; that limitation does not establish absence of all fusing mechanics. Machine configuration and client selection must be combined: `CanFuse206–228` alone accepts nominal pet count and does **not** validate ownership, locked/XL flags, eligibility or matching variant.

| Machine | Enabled / required count / catalog interval | Received cooldown field | Catalog random outcomes |
| --- | --- | --- | --- |
| RebirthMachine |true /5 /1800s |NextRebirthMachineUse |Neon Overlord50, Neon Soul30, Neon Pyramidium18.3, Neon Dragon0.5, Neon Seeker0.2 |
| CrystalAltar |true /3 /3600s |NextCrystalAltarUse |Crystal Seal60, Grand Topaz33, Crystal Reaper5, Nightseeker2 |
| SkyAltar |**false** /3 /3600s |NextSkyAltarUse |Starry Gale75, Sky Sentinel20, Skyramidium5; retained disabled definition |
| AdminRebirthMachine |no equivalent Enabled flag inspected /4 /300s (`DONATION_INTERVAl`) |NextAdminRebirthMachineUse |Giant Neon Elemental60, Seraphim25, The Eternity10, UwUlord5 |

Numbers above are literal Chance fields displayed by native client, not verified server draws. RebirthMachine fields sum99, whereas Crystal/Admin sum100. An unused required GetRandomWeightedItem reference does not show which server sampler is used; do not silently renormalize99 or invent a missing1% outcome. Special combinations return a one-item Chance100 pool in GetAvailablePets237–244, still not a live guarantee.

Normal/Crystal/Sky eligibility helper136–147 requires catalog Secret rarity, rejects Infinity/Void/AdminAbuse and allows Celestial only when configured (all three saved definitions AllowCelestial=true). Crystal/Sky additionally require manual names. Crystal manual set: Crystal Pyramidium, Crystal Golem, Soul Star, Emerald/Ruby/Sapphire Crystal Dragon. Sky manual set: Cloud Catcher, Sky Chime, Empyrean Bolt, Rainshine. Native client195–208 additionally rejects Locked and XL, duplicate selected IDs, and mixed Shiny/Mythic variants. It rejects equipped pets through PetChoosePrompt callback426–428; exact equipped-team derivation belongs to that prompt dependency. Admin client127–144 instead requires AdminAbuse Secret and rejects Infinity/Celestial/Void plus Locked/XL/duplicate/mixed variant. These differences prevent sharing an overly broad generic fusing allowlist.

Combination matcher185–205 counts **name multiplicity**:5King Doggy→BIG KING DOGGY;5The Overlord→The Duallord; one each Fire/Dark/Earth/Sky/Water Champion→Rainbow Champion; one each Emerald/Ruby/Sapphire Crystal Dragon→Omega Crystal Dragon;3Rainshine→Azure Shard (disabled SkyAltar). Variant map is Normal0/Shiny1/Mythic2/ShinyMythic3 and ignores XL because client rejects XL. No Super field handling is established here; protect valuable variants until exact eligibility is verified.

Product-derived Secret name lists have `PolicySecretsEnforced=true`; client434 and Admin371 reject restricted paid random items when `PolicyInfo.ArePaidRandomItemsRestricted` is true. Treat missing policy data as unavailable, not permissive. Premium cooldown-skip UI calls MarketplaceService:PromptProductPurchase; these are paid actions outside this research and should remain protected in any later plan.

Native conversion confirmation serializes an ordered list of selected **unique pet IDs**, not names or whole profiles: `InvokeServer("UseRebirthMachine", machineName, petIds)` at client742, and `InvokeServer("UseAdminRebirthMachine", petIds)` at Admin627. Returned nil triggers error, nonnil displays received item; clients clear selection afterward. Each machine reads an absolute received next-use timestamp and compares it to native Time.now. A local countdown, nominal DonationInterval or conversion animation cannot prove consumed pet removal, output ownership or server cooldown persistence. Required later verification is exact selected-ID disappearance, identifiable added/output pet and next-use change, with reconciliation on timeout before any retry.

RebirthMachine client1003–1012 creates handlers for all three configurations, binds Overworld/Outer Space/RebirthMachine when enabled, and binds Workspace.SkyAltar only if enabled. Crystal handler is created but no binding is present in this fully read module. Admin imports Activation without an in-frame binding, but the independent follow-up resolved its source consumer: `Client.Activation191–203` binds an Activation-tagged model whose parent.Name is AdminRebirthMachine to `GuiFrame:Open("AdminRebirthMachine")`, then returns. Tag enumeration305–309 excludes TradingPlaza. Read-only saved scene has `Workspace.Worlds.The Overworld.Islands.Floating Island.Island.AdminRebirthMachine.Activation` with Root/Ring/Border children. Actual CollectionService tag membership was not exposed by the inspected properties, so saved object identity plus source mapping does not prove live registration. Crystal consumer binding and live availability remain unavailable. Never travel to a catalog name without an actual observed accessible activation.

Future pet policy must recompute the best feasible owned team after hypothetical removal and output scenarios, preserve equipped/locked/protected/rare/collection/trade commitments, and compare expected marginal **team** value against all consumed pet opportunity costs. No conversion is currently authorized. Use central planner/scheduler ownership with a bounded location lease and zero retries after an uncertain irreversible result.

Batch F saved: complete semantic read of the8 additional native modules listed in the ledger. Server actions, paid purchases and live verification were not performed.

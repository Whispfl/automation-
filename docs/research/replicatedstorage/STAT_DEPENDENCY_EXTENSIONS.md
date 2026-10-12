# Stat dependency extensions: runes, fragments, Supers and guilds

Evidence date: 2026-10-11. Read-only saved workspace, Studio `5528d459-f21f-4304-aa34-0f2deff5a197`, Edit mode. This batch read source and saved documentation only. No game actions, Luau execution, source/object edits, builds/tests or Git synchronization occurred.

**SOURCE_CONFIRMED** means exact saved source control flow or definition. **CLIENT_ESTIMATE** means the native client's derived value; decompiler fidelity and server interpretation still limit it. **HYPOTHESIS** means a proposed planning model. **UNVERIFIED** in this batch is an alias for **UNAVAILABLE**: the required rule/account/live observation is missing, not an accepted contract. Number references below are MCP-returned one-based source lines.

## Exact modules and review depth

Nine additional complete sources were fetched; seven complete filtered executable/data bodies were reviewed. Long executable lines were retained. Bytecode and decompiler comment blocks were excluded from displayed excerpts and never saved as source.

| Exact path | Complete fetched range | Review |
|---|---:|---|
| ReplicatedStorage.Shared.Utils.RuneUtil | 1–74 | Complete body |
| ReplicatedStorage.Shared.Data.Runes | 1–228 | Complete definitions, including all recipes |
| ReplicatedStorage.Shared.Utils.FragmentUtil | 1–83 | Complete body |
| ReplicatedStorage.Shared.Utils.Stats.GuildUtil | 1–437 | Complete body |
| ReplicatedStorage.Shared.Data.Guilds | 1–206 | Complete definitions |
| ReplicatedStorage.Client.Gui.Frames.RuneCrafting | 1–469 | Complete body |
| ReplicatedStorage.Client.Gui.Frames.Buffs | 1–665 | Complete body |
| ReplicatedStorage.Shared.Data.Powerups | 1–974 | Targeted definitions and surrounding postprocessing, especially954–974 |
| ReplicatedStorage.Client.Gui.Frames.Guilds | 1–3044 | Targeted complete functions for season gating, unlock, level display and snapshot refresh |

Existing complete-body review of `Shared.Utils.SuperUtil1–202`, `Shared.Data.Enchants1–42` and other economic sources was reused; no duplicate coverage records were added. Existing targeted Inventory and StatsUtil reviews were extended to the callers below. Full fetch is distinct from a semantic audit of every dependency.

No ModuleScript named `GuildBuffUtil`, `Fragments`, `Supers` or `Super` was found in the complete saved ReplicatedStorage Shared/Client module inventory. The guild helper is `Shared.Utils.Stats.GuildUtil`; fragments are defined in `Shared.Data.Powerups`; Super coefficients are in `Shared.Utils.SuperUtil.Buffs` and Super enchant definitions in `Shared.Data.Enchants`. This finding does not establish what is present server-side.

## Runes: units, recipes and native contracts

SOURCE_CONFIRMED — RuneUtil19 defines active as `account.ActiveRunes[name] ~= nil`. RuneUtil29–33 returns `1 + Runes[name].Tiers[active.Tier].Buff / 100`, delegated through BuffUtil:GetValue. It does not inspect expiry or remaining Amount. RuneUtil12 defines86400 seconds; Inventory4424 describes a24-hour cooldown. The server lifecycle tying cooldown, expiry and depletion together remains UNVERIFIED.

An active record exposes `Tier` and `Amount`. The native Buffs UI608–635 shows Amount as remaining uses; it does not display these runes as an expiry timer. RuneUtil35–50 is a **mutating** consumption helper: subtracts the passed usage amount, removes ActiveRunes[name] at zero or below, returns false if absent. It was read, never executed.

| Family / tier | Buff % | Uses per item | Native craft seconds per item | Recipe consumed for one item |
|---|---:|---:|---:|---|
| Luck I | 20 | 5000 eggs | 45 | Lucky IV×3; Reroll Orb×25; Golden Orb×25 |
| Luck II | 50 | 5000 eggs | 120 | Luck I×1; Lucky V×5; Reroll Orb×50; Power Orb×5 |
| Luck III | 100 | 5000 eggs | 240 | Luck II×1; Lucky VI×3; Reroll Orb×100; Power Orb×15 |
| Secret I | 5 | 5000 eggs | 60 | Mythic IV×3; Super Ticket×10; Rift Shard×1 |
| Secret II | 10 | 5000 eggs | 120 | Secret I×1; Mythic V×5; Super Ticket×20; Rift Shard×2 |
| Secret III | 25 | 5000 eggs | 300 | Secret II×1; Mythic VI×3; Super Ticket×40; Rift Shard×3 |
| Bubbles I | 5 | 1000 clicks | 60 | Speed IV×3; Golden Key×10; Golden Orb×25 |
| Bubbles II | 10 | 1200 clicks | 120 | Bubbles I×1; Speed V×5; Golden Key×25; Golden Orb×50 |
| Bubbles III | 25 | 1500 clicks | 240 | Bubbles II×1; Speed VI×3; Golden Key×50; Golden Orb×100 |

Sources: Data.Runes52–111 Luck,112–150 Secret,151–188 Bubbles. Luck/Secret each define MaxAmount1,000,000 eggs. Bubbles has no MaxAmount field. SummerLuck189–227 retains20/50/100% tiers and5000-use amounts, but **Craftable=false**. Its retained recipes do not permit a crafting recommendation.

RuneUtil60–72 yields0 for Craftable=false, missing recipe or empty Items; otherwise:

`maxCraftable = min_i floor(ItemUtil:GetOwnedAmount(account, ingredient_i) / ingredient_i.Amount)`

This is an ingredient-affordability helper; it neither protects reserves nor checks RuneCraft busy state. Each current recipe was checked for distinct ingredient descriptors; the method itself does not combine duplicate descriptors.

Native RuneCrafting83–106 reads `account.RuneCraft = {Name, Tier, Amount, Start}`; predicted finish is `Start + Recipe.Duration × Amount`, not Duration alone. Buttons148–159 require maxCraftable>0. Requests are `StartRuneCraft(name, tier, count)`: one183, maximum205, chosen count276. Selection371–375 and UI396–425 block selection while RuneCraft exists. The one-item callback180–183 only explicitly checks selection; the chosen-count confirmation does not reread balances. There is no reserve rule or verified completion/grant handler in this module. Craft-skip309 is a paid product path, excluded from autonomous planning. The source binds `workspace.ShadowRealm.RuneCrafting`457–465; this does not establish the interaction distance or current live availability.

Inventory4392–4413 rejects reapplication while the same named ActiveRune exists and checks owned `{Type="Rune",Name,Tier}`. For multiple items,4420 caps selectable count by `min(owned, MaxAmount.Value // tier.Amount)`, or owned if MaxAmount absent. Requests4466/4486 are `UseRune(name,tier,count)`. The native client does not provide a reviewed final acknowledgement here. Count limit and active guard are call-site evidence, not server acceptance proof.

CLIENT_ESTIMATE — consumer semantics differ:

- Bubbles rune multiplies aggregate bubble amount by its1+buff/100 factor (StatsUtil146–147), before the final ceil174.
- Secret rune adds only buff/100 to Secret factor (StatsUtil1759–1760), before global/Dreamer/Secret/guild multipliers1763–1793.
- Luck rune adds buff/100 to primary ordinary Luck accumulator (StatsUtil2422–2424); SummerLuck does likewise only when egg name belongs to Constants.SummerEgg2426–2430.

Thus Luck III does not establish doubled final luck or doubled target odds. If the pre-addition accumulator is A, its local accumulator ratio is `(A+1)/A`; Secret III gives `(S+0.25)/S` before later unchanged factors. These are client factor ratios, not final server probabilities.

HYPOTHESIS — rank crafting against best feasible owned team and alternative uses of every ingredient. Upgrading II to III sacrifices II's remaining future utility plus new ingredients and queue time. Cap realized benefit by actual usable hatches/clicks before depletion/expiry, verified egg eligibility, travel and currency funding. Bubbles I→III increases uses as well as buff; Secret/Luck tiers keep the same5000-use amount. Native Craft All is not an economic policy. No reserve override was implemented.

## Fragments: permanent-looking counts and precise placement

SOURCE_CONFIRMED — FragmentUtil12–20 defines four colors, individual threshold250, total1000. GetFragmentValues28–35 reads `account.Fragments[color] or0` and sums; it does not clamp. GetFragmentValue75 returns `count × Scalar /100`.

| Color | Scalar per recorded use | At250 recorded uses | Native consumer |
|---|---:|---:|---|
| Green | 3% =0.03 | 7.5 | Adds to secondary ordinary Luck accumulator B; StatsUtil2432–2433 |
| Blue | 0.75% =0.0075 | 1.875 | Adds to HatchSpeed before guild multiplier; StatsUtil544–559 |
| Purple | 0.08% =0.0008 | 0.2 | Adds to Secret factor before later multipliers; StatsUtil1761–1793 |
| Rainbow | 0.08% =0.0008 | 0.2 | Adds to Infinity factor before player/global events; StatsUtil1879–1883 |

Data.Powerups954–957 registers the four as Type="Fragment", with the same per-use percentages and250-max descriptions; FragmentUtil77–81 validates their registration. Inventory4304–4317 checks loaded LocalData and owned Powerup amount>0, then4387–4388 sends `UseFragment(color)`, stripping " Fragment" from the selected key. That callback does **not** locally check recorded color count<250, send quantity, or prove resulting consumption. Server cap, spending and permanence rules remain UNVERIFIED. Saved definitions suggest accumulated persistent progress; they do not prove no future season reset or account rollback.

AllFragmentsCompleted59–65 requires **every color count>=250**, not merely total>=1000. StatsUtil2475–2476 then multiplies final ordinary Luck by1.25. Buffs UI327–345 instead labels Max from total>=1000. These agree for valid per-color-capped data; a malformed/uncapped uneven vector can disagree. Use the helper's per-color predicate in a model.

Material fidelity boundary: secondary Luck B initializes0 (StatsUtil2388), receives Infinity/Double Luck/global additions2398–2405, fragments2433 and Super Luck2447, and multiplies primary A **only when B>1**2451–2453. Do not replace the returned source with `A×(1+GreenBonus)`. With all other B additions zero,33 Green uses givesB0.99 and34 givesB1.02: the literal returned-source behavior has a threshold. Owner comparison to the native display is required before accepting this as live behavior.

HYPOTHESIS — let H be pre-guild HatchSpeed and g the unchanged guild factor. Blue's local rate multiplier for one additional count is `(H+0.0075)/H`; native hatch duration is `4.5/(g*H)` before and `4.5/[g*(H+0.0075)]` after (StatsUtil549–569). The unchanged g cancels in the ratio. Actual throughput also includes client pacing, affordability, storage and overhead. Purple/Rainbow local factor ratios are `(S+0.0008)/S` and `(I+0.0008)/I`. Final odds require the pool transform and unavailable server draw. Completing the last missing color may unlock1.25 ordinary Luck in addition to its own increment. Preserve fragment reserves and account facts; descriptions alone do not authorize consuming them.

## Supers: existing complete review, explicit units and limits

SOURCE_CONFIRMED — SuperUtil23–33 resolves active-team IDs through PetInventory and includes pets with Super=true. Enchant counts98–109 count every matching entry across those pets; no general deduplication is applied here. These are team effects, not automatic value attached to every owned Super.

| Effect | Base / Plus coefficient | Return units |
|---|---:|---|
| Luck | 100 /200% | count×1 + plusCount×2 |
| HatchSpeed | 75 /100% | count×0.75 + plusCount×1 |
| Bubble | 150 /250% | count×1.5 + plusCount×2.5 |
| Shiny | 10 /15% | count×0.10 + plusCount×0.15 |
| Mythic | 10 /15% | count×0.10 + plusCount×0.15 |
| Infinity | 7.5 /15% | count×0.075 + plusCount×0.15 |
| Duplication | 2.5 /10% | count×2.5 + plusCount×10, **percentage units** |

Source SuperUtil11 and118,155,164,173,182,191,200; definitions Data.Enchants26–41. Consumer references: HatchSpeed StatsUtil546–547; ordinary Luck2446–2453; Shiny1188; Mythic1654; Infinity1863–1864; Bubble PetUtil175–185. Different consumers add to different existing accumulators; the table is not a uniform final multiplicative bonus.

Burst134–146 checks whether `floor(Hatches/N) < floor((Hatches+batchCount)/N)`, N100 Base or75 Plus. If at least one corresponding enchant exists, it adds10 or15; the helper does not multiply that amount by enchant count or number of crossed boundaries. Literal grep for GetBurstBoost and GetDuplicationChance found definitions only in accessible scripts. Applying Burst to an entire batch, a single egg, final odds, or duplication reward count remains UNVERIFIED.

Constants52–53 baseline SuperChance0.1 and MaxSupers3; StatsUtil429–439 adds the reviewed milestone bonus to equipped capacity. GetSuperChance1805–1817 multiplies baseline by guild SuperLegendaryLuck; current guild catalog defines no such perk, so GuildUtil returns1 for it. Percent0.1 is a client chance unit, not proof of which rarity/variant draw is eligible.

Fidelity: SuperUtil53–54 checks the **success flag** of pcall(IsEdit), not IsEdit's returned boolean. If its cache branch is enabled,45–49/81–88 use module-wide frame cache without account identity. Hypothetical candidate-team evaluations must not rely on a possibly stale shared cache. No cache correction or alternative automation was implemented. Readable pure formulas still require owner comparison before live use.

## Guild stats, progression and time

SOURCE_CONFIRMED — GuildUtil425–435 defaults all five perks to1, then for each known stat takes the **maximum** of1+each unlocked percentage. It does not add percentages from successive levels. Level input is floored and clamped0–24; no guild uses level0 and all factors1.

Data.Guilds8–31 alternates one stat per level:

| Levels reached | Bubbles / Luck / HatchSpeed percentages unlocked successively | Secret percentage at fourth level |
|---|---:|---:|
| 1–4 | 2.5 | 2 |
| 5–8 | 5 | 4 |
| 9–12 | 7.5 | 6 |
| 13–16 | 10 | 8 |
| 17–20 | 15 | 10 |
| 21–24 | 20 | 12.5 |

Each stat changes at its own level, not simultaneously at the row's beginning. At level24: Bubbles/Luck/HatchSpeed1.2, SecretLuck1.125, SuperLegendaryLuck1. GetLevel383–391 returns1 until the next XP threshold, then the highest threshold reached; level24 threshold395000 XP. GetLevelProgress400–412 uses XP minus current threshold divided by next-minus-current threshold, clamped0–1; at max, Current/Required0, IsMaxtrue, Ratio1. No verified formula connecting guild quest points, hatch/bubble actions and guild XP was established here.

Native StatsUtil checks Guilds.Enabled and account.Guild.Id; if present it uses Guild.Level. Multipliers apply to Bubbles163–173, HatchSpeed549–559, Secret1783–1793, Super1807–1817, ordinary Luck2464–2474 and the separate GetSecretLuckMultiplier2512–2522. Do not multiply both Secret helper outputs together without a verified consumer; each can include the guild factor. GetInfinityLuck1819–1883 has no guild multiplier in its returned body.

Guilds UI2798–2856 unlocks its button at account.Stats.Bubbles>=1,000,000 (cumulative statistic, not bag.Amount). Data.Guilds206 also defines Enabled=true, member limit10, names3–20 characters, ActionCooldown0.75 seconds and InviteDuration120 seconds. These catalog/UI fields do not prove server membership acceptance, invitation rules or XP earning.

Time: Guilds206 defines seasonId2, UTC start2026-10-09, Duration2592000 (30 days), WeekDuration518400 (**6 days**). GuildUtil208–219 uses floored epoch time, start<=time<end for Active, and clamps week index1–5 even outside the active window. Calculated saved definition window is2026-10-09 through2026-11-08 UTC, end-exclusive. It is a catalog/client time window, not live active-event proof. Native UI217–246 additionally checks snapshot seasonId matches and hides tasks/rewards when inactive/mismatched.

Complete GuildUtil review also inspected deterministic quest/reward construction: quests254–257 carry Id, Task, Tiers, Points, Icon; the quest Task.Amount is the largest tier requirement. GetCompletedTier298–305 returns last attained tier. Quest seeds149 and reward seed348 are deterministic from season/week/tier; weightedItem165–177 normalizes **Weight**, not Chance. Do not treat an already generated known reward as a new probabilistic payoff.

**Source fidelity limit:** buildRewards339–350 loops through every eligible reward band and has no break; later matching Bands overwrite earlier entries. The separate getBand184–188 chooses the first matching band, but buildRewards does not call it. The saved source therefore cannot justify a confident first-band reward pool without native output/owner comparison. GetRewards364–374 caches per season and track.

HYPOTHESIS — value a level improvement by new/old perk factor, not cumulative catalog sum. A15%→20% guild stat upgrade changes that local factor by1.20/1.15≈1.04348, about4.35%, not another20%. Shared guild contributions, season expiry and attainable XP may dominate time to benefit. Native guild-management actions involve other people and were neither requested nor performed by this batch.

## Remaining evidence needed

1. Authoritative rune expiry/cooldown versus depleted-use semantics, batch consumption, server craft completion/refund handling and live recipe eligibility.
2. Fragment server cap, atomic item/count deltas, reset/permanence semantics and owner comparison of the Green Luck threshold.
3. Super variant eligibility/final draw, Burst consumer granularity, duplication application/cap, cache behavior in live client, and account-specific best team.
4. Guild XP earning/contribution rules, live membership/account level/snapshot, server season timing, and generated rewards confirming band semantics.
5. Final hatch probabilities after server-only transformations and actual earning/overhead measurements. No exact numeric ROI recommendation for the owner's account can be justified from catalogs alone.

All suggested ROI comparisons retain protected currency/item reserves and best-feasible-owned-team baselines from ECONOMY_AND_ROI.md. This document supplies knowledge and conditional mathematics; it implements no spending policy or reserve override.


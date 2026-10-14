# Phase 5 owner RemoteSpy capture delta | 2026-10-14

Source: owner-supplied 21-entry Word workbook `BGSI_OVERWORLD_CAPTURE_LIST_UPDATED_V2.docx`, with the corrected `MakePetShiny` capture, and the owner's verbatim transcribed requests in conversation. This file records **outgoing request evidence only** unless a prior independent acceptance document explicitly covers a result. No code executed, account state inspected, gameplay replayed, spending approved, or reward/grant verified.

## Notation

- `E(command, args...)` = `ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent:FireServer(command, args...)`.
- `F(command, args...)` = `ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction:InvokeServer(command, args...)`.
- `D` = dedicated native direct remote, not the Shared Framework dispatch.
- `<PET_ID>` = an actual observed UUID, redacted here because it is an example account/item identifier, **not** a reusable constant.
- Reported ranges are owner statements, not exhaustive sampled requests. An outgoing call does not establish the server's accepted return, debit or grant.

## Observed command inventory

| Workbook entry | Observed request or state | Evidence scope / unresolved boundary |
|---|---|---|
| 1 ClaimPlaytime | `F("ClaimPlaytime", 1)` | Owner reports indices 1 through 9; earlier request observations include 2. Return descriptor and exact granted reward are **NOT_OBSERVED**. Preserve Playtime sparse-map/cycle semantics. |
| 2 "DailyRewardClaimStars" | **Actual request** `E("DailyRewardsBuyItem", 6)` | Owner reports item indices 1 through 28. **This is a Stars shop purchase, not evidence of a free daily Stars-claim command**. Debit/ownership unverified. Do not rename to `DailyRewardClaimStars`. |
| 3 ClaimChest | `E("ClaimChest", "Giant Chest")` | Exact named chest example; eligibility, physical trigger, cooldown transition and reward receipt unverified. |
| 4 ClaimFreeWheelSpin | `E("ClaimFreeWheelSpin")` | Known zero-payload free-ticket request, no newly required signature. Existing `668d0af6f157` offline candidate; owner-live OC authorization and paired timer/ticket receipt still pending. |
| 5 ClaimPrize | `E("ClaimPrize", 116)` | Example prize ID, no claim/grant or requirement result observed. |
| 6 StartGenieQuest | `E("StartGenieQuest", 1)` | Owner reports option indices 1 through 3; completion/payout not observed. Starting a quest is not claiming a reward. |
| 7 EquipBestPets | `E("EquipBestPets", "Power")` | Owner observed a **Power string argument**; older native source inventories describe `EquipBestPets()` without payload. Preserve both as version/feature variants and investigate relevant client caller without assuming all game builds accept either. |
| 8 EquipPet | `E("EquipPet", <PET_ID>)` | Account-owned example UUID redacted. Earlier scoped owner-live equip evidence exists; new sample is request-only. |
| 9 UnequipAllPets | `E("UnequipAllPets")` | Newly observed zero-payload request; whole-team effects and protected state not observed. No automatic use approval. |
| 10 UnequipPet | `E("UnequipPet", <PET_ID>)` | Existing individual unequip supported in scoped past acceptance; sample is request-only. |
| 11 EquipTeam | **NOT_OBSERVED** | Owner reports native access/Mastery not unlocked. Do not force unlock or invent an actual local test. Retained source `EquipTeam(index)` is not this owner's new capture. |
| 12 CollectPickup | Existing dedicated pickup mechanism `D(CollectPickup, registryKey)` | Owner says existing collector works. Preserve prior scoped evidence, no new signature or re-test required. |
| 13 Teleport | `E("Teleport", "Workspace.Worlds.The Overworld.Islands.Outer Space.Island.Portal.Spawn")` | One full path example. Existing native/owner accepted travel scope remains limited to tested destinations. |
| 14 UpgradeMastery | `E("UpgradeMastery", "Buffs")`; `E("UpgradeMastery", "Pets")`; `E("UpgradeMastery", "Shops")` | Actual command-family arguments observed. `"Rifts"` was **guessed by the owner, NOT_OBSERVED**. No accepted level/debit, tier eligibility or purchase approval from these requests. |
| 15 BuyShopItem | `E("BuyShopItem", "alien-shop", 1, false)` | Shop ID, item index and boolean example only; no generic shop ID assumptions, price/ownership receipt or spend authority. |
| 16 GumShopPurchase | `E("GumShopPurchase", "Contrast")` | Observed item-name example, no ownership/debit receipt. |
| 17 HatchEgg | `E("HatchEgg", "Common Egg", 3)` | Newly observed hatch count=3 **request only**. Earlier one-count Common Egg owner-live acceptance must not be broadened to 3 from request alone. |
| 18 CraftPotion | `E("CraftPotion", "Lucky", 2, false)` | Potion name/tier/boolean example. Resource debit/grant unknown; no automatic crafting permission. |
| 19 RerollEnchants | `F("RerollEnchants", <PET_ID>, "Gems")` | Whole-pet Gems reroll; owner sample omits optional/unknown locked-slot parameter. Return/new ID/enchant grant and Gems debit not observed. |
| 19 RerollEnchant | `E("RerollEnchant", <PET_ID>, 1)` | Separate, orb-based single-slot reroll. Consumption and changed enchant not observed. |
| 20 MakePetShiny | `E("MakePetShiny", <PET_ID>, 1)` | **Corrected owner capture** replaces earlier erroneously duplicated `RerollEnchant`. Ingredient debit/Shiny pet grant unknown. |
| 21 UsePotion | `E("UsePotion", "Speed", 4)` | Exact potion name and number observed; stock debit/effect not verified. |

## Reconciliation and milestone boundaries

1. **Existing results to preserve:** Common Egg count=1 owner acceptance; stationary Coins/Gems pickup; scoped travel and owned-team equipment; read-only Mastery/rewards reports. Do not expand them based only on new outgoing request samples.
2. **Do not conflate:** `DailyRewardsBuyItem` with free daily Stars collection; `StartGenieQuest` with completion; `ClaimFreeWheelSpin` with ticket-consuming `WheelSpin`; `RerollEnchant` with `RerollEnchants`; `EquipBestPets("Power")` with previous no-argument native shape.
3. **Unavailable or speculative:** `EquipTeam` new owner capture and `UpgradeMastery("Rifts")` are not observed. No universal acceptance of hatch count=3, arbitrary shop IDs, purchased Mastery levels, or all indices is established.
4. **Still missing for Playtime-001:** actual `InvokeServer` return (mark `NOT_OBSERVED` when inaccessible), claimed-index change, actual matching received inventory/currency/pet delta, interference/automatic calls and clock/cycle association.
5. **Wheel milestone separate:** preflight + at most one actual claim is `READY_FOR_SEPARATE_AUTHORIZATION` only. No capture list or this document authorizes its live execution. Follow `docs/PHASE5-FREE-WHEEL-TICKET.md`.
6. **Paid/consumptive effects:** Mastery upgrades, Stars purchases, shops, hatches, crafting, enchanting, shiny, potions and spin consumption remain OFF without distinct bounded owner authority and exact before/after receipts.

## Next autonomous work for Codex (offline only)

- Reconcile each command above against native source and the full roadmap; update evidence statuses `OWNER_REQUEST_OBSERVED` / `PARTIALLY_VERIFIED` without promoting to `OWNER_LIVE_VERIFIED`.
- Inspect existing Phase 5 `GameKnowledge`, `RewardPolicy`, `RewardsManager`, `OCBrain`, `TaskScheduler`, receipt barriers and `GameMechanics` before any change. The newest approved free-wheel candidate already passed its offline tests.
- Advance the smallest free-reward receipt/eligibility work that is possible **without** inventing Playtime return shape or acting on a game account. Prefer pure, additive, disabled-by-default accounting + tests; if live return/grant evidence is essential, document that blocker and do not fabricate.
- Keep ALL gameplay actions OFF, no new permissions/loaders for live claims, no looping retries or silent fallback from missing state. Run official compile/build, baseline and relevant regression suites before any release. Preserve immutable pins and prior source/evidence.
- Summarize changes, exact unresolved Playtime receipt fields, updated priority list, exact validated artifact/commit when available, and the separate owner approval gate for future live wheel testing.

Reference: `docs/OWNER_REMOTESPY_CAPTURE_ROADMAP.md`, `docs/PHASE5-REWARDS-READ-ONLY.md`, `docs/PHASE5-FREE-WHEEL-TICKET.md`, `docs/PHASE5-ENTRY-PLAN.md`.

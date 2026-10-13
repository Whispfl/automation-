# Phase 4 native auto-delete audit — account state unresolved

Date: 2026-10-13. Outcome: **SOURCE-UNRESOLVED for the owner's actual live value; no production correction or new runtime release.** The inspected native client contract is understood. The supplied log does not capture the field needed to determine which branch blocked this account. No supported alternative representation, lost field or missing client default was found. No source-supported owner-readiness or unsafe paid-dispatch defect was demonstrated.

## Frozen release and authority

Runtime commit `55bf4cf437cccd826180519c482bdc6edbbbb51b`, build `f4e10f71c317`, immutable tag `phase4-hatch-f4e10f71c317` remain the working baseline. [The existing pinned bundle](https://raw.githubusercontent.com/Whispfl/automation-/phase4-hatch-f4e10f71c317/dist/OC.lua) and its zero-spend preflight configuration remain unchanged. No replacement bundle or tag is created by this audit.

Before implementation decisions and test edits, the latest available [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363), and [Phase 9/testing](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358) pages and applicable owner notes were reconfirmed. Their returned last-edited timestamps were respectively `2026-10-12T19:05:43.587Z`, `19:06:12.841Z`, `19:05:47.249Z`, and `19:05:51.517Z`. Phase gates, native evidence precedence, one Brain/scheduler, and preservation still apply. This task does not implement Mastery or Phase 9.

The completed libraries were reused, without a new full research pass or changes to their contents:

- [Native eggs and pets](research/replicatedstorage/EGGS_AND_PETS.md): client eligibility, catalog/pool separation, receipt verification and unavailable authoritative hatch handling.
- [Economy source ledger](research/replicatedstorage/ECONOMY_SOURCE_LEDGER.md), especially its final limitations: no authoritative server hatch/variants/auto-delete handler was accessed.
- [Navigation action contracts](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md) and [local architecture evidence](research/replicatedstorage/LOCAL_ARCHITECTURE_EVIDENCE.md): preserve existing interfaces, identity and ownership; call-site evidence does not prove server acceptance.
- [Wiki knowledge gaps](research/wiki/KNOWLEDGE_GAPS.md), [native/wiki conflicts](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), and the existing probability reports: historical descriptions cannot establish current effective settings or private server deletion semantics.
- [Test B native evidence](PHASE4-TEST-B-NATIVE-EVIDENCE.md), [registration observation](PHASE4-REGISTRATION-OBSERVATION-EVIDENCE.md), [zero-receiver evidence](PHASE4-ZERO-RECEIVER-EVIDENCE.md), and [approved classification delivery](PHASE4-RECEIVER-CLASSIFICATION-DELIVERY.md): keep the successful receiver repair separate from this account-setting blocker.

## Exact owner-live evidence

Input attachment: `C:\Users\rmger\.codex\attachments\5e1db39b-8e9b-4275-890d-fc4adc8bbfd2\Pasted text.txt`, supplied as the latest `Pasted markdown(20261013-050253).md` log. Attachment SHA256: `10d56733db9b6527fe7a89c8ee01b8f1d752856784faa02f3fbb396c8bf3e827`. References below are one-based physical lines in that attachment, including timestamp lines.

- Line 156 reports `PHYSICAL_ARRIVAL_OBSERVED`; line 160 reports stable arrival at `3.54/6.5` studs for one second. Direct and native travel attempts are zero because the character was already near the selected original. This is not a movement regression.
- Line 162 is the earlier preflight while the registration observation window was still open. It is not the final blocker.
- Line 171, following the `01:01:21` timestamp, reports `CURRENT_EXACT_REGISTRATION_OBSERVED` and `OPENED_NEAREST`, native price `10 Coins`, balance `7267071`, storage `1926/1000000`, digital storage true, `EggsOpened=2`, and absent `NextEggOpenAt`.
- The completed observation reports 86 updates entered/completed, five candidate receivers, one qualifying receiver, selected membership trusted, and the window complete. Accepted session receiver `D0007` contains the exact selected original `I0040`, with loaded parent equality to folder `I0006`. Those IDs identify this session only.
- The 136 complete originals comprise 55 catalog entries, 21 sentinels and 60 noncatalog models. Noncatalog queue contents neither invalidate the valid receiver nor independently become interactive or paid hatch targets.
- The final reason is exactly `Native auto-delete settings unknown or active; OC does not modify them`. Hatch requests and requested spending are zero. Equipment and other action permissions remain off.

The owner-live receiver and selected interaction milestone is preserved. Auto-delete is an independent subsequent guard. The log contains no raw `AutoDelete` value or type, so it cannot show whether that field was absent, malformed, or a nonempty native settings map. Cooldown, presentation and final consistency guards later in the first-blocker sequence are not established by this log.

## Native source contract and provenance

Targeted original source was read through Studio MCP, without execution, requiring modules, settings clicks, play-state changes, remote invocations or object changes. Connected saved Studio ID was `2fa4fc98-1910-41a2-8ad7-deb5bc3f9326`, named `place 85896571713843 Bubble Gum Simulator INFINITY.rbxl`. That name is not independent proof of the active runtime PlaceId or the owner's current profile. Line references refer to the source returned by `script_read` in this saved workspace; decompiled variable names are not public API names.

| Original path | Returned source lines | Evidence |
|---|---|---|
| `game.ReplicatedStorage.Client.Framework.Services.LocalData` | 11; `IsReady` 14–23; `Get` 36–43 | Profile starts nil; ready means the received profile exists; Get returns that profile directly. |
| Same LocalData | `PlayerDataLoaded` 107–120; `PlayerDataChanged` 132–153, assignment 142 | Received payload becomes the profile; subsequent field values replace their received fields. No AutoDelete-specific default or coercion is inserted here. |
| `game.ReplicatedStorage.Client.Gui.LootPoolViewer` | 127, 141–154; toggle 222–230; remote 246; icon 648 | Reads `profile.AutoDelete[petName]`; enables with true, disables by removing the key. Tooltip uses truthiness while the icon also uses non-nil presence. |
| `game.ReplicatedStorage.Client.Gui.Utils.LootPoolPage` | `setAutoDelete` 304–343, especially 318–327 and 340; tooltip 103–120; icons 246/261 | A second native UI uses the same root map and true/nil toggle. No nested variant record is written. |
| `game.ReplicatedStorage.Client.Gui.HUD` | 2713–2724 | Forwards a received `HatchEgg` payload to the native effect. This is not a deletion-decision implementation. |
| `game.ReplicatedStorage.Client.Effects.HatchEgg` | `createResultFrame` 850–871, especially 864 and 866–868 | Displays the received `Deleted` field and separately displays variant flags. Variant result fields do not establish a variant settings schema. |
| `game.ReplicatedStorage.Shared.Types` | 1–7 | Returned source contains no recovered AutoDelete schema. |
| `game.ReplicatedStorage.Shared.Utils.Stats.StatsUtil` | `GetMaxEggHatches` 571–612; `HasDigitalStorage` 615–622; storage 624–682 | Native helpers directly read PermanentBuffs, MasteryUpgrades and Passes; missing prerequisites throw rather than producing valid capacity. This targeted read checked partial-profile mock fidelity, not a new full research pass. |
| `game.ServerScriptService` | Read-only hierarchy observation | Saved inspection returned zero children; the server deletion and SetAutoDelete handlers are unavailable. This does not imply the live server has no such code. |

The essential native setter evidence in `LootPoolPage` is:

```luau
local v12 = u10.AutoDelete[Item_upv_1.Name] == nil -- 318
-- 322–327: v12 -> true; otherwise nil; assign AutoDelete_1[Name_1]
Remote_upv_1:FireServer("SetAutoDelete", Item_upv_1.Name, v12) -- 340
```

This supports a **client settings map keyed by pet name**: true means selected for auto-delete; an absent key means that pet is not selected. An empty ready map has no client-selected rules. A nonempty map of pet-name keys with true values represents selected client rules. These conclusions do not certify server acknowledgement or future pet deletion outcomes.

The native UI changes the local map before sending the settings request. A locally observed preference may therefore precede server acceptance. No read-only server acknowledgement accessor, alternative authoritative settings store, rarity-keyed representation, nested Shiny/Mythic/XL/Super schema, or safe meaning for an entirely absent field was found in the accessible sources and existing ledgers.

`AutoDelete[name]=false` is unsupported by both native toggle writers, and non-nil icon selection conflicts with the tooltip's falsy interpretation. Nested tables, including `{Shiny=false}`, are also unsupported here and remain truthy/present in those native consumers. They must not be treated as confirmed disabled. The current nonempty-map veto safely blocks such records without proving they are genuine native active rules.

## Existing OC path and the unresolved branch

The frozen `GameKnowledge:PetContext` contains:

```luau
context.AutoDeleteKnown = type(profile.AutoDelete) == "table"
context.AutoDeleteActive = context.AutoDeleteKnown and next(profile.AutoDelete) ~= nil
```

Those legacy fields express the current guard's risk predicate, not a complete native certainty enum. A malformed nonempty map can have `AutoDeleteActive=true` in OC without proving a valid native rule. The merged message deliberately reports the disjunction. Reaching it proves only:

```text
type(detachedProfile.AutoDelete) ~= "table"
OR next(detachedProfile.AutoDelete) ~= nil
```

It does **not** prove the owner's native preference is active. It also does not prove a missing-field initialization error. All six possibilities in the owner's directive were considered:

| Possibility | Finding |
|---|---|
| Missing field | Consistent with the message; actual live type was not logged. No native evidence permits treating absence as disabled. |
| Unsupported encoding | Consistent with the message; no supported nonempty disabled encoding was found. |
| Genuinely active map | Consistent with the message; source supports pet-name/true entries, but the owner's entries were not observed. |
| Disabled state stored elsewhere | No alternate authoritative source was found. OC's own auto-delete flag is independent. |
| Timing, projection or synchronization defect | No demonstrated OC defect. Native data is asynchronous and UI changes are optimistic, so timing is not ruled out retrospectively. |
| Another supported state | No additional safe representation was discovered. |

The existing read/freshness path was traced, rather than changing this predicate:

- `AccountStateReader:_dependency` 117–120 reads the already-loaded dependency cache; it does not load modules. `GetLiveProfile` 479–486 checks native IsReady/Get and returns the received table without projecting or defaulting AutoDelete.
- `GameKnowledge:PetContext` 465–484 requires a ready snapshot and current raw profile, recursively detaches that whole profile, retains it as `AccountFacts`, and supplies separate detached copies to native statistics helpers. AutoDelete is neither dropped nor overwritten by that projection.
- `PetPolicy` 449–450 and `OCBrain` 122–124 veto unknown/nonempty settings. No frozen Brain or capacity policy change is necessary or made.
- `PetManager:Fresh` 65–84 rebuilds account context. `Analyze` 214 onward can retain the expensive planning report for the configured analysis interval, but always obtains fresh context; read-only preflight receives that fresh context.
- `ReportHatchPreflight` 305 uses the same context veto, and 312–315 invalidates a would-be ready result if the current full profile/account/character no longer matches.
- Future paid preparation calls Fresh at 502 and again at 647 following yielding native work. Full account/profile/config equality at 688–693 and again at 716–719 after final exact interaction/arrival observations prevents a captured disabled map from surviving changes into dispatch. Existing authorization and spending guards remain additional requirements.

No demonstrated mapping, defaulting, data-loss or stale-dispatch defect justifies a runtime correction. A new classifier could name the branches more precisely, but it would not supply the absent live value or clear the current blocker safely. Publishing that alone would be the diagnostic-only release the owner explicitly prohibited.

## Decision and preserved invariants

Use the directive's **Case C stop condition for the unobserved account value**, without claiming the actual field is missing. Leave the guard, production source, bundles and loaders unchanged. Case B cannot be selected without observing genuinely active rules. No protected-method proposal is necessary because no protected method is modified.

Before and after this audit:

- Unknown, malformed and nonempty maps block; a ready empty client map may clear only this individual guard.
- Settings are never cleared, disabled or reinterpreted by OC. No native settings, hatch, inventory, deletion or equipment requests were executed during this work.
- Exact receiver/loaded Instance identity, independent interaction eligibility, opened nearest rules across all names, native visual prerequisite, independent pricing and storage remain unchanged.
- Every movement method, geometry, CFrame assignment, travel lease, Brain, scheduler and stable-arrival rule remains unchanged.
- AUTO_HATCH, AUTO_EQUIP, OC auto-delete, hatch-once and owner allowance remain false; authorized account and all hatch spending allowances remain zero in the unchanged safe preflight example.
- Later read-only guards must still pass. No paid Test B permission, complete readiness, live hatch acceptance or Phase 4 completion is claimed.

## Offline fixtures and verification

The 649-case frozen baseline was run successfully before the added fixtures. New tests are confined to `tests/phase4-test-b-interaction.luau`; existing assertions are retained. They exercise the real OC methods against isolated mocks, not a separate invented classifier.

Added coverage includes detached field preservation without inserting defaults; missing/scalar/flat-false/nested-false/nested-true/nested-empty/nested-invalid/active states; accepted mixed-136 receiver preflight; policy/dispatch vetoes; active → empty → active reevaluation; readiness/profile disappearance and recovery; empty/partial received profiles; actual AccountStateReader behavior when native readiness, payload or service disappears; repeated unknown states over 600 simulated seconds; profile changes after capture; changes during native idle checks; changes during first/final native helper calls; and changes after final exact range verification. Existing tests retain account/character switching, exact identity, decorative exclusion, all-name nearest, pricing, capacity, authorization and zero-action protections. Unsupported alternate-source/conflicting-source fixtures are not invented when no such native source was discovered.

One initial partial-profile assertion failed because the generic mocks returned valid native capacity for a literal profile missing Passes/PermanentBuffs/MasteryUpgrades. The inspected StatsUtil source would throw for those inputs. Only this new fixture's helper mocks were corrected to enforce those native prerequisites; its BLOCKED, WAIT, zero-action and immutability assertions were not weakened. The unchanged native adapter converts the helper failures to unknown MaxHatches/DigitalStorage and blocks.

A separate synthetic reporting limitation remains: when mocks supply otherwise valid capacity outputs while the active team is unavailable, preflight can report READY although PetContext.Inventory is nil. Paid policy still returns WAIT with zero requests. This observation is not a demonstrated state in the owner log, does not explain its auto-delete blocker, and was not fixed by changing expectations or runtime logic. It is recorded in `.test-output/autodelete-synthetic-reporting-limitation.txt` and here for later focused review; complete account/team facts remain necessary for the future paid path. No live-readiness claim is made from synthetic helpers or an empty map alone.

Test code intentionally changes **mock** profiles to simulate native updates and races. Those fixture mutations are not native settings changes. Blocked paths assert no mock hatch/spending/equipment/travel commands and no consumed allowance. Positive empty-map preflights assert allowance remains off. Offline assertions do not prove the owner's current field or live server outcomes.

Verification results:

- `node scripts/test.mjs`: official Luau compilation succeeded; **661 main-suite cases**, including **46 Test B interaction cases**, passed after the **12 added tests**. Distribution freshness is checked by the suite against unchanged deterministic production inputs.
- The approved queue cases and **67 identity cases** pass. Mixed 136/135 queues remain valid where justified, and noncatalog contents are not automatically paid or privately registered targets.
- **13 prior membership checks**, **18 exact approved classification checks**, and **seven receiver/price/paid-guard preservation areas** pass.
- Original **ten historical Test A hashes** verify; nine current checks are unchanged and the one prior approved sparse-array membership difference remains separately recorded. No historical manifest or approved difference was rewritten.
- `node scripts/build.mjs` reproduced the existing `f4e10f71c317` bundle and example pins, without any byte changes. Bundle SHA256 remains `1ac819487fd763554caf659a3d299b8cfe83b7629ca98f6739c2519cacbdd1b4`.
- **161 frozen files** compare byte-identical against commit `55bf4cf`, including every production source, bundle, loader, script, approval record and the **104 completed research files**. The research files also compare unchanged against the earlier recovery snapshot.
- The owner's facts-only snippet below separately passed official Luau compilation and **nine offline observation cases**, including scalar false, absent getter/profile, empty map, active map and unsupported mixed values. These are auxiliary checks, not added to the 661 main count.
- Public content and tag verification for the documentation/tests-only handoff is recorded in the local public audit report. Its verifier retains existing raw-byte/historical-pin checks while explicitly distinguishing the new audit commit from the preserved runtime commit; publication of this audit does not create a new runtime pin.

Local outputs: `.test-output/phase4-autodelete-baseline-tests.log`, `.test-output/phase4-autodelete-complete-tests.log`, and the preservation/public audit reports. Tool downloads and output logs remain ignored, rather than published as third-party source extracts.

## One essential owner observation, when awake

The missing fact is the **current received AutoDelete field**, not another travel test. With the existing zero-spend OC instance already running, this optional facts-only snippet reads its existing reader and prints one bounded line. It does not reload OC, require native modules, change configuration, click UI, mutate a profile or send a remote. Run it in the owner's existing client environment, never through Studio MCP.

```luau
local oc = type(shared) == "table" and shared.__OC_PHASE1_INSTANCE
local reader = oc and oc.Reader
local ok, profile = false, nil
if reader and type(reader.GetLiveProfile) == "function" then
    ok, profile = pcall(reader.GetLiveProfile, reader)
end
local value
if ok and type(profile) == "table" then value = rawget(profile, "AutoDelete") end
local entries, enabled, falsy, nested, other, nonStringKeys = 0, 0, 0, 0, 0, 0
if type(value) == "table" then
    for key, item in pairs(value) do
        entries += 1
        if type(key) ~= "string" then nonStringKeys += 1 end
        if item == true then enabled += 1
        elseif item == false then falsy += 1
        elseif type(item) == "table" then nested += 1
        else other += 1 end
    end
end
print(string.format(
    "[OC][AUTO_DELETE_FIELD] getter_ok=%s; profile_available=%s; type=%s; entries=%d; true_values=%d; false_values=%d; nested_values=%d; other_values=%d; nonstring_keys=%d; observation_only=true",
    tostring(ok), tostring(ok and type(profile) == "table"), type(value),
    entries, enabled, falsy, nested, other, nonStringKeys))
```

This reports no account ID, inventory, pet names or secrets. Missing reader/profile is reported as unavailable; scalar false remains type boolean, not silently converted to nil. The output is a current client field observation, not proof of the value at 01:01:21, server acknowledgement, or hatch readiness. A fresh supported empty map, if observed, still requires every remaining independent preflight guard. Unsupported/missing contents stay blocked. If proper active rules are observed, only the owner may later decide whether to change personal game settings.

The evidence and test additions are the only proposed publication to the development branch; the runtime commit, immutable tag, bundle and safe loader remain `55bf4cf` / `f4e10f71c317`. No new runtime build is published because no correction to the owner's blocker is established. Owner live hatch acceptance remains pending.

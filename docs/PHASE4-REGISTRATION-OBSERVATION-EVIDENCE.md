# Phase 4 native registration observation follow-up

Focused source investigation, October 12, 2026. The owner-approved Test A remains build `0d5caa499c8c`, commit `25890f224f0448f148d009e65514c129aeb4f59c`, tag `phase4-travel-0d5caa499c8c`. The reported Test B preflight used build `59c475d125c2`, commit `358bd6b22a2158ad4be14a7a9adc1561566697b2`, tag `phase4-hatch-59c475d125c2`. Neither existing pin is replaced. The previously withdrawn failed movement log and the `79273e3c1cc9` standing changes are not the movement baseline.

The owner's current evidence establishes correct physical selection and stable arrival, with two physical Common Egg originals, zero direct attempts because the character was already 6.21 studs from the retained Root, zero hatch requests and zero OC spending. It does **not** establish why OC accepted no egg receiver. This follow-up preserves that distinction and keeps Test B and Phase 4 awaiting owner acceptance.

## Sources accessible and actually reviewed

Fresh Notion fetches succeeded for the [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363), and [Phase 9](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358). Returned last-edit times were respectively `2026-10-12T19:05:43.587Z`, `19:06:12.841Z`, `19:05:47.249Z`, and `19:05:51.517Z`. Their October 12 Mastery-first directives, native-data precedence, one Brain/scheduler, Studio read-only rule, owner-only acceptance and later-phase approval gates were read. This isolated registration/preflight task authorizes no Mastery or Phase 9 implementation and changes no world reserve.

The existing completed libraries were reused, not restarted:

- [EGGS_AND_PETS.md](research/replicatedstorage/EGGS_AND_PETS.md): catalog versus account facts, native original interaction, price/storage helpers, and unavailable server rules.
- [NATIVE_ACTION_CONTRACTS_NAVIGATION.md](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md): physical arrival, interaction eligibility, request dispatch, received result and persistence are separate evidence.
- [NATIVE_VS_WIKI_CONFLICTS.md](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md): current native definitions and runtime helpers take priority over historical wiki descriptions and disputed reconstructed formulas.
- [KNOWLEDGE_GAPS.md](research/wiki/KNOWLEDGE_GAPS.md): server hatch validation, debit/grant, authoritative variant sampling and persistence remain unavailable; source and mock tests do not establish live acceptance.
- [FUTURE_OC_IMPROVEMENTS.md](research/wiki/FUTURE_OC_IMPROVEMENTS.md): evidence and uncertainty per candidate, bounded failure/reconciliation, existing cache/Brain/scheduler reuse, and no additional phase authorization.
- [PHASE4-EGG-IDENTITY-EVIDENCE.md](PHASE4-EGG-IDENTITY-EVIDENCE.md), [PHASE4-EGG-LOCATION-EVIDENCE.md](PHASE4-EGG-LOCATION-EVIDENCE.md), [PHASE4-TEST-B-NATIVE-EVIDENCE.md](PHASE4-TEST-B-NATIVE-EVIDENCE.md), and [PHASE4-TEST-A-PRESERVATION.json](PHASE4-TEST-A-PRESERVATION.json): exact original identity, duplicate physical placements, passive native receiver evidence, two distinct interaction paths, and frozen Test A methods/files. Historical candidate acceptance statements in those earlier documents are superseded only by the owner's later explicit Test A approval.

Studio was refreshed to the owner-confirmed saved `Game`, ID `bbe2d8d8-d973-46af-861a-dde5eef21a7f`. Resolved native paths below were accessible through read-only `script_read`; the saved Coming Soon hierarchy was accessible through `inspect_instance`. No Luau or require was executed in Studio, no object or script was changed, and no play state was changed. The saved scene is not the owner's live runtime registry or account. Source references use returned MCP line numbers, not embedded decompiler line comments. Saved/decompiled fidelity and hidden server behavior remain limitations.

## What explains the reported state transition

The current source demonstrably explains the **wording transition**, but the live receiver-capture failure is **not proven**:

1. `GameKnowledge:ObserveEggChunker` starts one approximately five-second passive window once the Chunker dependency is available. It then marks `EggObservationFinished=true` and releases the shared wrapper.
2. `EnsureChunkerObserver` observes receivers only after the game's own native Update has returned. During that window it stores a receiver only if the native 3D structure and every inspected chunk member satisfy the existing original/interface/catalog checks.
3. Before the window finishes, unverified physical candidates produce `NATIVE_EGG_REGISTRATION_PENDING`. After it finishes, the same lack of complete accepted receiver evidence becomes `NATIVE_EGG_IDENTITY_UNVERIFIED`.
4. The old messages do not distinguish an unavailable dependency, failed installation, zero native calls, rejected receivers, observer errors, or multiple matching receivers. The owner's log cannot retroactively identify which occurred.

Physical originals and registration are separate observations. Thus `physical originals=2; registered=0` can honestly coexist with stable physical arrival. Neither physical arrival nor a model's shape authorizes a hatch. The comparison with the brother's earlier `registered=2` result does not prove an account, avatar, timing or game-state cause.

The hypothesis that the native registry was initialized before OC attached is insufficient by itself. `ClientScript:790-809` repeatedly calls `u12:Update(root.Position)` through ordinary method lookup while a root exists. `Shared.Framework.Utilities.every:14-32` starts the callback immediately and continues from Heartbeat at the configured interval; the egg caller requests 0.25 seconds. Consequently, a preinitialized receiver can still be observed without a new Add or a character move. `ClientScript:803-807` returns when the native root is absent. Whether those callbacks reached the OC wrapper in the owner's particular five-second window remains a live evidence gap. No deadline extension or retry loop is justified solely by the old log.

The catalog dependency and Chunker load independently in the existing reader. The observer can be installed before Eggs is ready; the old validator treats an unavailable definition table as empty. This is another possible rejection path to report explicitly, not a demonstrated cause in the owner's session.

## Fresh native contracts

| Native source | Verified saved-source behavior |
|---|---|
| `ClientScript:24-26,51-53` | Requires LocalData, the recurring `every` helper, Eggs and the same public Chunker module. |
| `ClientScript:374-376` | Keeps the original-key registry private and constructs the egg receiver with `Chunker.new(128,2)` then `Mode="3D"`. Matching settings alone are insufficient receiver identity. |
| `Chunker:9-20` | Returns a receiver containing `_chunks`, `_loaded`, `_chunkSize`, `_folder`, Loaded/Unloaded signals, Mode and RenderDistance. Each receiver gets a new same-named folder. No global receiver collection is exported. |
| `ClientScript:639-674,747-767` | Prepares each exact tagged original, removes its Egg tag, and calls `u12:Add(original:GetPivot().Position,original)`. It assumes direct Root, Prompt, Plate and Cost interfaces. |
| `Chunker:33-55` | Stores the actual values in coordinate arrays; loaded Instances are parented to the receiver's exact folder. It does not clone them. |
| `ClientScript:507-635` | Creates an engine prompt and a separately cloned Generic visual, then stores the private registry entry keyed by the exact original at 632. Generic copies are not original-key evidence. |
| `ClientScript:453-469`; `Chunker:118-167` | Unload removes private presentation/registry state; native Update reparents exact original values and changes loaded-coordinate membership. Fresh membership/ancestry must be checked after observation. |
| `Chunker:66-75,99-117,146-150,159-163` | Removal assigns a member to nil without compacting surviving members. Exact membership and Update use generic iteration, so native arrays can legitimately be sparse. |
| `ClientScript:491-505,790-809`; `every:14-32` | Initial/character-added and recurring native Update calls permit passive observation of an already initialized receiver. No root means the recurring egg callback returns. |
| `ClientScript:395-451` | Opened state detaches the engine prompt, and native eligibility updates original.Unlocked. Unlocked alone does not establish exact current registration. |
| `ClientScript:869-885` | With native prompt Visible equal zero, scans all private registry keys across egg names; requires Root 3D distance at most 16 and truthy Unlocked, and chooses a strictly closer original. An unresolved tie or incomplete competitor set must remain blocked. |
| `ClientScript:568-616`; `Client.Gui.ProximityPrompt:21-51` | The distinct unopened path uses the exact original's cached/attached engine prompt with 6.5-stud activation distance, current account cost and storage guards. The correction does not trigger or manufacture a prompt. |
| `Shared.Data.Eggs:45-46` | Common Egg base definition is 10 Coins in The Overworld. This is not the account-specific observed quote. |
| `StatsUtil:GetEggCost:197-226` | Reads catalog Cost and applies account milestone EggCost through a cloned item and `ceil(baseAmount/factor)`. Missing named data uses a very large fallback, not an actionable quote. Current runtime helper output is required. |
| `ClientScript:595-616,889,926-931,986-1025` | Native callers compute price from current LocalData. Ordinary dispatch sends egg name and count, not an Instance ID. NextEggOpenAt is a LocalPlayer attribute. Server-side original selection and debit/grant remain unavailable. |

### Coming Soon and incomplete entries

The native sentinel is explicit: `ClientScript:533-535` uses the Common Egg visual asset, `670-672` sets its label, and `414-415,440-451` makes it nonselectable/unlocked false with the engine prompt detached. Fresh saved inspection returned seven distinct Coming Soon original-shaped Models, each with Root, Prompt, Plate, Cost and Decoration and `Unlocked=false`.

The existing observer already permits the Coming Soon name, while still requiring its complete original interface. The fresh scene supports that interface. There is no evidence that this sentinel caused the owner's zero-receiver result. A valid sentinel can be present in the receiver without becoming a selectable paid egg.

The native Chunker supports unloaded originals; these may have Parent=nil while remaining in `_chunks`. The existing observer's shape check does not require Parent, so unloading alone is not a demonstrated receiver rejection. Incomplete or unsupported values can reject the whole receiver conservatively; diagnostics must identify the exact member and reason. No source proves that all malformed values are harmless, so the correction must not silently skip them to obtain registration.

## Demonstrated local defects and narrow correction

Two registration readers demonstrably disagree with the native sparse-array contract. `NativeRegisteredEggModels` in `59c475d125c2` assumes dense indices, while the protected `ObserveEggModel` method uses `table.find(values,model)` to determine exact loaded membership. Native `Chunker.Remove:66-75` deliberately leaves holes while other members remain. Independent official Luau reproduction with `{[2]=selected,[5]=other}` returns nil for both `table.find` queries; `{[1]=selected,[3]=other}` finds the first original but misses the original after the hole. Thus a source-valid registered original can be missed by the protected membership reader as well as rejected by the later nearest-selection reader.

This is a demonstrated code defect and can explain an individual `registered=0` observation **if that live array was sparse in the relevant way**. No supplied live evidence establishes that condition. It also does not explain every final message: with one accepted receiver and a finished window, a missed exact selected membership produces the selected-instance registration blocker; the reported generic unavailable/ambiguous branch comes from incomplete accepted-receiver evidence. Receiver diagnostics are still required to determine the owner's actual state.

The minimum complete sparse-membership repair requires a protected-method edit: replace only `table.find` in `ObserveEggModel` with generic iteration and actual `value == model` equality over the loaded coordinate array. Keep the existing original shape, folder, loaded-coordinate, receiver count and post-window verification rules. The unprotected `NativeRegisteredEggModels` reader can separately read every present native member by generic iteration, preserve finite positive integer keys, exact identity, folder/load/geometry checks and bounded count, and continue rejecting malformed entries. Neither change compacts, edits or fills a native array. The protected change has **not** been applied.

Two reporting defects are source-demonstrated. `PetManager:ReportHatchPreflight` searches `context.Eggs` for an exact eligible model before showing its price. `PetContext` skips modifier-aware cost computation when registration fails, so the old preflight's UNKNOWN price is downstream of that missing identity context; it is not proof the native quote itself was unavailable. A read-only quote may be computed independently from the real definition, current detached account facts and native GetEggCost, while hatch readiness remains blocked on missing identity. Missing/invalid quote still blocks; 10 Coins remains only the future ceiling. `OCController:Log` omits `HATCH_PREFLIGHT` from its ordinary immediate category list, so the final status is hidden with debug disabled despite being generated. Allowing that category is presentation-only.

The local diagnostic/preflight work keeps the protected `ObserveEggChunker` and `ObserveEggModel` method bytes, the original five-second deadline, and the entire Test A movement files unchanged. Additive diagnostic counters belong in the unprotected `EnsureChunkerObserver` body. They do not change receiver acceptance predicates, invoke Update, mutate native membership or start another loop. A read-only status reader reports these observations and exact current loaded membership.

Because a complete source-supported sparse-membership fix now demonstrably depends on the protected `ObserveEggModel` method, the owner's explicit gate applies. Work stops before publication and before that edit. The owner must approve the narrowly scoped exact-equality iteration change; only then may the corresponding approved preservation-manifest method entry be updated. All other protected hashes must remain unchanged. The proposed diff is documented separately for review. No new release, commit or push is authorized by inference from this finding.

## Required normal-console evidence

The safe preflight must emit concise, deduplicated material state changes with debug OFF. The selected original is printed first with a distinct per-session ID; other genuine physical originals follow. Decorative copies are summarized as an excluded count. Paths are presentation only and cannot replace exact Instance equality. Full decorative/ancestry rows remain an explicit expanded diagnostic.

Registration reporting must distinguish these facts rather than combine them into one unavailable/ambiguous message:

1. Native Chunker dependency status.
2. Observer installation success or failure.
3. Whether any native Update reached the wrapper.
4. Total observed native Update count.
5. Distinct receiver count.
6. Count passing native 3D structure checks.
7. Rejected receiver count with exact rejection/error reasons.
8. Exact original membership in inspected `_chunks`.
9. Corresponding current `_loaded` coordinate state.
10. Selected Common Egg found by actual Instance equality.
11. Unrelated pickup/other receiver evidence, without accepting matching settings alone.
12. Timeout before a qualifying native Update versus timeout after observed rejections.
13. Multiple genuinely accepted egg receivers, which remain ambiguous.
14. Later loaded membership, ancestry, receiver change, unload or selected replacement, which invalidates readiness.

An illustrative trace is below; fields are runtime observations, not promised values or hardcoded session IDs:

```text
[OC][EGG_TRAVEL] PHYSICAL_TARGET_RESOLVED | egg=Common Egg; selected=<session Instance ID>; physical originals=<observed count>
[OC][EGG_TRAVEL] PHYSICAL_ARRIVAL_OBSERVED | distance=<observed>; direct attempts=<observed>
[OC][HATCH_PREFLIGHT] <registration status> | dependency=<actual>; observer=<actual>; native updates=<count>; receivers=<count>; structural matches=<count>; qualifying=<count>; rejected=<exact reasons>; selected membership=<actual>
[OC][HATCH_PREFLIGHT] <interaction status> | opened Root scan=<verified or exact blocker>; selected=<same session Instance ID>; price=<native observed quote or UNKNOWN> Coins
[OC][HATCH_PREFLIGHT] HATCH_PREFLIGHT_READY_ALLOWANCE_OFF | hatch requests=0; requested spending=0
```

If observation fails, the last line must instead be `HATCH_PREFLIGHT_BLOCKED` with the exact evidence gap, such as no observed native Update, all structural receivers rejected with stated member reasons, multiple qualifying receivers, selected original no longer loaded, closer/tied eligible original, or missing native quote. Physical arrival remains independently reported. Positive eligibility describes supported client evidence, never server acceptance or an authorized hatch.

## Preservation, spending and acceptance

The safe loader must retain AUTO_HATCH=false, OWNER_ONE_HATCH_TEST_ALLOWANCE=false and all exceptional allowance, egg-price and session-spend ceilings at zero. No authorized account ID is populated. Equipment and unrelated gameplay actions remain disabled. The prepared one-hatch loader is not activated, no native HatchEgg request is sent during investigation, and normal world reserves are preserved.

Local verification must run official Luau compilation, the existing regression suite and `scripts/verify-test-a-preservation.mjs`, and report exact results. Publication and public immutable-bundle verification are held at the protected-method approval gate. The preservation manifest must not be regenerated to conceal an unapproved edit. All completed research files remain unchanged. Regression coverage must include preinitialized/no-update windows, valid duplicates, unrelated/multiple receivers, sentinel and sparse arrays, partial/unloaded/replaced members, opened scan across all names/ties, decoration exclusion, missing registration/price, ordinary logger visibility, zero actions and Phase 2 preservation. The protected sparse-membership failure must remain documented instead of changing its assertion to claim a pass.

The delivery report records the local build, offline counts, exact Git status and protected diff proposal. Existing public builds/pins remain in place; no new immutable candidate is published before explicit approval. The primary owner's live receiver-capture cause remains unresolved until passive diagnostics identify it. A future approved publication would be a candidate for a zero-spend owner retest, not a claim that the missing registration was repaired in that session. Test B success and Phase 4 completion require the owner's actual result. Rejoin/restart persistence remains unverified.

## Historical pre-approval local verification and handoff

Local bundle **`5141227b97af`** was rebuilt with `node scripts/build.mjs`. It is unpublished: the example loader pins generated by the build refer to a future candidate tag that does not yet exist publicly. Do not present those local pins as a working released URL. Current Git remains branch `codex/phase4-test-b` at **`358bd6b22a2158ad4be14a7a9adc1561566697b2`**, with uncommitted changes and no new commit, push or tag from this investigation.

`node scripts/test.mjs` passed official Luau compilation, static bundle checks, **622 main-suite cases** (599 baseline plus 23 additions), initializer/Config isolation and example guard checks. The actual-knowledge identity file contains **47 checks**, and the Test B interaction file contains **27 checks**. The tests intentionally preserve the blocked sparse selected-instance result; they do not claim that protected defect has been fixed. Native update exceptions preserve their arguments, error propagation and multiple-result forwarding; diagnostics separately count entered and completed updates. Receiver/coordinate/value counts are bounded, and diagnostics have a separate stable ID namespace with explicit aliases to previously assigned physical IDs. A regression compares with an uninstrumented fixture and confirms unchanged physical ID allocation and unchanged discovery cache/timestamps.

`node scripts/verify-test-a-preservation.mjs` passed **all 10 unchanged hashes** against the approved baseline. The completed-library comparison passed **all 104 byte-identical files**. `git diff --check` passed. These are offline/source checks only; no Studio or live game actions were performed.

Changed source files are `src/OCFoundation/GameKnowledge.luau` (unprotected passive diagnostics, separate diagnostic IDs, source-valid sparse enumeration), `PetManager.luau` (read-only native quote, registration reporting and semantic throttling) and `OCController.luau` (ordinary preflight visibility). Changed tests are `tests/phase4-egg-identity.luau` and `tests/phase4-test-b-interaction.luau`. The build regenerated `dist/OC.lua`, `dist/OC.local.lua` and the two safe/prepared Test B example pins. This evidence document and [PHASE4-PROTECTED-MEMBERSHIP-PROPOSAL.md](PHASE4-PROTECTED-MEMBERSHIP-PROPOSAL.md) are new. No protected method, movement file, preservation manifest, central Config, paid dispatch, allowance logic or reserve was edited. Both example configurations remain inactive for paid actions, with authorized account ID zero.

The next step requires the owner's explicit approval of the linked minimum protected membership diff. Only afterward may the approved method hash change be recorded, the sparse identity regression require positive recognition, and a new candidate be built/published/verified for a zero-spend owner retest. The additional diagnostics still need that live retest to identify why the original five-second receiver capture failed. No Test B pass or Phase 4 approval is claimed.

## Owner-approved exact-membership follow-up

The preceding approval-gate and unpublished-build sections are historical records of the earlier held investigation. The owner subsequently **explicitly approved only the proposed `ObserveEggModel` membership replacement**: enumerate existing native values with `pairs` and compare `value == model`, replacing `table.find`. That approval permits the narrow fix, its preservation exception record, regressions and a new safe candidate publication. It authorizes neither movement changes nor a hatch, allowance activation or spending. The earlier stop was honored; this appendix records the later authorization without rewriting it.

The approved source change is exactly:

```diff
             local values = receiver._chunks[coord]
-            if type(values) == "table" and table.find(values, model) then registered += 1 break end
+            local member = false
+            if type(values) == "table" then
+                for _, value in pairs(values) do
+                    if value == model then member = true break end
+                end
+            end
+            if member then registered += 1 break end
```

Fresh read-only Studio enumeration again returned the saved `Game`, ID `bbe2d8d8-d973-46af-861a-dde5eef21a7f`. A focused reread of `ReplicatedStorage.Shared.Utils.Chunker:56-167` reconfirmed the exact justification: Remove sets the matching member nil at 68 and leaves other members at their surviving keys; IsValueLoaded iterates every present member and compares exact values at 104-113; Update likewise uses generic iteration at 146-150 and 159-163. The approved code follows this current native contract. No native Update was called to manufacture evidence, no registry was mutated, and no new research project or Studio gameplay test was performed.

Independent source review confirms that the remaining `ObserveEggModel` code is unchanged: original Root/Prompt/Plate/Cost and finite geometry, loaded Workspace ancestry, exact receiver-folder parent, accepted native receiver structure, loaded-coordinate iteration, distinct-receiver ambiguity and post-window verification policy remain intact. The whole movement implementation and physical-location methods remain the Test A behavior. The original five-second `ObserveEggChunker` deadline and shared cleanup remain unchanged; preinitialized registry or missed timing is still not asserted as the live cause.

`NativeRegisteredEggModels` now accepts native sparse positive-integer keys while preserving all present-member type, loaded, exact parent, Workspace, geometry and bounded-count checks. Its generic enumeration neither fills holes nor guesses missing originals. The read-only selected-membership diagnostic uses the same exact generic comparison and no longer claims that the now-approved protected reader necessarily misses a sparse member. Missing receiver capture, unsupported members, multiple qualifying receivers, unloaded/replaced selected Instances, closer/tied eligible originals and missing native quotes still block hatch readiness.

The original [Test A preservation manifest](PHASE4-TEST-A-PRESERVATION.json) is retained unchanged as the historical baseline. A separate explicit owner-approval record accounts for the one approved `ObserveEggModel` hash and exact snippet. The verifier must preserve the other nine baseline hashes and validate this precise exception; it must reject any additional protected alteration rather than accepting a broad rewritten method. Final preservation/test results and release identifiers are recorded after root verification.

The ordinary safe preflight keeps debug OFF, AUTO_HATCH=false, OWNER_ONE_HATCH_TEST_ALLOWANCE=false, AUTHORIZED_ACCOUNT_ID=0 and all exceptional allowance/egg/session cost ceilings at zero. Equipment, pickups, purchases, farming, bubbles, selling, rewards and unrelated actions remain OFF. It preserves the already-approved bounded TRAVEL_ONLY behavior. The prepared ONE_HATCH example remains disabled by its false approval flag and zero account ID. Neither loader is authorized for paid action by this membership approval.

The positive sparse-member regression can now require exact selected-instance recognition under native source-valid holes, followed by the existing all-name opened scan, range, visibility, tie, unload and account guards. These remain offline mock results. The corrected source defect may have contributed to an observed zero membership, but the supplied live log still does not establish a sparse array or the exact failed receiver-capture path. Passive counters distinguish no observed Update, observed rejections, multiple receivers and later membership changes for the owner's next zero-spend preflight. The actual earlier live cause remains **UNPROVEN**; no Test B pass, successful hatch, server-side Instance selection or Phase 4 completion is claimed.

The approved candidate is build **`926bc78d88af`**, tag **`phase4-hatch-926bc78d88af`**. Official compilation, **623 main-suite cases**, **13 exact-difference/preservation checks**, Config isolation and example zero-budget guards passed. All ten historical hashes remain recorded unchanged, nine current checks remain exact baseline bytes, and only the explicitly approved `ObserveEggModel` method has new hash `ece9abde1eb24fa01041a8d73ce5340ea075eca3d52b7b25aeed07dbb0aaedf1`. The separately recorded [approved correction](PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json) and [current delivery instructions](PHASE4-REGISTRATION-PREFLIGHT-DELIVERY.md) supersede the earlier held/unpublished handoff status without rewriting that history.

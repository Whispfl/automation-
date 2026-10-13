# Phase 4: 85 observed Updates, zero qualifying egg receivers

Focused follow-up to the owner's safe preflight on build `926bc78d88af`, commit `d864a3ec269f2bb1702b47244f3026300ec2ce29`, tag `phase4-hatch-926bc78d88af`. The owner reports correct Common Egg selection and stable physical arrival while already approximately 3.42 studs away, zero movement attempts, zero hatch requests and zero spending. The native runtime quote was independently observed as 10 Coins. Those working movement and pricing behaviors remain preserved.

The current live evidence proves the observer installed and completed 85 global native Update observations across five receivers. It does **not** yet identify the genuine egg receiver or prove that any of those calls came from it. The new task is to fill that exact evidence gap through bounded read-only diagnostics, without relaxing classification or native hatch guards.

## Accessible sources and preserved scope

The root freshly fetched and read the [Notion master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363), and [Phase 9](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358). The October 12 Mastery-first policy, one Brain/scheduler, native-data precedence, read-only Studio and explicit approval gates remain applicable; no Mastery or Phase 9 feature is implemented.

Completed research reused for this investigation:

- [EGGS_AND_PETS.md](research/replicatedstorage/EGGS_AND_PETS.md), native physical egg contract and unavailable server rules: catalog, physical availability, native interaction and paid acceptance are separate.
- [NATIVE_ACTION_CONTRACTS_NAVIGATION.md](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md), contract states/result standards: stable physical arrival remains valid evidence even when interaction registration is unavailable.
- [NATIVE_VS_WIKI_CONFLICTS.md](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), native/current-source precedence and historical-description limitations.
- [KNOWLEDGE_GAPS.md](research/wiki/KNOWLEDGE_GAPS.md), hatch/server validation, result and persistence uncertainty.
- [FUTURE_OC_IMPROVEMENTS.md](research/wiki/FUTURE_OC_IMPROVEMENTS.md), candidate evidence/uncertainty and bounded reconciliation using the existing architecture.
- [PHASE4-EGG-IDENTITY-EVIDENCE.md](PHASE4-EGG-IDENTITY-EVIDENCE.md), [PHASE4-EGG-LOCATION-EVIDENCE.md](PHASE4-EGG-LOCATION-EVIDENCE.md), [PHASE4-TEST-B-NATIVE-EVIDENCE.md](PHASE4-TEST-B-NATIVE-EVIDENCE.md), [PHASE4-REGISTRATION-OBSERVATION-EVIDENCE.md](PHASE4-REGISTRATION-OBSERVATION-EVIDENCE.md), and [PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json](PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json): exact original identity, native lifecycle, opened scan, approved sparse membership and the preserved movement baseline.

Fresh Studio enumeration returned the owner-confirmed saved `Game`, ID `bbe2d8d8-d973-46af-861a-dde5eef21a7f`. Targeted native source, hierarchy and instance inspections below succeeded. No Luau or require was executed in Studio, no Instance or script was changed, and no play state was changed. The saved scene does not expose the owner's live receiver tables, unparented originals or private original-key registry. No broad native/wiki research was restarted, and the completed libraries are unchanged. Line references are returned MCP `script_read` numbers, not embedded decompiler comments.

## What the owner's new log establishes

The first status records dependency ready, observer installed/active, 29 entered and completed Updates, five receiver objects, four structurally compatible 3D receivers, five rejections and zero accepted egg receivers. The final status records 85 entered/completed Updates, the same five receivers, zero accepted egg receivers and the bounded observer inactive after completion. Therefore failed installation or zero global Update calls do not explain this session. The cleanup status is consistent with the existing five-second window ending.

Four matching 3D structures do not prove four egg registries. Likewise, 85 global calls do not prove even one egg call. The old implementation stops classification at a receiver's first unsupported member, so its rejection example is not a full inventory of that receiver's contents.

There is also a demonstrated diagnostic scope defect in this published candidate: `NativeEggRegistrationDiagnostics` computes `SelectedFound`, `SelectedLoaded` and protected membership by scanning **only `NativeEggChunkers`, the already accepted receiver set**. Because that set is empty, the reported `exact selected in chunks=false` cannot establish that the selected Common Egg was absent from all five observed/rejected receivers. It means only that no accepted receiver supplied that proof. The next diagnostic must explicitly separate all-observed membership from accepted membership; it must not turn observed membership alone into hatch permission.

## Current native lifecycle and receiver kinds

| Fresh source | Saved native behavior |
|---|---|
| `ClientScript:53,374-376` | Requires the public Chunker class and constructs the egg receiver with chunk size 128, render distance 2 and Mode 3D. The original-key presentation/interaction registry remains private. |
| `Shared.Utils.Chunker:7-20` | The shared class is the receiver metatable and its own `__index`; each receiver gets an actual separate folder under Rendered. A folder name is not unique receiver identity. No global receiver list is exported. |
| `ClientScript:639-674,697-747` | `createFromModel` prepares the direct Root/Prompt/Plate/Cost interfaces, removes the Egg tag, reads native display cost, and queues the exact original through `u12:Add`. It contains no catalog-membership filter before Add. |
| `ClientScript:750-768` | Processes each tagged Egg original and future tagged additions; Infinity is processed separately. A removed tag after initialization is expected. |
| `ClientScript:507-540,554-635` | On load, `create(original)` first seeks a matching Assets.Eggs visual, with explicit Coming Soon handling. If the asset is absent it returns at 539-540 before creating the private entry. Otherwise the exact original keys that private entry at 632. Native queued values and private registered interactive entries are related but not identical sets. |
| `Chunker:33-55` | Queues exact values into `_chunks`; loaded Instance values are parented to the exact receiver folder, while unloaded ones may have Parent=nil. It does not clone originals. |
| `Chunker:66-75,99-117,146-150,159-163` | Native Remove leaves holes; exact loaded membership and Update use generic iteration. The existing approved `pairs` correction remains required and unchanged. |
| `ClientScript:491-505,790-809` | Character-added, initial and recurring egg updates use ordinary `u12:Update(...)` lookup. The recurring callback returns without a native root; otherwise it calls Update every 0.25 seconds. No cached Update function reference or alternate egg Update implementation appears in these inspected callers. |
| `Shared.Framework.Utilities.every:14-32` | Spawns the callback initially and subsequently from Heartbeat at the requested interval. A previously initialized receiver can still be observed on later calls. Actual owner-session wrappers/callback interruptions are not exposed by saved source. |
| `ClientScript:1140-1141,1292-1324` | Pickup receiver uses the same 128/2/3D settings. It clones a pickup, names it from the received Id at 1322, then queues that exact Model at 1324. A UUID-like name is compatible with this path, not proof of that particular runtime receiver. |
| `ClientScript:1417-1418,1547,1682-1697` | Portal receiver also uses 128/2/3D; `hookPortal` queues the exact portal Model, and its recurring update runs every two seconds. A Zen model lacking egg-original interfaces is compatible with this subsystem, not unique receiver proof. |
| `Client.Effects.RenderAnimatedObject:16-17,30-44,77,98-106` | Another 128/2/3D receiver queues `{Guid,Constructor}` tables, not original Instances, and updates every 0.5 seconds. A non-Instance entry is source-compatible here and invalid for egg classification. |
| `Client.Effects.PhysicalItem:10,26`; `Chunker:20` | Physical items construct a 256/2 receiver and retain the default 2D Mode. Matching this structure explains a non-egg category without treating its folder name as authority. |
| `ClientScript:395-451,869-885` | Opened eggs detach the initial engine prompt. The opened scan requires global Visible=0 and selects the strictly nearest eligible original across all private registry keys/names, Root distance at most 16. Missing/incomplete competing evidence remains a hatch blocker. |

Native queued full originals are not guaranteed catalog-backed by `createFromModel`. Therefore the current whole-queue requirement that every name be catalog-backed or Coming Soon is stronger than that caller's explicit prerequisites. This is a source-supported distinction to investigate. It is **not** sufficient evidence to accept a particular rejected receiver or ignore an unsupported entry: the actual egg receiver, selected membership and the entry's interaction/lifecycle semantics must first be established.

## Five observed rejection examples

Diagnostic labels are session-only and are never copied into selection code.

| Owner example | What is established | What remains unknown |
|---|---|---|
| D0001: UUID-like Model, Root/Prompt/Plate/Cost absent, loaded=true | That sampled member fails the complete original interface. Its naming/content are compatible with native pickup clones. | Exact receiver attribution requires native references/membership evidence, not the UUID pattern. |
| D0004: complete-interface member named Egg, ready catalog lacks its name, coordinate `-6,1,3`, loaded=nil | Classification reached the name check only after that sampled Instance passed the shape check; it is in an unloaded coordinate. | Whether this is the real egg receiver; whether selected/other Common originals occur elsewhere in it; actual current name/attributes/asset/tag/private-entry origin. |
| D0007: non-Instance entry | The sampled value cannot be an egg original Instance. Constructor records in RenderAnimatedObject provide a compatible native explanation. | Exact receiver attribution and other contents. |
| D0009: 2D, chunk size 256 | Its structure differs from the native egg receiver; it is compatible with PhysicalItem. | Exact physical-item attribution is not independently established by the log. |
| D0011: Zen, full egg-original interface absent, loaded=true | That sampled member cannot satisfy the original egg interface. Native portal content is compatible. | Exact receiver attribution and current folder relationship. |

The five known native constructor kinds and five observed objects are suggestive but do not prove a one-to-one correspondence. Multiple objects can share class/settings, runtime state can differ, and an observed receiver can remain incorrectly classified. No receiver is selected by exclusion or call order.

### The noncatalog Egg remains unidentified

Fresh saved hierarchy search found named Egg Models under BunnyEgg, Seven Seas area platform groups, a Hyperwave platform group and visual-asset decorations. Inspected BunnyEgg.Egg contains Decoration/Hitbox only; the inspected Seven Seas and Hyperwave Egg groups contain an EggPlatformSpawn Model rather than direct Root/Prompt/Plate/Cost. These saved named objects do not match the sampled full interface in the owner's log.

`ReplicatedStorage.Assets.Eggs.Egg` was absent in the saved scene. A complete search of the saved asset egg-name Models returned 584 matching rows; exact Egg names were pickup/visual-decoration children, without exposing the owner's unloaded full original. These are saved-scene facts only. They do not prove the identity or origin of the runtime object at an unloaded coordinate. Allowed tools do not expose that unparented owner's Instance or its live tag history, and a name/coordinate match cannot bridge that gap.

The source permits a complete tagged noncatalog original to enter the queue if its preparation completes. Separately, missing visual assets cause native loaded `create` to return before adding the private interactive entry. This supports distinguishing queued versus interactive content. It does not prove that the owner's Egg member took either path or that it can safely be ignored. No Egg whitelist, hardcoded coordinate, fake prompt membership or invented private-registry accessor is justified.

## Narrow diagnostic correction and stop condition

The authorized change is confined to unprotected read-only diagnostic reporting. Continue using the existing installed observer; add no hook, native Update call, event subscription, polling loop or deadline extension. Preserve the actual acceptance/rejection predicates and all native return/error forwarding and cleanup. No native registry, Instance or game state is changed.

For **every observed receiver**, scan all present `_chunks` values with explicit receiver/coordinate/value bounds even when one member is rejected for classification. Report Mode, size/distance, distinct actual folder ID/ancestry, loaded-coordinate and total-coordinate counts, Instance/Model and complete-original counts, unsupported/malformed entries and precise rejection reasons. Compare the retained selected and other genuine physical Common originals by actual Instance equality throughout every candidate, including rejected receivers. Report their current coordinate loaded state and exact parent-folder equality separately. An exhausted bound or read failure must say evidence is incomplete.

The accepted receiver set remains independently reported. An observed candidate containing the exact selected original is a useful fact, but is not a green registration decision while that candidate has unsupported contents, unclear provenance or contradictory loaded state. The diagnostic method cannot grant identity, choose a receiver, retarget an egg or authorize hatch. The actual protected `ObserveEggModel` result remains separate from an observed membership count.

If the selected Common Egg appears in none of the fully scanned candidates, report `SELECTED_EXACT_INSTANCE_NOT_FOUND_IN_OBSERVED_RECEIVERS` only with a complete bounded scan; this does not imply no genuine egg receiver exists anywhere. If it appears in a rejected candidate, report `SELECTED_EXACT_INSTANCE_PRESENT_IN_REJECTED_RECEIVER` with exact reasons and folder/load relationships. The next owner trace can then distinguish a rejected genuine candidate from a missed/unobserved receiver. No source-supported classification repair is applied merely to produce qualifying=1.

Any later fix that changes another protected observation/discovery/movement method requires a new minimal diff proposal and explicit owner approval. The prior permission covers only the already-applied `ObserveEggModel` sparse membership snippet. The original historical manifest and separate approved correction record remain unchanged.

## Expected concise owner trace

The next safe loader keeps ordinary console logging, debug OFF, current native quote handling and all paid actions/allowances/budgets OFF. One final decision must remain `HATCH_PREFLIGHT_READY_ALLOWANCE_OFF` or `HATCH_PREFLIGHT_BLOCKED`, with hatch requests=0 and requested spending=0. With the currently known unresolved classification, a blocker remains the expected honest result.

Illustrative fields below contain live observations, not fixed counts or guaranteed outcomes:

```text
NATIVE_EGG_RECEIVER_OBSERVATION
Updates observed=<entered>/<completed>; candidates=<count>; structurally compatible=<count>
exact selected in all observed receivers=<actual>; exact other original=<actual>
qualifying egg receivers=<actual>; observation complete=<actual>; scan complete=<actual>
candidate=<session ID>; Mode=<actual>; chunk size=<actual>; render distance=<actual>
folder=<distinct session ID>; ancestry=<actual>; coordinates=<total>/<loaded>
members=<Instance/Model/original counts>; selected=<exact equality/load/parent facts>; other=<exact facts>
rejection=<exact reasons>; unsupported=<bounded summaries>
HATCH_PREFLIGHT_BLOCKED | native price=<current native quote> Coins | <exact remaining blocker>
hatch requests=0; requested spending=0
```

The selected physical original and a compact row for the other original remain prioritized; decorative Generic copies are summarized as excluded. Receiver IDs and same-path names are presentation only. Material changes/final observation are logged without repeating dozens of decorative paths.

Wait for the existing five-second observation and stable-arrival period to finish, then return the concise receiver observation and final preflight lines. If incomplete data or a rejection remains, do not activate ONE_HATCH or try a paid action. The owner performs this live test; source and regression results cannot establish actual accepted registration, paid result or Phase 4 completion.

## Verification and release record

Candidate build `6dfccccdf6cf`, new pin `phase4-hatch-6dfccccdf6cf`, was rebuilt with `node scripts/build.mjs`. `node scripts/test.mjs` passed official Luau compilation and all 637 main-suite cases, including 60 egg-identity cases and 29 Test B interaction cases. Thirteen approved-membership checks and seven exact receiver/price/paid-guard preservation checks passed. The historical ten-method Test A hashes were verified: nine current methods remain identical and the previously approved exact membership correction remains separately recorded. Shared geometry and Instance identity helpers remain unchanged.

All 104 completed research-library files compare unchanged against the incoming commit. `git diff --check` passed. The immutable historical manifest and separate approved correction record remain byte-identical. The preserved Test A baseline remains `25890f224f0448f148d009e65514c129aeb4f59c`. Publication must use the existing development branch and a fresh tag, followed by anonymous Git-tree and raw-byte verification, including the older Test A and Test B pins. The final delivery supplies the resulting full commit SHA and public verification result; these offline checks are not live registration or gameplay success.

This release is a **safe preflight candidate with full observed-receiver diagnostics**, not a claim that the genuine egg receiver has now been identified or classification repaired. The demonstrated old reporting scope defect is corrected; the live registration root cause remains unresolved pending the all-candidate exact-membership trace. No hatch, equipment command or OC spending is performed during development or authorized by readiness reporting.

## Independent empty-coordinate reader correction

Fresh `Chunker:73-75` clears `_chunks[coord]` after the last member is removed, without clearing `_loaded[coord]`. `IsValueLoaded:104-107` skips that absent bucket, and `Update:154-157` can retain the empty loaded coordinate. The prior unprotected `NativeRegisteredEggModels` reader rejected every non-table bucket, including this legitimate nil state. The exact source-supported correction was documented to the owner before editing: require loaded=true, skip only an absent nil bucket, and continue to reject false/string/other malformed present buckets and nontrue loaded flags. A bounded coordinate count additionally prevents an unbounded empty-coordinate scan. Every present member still receives the existing exact identity, positive-integer key, Model, folder, Workspace and geometry checks.

This separate correctness repair cannot explain the zero qualifying receivers: classification iterates existing `_chunks` entries and never sees the absent key. It is not a classifier relaxation or proof of live registration. Tests cover a removed last member, surviving originals in other coordinates, an emptied selected bucket, malformed present buckets and false loaded flags.

## Exact scope of the next snapshot

Each captured receiver is scanned read-only with bounded coordinates, values and examples even if the existing classifier rejected it. Exact selected and other cached same-name original references are searched by actual equality, independently of the accepted registry map. The output separates raw observed membership from trusted membership; a partial scan reports UNKNOWN instead of absence. The snapshot reports current counts and current membership, while `last native rejection` identifies the previously recorded callback-time rejection. It does not pretend to reconstruct unrecorded historical contents.

Standard `getmetatable`, `rawget(receiver,"Update")`, and function-reference equality report whether a captured receiver currently uses the public class, has an own Update function, and resolves the same public function. These are observations only: no function is invoked, no metatable is edited, and no private closure/upvalue/runtime enumeration is used. The facts can identify an observable cached own-method difference among captured receivers; they cannot expose the invocation path of a receiver that was never captured. Folder identity and exact selected-parent equality are reported alongside ancestry; names remain presentation only.

No change was made to EnsureChunkerObserver, RecordNativeEggUpdate, ObserveEggChunker, ReleaseChunkerObserver, pickup observation, Destroy cleanup, physical selection, travel, native interaction guards, paid Prepare or the owner-verified native price quote. The previously approved sparse membership method and historical hashes remain intact. No further protected-method approval was needed because those methods were not edited. A future classifier/observation repair still requires its own source evidence and any applicable owner gate.

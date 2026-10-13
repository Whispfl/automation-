# Source-supported receiver classification correction — awaiting approval

This is a proposal only. The exact source patch is [PHASE4-RECEIVER-CLASSIFICATION-PROPOSED.patch](PHASE4-RECEIVER-CLASSIFICATION-PROPOSED.patch). No production source, bundle, loader, Config, preservation record or release tag has changed. No commit or publication is made. Incoming development HEAD remains `478ce3710ba2ece46d46653d4372ededc3638e2f`, build `6dfccccdf6cf`.

## Required sources checked

Fresh Notion fetches succeeded for the [master roadmap](https://app.notion.com/p/3f53d7e9278d81c5a6cacfe227eb4349), [Phase 4](https://app.notion.com/p/3f53d7e9278d81a796a9d3c505076363), [Phase 3](https://app.notion.com/p/3f53d7e9278d816c8494da53650aaa10) and [Phase 9](https://app.notion.com/p/3f53d7e9278d81e7a631d19062ab3358). Their latest returned owner notes retain the October 12 Mastery-first policy, native-data precedence, one Brain/scheduler, read-only Studio, owner-only gameplay tests and phase approval gates. No Mastery or Phase 9 implementation is included.

Existing research reused, with relevant sections reread rather than restarting the deep dives:

- [EGGS_AND_PETS.md](research/replicatedstorage/EGGS_AND_PETS.md), Native physical egg contract: exact native prompt/opened scanner, received account and hatch guards; server-only results remain unavailable.
- [NATIVE_ACTION_CONTRACTS_NAVIGATION.md](research/replicatedstorage/NATIVE_ACTION_CONTRACTS_NAVIGATION.md), Contract states and intentional egg location: physical arrival, interaction and purchase/result are separate evidence.
- [NATIVE_VS_WIKI_CONFLICTS.md](research/wiki/NATIVE_VS_WIKI_CONFLICTS.md), current native/account evidence overrides historical wiki descriptions and unverified effective odds.
- [KNOWLEDGE_GAPS.md](research/wiki/KNOWLEDGE_GAPS.md), private server rules, hatch/policy acceptance and required owner account-state observations.
- [FUTURE_OC_IMPROVEMENTS.md](research/wiki/FUTURE_OC_IMPROVEMENTS.md), attach version/uncertainty, preserve explicit action gates and shared architecture.
- [PHASE4-EGG-IDENTITY-EVIDENCE.md](PHASE4-EGG-IDENTITY-EVIDENCE.md), [PHASE4-EGG-LOCATION-EVIDENCE.md](PHASE4-EGG-LOCATION-EVIDENCE.md), [PHASE4-TEST-B-NATIVE-EVIDENCE.md](PHASE4-TEST-B-NATIVE-EVIDENCE.md), [PHASE4-REGISTRATION-OBSERVATION-EVIDENCE.md](PHASE4-REGISTRATION-OBSERVATION-EVIDENCE.md) and [PHASE4-ZERO-RECEIVER-EVIDENCE.md](PHASE4-ZERO-RECEIVER-EVIDENCE.md), exact original versus visual copy, native queue lifecycle, opened nearest scan and previous evidence limits.

The separate prior [approved membership correction](PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json) and original [Test A manifest](PHASE4-TEST-A-PRESERVATION.json) remain unchanged. Studio `Game`, ID `bbe2d8d8-d973-46af-861a-dde5eef21a7f`, was inspected through read-only source/hierarchy tools. No Luau/require was executed there and no object or play state was changed.

## What the latest live trace establishes

Across 19 receiver snapshots, D0004 contains the exact selected original and the other physical Common original; selected membership is loaded and its parent equals the exact receiver folder. Fourteen snapshots show `136 = 55 catalog + 21 Coming Soon + 60 noncatalog`; five show `135 = 54 + 21 + 60`. These changes reinforce that the queue is live state, not an immutable list. The 60 missing definitions remain consistent. The source class metatable, inherited public Update, 128/2/3D settings, all-Model full interfaces and same folder provide positive queue association beyond names or paths.

The production acceptance predicate is in `EnsureChunkerObserver`: any present full original whose name is neither catalog-backed nor Coming Soon makes the whole queue invalid. `RecordNativeEggUpdate` independently repeats that restriction. The read-only snapshot identifies the missing definitions as the sole current content issue in D0004. Thus the demonstrated receiver rejection is the whole-queue catalog requirement, rather than installation failure, no native Updates or absence of the selected Instance from captured data.

## Fresh native source and the three attached modules

Line numbers below refer to returned MCP source lines or physical lines in the owner's attached files, not embedded decompiler line comments.

| Source | Relevant contract |
|---|---|
| `ClientScript:53,374–376` | Uses the public Chunker class, constructing the egg queue with 128/2/3D settings. |
| `ClientScript:639–674,697–747,750–768` | Prepares tagged original Root/Prompt/Plate/Cost, removes the Egg tag and adds the exact original to the egg queue. There is no catalog-membership requirement before Add. |
| `Shared.Utils.Chunker:7–20,33–55` | The actual public class is the receiver metatable. Instance values are parented to the exact receiver folder when loaded, and nil when unloaded. Add stores originals rather than visual clones. |
| `Chunker:66–75,99–117,118–167` | Remove leaves sparse indexes; native lookup/update iterate present values. Empty loaded coordinates can persist after the final member is removed. |
| `ClientScript:507–540,554–635` | On load, native create seeks a matching visual asset, substituting Common for Coming Soon. Missing asset returns before private registry insertion at 632. Catalog-backed target data and successful visual creation are separate from queue membership. |
| `ClientScript:395–451` | updateUnlocked first requires the exact private registry key at 409–412, then updates prompt/lock state and the original's Unlocked attribute. Current loaded membership and Unlocked are lifecycle corroboration, not direct access to that private table. |
| `ClientScript:491–505,790–809,869–885` | Recurring ordinary public Update calls provide passive receiver observation. Opened nearest scanning uses all private originals across names, global Visible=0, Unlocked, distance at most 16 and the strictly nearest Root. |
| Owner `Eggs.luau:531–540` | Iterates tagged Egg objects, looks up their names and updates Island only when a catalog definition exists. Unknown tagged names are tolerated; they are not added to the catalog or certified as interactive. |
| Owner `EggBuilder.luau:16–26,27–53,144–180` | Constructs catalog definitions, including Pool, Image, Cost, World, Reward, ProductId, Event and other policy/layout fields. The default definition cost is not a live price quote. This builder supplies no physical Instance/Chunker registration. |
| Owner `GetEggPool.luau:13–28,73–129` | Reads a catalog entry by name and transforms its Pool with luck/rarity/season factors. It neither registers physical Instances nor proves membership in a native interaction registry. It must not be called for an undefined target to invent a reward pool. |

The attached files were read as source evidence and not executed or copied into production. Full file SHA256 values identify the exact owner inputs:

- `Eggs.luau`: `702e6c05b034e71f305d78e055430c1fc82adfa5ec17eaf7c095efa56f006ae4`.
- `EggBuilder.luau`: `5cec9b89dbb2330a995cb6caf337a097dfb14c25a11bb08ba10857d6014f8322`.
- `GetEggPool.luau`: `b6ef4d60143ca2ff8b2ff700ff4856f88b007ff454015e7acc012d4f06b2e1c8`.

The combined source and live evidence supports complete noncatalog originals as native queue contents. It does not establish the individual tag history, private interactive keys or hatch eligibility of all 60 runtime Models. They are unparented/current runtime values unavailable through the saved Studio scene; saved named Egg decorations do not match their full interfaces, and the saved `Assets.Eggs.Egg` asset is absent. No name whitelist or fabricated private-registry accessor is proposed.

Fresh read-only inspection also confirms `ReplicatedStorage.Assets.Eggs.Common Egg` is a Model with a Hitbox. Native create clones its matching visual at 555 and calls Model:ScaleTo at 629 before private insertion at 632. The proposed Model asset prerequisite is therefore source-supported; its presence alone cannot certify private callback completion or registry membership.

## Exact proposed scope

The linked patch modifies three existing methods in `GameKnowledge.luau` and adds one local read-only classifier before `InstanceId`:

1. **EnsureChunkerObserver** uses the shared classifier instead of the whole-queue catalog restriction. It still observes only after the original native Update returned, forwards all arguments/returns/errors, uses the same bounded window and weak receiver map, and retains pickup behavior/cleanup. Invalid reobserved contents revoke that receiver's prior candidate acceptance within the existing window.
2. **RecordNativeEggUpdate** counts catalog, sentinel and noncatalog originals separately, then uses that same classifier for qualification. This prevents a diagnostic/production acceptance mismatch. Existing counters and IDs remain observations only.
3. **NativeEggRangeEligible** gains one conservative selected-visual prerequisite check, because native create returns before private insertion without a matching asset. Asset existence is necessary corroboration, not proof of a private key. All existing range, exact identity, nearest/tie, initial prompt, access and account checks remain.

The classifier requires actual native class metatable equality, existing 128/2/3D/folder structure, bounded coordinates and values, positive integral sparse member keys, full original Model interfaces and finite geometry, true loaded flags, exact loaded parent-folder/Workspace ancestry and nil unloaded parenting. It requires at least one loaded catalog-backed original anchor. Every unknown original receives the same schema/lifecycle validation; none is silently skipped or accepted because it is named Egg.

The selected original's exact membership and loaded folder identity are still checked by unchanged `ObserveEggModel`/`ResolveEggInstance`; completed observation with exactly one qualifying receiver remains mandatory for the owner's opened-egg path and its all-name loaded reader. The existing unopened exact cached-prompt path remains separate. Neither a name/path match nor the presence of a catalog anchor can select or substitute the target.

Noncatalog queue entries are not promoted into selectable paid eggs: unchanged `EggModels`/catalog discovery and native quote/paid guards exclude undefined targets. `NativeRegisteredEggModels` still reads **all** loaded originals across names, including unknown ones; an unlocked closer or tied unknown stays a conservative nearest-selection blocker. No catalog filtering removes potential competitors. Known different-name interactive originals still participate. Missing or contradictory evidence remains a blocker, and no green preflight result is guaranteed.

The proposed correction is general to ordinary catalog eggs. Common, Egg, receiver IDs, coordinates, account IDs, balances and the observed 55/21/60 counts are not selection constants in the patch. Coming Soon remains the existing native sentinel used only in diagnostic counting, not a paid target.

## Exact proposed method hashes

These are proposed differences, not applied changes or rewritten history. Original source, approved sparse method, historical hashes and every existing pin remain unchanged.

| Method | Current SHA256 | Proposed SHA256 |
|---|---|---|
| EnsureChunkerObserver | `f8a2fcf35c88088fb13ed14f690b5cbba0ade21abe1812c8063d586b658b4e06` | `398380ce44359616321a0a8d927b80f3d79e1eabd2096d304796b80a6ee21add` |
| RecordNativeEggUpdate | `9f904fd8b7d5676213d12699ad9949e1a8e7cf74a9c3a4636fff6605b4c23cf6` | `2c83d2480ca8ffb0c1e780188e0787ce66a72a91f195e5f061731c8817297285` |
| NativeEggRangeEligible | `1df9b01f21ad46eabc1eb88a709dfb2ba7e66f2e0b170914e98155186fc8e108` | `18bda385d398b2ce78d458faeecf85a885f3d9f1d63ff3089057e751c845da86` |

Exact patch SHA256: `f46399a7079e6de22062a932ed8f08590724199ce7ea085073d97034e730eadf`. `git apply --check` validates its context without applying it. In-memory comparison of the proposed text confirms ten other existing methods and the three shared geometry/receiver helpers are unchanged; no modified source file was created. After explicit approval, these exceptions would receive a new separate before/after record and appropriate preservation checks. Existing historical JSON and the prior sparse approval are not broadened.

## Verification and focused tests

On the unchanged production baseline, `node scripts/test.mjs` passed official Luau compilation and all 637 main-suite cases. Thirteen approved-membership checks, seven observer/price/paid-guard preservation areas, historical ten-method verification, nine unchanged movement checks and shared geometry/identity checks passed. The sole existing protected membership correction remains exact. No proposed protected source has been applied or tested as an implemented fix.

After approval, focused implementation tests will cover the exact `55 + 21 + 60` fixture and its changing `54 + 21 + 60` snapshot; selected loaded-folder equality and two Common originals; another ordinary catalog egg without Common assumptions; no loaded catalog anchor; unrelated/native-class-mismatched/Generic/malformed members; sparse arrays and nil empty loaded buckets; loaded-flag/parent inconsistencies and read limits; invalid reobserved candidate revocation; multiple qualifying receivers; unknown loaded closer/tied competitors across names; selected missing visual asset; initial versus opened interaction; native price 10 independently observed; storage/cooldown/presentation/account guards; bounded cleanup/Stop/Destroy and zero requests/spending. Expected qualification is queue evidence only, not a mocked private registry or live PASS.

Build, official compilation, the complete suite and separate exact-method/movement preservation checks would run after implementation. Only then would a new zero-spend candidate be committed, tagged on `codex/phase4-test-b`, pushed and anonymously verified. There is no additional diagnostic-only release for this investigation.

## Owner approval gate

Section 5 of the current owner request explicitly says: “Then STOP and request my approval BEFORE applying or publishing that protected-method modification.” The addendum repeats: “If the correction requires a protected-method change, show me the minimum diff and wait for approval before applying or publishing it.” This owner gate applies to EnsureChunkerObserver and the complete proposed native-observation/interaction scope above; it is not an inferred skill restriction.

Approval is requested for this exact three-method patch and its pure classifier, followed by focused tests and immutable zero-spend preflight publication. It would authorize no hatch, equipment action or spending. All movement, physical discovery/selection, Brain/scheduler handoffs and Test A travel remain frozen. AUTO_HATCH/AUTO_EQUIP/owner allowance remain false, authorized account ID and all budgets remain zero. The next paid hatch and Phase 4 approval remain separate owner decisions.

## Subsequent owner approval — October 13, 2026

The proposal above preserves its historical pre-approval state. The owner subsequently authorized the exact linked patch and shared classifier in the direct message **APPROVED — PHASE 4 NATIVE EGG RECEIVER CLASSIFICATION REPAIR**: “I approve implementation of the narrowly scoped three-method proposal described in `docs/PHASE4-RECEIVER-CLASSIFICATION-PROPOSED.patch`, together with its shared classifier.” Approval covers EnsureChunkerObserver, RecordNativeEggUpdate and the documented native visual prerequisite in NativeEggRangeEligible, plus tests and zero-spend publication. It grants no broader protected change or paid hatch.

The applied differences are recorded separately in [PHASE4-APPROVED-CLASSIFICATION-CORRECTION.json](PHASE4-APPROVED-CLASSIFICATION-CORRECTION.json). Exact whole-file verification against the approved patch supplements method hashes; the original Test A manifest and prior sparse-membership record retain their original bytes. Publication and owner-test status belong to [PHASE4-RECEIVER-CLASSIFICATION-DELIVERY.md](PHASE4-RECEIVER-CLASSIFICATION-DELIVERY.md), not a rewritten claim that the new observation methods are identical to earlier builds.

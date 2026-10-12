# Focused Studio source recheck and corrected local delivery

**2026-10-12 publication note:** migration preserves this dated inspection record.
The 38 raw third-party source extracts linked below remain in the local workspace
and recovery copy, with original names/paths/hashes in `LOCAL_FEATURES_DELIVERY.json`;
they are excluded from public Git publication because redistribution permission
is undocumented. [Public evidence coverage](local-feature-studio-evidence/README.md)
explains what is included. This migration makes no new Studio inspection or gameplay claim.

Date: 2026-10-11. Final build **005f77211830** supersedes local build a4e17c439309. Status: **OFFLINE CHECKS PASS / OWNER GAMEPLAY VERIFICATION PENDING**. Use the same [paste-ready file](../dist/OC.local.lua), with `TEST_MODE = "NONE"` initially. The four independent A/B/C/D presets and first-test one-box allowance remain; no GitHub code is downloaded.

## Connection and inspection scope

After the owner enabled MCP, `list_roblox_studios` returned Studio `681d6e17-4b4e-443e-8997-73c126b5e682`, labeled `place 85896571713843 Bubble Gum Simulator INFINITY.rbxl`. `get_studio_state` reported **Edit**, with Edit as its only available DataModel. The label is a file/session identifier; it does not independently prove the live game PlaceId, active server version, received player profile or gameplay acceptance.

The earlier delivery's empty discovery result was accurate at that time. This follow-up reused its research, then read only the source/interfaces needed to resolve the documented gaps. No complete research restart occurred. Source exports retain returned line numbers and omit explicitly identified encoded-bytecode comments; they are text evidence, never executed. Saved-scene geometry is evidence of the Edit copy, rather than an observed owner arrival.

- Root: complete semantic `ReplicatedStorage.Client.Gui.Frames.Playtime` and `Shared.Data.Playtime` bodies (2 source reads; encoded line 4 omitted).
- Rewards review: four complete source fetches; PhysicalItem and PhysicalItem.Gift fully semantically reviewed, ClientScript and Inventory reviewed at the complete relevant callbacks/functions. Saved two full semantic bodies and two caller extracts.
- Travel review: five unique scripts, 13 source reads; two complete semantic bodies and three scripts read at relevant ranges. Also two targeted tree searches and two Root/Prompt property inspections. Saved nine source excerpts and one geometry JSON.
- Input review: 23 source reads/excerpts across 15 exact native paths, plus a literal-key search record. These targeted excerpts cover input dispatch, profile bindings, AFK/report handling, hatch status, GUI state and gift conflict guards. This is not a claim of exhaustive review of every game's input callback.

All retained evidence and file hashes are listed in [the current delivery manifest](LOCAL_FEATURES_DELIVERY.json). Studio received no Luau execution, module require, object/script mutation, input/navigation command, installation or play-state change. Only the owner runs gameplay tests.

## Corrections supported by fresh source

### Ordinary Mystery Boxes

The initial adapter assumed a Model and `component.Name`; native [PhysicalItem](local-feature-studio-evidence/PhysicalItem.source.txt):49–90 instead clones an asset BasePart, assigns **gift ID** to its Name, and constructs a component whose [fields](local-feature-studio-evidence/PhysicalItem.Gift.source.txt):60 include Model/InRange/Animating/HitCount but no item Name. `GetActiveGifts()` returns **loaded Instance → component** entries, while `GetActiveObjects("Gift")` counts all registered gifts.

The public [RenderGifts callback](local-feature-studio-evidence/ClientScript.RenderGifts.source.txt):1894–1905 receives ID → {Name, Position}. AccountStateReader now observes that existing signal through its dependency cache, once per reader lifetime when ordinary boxes are enabled. The callback only validates and records received facts, queues the ordinary reader refresh, and never dispatches gameplay. Its connection disconnects with reader destruction. A unique reader epoch and increasing revision distinguish a newly received identity from stale/replayed data; conflicting or malformed identity makes the observer unavailable.

The mechanics adapter now joins those facts to the exact loaded BasePart/component and retained pending ID. Both native `component.InRange == true` and horizontal distance ≤15 are required before native Hit(self). Total registered count controls pre-open and completion checks, so unloading a gift cannot simulate finishing it. New facts from another reader epoch cannot authorize hits for an old uncertain operation. A previously proved gift's total disappearance can still be observed, but consumption and visible reward delta are also required before continuation.

The reserve, persistent request allowance and one-box operation remain. The first test permits at most one owned ordinary box; no purchase, rare/event/Infinity gift or synthetic screen click was added. Missing or missed identity after an attempted opening retains uncertainty and blocks another consumption. Native [Inventory](local-feature-studio-evidence/Inventory.AutoMysteryBox.source.txt):239–267 confirms total-count guarding and UseGift arguments; its loop was not imported.

Native Hit eight defers Collect, which later sends ClaimGift and destroys its visual component. OC stops initiating new hits on Pause/Stop, but it cannot cancel an already triggered native deferred effect or recall an accepted server request. Visual disappearance does not prove server reward receipt.

### Selected-egg travel

[ClientScript model registration](local-feature-studio-evidence/EGG_RENDER_AND_MODEL_REGISTRATION.source.txt) attaches the initial engine prompt to the egg's **Prompt** part. Its initial distance is 6.5. The opened-egg scan uses **Root**, range 16, Unlocked, nearest-egg selection and the public `ProximityPrompt.Visible == 0` counter.

[Saved Common Egg geometry](local-feature-studio-evidence/COMMON_EGG_PROMPT_GEOMETRY.json) contains two original copies whose Prompt positions differ from Root by about 2.87 studs. Therefore, being within 6.5 of Root alone did not establish the initial prompt range.

The manager now uses actual Prompt geometry for unopened range, with a present/enabled engine prompt, finite activation distance and the inspected line-of-sight setting. Opened range uses Root plus known zero prompt counter, Unlocked and conservative nearest-unlocked-egg checks. Standing candidates and the final direct-position check use that same actual range origin. Target/prompt replacement, geometry changes, mode changes or unavailable eligibility halt the lease. Stable arrival also rechecks current presentation/input guards before logging HATCH_RANGE_OBSERVED.

The native island Teleport path remains the verified canonical Spawn path. Direct CFrame positioning remains explicitly configured and bounded to one selected task; no unlock, hatch, spending, event chase or pickup navigation was added. WorldUtil's current-world helper uses nearest horizontal world spawn; it is not server membership proof. Corrupt WorldMap unlock reconstruction is not used as independent server validation.

### Anti-AFK

[AFKReport](local-feature-studio-evidence/AntiAFK_ReplicatedStorage_Client_AFKReport_605-685.source.txt):638–649 ignores MouseMovement and None. The prior mouse-only method therefore had no source basis for resetting this native activity handler. The corrected Config accepts only **VIRTUAL_INPUT_SCROLL_LOCK**, a protected-call keyDown/keyUp pair; Space and R remain excluded.

The scoped native search found no literal ScrollLock binding. Because [key selection](local-feature-studio-evidence/AntiAFK_ReplicatedStorage_Client_Gui_Frames_Settings_315-375.source.txt):331–347 is customizable, the guard additionally reads fresh received Settings and blocks a ScrollLock assignment. This excludes inspected native bindings, not every possible Roblox/OS/default or external-script binding.

[AFKReport:Get](local-feature-studio-evidence/AntiAFK_ReplicatedStorage_Client_AFKReport_226-276.source.txt):261–276 exposes pending Pets. The guard blocks pending/unknown results and visible AFK/AFKReveal UI, plus typing, native hatch/pet/location ownership, game UI, real held input, locked camera, out-of-viewport cursor and **all registered gifts**, including unloaded ones. The adapter rechecks positive scheduler owner/generation after potentially yielding guards.

A possible held key is tracked before keyDown. KeyUp runs synchronously after success/failure and on Pause/Stop/Destroy. A failed release preserves that record and blocks another keyDown. Reload keeps the prior controller reference and blocks replacement/start until its tracked release succeeds; it does not silently discard a possibly held input.

VirtualInputManager is an internal API. Runtime method/enum presence, permission, actual key release and native input reception still require owner testing. API acceptance does not prove LocalPlayer.Idled reset or long-duration effectiveness. The native [AFK script](local-feature-studio-evidence/AntiAFK_StarterPlayer_StarterPlayerScripts_AFK_1-complete.source.txt):71–130 attempts auto-rejoin after 720 seconds and stops retries on InputBegan, so an accepted pulse may affect that native retry lifecycle. No guaranteed or undetectable operation is claimed.

### Playtime

Fresh [Playtime UI source](local-feature-studio-evidence/Playtime.client.source.txt):99–135 agrees with elapsed Time.now()-Start and sparse string-keyed claim state. Lines 394–404 agree with the received Playtime upgrade; 41–43 exclude Trading Plaza. Lines 369–376 call InvokeServer("ClaimPlaytime", index). Fresh [data](local-feature-studio-evidence/Playtime.data.source.txt):37–40 agrees with all nine thresholds. No eligibility change was necessary.

Bulk ClaimAllPlaytime exists, but this scoped implementation still uses individual eligible indices and received claim acknowledgement. Source/UI contracts do not expose server-only validation, durable save/reset behavior or prove reward receipt.

## Validation and preservation

`node scripts/build.mjs` and `node scripts/test.mjs` pass. Final build: **005f77211830**. The official Luau compiler, 409 main-suite cases, existing examples, actual initializer, exact Config/header/embedded-bundle equivalence and all five local presets pass. The 321 preexisting cases remain; 88 local-feature cases comprise 17 travel, 33 rewards, 25 anti-AFK and 13 integration cases. The actual initializer additionally tests failed-release replacement blocking and subsequent cleanup retry. [Saved final test output](verification/local-features-studio-recheck-2026-10-11.txt) is offline evidence only.

The first aggregate run exposed a synthetic gift fixture missing the exact dispatched pending state required by the strengthened guard. Only the fixture was corrected to model the real pending operation; the final full suite then passed.

Before follow-up gameplay edits, another full recoverable snapshot was saved outside the checkout as `OC_before_studio_recheck_fix_a4e17c439309.zip`, with exact non-Git ZIP-entry hashes (213 entries) and Git history included. It supplements the original preimplementation baseline. Both research libraries remain byte-for-byte preserved (60 Stage 1 +44 Stage 2 files), and Git HEAD remains unchanged. All code and bundle changes are local/uncommitted; no GitHub synchronization or publication occurred.

## Owner test entry

Open **C:\Users\rmger\Documents\ChatGPT\roblox app\dist\OC.local.lua**. Select A_TRAVEL with an exact permanent SELECTED_EGG, B_PLAYTIME, C_ONE_BOX or D_ANTI_AFK; copy the entire file into the supported test runtime. NONE remains the initial all-actions-off mode. Expected events and full Config/lifecycle details are in [LOCAL_FEATURES.md](LOCAL_FEATURES.md).

Owner results still need to establish actual safe standing/native range, travel acceptance, claim acknowledgements and grants, RenderGifts reception/native box completion, key permission/release/native activity reception, long-duration idle prevention and combined hatching/farming conflicts. Current special/event/premium/Infinity travel eligibility remains manual because its adapter is unverified. No entire phase is marked live-verified.

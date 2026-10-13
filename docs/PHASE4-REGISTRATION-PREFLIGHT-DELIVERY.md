# Phase 4 — zero-spend registration preflight candidate

Build **`926bc78d88af`**, immutable release **`phase4-hatch-926bc78d88af`**, development branch **`codex/phase4-test-b`**. The release tag identifies its exact commit. Source and bundles are published together; anonymous raw bytes and tag/branch/commit identity are verified after push. Publication is a candidate for owner testing, not live Test B acceptance.

## Scope and exact approved difference

The owner approved only native exact-Instance membership detection and zero-spend preflight publication. Native `ReplicatedStorage.Shared.Utils.Chunker:66–75` removes an entry with nil and retains the other keys; its `IsValueLoaded:104–113` enumerates every present value. The protected `ObserveEggModel` now matches that sparse-array contract:

```diff
-            if type(values) == "table" and table.find(values, model) then registered += 1 break end
+            local member = false
+            if type(values) == "table" then
+                for _, value in pairs(values) do
+                    if value == model then member = true break end
+                end
+            end
+            if member then registered += 1 break end
```

[PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json](PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json) records the owner approval, complete before/after method texts, exact diff and new hash. The historical [Test A manifest](PHASE4-TEST-A-PRESERVATION.json) retains all original hashes. The preservation verifier validates all ten historical checks, nine unchanged current checks, and the exact approved method transformation separately. It rejects a forged hash or any broader method/helper edit.

The complete EggTravelManager, GameMechanics, OCBrain, TaskScheduler and Test A loader remain byte-identical to commit `25890f224f0448f148d009e65514c129aeb4f59c`. Physical discovery/selection, Root/Prompt geometry, floor/collision/standing/CFrame behavior, scheduler movement ownership, stable arrival and bounded attempts remain the owner-approved behavior. The passive window remains five seconds. No further protected-method change was made.

The unprotected diagnostic/reader work reports exact receiver observation and rejection states, reads all present members of a native sparse array, quotes native account-specific price independently of registration, and exposes throttled preflight status with debug OFF. Reporting uses a separate stable ID namespace and cached observations so it cannot change physical tie ordering or force a scan. Native membership, geometry, all-name nearest scanning, visibility, ties, cost, current account, storage and cooldown guards remain required. No native Update is invoked to force an observation.

**The cause of the owner's earlier live receiver-capture failure remains unproven.** Correcting a demonstrated sparse-array bug is not evidence that that particular session used sparse arrays or that receiver capture will now succeed. Missing native evidence remains blocked with the precise passive observer state. See [PHASE4-REGISTRATION-OBSERVATION-EVIDENCE.md](PHASE4-REGISTRATION-OBSERVATION-EVIDENCE.md) for the fresh Notion/native source reads and exact supporting files from both completed research libraries. All 104 completed research files are preserved.

## Owner test

Run only OC in the same authorized client test environment that supports the previously approved loader. Position near the intended physical Common Egg before loading. The unchanged TRAVEL_ONLY capability may make at most one bounded approach when needed; if already in stable physical arrival range, zero direct attempts is expected. This loader enables neither a hatch nor spending nor equipment.

Keep debug OFF and leave every authorization/budget value below unchanged. Do not manually click Buy or enable native auto hatch while collecting this isolated preflight log. Wait for the first preflight decision and the final observer state after the five-second window; allow account/dependency loading and owned-team analysis to finish. Approximately 20–30 seconds is normally enough for an initial log, but the readiness line—not elapsed time—is the evidence. If no preflight appears, return the available dependency, physical arrival and blocker lines rather than assuming readiness.

Return the `[OC][INIT]` build, selected actual Instance ID and physical arrival line, the final `[OC][HATCH_PREFLIGHT]` line with price and registration counters/rejections, and whether the character remained correctly placed. Every report must retain hatch requests=0 and requested spending=0. A blocked registration is a useful diagnostic result; do not retry a paid action or replace the target to bypass it. Pause/Resume/Stop remain available through the existing OC controls. A successful readiness report still grants no paid hatch authorization.

Expected conditional output (IDs, prices, counts and distances below are runtime fields, not promised values):

```text
[OC][INIT] ... build=926bc78d88af
[OC][EGG_TRAVEL] ... PHYSICAL_TARGET_RESOLVED ...
[OC][EGG_TRAVEL] ... PHYSICAL_ARRIVAL_OBSERVED ... direct attempts=<0 or 1>
[OC][HATCH_PREFLIGHT] HATCH_PREFLIGHT_READY_ALLOWANCE_OFF ... native price=<native quote> Coins ... interaction=OPENED_NEAREST ... registration=CURRENT_EXACT_REGISTRATION_OBSERVED ... hatch requests=0; requested spending=0
```

If registration or another guard fails, the last line instead reports `HATCH_PREFLIGHT_BLOCKED` with actual observations such as `TIMED_OUT_BEFORE_ANY_NATIVE_UPDATE`, `TIMED_OUT_WITHOUT_QUALIFYING_EGG_RECEIVER` plus exact rejection reasons, `MULTIPLE_QUALIFYING_EGG_RECEIVERS`, selected-instance unload/replacement, a closer/tied registered original, or unknown price. Physical arrival is reported independently. An unopened account uses the separate exact cached initial Prompt path. The remote's hidden server selection, accepted hatch and durable rejoin persistence remain unverified.

## Complete safe loader

The published copy-ready loader is [examples/Phase4TestBPreflight.luau](../examples/Phase4TestBPreflight.luau). It pins the following anonymous bundle:

https://raw.githubusercontent.com/Whispfl/automation-/phase4-hatch-926bc78d88af/dist/OC.lua

AUTO_HATCH and the exceptional allowance are false; account ID is zero; hatch, session, allowance, upgrade and world-purchase cost ceilings are zero. Equipment, upgrades, purchases, farming, pickups, bubbles, selling, rewards and anti-AFK are disabled. The prepared ONE_HATCH file remains disabled and is not the loader for this test. Test A `phase4-travel-0d5caa499c8c` and previous Test B `phase4-hatch-59c475d125c2` remain independent immutable pins.

## Verification and publication

`node scripts/build.mjs` produced build `926bc78d88af`. `node scripts/test.mjs` passed official Luau compilation, **623 main-suite cases**, **13 exact-approval/preservation checks**, initializer/Config isolation and safe/prepared example guards. The actual-knowledge identity file passed 48 cases, including source-valid sparse membership and invalid replacements/unloads/competitors. No real game actions were executed by these synthetic tests.

`scripts/verify-test-a-preservation.mjs` verified all **10 original historical hashes**, **nine unchanged current checks**, the **one separately approved exact method transformation**, and unchanged shared geometry/identity helpers. The original historical manifest remains byte-identical; its hash is `22b156775d41f1528e3c1441cec407192cebef8a972d3429a403e4474747075a`. The approved method's new hash is `ece9abde1eb24fa01041a8d73ce5340ea075eca3d52b7b25aeed07dbb0aaedf1`. All **104 research files** remained byte-identical to their pre-edit snapshot, and `git diff --check` passed.

After push, `scripts/verify-public.mjs` checks the new branch/tag/commit and complete public Git tree, anonymous raw bytes of the bundle/examples/source/preservation records, and the unchanged Test A and previous Test B tags/artifacts. Its verification output accompanies the owner delivery. These checks establish local correctness and publication only. The owner remains the sole live tester; Test B and Phase 4 are not marked approved or complete.

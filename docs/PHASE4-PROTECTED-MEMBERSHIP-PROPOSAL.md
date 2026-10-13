# Proposed protected exact-membership repair — awaiting owner approval

This is a reviewable proposal, not an applied change. `ObserveEggModel` and every Test A preservation hash remain unchanged. No new commit, tag, push or loader has been published for this investigation.

The owner explicitly requires: “If a protected-method edit was unavoidable, STOP before publishing it and request explicit owner approval, with a narrowly scoped diff proposal.” This gate applies to the method below, which is protected by `docs/PHASE4-TEST-A-PRESERVATION.json`.

## Demonstrated dependency

Current native `ReplicatedStorage.Shared.Utils.Chunker:66–75` removes an entry by assigning its index to nil. Remaining indices need not be consecutive. Native `IsValueLoaded:104–113` and `Update:146–150,159–163` iterate all present entries. Official Luau reproduction confirms that `table.find({[2]=selected,[5]=other},selected)` returns nil. The current protected `ObserveEggModel` instead uses `table.find` and can deny exact loaded membership after a native removal.

The authorized, unprotected `NativeRegisteredEggModels` reader now enumerates present entries with `pairs`, retaining positive integral key, Instance, Model, exact receiver-folder, Workspace, geometry and bounded-entry checks. However, hatch eligibility first passes through `ResolveEggInstance` → protected `ObserveEggModel`. The second reader cannot repair that earlier identity denial, so sparse selected membership remains explicitly blocked.

## Minimum proposed source diff

File: `src/OCFoundation/GameKnowledge.luau`, method `ObserveEggModel`. Replace one membership operation only:

```diff
         for coord in pairs(receiver._loaded) do
             local values = receiver._chunks[coord]
-            if type(values) == "table" and table.find(values, model) then registered += 1 break end
+            local member = false
+            if type(values) == "table" then
+                for _, value in pairs(values) do
+                    if value == model then member = true break end
+                end
+            end
+            if member then registered += 1 break end
         end
```

This uses actual Instance equality, matching native enumeration. It keeps the current receiver validation, exact parent-folder comparison, loaded-coordinate iteration, physical interface and geometry checks, receiver-count ambiguity, five-second observation deadline and post-window verification policy. It neither calls native Update nor modifies a native array, selects a different target, changes Root/Prompt calculations or moves a character.

Only after explicit approval would the one corresponding `ObserveEggModel` hash be updated to record that approved exception. The baseline commit, nine other checks and both existing immutable pins would remain unchanged. The regression that currently documents the sparse selected-instance blocker would then require successful exact identity for that source-valid member, followed by the existing all-name nearest/tie/unload safeguards. Build, complete official regression suite, preservation verification, commit/tag/push and anonymous raw verification would follow before delivering a pinned zero-spend candidate.

## What this proposal does not establish

The owner's exact final unavailable/ambiguous reason implies incomplete accepted-receiver evidence. A sparse `table.find` miss inside one fully accepted receiver does not by itself produce that same final reason. The available live log cannot distinguish no observed Update, rejected receivers, multiple qualifying receivers or later changed receiver state. Fresh source shows recurring native Update every 0.25 seconds when a character Root exists; preinitialized registration alone is not evidence that a longer window is needed. No timeout extension is proposed.

The local read-only counters and price/logger corrections supply those missing distinctions for a later owner test, while retaining strict blockers. Approval of this diff authorizes neither a hatch nor spending. AUTO_HATCH, the exceptional allowance, budgets and the prepared one-hatch loader remain OFF. Movement remains the owner-approved Test A behavior. See [the source evidence report](PHASE4-REGISTRATION-OBSERVATION-EVIDENCE.md) for exact native/research references and the accessible-source limitations.

## Subsequent owner approval — October 12, 2026

The proposal above is the historical pre-approval state. The owner subsequently approved this exact membership-only replacement and zero-spend preflight publication in the direct message “APPROVED — NARROW PHASE 4 PROTECTED-METHOD CORRECTION.” The historical Test A preservation manifest is unchanged. The approved before/after method text, exact diff and new hash are recorded separately in [PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json](PHASE4-APPROVED-MEMBERSHIP-CORRECTION.json), and the released candidate is described in [PHASE4-REGISTRATION-PREFLIGHT-DELIVERY.md](PHASE4-REGISTRATION-PREFLIGHT-DELIVERY.md). No broader protected edit, movement change or paid hatch was approved. The sparse-array correctness repair does not establish the cause of the owner's earlier live receiver-capture failure.

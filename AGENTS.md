# OC development rules

Use ReplicatedStorage first to understand every new feature: inspect the relevant
Assets, Client, Remotes and Shared definitions/behavior/interfaces before coding.
Keep evidence and uncertainty explicit; a remote's existence is not a verified contract.

Responsibilities: ReplicatedStorage provides game knowledge; the verified LocalData
service provides player/account facts; Workspace provides live spawned objects,
positions, geometry and interaction/navigation state. Server-only rules remain
unavailable unless supported behavior is observable and owner-verified.

Reuse GameKnowledge and the existing reader dependency cache, world observations,
mechanics adapter, verification and central OCBrain/TaskScheduler. No competing
automation loops. Preserve owner-tested Phase 1, bubbles, selling and teleportation;
make incremental changes when they address a demonstrated problem or new feature.

Roblox Studio tools are strictly read-only. Do not insert, modify, remove or install
scripts/objects, execute Luau there, or change Studio play state. Code lives in this
GitHub repository. Maintain central OCConfig.luau, existing UPPER_SNAKE_CASE settings,
and a function-returning single dist/OC.lua accepting custom Config. Client loaders
use the public raw URL without tokens, headers or authentication.

After each fix run node scripts/build.mjs and node scripts/test.mjs, commit/push
source and bundle, verify the public raw artifact, and give the owner the Config
and simple loadstring plus checks. Offline tests/source inspection are not live
gameplay verification. The owner performs all in-game testing. Phase 2's agreed
stationary farming scope is owner-approved. The owner explicitly authorized Phase 3
island/world progression; new unlock/travel actions remain pending live verification.
Advanced hybrid farming is deferred to Phase 9. Do not implement Phase 4 without
explicit approval. The owner confirmed the connected Game session
as the new saved workspace; MCP cannot independently expose its actual PlaceId.
Retained Fall catalogs are not proof of an active event; the owner reports Halloween.

Future phases follow docs/ARCHITECTURE.md and require inspection of each feature's
native interfaces, prerequisites, results and stop conditions before implementation.

## Action-First Development Policy

This is a permanent owner instruction applying to all current and future OC phases.
This policy takes precedence over conflicting development guidance; all compatible
existing instructions remain in force.

**Primary workflow:** Build → Offline verification → Publish → Owner live test → Fix observed failures → Move forward.

**Rules:**

1. Prioritize functional gameplay capabilities and real owner-tested milestones over planning-only deliverables.
2. Reuse the completed ReplicatedStorage and wiki research libraries. Do not repeat broad research.
3. Research only specific unknowns that materially block implementation.
4. Every development assignment should have a concrete implementation or blocker-resolution objective.
5. Batch related implementation, tests and corrections to reduce unnecessary approval cycles and usage.
6. Preserve existing One Brain, TaskScheduler, GameKnowledge, mechanics adapters and working releases.
7. Keep documentation concise: record essential evidence, implementation decisions, limitations and release pins.
8. Run required compilation, regressions and safety tests before publishing.
9. Offline tests never count as live gameplay acceptance. The owner alone performs Roblox live tests.
10. Ask for approval when a new protected-method change or previously unauthorized gameplay action requires it. Never assume permission for spending, purchases, destructive actions or repeated attempts.
11. After verification, provide a complete usable loader and clear owner-test instructions whenever a live test is authorized.
12. Avoid planning-only milestones, speculative investigations and unnecessary diagnostic builds unless a demonstrated blocker requires them.
13. Report concisely: what works, what failed, what was published, and the next concrete action.

**Priority:** Get OC reliably performing useful gameplay actions while maintaining necessary safety and verification.

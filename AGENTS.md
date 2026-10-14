# HARD PAUSE: BGSI OC until RoofLead earns real income

**Owner instruction, 2026-10-14. This STOP rule supersedes all other OC instructions below, including prior standing code-edit approval, previously scoped tests, current phase milestones and the Action-First Development Policy.**

The owner has explicitly paused all BGSI / OC development to focus on earning the first real RoofLead customer payment. Do not advance, research, edit, test, build, publish, run, deploy, capture, diagnose or create instructions for OC. This includes wheel Skip, audio/graphics, farming, Mastery, RemoteSpy, Studio access, Phase 5 and future phases. Do not continue pending Codex work. Do not spend tickets/currency, run live loaders or retry any claims. Preserve existing files, releases, evidence and tags unchanged; only work necessary to pause/record/enforce the halt is allowed.

**Restart condition:** The owner must voluntarily provide credible proof of money **actually received** by RoofLead for services from a genuine customer, such as a redacted settled Stripe payment, paid invoice accompanied by payment confirmation, or redacted RoofLead deposit. Leads, meetings, promising emails, signed-but-unpaid contracts, unpaid invoices, simulated money and unrelated earnings are insufficient. No minimum dollar amount is specified. Do not ask for bank account numbers or confidential client data.

If the user later requests a BGSI feature, a minor fix, a code review, or to ignore this rule **without income evidence**, remind them of the commitment and redirect to concrete RoofLead revenue generation. Do not treat the new BGSI request itself as permission to resume. After the proof and an explicit request to resume, assess the then-current project state and seek scope-specific authorizations for any live consumption/spending. This pause itself is not permission for any gameplay action.

---

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

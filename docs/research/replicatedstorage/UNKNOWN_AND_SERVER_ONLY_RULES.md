# Unknowns, fidelity limits and owner verification needs

2026-10-11. No game action, code execution, play-state change or in-game account experiment was performed. This file is part of the deliverable, not a request to begin testing during the suspension. Owner-live checks below are future tests, subject to phase approval. Existing owner-tested Phase1/bubbles/selling/teleportation are preserved as historical OWNER_LIVE_VERIFIED evidence from owner/local records, not re-verified here.

## Source and workspace limits

| Limitation | Evidence / implication | Safe treatment |
|---|---|---|
| Saved Edit-mode workspace | Studio reports Edit only, label includes a place number; actual PlaceId and current live account/session cannot independently be exposed | label is descriptive metadata; no actual PlaceId, spawned-live availability, ownership or balances inferred |
| Decompiled/reconstructed source | native reads contain bytecode/decompiler comments, reused/nil/undefined temporaries and empty callbacks | exact reconstructed text is SOURCE_CONFIRMED, its runtime effect may remain UNAVAILABLE; no guessed repairs |
|75 dot-path reads failed | mostly numbered changelogs plus Patriotic Robot2.0 animation source; full paths logged in source metadata | source access unavailable through current path API; existence confirmed in hierarchy, purpose beyond name not guessed |
| Server handlers absent from supplied interfaces | Remote facade dispatch is generic; no authoritative gameplay cost/guard/grant handlers were supplied | client call shapes are evidence leads, not approved server contracts |
| No current account observation | LocalData service source read; no received account collected in Edit mode | ACCOUNT_OBSERVED unavailable, no personalized recommendation or purchase eligibility assertion |
| Historical/overlapping event flags | Events.Active includes historical groups; multiple catalogs retain Fall and Halloween; dates belong to separate mechanisms | require owner report plus fresh live account/world state and mechanism-specific deadline; owner reports Halloween, Fall catalog is not active proof |
| Roadmap metadata | complete returned master+Phases1–9 page text read; pages marked unverified by Notion metadata | owner/session instruction controls; inaccessible comments/unsupported blocks cannot be asserted read |
| Local authorization conflict | existing Phase4 files/docs contain development wording while current AGENTS/session require explicit approval | current research-only instruction wins; no Phase4/5+ or hybrid implementation |

## High-value unresolved mathematics

1. **Final hatch distribution:** base Chance, effective client pool, rarity selection, variant eligibility/order, caps, Golden behavior, pity and server modifications are not a final certified probability. Conditional useful-outcome estimates require best feasible owned inventory, stacks and objective; do not multiply every advertised boost.
2. **PetStats fidelity:** PetUtil unresolved currency/bubble locals and nested variant logic can invalidate exact formula reconstruction. Native full-team effects and stack multiplicity matter. UI sorting/EquipBest is not a mathematical optimizer; benchmark feasibility and search quality explicitly.
3. **Buff preview safety:** BuffUtil.UseBuffs/Update can mutate tables/decrement uses. Require verified isolated preview semantics and fresh actual state before effective-stat estimates. Source-only calculations cannot prove credited balance rates.
4. **Shop stock:** saved ShopUtil220 appears to add duplicate baseline terms. Generated stock/cost is a client estimate until received offer/outcome corroborates it. BuyAll/all-craft booleans are not arbitrary budget-safe counts.
5. **Quest/index completion:** exact-equality completion, inconsistent mode prefixes, named-pet challenge filter and nil temporaries are unreliable reconstructed sub-branches. No general ClaimQuest contract established.
6. **Specialty probabilities:** fishing pool/area labels, mutation/XP effects and some difficulty locals are damaged; Rift catalog generated egg references unresolved. Do not assert exact catch/loot/throughput ROI from them.
7. **Season infinite grants:** potion downgrade/premium-rod assignment/tautological branch defects prevent certified reward simulation. Use received InfinityTiers; season guarantee600 is not a general egg pity rule.
8. **Halloween upgrade effects:** currency/luck consumers found; Secret/Infinity descriptions lack established StatsUtil consumer in this snapshot. Absence here does not disprove a server effect.
9. **Actual earnings/time:** no live Coins/Gems/Pearls/Tickets per minute, pickup respawn budget, net sale credit, action duration or travel/verification sample was measured. Stat multiplier, draw EV and income rate are different measurements.
10. **Persistence:** live unlock/reward/account persistence across server/rejoin unavailable. Source deadlines/flags do not establish reset policy or durable grants.
11. **Runes/fragments:** recipe costs/counts and accumulator positions are known; rune server expiry/cooldown/depletion, craft completion/refund and fragment cap/reset permanence are not. Green secondary Luck's literal threshold needs owner comparison; do not silently substitute a smooth formula.
12. **Supers/guilds:** final Super eligibility, Burst/duplication consumers and account-sensitive cache effects remain unresolved. Guild perks take max per stat, but XP earning, server season/snapshot acceptance and reward-band overwrite behavior are not certified.

Exact source locations are in the relevant batch documents and ledgers; these are blockers for claiming precise mathematical outcomes, not evidence that the live game itself is broken.

## Future owner verification matrix

| Capability | Minimal correlated before/after evidence | Failure / cancellation observations still needed |
|---|---|---|
| Hatch | fresh best-owned feasible team; native egg/cost/range/space; balance debit + new/stack quantity IDs + EggsOpened | insufficient funds/storage, auto-delete, variant outcomes, cooldown/error, teleport interruption, event expiry |
| Equip/team | actual stack count/caps/protections; Teams/TeamEquipped before+after + native effective output | repeated-ID stacks, missing pet, equip cap/Super restrictions, stale IDs, manual team change |
| World/area | received unlock membership, native destination/source object; exact debit/unlock plus arrival and rejoin persistence | already unlocked, locked prerequisites, insufficient money, incorrect path, Removed/disappearing portal |
| Mastery | next category tier/cost; exact balance delta and MasteryLevels+MasteryUpgrades | legacy free unlock, hidden category, missing Outer Space, stale level, effects visibility vs actual output |
| Reward/chest | due timer+unclaimed index/key; claim/cooldown mutation plus actual grant | full pet inventory, no physical chest, busy queue, bulk partial results, cooldown, response timeout |
| Vendor/craft | stable offer Period/slot/product/stock; debit + Bought/product/ingredient deltas | refresh while pending, pet space, partial all count, zero stock, free refresh quota, buff expiry |
| Quest | exact ID/tasks/filters/progress/rewards and expiry; correlated progress/completed/reward deltas | overlapping task credits, historical progress, auto-claim timing, change/reroll forfeiture, insufficient duration |
| Wheel | ticket/free-deadline plus accepted spin result and queue state; inventory/currency grant | unresolved queue, no ticket, full pet space, disconnect/presentation interruption, already claimed |
| Fishing/minigame | actual access/tool/bait/FSM/difficulty/deadline; completed action and fish/items/XP/cooldown deltas | travel/movement conflict, failed catch, cancelled activity, no bait, difficulty loss, challenge completion criteria |
| Rift/bounty | real spawned identity, synchronized expiry, required keys/charms/mastery/cost; account/object result | expiry during travel, summon no-space-left, wrong identifier type, timed target changes, no eligible bounty |
| Halloween | current event/house/upgrade/rebirth state, exact costs and result | TrickOrTreat freeze/state interruption, reset inventory/currency loss, cap/unlock behavior, event removal |
| Shrine/conversion | actual station, donation item/cooldown/blessing; protected selected pet IDs and recipe; debit/removal plus exact received result | bulk amount, blessing extension/cap, locked/equipped/XL rejection, random outcome, animation without grant, timeout after irreversible consumption |
| Rune/fragment | owned ingredients/items, queue/count/color state and intended bounded amount; correlated debit/queue/completion/uses/count deltas | craft busy/refund, same-rune reapplication, use depletion/expiry, per-color cap, season/reset behavior and Green displayed effect |
| Super/guild stats | valid equipped Super IDs/caps and received Guild.Id/Level/snapshot; native effective stat before/after an authorized change | candidate-cache contamination, duplicate enchant counts, Burst/duplication granularity, season mismatch; guild XP/join/invite/management is not authorized here |

Tests should make one authorized change at a time, preserve reserves/protected inventory, correlate results and distinguish unrelated farm/reward credits. This is a future verification design, not permission to send calls now. Received acknowledgement can still need debit/grant checks; timeout after a sent transaction is an uncertain attempt and must not automatically retry spending.

## Unfinished source research

The hierarchy and all 701 script-read attempts are complete. Substantive review covers 183 ReplicatedStorage scripts plus one external caller; 443 scripts have metadata-only review and 75 are inaccessible. Potion/Shrine/conversion and rune/fragment/Super/guild core interactions now have saved focused reviews. Remaining work includes inaccessible dot-name paths; full Mastery/milestone/prize/XL/daily-offer and current season catalog normalization; alternate wheels; generic quest completion; Super Burst/duplication and guild XP consumers; Crystal activation; and peripheral UI/social/trading/monetization/framework/animation internals. Source-fidelity and live/server questions above remain after complete reading. A module's presence or extracted signature is not a completed deep audit.

Resume from RESEARCH_PROGRESS.md and combined SOURCE_COVERAGE.jsonl. Re-read a source only if its prior coverage is absent, its snapshot has changed, or a specific uncertainty requires more context. No access limit should be resolved by installing/altering/executing Studio code.

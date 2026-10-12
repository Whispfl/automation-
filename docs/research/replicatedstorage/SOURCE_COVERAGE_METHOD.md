# Combined source coverage method

Research date: 2026-10-11. The manifest is derived documentation, not native source or an executable adapter.

## Inputs and reconciliation

Eight `inventory/source_metadata_*.jsonl` files provide all 701 script paths from the complete ReplicatedStorage inventory. They record full source-read attempts, automated dependency/signature metadata or explicit failures. Metadata alone never certifies semantic understanding.

Four substantive review manifests contribute exact paths and review scopes:

- `catalogs/SOURCE_COVERAGE_ROOT.jsonl`: 52 targeted core reviews.
- `catalogs/ECONOMY_SOURCE_COVERAGE.jsonl`: 50 reviews: 38 complete filtered bodies, two systematic catalog fact extractions and ten targeted reviews.
- `SOURCE_COVERAGE_ARCHITECTURE_NATIVE.jsonl`: 40 reviews: 31 deep core and nine targeted.
- `NAVIGATION_FISHING_SOURCE_COVERAGE.jsonl`: 80 reviews: 67 deep core and 13 targeted.

There are 222 contributions and 184 distinct substantive paths. All 183 reviewed ReplicatedStorage paths match the inventory. The additional native caller is `StarterPlayer.StarterPlayerScripts.ClientScript`, separate from ReplicatedStorage counts. Local OC file review is documented independently and excluded from native counts.

## Union labels

Each combined row retains every original `semanticReviewContributions` entry, manifest and scope. A summary label selects the highest recorded kind in this order: explicit COMPLETE_BODY_REVIEW, SYSTEMATIC_CATALOG_FACTS, DEEP_CORE_REVIEW, TARGETED_REVIEW, otherwise METADATA_ONLY or UNAVAILABLE_SOURCE. This order is bookkeeping, not a quantitative quality score. Systematic facts do not mean a complete behavioral audit; deep core does not imply all visual functions or dependencies were reviewed.

The economic manifest's explicit “complete filtered body reviewed” supports COMPLETE_BODY_REVIEW. “DEEP_CORE” in other manifests is retained as DEEP_CORE_REVIEW, avoiding promotion to a full-body claim. Full fetch, semantic review, derived facts, account observation and accepted server outcome remain distinct.

`SOURCE_CONFIRMED` on a reviewed/metadata row means the saved representation was readable; only contribution scopes and subject documents support specific behavior assertions. Failures retain UNAVAILABLE, with hierarchy evidence separately recorded in metadata. Every combined row marks server acceptance and live account observation UNAVAILABLE because no action/account experiment occurred.

The manifest has 702 rows: 701 ReplicatedStorage scripts and one external caller. `SOURCE_COVERAGE_SUMMARY.json` holds deduplicated totals. `inventory/REMAINING_SEMANTIC_REVIEW.jsonl` lists 518 ReplicatedStorage paths without substantive review: 443 metadata-only and 75 unreadable.

## Anchors and limits

Native anchors are one-based Studio MCP returned lines. Embedded decompiler original-line comments can use different numbering. Bytecode/comments were excluded from semantic excerpts; full source was transient and was not saved in the library.

Saved source can contain damaged variable scopes, empty callbacks or overwritten branches. Complete reading cannot remove those fidelity limits. Duplicate names and decimal dots can prevent reliable addressing through the path API. No Luau execution, require call, path mutation or Studio workaround was attempted.

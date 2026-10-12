# Preserved offline regression records

- `local-features-studio-recheck-2026-10-11.txt`: original 409-case recheck output;
  SHA-256 `384bbf8f093fabf4109ace66092b9fc71b7788266167246e656afc8e5d0978c2`.
- `phase3-historical-last-test.txt`: older 157-case Phase 3 output;
  SHA-256 `83a4ea19df132ae3240767fa31d1a81c3ec3cc4203c9b8cafb19e7d797c97462`.
- `migration-regression-2026-10-12.txt`: migration run, 409 existing suite cases
  plus existing example/initializer/local-preset checks and migration actions-OFF
  Config/default-merge validation; all passed.

These are synthetic offline harness records, reviewed before publication. They
contain no live player/account data or third-party source exports. They do not
prove gameplay acceptance. Full original local tooling and logs remain in the
external recovery copy. Git attributes preserve these record bytes exactly.

The post-push public verification report records the published commit and actual
anonymous Git/raw comparisons outside the committed tree to avoid a circular
self-commit reference. Run `node scripts/verify-public.mjs` to reproduce it.

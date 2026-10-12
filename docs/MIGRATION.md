# Existing OC project migration — 2026-10-12

Destination: **https://github.com/Whispfl/automation-**, branch **main**.
The trailing hyphen is required. Migration is owner-authorized for this repository
only. Existing `main` ancestry is preserved; there is no reset, clean, force push,
mirror push, history rewrite, replacement checkout or new development branch.

## Preserved local state and recovery

Original workspace: `C:/Users/rmger/Documents/ChatGPT/roblox app`.
Baseline HEAD: `114caa4e18e05ba8881a4a93e83470b993273ecc`, 27 main commits.
Build: **005f77211830**, confirmed from current source rather than assumed from an
old report. All current unpublished modules and tests are part of the migration.

Verified recovery copy outside the repository:
`C:/Users/rmger/.codex/visualizations/2026/10/12/01a130dd-af9f-7401-bb12-c35c2c321cd6/OC-recovery-2026-10-12T16-09-47-338Z`.
It contains 1,137 byte-verified files, including 887 Git files, a separately verified
all-refs Git bundle, and a separate copy of 157 required untracked files. Full `.git`
preserves available dangling objects/reflogs as well as branch/tag history. Old
remote configuration and private recovery manifest are stored outside publication.
The original project remains in place. Prior dated recovery/delivery and research
preservation reports were inspected; the prior pre-recheck archive SHA-256 matched
its recorded value. No separately named recovery report was found in the project.

## Coverage and public review

The pre-migration project has 26 Luau source files, 11 examples, 16 test files,
4 build/test/public-verification scripts, `package.json`, architecture/phase notes,
and both `dist/OC.lua` and the self-contained `dist/OC.local.lua`.
No dependency lockfile exists; the package manifest declares no dependencies.
No missing source, bundle, test or research file was discovered in the required scope.

Both completed research libraries are preserved byte-for-byte: **60** files under
`docs/research/replicatedstorage/` and **44** under `docs/research/wiki/`. Attributed
summaries, factual catalogs, source ledgers, known uncertainties and existing
validation/preservation records are retained. Available sanitized offline test
records are published under `docs/verification/`; complete original tooling/logs
remain in the recovery copy.
Research/record Git attributes preserve original line endings and exempt archived
formatting from whitespace lint, so publication does not alter evidence hashes.

Review covered all 27 main commits and their 384 distinct blobs (11,684,554 bytes),
plus all 223 pre-migration tracked/nonignored files. No credentials, cookies,
private keys, private account dumps/support correspondence, unrelated projects,
or sensitive-history condition requiring a history rewrite was found. Available
Git author addresses are noreply. Benign local paths in original evidence records
are retained as historical provenance.

**Excluded:** 38 untracked raw third-party `.source.txt` extracts, 178,725 bytes,
under `docs/local-feature-studio-evidence/`; no redistribution permission is
documented. They remain locally and in recovery. The authored `AntiAFK_KEY_SEARCH`
search log, geometry JSON and Mystery Gift summary are included. Original native
paths, line citations and file hashes remain in the authored delivery/recheck
records. See [evidence boundary](local-feature-studio-evidence/README.md).
Ignored `.tools/`, `.test-output/`, `node_modules/`, secret environment files,
backup archives, private remote configuration and `.git` as ordinary files are
excluded from publication. No other local branches or old tags are pushed;
they remain fully backed up. A new lightweight `migration-005f77211830` tag pins
this migration commit so the two egg examples and migration check load the exact
matching bundle rather than `main`.

## Migration-only changes and checks

Operational public URLs/current setup references use `Whispfl/automation-`.
Historical commit/build citations, old delivery statements and unrelated source
links are retained. New publication verification compares remote main/pin SHA,
every Git file path/blob hash, and representative raw source/research/config/
example/bundle bytes anonymously. It saves actual results and the published SHA
to `.test-output/migration-public-verification.json` after publication; an external
copy accompanies the final owner delivery.

Run `node scripts/build.mjs`, `node scripts/test.mjs`, then, after publishing,
`node scripts/verify-public.mjs`. The migration verification example explicitly
disables every gameplay action and is checked after central default merging.
The migration build and regression run passed: static/deterministic bundle checks,
official Luau compilation, all 409 existing main-suite cases, all existing example
Configs, the initializer/reload checks, five local presets and the new migration
Config isolation check. Saved records are in [verification/](verification/README.md).
Rebuilding uses the backed-up current source and preserves **005f77211830** and
both original artifact hashes:

- `dist/OC.lua`: `d8fe5f16a6d9559c8605f92a9985ebfd0c7a1ee349a90a894b0d2ac6ecf4cc41`
- `dist/OC.local.lua`: `1126779130e6d11e2336bed6f9aba16e25148e5b97eda39798a4d5a8974822cc`

## Status carried forward

- Preserve the owner-confirmed owned-team result at build `90ce16e63ccd`:
  native score 117 → 1586, protected Shiny Ice Kitty, frozen seven-pet membership
  and no repeated swaps. This is equipment evidence, not a measured income rate.
- Phase 3 paid world unlocks, automatic gate approach, actual leave/rejoin
  persistence and later-world routes remain open.
- Hatching, selected-egg travel, reward receipt/box completion and anti-AFK
  permissions/release/long-duration operation remain subject to owner gameplay tests.
- **User reported playtime auto-claim failure — awaiting investigation.**
- Full Phase 4 completion and Phase 9 hybrid integration are not implied by migration.

Notion master roadmap, Phase 4 and Phase 9 were freshly fetched and read, including
their owner notes; discussion requests returned no discussion content. Phase 5's
relevant owner/reward notes were also read. Search returned phase pages rather than
a separate latest-owner-note page. Their native verification state is unverified;
the explicit migration request is the current scope authority.

No Roblox Studio tool or gameplay execution is part of this migration. Offline
checks and publication parity do not establish live gameplay success. The owner
runs the supported Config/loader and provides future acceptance evidence.

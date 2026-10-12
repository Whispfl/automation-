# Primary Stage2 evidence validation

Validated2026-10-11. **PASS_WITH_EXEMPTIONS: no outstanding structural/reference errors.** Scope is the eight primary source/claim JSONL files in `evidence/`; aggregate indexes and the truth of gameplay claims were not audited here. Full checks, file SHA256 snapshots, exact reference results and exemptions are in [PRIMARY_EVIDENCE_VALIDATION.json](PRIMARY_EVIDENCE_VALIDATION.json).

| Namespace | Sources | Claims |
|---|---:|---:|
| EGG |13|48|
| MASTERY |22|53|
| WORLD |32|36|
| ROOT |16|16|
| Total |83|153|

All236records parse; IDs are unique; required metadata/claim fields are present; source joins resolve; all classifications belong to the eight allowed values. Arrays and nonempty text fields were checked. All257URL values are syntactically valid absolute HTTP(S) URLs and claim URLs match their joined sources. Syntax validation does not establish access or current content.

Against the saved701script inventory,230script references have exact valid paths and numeric bounds covering358cited spans. The inventory has626fetched metadata records and75unavailable records; unavailable diagnostic counts were not treated as source bounds. Two references to the external native ClientScript use the supplemental complete-fetch record's3323last line. Bounds do not prove semantic review or claim support.

All233Stage1 document references resolve, including89heading anchors across12unique target documents. Five new-source references point to the existing Stage2 reward-strategy document. Author path conventions were resolved explicitly; Markdown heading slugs were compared locally.

One actionable error was found and corrected by the root researcher: R-C006 cited `ReplicatedStorage.Client.Gui.RebirthMachine`; the actual path is `ReplicatedStorage.Client.Gui.Frames.RebirthMachine`,1013returnedlines. Final primary record was independently re-read; cited195–208,426–428,742bounds fit.

Eight Workspace property references are exempt from script inventory/line validation. They cover island folders, sell-model summaries, two gates, board nodes and R-C004's explicitly labeled property summary. This does not certify exact leaf-instance identity or property values; R-C004 remains a summary rather than an exact instance path. Both Roblox listing records R-S004/W-S012 now retain unknown revisionDate and label2026-10-11separately as experienceUpdatedDate.

Only these two validation artifacts were written. No primary ledger, Stage1 file, gameplay/source/configuration, Studio state, build/test, Git or network operation was changed or run. This result validates references and record integrity; it certifies no server rule, final odds, account state or live action acceptance.

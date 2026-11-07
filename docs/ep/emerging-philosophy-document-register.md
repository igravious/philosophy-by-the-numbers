# Emerging Philosophy — document and authority register

**Register ID:** `EP-R001`  
**Established:** 2026-10-20  
**Status:** initial inventory; maintained reference, with the limits below.  
**Related proposal:** [ontology vision](emerging-philosophy-ontology-vision.md)

## What this register records

The research bank comprises Zotero and a documented set of non-Zotero records. This document explicitly lists both, including **this document itself** as `EP-R001`. A row describes a resource; it is not the resource. Zotero is a cataloguing system, its JSON snapshots are documents, and a scan is a file representing pages of a work. They remain distinct even when they concern the same work.

The IDs identify registered resources within this register's namespace. They are independent of opaque EP audit-unit IDs (`EP-` plus at least three digits), deep-dive sequence numbers (`DD-###`), Zotero keys, and filenames. EP audit-unit IDs identify complexes or singletons, not necessarily genuine projects. Keep an ID when a resource moves. Assign a new ID to a separately retained version or resource and record its relationship to the original. Never reuse retired **register** IDs; EP audit-unit allocation and its inherited exceptions are specified separately below.

**Inventory boundary at establishment:** the named audit/ontology/review documents below and the files currently under `sources/emerging_philosophy/`. The 14 JARs are individually enumerated by a registered manifest; the 27 retained page images are explicitly enumerated below. General Rails documentation, implementation dependencies outside this directory, conversation transcripts, temporary OCR files, and external sources merely linked from dossiers are outside this initial inventory. Those external sources are discoverable through the dossiers but are not yet a complete individually registered source inventory. Dropbox originals and Zotero attachments have not been reconciled against every local copy by this register.

“Non-Zotero” means maintained outside the live Zotero catalog; it does not mean that the document cannot also have a Zotero record. A future cross-link must state whether it links a bibliographic work, an attachment, or a file copy. This register establishes neither duplicates nor identity from filenames alone.

## Authority by record family

| Record family | Responsible record/system | Scope and limits |
|---|---|---|
| Live bibliographic metadata, attachment relationships, collection membership | `EP-R002` — Zotero | What the live catalog currently records. Metadata may need correction; its presence is not historical proof. No live refresh was performed to create this register. |
| Frozen audit population | `EP-R005` — 2026-10-15 snapshot | State captured at library version 8069; 161 top-level items. Later discoveries and live edits do not rewrite this baseline. `EP-R004` defines population and staging policy. |
| Audit procedure and recorded user rulings | `EP-R004` — audit plan | Procedure and execution history, with revisions recorded there. A proposal in `EP-R003` does not silently amend approved audit rules. |
| Gate rulings, anchors/assignments, and expected-artifact inventory rulings | `EP-R037` — `decisions.jsonl` | Authoritative append-only, last-wins ledger. Legacy `same-project` operationally means same complex, and `to_project` points to an EP audit-unit ID. On 2026-10-26 the user approved 357 inventory rulings; the derived inventory has 194 confirmed artifacts and no unknowns. |
| Current derived review views | `EP-R007` and `EP-R008` — review-sheet YAML/Markdown | Generated from the frozen snapshot, `EP-R037`, and `EP-R036`. They display proposals and rulings but are not editing surfaces or independent authorities. |
| Retrieval routes and liveness evidence | `EP-R040` — source-material audit and curated overrides | Complete 194-row classification with status, route, evidence, and confidence. The CSV is derived from the confirmed inventory and network/local evidence; the curated YAML records reviewed corrections. Phase-2 status is complete; this is not a Phase-3 acquisition manifest. |
| Phase-3 acquisition outcomes and physical-object coverage | `EP-R043` — acquisition slot/object manifests, registry, and coverage | Slot/object manifests record terminal outcomes, shared-object links, provenance, attempts, and verification evidence. `registry.json` and `coverage.json` are regenerated indexes, including required/optional coverage and pending slots. Phase-2 routes remain EP-R040. |
| Singleton EP audit-unit IDs, coordinated with anchored IDs | `EP-R036` — `singleton-ids.json` | Authority for the EP-028…EP-140 mapping of the 113 previously unanchored singletons. Anchoring the same record preserves its EP ID; its mapping is dormant while anchored and active on return. Individual assignments live in that mapping, not in this register. |
| Scholarly descriptions and interpretations | Individual deep-dive dossiers | Accounts attributable to their authors/reviewers, bounded by their source registers and reading disclosures. Dossiers do not override gate decisions by implication. |
| Preserved artifact inventory and hashes | Registered manifests and source records | Statements about enumerated local artifacts at the recorded time; a manifest does not establish operational reproducibility by itself. |
| Staging/import history | `EP-R018` and the audit log | Records of actions and proposals. Present Zotero state must be checked separately if needed. |
| Review findings | `EP-R019`–`EP-R021` | Findings about drafts inspected at the stated time. Earlier reports can remain useful historical records after the dossiers change. |
| Register membership and authority map | `EP-R001` — this document | What this inventory declares within its boundary. Its own entry is subject to the same provenance and revision rules. |

Authority here means responsibility for a record family, not infallibility or a universal precedence order. If a scan contradicts a Zotero title, retain the evidence and correct the bibliographic record explicitly. If a dossier disagrees with a gate decision, record the discrepancy for a decision rather than silently replacing the gate. If the YAML and Markdown views disagree, inspect the ledger and other generation inputs, correct the authoritative input rather than either view, and regenerate both. A newer date alone does not resolve a substantive contradiction.

EP audit-unit IDs contain at least three digits (`EP-001`, `EP-1000`). New IDs exceed the high-water mark across active, dormant, logged, and retired IDs; no **new** allocation reuses an ID. The active EP-004/EP-020/EP-022 records and retired originals with the same numbers are inherited pre-policy exceptions. Preserve that history through explicit, version-qualified mappings; do not renumber it. Validation finishes before any YAML, Markdown, singleton-registry, or IDMAP write.

## Registered systems and documents

Local links are relative to this document. Rows identify the resource, its documentary role, and its status or relationship. “Current” means the maintained document at that path; it does not certify that every assertion in it is up to date.

| ID | Resource / location | Type, role, and status |
|---|---|---|
| EP-R001 | [This document](emerging-philosophy-document-register.md) | Document register; explicit self-entry; maintained. This row describes the document that contains the row. |
| EP-R002 | Zotero user library `1248965`, collection `8QSGBCWF` (“emerging philosophy”); staging subtree `MNG9HZDC` | Live cataloguing authority. Identifiers from the audit plan; not a new live-state check. |
| EP-R003 | [Ontology vision](emerging-philosophy-ontology-vision.md) | Design proposal; revised 2026-10-25. Conceptual distinctions and candidate mappings, not an implemented schema. |
| EP-R004 | [Audit plan](emerging-philosophy-audit-plan.md) | Approved audit procedure with subsequent rulings and execution log; maintained. |
| EP-R005 | [Frozen snapshot](../../sources/emerging_philosophy/dumps/snapshot-20261015T172014Z.json) | Zotero export, library version 8069; input to the derived views EP-R007 and EP-R008. Snapshot checksum recorded in those views. |
| EP-R006 | [Earlier baseline export](../../sources/emerging_philosophy/dumps/baseline-2026-10-15.json) | Historical JSON baseline used for audit comparison; distinct from EP-R005. |
| EP-R007 | [Review sheet YAML](../../sources/emerging_philosophy/review-sheet-v2.yaml) | Derived machine-readable view of proposals and ledger rulings, generated by `scripts/zotero_cluster.rb` from EP-R005, EP-R036, and EP-R037. Do not edit directly. |
| EP-R008 | [Review sheet Markdown](../../sources/emerging_philosophy/review-sheet-v2.md) | Derived readable view generated from the same inputs as EP-R007. Do not edit either generated view; append rulings to EP-R037 and regenerate both. |
| EP-R009 | [Pre-regeneration YAML](../../sources/emerging_philosophy/review-sheet-v1.preregen-20261019.yaml) | Historical retained review-sheet version; current rulings belong to EP-R037, with current derived views EP-R007 and EP-R008. |
| EP-R010 | [Pre-regeneration Markdown](../../sources/emerging_philosophy/review-sheet-v1.preregen-20261019.md) | Historical presentation corresponding to EP-R009. |
| EP-R011 | [Deep-dive index](../../sources/emerging_philosophy/deep-dive/INDEX.md) | Maintained reading sequence, scope, and dossier-status index. |
| EP-R012 | [Sloman dossier](../../sources/emerging_philosophy/deep-dive/001-1978-sloman-computer-revolution.md) | Scholarly account; edition and reading limits recorded within. |
| EP-R013 | [TALLC dossier](../../sources/emerging_philosophy/deep-dive/002-1983-project-tallc.md) | Scholarly and technical account; source, artifact, and consultation disclosures within. |
| EP-R014 | [TALLC runbook](../../sources/emerging_philosophy/deep-dive/002-1983-project-tallc-runbook.md) | Execution instructions and recorded observations; dependencies and limits within. |
| EP-R015 | [TALLC launcher](../../sources/emerging_philosophy/deep-dive/run-tallc-applet.sh) | Executable supporting artifact for EP-R014; registration is not execution or verification. |
| EP-R016 | [Bedau/Moor Proof Designer dossier](../../sources/emerging_philosophy/deep-dive/003-1988-proof-designer.md) | Scholarly account with namesake disambiguation and scan inventory. |
| EP-R017 | [Wittgenstein Archives dossier](../../sources/emerging_philosophy/deep-dive/004-1990-wittgenstein-archives.md) | Scholarly account; current draft and source disclosures within. |
| EP-R018 | [WAB staging/import record](../../sources/emerging_philosophy/deep-dive/004-wab-outputs-zotero-import.md) | Records 2026-10-19 staging additions and proposed classifications; not a live inventory. |
| EP-R019 | [Initial scholarship review](deep-dive-scholarship-review-2026-10-19.md) | Historical assessment; later findings and corrections recorded in EP-R020. |
| EP-R020 | [Scholarship re-review](deep-dive-scholarship-rereview-2026-10-19.md) | Dated assessment with draft fingerprints and source limits. Reconcile against later edits before treating findings as current. |
| EP-R021 | [Re-review working notes](deep-dive-scholarship-rereview-2026-10-19-working-notes.md) | Working record of review activity; distinct from the published assessment EP-R020. |
| EP-R022 | [TALLC artifact manifest](../../sources/emerging_philosophy/deep-dive/artifacts/tallc/MANIFEST.md) | Enumerates 14 JARs by filename, source URL, checksum, and observed run status. Also serves as the explicit member list for this registered binary artifact set. |
| EP-R023 | [Review-source manifest](../../sources/emerging_philosophy/deep-dive/artifacts/reviews/MANIFEST.md) | Provenance, transformation notes, and hashes for EP-R024–EP-R027. |
| EP-R024 | [Hofstadter raw text](../../sources/emerging_philosophy/deep-dive/artifacts/reviews/hofstadter-1980-review.raw.txt) | Retained proxy output; source and extraction limitations in EP-R023. |
| EP-R025 | [Hofstadter cleaned text](../../sources/emerging_philosophy/deep-dive/artifacts/reviews/hofstadter-1980-review.txt) | Cleaned derivative of EP-R024; not interchangeable with the publisher PDF. |
| EP-R026 | [Stich HTML](../../sources/emerging_philosophy/deep-dive/artifacts/reviews/stich-1981-review.html) | Retained mirrored source, with provenance in EP-R023. |
| EP-R027 | [Stich extracted text](../../sources/emerging_philosophy/deep-dive/artifacts/reviews/stich-1981-review.txt) | Text extraction from EP-R026; distinct file and representation. |
| EP-R028 | [Burkholder volume front matter](../../sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/front-matter/front-matter.pdf) | Local front-matter scan; not the complete volume. |
| EP-R029 | [Croy/Amidon chapter scan](../../sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/chapters/ch12-croy-amidon-graphic-mouse-driven-interface_pp213-217.pdf) | Chapter 12, printed pp. 213–217; local copy of supplied scan. |
| EP-R030 | [Bedau/Moor chapter scan](../../sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/chapters/ch13-bedau-moor-proof-designer_pp218-228.pdf) | Chapter 13, printed pp. 218–228; local copy of supplied scan. |
| EP-R031 | [Portoraro chapter scan](../../sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/chapters/ch14-burkholder-portoraro-finite-structures-symlog_pp229-234.pdf) | Chapter 14, printed pp. 229–234; local copy of supplied scan. |
| EP-R032 | [Barker/Scott chapter scan](../../sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/chapters/ch15-barker-scott-socratic-dialogue-dialog1_pp235-246.pdf) | Chapter 15, printed pp. 235–246; local copy of supplied scan. |
| EP-R033 | [Retained page-image set](../../sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/pages/) | Documentary image set, 27 explicit members below. Filename grouping alone does not establish derivation from a particular PDF. |
| EP-R034 | [Openproof/Hyperproof dossier](../../sources/emerging_philosophy/deep-dive/005-1991-openproof-hyperproof.md) | Deep-dive draft; reading limits disclosed in its source register. Reviewed in EP-R035. |
| EP-R035 | [Scholarship re-review, 2026-10-20](deep-dive-scholarship-rereview-2026-10-20.md) | Current review of deep-dive drafts 001–005 and supporting index/runbook; evidence and scope limits stated in the report. |
| EP-R036 | [Singleton audit-unit ID mapping](../../sources/emerging_philosophy/singleton-ids.json) | JSON authority for EP-028…EP-140, assigning the 113 previously unanchored singleton records and coordinating with anchored allocation. Anchoring preserves the same record's ID, with registry dormancy while anchored and reactivation on return. EP-001…EP-027 remain opaque IDs for 11 complexes and 16 anchored singletons. |
| EP-R037 | [Decisions ledger](../../sources/emerging_philosophy/decisions.jsonl) | Append-only JSONL authority for gate **and inventory** rulings. Last-wins `inventory` records are keyed by artifact ID; `required`/`optional` set `proposed: false` and preserve `basis` plus optional `date`, `note`, and `evidence`, while `not-expected` removes the row. New artifacts carry an explicit `basis`. The user approved 357 rulings on 2026-10-26; YAML and Markdown are derived views. |
| EP-R038 | [Phase-2 remediation review packet](phase-2-inventory-persistence-and-audit-unit-identity-remediation-for-independent-review.md) | R1–R5 dispositions, reproduction evidence, current fingerprints, and independent re-review questions. Agent-neutral filename; not an inventory ruling authority. |
| EP-R039 | [Inventory recommendations and independent consistency review](phase-2-expected-artifact-inventory-recommendations-for-independent-review-2026-10-26.md) | All 329 draft entries reviewed plus 28 proposed additions; user-approved on 2026-10-26 and enacted in EP-R037. Companion row data: `sources/emerging_philosophy/inventory-recommendations-2026-10-26.csv`. |
| EP-R040 | [Phase-2 source-material audit](phase-2-source-material-audit-for-review-2026-10-26.md) | Complete 194-row retrieval-route audit with evidence and final review outcome. Companion data: `sources/emerging_philosophy/artifact-audit-2026-10-26.csv`; curated route overrides: `sources/emerging_philosophy/artifact-audit-overrides-2026-10-26.yaml`; generator: `scripts/zotero_inventory_audit.rb`. |
| EP-R041 | [Independent Phase-2 audit review](phase-2-source-material-audit-independent-review-2026-10-26.md) | Independent no-blocker review; DIALOG1 local-preservation correction and Phase-3 checks for EP-011 dataset/interface separation and EP-105 programme-content verification. |
| EP-R042 | [Phase-2 → Phase-3 acquisition handoff](phase2-phase3-handoff.md) | Fresh-context acquisition guide: confirmed routes, slot/object deduplication, manifests, verification, resumption, special cases, and definition of done. |
| EP-R043 | [Phase-3 acquisition registry](../../sources/emerging_philosophy/acquisition/registry.json) | Maintained index of Phase-3 physical objects and linked slot manifests. Companion `coverage.json` reports required/optional outcomes and pending work; slot/object manifests under `acquisition/` are the underlying records. Phase 3 complete: 121 acquired, 39 reference-only, 9 manual, 25 documented failures, 112 objects, zero pending; required coverage 142/172 and optional coverage 18/22. |

### EP-R033: explicit members

All filenames below are relative to `sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/pages/`. This is a closed list at establishment, not a wildcard covering future additions.

```text
part1-1.png
part1-2.png
part1-3.png
part1-4.png
part1-5.png
part2-01.png
part2-02.png
part2-03.png
part2-04.png
part2-05.png
part2-06.png
part2-07.png
part2-08.png
part2-09.png
part2-10.png
part2-11.png
part3-01.png
part3-02.png
part3-03.png
part3-04.png
part3-05.png
part3-06.png
part3-07.png
part3-08.png
part3-09.png
part3-10.png
part3-11.png
```

## Versioning, self-reference, and maintenance

This document's row is an ordinary resource description. It does not assert its own correctness, approval, or completeness. The registry's internal IDs and links provide the self-reference; a hash embedded in the same bytes it hashes is not required. If an exact register version must be cited, record a commit identifier when committed or compute an external checksum of a retained copy. A path plus the establishment date identifies this maintained document but does not freeze its later contents.

Existing frozen exports and manifests retain their own version evidence. A maintained file's modification time is not a substitute for the source version used in an assessment. A future integrated export should record the precise versions of its input register, Zotero snapshot, decisions, dossiers, and manifests so that the result can be reproduced.

When adding an in-scope document, assign a fresh register ID and record its location, type, role, status, and derivation or supersession relationships. Extend an explicit set's membership when adding a member. Preserve records for retired documents with their successor or removal rationale. Update the authority table when responsibility changes; do not infer new authority just because a new file exists. Derived outputs must identify their inputs and should not silently become an independently edited authority.

**Revision record — 2026-10-20:** initial register created in response to the user's requirement to enumerate Zotero and the non-Zotero documents, including the enumerating document itself. Locations and inventory coverage checked locally; source scholarship, live Zotero state, and all document assertions were not re-audited in establishing this register.

**Revision record — 2026-10-25:** adopted complex/singleton/audit-unit terminology and EP audit-unit IDs. Added EP-R036 for the `singleton-ids.json` authority and its record-family scope; did not create or modify the mapping or assign individual EP-028…EP-140 IDs here. The accounting is 11 complexes + 129 singletons = 140 audit units, comprising 28 complex-member records + 129 singleton records, with 4 non-project records excluded from the 161-record population.

**Revision record — 2026-10-25, Phase-2 remediation:** added EP-R037 as the authority for gate and inventory rulings; corrected EP-R007/EP-R008 to derived-view status and removed the instruction to edit YAML. Documented coordinated singleton/anchored ID transitions, 3+-digit EP IDs, validation-before-write, and the inherited version-qualified EP-004/EP-020/EP-022 exceptions without renumbering history.

**Revision record — 2026-10-26, Phase 3 started:** added EP-R043 for the acquisition slot/object manifests and regenerated registry/coverage indexes. The initial pilot records 3 acquired required slots across 2 physical objects, with 191 slots pending; this does not change the Phase-2 route authority EP-R040 or any rulings in EP-R037.

**Revision record — 2026-10-26, present-route batch:** updated EP-R043 after all 73 `present` slots were processed: 72 acquired, 1 documented failed required slot (Hyperproof table-of-contents excerpt), 57 physical objects, 121 other slots pending. This records content verification outcomes without reclassifying the Phase-2 route or inventory.

**Revision record — 2026-10-28, iterative phases:** the governing plan now defines Phase 6 as integration through Zotero staging and user promotion, Phase 7 as the iterate-or-publish decision gate, and Phase 8 as website/A0-poster dissemination. Staging remains quarantined until Phase 6; no new registered resource is required.

**Revision record — 2026-10-28, OpenAlex batch:** updated EP-R043 for all 8 OpenAlex slots: 5 acquired across 5 objects, 3 documented required failures, bringing overall acquisition to 77 acquired slots, 4 failed required slots, 62 objects, and 113 pending. `EP-135` supplies full HTML text; `EP-129` is a wrong-publication route; `EP-133` and `EP-140` preserve access-failure attempts. Phase 3 remains incomplete.

**Revision record — 2026-10-28, Phase 3 complete:** updated EP-R043 after direct URLs, full Git clones, homepage downloads, Wayback captures, and all non-download terminal outcomes were processed. Final totals: 121 acquired (110 required + 11 optional), 39 reference-only (32 + 7), 9 manual (8 + 1), 25 documented failures (22 + 3), 112 physical objects, and zero pending. Required coverage is 142/172 satisfied and optional coverage 18/22; missing required artifacts remain explicit. Terminal-state completion is not full recovery. Live Zotero was not modified.

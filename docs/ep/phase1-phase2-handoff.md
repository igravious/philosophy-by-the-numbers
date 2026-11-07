# Handoff: Phase 1 → Phase 2 (Emerging Philosophy audit)

**Written 2026-10-21, at the close of the Phase 1 human gate. For a model arriving with zero context.**

You are continuing an audit of the user's Zotero collection **"emerging philosophy"** — a personal research bibliography cataloguing projects in *philosophic computing* (computing as a method of doing philosophy: logic-teaching software, corpora, digital editions, visualizations, analysis tools). The governing plan is `docs/ep/emerging-philosophy-audit-plan.md` — **read its giant "Execution log" paragraph (line 4) first**; it is the session-by-session record of every ruling. This handoff summarizes what you need; the plan log is the ground truth.

## What Phase 1 was, and its outcome

Phase 1 (plan §4) answered: *which of the 161 top-level items belong to the same complex?* The frozen snapshot (`sources/emerging_philosophy/dumps/snapshot-20261015T172014Z.json`, library version 8069) was clustered by a generator script, and every proposed link was ruled at a human gate over several sessions.

**Outcome: 11 complexes and 129 singletons — 16 anchored singletons below plus 113 unanchored singletons — with 216 link rulings and 4 excluded non-project records.** A **complex** is a curated grouping of 2+ Zotero records treated as one audit unit; a **singleton** is a one-record audit unit. An **audit unit** is either a complex or a singleton. The 27 anchored entries EP-001…EP-027 therefore comprise 11 complexes + 16 anchored singletons. Together with the 113 unanchored singletons, this gives **140 audit units receiving Phase-2 inventories**. The records account for the whole population as **28 in complexes + 129 singleton records + 4 non-project records = 161**. Every grouping is gated; the snag list is empty.

A singleton may be a genuine project, work, software output, or other output: **project/work describes the endeavour or output, not the number of records**. EP-001…EP-027 are now opaque **EP audit-unit IDs**, not project IDs. Singleton IDs EP-028…EP-140 are held in `sources/emerging_philosophy/singleton-ids.json`, coordinated with the anchored-ID allocation. EP IDs contain at least three digits (`EP-001`, `EP-1000`). Anchoring the same singleton record preserves its EP ID; its registry mapping becomes dormant while it is anchored and active again if it returns to singleton status. New IDs exceed the high-water mark across all active, dormant, logged, and retired IDs. No **new** allocation reuses an ID; the inherited active/retired EP-004, EP-020, and EP-022 exceptions below remain explicit and version-qualified rather than being renumbered.

The anchored roster (see `sources/emerging_philosophy/review-sheet-v2.yaml` for members/edges):

| EP audit-unit ID | Audit unit | Type | Records | ~Year |
|---|---|---|---:|---|
| EP-001 | Project TALLC | Complex | 4 | 1983 |
| EP-002 | Proof Designer (Bedau & Moor) | Anchored singleton | 1 | 1988 |
| EP-003 | Openproof/Hyperproof | Complex | 2 | 1991 |
| EP-004 | Dialog1 (Barker) | Anchored singleton | 1 | 1992 |
| EP-005 | Philosophy and the Computer (Burkholder volume) | Anchored singleton | 1 | 1992 |
| EP-006 | SYMLOG (Portoraro) | Anchored singleton | 1 | 1992 |
| EP-007 | Language, Proof and Logic | Complex | 3 | 1998 |
| EP-008 | PhiloSURFical (Pasin & Motta) | Anchored singleton | 1 | 2004 |
| EP-009 | DAPHNET Philosophy Sources (ILIESI-CNR) | Complex | 2 | 2006 |
| EP-010 | The Discovery Project (D'Iorio) | Complex | 4 | 2006 |
| EP-011 | Philosophy Knowledge Map (Kim group) | Anchored singleton | 1 | 2007 |
| EP-012 | Philosophome / PDC Philosophy Ontology (Grenon & Smith) | Complex | 2 | 2007 |
| EP-013 | 30th Wittgenstein Symposium proceedings (vols I & II) | Complex | 2 | 2008 |
| EP-014 | Synthese 182(2) "Representing Philosophy" special issue | Complex | 2 | 2011 |
| EP-015 | NEH Institute "Computer Simulations in the Humanities" | Anchored singleton | 1 | 2011 |
| EP-016 | Graphing the History of Philosophy (Raper) | Anchored singleton | 1 | 2012 |
| EP-017 | Co-Citation Network for Philosophy (Healy) | Anchored singleton | 1 | 2013 |
| EP-018 | Zoomable Graph of the History of Philosophy (Hogan) | Anchored singleton | 1 | 2013 |
| EP-019 | Tractatus Tree (Bellon) | Anchored singleton | 1 | 2014 |
| EP-020 | Visualizing the Bibliography of Philosophy (Sula/Dean) | Anchored singleton | 1 | 2014 |
| EP-021 | Digital Ricoeur | Anchored singleton | 1 | 2017 |
| EP-022 | DR2 (distant reading / fMOD) | Complex | 3 | 2017 |
| EP-023 | TheofPhilo thesaurus (ILIESI-CNR) | Anchored singleton | 1 | 2017 |
| EP-024 | The History of Philosophy (Önduygu) | Complex | 2 | 2018 |
| EP-025 | Open Philosophy topical issue "Computer Modeling in Philosophy" (guest-ed. Grim) | Anchored singleton | 1 | 2019 |
| EP-026 | SEP "Computational Philosophy" | Complex | 2 | 2020 |
| EP-027 | Challenging_DMs (Oortwijn et al.) | Anchored singleton | 1 | 2021 |

Note EP-004 here is **Dialog1** — the *original* EP-004 (Deep Thought) was retired by merge into EP-001. Retired IDs: EP-004(orig), EP-020(orig: Daily Nous/Open Culture commentary pair, dissolved), EP-022(orig: Bloomsbury chapter pair, dissolved). History lives in `sources/emerging_philosophy/regen-idmap.json` and the ledger.

## The machinery (how to operate it)

Four files, all in the repo:

1. **`sources/emerging_philosophy/decisions.jsonl`** — the append-only decisions ledger. THE source of truth for both gate and inventory rulings. Record types:
   - `{"type":"gate","a":K1,"b":K2,"gate":V,"channel":"membership"|"containment","date":"...","note":"..."}` — one line per unordered item pair; mirrors auto-complete; **last line wins** per (pair, channel). Never edit old lines; append corrections.
   - `{"type":"project","key":K,"name":"..."}` — the legacy serialized anchor record; operationally it anchors an audit unit, whether a complex or a one-record singleton. `"name":null` **retires** an anchor (dissolves the grouping).
   - `{"type":"note","key":K,"text":"..."}` — free annotations (used for absent-project confirmations).
   - `{"type":"assignment","key":K,"value":"non-project"|"unresolved"}` — forces non-project status.
   - `{"type":"inventory","id":"EP-028/software/repo","requirement":"required|optional|not-expected",...}` — one last-wins ruling per artifact ID. `required` and `optional` confirm the row with `proposed: false`, preserving `basis` and optional `date`, `note`, and `evidence`; `not-expected` removes the row. New artifacts require an explicit `basis`. Append rulings here, never by editing a generated sheet. On 2026-10-26 the user approved 357 rulings; the derived inventory now has 194 confirmed artifacts and no unknowns.
2. **`scripts/zotero_cluster.rb`** — regenerates the derived YAML and Markdown views from snapshot + ledger + singleton-ID registry. Run:
   ```
   ZOTERO_SHEET_YAML=sources/emerging_philosophy/review-sheet-v2.yaml \
   ZOTERO_SHEET_MD=sources/emerging_philosophy/review-sheet-v2.md \
   bin/bundle exec ruby scripts/zotero_cluster.rb
   ```
   Regen is byte-deterministic across all four outputs: YAML, Markdown, `singleton-ids.json`, and `regen-idmap.json` (old→new EP-ID map). Validation finishes before any sheet, Markdown, registry, or IDMAP write, so a failed regeneration does not leave partial output changes.
3. **`sources/emerging_philosophy/singleton-ids.json`** — persistent key→EP-ID registry coordinated with anchored IDs. Anchoring the same record preserves its EP ID and makes its registry mapping dormant; returning to singleton status reactivates that mapping. Existing mappings survive regeneration and dormancy. New IDs exceed every active, dormant, logged, and retired high-water ID; no new allocation reuses an ID. The inherited EP-004/EP-020/EP-022 active/retired exceptions remain explicit and version-qualified.
4. **`scripts/zotero_verify_decisions.rb`** — `bin/bundle exec ruby scripts/zotero_verify_decisions.rb`. Checks 1–7 cover the existing gate/accounting/ID invariants plus exact frozen-snapshot population keys, every `to_project` target against the key→audit-unit map, and inventory structure and rulings. Optional check 8 is enabled with `ZOTERO_PRESERVATION_BASELINE` and compares against the retained baseline for preservation drift; an explicitly empty inventory is valid and is not, by itself, an error. For the completed remediation, all 8 checks passed, and the final line was `ALL CHECKS PASSED`.

**Legacy tokens are retained, not renamed.** `same-project` operationally means **same complex** and welds records into a complex. `type: project` is the audit-unit anchor record above; `to_project` points to an EP audit-unit ID; `non-project` excludes a record from the audit-unit population. These serialized words do not make every singleton a project or every complex a single genuine endeavour. Membership rulings: `same-project` (welds) | `describes` | `implements` | `cites` | `unrelated` | `siblings` (all cut). Containment rulings: `part-of` | `unrelated` (never weld/cut; display only). Rulings on pairs with no evidence edge synthesize a `decision` edge (high confidence for membership, low for containment so it can't weld).

## The rulebook (gate conventions settled by user rulings — do not reopen)

- **Venue-ownership**: venue = the intellectual forum (journal/conference/book/site); ownership = editorial control. A project's own venue (own site, own book, own README, own in-house institute series) → `same-project`; others' venues (journal articles, edited-volume chapters, conference proceedings, reddit/news/blog coverage — *even when developer-authored*) → `describes`. Publisher is irrelevant. Rare carve-out: a project's own conference counts as own venue.
- **Projects need not be software**: events (NEH institute) and editorial endeavours (special issues, proceedings volumes) qualify. Chapters/articles are **never members** of a container project — they get `containment: part-of` only.
- **`siblings`**: co-container chapters or parallel co-commentary — related, not one endeavour.
- **Absent projects** (described by a record but no artefact in the collection): ledger `note` + Phase-5 staging candidacy. Bazzocchi's hypertext was removed from this category on 2026-10-26: its record `DS7C8WTQ` is present as EP-047, and `I7MAW4IQ` is its required descriptive chapter.
- **Container pre-typing**: bookSection↔book title matches come pre-typed `containment: part-of`; chapter cliques and same-journal doi-stem links are intentionally left blank.
- Full-name creator matching (`name:SURNAME_forename`); bare surnames never match.

## Loose ends carried forward (none block Phase 2)

- **Staging collection `MNG9HZDC`** (subcollection of the root, deliberately excluded from the population) holds post-snapshot discoveries — ~25 items incl. the Philosopher's Web pair, the WAB-Bergen Wittgenstein digital-editions set, Healy's philcites interactive, the Openproof home page, scanned Burkholder-volume chapters' online twins, reviews of Sloman's CRP, Velleman's *How to Prove It*, the Allwein & Barwise volume. **Reconciled at Phase 5**, never silently merged.
- **Open question**: does the Synthese "Representing Philosophy" issue (EP-014) fold into the InPhO programme (Allen/Niepert/Buckner items are singletons)? Deferred from the EP-014 gate.
- Metadata fixes for Phase 5: `QKD3VTIY` date is a scrape artifact; `DGWBG5LH` is typed blogPost but is the NEH whitepaper report; `NB3PQBT9` is a working paper not a journal article.
- Burkholder volume scans live at `sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/` (front matter + ch. 12–15; manifests pending — Phase 3 material).
- The user's scanned Burkholder chapter PDFs also sit in `~/Dropbox/document transfer/Burkholder_PatC/`.
- §9 open questions for the user, still open: **Unpaywall contact email** (needed for Phase 2's OA-resolution route); books: OpenLibrary/WorldCat vs straight-to-`manual`.

## Phase 2 (plan §5) — COMPLETE (2026-10-26)

Phase 2 covered **every one of the 140 audit units — all 11 complexes and all 129 singletons**, not just the 27 anchored entries.

- **Inventory gate:** the user approved 357 rulings covering all 329 machine proposals plus 28 additions. The confirmed inventory contains **194 artifacts: 172 required and 22 optional**, with no unknowns and every entry `proposed: false`. There were 163 `not-expected` removals. DIALOG1's original LEVEL5 program was added as `EP-004/software/original [required]`; EP-047's chapter was confirmed required and its absent-project note corrected.
- **Retrieval audit:** `sources/emerging_philosophy/artifact-audit-2026-10-26.csv` and `docs/ep/phase-2-source-material-audit-for-review-2026-10-26.md` contain all 194 rows with status/route/evidence/confidence. Final statuses: 73 present, 8 oa-resolvable, 25 direct, 9 manual, 2 unresolved, 3 clonable, 19 downloadable, 12 wayback, 39 reference-only, and 4 lost-candidates.
- **Review close:** the user accepted manual retrieval for seven publications and a targeted search of the other eight cases. EP-011 gained a verified archived dataset and EP-020 a live Tableau visualization; the other six retain unresolved/lost-candidate status with evidence, not claims of nonexistence. Remaining review-needed rows: 9 manual, 2 unresolved, 4 lost-candidates.
- **Independent review correction:** DIALOG1's 2016 implementation is `present/local-file` (401,245 bytes; manifest SHA256 verified), not `wayback`; Wayback remains provenance/fallback, and the original LEVEL5 program remains lost-candidate. The independent review found no blocker to Phase 3.
- **Verification:** exact inventory row order and all 194 IDs; all statuses have evidence; all 61 stored-PDF claims match attachments and all 12 local preservation paths exist. No artifact bytes were downloaded and Unpaywall was not used.
- **Next:** Phase 3 acquisition, using `scripts/zotero_inventory_audit.rb` and `sources/emerging_philosophy/artifact-audit-overrides-2026-10-26.yaml` as the curated route record. Manual, unresolved, and lost-candidate items retain their documented terminal categories for Phase 2 and explicit acquisition outcomes for Phase 3. Preserve EP-011's dataset-versus-interface distinction, and verify EP-105's programme PDF actually contains the expected text, with relevant pages recorded.

## Working relationship (user preferences, hard-won)

- The user rules on classification decisions; machinery is yours. "Don't bother me with trivialities; only tap me on the shoulder when there's an actual decision." When in doubt, present a lean with evidence and let them confirm or amend ("we can tweak things as we iterate").
- Plain language. Translate item keys to titles; avoid unexplained jargon (they pushed back on "edge"/"gate" shorthand — say "link" and "ruling"); no false either/or framings where both can be true.
- When they add items to Zotero staging, verify with `bin/rails runner tmp/zotero_staging_peek.rb` and log the library version.
- Log everything in the plan's execution log (line 4) — one append per work session, tally updates included.

## Environment gotchas

- Ruby 2.6.10, Rails 4.2: always `bin/bundle exec ruby` / `bin/rails runner`; no `Array#tally` (use `Hash` counting); the repo's YAML files use tabs-for-indentation in the generator source.
- python3 available (no yaml module — parse JSON snapshot with python3, sheets with ruby).
- Zotero API credentials come from `.env` via `SecurityConfig.load_credential` (see `lib/zotero/client.rb`); the live library is well past the snapshot's version 8069 (~8154 by 2026-10-21) — all audit work runs off the frozen snapshot; live-library changes land via staging and Phase 5 reconciliation.
- AGENTS.md workspace rules: EP material lives in `docs/ep/` (hived off from `docs/ai`/`docs/wip`, which serve the four CorpusBuilder sub-projects this field survey feeds).

# Deep-dive and summarise process — handoff

**Purpose.** For each audit unit in the Emerging Philosophy Zotero
collection, produce a dossier that lets a reader skim to understand what it is,
what it argues or does, who made it, what survives, and how well we know. The
collection is meant to be read as a research bank: entries are short enough to
flit through, sourced well enough to trust.

An **audit unit** is a **complex** (a curated grouping of 2+ Zotero records) or
a **singleton** (one record). A singleton can still be a genuine project, work,
software output, or other output; project/work is not a record count. EP IDs
(`EP-` plus at least three digits) are opaque audit-unit IDs. The legacy gate
token `same-project` means same complex.

**Deeper rule.** A dossier is only as good as its reading. Metadata and
abstracts are not a deep dive. Read the primary text, the book's own front
matter, the program, the live site. Where a source could not be read, say so
and bound the claims accordingly.

## Where things live

| What | Path |
|---|---|
| Dossiers (one per work, plus supporting files) | `sources/emerging_philosophy/deep-dive/` |
| Queue, statuses, links | `sources/emerging_philosophy/deep-dive/INDEX.md` |
| Technical initialisms | `sources/emerging_philosophy/deep-dive/GLOSSARY.md` |
| Preserved artifacts and manifests | `sources/emerging_philosophy/deep-dive/artifacts/` |
| Outstanding source-access gaps | `docs/ep/currently_outstanding.md` |
| Review history (older → newer) | `docs/ep/deep-dive-scholarship-review-2026-10-19.md`, `docs/ep/deep-dive-scholarship-rereview-2026-10-19.md`, `docs/ep/deep-dive-scholarship-rereview-2026-10-20.md`, `docs/ep/deep-dive-scholarship-review-2026-10-26.md` |
| Authority register (what is authoritative for what) | `docs/ep/emerging-philosophy-document-register.md` |
| Audit plan, population, staging policy, user rulings | `docs/ep/emerging-philosophy-audit-plan.md` and the plan's revisions |
| Gate and inventory ruling authority | `sources/emerging_philosophy/decisions.jsonl` |
| Derived clustering/inventory review views (do not edit directly) | `sources/emerging_philosophy/review-sheet-v2.yaml` and `sources/emerging_philosophy/review-sheet-v2.md` |

The deep-dive directory is gitignored; `docs/` is versioned.

## Process per audit unit

1. **Identity** — Zotero key, type, creators, date, container, identifiers,
   collections, URL. Flag where the cataloguing is wrong (item type, role,
   dates, missing identifiers) rather than silently working around it.
2. **Provenance** — editions, versions, reissues, where the text came from, and
   which edition the dossier summarises.
3. **Primary sources** — read them. Book front matter and acknowledgements,
   conference papers, program documentation, the live site. Extract the
   project's own account of itself: team, funding, dates, methods, aims.
4. **Artifact and liveness check** — what is downloadable, what runs, what is
   archived, what is dead. Date every live check.
5. **Relation to the collection** — which records belong to the same complex,
   which are separate singleton audit units, and which merely describe the unit.
6. **Write the dossier** using the structure of the existing files: Identity,
   one-minute overview, what it is, people, history/timeline, software or
   method, related collection items and complex-grouping note, liveness and
   artifacts, significance (marked as interpretation), open questions, source
   register with reading status, and an explicit "not done" list.
7. **Record status honestly.** Every source carries a reading status: full text,
   selected pages, abstract only, metadata only, not accessed.

## Rules the reviews enforced

- Never claim completeness you have not verified; label drafts as drafts.
- Pin consequential claims to a page or section.
- Distinguish original text from later additions and revised editions; do not
  let a revised edition stand in for the original.
- Mark interpretation as interpretation, and bound comparative claims ("one of
  the first", "longest-lived") unless a comparative source supports them.
- Distinguish what an author claims from what is independently established.
- Externally published papers that *describe* a project are cross-references
  and separate singleton audit units, not members of its complex, unless the
  gate says otherwise.
- Expand domain and project acronyms inline on first use; keep technical
  initialisms in `GLOSSARY.md`; do not expand product names.
- **Never write to the Zotero SQLite database.** Read it with
  `sqlite3 "file:…/zotero.sqlite?immutable=1"`. Zotero API writes are
  permitted only into the `staging` sub-collection, and only when asked.
- Do not edit the derived YAML or Markdown review views; dossiers propose,
  while `decisions.jsonl` records the authoritative gate and inventory rulings.

## Progress

| DD | Work | State | Main gaps |
|---|---|---|---|
| 001 | Sloman, *The Computer Revolution in Philosophy* (1978) | Reviewed draft; revised edition read; Stich and Hofstadter reviews read in full | Full 1978 edition collation; Mackay and Ringle reviews unread; pinpoint page refs for consequential claims |
| 002 | Project TALLC (1983–) | Reviewed draft; 1992 chapter, Croy 1999/2000, Stamper et al. 2013 read; 14 JARs preserved | Publication trail incomplete (missing author/venue/page data); pinpoint page refs; software not exercised; classroom use and grading unverified |
| 003 | Proof Designer, Bedau & Moor (1988) | Reviewed draft; full chapter read from the supplied scan | Pinpoint page refs; software survival unknown |
| 004 | Wittgenstein Archives, Bergen (1990) | Reviewed draft; site, BEE, IDP/SFB, ontology, Pichler documented | Editions and BEE not exercised; comparative wording; 11 output records staged in Zotero, not yet moved |
| 005 | Openproof Courseware: Hyperproof (1991) | Reviewed draft; 1992 AAAI paper read in full; 1994 book front matter and Ch. 1; 2017 LRDS contents | Full 1994 book and 2017 volume unread; software not run; Grade Grinder not tested |
| 006 | DIALOG1 — Socratic Dialogue CAI (1990–1992; web revival 2016) | Reviewed draft (2026-10-26); chapter full text; 2016 web program preserved whole; history from Barker's archived about page; gate outcome recorded (EP-004 singleton; EP-031 chapter singleton) | 1988 precursor paper unaccessed; LEVEL5 original unlocated; claims (award, Italian textbook, translations) are Barker's own; chapter reception unchecked |
| 007 | SYMLOG — Finite Structures chapter (1992) | Reviewed draft (2026-10-26); chapter full text; *Logic with Symlog* book/CADE-12/SEP careers established via the author's live profile; program record `XUR4E5SE` found (its URL points at the later web site; no copy held); gate outcome recorded (EP-006 singleton; EP-032 chapter singleton) | Software unlocated; cited "Portoraro 1989, 1990" unidentified; book, CADE-12, 1998 papers unaccessed; symlog.ca gated contents unexplored |
| 008 | OSCAR — The OSCAR Project, Pollock (item 1995; site text c. 2001–2013) | Reviewed draft (2026-10-26); complete site mirror preserved (51 files, 6.4 MB); **OSCAR 3.31 ran under SBCL 2.4.7** — collective rebutting defeat reproduced end-to-end; full paper-family list from publications page incl. OSCAR-MDA medical decision support (1996); original host's Wayback capture history 2000–2010 established 2026-10-26 | Published papers unread (preserved but unaccessed); "world's first" claim unverified; Arizona-only Wayback items (`OSCAR.htm`, `OSCAR.zip`, `Code for probable probabilities.zip`, `Degrees.pdf`, older problem variants) are Phase-3 acquisition leads; OSCAR-MDA fate unknown |
| 009 | LPL — Language, Proof and Logic courseware (software record 1998; first ed. 1999; rev. 2nd ed. 2011) | Draft 2026-10-26, not yet reviewed; both edition press-file PDFs preserved and read in substantial part; package anatomy (Tarski's World/Fitch/Boole/Submit → Grade Grinder) and edition-delta material read from the current official site; Hyperproof lineage and Velleman disambiguation recorded | `1998` record date unresolved; software binaries of any generation not collected (registration-gated); body chapters read at heading level; old-site (`ggweb`) sibling pages not recaptured; reception not searched |
| 010 | Pollock, "Procedural Epistemology" — chapter 1 of *The Digital Phoenix* (1998) | Draft 2026-10-26, not yet reviewed (batched); pp. 17–36 established by three concordant citations; EP-038/EP-040 relationships verified against the approved sheet; 1999 Guide variant identified and disambiguated (separate commissioned survey, ch. 16 pp. 383–414); Lokhorst review (1999) preserved full text and read | Chapter text unlocated (IA lending scan only — manual route confirmed); 1999 Guide variant unread (summary-only); Tomassi review unread (Cloudflare/paywall); `pages` field empty on the record (Phase-5 fix) |

**Next:** the chronological queue resumes at DD-009: EP-007, the **Language,
Proof and Logic (LPL)** courseware complex (`ZSE63NLV` "LPL Features", 1998;
`FNPDGWKC` first edition 1999; `3N9WUCQZ` revised second edition 2011). No
population record is dated 1996 or 1997. Within 1998, EP-039 (`HVU3VI2E`) and
EP-040 (`UKQIXPTG`, both 28 Feb 1998) sort ahead by day-level date and remain
uncovered; EP-039 is Pollock's own describing chapter for DD-008's project.
The volume's ch. 16 (Mostert et al., pp. 247–258) is not catalogued and has no
scan.

**DD-009 status (2026-10-26): dossier written, not yet reviewed.** See
`INDEX.md`. Direct routes for EP-007 slots (`3N9WUCQZ`, `FNPDGWKC`,
`ZSE63NLV`) were exercised for reading during the dossier work; one proved
stale (the UC route for the second-edition PDF now serves HTML — the
Wayback capture of the same route supplied the text). New source locations are
recorded in `sources/emerging_philosophy/deep-dive/artifacts/lpl/MANIFEST.md`
to feed Phase-3 acquisition deduplication.

**DD-010 status (2026-10-26): dossier written, not yet reviewed (batched).**
EP-039, Pollock's "Procedural Epistemology" — the OSCAR project's anthology
statement, Part I ch. 1 of EP-040 at pp. 17–36 (page span established by three
concordant citations; the record's `pages` field is empty — Phase-5 metadata
fix). The chapter text has no legitimate route (IA item
`digitalphoenixho0000unse` is lending-restricted), so the dossier is built on
the record, the sheet, the preserved Lokhorst review and ECU catalogue record
(`deep-dive/artifacts/procedural-epistemology/`), and IA metadata. The 1999
*Blackwell Guide to Epistemology* variant is identified and disambiguated.
**DD-011 next:** EP-040, the *Digital Phoenix* volume — volume facts already
gathered in the DD-010 dossier; the volume roster file remains the main
research object.

**Closed recently:** Stich 1981, Hofstadter 1980, Stamper et al. 2013, Croy 1999
and 2000 (read in full); Burkholder volume chapters 14 and 15 (read in full for
their new dossiers). Remaining gaps are listed chronologically in
`docs/ep/currently_outstanding.md`.

## What the reviews are

Four review documents, newest last. The **2026-10-26 review** is the current
statement for dossiers 006–008 (and includes the audit-unit coverage map's
justification in `INDEX.md`). The 2026-10-20 rereview stands for dossiers
001–005. Earlier documents remain useful as history, but their line numbers and
file fingerprints refer to older drafts and no longer match the files. Re-run a
review, or read the newest findings for the dossier in question, before treating
a dossier as audit-ready.

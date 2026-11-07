# Emerging Philosophy deep-dive review — 2026-10-20

## Assessment

There is now a current review of the five draft dossiers listed in the deep-dive index as of 2026-10-20, plus the TALLC runbook and launcher. The drafts are unusually transparent about reading status and source limitations. They are not yet uniformly audit-ready: several technical or historical claims still need pinpoint citations, the TALLC publication trail remains provisional, and the fifth dossier contained errors in project-boundary language, chronology, and the significance claim. I corrected those three issues and expanded “USF” at first mention in dossier 005.

This is a critical review, not a line-by-line verification of every statement against every cited source. Source access performed for each dossier is disclosed in its source register. In particular, the 1994 *Hyperproof* book and 2017 LRDS volume were not read in full, the software was not executed, and this review did not independently re-run all live-site checks.

## Findings requiring attention

### 1. Dossier 005: complex boundary and primary paper

The dossier correctly identifies the 1992 Barwise and Etchemendy paper as an important primary account, but its former wording asked whether the paper should be a `same-project` member. That conflicts with the established venue-ownership rule and the recorded `describes` edge: the externally published paper describes the genuine Hyperproof project but is not a member of the EP-003 complex; it remains a separate singleton audit unit. I corrected the dossier to state this and removed the contradictory open question. The Zotero record's item type and page field still need bibliographic correction as the dossier notes.

### 2. Dossier 005: Macintosh chronology

The former claim that the original 1994 program was Macintosh-only “(Mac OS 8.5)” projected a later operating system onto the original release. Apple announced Mac OS 8.5 in October 1998, four years after the book's publication. The current Grade Grinder FAQ says older Hyperproof builds may run on Mac OS 8.5–8.6; it does not establish that those were the original release requirements. I removed the unsupported original-version requirement and made that distinction explicit. [Apple's Mac OS 8.5 announcement](https://www.apple.com/ca/fr/press/1998/10/MacOS85.html), [Grade Grinder FAQ](https://www.gradegrinder.net/Support/faq.html).

### 3. Dossier 005: Grade Grinder significance

The former description of Hyperproof as an early example of “automated grading/learning analytics” was too broad for the evidence and risked conflating the 1994 release with the later LRDS/Grade Grinder package. The dossier now says only that the later package connects Hyperproof to an online grading service; it leaves the service's origins and its data practices open. The product page supports the current package connection, not a historical priority claim or learning-analytics classification. [LRDS product page](https://www.gradegrinder.net/Products/lrds-index.html).

### 4. Dossiers 002 and 003: page-level traceability

The prior review's recommendation remains: add printed-page locators beside detailed claims in the Croy and Amidon TALLC chapter and the Bedau and Moor Proof Designer chapter. Full scans were supplied and read, but a reader should not have to search an entire short chapter to audit a technical or historical statement. The source registers should retain scan hashes and printed pagination. This is a traceability improvement, not evidence that the summaries are presently inaccurate.

### 5. Dossier 002: publication trail and outcome inference

The TALLC publication trail remains a research map rather than a complete, dependable bibliography. Complete missing author, venue, page, and identifier information where available; preserve distinctions between published versions and author-updated copies; and keep abstract-level descriptions attributed to the abstract. The 2013 Hint Factory summary is substantially accurate based on the full article, with an important limitation already recorded: treatment was assigned by section, while the principal reported outcome tests are pooled student-level analyses. The article does not report cluster-adjusted inference or treatment-by-instructor/semester outcome interactions. Its independence conclusion should remain identified as the authors' interpretation, not as a directly tested interaction result.

### 6. Dossier 001: Sloman edition and reception

The dossier is explicit that it summarizes the revised online edition and that checks against the 1978 printing are incomplete. Keep that boundary visible. Add pinpoint page or section references for consequential claims, especially where later notes change the historical account. Hofstadter and Stich reviews are now reported as read in full; Mackay and Ringle remain unread. The full-edition collation remains outstanding, so the revised text must not stand in for the 1978 edition without qualification.

### 7. Dossier 004: comparative wording and dated liveness

The WAB dossier's source boundaries and dated live checks are clear. Its comparative description of the archive as “one of the major digital archives” should either be supported by an appropriate comparative source or softened to a descriptive statement about the archive's scope and function. Continue to date claims about live pages, services, and access. The source inspection described in the dossier does not establish that all referenced services, certificates, or archival workflows were exercised.

### 8. Index and coverage

The index lists dossiers 001–005 and identifies 006 as next. The current deep-dive set is therefore a reviewed draft sequence, not a complete account of the broader emerging-philosophy corpus. Keep the status and “next” language explicit as new dossiers are added. The 005 dossier is candid about partial access to the 1994 book and the 2017 volume, and about not running the software; those are material limits, not defects to hide.

## Scope and evidence limits

- Dossiers reviewed: `001-1978-sloman-computer-revolution.md`, `002-1983-project-tallc.md`, `002-1983-project-tallc-runbook.md`, `003-1988-proof-designer.md`, `004-1990-wittgenstein-archives.md`, `004-wab-outputs-zotero-import.md`, `005-1991-openproof-hyperproof.md`, `INDEX.md`, and `run-tallc-applet.sh`.
- Source access is as disclosed in dossier registers and the 2026-10-19 review: Sloman checks are targeted; Croy/Amidon and Bedau/Moor chapter scans were read; the full 2013 Hint Factory paper and Croy author copies were read; the 1992 Hyperproof paper was read in full, while the 1994 and 2017 books were only partly inspected as disclosed.
- Current-state claims about software, websites, licensing, grading, or continued use need dated checks. The 005 historical claims above were checked against Apple's announcement and Grade Grinder's current product/FAQ pages.
- This report assesses fidelity and transparency from available evidence; it cannot certify every summary sentence as faithful or comprehensive. A world-class scholarly package would additionally make specific claims easy to trace to pages, provide complete bibliographic records, preserve edition distinctions, and keep negative findings and untested claims explicit.

## Current fingerprints

The following hashes identify reviewed Markdown files after the corrections to dossier 005. They are fingerprints, not proof of scholarly accuracy.

| File | SHA-256 |
|---|---|
| `001-1978-sloman-computer-revolution.md` | `642833c375de4c7fd244755abe29590abd22e0eaaaaedd8acd87c9c86901768d` |
| `002-1983-project-tallc-runbook.md` | `3d5e070397ccced6b1ec9680fe6d2009814820b1f7af1f7eac5914bcbf206f6f` |
| `002-1983-project-tallc.md` | `d08ae206c0dc47ace4a4686c7359bcefce9c34b08394ce7c88673099720d17fe` |
| `003-1988-proof-designer.md` | `953036a3f3c72d8a7f4511b6d045190b3f4ff2dc0b2f61ad534a1e5c9197fd4b` |
| `004-1990-wittgenstein-archives.md` | `11bc49b83cc698bfc4f0761bd3a41cee469b2d86d1f79b2c39fec931dcb31388` |
| `004-wab-outputs-zotero-import.md` | `068ad14d6fcb3f440b211e744b6f243961b9f9a46ec54ae1f2278bc58a4705e8` |
| `005-1991-openproof-hyperproof.md` | `62ac99833f1ecb52ff8983136e7942725128d49daba7e24364b3cdae262e143a` |
| `INDEX.md` | `155de2aeca80a6084480b4f613f09bb10b04a4bc3860c29651491b1bdb512dde` |

# Emerging Philosophy deep-dive scholarship review — 2026-10-26

## Scope

First review of dossiers 006–008, which were written 2026-10-20 after the
2026-10-20 rereview closed dossiers 001–005. Dossiers 001–005 were not re-opened
on their substance; see the fingerprint note below.

This is a critical review, not a line-by-line re-verification of every summary
sentence against every source. The chapter scans behind 006 and 007 were already
read in full by the dossier; the OSCAR site mirror and code run behind 008 are
preserved artifacts whose hashes were re-checked here. Each dossier's source
register records what was read and what was not.

Note on fingerprints from the previous review: those for dossiers 001–005 and
their support files still match the files on disk; the `INDEX.md` fingerprint
no longer does, because this session edits that file (coverage map, statuses,
next pointer) — expected, since an index is a living document.

## Verification performed

1. **Cataloguing caveats against the frozen snapshot.** Every field claim in the
   Identity sections of 006 and 007 — titles, item types, dates, page fields,
   URLs, creator lists, ISBN, empty version/system/language fields on the program
   records, the abstract-on-chapter-is-a-self-description note, the attachment
   titles — was checked against `snapshot-20261015T172014Z.json`. All accurate,
   including the truncation of the SYMLOG chapter title (Crossref's record
   confirms the printed title is "Designing and Implementing Finite Structures
   **in SYMLOG**", Portoraro solo author on the reissue) and the ISBN mismatch
   premise (Zotero `978-0-8133-7994-4`).
2. **Chapter DOIs and pagination via Crossref, independently.**
   `10.4324/9780429301629-18` = Portoraro, pp. 229–234 (matches 007);
   `10.4324/9780429301629-19` = Barker & Scott, pp. 235–246 (matches 006).
   Both Routledge, 2019 reissue of *Philosophy and the Computer*.
3. **Artifact manifests.** `artifacts/dialog1/dialog1-20170203025603.html`
   hash re-computed and matches both the DIALOG1 dossier and the Phase-3
   handoff (`7f152ca5…`). The OSCAR mirror re-counted: 53 files under
   `artifacts/oscar/` including the two manifest files, i.e. the manifest's
   "51 files" of site data; 6.4–6.5 MB as stated. The six distribution defects
   in the dossier match the `MANIFEST.md` step list.
4. **Wayback CDX retry (open item from 008).** The CDX API — offline
   2026-10-20 — was retried 2026-10-26 and works. Result recorded in the
   dossier and `currently_outstanding.md` item 10: the original host
   `oscarhome.soc-sci.arizona.edu/ftp/OSCAR-web-page/*` has 200-status captures
   from 2000-08-31 to at least 2010-06-29 (bounded to the first 100 unique
   URLs), including Arizona-era items the johnpollock.us mirror does not hold
   (`OSCAR.htm` 2000 vintage, `OSCAR.zip`, `Code for probable probabilities.zip`,
   `Degrees.pdf`, older problem-file variants), and no sign of the
   never-distributed `OSCAR_3-31-acl.lisp` in the era captured. This mutually
   corroborates the mirror (its files match the 2010 capture generation) and
   downgrades the "unknown capture history" gap to a bounded, itemable
   archaeology task.
5. **Gate outcome cross-check.** The clustering notes in 006 and 007 still
   described the pre-gate sheet state (v5, `unresolved`, "no software item").
   `decisions.jsonl` shows the gate has since ruled precisely as the dossiers
   proposed (`describes` edges 2026-10-20/21; EP-004/EP-031 and EP-006/EP-032
   structure; user-approved inventory rows of 2026-10-26). The dossiers'
   clustering sections now record these outcomes in dated follow-up notes; no
   authority tables were edited.

## Corrections applied

- **008, heading:** the section header read "(software c. 1990s–2000s; site text
  c. 2001–2013)" while the index reads "(item 1995; site text c. 2001–2013)";
  made the dossier match the index (the Zotero item date 1995 is the anchor; the
  code's *stamp* is 3.31 and the site text is 2001–2013).
- **008, editing artifact:** a stray non-English fragment in the People section
  ("the的职业 started in logic") replaced with "his career started in logic".
- **008, wording:** "loadstone" → "lodestone".
- **006, wording:** a left-over "which the review could reach" in the Provenance
  section (written pre-review) rephrased to "which research could reach".
- **006/007, staleness:** clustering notes updated to record the decided gate
  outcomes (see Verification 5). The 008 clustering note needed no change.

## Findings requiring attention (no edit applied)

1. **Pinpoint chapter citations (extends the 2026-10-20 review's item 4).**
   Dossiers 006 and 007 cite chapter claims with page numbers in the text —
   better than the norm they were measured against — but a few load-bearing
   values in 007 (the `trt`/`ext`/`int` predicate fields, note 3's
   "Fregean implementation" wording, note 5's "a couple of seconds") rest on
   single figure/note locations that should be quoted verbatim when the dossier
   goes audit-ready.
2. **006's claimed reception items (Barker assertions).** The award, the Italian
   textbook, and the translations remain the about page's own claims, flagged as
   such — correct handling confirmed; they should stay flagged until
   `currently_outstanding.md` item 9 closes.
3. **008's unverified boast.** Same status as recorded; the preserved
   Prakken & Vreeswijk survey remains unread and is the natural yardstick.
4. **Velleman coverage stays cross-referenced, not duplicated.** `8WJ3UJWY`
   (Velleman's Proof Designer, 1994) is not a DD-003 member and must not be
   merged; until its own singleton dossier exists, the index's coverage map
   (added this session) records the dependency explicitly.
5. **Index status language.** The index previously described 006–008 as
   "draft, not yet reviewed"; with this review, all three are updated to
   reviewed-draft status with the outstanding gaps that remain.

## Fingerprints

After the corrections above, in their reviewed state. Fingerprints, not proof
of scholarly accuracy.

| File | SHA-256 |
|---|---|
| `006-1992-socratic-dialogue-dialog1.md` | `19442b77b3ac1b6bc8c05fec52ab3b42778c121877719b004837394730c0b82e` |
| `007-1992-symlog.md` | `7b3409f7edf3295e7b1a05463552f6ee7ea715e2a0d7820cb80bd26acfc5bb15` |
| `008-1995-oscar.md` | `49b93d2ac9f20755bbd6eeb6b6043d82380a23b5fce23d5613dd24eef0e4afd0` |

(Hashes taken immediately after the corrections recorded above.)

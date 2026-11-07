# Phase 2 source-material audit — independent review

**Date:** 2026-10-26  
**Disposition:** Phase 2 is substantively complete; no blocker found to proceeding to Phase 3. One existing local-preservation route should be corrected, and two evidence limitations should accompany acquisition. None requires reopening inventory approval or the earlier identity-machinery review.

Reviewed the [final audit](phase-2-source-material-audit-for-review-2026-10-26.md), [CSV](../../sources/emerging_philosophy/artifact-audit-2026-10-26.csv), [overrides](../../sources/emerging_philosophy/artifact-audit-overrides-2026-10-26.yaml), [approved inventory recommendations](phase-2-expected-artifact-inventory-recommendations-for-independent-review-2026-10-26.md), and [handoff](phase1-phase2-handoff.md), with the frozen snapshot, confirmed inventory, generator, and focused tests as supporting evidence.

## What checks out

- All **194 CSV rows** match the confirmed inventory in exact order, artifact ID, audit-unit ID, and requirement. All **140 audit units** are covered; there are **172 required**, **22 optional**, and no unknown or unconfirmed entries.
- The ten reported status counts are correct. Every row has evidence, and review flags consistently identify the 9 manual, 2 unresolved, and 4 lost-candidate slots.
- All **61 stored-PDF rows** identify an imported PDF attachment whose parent matches the named snapshot item. All **11 local-preservation paths** exist. All **58 overrides** agree with their CSV rows.
- The 9 manual slots refer to **7 distinct publication item keys**, consistent with the recorded acceptance of manual retrieval for seven publications.
- Audit tests independently passed: **17 runs, 83 assertions, 0 failures, 0 errors**. Current inventory verifier checks **1–7** also passed.
- Offline resume into temporary output files reproduced the CSV **byte-for-byte**, with **zero network requests**.

These are inventory-slot counts, not counts of distinct physical objects: the 61 PDF slots reference **49 distinct stored attachments**, and the 11 local slots reference **7 distinct paths**. This is legitimate reuse across audit units, not a coverage error. Phase 3 should acquire/verify shared objects once and associate them with all relevant slots.

## Small route correction: DIALOG1 is already local

**Location:** [CSV](../../sources/emerging_philosophy/artifact-audit-2026-10-26.csv), line 13, `EP-004/software/site`.

This row is `wayback`, but the approved slot explicitly concerns the preserved **2016 web implementation**. Its existing local artifact is:

`sources/emerging_philosophy/deep-dive/artifacts/dialog1/dialog1-20170203025603.html`

I verified its size (**401,245 bytes**) and SHA256 against the [existing manifest](../../sources/emerging_philosophy/deep-dive/artifacts/dialog1/MANIFEST.md):

`7f152ca593a927da365db05636f8d87895339273b349601c026888b9d567a529`

**Suggested correction:** add a curated `present` / `local-file` override for that slot, retaining Wayback as provenance/fallback. The **1990/1992 original** is a different slot and remains `lost-candidate`. This would change the headline counts to **73 present / 12 wayback**, with every other count unchanged. It is a route correction that avoids unnecessary retrieval, not a new inventory decision. No authoritative row was changed during this review.

## Carry these evidence limits into Phase 3

1. **EP-011/software/site — distinguish dataset recovery from interface recovery.** The override explicitly identifies an archived *Philosophy Published Subject Set* dataset and says the visualization interface was not verified. Preserve that qualification. Acquiring the dataset should not silently become a claim that the Knowledge Map interface has been recovered. Keep any unsatisfied part visible in the acquisition outcome.

2. **EP-105/paper/main — check the document's contents.** The recorded direct route is `eadh2018_programme_5dec1.pdf`, and its evidence is a HEAD response and PDF URL pattern. That establishes a candidate route, not that the programme contains the expected *Digital Ricoeur Data Model* text. During acquisition, identify the relevant pages and document whether they supply the expected text, an abstract, or only a programme listing. I did not fetch the PDF or conclude that it lacks the text.

More generally, the audit's `downloadable`, `clonable`, `direct`, and `wayback` labels are retrieval routes. Phase 3 still verifies the acquired content, identity, extent, and relevant dependencies. The report's explicit distinction between failed discovery and nonexistence is appropriate.

## Scope and conclusion

This was a review of the recorded evidence and existing local artifacts, not a new live-web audit. No network requests, artifact acquisition, live Zotero changes, or edits to authoritative audit records were performed. Only this review document was added; the four checked inventory/ledger/CSV/override source files remained byte-identical.

The full Rails suite, StandardRB, and the reported historical preservation-baseline check were not independently rerun; their results remain attributed to the implementation pass. The independently repeated checks above support the Phase 2 handoff without another general remediation cycle.

**Proceed with Phase 3 when the user gives the go-ahead**, carrying the local DIALOG1 correction and the two specific content checks into that work.

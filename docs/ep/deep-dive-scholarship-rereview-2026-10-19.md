# Re-review of the Emerging Philosophy deep dives — 2026-10-19

**Superseded for current draft status by [the 2026-10-20 re-review](deep-dive-scholarship-rereview-2026-10-20.md).** This remains a historical review of the earlier draft state; it does not cover dossier 005 or the October 20 edits.

## Assessment

The dossiers are substantially more transparent and source-conscious than the initial review found. The Sloman dossier now defines itself as a summary of the revised online edition and accurately records the limits of its selected textual checks. The TALLC dossier incorporates the complete Croy and Amidon chapter scan and now summarizes the full 2013 Hint Factory study, alongside two additional Croy papers. The Proof Designer dossier reflects the full Bedau and Moor chapter and distinguishes the authors' pedagogical rationale from demonstrated results. The index correctly calls its short queue a preview and uses *reviewed draft* rather than *complete*.

I found no new high-confidence misquotation or substantive paraphrase error in the passages checked against the supplied 1992 chapters, the full Stamper et al. (2013) article, and the frozen Sloman PDF. The TALLC dossier's summary of the 2013 design and outcomes is substantially accurate and adds the intervention mechanism. The important remaining methodological caveat is that the authors' claim of effects independent of instructor or semester is not directly tested in the reported pooled student-level outcome analyses. This is not certification of every sentence: the Sloman book review remains targeted rather than line-by-line, most TALLC research papers remain unread in full, and detailed source claims need precise locators. The current Sloman dossier now includes full summaries of the Stich and Hofstadter reviews; those updates are reflected in the fingerprint below.

I corrected three current-document inconsistencies during this re-review: TALLC's source register understated the degree to which applets had been exercised; its open questions said JAR preservation was unverified even though the dossier includes all 14 JARs and a manifest; and the runbook wrote a policy file before creating its directory. I also qualified the Velleman date and liveness description in the Proof Designer dossier.

The newly supplied Portoraro (pp. 229–234) and Barker–Scott (pp. 235–246) scans, together with the volume's contents pages, confirm the adjacent chapter identities and page sequence. I have now read both scans for context, using OCR checked against page images. Portoraro describes SYMLOG's Models environment for constructing finite interpretations and evaluating first-order sentences, including its internal data structures, variable-scope handling, undefined-value conventions, and worst-case runtime estimate. Barker and Scott describe DIALOGUE, a game-like Euthyphro tutor built with LEVEL 5 and a C natural-language interface; they explain the limits imposed by branching response paths and explicitly acknowledge where their playable program adds explanations and supporting arguments beyond Plato. Neither scan is summarized as a standalone dossier here. The file named as the edited book is an 11-page front-matter extract, not the full 268-page volume; its contents and contributor pages are useful bibliographic evidence but do not provide the other chapters' full text.

## Findings and remaining work

### 1. Put printed-page locators beside the detailed chapter claims

The TALLC dossier records reading the complete Croy and Amidon chapter, and the Proof Designer dossier records reading the complete Bedau and Moor chapter. Their detailed summaries are substantially better than abstract-only accounts. But their technical and historical claims are grouped without page-level locators: for example, the interface prototype, student work away from the computer, and proof-tree design in TALLC; and the configurable grammar/rule system, platform, demonstration date, and philosophical rationale in Proof Designer.

**Recommendation:** add printed-page references to each paragraph or compact claim cluster. Keep the scans' SHA-256 values and printed pagination in the source registers. This lets a reader audit the claims without repeating OCR or searching an eleven-page scan.

### 2. The TALLC publication trail is a research map, not yet a dependable bibliography

The dossier now marks Croy 1999, Croy 2000, and Stamper et al. 2013 as full texts read; most other works remain metadata- or abstract-level. Several entries are still difficult to identify or retrieve: the second 1988 item has no complete publication details; the 2007–2011 entries omit some author, venue, page, or identifier information; and some conference/journal versions need complete linked citations. The “relevance” column sometimes synthesises a work's contribution from an abstract or title, not a full reading. The author's online 2000 text includes a “CURRENT VERSION UPDATES” note correcting references after publication, so a claim about the journal issue should distinguish the published text from that subsequently updated online version.

**Recommendation:** label this section a provisional publication trail, retain the reading-status field, complete citations where metadata can be verified, and distinguish author-updated copies from publication versions. For abstract-level descriptions, say “the abstract presents/reports…”; reserve claims about arguments, methods, or findings for texts actually read.

### 3. The 2013 Hint Factory study is accurately summarized, but its independence claim needs qualification

The dossier accurately reports the six sections, three instructors, two semesters, sample flow, hint-enabled problem levels, pooled completion and attempt rates, dropout comparison, final grades, hint-use patterns, and the authors' stated cautions. The new short explanation of the Interaction Network/MDP mechanism makes the treatment more intelligible and records the previously observed but unmeasured practice of deleting steps until a hint becomes available.

One analytical limitation should remain explicit. Treatment was assigned by course section, while the paper reports pooled student-level t-tests for the main outcomes. It does not report cluster-adjusted inference or instructor/semester interaction analyses of treatment effects (though it does report a Professor × Semester baseline pre-test analysis). Its conclusion that results are independent of instructor or semester is therefore the authors' interpretation of the cross-over design, not an outcome interaction directly demonstrated in the reported tests. Thirty-eight of 241 pre-test participants are absent from the Deep Thought log analyses; the paper does not assess possible selection effects from that difference. These limitations do not erase the reported associations, but they constrain causal and general claims.

### 4. Keep summary scope and interpretation visible in Sloman

The dossier now clearly limits itself to the identified revised online edition and corrects the earlier validity/rigour, Kant, POPEYE, Epilogue, and Postscript issues. It also labels the extended-mind/stigmergy comparison as interpretation and records that the reviews were not read in full. Those are sound revisions.

What remains is a traceability issue: the ten chapter summaries contain many compact claims, while citations usually give a chapter-wide PDF range rather than a page or subsection for the specific point. Since the dossier is deliberately not a line-by-line comparison with the 1978 printing, readers should be able to distinguish original wording from dated additions wherever a later note materially changes the historical account.

**Recommendation:** add page-level locators to the most consequential or controversial claims, and use the existing “later notes” conventions consistently. Keep the 1978 collation and the remaining reception work (including Mackay and Ringle) marked outstanding rather than implying that the revised edition settles them.

### 5. Preserve the distinction between software availability and reproducibility

The TALLC runbook and manifest now correctly state that 14 JAR files are preserved, while wrappers, settings, images, and other live-host resources are not. The launcher is explicitly live-host-dependent and does not enforce the recorded hashes. The runbook also distinguishes launch, partial exercise, and end-to-end grading verification, and warns about `AllPermission` and possible data transmission.

The surviving record therefore supports partial artifact preservation and limited local execution, not a complete reproducible installation or verified course workflow. The corrected source register now says Dogs and Cats and Deep Thought were partially exercised, Justified Thought exited immediately, and the other applets were not tested.

### 6. Keep present-day and comparative claims dated

TALLC's site and applet availability statements are explicitly tied to checks on 2026-10-19, and the dossier distinguishes page modification dates from historical dates. Its claims about current classroom use, the HTML port, and the early status of its teaching/research integration remain appropriately qualified. The supplied site currently describes instructional programs in PHIL 2105 since 1983, but that institutional account alone does not establish uninterrupted operation or comparative priority. [UNC Charlotte's overview](https://pages.charlotte.edu/logic/) supports the site's own account; it is not independent evidence for continuous use.

The Proof Designer comparison now identifies 1994 as Velleman's Zotero date rather than a verified release date, and dates the live-site check. Keep such checks dated when the dossier is revised.

The added volume scan is not a full scan of the book. Its 11 pages cover front matter and contents. The separately supplied Portoraro and Barker–Scott chapters match the contents page ranges (pp. 229–234 and 235–246) and have now been read for context; no standalone dossiers have been drafted.

## Previously reported issues now corrected

- Sloman's ordinary reasoning is no longer described as generally valid; the dossier preserves the validity/rigour distinction.
- The Kant passage no longer attributes an unsupported innateness thesis to Kant.
- The Epilogue's qualified endorsement and the uncertainty in Sloman's retrospective POPEYE account are preserved.
- The Postscript separates its 1978 POP2 example from the Pop-11 conversion in September 2001.
- The extended-mind and stigmergy comparison is identified as a later interpretive comparison, not a claim of identity or influence.
- TALLC no longer claims exceptional longevity or treats its work as definitively early “learning analytics.” Its 2013 study account is now based on the complete paper and qualifies the authors' independence claim.
- The index describes its displayed list as a preview, and identifies Velleman's same-titled software as separate.
- The Proof Designer source-access and software-loss overclaims were corrected after the full chapter arrived.
- TALLC's 2013 Hint Factory article is no longer abstract-only: the complete 15-page paper is recorded and summarized, including its design, measured outcomes, and stated limitations.
- The TALLC source register's appraisal of applet testing and JAR preservation now matches the runbook and manifest. The runbook creates its working directory before writing the policy file.

## Source access and limits

- Sloman: frozen revised PDF, 190 pages, MD5 `a267d691c2b9d7326f551ad664ebf2e5`; targeted checks only, no full collation with a 1978 printing.
- Croy and Amidon: supplied five-page scan, printed pp. 213–217, SHA-256 `fe81e14fa95544dc125bb4bf90004089f845aaaa0253512b97734bec72062950`; complete chapter per the user's confirmation.
- Bedau and Moor: supplied eleven-page scan, printed pp. 218–228, SHA-256 `f0992f2feb5b4f9551847544ec2c0a66738debef8fbee82d53898ea7cbea9dc0`; complete chapter supplied and read, OCR checked against page images.
- Volume front matter: 11 pages, SHA-256 `55bb9a445e101f9c80b60346f49f7490730682882efbf3a50a368b72995913bd`; contents confirm four adjacent chapter ranges but this is not the full book.
- Portoraro, “Designing and Implementing Finite Structures in SYMLOG”: six pages, printed pp. 229–234, SHA-256 `bc2f25c96e1b7285887e60b565795999a4face5e119388efa1592cfdea3c6f40`; identity and page sequence checked, chapter not read for a substantive dossier.
- Barker and Scott, “Computer-Assisted Instruction for a Socratic Dialogue”: 12 pages, printed pp. 235–246, SHA-256 `ae4f2249fe1e212ee00dfa35ee08a6053db286c6df5608c34b9f7bf95e06cbb4`; identity and page sequence checked, chapter not read for a substantive dossier.
- TALLC: current and archived project pages, the complete 1992 chapter, applet JARs and manifest inspected. The full 2013 Hint Factory article (15 pages; SHA-256 `7a8173fc75d3dcc7c99491feeb6b45c7527af8f13327f5279629709394cdcacd`) and author copies of Croy 1999/2000 were read; the remaining cited research papers retain the reading statuses disclosed in the dossier.
- Reception: Hofstadter's and Stich's reviews have now been read in full and are summarized in the current Sloman dossier. Mackay and Ringle remain unread; Sloman's author-maintained review page is useful for discovery but is not a substitute for those reviews.

The two earlier reports remain useful for the initial version history, but their findings about the index, Proof Designer access, and some TALLC artifact/runbook details are superseded by this re-review and its corrections: [initial review](deep-dive-scholarship-review-2026-10-19.md).

## Current draft fingerprints

| File | SHA-256 |
|---|---|
| `001-1978-sloman-computer-revolution.md` | `16ca8f4c7c8b4c4e0642bea4cd14f2b56b0936560993aaff2c0b5c1f827dfb0e` |
| `002-1983-project-tallc.md` | `b3cd9b31e2946c0860613f9d60c59051f21b31a56af85070646d0fbb76ad2d25` |
| `002-1983-project-tallc-runbook.md` | `56f24d995afed82b6df8f01eaffd571e8044bf638f98542a340a1a37c99d5562` |
| `003-1988-proof-designer.md` | `c5ebe93af6f78c47c3ce5b840ad0af5d556450dd05a2bc2df571ea1cdef1620b` |
| `INDEX.md` | `bf2dab7cbd63dd6a91c9ccc38722528430e7dc6a01aa3599de38fb445d768e16` |
| `run-tallc-applet.sh` | `f10a9a3bf310130725a42f43d1a0c8a5bdf104de44a77bc247dfb795e1f55f2f` |

# Scholarly review of the Emerging Philosophy deep dives

> This records the initial review. For current findings and corrected source status, see the [re-review dated 2026-10-19](deep-dive-scholarship-rereview-2026-10-19.md); it supersedes claims below about index completeness, Proof Designer source access, and TALLC artifact/runbook status.

Reviewed 19 October 2026; source update and dossier 003 revision 19 October 2026. Scope: dossiers 001–003, INDEX, TALLC runbook, and launcher in `sources/emerging_philosophy/deep-dive/`. Dossier 003 and an index revision appeared during the initial review and received a supplementary pass. The user subsequently supplied full scans of both chapters from Burkholder's volume. This report records the updated status and revisions; findings on other dossiers remain as originally reviewed.

**Assessment: substantial research drafts, but not yet ready to be described as complete or as fully verified scholarship.** Sloman has extensive chapter coverage and several careful distinctions; TALLC has useful software investigation and a substantial bibliography. Nevertheless, there are demonstrable paraphrase errors, insufficient separation of historical versions, unsupported interpretative claims, and gaps between sources listed and sources demonstrably read. The problems are repairable. More confident prose alone would make them worse.

This review distinguishes confirmed textual discrepancies from claims that remain unsupported or incompletely checked. It does not certify every sentence. Full access to other important sources remains outstanding.

## Evidence and limits of this review

- Read all six files identified above. Inspected relevant snapshot records and the current clustering sheet without editing either. For the Proof Designer dossier, also checked Velleman's live site/help. The initial review predated receipt of the Bedau/Moor full text; it has since been read and the dossier revised.
- Located the exact Sloman PDF in `/home/groobiest/Zotero/storage/5M6S2VXM/PDF of Sloman's Computer Revolution in Philosophy.pdf`. Independently extracted its text and verified 190 pages, 1,228,488 bytes, and MD5 `a267d691c2b9d7326f551ad664ebf2e5`. SHA-256: `b598b6fc9fffdb1573a8e905e26229fb12c12cb8a05c32ffe3dc5d1b33d3d2c1`.
- Checked selected argumentative passages against that PDF, especially modal qualifications, representation/validity, number knowledge, historical explanations, and the Postscript. This was targeted textual verification, not a line-by-line collation of the whole revised book with the original 1978 printing. PDF page references below identify this frozen file; they must not be transferred to a changing online PDF.
- Inspected saved TALLC overview, pedagogical rationale, and grading-page HTML under `/tmp/opencode/tallc/`. These are accessible working copies, not an independently preserved archive with complete retrieval metadata. The online overview's indexed text corroborates the principal project description.
- Retrieved the publisher's abstract for Croy and Amidon (1992), then inspected the user's supplied scan `/home/groobiest/Dropbox/document transfer/Burkholder_PatC/2026-10-19 18.57.17.pdf` (five scanned pages; 12,601,336 bytes; SHA-256 `fe81e14fa95544dc125bb4bf90004089f845aaaa0253512b97734bec72062950`). The user confirms this is the complete five-page chapter (printed pp. 213–217); the fifth scan is tightly cropped. The separate Bedau/Moor chapter was subsequently supplied in `/home/groobiest/Dropbox/document transfer/Burkholder_PatC/2026-10-19 19.10.58.pdf` (11 scanned pages; printed pp. 218–228; 26,471,043 bytes; SHA-256 `f0992f2feb5b4f9551847544ec2c0a66738debef8fbee82d53898ea7cbea9dc0`). I read the chapter, using OCR as an aid and checking against page images. Both scans are treated as complete chapters per the user's confirmation/context.
- Retrieved the publisher's abstract and metadata for Stamper et al. (2013), not the full article. Verified the existence of distinct conference/journal publication records relevant to the bibliography. Requested the 2013 article and the Hofstadter/Stich reviews from the user after full-text retrieval attempts failed. The Sloman reviews listing is accessible; it is an author-maintained account, not a substitute for the reviews.
- Independently matched the three saved JAR checksums and sizes and the JDK tarball checksum in the runbook. Inspected JAR contents and manifests; no `.java` files occur in those three JARs. Did not execute legacy applets, reproduce previous GUI sessions, validate grading, or independently establish current classroom use.
- No Rails tests were needed: this review changes documentation only. The Proof Designer dossier and this review report were revised; no launcher, clustering assignment, or Zotero record was changed.

## Findings requiring correction

### 1. Sloman's claim about possible validity becomes a claim about how often people reason validly

**Confirmed substantive discrepancy.** [Sloman dossier, line 237](../../sources/emerging_philosophy/deep-dive/001-1978-sloman-computer-revolution.md#L237): “Most human reasoning is valid but not rigorous.”

In Chapter 7, PDF p. 101, Sloman says most forms of reasoning used in thinking and communication are not rigorous. He then says lack of an articulated justification does not entail invalidity: such inferences **may** be valid, and we may know their validity without articulating why. The summary turns a distinction between validity and rigour into an unsupported generalisation about the prevalence of valid reasoning.

**Suggested replacement:** “Sloman distinguishes validity from rigour: ordinary reasoning often lacks an explicit semantic justification, yet an inference can still be valid, and its validity can sometimes be recognised without articulating that justification.” Cite Chapter 7, PDF p. 101, alongside the relevant subsection.

This is the clearest example of why the next pass must check modal words and quantifiers, not only topic coverage.

### 2. The account of Kant adds an attribution the cited passage does not establish

**Unsupported attribution in an otherwise recognisable paraphrase.** [Sloman dossier, line 266](../../sources/emerging_philosophy/deep-dive/001-1978-sloman-computer-revolution.md#L266) says Kant is “wrong to make” arithmetic truths innate.

Chapter 8, PDF p. 114, endorses Kant's treatment of arithmetic truths as synthetic and discusses their necessity, then states that they are not innate and must be discovered through mathematical activity. That passage does not explicitly attribute the opposing innateness thesis to Kant. The draft should not introduce a claim about Kant's position without its own evidence. It also risks inviting readers to conflate non-empirical justification with innateness.

**Suggested replacement:** “Sloman endorses Kant's view that arithmetic truths are synthetic rather than merely consequences of definitions. He also holds that these truths are not innate: grasping them requires mathematical activity and reflection.” If the author intends a criticism of Kant on innateness, supply a separate, precise textual warrant.

### 3. The Postscript omits an explicitly documented change between editions

**Confirmed historical omission.** [Sloman dossier, lines 358–368](../../sources/emerging_philosophy/deep-dive/001-1978-sloman-computer-revolution.md#L358) gives the Pop-11 example under the original Postscript's page range without dating the implementation change.

The source's Postscript note [1], PDF p. 180, explicitly says the 1978 examples used **POP2** and were converted to **Pop-11 in September 2001**. The opening notice that the whole PDF is revised is helpful but insufficient for a chronological dossier: this is exactly the kind of historical detail readers may reuse independently.

**Required correction:** add that distinction beside the examples. Describe the general self-reference argument separately from its revised code presentation. More broadly, classify passages as original text, dated addition/revision, or edition provenance unresolved. Original chapter page ranges are not evidence that every sentence beneath them existed in 1978.

Without a 1978 scan, a complete original/revised collation remains unperformed. The dossier can instead explicitly scope itself as a summary of the identified revised edition of a book first published in 1978.

### 4. Qualification and attribution are lost in several other places

**Confirmed loss of qualification; broader editorial risk.**

- [Sloman, line 354](../../sources/emerging_philosophy/deep-dive/001-1978-sloman-computer-revolution.md#L354): “He accepts all five” strengthens the Epilogue's qualified inclination to accept the theses, followed immediately by doubts about the desirability of creating intelligent machines (PDF p. 176). Preserve the tentative endorsement; do not frame this as unconditional acceptance.
- [Sloman, line 314](../../sources/emerging_philosophy/deep-dive/001-1978-sloman-computer-revolution.md#L314): the failure of the POPEYE grant is stated as caused partly by Marr's influence and neural networks. The September 2001 note says the failure and incomplete publication **appear** partly attributable to a contemporary view associated with Marr; it discusses neural networks subsequently (PDF pp. 157–158). Report this as Sloman's retrospective interpretation, with its uncertainty, rather than an independently established causal history.
- Assertive formulations such as the refutation of reductionism or the failure of transcendental arguments often reflect Sloman's own rhetoric. Their assertiveness alone is not a paraphrase error. However, a standing note should establish that chapter summaries reconstruct his positions, and contested assessments should remain attributable when excerpts are read independently.

**Required correction:** review “all,” “most,” “must,” “cannot,” “refutes,” and causal “because” statements against the source. Preserve qualifications and distinguish the author's argument from the summariser's endorsement.

### 5. Interpretation and historical priority are not consistently identified

**Unsupported interpretative/historical claims, not demonstrated falsehoods.**

- [Sloman, line 201](../../sources/emerging_philosophy/deep-dive/001-1978-sloman-computer-revolution.md#L201) calls his treatment of environmental information stores “an early statement of the extended mind and stigmergy.” External storage and the porous system/environment boundary are in the source. The connection to named theoretical traditions is an additional interpretation; resemblance does not establish identity, priority, or influence.
- [TALLC, lines 188–193](../../sources/emerging_philosophy/deep-dive/002-1983-project-tallc.md#L188) calls the project one of the longest-lived and treats its research as an early example of later learning analytics. No comparative historical survey is provided. “Running since 1983” also suggests continuous operational use, which the available site history and surviving files do not establish.
- The characterisation of Croy's ethical papers as a sustained critique and defence of instructors needs substantive reading evidence. Titles and bibliographic records alone do not warrant that synthesis.

**Required correction:** explicitly mark the significance section as interpretation. Use bounded claims: the project site dates instructional computer use to 1983; the 1992 abstract documents an integration of teaching and research. Explain conceptual comparisons as comparisons and cite separate evidence for priority or influence.

### 6. “Complete” is not supported by the source-access and coverage record

**Major transparency and comprehensiveness gap.** [INDEX, lines 30–31](../../sources/emerging_philosophy/deep-dive/INDEX.md#L30) labels both dossiers complete. The TALLC dossier's [sources checked](../../sources/emerging_philosophy/deep-dive/002-1983-project-tallc.md#L207) lists web pages, manifests, OpenAlex/Crossref metadata, and video metadata, but does not record reading the cited research papers in full.

The [1992 chapter abstract](https://www.taylorfrancis.com/chapters/edit/10.4324/9780429301629-16/graphic-mouse-driven-interface-integrating-teaching-research-deductive-proof-construction-marvin-croy-john-amidon) supports the basic DT/JT distinction and collection of student-error data. The supplied five-page scan is the complete chapter. It adds important detail: the mouse-driven graphical interface was then a **prototype**, mostly complete for implicational-rule problems; the previous line-number/keyboard format was tedious and error-prone, leading students to do proof work away from the computer and enter results chiefly for checking; the chapter presents a graphical proof tree, rule palette, backward work from the conclusion, and linked forward/backward views. The authors frame the new interface as a way to observe proof-construction processes and their misuses, and express this as a goal—not a demonstrated learning outcome. Cite the chapter's printed pages and preserve those temporal qualifications. “Main paper” remains an editorial characterization, not an authorial or bibliographic designation.

Sloman's reception section identifies reviewers but barely reconstructs their arguments. The [author's reviews page](https://cogaffarchive.org/crp/crp-reviews.html) also reports MacKay's criticism concerning omitted predecessors. An account of reception should distinguish reviewers' own arguments from Sloman's retrospective responses. Reading an author's report of criticism is not equivalent to reading the critic.

**Required correction:** use separate statuses for drafting, primary-text access, textual verification, historical verification, and review. For each cited work, record `full text read`, `selected pages read`, `abstract only`, `metadata only`, or `not accessed`. Limit conclusions accordingly. Do not imply that every peripheral publication must be read to describe the software; do require full reading for substantive claims about a paper's argument or evidence.

### 7. The empirical significance claim lacks the information needed to assess it

**Supported at abstract level, inadequately contextualised.** [TALLC, lines 154 and 193](../../sources/emerging_philosophy/deep-dive/002-1983-project-tallc.md#L154) says hints improve persistence/completion. That direction of result is supported by the [2013 publisher abstract](https://journals.sagepub.com/doi/abs/10.3233/JAI-130029); it should not be called invented. The abstract describes a switching-replications design involving three instructors across two semesters and reports tutor-use and performance outcomes.

The dossier supplies no sample size, allocation details, effect estimates, attrition treatment, limitations, or distinction between task completion, retention in the tutor, and broader learning. It also does not distinguish author-reported results from an independent assessment.

**Required correction:** until the full paper is read, explicitly attribute the result to the abstract and name the measured outcomes. After reading, add a compact study account covering population, comparison, outcomes, effect size/uncertainty where reported, and the authors' limitations. Do not infer general educational efficacy from this particular study.

### 8. The bibliography combines distinct conference and journal records

**Confirmed bibliographic ambiguity.** [TALLC, lines 151 and 154](../../sources/emerging_philosophy/deep-dive/002-1983-project-tallc.md#L151): “2010 … LNCS / IJAIED” and “2011/2013 … IJAIED” leave different publications represented as ambiguous dates/venues.

For expert seeding, the [ITS 2010 publisher contents](https://link.springer.com/book/10.1007/978-3-642-13437-1) identify a conference chapter on pp. 31–40; the [ERIC record](https://eric.ed.gov/?id=EJ954191) identifies a 2011 journal article in IJAIED 21(1–2), pp. 153–167. For experimental evaluation, the journal publisher identifies the cited DOI as a 2013 article, while [Croy's publication list](https://pages.charlotte.edu/marvin-croy/publications/) also identifies a 2011 conference publication. The latter list was available through indexed text during this review; its direct page fetch failed.

**Required correction:** give each version a distinct bibliographic entry, full authorship, date, venue, pages, and identifier where verified. Link related versions but do not assume they contain identical evidence. Mark the 1999 OpenAlex-only entry provisional pending resolution of its document type and venue. A dissertation, conference item, or duplicate record should not silently become a journal article.

### 9. Citations and artifact records do not yet allow efficient claim verification

**Cross-cutting reproducibility gap.** The Sloman checksum and chapter page ranges are strengths. But ranges of tens of pages do not readily support individual contentious paraphrases. TALLC's source list mostly names pages instead of giving exact URLs; Wayback years do not identify captures. Its legacy-version and present-tense claims are difficult to reconstruct from a list of checked sites.

**Required correction:** add citations at the paragraph or claim cluster level, with narrower locators for contentious claims. Give exact page URLs, archive capture timestamps, access dates, and reading scope. Keep observation time distinct from page publication/update time and the historical date asserted by the page. A live page saying work is underway does not establish that the work continues in 2026; “no port found in these searches” is narrower than no public port existing.

Maintain a source register mapping a stable identifier to the artifact, edition, hash where appropriate, and relevant locator. Record unsuccessful access attempts as such. A blanket “sources checked” list cannot distinguish which sources support which sentences.

### 10. The index overstates its coverage; its rejected identity grouping was corrected during review

**Confirmed coverage inconsistency; identity issue now corrected externally.** [INDEX, lines 15–26](../../sources/emerging_philosophy/deep-dive/INDEX.md#L15) calls the queue the full population, but displays a short preview and an ellipsis. The initial version also grouped `8WJ3UJWY` with `LYZJNKEZ` and `9PVXVXNY` as Proof Designer. A concurrent edit, not made by this reviewer, now separates Velleman's project. That identity problem is no longer outstanding in the index.

The authoritative YAML explicitly marks both edges from `8WJ3UJWY` to those items `unrelated`. Its member record dates Velleman's program to 1994. The revised index inserts that 1994 entry ahead of the 1990/1991 entries, so it still does not meet its stated chronological-order convention.

**Required correction:** label the displayed queue a preview or actually generate the full queue, and either sort by date or explicitly distinguish a cross-reference from a queue entry. Retain the corrected identity separation. Cross-reference the authoritative sheet rather than retaining stale clustering assertions. Do not change the sheet to fit the narrative.

### 11. The software record establishes partial inspection, not preserved reproducibility

**Confirmed limits of the current procedure.** The runbook helpfully says Dogs and Cats and Deep Thought opened, and Justified Thought exited. Those are useful observations, but window opening is not verification of full pedagogical functionality. The status matrix should distinguish discovered, downloaded, checksum verified, launched, exercised, and grading verified.

The [launcher, lines 79–89](../../sources/emerging_philosophy/deep-dive/run-tallc-applet.sh#L79) loads JARs and resources directly from the remote host. It does not enforce the recorded checksums or pin dependencies. The [runbook's final cleanup section](../../sources/emerging_philosophy/deep-dive/002-1983-project-tallc-runbook.md#L183) treats the downloaded JARs as disposable even though source/JAR preservation is an open question. Hashes without retained bytes will not reconstruct a lost program.

**Required correction for archival claims:** preserve an identified local artifact set and manifest before deleting working copies; include dependencies needed for the exercised functions, commands, logs, and bounded test results. Label the existing launcher a live-host-dependent convenience, not a frozen reproduction. The claim that certificates cannot function at all is stronger than the logged evidence: loss of LMS context and a successful window launch do not alone establish every certificate path's behaviour.

Minor runbook issues: its steps write into `/tmp/opencode/tallc_run` without creating that directory, and the shell launcher's final `exec` bypasses its shell's ordinary EXIT-trap cleanup on successful replacement. These are secondary to the scholarly findings and were not repaired during this review.

### 12. Proof Designer: source-access and loss-status issue resolved after full chapter arrived

**Confirmed overreach in the version initially reviewed; corrected after the full chapter was supplied.** The earlier [Proof Designer dossier](../../sources/emerging_philosophy/deep-dive/003-1988-proof-designer.md) described the program as effectively “lost or offline” and treated the paper as present only through metadata and an abstract. The user then supplied an 11-page scan of the complete chapter (printed pp. 218–228), which has now been read and recorded in the dossier with its file hash. The revised dossier no longer implies that a failed public search proves loss; survival and current availability of the software remain unknown.

The full text resolves the paper-access gap. It also confirms that the software lets users define grammars, symbols, rules, axioms, and proof formats, and reports a Macintosh/Lightspeed Pascal implementation and a preliminary demonstration on 25 August 1988. It does not establish learning outcomes, classroom uptake, or whether a software copy survives.

The initial dossier's explicit access disclosure was good practice for its time; the revised dossier now describes the full chapter's evidence and keeps software survival and educational efficacy open.

### 13. Proof Designer's grouping description should distinguish the graph edge from audit-unit assignment

At the review date, the YAML recorded the `LYZJNKEZ`–`9PVXVXNY` pair as `same_cluster: true` under “Proof Designer (Bedau & Moor) <-> PROOF DESIGNER workbench paper.” That was the historical state assessed here, not the current assignment. Under the later gate and the 2026-10-25 terminology ruling, EP-002 is an **anchored singleton** containing the program `LYZJNKEZ`; the chapter `9PVXVXNY` is a separate singleton audit unit with a `describes` cross-reference. A graph edge does not by itself settle an inventory role.

The current dossier should therefore report the genuine Bedau/Moor Proof Designer project without treating the chapter as a member of the EP-002 audit unit. EP-002 remains an opaque audit-unit ID, not a project ID; legacy `same-project` would mean same complex where present.

Also keep Velleman's “1994” explicitly labelled as **Zotero metadata, release date unverified**. His [current help page](https://djvelleman.github.io/pd/help/Help.html) verifies the JavaScript implementation and educational purpose, but does not date that implementation to 1994. The dossier's identity table correctly qualifies the Bedau/Moor date as metadata; apply the same discipline to the comparison. This review does not establish the actual first release date of Velleman's software.

## What the drafts already do well

- Sloman covers all ten chapters, the Epilogue, and the Postscript, rather than reducing the book to its manifesto. It represents explaining possibilities, conceptual analysis, representational choice, number learning, and perceptual architecture as connected subjects.
- It explicitly identifies the reading copy as revised, records a matching checksum, separates many later notes, recognises the distinction between possibility explanation and prediction, and includes limitations of POPEYE and computational modelling.
- TALLC distinguishes a suite from an individual program, identifies related software, documents substantive technical observations, and lists unresolved pre-Java history, code lineage, source availability, and current teaching use.
- The runbook reports an unsuccessful launch rather than concealing it. Its three JAR hashes and JDK hash match the available local artifacts.
- Proof Designer now distinguishes author-reported design and aims from demonstrated outcomes, records its full-text source, and correctly separates the identically named programs.

These strengths are reasons to revise carefully, not to discard the work. The primary problem is that the certainty and completion claims exceed the documented verification.

## Standard for the next revision

1. State exactly what is being summarised: a particular edition of a text, a historically changing project, or a selected body of research. Define the intended coverage; “comprehensive” must be relative to that scope.
2. Identify the source and reading extent for each substantive account. Separate the original text, later revisions, contemporary documentation, retrospective recollections, and present-day observations.
3. Reconstruct arguments as question → thesis → reasons/evidence → qualifications → consequences. Topic lists alone are insufficient, but every tangential paragraph need not be reproduced.
4. Retain the author's uncertainty, quantifiers, distinctions, and acknowledged limitations. Distinguish a position criticised by the author from an independently accurate account of that position.
5. Mark interpretation and proposed historical connections. Supply comparative evidence before claiming priority, influence, or exceptional longevity.
6. For empirical research, identify what was tested, against what comparison, with which outcomes and limits. Distinguish software availability, observed behaviour, classroom use, and demonstrated educational effects.
7. Present reception through the reviewers' actual arguments when available, with precise references and a separate account of the author's reply. State gaps where full text is unavailable.
8. Resolve bibliography/version identities and stale index statements. Preserve sources supporting technical observations where possible and document access failures.
9. Finish with an explicit audit status and unresolved questions. A source-constrained draft can be excellent and transparent without pretending that inaccessible material has been verified.

## Source material still needed

The user has been asked for local paths or accessible copies of:

- Stamper et al., the 2013 IJAIED article, DOI `10.3233/JAI-130029`.
- Hofstadter's 1980 and Stich's 1981 reviews of Sloman.

Further requirements depend on final scope: an original 1978 Sloman scan for exhaustive edition collation; full texts of the ethical/pedagogical papers if retaining substantive interpretations of their arguments; and other reviews if claiming a comprehensive reception history. These are not established errors in those sources; they are limits of the present review.

The supplied Bedau and Moor chapter (printed pp. 218–228) has now been read and its dossier revised. Still outstanding for a complete review of the wider deep-dive set are the full Stamper et al. (2013) article and the Hofstadter and Stich reviews listed above.

## Reviewed draft fingerprints

Line references above refer to these versions. Markdown `#L` fragments are locator hints; some local viewers do not navigate to them.

| File | SHA-256 |
|---|---|
| `001-1978-sloman-computer-revolution.md` | `6eb79e15ed0c2504d7fd7c53cd61396e11293cbc2b6c65de0e9ca48d599015a1` |
| `002-1983-project-tallc.md` | `73a71d182064cdc8dc31d31f899a8a2f99b12e25ef365a5f125357e5135069ea` |
| `002-1983-project-tallc-runbook.md` | `e3939b2ac069f3a25cb795efcdd53dc727a2accc47a67d9177eec108319cf2d1` |
| `003-1988-proof-designer.md` | `6811cc9c6d0157ddf9e85c224a903aaad029fe2d4418d4783f28b12e7ce02ed2` |
| `INDEX.md` | `5b9830b8c894ba829dc7b7e16f73306b3536792795604623de8ee39ae8f63d59` |
| `run-tallc-applet.sh` | `cee8ce195a514b715698598a4b3487db65f41f63c658ec486dbd72bb21fbb22b` |

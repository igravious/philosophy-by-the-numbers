# Currently Outstanding — Emerging Philosophy Deep Dives

**Status:** 2026-10-20. Companion to the review documents and the dossiers in `sources/emerging_philosophy/deep-dive/`.

**Scope note.** Core works are collection items dated 1978–1999. Sources from the 2000s are included only when they directly document a 1990s project. Sources from the 2010s are later lineage/reception, not new queue entries; Stamper et al. 2013 is the outer edge of that category.

**Recently closed.**
- **Stamper et al. 2013** — full PDF supplied and read; study account added to `002-1983-project-tallc.md`.
- **Stich 1981** — read in full from the author-mirrored copy; reception section updated.
- **Hofstadter 1980** — read in full from the AMS Bulletin PDF; reception section updated.
- **Croy 1999 and 2000** — read in full from the author's PDFs; the 1999 venue is resolved as *Journal of Computers in Mathematics and Science Teaching* 18(4): 371–386.
- **TALLC JARs** — 14 applet JARs preserved in `artifacts/tallc/` with a manifest.
- **TALLC 1992 chapter** — five-page scan read in full; interface details added.

**User ruling, 2026-10-20 (scoping).** Croy items that do not pertain specifically to
philosophy or a universally recognised sub-field are out of scope and no longer
tracked: 1985 (*Metaphilosophy*, ethics of CAI in the abstract), 1989 (expert
systems in education), 1993 (feedback study), 1995 (educational expert-system
simulation), and 2000 "Faculty as Machine Monitors" (higher education generally).
The dossier's source register still lists them by title with "not accessed"
status; that remains honest and correct — they are simply not owed a reading.
Meta-rule behind the ruling: the interest is computing applied to philosophy —
***philosophic computing*** (the user's coinage; looser synonyms like
"computational/digital philosophy" are ambiguous, e.g. "digital philosophy"
also names the Wolfram/Zuse program), on the analogy of humanities computing
and scientific computing. Philosophical reflection *about* computing itself is
out of scope except where a collection item requires it.

This file tracks what remains.

## 1. Stamper et al. 2013 — the empirical claim

**Status: closed 2026-10-19.** The full article was read from `/home/groobiest/Dropbox/document transfer/stamper2013.pdf` (15 pp; 794,913 bytes; SHA-256 `7a8173fc75d3dcc7c99491feeb6b45c7527af8f13327f5279629709394cdcacd`).

What the full text established:
- Six sections, three instructors, Spring 2009 and Fall 2009; each instructor taught one semester with hints and one without (switching replications; not student-level randomisation).
- 241 students in the pre-test, 203 with Deep Thought logs (105 Hint, 98 Control), 203 final grades.
- Eleven Deep Thought problems; hints on seven Level 1 and Level 2 problems; Level 3 was an unhinted post-test.
- Completion: L1 78.2% vs 61.2% (d = 0.51, p < 0.001); L2 67.4% vs 42.4% (d = 0.64, p < 0.001); L3 59.0% vs 41.5% (d = 0.39, p = 0.006).
- Attempt rates: no L1 difference; L2 73.2% vs 56.0% (d = 0.44, p = 0.002); L3 71.5% vs 57.0% (d = 0.33, p = 0.021).
- Dropout after L1: 9% Hint vs 28% Control; χ²(1) = 11.05, p = 0.001; odds ratio 3.61.
- Final grade: Hint 83.96 (SD 15.74) vs Control 77.82 (SD 21.77); t(201) = −2.31, p = 0.022, d = 0.33.
- Authors' limitations: possible "trail-blazing" effect; hints on only some problems should be rotated; analysis less sophisticated than knowledge tracing; MDP does not explicitly model student knowledge. No separate attrition analysis for the 38 pre-test participants without logs.
- Scope: one course, section-level quasi-experiment; results should not be generalised to all logic instruction or all CAI.

Full account: `sources/emerging_philosophy/deep-dive/002-1983-project-tallc.md` (section "The 2013 Hint Factory study").

## 2. Hofstadter 1980 and Stich 1981 — reception

**Both are closed.**

Stich's mirrored review argues that Sloman uses "possibility" in several senses; in examples such as Newton explaining the tides, the modal formulation is either a paraphrase of the ordinary explanatory claim or implausible as stated. Stich concludes that the attempt to show science aims at explaining possibilities — and therefore that AI is continuous with science — does not succeed. He praises Chs. 4, 6–9, criticises the tone of Chs. 1–3, and questions the claim that unconscious processes are "essentially similar" to conscious ones. Sloman accepts the style criticisms and replies partially in "Construction kits…".

Hofstadter agrees with Sloman's central thesis and praises Part II ("Mechanisms") — architecture, representation/indexing, number learning, POPEYE, and the candid account of AI's limits. He agrees on emotions as complex interactions and criticises shallow models such as PARRY. His main disagreements are the harsh tone, the anti-reductionist rhetoric ("AI is the epitome of the reductionistic view of mind"), the relatively uninteresting Chs. 2–3 ("good AI speaks for itself, without need of verbose philosophical defenses"), and the cursory dismissal of Lucas/Gödel. His verdict is still that the book is "a significant and highly original contribution to the debate about minds and machines."

**Remaining, optional:** Mackay's 1979 *BJPS* review and Ringle's 1982 *Noûs* review were not read. The author's page reports Mackay's criticism about omitted predecessors. These are lower priority than the two main reviews.

**Priority:** low for the core exposition; both main reception sources are now read.

## 3. Original 1978 Sloman scan — edition history

**Why it matters.** The dossier summarises the revised online edition. We know at least one concrete change: the Postscript used POP2 in 1978 and was converted to Pop-11 in September 2001. Other notes and additions may sit inside the original chapter page ranges. Without a 1978 scan, we cannot tell which sentences are original and which are 2001/2015/2016 additions.

**What a scan would settle.** Original pagination and text for the key passages (Ch. 2 on possibilities, Ch. 7 on validity, Ch. 8 on Kant/numbers, Ch. 10 on consciousness, the Postscript). It would also let us verify the 1978 title page, preface, and bibliography.

**Access.** OpenLibrary lists a borrowable Internet Archive copy (`computerrevoluti00slom`); ILL or a used copy are the other routes. The author's site does not host a full 1978 scan.

**Priority:** medium-high for historical claims; not necessary for a cursory summary.

## 4. Croy's logic and philosophy papers — interpretation

**Scope (user ruling, 2026-10-20).** Only Croy papers that pertain specifically to
philosophy or a recognised sub-field are tracked. Logic (1986, 1988 ×2, 2004,
2010) and philosophy of mind (2002) are in scope. Papers on CAI in the abstract,
expert systems in education, feedback research, and faculty roles in higher
education generally (1985, 1989, 1993, 1995, 2000) are out of scope.

**Still unread, in scope:**
- 1986 — "The Current State of Computer-Assisted Instruction for Logic," *Teaching Philosophy* 9(4): 333–350.
- 1988 — "The use of CAI to enhance human interaction in the learning of deductive proof construction," *Computers and the Humanities* 22(4): 277–284.
- 1988 — "Computer-assisted instruction and rule applications for deductive proof construction," *Collegiate Microcomputer*.
- 2002 — "Philosophy of Mind, Cognitive Science, and Pedagogical Technique," *Metaphilosophy* 33(1–2): 49–69.
- 2004 — "Making Useful Comparisons of Traditional, Hybrid, and Distance Approaches to Teaching Deductive Logic," *Discourse* 4(1): 159–170.
- 2010 — "Teaching the Practical Relevance of Propositional Logic," *Teaching Philosophy* 33(3): 253–270.

**Why they matter.** The 1986 and 1988 papers document the state of logic CAI
and the interaction claims behind TALLC's design; the 2002 paper connects the
pedagogy to philosophy of mind and cognitive science; 2004 and 2010 bear on how
the software's teaching approach is evaluated and justified.

**Access.** Taylor & Francis (*Computers and the Humanities*), Philosophy
Documentation Center (*Teaching Philosophy*), Wiley (*Metaphilosophy*), UNC
Charlotte library/ILL; Croy's page for any posted PDFs; author contact.

**Priority:** medium-high for interpretive claims; not needed to describe the software.

## 5. Current classroom use — liveness

**Why it matters.** The site says PHIL 2105 uses the applets in Canvas, but the overview was last modified in 2018. We do not know whether the course still uses them in 2026, which applets, or in what configuration. This affects whether TALLC is active, dormant, or archival.

**How to close it.** Contact Marvin Croy; check the UNC Charlotte catalog and recent section listings; ask the department; inspect Canvas only with authorised access; look for recent publications or presentations. The site itself is not sufficient.

**Priority:** medium.

## 6. Grading and certificate paths — technical verification

**Why it matters.** The local `appletviewer` launch bypasses the LMS. The JARs contain `Certificate`, `CertThread`, `DataThread`, `getCertificateCgiPath`, and `getResearchCgiPath`; strings include "Your progress has been recorded on the server" and instructions to email certificate numbers to the instructor outside WebCT. We do not know whether the CGI still works or what data is transmitted.

**How to close it.** Decompile or inspect `CertThread`, `DataThread`, `Certificate`, and `Settings`; extract the configured CGI endpoint from `settings/global.properties`; run a proof to generate a certificate; point the applet at a stub server or capture the network request; test with and without LMS parameters. This is doable offline and matters for the privacy warning ("Applet set to collect research data").

**Priority:** medium; technical and privacy-relevant.

## 7. Bedau/Moor software survival — the historical artifact

**Why it matters.** The chapter describes a Macintosh/Lightspeed Pascal application of about 200K, with a proof editor, proof checker, grammar editor, rules editor, and user-definable logic systems. Work began in summer 1987; a preliminary version was demonstrated on 25 August 1988 at the Third International Conference on Computers and Philosophy at Dartmouth. No public copy has been found. A surviving copy would let us test the "programmable" claims and preserve a notable 1980s philosophy-software artifact.

**How to close it.** Contact Mark Bedau and James Moor; ask about CAP conference materials; check Dartmouth and Reed College course archives; look for old Macintosh disks; try software-preservation groups. The chapter gives no distribution address.

**Priority:** medium; historical/preservation rather than exposition.

## 8. SYMLOG software survival — the historical artifact

**Why it matters.** DD-007's chapter (1992) describes a Pascal Models environment; the Zotero program record `XUR4E5SE` only points at the much later symlog.ca web site and holds no file. No copy of the Pascal-era system (1989–1994) has been located. A surviving copy would let us test the *Logic with Symlog*-era claims (Fitch-style proof construction, automated advice) and preserve a cornerstone of the era's semantics-teaching software.

**How to close it.** Contact Frederic Portoraro (fred.portoraro@symlog.ca, per his live profile page); ask the University of Toronto philosophy department and IBM Canada-era records; look for the Prentice-Hall book's bundled software; check software-preservation groups. Also: identify the chapter's cited "Portoraro, 1989, 1990."

**Priority:** medium; same character as the Bedau/Moor Proof Designer search (item 7).

## 9. DIALOG1 — 1990 LEVEL5 program and Barker claims

**Why it matters.** DD-006 rests on the 1992 chapter (read in full) and on Barker's own 2016-era web pages (preserved). The original LEVEL5 program (started March 1990; Scott, Barker, Daugherty), its natural language interface, and the third part of the program have no located copy. Several claims — the 1988 "Best Theoretical Paper Award," translation into other languages, incorporation into an Italian philosophy textbook — come from Barker's own page and are unverified.

**How to close it.** Locate the 1988 IBSCUG paper (Barker & Clayton, "Building Expert Systems by Learning to Formalize Arguments," pp. 67–73); identify the Italian textbook; ask Don Barker whether any LEVEL5-era files survive; confirm the award with the conference's records.

**Priority:** medium-low; exposition is unaffected, provenance is.

## 10. LPL (DD-009) — software binaries and the 1998 record date

**Why it matters.** DD-009 (2026-10-26) covers EP-007, the courseware complex.
The two edition texts are preserved and read (press-file PDFs in
`deep-dive/artifacts/lpl/`), but the *running software* — Tarski's World 6.0/7.x,
Fitch, Boole, Submit, and the Grade Grinder's earlier generations — has no
preserved installer anywhere in the collection: every generation is gated by a
purchased registration ID, and the record's 1998 date could not be pinned to a
documented 1998 event (earliest web evidence is April 1999; CSLI catalog page
dated 8/31/99; press file dated 9 August 1999).

**How to close it.** Locate installers of any generation (1999 CD-ROMs with
CD-face registration IDs; the 2011 3.x/7.x desktop installers; the 2005–2019
ggweb desktop era) via software-preservation groups, used-copy CD scans, or
archived download routes; determine the intended referent of `ZSE63NLV`'s
1998 date and record it for the Phase-5 metadata fixes. Additionally, the
route `EP-007` uses for the second-edition PDF (the UC route) is stale — the
Wayback capture of that route supplied the text for reading.

**Priority:** medium-high for artifact survival (the package is commercially
the largest of all courseware in the collection); low for the date question
(metadata-only).

## 11. Pollock chapter and Digital Phoenix volume (DD-010/DD-011) — chapter text, record details

**Why it matters.** DD-010 (2026-10-26) established the chapter's identity:
EP-039 = `HVU3VI2E`, "Procedural Epistemology", Part I ch. 1 of *The Digital
Phoenix* (EP-040), **pp. 17–36** of the 412-pp. 1998 anthology (record's
`pages` field empty — Phase-5 metadata fix), with the 1999 *Blackwell Guide
to Epistemology* variant (ch. 16, pp. 383–414) disambiguated as a separate
commissioned text. The chapter's 20 pages remain unread: no legitimate route
exists (no chapter-level DOI; the IA scan of the volume
`digitalphoenixho0000unse` is lending-restricted).

**How to close it.** Acquire the chapter text via the IA lending scan (borrow,
read pp. 17–36), library scans, or the volume's other holdings; record the
span `17-36` on the record at the Phase-5 metadata pass; read the 1999 Guide
chapter (Wiley) and the Tomassi review (BJPS 1999) when accessible; and
DD-011 (the volume itself) should re-use the volume facts established in
DD-010 rather than re-derive them.

**Priority:** high for the chapter's text (the record cites a paper whose
content is unknown in the collection at present); low for the volume record's
details (already gathered).

## 12. OSCAR — unverified boast and unset fate details

**Why it matters.** DD-008 (2026-10-20) established that OSCAR 3.31 runs end-to-end under modern SBCL after six catalogued distribution defects — the collection's only live-tested AI codebase. But two things remain open: (a) the site's boast that OSCAR's defeasible reasoner is "the world's first such reasoner capable of operating in a rich logical environment like first-order logic in which logical consistency is not decidable" is recorded but unverified against the defeasible-argumentation literature (the Prakken & Vreeswijk survey, preserved in the mirror, is the natural yardstick); (b) the original host `oscarhome.soc-sci.arizona.edu` is dead — its Wayback capture existence is now established (item below, 2026-10-26), leaving the full CDX walk and the Arizona-only items as the open part.

**How to close it.** ~~Retry Wayback CDX~~ — **partially closed 2026-10-26:** the CDX API is reachable again; the original host has 200-status captures from 2000-08-31 to at least 2010-06-29 (bounded 100-URL retrieval), including Arizona-era items the mirror lacks (`OSCAR.htm` 2000 vintage, `OSCAR.zip` complete 2000 distribution, `Code for probable probabilities.zip`, `Degrees.pdf`, older problem-file variants). Remaining: full CDX walk; decide in Phase 3 which of the Arizona-only items to acquire; read the preserved Prakken & Vreeswijk survey and check how OSCAR's defeasible reasoner compares with the systems it covers; read preserved papers (esp. "Rational Cognition in OSCAR" ATAL-99 and the manual chapters) for pinpoint claims; trace what became of OSCAR-MDA (emergency-room decision support, 1996); search for OSCAR versions after 3.31 or the never-distributed `OSCAR_3-31-acl.lisp` (the CDX scan so far shows the `-acl` file was also absent 2000–2010, supporting the read that it was never distributed).

**Priority:** low for the boast (cited-as-claim in the dossier), medium for Wayback archaeology (affects provenance of what else may have existed but was never mirrored).

## Chronological outstanding (open items only)

1. **1978 — original Sloman scan.** Edition history: distinguish 1978 text from 2001/2015/2016 additions.
2. **1986 — Croy, “The Current State of Computer-Assisted Instruction for Logic,”** *Teaching Philosophy* 9(4): 333–350.
3. **1988 — Croy, “The use of CAI to enhance human interaction in the learning of deductive proof construction,”** *Computers and the Humanities* 22(4): 277–284.
4. **1988 — Croy, “Computer-assisted instruction and rule applications for deductive proof construction,”** *Collegiate Microcomputer*.
5. **1988 — Bedau/Moor *Proof Designer* software copy.** The program’s survival, not the 1992 chapter (already read).
6. **2002 — Croy, “Philosophy of Mind, Cognitive Science, and Pedagogical Technique,”** *Metaphilosophy* 33(1–2): 49–69.
7. **2004 — Croy, “Making Useful Comparisons of Traditional, Hybrid, and Distance Approaches to Teaching Deductive Logic,”** *Discourse* 4(1): 159–170.
8. **2010 — Croy, “Teaching the Practical Relevance of Propositional Logic,”** *Teaching Philosophy* 33(3): 253–270.
9. **Present (2026) — current classroom use.** Whether PHIL 2105 still uses the applets, which ones, and in what Canvas configuration.
10. **Present/legacy — grading and certificate paths.** Whether the CGI/server path still works and what data it transmits.
11. **1992 SYMLOG program copy.** DD-007 above (#8).
12. **1990/1992 DIALOG1 LEVEL5 copy + Barker claims.** DD-006 above (#9).
13. **1998/1999+ LPL software binaries + `1998` record date.** DD-009 above (#10); installers of any generation are uncollected and registration-gated.
14. **1998 — Pollock chapter (PP. 17–36) text; *The Digital Phoenix* volume (DD-011 next).** DD-010 above (#11); chapter unread (IA lending scan only); 1999 Guide variant unread.
15. **2000–2010 OSCAR capture history, Arizona-only items.** DD-008 above (#12); partially closed 2026-10-26 (CDX range established, full walk owed).

Out of scope (user ruling, 2026-10-20; CAI in the abstract, not philosophy-specific):
Croy 1985, 1989, 1993, 1995, and 2000 “Faculty as Machine Monitors”.

Closed and therefore not listed: Stich 1981; Hofstadter 1980; Croy 1999; Croy 2000 (“Problem Solving, Working Backwards…”); Stamper et al. 2013.

## Priority order

1. **Croy 1986/1988/2002/2004/2010** — logic and philosophy-of-mind claims only.
2. **1978 Sloman scan** — edition history.
3. **Current classroom use** and **grading paths** — liveness and technical verification.
4. **Bedau/Moor software** — artifact survival.
5. **LPL software binaries** (#10) — artifact survival of the courseware lineage's running code (its texts are already preserved).
6. **Pollock chapter text** (#11) — the record cites a paper unread anywhere in the collection; IA lending scan is the known route.

The first affects substantive interpretive claims; the others affect provenance and liveness. Reception is now covered by the two main reviews.

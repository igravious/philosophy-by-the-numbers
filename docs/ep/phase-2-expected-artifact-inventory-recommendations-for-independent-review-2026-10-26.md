# Phase 2 expected-artifact inventory recommendations — for independent review

**Date:** 2026-10-26  
**Status:** APPROVED by the user and enacted in `decisions.jsonl`; retrieval classification follows separately

This packet covers all **329 existing draft entries** and **28 additions**. It reconciles four independent range reviews and an independent consistency review. The complete row-level data is in `sources/emerging_philosophy/inventory-recommendations-2026-10-26.csv`.

**Outcome:** all 357 recommendations were approved, including a separate required `EP-004/software/original`. The derived inventory now contains 194 confirmed artifacts: 172 required and 22 optional, with no unknowns. EP-047's chapter is required and its outdated absent-project note has been corrected.

## Reconciliation rules

- An audit unit's principal artifact is `required`, whether it is software, a book, a paper, a visualization, a dataset, or a substantive web output. Supplementary artifacts are `optional`.
- Generated `paper/main` and `software/repo` placeholders are not evidence. Unsupported placeholders become `not-expected`.
- External papers ruled `describes` may be expected artifacts of a complex while remaining separate singleton audit units.
- Post-snapshot staging items remain excluded until Phase 5.
- Mistyped entries are replaced, not treated as unwanted artifacts.

## Recommendation counts

| Action | Entries |
|---|---:|
| confirm-required | 155 |
| confirm-optional | 11 |
| add-required | 17 |
| add-optional | 11 |
| not-expected | 163 |
| uncertain | 0 |

There are **172 required confirmations/additions**, **22 optional confirmations/additions**, and **163 not-expected removals**. No entries remain `uncertain`; only EP-004's version-granularity choice needs a user ruling.

## Genuine user decision

**EP-004/software/original — recommended `required`.** The 1990/1992 LEVEL5 DIALOG1 program is documented but unlocated and is distinct from the preserved 2016 web conversion. Recommended: retain it as a separate required artifact so its absence is visible. Alternative: deliberately cover the whole lineage under `EP-004/software/site`.

## Evidence-based correction

**EP-047/paper/main is `required`, not uncertain.** `DS7C8WTQ` is Bazzocchi's Tractatus software record at `bazzocchi.com/wittgenstein/tractatus/eng/index.htm`, and `I7MAW4IQ` is *On Butterfly Feelers*. The earlier absent-project note names the same hypertext path, so the collection is not devoid of a project record. Require the chapter and correct the outdated note.

## Consistency upgrades

Twenty-two principal web outputs were changed from the range reviewers' `keep-optional` to `required`: EP-048/web/site, EP-060/web/site, EP-069/web/site, EP-070/web/site, EP-072/web/site, EP-073/web/site, EP-075/web/site, EP-076/web/site, EP-078/web/site, EP-079/web/site, EP-080/web/site, EP-081/web/site, EP-082/web/site, EP-083/web/site, EP-085/web/site, EP-090/web/site, EP-093/web/site, EP-096/web/site, EP-097/web/site, EP-099/web/site, EP-100/web/site, EP-101/web/site. Core sister artifacts EP-001/software/other-1 and EP-009/software/other-1 were also made required. InPhO supplementary papers were made optional, and the current 2024 SEP version was made principal over the archived 2020 version.

## All recommendations

Existing entries use `confirm-*` or `not-expected`; new artifacts use `add-*`. The EP-004 user-decision row is also listed above.

| Artifact ID | Current | Recommended | Action | Confidence | Evidence |
|---|---|---|---|---|---|
| EP-001/paper/main | unknown | required | confirm-required | high | `VD89ULRH` **A Graphic, Mouse-Driven Interface for Integrating Teaching and Research in Deductive Proof Construction**; dossier explicitly identifies it as TALLC’s main paper (`deep-dive/002-1983-project-tallc.md`). |
| EP-001/software/other-1 | optional | required | confirm-required | high | Justified Thought is a core TALLC applet, not a supplementary version. |
| EP-001/software/other-2 | optional | optional | confirm-optional | high | `PJ6LLK7F` **Project TALLC**; suite-level software record supplements the individual applets. |
| EP-001/software/site | required | required | confirm-required | high | `7LCVEML6` **Deep Thought**; core TALLC proof-construction applet. |
| EP-001/web/site | optional | optional | confirm-optional | high | `EKT6SMX2` **Project TALLC \\| Overview**; project documentation. |
| EP-002/paper/main | unknown | required | confirm-required | high | `9PVXVXNY` **PROOF DESIGNER: A Programmable Prover’s Workbench**; principal project chapter (`deep-dive/003-1988-proof-designer.md`). |
| EP-002/software/site | required | required | confirm-required | high | `LYZJNKEZ` **Proof Designer**; Bedau/Moor program, despite no located public copy. |
| EP-003/book/main | required | required | confirm-required | high | `Q2JIUVCR` **Hyperproof**; companion book is a core project output. |
| EP-003/paper/main |  | required | add-required | high | FHX5WAQG, Hyperproof: Logical Reasoning with Diagrams; principal system paper. |
| EP-003/paper/other-1 |  | optional | add-optional | high | KET5FAJM, Visual Information and Valid Reasoning; broader companion account. |
| EP-003/software/site | required | required | confirm-required | high | `KC8IUZRH` **Openproof Courseware: Hyperproof**; core software/package. |
| EP-004/paper/main | unknown | required | confirm-required | high | `5HP9VZKP` **Computer-Assisted Instruction for a Socratic Dialogue**; developers’ substantive chapter (`deep-dive/006-1992-socratic-dialogue-dialog1.md`). |
| EP-004/software/original |  | required | add-required | high | The 1990/1992 LEVEL5 program is documented but unlocated; keep it distinct from the preserved 2016 web conversion. Alternative: deliberately cover the whole lineage under software/site. |
| EP-004/software/site | required | required | confirm-required | high | `HQGYTDNX` **Dialog1**; preserved 2016 web implementation represents the project software. |
| EP-005/book/main | required | required | confirm-required | high | `NSKZWTFZ` **Philosophy and the Computer**; the editorial endeavour’s primary output. |
| EP-005/software/repo | unknown | not-expected | not-expected | high | Edited book/CAP editorial project; no software implementation or repository is evidenced. |
| EP-006/paper/main | unknown | required | confirm-required | high | `Q24IWE5B` **Designing and Implementing Finite Structures**; Portoraro’s technical chapter on SYMLOG (`deep-dive/007-1992-symlog.md`). |
| EP-006/software/original |  | required | add-required | high | Original Pascal-era SYMLOG program, distinct from the later symlog.ca presence; no usable original copy located. |
| EP-006/software/site | required | required | confirm-required | high | `XUR4E5SE` **SYMLOG**; project’s later web presence, but not the original Pascal program. |
| EP-007/book/main | required | required | confirm-required | high | `3N9WUCQZ` **Language, Proof, and Logic**, revised second edition. |
| EP-007/book/other-1 | optional | optional | confirm-optional | high | `FNPDGWKC` **Language, Proof, and Logic**, first edition; useful earlier version, not a second required artifact. |
| EP-007/software/site | required | required | confirm-required | high | `ZSE63NLV` **LPL Features**; courseware’s own software/site. |
| EP-008/paper/main | unknown | required | confirm-required | high | `3VEBTE69` **PhiloSURFical: browse Wittgenstein’s world with the Semantic Web**; developers’ project paper. |
| EP-008/software/site | required | required | confirm-required | high | `ZFWIGUVU` **PhiloSURFical: project site**; primary project interface. |
| EP-009/paper/main | unknown | not-expected | not-expected | medium | No specific DAPHNET paper is linked or otherwise identified in the frozen population. |
| EP-009/software/other-1 | optional | required | confirm-required | high | Early Modern Philosophy Source is a distinct sister collection, not a supplementary version. |
| EP-009/software/site | required | required | confirm-required | high | `694QTUF3` **Ancient Philosophy Source – Home**; one of the two DAPHNET collections. |
| EP-010/paper/main | required | required | confirm-required | high | `IB9TNC2K` **Discovery: D1.8 Final Report**; authoritative final project report. |
| EP-010/paper/other-1 |  | optional | add-optional | high | XSRI2I29, Philosophy in an Evolving Web; project-authored Discovery chapter. |
| EP-010/software/site | required | required | confirm-required | high | `CHSEZLKD` **The Discovery Project: Philosophy in the Digital Era?**; main project site and Philosource/Philospace description. |
| EP-010/web/site | optional | optional | confirm-optional | high | `5J9KWAQ8` **Discovery Project – Publications**; supplementary project page. |
| EP-010/web/site-1 | optional | optional | confirm-optional | high | `Z2K2S3K5` **Digital Semantic Corpora for Virtual Research in Philosophy**; later Oxford-phase page. |
| EP-011/paper/main | unknown | required | confirm-required | high | `7ZFQ8HD8` **A Methodology for Constructing of Philosophy Ontology Based on Philosophical Texts**; principal methodology paper. |
| EP-011/paper/other-1 |  | optional | add-optional | high | JFQ3D9AL, Philosophy Ontology for Learning the Contents of Texts; second Kim-group paper. |
| EP-011/software/site | required | required | confirm-required | high | `CZZ33CIH` **Philosophy Knowledge Map**; software output described by both Kim-group papers. |
| EP-012/paper/main | unknown | required | confirm-required | high | `FPK48QJ3` **Foundations of an Ontology of Philosophy**; Grenon/Smith’s substantive ontology paper. |
| EP-012/software/site | required | required | confirm-required | high | `9MMPB8CE` **PDC Philosophy ontology**; the actual OWL ontology, not merely a generated software slot. |
| EP-012/web/site | optional | optional | confirm-optional | high | `US2DWY3M` **Homepage**; Philosophome project context and resource index. |
| EP-013/book/main | required | required | confirm-required | high | `5B7ATFW9` **Wittgenstein and the Philosophy of Information**; proceedings volume I. |
| EP-013/book/other-1 | optional | required | confirm-required | high | `LFP7FHS2` **Philosophy of the Information Society**; proceedings volume II, not a duplicate or dispensable follow-up. |
| EP-013/software/repo | unknown | not-expected | not-expected | high | Symposium/proceedings editorial endeavour; no project software repository is evidenced. |
| EP-014/issue/main |  | required | add-required | high | MI6EIDDI, the issue-level Representing Philosophy record; replaces mistyped paper/followup-1. |
| EP-014/paper/followup-1 | optional | not-expected | not-expected | high | `MI6EIDDI` is the **issue-level record**, not a follow-up paper; replace with `issue/main` below. |
| EP-014/paper/main | required | required | confirm-required | high | `27S8UJJA` **“Synthese” special issue: representing philosophy**; guest editors’ introduction. |
| EP-014/software/repo | unknown | not-expected | not-expected | high | Guest-edited journal issue; no software repository is part of the endeavour. |
| EP-015/paper/main | unknown | required | confirm-required | high | Use `DGWBG5LH` **Computer Simulations in the Humanities** here; it is the institute’s own NEH report, with PDF attachment. |
| EP-015/paper/other-1 |  | optional | add-optional | high | MS242R4Y, NEH Project: Computer Simulations in the Humanities; separate AAAI paper about the institute. |
| EP-015/software/repo | unknown | not-expected | not-expected | high | NEH institute/event; no institute software repository is evidenced. |
| EP-015/web/site | optional | not-expected | not-expected | high | `DGWBG5LH` is the NEH **White Paper Report**, mislabeled as an optional blog/site artifact; replace through `paper/main`. |
| EP-016/dataset/main |  | optional | add-optional | high | Raper's three-column philosopher-influence CSV dataset constructed from DBpedia, documented in https://drunksandlampposts.wordpress.com/2012/06/13/graphing-the-history-of-philosophy/. |
| EP-016/paper/main | unknown | not-expected | not-expected | high | `FIRSI9NY` **The History of Philosophy Visualized** is third-party web coverage, not a project paper. |
| EP-016/software/repo | unknown | not-expected | not-expected | medium | The page supplies a SPARQL query and procedure, not evidence of a project repository. |
| EP-016/visualization/main |  | required | add-required | high | Raper's downloadable vector influence graph, explicitly offered in https://drunksandlampposts.wordpress.com/2012/06/13/graphing-the-history-of-philosophy/. |
| EP-016/web/site | optional | optional | confirm-optional | high | `B36XFIWR` **Graphing the History of Philosophy**; Raper’s own methodological write-up. |
| EP-017/paper/main | unknown | not-expected | not-expected | high | `UDQ9L6ZM` is a Reddit discussion, not a paper; no scholarly project paper is evidenced. |
| EP-017/software/repo | unknown | not-expected | not-expected | high | No repository is evidenced; the separately discovered philcites interactive is staging-only and excluded. |
| EP-017/web/site | optional | required | confirm-required | high | `THUECHWU` **A Co-Citation Network for Philosophy** is Healy’s substantive analysis and the frozen snapshot’s main output, not incidental publicity. |
| EP-018/paper/main | unknown | not-expected | not-expected | high | `76JX3CTF` is a Reddit post about the graph, not a project paper. |
| EP-018/software/repo | unknown | not-expected | not-expected | medium | No distinct source repository is identified in the snapshot or dossier context. |
| EP-018/web/site | optional | required | confirm-required | high | `EK7B5CUW` **A Zoomable Graph of the History of Philosophy** is the project’s own visualization page and primary artifact. |
| EP-019/paper/main | unknown | not-expected | not-expected | high | `N4T4IJIE` is developer-shared Reddit coverage, not a paper. |
| EP-019/software/repo |  | required | add-required | high | https://github.com/pbellon/tractatus-tree — source corresponding to the deployed Tractatus Tree. |
| EP-019/software/site | required | required | confirm-required | high | `CVTK95CG` **Tractatus Tree**; live D3 visualization artifact. |
| EP-020/paper/main | unknown | required | confirm-required | high | `EXT8ALKU` **Visualization of Historical Knowledge Structures: An Analysis of the Bibliography of Philosophy**; DH2014 project poster/paper. |
| EP-020/software/repo | unknown | not-expected | not-expected | medium | No concrete project repository was identified; do not infer one merely from the visualization’s existence. |
| EP-020/visualization/main |  | required | add-required | medium | The Bibliography of Philosophy visualization itself, distinct from its write-up and analysis. |
| EP-020/web/site | optional | optional | confirm-optional | high | `C53NA58K` **Visualizing the Bibliography of Philosophy**; Sula/Dean/Ryti project page. |
| EP-021/paper/main | unknown | required | confirm-required | high | `4WGFYP6Y` **Digital Ricoeur**; the site itself explicitly cites this article for the project model. |
| EP-021/paper/other-1 |  | optional | add-optional | high | 8ZZAKGN4, Digital Ricoeur Data Model; second linked project paper. |
| EP-021/software/site | required | required | confirm-required | high | `PL246G6Y` **Digital Ricoeur – context**; project site and search/analysis interface. |
| EP-022/paper/main | unknown | required | confirm-required | high | `CYC8HM7K` **Natural Language Processing and Network Visualization for Philosophers**; explicitly linked as a DR2-describing publication. |
| EP-022/paper/other-1 |  | optional | add-optional | medium | TS5N64ZF, Hermeneutic Calvinball versus modest digital humanities; supplementary DR2 publication. |
| EP-022/software/site | required | required | confirm-required | high | `W7DKXVKG` **DR2 – Distant Reading and Data-driven Research in the History of Philosophy**; fMOD project venue. |
| EP-022/web/site | optional | optional | confirm-optional | high | `7DIFGICK` **A semantic-network approach to the history of philosophy…**; DR2 open-peer-review contribution. |
| EP-022/web/site-1 | optional | optional | confirm-optional | high | `C82VEKP5` **Exploring Knowledge Dynamics in the Humanities…**; second DR2 open-peer-review contribution. |
| EP-023/dataset/main |  | required | add-required | high | The multilingual TheofPhilo thesaurus data described by the principal report. |
| EP-023/paper/main | required | required | confirm-required | high | `XVHLW8LT` **TheofPhilo – Thesaurus of Philosophy**; principal report on the thesaurus and its construction. |
| EP-023/paper/other-1 |  | optional | add-optional | high | 23T3FG8R, TheofPhilo: A prototype for a Thesaurus of Philosophy; earlier prototype paper. |
| EP-023/software/repo | unknown | not-expected | not-expected | high | The abstract supports a thesaurus dataset and search interface, not a source-code repository. |
| EP-023/software/site |  | required | add-required | high | The thesaurus search/browse interface is part of the thesaurus itself, per the report abstract. |
| EP-024/paper/main | unknown | not-expected | not-expected | high | Linked records are press coverage or unrelated visualizations; no project paper is evidenced. |
| EP-024/software/site | required | required | confirm-required | high | `REGDYTQX` **The History of Philosophy**; primary interactive visualization. |
| EP-024/web/site | optional | optional | confirm-optional | high | `AMNRSRJF` **The History Of Philosophy – README**; project explanation and methodology. |
| EP-025/issue/main |  | required | add-required | high | The complete Computer Modeling in Philosophy topical issue, not only Grim's editorial introduction. |
| EP-025/paper/main | required | required | confirm-required | high | `SGVF9YJG` **Editorial introduction to the Topical Issue “Computer Modeling in Philosophy”**. |
| EP-025/software/repo | unknown | not-expected | not-expected | high | Guest-edited topical issue; no software repository is part of the editorial project. |
| EP-026/book/main | required | not-expected | not-expected | high | PFA7MGVG is the archived 2020 SEP version; replace with EP-026/paper/other-1. |
| EP-026/commentary/main | optional | not-expected | not-expected | high | BWIS8G7W is the current 2024 SEP version; replace with EP-026/paper/main. |
| EP-026/paper/main |  | required | add-required | high | BWIS8G7W, current 2024 SEP version; principal current version, replacing mistyped commentary/main. |
| EP-026/paper/other-1 |  | optional | add-optional | high | PFA7MGVG, archived 2020 SEP version; earlier version, replacing mistyped book/main. |
| EP-026/software/repo | unknown | not-expected | not-expected | high | Encyclopedia article; no accompanying repository is evidenced. |
| EP-027/paper/main | unknown | required | confirm-required | high | `Y86ECU3J` **Challenging distributional models with a conceptual network of philosophical terms**; repository explicitly identifies this as its paper. |
| EP-027/software/repo | required | required | confirm-required | high | `W35XVAL3` **YOortwijn/Challenging_DMs**; actual repository containing code and dataset. |
| EP-028/book/main | required | required | confirm-required | high | `2PIU8IIM` **The Computer Revolution in Philosophy**; book with preserved revised-online-edition PDF. |
| EP-028/software/repo | unknown | not-expected | not-expected | high | Monograph; reviews and other staged discoveries do not create a repository expectation. |
| EP-029/paper/main | unknown | not-expected | not-expected | medium | WAB has many outputs, but no single principal paper is identified in this frozen unit; the gathered output set is staging-only. |
| EP-029/software/site | required | required | confirm-required | high | `PTDUCCRS` **The Wittgenstein Archives at the University of Bergen**; institutional archive/project site. |
| EP-030/book/main | required | required | confirm-required | high | `VD89ULRH` **A Graphic, Mouse-Driven Interface…**; complete chapter is locally scanned. |
| EP-030/software/repo | unknown | not-expected | not-expected | high | Chapter audit unit; TALLC software is already represented under EP-001, with no repository evidenced. |
| EP-031/book/main | required | required | confirm-required | high | `5HP9VZKP` **Computer-Assisted Instruction for a Socratic Dialogue**; complete chapter is locally scanned. |
| EP-031/software/repo | unknown | not-expected | not-expected | high | Chapter audit unit; DIALOG1 software belongs to EP-004 and no repository is evidenced. |
| EP-032/book/main | required | required | confirm-required | high | `Q24IWE5B` **Designing and Implementing Finite Structures**; complete SYMLOG chapter is locally scanned. |
| EP-032/software/repo | unknown | not-expected | not-expected | high | Chapter audit unit; SYMLOG software belongs to EP-006 and no repository is evidenced. |
| EP-033/paper/main | required | required | confirm-required | high | `FHX5WAQG` **Hyperproof: Logical Reasoning with Diagrams**; AAAI paper with preserved PDF. |
| EP-033/software/repo | unknown | not-expected | not-expected | high | Paper audit unit; Hyperproof software belongs to EP-003 and no separate repository is evidenced. |
| EP-034/book/main | required | required | confirm-required | high | `9PVXVXNY` **PROOF DESIGNER: A Programmable Prover’s Workbench**; complete chapter is locally scanned. |
| EP-034/software/repo | unknown | not-expected | not-expected | high | Chapter audit unit; the program belongs to EP-002, and no public source copy/repository was located. |
| EP-035/book/main | required | required | confirm-required | high | `MQDZ556Q` **The Computer as a Laboratory for Epistemology**; Herbert Simon’s volume chapter. |
| EP-035/software/repo | unknown | not-expected | not-expected | high | Philosophical essay; no implementation or repository is evidenced. The staged preprint is excluded. |
| EP-036/book/main | required | required | confirm-required | high | `KET5FAJM`, *Visual Information and Valid Reasoning*, is the book chapter itself. |
| EP-036/software/repo | unknown | not-expected | not-expected | high | `KET5FAJM` is a chapter; its descriptions of Hyperproof do not make a repository an artifact of this chapter unit. |
| EP-037/paper/main | unknown | not-expected | not-expected | high | No frozen paper describes Velleman’s program. The companion *How to Prove It* is a post-snapshot staged book, not a paper, and is excluded until Phase 5. |
| EP-037/software/site | required | required | confirm-required | high | `8WJ3UJWY`, Velleman’s *Proof Designer*, is the program/site; `sources/emerging_philosophy/deep-dive/003-1988-proof-designer.md` confirms its distinct identity. |
| EP-038/document/manual |  | required | add-required | high | Surviving seven-chapter OSCAR Manual plus two appendices documented in the OSCAR dossier. |
| EP-038/paper/main | unknown | required | confirm-required | high | `HVU3VI2E`, *Procedural Epistemology*, explicitly `describes` OSCAR; its chapter URL is the OSCAR project page. |
| EP-038/software/download |  | required | add-required | high | Complete surviving OSCAR 3.31 Common Lisp distribution documented in the OSCAR dossier. |
| EP-038/software/site | required | required | confirm-required | high | `6YSSF25Z`, *The OSCAR Project*, is the project/software site; the OSCAR dossier confirms a substantial surviving project artifact set. |
| EP-039/book/main | required | required | confirm-required | high | `HVU3VI2E`, *Procedural Epistemology*, is the chapter artifact. |
| EP-039/software/repo | unknown | not-expected | not-expected | high | This is a book-chapter unit; OSCAR’s software belongs to EP-038, not this chapter’s own inventory. |
| EP-040/book/main | required | required | confirm-required | high | `UKQIXPTG`, *The Digital Phoenix: How Computers are Changing Philosophy*, is the book. |
| EP-040/software/repo | unknown | not-expected | not-expected | high | An edited book does not mechanically imply a repository; none is evidenced. |
| EP-041/book/main | required | required | confirm-required | high | `84G5K6QT`, *The Philosophical Computer: Exploratory Essays in Philosophical Computer Modeling*, is the book. |
| EP-041/software/repo | unknown | not-expected | not-expected | high | No project repository is evidenced for this edited volume. |
| EP-042/book/main | required | required | confirm-required | high | `R9HJ9N5Q`, *Philosophy and Computing: An Introduction*, is the monograph. |
| EP-042/software/repo | unknown | not-expected | not-expected | high | No software artifact or project repository is evidenced for Floridi’s book. |
| EP-043/book/main | required | required | confirm-required | high | `GR4UZDT3`, *Cyberphilosophy: The Intersection of Philosophy and Computing*, is the edited book. |
| EP-043/software/repo | unknown | not-expected | not-expected | high | No repository is evidenced for this editorial work. |
| EP-044/book/main | required | required | confirm-required | high | `H7RZ76WZ`, *Computational Modeling as a Philosophical Methodology*, is the chapter. |
| EP-044/software/repo | unknown | not-expected | not-expected | high | A methodology chapter does not itself entail a repository; none is evidenced. |
| EP-045/book/main | required | required | confirm-required | high | `AU6QQZEV`, *Ontology*, is the chapter. |
| EP-045/software/repo | unknown | not-expected | not-expected | high | No software implementation or repository is evidenced for this chapter unit. |
| EP-046/book/main | required | required | confirm-required | high | `6ZZARMCP`, *The Blackwell Guide to the Philosophy of Computing and Information*, is the edited book. |
| EP-046/software/repo | unknown | not-expected | not-expected | high | No repository is evidenced for this editorial work. |
| EP-047/paper/main | unknown | required | confirm-required | high | I7MAW4IQ, On Butterfly Feelers, describes DS7C8WTQ's Bazzocchi Tractatus hypertext at the same path named by the outdated absent-project note; require the chapter and correct that note. |
| EP-047/software/site | required | required | confirm-required | high | `DS7C8WTQ`, Bazzocchi’s *Tractatus*, is the hypertext/software record. The handoff’s Wayback reference supports preservation independently of current domain liveness. |
| EP-048/paper/main | unknown | not-expected | not-expected | high | The ILPS listing is not a publication and has no specific paper artifact of its own. |
| EP-048/software/repo | unknown | not-expected | not-expected | high | A listing of multiple institutional projects does not establish a repository for this web-page unit. |
| EP-048/web/site | optional | required | confirm-required | high | `EJU6E3FU`, *ILPS \\| Projects*, is an institutional project-listing page, appropriately retained as a web reference. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-049/paper/main | required | required | confirm-required | high | `RPPKCJ2X`, *Designing and Implementing an Ontology for Logic and Linguistics*, is the journal article. |
| EP-049/software/repo | unknown | not-expected | not-expected | high | The article discusses the LoLaLi ontology, but no repository belonging to this article unit is evidenced. |
| EP-050/paper/crowdsourcing-concept-hierarchies |  | optional | add-optional | high | DL7Z8NZN, Crowdsourcing the Assembly of Concept Hierarchies; supplementary InPhO publication. |
| EP-050/paper/from-encyclopedia-to-ontology |  | optional | add-optional | high | V4IPFP6M, From Encyclopedia to Ontology; supplementary InPhO publication. |
| EP-050/paper/main | unknown | required | confirm-required | high | `R68STAZV`, *A Dynamic Ontology for a Dynamic Reference Work*, explicitly `describes` InPhO. Two further frozen-population InPhO papers should be added separately below. |
| EP-050/software/site | required | required | confirm-required | high | `ICX8ZK92`, *InPhO – The Internet Philosophy Ontology Project*, is the project/site artifact. |
| EP-051/paper/main | unknown | not-expected | not-expected | high | No frozen record is ruled as a paper describing Nietzsche Source; nearby Nietzsche/DR2 records were ruled unrelated. |
| EP-051/software/site | required | required | confirm-required | high | `9ZYG4YFU`, *Nietzsche Source – Home*, is the digital-edition site. |
| EP-052/paper/main | unknown | not-expected | not-expected | high | No frozen paper member or describing paper is established. The later WAB publication/edition discoveries are staged and excluded until Phase 5. |
| EP-052/software/site | required | required | confirm-required | high | `DQJL5VYD`, *Wittgenstein Source – Home*, is the digital-edition site. |
| EP-053/paper/main | required | required | confirm-required | high | `R68STAZV`, *A Dynamic Ontology for a Dynamic Reference Work*, is the conference paper. |
| EP-053/software/repo | unknown | not-expected | not-expected | high | This is the paper unit; the described InPhO software/site is separately audited as EP-050. |
| EP-054/paper/main | required | required | confirm-required | high | `7ZFQ8HD8`, *A Methodology for Constructing of Philosophy Ontology Based on Philosophical Texts*, is the journal article. |
| EP-054/software/repo | unknown | not-expected | not-expected | high | The article describes the Philosophy Knowledge Map, but no repository belongs to this article unit. |
| EP-055/paper/main | required | required | confirm-required | high | `JFQ3D9AL`, *Philosophy Ontology for Learning the Contents of Texts*, is the conference paper. |
| EP-055/software/repo | unknown | not-expected | not-expected | high | This is a describing paper, not a software artifact; no repository is evidenced. |
| EP-056/book/main | required | required | confirm-required | high | `I7MAW4IQ`, *On Butterfly Feelers: Some Examples of Surfing on Wittgenstein’s Tractatus*, is the chapter. |
| EP-056/software/repo | unknown | not-expected | not-expected | high | The chapter is the artifact of this singleton. Any associated hypertext belongs to a separate project inventory, not a repository mechanically attached to this chapter. |
| EP-057/book/main | required | required | confirm-required | high | `XSRI2I29`, *Philosophy in an Evolving Web: Necessary Conditions, Web Technologies, and the Discovery Project*, is the chapter. |
| EP-057/software/repo | unknown | not-expected | not-expected | high | This chapter describes EP-010, the Discovery Project; it does not itself have a repository artifact. |
| EP-058/book/main | required | required | confirm-required | high | `3VEBTE69`, *PhiloSURFical: Browse Wittgenstein’s World with the Semantic Web*, is the chapter. |
| EP-058/software/repo | unknown | not-expected | not-expected | high | The chapter describes EP-008; no repository belongs to the chapter unit itself. |
| EP-059/paper/main | required | required | confirm-required | high | `DL7Z8NZN`, *Crowdsourcing the Assembly of Concept Hierarchies*, is the conference paper. |
| EP-059/software/repo | unknown | not-expected | not-expected | high | This is a paper about InPhO-related methods, not a software artifact with an evidenced repository. |
| EP-060/paper/main | unknown | required | confirm-required | high | `73J9U9FM`, *NEH Panel: A Model for Philosophers*, explicitly `describes` TDI’s NEH work. |
| EP-060/software/repo | unknown | not-expected | not-expected | high | Neither the TDI page nor Crowley’s panel paper evidences a project repository. |
| EP-060/web/site | optional | required | confirm-required | high | `2Q6SXGXJ`, *A Model for Philosophers*, is TDI’s own web presence; the snapshot abstract describes the Toolbox Dialogue Initiative. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-061/paper/main | required | required | confirm-required | high | `FPK48QJ3`, *Foundations of an Ontology of Philosophy*, is the journal article. |
| EP-061/software/repo | unknown | not-expected | not-expected | high | The article describes the PDC/Philosophome ontology, separately audited under EP-012; this article has no repository artifact. |
| EP-062/paper/main | required | required | confirm-required | high | `V4IPFP6M`, *From Encyclopedia to Ontology: Toward Dynamic Representation of the Discipline of Philosophy*, is the journal article. |
| EP-062/software/repo | unknown | not-expected | not-expected | high | This is an InPhO paper, not the software project; no repository belongs to the paper unit. |
| EP-063/paper/main | required | required | confirm-required | high | `HRNTF5QA`, *Knowledge Representation, the World Wide Web, and the Evolution of Logic*, is the journal article. |
| EP-063/software/repo | unknown | not-expected | not-expected | high | A discussion of Common Logic and web representation does not establish a repository for this article. |
| EP-064/paper/main | required | required | confirm-required | high | `F2KDBQPQ`, *Naturalized Metaphilosophy*, is the journal article. |
| EP-064/software/repo | unknown | not-expected | not-expected | high | No software output or repository is evidenced for this article. |
| EP-065/paper/main | required | required | confirm-required | high | `73J9U9FM`, *NEH Panel: A Model for Philosophers*, is the paper. |
| EP-065/software/repo | unknown | not-expected | not-expected | high | The paper describes TDI’s NEH work; no repository belongs to this paper unit. |
| EP-066/paper/main | required | required | confirm-required | high | `MS242R4Y`, *NEH Project: Computer Simulations in the Humanities*, is Croy’s paper about the institute. |
| EP-066/software/repo | unknown | not-expected | not-expected | high | The paper describes EP-015’s event/project; no repository belongs to the paper unit. |
| EP-067/paper/main | required | required | confirm-required | high | `TNTCB8B6`, *Noesis and the Encyclopedic Internet Vision*, is the journal article. |
| EP-067/software/repo | unknown | not-expected | not-expected | high | The article recounts Noesis, but no software member or repository is evidenced for this article unit. |
| EP-068/paper/main | required | required | confirm-required | high | `PFI87H2K`, *Ontological Requirements for Annotation and Navigation of Philosophical Resources*, is the journal article. |
| EP-068/software/repo | unknown | not-expected | not-expected | high | No implementation repository is evidenced for this paper. |
| EP-069/paper/main | unknown | not-expected | not-expected | high | No separate paper is evidenced; the related Reddit thread was ruled a sibling discussion, not a paper artifact. |
| EP-069/software/repo | unknown | not-expected | not-expected | high | The existence of an analysis/visualization does not by itself establish a repository; none is catalogued or otherwise evidenced. |
| EP-069/web/site | optional | required | confirm-required | high | `ESUJQZI7`, *A Not Quite Satisfactory Way of Looking at Departments and Specialties*, is Healy’s own analysis page. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-070/paper/main | unknown | not-expected | not-expected | high | An admissions/programme page has no paper artifact of its own. |
| EP-070/software/repo | unknown | not-expected | not-expected | high | An academic degree programme does not mechanically imply a software repository; none is evidenced. |
| EP-070/web/site | optional | required | confirm-required | high | `VX53UV7Z`, *Degree in Computer Science and Philosophy at Oxford*, is the degree-programme page. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-071/paper/main | required | not-expected | not-expected | high | HXH5RN22 is a Master's thesis, not a paper; replace with EP-071/thesis/main. |
| EP-071/software/repo | unknown | not-expected | not-expected | high | `HXH5RN22` is a standalone thesis; no software implementation or repository is evidenced. |
| EP-071/thesis/main |  | required | add-required | high | HXH5RN22, Il valore euristico di un'ontologia digitale; Master's thesis replacing mistyped paper/main. |
| EP-072/paper/main | unknown | not-expected | not-expected | high | `QKD3VTIY` is a Reddit thread; no associated paper is evidenced. Its relation to Healy’s department analysis is `siblings`, not containment. |
| EP-072/software/repo | unknown | not-expected | not-expected | high | The Reddit thread supplies no evidence of a software project or repository. |
| EP-072/web/site | optional | required | confirm-required | high | `QKD3VTIY`, the Reddit thread on sub-field specialization and rankings, is the sole web record. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-073/paper/main | unknown | not-expected | not-expected | high | `FIRSI9NY` is third-party coverage describing Simon Raper’s EP-016 project, not a paper record. |
| EP-073/software/repo | unknown | not-expected | not-expected | high | Any Raper software belongs to EP-016; the Open Culture record evidences no repository of its own. |
| EP-073/web/site | optional | required | confirm-required | high | `FIRSI9NY`, Open Culture’s *The History of Philosophy Visualized*, is the sole commentary page. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-074/paper/main | unknown | not-expected | not-expected | high | `3MBPU8DM` is an introductory project page; no particular paper is evidenced by this singleton. |
| EP-074/software/site | required | required | confirm-required | high | `3MBPU8DM`, *Wikidata:Introduction*, is the catalogued Wikidata software/project site record. |
| EP-075/paper/main | unknown | not-expected | not-expected | high | `2J78UWPE` is a webpage presenting diagrams; no associated paper is evidenced. |
| EP-075/software/repo | unknown | not-expected | not-expected | high | Scharp’s page says the diagrams were made by hand or with Visio; it supplies no repository expectation. |
| EP-075/web/site | optional | required | confirm-required | high | `2J78UWPE`, Kevin Scharp’s *Diagrams*, is the sole project webpage. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-076/paper/main | unknown | not-expected | not-expected | high | `A43YAUPR` is a blog analysis, not a record of a separate paper. |
| EP-076/software/repo | unknown | not-expected | not-expected | high | The post supplies no software/repository evidence; Phase 1 also ruled it unrelated to Healy’s EP-017 co-citation project. |
| EP-076/web/site | optional | required | confirm-required | high | `A43YAUPR`, Kieran Healy’s *Lewis and the Women*, is the sole analysis post. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-077/paper/main | required | required | confirm-required | high | `3HHDRNPJ`, *Overlapping and Competing Ontologies in Digital Humanities*, is the conference paper; snapshot includes PDF attachment `VPDU75WU`. |
| EP-077/software/repo | unknown | not-expected | not-expected | high | `3HHDRNPJ` is an ontology study/paper; no repository is evidenced. |
| EP-078/paper/main | unknown | not-expected | not-expected | high | `HFT78RWS` supplies no associated paper record or bibliographic evidence. |
| EP-078/software/repo | unknown | not-expected | not-expected | high | A web visualization does not itself establish a public repository; none is evidenced. |
| EP-078/web/site | optional | required | confirm-required | high | `HFT78RWS`, Aaron Kosel’s *Philosophy Summary*, is the sole web visualization record. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-079/paper/main | unknown | not-expected | not-expected | high | `9HTGPT7F` supplies no associated paper record or bibliographic evidence. |
| EP-079/software/repo | unknown | not-expected | not-expected | high | No public implementation repository is evidenced for this webpage. |
| EP-079/web/site | optional | required | confirm-required | high | `9HTGPT7F`, Aaron Kosel’s *Philosophy Survey*, is the sole web visualization record. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-080/paper/main | unknown | not-expected | not-expected | high | `76JX3CTF` is third-party Reddit coverage describing EP-018, not a paper. |
| EP-080/software/repo | unknown | not-expected | not-expected | high | Any Hogan graph software belongs to EP-018; no repository is evidenced for this Reddit record. |
| EP-080/web/site | optional | required | confirm-required | high | `76JX3CTF`, the Reddit thread on *A Zoomable Graph of the History of Philosophy*, is the sole record. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-081/paper/main | unknown | not-expected | not-expected | high | `JHQN9HNJ` is third-party coverage describing EP-075, not a paper record. |
| EP-081/software/repo | unknown | not-expected | not-expected | high | The Reddit thread supplies no repository evidence and does not own Scharp’s diagram output. |
| EP-081/web/site | optional | required | confirm-required | high | `JHQN9HNJ`, the Reddit thread on Scharp’s 600 B.C.E.–1935 diagrams, is the sole record. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-082/paper/main | unknown | not-expected | not-expected | high | `VAXQTKIZ` is a Reddit thread; no associated paper is evidenced. |
| EP-082/software/repo | unknown | not-expected | not-expected | high | No repository is evidenced by the thread; a visualization reference alone does not create one. |
| EP-082/web/site | optional | required | confirm-required | high | `VAXQTKIZ`, the Reddit thread *Visually search through the Stanford Encyclopedia of Philosophy*, is the sole record. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-083/paper/main | unknown | not-expected | not-expected | high | `6LT8T5Q7` is a Reddit thread; no associated paper is evidenced. |
| EP-083/software/repo | unknown | not-expected | not-expected | high | The thread supplies no evidence of a public software repository. |
| EP-083/web/site | optional | required | confirm-required | high | `6LT8T5Q7`, the Reddit thread *What do philosophers believe?*, is the sole record. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-084/paper/main | required | required | confirm-required | high | `TUBSWHL8`, *Sharing and debating Wittgenstein by using an ontology*, is the journal article itself. |
| EP-084/software/repo | unknown | not-expected | not-expected | high | `TUBSWHL8` discusses Wittgenstein Archives ontology work; no repository is evidenced for this paper singleton. |
| EP-085/paper/main | unknown | not-expected | not-expected | high | `W6LKDCA8` is third-party coverage describing EP-075, not a paper. |
| EP-085/software/repo | unknown | not-expected | not-expected | high | The Open Culture article evidences no repository; Scharp’s own output remains EP-075. |
| EP-085/web/site | optional | required | confirm-required | high | `W6LKDCA8`, Open Culture’s article on Scharp’s two 44-foot diagrams, is the sole commentary page. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-086/paper/main | required | required | confirm-required | high | `PJVRDK9D`, *A Selective Study of Argument in the Philosophy of Animal Psychology…*, is the final report; PDF attachment `PHUXIT9M` is recorded. |
| EP-086/software/repo | unknown | not-expected | not-expected | high | `PJVRDK9D` is an argument-mining study report; no repository is evidenced. |
| EP-087/paper/main | required | required | confirm-required | high | `WV62DBRF`, *Iconic Representations and Representative Practices*, is the journal article; PDF attachment `7VUFSLJR` is recorded. |
| EP-087/software/repo | unknown | not-expected | not-expected | high | `WV62DBRF` is a philosophical article about representation, not evidence of a software repository. |
| EP-088/paper/main | required | required | confirm-required | high | `47RQBTUA`, *LODE: Linking digital humanities content to the web of data*, is the conference paper; PDF attachment `ZJ694EGN` is recorded. |
| EP-088/software/repo | unknown | not-expected | not-expected | high | `47RQBTUA` is a paper about linked-data infrastructure; no repository is evidenced for this singleton. |
| EP-089/book/main | required | required | confirm-required | high | `26DNM9ZQ`, *Philosophy, Computing and Information Science*, is the book itself. |
| EP-089/software/repo | unknown | not-expected | not-expected | high | `26DNM9ZQ` is an edited scholarly book; no software repository is evidenced or mechanically implied. |
| EP-090/paper/main | unknown | not-expected | not-expected | high | `N4T4IJIE` is third-party coverage describing EP-019, not a paper. |
| EP-090/software/repo | unknown | not-expected | not-expected | high | Bellon’s Tractatus Tree belongs to EP-019; the Reddit record supplies no repository expectation. |
| EP-090/web/site | optional | required | confirm-required | high | `N4T4IJIE`, the Reddit thread on visualizing the *Tractatus* tree, is the sole record. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-091/paper/main | required | required | confirm-required | high | `23T3FG8R`, *TheofPhilo. A prototype for a Thesaurus of Philosophy*, is the DH2014 conference paper. |
| EP-091/software/repo | unknown | not-expected | not-expected | high | `23T3FG8R` describes EP-023’s thesaurus; no repository is evidenced for this separate paper singleton. |
| EP-092/paper/main | required | required | confirm-required | high | `EXT8ALKU`, *Visualization of Historical Knowledge Structures: An Analysis of the Bibliography of Philosophy*, is the DH2014 poster/paper. |
| EP-092/software/repo | unknown | not-expected | not-expected | high | `EXT8ALKU` describes EP-020’s visualization; no repository is evidenced for this paper singleton. |
| EP-093/paper/main | unknown | not-expected | not-expected | high | `UDQ9L6ZM` is third-party coverage describing EP-017, not a paper. |
| EP-093/software/repo | unknown | not-expected | not-expected | high | Healy’s project belongs to EP-017; the Reddit record supplies no repository evidence. |
| EP-093/web/site | optional | required | confirm-required | high | `UDQ9L6ZM`, the Reddit thread on Healy’s co-citation network, is the sole record. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-094/paper/main | required | required | confirm-required | high | `XRS9DLTV`, *Phil@Scale: Computational methods within philosophy*, is the workshop paper; PDF attachment `5BZXXZ4T` is recorded. |
| EP-094/software/repo | unknown | not-expected | not-expected | high | `XRS9DLTV` is a computational-methods paper; no repository is evidenced. |
| EP-095/paper/main | required | required | confirm-required | high | `TWDLHEAL`, *Summa Philosophiae: a Semantic Wiki for Professional Philosophers*, is the conference paper; PDF attachment `M3SSMKG4` is recorded. |
| EP-095/software/repo | unknown | not-expected | not-expected | high | The paper presents a semantic wiki, but `TWDLHEAL` supplies no repository evidence; a described system does not prove a repo is expected. |
| EP-096/paper/main | unknown | not-expected | not-expected | high | `6KS4PH83` is third-party coverage of Valentin Lageard’s mapping, not a paper record. |
| EP-096/software/repo | unknown | not-expected | not-expected | high | The article supplies no repository evidence for this singleton. |
| EP-096/web/site | optional | required | confirm-required | high | `6KS4PH83`, Open Culture’s *The Entire Discipline of Philosophy Visualized with Mapping Software*, is the sole commentary page. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-097/paper/main | unknown | not-expected | not-expected | high | `L9LAUF6A` is third-party coverage of Oliveira’s Philosopher’s Web, not a paper. |
| EP-097/software/repo | unknown | not-expected | not-expected | high | The Daily Nous record evidences no repository. Post-snapshot Philosopher’s Web records remain excluded until Phase 5. |
| EP-097/web/site | optional | required | confirm-required | high | `L9LAUF6A`, Daily Nous’s *A Visualization of Influence in the History of Philosophy*, is the sole commentary page. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-098/paper/main | required | required | confirm-required | high | `4WGFYP6Y`, *Digital Ricoeur*, is the journal article; PDF attachment `YUDHMM2X` is recorded. |
| EP-098/software/repo | unknown | not-expected | not-expected | high | `4WGFYP6Y` describes the EP-021 Digital Ricoeur project; no repository is evidenced for this separate article singleton. |
| EP-099/paper/main | unknown | not-expected | not-expected | high | `7KLAD4EF` is a Reddit visualization post; no paper is evidenced. |
| EP-099/software/repo | unknown | not-expected | not-expected | high | The post supplies no repository evidence; an original visualization does not mechanically imply a repo. |
| EP-099/web/site | optional | required | confirm-required | high | `7KLAD4EF`, the Reddit thread graphing related SEP entries, is the sole record. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-100/paper/main | unknown | not-expected | not-expected | high | `J47QWDAY` is a project-description page; no particular paper is evidenced. |
| EP-100/software/repo | unknown | not-expected | not-expected | high | The TOPIC page supplies no repository evidence. |
| EP-100/web/site | optional | required | confirm-required | high | `J47QWDAY`, *TOPIC: Tracing tracks of philosophical innovation in digital text corpora*, is the sole project/blog page. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-101/paper/main | unknown | not-expected | not-expected | high | `NMWMEXNM` is third-party coverage, not a paper record. |
| EP-101/software/repo | unknown | not-expected | not-expected | high | The article supplies no repository evidence. Post-snapshot Philosopher’s Web artifacts are excluded until Phase 5. |
| EP-101/web/site | optional | required | confirm-required | high | `NMWMEXNM`, Open Culture’s Philosopher’s Web article, is the sole commentary page. Principal artifact of this singleton; required consistently with the other sole web outputs. |
| EP-102/paper/main | required | required | confirm-required | high | `54ZVJYQ9`, *A philosophical perspective on visualization for digital humanities*, is the conference paper; PDF attachment `SJSVVG9L` is recorded. |
| EP-102/software/repo | unknown | not-expected | not-expected | high | `54ZVJYQ9` is a methodological visualization paper; no repository is evidenced. |
| EP-103/paper/main | required | required | confirm-required | high | `NJXIE88Q`, *BolVis: Visualization for Text-based Research in Philosophy*, is the system paper; PDF attachment `X9DH3CU2` is recorded. |
| EP-103/software/repo | unknown | not-expected | not-expected | high | `NJXIE88Q` describes the BolVis tool but supplies no repository evidence; the paper singleton should not acquire a mechanical repo slot. |
| EP-104/paper/main | unknown | not-expected | not-expected | high | `YF3SRQKF` supplies no particular associated paper; absence of a paper-role member is not evidence that one should be added speculatively. |
| EP-104/software/site | required | required | confirm-required | high | `YF3SRQKF`, *CatVis*, is the catalogued Visual Analytics for the World’s Library Data project/software site. |
| EP-105/paper/main | required | required | confirm-required | high | `8ZZAKGN4`, *Digital Ricoeur Data Model*, is the EADH 2018 conference paper record. |
| EP-105/software/repo | unknown | not-expected | not-expected | high | `8ZZAKGN4` describes the EP-021 Digital Ricoeur project; no repository is evidenced for this separate conference-paper singleton. |
| EP-106/paper/main | required | required | confirm-required | high | KHC5YDIS, *Exploring the History of American Philosophy in a Computer-Assisted Framework*: conference paper with stored PDF. |
| EP-106/software/repo | unknown | not-expected | not-expected | high | KHC5YDIS: paper applying concept-analysis tools; no distinct software project or distributable code identified. |
| EP-107/paper/main | unknown | not-expected | not-expected | high | RB4R2L7J: web commentary, not a separate paper. |
| EP-107/software/repo | unknown | not-expected | not-expected | high | RB4R2L7J describes EP-024, *The History of Philosophy*; it is not the software project itself. |
| EP-107/web/site | optional | required | confirm-required | high | RB4R2L7J, *Gorgeous Interactive Timeline of Philosophical Ideas*: upgrade; this Daily Nous article is the singleton’s main output. |
| EP-108/paper/main | unknown | not-expected | not-expected | high | 39UYKEQF: blog discussion; no separate paper is an artifact of this audit unit. |
| EP-108/software/repo | unknown | not-expected | not-expected | high | 39UYKEQF: methodological blog commentary with no identified software release. |
| EP-108/web/site | optional | required | confirm-required | high | 39UYKEQF, *Philosophers’ Favorite Word Is “Wisdom.” NOT*: upgrade; the blog post is the singleton’s main output. |
| EP-109/paper/main | unknown | not-expected | not-expected | high | EH9KKPCL: web visualization post, not a paper. |
| EP-109/software/repo | unknown | not-expected | not-expected | high | EH9KKPCL: no repository or software project identified. |
| EP-109/web/site | optional | required | confirm-required | high | EH9KKPCL, *Recent Philosophy, Visualized*: upgrade; the Reddit visualization post is the singleton’s main output. |
| EP-110/paper/main | unknown | not-expected | not-expected | high | F6MVJAHB: web analysis with no separate paper identified. |
| EP-110/software/repo | unknown | not-expected | not-expected | medium | F6MVJAHB: analysis code is plausible, but no repository or code release is identified in the record. |
| EP-110/web/site | optional | required | confirm-required | high | F6MVJAHB, *SEP Analysis*: upgrade; the analysis site itself is the singleton’s main output. |
| EP-111/paper/main | unknown | not-expected | not-expected | high | UL4YCU77: web commentary, not a separate paper. |
| EP-111/software/repo | unknown | not-expected | not-expected | high | UL4YCU77 describes EP-024; the timeline/software is not an output of this commentary unit. |
| EP-111/web/site | optional | required | confirm-required | high | UL4YCU77, *The History of Philosophy Visualized in an Interactive Timeline*: upgrade; the Open Culture article is the singleton’s main output. |
| EP-112/paper/main | required | required | confirm-required | high | CYHYXVQ3, *A Computationally Assisted Reconstruction…in Spinoza’s Ethics*: journal article with stored PDF and DOI. |
| EP-112/software/repo | unknown | not-expected | not-expected | medium | CYHYXVQ3 uses an automated deduction system, but identifies no separate distributable code artifact. |
| EP-113/book/main | required | required | confirm-required | high | P7KW5AL3, *Causal Attributions and Corpus Analysis*: book chapter with stored PDF and DOI. |
| EP-113/software/repo | unknown | not-expected | not-expected | medium | P7KW5AL3 uses corpus and distributional-semantic methods; no supplemental code release is identified. |
| EP-114/paper/main | unknown | not-expected | not-expected | high | 8R9I95UB: archival collection/web resource, not a paper. |
| EP-114/software/repo | unknown | not-expected | not-expected | high | 8R9I95UB: library archival project; no software expectation follows. |
| EP-114/web/site | optional | required | confirm-required | high | 8R9I95UB, *Charles S. Peirce Papers*: upgrade; the archival collection page is the singleton’s main output. |
| EP-115/dataset/main | required | required | confirm-required | high | U5CYJ6QC, *Computational History of Philosophy of Science Dataset*: Zenodo dataset, DOI 10.5281/zenodo.3539563. |
| EP-115/paper/main | unknown | not-expected | not-expected | high | U5CYJ6QC: dataset record; no specific companion paper identified. |
| EP-115/software/repo | unknown | required | confirm-required | high | U5CYJ6QC explicitly identifies the generation code at `github.com/dhicks/comp-HOPOS`. |
| EP-116/paper/main | required | required | confirm-required | high | XAZXP5UR, *Computer Modeling in Philosophy of Religion*: journal article with stored PDF and DOI. |
| EP-116/software/repo | unknown | not-expected | not-expected | high | XAZXP5UR: conceptual/methodological article; no particular software release identified. |
| EP-117/paper/main | required | required | confirm-required | high | X2FX7P5P, *Computer Science and Metaphysics: A Cross-Fertilization*: journal article with stored PDF and DOI. |
| EP-117/software/repo | unknown | not-expected | not-expected | medium | X2FX7P5P reports computer-assisted results but identifies no separate repository artifact. |
| EP-118/book/main | required | required | confirm-required | high | 5IZS6JVY, *History of Philosophy in Ones and Zeros*: book chapter with stored PDF and DOI. |
| EP-118/software/repo | unknown | not-expected | not-expected | high | 5IZS6JVY: historical chapter; links to visualization projects were ruled unrelated, not implementations. |
| EP-119/paper/main | required | required | confirm-required | high | 5WG7CYTZ, *Modeling Working Memory to Identify Computational Correlates of Consciousness*: article with stored PDF and DOI. |
| EP-119/software/repo | unknown | not-expected | not-expected | medium | 5WG7CYTZ describes computational models but identifies no public code artifact. |
| EP-120/book/main | required | required | confirm-required | high | CYC8HM7K, *Natural Language Processing and Network Visualization for Philosophers*: chapter with stored PDF and DOI. |
| EP-120/software/repo | unknown | not-expected | not-expected | high | CYC8HM7K describes EP-022/DR2; any DR2 software belongs to that separate unit. |
| EP-121/paper/main | required | required | confirm-required | high | JIHIL6JB, *Signals and Spite in Fluctuating Populations*: article with stored PDF and DOI. |
| EP-121/software/repo | unknown | not-expected | not-expected | medium | JIHIL6JB reports computational experiments without identifying a code release. |
| EP-122/paper/main | required | required | confirm-required | high | LPTARVPF, *The Curious Case of Connectionism*: article with stored PDF and DOI. |
| EP-122/software/repo | unknown | not-expected | not-expected | high | LPTARVPF: historical survey of connectionism, not a software output. |
| EP-123/paper/main | required | required | confirm-required | high | PBLT2LNY, *The Evaluation of Discovery*: article with stored PDF and DOI. |
| EP-123/software/repo | unknown | not-expected | not-expected | medium | PBLT2LNY discusses search algorithms and simulations but identifies no specific repository. |
| EP-124/paper/main | required | required | confirm-required | high | P4TKDCDQ, *Towards Computer Simulations of Virtue Ethics*: article with stored PDF and DOI. |
| EP-124/software/repo | unknown | not-expected | not-expected | medium | P4TKDCDQ mentions a Python/Sugarscape sample simulation, but no supplemental repository or downloadable implementation is identified. |
| EP-125/paper/main | required | required | confirm-required | high | 86CBJJDY, *Towards More Realistic Modeling of Linguistic Color Categorization*: article with stored PDF and DOI. |
| EP-125/software/repo | unknown | not-expected | not-expected | medium | 86CBJJDY presents a model and evaluation method without identifying a public code artifact. |
| EP-126/paper/main | required | required | confirm-required | high | 2WB2G975, *Using AI Methods to Evaluate a Minimal Model for Perception*: article with stored PDF and DOI. |
| EP-126/software/repo | unknown | not-expected | not-expected | medium | 2WB2G975 describes an implemented minimal model, but no separate distribution is identified. |
| EP-127/book/main | required | required | confirm-required | high | UNYNUDYK, *Using Corpus Linguistics to Investigate Mathematical Explanation*: chapter with stored PDF and DOI. |
| EP-127/software/repo | unknown | not-expected | not-expected | medium | UNYNUDYK reports corpus analysis; no code or corpus repository is identified as its artifact. |
| EP-128/paper/main | required | required | confirm-required | high | 5FVCGC6H, *What Simulations Teach Us About Ordinary Objects*: article with stored PDF and DOI. |
| EP-128/software/repo | unknown | not-expected | not-expected | high | 5FVCGC6H reviews models and simulations rather than presenting a named software release. |
| EP-129/paper/main | required | required | confirm-required | high | L6A78CC9, *Computer-Supported Analysis…in Variants of Gödel’s Ontological Argument*: journal article with DOI. |
| EP-129/software/repo | unknown | not-expected | not-expected | medium | L6A78CC9: computer-supported analysis does not itself establish an expected public repository. |
| EP-130/dataset/main |  | required | add-required | high | 2Y8RXPUW, Gephi Tutorial Data; DOI 10.4231/C5P0-3592 identifies tutorial data, replacing paper/main. |
| EP-130/paper/main | required | not-expected | not-expected | high | 2Y8RXPUW, *Gephi Tutorial Data—Mapping Topics…Deleuze*: wrong artifact type; DOI 10.4231/C5P0-3592 identifies dataset/tutorial data, not a paper. Replace as noted below. |
| EP-130/software/repo | unknown | not-expected | not-expected | high | 2Y8RXPUW: dataset/tutorial-data output; no software repository identified. |
| EP-131/paper/main | required | required | confirm-required | high | Y86ECU3J, *Challenging Distributional Models with a Conceptual Network…*: NAACL paper with stored PDF and ACL DOI. |
| EP-131/software/repo | unknown | not-expected | not-expected | high | Y86ECU3J describes EP-027, *Challenging_DMs*; the repository belongs to that separate software unit. |
| EP-132/paper/main | unknown | not-expected | not-expected | high | TWVDCDBK: project description names no particular paper as the project’s expected main publication. |
| EP-132/software/site | required | not-expected | not-expected | high | TWVDCDBK, *From Data to Wisdom—FDTW Project*: wrong artifact type; the record describes a funded humanities research project and its website, not software. Replace below. |
| EP-132/web/site |  | required | add-required | high | TWVDCDBK, From Data to Wisdom project website; replaces mistyped software/site. |
| EP-133/paper/main | required | required | confirm-required | high | QRWNFU8B, *The Computational Philosophy: Simulation as a Core Philosophical Method*: journal article with DOI. |
| EP-133/software/repo | unknown | not-expected | not-expected | medium | QRWNFU8B: methodological article; no particular implementation or repository identified. |
| EP-134/paper/main | required | required | confirm-required | high | HDJVW84R, *Computational Modeling in Philosophy: Introduction to a Topical Collection*: editorial article with DOI. |
| EP-134/software/repo | unknown | not-expected | not-expected | high | HDJVW84R: collection introduction/editorial work, not a software project. |
| EP-135/paper/main | required | required | confirm-required | high | Q2X9RT6Q, *Symbolic AI and Gödel’s Ontological Argument*: journal article with DOI. |
| EP-135/software/repo | unknown | not-expected | not-expected | medium | Q2X9RT6Q: symbolic-AI subject matter alone does not establish a separate code artifact. |
| EP-136/misc/9UU9MIKC | unknown | not-expected | not-expected | high | 9UU9MIKC, *Data-Driven History of Ideas*: generic `misc` type is unsuitable for an editorial special collection; replace with its collection website below. |
| EP-136/paper/main | unknown | not-expected | not-expected | high | 9UU9MIKC: special collection with no single main paper; constituent works are not a generated `paper/main`. |
| EP-136/software/repo | unknown | not-expected | not-expected | high | 9UU9MIKC: editorial/curatorial endeavour; no mechanical software expectation. |
| EP-136/web/site |  | required | add-required | high | 9UU9MIKC, Data-Driven History of Ideas collection landing page; replaces generic misc entry. |
| EP-137/paper/main | required | required | confirm-required | high | TS5N64ZF, *Hermeneutic Calvinball versus Modest Digital Humanities…*: journal article with DOI. |
| EP-137/software/repo | unknown | not-expected | not-expected | high | TS5N64ZF describes EP-022/DR2; software expectations remain with that separate unit. |
| EP-138/book/main | required | required | confirm-required | high | HFE4XTVZ, *How Far Can We Get in Creating a Digital Replica of a Philosopher?*: book chapter. |
| EP-138/software/repo | unknown | not-expected | not-expected | medium | HFE4XTVZ: no independently identified replica implementation or public code release in the record. |
| EP-139/paper/main | required | required | confirm-required | high | 56Q2IIEE, *Computational Philosophy: Reflections on the PolyGraphs Project*: journal article with DOI. |
| EP-139/software/repo | unknown | not-expected | not-expected | medium | 56Q2IIEE reflects on PolyGraphs, but this paper unit identifies no specific project repository or software release. |
| EP-140/paper/main | required | required | confirm-required | high | 7WAESDDN, *Creating a Large Language Model of a Philosopher*: journal article with DOI. |
| EP-140/software/repo | unknown | not-expected | not-expected | medium | 7WAESDDN: no distinct model repository or code release is identified; the related chapter EP-138 is a sibling, not software membership. |

## Review focus

The independent consistency findings were resolved before user approval. The user then approved the complete batch, including EP-004 as a separate required original artifact. These recommendations are now ledger rulings; any later amendment requires a new last-wins `inventory` record.

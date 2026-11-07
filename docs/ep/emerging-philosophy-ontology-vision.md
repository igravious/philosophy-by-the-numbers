# A Vision for an Ontology of the Emerging Philosophy Research Bank

**Status:** revised proposal, 2026-10-25; preserves distinctions identified in critique and adds the approved audit-unit and agentive-entity model. No RDF schema or migration has been implemented.
**Scope:** a research bank whose frozen 2026-10-15 baseline contains 161 top-level Zotero items: 28 records in 11 complexes, 129 singleton records, and 4 excluded non-project records. The resulting 140 audit units receive inventories, with additional staged discoveries and ongoing deep dives outside that frozen count. The field is broadly the intersection of philosophy and computing, with items spanning the 1970s to the present.
**Purpose:** to describe the bank's entities, relations, evidence, and statuses well enough to support the audit — not to build an ontology of philosophy.

## 1. The problem

The bank is heterogeneous. It contains books, papers, software, applets, datasets, websites, digital editions, archives, conferences, people, institutions, and multi-year projects. A single project may produce papers, software, and a website over decades; a single item may play several roles. Zotero is good at cataloguing the items, but it is not an ontology: it has no native model for genuine projects and works, curated record complexes, singleton audit units, artifact inventories, same-complex relations, liveness, claim provenance, or stable audit-unit IDs.

The data model should make the bank's existing model explicit:

- complexes and singletons as audit units, distinct from genuine projects, works, and other outputs;
- audit-unit inventories and artifacts;
- item roles and primary assignments;
- cross-references (legacy `same-project`, operationally same complex, plus `describes`, `implements`, `cites`, `unrelated`);
- stable opaque EP audit-unit IDs and merge/split history;
- sources, snapshots, hashes, and reading status;
- claims, evidence, confidence, and interpretation;
- liveness and acquisition status;
- agentive people, AIs/LLMs, recursively constituted collectives, and their evidenced roles.

### Authority and documentary record

There is no single source of truth for the whole bank. Authority is divided by record family and must be explicit. Zotero is authoritative for the live bibliographic records, attachment relations, and collection membership it currently stores. A dated Zotero export is authoritative only for the state captured in that snapshot. The clustering review sheet records human gate decisions; the audit plan records the procedure and invariants; deep-dive dossiers record scholarly assessments; manifests record local artifact inventories and byte-level identity; scans and archived pages are evidence sources. These records can disagree because they have different scopes or dates. The bank must retain provenance and resolve conflicts by record family, scope, and time rather than silently picking one global winner.

Maintain a **document and authority register** as a first-class bank record. It lists Zotero itself (as a live cataloguing authority), each relevant non-Zotero document or explicitly grouped document set, and the register document itself. Its own entry uses a stable register ID and repository path; it does not embed a self-hash, since changing the register would change that hash. Record for each entry its identifier, title, document/resource type, location, authority scope, relation to other records, status, and version evidence (date, snapshot version, or checksum where suitable). A group entry must enumerate its members, not hide an open-ended directory behind a label.

The initial inventory is the [document and authority register](emerging-philosophy-document-register.md). It is an index and provenance map, not a claim that all listed records are equally authoritative or current. In particular, a review-sheet Markdown rendering is derived from its YAML source; a pre-regeneration sheet is historical evidence, not the current decision source; and a dossier is an interpretive account, not a substitute for its cited primary sources. Zotero is registered as a cataloguing system, its exports as documents, and this proposal as a document. The register contains a record describing the register document itself. That does not make the record, the document, and the cataloguing system the same entity.

**Authority is scoped responsibility, not guaranteed truth.** Zotero can contain a bibliographic error; an approved decision can later be revised; a manifest can be stale. A contradiction must retain the competing records and the evidence for a correction. A newer timestamp alone does not settle it. The register documents where a correction belongs and which derived records must then be refreshed.

## 2. Design stance

1. **Small core, explicit distinctions.** Define the entities and relations required by the bank's cases, then review candidate mappings to existing vocabularies. Economy means avoiding duplication, not collapsing distinctions that affect interpretation.
2. **Multiple authorities, explicit boundaries.** Keep Zotero as the live bibliographic catalog, and identify the authoritative record for each other data family. Preserve snapshots and decision documents with their dates and provenance. RDF, if adopted, is a derived integration view; it does not silently supersede those authorities.
3. **Activities and their products.** Distinguish an editorial endeavour from the volume it produces, and a software endeavour from its program and releases. A bank entry may refer to several of these; that does not require treating an activity and an intellectual work as the same entity. Event and editorial projects remain fully supported.
4. **Evidence-first.** Keep claims, source passages, source consultations, and assessments distinct. A claim may be attributed to an author or asserted by the dossier; a passage is located in a particular source version; a consultation records who checked what and how much; an assessment records support, contradiction, or interpretation and its rationale. Do not treat full-text access as proof that every claim was checked.
5. **Human-scale.** Use maintainable documents and validation for the current bank. File count, serialization, and a possible triple store are implementation decisions; they do not determine which distinctions exist.
6. **Stable IDs.** EP audit-unit IDs and artifact IDs are opaque and stable; an EP ID is `EP-` followed by at least three digits (`EP-001`, `EP-1000`), and EP IDs are not project IDs. Existing EP-001…EP-027 identify 11 complexes and 16 anchored singletons; EP-028…EP-140 identify the remaining singletons through the singleton-ID register. Coordinated allocation preserves the same record's ID through anchoring and return, with its registry mapping dormant while anchored. Retired IDs are logged with successors. New IDs exceed the high-water mark across active, dormant, logged, and retired IDs, and no **new** allocation reuses an ID. The existing active/retired EP-004, EP-020, and EP-022 exceptions are inherited pre-policy history: keep them explicit and version-qualified; do not renumber them.
7. **Do not model the field's ideas.** The ontology describes the bank, not philosophy. Concepts are represented as `skos:Concept` links to InPhO, PDC, PhilPapers, and local terms, not by reimplementing the field's intellectual content.

## 3. Core model

### Classes

These are candidate concepts, not a requirement to mint a local class for every row. “Alignment” below means a candidate to investigate, not `owl:equivalentClass` or a commitment to import all listed vocabularies. Before formalizing a mapping, record its direction, strength, vocabulary version, and intended inferences.

| Local class | Alignment | Purpose |
|---|---|---|
| `ep:Entry` | local catalog record | A bank record referring to one or more entities. Distinguish the record from the work, program, or endeavour it describes. |
| `ep:Entity` | review agent/group/event mappings separately | An agentive entity: a person, an AI/LLM, or a collective, including publishers, institutions, families, movements, conferences, and other event-like collectives. Entities may recursively contain entities and may occupy author, editor, publisher, organizer, or contributor roles. |
| `ep:Person` | `crm:E21_Person`, `foaf:Person`, `schema:Person` | Philosophers, programmers, editors, directors; a kind of agentive `ep:Entity`. |
| `ep:Organization` | `crm:E74_Group`, `org:Organization`, `schema:Organization` | Universities, labs, archives, publishers; a kind of collective `ep:Entity`. |
| `ep:Complex` | local curated record grouping | A curated grouping of 2+ Zotero records treated as one audit unit. Complex cardinality is a documentary grouping decision, not a claim that its members are one project or work. |
| `ep:AuditUnit` | local; complex or singleton | The unit receiving an expected-artifact inventory and audit summary. A singleton contains exactly one record and may represent a genuine project, work, software output, or other output. |
| `ep:Project` | review activity mappings; DOAP only for applicable software projects | A genuine named endeavour, including research, software, editorial, and event projects, with optional subprojects and constituent activities. Project-hood is independent of whether its records form a complex or singleton. |
| `ep:Work` | `lrMoo:F1_Work`, `fabio:Work` | The intellectual work: a book, paper, theory, or software design. Work-hood likewise does not follow from record cardinality. |
| `ep:Expression` | `lrMoo:F2_Expression` | A particular text, version, translation, or implementation. |
| `ep:Manifestation` | review LRMoo manifestation model | An edition or distribution specification; distinguish it from a particular physical copy or downloaded file. |
| `ep:Copy` / `ep:DigitalFile` | review LRMoo item and CRMdig digital-object models separately | A particular copy or stored file, with location, checksum where applicable, and derivation from a source. A scan is a surrogate, not a new assertion that the underlying work is identical to its file. |
| `ep:Software` | review CRMdig and software-application models | Programs, applets, web apps, toolkits; distinguish software project, program, release, executable file, and execution. |
| `ep:Dataset` / `ep:Distribution` | review DCAT models | A dataset and a particular available distribution of it; distinguish these from locally downloaded bytes. |
| `ep:WebResource` / `ep:Capture` | local; review external web-resource models | A web resource and a dated capture of its content. A URL, successful HTTP response, preserved page, and operational service are different observations. |
| `ep:Event` | `crm:E7_Activity`, `schema:Event` | Conferences, workshops, demos, publications. A conference can be both an event and an agentive collective entity; distinguishing those aspects does not deny its entity status. |
| `ep:Concept` | SKOS candidate; individual mappings reviewed separately | Topics, schools, methods, field classifications. Do not treat whole external concept classes as equivalent or default individual links to exact matches. |
| `ep:Artifact` / `ep:InventorySlot` | local | An identified artifact versus an inventory expectation that may be satisfied by zero, one, or several artifacts. A required slot does not prove its expected artifact ever existed. |
| source role | local relation to consultation/assessment | A document, file, dataset, or other entity used as evidence. Being a source is a role, not a second copy of that entity. |
| `ep:Proposition` | local; possible CRMinf alignment after review | Content asserted by an author, source, or dossier; keep separate from anyone's belief in it. |
| `ep:Claim` | local | A dated assertion made by a source, dossier, reviewer, or decision-maker, with explicit attribution and scope. |
| `ep:SourcePassage` | local; possible PROV-qualified source relation | A locator into a particular source version, including a whole-source locator where appropriate. |
| `ep:Consultation` | `prov:Activity` (candidate) | Who accessed which source version, when, and at what coverage/depth. Reading status belongs here. |
| `ep:Assessment` | local | A support/contradiction/interpretation judgment connecting claim and passage, with rationale and assessor. Confidence is optional and must be defined. |
| `ep:RegisterRecord` | local | A register entry describing a document, document set, system, or other resource, including an entry describing the register document. |
| `ep:DecisionRecord` | local; provenance from a decision activity | A record of a human-gate assignment or edge decision with date, rationale, evidence, and supersession history. Distinguish the decision activity from its record. |
| `ep:AvailabilityObservation` / `ep:AcquisitionAttempt` | local; provenance from inspection/acquisition activities | A dated finding versus an attempt to obtain something. Record inspected target, method, outcome, and limits; absence from one location does not establish loss everywhere. |

### Relations

| Local relation | Alignment | Use |
|---|---|---|
| `ep:hasPrimaryAssignment` | local | Entry → assignment decision, scoped to a population/version. Its outcome is assigned, unresolved, or non-project; an assigned outcome identifies an audit unit. |
| `ep:memberOfComplex` | local pending domain review | Entry → curated complex. Do not align to `prov:wasAssociatedWith`, which relates an agent to an activity, and do not infer membership in a genuine project from complex membership. |
| `ep:sameComplexAs` | local | Confirmed same-complex relation between records. The legacy serialized gate token `same-project` maps operationally to this relation; the token is retained for compatibility. |
| `ep:generatedArtifact` | PROV generation candidate; inverse is `prov:wasGeneratedBy` | Activity → artifact actually generated; the inverse is not a qualified relation. |
| `ep:hasInventorySlot` / `ep:satisfiesSlot` | local | Audit unit → expectation; artifact → expectation it satisfies. Required/optional status belongs to the inventory slot in its audit-unit context, whether complex or singleton. |
| `ep:hasProjectPart` | local pending domain review | Genuine project/subproject structure where the human model asserts an endeavour has parts. Keep distinct from record grouping and bibliographic containment. |
| `ep:partOfDocument` | local pending domain review | Structural containment such as chapter-in-volume or article-in-issue; not evidence of same-complex membership. |
| `ep:hasRole` | local, attached to a contextual relation | Primary paper or secondary commentary relative to an audit unit, or author/editor/publisher/organizer/contributor/programmer relative to an activity or output. Keep roles distinct from resource types such as book, software, or dataset. |
| `ep:containsEntity` | local; external mereology/group mappings require review | Entity → constituent entity, recursively applicable. Constituency alone asserts no contribution to every output. |
| `ep:crossReference` | local typed relation with decision provenance | `describes`, `implements`, `cites`, or containment. `unrelated` records rejection of a proposed link in a specified audit; it does not assert absence of every conceivable relationship. |
| `ep:createdBy` | `prov:wasAttributedTo` | Agentive entity responsible, with collective and constituent credit asserted separately. |
| `ep:authoredBy` / `ep:programmedBy` / `ep:editedBy` / `ep:publishedBy` / `ep:organizedBy` / `ep:contributedBy` | review `prov:wasAttributedTo` and role-specific mappings | Role-specific credit for a person, AI/LLM, or collective. A role held by a collective does not distribute that role to all constituents. |
| `ep:affiliatedWith` | local; ORG membership only where actual membership is meant | Agentive entity → organization, with role, dates, and evidence where known. Affiliation need not be membership. |
| `ep:hasVersion` | local pending exact property review | Version/edition relation. Do not map to PROV specialization without checking domain semantics and direction. |
| `ep:wasRevisionOf` | `prov:wasRevisionOf` | Successor/predecessor. |
| `ep:cites` | `cito:cites` | Citation. |
| `ep:influencedBy` | local; CRM activity-influence mapping requires domain review | An attributed influence claim with evidence and explicitly typed participants. |
| `ep:implements` | local | Software implements a theory, logic, or design. |
| `ep:describes` | `crm:P129_is_about` | Commentary or documentation. |
| `ep:uses` | PROV usage candidate for activity → entity | Activity using a tool, source, or other entity. Mere topical relation is not usage. |
| `ep:about` | `crm:P129_is_about` | Work about a concept/project. |
| `ep:consultedSource` | `prov:used` (via consultation activity) | A source version used in a documented research activity. |
| `ep:hasAssessment` | local | Connects a claim to a source passage and records how the passage bears on it. |
| `ep:hasAvailabilityObservation` | local | Dated liveness/access/acquisition observation; these are time-varying findings. |
| `ep:identifier` | identifier node or typed literal | External identifier with scheme, value, and identified entity. Use `owl:sameAs` only when two resource URIs denote the same individual. |
| identifier succession | local decision record | Merge/split/retirement, reasons, affected records, and successors; renaming a record does not itself establish identity between the entities described. |

**Collective emission and credit.** A collective entity can emit output through only a subset of its constituents. For example, a conference can generate proceedings through its organizers, editors, and authors without every participant contributing. Assertions that the collective generated, published, organized, or contributed an output are separate from assertions about particular constituents. Record the evidenced role-holders and their roles; never infer that every member, participant, or constituent contributed.

## 4. Candidate vocabularies

- **CIDOC CRM** is a candidate reference model for activities, agents, objects, and their historical relations.
- **LRMoo** is a candidate for distinctions among works, expressions, manifestations, and items; its applicability to software versions must be assessed case by case.
- **CRMdig** supplies digital objects and software.
- **CRMinf** is available if claims and argumentation need a formal model; it is not required at the current scale.
- **SKOS** is a candidate for local concept schemes; mappings to external terms require their own evidence, scope, and match strength.
- **PROV-O** carries provenance; **DCAT** carries datasets; **DOAP/CodeMeta** carries software.
- **schema.org** is an export/publishing veneer, not the internal model.
- **SHACL** can validate a declared graph against data requirements if RDF is adopted. A valid graph does not establish that historical claims are true or the evidence is comprehensive.

CIDOC CRM is a reference model, not a full implementation. The bank should use the parts it needs and map the rest; a full CRM deployment would be over-engineering at this scale.

## 5. Invariants

These are the rules worth enforcing with SHACL or a validation script:

1. The audit assigns each in-scope Zotero item exactly once in the declared population, while complex membership, genuine project/work identity, structural containment, and cross-references remain separate relations.
2. A complex contains at least two curated records; a singleton audit unit contains exactly one. Neither cardinality determines whether the represented endeavour/output is a project, work, software output, or another kind.
3. Every audit-unit inventory, whether for a complex or singleton, separates artifact expectation (`required` / `optional` / `unknown`) from current presence/access and from acquisition-attempt history. Phase-2 and Phase-4 coverage includes all 140 audit units.
4. EP audit-unit, artifact, and decision IDs are unique within their declared namespaces; retired IDs and supersession links remain resolvable. EP-001…EP-140 do not denote projects merely by being assigned.
5. Every substantive summary claim has an assessment record; the policy may allow source-level support where passage-level checking has not occurred, but must label that coverage honestly.
6. Each completed source consultation records source version, access date, reader/activity, and coverage (`full text`, selected pages, abstract, metadata). `Not accessed` belongs to a research/acquisition record, not a completed consultation. A locator may identify a passage or explicitly identify the source as a whole; access does not imply reading, and reading does not imply claim verification.
7. Availability, acquisition attempts, reading coverage, and gate-decision states are distinct, dated observations rather than one terminal status field.
8. Version/edition relations are asserted only where identity and direction have been checked. An unknown predecessor remains unknown; the earliest located version need not be the original.
9. Every external identifier records its scheme and the entity it identifies; identifier values are not treated as identity links by default.
10. Human-gate decisions include date, rationale, evidence, decision-maker, and supersession history.
11. Complexes are derived only from confirmed legacy `same-project` decisions, interpreted as `ep:sameComplexAs`; `part-of`, `describes`, `implements`, `cites`, and `unrelated` do not create complex membership. Genuine `ep:hasProjectPart` assertions are not derived from record grouping.
12. Credit to a collective and credit to its constituents require separate assertions. Constituency, participation, or membership never licenses an inference that every entity contributed to an output; collective emission through an evidenced subset, such as conference proceedings through organizers/editors/authors, must remain representable.
13. The document/authority register includes itself, the Zotero authority record, and every document within its declared inventory boundary. Grouped entries enumerate their members or refer to a registered manifest that does so. External references not yet individually registered are disclosed as a coverage gap.

## 6. Implementation path

1. Work through concrete cases: Sloman's original and revised text plus reviews; the two Proof Designers; the Burkholder volume, chapters, and scans; TALLC's project, applets, papers, and partial runtime preservation; the symposium and its editorial subprojects. Record which distinctions each case requires.
2. Create and maintain the document/authority register, including its explicit self-entry; agree which artifacts are authoritative by data family and how conflicts are resolved.
3. Define the smallest query set the audit must answer and model only the distinctions those queries require.
4. Prototype the data in the simplest maintainable format (YAML/Markdown plus validation scripts is a candidate); verify that Zotero records, snapshots, gate decisions, artifact records, consultations, and assessments can be linked without flattening their distinctions.
5. Compare the prototype with RDF and SHACL only if interoperability or graph queries justify the extra vocabulary and tooling. Treat external alignments as reviewed mappings, not declarations of equivalence.
6. If RDF is adopted, make it a reproducible view of the registered authority records and preserve source/version provenance in the export.
7. Consider public JSON-LD only after licensing and disclosure review; private scans and research copies must not leak through the export.
8. Iterate at human gates; revise the model when a real case or query exposes a gap, and document the migration.

## 7. What it must answer

- Which audit units are complexes and which are singletons, which records belong to each, and what artifacts does each inventory contain?
- Which genuine projects, works, software outputs, and other endeavours/outputs exist, and how do they relate to audit units without conflating the two?
- Which artifacts are present, missing, or only reference-only across all 140 audit units?
- Which records are same-complex (legacy `same-project`), cross-referenced, unresolved, or non-project?
- Which claims are supported by which sources, and how well were those sources read?
- Which artifacts are alive, dead, link-rotted, lost, or unknown?
- Which agentive people, AIs/LLMs, and collectives occupy author/editor/publisher/organizer/contributor roles for each activity or output?
- Where a collective is credited, which constituents have separately evidenced roles, and which subset actually emitted the output?
- What changed between snapshots?
- Which IDs have been retired, merged, or split?
- Which document or system governs each kind of record, which version was used, and which outputs depend on it?
- Which statements are attributed to a source, endorsed by a reviewer, contested, or still unchecked?
- What does the register say about itself, its coverage, and its revision history?

## 8. Risks and open questions

- **Over-modeling.** The biggest risk is building a grand ontology for a small bank. Keep the core thin; add classes only when a real query needs them.
- **Project, work, and complex.** Preserve the book as intellectual work, its production as an editorial endeavour, its role as an output of a larger project, and the curated complex grouping its records. One entry can refer to these connected entities without making them identical; a singleton can still be a genuine project or work.
- **Multi-role items.** A paper can be a primary paper for one audit unit and a secondary commentary for another. Roles must be relation-specific, not intrinsic.
- **Identity and credit.** Same-entity and same-complex identity across records is hard. Use external IDs and human confirmation; do not infer identity from names alone, or constituent contributions from collective credit alone.
- **Zotero limitations.** Zotero's item types do not map cleanly to editions, software, datasets, or journals. The ontology should absorb that mismatch, not reproduce it.
- **Claims in RDF.** It may be better to keep claim/evidence records in Markdown/YAML and link to them, rather than put every sentence in RDF. Decide before building the claim layer.
- **Licensing.** Some sources are private research copies; the public bank may need rights metadata and access restrictions.
- **Scope creep.** The deep-dive sequence and the broader collection have different coverage. Representing a later publication or an external authority must not silently add it to the audited population.

Open questions for the critic:

- Which CIDOC CRM distinctions help the concrete cases, and which mappings can safely remain optional?
- Which project instances admit an activity mapping, and which need a distinction between continuing endeavour and constituent activities?
- Do we need CRMinf, or is a local claim/evidence model enough?
- Which external concepts should be linked, with what match strength and evidence? Importing a vocabulary is a separate decision.
- Should the public bank be a static JSON-LD export, a SPARQL endpoint, or both?
- How should the existing YAML gate decisions be exposed in other formats while preserving their authoritative source and history?

The vocabulary review should check exact terms against their specifications, including [PROV-O](https://www.w3.org/TR/prov-o/), [SKOS](https://www.w3.org/TR/skos-reference/), and [CRMinf](https://cidoc-crm.org/extensions/crminf/html/CRMinf_v1.2.1.html). Candidate mappings in this proposal are not a completed standards-conformance review.

## 9. Success criteria

The ontology succeeds if a new deep-dive entry can be added without schema changes in the common case, and if the bank can answer the questions in §7 without manual reconstruction. It fails if it becomes a second cataloguing system, if it duplicates Zotero, or if maintaining the ontology costs more than maintaining the bank.

The measure is not ontological completeness. It is whether the bank's claims, artifacts, and relations remain auditable as it grows.

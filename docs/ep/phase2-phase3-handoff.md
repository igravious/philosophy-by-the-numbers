# Handoff: Phase 2 → Phase 3 (Emerging Philosophy acquisition)

**Written 2026-10-26, after the completed Phase-2 independent reviews. For a model arriving with zero context.**

You are continuing an audit of the user's Zotero collection **"emerging philosophy"**: a personal bibliography of *philosophic computing* (computing used as a method of doing philosophy). Phase 1 grouped the records. Phase 2 confirmed the expected-artifact inventory and classified retrieval routes. **Phase 3 is acquisition and verification of the actual artifacts.**

**Current boundary:** Phase 3 is **complete under its terminal-state rule**. All 194 slots have recorded outcomes and no slots remain pending: **121 acquired** (110 required + 11 optional), **39 reference-only** (32 required + 7 optional), **9 manual** (8 required + 1 optional), and **25 documented failures** (22 required + 3 optional). There are 112 physical objects. Required coverage is **142/172 satisfied** and 30 required gaps remain visible; optional coverage is 18/22. Every acquired object passes current verification and registry ownership/link checks. Completion does not mean that every artifact was recovered. Live Zotero was not changed.

## 1. Ground truth and reading order

1. **Governing plan:** `docs/ep/emerging-philosophy-audit-plan.md`
   - Read the giant **Execution log** on line 4 first. It is the session-by-session record of user rulings and verification results.
   - Phase 3 rules are in §6.
2. **Phase-2 handoff:** `docs/ep/phase1-phase2-handoff.md`
3. **Confirmed inventory:** `sources/emerging_philosophy/review-sheet-v2.yaml`
4. **Retrieval routes:** `sources/emerging_philosophy/artifact-audit-2026-10-26.csv`
5. **Curated route corrections:** `sources/emerging_philosophy/artifact-audit-overrides-2026-10-26.yaml`
6. **Independent final review:** `docs/ep/phase-2-source-material-audit-independent-review-2026-10-26.md`
7. **Document and authority register:** `docs/ep/emerging-philosophy-document-register.md`

Authority distinctions matter:

- `sources/emerging_philosophy/decisions.jsonl` is the **append-only, last-wins authority for grouping and inventory rulings**. Do not rewrite old lines; append corrections.
- The frozen snapshot is authoritative for the Phase-1/2 population: `sources/emerging_philosophy/dumps/snapshot-20261015T172014Z.json`, library version 8069, SHA256 `57eb3a63fb299e9b122af000fa7b9923083aeff4ce0bfd305a948daa9d13c463`.
- `review-sheet-v2.yaml` and `.md` are **derived views**, not editing surfaces.
- The artifact-audit CSV is the current route table; the overrides YAML records reviewed corrections. Use both through `scripts/zotero_inventory_audit.rb`.
- Existing local `MANIFEST.md` files document particular preserved artifact sets. They are evidence, not a global Phase-3 manifest implementation.

## 2. Vocabulary that must not be collapsed

- **Complex:** 2+ Zotero records treated as one audit unit.
- **Singleton:** one-record audit unit. A singleton can itself be a project, book, article, artwork, or software output.
- **Audit unit:** a complex or singleton. There are 140.
- **Project/work:** genuine endeavours or outputs, independent of record cardinality.
- **Agentive entity:** person, AI/LLM, or collective, including publishers and conferences. Collectives may emit outputs through a subset of constituents.
- **Artifact slot:** an expected inventory entry. Several slots may legitimately resolve to one physical file, attachment, directory, or repository.
- **Physical object:** the actual file/directory/repository acquired and verified. Deduplicate these during Phase 3.

There are **11 complexes + 129 singletons = 140 audit units**, comprising 161 population records: 28 complex members + 129 singleton records + 4 excluded `non-project` records.

## 3. Confirmed Phase-2 result

The user approved **357 inventory rulings** covering all 329 machine proposals plus 28 additions. The final inventory contains **194 confirmed artifacts**, with no `unknown` entries and every remaining entry `proposed: false`.

- **172 required**
- **22 optional**
- **163 not-expected removals**
- DIALOG1's original LEVEL5 program was added separately as `EP-004/software/original [required]`.
- EP-047's Bazzocchi chapter was confirmed required and its outdated absent-project note corrected.

### Retrieval status totals

| Status | Required | Optional | Total |
|---|---:|---:|---:|
| present | 70 | 3 | **73** |
| oa-resolvable | 7 | 1 | **8** |
| direct | 19 | 6 | **25** |
| manual | 8 | 1 | **9** |
| unresolved | 2 | 0 | **2** |
| clonable | 3 | 0 | **3** |
| downloadable | 18 | 1 | **19** |
| wayback | 9 | 3 | **12** |
| reference-only | 32 | 7 | **39** |
| lost-candidate | 4 | 0 | **4** |
| **Total** | **172** | **22** | **194** |

**Coverage denominators use required slots only**, not all 194. Optional artifacts must not be used to disguise missing required artifacts.

### Remaining review-needed rows: 15

| Artifact ID | Requirement | Status | Phase-3 meaning |
|---|---|---|---|
| EP-002/software/site | required | lost-candidate | Bedau/Moor Proof Designer; no usable public copy located; do not substitute Velleman's namesake. |
| EP-004/software/original | required | lost-candidate | Original LEVEL5 DIALOG1 remains unlocated; 2016 web version is separately present. |
| EP-005/book/main | required | manual | Complete Burkholder volume; only front matter is local. |
| EP-006/software/original | required | lost-candidate | Original Pascal-era SYMLOG remains unlocated; book+disk package is a physical lead. |
| EP-011/paper/other-1 | optional | manual | KES 2007 ontology paper; same publication as EP-055. |
| EP-023/dataset/main | required | unresolved | TheofPhilo dataset; historical evidence says staff-only access, no public download verified. |
| EP-023/software/site | required | lost-candidate | TheofPhilo search/browse interface; no usable public route found. |
| EP-038/paper/main | required | manual | Pollock, *Procedural Epistemology*; same publication as EP-039. |
| EP-039/book/main | required | manual | Same Pollock chapter in a second inventory slot. |
| EP-040/book/main | required | manual | *The Digital Phoenix*. |
| EP-042/book/main | required | manual | Floridi, *Philosophy and Computing*. |
| EP-043/book/main | required | manual | *Cyberphilosophy*. |
| EP-055/paper/main | required | manual | Same KES paper as EP-011/paper/other-1. |
| EP-071/thesis/main | required | manual | Sapienza Master's thesis; institutional/author-assisted retrieval needed. |
| EP-079/web/site | required | unresolved | Aaron Kosel's *Philosophy Survey*; live 404 and no HTTP-200 capture verified. |

The user **accepted manual status for the seven distinct manual publications** and requested a targeted search of the other eight cases. That search upgraded EP-011 and EP-020; the other six remain unresolved/lost with evidence, not claims of nonexistence.

**Phase-3 acquisition addition:** `EP-003/book/main` is also an open required-artifact gap. Stored attachment `7XR2LIMA` contains only four table-of-contents pages (ix–xii), not the complete Hyperproof book. Its slot is terminally `failed` with the object and OCR evidence preserved; this is a Phase-3 content-verification result, not a Phase-2 route reclassification.

**OpenAlex outcomes:** `EP-129/paper/main` is a wrong-publication route (Satoru Niki's article, not the expected Computer-Supported Analysis paper) and remains `failed`. `EP-133/paper/main` remains `failed` after six requests in a Springer cookie/authorization redirect loop; `EP-140/paper/main` remains `failed` after one Wiley HTTP 403. Their attempt histories are preserved. `EP-135/paper/main` is acquired as verified full HTML text, not an abstract.

## 4. Phase-2 routes → Phase-3 actions

| Phase-2 status | Phase-3 action |
|---|---|
| `present/local-file` or `present/local-directory` | Verify the recorded existing local path; do not re-download unnecessarily. Record checksum/size/type and provenance. |
| `present/zotero-stored-pdf` | The attachment record is not proof of a local copy. Retrieve the attachment's file content through the Zotero API using its `attachment_key`, once per shared attachment, unless an existing local copy already passes verification; then verify and manifest it. |
| `oa-resolvable` | Retrieve the recorded OpenAlex best-OA URL and verify identity/content. Unpaywall remains unused. |
| `direct` | Retrieve the exact direct URL, respecting redirects and version distinctions. |
| `clonable` | Clone the repository; record remote, HEAD, shallow/full, clone status, `git fsck`, and clean worktree. |
| `downloadable` | Retrieve from the live project homepage/download route; inspect what the route actually supplies. |
| `wayback` | Retrieve the recorded capture and verify that its content matches the expected artifact. |
| `reference-only` | Record a terminal `reference-only` manifest; no file acquisition is implied. |
| `manual` | Await user-supplied or institutional-access retrieval; record `manual` unless a legitimate route is later supplied. |
| `unresolved` | Make only evidence-bounded further attempts; otherwise record failure/uncertainty honestly, not loss. |
| `lost-candidate` | Do not invent a download. Record a documented acquisition failure or `absent-expected` only when the evidence supports that terminal outcome. |

**Route labels are not content verification.** A PDF URL or HTTP 200 does not prove the expected text, edition, completeness, or interface was obtained.

## 5. Required acquisition design

Implement a **resumable, manifest-driven acquisition runner** rather than a one-off download script.

### Slot/object separation

- Every one of the **194 slots** needs a terminal outcome and an artifact-slot manifest or manifest entry.
- Deduplicate physical objects through a shared object registry. Slot manifests point to the verified shared object; do not download duplicate copies.
- The 61 stored-PDF slots reference **49 distinct stored attachments**.
- The 12 local-file/directory slots reference **8 distinct local paths**.
- Each file/clone on disk must belong to exactly one physical-object manifest. Shared objects may satisfy multiple slots without violating that rule.

### Per-artifact `manifest.json`

Record at least:

- artifact slot ID and shared object ID;
- requirement (`required | optional`);
- source URL(s), final URL, provenance, and version/edition where relevant;
- fetched-at, HTTP statuses, identifying User-Agent, retries, and complete attempt log including failures;
- terminal status: **`acquired | failed | manual | reference-only | absent-expected`**;
- verification fields and any content/coverage qualification;
- local path or repository path, size, SHA256 where applicable, and links to dependent slot manifests.

A terminal `failed` or `absent-expected` outcome must preserve evidence and reasoning. Do not convert a failed request into `dead` or `lost`.

### Network behavior

- Serial requests, polite delays, identifying User-Agent, bounded retries (**3 with backoff**), timeouts, and redirect limits.
- No paywall circumvention. No live Zotero writes. No redistribution of private research copies.
- `/sources/` is gitignored. Do not commit acquired artifacts.
- Post-snapshot staging subtree `MNG9HZDC` remains excluded until Phase 6. An external source may still supply a route for a frozen artifact; that does not admit the staged record into the population.

### File verification

- SHA256 and byte size for every acquired file.
- `%PDF` magic for PDFs and `pdfinfo` when available.
- Relevant format checks for HTML, images, datasets, and archives; record extraction/validation results.
- Verify expected identity, edition/version, and content extent, not just file existence.

### Repository verification

A repository has no single checksum. Record:

- remote URL and whether clone is shallow/full;
- `git rev-parse HEAD` and clone exit status;
- `git fsck` result;
- `git status --porcelain` empty;
- dependency/submodule state when relevant.

### Resumption

Skip only `acquired` artifacts whose current verification still passes:

- files: recorded SHA256 still matches;
- repositories: HEAD matches, `git fsck` is clean, and worktree is empty;
- local paths and manifests still agree.

Re-attempt or await human input for all others. A stale manifest is not proof of current integrity.

### Definition of done

Phase 3 is complete only when **every planned artifact slot has a recorded terminal outcome**, every acquired object verifies, and every file/clone belongs to exactly one physical-object manifest. Missing required artifacts must remain visible in the coverage report.

## 6. Special cases to carry into acquisition

- **EP-004 DIALOG1:** the 2016 web implementation is already local at `sources/emerging_philosophy/deep-dive/artifacts/dialog1/dialog1-20170203025603.html` — **401,245 bytes**, SHA256 `7f152ca593a927da365db05636f8d87895339273b349601c026888b9d567a529`, matching `MANIFEST.md`. Route is `present/local-file`; Wayback is provenance/fallback. The separate 1990/1992 LEVEL5 original remains `lost-candidate`.
- **EP-011 Knowledge Map:** the archived **Philosophy Published Subject Set dataset** was preserved, but its slot remains `failed` because the dataset does not recover the visualization interface. Dataset preservation is not counted as interface recovery.
- **EP-020 visualization:** the live Tableau `Rand` dashboard returned static HTML, but the slot remains `failed`: that response does not preserve or verify the JavaScript-dependent working visualization.
- **EP-105 Digital Ricoeur Data Model:** the nine-page EADH 2018 draft programme supplies only a session listing on PDF page 4 (11:00, Philip McGrath and Fernando Nascimento), not a full paper or abstract. EP-105 and the shared EP-021 optional slot therefore remain `failed` with the programme object preserved.
- **Burkholder chapters:** EP-001/030, EP-002/034, EP-004/031, and EP-006/032 have complete local chapter scans under `sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/`. EP-005 is the whole volume and remains manual; front matter alone is not the full book.
- **OSCAR:** software/site, distribution, and manual are locally preserved under `sources/emerging_philosophy/deep-dive/artifacts/oscar/`. Verify and deduplicate rather than fetch again. EP-038/039's Pollock chapter is not supplied by that mirror and remains manual.
- **EP-023 TheofPhilo:** historical Daphnet proceedings explicitly restrict database access to staff. Do not imply that a later public dataset/interface exists without evidence.
- **Version-specific sources:** reprints, working drafts, archived editions, and current editions must retain their version notes. Do not silently substitute them for the canonical version named by the slot.

## 7. Verification commands and current baseline

Current known-good results:

- Phase-2 inventory/regeneration verifier: checks 1–7 passed at Phase-3 close; all 8 checks including preservation passed at Phase-2 close.
- Phase-3 acquisition tests: **38 runs, 204 assertions, 0 failures, 0 errors**.
- Retrieval audit tests: **17 runs, 83 assertions, 0 failures, 0 errors**.
- Full Rails suite: **701 runs, 2,055 assertions, 0 failures, 0 errors, 3 skips**.
- StandardRB passed for the acquisition and audit generator files and their focused tests. Older clustering scripts retain a pre-existing style-offense baseline; do not mass-reformat them.

Useful commands:

```bash
# Inventory and ruling verification
bin/bundle exec ruby scripts/zotero_verify_decisions.rb

# Optional preservation check
ZOTERO_PRESERVATION_BASELINE=/path/to/baseline.yaml \
  bin/bundle exec ruby scripts/zotero_verify_decisions.rb

# Phase-3 acquisition tests
bin/rake test TEST=test/lib/zotero_acquisition_test.rb

# Retrieval audit tests
bin/rake test TEST=test/lib/zotero_inventory_audit_test.rb

# Focused Phase-3 lint
bin/standardrb lib/zotero/acquisition.rb scripts/zotero_acquire.rb test/lib/zotero_acquisition_test.rb

# Full suite
bin/rake test

# Regenerate current audit from its previous base plus curated overrides (no new network pass)
bin/bundle exec ruby scripts/zotero_inventory_audit.rb \
  --resume sources/emerging_philosophy/artifact-audit-2026-10-26.csv --quiet

# Run/resume all present routes
bin/bundle exec ruby scripts/zotero_acquire.rb --status present

# Verify all present routes; Hyperproof remains the sole expected non-resumable slot
bin/bundle exec ruby scripts/zotero_acquire.rb --verify --status present

# Run/resume OpenAlex routes
bin/bundle exec ruby scripts/zotero_acquire.rb --status oa-resolvable

# Verify OpenAlex routes; EP-129, EP-133, and EP-140 remain non-resumable
bin/bundle exec ruby scripts/zotero_acquire.rb --verify --status oa-resolvable
```

The Phase-3 runner is implemented in `lib/zotero/acquisition.rb` and `scripts/zotero_acquire.rb`. It supports local files/directories, stored Zotero PDFs, direct/OpenAlex/homepage/Wayback downloads, full Git clones, remote PDF/HTML/XML/RDF sources, non-file terminal outcomes, file/directory/repository verification, OCR, content-specific expectations, local preserved-copy fallbacks, and preserved failed objects. Slot/object manifests and regenerated registry/coverage indexes live under `sources/emerging_philosophy/acquisition/` (EP-R043).

## 8. Environment and working conventions

- Ruby 2.6.10, Rails 4.2: use `bin/rake`, `bin/rails`, and `bin/bundle exec ruby`.
- Do not preload gems with `bin/bundle exec ruby -rjson`; Ruby's default JSON may activate before Bundler and conflict with the Gemfile. Use `bin/bundle exec ruby -e 'require "yaml"; require "json"; ...'`.
- Ruby 2.6 has no `Array#tally`; use a Hash counter.
- YAML in the older generator uses tabs for indentation. Do not mass-reformat legacy scripts.
- Python 3 exists but has no `yaml` module; parse JSON with Python and YAML with Ruby.
- Zotero credentials come from `.env` through `SecurityConfig.load_credential` (`lib/zotero/client.rb`). Never print or transmit secrets. Use the API read-only for attachment retrieval; do not write to live Zotero.
- Live Zotero is beyond snapshot version 8069. Do not refresh the frozen population. New discoveries stay in staging until Phase 6.
- `.ai-instructions.md` is canonical; `AGENTS.md` and similar agent files are symbolic links to it. Edit only the canonical file.
- EP documentation belongs in `docs/ep/`; data artifacts belong in `sources/emerging_philosophy/`.
- Write independent-review outputs to descriptively named files **without an agent/model name in the filename**. Agent identity may change.
- Log each work session and tally changes in the plan's execution log.
- The user rules on classification decisions; machinery belongs to the agent. Present a lean with evidence and ask only when a genuine decision is needed.

## 9. Open questions and non-blockers

- **Unpaywall contact email:** still unanswered. Phase 2 used OpenAlex; continue without Unpaywall unless the user supplies it.
- **Books:** manual retrieval was accepted for the seven publications above. Do not reopen the OpenLibrary/WorldCat policy without new evidence or a user request.
- EP-014's possible relationship to the InPhO programme remains a deferred classification question, not an acquisition blocker.
- Phase-6 integration metadata fixes remain pending for `QKD3VTIY`, `DGWBG5LH`, and `NB3PQBT9`; do not silently apply them to the frozen snapshot.

## 10. Phase 3 complete; next Phase 4

All acquisition routes and non-download outcomes have been processed. The final registry contains **121 acquired slots, 39 reference-only slots, 9 manual slots, and 25 documented failures**, with **112 physical objects and zero pending slots**. The three Git repositories are full clones with recorded HEADs, successful clone/fsck checks, no submodules, and clean worktrees. Required coverage is 142/172 satisfied; optional coverage is 18/22.

The 25 failures preserve their different causes: 4 earlier content/access failures, 6 direct-route non-equivalences/access failures, 6 unresolved/lost-candidate outcomes, and 9 final remote failures. The last group comprises the TALLC SSL failure, Hyperproof redirect-only response, SYMLOG login page, two DAPHNET spam replacements, Knowledge Map dataset-without-interface, Philosophome frameset-only response, Bazzocchi `/lander` redirect, and CatVis timeout. Static shell/page acquisitions carry qualifications where dynamic behavior was not verified; they are not claims of working software preservation.

Phase 3's terminal-state rule is satisfied, but missing required artifacts remain visible in `coverage.json`. Proceed to **Phase 4: source-pinned summaries for all 140 audit units**, followed by the Phase-5 coverage/re-assessment gate. Do not skip ahead to dissemination merely because every slot is terminal. Live Zotero remains unchanged and staging remains quarantined until Phase 6.

# Phase 2 expected-artifact inventory generation and terminology implementation — for GPT-6-Luna review

**Pass date:** 2026-10-25  
**Status:** machinery and documentation complete; inventory human review has **not** begun  
**Review role:** independent critique; no direct writes to the decisions ledger, Zotero, or authoritative audit records

## 1. Purpose and scope of this pass

This pass separated record-grouping cardinality from genuine projects and works, extended expected-artifact inventory generation to every audit unit, and updated the governing documentation. It did **not** confirm inventory requirements, classify retrieval routes, probe URLs, acquire artifacts, or alter live Zotero.

The agreed local vocabulary is:

- **Complex:** a curated grouping of two or more Zotero records treated as one audit unit.
- **Singleton:** a one-record audit unit. A singleton may be a genuine project, book, article, artwork, software output, or other endeavour/output.
- **Audit unit:** one complex or one singleton. Expected-artifact inventories and later summaries belong to audit units.
- **Project/work:** genuine endeavours or outputs, not record-count categories.
- **Agentive entity:** a person, AI/LLM, or collective, including publishers and conferences. Entities may recursively contain entities. A collective may emit an output through only a subset of its constituents; collective credit and constituent credit are separate assertions, and contribution by every member must not be inferred.

## 2. Inputs and authorities

- Frozen population: `sources/emerging_philosophy/dumps/snapshot-20261015T172014Z.json`
  - library version 8069
  - SHA256 `57eb3a63fb299e9b122af000fa7b9923083aeff4ce0bfd305a948daa9d13c463`
  - 161 top-level records
- Decisions ledger: `sources/emerging_philosophy/decisions.jsonl`
  - 216 effective link rulings
  - append-only; not rewritten in this pass
- Existing anchored IDs and inventories: EP-001…EP-027
- Governing plan: `docs/ep/emerging-philosophy-audit-plan.md`
- Updated handoff: `docs/ep/phase1-phase2-handoff.md`

## 3. Generated result

`review-sheet-v2.yaml` and its Markdown rendering now contain:

| Measure | Count |
|---|---:|
| Complexes | 11 |
| Anchored singletons within EP-001…EP-027 | 16 |
| Unanchored singletons with new IDs | 113 |
| Total singletons | 129 |
| Total audit units with inventories | 140 |
| Records inside complexes | 28 |
| Excluded `non-project` records | 4 |
| Population check | 28 + 129 + 4 = 161 |

The 113 new singleton mappings are EP-028…EP-140 in `sources/emerging_philosophy/singleton-ids.json`. Allocation followed the pre-change singleton sheet order, not title semantics or row position on later regenerations.

Inventory drafts now contain **329 artifact entries**:

| Requirement | Entries |
|---|---:|
| `required` | 109 |
| `optional` | 47 |
| `unknown` | 173 |

There are **137 audit units with at least one `unknown` entry** and three without unknowns. These are machine proposals, not confirmed expectations. In particular, a generated `software/repo [unknown]` is not evidence that a repository should exist.

## 4. Implementation to review

- `scripts/zotero_cluster.rb`
  - distinguishes complexes from anchored singletons;
  - generates inventories for all 113 previously unanchored singletons;
  - adds singleton EP IDs to cross-reference targets;
  - assigns distinct IDs to repeated video artifacts;
  - carries existing ID-log entries forward without changing their dates/reasons;
  - checks unique audit-unit and artifact IDs during generation.
- `scripts/zotero_singleton_ids.rb`
  - loads and validates the singleton registry;
  - adds mappings without changing existing ones;
  - rejects duplicate item keys, duplicate EP IDs, and collisions with active/retired/logged IDs;
  - retains dormant mappings when items leave the singleton population and restores them on return.
- `scripts/zotero_verify_decisions.rb`
  - retains the original six checks;
  - adds check 7 for cardinality, population accounting, inventories, unique IDs, registry consistency, and singleton inventory flags.
- Regression tests:
  - `test/lib/zotero_singleton_ids_test.rb`
  - `test/lib/zotero_cluster_inventory_test.rb`

Legacy serialized values remain deliberately unchanged: `same-project`, ledger `type: project`, `to_project`, `non_project`, and YAML `proposed_clusters`. Operationally, `same-project` means same complex. These compatibility tokens should not be treated as ontology recommendations.

## 5. Documentation to review

- `docs/ep/phase1-phase2-handoff.md`
- `docs/ep/emerging-philosophy-audit-plan.md`
- `docs/ep/emerging-philosophy-ontology-vision.md`
- `docs/ep/emerging-philosophy-document-register.md`
- Selected grouping/assignment passages in the deep-dive handoff, scholarship reviews, glossary, index, and dossiers

Historical execution-log wording, frozen sheets/snapshots, old ledger notes, and genuine project names were intentionally preserved. The handoff roster was checked mechanically against the generated sheet: EP-012 is a two-record complex; EP-015 is an anchored singleton.

## 6. Verification evidence

The following passed on the generated deliverables:

1. All seven checks in `bin/bundle exec ruby scripts/zotero_verify_decisions.rb`.
2. All 27 pre-existing anchored units retained their memberships, rulings, inventories, existing cross-reference targets, and ID-log entries. New `to_project` values for previously unidentifiable singleton targets were intentional additions.
3. Regenerating YAML, Markdown, and the singleton registry produced byte-identical outputs.
4. Singleton IDs followed the pre-change singleton row order.
5. Registry lifecycle tests covered addition, departure/dormancy, return, duplicate-key rejection, duplicate-ID rejection, and collision rejection.
6. A repeated-video regression test confirmed `video/main` and `video/other-1` are distinct.
7. Full Rails suite: **639 runs, 1,725 assertions, 0 failures, 0 errors, 3 skips**.
8. StandardRB passed for the new registry and test files. The legacy clustering scripts retain a large pre-existing style-offense baseline; they were not mass-reformatted.

## 7. Specific questions for Luna

1. Does any current wording still conflate complexes, singletons, projects, works, or audit units?
2. Does the agentive-entity model adequately represent publishers, conferences, recursive collectives, and output emitted through only a subset of constituents?
3. Are any preservation claims stronger than the stated checks justify?
4. Can the singleton-ID lifecycle produce reuse, loss, collision, or non-deterministic allocation in an untested case?
5. Does generating inventories for all 140 audit units introduce any structural omission or double-counting?
6. Are the 329 draft entries correctly characterized as proposals, especially the 173 `unknown` entries?
7. Does the ontology's separate `ep:Complex`, `ep:AuditUnit`, `ep:Project`, and `ep:Work` treatment avoid both false identity claims and loss of genuine project structure?

Please return concrete findings with severity, file/line references where possible, and a suggested correction. Do not treat the inventory requirements as settled rulings.

## 8. Next pass after review

Incorporate valid findings, rerun regeneration and verification, then prepare evidence-backed proposals to resolve every inventory `unknown`. Only genuine classification uncertainties should require the user's decision; no artifact retrieval begins before the inventory review is complete.

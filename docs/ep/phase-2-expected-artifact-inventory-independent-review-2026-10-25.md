# Phase 2 inventory generation and terminology — independent review

**Review date:** 2026-10-25  
**Scope:** [implementation handoff](phase-2-expected-artifact-inventory-generation-and-terminology-implementation-for-gpt-6-luna-review.md), its scripts/tests, current generated outputs, governing documents, and selected deep-dive grouping passages.  
**Disposition:** the current draft accounting is reproducible, but the inventory-editing workflow needs correction before recording human inventory decisions. Five findings follow. This review makes no inventory rulings.

Only this review document was added to the project. Reproduction experiments modified copies under `/tmp`; no source scripts, ledger, registry, review sheets, ID map, authoritative audit documents, or live Zotero records were changed. No retrieval or URL probing was performed.

## Findings

### R1 — High: the advertised editing workflow loses inventory decisions

**Locations:** [generator](../../scripts/zotero_cluster.rb), lines 907, 936, 1039–1040, 1058, 1100–1101; [document register](emerging-philosophy-document-register.md), lines 25 and 47–48; [handoff](phase1-phase2-handoff.md), lines 53–66 and 92.

The generated sheet says to edit its YAML, resolve unknowns, and remove artifacts that are not expected. The register likewise says “edit the YAML, then regenerate.” However, regeneration calls `inventory_for` afresh for every audit unit and overwrites the sheet. It reads the existing output only for `id_log`; the ledger loader has no inventory-decision record type. Consequently there is no implemented round trip for those review decisions.

**Reproduction:** in a temporary copy, change `EP-028/software/repo` from `unknown`, `proposed: true` to `optional`, `proposed: false`. Regeneration succeeds but restores `unknown`, `proposed: true`. This is a synthetic persistence test, not a proposal that Sloman's book requires software.

**Suggested correction:** define and implement a durable inventory-decision source, including explicit removals, and overlay it on machine proposals. Alternatively, provide a documented render-only operation for a maintained authoritative sheet. Test confirmation, removal, and repeated regeneration before beginning the inventory gate. Register `decisions.jsonl` explicitly as the ruling authority and describe the generated sheets as derived views; currently the register omits that ledger and conflicts with the handoff. Also replace the stale v1 sheet pointer in [deep-dive-handoff.md](deep-dive-handoff.md), line 31, with the current authority/view relationship.

This persistence gap predates some terminology changes, but extending inventories to all units makes it consequential for the next authorized phase.

### R2 — High: anchored allocation conflicts with persistent singleton IDs

**Locations:** [generator](../../scripts/zotero_cluster.rb), lines 826–835, 872, 877–884; [registry helper](../../scripts/zotero_singleton_ids.rb), lines 41–44; [audit plan](emerging-philosophy-audit-plan.md), lines 37–38.

Anchored units still receive `EP-001` onward from their sorted positions. The singleton registry is checked only afterward. Creating a 28th anchored unit therefore allocates `EP-028`, which is already reserved by the persistent singleton registry. The collision guard correctly refuses to overwrite it, but an ordinary lifecycle transition cannot complete.

**Reproduction:** append a legacy `project` anchor for existing singleton `2PIU8IIM` (Sloman, currently `EP-028`) to a temporary ledger. Regeneration fails with `singleton EP IDs collide with previously assigned IDs: EP-028`. The temporary `regen-idmap.json` has already changed when it fails. Existing tests exercise the helper's dormancy behavior, not this generator integration.

**Suggested correction:** allocate anchored and singleton units through a coordinated persistent ID policy. Preserve identity when merely adding an anchor to the same singleton; apply explicit merge/split succession decisions when membership changes. Reserve active, dormant, and retired IDs before allocation, and finish validation before publishing any output. Add an integration test covering singleton → anchored unit/complex → singleton and failure without partial output changes.

**Historical qualification:** the current sheet already has active IDs `EP-004`, `EP-020`, and `EP-022` in its retirement log. The handoff explicitly acknowledges older uses of these IDs. This is inherited history, not a new reuse introduced by this pass, but blanket claims that all historical EP IDs are globally unambiguous or “never reused” need qualification. Preserve that history with a version-qualified mapping; do not silently renumber authoritative records during remediation.

### R3 — Medium: successful verification does not establish cross-reference integrity or inventory preservation

**Locations:** [verifier](../../scripts/zotero_verify_decisions.rb), lines 335–358; [generator](../../scripts/zotero_cluster.rb), lines 1020–1037; [audit plan](emerging-philosophy-audit-plan.md), line 26.

Check 7 validates counts and uniqueness but does not validate `to_project` targets against the audit unit containing the referenced item. The generator checks that an outgoing item key exists, not that its serialized EP target is correct. The verifier also does not compare inventories against a preserved pre-change baseline.

**Reproduction:** in a temporary sheet, point an anchored unit's candidate link to nonexistent `EP-999`. In the same copy, replace the first singleton's inventory with `[]` and clear its unknown flag. All seven checks still pass. An empty confirmed inventory can be legitimate; this experiment shows that the verifier cannot establish preservation of the existing draft inventory or the documented cross-reference invariant.

**Suggested correction:** verify each EP target against a key → audit-unit map, verify population keys against the frozen snapshot rather than only their count, and validate inventory entry structure. Add a separate preservation comparison against a retained pre-change baseline, allowing only explicitly intended additions. Do not require nonempty inventories universally: zero-required and explicitly empty inventories need to remain representable.

### R4 — Medium: the generated review vocabulary still equates grouping with endeavour identity

**Location:** [generator's review instructions](../../scripts/zotero_cluster.rb), lines 1075–1080 and 1102–1103.

`describes` is explained as “one talks about the other, but they are different endeavours”; `siblings` is explained as “NOT one endeavour.” Neither conclusion follows from the grouping ruling. Under the approved venue rule, an externally published paper can describe the very same genuine project while remaining a separate singleton. The label “things the machine thinks are not projects” similarly misstates `non-project` as an intellectual classification, although the revised handoff defines it as exclusion from the audit-unit population.

**Suggested correction:** describe the relations in terms of record grouping and contextual roles: a `describes` ruling does not join the records into one complex, and a `siblings` ruling records co-container/co-commentary context without joining them. Neither decides whether the records concern one genuine endeavour. Describe `non-project` as the retained exclusion token. Regenerate both views from the corrected instructions.

### R5 — Low: allocation can write an ID that the registry cannot reload

**Location:** [registry helper](../../scripts/zotero_singleton_ids.rb), lines 21, 47, and 52.

`format("EP-%03d", number)` permits four digits, while loading and high-water parsing require exactly three. In a temporary registry, `reconcile(path, ["A"], ["EP-999"])` writes `EP-1000`; the next `load(path)` rejects it. This does not affect today's 140 units, but it is an untested boundary in the advertised additive lifecycle.

**Suggested correction:** either support at least three digits consistently throughout allocation, parsing, and validation, or reject namespace exhaustion before writing. Add a boundary test at 999.

## Answers to the seven review questions

| Question | Assessment |
|---|---|
| Remaining terminology conflation? | Yes: R4 identifies current generated instructions. The main definitions and roster otherwise distinguish complexes, singletons, projects, and works correctly. |
| Agentive entities and collective emission? | Adequate at proposal level. The vision explicitly includes publishers/conferences, recursive constituency, contextual roles, separate collective/constituent credit, and emission through a subset. No implemented schema or inference tests exist yet; external vocabulary conformance was outside this review. |
| Preservation claims too strong? | Present-input byte determinism is reproduced. The historical claim that all 27 anchored inventories/targets were unchanged is not independently established by the seven checks, and a pre-terminology v2 baseline was not supplied with the packet. R1–R3 limit any broader lifecycle/preservation claim. |
| Untested singleton-ID lifecycle failures? | Yes: R2's integrated anchoring transition and R5's numeric boundary. Helper-level dormancy and ordinary regeneration tests pass. |
| Structural omission or double-counting across 140 units? | None found in the current record partition: 28 complex members + 129 singleton records + 4 exclusions = 161. All 140 units have inventories and artifact IDs are unique. Unique inventory slots do not prove distinct underlying physical artifacts; later evidence may show that one artifact satisfies slots in multiple units. |
| Are the 329 entries proposals? | Yes. Independently counted 109 required, 47 optional, 173 unknown; all 329 carry `proposed: true`. Exactly 137 units contain unknowns. Neither `required` nor absence of unknowns means human confirmation; a generated repository slot is not evidence of a repository. |
| Does the ontology retain genuine project structure? | Yes at conceptual level: `ep:Complex`/`ep:AuditUnit` are distinct from `ep:Project`/`ep:Work`; project parts, record membership, document containment, and inventory slots are separate. Implementation should retain those distinctions and address the instruction drift in R4. |

## Verification and limits

- Existing verifier: all seven checks passed against the current files.
- Registry tests: **4 runs, 13 assertions, 0 failures/errors** using `bin/rake test TEST=test/lib/zotero_singleton_ids_test.rb`.
- Repeated-video test: **1 run, 2 assertions, 0 failures/errors** using `bin/rake test TEST=test/lib/zotero_cluster_inventory_test.rb`.
- Regeneration into temporary copies produced byte-identical YAML, Markdown, singleton registry, and ID map. All generator output paths, including `IDMAP`, were redirected before running; input sheet basename remained `review-sheet-v2`.
- Current frozen graph contains no undecided high-confidence welding edges. The older `welds?` fallback still permits them in other inputs, so the stronger confirmed-only invariant is not generally enforced by that function.
- The full Rails suite and StandardRB were not rerun for this review; the packet's reported full-suite result remains attributed to the implementation pass. An initial attempt to pass two filenames in one `TEST` value was rejected by the Rails task; both files were then run individually as reported above.

Reviewed fingerprints (SHA256):

```text
scripts/zotero_cluster.rb
48e8e6f02d44864186e90940d18d989190be6bd84985ed5c6f68df58a37e490f
scripts/zotero_singleton_ids.rb
03297fe06b6d5a40f3e036277f7e69c0e7f4fc73cc212f1e6bb76aa7ba515148
scripts/zotero_verify_decisions.rb
fa9d004601c94a20dc456769c0455ed05130996c56b18a665963a4fb1bfa008f
sources/emerging_philosophy/review-sheet-v2.yaml
f0b04bcf4250dcbf29724b27bb3e03df22b9302faff74fb69a07ab5cc0f767a5
sources/emerging_philosophy/decisions.jsonl
710dc5dbe088f4fb7ea84a9b4edd610c6bff78975706257ae489a0defc07a08a
sources/emerging_philosophy/singleton-ids.json
9a6642b00017e44079a18cc664ad6d3012618af67287ff821c854bcf59a25e58
```

The snapshot checksum independently matches the handoff's `57eb3a63fb299e9b122af000fa7b9923083aeff4ce0bfd305a948daa9d13c463`. Inventory confirmation and artifact retrieval remain outstanding.

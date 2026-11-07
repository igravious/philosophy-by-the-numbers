# Phase 2 inventory persistence and audit-unit identity remediation — for independent review

**Date:** 2026-10-25  
**Disposition:** R1–R5 addressed; ready for independent re-review  
**Authoritative changes:** implementation, generated views, tests, and documentation only. No inventory rulings were appended, no artifact requirements were changed, no retrieval was performed, and live Zotero was untouched.

## 1. Baseline and unchanged result

The frozen population remains 161 records partitioned into 11 complexes, 129 singletons, and four `non-project` exclusions. There are 140 audit units and 329 machine-proposed inventory entries: 109 `required`, 47 `optional`, and 173 `unknown` across 137 units. EP-001…EP-140 assignments and all 216 link rulings are unchanged.

After remediation, a structural comparison against the pre-remediation sheet confirmed that every audit unit retained its EP ID, members, grouping, edges, candidate links, and inventory. The singleton registry and ID map are byte-identical to their pre-remediation versions. All 329 entries remain `proposed: true`.

## 2. R1 — inventory decisions now persist

**Original finding:** regeneration discarded human inventory edits.

**Resolution:** `decisions.jsonl` is now authoritative for inventory as well as link rulings. It accepts append-only, last-wins records of this form:

```json
{"type":"inventory","id":"EP-028/software/repo","requirement":"optional","note":"reason"}
```

Allowed requirements are `required`, `optional`, and `not-expected`:

- `required` and `optional` retain the proposal basis, set `proposed: false`, and preserve optional `date`, `note`, and `evidence` metadata.
- `not-expected` removes the entry from the derived inventory.
- Empty confirmed inventories remain valid.
- Invalid records and rulings without a corresponding machine-proposed artifact fail generation.

The overlay is applied after machine proposal generation for every complex and singleton. Repeated regeneration preserves confirmations and removals. The generated instructions and document register now describe YAML and Markdown as derived views, not editing authorities.

**Regression evidence:** a synthetic `optional` confirmation and a `not-expected` removal survived two consecutive regenerations. These records existed only in a temporary test ledger; no equivalent ruling was made in the authoritative ledger.

## 3. R2 — singleton and anchored IDs are coordinated

**Original finding:** anchoring an existing singleton could allocate its registry EP ID to an anchored unit and fail with a collision.

**Resolution:**

- Singleton mappings load before anchored-unit IDs are assigned.
- Anchoring the same record preserves its existing singleton EP ID. The registry mapping is dormant while anchored and active again if the record returns to the unanchored singleton population.
- Existing anchored IDs are retained by exact member-set from the identity sheet.
- Genuinely new units receive IDs above the high-water mark across active, dormant, logged, and retired IDs.
- Duplicate current-unit IDs fail validation.
- Sheet, Markdown, registry, and ID map are written only after generation, cross-reference checks, inventory checks, and rendering all succeed.

The inherited active/retired EP-004/EP-020/EP-022 history remains unchanged. The documentation now distinguishes the rule that **no new allocation reuses an ID** from older pre-policy exceptions; no renumbering was performed.

**Regression evidence:** Sloman's `2PIU8IIM` transitioned singleton → anchored singleton → singleton while retaining EP-028. Both states passed generation and standalone verification. A malformed-registry failure left all four pre-existing outputs byte-identical.

## 4. R3 — verification now checks meaning, not only counts

**Original finding:** forged EP targets and unauthorized inventory changes passed all seven checks.

**Resolution:** check 7 now validates:

- assigned item keys against the frozen snapshot's exact top-level population;
- every anchored and singleton `to_project` target against the actual item-key → audit-unit-ID map;
- inventory ID syntax, requirement, boolean `proposed`, and string basis;
- global EP and artifact-ID uniqueness;
- inventory ledger confirmations and removals;
- registry consistency and legitimate same-record anchor transitions.

Optional check 8 is enabled with `ZOTERO_PRESERVATION_BASELINE=/path/to/sheet.yaml`. It compares every baseline audit unit's inventory and candidate links, applies ledger rulings per artifact so one ruling cannot mask unrelated drift, and retains existing EP targets. Empty inventories are structurally valid but fail preservation comparison when the change is unauthorized.

**Regression evidence:** a forged `EP-999` target and a string-valued `proposed` field failed verification. An empty inventory passed ordinary structural verification but failed preservation comparison against its nonempty baseline. An unknown population key failed verification. Authorized inventory changes passed preservation comparison; an additional unauthorized artifact in the same unit failed it.

## 5. R4 — grouping vocabulary no longer decides endeavour identity

The generated instructions now say that:

- `describes` leaves records in separate audit units whether or not they concern the same genuine endeavour;
- `siblings` records co-container/co-commentary context without deciding endeavour identity;
- `non-project` is the retained audit-population exclusion token, not an intellectual classification;
- the append-only ledger is authoritative and YAML/Markdown are derived views.

Both generated views were regenerated from these instructions.

## 6. R5 — EP-1000 round-trips correctly

Registry validation and high-water parsing now accept three or more digits. Allocation retains `%03d` formatting as a minimum width, so EP-999 is followed by EP-1000. Assignment matching already accepted variable-width IDs.

**Regression evidence:** a temporary registry allocated EP-1000, wrote it, and reloaded it successfully.

## 7. Verification summary

- Remediation integration tests: **6 runs, 32 assertions, 0 failures, 0 errors**.
- Singleton registry tests including EP-1000: **5 runs, 15 assertions, 0 failures, 0 errors**.
- Repeated-video test: **1 run, 2 assertions, 0 failures, 0 errors**.
- Current-sheet verifier: checks 1–7 pass.
- Preservation-baseline verifier: checks 1–8 pass.
- All 140 EP assignments, memberships, links, and 329 inventories preserved.
- YAML, Markdown, singleton registry, and ID map are byte-deterministic across regeneration.
- Full Rails suite: **646 runs, 1,759 assertions, 0 failures, 0 errors, 3 skips**.
- StandardRB passed for the registry module and all new/focused test files. The legacy clustering scripts retain their pre-existing style-offense baseline.

## 8. Reviewed fingerprints

```text
759be7869b840a6bf4e532783db74765ad5f3b7099f4ab3b8ef05dd1732fdd30  scripts/zotero_cluster.rb
a06707a0b7d5c8878dd79485e78e4e19f4c36bc07507fcc56b07e1192477a0e7  scripts/zotero_singleton_ids.rb
658cffcdd0070cdaa615b95ec726e75bcabc3b92941c53cbf2d75e6bb157a12b  scripts/zotero_verify_decisions.rb
cf19783850efe054e1d725033ad80d8f22bc2aa3cd5b5cd88c3cd61520968cfc  sources/emerging_philosophy/review-sheet-v2.yaml
710dc5dbe088f4fb7ea84a9b4edd610c6bff78975706257ae489a0defc07a08a  sources/emerging_philosophy/decisions.jsonl
9a6642b00017e44079a18cc664ad6d3012618af67287ff821c854bcf59a25e58  sources/emerging_philosophy/singleton-ids.json
c09a24c2908e16292765172580b233948524a080e2fe566be6c32496e383368b  sources/emerging_philosophy/regen-idmap.json
c643147722445b9a2ad88101bbec185988ef453d76178e4f1c856c74d0abad26  test/lib/zotero_phase2_remediation_test.rb
```

## 9. Questions for the next independent reviewer

1. Can any inventory confirmation, removal, correction, or stale-ruling path still bypass the ledger or lose information on regeneration?
2. Can singleton ↔ anchored ↔ complex transitions produce a duplicate, remapping, or unlogged retirement not covered by the new lifecycle test?
3. Can a generation or rendering failure still mutate any of the four outputs before validation completes?
4. Do target, population, and inventory checks cover the remaining meaningful corruption paths without forbidding valid empty inventories?
5. Does the documentation consistently distinguish derived sheets from the ledger authority and avoid new claims that erase inherited ID-history exceptions?

Please reproduce any concern against temporary copies and report severity, evidence, and suggested correction. The next functional step after review is evidence-backed resolution of the 173 `unknown` inventory proposals, not artifact retrieval.

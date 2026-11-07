# Phase 2 inventory persistence and audit-unit identity — independent re-review

**Date:** 2026-10-26  
**Reviewed packet:** [remediation handoff](phase-2-inventory-persistence-and-audit-unit-identity-remediation-for-independent-review.md)  
**Previous assessment:** [2026-10-25 review](phase-2-expected-artifact-inventory-independent-review-2026-10-25.md)  
**Disposition (corrected 2026-10-26):** proceed with Phase 2's evidence-backed inventory review for the current 140 audit units. The confirmation/removal workflow passes its persistence tests. The findings below identify follow-up work; they are not prerequisites for reviewing the current inventories.

**Correction to the review's scope:** the original disposition treated completion of general identity-lifecycle machinery as a readiness requirement for Phase 2. That was an overreach. F1–F2 concern changes to grouping or proposal identity, which the current inventory review does not require. F3 concerns verifier gaps for manually corrupted views or invalid ledger entries; generation and comparison against the retained full-proposal baseline remain available for the supported inventory workflow. F4 concerns switching to a later baseline after removals, not retaining that original baseline. F5 concerns output-publication failure, and F6 concerns wording. Keep these findings available when their triggering operations become relevant, without making another remediation/re-review cycle a condition of starting Phase 2. The next work is to assess the 173 unknown proposals using evidence and bring genuine classification uncertainties to the user.

This review added only this document to the project. All synthetic rulings, corrupted sheets, permission changes, and regeneration experiments used temporary copies under `/tmp`. They are tests of machinery, not proposed scholarly groupings or inventory decisions. The authoritative ledger, registry, ID map, generated sheets, implementation, and live Zotero were not changed. No artifacts were retrieved.

## Findings

### F1 — High: merge/split history is lost, allowing new EP IDs to be reused

**Locations:** [generator](../../scripts/zotero_cluster.rb), lines 864–879 and 888–916; [audit plan](emerging-philosophy-audit-plan.md), lines 38–40.

Allocation preserves exact member sets from the identity sheet, but retirement/remapping still compares against the historical v1 `PREV_SHEET`. A newly formed complex absent from v1 can disappear without a retirement record. After its ID drops out of the current sheet and rewritten ID map, its high-water reservation is lost.

**Reproduction, with the default identity source following the temporary output sheet:**

1. Append a synthetic `same-project` ruling joining `2PIU8IIM` / `PTDUCCRS` (currently EP-028 / EP-029). Generation creates complex **EP-141**.
2. Append `unrelated` for that pair. Generation restores singleton IDs EP-028 / EP-029. **EP-141 has no retirement record.**
3. Append `same-project` for a different pair, `VD89ULRH` / `5HP9VZKP` (EP-030 / EP-031). Generation assigns **EP-141 again**, now to different records.

Generation and standalone checks 1–7 pass at all three stages. This is new reuse, unrelated to the acknowledged historical EP-004/020/022 exceptions. The first merge also contradicts the approved lowest-existing-ID merge rule, and the split restores old singleton IDs instead of issuing new fragment IDs.

**Suggested correction:** persist the identity and succession history of every audit unit independently of the current derived sheet and one-generation ID map. Apply the approved merge/split policy, record all predecessors/successors, and reserve every issued ID permanently. Add a multi-generation integration test for the exact cycle above. The current same-record anchoring test does not cover membership changes.

### F2 — High: stale inventory rulings have no append-only retirement path

**Locations:** [ledger loader](../../scripts/zotero_cluster.rb), lines 556–560; generator lines 1096–1097.

Every effective inventory ruling must match a current machine proposal, including `not-expected` rulings. This safely detects a stale ID, but the supported ledger vocabulary provides no way to supersede that ruling once a grouping or proposal change removes its artifact ID. Appending another supported requirement cannot remove the ID from the effective ruling map.

**Reproduction:** confirm `EP-028/software/repo` as `optional` in a temporary ledger and regenerate successfully. Apply the first synthetic merge from F1. Generation fails with:

```text
inventory rulings have no proposed artifact: EP-028/software/repo
```

Append a correction marking that old slot `not-expected`; generation fails with the same message. Adding a ruling for the successor slot would not clear the obsolete key either. Completing this legitimate lifecycle transition would currently require changing historical ledger lines, reverting the grouping, or changing the implementation.

**Suggested correction:** define an explicit append-only retirement/supersession operation for inventory decisions, tied to artifact/audit-unit succession. Preserve the historical ruling and its evidence while excluding a deliberately retired ruling from current-proposal validation. Continue rejecting unexplained stale IDs. Test confirmations and removals through merges, splits, and removal of a proposal.

### F3 — Medium: standalone verification still accepts unruled confirmations and nonexistent removals

**Locations:** [verifier](../../scripts/zotero_verify_decisions.rb), lines 62–82 and 365–380; contrast generator lines 556–560 and 1096–1097.

The verifier checks that effective confirmations appear, but does not require every `proposed: false` entry to have a matching confirmation. It also accepts a `not-expected` ruling merely because its ID is absent from the sheet; it does not establish that the slot exists among machine proposals. Its separate ledger loader omits the generator's inventory validation.

**Reproductions:**

- Change the first EP-028 inventory entry's `proposed` value from `true` to `false`, without any ledger ruling. Checks **1–7 pass**, presenting an unapproved entry as confirmed.
- Append `{"type":"inventory","id":"EP-999/paper/nonexistent","requirement":"not-expected"}` to a temporary ledger. Checks **1–8 pass** against the unchanged baseline, while generation rejects that same ledger because the artifact has no proposal.

**Suggested correction:** share ledger validation and proposal derivation between generation and verification. Require confirmed entries to correspond to effective ledger confirmations, and validate removal targets against proposals or explicit retirement history. Preserve support for empty inventories; emptiness alone is not the defect. Test each corruption independently. In the existing test at [test/lib/zotero_phase2_remediation_test.rb](../../test/lib/zotero_phase2_remediation_test.rb), lines 82–93, the string-valued `proposed` case retains the previously forged EP target, so its failing exit does not independently prove that field was checked.

### F4 — Medium: check 8 rejects an authorized restoration after a removal

**Location:** [verifier](../../scripts/zotero_verify_decisions.rb), lines 425–435.

Preservation expectations are constructed only from entries still present in the baseline. A valid latest ruling cannot restore a slot removed before that baseline was saved, because the comparison never visits that slot.

**Reproduction:** append `not-expected` for `EP-028/software/repo`, regenerate, and retain that valid sheet as the next preservation baseline. Append a later `optional` ruling for the same slot and regenerate. Generation and checks 1–7 pass; check 8 reports `unauthorized inventory change in EP-028` despite the explicit last-wins correction.

**Suggested correction:** distinguish the full proposal baseline from a derived reviewed-state baseline. Either support restoration by reconciling the complete proposal set and applicable decision history, or formally restrict check 8 to an identified immutable proposal baseline and reject unsupported baseline types clearly. Add removal → restoration and subsequent-baseline tests. The packet's pre-remediation baseline is not affected by this particular example; the defect appears when using a later valid baseline.

### F5 — Medium: publication failures can still leave mixed output generations

**Locations:** [generator](../../scripts/zotero_cluster.rb), lines 1104–1109; [operating handoff](phase1-phase2-handoff.md), line 65.

Validation and Markdown rendering now finish before writes, which resolves the original early-mutation problem. However, publishing the four files remains sequential. The handoff's broader assurance that a failed regeneration leaves no partial output changes is therefore too strong.

**Reproduction:** append a synthetic `optional` confirmation, make the temporary existing Markdown output read-only, and regenerate. Writing Markdown raises `Errno::EACCES` at line 1109. The YAML has already changed to contain the confirmation; Markdown remains at the earlier state. The process exits unsuccessfully.

**Suggested correction:** stage all outputs, then use a publication mechanism with rollback/recovery or a single generation-directory/pointer switch. If transactional publication is deferred, narrow the documentation to the protection actually implemented: generation, validation, and rendering failures before publication leave outputs unchanged; write failures may not. Merely checking writability in advance does not establish a transaction.

**Positive control:** forcing `render_markdown` to raise before publication left all four temporary outputs byte-identical. This review found no mutation before validation/rendering completed.

### F6 — Low: generated instructions still tell reviewers to edit derived fields

**Location:** [generated instructions](../../scripts/zotero_cluster.rb), lines 1135–1142 and 1157–1161.

The opening and closing authority statements correctly prohibit editing generated views, but the intervening instructions still say “The fields you fill in,” “Type ONE word after it,” and “correct a wrong one by retyping `containment: unrelated`.” These are instructions to edit the displayed fields and conflict with the ledger-only workflow.

**Suggested correction:** replace these passages with append-only ledger examples identifying the pair, channel, and ruling. The repaired `describes` wording should also say that the ruling *does not itself join* records; “the records remain separate audit units” is stronger than the plan's allowance for descriptive cross-references within a complex formed through other links.

## Status of the earlier findings

| Earlier finding | Re-review result |
|---|---|
| R1: inventory edits lost | Confirmation/removal persistence works through the ledger. Stale-ruling retirement remains unresolved (F2); verifier authority checks remain incomplete (F3). |
| R2: anchoring collision | The same-record singleton → anchored singleton → singleton test passes. General merge/split identity and permanent reservation remain broken (F1). Validation/rendering no longer mutate outputs early; publication failures need a narrower guarantee or recovery (F5). |
| R3: weak verification | Exact population comparison, forged EP-target rejection, and basic inventory structure checks are implemented. F3 and F4 identify remaining authorization and correction gaps. |
| R4: endeavour/grouping conflation | The original claims about different genuine endeavours and the exclusion token were corrected. Some review instructions remain inconsistent (F6). The register now names the ledger authority, and the deep-dive handoff points to the current derived views. |
| R5: EP-1000 reload | Fixed; the focused boundary test passes. |

The authority documentation is materially improved and explicitly preserves inherited ID-history exceptions. One provenance caveat remains: the generator also reads the identity sheet and prior ID map, although the register's generation-input description names only snapshot, ledger, and singleton registry. F1's durable identity solution should register that authority and make its preservation requirements explicit.

## Verification evidence and limits

- Remediation tests: **6 runs, 32 assertions, 0 failures/errors**.
- Singleton registry tests: **5 runs, 15 assertions, 0 failures/errors**.
- Repeated-video test: **1 run, 2 assertions, 0 failures/errors**.
- Combined focused result: **12 runs, 49 assertions, 0 failures/errors**. Each file was run using `bin/rake test TEST=...`.
- The authoritative current sheet passes standalone checks 1–7. An unchanged temporary copy passes checks 1–8 against a retained copy of that current sheet.
- Temporary regeneration reproduces all four current outputs byte-for-byte. The failure reproductions above do not imply corruption of those authoritative outputs.
- Current counts remain 140 audit units and 329 proposed entries; the source sheet matches the remediation packet's fingerprint. No human inventory rulings were added.
- The full Rails suite and StandardRB were not rerun. Their results in the handoff remain evidence from the implementation pass.
- The historical pre-remediation sheet was not supplied as a retained file in this packet. This review verifies present-input regeneration; it does not independently certify the reported structural comparison to that earlier sheet.

Reviewed SHA256 fingerprints match the remediation packet:

```text
759be7869b840a6bf4e532783db74765ad5f3b7099f4ab3b8ef05dd1732fdd30  scripts/zotero_cluster.rb
a06707a0b7d5c8878dd79485e78e4e19f4c36bc07507fcc56b07e1192477a0e7  scripts/zotero_singleton_ids.rb
658cffcdd0070cdaa615b95ec726e75bcabc3b92941c53cbf2d75e6bb157a12b  scripts/zotero_verify_decisions.rb
c643147722445b9a2ad88101bbec185988ef453d76178e4f1c856c74d0abad26  test/lib/zotero_phase2_remediation_test.rb
cf19783850efe054e1d725033ad80d8f22bc2aa3cd5b5cd88c3cd61520968cfc  sources/emerging_philosophy/review-sheet-v2.yaml
710dc5dbe088f4fb7ea84a9b4edd610c6bff78975706257ae489a0defc07a08a  sources/emerging_philosophy/decisions.jsonl
9a6642b00017e44079a18cc664ad6d3012618af67287ff821c854bcf59a25e58  sources/emerging_philosophy/singleton-ids.json
c09a24c2908e16292765172580b233948524a080e2fe566be6c32496e383368b  sources/emerging_philosophy/regen-idmap.json
```

Inventory requirements remain proposals. This review neither resolves the 173 unknowns nor authorizes artifact retrieval.

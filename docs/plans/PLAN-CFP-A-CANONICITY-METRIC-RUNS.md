# Plan CFP-A: Canonicity Metric Runs

**Status:** COMPLETE — genuine inputs restored and Phases 0–5 verified with corrected full-population publications on 2026-11-10.
**Series:** CFP-A; outside the numerical modernisation sequence.
**Pillar:** 1 — `philosophy-by-the-numbers`.
**Three-pillar programme:** [CFP planning and research-programme structure](../wip/dh2027-cfp-planning.md#research-programme-structure)
**Scope:** `philosophy-by-the-numbers`, including immutable input datasets, controlled canonicity experiments, replay, dependencies, retention, and publication.
**Starting run version:** `0.7.0` independently for each subject type.
**Compatibility rule:** Existing records, weights, snapshots, and current displayed measures remain unchanged unless explicitly published from a completed run.

| Phase | Status | Verification |
|---|---|---|
| 0 — Pure calculators | Complete | Characterization and calculator tests |
| 1 — Schemas and retention | Complete | Model, retention, and schema tests |
| 2 — Imports and capture | Complete | Atomic import and coherent capture tests |
| 3 — Calculate and replay | Complete | Controlled runs and exact replay |
| 4 — Publication and comparison | Complete | 1,137 tests, exact replay, real publication and rollback |
| 5 — Documentation and verification | Complete | 1,142 tests, genuine restoration, corrected publications |

## 1. Objective

Finish the canonicity architecture so that calculations are reproducible, controlled, and non-clobbering.

The architecture separates:

1. **Immutable input datasets:** coherent populations and primitive inputs captured once.
2. **Metric runs:** calculations over a dataset using a specified calculator and configuration.
3. **Publications:** explicit promotion of a complete result set to current display values.

Operations are distinct:

- **Calculate:** create a run from a dataset and configuration.
- **Recalculate:** create another run from the same dataset with an alternative configuration, enabling source omissions and weight perturbations without conflating input changes with configuration changes.
- **Replay:** verify an existing run's stored measures, population, normalisation, and ranks without writing anything.

The intended formula is retained. Work's duplicate genre application is treated as a defect, not a second formula.

### Identifier glossary

| Identifier | Example | Changes when |
|---|---|---|
| Calculator | `philosopher-v2` | The formula implementation or derivation rules change |
| Configuration | `2.1` | A new weight set is created |
| Run | `0.8.1` | Every calculation attempt, including a failed attempt |
| Payload schema | `1.0` | The primitive input-record shape changes |

Always prefix a version with its kind in prose: calculator `philosopher-v2`, configuration `2.1`, run `0.8.1`, or payload schema `1.0`. A bare `2.0` is ambiguous and should not be used.

## 2. Decisions

- No meaningful run names or manually maintained labels.
- Run identity comprises `subject_type`, `version`, `started_at`, and `completed_at`.
- Versions use `major.minor.patch` **independently for each subject type**, beginning with both Philosopher and Work at run `0.7.0`.
- Run, calculator, configuration, dataset, and publication identities are distinct.
- Existing algorithm versions and historical snapshots are not renumbered.
- Philosopher configuration `2.0` is historical-only: its source weights can total more than 1 and new calculations reject it before allocating a run version.
- The canonical Work formula applies genre exactly once.
- `linkcount` is available and time-varying but unused in the current formula.
- Failed runs retain evidence and consume version numbers within their subject sequence.
- JSON is stored as serialized text with a versioned payload schema.
- Partial runs may be used for experiments and replay but may not become the current global ranking.
- Publication requires complete coverage of the intended publication population.
- Publication history is append-only; the latest publication ID for each subject type identifies the current publication. No separate current-publication table exists.
- A completed Philosopher run is required before capturing any Work dataset; there is no legacy-author fallback.

## 3. Defect disposition

| ID | Original defect | Disposition |
|---|---|---|
| 1 | Work applied genre twice | Fixed in Phase 0; genre is applied once |
| 2 | Work read stale or nil live author measures | Fixed in Phases 0 and 2; frozen completed-run dependencies are mandatory |
| 3 | Calculation mixed live inputs, extrema, relationships, and writes | Fixed in Phases 0–3; capture, pure calculation, and run persistence are separate |
| 4 | Null primitive inputs were coerced or rejected | Fixed in Phase 1; null and numeric zero remain distinct |
| 5 | Work could calculate non-finite output before guarding denominators | Fixed in Phase 0; both outputs are guarded and checked |
| 6 | Capture lacked a coherent population contract | Fixed in Phase 2; selected IDs must be contained in normalisation IDs |
| 7 | Entity errors could still report completion | Fixed in Phases 2 and 3; captures and runs fail atomically |
| 8 | Latest-result scopes included unfinished data | Fixed in Phase 3; completed status is required positively |
| 9 | Snapshots read live weights | Fixed in Phases 1 and 3; run-linked snapshots read frozen weights |
| 10 | Ranking tasks rewrote snapshots and display ranks | Fixed in Phase 4; legacy entry points only delegate to explicit publication |
| 11 | Flag imports were hidden in Work calculation | Fixed in Phase 2; imports are separate atomic source events |
| 12 | Provenance was placeholder-only and role exclusions implicit | Fixed in Phase 2; provenance and calculator derivation rules are frozen descriptively |
| 13 | Danker import wrote invalid snapshots without updating inputs | Fixed in Phase 2; typed source events and current inputs update atomically |
| 14 | Publication edge cases were undefined | Fixed in Phase 4; eligibility, locking, rollback, and republishing are specified and tested |
| 15 | Entity deletion could erase evidence | Fixed in Phase 1; retention and reassignment safeguards are enforced |
| 16 | Version identities could not support controlled experiments | Fixed in Phases 1 and 3; calculator, configuration, run, and schema identities are distinct |
| 17 | Display values bypassed latest-snapshot helpers | Fixed in Phase 4; publication writes `shadows.measure` and `measure_pos` directly |

## 4. Phase 0: pure calculators and characterization

Complete this phase before creating run infrastructure.

### Calculator identity

Extract pure calculator strategies:

- `Canonicity::Philosopher::V2`
- `Canonicity::Work::V2`

Each calculator is a pure function:

```text
primitive entity payload + frozen configuration + normalisation context + dependency inputs
  → measure and explanatory derived context
```

Calculators perform no database queries or writes. Strategies remain available for replay after newer calculator versions are introduced.

### Numerical rules and output meanings

- A normalized measure is a product `S₀ × S₁ × S₂ × … × Sₙ`, with every factor in `[0, 1]`, so the product is also in `[0, 1]`.
- Scalar signals are normalized using extrema fixed for the run. Compound signals are bitsets whose weights, including any bonus, sum to 1.
- Both V2 calculators use `Canonicity::Normalization.product` to reject negative, non-finite, or greater-than-1 components with `Canonicity::NormalizationError` rather than returning an invalid measure.
- Philosopher's active bitset weights are stored directly at two decimal places and sum to exactly 1.000000; `all_bonus` is 0.08.
- Guard zero denominators before calculating either normalized or displayed measures.
- Require finite measures before snapshot persistence or run completion.
- Apply genre exactly once to Work.
- `metric_snapshots.measure` stores the display-scaled value:
  - Philosopher: normalized measure × `10_000_000`.
  - Work: normalized measure × `1_000_000`.
- The normalized value belongs in explanatory `calculation_context`, not in `measure`.
- Do not apply another multiplier during publication.

### Worked Philosopher example

For one philosopher, suppose the frozen inputs are `mention = 100`, `danker = 1.0`, Routledge coverage, and Stanford coverage. The normalisation maxima are `max_mention = 200` and `max_rank = 2.0`. Under configuration `2.1`, the source contributions are Routledge `0.17`, Stanford `0.10`, and `all_bonus = 0.08`, giving source coverage `0.35`.

```text
mention factor  = 100 / 200 = 0.5
Danker factor   = 1.0 / 2.0 = 0.5
source coverage = 0.17 + 0.10 + 0.08 = 0.35
normalized      = 0.5 × 0.5 × 0.35 = 0.0875
display measure = 0.0875 × 10,000,000 = 875,000
```

Publication copies `875,000`; it does not scale the value again.

### Characterization tests

Pin the following behaviours so extraction does not change them accidentally:

- Philosopher role suppression occurs when more than one configured capacity matches.
- Maxima are calculated over all philosophers, including those whose mention is suppressed by the role rule.
- Work `all_bonus` excludes PhilPapers-only coverage.
- Work author adjustment is computed before a zero `sourcey` becomes `0.1`.
- Philosopher and Work use different missing-mention defaults.
- Philosopher and Work use different Danker minimum-selection rules.
- Work's `where.not(danker: 0.0)` excludes both zero and NULL in SQL.
- `nil` and `0.0` remain distinct input values.
- The current author-adjustment failure for a `nil` author measure is documented rather than silently preserved.

Also pin the intended single-genre Work formula and the zero-denominator guard.

## 5. Immutable input datasets

### 5.1 `metric_input_datasets`

Create dataset records with:

| Field | Purpose |
|---|---|
| `id` | Dataset identity |
| `subject_type` | `Philosopher` or `Work` |
| `status` | `capturing`, `ready`, or `invalid` |
| `schema_version` | Version of the primitive input-payload contract |
| `selected_entity_ids` | Exact entities intended for calculation |
| `normalization_entity_ids` | Population used for maxima/minima, which may differ from selected entities |
| `normalization_context` | Maxima, minima, and fallback values |
| `source_provenance` | Source versions, import IDs, artifact checksums, and dependency provenance |
| `input_run_id` | Completed Philosopher run supplying author inputs for a Work dataset |
| `population_checksum` | Stable checksum of canonical selected and normalisation ID sets |
| `capture_completed_at` | Time the coherent dataset was materialized |
| `failure_reason` | Optional capture failure information |
| Rails timestamps | Record metadata |

Only a `ready` dataset can be used for calculation. It is immutable after capture completion.

### 5.2 `metric_input_records`

Capture one input record for every entity in the **union** of selected and normalisation IDs, with flags indicating membership in each set.

Each record contains:

- `metric_input_dataset_id`.
- `shadow_id`.
- `shadow_type`.
- `entity_id` and a display label, so evidence remains intelligible if the live entity is deleted.
- `selected`, indicating whether a run snapshot is expected.
- `normalization`, indicating use in extrema calculation.
- `input_payload`, serialized JSON text.

Add a unique index on `[metric_input_dataset_id, shadow_id]`.

Selected IDs must be a subset of normalisation IDs; capture rejects any selected entity outside the normalisation population. Normalisation may be a strict superset of selection. This guarantees that a selected entity's raw scalar cannot exceed the maximum used as its denominator. For example, scoring 50 philosophers while normalising against all 13,329 remains valid, while scoring Plato against only minor figures is rejected rather than producing a mention factor above 1.

Extrema are calculated **only from normalisation IDs**, including when that population is a superset of the selected IDs. Replay follows the same rule. Capturing the union permits normalisation to be recomputed rather than merely comparing stored maxima with themselves.

### 5.3 Primitive payload contract

The versioned payload includes every primitive input consumed by the calculator:

- Raw `mention`, preserving integer/null distinctions.
- Raw `danker`, preserving null versus numeric zero.
- `linkcount` where available.
- Reference-work and PhilPapers flags with their original types.
- Capacity IDs relevant to role exclusions.
- Expression/author IDs and the author snapshot IDs/measures used.
- Raw genre and other work attributes.
- Any other primitive needed by the selected calculator.

Replay and recalculation read exclusively from this payload and the run configuration.

Derived values such as `sourcey`, author adjustment, and genre multiplier are **explanatory outputs**, not authoritative inputs. They are recomputed from primitives and stored only as explanatory calculation context.

## 6. Coherent capture and completeness

Dataset capture must:

1. Select and freeze selected entity IDs and normalisation IDs explicitly.
2. Materialize all primitive records and source provenance in a consistent SQLite read transaction.
3. Use a cross-process file lock at `tmp/metric_capture.lock` for imports, captures, runs, and publications. An in-memory mutex is insufficient because these operations run in separate Rake processes.
4. On acquiring that lock at the start of any operation, reconcile leftover `capturing` datasets as `invalid` and leftover `running` runs as `failed`, both with `failure_reason = interrupted`, before starting new work.
5. Validate exactly one input record per selected/normalisation union entity.
6. Validate that provenance describes the same imported artifacts as the captured values.
7. Mark the dataset `ready` only after all checks pass.

Per-entity errors invalidate capture or run completion; they are never rescued into apparent success.

A metric run completes only when:

- Every selected entity has exactly one snapshot.
- Every measure is finite.
- Dense ranks have been assigned and verified.
- No input or snapshot records are missing.

Add a unique index on `[metric_run_id, shadow_id]`.

A `ready` dataset can be reused after interruption; an incomplete dataset capture must be explicitly recaptured. Failed run versions are consumed.

## 7. Metric runs and controlled recalculation

### 7.1 `metric_runs`

Create runs with:

| Field | Purpose |
|---|---|
| `id` | Run identity |
| `version` | Display version such as `0.7.0`; unique within `subject_type` |
| `major`, `minor`, `patch` | Integer components for numeric ordering within `subject_type` |
| `subject_type` | `Philosopher` or `Work` |
| `metric_input_dataset_id` | Frozen dataset used for calculation |
| `parent_run_id` | Optional experimental ancestor |
| `calculator_identity` | Stable implementation identity, e.g. `philosopher-v2` |
| `configuration_version` | Configuration version, currently `2.1` or `2.0-work` |
| `configuration_fingerprint` | Stable checksum of canonical weights and signal configuration |
| `status` | `running`, `completed`, or `failed` |
| `started_at` | Run kick-off timestamp |
| `completed_at` | Successful completion timestamp |
| `weights_config` | Exact frozen weights as serialized JSON text |
| `signal_config` | Frozen descriptive record of calculator source lists and role exclusions |
| `source_provenance` | Provenance specific to this calculation |
| `failure_reason` | Optional failure information |
| Rails timestamps | Record metadata |

Indexes include unique `[subject_type, version]`, unique `[subject_type, major, minor, patch]`, dataset, parent run, calculator identity, configuration fingerprint, status, and timestamps.

`MetricSnapshot#weights_config` returns the run configuration when present; live-weight lookup exists only for legacy snapshots.

### 7.2 Calculate and recalculate

**Calculate** creates a run from a ready dataset and a selected configuration version.

**Recalculate** creates a run from the same ready dataset with an explicit alternative configuration version. Set `parent_run_id` to the experiment's ancestor where applicable.

This is the controlled experiment:

```text
same selected entities + same primitive inputs + same author dependencies
  + alternative weights or reference-source selection
  → attributable output differences
```

No live input refresh occurs during recalculation.

Configuration edits create a new configuration version. A reference-source omission requires a complete new weight set in `canonicity_weights`, with that source inactive or assigned zero weight. Rows identified by `(algorithm_version, source_name)` are never updated in place after being used by a run. Derived source terms are recomputed from the resulting weights, so conditional bonuses still follow the ordinary calculator rules.

`signal_config` is a frozen descriptive record used in the configuration fingerprint; it is not an executable calculator argument. Role exclusions and calculator source lists belong to calculator identity. Changing those derivation rules requires a new calculator and a major run-version bump. Disabling scalar mention or Danker signals independently is outside the current experiment model.

### 7.3 Snapshots and retention

Add to `metric_snapshots`:

- `metric_run_id`, nullable for history.
- `metric_input_record_id`, linking the primitive input used.
- `calculation_context`, serialized JSON text for explanatory derived values.

Relax `danker_score`, `linkcount`, and `mention_count` to nullable columns so run-linked snapshots can preserve the same null/zero distinctions as the payload. The payload remains authoritative for replay.

Remove `dependent: :destroy` from snapshot associations.

Retention rules:

- Completed runs cannot be updated, deleted, reassigned, or given additional snapshots.
- Entity deletion does not cascade into datasets or snapshots.
- Raw entity identity and labels remain in the frozen payload.
- Input records and snapshots cannot be moved to another run or dataset.

Application-level enforcement is in scope. Inventory and test every create, update, reassignment, deletion, and cascade path; no database trigger is required in this phase.

## 8. Replay

`replay(version, subject_type)` and `bin/rake metric:replay[Philosopher,0.7.0]`:

- Require a completed run of the stated subject type.
- Use only its calculator identity, frozen configuration, dataset payload, and dependency inputs.
- Perform no source refresh and no writes.
- Recompute every selected entity, all finite measures, and dense ranks.
- Recompute extrema from all selected/normalisation union records and verify normalisation context.
- Report added, missing, and mismatched entities and ranks.

For replay on the same runtime, numeric measures must match exactly and serialized output must use full precision with stable key ordering. Display rounding is not part of equality checking.

Ordinary latest-result lookups positively require completed runs; they do not merely exclude failed runs.

## 9. Work author dependencies

A Work dataset must not read live `Philosopher#measure`.

At capture:

- A completed Philosopher run is mandatory; there is no `legacy_shadows` fallback.
- Default to the latest completed Philosopher run, or accept an explicit `input_run_id`.
- Validate that the dependency is completed and has `subject_type = Philosopher`.
- Read linked-author measures from that run's snapshots.
- Store `input_run_id`, linked-author snapshot IDs, and measures in the dataset's provenance and primitive payload.
- If a linked philosopher is absent from the selected dependency, fail capture with an actionable list. Missing is not treated as zero.

Publication does not determine the default dependency: future Work datasets use the latest completed Philosopher run unless an explicit dependency is supplied. Existing datasets and runs retain their original dependencies.

## 10. Configuration identity and signal registry

Distinguish:

- **Calculator identity:** the pure implementation used for replay.
- **Configuration version:** the named configuration family, currently `2.1` and `2.0-work`. Original `2.0` is preserved for historical replay only.
- **Configuration fingerprint:** stable checksum of canonical weights and descriptive calculator signal configuration.
- **Run version:** the execution label within a subject sequence.

A new weight set using V2 therefore has a different configuration fingerprint without implying a new calculator.

Create `canonicity_signals` in Phase 1 as descriptive metadata with:

- Algorithm/configuration version.
- Name and description.
- Source.
- `subject_to_change`.
- `used_in_formula`.
- `active`.

This table documents which inputs change over time. The registry and `signal_config` are descriptive evidence; executable derivation rules belong to the identified calculator, while weights belong to the identified configuration.

Create an empty fixture file for this and every other new table so Rails cannot leak development rows into tests.

## 11. Subject-scoped run version allocation

Each subject type has an independent semantic sequence. Compare components numerically, never lexicographically.

For each new run:

1. Find the previous completed run of the same subject type.
2. Determine the bump:
   - **Major:** calculator identity changes.
   - **Minor:** configuration version, weights, signals, or source semantics changes.
   - **Patch:** otherwise, including new Danker or mention data with unchanged semantics.
3. Apply the bump to the highest semantic version within that subject type, including failed runs.
4. Persist components and display string transactionally, retrying unique-index collisions.

Examples:

- First Philosopher run: `0.7.0`.
- First Work run: `0.7.0`.
- A Philosopher recalculation with changed weights: next Philosopher minor version.
- A new Danker drop with unchanged semantics: next patch version within the affected subject.
- Repeated failed attempts after the same configuration change intentionally receive successive candidate versions while the completed baseline remains unchanged.

These are execution labels, not stability claims or substitutes for configuration fingerprints and dependency provenance.

## 12. Danker and source-event integration

Introduce `source_events` for input changes rather than `MetricSnapshot` records.

Each import:

- Has an import identity and source artifact identity/checksum.
- Records old and new values with their original types, including null-to-zero transitions.
- Records source and retry provenance.
- Writes `nil` for an entity missing from the Danker file rather than coercing it to `0.0`.

Validate the entire input file and artifact identity **before** opening the import transaction. Then commit every input change and every source event for that import in **one transaction**. Any validation failure or interruption leaves the previous inputs intact; no separate partial-import recovery system is introduced. Later dataset capture reads the committed values and their import provenance.

Work's ranked-minimum query excludes both `0.0` and NULL. Therefore preserving missing-file entities as `nil` does not, by itself, change that population. Characterization tests must demonstrate this before the import change. Any actual semantic change requires a minor bump; otherwise a new data drop remains a patch bump.

This repairs the invalid Danker snapshot attributes while ensuring imported data can affect later calculations.

Historical provenance that cannot be established is recorded as `unknown`; new events do not pretend to reconstruct earlier imports.

Encyclopedia-flag updating moves out of `shadow:work:measure` into the same input-event mechanism.

## 13. Publication

### 13.1 Eligibility

The default publication population is **all records of the subject type**, matching the current calculators. A run is publishable only when:

- It is completed.
- Its selected IDs and snapshot coverage exactly match that population at publication time.
- Its normalisation IDs equal its selected IDs, and both sets equal all current records of that subject type.
- Every measure is finite and dense ranks are verified.

Partial experimental runs are not publishable. New or missing entities make a previously complete run stale for publication until a fresh complete run is produced. If the population is unchanged, an older run remains publishable after input refreshes. There is no partial overlay and no mixing of ranks from different populations.

### 13.2 Append-only publication records

Create `publications` with `metric_run_id`, `subject_type`, and `created_at`. Publication does not mutate the run or snapshots.

The latest publication ID for each subject type identifies the current publication. Republishing an older run appends another record and makes it current, preserving full history.

### 13.3 Atomic publication

For each subject type, acquire the cross-process lock and perform one transaction that:

1. Revalidates eligibility.
2. Updates all current `shadows.measure` and `measure_pos` values from the run.
3. Appends the publication record.

An interruption rolls back both current-value changes and the publication record. Concurrent publications are serialized by the same lock.

The actual publication target is the `shadows` columns, not the currently uncalled `latest_measures_for_all_*` helpers. Those helpers may be retained for compatibility but are not a substitute for publishing current values.

A Work run may depend on a Philosopher run other than the currently published one. Publication compares `metric_input_datasets.input_run_id` with the current Philosopher publication and shows a warning on `/canonicity` when they differ, including when no Philosopher run is published. This does not block Work publication: blocking would impose an unnecessary publication order and make republishing an older Philosopher run invalidate Work evidence.

`shadow:work:order2` and `shadow:philosopher:new_order` require an explicit run version and delegate only to the publication service. They no longer rank live values independently or mutate snapshots.

## 14. Comparison and incremental UI

Rake interface:

```bash
bin/rake shadow:philosopher:metric
bin/rake shadow:work:measure
bin/rake metric:runs
bin/rake metric:show[Philosopher,0.7.0]
bin/rake metric:recalculate[Philosopher,0.7.0,2.1]
bin/rake metric:replay[Philosopher,0.7.0]
bin/rake metric:compare[Philosopher,0.7.0,0.7.1]
bin/rake metric:publish[Philosopher,0.7.1]
```

Build the `/canonicity` UI incrementally from the start of implementation. Visibility and UAT must not wait until Phase 4. Each phase exposes its new state as soon as the backend lands, allowing review and course correction before subsequent phases.

- **Available foundation:** read-only calculator identities and algorithm configuration, including active sources, inactive legacy sources, and `NULL` weights.
- **Phase 1:** signal definitions and the newly available dataset, run, source-event, and publication schema state.
- **Phase 2:** dataset status, population, provenance, dependency details, capture failures, and import events.
- **Phase 3:** run versions, calculator and configuration identities, timestamps, status, recalculation differences, and replay matches/mismatches.
- **Phase 4:** publication eligibility, history, comparison, and controlled publication actions.

This is not the general UI overhaul from Plan 6.

Comparison is allowed only between runs of the same subject type. Report:

- Measure and rank movement.
- Added and missing entities.
- Population and normalisation differences.
- Calculator and configuration differences.

## 15. Implementation sequence

### Phase 0: Calculators and characterization

**Status:** COMPLETE (2026-11-06). Pure V2 calculators and model delegation implemented; duplicate-genre and zero-denominator defects repaired. Focused calculator/model tests and the full Rails suite pass (717 runs, 2,098 assertions, 0 failures, 0 errors, 3 skips); new calculator/test files pass StandardRB.

Complete §4. Do not create source-event or run tables here.

### Phase 1: Dataset, signal, source-event, and publication schemas

**Status:** COMPLETE (2026-11-06). Six-table schema and models, nullable snapshot inputs, frozen run configuration, retention safeguards, populated signal registry, empty fixtures, and incremental dashboard state implemented. Full Rails suite passes (761 runs, 2,218 assertions, 0 failures, 0 errors, 3 skips); all new Phase 1 files pass StandardRB.

Write tests first for payload null/type preservation, dataset coverage, source-event imports, publication history, and retention. Create the schema for immutable datasets, input records, `canonicity_signals`, source events, runs, and publications. Add an empty fixture file for every new table and relax the three snapshot input columns to nullable. Extend the existing read-only `/canonicity` dashboard with the new schema and signal state.

### Phase 2: Import integration and coherent capture

**Status:** COMPLETE (2026-11-06). Atomic Danker/reference-flag imports, cross-process locking and reconciliation, coherent dataset capture with dependency validation, unlinked-snapshot removal, and dataset/import dashboard evidence implemented. Three small real Philosopher datasets are ready for UAT. The hardened full Rails suite passes (805 runs, 2,603 assertions, 0 failures, 0 errors, 0 skips); Phase 2 service and test files pass StandardRB.

**Review hardening:** Danker validation streams and checksums the artifact in one pass while retaining only subject scores. Capture reads IDs and provenance inside its transaction, validates captured values against the latest relevant source events, records early failures, aggregates missing-author lists, and preserves original exceptions. Duplicate Work rows are rejected, the operation lock is re-entrant, and strict adapters convert database-round-tripped payloads to calculator inputs. Read-only validation of the real 724 MB Danker CSV completed successfully: 25,470,322 rows validated, 12,940 subject scores retained, approximately 130 MB peak RSS, 10:07 elapsed.

Implement atomic Danker and flag imports, then coherent dataset capture with the cross-process lock and startup reconciliation. Stop the existing model methods from creating unlinked snapshots; wrapping only rake tasks is insufficient. Expose capture status, populations, provenance, dependencies, failures, and import events in the dashboard for UAT.

The measure tasks use controlled capture and calculation. The legacy ranking tasks retained direct display-value writes until Phase 4, where they became explicit publication wrappers.

### Phase 3: Calculate, recalculate, and replay

**Status:** COMPLETE (2026-11-06). Controlled calculation and recalculation over ready datasets, subject-scoped semantic versions, frozen configuration fingerprints, dense ranking, failure recovery, and exact read-only replay implemented. Philosopher runs 0.7.0 and 0.7.1 were created from real dataset 3 and both replay exactly. Run/snapshot inspection and replay are available in the dashboard. Full Rails suite passes (876 runs, 2,929 assertions, 0 failures, 0 errors, 0 skips); Phase 3 service and test files pass StandardRB.

**Review hardening:** calculation, completion validation, and replay now share `Canonicity::DenseRank`, so tied measures receive the same rank and the next distinct measure increments once. Original `2.0` weights are restored for compatibility; normalized two-decimal weights and their signal registry now belong to `2.1`, the Philosopher default. Cross-subject configurations are rejected before run creation. Real run 0.8.0 uses `2.1` and all three real runs replay exactly. Final full suite: 1087 runs, 4076 assertions, 0 failures, 0 errors, 0 skips.

Implement controlled calculation over ready datasets, completion validation, dense ranking, recovery, and read-only replay. Test repeated recalculation from one dataset and exact replay of measures, population, normalisation, and ranks. Expose runs, controlled differences, and replay results in the dashboard for UAT.

### Phase 4: Publication and UI completion

**Status:** COMPLETE (2026-11-10). Publication eligibility, atomic updates, rollback, republishing, comparison, rake tasks, legacy wrappers, and dashboard controls were implemented test-first. Full Rails suite: 1,137 runs, 4,409 assertions, 0 failures, 0 errors, 0 skips. New Phase 4 service and test files pass StandardRB.

- [x] Capture full Philosopher dataset 4: 13,329 selected and normalisation IDs.
- [x] Complete and exactly replay Philosopher run `0.8.1` under configuration `2.1`: 13,329 snapshots.
- [x] Capture full Work dataset 5 against Philosopher run `0.8.1`: 3,654 selected and normalisation IDs.
- [x] Complete and exactly replay Work run `0.7.0` under configuration `2.0-work`: 3,654 snapshots.
- [x] Reject selected IDs outside normalisation during capture.
- [x] Reject Philosopher configurations whose source weights can exceed 1 before run allocation; configuration `2.0` is historical-only.
- [x] Implement eligibility, atomic publication, republishing, interruption rollback, and comparison.
- [x] Preserve exact floating-point measures through bound ActiveRecord updates; regression-tested against two real SQLite edge values.
- [x] Publish Philosopher run `0.8.1` and Work run `0.7.0`, verify every current value and rank exactly, verify interruption rollback, and append republication history. Current publication IDs are 4 and 3 respectively.
- [x] Restrict `shadow:work:order2` and `shadow:philosopher:new_order` to explicit publication.
- [x] Complete the dashboard with eligibility, history, comparison, dependency warnings, and publication actions.
- [x] Print dependency warnings from `metric:publish` and the Work compatibility wrapper.
- [x] Paginate dashboard snapshots at 100 rows and batch index population/snapshot eligibility queries.
- [x] Reject Work source weights above 1 before run allocation, excluding genre multipliers from that sum.

### Phase 5: Documentation and verification

**Status:** COMPLETE (2026-11-10). All operating guides, controlled-configuration scenarios, genuine Danker restoration, corrected publications, zero-score semantics, dependency hardening, and final verification are complete.

Update:

- [x] `docs/CANONICITY_ALGORITHM.md`
- [x] `app/ERD.md`
- [x] `docs/RAKE_TASKS.md`
- [x] `docs/DATA_REFRESH_GUIDE.md`
- [x] `docs/TESTING_STRATEGY.md`
- [x] `.ai-instructions.md` if project guidance or status changes

Run:

```bash
bin/rake test
bin/standardrb
```

Current result: the full Rails suite passes with 1,142 runs and 4,438 assertions, 0 failures, 0 errors, and 0 skips. The repository-wide StandardRB command still reports 67,169 offences across the legacy codebase; all new and directly changed service, controller, task, and test files pass their focused StandardRB check. Both corrected runs replay exactly, current display values have zero mismatches, and the live dashboard shows Philosopher `0.10.0` and Work `0.7.2` as current.

End-to-end evidence uses small real datasets for controlled experiments and full populations for dependency and publication checks:

1. On a small dataset, capture a Philosopher dataset and complete run `0.7.0`.
2. Recalculate from the same dataset with a new configuration version and confirm that only configuration-dependent outputs differ.
3. Replay both small runs and confirm exact measures, population, normalisation, and ranks.
4. Capture and run the full Philosopher population, then capture the full Work population against that completed dependency and complete Work run `0.7.0`; replay both exactly.
5. Attempt to publish a partial run and confirm rejection.
6. Create a new configuration version rather than editing immutable configuration.
7. Import new Danker data, including a missing entity, and verify atomic current-value/event updates and unchanged Work minimum-rank behaviour.
8. Confirm that earlier datasets, runs, and current display values remain unchanged before publication.
9. Publish a complete full-population run, interrupt a second publication attempt, and verify rollback.
10. Republish the first run and verify append-only history and latest-ID current selection.

Phase 5 real-data results:

- Configuration `2.2` was created as a complete copy of `2.1` with only Routledge changed from `0.17` to `0.16`; `2.1` was verified unchanged. Run `0.9.0` reused dataset 3, replayed exactly, and differed from `0.8.0` only through configuration-dependent output.
- Synthetic sorted Danker artifacts changed one positive score and omitted one different positive score for each subject. Imports committed 13,329 Philosopher and 3,654 Work source events atomically, preserved old/new types, and stored the omitted values as `nil`. Earlier runs and displayed values remained unchanged, but the synthetic values entered the live development inputs; this was an unsafe scenario design, not a successful no-side-effects check.
- **PUBLICATION QUARANTINE:** Work dataset 6 and immutable Work run `0.7.1` contain those synthetic inputs and must never be published. Eligibility does not inspect provenance, so this run remains technically eligible; the explicit-version publication requirement and this permanent note are the safeguards. Any corrected Work publication must use a new dataset and run.
- Real interruption rollback and append-only republication passed, as did the live dashboard HTTP check.
- Default Work dependency was repaired test-first to select the latest completed Philosopher run whose selected IDs equal the current full population. The regression uses a newer partial run to prove it cannot be selected accidentally.
- The genuine 2019 Danker artifact was re-imported for both subjects through the atomic import service. All four synthetic changes were reversed, all 277 philosopher and 626 Work coerced zeros became `nil`, and no `danker = 0.0` remains. Restoration committed another complete set of typed source events.
- Philosopher dataset 7 produced run `0.10.0`; plain Work capture selected that full-population dependency and dataset 8 produced Work run `0.7.2`. Both replay exactly. Philosopher `0.10.0` was published as publication 5, followed by Work `0.7.2` as publication 6, with zero display mismatches and no dependency warning.

Zero-measure interpretation is an audit requirement, not a philosophical classification. In the corrected current publications, 3,354 philosophers have raw zero mentions, 4 have positive mentions suppressed by roles, and 9 Works have source coverage cancelled by all-zero authors. No zero-measure entity has a zero Danker factor. Genuine restoration moved 210 philosophers and 626 Works off zero. The previous 277 philosopher and 626 Work raw Danker zeros were missing values coerced by historical import code, not genuine source zeros. See `docs/CANONICITY_ALGORITHM.md` for the full semantics and required pre-publication audit.

## 16. Acceptance criteria

The work is complete when all of the following hold:

- Recalculation from one immutable dataset produces controlled, attributable differences.
- Every completed run replays exactly, including population, measures, normalisation, and dense ranks.
- Nulls, zeroes, primitive types, capacities, expressions, genre, and author inputs are preserved unambiguously.
- Dataset capture is coherent, and incomplete execution cannot become completed.
- Every Work dataset uses a completed Philosopher run; missing authors fail clearly, and no stale legacy-author fallback exists.
- Partial runs cannot become the current global ranking.
- Publication is atomic, append-only, interruption-safe, and republishable.
- Current display values change only through eligible publication.
- Entity deletion cannot erase completed-run evidence.
- Danker and reference-flag imports update current inputs and source events atomically.
- Historical snapshots remain valid with `metric_run_id = NULL`.
- Every new table has an empty fixture file.
- Each phase exposes its new state through `/canonicity` for UAT and course correction before later phases proceed.
- All new and existing tests pass, and StandardRB introduces no new offences.
- The small-dataset experiment checks and full-population dependency/publication checks pass.

## 17. Non-goals

- Redesigning the intended canonicity formula.
- Adding `linkcount` to the formula.
- Disabling mention or Danker independently through `signal_config`; current source omissions are weight-based.
- Manual run naming or curated labels.
- A global semantic version sequence shared by both subject types.
- Legacy fallback to stale `Philosopher#measure`.
- A separate `current_publications` table.
- Renumbering historical algorithm versions or snapshots.
- Recomputing historical results.
- Partial-publication overlays or mixed-population rankings.
- The broader Rails, schema, query-DSL, or full UI modernisation plans.
- Longitudinal visualisation beyond the initial comparison view.
- Database-trigger enforcement in this phase.

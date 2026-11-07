# Plan CFP-A: Canonicity Metric Runs

**Status:** Phases 0–3 complete, including controlled runs and exact replay; Phase 4 is next.
**Series:** CFP-A; outside the numerical modernisation sequence.
**Pillar:** 1 — `philosophy-by-the-numbers`.
**Three-pillar programme:** [CFP planning and research-programme structure](../wip/dh2027-cfp-planning.md#research-programme-structure)
**Scope:** `philosophy-by-the-numbers`, including immutable input datasets, controlled canonicity experiments, replay, dependencies, retention, and publication.
**Starting run version:** `0.7.0` independently for each subject type.
**Compatibility rule:** Existing records, weights, snapshots, and current displayed measures remain unchanged unless explicitly published from a completed run.

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

## 2. Decisions

- No meaningful run names or manually maintained labels.
- Run identity comprises `subject_type`, `version`, `started_at`, and `completed_at`.
- Versions use `major.minor.patch` **independently for each subject type**, beginning with both Philosopher and Work at `0.7.0`.
- Run, calculator, configuration, dataset, and publication identities are distinct.
- Existing algorithm versions and historical snapshots are not renumbered.
- The canonical Work formula applies genre exactly once.
- `linkcount` is available and time-varying but unused in the current formula.
- Failed runs retain evidence and consume version numbers within their subject sequence.
- JSON is stored as serialized text with a versioned payload schema.
- Partial runs may be used for experiments and replay but may not become the current global ranking.
- Publication requires complete coverage of the intended publication population.
- Publication history is append-only; the latest publication ID for each subject type identifies the current publication. No separate current-publication table exists.
- A completed Philosopher run is required before capturing any Work dataset; there is no legacy-author fallback.

## 3. Current gaps and defects

The following must be repaired or explicitly accounted for:

1. Work's rake task applies genre a second time (`lib/tasks/shadow/work_tasks.rake:563`). For `genre = false`, the snapshot applies `0.50`, while the displayed value applies it twice and is therefore `0.25` of the unscaled contribution rather than `0.50`.
2. Work author adjustment reads live `Philosopher#measure`, which is stale because the Philosopher metric task creates snapshots without updating it. Any author's `nil` measure also raises `TypeError` during summation.
3. Both calculation methods mix live input gathering, extrema queries, relationships, and snapshot writes.
4. Existing snapshots coalesce `danker = nil` to `0.0`; schema columns `danker_score`, `linkcount`, and `mention_count` are also `null: false`.
5. Work computes `raw_measure` before guarding zero denominators and can persist non-finite output.
6. Input capture lacks a coherent database-state and population contract.
7. Per-entity exceptions can be rescued while the task still reports completion.
8. Latest-result scopes can return unfinished or failed data.
9. Snapshot weights are read live rather than from frozen configuration.
10. Independent ranking tasks rewrite the latest snapshot.
11. Encyclopedia-flag imports are hidden in the Work calculation task.
12. Work provenance uses placeholder text, and role exclusions are hardcoded.
13. Danker import writes invalid snapshot attributes while its current-value update is commented out.
14. Publication requirements are undefined for partial populations, interruptions, republishing, and concurrent publication.
15. `dependent: :destroy` allows entity deletion to remove snapshot evidence; insertion and reassignment also need retention rules.
16. Existing version, configuration, and run identities are insufficient to support controlled experiments.
17. The existing `latest_measures_for_all_*` helpers have no callers; the actual display reads `shadows.measure` and `measure_pos` directly.

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

Extrema are calculated **only from normalisation IDs**, even when those IDs are a subset or superset of the selected IDs. Replay follows the same rule. Capturing the union permits normalisation to be recomputed rather than merely comparing stored maxima with themselves.

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
| `signal_config` | Enabled signals and executable configuration, including role exclusions |
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
  + alternative weights or source selection
  → attributable output differences
```

No live input refresh occurs during recalculation.

Configuration edits create a new configuration version. A source omission requires a complete new weight set in `canonicity_weights`. Rows identified by `(algorithm_version, source_name)` are never updated in place after being used by a run.

Disabled sources are removed **before** derived terms are computed, including Philosopher `has_sources`/`all_bonus` and Work `encyclopedia_sum`, `sourcey`, and the author adjustment. A disabled multiplicative signal contributes `1.0`; a disabled additive contribution contributes `0.0`; a disabled adjustment is omitted.

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
- **Configuration version:** the named configuration family, currently `2.1` and `2.0-work`. Original `2.0` is preserved for compatibility.
- **Configuration fingerprint:** stable checksum of canonical weight and executable signal configuration.
- **Run version:** the execution label within a subject sequence.

A new weight set using V2 therefore has a different configuration fingerprint without implying a new calculator.

Create `canonicity_signals` in Phase 1 as descriptive metadata with:

- Algorithm/configuration version.
- Name and description.
- Source.
- `subject_to_change`.
- `used_in_formula`.
- `active`.

This table is required by the project's need to document which inputs change over time. Executable behaviour belongs to `signal_config`, not merely to registry metadata.

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
- Its normalisation population is valid for that publication.
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

`shadow:work:order2` and the Philosopher ranking task are retired as independent snapshot-mutating tasks or limited strictly to publication.

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

Legacy ranking tasks still contain direct display-value writes. Their retirement or restriction to publication remains Phase 4 work; the measure tasks now use controlled capture and calculation.

### Phase 3: Calculate, recalculate, and replay

**Status:** COMPLETE (2026-11-06). Controlled calculation and recalculation over ready datasets, subject-scoped semantic versions, frozen configuration fingerprints, dense ranking, failure recovery, and exact read-only replay implemented. Philosopher runs 0.7.0 and 0.7.1 were created from real dataset 3 and both replay exactly. Run/snapshot inspection and replay are available in the dashboard. Full Rails suite passes (876 runs, 2,929 assertions, 0 failures, 0 errors, 0 skips); Phase 3 service and test files pass StandardRB.

**Review hardening:** calculation, completion validation, and replay now share `Canonicity::DenseRank`, so tied measures receive the same rank and the next distinct measure increments once. Original `2.0` weights are restored for compatibility; normalized two-decimal weights and their signal registry now belong to `2.1`, the Philosopher default. Cross-subject configurations are rejected before run creation. Real run 0.8.0 uses `2.1` and all three real runs replay exactly. Final full suite: 1087 runs, 4076 assertions, 0 failures, 0 errors, 0 skips.

Implement controlled calculation over ready datasets, completion validation, dense ranking, recovery, and read-only replay. Test repeated recalculation from one dataset and exact replay of measures, population, normalisation, and ranks. Expose runs, controlled differences, and replay results in the dashboard for UAT.

### Phase 4: Publication and UI completion

Implement eligibility, atomic publication, republishing, interruption rollback, and comparison. Complete the dashboard with publication eligibility, history, comparison, and controlled publication actions. Use the existing **Ruby 2.6** thread-error workarounds where applicable.

### Phase 5: Documentation and verification

Update:

- `docs/CANONICITY_ALGORITHM.md`
- `app/ERD.md`
- `docs/RAKE_TASKS.md`
- `docs/DATA_REFRESH_GUIDE.md`
- `docs/TESTING_STRATEGY.md`
- `.ai-instructions.md` if project guidance or status changes

Run:

```bash
bin/rake test
bin/standardrb
```

End-to-end scenario on a small real dataset:

1. Capture a Philosopher dataset and complete run `0.7.0`.
2. Recalculate from the same dataset with a new configuration version and confirm that only configuration-dependent outputs differ.
3. Replay both runs and confirm exact measures, population, normalisation, and ranks.
4. Capture a Work dataset using the completed Philosopher dependency and complete Work run `0.7.0`.
5. Attempt to publish a partial run and confirm rejection.
6. Create a new configuration version rather than editing immutable configuration.
7. Import new Danker data, including a missing entity, and verify atomic current-value/event updates and unchanged Work minimum-rank behaviour.
8. Confirm that earlier datasets, runs, and current display values remain unchanged.
9. Publish a complete run, interrupt a second publication attempt, and verify rollback.
10. Republish the first run and verify append-only history and latest-ID current selection.

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
- The small real-data end-to-end check passes.

## 17. Non-goals

- Redesigning the intended canonicity formula.
- Adding `linkcount` to the formula.
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

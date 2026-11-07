# CorpusBuilder Modernisation - Master Plan

This master plan covers six major workstreams to modernise the CorpusBuilder codebase.
Each sub-plan is self-contained and designed to be tackled in sequence, though some
parallel work is possible where noted.

## Current State (reconciled November 2026)

| Dimension | Status |
|-----------|--------|
| Ruby | 2.6.10 (EOL March 2022) |
| Rails | 4.2.11.3 (EOL April 2017) |
| Test Coverage | Last complete run: 785 tests, 2504 assertions, no failures/errors/skips; 37.15% coverage |
| Rake Tasks | 114 application tasks classified; nine workflows expose 93 distinct tasks |
| Frontend | Picnic CSS + jQuery + Bower (deprecated), server-rendered ERB |
| App Code | ~10,700 lines across 42 models, 27 controllers, 183 views |

## Workstream Overview

| # | Workstream | Sub-plan | Dependency |
|---|-----------|----------|------------|
| 1 | [100% Test Coverage](docs/plans/PLAN-1-TEST-COVERAGE.md) | Build the safety net | None (start here) |
| 2 | [Task Classification & Workflows](docs/plans/PLAN-2-TASK-CLASSIFICATION.md) | Organise and orchestrate 120+ rake tasks | Can overlap with #1 |
| 3 | [Ruby and Rails Migration](docs/plans/PLAN-3-RUBY-RAILS-MIGRATION.md) | Ruby 2.6.10 -> 3.4.x; Rails 4.2.11.3 -> 8.1.x | Requires #1; uses #2 workflow checks |
| 4 | [Schema Overhaul](docs/plans/PLAN-4-SCHEMA-OVERHAUL.md) | Normalise tables, fix data integrity, add views | Requires #3 complete |
| 5 | [Query DSL & Virtual Tables](docs/plans/PLAN-5-QUERY-DSL.md) | Composable query language + view-backed models | Requires #4 complete |
| 6 | [UI Overhaul](docs/plans/PLAN-6-UI-OVERHAUL.md) | Modern frontend on modern Rails | Requires #5 complete |

## Sequencing

```
#1 Test Coverage --------> #3 Ruby + Rails ----> #4 Schema ----> #5 Query DSL ----> #6 UI
#2 Task Classification ---/ (workflow checks)
```

- **#1 first** establishes regression coverage for the migration.
- **#2 can overlap with #1**; its workflow tests help verify command-line behaviour
  during the migration. Extend the existing CLI implementation.
- **#3 coordinates Ruby and Rails** in one sequence, with a passing checkpoint
  after each version change.
- **#4 follows #3** for broader schema changes on the upgraded framework.
- **#5 follows #4** because the query DSL builds on the normalised tables and views.
- **#6 follows #5** for the full interface and asset overhaul.

## Guiding Principles

1. **Incremental, testable steps.** Each phase is individually verifiable.
2. **One version jump at a time** for Ruby and Rails.
3. **Branch-per-phase.** Merged to main only when all tests pass.
4. **Reproducible verification.** Use project binstubs and record test results at each checkpoint.
5. **Preserve existing behaviour.** Migration changes internals, not functionality.

## Existing Tooling (scripts/)

These scripts already exist and are directly useful:

| Script | Relevant Plan | Purpose |
|--------|--------------|---------|
| `scripts/categorize_rake_tasks.rb` | Plan 2 | Separates built-in vs user-created rake tasks |
| `scripts/list_and_categorize_rake_tasks.rb` | Plan 2 | Alternative task categorisation script |
| `scripts/check_gems.rb` | Plan 3 | Compares `bundle list` vs `bundle outdated` |
| `scripts/test_delta_workflow.rb` | Plan 1 | Integration test for delta analysis pipeline |
| `scripts/test_work_based_delta.rb` | Plan 1 | Integration test for work-based delta analysis |

WIP notes: `docs/wip/CODE_COVERAGE.md` has an existing todo list for coverage gaps.

---

## Actionable Checklist

### Workstream 1: Test Coverage
> Detail: [docs/plans/PLAN-1-TEST-COVERAGE.md](docs/plans/PLAN-1-TEST-COVERAGE.md)

- [x] Establish the coverage baseline and reuse shared test helpers
- [x] Fill the original simple-model stubs and add snapshot/weights/expression tests
- [x] Cover substantive helpers; remove the orphaned helper test
- [x] Add the previously missing includings, info and bulk query controller tests
- [x] Exercise file/resource controller paths with controlled HTTP responses
- [x] Replace the composite-key controller skip with STI CRUD coverage
- [x] Isolate the philosopher metric task and remove its normal-suite skip
- [x] Add workflow CLI/TUI execution and task-contract regressions
- [x] Exercise cumulative Saffron processing with a fake external process
- [x] Complete a full test run with no failures, errors or skips
- [ ] Deepen filtering, validation-failure and cross-entity controller coverage
- [ ] Cover remaining external integrations, work-based delta selection and library utilities
- [ ] Audit remaining fixture isolation and mutating-task behaviour
- [ ] Reach the 100% coverage target, documenting justified exclusions

**Gate: SimpleCov >= 100%, all tests green, no network-dependent tests.**
The passing preparation run strengthens the safety net; it does not complete the
100% coverage requirement.

---

### Workstream 2: Task Classification and Workflows
> Detail: [docs/plans/PLAN-2-TASK-CLASSIFICATION.md](docs/plans/PLAN-2-TASK-CLASSIFICATION.md)

- [x] Reconcile the existing `bin/corpus` CLI, YAML workflows and event-log state
- [x] Classify all 114 application tasks separately from Rails/gem tasks
- [x] Record the 21 unexposed tasks and their review status
- [x] Validate task names and positional parameter contracts
- [x] Cover dependency failures, declined steps, resume, dry runs and exit status
- [x] Share execution rules between CLI and TUI
- [x] Keep direct `bin/rake` use available
- [ ] Review legacy task-level exception handling and restart/idempotency guarantees
- [ ] Define cross-workflow dependencies and input-reset rules for live use
- [ ] Decide which descriptive postconditions should become executable checks
- [ ] Reconcile metric/ranking commands with CFP-A publication semantics
- [ ] Validate selected live workflows on disposable data

**Gate: Task classification and execution regressions pass; selected live workflows
also satisfy their task-level error/restart and integration contracts.**

Audit: [docs/ai/migration-preparation-audit.md](docs/ai/migration-preparation-audit.md).
Current work: [docs/wip/migration-preparation.md](docs/wip/migration-preparation.md).

---

### Workstream 3: Ruby and Rails Migration
> Detail: [docs/plans/PLAN-3-RUBY-RAILS-MIGRATION.md](docs/plans/PLAN-3-RUBY-RAILS-MIGRATION.md)

**Preparation**
- [ ] Reconcile Plan 1 coverage and Plan 2 workflow implementation with their progress notes
- [ ] Record passing tests, dependency versions and a database backup
- [ ] Audit dependencies and enable deprecation reporting

**Coordinated upgrade checkpoints**
- [ ] Rails 4.2 -> 5.0 -> 5.1 -> 5.2 on Ruby 2.6, matching CPK versions at each step
- [ ] Rails 5.2 -> 6.0 -> 6.1 on Ruby 2.6; prepare autoloading and dependencies
- [ ] Ruby 2.6 -> 2.7 -> 3.0 on Rails 6.1; resolve keyword arguments and verify workaround removal
- [ ] Rails 6.1 -> 7.0 on Ruby 3.0; complete Zeitwerk and retain Sprockets
- [ ] Ruby 3.1 on Rails 7.0, then Rails 7.1 -> 7.2; handle Psych and native composite keys
- [ ] Ruby 3.2 -> 3.3 -> 3.4 on Rails 7.2; verify native gems and serialisation
- [ ] Rails 7.2 -> 8.0 -> 8.1 on Ruby 3.4; verify SQLite and framework defaults
- [ ] Test and commit each checkpoint before advancing

**Gate: Ruby 3.4.x + Rails 8.1.x, reproducible bundle, Zeitwerk, native composite keys,
existing web and CLI behaviour preserved, all tests green**

---

### Workstream 4: Schema Overhaul
> Detail: [docs/plans/PLAN-4-SCHEMA-OVERHAUL.md](docs/plans/PLAN-4-SCHEMA-OVERHAUL.md)

**Phase 1 - Reference Work Flag Normalisation**
- [ ] Create `reference_work_entries` table (shadow_id, source_name, flagged_at)
- [ ] Migrate 12 boolean columns from `philosopher_attrs`
- [ ] Update `Philosopher` model, `import/sauce.rb`, canonicity calculation
- [ ] Remove boolean columns from `philosopher_attrs`

**Phase 2 - MetaFilter Serialisation Fix**
- [ ] Replace Base64-encoded `Marshal.dump` with JSON in `meta_filter_pairs`
- [ ] Update `MetaFilterPair` model and `QuestionsController#from_filter`

**Phase 3 - Verify Native Composite Keys**
- [ ] Verify Plan 3 native-key behaviour after schema changes
- [ ] Confirm associations, lookups and fixtures remain correct

**Phase 4 - SQL Injection Cleanup**
- [ ] Fix raw SQL string concatenation in `QuestionsController#specific_features`
- [ ] Grep and fix all raw SQL patterns (`.where("`, `.execute(`, `.find_by_sql(`)

**Phase 5 - Schema Cleanup**
- [ ] Archive and drop `obsolete_attrs` table
- [ ] Evaluate `date_hack`, `name_hack`, `philosophy` columns on `shadows`
- [ ] Clean up `http_request_loggers`, review `viaf_cache_items`

**Phase 6 - Database Views for Common Aggregations**
- [ ] Create views: `philosopher_summaries`, `work_summaries`, `property_aggregations`, `encyclopedia_coverage`
- [ ] Create read-only ActiveRecord models backed by views

**Phase 7 - Author-Philosopher Linkage**
- [ ] Add `shadow_id` FK to `authors` table
- [ ] Data migration to match existing authors to philosophers

**Gate: No Marshal serialisation, no CPK gem, no raw SQL, reference flags normalised, views in place, all tests green**

---

### Workstream 5: Query DSL & Virtual Tables
> Detail: [docs/plans/PLAN-5-QUERY-DSL.md](docs/plans/PLAN-5-QUERY-DSL.md)

**Phase 1 - Query Object Foundation**
- [ ] Create `CorpusQuery` entry point + `PhilosopherQuery`, `WorkQuery`, `TextQuery`
- [ ] Implement chainable methods: `.born_in()`, `.in_reference_work()`, `.with_canonicity()`, etc.

**Phase 2 - View-Backed Models**
- [ ] Create readonly `PhilosopherSummary`, `WorkSummary`, `PropertySummary` models
- [ ] Wire CorpusQuery to use view-backed models for reads

**Phase 3 - Property/Relationship Queries**
- [ ] DSL methods wrapping P::Smart subclasses (born_in, died_in, from_country, etc.)
- [ ] Aggregation methods: `.group_by(:birth_place).count`
- [ ] Refactor `QuestionsController` to delegate to CorpusQuery

**Phase 4 - Composed & Cross-Entity Queries**
- [ ] Cross-entity: `CorpusQuery.works.by_philosopher(born_in: "Athens")`
- [ ] `.or()` and `.not()` support for composition

**Phase 5 - Saved Queries (MetaFilter Replacement)**
- [ ] Create `saved_queries` table with JSON serialisation
- [ ] `query.save_as("name")` / `CorpusQuery.load("name")`
- [ ] Migrate existing MetaFilter data, archive old tables

**Phase 6 - Query Console**
- [ ] `.explain` (show SQL), `.to_csv` (export), `.to_table` (pretty-print)
- [ ] Rake task: `bin/rake query:run["philosophers.born_in('Athens')"]`

**Gate: All QuestionsController queries expressible via DSL, saved queries replace MetaFilter, all tests green**

---

### Workstream 6: UI Overhaul
> Detail: [docs/plans/PLAN-6-UI-OVERHAUL.md](docs/plans/PLAN-6-UI-OVERHAUL.md)

**Phase 1 - Asset Pipeline Migration**
- [ ] Remove Bower (`bower.json`, `.bowerrc`, `vendor/assets/bower_components/`)
- [ ] Install Propshaft + Import Maps
- [ ] Pin: `bootstrap`, `@popperjs/core` (+ fix-popper.sh), `alpinejs`, `d3`
- [ ] Remove `resolve:paths` rake task
- [ ] All pages load without JS/CSS errors

**Phase 2 - Layout & Navigation (Bootstrap 5)**
- [ ] Responsive layout with Bootstrap navbar, breadcrumbs, grid
- [ ] Bootstrap components throughout (cards, tables, badges, alerts, modals)
- [ ] Replace Font Awesome 4 with Bootstrap Icons or FA 6
- [ ] Dark mode support (`data-bs-theme="dark"`)

**Phase 3 - jQuery Removal (Alpine.js + fetch)**
- [ ] Replace jQuery DOM manipulation with Alpine.js (`x-data`, `x-show`, `x-on`)
- [ ] Replace Cocoon nested forms with Alpine.js `x-for` arrays
- [ ] Remove `jquery-rails` and `cocoon` gems entirely

**Phase 4 - Data Display**
- [ ] Philosopher index: Bootstrap card grid with metrics
- [ ] Philosopher show: Bootstrap tabs profile page
- [ ] Text/Work index: searchable sortable Bootstrap tables
- [ ] Dictionary/Unit views

**Phase 5 - Visualisation Rebuild**
- [ ] D3 v3 -> D3 v7 (or Observable Plot)
- [ ] Replace Springy/Dracula with Sigma.js (or D3 force graph)
- [ ] Replace Venn.js with modern equivalent
- [ ] New metrics dashboard

**Phase 6 - Forms & Interactions**
- [ ] Bootstrap 5 form components (`form-control`, floating labels)
- [ ] Alpine.js form validation (`x-on:input`, Bootstrap `is-invalid` classes)
- [ ] Autocomplete via Alpine.js + fetch()
- [ ] Bulk operations via Alpine.js
- [ ] Bootstrap modals for confirmations

**Phase 7 - Polish**
- [ ] Loading skeletons, keyboard shortcuts
- [ ] Accessibility audit (ARIA, colour contrast)
- [ ] Mobile testing
- [ ] Lighthouse score >= 90

**Gate: No jQuery, no Bower, responsive, Lighthouse >= 90, all tests green**

---

## Original Estimated Total Effort

These estimates predate the implemented test and workflow work. Re-estimate the
remaining work from the reconciled checklists; do not treat the totals as a fresh
build-from-scratch estimate.

| Workstream | Sessions | Can Parallelise? |
|-----------|----------|-----------------|
| 1. Test Coverage | 15-23 | Start first |
| 2. Task Classification | 6-8 | Overlap with #1 |
| 3. Ruby and Rails Migration | 20-30 | After #1, using #2 workflow checks |
| 4. Schema Overhaul | 9-14 | After #3 |
| 5. Query DSL & Virtual Tables | 12-18 | After #4 |
| 6. UI Overhaul | 18-26 | After #5 |
| **Total** | **~80-119 sessions** | |

With #1 and #2 overlapping and the combined migration counted once, the provisional
critical path remains roughly **~74-111 sessions**.

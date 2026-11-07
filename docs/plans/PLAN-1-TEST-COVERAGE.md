# Plan 1: 100% Test Coverage

**Goal:** Achieve comprehensive test coverage across all models, controllers, helpers,
libraries, and rake tasks before beginning migration work.

**Back to:** [Master Plan](../../MASTER_PLAN.md)

## Current State (reconciled 2026-11-06)

The February inventory is historical. Substantial work already exists; use
[the recorded progress](../wip/PLAN1_PROGRESS.md) and
[current migration preparation](../wip/migration-preparation.md) rather than
recreating test files described as missing in the original inventory.

Baseline measured before this preparation pass:

| Check | Result |
|-------|--------|
| Full suite | 743 runs, 2172 assertions |
| Failures / errors / skips | 0 / 2 / 3 |
| Runtime | 212.05 seconds |
| SimpleCov | 33.30%, 4178/12545 lines |

The two errors came from real HTTP requests in file-update and resource-edit
controller tests. Skips covered file creation, composite-key property controllers,
and the philosopher metric task. These are migration risks, not acceptable
substitutes for passing tests.

The repository now has substantive model/helper tests, nine workflow definitions,
a CLI test suite, pure canonicity calculator tests, and Zotero integration tests.
Coverage includes more code than the February baseline, so the percentages are
not a direct measure of improvement across those snapshots.

### Verified Preparation Result

Full suite, seed 23291: **785 runs, 2504 assertions, 0 failures, 0 errors, 0 skips**
in 218.67 seconds. SimpleCov: **37.15% (4570/12302 lines)**. Formatting and added
coverage changed the measured denominator; retain the exact counts alongside the
percentages. The 100% coverage objective remains open.

### Preparation Work

- [x] Exercise file creation/update with controlled HTTP responses.
- [x] Exercise resource metadata redirects and absent-metadata rendering offline.
- [x] Cover bulk saved-query creation, updates and entity selection.
- [x] Replace the composite-key controller skip with STI CRUD tests.
- [x] Isolate the philosopher metric Rake test and restore patched state reliably.
- [x] Cover workflow parameters, dependency failures, resume, CLI exit status and TUI execution.
- [x] Check workflow task names and positional arguments against registered Rake tasks.
- [x] Exercise cumulative delta processing with fake Saffron output and real temporary files.
- [x] Record the final full-suite/coverage result after this pass.
- [ ] Complete the remaining broader coverage work below; 100% is not yet achieved.

## Phases

### Phase 1: Foundation & Tooling
- [x] Keep SimpleCov opt-in via `COVERAGE=1`; measure coverage during verification
- [x] Run `COVERAGE=1 bin/rake test` and record the baseline percentage
- [ ] Review and update fixtures in `test/fixtures/` - ensure they cover key relationships
- [x] Reuse the existing `create_test_philosopher` and `create_test_work` helpers

### Phase 2: Model Tests (Priority: High)
Test models in dependency order (leaf models first, then models with associations).

**Tier 1 - Simple models, no complex associations:**
- [x] Tag, Role, Capacity, Resource, Link
- [x] Author, Writing
- [x] Fyle, HttpRequestLogger
- [x] ViafCacheItem
- [x] MetricSnapshot, CanonicityWeights

**Tier 2 - Models with important associations:**
- [x] Name (multi-language labels, philosopher association)
- [x] Text (belongs_to Author, has_many Writings)
- [x] Dictionary, Unit (lexical analysis)
- [x] Filter, MetaFilter, MetaFilterPair, Labeling, Including

**Tier 3 - Complex models (STI, delegation):**
- [ ] Shadow (base STI class - partially done)
- [ ] Philosopher (extends Shadow - partially done)
- [ ] Work (extends Shadow - partially done)

**Tier 4 - P:: namespace models:**
- [ ] P::Smart and all P:: subclasses (d1, d2, d3, j1, j27, p19, p20, p27, p31, p1412)
- [x] Include the entire P:: namespace in SimpleCov; no subsystem exclusions.

**For each model, test:**
1. Validations (presence, uniqueness, format)
2. Associations (has_many, belongs_to, through)
3. Scopes (if any)
4. Instance methods (especially complex logic)
5. Class methods
6. Callbacks (before_save, after_create, etc.)

### Phase 3: Controller Tests
Many controllers already have substantive tests. The priority is:
1. Audit existing test files - determine which have real assertions vs stubs
2. Fill in stubs with substantive tests
3. Create the 3 missing test files

**Step 1 - Audit current test files:**
- [ ] Check each file for actual assertion count (not just class declaration)
- [ ] Rank by: empty stubs first, partial tests next, complete tests last

**Step 2 - Previously missing test files:**
- [x] IncludingsController
- [x] InfoController
- [x] Bulk::MetaFilterPairsController

**Step 3 - Fill stubs, ordered by complexity:**

*Simple CRUD controllers:*
- [ ] AuthorsController, RolesController, TagsController
- [ ] WritingsController, LabelingsController
- [ ] ResourcesController, LinksController
- [ ] CapacitiesController

*Controllers with filtering/search:*
- [ ] TextsController (complex filtering)
- [ ] NamesController
- [ ] FiltersController, MetaFiltersController, MetaFilterPairsController
- [ ] DictionariesController (includes path traversal security)
- [ ] UnitsController

*Complex controllers:*
- [ ] PhilosophersController (already substantive - verify completeness)
- [ ] QuestionsController (already substantive - verify completeness)
- [ ] PagesController (visualisations, multiple action types)
- [ ] P::SmartsController
- [ ] WelcomeController, FilesController, WorksController

**For each controller, test:**
1. Index action (with and without filters)
2. Show action (valid and invalid IDs)
3. New/Create actions (valid and invalid params)
4. Edit/Update actions (valid and invalid params)
5. Destroy action
6. Any custom actions
7. Access control / authorisation (if applicable)

### Phase 4: Helper Tests
- [ ] ShadowsHelper (likely the most complex - Wikidata URL generation, etc.)
- [ ] PagesHelper (partially done)
- [ ] QuestionsHelper
- [ ] PhilosophersHelper (if distinct from ShadowsHelper)
- [ ] TextsHelper, AuthorsHelper, WritingsHelper
- [ ] All remaining helpers (likely thin - quick to test)

### Phase 5: Library Tests
These are standalone modules - test in isolation.

**Tier 1 - Core utilities:**
- [ ] truncate.rb, texify.rb, delivery.rb, test_delivery.rb
- [ ] app_config.rb, update_without_timestamping.rb

**Tier 2 - External integration (may need mocking):**
- [ ] knowledge.rb + knowledge/*.rb (Wikidata, DBpedia, Wikipedia, MediaWiki)
- [ ] wikidata/*.rb (client_helpers, query_executor, sparql_queries)
- [ ] elastic_helper.rb (Elasticsearch operations)
- [ ] do_http.rb (HTTP client)
- [ ] zotero.rb, philosoraptor.rb

**Tier 3 - Analysis modules:**
- [ ] delta_analysis/custom_diff_strategies.rb
- [ ] delta_analysis/delta_of_delta_processor.rb
- [ ] delta_analysis/work_based_delta_processor.rb

**Tier 4 - Rails integration:**
- [ ] the_git.rb (git operations)
- [ ] markdown_erb_template_handler.rb
- [ ] console_extension.rb

### Phase 6: Integration Tests
- [ ] End-to-end philosopher creation workflow
- [ ] End-to-end text addition workflow
- [ ] Search/filter workflow across controllers
- [ ] Visualisation page rendering (Springy, Dracula, D3)

### Phase 7: Rake Task Tests
- [ ] Extend shadow_rake_tasks_test.rb patterns to cover remaining tasks
- [ ] Focus on tasks that modify data (population, metrics, scraping)
- [ ] Use mocking for external API calls (Wikidata, VIAF, encyclopedias)

## Success Criteria
- SimpleCov reports >= 100% line coverage; document any exclusions. Exercise
  network error paths with controlled responses rather than treating them as untestable.
- All tests pass: `bin/rake test` exits 0
- No test depends on external network access (all HTTP calls mocked)
- Record full-suite duration. The original under-60-second target is not yet met;
  measure the subprocess-heavy Zotero checks separately before optimising.

## Estimated Effort
- Phase 1: 1 session
- Phase 2: 3-5 sessions (19+ model stubs to fill)
- Phase 3: 4-6 sessions (20+ controllers)
- Phase 4: 1-2 sessions (mostly thin helpers)
- Phase 5: 3-4 sessions (external integration mocking is the bulk)
- Phase 6: 1-2 sessions
- Phase 7: 2-3 sessions
- **Total: ~15-23 sessions**

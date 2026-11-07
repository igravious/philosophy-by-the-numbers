# Plan 1: Test Coverage Progress

## Migration Preparation (2026-11-06)

- Full suite: **785 runs, 2504 assertions, 0 failures, 0 errors, 0 skips**
  (seed 23291; 218.67 seconds).
- Coverage: **37.15% (4570/12302 lines)**; the measured code population differs
  from February and from the pre-preparation baseline.
- Replaced file/resource network dependencies with controlled responses.
- Replaced all three ordinary-suite skips with exercised file creation,
  composite-key STI CRUD and an isolated metric task test.
- Added saved-query, workflow argument/dependency/resume/TUI and cumulative Saffron
  regression coverage; fixed the exposed routing, execution and reporting defects.
- The 95% target and broader integration/library coverage remain open.
- Current working notes: [migration-preparation.md](migration-preparation.md).

## Baseline (2026-02-08)
- **Coverage:** 21.34% (2014/9438 lines)
- **Tests:** 219 runs, 480 assertions, 0 failures, 0 errors, 6 skips
- **36 files at 100%**, 15 files at 0%

## Session 2 (2026-02-08)
- **Coverage:** 21.57% (2035/9436 lines)
- **Tests:** 378 runs, 722 assertions, 0 failures, 0 errors, 7 skips
- **+159 test runs**, **+242 assertions**, all green

## Session 3 (2026-02-08)
- **Coverage:** ~24.95% (2314/9275 lines)
- **Tests:** ~500 runs, ~1000 assertions, 0 failures, 0 errors, 3 skips
- **+120 test runs**, **+280 assertions**, all green
- Coverage jumped from 21.57% → 24.95% (+3.38%)

## Session 4 (2026-02-08)
- **Coverage:** 25.28% (2345/9275 lines)
- **Tests:** 543 runs, 1163 assertions, 0 failures, 0 errors, 3 skips
- **+43 test runs**, **+163 assertions**, all green
- Phase 4 (Helper Tests) complete: 4 substantive helpers tested, orphaned test deleted
- Coverage: 24.95% → 25.28% (+0.33%)

## Phase 1: Foundation & Tooling ✅
- [x] Get SimpleCov baseline: 21.34%
- [x] Review and update fixtures (created canonicity_weights.yml, empty roles.yml; deleted broken expressions/metric_snapshots fixtures)
- [x] Create shared test helpers: `create_test_philosopher`, `create_test_work` in test_helper.rb
- [x] Verify stubs vs substantive: 29 substantive, 33 stubs, 11 empty
- [x] Fix STI fixture loading: `set_fixture_class canonicity_weights: CanonicityWeights`
- [x] Fix phantom data bug: empty roles.yml prevents stale dev data leaking into tests

## Phase 2: Model Tests
- [x] Tier 1 - Simple models: link, tag, role, writing, capacity, http_request_logger, viaf_cache_item, labeling, resource, property
- [x] Tier 2 - Models with associations: name, text, dictionary, unit, filter, meta_filter, meta_filter_pair, including, author, fyle
- [x] New test files: canonicity_weights_test.rb (14 tests), metric_snapshot_test.rb (16 tests), expression_test.rb (4 tests)
- [x] Controller fix: roles_controller_test.rb (7 tests, all passing)
- [x] Tier 3 - Shadow/Philosopher/Work (~50 tests): delegation, attrs auto-build, STI, associations, year/get_year, english, show_label, birth_death, reference_work_flags_json, scopes, capacities
- [x] Tier 4 - P::Smart base class (12 tests): property(), property_id, aliases, entity_label, dbpedia_property, composite PKs, subclass inheritance

## Phase 4: Helper Tests ✅
- [x] pages_helper_test.rb (4 tests): table_description — known tables, unknown, fallback
- [x] application_helper_test.rb (11 tests): on_off, symbol_or_blank, title, truncate
- [x] capacities_helper_test.rb (2 tests): c_extra — checked/unchecked states
- [x] shadows_helper_test.rb (19 tests): make_safe, Wikidata/Wikipedia URL helpers, wikidata_type, p_extra, w_extra, cache logic
- [x] Deleted orphaned entries_helper_test.rb (no matching helper)
- Skipped: toggleable/sortable (depend on controller-defined methods — better as integration tests)
- Note: 18 of 23 helpers are empty scaffold modules — nothing to test

## Phase 3: Controller Tests (started)
- [x] pages_controller_test.rb (14 tests): index, about, welcome redirect, export, inquiry, questions, collect, dracula, pome, paper, dashboard, search, springy
- [x] welcome_controller_test.rb (1 test): class existence (no route — dead controller)
- [x] includings_controller_test.rb (4 tests, NEW): show JSON, create, destroy, uncreate
- [x] info_controller_test.rb (2 tests, NEW): schema action
- [ ] Remaining: audit 18 CRUD controllers for deeper coverage beyond scaffold tests
- [ ] Missing: bulk/meta_filter_pairs_controller

## Phase 5: Library Tests (started)
- [x] truncate_test.rb (6 tests): Truncatable module
- [x] delivery_test.rb (7 tests): attributes, SHA1, determinism, SEED
- [x] custom_diff_strategies_test.rb (18 tests): all 4 strategy classes
- [x] knowledge_version_test.rb (2 tests): VERSION constant
- [x] update_without_timestamping_test.rb (3 tests): timestamp bypass
- [ ] Remaining: app_config, elastic_helper, do_http, texify, the_git, philosoraptor (medium)
- [ ] Remaining: knowledge/*, wikidata/*, zotero, delta processors (hard)

## Key Discoveries
- Philosopher and Work defined in `shadow.rb`, not separate files
- `after_initialize :build_attrs_if_needed` fires on every Philosopher/Work instantiation
- Tables without fixture files retain stale data (caused the roles test bug)
- `expressions` and `viaf_cache_items` have `id: false` — can't use standard fixtures
- **`year()`/`get_year()`/`birth_death()` are broken for delegated attrs** — `self[:birth]` reads raw shadows columns, but birth/death are on philosopher_attrs. These methods always return nil/`(0)` for birth/death.
- **`show_label()` requires join-loaded objects** — `self.label`/`self.lang` only exist when Shadow is loaded via `select('shadows.*, names.label, names.lang').joins(:names)`
- **work_attrs column types are surprising**: genre=boolean, philrecord/philtopic/britannica=string (not boolean!), philosophical=integer, pub_approx=string
- **WelcomeController is dead code** — no route maps to it (`get 'welcome'` → pages#welcome)
- **IncludingsController only has 4 routes** — show, create, uncreate, destroy (no index/new/edit/update)

## Historical Skipped Tests (February; all three resolved in November)
1. ShadowRakeTasksTest — flaky, needs isolation
2. FilesControllerTest#create — needs HTTP mocking
3. P::SmartsControllerTest — STI routing needs refactoring

Previously skipped, now resolved:
- ~~ShadowsControllerTest~~ — deleted (controller doesn't exist)
- ~~QuestionsControllerSecurityTest~~ — fixed
- ~~DictionariesControllerSecurityTest~~ — fixed
- ~~UnitTest#set_display_name~~ — fixed

## Historical Next Steps (see current preparation notes)
- Phase 3: Deepen existing CRUD controller tests (edge cases, validation failures, filters)
- Phase 5: Continue lib/ tests (medium difficulty: app_config, do_http, the_git)
- Phase 6: Rake task tests (extend shadow_rake_tasks_test.rb patterns, mock external APIs)
- Phase 7: Integration tests (end-to-end CLI workflows, UI flows — last because heaviest)
- Investigate: fix `year()`/`birth_death()` to use delegation instead of `self[date_sym]` (Workstream 4 candidate)

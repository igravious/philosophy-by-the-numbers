# Full actual-code coverage — current working state

## Objective and constraints

The user requires **100% coverage of actual code**. Do not stop at a partial
percentage, lower either coverage floor, or exclude an untested subsystem.
Continue until every included executable line is covered and the full suite passes.

- Ruby 2.6.10 / Rails 4.2.11.3. Use binstubs; require default gems inside Ruby,
  after Bundler setup. Never use a command-line `-rjson` preload.
- Test first, then repair demonstrated bugs. No unnecessary architecture or
  nitpicking; the user wants concrete work and dislikes confirmation requests.
- No agents unless explicitly authorized. No commits made.
- Shared dirty workspace includes substantial other-agent CFP-A work. Preserve it.
  `.ai-instructions.md` is canonical; its linked instruction files are not copies.
- Use `RAILS_ENV=test DATABASE_URL=sqlite3:/tmp/corpusbuilder-coverage-tests.sqlite3`
  for all Rails tests. This isolated SQLite DB was made by a read-only SQLite backup
  of db/test.sqlite3. Do not run DB test processes against it concurrently.

## Coverage measurement

`.simplecov` tracks unloaded Ruby files in app/, lib/, config/, scripts/, all Rake
files, application Ruby binstubs, Rakefile and config.ru. Includes P:: models.
Tests/support, vendor code, generated schema and migrations are outside runtime
coverage. Parent overall and per-file floors are **100**. Optional clarification
about runtime config/binstubs was unanswered; current scope includes them.

Start coverage before Rails/Rake boot, loading the binstub by absolute path:

    RAILS_ENV=test DATABASE_URL=sqlite3:/tmp/corpusbuilder-coverage-tests.sqlite3 COVERAGE=1 TESTOPTS='--verbose --seed 23291' bin/bundle exec ruby -e 'require "simplecov"; load File.expand_path("bin/rake")' test

Before a new authoritative full run, back up and remove generated
coverage/.resultset.json. Otherwise old source line numbers and replacement of
same-named parent suites make intermediate percentages misleading.

Two Ruby 2.6 measurement pitfalls were found and regression-tested:

1. Main scripts were not instrumented by the RUBYOPT require hook. The real launcher
   test/support/subprocess_coverage.rb now starts SimpleCov, sets $PROGRAM_NAME to
   the target, then loads it. Zotero phase-two integration tests use this launcher
   when COVERAGE is set. Child collectors report loaded files only, have unique
   command names, suppress formatters and leave the 100% check to the parent.
   Existing generator/verifier integration passed through it; generated script
   coverage now records hundreds of executed lines rather than zero.
2. Reloading a file loses earlier counters. test/support/rake_task_testing.rb caches
   isolated Rake applications by path, reenabling tasks between tests. Wrapped
   helper definitions in test/support/loaded_helpers.rb are cached likewise.
   Coverage contracts verify actual execution across setup cycles.
   A later full run exposed two old tests still reloading *all* task files, undoing
   these counters. They are now corrected: ShadowRakeTasksTest loads only its cached
   shadow.rake; DankerUpdateTest loads tasks only if absent. Existing Names tests
   share the cached names application with the newer tests.

## Last authoritative full-suite result

`/tmp/corpusbuilder-full-instrumented-coverage.log`: **1047 tests, 3818 assertions,
zero failures/errors/skips**, seed 23291. Report **8611/12464 (69.09%)**, 232 files.
Raw backup `/tmp/corpusbuilder-authoritative-coverage-resultset.json`.

This still undercounts some task bodies because the old global task reloads above
were corrected afterward. It is not the goal achieved. A new clean full run is
needed once the current batch is green.

Earlier logs are historical: the initial narrow 37.15% report, corrected-scope
49.92%, hook-only 56.84%, and intermediate merged 61–63% reports are not final.

## Running now / immediate next actions

- Current process: session **49495**, log
  `/tmp/corpusbuilder-actual-task-counters-verified.log`.
  It runs coverage over task utilities, philosopher maintenance, delta phases and
  analysis, Danker, dictionary/unit/name/reference tasks, plus existing shadow,
  name, date and task-registration tests.
- Wait for it; inspect failures. Exit 2 from the strict coverage floor is expected
  until the complete project reaches 100%; test failures are separate.
- Inspect merged per-file coverage to verify delta_phases.rake and
  danker_update.rake retain their executed bodies after all setup cycles.
- Then continue closing the substantial remaining gaps and perform a clean full
  suite when changes justify it. Do not finish at another partial percentage.

A read-only way to inspect merged missed lines without starting new collection:

    bin/bundle exec ruby -e 'ENV["SIMPLECOV_NO_DEFAULTS"]="1"; require "simplecov"; SimpleCov.root Dir.pwd; r=SimpleCov::ResultMerger.merged_result; puts r.files.sort_by {|f| -f.missed_lines.size}.take(30).map {|f| [f.missed_lines.size,f.filename].join(" ")}'

## Work completed in this continuation

- Date tests cover actual creation/update scopes, delegated birth/death/pub values,
  BCE labels and rejection of arbitrary model method names. Shadow#year reads real
  columns from its metadata association. Bare four-digit years were then found to
  be interpreted by Date._parse as month/day: shared DateTimeMethods.extract_year
  now preserves year-only and ISO inputs, with malformed-encoding tests.
- Real temp-file Fyle processing: plain/HTML/TEI/GZIP, converter-output PDF boundary,
  encoding repair and invalid data, binary persistence, cache failures, editing,
  path normalization and URL helpers. Existing absolute files are preserved;
  cache no longer returns from its callback before boolean success/failure handling.
  Fyle reached zero missed lines in the last measured report.
- Work-based delta selection uses real SQLite and author/text/fyle associations.
  Fixed PostgreSQL-only mixed ranking syntax and stale table/association references.
  Removed an overwritten duplicate helper and unused Work#text extraction method.
- All three delta phases exercised with real generated corpora and fake Saffron
  results. Fixed nonexistent Jaccard class, missing-directory handling and off-by-one
  convergence corpus. Analysis tasks also fixed require paths and obsolete flags.
- Text export tests exercise string query parameters, actual large/small files,
  snapshot metadata and author roles. Fixed nonexistent Fyle#plain calls and empty
  extra chunks at exact megabyte boundaries.
- Text mutation tests exposed partial writes and nonexistent RecordError rescue.
  Create/update now transact text and associations, rescue specific model errors,
  and preserve association-only request parameters. Existing CRUD/security tests pass.
- Questions tests exercise typed properties, grouping, selected IDs, saved filters,
  uploads and SQL-looking data. Parameterized label/ID queries, rejected malformed
  IDs, skipped blank upload lines, and initialized/paginated instance tables.
  Saved filters intentionally restore a table with checked features, not immediate
  entity results; tests preserve that behavior.
- Reference-index tests use browser/HTTP boundaries, actual parsing and persisted
  metadata. SEP, Runes, REP, IEP, both Oxford editions and InPhO paths covered.
  InPhO's unused stale-column debug lookup and unconditional exit were removed.
- Philosopher task tests cover selection presets, date variants, translation query
  construction, logs, population preview/force/errors, labels/lang frequency,
  historical year correction and gender counts. Selectors now address attrs or
  obsolete_attrs correctly; placeholder date alternatives are discarded; gender
  report joins the actual year table and escapes the percentage format correctly.
  Last focused date/maintenance check: **72 tests, 322 assertions**, green.
- Real progress-spinner thread tested with synchronization and cleanup.
  TaskUtilities logging regression showed it retained only internal stack frames;
  changed the filter to reject those frames. This fix is in the running check.
- Actual compressed Danker fixture produces numeric/alphabetical/CSV files using
  local bzip2/bzcat/sort/sed. Downloads, symlinks and failures use temp directories
  and controlled HTTP; optional reader validation is tested at its dependency seam.
- Page integrations: actual RDF serialization/node/edge creation, search/pagination,
  unavailable services, WordNet, memes and PDF boundaries. Fixed incorrect WordNet
  and Wikidata requires and added the missing PDF-error template.
- Maintenance scripts/binstubs exercised with commands intercepted. Memcache
  inspection now uses standard-library sockets instead of its missing net-telnet
  dependency. Rack gem-name extraction was corrected by its regression.
- Knowledge clients/caches, HTTP/Elasticsearch/Git helpers, query executor, CLI
  commands and TUI menus were covered earlier in this goal. Fixed local-file HTTP
  yielding, credential-loader paths, cached DBpedia logging/debug exit, CLI verbose
  declaration, unsupported TUI borders and a guard that always returned early.

## Recent verification logs

- `/tmp/corpusbuilder-query-reference-and-task-isolation-green.log`:
  **44 tests, 188 assertions**, zero failures/errors/skips.
- `/tmp/corpusbuilder-controllers-and-danker-green.log`:
  **58 tests, 223 assertions**, zero failures/errors/skips.
- `/tmp/corpusbuilder-philosopher-maintenance-fixed.log`:
  **72 tests, 322 assertions**, zero failures/errors/skips.
- `/tmp/corpusbuilder-task-logging-contract-red.log`: expected failing logging
  contract before the one-line filter fix; superseded by current running check.

Standard applied only to owned new test/support files, not wholesale legacy source.
Three direct references to Rack's legacy $_REQ global in its entrypoint test remain
style warnings. A formatter loop in a nested test conditional was fixed by moving
its comparison label outside the nested stubs. No blanket suppression added.

## Remaining substantial coverage work

Previous missed-line list includes artifacts of the now-fixed global reloads; do
not assume already tested delta/Danker/name tasks remain uncovered.

- lib/tasks/shadow.rake: still the biggest file. New maintenance tests cover much
  of selection/date/population/labels/year/gender but DBpedia tasks, properties,
  locales, old ranking, mentions, exploration and some error paths remain.
- lib/tasks/shadow/work_tasks.rake (~380 previously missed), corpus.rake (~235).
- snarf.rake: remaining browser-processing tasks dic_phil, dic_phil_too, borchert,
  date-headword variants/errors and InPhO alternate/no-Wikipedia/error paths.
- scripts/test_delta_workflow.rb, test_work_based_delta.rb, debug_work_files.rb,
  sitelink.rb, works.rb, set_relevant.rb, viaf.rb and remaining Zotero script paths.
  The delta quick-test script computes its output directory one parent too high;
  work-based/debug scripts still query nonexistent direct Work#text/obsolete fields.
  Test/repair these with temporary data and controlled execution boundaries.
- Remaining controller CRUD/error paths, Name caches, query helper presentation,
  task utility/CLI branches, source/property/reference/file/resolve tasks.
- Date parser and philosopher maintenance changes have targeted green checks; new
  full-suite baseline still required. The project is not ready for migrations yet.

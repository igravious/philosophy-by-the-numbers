# Migration preparation: Plans 1 and 2

## Scope

Reconcile the existing coverage and workflow implementations, then strengthen the
regression checks needed for Plan 3. Preserve the concurrent CFP-A implementation.
The historical 95% coverage target is not yet achieved.

## Baseline — 2026-11-06

- `COVERAGE=1 bin/rake test`: 743 runs, 2172 assertions, 0 failures, 2 errors,
  3 skips; 212.05 seconds.
- SimpleCov: 33.30% (4178/12545 lines). This includes more code than the February
  baseline, so percentages are not directly comparable.
- Errors: file update contacted example.com; resource edit contacted DBpedia.
- Workflow CLI already includes nine YAML workflows, status/history, diagrams,
  an interactive interface and step-level resume.

## Work in progress

- [x] Add failing CLI regressions before fixes.
- [x] Preserve declared parameter order, defaults, literal shell arguments and
  positional Rails runner arguments.
- [x] Block dependent steps after failure or declined execution.
- [x] Invalidate previous successes after failed or interrupted reruns.
- [x] Reject duplicate/invalid dependency definitions and report corrupt history.
- [x] Correct nonexistent workflow task names and test task/argument contracts.
- [x] Make CLI failures return a failing exit status; share execution rules with TUI.
- [x] Mock controller HTTP dependencies and exercise file creation.
- [x] Cover saved-query parameter creation, update and entity selection.
- [x] Exercise composite-key STI controller routes in place of their skipped test.
- [x] Cover cumulative Saffron processing with a fake process and fix reporting defects.
- [x] Isolate the skipped metric Rake test without modifying CFP-A implementation.
- [x] Run the full suite and focused regression checks; update Plans 1/2 and the master plan.
- [x] Verify edited Ruby files under StandardRB and compare existing delta-processor style debt.
- [x] Verify `bin/corpus workflows list` and the Danker workflow dry run.

## Verification

- Full suite: `COVERAGE=1 bin/rake test TESTOPTS="--verbose --seed 23291"`:
  **785 runs, 2504 assertions, 0 failures, 0 errors, 0 skips**, 218.67 seconds.
- Coverage: **37.15% (4570/12302 lines)**. Formatting changed the executable-line
  denominator; retain the exact counts alongside the percentage.
- Final focused checks, including two later CLI-input regressions:
  **137 runs, 868 assertions, 0 failures, 0 errors, 0 skips**.
- StandardRB passes on the 20 edited Ruby files selected for formatting. The
  delta processor retains pre-existing style debt: 117 offences in the original
  file versus 116 after this pass; the small algorithm/report fixes introduce no
  new style debt. Untouched CLI files also retain existing style issues.
- `bin/corpus workflows list` and `bin/corpus exec workflow danker_pagerank --dry-run`
  both exit successfully; the dry run previews all three steps.
- Local Markdown links in the plans, master plan, audit and progress notes resolve.
- Workflow task audit: **114 application tasks**, **93 exposed tasks**, nine workflows,
  **47 pipeline steps**, **50 auxiliary steps**, **21 unexposed commands**.

Logs for this session are under `/tmp/corpusbuilder-preparation-*`.

## Changes and Behaviour

- Workflow parameters preserve declaration order, defaults and shell literals;
  Rails runner scripts receive positional values. Numbered enum choices resolve
  to their option values and EOF uses defaults.
- Failed/declined prerequisites block dependent execution. Resume retries failed
  steps and reruns dependent outputs after a prerequisite is rerun.
- CLI execution failures return exit status 1; CLI and TUI share the runner.
- Malformed history fails explicitly instead of erasing the apparent history.
- Workflow definitions reference existing tasks and match their argument contracts.
- File/resource tests use controlled responses. Composite-key STI forms and redirects
  use the base property-resource routes, and bulk saved queries have regression tests.
- Delta processing rejects empty input clearly, returns a report for one work and
  includes the convergence-triggering work in its processed-population count.
- The metric Rake test uses a private task registry and scoped stubs. Its temporary
  filesystem data is outside the real Danker directory.

## Remaining Work Before Declaring the Plans Complete

- Plan 1's original **95%** coverage gate remains open. Prioritise actual filtering,
  cross-entity queries, work-based delta selection and external integration failure
  paths; avoid padding coverage with assertions about Rails declarations.
- Audit fixture isolation for tables without direct fixture files, accounting for
  the existing STI fixtures rather than adding duplicate `shadows` fixtures.
- Review the 21 unexposed commands in
  [the task audit](../ai/migration-preparation-audit.md) and deprecate obsolete paths.
- Legacy tasks can rescue errors and exit successfully. Validate selected tasks'
  error/restart semantics before relying on unattended live workflows.
- Postconditions are descriptive, not executed checks. Resume is step-level and
  not parameter-aware; reset workflows when changing inputs or configuration.
- Coordinate metric/ranking workflow bindings with CFP-A's run/publication work.
- Broader global lint cleanup and selected live workflows remain unverified.

Neither numbered plan is marked complete, and no Ruby/Rails upgrade was started.

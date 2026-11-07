# Plan 2: Task Classification and Workflows

**Goal:** Make CorpusBuilder's application tasks discoverable and repeatable,
with explicit ordering, reliable failure reporting and tested step-level resume.

**Back to:** [Master Plan](../../MASTER_PLAN.md)

**Migration role:** Work alongside [Plan 1](PLAN-1-TEST-COVERAGE.md) to protect the
command-line workflows during [Plan 3](PLAN-3-RUBY-RAILS-MIGRATION.md).

## Current State (reconciled 2026-11-06)

The workflow implementation already exists. Extend it rather than introducing
the separate `TaskStateMachine` module and database table proposed in February.

| Component | Existing implementation |
|-----------|-------------------------|
| Entry point | `bin/corpus` |
| Definitions | Nine YAML files in `config/workflows/` |
| Model and validation | `WorkflowDefinition`, `WorkflowStep`, `StepParam` |
| Discovery | `WorkflowRegistry` |
| Execution | `WorkflowRunner` |
| Persistence | `StateTracker`, append-only JSON events in `log/corpus_workflow.log` |
| Interfaces | Thor commands and an interactive TUI |
| Inspection | Workflow help, status/history and diagrams |
| Tests | `test/lib/corpus_cli/` |

The registry audit found **114 application Rake tasks**, excluding built-in Rails
and gem tasks. The nine workflows contain **47 pipeline steps and 50 auxiliary
steps**, exposing **93 distinct application tasks**. The remaining 21 are listed
and classified in the [task audit](../ai/migration-preparation-audit.md).
Classification does not imply every task belongs in an automated pipeline.

## Workflow Inventory

| Workflow | Purpose |
|----------|---------|
| `philosopher_population` | Discover/enrich figures, import signals and calculate metrics |
| `work_discovery` | Discover/enrich works and connect them with corpus texts |
| `danker_pagerank` | Download, process and import PageRank inputs |
| `reference_integration` | Leverage reference work indices and metadata, then import coverage flags |
| `corpus_git` | Manage corpus file version control |
| `corpus_elasticsearch` | Index and inspect corpus snapshots |
| `delta_analysis` | Run progressive Saffron analysis and compare its outputs |
| `dictionary_cleanup` | Clean dictionary entries and normalise units |
| `utilities` | Independent reports and maintenance commands |

The original A-G classification remains useful for the task inventory:

- **A — Data acquisition:** external data and input imports.
- **B — Reference works:** index/metadata retrieval and coverage integration.
- **C — Metrics:** derived measures and ranking operations.
- **D — Corpus management:** corpus files, Git and Elasticsearch.
- **E — Text analysis:** Saffron and delta-of-deltas processing.
- **F — Data cleaning:** names, dates, dictionary entries and units.
- **G — Utilities/reporting:** independent inspection and maintenance.

These are documentation categories, not seven additional executable state machines.
A task can appear in several useful workflows while retaining one inventory category.

## Execution Contract

- Pipeline order follows declared prerequisites; cycles, duplicate step IDs and
  unknown prerequisites are rejected.
- Pipeline steps cannot depend on auxiliary steps that the pipeline never runs.
- A failed or declined prerequisite blocks dependent steps. Continuing after a
  failure permits independent branches only.
- A successful step is skipped on resume. Failed/interrupted reruns invalidate an
  earlier success, and rerunning a prerequisite reruns its dependent steps.
- Dry runs preview commands without executing them or recording completion.
- Parameter order follows the definition, defaults preserve `false`, Rake values
  are escaped, and Rails runner scripts receive positional arguments.
- The CLI returns a failing exit status for failed/incomplete execution and unknown
  execution targets.
- The TUI uses the same execution and dependency handling as the CLI.
- Existing direct `bin/rake` invocations continue to work.

History stores step events, not a transactional snapshot of external inputs or
parameters. Reset a workflow when changing its input population, configuration or
parameters. Resume reruns an interrupted step from its beginning; it does not resume
inside an individual Rake task. Corrupt history raises an error instead of silently
pretending no previous execution happened.

CFP-A owns metric datasets, metric runs, source-event imports and publication.
Workflow history must not replace those domain records. Review metric/ranking task
bindings as the CFP-A implementation progresses.

## Reconciliation and Regression Work

- [x] Reuse the CLI, YAML definitions and event log already in the repository.
- [x] Inventory registered application tasks separately from framework tasks.
- [x] Classify all application tasks, including those not exposed by the CLI.
- [x] Replace nonexistent task references with their actual counterparts.
- [x] Remove commands with no equivalent task instead of inventing one.
- [x] Align parameter names/order with the actual Rake argument declarations.
- [x] Add regression checks for registered task names and argument contracts.
- [x] Cover failed, declined, dry-run and resumed workflow execution.
- [x] Cover invalid definitions and malformed history.
- [x] Share CLI/TUI execution rules and expose failing process status.
- [x] Record the passing full-suite result in the preparation notes.
- [x] Complete final focused verification: 137 tests, 868 assertions, no failures/errors/skips.
- [x] Check the 20 edited Ruby files under StandardRB; record pre-existing delta-processor style debt separately.

## Remaining Work

These items remain open; the original pause/retry/full-pipeline promises are not
implemented simply because the CLI exists.

- [ ] Review the 21 unexposed tasks: retain useful commands, explicitly deprecate
      obsolete ones, and add supported commands only where needed.
- [ ] Audit task exit codes where legacy tasks rescue exceptions and continue.
      A successful subprocess exit alone cannot prove a successful import.
- [ ] Audit idempotency and restart behaviour of the mutating tasks individually.
- [ ] Define which workflow inputs require a fresh run/reset.
- [ ] Decide whether declared `postconditions` should become executable checks;
      they currently provide descriptive help only.
- [ ] Add bounded retries only for tasks that can safely be repeated.
- [ ] Define cross-workflow prerequisites without requiring every unrelated
      acquisition task to finish before any analysis can run.
- [ ] Validate representative live workflows on disposable data with their services
      available; automated tests use controlled local fixtures and commands.
- [ ] Reconcile metric calculation/ranking steps with CFP-A publication semantics
      before relying on a combined data-refresh pipeline.

## Verification Commands

```bash
bin/corpus workflows list
bin/corpus workflows show danker_pagerank
bin/corpus status show
bin/corpus exec workflow danker_pagerank --dry-run
bin/rake test TEST='test/lib/corpus_cli/*_test.rb'
bin/rake test
```

Reset a completed workflow when intentionally changing its inputs:

```bash
bin/corpus status reset WORKFLOW
```

## Completion Criteria

- Every application task has a documented classification and disposition.
- Exposed task names and positional arguments match the Rake registry.
- Ordering, failure propagation, resume and dry-run behaviour have regression tests.
- Status/history, workflow inspection and direct Rake use remain available.
- Legacy task-level error handling and restart guarantees are explicitly resolved
  for the workflows selected for live use.
- Representative workflows pass their integration checks and the full suite passes.

## Estimated Remaining Effort

The original 6-8-session estimate described building the infrastructure from
scratch. Re-estimate from the open items above after verification; do not repeat
completed implementation solely to match the February design.

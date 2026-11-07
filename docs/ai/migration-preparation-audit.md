# Migration preparation: application task audit

Audited on 2026-11-06 for [Plan 2](../plans/PLAN-2-TASK-CLASSIFICATION.md).

Application tasks are identified by actions defined under `lib/tasks/`, excluding
Rails/gem tasks. This records the checkout at audit time; it does not invoke imports,
downloads, corpus mutations or external services.

- Application tasks: **114**.
- Workflows: **9**, with **47 pipeline** and **50 auxiliary** steps.
- Distinct tasks exposed by the workflows: **93**.
- Classified tasks not exposed by the workflows: **21**.

During the coverage pass, `names:cap_no_dot` was removed: it was an unimplemented,
unexposed debug placeholder calling `Kernel#test` without arguments. The inventory
below retains its original audit entry as a historical record.

Each task appears in one classification below. Multiple workflow appearances
are reuse, not additional inventory entries. Unexposed commands remain callable
directly through `bin/rake`; review their intended use before adding them to a pipeline.

## Verification scope

Automated tests validate registered task names, argument order and workflow
execution/resume rules using local commands. They do not establish that every
legacy import, service integration or destructive operation succeeds on live data.

The old `shadow:philosopher:order` and `old_metric` tasks are legacy metric
paths. The exposed ranking tasks also require review against CFP-A publication
semantics as that implementation progresses. Repeated calculation, import and
publication are separate operations in CFP-A.

## A: Data acquisition (18)

| Task | Workflow exposure |
|------|-------------------|
| `danker:process_files` | `danker_pagerank` |
| `danker:update` | `danker_pagerank` |
| `shadow:philosopher:additional` | `philosopher_population` |
| `shadow:philosopher:danker` | `danker_pagerank`, `philosopher_population` |
| `shadow:philosopher:dbpedia` | Not exposed; review before adding |
| `shadow:philosopher:dumbprop` | Not exposed; review before adding |
| `shadow:philosopher:flesh` | `philosopher_population` |
| `shadow:philosopher:phil_labels` | `philosopher_population` |
| `shadow:philosopher:populate` | `philosopher_population` |
| `shadow:philosopher:smartprop` | Not exposed; review before adding |
| `shadow:philosopher:subject_info` | Not exposed; review before adding |
| `shadow:property:roles` | `utilities` |
| `shadow:work:by_viaf` | `work_discovery` |
| `shadow:work:populate` | `work_discovery` |
| `shadow:work:signal1` | `work_discovery` |
| `shadow:work:signal2` | `work_discovery` |
| `shadow:work:signal3` | `work_discovery` |
| `shadow:work:work_labels` | `work_discovery` |

## B: Reference work indices and metadata (10)

| Task | Workflow exposure |
|------|-------------------|
| `snarf:borchert` | `reference_integration` |
| `snarf:dic_phil` | `reference_integration` |
| `snarf:dic_phil_too` | `reference_integration` |
| `snarf:iep` | `reference_integration` |
| `snarf:inpho` | `reference_integration` |
| `snarf:odp_2nd` | `reference_integration` |
| `snarf:odp_3rd` | `reference_integration` |
| `snarf:rep` | `reference_integration` |
| `snarf:runes` | `reference_integration` |
| `snarf:sep` | `reference_integration` |

## C: Metrics and ranking (9)

| Task | Workflow exposure |
|------|-------------------|
| `shadow:philosopher:mentions` | `philosopher_population` |
| `shadow:philosopher:metric` | `philosopher_population`, `reference_integration` |
| `shadow:philosopher:new_order` | `philosopher_population` |
| `shadow:philosopher:old_metric` | Not exposed; review before adding |
| `shadow:philosopher:order` | Not exposed; review before adding |
| `shadow:philosopher:pagerank` | Not exposed; review before adding |
| `shadow:reference:pagerank` | `utilities` |
| `shadow:work:measure` | `work_discovery` |
| `shadow:work:order2` | `work_discovery` |

## D: Corpus management (27)

| Task | Workflow exposure |
|------|-------------------|
| `corpus:ES_ADD_DOC` | `corpus_elasticsearch` |
| `corpus:ES_DEL_LATEST` | Not exposed; review before adding |
| `corpus:ES_LIST` | `corpus_elasticsearch` |
| `corpus:ES_LOOK_FOR` | `corpus_elasticsearch` |
| `corpus:ES_MAKE_SNAPSHOT` | `corpus_elasticsearch` |
| `corpus:ES_NUKE` | Not exposed; review before adding |
| `corpus:ES_SCHEMA_INFO` | `corpus_elasticsearch` |
| `corpus:ES_STORE_AS_ONE_DOC` | `corpus_elasticsearch` |
| `corpus:ES_TOTAL` | `corpus_elasticsearch` |
| `corpus:GIT_BARE` | `corpus_git` |
| `corpus:GIT_CHANGED` | `corpus_git` |
| `corpus:GIT_CONFIG` | `corpus_git` |
| `corpus:GIT_DIFF` | `corpus_git` |
| `corpus:GIT_FILES` | `corpus_git` |
| `corpus:GIT_HELP` | `corpus_git` |
| `corpus:GIT_INIT` | `corpus_git` |
| `corpus:GIT_LOG` | `corpus_git` |
| `corpus:GIT_NUKE` | `corpus_git` |
| `corpus:GIT_RECORD` | Not exposed; review before adding |
| `corpus:GIT_RESET` | `corpus_git` |
| `corpus:GIT_REV` | `corpus_git` |
| `corpus:GIT_STAT1` | `corpus_git` |
| `corpus:GIT_STAT2` | `corpus_git` |
| `corpus:GIT_STATUS` | `corpus_git` |
| `corpus:GIT_TRACK` | `corpus_git` |
| `shadow:work:connect` | `work_discovery` |
| `shadow:work:expunge` | `work_discovery` |

## E: Text analysis (6)

| Task | Workflow exposure |
|------|-------------------|
| `delta_analysis:process` | Not exposed; review before adding |
| `delta_analysis:process_canonical_works` | `delta_analysis` |
| `delta_analysis:process_works` | `delta_analysis` |
| `delta_phases:calculate_deltas` | `delta_analysis` |
| `delta_phases:delta_of_deltas` | `delta_analysis` |
| `delta_phases:saffron_runs` | `delta_analysis` |

## F: Data cleaning and normalisation (16)

| Task | Workflow exposure |
|------|-------------------|
| `dictionary:clean:align_slash` | `dictionary_cleanup` |
| `dictionary:clean:brackets` | `dictionary_cleanup` |
| `dictionary:clean:grok` | `dictionary_cleanup` |
| `dictionary:clean:parens` | `dictionary_cleanup` |
| `dictionary:clean:proper` | `dictionary_cleanup` |
| `dictionary:clean:remove_slash` | `dictionary_cleanup` |
| `dictionary:clean:strip` | `dictionary_cleanup` |
| `names:bunny` | Not exposed; review before adding |
| `names:cap_no_dot` | Removed unimplemented debug placeholder after this audit |
| `names:funny` | Not exposed; review before adding |
| `names:languages` | `utilities` |
| `names:runny` | Not exposed; review before adding |
| `reference:load` | `reference_integration` |
| `shadow:philosopher:year` | Not exposed; review before adding |
| `units:all:all` | Not exposed; review before adding |
| `units:normalise` | `dictionary_cleanup` |

## G: Utilities and reporting (28)

| Task | Workflow exposure |
|------|-------------------|
| `danker:list` | `danker_pagerank` |
| `delta_analysis:create_test_works` | Not exposed; review before adding |
| `delta_analysis:list_works` | `delta_analysis` |
| `delta_analysis:show_available_works` | `delta_analysis` |
| `delta_analysis:test_saffron` | `delta_analysis` |
| `delta_phases:count_works` | `delta_analysis` |
| `downloaded:clear` | `utilities` |
| `downloaded:report` | `utilities` |
| `downloaded:uncached` | `utilities` |
| `knowledge:google` | `utilities` |
| `names:demo` | `utilities` |
| `resolve:paths` | `utilities` |
| `shadow:philosopher:capacities` | `philosopher_population` |
| `shadow:philosopher:count` | `philosopher_population` |
| `shadow:philosopher:explore1` | `philosopher_population` |
| `shadow:philosopher:explore2` | `philosopher_population` |
| `shadow:philosopher:explore3` | Not exposed; review before adding |
| `shadow:philosopher:gender` | `philosopher_population` |
| `shadow:philosopher:help` | `philosopher_population` |
| `shadow:philosopher:locale_build` | Not exposed; review before adding |
| `shadow:philosopher:locale_infer` | Not exposed; review before adding |
| `shadow:work:describe` | `work_discovery` |
| `shadow:work:show` | `work_discovery` |
| `sources:clear` | `utilities` |
| `sources:report` | `utilities` |
| `wikidata:grepify` | `utilities` |
| `wikidata:recurse` | `utilities` |
| `wikidata:wobble` | `utilities` |

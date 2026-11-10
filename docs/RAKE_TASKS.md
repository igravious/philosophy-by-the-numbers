# Rake Tasks Documentation

## Overview

The CorpusBuilder application provides comprehensive Rake tasks for building and maintaining a philosophical corpus database. Tasks are organized into several categories: data population from Wikidata, encyclopedia scraping, canonicity calculations, corpus management, and data analysis. All core tasks support configurable algorithms and comprehensive audit trails.

## Core Tasks

### `rake shadow:philosopher:metric`

**Purpose**: Calculate Philosopher measures using the V2 calculator and configured weights without creating unlinked snapshots

This task now uses the controlled dataset capture and run pipeline. It does not create unlinked snapshots or change current display values; publication remains a separate operation.

```bash
bin/rake shadow:philosopher:metric
```

### `rake shadow:philosopher:danker`

**Purpose**: Atomically import the latest processed Danker CSV for the complete Philosopher population

- Validates the entire file before opening the import transaction.
- Updates current `shadows.danker` values, using `nil` when an entity is missing from the file.
- Records typed old/new values and artifact provenance in `source_events`.
- Uses the cross-process metric operation lock.
- Does not create calculation snapshots.

```bash
bin/rake shadow:philosopher:danker
```

Conditional selections are ignored so the import remains a complete-population operation. Use a complete artifact: every omitted entity is deliberately assigned `nil`, and every subject row receives a source event, even when its numeric value is unchanged. A partial file is not an incremental overlay.

### `rake metric:import_danker[file_path,subject_type,source_version]`

Import an explicit Danker CSV or TSV artifact for Philosopher or Work. The artifact must be sorted and duplicate-free; all rows are validated before any write. Omitted entities become `nil`, never `0.0`, and the complete set of current values and source events commits atomically.

```bash
bin/rake "metric:import_danker[db/danker/latest/scores.csv,Philosopher,2026-11-06]"
```

### `rake metric:import_work_flags[file_path]`

Atomically import Work Cambridge, Borchert, and Routledge flags from the `works.json` format, with typed source events.

```bash
bin/rake "metric:import_work_flags[works.json]"
```

### `rake metric:capture[subject_type,input_run_id,selected_entity_ids,normalization_entity_ids]`

Capture an immutable dataset and its primitive input records. Omit the last three arguments for the complete subject population. Use pipe-separated IDs for small experimental captures; `input_run_id` is optional for Philosopher and defaults to the latest completed Philosopher run whose selected IDs equal the current full population. An explicit dependency may be supplied for controlled experiments. Selected IDs must be contained in normalisation IDs, although normalisation may include additional entities.

```bash
# Complete Philosopher population
bin/rake "metric:capture[Philosopher]"

# Two entities in both selected and normalization populations
bin/rake "metric:capture[Philosopher,,5484|5485,5484|5485]"

# Work using an explicit completed Philosopher dependency
bin/rake "metric:capture[Work,12]"
```

Failed captures become invalid with a failure reason and do not retain partial input records. Interrupted captures and runs are reconciled when the lock is next acquired. Dataset status, normalization context, provenance, dependencies, failures, and import events are visible at `/canonicity`.

### `rake metric:calculate[dataset_id,configuration_version,parent_run_id]`

Calculate a controlled run over a ready dataset. Configuration defaults to normalized `2.1` for Philosopher and `2.0-work` for Work. Original `2.0` is historical-only. Cross-subject configurations and source weights above 1 are rejected before run allocation; Work's check excludes genre multipliers. Runs begin at `0.7.0` independently for each subject type.

```bash
bin/rake "metric:calculate[3]"
```

### `rake metric:recalculate[subject_type,version,configuration_version]`

Create another run from the same immutable dataset with an explicit configuration and a parent run. No live inputs are refreshed. Unchanged calculator/configuration receives a patch bump; a configuration change receives a minor bump; a calculator identity change receives a major bump. Configurations must belong to the dataset's subject type.

```bash
bin/rake "metric:recalculate[Philosopher,0.7.0,2.1]"
```

### `rake metric:replay[subject_type,version]`

Recompute a completed run from its frozen calculator, configuration, dataset payloads, and dependencies. Replay verifies exact measures, selected population, normalization context, and dense ranks without writing anything.

```bash
bin/rake "metric:replay[Philosopher,0.7.0]"
```

The command prints `matches: true` only when every check matches and raises on mismatches.

### `rake metric:compare[subject_type,from_version,to_version]`

Compare two runs of one subject. The JSON report includes measure and dense-rank movement, added and missing entities, selected and normalisation population differences, normalization-context changes, and calculator/configuration differences.

```bash
bin/rake "metric:compare[Philosopher,0.8.0,0.9.0]"
```

### `rake metric:publish[subject_type,version]`

Publish a completed run only when selected, normalisation, snapshot, and current subject populations are identical and all measures and dense ranks verify. One transaction updates current `shadows.measure` and `measure_pos` values with bound ActiveRecord writes and appends the publication record. Republishing appends another record; interruption rolls back everything.

```bash
bin/rake "metric:publish[Philosopher,0.8.1]"
```

Work dependency mismatches print a warning without blocking publication. `shadow:work:order2[version]` and `shadow:philosopher:new_order[version]` are compatibility wrappers over the same service and require an explicit version; they no longer rank live values or modify snapshots.

### `rake metric:runs` and `rake metric:show[subject_type,version]`

List run identities or inspect one run and its snapshots. Run details, comparison, publication history/actions, and read-only replay are also available at `/canonicity`; dashboard snapshots are paginated 100 at a time.

### `rake danker:update`

**Purpose**: Download and manage latest danker ranking data

**Features**:
- Downloads latest danker data from external source
- Creates versioned directory structure (`db/danker/YYYY-MM-DD/`)
- Maintains `latest` symlink to current version
- Handles data validation and error checking

**Directory Structure**:
```
db/danker/
├── 2024-10-04/
│   └── 2024-10-04.all.links.c.alphanum.csv
├── 2024-10-05/
│   └── 2024-10-05.all.links.c.alphanum.csv
└── latest -> 2024-10-05
```

**Usage**:
```bash
bin/rake danker:update
```

## Algorithm Configuration

### Weight Management

Weights are stored in the `canonicity_weights` table with support for:
- Multiple algorithm versions
- Active/inactive weight sets
- Descriptive metadata for each source
- Precision decimal storage (8,6)

### Adding New Algorithm Versions

```ruby
# Create new weight set
weights_v21 = [
  { source_name: 'stanford', weight_value: 0.18, description: 'Stanford Encyclopedia (updated)' },
  { source_name: 'routledge', weight_value: 0.22, description: 'Routledge Encyclopedia (updated)' },
  # ... other weights
]

weights_v21.each do |weight|
  CanonicityWeights.create!(
    algorithm_version: '2.1',
    source_name: weight[:source_name],
    weight_value: weight[:weight_value],
    description: weight[:description],
    active: true
  )
end
```

### Using Different Algorithm Versions

```bash
# In rake task or console
philosopher.calculate_canonicity_measure(algorithm_version: '2.1')
```

## Testing Strategy

### Isolated Testing Approach

The rake tasks are tested using an isolated approach that avoids processing the full 13,000+ philosopher database:

1. **Mock Data Creation**: Tests create small sets of test philosophers with `entity_id > 9000`
2. **Method Overriding**: Strategic overriding of `Philosopher.order` and similar methods to limit scope
3. **Cleanup**: Automatic cleanup of test data in setup/teardown
4. **Verification**: Verification of algorithm behavior, snapshot creation, and configuration usage

### Test Coverage

**MetricSnapshot Tests** (`test/models/metric_snapshot_test.rb`):
- Snapshot creation and retrieval
- Weight configuration capture
- Historical data integrity

**Philosopher Canonicity Tests** (`test/models/philosopher_canonicity_test.rb`):
- Algorithm calculation accuracy
- Edge case handling (zero mentions, missing data)
- Source weight application
- Normalized vs. raw measure handling

**Rake Task Tests** (`test/models/shadow_rake_tasks_test.rb`):
- Task execution without full database iteration
- Snapshot creation verification
- Configuration usage validation

**Danker Update Tests** (`test/models/danker_update_rake_task_test.rb`):
- Data structure validation
- Error handling
- File format verification

### Running Tests

```bash
# Run all canonicity-related tests
bin/rake test TEST=test/models/metric_snapshot_test.rb TEST=test/models/philosopher_canonicity_test.rb TEST=test/models/shadow_rake_tasks_test.rb TEST=test/models/danker_update_rake_task_test.rb

# Run individual test suites
bin/rake test TEST=test/models/shadow_rake_tasks_test.rb
```

## Performance Considerations

### Memory Management
- Progress bars prevent memory buildup during large iterations
- Database queries use efficient ordering and batching
- Selective snapshot creation (only when values change)

### Disk I/O Optimization
- Danker data cached in versioned directories
- Symlinks provide fast access to latest data
- CSV parsing uses system tools (`look` command) for efficiency

### Database Optimization
- Proper indexing on philosopher lookup fields
- Batch snapshot creation with single transaction per philosopher
- Selective updates (only changed danker scores)

## Troubleshooting

### Common Issues

**No Danker Data Found**:
```bash
ERROR: No danker data found. Run 'rake danker:update' first.
```
Solution: Run `bin/rake danker:update` to download latest data

**Missing Algorithm Weights**:
```bash
NoMethodError: undefined method `[]' for nil:NilClass
```
Solution: Ensure weights exist for the algorithm version being used

**Large Memory Usage**:
Solution: Run with `FORCE=true` to enable progress bars and memory optimization

### Debugging

Enable verbose output:
```bash
# Show detailed calculation output
bin/rake shadow:metric FORCE=false

# Show progress without progress bar
bin/rake shadow:danker FORCE=false
```

Check algorithm configuration:
```ruby
# In rails console
CanonicityWeights.active.for_version('2.0').each do |w|
  puts "#{w.source_name}: #{w.weight_value} (#{w.description})"
end
```

## Future Enhancements

### Planned Features
- Parallel processing for large datasets
- Delta calculations (only process changed philosophers)
- Web interface for algorithm configuration
- Automated danker data updates via cron
- Algorithm performance comparison reports

### Extensibility Points
- Additional algorithm versions through weight configuration
- Custom calculation methods via strategy pattern
- Integration with external ranking services
- Advanced audit trail querying and reporting
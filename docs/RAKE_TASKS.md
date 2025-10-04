# Rake Tasks Documentation

## Overview

The CorpusBuilder application provides several rake tasks for managing philosopher canonicity calculations and danker (PageRank-style) data imports. All tasks support configurable algorithms and comprehensive audit trails.

## Core Tasks

### `rake shadow:metric`

**Purpose**: Calculate canonicity measures for all philosophers using the Linear Weighted Combination algorithm

**Features**:
- Uses configurable weights from `canonicity_weights` table (no hardcoded constants)
- Creates `MetricSnapshot` records for each calculation with full audit trail
- Supports algorithm versioning for comparison and evolution
- Integrates with danker data versioning
- Progress tracking with estimated completion times

**Usage**:
```bash
bin/rake shadow:metric
```

**Output**:
- Progress bar showing completion status
- Algorithm version and danker data information
- Per-philosopher calculation results (when run without progress bar)
- Summary of snapshots created

**Audit Trail**:
- Each calculation creates a `MetricSnapshot` with:
  - Exact weights configuration used (JSON)
  - Algorithm version
  - Danker data version and file
  - Calculation timestamp
  - Computed measure value

### `rake shadow:danker[condition]`

**Purpose**: Import latest danker (PageRank) scores for philosophers

**Features**:
- Automatically checks for latest danker data
- Updates philosopher danker scores from CSV files
- Creates snapshots only when scores change
- Supports conditional processing with SQL-like conditions
- Integrates with danker data versioning system

**Usage**:
```bash
# Process all philosophers
bin/rake shadow:danker

# Process with condition
bin/rake shadow:danker["entity_id > 1000"]
```

**Data Flow**:
1. Checks for latest danker data in `db/danker/latest/`
2. Reads CSV file with format: `Q{entity_id},{score}`
3. Updates philosopher records where scores differ
4. Creates `MetricSnapshot` for changed records with `algorithm_version: 'danker_import'`

**Audit Trail**:
- Snapshots created only for changed danker scores
- Records old and new values in notes field
- Links to specific danker data file and version

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
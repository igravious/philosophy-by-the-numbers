# Testing Strategy for CorpusBuilder

## Overview

CorpusBuilder uses a comprehensive testing strategy that addresses the unique challenges of testing a legacy Rails application with a large production database (13,000+ philosopher records) and complex canonicity calculations.

## Testing Philosophy

### Test-Driven Development (TDD)
- **Write tests first** before implementing functionality
- **Red-Green-Refactor** cycle for all new features
- **Comprehensive edge case coverage** for mathematical calculations
- **Integration tests** that verify end-to-end functionality

### Isolated Testing Approach
Given the large development dataset and legacy fixture constraints, tests use **isolated database state and explicitly created scenario data**:

1. **Use the declared fixtures**: `test/test_helper.rb` loads `fixtures :all`; do not disable them or assume the tables are empty
2. **Create focused scenario data**: Generate only the additional entities needed for a test, using helpers such as `create_test_philosopher`, `create_test_work`, and `create_completed_metric_run`
3. **Avoid identity conflicts**: Use high entity IDs where appropriate and account for fixture Philosophers and Works in full-population cases
4. **Isolate the database**: Use the project's test database URL and never run tests against `db/development.sqlite3`
5. **Automatic cleanup**: Transactions and setup/teardown preserve independence between tests

## Test Structure

### Model Tests

#### MetricSnapshot Tests (`test/models/metric_snapshot_test.rb`)
**Purpose**: Verify the audit trail and snapshot functionality

**Key Tests**:
- Snapshot creation with proper associations
- Weight configuration capture in JSON format
- Historical data retrieval and querying
- Philosopher association integrity

**Isolation Strategy**: Use the declared empty metric fixtures and create explicit run/input records as needed. Run-linked snapshots use `shadow_id` and `shadow_type`; historical unlinked snapshots remain valid.

#### Pure V2 Calculator Tests (`test/lib/canonicity_philosopher_v2_test.rb` and `test/lib/canonicity_work_v2_test.rb`)
**Purpose**: Verify exact calculator outputs independently of ActiveRecord, including normalized and display-scaled measures.

**Key Tests**:
- Source weights, all-bonus, PhilPapers, and genre behaviour
- Role suppression and maxima that include suppressed philosophers
- Null versus zero Danker and mention handling
- Work author adjustment and missing-author validation
- Zero-denominator guards and finite outputs
- Genre applied exactly once

#### Controlled Run and Publication Tests

- `test/lib/canonicity_dataset_capture_test.rb`: coherent inputs, selected/normalisation containment, source provenance, and Work dependencies
- `test/lib/canonicity_metric_run_calculator_test.rb`: controlled calculation, dense ranks, failure recovery, subject/configuration validation, and Philosopher/Work source-weight pre-flight
- `test/lib/canonicity_replay_test.rb`: exact read-only replay and mismatch reporting
- `test/lib/canonicity_publication_test.rb`: full-population eligibility, exact float publication, rollback, republishing, and dependency warnings
- `test/lib/canonicity_run_comparison_test.rb` and `test/lib/metric_tasks_test.rb`: movement reports and real rake-task behavior, including CLI warnings
- `test/controllers/canonicity_controller_test.rb`: dashboard evidence, batched eligibility queries, comparison, publication, and 100-row snapshot pagination

Zero-score tests must distinguish raw zero, missing `nil`, and derived zero. A zero measure is not a philosophical classification; audit its cause using the frozen payload and calculation context rather than asserting that an entity does or does not belong in the corpus.

#### Philosopher Canonicity Tests (`test/models/philosopher_canonicity_test.rb`)
**Purpose**: Verify the Linear Weighted Combination algorithm accuracy

**Key Tests**:
- Algorithm returns values in expected range (0.0 to 1.0)
- Source weights properly applied from database configuration
- Edge cases: zero mentions, nil danker scores, no sources
- Snapshot creation with correct algorithm version and weights

**Data Management**:
```ruby
def setup
  philosophers = Philosopher.where("entity_id >= 9100 AND entity_id < 9200")
  MetricSnapshot.where(shadow_id: philosophers.pluck(:id), shadow_type: "Philosopher").delete_all
  philosophers.delete_all

  seed_canonicity_weights unless CanonicityWeights.exists?(algorithm_version: "2.1")
end
```

#### Rake Task Tests (`test/models/shadow_rake_tasks_test.rb`)
**Purpose**: Verify rake task functionality without processing full database

**Key Innovation - Method Override Strategy**:
```ruby
# Override Philosopher.order to limit scope to test data
original_method = Philosopher.method(:order)
Philosopher.define_singleton_method(:order) do |*args|
  if args.first == :entity_id
    where("entity_id > 9000").order(*args)  # Only test data
  else
    original_method.call(*args)             # Normal behavior
  end
end

# Run task with limited scope
Rake::Task['shadow:metric'].invoke

# Restore original method
Philosopher.define_singleton_method(:order, original_method)
```

**Verification Points**:
- Snapshots created for test philosophers only
- Algorithm configuration properly loaded from database
- Progress tracking and error handling work correctly

#### Danker Update Tests (`test/models/danker_update_rake_task_test.rb`)
**Purpose**: Verify danker data management without external dependencies

**Mock Strategy**:
- **File System Mocking**: Create temporary danker data directories
- **Command Mocking**: Mock external `look` command for CSV parsing
- **Network Isolation**: Skip actual download tests, focus on data processing logic

## Test Data Management

### Test Data Creation Strategy

#### Minimal Data Sets
Create only the data needed for specific test scenarios:

```ruby
# High canonicity philosopher (many sources)
high_canon_philosopher = Philosopher.create!(
  entity_id: 9990,
  mention: 200,
  danker: 0.8,
  inphobool: true,
  stanford: true,
  cambridge: true,
  routledge: true,
  oxford: true
)

# Low canonicity philosopher (few sources)  
low_canon_philosopher = Philosopher.create!(
  entity_id: 9991,
  mention: 50,
  danker: 0.2,
  inphobool: false,
  stanford: false,
  cambridge: false,
  routledge: false,
  oxford: false
)
```

#### Weight Configuration Seeding
Ensure algorithm weights are available for testing:

```ruby
def seed_canonicity_weights
  weights_v2 = [
    { source_name: 'stanford', weight_value: 0.10, description: 'Stanford Encyclopedia of Philosophy' },
    { source_name: 'routledge', weight_value: 0.17, description: 'Routledge Encyclopedia of Philosophy' },
    # ... other weights
  ]
  
  weights_v2.each do |weight|
    CanonicityWeights.create!(
      algorithm_version: '2.1',
      source_name: weight[:source_name], 
      weight_value: weight[:weight_value],
      description: weight[:description],
      active: true
    )
  end
end
```

### Cleanup Strategy

#### Comprehensive Teardown
```ruby
def teardown
  # Clean up test data using high entity_id filter
  MetricSnapshot.where("philosopher_id > 9000").delete_all
  Philosopher.where("entity_id > 9000").delete_all
  
  # Clean up any rake task state
  Rake::Task['shadow:metric'].reenable if Rake::Task.task_defined?('shadow:metric')
end
```

## Edge Case Testing

### Mathematical Edge Cases

#### Zero Values
```ruby
test "philosopher with zero mention gets minimum measure" do
  philosopher = Philosopher.create!(
    entity_id: 9993,
    mention: 0,  # Zero mentions
    danker: 0.1,
    # ... source flags
  )
  
  result = philosopher.calculate_canonicity_measure
  assert result >= 0, "Zero mention should not produce negative measure"
end
```

#### Missing Data
```ruby
test "philosopher with nil danker gets minimum rank" do
  philosopher = Philosopher.create!(
    entity_id: 9994,
    mention: 100,
    danker: nil,  # Missing danker score
    # ... source flags
  )
  
  result = philosopher.calculate_canonicity_measure
  assert result >= 0, "Nil danker should not produce negative measure"
end
```

#### No Sources
```ruby
test "philosopher with no sources gets zero measure" do
  philosopher = Philosopher.create!(
    entity_id: 9995,
    mention: 100,
    danker: 0.5,
    # All source flags false
    inphobool: false,
    stanford: false,
    # ... other sources false
  )
  
  result = philosopher.calculate_canonicity_measure
  assert_equal 0.0, result, "No sources should result in zero canonicity"
end
```

## Integration Testing

### Rake Task Integration
Tests verify that rake tasks work end-to-end but with limited scope:

1. **Task Loading**: Verify rake tasks load properly
2. **Scoped Execution**: Run tasks on test data only
3. **Output Verification**: Check snapshots, database updates, and audit trails
4. **Error Handling**: Verify graceful handling of edge cases

### Algorithm Configuration Integration
Tests verify that the configurable weight system works properly:

1. **Weight Loading**: Algorithm loads weights from database
2. **Version Handling**: Different algorithm versions use correct weights
3. **Audit Trail**: Snapshots capture exact weights used
4. **Backward Compatibility**: Historical snapshots remain valid

## Performance Testing Considerations

### Memory Usage
- **Progress Bar Testing**: Verify memory doesn't grow during iteration
- **Cleanup Verification**: Ensure test data doesn't accumulate
- **Batch Processing**: Test snapshot creation in batches

### Database Query Optimization
- **Index Usage**: Verify queries use appropriate indexes
- **N+1 Prevention**: Check for efficient association loading  
- **Transaction Scope**: Verify appropriate transaction boundaries

## Running the Test Suite

### Individual Test Files
```bash
# Run canonicity algorithm tests
bin/rake test TEST=test/models/philosopher_canonicity_test.rb

# Run snapshot tests  
bin/rake test TEST=test/models/metric_snapshot_test.rb

# Run rake task tests
bin/rake test TEST=test/models/shadow_rake_tasks_test.rb

# Run danker update tests
bin/rake test TEST=test/models/danker_update_rake_task_test.rb
```

### Focused Canonicity Suite

Repeated `TEST=` assignments do not select multiple files. Load multiple test files through one Ruby process instead:

```bash
RAILS_ENV=test DATABASE_URL=sqlite3:/tmp/corpusbuilder-coverage-tests.sqlite3 \
  bin/bundle exec ruby -Itest -e 'ARGV.each { |file| require File.expand_path(file) }' \
  test/models/metric_snapshot_test.rb \
  test/models/philosopher_canonicity_test.rb \
  test/lib/canonicity_metric_run_calculator_test.rb \
  test/lib/canonicity_publication_test.rb \
  test/lib/canonicity_run_comparison_test.rb \
  test/controllers/canonicity_controller_test.rb
```

### Full Suite and Test Environment Setup
```bash
RAILS_ENV=test DATABASE_URL=sqlite3:/tmp/corpusbuilder-coverage-tests.sqlite3 bin/rake db:test:prepare
RAILS_ENV=test DATABASE_URL=sqlite3:/tmp/corpusbuilder-coverage-tests.sqlite3 bin/rake test
bin/rake test TEST=test/models/philosopher_canonicity_test.rb TESTOPTS="-v"
```

Do not run separate test processes concurrently against the same SQLite database. Latest full verification: 1,142 runs, 4,438 assertions, 0 failures, 0 errors, 0 skips.

## Debugging Test Issues

### Common Problems

#### Fixture Conflicts
**Symptom**: `UNIQUE constraint failed: fyles.URL`
**Solution**: Account for declared fixtures and choose nonconflicting identities; do not assume fixtures are disabled or tables are empty

#### Missing Algorithm Weights  
**Symptom**: `NoMethodError: undefined method '[]' for nil:NilClass`
**Solution**: Verify `seed_canonicity_weights` runs in test setup

#### Rake Task State
**Symptom**: `RuntimeError: Don't know how to build task`
**Solution**: Use `Rake::Task['task_name'].reenable` in teardown

### Debug Techniques

#### Output Capture
```ruby
def capture_output
  old_stdout, old_stderr = $stdout, $stderr
  $stdout, $stderr = StringIO.new, StringIO.new
  yield
  { stdout: $stdout.string, stderr: $stderr.string }
ensure
  $stdout, $stderr = old_stdout, old_stderr
end
```

#### Algorithm Debugging
```ruby
# Print intermediate calculation values
result = philosopher.calculate_canonicity_measure
puts "Mention: #{philosopher.mention}"
puts "Danker: #{philosopher.danker}"  
puts "Source contributions: #{source_contributions}"
puts "Final result: #{result}"
```

## Future Testing Enhancements

### Planned Improvements
- **Performance benchmarking** for algorithm changes
- **Load testing** with larger test datasets
- **Integration testing** with external danker data sources
- **Visual regression testing** for canonicity trends
- **Automated testing** in CI/CD pipeline

### Testing Tool Integration
- **Factory patterns** for complex test data creation
- **Database cleaner** for more sophisticated cleanup
- **VCR/WebMock** for external API testing
- **SimpleCov** for code coverage reporting
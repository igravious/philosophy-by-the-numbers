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
Given the large production dataset and broken legacy fixtures, we use an **isolated testing strategy**:

1. **Bypass Legacy Fixtures**: Disable automatic fixture loading to avoid constraint violations
2. **Create Clean Test Data**: Generate minimal test data sets for specific test scenarios  
3. **Use High Entity IDs**: Test philosophers use `entity_id > 9000` to avoid conflicts
4. **Automatic Cleanup**: Comprehensive setup/teardown ensures test isolation

## Test Structure

### Model Tests

#### MetricSnapshot Tests (`test/models/metric_snapshot_test.rb`)
**Purpose**: Verify the audit trail and snapshot functionality

**Key Tests**:
- Snapshot creation with proper associations
- Weight configuration capture in JSON format
- Historical data retrieval and querying
- Philosopher association integrity

**Isolation Strategy**:
```ruby
# Disable fixtures entirely
self.use_transactional_fixtures = false
self.use_instantiated_fixtures = false

def self.fixtures(*args)
  # Do nothing to prevent fixture loading
end
```

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
  # Clean up any existing test data
  MetricSnapshot.where("philosopher_id > 9000").delete_all
  Philosopher.where("entity_id > 9000").delete_all
  
  # Seed algorithm weights if needed
  seed_canonicity_weights unless CanonicityWeights.exists?(algorithm_version: '2.0')
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
    { source_name: 'stanford', weight_value: 0.15, description: 'Stanford Encyclopedia of Philosophy' },
    { source_name: 'routledge', weight_value: 0.25, description: 'Routledge Encyclopedia of Philosophy' },
    # ... other weights
  ]
  
  weights_v2.each do |weight|
    CanonicityWeights.create!(
      algorithm_version: '2.0',
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

### Full Canonicity Test Suite
```bash
bin/rake test TEST=test/models/metric_snapshot_test.rb TEST=test/models/philosopher_canonicity_test.rb TEST=test/models/shadow_rake_tasks_test.rb TEST=test/models/danker_update_rake_task_test.rb
```

### Test Environment Setup
```bash
# Prepare test database (includes migrations and schema)
bin/rake db:test:prepare

# Run tests with verbose output
bin/rake test TEST=test/models/philosopher_canonicity_test.rb TESTOPTS="-v"
```

## Debugging Test Issues

### Common Problems

#### Fixture Conflicts
**Symptom**: `UNIQUE constraint failed: fyles.URL`
**Solution**: Ensure fixtures are disabled and test uses isolated data

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
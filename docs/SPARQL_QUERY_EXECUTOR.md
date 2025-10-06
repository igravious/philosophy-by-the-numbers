# SPARQL Query Execution Utility

The `Wikidata::QueryExecutor` module provides centralized SPARQL query execution with enhanced logging, timing, error handling, and progress indication.

## Features

- **Comprehensive Logging**: All queries are logged with timing, result counts, and metadata
- **Progress Indication**: Visual progress spinner for long-running queries
- **Automatic Retry Logic**: Built-in retry with exponential backoff for timeout errors
- **Error Handling**: Standardized error handling and reporting
- **Performance Monitoring**: Query timing and result metrics
- **Debug Support**: Integration with `SPARQL_DEBUG` and `SPARQL_LOG` environment variables

## Usage

### Full-Featured Query Execution

For important or large queries that need robust error handling:

```ruby
results = Wikidata::QueryExecutor.execute(
  query_string, 
  'query_name',
  {
    task_name: 'my_rake_task',
    metadata: { description: 'Population query', version: '2.0' },
    max_retries: 5,
    show_spinner: true
  }
)
```

### Simple Query Execution

For quick queries where full error handling isn't needed:

```ruby
results = Wikidata::QueryExecutor.execute_simple(
  query_string, 
  'simple_query',
  {
    task_name: 'my_task',
    log_query: true  # Optional: log the query details
  }
)
```

### Convenience Methods

Pre-configured methods for common operations:

```ruby
# Execute the main philosopher population query
philosophers = Wikidata::QueryExecutor.execute_philosopher_query

# Find philosopher by Wikidata entity ID
philosopher = Wikidata::QueryExecutor.find_philosopher_by_id('Q5891', {
  task_name: 'my_task'
})

# Find philosopher by name
philosopher = Wikidata::QueryExecutor.find_philosopher_by_name('Aristotle', {
  task_name: 'name_lookup'
})

# Execute philosophical works queries
works = Wikidata::QueryExecutor.execute_philosophical_works_query
works_by_philosophers = Wikidata::QueryExecutor.execute_works_by_philosophers_query

# Get entity attributes
attributes = Wikidata::QueryExecutor.execute_entity_attributes_query('Q5891')

# Execute hits/filter queries
hits = Wikidata::QueryExecutor.execute_hits_query('Q5891', 'some_filter_expression')

# Performance monitoring
stats = Wikidata::QueryExecutor.performance_stats
puts "Total queries: #{stats[:total_queries]}"
puts "Average duration: #{stats[:avg_duration]}ms"
puts "Fastest query: #{stats[:fastest_query][:name]} (#{stats[:fastest_query][:duration]}ms)"
```

## Options

### Main Execute Method Options

- `task_name` (String): Name of the rake task calling this query
- `metadata` (Hash): Additional metadata to include in logs
- `max_retries` (Integer): Number of retry attempts (default: 3)
- `show_spinner` (Boolean): Whether to show progress spinner (default: true)

### Simple Execute Method Options

- `task_name` (String): Name of the rake task calling this query
- `log_query` (Boolean): Whether to log query details (default: false)

## Logging

The utility integrates with the existing logging infrastructure:

- **SPARQL Query Log**: `log/sparql_queries.log` - Contains query details, metadata, timestamps
- **Task Output Log**: `log/task_output.log` - Contains execution results, timing, error messages
- **Console Output**: Real-time progress and results displayed to console

### Environment Variables

- `SPARQL_DEBUG=true`: Enable detailed debugging output
- `SPARQL_LOG=true`: Enable query logging to files

## Error Handling

### Automatic Retry Logic

The utility automatically retries queries that fail with `Net::ReadTimeout`:

1. Progressive backoff: 5s, 10s, 15s delays between retries
2. Configurable retry count (default: 3 attempts)
3. Comprehensive logging of retry attempts
4. Final error reporting if all retries fail

### Error Types Handled

- `Net::ReadTimeout`: Automatic retry with backoff
- Other exceptions: Logged and re-raised for caller handling

## Integration with Existing Code

### Before (Old Pattern)
```ruby
require 'knowledge'
include Knowledge
w = Knowledge::Wikidata::Client.new

begin
  res = w.query(SOME_QUERY)
  puts "Query completed with #{res.length} results"
rescue Net::ReadTimeout => e
  puts "Query timed out: #{e.message}"
  # Manual retry logic...
end
```

### After (New Pattern)
```ruby
require_relative '../wikidata/query_executor'

res = Wikidata::QueryExecutor.execute(
  SOME_QUERY,
  'descriptive_query_name',
  {
    task_name: 'my_rake_task',
    metadata: { purpose: 'data refresh' }
  }
)
```

## Performance Benefits

1. **Centralized Timing**: All queries are automatically timed and logged
2. **Consistent Error Handling**: No need to duplicate retry logic across tasks
3. **Progress Indication**: Visual feedback for long-running operations
4. **Debug Integration**: Easy to enable/disable detailed logging across all queries
5. **Metadata Tracking**: Structured logging for better debugging and monitoring

## Migration Guide

To migrate existing query calls:

1. Add `require_relative '../wikidata/query_executor'` to your rake task
2. Replace direct `client.query(string)` calls with `QueryExecutor.execute(string, name, options)`
3. Remove manual retry logic and progress indicators
4. Use convenience methods where applicable
5. Add appropriate `task_name` and `metadata` for better logging

This provides a significant improvement in code organization, debugging capabilities, and user experience across all SPARQL operations.

## Performance Monitoring

The QueryExecutor includes built-in performance monitoring capabilities:

### Real-time Monitoring
Every query execution automatically logs:
- Query name and execution time
- Result count and success/failure status  
- Task context and metadata
- Retry attempts and error details

### Performance Statistics
Access aggregated performance data:

```ruby
stats = Wikidata::QueryExecutor.performance_stats

# Available metrics:
stats[:total_queries]     # Total number of queries executed
stats[:avg_duration]      # Average query duration in milliseconds
stats[:total_results]     # Total results returned across all queries
stats[:fastest_query]     # { duration: ms, name: query_name }
stats[:slowest_query]     # { duration: ms, name: query_name }
stats[:query_counts]      # Hash of query_name => execution_count
```

### Performance Optimization
Use the stats to identify:
- Slow queries that need optimization
- Most frequently executed queries for caching candidates
- Query patterns and usage trends
- Performance regressions over time

The performance data is automatically collected from the task output logs, providing historical performance tracking across all SPARQL operations.
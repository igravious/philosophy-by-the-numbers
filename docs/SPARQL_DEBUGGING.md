# SPARQL Query Debugging Guide

This document explains how to debug SPARQL queries and Wikidata access issues in CorpusBuilder.

## Environment Variables

### SPARQL_DEBUG=true
Enables detailed console output of all SPARQL queries before execution.

**Usage:**
```bash
SPARQL_DEBUG=true bin/rake shadow:philosopher:populate
```

**Output:**
- Shows the complete SPARQL query with proper formatting
- Includes timestamp and method context
- Displays query parameters and substitutions
- Perfect for debugging query syntax and logic

### SPARQL_LOG=true
Logs all SPARQL queries to a file for analysis.

**Usage:**
```bash
SPARQL_LOG=true bin/rake shadow:philosopher:populate
```

**Output File:** `log/sparql_queries.log`

### Combined Usage
Enable both console debugging and file logging:

```bash
SPARQL_DEBUG=true SPARQL_LOG=true bin/rake shadow:philosopher:populate
```

## Debugging Network Timeouts

When you see `Net::ReadTimeout` errors:

1. **First, examine the query:**
   ```bash
   SPARQL_DEBUG=true bin/rake shadow:philosopher:populate
   ```

2. **Test the query manually** at https://query.wikidata.org/

3. **Check query complexity:**
   - Look for multiple `UNION` clauses
   - Check for unbounded `OPTIONAL` patterns
   - Verify `LIMIT` clauses are present

4. **Monitor query execution time:**
   - Wikidata SPARQL endpoint has a 60-second timeout
   - Complex queries may need optimization

## Common Issues & Solutions

### Query Too Complex
**Problem:** Large SPARQL queries timeout
**Solution:** Break into smaller queries or add more specific filters

### Missing LIMIT Clause
**Problem:** Query returns too many results
**Solution:** Add `LIMIT 10000` or similar constraint

### Multiple UNION Operations
**Problem:** Complex union queries are slow
**Solution:** Split into separate queries and combine results

## Example Debug Session

```bash
# Enable debugging
export SPARQL_DEBUG=true
export SPARQL_LOG=true

# Run the populate task
bin/rake shadow:philosopher:populate

# Check the generated query
cat log/sparql_queries.log

# Test timeout with a smaller query first
bin/rake shadow:philosopher:populate[limit=5]
```

## Query Analysis

After capturing queries in the log file, you can:

1. **Copy query to Wikidata Query Service:** https://query.wikidata.org/
2. **Check execution time** in the browser
3. **Optimize with additional filters** if needed
4. **Test with smaller result sets** first

## Performance Tips

- Always test new queries with `LIMIT 100` first
- Use specific property filters rather than broad searches
- Monitor the `log/sparql_queries.log` file size
- Clear log file periodically: `> log/sparql_queries.log`

## Log File Management

The SPARQL log file will grow over time. Manage it with:

```bash
# Clear the log
> log/sparql_queries.log

# View recent queries
tail -50 log/sparql_queries.log

# Search for specific queries
grep -A 10 "populate_philosophers" log/sparql_queries.log
```
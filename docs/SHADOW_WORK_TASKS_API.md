# Shadow Work Tasks API Documentation

## Overview

The `shadow:work` namespace provides a comprehensive set of rake tasks for managing philosophical works in the CorpusBuilder system. These tasks integrate with Wikidata to discover, import, analyze, and maintain philosophical works and their relationships to philosophers and texts.

## Architecture

### Core Components

- **Shadow Table**: Uses Single Table Inheritance (STI) to store both philosophers and works
- **Work Model**: Represents philosophical works with metadata from Wikidata
- **Expression Model**: Links philosophers to their works (many-to-many relationship)
- **Wikidata Integration**: SPARQL queries to discover and enrich work data
- **Text Integration**: Connects works to actual text files in the corpus

### Key Relationships

```
Philosopher (Shadow) ←→ Expression ←→ Work (Shadow)
                                         ↓
                                     Text (actual files)
```

## Task Categories

### 1. Discovery and Investigation Tasks

#### `shadow:work:show[condition, count]`

**Purpose**: Query and display philosophical works from Wikidata without importing them.

**Parameters**:
- `condition`: Query type (`works1` or `works2`)
- `count`: Optional - if provided, shows debug info instead of full listing

**Modes**:
- **`works1`**: Notable works BY philosophers
  - Uses `THESE_WORKS_BY_PHILOSOPHERS` SPARQL query
  - Finds works authored by people classified as philosophers
  - Includes P800 (notable work) and P50 (author) relationships
  - Excludes visual arts, TED talks, editions
  
- **`works2`**: Works classified as philosophical works
  - Uses `THESE_PHILOSOPHICAL_WORKS` SPARQL query  
  - Finds works with genre = philosophy or branch of philosophy
  - Includes subclassifications up to 2 levels deep

**Usage**:
```bash
# Show notable works by philosophers
bin/rake shadow:work:show[works1]

# Show works classified as philosophical
bin/rake shadow:work:show[works2]

# Show count only
bin/rake shadow:work:show[works1,1]
```

**Output Format**:
```
[index] [sitelinks] [work_entity] by [philosopher_entity] "Work Title" Work Type
```

### 2. Data Population Tasks

#### `shadow:work:populate[condition]`

**Purpose**: Import philosophical works from Wikidata into the local Shadow table.

**Parameters**:
- `condition`: Query type (`works1` or `works2`) - same as `show` task

**Process**:
1. Executes SPARQL query to get work data
2. For each work found:
   - Looks up the philosopher in local database
   - Creates new `Work` record with entity_id and linkcount
   - Creates `Expression` record linking philosopher to work
   - Handles duplicate prevention

**Usage**:
```bash
# Import notable works by philosophers
bin/rake shadow:work:populate[works1]

# Import works classified as philosophical
bin/rake shadow:work:populate[works2]
```

**Database Changes**: ✅ **WRITES DATA** - Creates Work and Expression records

### 3. Enrichment and Metadata Tasks

#### `shadow:work:work_labels[condition, execute]`

**Purpose**: Update labels and names for works associated with specific philosophers.

**Parameters**:
- `condition`: Philosopher entity ID (`Q123`) or internal ID (`123`)
- `execute`: Execution flag

**Usage**:
```bash
# Update labels for all works by philosopher Q123
bin/rake shadow:work:work_labels[Q123]

# Update labels for philosopher with internal ID 456
bin/rake shadow:work:work_labels[456]
```

#### `shadow:work:viaf[condition]`

**Purpose**: Populate Work records using philosopher VIAF (Virtual International Authority File) data.

**Usage**:
```bash
bin/rake shadow:work:viaf[condition]
```

#### `shadow:work:signal1`

**Purpose**: Gather Britannica and PhilPapers signal data for works.

#### `shadow:work:signal2`

**Purpose**: Gather mentioning/citation data for works.

#### `shadow:work:signal3`

**Purpose**: Set genre classifications for works.

### 4. Analysis and Quality Tasks

#### `shadow:work:measure`

**Purpose**: Calculate and analyze measures/metrics for philosophical works.

#### `shadow:work:order2`

**Purpose**: Perform ordering analysis on works.

#### `shadow:work:describe`

**Purpose**: Analyze and describe the properties/predicates found in work data.

**Process**:
- Executes DESCRIBE queries for each work entity
- Collects statistics on predicates used
- Outputs frequency analysis of properties

#### `shadow:work:connect`

**Purpose**: Connect Works in the Shadow table to actual Text files in the corpus.

**Process**:
1. Gets philosophers ordered by measure (canonicity)
2. For each philosopher:
   - Finds their works from Expression relationships
   - Attempts to match work labels to Text records
   - Reports connection statistics
3. Cross-references with Writing/Author relationships

**Output**: Lists matched texts with file IDs and connection ratios

#### `shadow:work:expunge`

**Purpose**: Remove works that are definitively not wanted in the corpus.

### 5. Utility Functions

#### `deez_wurks(query)`

**Internal function** used by populate tasks:
- Executes SPARQL queries
- Processes results and creates database records
- Handles progress tracking and error reporting

## Data Flow

### Discovery → Import → Enrichment → Analysis

1. **Discovery**: Use `show` tasks to explore available works
2. **Import**: Use `populate` tasks to bring works into local database  
3. **Enrichment**: Use `work_labels`, `viaf`, `signal*` tasks to add metadata
4. **Analysis**: Use `measure`, `describe`, `connect` tasks to analyze corpus
5. **Quality**: Use `expunge`, `order2` tasks to refine the corpus

## Integration Points

### With CorpusBuilder Core

- **Shadow Table**: Works stored using STI alongside philosophers
- **Canonicity System**: Works can have measures/scores like philosophers
- **Text Corpus**: Works connected to actual text files via `connect` task
- **SPARQL Infrastructure**: Reuses existing Wikidata query system

### With Delta of Delta Algorithm

Works from the Shadow table can be used as input to the delta analysis:

```ruby
# Get works ordered by significance (linkcount, measure, etc.)
significant_works = Work.joins(:texts)
  .where.not(obsolete: true)
  .order(:linkcount => :desc, :measure => :desc)
  .includes(:texts)
  .limit(50)

# Extract file paths for delta analysis
work_files = significant_works.flat_map { |work| 
  work.texts.map(&:file_path) 
}.compact
```

## Configuration

### SPARQL Queries

The tasks use predefined SPARQL queries from `lib/wikidata/sparql_queries.rb`:

- `THESE_WORKS_BY_PHILOSOPHERS`: Notable works by philosophers
- `THESE_PHILOSOPHICAL_WORKS`: Works classified as philosophical

### Query Caching

- Uses `Wikidata::QueryExecutor` for caching and rate limiting
- Results cached to avoid repeated API calls
- Task names used for cache differentiation

## Error Handling

### Common Issues

1. **Missing Philosophers**: Works found for philosophers not in local database
2. **Duplicate Entities**: Handled via ActiveRecord::RecordNotUnique
3. **API Rate Limits**: Managed by QueryExecutor
4. **Network Issues**: SPARQL endpoint connectivity problems

### Debugging

- Use `count` parameter in `show` tasks for debugging
- Progress bars show processing status
- Error messages indicate missing relationships

## Best Practices

### Workflow Recommendations

1. **Start with Investigation**:
   ```bash
   bin/rake shadow:work:show[works1]
   bin/rake shadow:work:show[works2]
   ```

2. **Import Core Data**:
   ```bash
   bin/rake shadow:work:populate[works1]
   ```

3. **Enrich Metadata**:
   ```bash
   bin/rake shadow:work:signal1
   bin/rake shadow:work:signal2
   ```

4. **Analyze Connections**:
   ```bash
   bin/rake shadow:work:connect
   bin/rake shadow:work:measure
   ```

5. **Quality Control**:
   ```bash
   bin/rake shadow:work:expunge
   ```

### Data Quality

- Always run `show` before `populate` to preview changes
- Monitor for missing philosopher relationships
- Regular cleanup with `expunge` task
- Verify text connections with `connect` task

### Performance

- Tasks use progress bars for long-running operations
- SPARQL queries cached to minimize API calls
- Batch processing where possible
- Error recovery and continuation mechanisms

## Examples

### Complete Workflow Example

```bash
# 1. Discover what's available
bin/rake shadow:work:show[works1] | head -20

# 2. Import the data
bin/rake shadow:work:populate[works1]

# 3. Add metadata
bin/rake shadow:work:signal1
bin/rake shadow:work:work_labels[Q9068,true]

# 4. Analyze connections
bin/rake shadow:work:connect

# 5. Use in Delta Analysis
works = Work.joins(:texts).order(:linkcount => :desc).limit(20)
processor = DeltaOfDeltaProcessor.new(
  works: works.flat_map { |w| w.texts.map(&:file_path) },
  output_dir: 'tmp/delta_works_analysis'
)
```

### Targeted Analysis Example

```bash
# Focus on specific philosopher's works
bin/rake shadow:work:work_labels[Q9068]  # Aristotle
bin/rake shadow:work:work_labels[Q859]   # Plato
bin/rake shadow:work:work_labels[Q8806]  # Descartes

# Analyze the connections
bin/rake shadow:work:connect
```

## Future Enhancements

1. **Automated Quality Scoring**: Integrate with canonicity algorithm
2. **Batch Import**: More efficient bulk operations
3. **Relationship Analysis**: Enhanced philosopher-work connections
4. **Text Matching**: Improved algorithms for connecting works to files
5. **Delta Integration**: Direct pipeline from works to delta analysis
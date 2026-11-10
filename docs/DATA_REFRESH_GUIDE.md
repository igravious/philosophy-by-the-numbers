# Data Refresh Guide for CorpusBuilder

*Last Updated: October 5, 2025*

## System Overview

**CorpusBuilder** is a Rails application that builds and maintains a comprehensive database of philosophical figures and works. The system:

- Populates a database with philosophical figures and works from Wikidata
- Cross-references against encyclopedias (Stanford, Oxford, Cambridge, etc.)
- Calculates canonicity rankings using multiple data sources
- Integrates Wikipedia PageRank data (via "danker" scores)
- Maintains versioned snapshots with full audit trails

### Core Architecture

The system uses:
- **Shadow** model (STI base class for Philosopher/Work entities)
- **Wikidata SPARQL queries** for data population
- **Reference-work index and metadata leveraging** for cross-referencing
- **Danker scores** (Wikipedia PageRank data)
- **Configurable weight algorithms** for canonicity calculations

### Key Database Tables
- `shadows` - Core entities (philosophers and works)
- `names` - Multi-language labels for entities
- `metric_snapshots` - Audit trail of all calculations
- `canonicity_weights` - Configurable algorithm weights
- Various encyclopedia cross-reference tables

---

# Detailed Step-by-Step Plan for Freshening Data

## Phase 1: Environment Setup & Validation

### Step 1.1: Verify System Dependencies
```bash
# Check Ruby version and gem dependencies
cd /home/groobiest/Code/CB.old
bundle install
bin/rake about
```

### Step 1.2: Database Health Check
```bash
# Check database connectivity and schema
bin/rake db:migrate:status
bin/rake db:version
```

### Step 1.3: Backup Current Data
```bash
# Create backup of current database
cp db/development.sqlite3 db/development.sqlite3.backup-$(date +%Y%m%d)
```

## Phase 2: Update External Data Sources

### Step 2.1: Download Latest Danker (Wikipedia PageRank) Data
```bash
# Downloads latest Wikipedia PageRank data from external source
bin/rake danker:update
```

**What this does:**
- Downloads latest danker data from https://danker.s3.amazonaws.com/
- Creates versioned directory structure (db/danker_YYYY-MM-DD/)
- Maintains 'danker' symlink to current version (db/danker → danker_YYYY-MM-DD)
- Downloads compressed .rank.bz2 files and .stats.txt files
- Validates data format (requires bzip2-ffi gem for full verification)

### Step 2.2: Verify Danker Data
```bash
# List available versions and confirm latest is active
bin/rake danker:list
```

## Phase 3: Populate Core Philosophical Entities

### Step 3.1: Populate Philosophers from Wikidata
```bash
# Query Wikidata for philosophers and populate database
# Use force=true to actually create records (dry-run without force)
bin/rake shadow:philosopher:populate[true]
```

**What this does:**
- Executes SPARQL query: `THESE_PHILOSOPHERS` against Wikidata
- Finds entities with `wdt:P31 wd:Q5` (instance of human) AND philosophy-related properties
- Creates Shadow records with type='Philosopher'
- Captures entity_id, linkcount, basic labels

**SPARQL Query Pattern:**
```sparql
SELECT ?entity ?entityLabel (COUNT(DISTINCT ?sitelink) AS ?linkcount) WHERE {
  ?entity wdt:P31 wd:Q5 .
  {{?entity p:P106 ?l0 . ?l0 ps:P106 wd:Q4964182 .} UNION 
   {?entity p:P101 ?l0 . ?l0 ps:P101 wd:Q4964182 .} UNION 
   {?entity p:P39 ?l0 . ?l0 ps:P39 wd:Q4964182 .}}
  # Philosophy-related occupation, field of work, or position held
}
```

### Step 3.2: Enrich Philosopher Data with Additional Properties
```bash
# Add birth/death dates, gender, locations, etc.
bin/rake shadow:philosopher:flesh
```

**What this does:**
- Queries Wikidata for additional properties:
  - P569 = date of birth
  - P570 = date of death  
  - P21 = sex or gender
  - P19 = place of birth
  - P20 = place of death
- Updates existing philosopher records with enriched metadata
- Normalizes date formats and extracts years

### Step 3.3: Populate Multi-language Labels
```bash
# Get philosopher names in multiple languages
bin/rake shadow:philosopher:phil_labels
```

**What this does:**
- Queries Wikidata for labels in multiple languages
- Populates `names` table with language-specific labels
- Enables multi-language display and search
- Supports languages: en, nl, fr, de, es, it, sv, da, ru, ca, ja, hu, pl, fi, cs, zh, fa, sk, uk, ar, he, et, sl, bg, el, hr, la, hy, zh-cn, sr, az, lv, krc

### Step 3.4: Extract and Normalize Temporal Data
```bash
# Process birth/death dates into normalized year fields
bin/rake shadow:philosopher:year
```

**What this does:**
- Parses various date formats from Wikidata
- Extracts birth_year and death_year integers
- Handles approximate dates and flourishing periods
- Normalizes temporal data for analysis

## Phase 4: Populate Philosophical Works

### Step 4.1: Populate Works by Philosophers
```bash
# Get works authored by known philosophers
bin/rake shadow:work:populate[works1]
```

**What this does:**
- Uses SPARQL query `THESE_WORKS_BY_PHILOSOPHERS`
- Finds works (P50=author) by known philosophers
- Creates Shadow records with type='Work'
- Links works to their philosopher authors

### Step 4.2: Populate General Philosophical Works
```bash
# Get broader set of philosophical works
bin/rake shadow:work:populate[works2]
```

**What this does:**
- Uses SPARQL query `THESE_PHILOSOPHICAL_WORKS`
- Finds works classified as philosophical literature
- Broader scope than works by known philosophers
- Captures important philosophical texts regardless of author status

### Step 4.3: Enrich Work Labels and Metadata
```bash
# Add multi-language labels for works
bin/rake shadow:work:work_labels[,true]
```

**What this does:**
- Populates multi-language labels for philosophical works
- Updates `names` table with work titles in various languages
- Second parameter (true) enables actual database updates

## Phase 5: Cross-Reference with Encyclopedias

### Step 5.1: Stanford Encyclopedia of Philosophy
```bash
# Scrape and cross-reference with SEP
bin/rake snarf:sep
```

**What this does:**
- Scrapes Stanford Encyclopedia of Philosophy entries
- Matches entries against known philosophers
- Sets `stanford` boolean flag on matched records
- Adds canonical weight to SEP-listed philosophers

### Step 5.2: Oxford Reference Works
```bash
# Cross-reference with Oxford sources
bin/rake snarf:oxford2  # Oxford Dictionary of Philosophy, 2nd ed.
bin/rake snarf:oxford3  # Oxford Dictionary of Philosophy, 3rd ed.
```

**Encyclopedia Sources:**
- Oxford Dictionary of Philosophy, 2nd edition → Sets `oxford2` flag
- Oxford Dictionary of Philosophy, 3rd edition → Sets `oxford3` flag
- Note: Previously unified `oxford` flag has been split to track edition-specific coverage

### Step 5.3: Cambridge Dictionary of Philosophy
```bash
# Cross-reference with Cambridge sources
bin/rake snarf:cambridge
```

**What this does:**
- Cross-references with Cambridge Dictionary of Philosophy
- Sets `cambridge` boolean flag
- Adds to canonicity calculation weights

### Step 5.4: Other Encyclopedia Sources
```bash
# Internet Encyclopedia of Philosophy
bin/rake snarf:internet

# Routledge Encyclopedia
bin/rake snarf:routledge

# Additional sources as needed
bin/rake snarf:kemerling
bin/rake snarf:runes
```

**Additional Sources:**
- **Internet Encyclopedia** (`internet` flag)
- **Routledge Encyclopedia** (`routledge` flag)  
- **Kemerling's Philosophy Pages** (`kemerling` flag)
- **Philosophy Dictionary (Runes)** (`runes` flag)
- **Borchert Encyclopedia** (`borchert` flag)

## Phase 6: Import Latest Rankings Data

### Step 6.1: Import Danker Scores
```bash
# Process downloaded files if necessary
bin/rake danker:process_files

# Atomically import the latest processed CSV
bin/rake shadow:philosopher:danker

# Or import an explicit CSV/TSV artifact
bin/rake "metric:import_danker[path/to/scores.csv,Philosopher,2026-11-06]"
```

**What this does:**
- Streams and checksums the complete artifact in one validation pass before opening the import transaction; only scores needed by the subject population are retained in memory.
- Updates current `shadows.danker` values for the complete subject population.
- Writes `nil` for an entity missing from the file rather than coercing it to `0.0`.
- Records old and new values, artifact identity/checksum, import identity, and timestamps in `source_events`.
- Commits all current-value changes and source events in one transaction under the metric operation lock.
- Does not create metric calculation snapshots.

An explicit Work import uses `metric:import_danker[path,Work,version]`. Work reference flags use `metric:import_work_flags[works.json]`; they are no longer updated implicitly by `shadow:work:measure`.

**Never treat a partial Danker file as an incremental overlay.** Every omitted entity is assigned `nil`, and every subject row receives an old/new source event even if its numeric score is unchanged. Generate or validate a complete sorted artifact before import, and deliberately check every numeric `0.0` and every NULL transition. Numeric zero is a source value; omission is missing data. Neither, by itself, determines whether an entity belongs in the philosophical corpus.

### Step 6.2: Update Philosophy/Philosopher Mention Scores
```bash
# Count mentions in philosophical texts
bin/rake shadow:philosopher:mentions
```

**What this does:**
- Counts mentions of philosophers in philosophical corpus
- Updates `shadows.mention` field
- Updates `shadows.philosophy` and `shadows.philosopher` scores
- Provides signal for canonicity calculations

## Phase 7: Add Extra Metadata

### Step 7.1: Process Philosophical Capacities/Roles
```bash
# Categorize philosophers by their areas (ethicist, logician, etc.)
bin/rake shadow:philosopher:capacities
```

**What this does:**
- Queries Wikidata for philosophical specializations
- Categorizes by areas: ethics, logic, metaphysics, epistemology, etc.
- Populates philosophical capacity metadata
- Enables filtering and analysis by philosophical area

### Step 7.2: Add VIAF Data for Works
```bash
# Cross-reference works with VIAF authority data
bin/rake shadow:work:viaf
```

**What this does:**
- Cross-references works with VIAF (Virtual International Authority File)
- Adds authoritative identifiers for works
- Improves data quality and deduplication
- Links to international library authority records

### Step 7.3: Set Genre Classifications
```bash
# Classify works by genre/type
bin/rake shadow:work:signal3
```

**What this does:**
- Classifies works by philosophical genre
- Sets `genre` boolean flag for relevant works
- Helps distinguish philosophical works from other literature
- Improves canonicity calculations

### Step 7.4: Add External Identifier Links
```bash
# Add Britannica, PhilPapers, and other external IDs
bin/rake shadow:work:signal1
```

**What this does:**
- Adds Britannica Encyclopedia identifiers (`britannica` field)
- Adds PhilPapers identifiers (`philrecord` field)
- Links to external authoritative sources
- Enhances cross-referencing capabilities

## Phase 8: Compute New Rankings

### Step 8.1: Configure Canonicity Weights
```ruby
# Check/update weights in Rails console or via migration
bin/rails console
> CanonicityWeights.where(active: true).order(:source_name)
```

**Weight Configuration:**
The system uses configurable weights stored in the `canonicity_weights` table:

| Source | Weight | Description |
|--------|--------|-------------|
| stanford | 0.10 | Stanford Encyclopedia presence |
| oxford2 | NULL | Oxford Dictionary of Philosophy, 2nd ed. (inactive legacy source) |
| oxford3 | 0.13 | Oxford Dictionary of Philosophy, 3rd ed. |
| cambridge | 0.13 | Cambridge Dictionary presence |
| borchert | 0.17 | Macmillan Encyclopedia (Borchert) |
| routledge | 0.17 | Routledge Encyclopedia |
| inphobool | 0.10 | Internet Encyclopedia of Philosophy |
| internet | 0.03 | Internet sources |
| kemerling | 0.07 | Kemerling Philosophy Pages |
| populate | 0.01 | Wikipedia (as philosopher) |
| dbpedia | 0.01 | DBpedia (as philosopher) |
| all_bonus | 0.08 | Bonus for having any authoritative sources |
| runes | NULL | Philosophy Dictionary (inactive legacy source) |

**Total Active Bitset Weight:** 1.000000, including `all_bonus` when it applies

**Weight Determination:** Source weights were determined using Wikipedia PageRank data (danker scores) to measure the relative significance of each encyclopedia source.

**Note:** The `all_bonus` is conditional—it only applies if the philosopher appears in at least one active authoritative source. Oxford2 and Runes are inactive legacy sources with `NULL` weights; Oxford3 actively contributes.

**Algorithm Versioning:**
- Supports multiple algorithm and configuration versions; never edit a weight set already used by a run
- Create a complete new configuration by copying an existing version and changing the intended weights
- Run-linked snapshots read frozen configuration; original `2.0` is historical-only
- Default calculators: `philosopher-v2` and `work-v2`

### Step 8.2: Capture Coherent Philosopher Inputs
```bash
# Complete population
bin/rake "metric:capture[Philosopher]"

# Small review population using pipe-separated IDs
bin/rake "metric:capture[Philosopher,,5484|5485,5484|5485]"
```

Capture freezes the selected and normalization populations, primitive payloads, normalization context, and source provenance. Selected IDs must be contained in normalization IDs. Missing entities invalidate capture without leaving partial records. Review status and evidence at `/canonicity`.

Calculate a controlled run after capture:

```bash
# Calculate from a ready dataset
bin/rake "metric:calculate[3]"

# Recalculate from the same dataset, with a parent run and explicit configuration
bin/rake "metric:recalculate[Philosopher,0.7.0,2.1]"

# Verify measures, population, normalization, and dense ranks without writes
bin/rake "metric:replay[Philosopher,0.7.0]"
```

Run versions begin at `0.7.0` independently for Philosopher and Work. Recalculation reuses the dataset and frozen inputs. Cross-subject configurations and source weights above 1 are rejected before version allocation; Work's source check excludes genre multipliers. Current display values are not changed by calculation or replay. `shadow:philosopher:metric` and `shadow:work:measure` use this same controlled capture/run pipeline.

### Step 8.3: Capture Work Inputs After Philosopher Runs
```bash
# Uses the latest completed full-population Philosopher run by default
bin/rake "metric:capture[Work]"

# Or select an explicit dependency
bin/rake "metric:capture[Work,12]"
```

A completed Philosopher run is mandatory. Work capture freezes linked-author snapshot IDs and measures from that run; missing author dependencies fail capture with an actionable error. Work reference flags are imported separately using `metric:import_work_flags[works.json]`.

### Step 8.4: Compare, Audit Zeros, and Publish

Compare candidate runs and replay them before publication:

```bash
bin/rake "metric:compare[Philosopher,0.8.0,0.9.0]"
bin/rake "metric:replay[Philosopher,0.9.0]"
bin/rake "metric:publish[Philosopher,0.8.1]"
```

Publication requires selected, normalization, snapshot, and current populations to be identical, with finite measures and verified dense ranks. It atomically updates current values and appends history. A Work/Philosopher dependency mismatch prints a warning but does not block.

Before every publication, inspect the entities whose measure is `0.0` and break down the causes using frozen `calculation_context` and primitive payloads: raw zero mention, role-suppressed positive mention, raw zero Danker, missing Danker fallback, zero source coverage, or zero-author adjustment. A zero score is not a philosophical classification. Preserve the distinction between raw `0.0`, `nil`, and derived zero; investigate missing philosophy mentions as suspicious input evidence rather than automatic grounds for exclusion.

## Phase 9: Data Quality & Validation

### Step 9.1: Count and Validate Records
```bash
# Check philosopher counts
bin/rake shadow:philosopher:count

# Validate gender distribution
bin/rake shadow:philosopher:gender
```

**Validation Checks:**
- Total philosopher count vs. expected ranges
- Gender distribution analysis by time period
- Geographic distribution validation
- Temporal coverage verification

### Step 9.2: Clean and Normalize Data
```bash
# Clean dictionary/reference data
bin/rake dictionary:clean:all

# Normalize units if needed
bin/rake units:normalise
```

**Data Normalization:**
- Standardizes name variations using `Knowledge::Wikidata::MAP_NAME`
- Normalizes date formats across sources
- Cleans encyclopedia entry text
- Standardizes language codes and labels

### Step 9.3: Run Data Quality Checks
```bash
# Check for philosophers not yet in database
bin/rake shadow:philosopher:additional

# Verify work-text connections
bin/rake shadow:work:connect
```

**Quality Assurance:**
- Identifies philosophers in Wikidata query results not in local DB
- Validates work-to-text linkages
- Checks for orphaned records
- Verifies referential integrity

## Phase 10: Final Verification

### Step 10.1: Generate Reports
```bash
# Check final counts and rankings
bin/rails console
> puts "Philosophers: #{Shadow.where(type: 'Philosopher').count}"
> puts "Works: #{Shadow.where(type: 'Work').count}" 
> puts "Top 10 Philosophers:"
> Shadow.where(type: 'Philosopher').order('measure desc').limit(10).each {|p| puts "#{p.measure_pos}. #{p.english} (#{p.measure})"}
```

### Step 10.2: Validate Runs, Snapshots, and Publications
```ruby
> run = MetricRun.order(:id).last
> puts "Run: #{run.subject_type} #{run.version} (#{run.status})"
> puts "Configuration: #{run.configuration_version}"
> puts "Snapshots: #{run.metric_snapshots.count}"
> puts "Weights used: #{run.weights_config.inspect}"
> puts "Current Philosopher publication: #{Publication.current_for('Philosopher')&.metric_run&.version}"
> puts "Current Work publication: #{Publication.current_for('Work')&.metric_run&.version}"
```

For run-linked snapshots, `weights_config` is already a deserialized Hash and does not need `JSON.parse`. Historical unlinked snapshots remain valid and read legacy live-weight configuration.

### Step 10.3: Historical Comparison

Use controlled comparison rather than comparing whichever snapshots happen to be latest:

```bash
bin/rake "metric:compare[Philosopher,0.8.0,0.9.0]"
```

The report covers measure/rank movement, added and missing entities, population and normalization changes, and calculator/configuration differences. See `docs/CANONICITY_ALGORITHM.md` for the required zero-score cause audit before publication.

---

## Configuration & Troubleshooting

### Key Configuration Files
- `lib/wikidata/sparql_queries.rb` - SPARQL query definitions
- `lib/knowledge/wikidata.rb` - Name mapping and normalization
- `lib/tasks/shadow.rake` - Core philosopher processing tasks
- `lib/tasks/danker_update.rake` - PageRank data management

### Common Issues & Solutions

#### 1. Wikidata Query Timeouts
**Problem:** SPARQL queries timeout on large datasets
**Solution:** 
- Break queries into smaller batches
- Use conditional parameters to process subsets
- Monitor Wikidata query service status

#### 2. Encyclopedia Scraping Failures
**Problem:** Website structure changes break scrapers
**Solution:**
- Check snarf task implementations in `lib/tasks/snarf.rake`
- Update CSS selectors or parsing logic
- Implement retry logic with backoff

#### 3. Danker Data Format Changes
**Problem:** PageRank data format or location changes
**Solution:**
- Update `danker:update` task in `lib/tasks/danker_update.rake`
- Verify data validation logic
- Check S3 bucket structure

**Note:** As of October 2025, the danker format has changed from:
- Old: `YYYY-MM-DD.all.links.c.alphanum.csv` (uncompressed CSV)
- New: `YYYY-MM-DD.allwiki.links.rank.bz2` (compressed tab-separated)

#### 4. Memory Issues on Large Datasets
**Problem:** Rails process runs out of memory
**Solution:**
- Process in batches using `find_in_batches`
- Clear ActiveRecord caches periodically
- Increase system memory or use streaming

### Monitoring & Maintenance

#### Regular Tasks (Weekly)
```bash
# Update danker data
bin/rake danker:update
bin/rake shadow:philosopher:danker

# Recalculate rankings
bin/rake shadow:philosopher:metric
```

#### Monthly Tasks
```bash
# Full data refresh
bin/rake shadow:philosopher:populate[true]
bin/rake shadow:philosopher:flesh
bin/rake shadow:work:populate[works1]
bin/rake shadow:work:populate[works2]
```

#### Quarterly Tasks
```bash
# Encyclopedia cross-reference updates
bin/rake snarf:sep
bin/rake snarf:oxford2
bin/rake snarf:oxford3
bin/rake snarf:cambridge
# ... other encyclopedia sources
```

### Performance Optimization

#### Database Indexes
Ensure these indexes exist for performance:
```sql
-- Core entity lookups
CREATE INDEX index_shadows_on_entity_id ON shadows(entity_id);
CREATE INDEX index_shadows_on_type ON shadows(type);

-- Ranking queries
CREATE INDEX index_shadows_on_measure_and_type ON shadows(measure, type);
CREATE INDEX index_shadows_on_measure_pos ON shadows(measure_pos);

-- Snapshot queries
CREATE INDEX index_metric_snapshots_on_calculated_at ON metric_snapshots(calculated_at);
CREATE INDEX index_metric_snapshots_on_philosopher_id_and_calculated_at ON metric_snapshots(philosopher_id, calculated_at);
```

#### Query Optimization
- Use `select` to limit returned columns
- Batch process large datasets with `find_in_batches`
- Cache frequently accessed data
- Use database-level aggregations where possible

---

## Data Sources & Attribution

### Primary Sources
- **Wikidata** - Structured data about philosophers and works
- **Wikipedia** - PageRank scores via danker data
- **Stanford Encyclopedia of Philosophy** - Authoritative philosophical content
- **Oxford Reference** - Academic philosophical dictionaries
- **Cambridge Dictionary of Philosophy** - Scholarly reference work

### Data Licensing
- Wikidata: CC0 (Public Domain)
- Wikipedia: CC-BY-SA
- Encyclopedia content: Check individual source licensing
- PageRank data: Verify danker data licensing terms

### Update Frequency
- **Wikidata**: Real-time (queries run on demand)
- **Danker Data**: Updated periodically (check external source)
- **Encyclopedia Sources**: Manual scraping (update as needed)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-05 | Initial comprehensive data refresh guide |

---

*This document should be updated whenever significant changes are made to the data refresh process or when new data sources are added.*
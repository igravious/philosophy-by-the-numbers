# Plan 4: Schema Overhaul

**Goal:** Refactor the database schema to properly normalise the wide STI tables,
fix data integrity issues, and prepare a clean foundation for the query DSL
(Plan 5) and UI overhaul (Plan 6).

**Back to:** [Master Plan](../../MASTER_PLAN.md)

**Prerequisite:** [Plan 3 (Ruby and Rails Migration)](PLAN-3-RUBY-RAILS-MIGRATION.md) complete.
Schema changes are far easier on modern Rails (native composite keys, Zeitwerk, etc.).

## Current State

### Table Inventory (28 tables)

| Table | Columns | Records (approx) | Notes |
|-------|---------|-------------------|-------|
| `shadows` | 20 | ~13,000 | STI base (Philosopher/Work) |
| `philosopher_attrs` | 38 | ~13,000 | 12 boolean ref work flags + bio data |
| `work_attrs` | 20 | ~2,000 | Publication metadata |
| `names` | 4 | ~100,000 | Multi-language labels |
| `expressions` | 2 | many | Philosopher-Work join (composite PK) |
| `properties` | 9 | ~3,000,000 | Wikidata RDF properties |
| `p_smarts` | 5 | many | STI property subclasses (composite PK) |
| `texts` | 9 | ~1,500 | Corpus content |
| `authors` | 8 | varies | Text authors |
| `writings` | 4 | varies | Author-Text join with role |
| `fyles` | 11 | varies | File metadata + caching |
| `dictionaries` | 11 | varies | Reference works |
| `units` | 8 | ~50,000+ | Dictionary entries |
| `tags` | 3 | varies | Text classification |
| `labelings` | 4 | varies | Tag-Text join |
| `filters` | 6 | varies | Named text filters |
| `includings` | 4 | varies | Filter-Text join |
| `meta_filters` | 4 | varies | Saved query parameter sets |
| `meta_filter_pairs` | 5 | varies | Base64-encoded marshalled Ruby objects |
| `links` | 5 | varies | RDF resource links |
| `resources` | 3 | varies | RDF resource URIs |
| `roles` | 5 | varies | Philosopher-Capacity join |
| `capacities` | 5 | varies | Entity roles/professions |
| `canonicity_weights` | 6 | small | Algorithm configuration |
| `metric_snapshots` | 14 | growing | Canonicity audit trail |
| `obsolete_attrs` | 6 | varies | Deprecated metrics (candidate for removal) |
| `http_request_loggers` | 6 | varies | Request logging |
| `viaf_cache_items` | 4 | varies | VIAF API cache |

### Known Schema Problems

1. **`philosopher_attrs` is too wide (38 columns)**
   - 12 boolean reference work flags should be a separate normalised table
   - Querying "has any encyclopedia flag" requires OR across 12 columns
   - Adding a new reference source means a migration to add a column

2. **`meta_filter_pairs` stores Base64-encoded marshalled Ruby objects**
   - `value` column contains `Marshal.dump` output, Base64-encoded
   - Brittle: Ruby version changes can break Marshal format
   - Not queryable — can't search for filters by parameter value
   - Security risk: `Marshal.load` can execute arbitrary code

3. **Composite primary keys add complexity**
   - `expressions` (creator_id, work_id)
   - `p_smarts` (redirect_id, object_id, type)
   - `viaf_cache_items` (personal, uniform_title_work)
   - Rails 7.1+ has native composite PK support — can remove CPK gem dependency

4. **Raw SQL in querying layer**
   - `QuestionsController#specific_features` concatenates SQL strings
   - Should use parameterised queries (`where(object_id: features)`)

5. **`obsolete_attrs` table is dead weight**
   - Stores deprecated metrics superseded by `metric_snapshots`
   - Candidate for archival/removal

6. **`shadows` table still has columns that belong in attrs tables**
   - `date_hack`, `name_hack` — temporary data cleaning fields
   - `philosophy` — classification counter
   - Could be rationalised

7. **No database views**
   - Complex aggregation queries are done in Ruby (controller/model code)
   - Database views would push aggregation to SQLite, improving performance

8. **`authors` vs `shadows` (Philosopher) duplication**
   - `authors` table stores text authors with name, birth/death years
   - `shadows` (Philosopher) stores the same data for philosophers
   - Some authors ARE philosophers but the link is manual/weak

## Phases

### Phase 1: Reference Work Flag Normalisation

Extract the 12 boolean columns from `philosopher_attrs` into a proper
entity-attribute-value or join table.

**Current (wide):**
```
philosopher_attrs: oxford2, oxford3, stanford, internet, kemerling,
                   runes, borchert, cambridge, routledge, dbpedia,
                   populate, inpho, inphobool
```

**Target (normalised):**
```
reference_work_entries:
  id, shadow_id, source_name (string), flagged_at (datetime)
  unique index on (shadow_id, source_name)
```

- [ ] Create migration for `reference_work_entries` table
- [ ] Write data migration script to copy existing boolean flags
- [ ] Update `Philosopher` model: `has_many :reference_work_entries`
- [ ] Add helper methods: `philosopher.in_reference_work?('stanford')`,
      `philosopher.reference_work_count`
- [ ] Update `import/sauce.rb` to write to new table
- [ ] Update canonicity calculation to read from new table
- [ ] Update all views that display reference work flags
- [ ] Remove 12 boolean columns from `philosopher_attrs` (final migration)
- [ ] Update tests
- [ ] Commit: "Normalise reference work flags into reference_work_entries table"

**Benefits:**
- Adding new reference sources = inserting a row, not a migration
- `Philosopher.joins(:reference_work_entries).where(reference_work_entries: {source_name: 'stanford'})` replaces `where(stanford: true)`
- `philosopher.reference_work_entries.count` replaces OR across 12 columns
- Timestamps on each flag (when was it set?)

### Phase 2: MetaFilter Serialisation Fix

Replace Base64-encoded `Marshal.dump` with JSON.

- [ ] Add `json_value` column to `meta_filter_pairs` (text, stores JSON)
- [ ] Write data migration script to decode existing Base64/Marshal values and
      re-encode as JSON
- [ ] Update `MetaFilterPair` model to use JSON serialisation
- [ ] Update `QuestionsController#from_filter` to read JSON
- [ ] Drop old `value` column
- [ ] Update tests
- [ ] Commit: "Replace Marshal serialisation with JSON in meta_filter_pairs"

### Phase 3: Verify Native Composite Keys

The runtime migration in [Plan 3](PLAN-3-RUBY-RAILS-MIGRATION.md) moves off the
`composite_primary_keys` gem while crossing Rails 7.1. Verify that transition
against the schema changes in this plan rather than repeating it.

- [ ] Verify key definitions and associations for `Expression`, `P::Smart`
      subclasses and `ViafCacheItem`
- [ ] Verify lookups and fixtures after schema changes
- [ ] Confirm `composite_primary_keys` is absent from the bundle
- [ ] Run the relevant regression tests

### Phase 4: SQL Injection Cleanup

Fix all raw SQL string concatenation in the querying layer.

- [ ] `QuestionsController#specific_features`:
      `where('object_id = "'+features.first+'"...')` -> `where(object_id: features)`
- [ ] Grep codebase for other raw SQL patterns: `.where("`, `.execute(`, `.find_by_sql(`
- [ ] Replace with parameterised queries
- [ ] Add test cases for SQL injection attempts
- [ ] Commit: "Replace raw SQL with parameterised queries"

### Phase 5: Schema Cleanup

Remove dead tables and rationalise remaining columns.

- [ ] Archive and drop `obsolete_attrs` table
- [ ] Evaluate `date_hack` and `name_hack` columns on `shadows`:
  - If still needed, document purpose
  - If not, remove
- [ ] Evaluate `philosophy` column on `shadows`:
  - Consider moving to `philosopher_attrs` or a dedicated classification
- [ ] Clean up `http_request_loggers` (archive old data, add retention policy)
- [ ] Review `viaf_cache_items` — consider moving to Memcached or Solid Cache
- [ ] Update ERD documentation (`app/ERD.md`)
- [ ] Commit: "Remove obsolete tables and rationalise schema"

### Phase 6: Database Views for Common Aggregations

Create SQLite views for frequently-executed complex queries.

- [ ] View: `philosopher_summaries` — joins shadows + philosopher_attrs + name(en)
      + reference_work_entry count + latest metric_snapshot
- [ ] View: `work_summaries` — joins shadows + work_attrs + name(en) +
      expression(creator) + text(fyle)
- [ ] View: `property_aggregations` — groups p_smarts by type + object_id with counts
- [ ] View: `encyclopedia_coverage` — pivot of reference_work_entries by source
- [ ] Create migrations using `execute "CREATE VIEW ..."`
- [ ] Create read-only ActiveRecord models backed by views
- [ ] Update controllers to use view-backed models where appropriate
- [ ] Commit: "Add database views for common aggregations"

### Phase 7: Author-Philosopher Linkage

Strengthen the connection between `authors` (text authors) and `shadows` (philosophers).

- [ ] Add `shadow_id` column to `authors` table (nullable FK)
- [ ] Write data migration to match existing authors to philosophers by name
- [ ] Update `Author` model: `belongs_to :philosopher, class_name: 'Philosopher',
      foreign_key: :shadow_id, optional: true`
- [ ] Update views to show philosopher link when available
- [ ] Commit: "Link authors to philosophers via shadow_id"

## Success Criteria

- No Base64/Marshal serialisation in the database
- No `composite_primary_keys` gem (using native Rails CPK)
- No raw SQL string concatenation
- Reference work flags normalised into rows
- `obsolete_attrs` removed
- Database views in place for common queries
- All tests pass
- ERD documentation updated

## Estimated Effort

- Phase 1 (Reference Work Flags): 2-3 sessions
- Phase 2 (MetaFilter Fix): 1-2 sessions
- Phase 3 (Native CPK): 1-2 sessions
- Phase 4 (SQL Injection): 1 session
- Phase 5 (Cleanup): 1-2 sessions
- Phase 6 (Database Views): 2-3 sessions
- Phase 7 (Author-Philosopher Link): 1 session
- **Total: ~9-14 sessions**

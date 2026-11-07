# Plan 5: Query DSL & Virtual Tables

**Goal:** Create a domain-specific language (DSL) for querying the corpus and
a system of virtual tables (database views) that provide clean, composable
access to the data model.

**Back to:** [Master Plan](../../MASTER_PLAN.md)

**Prerequisite:** [Plan 4 (Schema Overhaul)](PLAN-4-SCHEMA-OVERHAUL.md) complete.
The schema must be normalised and the database views from Plan 4 Phase 6 must
be in place before building the query DSL on top.

## Current State

### How Querying Works Today

The current querying system is spread across several layers:

**1. QuestionsController (app/controllers/questions_controller.rb)**
- 20+ action methods, each implementing a different query type
- Dynamic dispatch via `SecurityConfig.validate_method_call(@multiplex)`
- Two-phase pattern: discover entity IDs via `P::Smart`, then load full records
- `generic_features` / `ordinary_features` / `specific_features` methods
- Pagination via Kaminari

**2. MetaFilter System (saved queries)**
- `MetaFilter` stores a named filter + query type string
- `MetaFilterPair` stores key-value parameters (currently JSON after Plan 4)
- `from_filter/:id` route re-executes saved queries
- Limited to what QuestionsController can express

**3. P::Smart Subclasses (Wikidata property queries)**
- 10 STI subclasses mapping to Wikidata property types
- `P::P19` (birth place), `P::P20` (death place), `P::P27` (country),
  `P::P31` (instance of), `P::P1412` (language), `P::D1`/`D2`/`D3` (DBpedia),
  `P::J1`/`J27` (other)
- `.henry` scope filters redirected entities
- Composite PK: `(redirect_id, object_id, type)`

**4. Filter/Tag/Labeling System (text filtering)**
- `Filter` defines named text filters with inequality operators on year
- `Tag`/`Labeling` provides text classification
- `Including` joins filters to texts

### Problems with the Current Approach

1. **Query logic lives in the controller** — fat controller, thin model
2. **Each query type is a separate action** — no composability
3. **No way to combine queries** — can't say "philosophers born in Athens
   who are in the Stanford Encyclopedia AND have a canonicity score > 0.5"
4. **MetaFilter is opaque** — parameters are serialised blobs, not structured queries
5. **No query preview/explain** — can't see what SQL will run before executing
6. **No virtual tables** — complex joins are done in Ruby, not SQLite
7. **Adding a new query type requires controller code changes**

## Design

### Core Concept: Query Objects + View-Backed Models

```
User writes DSL query
    ↓
QueryParser builds a Query object
    ↓
Query object composes ActiveRecord scopes
    ↓
Scopes run against database views (from Plan 4)
    ↓
Results returned as ActiveRecord relations (chainable)
```

### DSL Syntax (proposed)

```ruby
# Simple queries
CorpusQuery.philosophers.born_in("Athens")
CorpusQuery.philosophers.in_reference_work("stanford")
CorpusQuery.philosophers.with_canonicity(min: 0.5)

# Composed queries
CorpusQuery.philosophers
  .born_in("Athens")
  .in_reference_work("stanford")
  .with_canonicity(min: 0.5)
  .order_by(:canonicity, :desc)

# Cross-entity queries
CorpusQuery.works
  .by_philosopher(born_in: "Athens")
  .with_text_in_corpus
  .in_language("en")

# Aggregation queries
CorpusQuery.philosophers.born_in("Athens").count
CorpusQuery.philosophers.group_by(:century).count
CorpusQuery.philosophers.reference_work_coverage

# Saved queries (replaces MetaFilter)
query = CorpusQuery.philosophers.born_in("Athens").in_reference_work("stanford")
query.save_as("Athenian Stanford philosophers")
CorpusQuery.load("Athenian Stanford philosophers")

# Text/string query (full-text search via Elasticsearch or LIKE)
CorpusQuery.texts.containing("being and nothingness")
CorpusQuery.units.matching("ontolog*")
```

### Virtual Tables (Database Views)

Building on Plan 4 Phase 6, add query-oriented views:

```sql
-- Philosopher with all commonly needed joins pre-done
CREATE VIEW philosopher_full AS
  SELECT s.*, pa.*, n.label AS english_name,
         COUNT(rwe.id) AS reference_count,
         ms.measure AS latest_canonicity
  FROM shadows s
  JOIN philosopher_attrs pa ON pa.shadow_id = s.id
  LEFT JOIN names n ON n.shadow_id = s.id AND n.lang = 'en'
  LEFT JOIN reference_work_entries rwe ON rwe.shadow_id = s.id
  LEFT JOIN metric_snapshots ms ON ms.shadow_id = s.id
    AND ms.shadow_type = 'Philosopher'
    AND ms.calculated_at = (SELECT MAX(calculated_at) ...)
  WHERE s.type = 'Philosopher'
  GROUP BY s.id;

-- Work with creator and text file info
CREATE VIEW work_full AS
  SELECT s.*, wa.*, n.label AS english_name,
         creator.entity_id AS creator_entity_id,
         cn.label AS creator_name,
         f.local_file
  FROM shadows s
  JOIN work_attrs wa ON wa.shadow_id = s.id
  LEFT JOIN names n ON n.shadow_id = s.id AND n.lang = 'en'
  LEFT JOIN expressions e ON e.work_id = s.entity_id
  LEFT JOIN shadows creator ON creator.entity_id = e.creator_id
  LEFT JOIN names cn ON cn.shadow_id = creator.id AND cn.lang = 'en'
  LEFT JOIN texts t ON t.id = s.id  -- needs proper FK
  LEFT JOIN fyles f ON f.id = t.fyle_id
  WHERE s.type = 'Work'
  GROUP BY s.id;

-- Property aggregation (replaces generic_features Ruby code)
CREATE VIEW property_summary AS
  SELECT type, object_id, object_label, COUNT(*) AS entity_count
  FROM p_smarts
  WHERE entity_id = redirect_id  -- .henry scope
  GROUP BY type, object_id, object_label;

-- Geographic distribution
CREATE VIEW philosopher_geography AS
  SELECT ps.object_id AS place_id, ps.object_label AS place_name,
         ps.type AS relation_type, COUNT(*) AS philosopher_count
  FROM p_smarts ps
  WHERE ps.type IN ('P::P19', 'P::P20', 'P::P27')
    AND ps.entity_id = ps.redirect_id
  GROUP BY ps.type, ps.object_id;
```

## Phases

### Phase 1: Query Object Foundation

Create the core query builder that wraps ActiveRecord relations.

- [ ] Create `app/models/corpus_query.rb` — entry point class
- [ ] Create `app/models/corpus_query/philosopher_query.rb`
- [ ] Create `app/models/corpus_query/work_query.rb`
- [ ] Create `app/models/corpus_query/text_query.rb`
- [ ] Implement basic chainable methods:
  - `.where_entity(entity_id:)`
  - `.with_name(containing:)`
  - `.in_reference_work(source:)`
  - `.with_canonicity(min:, max:)`
  - `.born_in(place)`, `.died_in(place)`, `.from_country(country)`
  - `.in_period(start_year:, end_year:)`
  - `.order_by(column, direction)`
  - `.page(n)`, `.per(n)` (pagination)
- [ ] Write tests for each query method
- [ ] Commit: "Add CorpusQuery foundation with chainable philosopher queries"

### Phase 2: View-Backed Models

Create ActiveRecord models backed by the database views from Plan 4 Phase 6.

- [ ] Create `app/models/philosopher_summary.rb` (readonly, backed by view)
- [ ] Create `app/models/work_summary.rb` (readonly, backed by view)
- [ ] Create `app/models/property_summary.rb` (readonly, backed by view)
- [ ] Wire CorpusQuery to use view-backed models for read operations
- [ ] Benchmark: compare query performance (view-backed vs current Ruby joins)
- [ ] Write tests
- [ ] Commit: "Add view-backed readonly models for query performance"

### Phase 3: Property/Relationship Queries

Replace the `generic_features`/`specific_features` controller code with DSL methods.

- [ ] `CorpusQuery.philosophers.born_in(place)` — wraps P::P19 query
- [ ] `CorpusQuery.philosophers.died_in(place)` — wraps P::P20 query
- [ ] `CorpusQuery.philosophers.from_country(country)` — wraps P::P27 query
- [ ] `CorpusQuery.philosophers.speaking(language)` — wraps P::P1412 query
- [ ] `CorpusQuery.philosophers.influenced_by(philosopher)` — wraps P::Smart
- [ ] `CorpusQuery.philosophers.in_school(school)` — wraps P::Smart
- [ ] Aggregation methods: `.group_by(:birth_place).count`, `.group_by(:country).count`
- [ ] Refactor `QuestionsController` to delegate to CorpusQuery
- [ ] Write tests
- [ ] Commit: "Add property-based query methods, refactor QuestionsController"

### Phase 4: Composed & Cross-Entity Queries

Enable combining multiple conditions and querying across entities.

- [ ] Composition: chain any methods together (AND semantics)
- [ ] Cross-entity: `CorpusQuery.works.by_philosopher(born_in: "Athens")`
- [ ] Text corpus: `CorpusQuery.texts.by_author(name: "Aristotle")`
- [ ] Dictionary: `CorpusQuery.units.in_dictionary(title: "Stanford")`
- [ ] Add `.or()` support for OR composition
- [ ] Add `.not()` support for negation
- [ ] Write tests for complex composed queries
- [ ] Commit: "Add composed and cross-entity query support"

### Phase 5: Saved Queries (MetaFilter Replacement)

Replace the MetaFilter system with proper query serialisation.

- [ ] Design `saved_queries` table:
  ```
  id, name (string), query_json (text), description (text),
  created_at, updated_at
  ```
- [ ] `query.save_as("name")` serialises the CorpusQuery chain to JSON
- [ ] `CorpusQuery.load("name")` deserialises and returns a live query
- [ ] Migrate existing MetaFilter data to new saved_queries table
- [ ] Update routes: `/queries/:id` replaces `/questions/from_filter/:id`
- [ ] Update UI to show saved query management
- [ ] Archive and eventually drop `meta_filters` and `meta_filter_pairs` tables
- [ ] Write tests
- [ ] Commit: "Replace MetaFilter with serialisable CorpusQuery saved queries"

### Phase 6: Query Console

Create an interactive query interface (text-based, precursor to UI in Plan 6).

- [ ] Rails console extension: `CorpusQuery.philosophers.born_in("Athens").to_table`
  — pretty-prints results in terminal
- [ ] `CorpusQuery.philosophers.born_in("Athens").explain` — shows generated SQL
- [ ] `CorpusQuery.philosophers.born_in("Athens").to_csv` — exports results
- [ ] Rake task: `bin/rake query:run["philosophers.born_in('Athens')"]`
- [ ] Write tests
- [ ] Commit: "Add query console, explain, and export capabilities"

## Architecture

```
app/models/
  corpus_query.rb                    # Entry point: CorpusQuery.philosophers, .works, .texts
  corpus_query/
    base_query.rb                    # Shared chainable interface
    philosopher_query.rb             # Philosopher-specific methods
    work_query.rb                    # Work-specific methods
    text_query.rb                    # Text-specific methods
    unit_query.rb                    # Dictionary unit methods
    serialiser.rb                    # JSON serialisation for saved queries
  philosopher_summary.rb             # View-backed readonly model
  work_summary.rb                    # View-backed readonly model
  property_summary.rb                # View-backed readonly model
  saved_query.rb                     # Replaces MetaFilter

app/controllers/
  questions_controller.rb            # Refactored to delegate to CorpusQuery
  queries_controller.rb              # NEW: saved query management

lib/
  console_extension.rb               # Extended with CorpusQuery helpers

db/migrate/
  xxx_create_saved_queries.rb
```

## Success Criteria

- All 20+ QuestionsController query types expressible via CorpusQuery DSL
- Queries are composable (chain any conditions together)
- Saved queries replace MetaFilter with JSON serialisation
- View-backed models provide measurable query performance improvement
- `.explain` shows generated SQL for any query
- `.to_csv` exports results
- All tests pass
- QuestionsController is thin (delegates to CorpusQuery)

## Estimated Effort

- Phase 1 (Foundation): 3-4 sessions
- Phase 2 (View-Backed Models): 2-3 sessions
- Phase 3 (Property Queries): 2-3 sessions
- Phase 4 (Composed Queries): 2-3 sessions
- Phase 5 (Saved Queries): 2-3 sessions
- Phase 6 (Query Console): 1-2 sessions
- **Total: ~12-18 sessions**

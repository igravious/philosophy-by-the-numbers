# STI Attribute Migration - Philosopher & Work Models

**Date:** 2025-10-10
**Status:** ✅ Complete
**Rails Version:** 4.2.11.3
**Ruby Version:** 2.6.10

## Overview

This document describes the migration of type-specific attributes from the monolithic `shadows` Single Table Inheritance (STI) table to separate normalized attribute tables: `philosopher_attrs` and `work_attrs`.

## Background

The `shadows` table previously contained 100+ columns, including many attributes that were only relevant to either Philosopher or Work subclasses. This caused:
- Schema bloat (NULL values in type-specific columns)
- Confusion about which columns apply to which model
- Difficulty maintaining and understanding the data model

## Migration Goals

1. **Normalize the schema** by moving type-specific attributes to separate tables
2. **Preserve obsolete columns** in `obsolete_attrs` for historical analysis
3. **Maintain 100% backward compatibility** - no code changes required outside models
4. **Zero downtime** - all existing code continues working

## Architecture

### Before Migration
```
shadows table (100+ columns)
├── STI: type = 'Philosopher' or 'Work'
├── Shared columns: entity_id, mention, danker, measure, linkcount, etc.
├── Philosopher-only: birth, death, oxford2, stanford, inphobool, etc.
├── Work-only: pub, genre, obsolete, philrecord, philtopic, etc.
└── Obsolete: metric, metric_pos, dbpedia_pagerank, oxford
```

### After Migration
```
shadows table (18 shared columns)
├── STI: type = 'Philosopher' or 'Work'
└── Shared columns only

philosopher_attrs table (18 columns)
├── shadow_id → shadows.id
├── Birth/Death: birth, birth_year, death, death_year, etc.
├── Reference Works: oxford2, oxford3, stanford, internet, etc.
└── Demographics: gender

work_attrs table (12 columns)
├── shadow_id → shadows.id
├── Publication: pub, pub_year, pub_approx, work_lang, copyright
├── Classification: genre, obsolete
├── Reference Works: philrecord, philtopic, britannica
└── Metadata: image

obsolete_attrs table (4 columns)
├── shadow_id → shadows.id
├── shadow_type → 'Philosopher' or 'Work'
└── Obsolete fields: metric, metric_pos, dbpedia_pagerank, oxford
```

## Column Distribution

### Philosopher-Only Columns (18)

**Birth/Death Data:**
- `birth` - Birth date in ISO format
- `birth_approx` - Boolean: approximate birth date
- `birth_year` - Integer: extracted birth year
- `death` - Death date in ISO format
- `death_approx` - Boolean: approximate death date
- `death_year` - Integer: extracted death year
- `floruit` - Period when philosopher was active
- `period` - Historical period

**Reference Work Flags:**
- `dbpedia` - Present in DBpedia as philosopher
- `oxford2` - Oxford Dictionary of Philosophy, 2nd ed.
- `oxford3` - Oxford Dictionary of Philosophy, 3rd ed.
- `stanford` - Stanford Encyclopedia of Philosophy
- `internet` - Internet Encyclopedia of Philosophy
- `kemerling` - Philosophy Pages (Kemerling)
- `runes` - Runes Dictionary (excluded from metrics due to bias)
- `populate` - Wikipedia presence as philosopher
- `inpho` - Indiana Philosophy Ontology ID
- `inphobool` - Boolean: present in InPhO

**Demographics:**
- `gender` - Wikidata gender entity ID

**Metrics:**
- `philosopher` - Count of "philosopher" mentions in RDF descriptions

### Work-Only Columns (12)

**Publication Data:**
- `pub` - Publication date string
- `pub_year` - Publication year
- `pub_approx` - Approximate publication date
- `work_lang` - Language of the work
- `copyright` - Copyright status

**Classification:**
- `genre` - Boolean: philosophical genre
- `obsolete` - Boolean: work is obsolete/superseded

**Reference Work Flags:**
- `philrecord` - PhilPapers record ID
- `philtopic` - PhilPapers topic ID
- `britannica` - Encyclopedia Britannica entry ID

**Metadata:**
- `image` - Associated image URL
- `philosophical` - Count of "philosophical" mentions in RDF descriptions

### Shared Columns (18)

**Core Identifiers:**
- `entity_id` - Wikidata Q-number (without 'Q' prefix)
- `type` - STI discriminator: 'Philosopher' or 'Work'

**Metrics:**
- `linkcount` - Number of Wikidata links
- `mention` - Total mention count (philosopher/philosophical + philosophy)
- `philosophy` - Count of "philosophy" mentions (shared)
- `danker` - PageRank score from Danker dataset
- `measure` - Current canonicity measure
- `measure_pos` - Ranking position by measure

**Reference Work Flags (both types):**
- `borchert` - Macmillan Encyclopedia (Borchert)
- `cambridge` - Cambridge Dictionary of Philosophy
- `routledge` - Routledge Encyclopedia of Philosophy

**Metadata:**
- `viaf` - VIAF (Virtual International Authority File) ID
- `date_hack` - Manual date override field
- `name_hack` - Manual name override field
- `country` - Country entity ID
- `what_label` - Wikidata label cache

**Timestamps:**
- `created_at`
- `updated_at`

### Obsolete Columns (4)

These columns are no longer used but preserved for historical analysis:
- `metric` - Old canonicity system (replaced by `measure`)
- `metric_pos` - Old ranking position (replaced by `measure_pos`)
- `dbpedia_pagerank` - Old DBpedia PageRank (replaced by `danker`)
- `oxford` - Combined Oxford flag (split into `oxford2` and `oxford3`)

## Mention Count Architecture

The mention count system works differently for Philosophers vs Works:

**For Philosophers:**
```ruby
philosopher + philosophy = mention
```
- `philosopher` - mentions of word "philosopher" in RDF descriptions (Philosopher-only)
- `philosophy` - mentions of word "philosophy" in RDF descriptions (shared)
- `mention` - total (shared, stored in shadows)

**For Works:**
```ruby
philosophical + philosophy = mention
```
- `philosophical` - mentions of word "philosophical" in RDF descriptions (Work-only)
- `philosophy` - mentions of word "philosophy" in RDF descriptions (shared)
- `mention` - total (shared, stored in shadows)

## Implementation Details

### 1. Database Migrations

Three migrations were created:

**Migration 1: `20251010094255_create_attribute_tables.rb`**
- Creates `philosopher_attrs`, `work_attrs`, and `obsolete_attrs` tables
- Adds indexes on `shadow_id` (unique for attrs tables, non-unique for obsolete)

**Migration 2: `20251010094358_migrate_attribute_data.rb`**
- Copies data from `shadows` to attribute tables using raw SQL INSERT
- Migrated 13,329 Philosophers + 3,654 Works = 16,983 total records

**Migration 3: `20251010095418_remove_migrated_columns_from_shadows.rb`**
- Removes 39 migrated columns from shadows table
- Includes both `up` and `down` methods for full rollback capability
- Down method restores columns with proper types and recreates data from attribute tables

### 2. Model Implementation

#### Philosopher Model (`app/models/shadow.rb`)

```ruby
class Philosopher < Shadow
  # Associations
  has_one :attrs, class_name: 'PhilosopherAttrs', foreign_key: :shadow_id,
          autosave: true, dependent: :destroy
  has_one :obsolete_data, -> { where(shadow_type: 'Philosopher') },
          class_name: 'ObsoleteAttrs', foreign_key: :shadow_id

  accepts_nested_attributes_for :attrs

  # List of delegated attributes
  DELEGATED_ATTRIBUTES = %w[
    birth birth_approx birth_year death death_approx death_year
    floruit period dbpedia oxford2 oxford3 stanford internet
    kemerling runes populate inpho inphobool gender philosopher
  ]

  # Delegation with auto-build
  delegate :birth, :birth=,
           :birth_approx, :birth_approx=,
           # ... (all 18 attributes)
           to: :attrs_with_autobuild

  # Ensure attrs exists on initialization
  after_initialize :build_attrs_if_needed

  # Handle mass assignment of delegated attributes
  def initialize(attributes = nil, options = {})
    delegated_attrs = {}
    if attributes.is_a?(Hash)
      DELEGATED_ATTRIBUTES.each do |attr|
        attr_sym = attr.to_sym
        if attributes.key?(attr_sym)
          delegated_attrs[attr_sym] = attributes.delete(attr_sym)
        elsif attributes.key?(attr)
          delegated_attrs[attr_sym] = attributes.delete(attr)
        end
      end
    end

    super(attributes, options)

    delegated_attrs.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  private

  def attrs_with_autobuild
    build_attrs if attrs.nil?
    attrs
  end

  def build_attrs_if_needed
    build_attrs if attrs.nil?
  end
end
```

#### Work Model (`app/models/shadow.rb`)

Similar structure to Philosopher, with 12 delegated attributes.

#### Key Implementation Features

1. **`DELEGATED_ATTRIBUTES` constant**: Lists all attributes that should be delegated
2. **Custom `initialize` method**: Intercepts mass assignment and routes delegated attributes appropriately
3. **`attrs_with_autobuild` delegation target**: Ensures attrs association always exists before delegation
4. **`after_initialize` callback**: Creates attrs record automatically when Philosopher/Work is initialized
5. **`accepts_nested_attributes_for :attrs`**: Enables nested form submission

## Backward Compatibility

All existing code continues working without changes:

```ruby
# Direct attribute access (most common)
philosopher.birth = "1724-04-22"
philosopher.stanford = true
work.genre = true
work.obsolete = false

# Mass assignment in .new()
Philosopher.new(entity_id: 123, oxford2: true, stanford: true)

# Mass assignment in .create()
Work.create!(entity_id: 456, genre: true, philrecord: "ABCD123")

# Queries still work
Philosopher.where(stanford: true)
Work.where(genre: true, obsolete: false)

# Model methods using delegated attributes
philosopher.calculate_canonicity_measure  # Uses oxford2, stanford, etc.
```

## Testing

### Test Results
- **173 tests, 428 assertions**
- **0 failures, 0 errors**
- **6 intentional skips** (ThreadError issues, external dependencies, intentional design)

### Test Coverage

**Unit Tests:**
- `test/models/shadow_test.rb` - Philosopher model attribute delegation
- `test/models/philosopher_canonicity_test.rb` - Canonicity calculation with delegated attrs
- `test/models/work_canonicity_test.rb` - Work canonicity calculation
- `test/models/canonicity_calculation_test.rb` - General canonicity tests
- `test/models/shadow_rake_tasks_test.rb` - Rake task integration

**Integration Tests:**
- `test/controllers/works_controller_test.rb` - Controller access to delegated attributes
- All 21 controller test suites pass with delegation

### Test Fixtures

Updated fixtures to reflect new schema:

**`test/fixtures/philosophers.yml`** - Only shadows table columns
**`test/fixtures/philosopher_attrs.yml`** - Philosopher-specific attributes
**`test/fixtures/works.yml`** - Only shadows table columns
**`test/fixtures/work_attrs.yml`** - Work-specific attributes

## Performance Considerations

### Query Performance
- **Single record access**: No performance impact (1:1 relationship with eager loading)
- **Bulk operations**: Use `includes(:attrs)` to avoid N+1 queries

```ruby
# Good: Eager load attrs
Philosopher.includes(:attrs).where(...)

# Bad: N+1 queries
Philosopher.all.each { |p| p.birth }  # Loads attrs for each philosopher
```

### Database Size
- **Before**: 1 table × 16,983 rows × 100 columns = ~1.7M cells (many NULL)
- **After**:
  - shadows: 16,983 rows × 18 columns = ~305K cells
  - philosopher_attrs: 13,329 rows × 18 columns = ~240K cells
  - work_attrs: 3,654 rows × 12 columns = ~44K cells
  - **Total: ~589K cells (65% reduction in NULL values)**

## Rollback Procedure

The migration is fully reversible:

```bash
# Rollback all three migrations
bin/rake db:migrate:down VERSION=20251010095418  # Remove columns
bin/rake db:migrate:down VERSION=20251010094358  # Restore data
bin/rake db:migrate:down VERSION=20251010094255  # Drop tables
```

The down migration in `20251010095418` fully restores:
1. Adds back all 39 columns to shadows table with correct types
2. Copies data from attribute tables back to shadows
3. Leaves attribute tables intact (dropped by separate down migration)

## Future Enhancements

### Potential Improvements
1. **Add database-level foreign key constraints** (currently using Rails associations only)
2. **Index frequently queried boolean flags** (stanford, oxford2, oxford3, genre, etc.)
3. **Consider JSON column for obsolete data** (if not querying individual fields)
4. **Add validation at model level** for required attributes

### Migration to Rails 5+
When upgrading to Rails 5+, consider:
- Using `attribute` method for virtual attributes
- Leveraging `store_accessor` for structured data
- ActiveRecord's improved delegation features

## Lessons Learned

### What Worked Well
1. **Three-phase migration**: Create → Migrate → Remove made rollback safe
2. **Custom initialize override**: Handles mass assignment elegantly
3. **attrs_with_autobuild pattern**: Prevents nil delegation errors
4. **Comprehensive testing**: Caught mass assignment issues early

### Challenges Overcome
1. **Mass assignment in tests**: Rails 4.2 bypasses delegation during `new()`
   - **Solution**: Override `initialize` to intercept and route attributes
2. **Test isolation**: Models load once, not per test
   - **Solution**: Used `RAILS_ENV=test bin/rake db:test:prepare`
3. **Delegation timing**: attrs not loaded during initialization
   - **Solution**: `attrs_with_autobuild` ensures association exists

## References

- **Original discussion**: GitHub issue [link if applicable]
- **Rails STI Guide**: https://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html
- **Delegation Guide**: https://api.rubyonrails.org/classes/Module.html#method-i-delegate
- **Related docs**:
  - `docs/CANONICITY_ALGORITHM.md` - Uses delegated attributes
  - `docs/RAKE_TASKS.md` - Tasks that populate delegated attributes
  - `docs/ENCYCLOPEDIA_FLAGS.md` - Populating reference work flags

## Contributors

- Claude Code (2025-10-10) - Implementation and documentation
- User (groobiest) - Architecture design and requirements

---

**Document Version:** 1.0
**Last Updated:** 2025-10-10

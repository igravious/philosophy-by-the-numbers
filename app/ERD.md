# Entity-Relationship Diagram (ERD) Documentation

## Overview

This Rails application uses a complex schema with 32+ tables centered around philosophical texts, figures, both of those things's associated metadata, and various novel algorithms such as canonicity calculations and delta of deltas analysis. The core architecture uses **Single Table Inheritance (STI)** where the `shadows` (don't ask) table serves as the base for `Philosopher` and `Work` subclasses.

## Tables/Models Overview

### Core Entities

**1. shadows** (Base STI table)
- **Purpose**: Central entity using STI - subclasses into `Philosopher` and `Work` – many many many columns
- **Key Columns**:
  - `type`: STI discriminator ('Philosopher' or 'Work')
  - `entity_id`: Unique identifier
  - Canonicity fields: `mention`, `danker`, `measure`, `measure_pos`, boolean flags for sources (stanford, routledge, cambridge, borchert, etc.)
  - Biographical/metadata fields (delegated to type-specific attrs tables)
- **Relationships** (Base Shadow):
  - `has_many :names, dependent: :destroy` (localized labels)
- **Relationships** (Philosopher subclass):
  - `has_one :attrs, class_name: 'PhilosopherAttrs'` (extended attributes - birth/death, encyclopedia flags)
  - `has_one :obsolete_data, class_name: 'ObsoleteAttrs'` (archived canonicity data)
  - `has_many :metric_snapshots` (STI-scoped to Philosopher)
  - `has_many :creations, through: :route_a, source: :work` (via Expression join table - mirrors Work's :creators)
  - `has_many :route_a, foreign_key: :creator_id, class_name: "Expression"`
- **Relationships** (Work subclass):
  - `has_one :attrs, class_name: 'WorkAttrs'` (extended attributes - publication info, language, genre)
  - `has_one :obsolete_data, class_name: 'ObsoleteAttrs'` (archived canonicity data)
  - `has_many :metric_snapshots` (STI-scoped to Work)
  - `has_many :creators, through: :route_b, source: :philosopher` (via Expression join table)
  - `has_many :route_b, foreign_key: :work_id, class_name: "Expression"`
- **Data Source**: Manual curation + automated imports from VIAF, DBpedia, Wikipedia

**2. names**
- **Purpose**: Localized labels/translations for shadows
- **Key Columns**: `shadow_id`, `label`, `lang`, `langorder`
- **Relationships**: `belongs_to :shadow`
- **Data Source**: Manual entry + automated translations

**3. texts**
- **Purpose**: Philosophical texts/works
- **Key Columns**: `name`, `original_year`, `edition_year`, `original_language`, `name_in_english`
- **Relationships**:
  - `has_many :authors, through: :writings`
  - `has_many :tags, through: :labelings`
  - `belongs_to :fyle` (file attachment)
  - `has_many :filters, through: :includings`
- **Data Source**: Manual cataloging

**4. authors**
- **Purpose**: Authors of philosophical texts
- **Key Columns**: `english_name`, `viaf_id`, etc.
- **Relationships**: `has_many :texts, through: :writings`
- **Data Source**: Manual entry + VIAF lookups

**5. writings** (Join table)
- **Purpose**: Author-text relationships with roles
- **Key Columns**: `author_id`, `text_id`, `role` (Author/Translator/Editor)
- **Relationships**: `belongs_to :author`, `belongs_to :text`
- **Data Source**: Manual assignment

### Canonicity & Metrics

**7. canonicity_weights**
- **Purpose**: Configurable weights for canonicity algorithm
- **Key Columns**: `source_name`, `weight_value`
- **Data Source**: Algorithm tuning parameters

**8. metric_snapshots**
- **Purpose**: Historical canonicity calculation snapshots for philosophers and works (audit trail)
- **Key Columns**:
  - Polymorphic: `shadow_id`, `shadow_type` ('Philosopher' or 'Work')
  - Calculation metadata: `calculated_at`, `canonicity_weight_algorithm_version` (FK to canonicity_weights.algorithm_version)
  - Input signals (captured at calc time): `danker_score`, `linkcount`, `mention_count`, `reference_work_flags` (JSON)
  - Danker provenance: `danker_version`, `danker_file`
  - Output: `measure` (calculated score), `measure_pos` (ranking position)
  - Optional: `notes`
- **Relationships**: `belongs_to :shadow` (Philosopher or Work via shadow_type)
- **Foreign Key**: `canonicity_weight_algorithm_version` → `canonicity_weights.algorithm_version`
- **Data Source**: Automated calculations via `Philosopher#calculate_canonicity_measure` and `Work#calculate_canonicity_measure`

**9. philosopher_attrs**
- **Purpose**: Extended attributes for philosophers (split from main shadows table via Shadow STI refactor)
- **Key Columns**: `birth`, `birth_approx`, `birth_year`, `death`, `death_approx`, `death_year`, `floruit`, `period`, `gender`, `philosopher` (mention count), encyclopedia flags (oxford2, oxford3, stanford, internet, kemerling, runes, populate, dbpedia), `inpho`, `inphobool`
- **Relationships**:
  - `belongs_to :shadow`
  - Inverse: Philosopher `has_one :attrs, class_name: 'PhilosopherAttrs'`
- **Data Source**: Migrated from shadows table columns + Wikidata/encyclopedia imports

**10. work_attrs**
- **Purpose**: Extended attributes for works (split from main shadows table via Shadow STI refactor)
- **Key Columns**: `pub`, `pub_year`, `pub_approx`, `work_lang`, `copyright`, `genre`, `obsolete`, `philrecord`, `philtopic`, `britannica`, `image`, `philosophical`
- **Relationships**:
  - `belongs_to :shadow`
  - Inverse: Work `has_one :attrs, class_name: 'WorkAttrs'`
- **Data Source**: Migrated from shadows table columns + encyclopedia/PhilPapers data

**11. obsolete_attrs**
- **Purpose**: Archived canonicity data from previous algorithm versions (pre-2.0)
- **Key Columns**: `shadow_id`, `shadow_type`, `metric`, `metric_pos`, `dbpedia_pagerank`, `oxford`
- **Relationships**: `belongs_to :shadow` (polymorphic via shadow_type column)
- **Data Source**: Historical data preservation from pre-refactor schema

### Tagging & Filtering

**12. tags**
- **Purpose**: User-defined tags for texts
- **Key Columns**: `name`
- **Relationships**:
  - `has_many :labelings`
  - `has_many :texts, through: :labelings`

**13. labelings** (Join table)
- **Purpose**: Text-tag associations
- **Key Columns**: `text_id`, `tag_id`
- **Relationships**:
  - `belongs_to :tag`
  - `belongs_to :text`

**14. filters**
- **Purpose**: Named filter sets for building text corpus subsets
- **Key Columns**: `name`, `tag_id`, `inequality`, `original_year`, `name_in_english`
- **Relationships**:
  - `has_many :includings`
  - `has_many :texts, through: :includings`
- **Data Source**: User-defined filters for selecting specific texts

**15. meta_filters**
- **Purpose**: Saving complex searches on the `shadows` table (Philosophers AND Works)
- **Key Columns**: `filter` (unique name), `type` (STI discriminator - MainMetaFilter, QuestionMetaFilter)
- **Relationships**: `has_many :meta_filter_pairs, dependent: :restrict_with_error`
- **Data Source**: User-defined complex queries for philosophers and works

**16. meta_filter_pairs**
- **Purpose**: Key-value storage for meta_filter search parameters
- **Key Columns**: `meta_filter_id`, `key`, `value` (serialized Ruby objects via Base64/Marshal)
- **Relationships**: `belongs_to :meta_filter`
- **Data Source**: Search criteria stored as serialized data structures

**17. includings** (Join table)
- **Purpose**: Text-filter associations for inclusion in analysis sets
- **Key Columns**: `filter_id`, `text_id`
- **Relationships**:
  - `belongs_to :text`
  - `belongs_to :filter`
- **Data Source**: User selections for corpus building

### Semantic Web & Linked Data

**18. p_smarts** (P::Smart model)
- **Purpose**: DBpedia/Wikidata property triples for entities (Stores semantic relationships like "Plato -> teacherOf -> Aristotle")
- **Key Columns**: `entity_id`, `redirect_id`, `object_id`, `object_label`, `type` (STI for property types like P::P31, P::P19, etc.)
- **Primary Key**: Composite (`redirect_id`, `object_id`, `type`)
- **Relationships**: Links to shadows via entity_id (not declared in model, manual query)
- **Data Source**: DBpedia SPARQL queries, Wikidata API
- **Note**: Uses STI with subclasses in `app/models/p/` for specific properties (P27, P31, etc.)

**19. properties**
- **Purpose**: Extended semantic properties with inference capabilities
- **Key Columns**: `property_id`, `entity_id`, `entity_label`, `data_id`, `data_label`, `instance_id`, `instance_label`, `original_id`, `inferred_id`, `inferred_label`
- **Relationships**: None declared (manual queries to shadows/p_smarts)
- **Data Source**: Automated inference from p_smarts + manual curation

### Roles & Capacities

**20. capacities**
- **Purpose**: Categories/types of roles philosophers can have (e.g., "Logician", "Metaphysician")
- **Key Columns**: `entity_id` (unique), `label`, `relevant`, `roles_count`
- **Relationships**: `has_many :roles`
- **Data Source**: Ontology of philosophical roles from Wikidata

**21. roles**
- **Purpose**: Specific role assignments to philosophers
- **Key Columns**: `shadow_id`, `entity_id`, `label`
- **Relationships**:
  - `belongs_to :shadow` (Philosopher)
  - `belongs_to :capacity`
- **Data Source**: Manual classification + automated inference from Wikidata

### Supporting Tables

**22. dictionaries**
- **Purpose**: Source encyclopedias/dictionaries for lexical analysis
- **Key Columns**: `title`, `long_title`, `URI`, `current_editor`, `contact`, `organisation`, `entity_id`, `dbpedia_pagerank`, `year`, `missing`, `content_uri`, `encyclopedia_flag`, `machine`
- **Relationships**: `has_many :units` (implied by schema, not declared in model)
- **Data Source**: Manual encyclopedia metadata entry

**23. units**
- **Purpose**: Lexical entries extracted from dictionaries for term analysis
- **Key Columns**: `dictionary_id`, `entry`, `normal_form`, `analysis`, `confirmation`, `what_it_is`, `display_name`
- **Relationships**: `belongs_to :dictionary` (implied by schema, not declared in model)
- **Data Source**: Saffron term extraction algorithm output

**24. expressions** (Join table)
- **Purpose**: Philosopher-Work relationships (authorship)
- **Key Columns**: `creator_id` (Philosopher shadow_id), `work_id` (Work shadow_id)
- **Primary Key**: None (composite index on work_id + creator_id)
- **Relationships**:
  - `belongs_to :work, class_name: 'Shadow'`
  - `belongs_to :philosopher, foreign_key: :creator_id, class_name: 'Shadow'`
- **Data Source**: Wikidata P50 (author) property imports

**25. links**
- **Purpose**: Polymorphic-style IRI references for Semantic Web/Linked Data integration
- **Key Columns**: `table_name`, `row_id`, `IRI`, `description`
- **Relationships**: None declared (polymorphic manual queries)
- **Data Source**: Manual curation + automated Linked Data harvesting

**26. resources**
- **Purpose**: External resource metadata tracking
- **Key Columns**: `URI`
- **Relationships**: None declared
- **Data Source**: External resource tracking

**27. fyles**
- **Purpose**: File attachments and cached web resources for texts
- **Key Columns**: `URL`, `what`, `type_negotiation`, `handled`, `status_code`, `cache_file`, `encoding`, `local_file`, `health`, `health_hash`, `file_size`
- **Relationships**:
  - `has_one :text`
  - Inverse: Text `belongs_to :fyle`
- **Data Source**: Web scraping + local file management

**28. viaf_cache_items**
- **Purpose**: Cached VIAF (Virtual International Authority File) lookup results
- **Key Columns**: `personal`, `uniform_title_work`, `q` (Wikidata Q-ID), `url`
- **Primary Key**: None (composite index on personal + uniform_title_work)
- **Relationships**: None declared
- **Data Source**: VIAF API responses

**29. http_request_loggers**
- **Purpose**: HTTP API request/response logging for debugging
- **Key Columns**: `caller`, `uri`, `request`, `response`
- **Relationships**: None declared
- **Data Source**: Automated logging from Knowledge module API calls

**30. writings** (Join table)
- **Purpose**: Author-text relationships with role information
- **Key Columns**: `author_id`, `text_id`, `role` (enum: Author/Translator/Editor)
- **Relationships**:
  - `belongs_to :author`
  - `belongs_to :text`
- **Data Source**: Manual cataloging + VIAF imports

## Key Relationships Summary

```
# Core Entity Relationships
Philosopher (shadows) → has_many :creations (Works), through: :expressions
Work (shadows) → has_many :creators (Philosophers), through: :expressions
Shadow (base) → has_many :names (localized labels)
Philosopher → has_one :attrs (PhilosopherAttrs)
Work → has_one :attrs (WorkAttrs)
Shadow → has_one :obsolete_data (ObsoleteAttrs)

# Text Corpus Relationships
Author → has_many :texts, through: :writings
Text → has_many :authors, through: :writings
Text → belongs_to :fyle (file attachment)
Text → has_many :tags, through: :labelings
Text → has_many :filters, through: :includings

# Filtering & Search
Filter → has_many :texts, through: :includings
MetaFilter → has_many :meta_filter_pairs (search criteria)
Tag → has_many :texts, through: :labelings

# Semantic Web / Linked Data
P::Smart (p_smarts table) → links to Shadows via entity_id (manual queries)
Property → complex semantic relationships (manual queries)
Link → polymorphic IRI references to any table

# Roles & Capacities
Philosopher → capacities (via roles join)
Role → belongs_to :shadow (Philosopher)
Role → belongs_to :capacity
Capacity → has_many :roles

# Canonicity System
Philosopher → has_many :metric_snapshots
Work → has_many :metric_snapshots
CanonicityWeights → configuration for canonicity algorithm (no AR relationships)

# Lexical Analysis
Dictionary → has_many :units (implied, not declared)
Unit → belongs_to :dictionary (implied, not declared)
```

## Visualization Recommendations

**1. Rails ERD (Recommended)**
```bash
# Add to Gemfile
gem 'rails-erd'

# Generate diagram
bundle exec erd --filename=docs/schema_diagram
```
Creates automatic ERD diagrams from your ActiveRecord associations.

**2. SchemaSpy (Web-based)**
```bash
# Generate HTML documentation
java -jar schemaspy.jar -t sqlite -db db/development.sqlite3 -s public -o docs/schema_docs
```
Produces interactive web documentation with table details and relationships.

**3. Manual Visualization**
- Use Draw.io or Lucidchart to create custom diagrams
- Focus on the core flow: Philosophers → Works → Texts → Authors

**4. Code-based Exploration**
- Check model associations in `app/models/`
- Use Rails console: `Model.reflect_on_all_associations`

**5. Database Tools**
- SQLite Browser or DBeaver for direct schema inspection
- Generate DOT files for Graphviz visualization

## Schema Architecture Notes

The schema appears designed for a philosophical text analysis system with heavy emphasis on canonicity calculations and multi-lingual support. The STI pattern allows flexible categorization of entities as either philosophers or works while sharing common attributes.

### Canonicity Algorithm Components
- **Citation Authority**: `mention` field (citation frequency)
- **Web Authority**: `danker` field (PageRank-style scores)
- **Source Coverage**: Boolean flags for authoritative sources (Stanford, Routledge, etc.)
- **Weights**: Configurable via `canonicity_weights` table

### Delta of Deltas Algorithm
- **Purpose**: Determines optimal corpus size for term extraction
- **Process**: Adds works in significance order, measures convergence
- **Output**: Stable terminology when adding less significant works doesn't change results

### Semantic Web Integration
- **P::Smart/Properties**: Store Wikidata/DBpedia triples
- **Inference**: Generate new relationships from existing data
- **Linked Data**: Connect philosophical concepts across knowledge graphs

### Data Flow
1. **Ingestion**: VIAF, DBpedia, Wikipedia data imported into `shadows` and `viaf_cache_items`
2. **Enrichment**: Semantic properties added via `p_smarts` and `properties`
3. **Classification**: Roles and capacities assigned to philosophers
4. **Corpus Building**: Texts selected via `filters` and `includings`
5. **Analysis**: Canonicity calculations stored in `metric_snapshots`
6. **Term Extraction**: Delta of deltas algorithm determines optimal text sets
7. **Presentation**: Multi-lingual labels via `names`, relationships via join tables
8. **Filtering**: Complex queries using `filters`, `meta_filters`, and `tags`

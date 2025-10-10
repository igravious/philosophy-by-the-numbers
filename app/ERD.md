# Entity-Relationship Diagram (ERD) Documentation

## Overview

This Rails application uses a complex schema with 26 tables centered around philosophical texts, authors, and canonicity calculations. The core architecture uses **Single Table Inheritance (STI)** where the `shadows` table serves as the base for `Philosopher` and `Work` subclasses.

## Tables/Models Overview

### Core Entities

**1. shadows** (Base STI table)
- **Purpose**: Central entity using STI - subclasses into `Philosopher` and `Work`
- **Key Columns**:
  - `type`: STI discriminator ('Philosopher' or 'Work')
  - `entity_id`: Unique identifier
  - Canonicity fields: `mention`, `danker`, `metric`, boolean flags for sources (stanford, routledge, etc.)
  - Biographical: `birth`, `death`, `gender`, `period`
- **Relationships**:
  - `has_many :names` (localized labels)
  - `has_many :metric_snapshots` (for Philosophers)
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

**6. canonicity_weights**
- **Purpose**: Configurable weights for canonicity algorithm
- **Key Columns**: `source_name`, `weight_value`
- **Data Source**: Algorithm tuning parameters

**7. metric_snapshots**
- **Purpose**: Historical canonicity scores for philosophers
- **Key Columns**: `shadow_id`, `shadow_type`, `metric_value`, `timestamp`
- **Relationships**: `belongs_to :shadow` (Philosopher)
- **Data Source**: Automated calculations

### Tagging & Filtering

**8. tags**
- **Purpose**: User-defined tags for texts
- **Key Columns**: `name`
- **Relationships**: `has_many :texts, through: :labelings`

**9. labelings** (Join table)
- **Purpose**: Text-tag associations
- **Key Columns**: `text_id`, `tag_id`

**10. filters** / **11. meta_filters** / **12. meta_filter_pairs**
- **Purpose**: Complex filtering system for texts
- **Key Columns**: Various filter criteria and metadata
- **Data Source**: User-defined search filters

### Supporting Tables

**13. dictionaries** / **14. units**
- **Purpose**: Lexical analysis system
- **Key Columns**: `entry`, `normal_form`, `analysis`
- **Relationships**: `has_many :units` (Dictionary)

**15. expressions**
- **Purpose**: Philosopher-Work relationships
- **Key Columns**: `creator_id` (Philosopher), `work_id`
- **Relationships**: `belongs_to :philosopher`, `belongs_to :work`

**16. links** / **17. resources**
- **Purpose**: External references and resources
- **Key Columns**: URLs, metadata

**18. viaf_cache_items**
- **Purpose**: Cached VIAF (Virtual International Authority File) data
- **Key Columns**: `personal`, `uniform_title_work`, `q`, `url`
- **Data Source**: VIAF API responses

**19. http_request_loggers**
- **Purpose**: API request logging
- **Key Columns**: Request details, timestamps

**20. fyles**
- **Purpose**: File attachments for texts
- **Key Columns**: File metadata

**21-26. Various supporting tables**: `actual_texts`, `capacities`, `includings`, `p_smarts`, `properties`, `roles`

## Key Relationships Summary

```
Philosopher (shadows) → expressions → Work (shadows)
Author → writings → Text
Text → labelings → Tag
Text → includings → ?
Shadow → names (localized labels)
Dictionary → units (lexical entries)
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

### Data Flow
1. **Ingestion**: VIAF, DBpedia, Wikipedia data imported into `shadows` and `viaf_cache_items`
2. **Processing**: Canonicity calculations stored in `metric_snapshots`
3. **Presentation**: Multi-lingual labels via `names`, relationships via join tables
4. **Filtering**: Complex queries using `filters`, `meta_filters`, and `tags`

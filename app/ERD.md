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
  - Canonicity fields: `mention`, `danker`, `metric`, boolean flags for sources (stanford, routledge, etc.)
  - Biographical: `birth`, `death`, `gender`, `period`
- **Relationships**:
  - `has_many :names` (localized labels)
  - `has_many :metric_snapshots` (for Philosophers)
  - `has_many :roles` (through capacities)
  - `has_one :philosopher_attrs` (extended attributes)
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
- **Purpose**: Historical canonicity scores for philosophers
- **Key Columns**: `shadow_id`, `shadow_type`, `metric_value`, `timestamp`
- **Relationships**: `belongs_to :shadow` (Philosopher)
- **Data Source**: Automated calculations

**9. philosopher_attrs**
- **Purpose**: Extended attributes for philosophers (split from main shadows table)
- **Key Columns**: Biographical data, source flags, gender, etc.
- **Relationships**: `belongs_to :shadow`
- **Data Source**: Migration from shadows table + new data

**10. obsolete_attrs**
- **Purpose**: Archived canonicity data from previous algorithm versions
- **Key Columns**: Old metric values, source flags
- **Relationships**: `belongs_to :shadow`
- **Data Source**: Historical data preservation

### Tagging & Filtering

**11. tags**
- **Purpose**: User-defined tags for texts
- **Key Columns**: `name`
- **Relationships**: `has_many :texts, through: :labelings`

**12. labelings** (Join table)
- **Purpose**: Text-tag associations
- **Key Columns**: `text_id`, `tag_id`

**13. filters** / **14. meta_filters** / **15. meta_filter_pairs**
- **Purpose**: Complex filtering system for texts
- **Key Columns**: Various filter criteria and metadata
- **Data Source**: User-defined search filters

**16. includings** (Join table)
- **Purpose**: Text-filter associations for inclusion in analysis sets
- **Key Columns**: `filter_id`, `text_id`
- **Relationships**: `belongs_to :text`, `belongs_to :filter`
- **Data Source**: User selections for corpus building

### Semantic Web & Linked Data

**17. p_smarts** (P::Smart model)
- **Purpose**: DBpedia/Wikidata property triples for entities
- **Key Columns**: `entity_id`, `redirect_id`, `object_id`, `object_label`, `type`
- **Relationships**: Links to shadows via entity_id
- **Data Source**: DBpedia SPARQL queries, Wikidata API
- **Purpose**: Stores semantic relationships like "Plato -> teacherOf -> Aristotle"

**18. properties**
- **Purpose**: Extended semantic properties with inference capabilities
- **Key Columns**: `property_id`, `entity_id`, `data_id`, `instance_id`, `inferred_id`
- **Relationships**: Complex semantic relationships
- **Data Source**: Automated inference from p_smarts + manual curation

### Roles & Capacities

**19. capacities**
- **Purpose**: Categories/types of roles philosophers can have (e.g., "Logician", "Metaphysician")
- **Key Columns**: `entity_id`, `label`, `relevant`, `roles_count`
- **Relationships**: `has_many :roles`
- **Data Source**: Ontology of philosophical roles

**20. roles**
- **Purpose**: Specific role assignments to philosophers
- **Key Columns**: `shadow_id`, `entity_id`, `label`
- **Relationships**: `belongs_to :shadow`, `belongs_to :capacity`
- **Data Source**: Manual classification + automated inference

### Supporting Tables

**21. dictionaries** / **22. units**
- **Purpose**: Lexical analysis system for term extraction
- **Key Columns**: `entry`, `normal_form`, `analysis`
- **Relationships**: `has_many :units` (Dictionary)
- **Data Source**: Saffron term extraction algorithm output

**23. expressions**
- **Purpose**: Philosopher-Work relationships
- **Key Columns**: `creator_id` (Philosopher), `work_id`
- **Relationships**: `belongs_to :philosopher`, `belongs_to :work`

**24. links** / **25. resources**
- **Purpose**: External references and resources
- **Key Columns**: URLs, metadata

**26. viaf_cache_items**
- **Purpose**: Cached VIAF (Virtual International Authority File) data
- **Key Columns**: `personal`, `uniform_title_work`, `q`, `url`
- **Data Source**: VIAF API responses

**27. http_request_loggers**
- **Purpose**: API request logging
- **Key Columns**: Request details, timestamps

**28. fyles**
- **Purpose**: File attachments for texts
- **Key Columns**: File metadata

## Key Relationships Summary

```
Philosopher (shadows) → expressions → Work (shadows)
Author → writings → Text
Text → labelings → Tag
Text → includings → Filter
Shadow → names (localized labels)
Shadow → roles → Capacity
Shadow → philosopher_attrs (extended data)
Dictionary → units (lexical entries)
P::Smart → Properties (semantic triples)
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

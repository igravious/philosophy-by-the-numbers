# Canonicity Calculation Algorithm Documentation

## Overview

The **Canonicity Calculation Algorithm** implements a **Linear Weighted Combination** approach to measure the scholarly importance and authority of philosophers. It combines multiple authoritative sources, citation frequency, and web authority metrics into a single canonicity score.

## Algorithm Components

The algorithm combines three primary components using normalized importance weights:

### 1. Citation Authority Component
- **Source**: `mention` field (citation/reference frequency)
- **Normalization**: `mention / max_mention` 
- **Range**: 0.0 to 1.0
- **Purpose**: Measures how frequently a philosopher is cited or referenced

### 2. Web Authority Component  
- **Source**: `danker` field (PageRank-style web authority scores)
- **Normalization**: `danker / max_danker`
- **Range**: 0.0 to 1.0  
- **Purpose**: Measures web-based authority and prominence

### 3. Source Coverage Component (Linear Weighted Combination)
- **Sources**: Multiple authoritative philosophical reference works
- **Weight Normalization**: Philosopher bitset weights, including the conditional bonus, sum to exactly 1.0 at stored precision
- **Range**: 0.0 to 1.0
- **Purpose**: Measures coverage across authoritative philosophical sources

## Source Weights (Algorithm v2.1)

The algorithm uses configurable weights stored in the `canonicity_weights` table. Weights were determined by analyzing the relative significance of each encyclopedia source using Wikipedia PageRank data (danker scores).

| Source | Weight | Description |
|--------|--------|-------------|
| `inphobool` | 0.10 | Internet Encyclopedia of Philosophy |
| `borchert` | 0.17 | Macmillan Encyclopedia (Borchert) |
| `internet` | 0.03 | Internet sources |
| `cambridge` | 0.13 | Cambridge Dictionary of Philosophy |
| `kemerling` | 0.07 | Kemerling Philosophy Pages |
| `populate` | 0.01 | Wikipedia (as philosopher) |
| `oxford` | NULL | Oxford Reference (inactive legacy source) |
| `oxford2` | NULL | Oxford Dictionary of Philosophy, 2nd ed. (inactive legacy source) |
| `oxford3` | 0.13 | Oxford Dictionary of Philosophy, 3rd ed. |
| `routledge` | 0.17 | Routledge Encyclopedia of Philosophy |
| `dbpedia` | 0.01 | DBpedia (as philosopher) |
| `stanford` | 0.10 | Stanford Encyclopedia of Philosophy |
| `all_bonus` | 0.08 | Bonus for having any authoritative sources |
| `runes` | NULL | Philosophy Dictionary (inactive legacy source) |

**Total Active Bitset Weight**: 1.000000, including `all_bonus`. All active weights are stored directly at two decimal places. Original `2.0` weights are preserved separately for compatibility; normalized `2.1` is the Philosopher default.

### Weight Determination Methodology

Source weights were determined empirically using Wikipedia PageRank data (danker scores) to measure the relative significance and authority of each encyclopedia source:

1. **Danker Analysis**: Each encyclopedia's Wikipedia article was analyzed for its PageRank score
2. **Relative Weighting**: Weights were assigned proportionally based on comparative authority
3. **Expert Adjustment**: Final weights incorporate domain knowledge about philosophical authority

### Legacy Sources

- **`oxford`**: pre-edition-split Oxford Reference row, retained only for historical reference
- **`oxford2`**: Oxford Dictionary of Philosophy, 2nd edition, tracked for display and historical comparison
- **`runes`**: Philosophy Dictionary (Runes), excluded because it contains no female thinkers and retained only as historical metadata

All three rows are inactive and have a `NULL` weight. They do not contribute to current canonicity calculations. Active sources must have numeric weights; `NULL` distinguishes an inactive legacy source from a numeric zero. Historical flags and snapshots remain unchanged.

### Edition-Specific Tracking

The Oxford Dictionary of Philosophy is tracked separately by edition:
- **`oxford2`**: 2nd edition (inactive legacy source, weight = `NULL`, displayed in UI for reference)
- **`oxford3`**: 3rd edition (active source, weight = 0.13, contributes to canonicity)

## Mathematical Formula

```
Canonicity Score = Citation_Authority × Web_Authority × Source_Coverage × Scale_Factor

Where:
- Citation_Authority = mention / max_mention
- Web_Authority = danker / max_danker  
- Source_Coverage = Σ(source_weight_i) for all active sources + all_bonus
- Scale_Factor = 10,000,000 (for user-friendly display)
```

## Edge Case Handling

### Zero Mentions
- Philosophers with `mention = 0` get `Citation_Authority = 0`
- Results in canonicity score of 0 (appropriate for uncited figures)

### Missing Web Authority  
- Philosophers with `danker = nil` get `Web_Authority = min_rank / 2`
- Provides minimal but non-zero authority score

### No Source Coverage
- Philosophers not in any authoritative source get `Source_Coverage = 0`
- `all_bonus` only applies if philosopher appears in at least one source
- Results in canonicity score of 0

### Mathematical Safety
- Division by zero protection for `max_mention = 0` or `max_rank = 0`
- Returns 0.0 for edge cases rather than NaN or infinity
- `Canonicity::Normalization.product` enforces the normalized formula shape `S₀ × S₁ × S₂ × … × Sₙ`
- Every scalar, bitset-coverage, genre, and derived factor must be finite and within `[0, 1]`; violations raise `Canonicity::NormalizationError` naming the offending component rather than returning an invalid measure

Scalar signals use extrema fixed for the run. Bitset signals sum weighted on/off flags, including any bonus, and their total factor cannot exceed 1. Genre, role suppression, missing-value fallbacks, and author adjustments are derived rules rather than additional raw signal types.

## Configuration Management

### Weight Storage
- Weights stored in `canonicity_weights` table
- Supports multiple algorithm versions simultaneously  
- Each weight includes description and active status

### Snapshot Auditing
- Each `MetricSnapshot` stores exact weights configuration used
- Enables historical analysis and algorithm comparison
- JSON format preserves weight values and descriptions

### Version Control
- Algorithm versions (e.g., '2.0', '2.1') allow experimentation
- Active weights determined by `algorithm_version` parameter
- Backward compatibility maintained for historical calculations

## Pure V2 Calculators

The V2 implementations live in:

- `app/lib/canonicity/philosopher/v2.rb`
- `app/lib/canonicity/work/v2.rb`

Each calculator is a pure function: it receives primitive inputs, weights, normalisation context, and dependency inputs, then returns normalized and display-scaled measures plus explanatory calculation context. Calculators perform no database queries or writes. Existing model methods delegate to these implementations while preserving their snapshot and return contracts.

`metric_snapshots.measure` stores the display-scaled measure. The normalized measure is returned separately in the calculation context.

Two numerical defects are corrected:

- Work's rake task no longer applies the genre multiplier twice.
- Work's zero-denominator guard runs before either normalized or display-scaled output is derived, preventing non-finite measures.

## Metric Run Infrastructure (Phases 1–3)

The controlled canonicity architecture now includes:

- `metric_input_datasets` and `metric_input_records` for immutable populations, normalization contexts, primitive payloads, provenance, and dependencies.
- `metric_runs` for subject-scoped versions, calculator/configuration identities, frozen weights, executable signal configuration, and run status.
- `canonicity_signals` for descriptive input-signal metadata, including time-varying and unused inputs.
- `source_events` for typed old/new source values and atomic import provenance.
- `publications` for append-only publication history, with the latest ID per subject type identifying the current publication.

Run-linked snapshots preserve nullable primitive inputs and explanatory `calculation_context`, and read weights from their frozen run configuration. Legacy snapshots retain live-weight compatibility. Entity deletion no longer destroys snapshot evidence; ready datasets, completed runs, and publications are protected from mutation.

Phase 2 adds atomic Danker and reference-flag imports using the re-entrant cross-process metric operation lock. Danker validation streams and checksums the artifact in one pass, retaining only scores for the subject population instead of loading the full Wikidata file. Every import records typed old/new values with source provenance. Danker entities missing from an artifact receive `nil`, never a coerced zero. Model calculations no longer create unlinked snapshots.

Dataset capture reads its IDs and provenance in the same transaction as its primitive records. It freezes selected and normalization populations, their union of inputs, normalization context, provenance, and any completed Philosopher dependency. Captured values must agree with the latest relevant source events. Missing entities or author dependencies invalidate capture without leaving partial input records, early dependency failures leave visible invalid evidence, and missing authors are reported across all Works. Interrupted captures become invalid and interrupted runs become failed when the lock is next acquired.

`Canonicity::CalculatorInput` adapts database-round-tripped JSON payloads to the symbol-keyed V2 contracts using required-key fetches. This prevents missing keys from silently becoming fallback values during calculation or replay.

Phase 3 adds controlled calculation and recalculation over ready datasets. Each run records a subject-scoped semantic version, calculator and configuration identities, a configuration fingerprint, frozen weights and signals, and provenance. Runs complete only after selected-population coverage, finite measures, and dense ranks are verified; failures retain evidence without partial snapshots. Philosopher and Work versions begin independently at 0.7.0. Recalculation reuses the dataset and applies patch, minor, or major bumps according to input/configuration/calculator changes.

Read-only replay uses only the frozen run and dataset to recompute exact measures, population, normalization context, and dense ranks. It reports added/missing entities and measure, rank, or normalization mismatches without repairing them or writing anything.

The `/canonicity` dashboard exposes calculator identities, configuration, signal definitions, dataset status/populations/provenance/dependencies/failures, source events, run identities, snapshots, and replay results for UAT as later phases add comparison and publication.

## Usage Examples

### Basic Calculation
```ruby
philosopher = Philosopher.find(123)
score = philosopher.calculate_canonicity_measure
# Returns: normalized score 0.0-1.0 for analysis

puts philosopher.measure  
# Displays: user-friendly scaled score (e.g., 1,234,567)
```

### Custom Algorithm Version
```ruby
score = philosopher.calculate_canonicity_measure(algorithm_version: '2.1')
```

### With Danker Data Context
```ruby
score = philosopher.calculate_canonicity_measure(
  algorithm_version: '2.0',
  danker_info: { 
    version: '2024-10-04', 
    file: '2024-10-04.all.links.c.alphanum.csv' 
  }
)
```

## Return Values

- **Method Return**: Normalized score (0.0 to 1.0) for algorithmic analysis
- **Database Storage**: Scaled score (`measure` field) for user display and ranking  
- **Snapshot Creation**: Automatic audit trail with exact configuration used

## Performance Considerations

- Global max/min calculations performed once per batch
- Weights loaded once per algorithm version  
- Database queries optimized with proper indexing
- Edge case handling prevents expensive exception handling

## Future Extensibility

- New sources easily added via `canonicity_weights` table
- Algorithm versions support A/B testing and gradual rollouts
- JSON weight storage enables complex configuration scenarios
- Snapshot system enables longitudinal studies and trend analysis
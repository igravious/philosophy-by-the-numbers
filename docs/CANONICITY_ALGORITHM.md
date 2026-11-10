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

**Total Active Bitset Weight**: 1.000000, including `all_bonus`. All active weights are stored directly at two decimal places. Original `2.0` is retained for historical replay only because its source weights can exceed 1; normalized `2.1` is the Philosopher default. Configuration `2.2` copies `2.1` with Routledge changed from `0.17` to `0.16`, preserving the original weight set for controlled comparison.

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

## Zero Scores and Edge Cases

A zero measure means **no positive score under the current canonicity inputs and derivation rules**. It does not mean that an entity is not a philosopher or not a philosophical work, and it is not a reason by itself to remove or reclassify that entity. Zero-valued inputs and missing inputs must be audited separately.

### Mention and Role Suppression

Philosophers with raw `mention = 0` have zero citation authority and therefore zero measure. A missing philosophy mention is also an input-quality warning: it may indicate limited source text, scraping or classification problems, or genuinely absent terminology, rather than insignificance. Positive raw mentions can also become zero through the pinned legacy role-suppression rule when more than one configured capacity matches. Work differs deliberately: nil or zero Work mentions default to `0.5` before normalization.

### Missing and Zero Danker Values

Philosopher `danker = nil` uses the run's frozen `min_rank` fallback. That context is calculated as half the minimum captured rank, including zero, so it can itself be `0.0`; a missing value does not guarantee a nonzero score. Work excludes both zero and NULL when selecting its ranked minimum, so its fallback is normally positive, but an explicit raw `danker = 0.0` remains zero. Danker imports preserve omitted entities as `nil`; they never coerce omission to numeric zero.

### Source Coverage and Author Adjustment

No active Philosopher source coverage produces a zero source factor. Work gives zero source coverage a `0.1` fallback, but the legacy author adjustment can cancel that coverage when all linked authors have zero measures. Work applies genre exactly once and guards zero denominators before deriving either output.

### Published Zero-Score Audit

The currently published runs, Philosopher `0.10.0` and Work `0.7.2`, contain 3,358 zero-measure philosophers and 9 zero-measure Works:

- 3,354 philosophers have raw `mention = 0`.
- 4 philosophers have positive raw mentions suppressed by the role rule.
- 9 Works have positive source coverage cancelled by the all-zero-author adjustment.
- No zero-measure philosopher or Work has a zero Danker factor.

Before genuine-input restoration, 277 philosophers and 626 Works had stored `danker = 0.0` even though all of them were absent from the genuine 2019 artifact. Historical import code coerced those missing values to numeric zero; they were not genuine source zeros. Restoration changed them to `nil`, moving 210 philosophers and all 626 Works off zero. The other 67 philosophers remained zero because of raw zero mention, and the 9 Works remained zero through the author adjustment.

Recheck the cause breakdown after every capture and before every publication. Distinguish genuine numeric zero, missing `nil`, and derived zero, and never treat the count alone as a philosophical classification.

### Mathematical Safety

- Division by zero protection for `max_mention = 0` or `max_rank = 0` returns 0.0 rather than NaN or infinity.
- `Canonicity::Normalization.product` enforces the normalized formula shape `S₀ × S₁ × S₂ × … × Sₙ`.
- Every scalar, bitset-coverage, genre, and derived factor must be finite and within `[0, 1]`; violations raise `Canonicity::NormalizationError` naming the offending component rather than returning an invalid measure.

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

## Controlled Runs and Publication (Phases 1–5)

The architecture includes immutable input datasets/records, subject-scoped metric runs, descriptive signal metadata, typed source events, and append-only publications. Run-linked snapshots preserve nullable inputs, explanatory calculation context, and frozen run weights. Entity deletion does not erase evidence, and ready datasets, completed runs, and publications are mutation-protected. `signal_config` is descriptive fingerprint evidence, not an executable calculator argument.

Danker and reference-flag imports update inputs and source events atomically under the re-entrant cross-process lock. Danker validation streams and checksums the complete artifact before the transaction. Every omitted entity receives `nil`, never a coerced zero. Model calculations do not create unlinked snapshots.

Capture freezes selected and normalisation IDs, their primitive inputs, extrema, provenance, and any completed Philosopher dependency in one transaction. Selected IDs must be contained in normalisation IDs. Work capture requires a completed Philosopher run and freezes linked-author snapshot IDs and measures. Missing entities or authors invalidate capture without partial records; interrupted captures and runs are reconciled when the lock is next acquired. `Canonicity::CalculatorInput` uses required-key fetches so absent payload keys cannot silently become fallbacks.

Calculation pre-flight rejects cross-subject configurations and source weights above 1 before allocating a run version. Work's check covers Borchert, Cambridge, Routledge, PhilPapers, and `all_bonus`, excluding genre multipliers. Completed runs verify exact selected coverage, finite measures, and dense ranks. Replay recomputes all of these read-only and reports every mismatch without repairing it.

Publication revalidates that selected, normalisation, snapshot, and current subject populations are identical, then updates display measures and ranks with bound ActiveRecord writes in the same transaction as the history record. Republishing appends history, interruption rolls everything back, and dependency mismatches warn on the dashboard and CLI without blocking. `metric:compare` reports measure/rank movement, added/missing entities, population and normalisation differences, and calculator/configuration differences. Legacy `order2` and `new_order` tasks only delegate to explicit publication.

The `/canonicity` dashboard exposes all of this state. Run snapshots are paginated 100 at a time, and index eligibility batches current-population and snapshot queries rather than issuing them independently for every run.

Real-data verification includes configuration `2.2` and small run `0.9.0`, which left `2.1` unchanged. A later synthetic scenario contaminated four live inputs and produced Work run `0.7.1`; that immutable run remains technically publish-eligible but is permanently quarantined and must never be published. The genuine 2019 artifact was then re-imported atomically for both subjects, restoring all four values and converting 903 legacy coerced zeros to `nil`. Full-population Philosopher run `0.10.0` and Work run `0.7.2` replayed exactly and are the current publications, with zero display mismatches and no dependency warning. Default Work capture now selects the latest completed full-population Philosopher run rather than a newer partial experiment.

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
  algorithm_version: '2.1',
  danker_info: { 
    version: '2024-10-04', 
    file: '2024-10-04.all.links.c.alphanum.csv' 
  }
)
```

## Return Values

- **Method Return**: Normalized score (0.0 to 1.0) for algorithmic analysis
- **Database Storage**: Scaled score (`measure` field) for user display and ranking  
- **Snapshot Creation**: Controlled runs create run-linked snapshots with frozen configuration; model calculations do not automatically create unlinked snapshots

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
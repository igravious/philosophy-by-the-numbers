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
- **Weight Normalization**: Individual weights sum to approximately 1.0
- **Range**: 0.0 to ~1.3 (includes all_bonus)
- **Purpose**: Measures coverage across authoritative philosophical sources

## Source Weights (Algorithm v2.0)

The algorithm uses configurable weights stored in the `canonicity_weights` table:

| Source | Weight | Description |
|--------|--------|-------------|
| `inphobool` | 0.15 | Internet Encyclopedia of Philosophy |
| `borchert` | 0.25 | Macmillan Encyclopedia (Borchert) |
| `internet` | 0.05 | Internet sources |
| `cambridge` | 0.20 | Cambridge Dictionary of Philosophy |
| `kemerling` | 0.10 | Kemerling Philosophy Pages |
| `populate` | 0.02 | Wikipedia (as philosopher) |
| `oxford` | 0.20 | Oxford Reference |
| `routledge` | 0.25 | Routledge Encyclopedia of Philosophy |
| `dbpedia` | 0.01 | DBpedia (as philosopher) |
| `stanford` | 0.15 | Stanford Encyclopedia of Philosophy |
| `all_bonus` | 0.13 | Bonus for having any authoritative sources |
| `runes` | 0.00 | Runes (excluded as biased) |

**Total Weight Sum**: ~1.31 (intentionally slightly over 1.0 as no philosopher achieves perfect scores)

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
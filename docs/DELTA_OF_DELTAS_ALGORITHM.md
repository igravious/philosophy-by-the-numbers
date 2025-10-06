# Delta of Delta Algorithm Documentation

## Overview

The Delta of Delta algorithm is a convergence detection method for term extraction analysis that determines when adding more philosophical works to a corpus no longer significantly changes the extracted terminology. This helps identify the optimal corpus size for comprehensive term analysis.

## Algorithm Description

### Core Concept

The algorithm implements a "difference of differences" approach:

1. **Sequential Processing**: Process philosophical works in **significance order** (most significant first)
2. **Cumulative Analysis**: Run Saffron term extraction on progressively larger sets (A, A+B, A+B+C, ...)
3. **Delta Calculation**: Calculate differences between consecutive term extraction results
4. **Delta of Delta**: Compare consecutive deltas to measure the rate of change in the rate of change
5. **Convergence Detection**: Stop when the delta of delta drops below a threshold

**CRITICAL**: Works must be ordered from **most significant to least significant** for the algorithm to work correctly. The convergence detection relies on this ordering to determine when adding less significant works no longer meaningfully changes the term extraction results.

### Mathematical Formulation

Given works W₁, W₂, W₃, ... in **decreasing order of significance** (W₁ most significant):

- **Cumulative Sets**: S₁ = {W₁}, S₂ = {W₁, W₂}, S₃ = {W₁, W₂, W₃}, ...
- **Saffron Results**: R₁ = Saffron(S₁), R₂ = Saffron(S₂), R₃ = Saffron(S₃), ...
- **Deltas**: δ₁₂ = diff(R₁, R₂), δ₂₃ = diff(R₂, R₃), δ₃₄ = diff(R₃, R₄), ...
- **Delta of Deltas**: Δδ₁₂₋₂₃ = diff(δ₁₂, δ₂₃), Δδ₂₃₋₃₄ = diff(δ₂₃, δ₃₄), ...

**Convergence Condition**: |Δδᵢ| < threshold

**Significance Ordering**: The algorithm assumes that adding W₁ (most significant) will cause large changes in term extraction, while adding Wₙ (least significant) will cause minimal changes. Convergence occurs when the rate of change stabilizes as less significant works are added.

## Implementation

### Core Classes

#### `DeltaOfDeltaProcessor`

Main orchestration class that manages the entire workflow.

**Key Methods:**
- `process()` - Main entry point, runs complete algorithm
- `process_cumulative_works(works, iteration_id)` - Processes a cumulative set
- `calculate_delta(result_a, result_b)` - Calculates differences using custom strategies
- `calculate_delta_of_delta(delta_a, delta_b)` - Computes delta of delta

**Configuration:**
- `works`: Array of work file paths in significance order
- `output_dir`: Directory for results and intermediate files
- `threshold`: Convergence threshold (default: 0.1)
- `diff_strategy`: Strategy for calculating deltas (default: :composite)

#### `CustomDiffStrategies`

Implements various strategies for calculating differences between Saffron results.

**Available Strategies:**

1. **TermWeightStrategy** - Focuses on term frequency and weight changes
   - Calculates added/removed terms
   - Measures weight changes for common terms
   - Combines structural and weight-based changes

2. **SemanticSimilarityStrategy** - Uses semantic similarity between term sets
   - Calculates Jaccard similarity/distance
   - Uses Saffron's term similarity matrices when available
   - More sophisticated than simple set operations

3. **DocumentDistributionStrategy** - Analyzes document-term distribution changes
   - Calculates entropy changes in term distributions
   - Measures document coverage changes
   - Analyzes within-document term distribution shifts

4. **CompositeStrategy** - Combines multiple strategies with configurable weights
   - Default: 40% term weight, 30% semantic similarity, 30% document distribution
   - Provides comprehensive analysis across multiple dimensions

### File Structure

```
lib/delta_analysis/
├── delta_of_delta_processor.rb    # Main algorithm implementation
├── custom_diff_strategies.rb      # Delta calculation strategies
└── ...

lib/tasks/
└── delta_analysis.rake            # Rake tasks for running analysis

scripts/
└── test_delta_workflow.rb         # Test script for validation

tmp/delta_analysis/                # Default output directory
├── saffron_results/               # Raw Saffron outputs
├── deltas/                        # Delta calculations
├── reports/                       # Analysis reports
└── ...
```

## Usage

### Basic Usage

```bash
# Run on all text files in _txt directory
bin/rake delta_analysis:process

# Specify custom parameters
bin/rake delta_analysis:process[_txt/2020/*.txt,tmp/my_analysis,0.05,composite]
```

### Parameters

- `works_pattern`: Glob pattern for finding works (default: `_txt/**/*.txt`)
- `output_dir`: Output directory (default: `tmp/delta_analysis`)
- `threshold`: Convergence threshold (default: `0.1`)
- `diff_strategy`: Delta calculation strategy (default: `composite`)

### Available Diff Strategies

- `term_weight`: Focus on term frequency/weight changes
- `semantic_similarity`: Use semantic similarity measures
- `document_distribution`: Analyze document-term distributions
- `composite`: Combine all strategies (recommended)

### Programmatic Usage

```ruby
require_relative 'lib/delta_analysis/delta_of_delta_processor'

# Find works (ensure they're in significance order)
works = Dir.glob('_txt/**/*.txt').sort_by { |f| significance_score(f) }

# Initialize processor
processor = DeltaOfDeltaProcessor.new(
  works: works,
  output_dir: 'tmp/my_analysis',
  threshold: 0.1,
  diff_strategy: :composite
)

# Run analysis
result = processor.process

# Access results
puts "Converged: #{result[:summary][:convergence_reached]}"
puts "Works processed: #{result[:summary][:total_works_processed]}"
```

## Output

### Directory Structure

```
output_dir/
├── saffron_results/              # Raw Saffron outputs for each iteration
│   ├── A/                        # First work
│   ├── B/                        # First + second work
│   └── C/                        # First + second + third work
├── deltas/                       # Delta calculations
│   ├── delta_A_to_B.json
│   ├── delta_B_to_C.json
│   └── delta_of_delta_*.json
├── reports/                      # Analysis reports
│   ├── parsed_results_A.json
│   ├── parsed_results_B.json
│   └── final_report.json
└── saffron_config.json          # Saffron configuration used
```

### Key Output Files

#### `final_report.json`
Comprehensive summary of the entire analysis including:
- Processing summary (works processed, convergence status)
- Results summary for each iteration
- Delta magnitudes over time
- Delta of delta progression

#### Delta Files
Each delta calculation produces a JSON file with:
- Comparison details (which iterations)
- Strategy used
- Magnitude score
- Detailed breakdown of changes

## Configuration

### Saffron Configuration

The processor automatically creates a default Saffron config file if none is provided:

```json
{
  "extractors": {
    "term": {
      "algorithm": "kea",
      "threshold": 0.1
    }
  },
  "consolidators": {
    "concept": {
      "algorithm": "exact_match"
    }
  }
}
```

You can provide a custom config file in the constructor.

### Threshold Selection

Choosing an appropriate threshold depends on your specific use case:

- **0.01-0.05**: Very sensitive, detects small changes
- **0.1**: Default, balanced sensitivity
- **0.2-0.5**: Less sensitive, requires larger changes to converge

### Strategy Selection

- **For small corpora**: Use `term_weight` strategy
- **For semantic analysis**: Use `semantic_similarity` strategy  
- **For document-focused analysis**: Use `document_distribution` strategy
- **For comprehensive analysis**: Use `composite` strategy (recommended)

## Testing

### Quick Test

```bash
# Create test works and run a quick validation
bin/rake delta_analysis:create_test_works
ruby scripts/test_delta_workflow.rb
```

### Validate Saffron Installation

```bash
bin/rake delta_analysis:test_saffron
```

### List Available Works

```bash
bin/rake delta_analysis:list_works
bin/rake delta_analysis:list_works[_txt/2020/*.txt]
```

## Work Selection and Significance Ordering

### Significance Metrics

The algorithm requires works to be ordered by significance. CorpusBuilder provides several metrics:

1. **Canonicity Measure**: From the CANONICITY_ALGORITHM (most recommended)
2. **Linkcount**: Number of Wikidata sitelinks (indicates notability)
3. **Mixed Ranking**: Weighted combination of canonicity and linkcount
4. **Custom Metrics**: Domain-specific significance measures

### Selection Strategies

#### By Canonicity (Recommended)
```ruby
# Uses the canonicity algorithm results
works = Work.joins(text: :fyle)
           .where.not(obsolete: true)
           .order(canonicity_measure: :desc)  # MOST significant first
           .limit(50)
```

#### By Linkcount
```ruby
# Uses Wikidata notability as proxy for significance
works = Work.joins(text: :fyle)
           .where.not(obsolete: true) 
           .order(linkcount: :desc)  # MOST linked first
           .limit(50)
```

#### Mixed Ranking
```ruby
# Combines multiple significance metrics
works = Work.joins(text: :fyle)
           .where.not(obsolete: true)
           .select('works.*, (canonicity_measure * 0.6 + normalized_linkcount * 0.4) as mixed_score')
           .order('mixed_score DESC')  # HIGHEST score first
           .limit(50)
```

## Integration with CorpusBuilder

The Delta of Delta algorithm integrates with the existing CorpusBuilder Rails application:

1. **Work Selection**: Use the existing `shadows` table to determine work significance
2. **File Management**: Leverage the `fyles` table for file location and metadata
3. **Progress Tracking**: Results can be stored in the database for historical analysis
4. **Rake Tasks**: Follow existing patterns in `lib/tasks/`

### Example Integration

```ruby
# CORRECT: Order by significance (most significant first)
significant_works = Work.joins(text: :fyle)
  .where.not(obsolete: true)
  .where.not(fyles: { local_file: nil })
  .order(canonicity_measure: :desc)  # CRITICAL: DESC for most→least
  .limit(50)
  .map { |work| File.join(Rails.root, work.text.fyle.local_file) }

processor = DeltaOfDeltaProcessor.new(
  works: significant_works,  # Already in correct order
  output_dir: "tmp/delta_analysis_#{Date.today}",
  threshold: 0.1
)

result = processor.process
```

### Work-Based Processor

For easier integration, use the `WorkBasedDeltaProcessor`:

```ruby
# Automatically handles significance ordering and file path extraction
processor = WorkBasedDeltaProcessor.by_canonicity(
  max_works: 50,
  min_canonicity: 0.1,
  output_dir: 'tmp/canonical_analysis',
  threshold: 0.05
)

result = processor.process
```

## Performance Considerations

1. **Saffron Overhead**: Term extraction can be time-intensive for large works
2. **File I/O**: Results are written to disk at each step for debugging/recovery
3. **Memory Usage**: Large corpora may require memory optimization
4. **Parallelization**: Current implementation is sequential; could be parallelized

## Troubleshooting

### Common Issues

1. **Saffron Not Found**: Ensure installed at `~/saffron-os`
2. **Maven Build Failed**: Check Java version and Maven installation
3. **Memory Issues**: Reduce corpus size or increase JVM heap
4. **Permission Errors**: Check write permissions on output directory

### Debug Mode

Enable detailed logging by examining intermediate files in the output directory:
- Check Saffron raw outputs in `saffron_results/`
- Examine delta calculations in `deltas/`
- Review parsed results in `reports/`

## Future Enhancements

1. **Parallel Processing**: Run Saffron on multiple works simultaneously
2. **Adaptive Thresholds**: Automatically adjust threshold based on corpus characteristics
3. **Visualization**: Generate charts showing convergence progression
4. **Database Integration**: Store results in CorpusBuilder database
5. **Custom Saffron Configs**: Per-iteration configuration optimization
6. **Statistical Analysis**: Add confidence intervals and significance testing
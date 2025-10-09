
## Canonicity Migration Status

### Philosopher Canonicity: ✅ COMPLETE
**Status:** Fully migrated to MetricSnapshot with polymorphic associations

**Implementation:**
- `Philosopher#calculate_canonicity_measure` method (shadow.rb:151-212)
- Creates `MetricSnapshot` records with shadow_type='Philosopher'
- Uses `CanonicityWeights` table (algorithm_version='2.0')
- 11 encyclopedia sources + mention + danker metrics
- Full audit trail in metric_snapshots table

### Work Canonicity: ✅ COMPLETE (as of 2025-10-09)
**Status:** Fully implemented with polymorphic MetricSnapshot

**Implementation:**
- `Work#calculate_canonicity_measure` method (shadow.rb:238-319)
- Creates `MetricSnapshot` records with shadow_type='Work'
- Uses `CanonicityWeights` table (algorithm_version='2.0-work')
- 3 encyclopedia sources (borchert, cambridge, routledge) + philpapers + genre + author_existence
- Full audit trail in metric_snapshots table

**Work-Specific Sources:**
1. Encyclopedia flags: borchert (0.25), cambridge (0.20), routledge (0.25)
2. PhilPapers signal: philrecord OR philtopic (0.20)
3. Genre multiplier: philosophical (1.0) vs other (0.5)
4. All bonus: 0.10 (if at least one source present)
5. Author existence penalty: -sourcey if all authors have measure=0

**Migration Details:**
- Migration 20251009021742: Made MetricSnapshot polymorphic (shadow_id + shadow_type)
- Migration 20251009021950: Added Work canonicity weights
- Both Philosopher and Work now use `has_many :metric_snapshots, as: :shadow`

### Remaining Tasks:
1. **Optional:** Refactor `shadow:work:measure` rake task to use new `Work#calculate_canonicity_measure` method
2. **Recommended:** Write tests for Work canonicity calculation
3. **Future:** Gradually migrate rake tasks to use snapshots instead of direct shadow record updates

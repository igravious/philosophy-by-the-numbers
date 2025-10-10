# Encyclopedia Flag Population System

## Overview

The encyclopedia flag system tracks which philosophers appear in various philosophy reference works. This metadata is used to calculate canonicity scores - philosophers appearing in more prestigious encyclopedias receive higher scores.

## The Problem (2025-10-10)

**Symptoms:**
- Both `oxford2` and `oxford3` dictionaries showed the same count (690 philosophers)
- No philosophers had `oxford2=true` or `oxford3=true` flags set
- The `dictionaries` table had `encyclopedia_flag='oxford'` for both editions (wrong)

**Root Cause:**
When Oxford Dictionary 3rd edition was added, a database migration split the `oxford` column into `oxford2` and `oxford3`. However, `import/sauce.rb` was never updated to use the new column names, so subsequent flag population runs failed silently.

**Three Bugs Fixed:**
1. **Line 25:** `$switch = :oxford` → should be `$switch = :oxford2`
2. **Line 29:** `$switch = :oxford` → should be `$switch = :oxford3`
3. **Line 551:** Case statement missing `:oxford2` and `:oxford3`

## Architecture

### Master Script: `import/sauce.rb`

Universal encyclopedia flag setter that works for all 9 reference sources.

**Supported Sources:**

| CLI Argument | Flag Column | Scraped File | Source |
|--------------|-------------|--------------|--------|
| `ox_2nd` | `oxford2` | `odp_tweak.txt` | Oxford Dictionary of Philosophy 2nd ed |
| `ox_3rd` | `oxford3` | `odp_3rd_tweak.txt` | Oxford Dictionary of Philosophy 3rd ed |
| `stanford` | `stanford` | `sep_date.txt` | Stanford Encyclopedia of Philosophy |
| `cambridge` | `cambridge` | `cupdop.txt` | Cambridge Dictionary of Philosophy |
| `routledge` | `routledge` | `rep_uniq.txt` | Routledge Encyclopedia of Philosophy |
| `internet` | `internet` | `iep_date.txt` | Internet Encyclopedia of Philosophy |
| `kemerling` | `kemerling` | `dop_done.txt` | Dictionary of Philosophical Terms |
| `borchert` | `borchert` | `good_borchert.txt` | Macmillan Encyclopedia (Borchert) |
| `runes` | `runes` | `runic.txt` | Dictionary of Philosophy (Runes) |

### Data Flow

```
Scraped Data          sauce.rb Matching              Database
─────────────         ──────────────────             ────────
odp_3rd_tweak.txt  →  Name matching (exact)    →     oxford3=true
(3,492 entries)       ├─ Date validation             (689 philosophers)
                      ├─ Fuzzy matching
                      └─ Q-ID fallback
```

## The Matching Algorithm

### 1. Name Extraction & Normalization

```ruby
# Input: "Anselm, St (1033-1109)"
# Parse into:
name = "Anselm"          # Last name
comma = "St"             # First name/title
full = "St Anselm"       # Full name
birth = 1033
death = 1109
```

**Name Normalization:**
- Removes bracketed text: `[ibn Sina] Avicenna` → `Avicenna`
- Applies mappings from `Knowledge::Wikidata::MAP_NAME` hash
- Handles "Last, First" vs "First Last" formats

### 2. Database Matching (via `app/models/name.rb`)

**Two-stage lookup:**

1. **Exact match** (`Name.exact_label_count`):
   ```ruby
   SELECT shadow_id, COUNT(*) FROM names
   WHERE label = 'Anselm'
   GROUP BY shadow_id
   ```

2. **Fuzzy match** (`Name.rough_label_count`) if exact fails:
   ```ruby
   SELECT shadow_id, COUNT(*) FROM names
   WHERE label LIKE '% Anselm %' OR label LIKE '% Anselm'
      OR label LIKE 'Anselm %' OR label = 'Anselm'
   GROUP BY shadow_id
   ```

**Memcached Integration:**
- Cache key: `"EC,#{name}"` (exact) or `"LC,#{name}"` (fuzzy)
- Hit rate: 90%+ on subsequent encyclopedia runs
- Graceful degradation if Memcached unavailable

### 3. Date Validation

Fuzzy date matching with different tolerances based on certainty:

**Non-circa dates (high certainty):**
- Birth **and** death exact match → ✓ MATCH
- Birth exact **and** death ±5 years → ✓ MATCH
- Birth ±5 years **and** death exact → ✓ MATCH
- Birth ±1 year **and** death ±3 years → ✓ MATCH
- Birth ±3 years **and** death ±1 year → ✓ MATCH

**Circa dates (lower certainty):**
- Birth **and** death exact match → ✓ MATCH
- Birth exact **and** death ±10 years → ✓ MATCH
- Birth ±10 years **and** death exact → ✓ MATCH
- Birth ±2 years **and** death ±6 years → ✓ MATCH
- Birth ±6 years **and** death ±2 years → ✓ MATCH

**Date Parsing:**
Handles complex formats via regex patterns:
- `(1033-1109)` - standard range
- `(c. 1033-1109)` - circa birth
- `(1033-c. 1109)` - circa death
- `(c. 1033-c. 1109)` - both circa
- `(4 BC–AD 65)` - BC/AD transition
- `(b. 1950)` - living philosophers
- `(1033)` - birth only (Oxford format)

### 4. Fallback: Manual Q-ID Mappings

If name/date matching fails, check `import/q_name.rb`:

```ruby
Q_NAME = {
  'Anselm, St' => 'Q43939',
  'Darwin, Charles' => 'Q1035',
  # ... manual mappings for ambiguous cases
}
```

Creates new `Philosopher` record with `entity_id` from Wikidata Q-ID.

### 5. Flag Setting

```ruby
def switch_on!(philosopher)
  philosopher.send("#{$switch}=", true)  # e.g., philosopher.stanford = true
  philosopher.save!
end
```

## Usage

### Prerequisites

1. **Scraped data files** must exist in `import/www.*.com/` directories
   - Named `*_tweak.txt` (cleaned versions)
   - NOT in git (copyrighted material)
   - Obtained via `bin/rake snarf:*` tasks or from backup

2. **Memcached running** (highly recommended):
   ```bash
   ps aux | grep memcache
   sudo systemctl start memcached  # if not running
   ```

### Running Flag Population

```bash
# Single source
bin/rails runner import/sauce.rb oxford3

# All sources (example batch script)
for source in ox_2nd ox_3rd stanford cambridge routledge internet kemerling borchert runes; do
  echo "Processing $source..."
  bin/rails runner import/sauce.rb $source
done
```

### Verification

```bash
bin/rails runner "
  puts 'Encyclopedia Flag Counts:'
  puts '  Oxford 2nd: ' + Philosopher.where(oxford2: true).count.to_s
  puts '  Oxford 3rd: ' + Philosopher.where(oxford3: true).count.to_s
  puts '  Stanford: ' + Philosopher.where(stanford: true).count.to_s
  puts '  Cambridge: ' + Philosopher.where(cambridge: true).count.to_s
"
```

### Update Dictionaries Table

After populating flags, update the `encyclopedia_flag` column:

```ruby
bin/rails runner "
  Dictionary.find(2).update!(encyclopedia_flag: 'oxford2')
  Dictionary.find(12).update!(encyclopedia_flag: 'oxford3')
"
```

## Performance

**Typical Run (Oxford 3rd Edition):**
- **Entries processed:** 3,492
- **Philosophers matched:** 689
- **Time (with Memcached):**
  - First run: ~90 seconds
  - Subsequent runs: ~6 seconds (cache hits)
- **Time (without Memcached):** 5-10 minutes

**Why It's Fast with Memcached:**
Each entry triggers 1-2 name lookups. With 3,492 entries × 2 queries = ~7,000 database queries. Memcached reduces this to ~300 queries (90%+ hit rate from previous runs).

## Output Interpretation

### Progress Bar
```
[####################################### ] [3300/3492] [ 94.46%] [00:05] [00:00]
```
- **3300/3492:** Entries processed / Total entries
- **94.46%:** Completion percentage
- **00:05:** Elapsed time
- **00:00:** Estimated time remaining

### Status Messages

- `<- Q43939 (Anselm)` - Successfully matched and flagged
- `-> Q43939 (Anselm)` - Created new philosopher from Q-ID
- `@ 22852` - Missing year data (logged but non-fatal)
- `_ bad date: ...` - Inconsistent birth/death dates (logged but non-fatal)

### Final Statistics
```
tot: 3492      # Total entries in file
nam: 751       # Entries with parseable names/dates
 ==: 744       # Successful matches
swi: 689       # Unique philosophers flagged (switch_on!)
twi: 1         # Date hacks added
```

## Troubleshooting

### "No server available (Dalli::RingError)"

**Problem:** Memcached not running
**Solution:**
```bash
sudo systemctl start memcached
```

**Workaround:** Error handling added 2025-10-10, script continues without caching (slower)

### Flags not being set

**Check:**
1. Correct `$switch` value in `sauce.rb` (lines 25, 29, etc.)
2. `$switch` included in case statement (line 551)
3. Database column exists: `Philosopher.column_names.include?('oxford3')`

### Wrong count after running

**Possible causes:**
1. SQLite boolean format mismatch (use ActiveRecord methods, not raw SQL)
2. Wrong `encyclopedia_flag` in `dictionaries` table
3. Cache from previous broken run (clear: `echo 'flush_all' | nc localhost 11211`)

## Directory Resolution

As of 2025-10-10, `sauce.rb` checks both `import/` and `slurp/` directories:

```ruby
def find_data_dir(subdir)
  import_path = Rails.root.join('import', subdir)
  slurp_path = Rails.root.join('slurp', subdir)

  Dir.exist?(import_path) ? import_path :
  Dir.exist?(slurp_path) ? slurp_path :
  raise "Neither #{import_path} nor #{slurp_path} exists!"
end
```

## Data Sources & Scraping

### Scraping Tasks

```bash
bin/rake snarf:odp_2nd     # Oxford 2nd edition
bin/rake snarf:odp_3rd     # Oxford 3rd edition
bin/rake snarf:sep         # Stanford Encyclopedia
bin/rake snarf:iep         # Internet Encyclopedia
bin/rake snarf:rep         # Routledge Encyclopedia
```

### File Format

**Input (`*_tweak.txt`):**
```
Anselm, St (1033-1109)
Aristotle (384-322 BC)
Avicenna (980-1037)
Berkeley, George (1685-1753)
```

**Cleaned from raw scrapes:**
- `*_tweak.txt` - Hand-corrected, canonical version (USE THIS)
- Original files may have encoding issues, duplicates, etc.

### Copyright Notice

Scraped encyclopedia data is copyrighted material used under fair use for metadata extraction. **Never commit `*_tweak.txt` files to git.**

## Related Documentation

- `CLAUDE.md` - Project overview and coding guidelines
- `docs/CANONICITY_ALGORITHM.md` - How encyclopedia flags affect scores
- `docs/RAKE_TASKS.md` - Complete list of scraping and data tasks
- `import/q_name.rb` - Manual Q-ID mappings for ambiguous philosophers

## Changelog

**2025-10-10:**
- Fixed oxford2/oxford3 bugs in `sauce.rb` (lines 25, 29, 551)
- Added Memcached error handling to `app/models/name.rb`
- Added directory resolution (`import/` or `slurp/`)
- Documented complete workflow
- Successfully populated 628 oxford2 + 689 oxford3 philosophers

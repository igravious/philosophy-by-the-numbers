# SQLite Boolean Handling in Rails 4.2

## Issue

**Date Discovered:** 2025-10-09

Rails 4.2 with SQLite3 has inconsistent boolean value handling across different migration methods.

## The Problem

SQLite doesn't have a native boolean type - it stores booleans as integers (0/1) or text ('t'/'f'). Rails 4.2 can create inconsistencies:

1. **Old migration approach** (via `create_table` with seed data using SQL `INSERT`):
   - Values stored as: `0` (false) and `1` (true)
   - Example: Original `CreateCanonicityWeights` migration (20251004222259)

2. **New migration approach** (via `execute` with string interpolation):
   - Values stored as: `'f'` (false) and `'t'` (true)
   - Example: `SplitOxfordWeightsInCanonicityWeights` migration (20251009095419)

3. **ActiveRecord queries**:
   - `WHERE "table"."column" = 't'` (expects text format)
   - This fails to match integer format (`1`/`0`)

## Impact

Scope queries like `.where(active: true)` generate SQL with `= 't'` which doesn't match integer `1` values, causing empty result sets despite correct data existing in the database.

## Solution

**Always use ActiveRecord methods for boolean updates in migrations**, not raw SQL:

### ❌ Bad (causes inconsistency):
```ruby
execute <<-SQL
  INSERT INTO table (active) VALUES (true)
SQL
```

### ✅ Good (consistent format):
```ruby
Model.create!(active: true)
# or
Model.where(condition).update_all(active: true)
```

## Fix for Existing Data

If you encounter mixed boolean formats:

```ruby
# In a new migration
def up
  # Let Rails handle the boolean conversion
  Model.where("active = 1 OR active = '1'").update_all(active: true)
  Model.where("active = 0 OR active = '0'").update_all(active: false)
end
```

## Detection

Check for this issue:

```sql
-- See if you have mixed formats
SELECT column_name, typeof(column_name), COUNT(*)
FROM table_name
GROUP BY typeof(column_name);
```

Expected output should show only ONE type per boolean column (either all `integer` or all `text`).

## Codebase Watch Areas

Monitor these patterns in migrations:

1. `execute` statements with `INSERT` or `UPDATE`
2. String interpolation of boolean values in SQL
3. Migrations that seed data directly

## Related Files

- `db/migrate/20251004222259_create_canonicity_weights.rb` - Uses integer format
- `db/migrate/20251009095419_split_oxford_weights_in_canonicity_weights.rb` - Originally used text format
- `app/models/canonicity_weights.rb` - Has `.active` scope that expects Rails default format

## References

- Rails 4.2 SQLite3 Adapter: Converts Ruby `true`/`false` to SQLite format automatically
- SQLite Datatypes: https://www.sqlite.org/datatype3.html

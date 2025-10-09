class NormalizeCanonicityWeightsBooleans < ActiveRecord::Migration
  def up
    # Normalize all boolean values in canonicity_weights to use consistent format
    # Rails 4.2 + SQLite can create mixed integer (0/1) and text ('t'/'f') formats
    # This ensures all active values use the same format that ActiveRecord expects

    # Update all active=true records (handles both 1 and 't' formats)
    CanonicityWeights.where("active = 1 OR active = 't'").update_all(active: true)

    # Update all active=false records (handles both 0 and 'f' formats)
    CanonicityWeights.where("active = 0 OR active = 'f'").update_all(active: false)
  end

  def down
    # No-op: normalization is idempotent and reversing would be meaningless
  end
end

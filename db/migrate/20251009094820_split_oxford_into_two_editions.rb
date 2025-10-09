class SplitOxfordIntoTwoEditions < ActiveRecord::Migration
  def up
    # Add columns for Oxford 2nd and 3rd editions
    add_column :shadows, :oxford2, :boolean, default: false unless column_exists?(:shadows, :oxford2)
    add_column :shadows, :oxford3, :boolean, default: false unless column_exists?(:shadows, :oxford3)

    # Copy existing oxford flag to oxford3 (since the existing data refers to 3rd edition)
    execute "UPDATE shadows SET oxford3 = oxford WHERE oxford = 1"

    # Note: oxford2 will remain false until populated by separate snarf task
  end

  def down
    # Remove the new columns
    remove_column :shadows, :oxford2 if column_exists?(:shadows, :oxford2)
    remove_column :shadows, :oxford3 if column_exists?(:shadows, :oxford3)
  end
end

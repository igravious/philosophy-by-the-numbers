class AddInputValuesToMetricSnapshots < ActiveRecord::Migration
  def change
    add_column :metric_snapshots, :input_values, :text
    add_column :metric_snapshots, :danker_score, :float
    add_column :metric_snapshots, :encyclopedia_flags, :text
    add_column :metric_snapshots, :linkcount, :integer
    add_column :metric_snapshots, :mention_count, :integer
  end
end

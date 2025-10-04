class AddWeightsConfigToMetricSnapshots < ActiveRecord::Migration
  def change
    add_column :metric_snapshots, :weights_config, :text
  end
end

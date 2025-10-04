class AddMetricPosToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :metric_pos, :integer
  end
end

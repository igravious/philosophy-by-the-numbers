class ChangeDataTypeForMetric < ActiveRecord::Migration
  def change
		change_column :shadows, :metric, :float
  end
end

class AddMeasurePosToShadows < ActiveRecord::Migration
  def change
		add_column :shadows, :measure_pos, :integer
  end
end

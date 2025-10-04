class AddMeasureToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :measure, :float, default: nil
  end
end

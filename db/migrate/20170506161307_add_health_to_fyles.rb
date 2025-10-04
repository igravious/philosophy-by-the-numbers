class AddHealthToFyles < ActiveRecord::Migration
  def change
    add_column :fyles, :health, :float
  end
end

class RemoveStripStartFromFyles < ActiveRecord::Migration
  def change
    remove_column :fyles, :strip_start, :integer
  end
end

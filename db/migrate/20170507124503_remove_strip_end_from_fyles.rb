class RemoveStripEndFromFyles < ActiveRecord::Migration
  def change
    remove_column :fyles, :strip_end, :integer
  end
end

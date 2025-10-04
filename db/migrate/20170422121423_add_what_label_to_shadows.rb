class AddWhatLabelToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :what_label, :string
  end
end

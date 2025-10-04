class AddWhatItIsToUnits < ActiveRecord::Migration
  def change
    add_column :units, :what_it_is, :string
  end
end

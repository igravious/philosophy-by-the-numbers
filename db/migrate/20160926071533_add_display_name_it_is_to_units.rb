class AddDisplayNameItIsToUnits < ActiveRecord::Migration
  def change
    add_column :units, :display_name, :string
  end
end

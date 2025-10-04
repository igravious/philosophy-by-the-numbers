class AddNormalFormToUnits < ActiveRecord::Migration
  def change
    add_column :units, :normal_form, :string
  end
end

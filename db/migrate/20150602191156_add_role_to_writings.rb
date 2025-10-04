class AddRoleToWritings < ActiveRecord::Migration
  def change
    add_column :writings, :role, :integer
  end
end

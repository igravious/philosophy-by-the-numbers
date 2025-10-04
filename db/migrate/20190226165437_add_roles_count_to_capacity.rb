class AddRolesCountToCapacity < ActiveRecord::Migration
  def change
    add_column :capacities, :roles_count, :integer
  end
end

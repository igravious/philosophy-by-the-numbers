class AddIndexToRoles < ActiveRecord::Migration
  def change
		add_index :roles, :entity_id
  end
end

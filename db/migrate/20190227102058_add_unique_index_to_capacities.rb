class AddUniqueIndexToCapacities < ActiveRecord::Migration
  def change
		add_index :capacities, :entity_id, :unique => true
  end
end

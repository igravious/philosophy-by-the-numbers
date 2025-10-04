class AddUniqueIndexToShadows < ActiveRecord::Migration
  def change
    add_index :shadows, :entity_id, unique: true
  end
end

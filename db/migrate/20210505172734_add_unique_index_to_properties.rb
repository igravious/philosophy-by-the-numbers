class AddUniqueIndexToProperties < ActiveRecord::Migration
	# ~~ kinda ~~ bin/rails g migration add_unique_index_to_properties [property_id,entity_id,data_id]:uniq --force
  def change
    add_index :properties, [:property_id, :entity_id, :data_id], unique: true
  end
end

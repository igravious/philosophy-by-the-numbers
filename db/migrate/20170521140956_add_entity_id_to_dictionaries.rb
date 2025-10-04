class AddEntityIdToDictionaries < ActiveRecord::Migration
  def change
    add_column :dictionaries, :entity_id, :integer
  end
end

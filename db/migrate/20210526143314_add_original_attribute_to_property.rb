class AddOriginalAttributeToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :original_id, :integer
  end
end

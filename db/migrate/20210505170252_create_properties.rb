class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.integer :property_id
      t.integer :entity_id
      t.string :entity_label
      t.integer :data_id
      t.string :data_label

      t.timestamps null: false
    end
  end
end

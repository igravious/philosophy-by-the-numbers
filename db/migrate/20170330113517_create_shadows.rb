class CreateShadows < ActiveRecord::Migration
  def change
    create_table :shadows do |t|
      t.string :type
      t.integer :entity_id

      t.timestamps null: false
    end
    add_index :shadows, :entity_id, unique: true
  end
end

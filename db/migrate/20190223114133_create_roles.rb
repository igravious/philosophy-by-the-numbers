class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.integer :shadow_id
      t.integer :entity_id
      t.string :label

      t.timestamps null: false
    end
  end
end

class CreateFilters < ActiveRecord::Migration
  def change
    create_table :filters do |t|
      t.string :name
      t.integer :tag_id
      t.string :inequality
      t.integer :original_year

      t.timestamps null: false
    end
    add_index :filters, :name, unique: true
  end
end

class CreateLinks < ActiveRecord::Migration
  def change
    create_table :links do |t|
      t.string :table_name
      t.integer :row_id
      t.string :IRI
      t.text :description

      t.timestamps
    end
  end
end

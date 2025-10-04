class CreateIncludings < ActiveRecord::Migration
  def change
    create_table :includings do |t|
      t.integer :filter_id
      t.integer :text_id

      t.timestamps null: false
    end
  end
end

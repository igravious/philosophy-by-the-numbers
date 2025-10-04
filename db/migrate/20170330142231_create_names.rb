class CreateNames < ActiveRecord::Migration
  def change
    create_table :names do |t|
      t.integer :shadow_id
      t.string :label
      t.string :lang

      t.timestamps null: false
    end
  end
end

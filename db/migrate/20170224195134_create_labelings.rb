class CreateLabelings < ActiveRecord::Migration
  def change
    create_table :labelings do |t|
      t.integer :tag_id
      t.integer :text_id

      t.timestamps null: false
    end
  end
end

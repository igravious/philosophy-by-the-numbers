class CreateWritings < ActiveRecord::Migration
  def change
    create_table :writings do |t|
      t.integer :author_id
      t.integer :text_id

      t.timestamps
    end
  end
end

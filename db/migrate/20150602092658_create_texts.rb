class CreateTexts < ActiveRecord::Migration
  def change
    create_table :texts do |t|
      t.string :name
      t.integer :original_year
      t.integer :edition_year

      t.timestamps
    end
  end
end

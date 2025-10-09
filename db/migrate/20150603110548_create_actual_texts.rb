class CreateActualTexts < ActiveRecord::Migration
  def change
    create_table :actual_texts do |t|
      t.string :URL
      t.integer :strip_start
      t.integer :strip_end

      t.timestamps
    end
  end
end

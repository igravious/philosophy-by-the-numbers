class CreateTextFiles < ActiveRecord::Migration
  def change
    create_table :text_files do |t|
      t.string :URL
      t.string :what
      t.integer :strip_start
      t.integer :strip_end

      t.timestamps
    end
  end
end

class CreateDictionaries < ActiveRecord::Migration
  def change
    create_table :dictionaries do |t|
      t.string :title
      t.string :long_title
      t.string :URI
      t.string :current_editor
      t.string :contact
      t.string :organisation

      t.timestamps
    end
  end
end

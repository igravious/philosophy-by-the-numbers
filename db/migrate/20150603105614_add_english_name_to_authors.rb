class AddEnglishNameToAuthors < ActiveRecord::Migration
  def change
    add_column :authors, :english_name, :string
  end
end

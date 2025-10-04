class AddEnglishNameToTexts < ActiveRecord::Migration
  def change
    add_column :texts, :english_name, :string
  end
end

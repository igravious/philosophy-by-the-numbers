class AddOriginalLanguageToTexts < ActiveRecord::Migration
  def change
    add_column :texts, :original_language, :string
  end
end

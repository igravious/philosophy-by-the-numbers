class AddUniqueIndexToTexts < ActiveRecord::Migration
  def change
		add_index :texts, [:name_in_english, :original_year], :unique => true
  end
end

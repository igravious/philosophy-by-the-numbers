class RenameEnglishNameForTexts < ActiveRecord::Migration
	def self.up
		# conflicts with column name in Author
		rename_column :texts, :english_name, :name_in_english
	end

	def self.down
		# rename back if you need or do something else or do nothing
	end
end

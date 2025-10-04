class RenameActualTextIdForTexts < ActiveRecord::Migration
	def self.up
		# changed table actual_text_id points to to TextFile
		rename_column :texts, :actual_text_id, :text_file_id
	end

	def self.down
		# rename back if you need or do something else or do nothing
	end
end

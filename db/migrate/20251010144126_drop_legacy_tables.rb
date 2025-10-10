class DropLegacyTables < ActiveRecord::Migration
	def change
		# Drop actual_texts table (superseded by fyles since June 2015)
		# Only contained 2 legacy rows
		drop_table :actual_texts

		# Drop author_texts table (superseded by writings since June 2015)
		# Completely empty (0 rows)
		drop_table :author_texts
	end
end

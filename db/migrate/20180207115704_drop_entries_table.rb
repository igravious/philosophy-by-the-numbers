class DropEntriesTable < ActiveRecord::Migration
  def up
		drop_table :entries if table_exists?(:entries)
	end

	def down
		raise ActiveRecord::IrreversibleMigration
	end
end

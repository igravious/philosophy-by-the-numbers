class DropEntriesTable < ActiveRecord::Migration
  def up
		drop_table :entries
	end

	def down
		raise ActiveRecord::IrreversibleMigration
	end
end

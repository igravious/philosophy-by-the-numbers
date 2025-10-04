class AddUniqueIndexToNames < ActiveRecord::Migration
  def change
		add_index :names, [:shadow_id, :lang], :unique => true
  end
end

class AddUniqueIndexToIncludings < ActiveRecord::Migration
  def change
		add_index :includings, [:filter_id, :text_id], :unique => true
  end
end

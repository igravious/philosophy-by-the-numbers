class AddUniqueIndexToTextFiles < ActiveRecord::Migration
  def change
		add_index :text_files, :URL, :unique => true
  end
end

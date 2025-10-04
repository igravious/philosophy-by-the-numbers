class AddCacheFileToTextFiles < ActiveRecord::Migration
  def change
		add_column :text_files, :cache_file, :string
  end
end

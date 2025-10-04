class RenameTextFilesToFyles < ActiveRecord::Migration
  def change
		rename_table :text_files, :fyles
		rename_column :texts, :text_file_id, :fyle_id
  end
end

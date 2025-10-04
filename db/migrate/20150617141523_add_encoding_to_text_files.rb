class AddEncodingToTextFiles < ActiveRecord::Migration
  def change
		add_column :text_files, :encoding, :string
  end
end

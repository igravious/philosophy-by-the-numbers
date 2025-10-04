class AddStatusCodeToTextFiles < ActiveRecord::Migration
  def change
		add_column :text_files, :status_code, :integer, :default => nil
  end
end

class AddHandledToTextFiles < ActiveRecord::Migration
  def change
		add_column :text_files, :handled, :boolean, :default => false
  end
end

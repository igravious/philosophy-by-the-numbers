class AddLocalFileToFyles < ActiveRecord::Migration
  def change
		add_column :fyles, :local_file, :string
  end
end

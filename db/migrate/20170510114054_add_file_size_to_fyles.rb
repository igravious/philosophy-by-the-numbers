class AddFileSizeToFyles < ActiveRecord::Migration
  def change
    add_column :fyles, :file_size, :integer
  end
end

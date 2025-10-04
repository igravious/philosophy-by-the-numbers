class AddInphoboolToShadow < ActiveRecord::Migration
  def change
    add_column :shadows, :inphobool, :boolean, default: false, null: false
  end
end

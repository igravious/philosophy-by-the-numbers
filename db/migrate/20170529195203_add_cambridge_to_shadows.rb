class AddCambridgeToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :cambridge, :boolean, default: :false
  end
end

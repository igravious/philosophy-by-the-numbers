class ChangeCambridgeToDefaultFalse < ActiveRecord::Migration
  def change
		change_column :shadows, :cambridge, :boolean, :default => 'f'
  end
end

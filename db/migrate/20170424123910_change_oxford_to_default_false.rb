class ChangeOxfordToDefaultFalse < ActiveRecord::Migration
  def change
		change_column :shadows, :kemerling, :boolean, :default => 'f'
  end
end

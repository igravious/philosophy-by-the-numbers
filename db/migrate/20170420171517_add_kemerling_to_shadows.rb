class AddKemerlingToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :kemerling, :boolean, :default => false
  end
end

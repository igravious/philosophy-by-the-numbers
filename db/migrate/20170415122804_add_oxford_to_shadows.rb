class AddOxfordToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :oxford, :boolean, :default => 'f'
  end
end

class AddPopulateToShadows < ActiveRecord::Migration
  def change
		    add_column :shadows, :populate, :boolean, :default => 'f'
  end
end

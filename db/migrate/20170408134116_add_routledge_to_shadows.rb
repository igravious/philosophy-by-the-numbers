class AddRoutledgeToShadows < ActiveRecord::Migration
  def change
		add_column :shadows, :routledge, :boolean, :default => 'f'
  end
end

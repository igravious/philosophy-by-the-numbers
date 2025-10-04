class ChangeApproxToDefaultFalse < ActiveRecord::Migration
  def change
		change_column :shadows, :birth_approx, :boolean, :default => 'f'
		change_column :shadows, :death_approx, :boolean, :default => 'f'
  end
end

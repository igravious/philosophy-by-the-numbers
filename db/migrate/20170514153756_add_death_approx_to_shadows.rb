class AddDeathApproxToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :death_approx, :boolean, default: :false
  end
end

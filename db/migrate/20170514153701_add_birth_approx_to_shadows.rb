class AddBirthApproxToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :birth_approx, :boolean, default: :false
  end
end

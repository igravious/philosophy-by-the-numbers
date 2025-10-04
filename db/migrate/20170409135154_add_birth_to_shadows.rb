class AddBirthToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :birth, :string
  end
end

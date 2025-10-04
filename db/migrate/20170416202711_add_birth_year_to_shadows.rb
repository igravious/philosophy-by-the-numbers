class AddBirthYearToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :birth_year, :integer
  end
end

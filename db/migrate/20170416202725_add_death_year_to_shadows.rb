class AddDeathYearToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :death_year, :integer
  end
end

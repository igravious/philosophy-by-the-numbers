class AddYearToDictionaries < ActiveRecord::Migration
  def change
    add_column :dictionaries, :year, :integer
  end
end

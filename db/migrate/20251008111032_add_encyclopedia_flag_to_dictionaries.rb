class AddEncyclopediaFlagToDictionaries < ActiveRecord::Migration
  def change
    add_column :dictionaries, :encyclopedia_flag, :string
  end
end

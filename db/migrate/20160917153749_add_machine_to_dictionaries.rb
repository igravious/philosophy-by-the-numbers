class AddMachineToDictionaries < ActiveRecord::Migration
  def change
    add_column :dictionaries, :machine, :boolean, default: false
  end
end

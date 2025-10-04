class AddMissingToDictionaries < ActiveRecord::Migration
  def change
    add_column :dictionaries, :missing, :integer
  end
end

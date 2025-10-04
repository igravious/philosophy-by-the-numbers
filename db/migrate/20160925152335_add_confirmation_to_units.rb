class AddConfirmationToUnits < ActiveRecord::Migration
  def change
    add_column :units, :confirmation, :boolean, default: false
  end
end

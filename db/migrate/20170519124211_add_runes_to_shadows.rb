class AddRunesToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :runes, :boolean, default: false
  end
end

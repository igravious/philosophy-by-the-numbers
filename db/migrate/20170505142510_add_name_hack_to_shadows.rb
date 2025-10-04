class AddNameHackToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :name_hack, :string
  end
end

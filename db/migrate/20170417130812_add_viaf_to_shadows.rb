class AddViafToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :viaf, :string
  end
end

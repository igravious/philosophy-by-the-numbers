class AddFloruitToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :floruit, :string
  end
end

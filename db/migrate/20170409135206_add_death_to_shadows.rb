class AddDeathToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :death, :string
  end
end

class AddLinkcountToShadow < ActiveRecord::Migration
  def change
    add_column :shadows, :linkcount, :integer
  end
end

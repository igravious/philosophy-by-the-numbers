class AddObsoleteToShadow < ActiveRecord::Migration
  def change
    add_column :shadows, :obsolete, :boolean, default: false, null: false
  end
end

class AddGenreToShadow < ActiveRecord::Migration
  def change
    add_column :shadows, :genre, :boolean, default: false, null: false
  end
end

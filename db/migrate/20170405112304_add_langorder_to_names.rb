class AddLangorderToNames < ActiveRecord::Migration
  def change
    add_column :names, :langorder, :integer
  end
end

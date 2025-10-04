class AddWorkAttrsToShadow < ActiveRecord::Migration
  def change
    add_column :shadows, :work_lang, :string
    add_column :shadows, :pub, :string
    add_column :shadows, :pub_approx, :string
    add_column :shadows, :pub_year, :string
    add_column :shadows, :country, :string
    add_column :shadows, :copyright, :string
    add_column :shadows, :image, :string
  end
end

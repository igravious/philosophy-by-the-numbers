class AddStanfordToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :stanford, :boolean, default: false
  end
end

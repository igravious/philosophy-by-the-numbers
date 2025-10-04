class AddInternetToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :internet, :boolean, default: false
  end
end

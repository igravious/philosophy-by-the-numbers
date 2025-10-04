class AddDateHackToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :date_hack, :string
  end
end

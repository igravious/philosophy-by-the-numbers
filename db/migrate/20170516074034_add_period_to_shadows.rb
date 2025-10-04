class AddPeriodToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :period, :string
  end
end

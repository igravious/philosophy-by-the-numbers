class AddGenderToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :gender, :string, default: nil
  end
end

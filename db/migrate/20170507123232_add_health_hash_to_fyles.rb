class AddHealthHashToFyles < ActiveRecord::Migration
  def change
    add_column :fyles, :health_hash, :string
  end
end

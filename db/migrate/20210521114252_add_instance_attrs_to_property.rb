class AddInstanceAttrsToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :instance_id, :integer
    add_column :properties, :instance_label, :string
  end
end

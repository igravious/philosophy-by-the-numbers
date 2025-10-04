class AddInferredAttrsToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :inferred_id, :integer
    add_column :properties, :inferred_label, :string
  end
end

class AddBorchertToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :borchert, :boolean, default: 'f'
  end
end

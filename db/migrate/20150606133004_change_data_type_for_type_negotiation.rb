class ChangeDataTypeForTypeNegotiation < ActiveRecord::Migration
  def change
		change_column :text_files, :type_negotiation, :integer
  end
end

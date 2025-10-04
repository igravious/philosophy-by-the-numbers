class AddTypeNegotiationToTextFiles < ActiveRecord::Migration
  def change
		add_column :text_files, :type_negotiation, :string
  end
end

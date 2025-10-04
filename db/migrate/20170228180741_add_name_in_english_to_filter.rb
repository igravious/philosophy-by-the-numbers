class AddNameInEnglishToFilter < ActiveRecord::Migration
  def change
    add_column :filters, :name_in_english, :string
  end
end

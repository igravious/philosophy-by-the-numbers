class AddStringDatesToAuthors < ActiveRecord::Migration
  def change
		add_column :authors, :date_of_birth, :string
		add_column :authors, :when_died, :string
  end
end

class AddLinksToShadow < ActiveRecord::Migration
  def change
    add_column :shadows, :philtopic, :string
    add_column :shadows, :britannica, :string
    add_column :shadows, :philrecord, :string
  end
end

class AddContentUriToDictionaries < ActiveRecord::Migration
  def change
    add_column :dictionaries, :content_uri, :string
  end
end

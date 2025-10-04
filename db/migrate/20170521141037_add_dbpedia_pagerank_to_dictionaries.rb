class AddDbpediaPagerankToDictionaries < ActiveRecord::Migration
  def change
    add_column :dictionaries, :dbpedia_pagerank, :float
  end
end

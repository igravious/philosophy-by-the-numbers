class AddDbpediaPagerankToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :dbpedia_pagerank, :float
  end
end

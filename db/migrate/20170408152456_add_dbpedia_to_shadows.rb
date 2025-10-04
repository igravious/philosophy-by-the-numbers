class AddDbpediaToShadows < ActiveRecord::Migration
  def change
    add_column :shadows, :dbpedia, :boolean, :default => 'f'
  end
end

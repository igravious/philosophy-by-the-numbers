class AddUniqueIndexToWritings < ActiveRecord::Migration
  def change
		add_index :writings, [:author_id, :text_id], :unique => true
  end
end

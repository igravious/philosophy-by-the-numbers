class AddUniqueIndexToLabelings < ActiveRecord::Migration
	# http://stackoverflow.com/questions/1449459/how-do-i-make-a-column-unique-and-index-it-in-a-ruby-on-rails-migration
  def change
		add_index :labelings, [:tag_id, :text_id], :unique => true
  end
end

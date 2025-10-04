class AddIndexToNames < ActiveRecord::Migration
  def change
		add_index :names, :label
  end
end

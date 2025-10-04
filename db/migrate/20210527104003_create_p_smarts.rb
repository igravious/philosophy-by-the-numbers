class CreatePSmarts < ActiveRecord::Migration
  def change
		# use namespace
		# no id and no timestamps :)
		create_table :p_smarts, id: false  do |t|
      t.integer :entity_id
      t.integer :redirect_id
      t.integer :object_id
      t.string  :object_label
      t.string  :type
    end
		# i think it is redirect_id
		add_index :p_smarts, [:redirect_id, :object_id, :type], unique: true
  end
end

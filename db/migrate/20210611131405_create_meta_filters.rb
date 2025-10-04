class CreateMetaFilters < ActiveRecord::Migration
  def change
    create_table :meta_filters do |t|
      t.string :filter, null: false
      # t.string :key, null: false
      # t.string :value
			t.string :type, null: false

      t.timestamps null: false
    end
		add_index :meta_filters, [:filter], :unique => true
  end
end

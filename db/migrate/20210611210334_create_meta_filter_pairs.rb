class CreateMetaFilterPairs < ActiveRecord::Migration
  def change
    create_table :meta_filter_pairs do |t|
      t.integer :meta_filter_id, null: false
      t.string :key, null: false
      t.string :value, null: false # we're going to be marshalling objects, for example: 2.4.0 :002 > Marshal.dump(nil) => "\x04\b0"

      t.timestamps null: false
    end
		add_index :meta_filter_pairs, [:meta_filter_id, :key], :unique => true
  end
end

class CreateCapacities < ActiveRecord::Migration
  def change
    create_table :capacities do |t|
      t.integer :entity_id
			t.string  :label
      t.boolean :relevant, default: false

      t.timestamps null: false
    end
  end
end

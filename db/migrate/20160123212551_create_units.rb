class CreateUnits < ActiveRecord::Migration
  def change
    create_table :units do |t|
      t.integer :dictionary_id
      t.string :entry

      t.timestamps
    end
  end
end

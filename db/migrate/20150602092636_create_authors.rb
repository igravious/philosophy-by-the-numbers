class CreateAuthors < ActiveRecord::Migration
  def change
    create_table :authors do |t|
      t.string :name
      t.integer :year_of_birth
      t.integer :year_of_death
      t.string :where
      t.text :about

      t.timestamps
    end
  end
end

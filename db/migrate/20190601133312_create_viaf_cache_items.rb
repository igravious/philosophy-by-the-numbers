class CreateViafCacheItems < ActiveRecord::Migration
  def change
    create_table :viaf_cache_items, id: false do |t|
      t.string :personal
      t.string :uniform_title_work
      t.string :q
      t.string :url

			t.index [:personal, :uniform_title_work], unique: true
    end
  end
end

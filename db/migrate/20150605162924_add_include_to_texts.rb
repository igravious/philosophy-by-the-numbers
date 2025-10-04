class AddIncludeToTexts < ActiveRecord::Migration
  def change
		add_column :texts, :include, :boolean, :default => false
  end
end

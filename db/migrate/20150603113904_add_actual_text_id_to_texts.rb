class AddActualTextIdToTexts < ActiveRecord::Migration
  def change
    add_column :texts, :actual_text_id, :integer
  end
end

class ChangeTextIdNull < ActiveRecord::Migration
  def change
		change_column_null(:includings, :text_id, false)
  end
end

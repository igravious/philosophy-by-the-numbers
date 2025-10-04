class ChangeFilterIdNull < ActiveRecord::Migration
  def change
		change_column_null(:includings, :filter_id, false)
  end
end

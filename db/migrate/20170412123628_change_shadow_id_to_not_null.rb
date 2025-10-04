class ChangeShadowIdToNotNull < ActiveRecord::Migration
  def change
		# Change the column to not allow null
		change_column :names, :shadow_id, :integer, :null => false
  end
end

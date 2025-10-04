class AddMentionToShadow < ActiveRecord::Migration
  def change
    add_column :shadows, :mention, :integer, default: 0, null: false
  end
end

class CreateExpressionsJoinTable < ActiveRecord::Migration
  def change
    create_join_table :creators, :works, table_name: :expressions do |t|
      # t.index [:creator_id, :work_id]
      t.index [:work_id, :creator_id], unique: true
    end
  end
end

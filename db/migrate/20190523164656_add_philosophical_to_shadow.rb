class AddPhilosophicalToShadow < ActiveRecord::Migration
  def change
    add_column :shadows, :philosophical, :integer
  end
end

class AddPhilosophyPhilosopherMetricToShadow < ActiveRecord::Migration
  def change
    add_column :shadows, :philosophy, :integer
    add_column :shadows, :philosopher, :integer
    add_column :shadows, :metric, :integer
  end
end

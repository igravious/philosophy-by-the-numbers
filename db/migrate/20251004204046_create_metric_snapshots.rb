class CreateMetricSnapshots < ActiveRecord::Migration
  def change
    create_table :metric_snapshots do |t|
      t.integer :philosopher_id, null: false
      t.datetime :calculated_at, null: false
      t.float :measure
      t.integer :measure_pos
      t.string :danker_version
      t.string :danker_file
      t.string :algorithm_version, default: '1.0'
      t.text :notes
      
      t.timestamps null: false
    end
    
    add_index :metric_snapshots, :philosopher_id
    add_index :metric_snapshots, :calculated_at
    add_index :metric_snapshots, [:philosopher_id, :calculated_at]
    add_index :metric_snapshots, :algorithm_version
  end
end

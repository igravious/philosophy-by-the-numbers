class MakeMetricSnapshotPolymorphic < ActiveRecord::Migration
  def up
    # Add shadow_type column for polymorphic association
    add_column :metric_snapshots, :shadow_type, :string unless column_exists?(:metric_snapshots, :shadow_type)

    # Set shadow_type to 'Philosopher' for all existing records
    execute "UPDATE metric_snapshots SET shadow_type = 'Philosopher' WHERE shadow_type IS NULL"

    # Make shadow_type NOT NULL after populating
    change_column_null :metric_snapshots, :shadow_type, false

    # Remove old philosopher-specific indexes (use current column names after rename)
    if index_exists?(:metric_snapshots, :philosopher_id, name: 'index_metric_snapshots_on_philosopher_id')
      remove_index :metric_snapshots, name: 'index_metric_snapshots_on_philosopher_id'
    end
    if index_exists?(:metric_snapshots, [:philosopher_id, :calculated_at], name: 'index_metric_snapshots_on_philosopher_id_and_calculated_at')
      remove_index :metric_snapshots, name: 'index_metric_snapshots_on_philosopher_id_and_calculated_at'
    end

    # Rename philosopher_id to shadow_id for polymorphic association
    rename_column :metric_snapshots, :philosopher_id, :shadow_id unless column_exists?(:metric_snapshots, :shadow_id)

    # Add new polymorphic indexes
    unless index_exists?(:metric_snapshots, [:shadow_type, :shadow_id])
      add_index :metric_snapshots, [:shadow_type, :shadow_id]
    end
    unless index_exists?(:metric_snapshots, [:shadow_type, :shadow_id, :calculated_at], name: 'index_metric_snapshots_on_shadow_and_calculated_at')
      add_index :metric_snapshots, [:shadow_type, :shadow_id, :calculated_at], name: 'index_metric_snapshots_on_shadow_and_calculated_at'
    end
  end

  def down
    # Remove polymorphic indexes
    remove_index :metric_snapshots, name: 'index_metric_snapshots_on_shadow_and_calculated_at'
    remove_index :metric_snapshots, [:shadow_type, :shadow_id]

    # Restore old indexes
    add_index :metric_snapshots, :shadow_id, name: 'index_metric_snapshots_on_philosopher_id'
    add_index :metric_snapshots, [:shadow_id, :calculated_at], name: 'index_metric_snapshots_on_philosopher_id_and_calculated_at'

    # Rename back
    rename_column :metric_snapshots, :shadow_id, :philosopher_id

    # Remove shadow_type column
    remove_column :metric_snapshots, :shadow_type
  end
end

class CreateCanonicityMetricRunInfrastructure < ActiveRecord::Migration
  def change
    create_table :metric_input_datasets do |t|
      t.string :subject_type, null: false
      t.string :status, null: false
      t.string :schema_version, null: false
      t.text :selected_entity_ids, null: false
      t.text :normalization_entity_ids, null: false
      t.text :normalization_context, null: false
      t.text :source_provenance, null: false
      t.integer :input_run_id
      t.string :population_checksum, null: false
      t.datetime :capture_completed_at
      t.text :failure_reason
      t.timestamps null: false
    end
    add_index :metric_input_datasets, :input_run_id
    add_index :metric_input_datasets, :status
    add_index :metric_input_datasets, :subject_type

    create_table :metric_input_records do |t|
      t.integer :metric_input_dataset_id, null: false
      t.integer :shadow_id, null: false
      t.string :shadow_type, null: false
      t.integer :entity_id, null: false
      t.string :entity_label, null: false
      t.boolean :selected, default: false, null: false
      t.boolean :normalization, default: false, null: false
      t.text :input_payload, null: false
      t.timestamps null: false
    end
    add_index :metric_input_records, [:metric_input_dataset_id, :shadow_id], unique: true, name: "index_metric_input_records_on_dataset_and_shadow"
    add_index :metric_input_records, :shadow_id

    create_table :canonicity_signals do |t|
      t.string :algorithm_version, null: false
      t.string :name, null: false
      t.text :description
      t.string :source, null: false
      t.boolean :subject_to_change, default: false, null: false
      t.boolean :used_in_formula, default: false, null: false
      t.boolean :active, default: true, null: false
      t.timestamps null: false
    end
    add_index :canonicity_signals, [:algorithm_version, :name], unique: true
    add_index :canonicity_signals, :active

    create_table :source_events do |t|
      t.string :source_name, null: false
      t.string :source_version
      t.string :import_identity, null: false
      t.string :artifact_identity, null: false
      t.string :artifact_checksum, null: false
      t.integer :shadow_id, null: false
      t.string :shadow_type, null: false
      t.integer :entity_id, null: false
      t.string :attribute_name, null: false
      t.text :old_value
      t.text :new_value
      t.text :provenance, null: false
      t.datetime :imported_at, null: false
      t.timestamps null: false
    end
    add_index :source_events, :import_identity
    add_index :source_events, :artifact_checksum
    add_index :source_events, [:shadow_id, :shadow_type]
    add_index :source_events, :source_name

    create_table :metric_runs do |t|
      t.string :version, null: false
      t.integer :major, null: false
      t.integer :minor, null: false
      t.integer :patch, null: false
      t.string :subject_type, null: false
      t.integer :metric_input_dataset_id, null: false
      t.integer :parent_run_id
      t.string :calculator_identity, null: false
      t.string :configuration_version, null: false
      t.string :configuration_fingerprint, null: false
      t.string :status, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.text :weights_config, null: false
      t.text :signal_config, null: false
      t.text :source_provenance, null: false
      t.text :failure_reason
      t.timestamps null: false
    end
    add_index :metric_runs, [:subject_type, :version], unique: true
    add_index :metric_runs, [:subject_type, :major, :minor, :patch], unique: true, name: "index_metric_runs_on_subject_and_version_components"
    add_index :metric_runs, :metric_input_dataset_id
    add_index :metric_runs, :parent_run_id
    add_index :metric_runs, :calculator_identity
    add_index :metric_runs, :configuration_fingerprint
    add_index :metric_runs, :status
    add_index :metric_runs, :started_at
    add_index :metric_runs, :completed_at

    create_table :publications do |t|
      t.integer :metric_run_id, null: false
      t.string :subject_type, null: false
      t.datetime :created_at, null: false
    end
    add_index :publications, :metric_run_id
    add_index :publications, :subject_type
    add_index :publications, :created_at

    add_column :metric_snapshots, :metric_run_id, :integer
    add_column :metric_snapshots, :metric_input_record_id, :integer
    add_column :metric_snapshots, :calculation_context, :text
    add_index :metric_snapshots, :metric_input_record_id
    add_index :metric_snapshots, [:metric_run_id, :shadow_id], unique: true
    change_column :metric_snapshots, :danker_score, :float, null: true
    change_column :metric_snapshots, :linkcount, :integer, null: true
    change_column :metric_snapshots, :mention_count, :integer, null: true
  end
end

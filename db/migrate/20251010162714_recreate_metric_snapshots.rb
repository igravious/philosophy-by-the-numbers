class RecreateMetricSnapshots < ActiveRecord::Migration
	def up
		# Drop the old metric_snapshots table (only had 3 test rows with incorrect schema)
		drop_table :metric_snapshots if table_exists?(:metric_snapshots)

		# Recreate with proper schema for metric snapshot system
		create_table :metric_snapshots do |t|
			# Polymorphic-style association (shadow_id + shadow_type)
			t.integer :shadow_id, null: false
			t.string :shadow_type, null: false  # 'Philosopher' or 'Work'

			# Calculation metadata
			t.datetime :calculated_at, null: false
			t.string :canonicity_weight_algorithm_version, null: false  # FK to canonicity_weights.algorithm_version (e.g., '2.0', '2.0-work')

			# Danker (PageRank) provenance
			t.string :danker_version, null: false  # e.g., '2019-05-10'
			t.string :danker_file, null: false     # e.g., '2019-05-10.all.links.c.alphanum.csv'

			# Input signals (captured at time of calculation)
			t.float :danker_score, null: false     # PageRank score
			t.integer :linkcount, null: false      # Wikipedia link count
			t.integer :mention_count, null: false  # Philosophy mentions
			t.text :reference_work_flags, null: false  # JSON: {stanford: true, oxford2: false, ...}

			# Output (calculated canonicity)
			t.float :measure, null: false          # Calculated canonicity score
			t.integer :measure_pos                 # Ranking position (nullable - calculated after all snapshots)

			# Optional metadata
			t.text :notes

			t.timestamps null: false
		end

		# Indexes for efficient querying
		add_index :metric_snapshots, [:shadow_type, :shadow_id]
		add_index :metric_snapshots, :calculated_at
		add_index :metric_snapshots, :canonicity_weight_algorithm_version  # FK to canonicity_weights.algorithm_version
		add_index :metric_snapshots, [:shadow_type, :shadow_id, :calculated_at],
			name: 'index_metric_snapshots_on_shadow_and_calculated_at'

		# Note: Rails 4.2 with SQLite3 does not enforce foreign key constraints by default.
		# The canonicity_weight_algorithm_version field references canonicity_weights.algorithm_version.
		# Application-level validation should ensure referential integrity.
	end

	def down
		drop_table :metric_snapshots
	end
end

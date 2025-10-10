class CreateAttributeTables < ActiveRecord::Migration
  def change
    create_table :philosopher_attrs do |t|
      t.integer :shadow_id, null: false

      # Birth/Death Data
      t.string :birth
      t.boolean :birth_approx, default: false
      t.integer :birth_year
      t.string :death
      t.boolean :death_approx, default: false
      t.integer :death_year
      t.string :floruit
      t.string :period

      # Reference Work Flags
      t.boolean :dbpedia, default: false
      t.boolean :oxford2, default: false
      t.boolean :oxford3, default: false
      t.boolean :stanford, default: false
      t.boolean :internet, default: false
      t.boolean :kemerling, default: false
      t.boolean :runes, default: false
      t.boolean :populate, default: false
      t.integer :inpho, default: 0
      t.boolean :inphobool, default: false

      # Demographics
      t.string :gender

      # Metrics
      t.integer :philosopher, default: 0

      t.timestamps null: false
    end

    create_table :work_attrs do |t|
      t.integer :shadow_id, null: false

      # Publication Data
      t.string :pub
      t.string :pub_year
      t.string :pub_approx
      t.string :work_lang
      t.string :copyright

      # Classification
      t.boolean :genre, default: false, null: false
      t.boolean :obsolete, default: false, null: false

      # Reference Work Flags
      t.string :philrecord
      t.string :philtopic
      t.string :britannica

      # Metadata
      t.string :image

      # Metrics
      t.integer :philosophical

      t.timestamps null: false
    end

    create_table :obsolete_attrs do |t|
      t.integer :shadow_id, null: false
      t.string :shadow_type, null: false

      # Old Canonicity System
      t.float :metric
      t.integer :metric_pos
      t.float :dbpedia_pagerank

      # Obsolete Reference Work Flag
      t.boolean :oxford, default: false

      t.timestamps null: false
    end

    add_index :philosopher_attrs, :shadow_id, unique: true
    add_index :work_attrs, :shadow_id, unique: true
    add_index :obsolete_attrs, :shadow_id
    add_index :obsolete_attrs, [:shadow_id, :shadow_type]
  end
end

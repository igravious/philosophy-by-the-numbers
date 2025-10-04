class CreateCanonicityWeights < ActiveRecord::Migration
  def change
    create_table :canonicity_weights do |t|
      t.string :algorithm_version, null: false
      t.string :source_name, null: false
      t.decimal :weight_value, precision: 8, scale: 6, null: false
      t.string :description
      t.boolean :active, default: true
      t.timestamps null: false
    end
    
    add_index :canonicity_weights, [:algorithm_version, :active]
    add_index :canonicity_weights, [:algorithm_version, :source_name], unique: true
    
    # Seed the current v2.0 weights
    reversible do |dir|
      dir.up do
        weights_v2 = [
          { source_name: 'runes', weight_value: 0.0, description: 'Runes (biased, excluded)' },
          { source_name: 'inphobool', weight_value: 0.15, description: 'Internet Encyclopedia of Philosophy' },
          { source_name: 'borchert', weight_value: 0.25, description: 'Macmillan Encyclopedia (Borchert)' },
          { source_name: 'internet', weight_value: 0.05, description: 'Internet sources' },
          { source_name: 'cambridge', weight_value: 0.2, description: 'Cambridge Dictionary of Philosophy' },
          { source_name: 'kemerling', weight_value: 0.1, description: 'Kemerling Philosophy Pages' },
          { source_name: 'populate', weight_value: 0.02, description: 'Wikipedia (as philosopher)' },
          { source_name: 'oxford', weight_value: 0.2, description: 'Oxford Reference' },
          { source_name: 'routledge', weight_value: 0.25, description: 'Routledge Encyclopedia of Philosophy' },
          { source_name: 'dbpedia', weight_value: 0.01, description: 'DBpedia (as philosopher)' },
          { source_name: 'stanford', weight_value: 0.15, description: 'Stanford Encyclopedia of Philosophy' },
          { source_name: 'all_bonus', weight_value: 0.13, description: 'Bonus for having any authoritative sources' }
        ]
        
        weights_v2.each do |weight|
          execute <<-SQL
            INSERT INTO canonicity_weights (algorithm_version, source_name, weight_value, description, active, created_at, updated_at)
            VALUES ('2.0', '#{weight[:source_name]}', #{weight[:weight_value]}, '#{weight[:description]}', true, '#{Time.current.to_s(:db)}', '#{Time.current.to_s(:db)}')
          SQL
        end
      end
    end
  end
end

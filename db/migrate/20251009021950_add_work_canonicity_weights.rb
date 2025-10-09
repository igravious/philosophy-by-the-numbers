class AddWorkCanonicityWeights < ActiveRecord::Migration
  def up
    # Add Work-specific canonicity weights based on the algorithm in work_tasks.rake:321-385
    # Algorithm version 2.0-work distinguishes Work weights from Philosopher weights

    CanonicityWeights.create!([
      {
        algorithm_version: '2.0-work',
        source_name: 'borchert',
        weight_value: 0.25,
        description: 'Macmillan Reference (Borchert) encyclopedia inclusion',
        active: true
      },
      {
        algorithm_version: '2.0-work',
        source_name: 'cambridge',
        weight_value: 0.20,
        description: 'Cambridge encyclopedia inclusion',
        active: true
      },
      {
        algorithm_version: '2.0-work',
        source_name: 'routledge',
        weight_value: 0.25,
        description: 'Routledge encyclopedia inclusion',
        active: true
      },
      {
        algorithm_version: '2.0-work',
        source_name: 'philpapers',
        weight_value: 0.20,
        description: 'PhilPapers inclusion (philrecord OR philtopic)',
        active: true
      },
      {
        algorithm_version: '2.0-work',
        source_name: 'all_bonus',
        weight_value: 0.10,
        description: 'Bonus for having at least one authoritative source',
        active: true
      },
      {
        algorithm_version: '2.0-work',
        source_name: 'genre_philosophical',
        weight_value: 1.00,
        description: 'Multiplier for philosophical works (genre=true)',
        active: true
      },
      {
        algorithm_version: '2.0-work',
        source_name: 'genre_other',
        weight_value: 0.50,
        description: 'Multiplier for non-philosophical works (genre=false)',
        active: true
      }
    ])
  end

  def down
    CanonicityWeights.where(algorithm_version: '2.0-work').destroy_all
  end
end

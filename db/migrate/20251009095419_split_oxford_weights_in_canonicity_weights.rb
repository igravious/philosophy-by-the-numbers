class SplitOxfordWeightsInCanonicityWeights < ActiveRecord::Migration
  def up
    # Split the oxford weight (0.2) into oxford2 (0.1) and oxford3 (0.1)
    # Total remains the same if a philosopher appears in both editions

    # Add oxford2 weight (Oxford Dictionary of Philosophy, 2nd ed.)
    # Use ActiveRecord to ensure consistent boolean handling across SQLite formats
    CanonicityWeights.create!(
      algorithm_version: '2.0',
      source_name: 'oxford2',
      weight_value: 0.1,
      description: 'Oxford Dictionary of Philosophy (2nd ed.)',
      active: true
    )

    # Add oxford3 weight (Oxford Dictionary of Philosophy, 3rd ed.)
    CanonicityWeights.create!(
      algorithm_version: '2.0',
      source_name: 'oxford3',
      weight_value: 0.1,
      description: 'Oxford Dictionary of Philosophy (3rd ed.)',
      active: true
    )

    # Deactivate the old oxford weight (keep for historical reference)
    # Use ActiveRecord update_all for consistent boolean handling
    CanonicityWeights.where(algorithm_version: '2.0', source_name: 'oxford').update_all(
      active: false,
      description: 'Oxford Reference (deprecated - split into oxford2 and oxford3)',
      updated_at: Time.current
    )
  end

  def down
    # Reactivate the old oxford weight
    CanonicityWeights.where(algorithm_version: '2.0', source_name: 'oxford').update_all(
      active: true,
      description: 'Oxford Reference',
      updated_at: Time.current
    )

    # Remove the split weights
    CanonicityWeights.where(algorithm_version: '2.0', source_name: ['oxford2', 'oxford3']).destroy_all
  end
end

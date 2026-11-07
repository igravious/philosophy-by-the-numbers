require 'test_helper'

# Focused tests for the canonicity calculation functionality
class PhilosopherCanonicityTest < ActiveSupport::TestCase
  # Create our own test data to avoid fixture conflicts
  # Fixtures are loaded but we use high entity_ids (> 9000) to avoid conflicts

  def setup
    # Clean up any existing test data
    MetricSnapshot.where("shadow_id > 9000 AND shadow_type = 'Philosopher'").delete_all
    Philosopher.where("entity_id > 9000").delete_all
    
    # Ensure we have the algorithm weights for testing
    unless CanonicityWeights.exists?(algorithm_version: '2.1')
      seed_canonicity_weights
    end
  end
  
  private
  
  def seed_canonicity_weights
    weights_v2 = [
      {source_name: "runes", weight_value: nil, description: "Runes (inactive legacy source)", active: false},
      { source_name: 'inphobool', weight_value: 0.10, description: 'Internet Encyclopedia of Philosophy' },
      { source_name: 'borchert', weight_value: 0.17, description: 'Macmillan Encyclopedia (Borchert)' },
      { source_name: 'internet', weight_value: 0.03, description: 'Internet sources' },
      { source_name: 'cambridge', weight_value: 0.13, description: 'Cambridge Dictionary of Philosophy' },
      { source_name: 'kemerling', weight_value: 0.07, description: 'Kemerling Philosophy Pages' },
      { source_name: 'populate', weight_value: 0.01, description: 'Wikipedia (as philosopher)' },
      {source_name: "oxford2", weight_value: nil, description: "Oxford Dictionary of Philosophy, 2nd ed. (inactive legacy source)", active: false},
      { source_name: 'oxford3', weight_value: 0.13, description: 'Oxford Dictionary of Philosophy, 3rd ed.' },
      { source_name: 'routledge', weight_value: 0.17, description: 'Routledge Encyclopedia of Philosophy' },
      { source_name: 'dbpedia', weight_value: 0.01, description: 'DBpedia (as philosopher)' },
      { source_name: 'stanford', weight_value: 0.10, description: 'Stanford Encyclopedia of Philosophy' },
      { source_name: 'all_bonus', weight_value: 0.08, description: 'Bonus for having any authoritative sources' }
    ]
    
    weights_v2.each do |weight|
      CanonicityWeights.create!(
        algorithm_version: '2.1',
        source_name: weight[:source_name],
        weight_value: weight[:weight_value],
        description: weight[:description],
        active: weight.fetch(:active, true)
      )
    end
  end
  
  def teardown
    # Clean up test data
    MetricSnapshot.where("shadow_id > 9000 AND shadow_type = 'Philosopher'").delete_all
    Philosopher.where("entity_id > 9000").delete_all
  end
  
  test "calculate_canonicity_measure returns float between 0 and 1" do
    philosopher = Philosopher.create!(
      entity_id: 9999,
      mention: 100,
      danker: 0.5,
      inphobool: true,
      stanford: true,
      cambridge: false,
      routledge: true,
      oxford2: false,
      oxford3: false
    )
    
    result = philosopher.calculate_canonicity_measure
    assert_kind_of Float, result
    assert result >= 0.0
    assert result <= 1.0
  end
  
  test "calculate_canonicity_measure considers boolean source flags" do
    # Test with all sources true
    high_canon_philosopher = Philosopher.create!(
      entity_id: 9990,
      mention: 200,
      danker: 0.8,
      inphobool: true,
      stanford: true,
      cambridge: true,
      routledge: true,
      oxford2: true,
      oxford3: true
    )
    
    # Test with all sources false
    low_canon_philosopher = Philosopher.create!(
      entity_id: 9991,
      mention: 50,
      danker: 0.2,
      inphobool: false,
      stanford: false,
      cambridge: false,
      routledge: false,
      oxford2: false,
      oxford3: false
    )
    
    high_result = high_canon_philosopher.calculate_canonicity_measure
    low_result = low_canon_philosopher.calculate_canonicity_measure
    
    assert high_result > low_result, "Philosopher with more sources should have higher canonicity. High: #{high_result}, Low: #{low_result}"
  end
  
  test "calculate_canonicity_measure does not create an unlinked metric snapshot" do
    philosopher = Philosopher.create!(
      entity_id: 9992,
      mention: 150,
      danker: 0.6,
      inphobool: true,
      stanford: false,
      cambridge: true,
      routledge: true,
      oxford2: false,
      oxford3: false
    )

    initial_count = philosopher.metric_snapshots.count
    result = philosopher.calculate_canonicity_measure

    assert_kind_of Float, result
    assert_equal initial_count, philosopher.metric_snapshots.count
  end
  
  test "philosopher with zero mention gets minimum measure" do
    philosopher = Philosopher.create!(
      entity_id: 9993,
      mention: 0,
      danker: 0.1,
      inphobool: false,
      stanford: false,
      cambridge: false,
      routledge: false,
      oxford2: false,
      oxford3: false
    )
    
    result = philosopher.calculate_canonicity_measure
    assert result >= 0, "Zero mention should not produce negative measure, got #{result}"
  end
  
  test "philosopher with nil danker gets minimum rank" do
    philosopher = Philosopher.create!(
      entity_id: 9994,
      mention: 100,
      danker: nil,
      inphobool: true,
      stanford: false,
      cambridge: false,
      routledge: false,
      oxford2: false,
      oxford3: false
    )
    
    result = philosopher.calculate_canonicity_measure
    assert result >= 0, "Nil danker should not produce negative measure"
  end
end
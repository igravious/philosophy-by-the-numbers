require 'test_helper'

class CanonicityCalculationTest < ActiveSupport::TestCase
  setup do
    # Clean up any existing test data
    MetricSnapshot.where("shadow_id > 9000 AND shadow_type = 'Philosopher'").delete_all
    Philosopher.where("entity_id > 9000").delete_all

    # Ensure we have the algorithm weights for testing
    unless CanonicityWeights.exists?(algorithm_version: '2.0')
      seed_canonicity_weights
    end

    # Create test philosophers with known values for predictable testing
    # Use entity_id > 9000 for isolation from fixture data
    @philosopher1 = Philosopher.create!(
      entity_id: 9010,
      mention: 200,
      danker: 1.0,
      oxford2: true,
      oxford3: true,
      stanford: true,
      routledge: true,
      cambridge: true,
      borchert: true,
      internet: true,
      kemerling: true,
      inphobool: true,
      dbpedia: true,
      populate: true
    )
    
    @philosopher2 = Philosopher.create!(
      entity_id: 9011,
      mention: 50,
      danker: 0.25,
      oxford2: false,
      oxford3: false,
      stanford: true,
      routledge: false,
      cambridge: false,
      borchert: false,
      internet: false,
      kemerling: false,
      inphobool: false,
      dbpedia: false,
      populate: false
    )
  end

  def teardown
    # Clean up test data
    MetricSnapshot.where("shadow_id > 9000 AND shadow_type = 'Philosopher'").delete_all
    Philosopher.where("entity_id > 9000").delete_all
  end

  private

  def seed_canonicity_weights
    weights_v2 = [
      { source_name: 'runes', weight_value: 0.0, description: 'Runes (biased, excluded)' },
      { source_name: 'inphobool', weight_value: 0.15, description: 'Internet Encyclopedia of Philosophy' },
      { source_name: 'borchert', weight_value: 0.25, description: 'Macmillan Encyclopedia (Borchert)' },
      { source_name: 'internet', weight_value: 0.05, description: 'Internet sources' },
      { source_name: 'cambridge', weight_value: 0.2, description: 'Cambridge Dictionary of Philosophy' },
      { source_name: 'kemerling', weight_value: 0.1, description: 'Kemerling Philosophy Pages' },
      { source_name: 'populate', weight_value: 0.02, description: 'Wikipedia (as philosopher)' },
      { source_name: 'oxford2', weight_value: 0.1, description: 'Oxford Dictionary of Philosophy, 2nd ed.' },
      { source_name: 'oxford3', weight_value: 0.1, description: 'Oxford Dictionary of Philosophy, 3rd ed.' },
      { source_name: 'routledge', weight_value: 0.25, description: 'Routledge Encyclopedia of Philosophy' },
      { source_name: 'dbpedia', weight_value: 0.01, description: 'DBpedia (as philosopher)' },
      { source_name: 'stanford', weight_value: 0.15, description: 'Stanford Encyclopedia of Philosophy' },
      { source_name: 'all_bonus', weight_value: 0.13, description: 'Bonus for having any authoritative sources' }
    ]

    weights_v2.each do |weight|
      CanonicityWeights.create!(
        algorithm_version: '2.0',
        source_name: weight[:source_name],
        weight_value: weight[:weight_value],
        description: weight[:description],
        active: true
      )
    end
  end

  test "canonicity metric calculation preserves input values" do
    original_mention1 = @philosopher1.mention
    original_danker1 = @philosopher1.danker
    original_mention2 = @philosopher2.mention
    original_danker2 = @philosopher2.danker
    
    # Simulate the metric calculation (we'll implement this method)
    @philosopher1.calculate_canonicity_measure
    @philosopher2.calculate_canonicity_measure
    
    # Values should be preserved
    assert_equal original_mention1, @philosopher1.mention
    assert_equal original_danker1, @philosopher1.danker
    assert_equal original_mention2, @philosopher2.mention
    assert_equal original_danker2, @philosopher2.danker
  end
  
  test "philosopher with all sources has higher measure than partial sources" do
    measure1 = @philosopher1.calculate_canonicity_measure
    measure2 = @philosopher2.calculate_canonicity_measure

    assert measure1 > measure2,
           "Philosopher with all sources should have higher measure"
  end
  
  test "measure calculation is deterministic" do
    first_measure = @philosopher1.calculate_canonicity_measure
    second_measure = @philosopher1.calculate_canonicity_measure

    assert_equal first_measure, second_measure,
                 "Same inputs should produce same measure"
  end
  
  test "measure is positive for valid philosophers" do
    measure = @philosopher1.calculate_canonicity_measure
    assert measure > 0, "Valid philosopher should have positive measure"
  end
  
  test "philosopher with zero mention gets minimum measure" do
    @philosopher2.update!(mention: 0)
    measure = @philosopher2.calculate_canonicity_measure

    # Should get minimum values in calculation
    assert measure >= 0, "Zero mention should not produce negative measure"
  end
  
  test "philosopher with nil danker gets minimum rank" do
    @philosopher2.update!(danker: nil)
    measure = @philosopher2.calculate_canonicity_measure

    assert measure >= 0, "Nil danker should not produce negative measure"
  end
end
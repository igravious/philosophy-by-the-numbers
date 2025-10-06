require 'test_helper'

class CanonicityCalculationTest < ActiveSupport::TestCase
  setup do
    # Create test philosophers with known values for predictable testing
    @philosopher1 = Philosopher.create!(
      entity_id: 1001,
      mention: 200,
      danker: 1.0,
      oxford: true,
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
      entity_id: 1002,
      mention: 50,
      danker: 0.25,
      oxford: false,
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
    @philosopher1.calculate_canonicity_measure
    @philosopher2.calculate_canonicity_measure
    
    assert @philosopher1.measure > @philosopher2.measure, 
           "Philosopher with all sources should have higher measure"
  end
  
  test "measure calculation is deterministic" do
    @philosopher1.calculate_canonicity_measure
    first_measure = @philosopher1.measure
    
    @philosopher1.calculate_canonicity_measure
    second_measure = @philosopher1.measure
    
    assert_equal first_measure, second_measure, 
                 "Same inputs should produce same measure"
  end
  
  test "measure is positive for valid philosophers" do
    @philosopher1.calculate_canonicity_measure
    assert @philosopher1.measure > 0, "Valid philosopher should have positive measure"
  end
  
  test "philosopher with zero mention gets minimum measure" do
    @philosopher2.update!(mention: 0)
    @philosopher2.calculate_canonicity_measure
    
    # Should get minimum values in calculation
    assert @philosopher2.measure >= 0, "Zero mention should not produce negative measure"
  end
  
  test "philosopher with nil danker gets minimum rank" do
    @philosopher2.update!(danker: nil)
    @philosopher2.calculate_canonicity_measure
    
    assert @philosopher2.measure >= 0, "Nil danker should not produce negative measure"
  end
end
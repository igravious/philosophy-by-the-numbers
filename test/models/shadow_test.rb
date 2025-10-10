require 'test_helper'

class ShadowTest < ActiveSupport::TestCase
  test "philosopher has canonicity measurement fields" do
    philosopher = Philosopher.new
    assert_respond_to philosopher, :measure
    assert_respond_to philosopher, :measure_pos
    assert_respond_to philosopher, :danker
    # dbpedia_pagerank is now obsolete and stored in obsolete_attrs
    assert_respond_to philosopher, :mention
    assert_respond_to philosopher, :linkcount
  end
  
  test "philosopher has source presence fields" do
    philosopher = Philosopher.new
    assert_respond_to philosopher, :oxford2
    assert_respond_to philosopher, :oxford3
    assert_respond_to philosopher, :stanford
    assert_respond_to philosopher, :routledge
    assert_respond_to philosopher, :cambridge
    assert_respond_to philosopher, :borchert
    assert_respond_to philosopher, :internet
    assert_respond_to philosopher, :kemerling
    assert_respond_to philosopher, :inphobool
    assert_respond_to philosopher, :dbpedia
    assert_respond_to philosopher, :populate
  end
end

class PhilosopherTest < ActiveSupport::TestCase
  setup do
    @philosopher = Philosopher.new(
      entity_id: 1234,
      mention: 100,
      danker: 0.5,
      oxford2: false,
      oxford3: true,
      stanford: true,
      routledge: false,
      cambridge: true,
      borchert: true,
      internet: false,
      kemerling: false,
      inphobool: true,
      dbpedia: true,
      populate: true
    )
  end
  
  test "philosopher responds to canonicity methods" do
    assert_respond_to @philosopher, :capacities
    assert_respond_to @philosopher, :relevant?
    assert_respond_to @philosopher, :birth_death
  end
  
  test "philosopher canonicity calculation inputs are preserved" do
    @philosopher.save!

    saved_philosopher = Philosopher.find(@philosopher.id)
    assert_equal 100, saved_philosopher.mention
    assert_equal 0.5, saved_philosopher.danker
    assert_not saved_philosopher.oxford2
    assert saved_philosopher.oxford3
    assert saved_philosopher.stanford
    assert_not saved_philosopher.routledge
    assert saved_philosopher.cambridge
  end
end

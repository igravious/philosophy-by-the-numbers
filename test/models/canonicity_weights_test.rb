require 'test_helper'

class CanonicityWeightsTest < ActiveSupport::TestCase
  test "canonicity weight can be read from fixtures" do
    weight = canonicity_weights(:danker_v2)
    assert_not_nil weight
    assert_equal "danker", weight.source_name
    assert_equal "2.0", weight.algorithm_version
  end

  test "validates presence of algorithm_version" do
    weight = CanonicityWeights.new(source_name: "test", weight_value: 0.1)
    assert_not weight.valid?
    assert weight.errors[:algorithm_version].any?
  end

  test "validates presence of source_name" do
    weight = CanonicityWeights.new(algorithm_version: "3.0", weight_value: 0.1)
    assert_not weight.valid?
    assert weight.errors[:source_name].any?
  end

  test "validates presence of weight_value" do
    weight = CanonicityWeights.new(algorithm_version: "3.0", source_name: "test")
    assert_not weight.valid?
    assert weight.errors[:weight_value].any?
  end

  test "allows nil weight for an inactive legacy source" do
    weight = CanonicityWeights.new(algorithm_version: "3.0", source_name: "runes", active: false)
    assert weight.valid?
    weight.save!
    assert_nil weight.reload.weight_value
  end

  test "validates weight_value is non-negative" do
    weight = CanonicityWeights.new(algorithm_version: "3.0", source_name: "test", weight_value: -0.1)
    assert_not weight.valid?
    assert weight.errors[:weight_value].any?
  end

  test "validates uniqueness of source_name scoped to algorithm_version" do
    weight = CanonicityWeights.new(algorithm_version: "2.0", source_name: "danker", weight_value: 0.5)
    assert_not weight.valid?
    assert weight.errors[:source_name].any?
  end

  test "allows same source_name for different algorithm versions" do
    weight = CanonicityWeights.new(algorithm_version: "3.0", source_name: "danker", weight_value: 0.3)
    assert weight.valid?
  end

  test "active scope returns only active weights" do
    active = CanonicityWeights.active
    active.each do |w|
      assert w.active
    end
  end

  test "for_version scope filters by algorithm version" do
    v2 = CanonicityWeights.for_version("2.0")
    v2.each do |w|
      assert_equal "2.0", w.algorithm_version
    end
  end

  test "weights_for_version returns hash of source to weight" do
    weights = CanonicityWeights.weights_for_version("2.0")
    assert_kind_of Hash, weights
    assert weights.key?("danker")
    assert_equal 0.25, weights["danker"].to_f
  end

  test "weights_for_version excludes inactive weights" do
    weights = CanonicityWeights.weights_for_version("1.0")
    assert_empty weights
  end

  test "active_version returns latest active version" do
    version = CanonicityWeights.active_version
    assert_equal "2.0", version
  end

  test "sum_for_version returns sum of active weights" do
    total = CanonicityWeights.sum_for_version("2.0")
    assert total > 0
    assert_equal 0.6, total.to_f
  end
end

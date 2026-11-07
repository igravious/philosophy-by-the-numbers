require "test_helper"

class CanonicityPhilosopherV2Test < ActiveSupport::TestCase
  def weights
    {
      "runes" => 0.0,
      "inphobool" => 0.10,
      "borchert" => 0.17,
      "internet" => 0.03,
      "cambridge" => 0.13,
      "kemerling" => 0.07,
      "populate" => 0.01,
      "oxford2" => 0.0,
      "oxford3" => 0.13,
      "routledge" => 0.17,
      "dbpedia" => 0.01,
      "stanford" => 0.10,
      "all_bonus" => 0.08
    }
  end

  def normalization
    {max_mention: 200.0, max_rank: 2.0, min_rank: 0.1}
  end

  def inputs(overrides = {})
    {
      mention: 100,
      danker: 1.0,
      capacities: [],
      sources: {
        runes: false,
        inphobool: false,
        borchert: false,
        internet: false,
        cambridge: false,
        kemerling: false,
        populate: false,
        oxford2: false,
        oxford3: false,
        routledge: true,
        dbpedia: false,
        stanford: true
      }
    }.merge(overrides)
  end

  def call(overrides = {})
    Canonicity::Philosopher::V2.call(
      inputs: inputs(overrides),
      weights: weights,
      normalization_context: normalization
    )
  end

  test "active bitset weights sum to one" do
    assert_in_delta 1.0, weights.values.sum, 0.000001
  end

  test "calculates normalized and display-scaled measures using source coverage and all bonus" do
    result = call

    assert_in_delta 0.0875, result[:normalized_measure], 0.000001
    assert_in_delta 875_000.0, result[:measure], 0.000001
    assert_in_delta 0.35, result[:calculation_context][:total_source_weight], 0.000001
  end

  test "all bonus requires a positively weighted source" do
    result = call(sources: inputs[:sources].merge(routledge: false, stanford: false, oxford2: true))

    assert_equal 0.0, result[:measure]
    assert_equal 0.0, result[:calculation_context][:source_contributions]["all_bonus"]
  end

  test "inactive legacy sources do not contribute even with flags and stale weights" do
    result = Canonicity::Philosopher::V2.call(
      inputs: inputs(sources: inputs[:sources].merge(runes: true, oxford2: true, routledge: false, stanford: false)),
      weights: weights.merge("runes" => 0.1, "oxford2" => 0.1),
      normalization_context: normalization
    )

    assert_equal 0.0, result[:measure]
    assert_not result[:calculation_context][:source_contributions].key?("runes")
    assert_not result[:calculation_context][:source_contributions].key?("oxford2")
  end

  test "role suppression uses more than one configured capacity" do
    result = call(capacities: [413, 41_217])

    assert_equal 0.0, result[:measure]
    assert_equal 0.0, result[:calculation_context][:mention]
    assert_equal 200.0, result[:calculation_context][:max_mention]
  end

  test "one suppressed capacity does not trigger role suppression" do
    result = call(capacities: [413])

    assert_in_delta 0.0875, result[:normalized_measure], 0.000001
  end

  test "nil danker uses the fallback while zero danker remains zero" do
    missing = call(danker: nil)
    actual_zero = call(danker: 0.0)

    assert_in_delta 0.1, missing[:calculation_context][:rank], 0.000001
    assert_in_delta 0.00875, missing[:normalized_measure], 0.000001
    assert_equal 0.0, actual_zero[:measure]
  end

  test "nil and zero mention produce zero measure" do
    assert_equal 0.0, call(mention: nil)[:measure]
    assert_equal 0.0, call(mention: 0)[:measure]
  end

  test "zero maxima and zero source coverage return finite zeroes" do
    zero_maxima = Canonicity::Philosopher::V2.call(
      inputs: inputs,
      weights: weights,
      normalization_context: {max_mention: 0.0, max_rank: 0.0, min_rank: 0.1}
    )
    no_sources = call(sources: inputs[:sources].merge(routledge: false, stanford: false))

    assert_equal 0.0, zero_maxima[:measure]
    assert_equal 0.0, zero_maxima[:normalized_measure]
    assert_equal 0.0, no_sources[:measure]
    assert zero_maxima[:measure].finite?
    assert zero_maxima[:normalized_measure].finite?
  end

  test "rejects a scalar component above one" do
    error = assert_raises(Canonicity::NormalizationError) { call(mention: 201) }

    assert_match(/mention/, error.message)
  end

  test "rejects bitset coverage above one" do
    error = assert_raises(Canonicity::NormalizationError) do
      Canonicity::Philosopher::V2.call(
        inputs: inputs,
        weights: weights.merge("routledge" => 1.0),
        normalization_context: normalization
      )
    end

    assert_match(/source_coverage/, error.message)
  end
end

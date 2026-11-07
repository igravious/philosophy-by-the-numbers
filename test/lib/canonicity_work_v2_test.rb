require "test_helper"

class CanonicityWorkV2Test < ActiveSupport::TestCase
  def weights
    {
      "borchert" => 0.25,
      "cambridge" => 0.20,
      "routledge" => 0.25,
      "philpapers" => 0.20,
      "all_bonus" => 0.10,
      "genre_philosophical" => 1.0,
      "genre_other" => 0.50
    }
  end

  def normalization
    {max_mention: 200.0, max_rank: 2.0, min_rank: 0.1}
  end

  def inputs(overrides = {})
    {
      mention: 100,
      danker: 1.0,
      borchert: true,
      cambridge: true,
      routledge: false,
      philrecord: false,
      philtopic: false,
      genre: true
    }.merge(overrides)
  end

  def call(overrides = {}, author_measures = [0.5, 0.25])
    Canonicity::Work::V2.call(
      inputs: inputs(overrides),
      weights: weights,
      normalization_context: normalization,
      dependency_inputs: {author_measures: author_measures}
    )
  end

  test "calculates normalized and display-scaled measures with genre applied once" do
    result = call

    assert_in_delta 0.1375, result[:normalized_measure], 0.000001
    assert_in_delta 137_500.0, result[:measure], 0.000001
    assert_in_delta 0.55, result[:calculation_context][:sourcey], 0.000001
  end

  test "non philosophical genre multiplies only once" do
    result = call({genre: false})

    assert_in_delta 0.06875, result[:normalized_measure], 0.000001
    assert_in_delta 68_750.0, result[:measure], 0.000001
  end

  test "philpapers alone contributes but does not trigger all bonus" do
    result = call({borchert: false, cambridge: false, philrecord: true}, [])

    assert_equal 0.0, result[:calculation_context][:source_contributions]["all_bonus"]
    assert_in_delta 0.05, result[:normalized_measure], 0.000001
  end

  test "all zero authors negate sourcey before any zero floor is applied" do
    result = call({}, [0.0, 0.0])

    assert_in_delta(-0.55, result[:calculation_context][:exists], 0.000001)
    assert_equal 0.0, result[:measure]
  end

  test "zero sourcey receives its floor after author adjustment" do
    result = call({borchert: false, cambridge: false}, [0.0])

    assert_equal 0.0, result[:calculation_context][:exists]
    assert_in_delta 0.1, result[:calculation_context][:sourcey], 0.000001
    assert_in_delta 0.025, result[:normalized_measure], 0.000001
  end

  test "missing author measure is rejected explicitly" do
    error = assert_raises(ArgumentError) { call({}, [nil]) }

    assert_match(/author measure is missing/, error.message)
  end

  test "nil danker uses fallback while zero danker remains zero" do
    missing = call({danker: nil})
    actual_zero = call({danker: 0.0})

    assert_in_delta 0.1, missing[:calculation_context][:rank], 0.000001
    assert_in_delta 0.01375, missing[:normalized_measure], 0.000001
    assert_equal 0.0, actual_zero[:measure]
  end

  test "missing mention uses the work default" do
    result = call({mention: nil})

    assert_in_delta 0.5, result[:calculation_context][:mention], 0.000001
    assert_in_delta 0.0006875, result[:normalized_measure], 0.000001
  end

  test "zero maxima return finite zeroes before either output is derived" do
    result = Canonicity::Work::V2.call(
      inputs: inputs,
      weights: weights,
      normalization_context: {max_mention: 0.0, max_rank: 0.0, min_rank: 0.1},
      dependency_inputs: {author_measures: []}
    )

    assert_equal 0.0, result[:measure]
    assert_equal 0.0, result[:normalized_measure]
    assert result[:measure].finite?
    assert result[:normalized_measure].finite?
  end

  test "rejects scalar and genre components above one" do
    assert_raises(Canonicity::NormalizationError) { call(mention: 201) }
    error = assert_raises(Canonicity::NormalizationError) do
      Canonicity::Work::V2.call(
        inputs: inputs,
        weights: weights.merge("genre_philosophical" => 1.1),
        normalization_context: normalization,
        dependency_inputs: {author_measures: [0.5]}
      )
    end

    assert_match(/genre/, error.message)
  end

  test "rejects source and author coverage above one" do
    error = assert_raises(Canonicity::NormalizationError) do
      Canonicity::Work::V2.call(
        inputs: inputs,
        weights: weights.merge("borchert" => 1.0),
        normalization_context: normalization,
        dependency_inputs: {author_measures: [0.5]}
      )
    end

    assert_match(/source_and_author/, error.message)
  end
end

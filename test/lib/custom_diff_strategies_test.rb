require 'test_helper'
require 'delta_analysis/custom_diff_strategies'

class TermWeightStrategyTest < ActiveSupport::TestCase
  # TermWeightStrategy.calculate_delta returns 0.0 (not a hash) when both term sets are empty
  test "returns zero for identical empty results" do
    result = CustomDiffStrategies::TermWeightStrategy.calculate_delta(
      { terms: {} }, { terms: {} }
    )
    assert_equal 0.0, result
  end

  test "detects added terms" do
    result_a = { terms: { 'philosophy' => 1.0 } }
    result_b = { terms: { 'philosophy' => 1.0, 'ethics' => 0.5 } }
    result = CustomDiffStrategies::TermWeightStrategy.calculate_delta(result_a, result_b)
    assert_kind_of Hash, result
    assert_includes result[:details][:added_terms], 'ethics'
    assert result[:magnitude] > 0
  end

  test "detects removed terms" do
    result_a = { terms: { 'philosophy' => 1.0, 'logic' => 0.5 } }
    result_b = { terms: { 'philosophy' => 1.0 } }
    result = CustomDiffStrategies::TermWeightStrategy.calculate_delta(result_a, result_b)
    assert_includes result[:details][:removed_terms], 'logic'
    assert result[:magnitude] > 0
  end

  test "detects weight changes in common terms" do
    result_a = { terms: { 'philosophy' => 1.0 } }
    result_b = { terms: { 'philosophy' => 2.0 } }
    result = CustomDiffStrategies::TermWeightStrategy.calculate_delta(result_a, result_b)
    changes = result[:details][:weight_changes]
    assert changes.key?('philosophy')
    assert_equal 1.0, changes['philosophy'][:change]
  end

  test "handles hash-based term weights" do
    result_a = { terms: { 'ethics' => { 'weight' => 0.5 } } }
    result_b = { terms: { 'ethics' => { 'weight' => 0.8 } } }
    result = CustomDiffStrategies::TermWeightStrategy.calculate_delta(result_a, result_b)
    changes = result[:details][:weight_changes]
    assert changes.key?('ethics')
  end

  test "handles nil term data in extract_weight" do
    result_a = { terms: { 'test' => nil } }
    result_b = { terms: { 'test' => 1.0 } }
    result = CustomDiffStrategies::TermWeightStrategy.calculate_delta(result_a, result_b)
    assert_not_nil result
  end

  test "returns zero for missing terms key" do
    result = CustomDiffStrategies::TermWeightStrategy.calculate_delta({}, {})
    assert_equal 0.0, result
  end

  test "returns strategy name in result" do
    result_a = { terms: { 'a' => 1 } }
    result_b = { terms: { 'a' => 2 } }
    result = CustomDiffStrategies::TermWeightStrategy.calculate_delta(result_a, result_b)
    assert_equal 'term_weight', result[:strategy]
  end
end

class SemanticSimilarityStrategyTest < ActiveSupport::TestCase
  # For empty sets: union is empty, so jaccard_similarity=0.0, jaccard_distance=1.0
  test "returns magnitude 1.0 for identical empty results" do
    result = CustomDiffStrategies::SemanticSimilarityStrategy.calculate_delta(
      { terms: {} }, { terms: {} }
    )
    assert_equal 'semantic_similarity', result[:strategy]
    assert_equal 1.0, result[:magnitude]
  end

  test "calculates jaccard distance for disjoint sets" do
    result_a = { terms: { 'a' => 1, 'b' => 1 } }
    result_b = { terms: { 'c' => 1, 'd' => 1 } }
    result = CustomDiffStrategies::SemanticSimilarityStrategy.calculate_delta(result_a, result_b)
    assert_equal 0.0, result[:details][:jaccard_similarity]
    assert_equal 1.0, result[:details][:jaccard_distance]
  end

  test "calculates jaccard distance for identical sets" do
    result_a = { terms: { 'a' => 1, 'b' => 1 } }
    result_b = { terms: { 'a' => 1, 'b' => 1 } }
    result = CustomDiffStrategies::SemanticSimilarityStrategy.calculate_delta(result_a, result_b)
    assert_equal 1.0, result[:details][:jaccard_similarity]
    assert_equal 0.0, result[:details][:jaccard_distance]
  end

  test "calculates jaccard distance for overlapping sets" do
    result_a = { terms: { 'a' => 1, 'b' => 1 } }
    result_b = { terms: { 'b' => 1, 'c' => 1 } }
    result = CustomDiffStrategies::SemanticSimilarityStrategy.calculate_delta(result_a, result_b)
    assert_in_delta(1.0 / 3.0, result[:details][:jaccard_similarity], 0.001)
  end

  test "includes semantic distance when similarity matrices present" do
    result_a = { terms: { 'a' => 1 }, term_similarity: { 'a' => { 'b' => 0.5 } } }
    result_b = { terms: { 'a' => 1 }, term_similarity: { 'a' => { 'b' => 0.8 } } }
    result = CustomDiffStrategies::SemanticSimilarityStrategy.calculate_delta(result_a, result_b)
    assert_not_nil result[:details][:semantic_distance]
  end
end

class DocumentDistributionStrategyTest < ActiveSupport::TestCase
  test "returns zero for identical empty results" do
    result = CustomDiffStrategies::DocumentDistributionStrategy.calculate_delta(
      { doc_terms: {} }, { doc_terms: {} }
    )
    assert_equal 'document_distribution', result[:strategy]
    assert_equal 0.0, result[:magnitude]
  end

  test "detects added documents" do
    result_a = { doc_terms: { 'doc1' => { 'term' => 1 } } }
    result_b = { doc_terms: { 'doc1' => { 'term' => 1 }, 'doc2' => { 'term' => 1 } } }
    result = CustomDiffStrategies::DocumentDistributionStrategy.calculate_delta(result_a, result_b)
    assert_includes result[:details][:added_docs], 'doc2'
    assert result[:magnitude] > 0
  end

  test "detects removed documents" do
    result_a = { doc_terms: { 'doc1' => { 'a' => 1 }, 'doc2' => { 'b' => 1 } } }
    result_b = { doc_terms: { 'doc1' => { 'a' => 1 } } }
    result = CustomDiffStrategies::DocumentDistributionStrategy.calculate_delta(result_a, result_b)
    assert_includes result[:details][:removed_docs], 'doc2'
  end

  test "calculates entropy for term distributions" do
    result_a = { doc_terms: { 'doc1' => { 'a' => 1, 'b' => 1 } } }
    result_b = { doc_terms: { 'doc1' => { 'a' => 1, 'b' => 1, 'c' => 1 } } }
    result = CustomDiffStrategies::DocumentDistributionStrategy.calculate_delta(result_a, result_b)
    assert result[:details][:entropy_a] > 0
    assert result[:details][:entropy_b] > 0
  end

  test "handles array-based doc terms" do
    result_a = { doc_terms: { 'doc1' => ['a', 'b'] } }
    result_b = { doc_terms: { 'doc1' => ['a', 'b', 'c'] } }
    result = CustomDiffStrategies::DocumentDistributionStrategy.calculate_delta(result_a, result_b)
    assert_not_nil result[:magnitude]
  end

  test "handles missing doc_terms key" do
    result = CustomDiffStrategies::DocumentDistributionStrategy.calculate_delta({}, {})
    assert_equal 0.0, result[:magnitude]
  end
end

class CompositeStrategyTest < ActiveSupport::TestCase
  test "combines strategy results" do
    result_a = { terms: { 'a' => 1 } }
    result_b = { terms: { 'a' => 1, 'b' => 1 } }
    result = CustomDiffStrategies::CompositeStrategy.calculate_delta(result_a, result_b)
    assert_equal 'composite', result[:strategy]
    assert result[:magnitude] >= 0
    assert result[:details].key?(:strategy_results)
    assert result[:details].key?(:weights)
  end

  test "accepts custom weights" do
    result_a = { terms: { 'a' => 1 } }
    result_b = { terms: { 'b' => 1 } }
    custom_weights = { 'term_weight' => 1.0 }
    result = CustomDiffStrategies::CompositeStrategy.calculate_delta(result_a, result_b, weights: custom_weights)
    assert_equal custom_weights, result[:details][:weights]
  end

  test "STRATEGIES constant includes TermWeightStrategy" do
    assert_includes CustomDiffStrategies::CompositeStrategy::STRATEGIES,
                    CustomDiffStrategies::TermWeightStrategy
  end
end

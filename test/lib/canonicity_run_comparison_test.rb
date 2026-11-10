require "test_helper"
require_relative "../support/canonicity_run_helpers"

class CanonicityRunComparisonTest < ActiveSupport::TestCase
  include CanonicityRunHelpers

  setup do
    @first = create_test_philosopher(entity_id: 42)
    @second = create_test_philosopher(entity_id: 43)
    @third = create_test_philosopher(entity_id: 44)
    @from = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@first, @second],
      measures: {@first.id => 100.0, @second.id => 50.0}
    )
    @to = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@second, @third],
      measures: {@second.id => 75.0, @third.id => 125.0},
      version: "0.7.1"
    )
  end

  test "reports entity measure and dense rank movement" do
    report = Canonicity::RunComparison.new(from_run: @from, to_run: @to).call

    assert_equal [@third.id], report.added_entities
    assert_equal [@first.id], report.missing_entities
    assert_equal 0, report.unchanged_entity_count
    assert_equal 1, report.changes.length
    change = report.changes.first
    assert_equal @second.id, change[:shadow_id]
    assert_equal 43, change[:entity_id]
    assert_equal 50.0, change[:from_measure]
    assert_equal 75.0, change[:to_measure]
    assert_equal 25.0, change[:measure_change]
    assert_equal 2, change[:from_rank]
    assert_equal 2, change[:to_rank]
    assert_equal 0, change[:rank_change]
  end

  test "reports population normalization calculator and configuration differences" do
    @to.update_column(:configuration_fingerprint, "different-fingerprint")
    report = Canonicity::RunComparison.new(from_run: @from, to_run: @to).call
    result = report.to_h

    assert_equal [@third.id], result[:population][:selected][:added]
    assert_equal [@first.id], result[:population][:selected][:missing]
    assert_equal [@third.id], result[:population][:normalization][:added]
    assert_equal [@first.id], result[:population][:normalization][:missing]
    assert_equal false, result[:calculator][:changed]
    assert_equal true, result[:configuration][:changed]
    assert_equal "configuration-Philosopher-0.7.0", result[:configuration][:from_fingerprint]
    assert_equal "different-fingerprint", result[:configuration][:to_fingerprint]
  end

  test "identical measures and ranks produce no entity changes" do
    identical = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@first, @second],
      measures: {@first.id => 100.0, @second.id => 50.0},
      version: "0.7.2"
    )

    report = Canonicity::RunComparison.new(from_run: @from, to_run: identical).call

    assert_empty report.changes
    assert_equal 2, report.unchanged_entity_count
    assert_empty report.added_entities
    assert_empty report.missing_entities
  end

  test "rejects comparisons across subject types" do
    work = create_test_work(entity_id: 45)
    work_run = create_completed_metric_run(subject_type: "Work", shadows: [work], measures: {work.id => 10.0})

    error = assert_raises(ArgumentError) do
      Canonicity::RunComparison.new(from_run: @from, to_run: work_run).call
    end
    assert_match(/same subject type/, error.message)
  end
end

require "test_helper"

class CanonicityMetricRunCalculatorTest < ActiveSupport::TestCase
  setup do
    seed_weights("2.1")
    @first = create_test_philosopher(entity_id: 42, mention: 100, danker: 1.0, routledge: true, stanford: true)
    @second = create_test_philosopher(entity_id: 43, mention: 50, danker: 0.5, routledge: true, stanford: true)
    @dataset = Canonicity::DatasetCapture.new(
      subject_type: "Philosopher",
      selected_entity_ids: [@first.id, @second.id],
      normalization_entity_ids: [@first.id, @second.id]
    ).call
  end

  def seed_weights(version, routledge: 0.17, stanford: 0.10, all_bonus: 0.08)
    {"routledge" => routledge, "stanford" => stanford, "all_bonus" => all_bonus}.each do |source, weight|
      weight_record = CanonicityWeights.find_or_initialize_by(algorithm_version: version, source_name: source)
      weight_record.update!(weight_value: weight, active: true)
    end
  end

  test "completes a controlled Philosopher run with dense ranks and unchanged display values" do
    original_measures = [@first.measure, @second.measure]
    run = Canonicity::MetricRunCalculator.new(dataset: @dataset).call

    assert run.completed?
    assert_equal "0.7.0", run.version
    assert_equal "2.1", run.configuration_version
    assert_equal 2, run.metric_snapshots.count
    first_snapshot = run.metric_snapshots.find_by!(shadow_id: @first.id)
    second_snapshot = run.metric_snapshots.find_by!(shadow_id: @second.id)
    assert_in_delta 0.35, first_snapshot.calculation_context["normalized_measure"], 0.000001
    assert_in_delta 0.0875, second_snapshot.calculation_context["normalized_measure"], 0.000001
    assert_equal 1, first_snapshot.measure_pos
    assert_equal 2, second_snapshot.measure_pos
    assert_equal run.weights_config, first_snapshot.weights_config
    assert_equal original_measures, [@first.reload.measure, @second.reload.measure]
  end

  test "recalculation reuses the dataset and allocates patch and minor versions" do
    first_run = Canonicity::MetricRunCalculator.new(dataset: @dataset).call
    second_run = Canonicity::MetricRunCalculator.new(dataset: @dataset, parent_run: first_run).call

    assert_equal "0.7.1", second_run.version
    assert_equal first_run.id, second_run.parent_run_id
    assert_equal first_run.metric_snapshots.pluck(:shadow_id, :measure).sort,
      second_run.metric_snapshots.pluck(:shadow_id, :measure).sort

    seed_weights("2.2", routledge: 0.16)
    third_run = Canonicity::MetricRunCalculator.new(dataset: @dataset, configuration_version: "2.2", parent_run: second_run).call

    assert_equal "0.8.0", third_run.version
    assert_equal "2.2", third_run.configuration_version
    assert_not_equal first_run.configuration_fingerprint, third_run.configuration_fingerprint
  end

  test "dense ranks share one rank for ties and increment once for the next distinct measure" do
    third = create_test_philosopher(entity_id: 44, mention: 100, danker: 1.0, routledge: true, stanford: true)
    dataset = Canonicity::DatasetCapture.new(
      subject_type: "Philosopher", selected_entity_ids: [@first.id, @second.id, third.id],
      normalization_entity_ids: [@first.id, @second.id, third.id]
    ).call

    run = Canonicity::MetricRunCalculator.new(dataset: dataset).call

    assert_equal 1, run.metric_snapshots.find_by!(shadow_id: @first.id).measure_pos
    assert_equal 2, run.metric_snapshots.find_by!(shadow_id: @second.id).measure_pos
    assert_equal 1, run.metric_snapshots.find_by!(shadow_id: third.id).measure_pos
  end

  test "rejects a configuration from another subject type before creating a run" do
    assert_no_difference "MetricRun.count" do
      error = assert_raises(ArgumentError) do
        Canonicity::MetricRunCalculator.new(dataset: @dataset, configuration_version: "2.0-work").call
      end
      assert_match(/not valid for Philosopher/, error.message)
    end
  end

  test "per-entity failure marks the run failed without partial snapshots" do
    partial_dataset = Canonicity::DatasetCapture.new(
      subject_type: "Philosopher", selected_entity_ids: [@first.id], normalization_entity_ids: [@second.id]
    ).call

    error = assert_raises(Canonicity::NormalizationError) do
      Canonicity::MetricRunCalculator.new(dataset: partial_dataset).call
    end

    assert_match(/mention/, error.message)
    run = MetricRun.order(:id).last
    assert_equal "failed", run.status
    assert_equal 0, run.metric_snapshots.count
    assert_equal "0.7.0", run.version
  end

  test "Work calculation uses its independent version sequence and frozen author dependency" do
    {
      "borchert" => 0.25, "cambridge" => 0.20, "routledge" => 0.25,
      "philpapers" => 0.20, "all_bonus" => 0.10,
      "genre_philosophical" => 1.0, "genre_other" => 0.5
    }.each do |source, weight|
      CanonicityWeights.create!(algorithm_version: "2.0-work", source_name: source, weight_value: weight, active: true)
    end
    philosopher_run = Canonicity::MetricRunCalculator.new(dataset: @dataset).call
    work = create_test_work(entity_id: 44, mention: 100, danker: 1.0, borchert: true, cambridge: true, genre: true)
    Expression.create!(creator_id: @first.id, work_id: work.id)
    work_dataset = Canonicity::DatasetCapture.new(
      subject_type: "Work", selected_entity_ids: [work.id], normalization_entity_ids: [work.id], input_run_id: philosopher_run.id
    ).call

    work_run = Canonicity::MetricRunCalculator.new(dataset: work_dataset).call

    assert work_run.completed?
    assert_equal "0.7.0", work_run.version
    assert_equal "work-v2", work_run.calculator_identity
    assert_equal 1, work_run.metric_snapshots.count
    assert_equal philosopher_run.id, work_dataset.input_run_id
  end
end

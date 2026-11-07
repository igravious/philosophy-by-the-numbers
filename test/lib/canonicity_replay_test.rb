require "test_helper"

class CanonicityReplayTest < ActiveSupport::TestCase
  setup do
    {"routledge" => 0.17, "stanford" => 0.10, "all_bonus" => 0.08}.each do |source, weight|
      weight_record = CanonicityWeights.find_or_initialize_by(algorithm_version: "2.1", source_name: source)
      weight_record.update!(weight_value: weight, active: true)
    end
    @first = create_test_philosopher(entity_id: 42, mention: 100, danker: 1.0, routledge: true, stanford: true)
    @second = create_test_philosopher(entity_id: 43, mention: 50, danker: 0.5, routledge: true, stanford: true)
    @dataset = Canonicity::DatasetCapture.new(
      subject_type: "Philosopher", selected_entity_ids: [@first.id, @second.id], normalization_entity_ids: [@first.id, @second.id]
    ).call
    @run = Canonicity::MetricRunCalculator.new(dataset: @dataset).call
  end

  test "replay exactly matches measures population normalization and ranks without writes" do
    original_snapshot_count = MetricSnapshot.count
    original_run_updated_at = @run.updated_at

    report = Canonicity::Replay.new(run: @run).call

    assert report.matches?
    assert_empty report.added_entities
    assert_empty report.missing_entities
    assert_empty report.mismatches
    assert_empty report.normalization_mismatches
    assert_equal original_snapshot_count, MetricSnapshot.count
    assert_equal original_run_updated_at.to_i, @run.reload.updated_at.to_i
  end

  test "replay reports measure rank and population mismatches" do
    snapshot = @run.metric_snapshots.find_by!(shadow_id: @first.id)
    snapshot.update_columns(measure: 0.0, measure_pos: 99)
    @run.metric_snapshots.find_by!(shadow_id: @second.id).delete

    report = Canonicity::Replay.new(run: @run).call

    assert_not report.matches?
    assert_equal [@second.id], report.missing_entities
    assert_equal [@first.id], report.mismatches.map { |mismatch| mismatch[:shadow_id] }
    assert_equal 99, report.mismatches.first[:stored_rank]
  end

  test "replay reports normalization drift without repairing it" do
    @dataset.update_columns(normalization_context: @dataset.normalization_context.merge("max_mention" => 999.0))

    report = Canonicity::Replay.new(run: @run).call

    assert_not report.matches?
    assert report.normalization_mismatches.any? { |mismatch| mismatch[:field] == "max_mention" }
    assert_equal 999.0, @dataset.reload.normalization_context["max_mention"]
  end

  test "replay preserves dense ranks for tied measures" do
    third = create_test_philosopher(entity_id: 44, mention: 100, danker: 1.0, routledge: true, stanford: true)
    dataset = Canonicity::DatasetCapture.new(
      subject_type: "Philosopher", selected_entity_ids: [@first.id, @second.id, third.id],
      normalization_entity_ids: [@first.id, @second.id, third.id]
    ).call
    run = Canonicity::MetricRunCalculator.new(dataset: dataset).call

    report = Canonicity::Replay.new(run: run).call

    assert report.matches?
    assert_equal 1, run.metric_snapshots.find_by!(shadow_id: @first.id).measure_pos
    assert_equal 2, run.metric_snapshots.find_by!(shadow_id: @second.id).measure_pos
    assert_equal 1, run.metric_snapshots.find_by!(shadow_id: third.id).measure_pos
  end
end

require "test_helper"
require_relative "../support/canonicity_run_helpers"

class CanonicityDatasetCaptureTest < ActiveSupport::TestCase
  include CanonicityRunHelpers
  test "captures the selected normalization union with coherent payloads and extrema" do
    selected = create_test_philosopher(entity_id: 42, mention: 100, danker: nil, stanford: true)
    normalization = create_test_philosopher(entity_id: 43, mention: 50, danker: 0.2, stanford: false)

    dataset = Canonicity::DatasetCapture.new(
      subject_type: "Philosopher",
      selected_entity_ids: [selected.id],
      normalization_entity_ids: [selected.id, normalization.id]
    ).call

    assert dataset.ready?
    assert_equal [selected.id], dataset.selected_entity_ids
    assert_equal [selected.id, normalization.id].sort, dataset.normalization_entity_ids
    assert_equal 2, dataset.metric_input_records.count
    selected_record = dataset.metric_input_records.find_by!(shadow_id: selected.id)
    normalization_record = dataset.metric_input_records.find_by!(shadow_id: normalization.id)
    assert selected_record.selected?
    assert selected_record.normalization?
    assert_not normalization_record.selected?
    assert normalization_record.normalization?
    assert_nil selected_record.input_payload["danker"]
    assert selected_record.input_payload["sources"]["stanford"]
    assert_equal 100.0, dataset.normalization_context["max_mention"]
    assert_equal 0.2, dataset.normalization_context["max_rank"]
    assert_equal 0.1, dataset.normalization_context["min_rank"]
  end

  test "capture rejects selected entities outside the normalization population" do
    selected = create_test_philosopher(entity_id: 42, mention: 100)
    normalization = create_test_philosopher(entity_id: 43, mention: 50)

    error = assert_raises(Canonicity::CaptureError) do
      Canonicity::DatasetCapture.new(
        subject_type: "Philosopher",
        selected_entity_ids: [selected.id],
        normalization_entity_ids: [normalization.id]
      ).call
    end

    assert_match(/Selected IDs must be contained in normalization IDs: #{selected.id}/, error.message)
    dataset = MetricInputDataset.order(:id).last
    assert_equal "invalid", dataset.status
    assert_equal 0, dataset.metric_input_records.count
  end

  test "missing entities invalidate capture without retaining partial input records" do
    selected = create_test_philosopher(entity_id: 42)

    assert_raises(Canonicity::CaptureError) do
      Canonicity::DatasetCapture.new(
        subject_type: "Philosopher",
        selected_entity_ids: [selected.id, -1],
        normalization_entity_ids: [selected.id, -1]
      ).call
    end

    dataset = MetricInputDataset.order(:id).last
    assert_equal "invalid", dataset.status
    assert_match(/Missing Philosopher IDs: -1/, dataset.failure_reason)
    assert_equal 0, dataset.metric_input_records.count
  end

  test "Work capture requires a completed Philosopher dependency" do
    work = create_test_work(entity_id: 42)

    error = assert_raises(Canonicity::CaptureError) do
      Canonicity::DatasetCapture.new(
        subject_type: "Work", selected_entity_ids: [work.id], normalization_entity_ids: [work.id]
      ).call
    end
    assert_match(/completed Philosopher run/, error.message)
    dataset = MetricInputDataset.order(:id).last
    assert_equal "invalid", dataset.status
    assert_equal work.id, dataset.selected_entity_ids.first
    assert_match(/completed Philosopher run/, dataset.failure_reason)
  end

  test "capture rejects values that do not match the latest source event" do
    selected = create_test_philosopher(entity_id: 42, danker: 0.5)
    SourceEvent.create!(
      source_name: "danker", import_identity: "danker-new", artifact_identity: "danker.csv",
      artifact_checksum: "abc", shadow_id: selected.id, shadow_type: "Philosopher",
      entity_id: selected.entity_id, attribute_name: "danker", old_value: 0.5, new_value: 0.9,
      provenance: {}, imported_at: Time.current
    )

    error = assert_raises(Canonicity::CaptureError) do
      Canonicity::DatasetCapture.new(
        subject_type: "Philosopher", selected_entity_ids: [selected.id], normalization_entity_ids: [selected.id]
      ).call
    end

    assert_match(/provenance mismatch/, error.message)
    assert_equal "invalid", MetricInputDataset.order(:id).last.status
  end

  test "Work capture freezes author snapshot ids and measures" do
    author = create_test_philosopher(entity_id: 42)
    work = create_test_work(entity_id: 43)
    Expression.create!(creator_id: author.id, work_id: work.id)
    dependency_dataset = MetricInputDataset.create!(
      subject_type: "Philosopher", status: "ready", schema_version: "1.0",
      selected_entity_ids: [author.id], normalization_entity_ids: [author.id],
      normalization_context: {}, source_provenance: {}, population_checksum: "dependency",
      capture_completed_at: Time.current
    )
    run = MetricRun.create!(
      subject_type: "Philosopher", version: "0.7.0", major: 0, minor: 7, patch: 0,
      metric_input_dataset: dependency_dataset, calculator_identity: "philosopher-v2",
      configuration_version: "2.0", configuration_fingerprint: "checksum", status: "running",
      started_at: Time.current, weights_config: {}, signal_config: {}, source_provenance: {}
    )
    snapshot = MetricSnapshot.create!(
      metric_run: run, shadow_id: author.id, shadow_type: "Philosopher",
      calculated_at: Time.current, canonicity_weight_algorithm_version: "2.0",
      danker_version: "unknown", danker_file: "unknown", reference_work_flags: "{}", measure: 123.0
    )
    run.update!(status: "completed", completed_at: Time.current)

    dataset = Canonicity::DatasetCapture.new(
      subject_type: "Work", selected_entity_ids: [work.id], normalization_entity_ids: [work.id]
    ).call

    payload = dataset.metric_input_records.find_by!(shadow_id: work.id).input_payload
    assert_equal run.id, dataset.input_run_id
    assert_equal [author.id], payload["author_ids"]
    assert_equal [snapshot.id], payload["author_snapshot_ids"]
    assert_equal [123.0], payload["author_measures"]
  end

  test "Work capture defaults to the latest completed full-population Philosopher run" do
    first = create_test_philosopher(entity_id: 42)
    second = create_test_philosopher(entity_id: 43)
    philosophers = Philosopher.order(:id).to_a
    full_run = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: philosophers,
      measures: {first.id => 100.0, second.id => 50.0},
      version: "0.8.1"
    )
    partial_run = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [first],
      measures: {first.id => 999.0},
      version: "0.9.0"
    )
    work = create_test_work(entity_id: 44)
    Expression.create!(creator_id: first.id, work_id: work.id)

    dataset = Canonicity::DatasetCapture.new(
      subject_type: "Work", selected_entity_ids: [work.id], normalization_entity_ids: [work.id]
    ).call

    assert_equal full_run.id, dataset.input_run_id
    assert_not_equal partial_run.id, dataset.input_run_id
    payload = dataset.metric_input_records.find_by!(shadow_id: work.id).input_payload
    assert_equal [100.0], payload["author_measures"]
  end

  test "Work capture reports missing author dependencies across all Works" do
    author = create_test_philosopher(entity_id: 42)
    first_work = create_test_work(entity_id: 43)
    second_work = create_test_work(entity_id: 44)
    Expression.create!(creator_id: author.id, work_id: first_work.id)
    Expression.create!(creator_id: author.id, work_id: second_work.id)
    dependency_dataset = MetricInputDataset.create!(
      subject_type: "Philosopher", status: "ready", schema_version: "1.0",
      selected_entity_ids: [author.id], normalization_entity_ids: [author.id],
      normalization_context: {}, source_provenance: {}, population_checksum: "dependency",
      capture_completed_at: Time.current
    )
    MetricRun.create!(
      subject_type: "Philosopher", version: "0.7.0", major: 0, minor: 7, patch: 0,
      metric_input_dataset: dependency_dataset, calculator_identity: "philosopher-v2",
      configuration_version: "2.0", configuration_fingerprint: "checksum", status: "completed",
      started_at: Time.current, completed_at: Time.current,
      weights_config: {}, signal_config: {}, source_provenance: {}
    )

    error = assert_raises(Canonicity::CaptureError) do
      Canonicity::DatasetCapture.new(
        subject_type: "Work", selected_entity_ids: [first_work.id, second_work.id],
        normalization_entity_ids: [first_work.id, second_work.id]
      ).call
    end

    assert_match(/Q43/, error.message)
    assert_match(/Q44/, error.message)
  end
end

require "test_helper"

class MetricRunTest < ActiveSupport::TestCase
  setup do
    @dataset = MetricInputDataset.create!(
      subject_type: "Philosopher", status: "ready", schema_version: "1.0",
      selected_entity_ids: [1], normalization_entity_ids: [1],
      normalization_context: {}, source_provenance: {}, population_checksum: "checksum",
      capture_completed_at: Time.current
    )
  end

  def attributes(overrides = {})
    {
      subject_type: "Philosopher",
      version: "0.7.0",
      major: 0,
      minor: 7,
      patch: 0,
      metric_input_dataset: @dataset,
      calculator_identity: "philosopher-v2",
      configuration_version: "2.0",
      configuration_fingerprint: "configuration-checksum",
      status: "running",
      started_at: Time.current,
      weights_config: {"kemerling" => 0.1, "runes" => nil},
      signal_config: {"suppressed_capacity_ids" => [413, 41_217]},
      source_provenance: {"dataset_checksum" => "checksum"}
    }.merge(overrides)
  end

  test "freezes configuration and signal payloads with their primitive types" do
    run = MetricRun.create!(attributes)

    run.reload
    assert_equal 0.1, run.weights_config["kemerling"]
    assert_nil run.weights_config["runes"]
    assert_equal [413, 41_217], run.signal_config["suppressed_capacity_ids"]
  end

  test "requires semantic version components to match the display version" do
    run = MetricRun.new(attributes(patch: 1))

    assert_not run.valid?
    assert run.errors[:version].any?
  end

  test "completed runs cannot be updated or destroyed" do
    run = MetricRun.create!(attributes(status: "completed", completed_at: Time.current))

    assert_raises(ActiveRecord::ReadOnlyRecord) { run.update!(source_provenance: {}) }
    assert_raises(ActiveRecord::ReadOnlyRecord) { run.destroy }
  end

  test "run-linked snapshots use frozen run weights" do
    run = MetricRun.create!(attributes)
    philosopher = create_test_philosopher
    snapshot = MetricSnapshot.create!(
      metric_run: run,
      shadow_id: philosopher.id,
      shadow_type: "Philosopher",
      calculated_at: Time.current,
      canonicity_weight_algorithm_version: "2.0",
      danker_version: "unknown",
      danker_file: "unknown",
      reference_work_flags: "{}",
      measure: 1.0,
      calculation_context: {"normalized_measure" => 0.0000001}
    )

    assert_equal run.weights_config, snapshot.weights_config
    assert_equal 0.0000001, snapshot.calculation_context["normalized_measure"]
  end
end

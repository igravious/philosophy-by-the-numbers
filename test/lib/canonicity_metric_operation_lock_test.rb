require "test_helper"

class CanonicityMetricOperationLockTest < ActiveSupport::TestCase
  setup do
    @lock_path = Rails.root.join("tmp", "metric_operation_lock_test_#{SecureRandom.hex(4)}.lock")
  end

  teardown do
    File.delete(@lock_path) if File.exist?(@lock_path)
  end

  test "acquiring the lock reconciles interrupted datasets and runs" do
    capturing = MetricInputDataset.create!(
      subject_type: "Philosopher", status: "capturing", schema_version: "1.0",
      selected_entity_ids: [1], normalization_entity_ids: [1], normalization_context: {},
      source_provenance: {}, population_checksum: "capturing"
    )
    ready = MetricInputDataset.create!(
      subject_type: "Philosopher", status: "ready", schema_version: "1.0",
      selected_entity_ids: [1], normalization_entity_ids: [1], normalization_context: {},
      source_provenance: {}, population_checksum: "ready", capture_completed_at: Time.current
    )
    running = MetricRun.create!(
      subject_type: "Philosopher", version: "0.7.0", major: 0, minor: 7, patch: 0,
      metric_input_dataset: ready, calculator_identity: "philosopher-v2",
      configuration_version: "2.0", configuration_fingerprint: "checksum", status: "running",
      started_at: Time.current, weights_config: {}, signal_config: {}, source_provenance: {}
    )

    called = false
    Canonicity::MetricOperationLock.new(@lock_path).synchronize { called = true }

    assert called
    assert_equal "invalid", capturing.reload.status
    assert_equal "interrupted", capturing.failure_reason
    assert_equal "failed", running.reload.status
    assert_equal "interrupted", running.failure_reason
  end

  test "nested synchronization reuses the held lock" do
    require "timeout"
    called = false
    lock = Canonicity::MetricOperationLock.new(@lock_path)

    Timeout.timeout(2) do
      lock.synchronize do
        lock.synchronize { called = true }
      end
    end

    assert called
  end
end

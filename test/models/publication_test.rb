require "test_helper"

class PublicationTest < ActiveSupport::TestCase
  setup do
    @dataset = MetricInputDataset.create!(
      subject_type: "Philosopher", status: "ready", schema_version: "1.0",
      selected_entity_ids: [1], normalization_entity_ids: [1],
      normalization_context: {}, source_provenance: {}, population_checksum: "checksum",
      capture_completed_at: Time.current
    )
    @run = create_run("0.7.0", 0)
  end

  def create_run(version, patch)
    MetricRun.create!(
      subject_type: "Philosopher", version: version, major: 0, minor: 7, patch: patch,
      metric_input_dataset: @dataset, calculator_identity: "philosopher-v2",
      configuration_version: "2.0", configuration_fingerprint: "checksum-#{version}",
      status: "completed", started_at: Time.current, completed_at: Time.current,
      weights_config: {}, signal_config: {}, source_provenance: {}
    )
  end

  test "publications are append only" do
    publication = Publication.create!(metric_run: @run, subject_type: "Philosopher")

    assert_raises(ActiveRecord::ReadOnlyRecord) { publication.update!(subject_type: "Work") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { publication.destroy }
  end

  test "latest publication id identifies current including republication" do
    other_run = create_run("0.7.1", 1)
    first = Publication.create!(metric_run: @run, subject_type: "Philosopher")
    Publication.create!(metric_run: other_run, subject_type: "Philosopher")
    republished = Publication.create!(metric_run: @run, subject_type: "Philosopher")

    assert_equal republished, Publication.current_for("Philosopher")
    assert_equal 3, Publication.where(subject_type: "Philosopher").count
    assert_operator republished.id, :>, first.id
  end
end

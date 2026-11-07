require "test_helper"

class MetricInputDatasetTest < ActiveSupport::TestCase
  def attributes(overrides = {})
    {
      subject_type: "Philosopher",
      status: "capturing",
      schema_version: "1.0",
      selected_entity_ids: [1, 2],
      normalization_entity_ids: [2, 3],
      normalization_context: {"max_mention" => 2, "min_rank" => nil},
      source_provenance: {"danker" => {"checksum" => "abc"}},
      population_checksum: "population-checksum"
    }.merge(overrides)
  end

  test "serialized dataset fields preserve primitive values" do
    dataset = MetricInputDataset.create!(attributes)

    dataset.reload
    assert_equal [1, 2], dataset.selected_entity_ids
    assert_equal [2, 3], dataset.normalization_entity_ids
    assert_nil dataset.normalization_context["min_rank"]
    assert_equal 2, dataset.normalization_context["max_mention"]
    assert_equal "abc", dataset.source_provenance.dig("danker", "checksum")
  end

  test "ready status requires completed capture" do
    dataset = MetricInputDataset.new(attributes(status: "ready"))

    assert_not dataset.valid?
    assert dataset.errors[:capture_completed_at].any?
    assert MetricInputDataset.new(attributes(status: "ready", capture_completed_at: Time.current)).valid?
  end

  test "ready datasets are immutable" do
    dataset = MetricInputDataset.create!(attributes(status: "ready", capture_completed_at: Time.current))

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      dataset.update!(population_checksum: "changed")
    end
  end
end

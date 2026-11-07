require "test_helper"

class MetricInputRecordTest < ActiveSupport::TestCase
  setup do
    @dataset = MetricInputDataset.create!(
      subject_type: "Philosopher", status: "capturing", schema_version: "1.0",
      selected_entity_ids: [1], normalization_entity_ids: [1],
      normalization_context: {}, source_provenance: {}, population_checksum: "checksum"
    )
  end

  def attributes(overrides = {})
    {
      metric_input_dataset: @dataset,
      shadow_id: 1,
      shadow_type: "Philosopher",
      entity_id: 42,
      entity_label: "Test Philosopher",
      selected: true,
      normalization: true,
      input_payload: {
        "mention" => nil,
        "danker" => 0.0,
        "stanford" => true,
        "runes" => false,
        "capacity_ids" => [413, 41_217],
        "genre" => nil
      }
    }.merge(overrides)
  end

  test "input payload preserves nulls zeroes booleans and integer ids" do
    record = MetricInputRecord.create!(attributes)

    payload = record.reload.input_payload
    assert_nil payload["mention"]
    assert_equal 0.0, payload["danker"]
    assert_equal true, payload["stanford"]
    assert_equal false, payload["runes"]
    assert_equal [413, 41_217], payload["capacity_ids"]
    assert_nil payload["genre"]
  end

  test "record belongs to selected or normalization population" do
    record = MetricInputRecord.new(attributes(selected: false, normalization: false))

    assert_not record.valid?
    assert record.errors[:base].any?
  end

  test "shadow is unique within a dataset" do
    MetricInputRecord.create!(attributes)
    duplicate = MetricInputRecord.new(attributes(entity_id: 99))

    assert_not duplicate.valid?
    assert duplicate.errors[:shadow_id].any?
  end

  test "input record cannot move to another dataset" do
    record = MetricInputRecord.create!(attributes)
    other_dataset = MetricInputDataset.create!(
      subject_type: "Philosopher", status: "capturing", schema_version: "1.0",
      selected_entity_ids: [2], normalization_entity_ids: [2],
      normalization_context: {}, source_provenance: {}, population_checksum: "other-checksum"
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      record.update!(metric_input_dataset: other_dataset)
    end
  end
end

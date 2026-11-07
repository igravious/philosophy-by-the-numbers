require "test_helper"

class SourceEventTest < ActiveSupport::TestCase
  test "preserves old and new value types and import provenance" do
    event = SourceEvent.create!(
      source_name: "danker",
      import_identity: "import-2026-11-06",
      artifact_identity: "danker_2026-11-06.tsv",
      artifact_checksum: "abc123",
      shadow_id: 1,
      shadow_type: "Philosopher",
      entity_id: 42,
      attribute_name: "danker",
      old_value: nil,
      new_value: 0.0,
      provenance: {"retry" => false, "row" => 7},
      imported_at: Time.current
    )

    event.reload
    assert_nil event.old_value
    assert_equal 0.0, event.new_value
    assert_equal false, event.provenance["retry"]
    assert_equal 7, event.provenance["row"]
  end

  test "requires artifact and import identities" do
    event = SourceEvent.new(source_name: "danker", attribute_name: "danker", imported_at: Time.current)

    assert_not event.valid?
    assert event.errors[:import_identity].any?
    assert event.errors[:artifact_identity].any?
    assert event.errors[:artifact_checksum].any?
  end
end

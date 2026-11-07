require "test_helper"

class CanonicitySignalTest < ActiveSupport::TestCase
  test "stores descriptive signal metadata" do
    signal = CanonicitySignal.create!(
      algorithm_version: "2.0",
      name: "danker",
      description: "Time-varying PageRank input",
      source: "Wikipedia",
      subject_to_change: true,
      used_in_formula: true,
      active: true
    )

    assert signal.reload.subject_to_change?
    assert signal.used_in_formula?
    assert_equal "Wikipedia", signal.source
  end

  test "signal name is unique within an algorithm version" do
    attributes = {algorithm_version: "2.0", name: "danker", source: "Wikipedia"}
    CanonicitySignal.create!(attributes)
    duplicate = CanonicitySignal.new(attributes)

    assert_not duplicate.valid?
    assert duplicate.errors[:name].any?
  end
end

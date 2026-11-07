require 'test_helper'

class UnitTest < ActiveSupport::TestCase
  test "unit can be read from fixtures" do
    unit = units(:one)
    assert_not_nil unit
  end

  test "unit belongs to dictionary" do
    unit = units(:one)
    assert_respond_to unit, :dictionary
    assert_not_nil unit.dictionary
  end

  test "unit defines SYMBOL constant" do
    assert_kind_of Array, Unit::SYMBOL
  end

  test "unit search returns entry when no comma" do
    unit = Unit.new(entry: "philosophy")
    assert_equal "philosophy", unit.search
  end

  test "unit search reverses comma-separated entry" do
    unit = Unit.new(entry: "Kant, Immanuel")
    assert_equal "Immanuel Kant", unit.search
  end

  test "unit set_display_name sets display_name from entry" do
    unit = Unit.new(dictionary_id: dictionaries(:one).id, entry: "philosophy")
    unit.set_display_name
    assert_equal "philosophy", unit.display_name
  end

  test "unit set_display_name truncates long entry" do
    long_entry = "A very long dictionary entry that exceeds the default truncation limit of forty-two characters"
    unit = Unit.new(dictionary_id: dictionaries(:one).id, entry: long_entry)
    unit.set_display_name
    assert unit.display_name.length < long_entry.length, "display_name should be truncated"
    assert unit.display_name.end_with?('…'), "truncated display_name should end with ellipsis"
  end

  test "unit can be created" do
    unit = Unit.new(dictionary_id: dictionaries(:one).id, entry: "test_entry")
    assert unit.save
  end

  test "unit can be destroyed" do
    unit = units(:two)
    assert_difference 'Unit.count', -1 do
      unit.destroy
    end
  end
end

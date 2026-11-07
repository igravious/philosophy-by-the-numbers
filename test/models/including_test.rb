require 'test_helper'

class IncludingTest < ActiveSupport::TestCase
  test "including can be read from fixtures" do
    including = includings(:one)
    assert_not_nil including
  end

  test "including belongs to text" do
    including = includings(:one)
    assert_respond_to including, :text
    assert_not_nil including.text
  end

  test "including belongs to filter" do
    including = includings(:one)
    assert_respond_to including, :filter
    assert_not_nil including.filter
  end

  test "including can be created with unique filter-text pair" do
    filter = Filter.create!(name: "Unique Filter")
    text = Text.create!(name: "Unique Text", name_in_english: "Unique Text")
    including = Including.new(filter_id: filter.id, text_id: text.id)
    assert including.save
  end

  test "including can be destroyed" do
    including = includings(:two)
    assert_difference 'Including.count', -1 do
      including.destroy
    end
  end
end

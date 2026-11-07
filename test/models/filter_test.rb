require 'test_helper'

class FilterTest < ActiveSupport::TestCase
  test "filter can be read from fixtures" do
    filter = filters(:one)
    assert_not_nil filter
  end

  test "filter has many includings" do
    filter = filters(:one)
    assert_respond_to filter, :includings
  end

  test "filter accepts nested attributes for includings" do
    filter = Filter.new(name: "Test Filter")
    assert_respond_to filter, :includings_attributes=
  end

  test "filter can be created" do
    filter = Filter.new(name: "New Filter", name_in_english: "New Filter")
    assert filter.save
  end

  test "filter can be destroyed" do
    filter = filters(:two)
    assert_difference 'Filter.count', -1 do
      filter.destroy
    end
  end
end

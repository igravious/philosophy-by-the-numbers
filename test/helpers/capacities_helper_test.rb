require 'test_helper'

class CapacitiesHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "c_extra returns hash with label, dynamic_count, and only_relevant" do
    @label = 'test_label'
    @dynamic_count = 42
    @only_relevant = 'checked'

    result = c_extra
    assert_equal 'test_label', result[:label]
    assert_equal 42, result[:dynamic_count]
    assert_equal 'on', result[:only_relevant]
  end

  test "c_extra returns off when only_relevant is not checked" do
    @label = nil
    @dynamic_count = nil
    @only_relevant = nil

    result = c_extra
    assert_nil result[:label]
    assert_nil result[:dynamic_count]
    assert_equal 'off', result[:only_relevant]
  end
end

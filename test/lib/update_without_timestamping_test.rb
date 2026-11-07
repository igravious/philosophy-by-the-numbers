require 'test_helper'
require 'update_without_timestamping'

class UpdateWithoutTimestampingTest < ActiveSupport::TestCase
  test "method is available on model instances" do
    phil = create_test_philosopher
    assert_respond_to phil, :update_record_without_timestamping
  end

  test "saves record without updating timestamps" do
    phil = create_test_philosopher
    original_updated_at = phil.updated_at
    phil.mention = 999
    phil.update_record_without_timestamping
    phil.reload
    assert_equal 999, phil.mention
    assert_equal original_updated_at.to_i, phil.updated_at.to_i
  end

  test "normal save updates timestamps" do
    phil = create_test_philosopher
    phil.mention = 888
    phil.save!
    phil.reload
    assert_equal 888, phil.mention
  end
end

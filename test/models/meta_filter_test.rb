require 'test_helper'

class MetaFilterTest < ActiveSupport::TestCase
  test "meta filter can be read from fixtures" do
    meta_filter = meta_filters(:one)
    assert_not_nil meta_filter
  end

  test "meta filter has many meta_filter_pairs" do
    meta_filter = meta_filters(:one)
    assert_respond_to meta_filter, :meta_filter_pairs
  end

  test "meta filter restricts destruction when pairs exist" do
    meta_filter = meta_filters(:one)
    assert meta_filter.meta_filter_pairs.count > 0
    assert_no_difference 'MetaFilter.count' do
      meta_filter.destroy
    end
  end

  test "meta filter can be created with STI type" do
    meta_filter = MainMetaFilter.new(filter: "unique_main_filter_#{Time.now.to_i}")
    assert meta_filter.save
  end

  test "meta filter without pairs can be destroyed" do
    meta_filter = MainMetaFilter.create!(filter: "temporary")
    assert_difference 'MetaFilter.count', -1 do
      meta_filter.destroy
    end
  end

  test "question meta filter is a subclass" do
    meta_filter = QuestionMetaFilter.new(filter: "question_filter")
    assert meta_filter.save
    assert_equal "QuestionMetaFilter", meta_filter.type
  end
end

require 'test_helper'

class MetaFilterPairTest < ActiveSupport::TestCase
  test "meta filter pair can be read from fixtures" do
    pair = meta_filter_pairs(:one)
    assert_not_nil pair
  end

  test "meta filter pair belongs to meta_filter" do
    pair = meta_filter_pairs(:one)
    assert_respond_to pair, :meta_filter
    assert_not_nil pair.meta_filter
  end

  test "meta filter pair serialises value with Marshal and Base64" do
    mf = MainMetaFilter.create!(filter: "serialize_test")
    pair = MetaFilterPair.new(meta_filter_id: mf.id, key: "test_key")
    pair.value = { foo: "bar", baz: 42 }
    assert pair.save

    reloaded = MetaFilterPair.find(pair.id)
    assert_equal({ foo: "bar", baz: 42 }, reloaded.value)
  end

  test "meta filter pair serialises array values" do
    mf = MainMetaFilter.create!(filter: "array_test")
    pair = MetaFilterPair.new(meta_filter_id: mf.id, key: "array_key")
    pair.value = [1, 2, 3]
    assert pair.save

    reloaded = MetaFilterPair.find(pair.id)
    assert_equal [1, 2, 3], reloaded.value
  end

  test "meta filter pair serialises string values" do
    mf = MainMetaFilter.create!(filter: "string_test")
    pair = MetaFilterPair.new(meta_filter_id: mf.id, key: "string_key")
    pair.value = "simple string"
    assert pair.save

    reloaded = MetaFilterPair.find(pair.id)
    assert_equal "simple string", reloaded.value
  end

  test "meta filter pair can be destroyed" do
    pair = meta_filter_pairs(:two)
    assert_difference 'MetaFilterPair.count', -1 do
      pair.destroy
    end
  end
end

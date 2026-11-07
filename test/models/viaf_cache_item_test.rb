require 'test_helper'

class ViafCacheItemTest < ActiveSupport::TestCase
  test "viaf cache item can be created with attributes" do
    item = ViafCacheItem.new(personal: "Plato", uniform_title_work: "Republic", q: "Q859", url: "https://viaf.org/viaf/108159964")
    assert item.save
  end

  test "viaf cache item persists all attributes" do
    ViafCacheItem.create!(personal: "Aristotle", uniform_title_work: "Metaphysics", q: "Q868", url: "https://viaf.org/viaf/7524651")
    found = ViafCacheItem.find_by(personal: "Aristotle", uniform_title_work: "Metaphysics")
    assert_not_nil found
    assert_equal "Q868", found.q
    assert_equal "https://viaf.org/viaf/7524651", found.url
  end

  test "viaf cache item enforces unique personal-work pair" do
    ViafCacheItem.create!(personal: "Kant", uniform_title_work: "Critique", q: "Q9312", url: "https://viaf.org/test")
    assert_raises(ActiveRecord::RecordNotUnique) do
      ViafCacheItem.create!(personal: "Kant", uniform_title_work: "Critique", q: "Q9312b", url: "https://viaf.org/test2")
    end
  end
end

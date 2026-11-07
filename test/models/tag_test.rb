require 'test_helper'

class TagTest < ActiveSupport::TestCase
  test "tag can be read from fixtures" do
    tag = tags(:one)
    assert_not_nil tag
    assert_equal "Test Tag", tag.name
  end

  test "tag has many labelings" do
    tag = tags(:one)
    assert_respond_to tag, :labelings
  end

  test "tag has many texts through labelings" do
    tag = tags(:one)
    assert_respond_to tag, :texts
  end

  test "tag can be created with a name" do
    tag = Tag.new(name: "Epistemology")
    assert tag.save
    assert_equal "Epistemology", tag.reload.name
  end

  test "tag can be destroyed" do
    tag = tags(:two)
    assert_difference 'Tag.count', -1 do
      tag.destroy
    end
  end

  test "tag accepts nested attributes for labelings" do
    tag = Tag.new(name: "Metaphysics")
    assert_respond_to tag, :labelings_attributes=
  end

  test "tag rejects blank nested labelings" do
    tag = Tag.create!(name: "Ethics")
    tag.update(labelings_attributes: [{ text_id: nil, tag_id: nil }])
    assert_equal 0, tag.labelings.count
  end
end

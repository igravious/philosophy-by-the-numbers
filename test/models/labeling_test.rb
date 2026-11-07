require 'test_helper'

class LabelingTest < ActiveSupport::TestCase
  test "labeling can be read from fixtures" do
    labeling = labelings(:one)
    assert_not_nil labeling
  end

  test "labeling belongs to tag" do
    labeling = labelings(:one)
    assert_respond_to labeling, :tag
    assert_not_nil labeling.tag
  end

  test "labeling belongs to text" do
    labeling = labelings(:one)
    assert_respond_to labeling, :text
    assert_not_nil labeling.text
  end

  test "labeling can be created" do
    labeling = Labeling.new(tag_id: tags(:two).id, text_id: texts(:two).id)
    assert labeling.save
  end

  test "labeling can be destroyed" do
    labeling = labelings(:two)
    assert_difference 'Labeling.count', -1 do
      labeling.destroy
    end
  end
end

require 'test_helper'

class TextTest < ActiveSupport::TestCase
  test "text can be read from fixtures" do
    text = texts(:one)
    assert_not_nil text
  end

  test "text has many writings" do
    text = texts(:one)
    assert_respond_to text, :writings
  end

  test "text has many authors through writings" do
    text = texts(:one)
    assert_respond_to text, :authors
  end

  test "text has many labelings" do
    text = texts(:one)
    assert_respond_to text, :labelings
  end

  test "text has many tags through labelings" do
    text = texts(:one)
    assert_respond_to text, :tags
  end

  test "text has many includings" do
    text = texts(:one)
    assert_respond_to text, :includings
  end

  test "text belongs to fyle" do
    text = texts(:one)
    assert_respond_to text, :fyle
  end

  test "text defines ORIGINAL_LANGUAGE constant" do
    assert_kind_of Array, Text::ORIGINAL_LANGUAGE
    assert Text::ORIGINAL_LANGUAGE.length > 0
    assert_equal "Ancient Greek", Text::ORIGINAL_LANGUAGE.first[0]
  end

  test "text defines INEQUALITY constant" do
    assert_equal [["<", 1], ["=", 2], [">", 3]], Text::INEQUALITY
  end

  test "text author_names returns comma-separated names" do
    text = texts(:one)
    names = text.author_names
    assert_kind_of String, names
  end

  test "text filename_suggestion generates filename" do
    text = texts(:one)
    suggestion = text.filename_suggestion
    assert_kind_of String, suggestion
    assert suggestion.length > 0
  end

  test "text tag_names returns comma-separated tag names" do
    text = texts(:one)
    names = text.tag_names
    assert_kind_of String, names
  end

  test "text column_direction returns asc for name_in_english" do
    assert_equal 'asc', Text.column_direction('name_in_english')
  end

  test "text column_direction returns desc for other columns" do
    assert_equal 'desc', Text.column_direction('original_year')
  end

  test "text accepts nested attributes for writings" do
    text = Text.new(name: "Test")
    assert_respond_to text, :writings_attributes=
  end

  test "text accepts nested attributes for labelings" do
    text = Text.new(name: "Test")
    assert_respond_to text, :labelings_attributes=
  end

  test "text can be created" do
    text = Text.new(name: "Republic", name_in_english: "Republic", original_year: -380)
    assert text.save
  end

  test "text can be destroyed" do
    text = Text.create!(name: "Temp Text", name_in_english: "Temp Text")
    assert_difference 'Text.count', -1 do
      text.destroy
    end
  end
end

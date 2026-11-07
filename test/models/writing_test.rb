require 'test_helper'

class WritingTest < ActiveSupport::TestCase
  test "writing can be read from fixtures" do
    writing = writings(:one)
    assert_not_nil writing
  end

  test "writing belongs to author" do
    writing = writings(:one)
    assert_respond_to writing, :author
    assert_equal authors(:one), writing.author
  end

  test "writing belongs to text" do
    writing = writings(:one)
    assert_respond_to writing, :text
    assert_equal texts(:one), writing.text
  end

  test "writing defines role constants" do
    assert_equal 1, Writing::AUTHOR
    assert_equal 2, Writing::TRANSLATOR
    assert_equal 3, Writing::EDITOR
  end

  test "writing ROLE lookup table contains all roles" do
    assert_equal [["Author", 1], ["Translator", 2], ["Editor", 3]], Writing::ROLE
  end

  test "writing can be created with unique author-text pair" do
    author = Author.create!(name: "New Author")
    text = Text.create!(name: "New Text", name_in_english: "New Text")
    writing = Writing.new(text_id: text.id, author_id: author.id, role: Writing::AUTHOR)
    assert writing.save
  end

  test "writing can be created as translator role" do
    author = Author.create!(name: "Translator Author")
    text = Text.create!(name: "Translated Text", name_in_english: "Translated Text")
    writing = Writing.new(text_id: text.id, author_id: author.id, role: Writing::TRANSLATOR)
    assert writing.save
  end

  test "writing can be destroyed" do
    writing = writings(:two)
    assert_difference 'Writing.count', -1 do
      writing.destroy
    end
  end
end

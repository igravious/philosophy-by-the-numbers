require 'test_helper'

class AuthorTest < ActiveSupport::TestCase
  test "author can be read from fixtures" do
    author = authors(:one)
    assert_not_nil author
  end

  test "author has many writings" do
    author = authors(:one)
    assert_respond_to author, :writings
    assert author.writings.count > 0
  end

  test "author has many texts through writings" do
    author = authors(:one)
    assert_respond_to author, :texts
    assert author.texts.count > 0
  end

  test "author accepts nested attributes for writings" do
    author = Author.new(name: "Test Author")
    assert_respond_to author, :writings_attributes=
  end

  test "author accepts nested attributes for texts" do
    author = Author.new(name: "Test Author")
    assert_respond_to author, :texts_attributes=
  end

  test "author can be created with basic attributes" do
    author = Author.new(name: "Immanuel Kant", english_name: "Immanuel Kant")
    assert author.save
  end

  test "author can be destroyed" do
    author = Author.create!(name: "Temporary Author")
    assert_difference 'Author.count', -1 do
      author.destroy
    end
  end
end

require 'test_helper'

class DictionaryTest < ActiveSupport::TestCase
  test "dictionary can be read from fixtures" do
    dictionary = dictionaries(:one)
    assert_not_nil dictionary
  end

  test "dictionary has many units" do
    dictionary = dictionaries(:one)
    assert_respond_to dictionary, :units
  end

  test "dictionary destroys dependent units" do
    dictionary = dictionaries(:one)
    unit_count = dictionary.units.count
    assert_difference 'Unit.count', -unit_count do
      dictionary.destroy
    end
  end

  test "domain extracts domain from URI" do
    dictionary = Dictionary.new(URI: "http://plato.stanford.edu/entries/")
    assert_equal "plato.stanford.edu", dictionary.domain
  end

  test "content_title returns title when content_uri is nil" do
    dictionary = Dictionary.new(title: "Philosophy Dictionary", content_uri: nil)
    assert_equal "Philosophy Dictionary", dictionary.content_title
  end

  test "content_title links Philosophy when content_uri present" do
    dictionary = Dictionary.new(title: "Philosophy Dictionary", content_uri: "http://example.com")
    result = dictionary.content_title
    assert_includes result, '<a href="http://example.com">'
    assert_includes result, "Philosophy"
  end

  test "dictionary can be created" do
    dictionary = Dictionary.new(title: "Test Dict", URI: "http://example.com/dict")
    assert dictionary.save
  end
end

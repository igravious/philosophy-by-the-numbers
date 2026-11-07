require 'test_helper'
require 'truncate'

class TruncateTest < ActiveSupport::TestCase
  setup do
    @obj = Object.new
    @obj.extend(Truncatable)
  end

  test "returns short string unchanged" do
    assert_equal 'hello', @obj.truncate('hello')
  end

  test "truncates long string at word boundary" do
    long = 'a ' * 30
    result = @obj.truncate(long)
    assert result.length <= 45, "Expected truncated result, got #{result.length} chars"
    assert result.end_with?('…')
  end

  test "uses custom level" do
    s = 'the quick brown fox jumps over the lazy dog'
    result = @obj.truncate(s, 20)
    assert result.length <= 24
  end

  test "uses custom suffix" do
    s = 'the quick brown fox jumps over the lazy dog and more words'
    result = @obj.truncate(s, 20, '...')
    assert result.end_with?('...')
  end

  test "returns exact-length string unchanged" do
    s = 'x' * 42
    assert_equal s, @obj.truncate(s)
  end

  test "returns string at boundary unchanged" do
    s = 'a' * 42
    assert_equal s, @obj.truncate(s, 42)
  end
end

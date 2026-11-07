require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  # on_off
  test "on_off returns on for checked" do
    assert_equal 'on', on_off('checked')
  end

  test "on_off returns off for anything else" do
    assert_equal 'off', on_off('unchecked')
    assert_equal 'off', on_off(nil)
    assert_equal 'off', on_off('')
  end

  # symbol_or_blank
  test "symbol_or_blank returns first matching symbol" do
    h = {f: true, m: false}
    assert_equal 'f', symbol_or_blank(h, :f, :m)
  end

  test "symbol_or_blank returns second symbol if first missing" do
    h = {m: true}
    assert_equal 'm', symbol_or_blank(h, :f, :m)
  end

  test "symbol_or_blank returns empty string when no match" do
    h = {x: true}
    assert_equal '', symbol_or_blank(h, :f, :m)
  end

  test "symbol_or_blank returns empty string for empty hash" do
    assert_equal '', symbol_or_blank({}, :f, :m)
  end

  # title
  test "title sets content_for :title" do
    @view_flow = ActionView::OutputFlow.new
    title('Test Page')
    assert_equal 'Test Page', content_for(:title)
  end

  test "title converts non-string to string" do
    @view_flow = ActionView::OutputFlow.new
    title(42)
    assert_equal '42', content_for(:title)
  end

  # truncate
  test "truncate returns label unchanged when short enough" do
    assert_equal 'hello', truncate('hello', 10)
  end

  test "truncate with word_break splits mid-word" do
    result = truncate('the quick brown fox jumps', 10)
    assert result.end_with?('…'), "Expected ellipsis, got: #{result}"
    assert result.length < 'the quick brown fox jumps'.length
  end

  test "truncate without word_break adds spaced ellipsis" do
    result = truncate('the quick brown fox jumps', 10, false)
    assert result.end_with?(' …'), "Expected ' …', got: #{result}"
  end

  test "truncate handles exact-length string" do
    assert_equal 'hello', truncate('hello', 5)
  end

  test "truncate handles single long word with word_break" do
    result = truncate('supercalifragilistic expialidocious', 20)
    assert result.include?('…')
  end
end

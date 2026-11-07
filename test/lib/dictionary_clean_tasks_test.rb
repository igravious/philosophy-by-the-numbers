require "test_helper"
require "minitest/mock"
require "rake"
require_relative "../support/rake_task_testing"
require "tmpdir"
require "stringio"
require "knowledge"

class DictionaryCleanTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting
  Input = Class.new(StringIO) do
    attr_accessor :filename

    def skip
      self
    end
  end

  setup do
    @directory = Dir.mktmpdir("dictionary-clean-")
    use_rake_tasks(Rails.root.join("lib/tasks/dict_clean.rake"))
    @receiver = Rake::Task["dictionary:clean:grok"].actions.first.binding.receiver
    @wrapper = @receiver.singleton_class.ancestors.find { |ancestor| ancestor.const_defined?(:URL_SEP, false) }
  end

  teardown do
    restore_rake_tasks
    FileUtils.remove_entry(@directory)
  end

  test "proper name cleanup reorders capitalized names and preserves ordinary terms" do
    output = run_clean("proper", "John Smith\nordinary term\nPlato\n")
    assert_includes output, "Smith, John | John Smith"
    assert_includes output, "ordinary term"
    assert_includes output, "Plato"
  end

  test "bracket parenthesis and variant cleanup preserve original source spellings" do
    assert_includes run_clean("brackets", "αδιαφορα [adiaphora]\nOrdinary\n"), "adiaphora | αδιαφορα [adiaphora]"
    assert_includes run_clean("parens", "Absorption (Abs.)\nPlain\n"), "Absorption | Absorption (Abs.)"
    assert_equal "adiaphora\nPlain\n", run_clean("strip", "adiaphora | αδιαφορα [adiaphora]\nPlain\n")
    output = run_clean("remove_slash", "continence / incontinence\nfirst / second | Original\nPlain\n")
    assert_includes output, "continence | continence / incontinence"
    assert_includes output, "first | Original"
    assert_includes output, "Plain"
  end

  test "slash alignment inserts spaces around a joined variant separator" do
    assert_equal "continence / incontinence\nPlain\n", run_clean("align_slash", "continence/incontinence\nPlain\n")
  end

  test "format inspection distinguishes dated figures common terms names and uncertain entries" do
    verify = ->(entry) do
      case entry
      when "ordinary" then [[], nil]
      when "Common" then [["common"], 1]
      when "Plato" then [["Plato"], 0]
      else [["Unknown", "Term"], 1]
      end
    end
    input = "Socrates (470–399) = https://example.test/socrates\nordinary = https://example.test/term\nCommon = url\nPlato = url\nUnknown Term = url\n"
    Knowledge::Format.stub(:verify, verify) do
      output = run_clean("grok", input)
      assert_includes output, "@ Socrates (470–399)"
      assert_includes output, "not initially uppercase"
      assert_includes output, "uppercase, but ordinary term"
      assert_includes output, "possible name"
      assert_includes output, "unsure"
    end
  end

  test "format inspection exits unsuccessfully on malformed index entries" do
    assert_equal 1, assert_raises(SystemExit) { run_clean("grok", "malformed entry\n") }.status
  end

  test "an unreadable command-line filename is reported without breaking input setup" do
    input = Object.new
    input.define_singleton_method(:filename) { raise IOError, "Cannot inspect input filename" }
    @wrapper.send(:remove_const, :ARGF) if @wrapper.const_defined?(:ARGF, false)
    @wrapper.const_set(:ARGF, input)
    output = capture_subprocess_io { @receiver.send(:argf_file) }.last
    assert_includes output, "Cannot inspect input filename"
  end

  private

  def run_clean(name, contents)
    path = File.join(@directory, "input.txt")
    File.write(path, contents)
    input = Input.new(contents)
    input.filename = path
    @wrapper.send(:remove_const, :ARGF) if @wrapper.const_defined?(:ARGF, false)
    @wrapper.const_set(:ARGF, input)
    task = Rake::Task["dictionary:clean:#{name}"]
    task.reenable
    capture_io { task.invoke }.first
  end
end

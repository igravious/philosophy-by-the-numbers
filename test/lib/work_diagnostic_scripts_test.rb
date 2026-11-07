require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../support/loaded_helpers"
require_relative "../support/script_runner"

class WorkDiagnosticScriptsTest < ActiveSupport::TestCase
  include LoadedHelpers
  include ScriptRunner

  setup do
    @directory = Dir.mktmpdir("work-diagnostic-")
    @helper = load_helpers("scripts/test_work_based_delta.rb")
    @figure = create_test_philosopher
    @figure.names.create!(lang: "en", label: "Diagnostic Author")
    @author = Author.create!(name: "Diagnostic Author", english_name: "Diagnostic Author")
    @path = File.join(@directory, "text.txt")
    File.write(@path, "Philosophical text")
    @file = Fyle.create!(what: "Diagnostic Text", local_file: @path)
    text = Text.create!(name: "Diagnostic Text", fyle: @file)
    Writing.create!(text: text, author: @author, role: Writing::AUTHOR)
    @works = 2.times.map do |index|
      work = create_test_work(measure: 9.0 - index, linkcount: 10 + index, obsolete: false)
      work.names.create!(lang: "en", label: "Diagnostic Work #{index}")
      work.creators << @figure
      work
    end
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "work diagnostics query actual associations and exercise every selection strategy" do
    output = nil
    with_output_directories { output = diagnostic_output }
    assert_includes output, "Works with text files: 2"
    %w[Linkcount Canonicity Mixed].each { |name| assert_includes output, "#{name} strategy test completed" }
    assert_includes output, "Diagnostic Work 0"
    assert_includes output, @path
  end

  test "diagnostics reject a population without file references and skip insufficient samples" do
    @file.update!(local_file: nil)
    capture_io { assert_equal 1, assert_raises(SystemExit) { @helper.main }.status }
    @file.update!(local_file: @path)
    Expression.where(work_id: @works.last.id).delete_all
    with_output_directories do
      assert_includes diagnostic_output, "Only 1 works with files"
    end
  end

  test "one failed strategy is reported without preventing other strategy checks" do
    with_output_directories do
      WorkBasedDeltaProcessor.stub(:by_linkcount, ->(**_) { raise IOError, "Selection failed" }) do
        output = diagnostic_output
        assert_includes output, "Error testing linkcount strategy: Selection failed"
        assert_includes output, "Canonicity strategy test completed"
      end
    end
  end

  test "database failures produce a nonzero diagnostic exit" do
    Work.stub(:count, -> { raise IOError, "Database unavailable" }) do
      output = capture_io { assert_equal 1, assert_raises(SystemExit) { @helper.main }.status }.first
      assert_includes output, "Database unavailable"
    end
  end

  test "unexpected cleanup errors produce a nonzero diagnostic exit" do
    FileUtils.mkdir_p(File.join(@directory, "delta_test_linkcount"))
    with_output_directories do
      FileUtils.stub(:rm_rf, ->(*) { raise IOError, "Cleanup unavailable" }) do
        output = capture_io { assert_equal 1, assert_raises(SystemExit) { @helper.main }.status }.first
        assert_includes output, "Unexpected error: Cleanup unavailable"
      end
    end
  end

  test "relationship debugging reports present missing and absent files and unmatched creators" do
    Text.create!(name: "No file").writings.create!(author: @author, role: Writing::AUTHOR)
    missing = Fyle.create!(what: "Missing Text", local_file: File.join(@directory, "missing.txt"))
    Text.create!(name: "Missing Text", fyle: missing).writings.create!(author: @author, role: Writing::AUTHOR)
    unmatched = create_test_philosopher
    unmatched.names.create!(lang: "en", label: "Unmatched Creator")
    @works.last.creators = [unmatched]
    output = capture_io { load_script(Rails.root.join("scripts/debug_work_files.rb")) }.first
    assert_includes output, "EXISTS"
    assert_includes output, "MISSING"
    assert_includes output, "No Fyle attached"
    assert_includes output, "No Author records found for 'Unmatched Creator'"
    assert_includes output, "SUMMARY STATISTICS"
  end

  private

  def diagnostic_output
    capture_io { @helper.main }.first
  rescue SystemExit => error
    flunk "Work diagnostics unexpectedly exited with status #{error.status}"
  end

  def with_output_directories(&block)
    original = File.method(:join)
    script_directory = Rails.root.join("scripts").to_s
    join = ->(*parts) do
      if parts.first == script_directory && parts.last.to_s.start_with?("delta_test_")
        original.call(@directory, parts.last)
      else
        original.call(*parts)
      end
    end
    File.stub(:join, join, &block)
  end
end

require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../support/loaded_helpers"

class DeltaDiagnosticScriptsTest < ActiveSupport::TestCase
  include LoadedHelpers

  setup do
    @directory = Dir.mktmpdir("delta-diagnostic-")
    @helper = load_helpers("scripts/test_delta_workflow.rb")
    @requested_directories = []
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "quick test creates progressive texts inside the project and reports the processor output" do
    FileUtils.mkdir_p(File.join(@directory, "output"))
    File.write(File.join(@directory, "output/old.txt"), "old output")
    settings = nil
    processor = Object.new
    processor.define_singleton_method(:delta_of_deltas_history) { [{magnitude: 0.02}] }
    processor.define_singleton_method(:process) do
      FileUtils.mkdir_p(settings[:output_dir])
      File.write(File.join(settings[:output_dir], "report.json"), "{}")
      {summary: {total_works_processed: 3, total_iterations: 2, convergence_reached: true}}
    end
    output = nil
    with_diagnostic_directory do
      with_saffron_available do
        DeltaOfDeltaProcessor.stub(:new, ->(**options) {
                                           settings = options
                                           processor
                                         }) do
          output = capture_io { @helper.main }.first
        end
      end
    end
    assert_equal [Rails.root.join("tmp/delta_test").to_s], @requested_directories
    assert_equal 3, settings[:works].size
    sizes = settings[:works].map { |path| File.size(path) }
    assert sizes.each_cons(2).all? { |first, last| first < last }
    assert_equal 0.05, settings[:threshold]
    assert_equal :composite, settings[:diff_strategy]
    assert_includes output, "workflow test completed successfully"
    assert_includes output, "report.json"
    refute File.exist?(File.join(@directory, "output/old.txt"))
  end

  test "quick test rejects a missing Saffron installation before creating any outputs" do
    original = File.method(:exist?)
    File.stub(:exist?, ->(path) { (path == DeltaOfDeltaProcessor::SAFFRON_SCRIPT) ? false : original.call(path) }) do
      capture_io { assert_equal 1, assert_raises(SystemExit) { @helper.main }.status }
    end
    assert_empty Dir.children(@directory)
  end

  test "quick test reports processor failures and exits unsuccessfully" do
    processor = Object.new
    processor.define_singleton_method(:process) { raise IOError, "Analysis unavailable" }
    with_diagnostic_directory do
      with_saffron_available do
        DeltaOfDeltaProcessor.stub(:new, processor) do
          output = capture_io { assert_equal 1, assert_raises(SystemExit) { @helper.main }.status }.first
          assert_includes output, "Analysis unavailable"
        end
      end
    end
  end

  private

  def with_saffron_available(&block)
    original = File.method(:exist?)
    File.stub(:exist?, ->(path) { (path == DeltaOfDeltaProcessor::SAFFRON_SCRIPT) ? true : original.call(path) }, &block)
  end

  def with_diagnostic_directory(&block)
    original = File.method(:join)
    script_directory = Rails.root.join("scripts").to_s
    join = ->(*parts) do
      if parts.first == script_directory && parts.include?("delta_test")
        @requested_directories << File.expand_path(original.call(*parts))
        @directory
      else
        original.call(*parts)
      end
    end
    File.stub(:join, join, &block)
  end
end

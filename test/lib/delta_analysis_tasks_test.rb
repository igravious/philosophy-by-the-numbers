require "test_helper"
require "minitest/mock"
require "rake"
require_relative "../support/rake_task_testing"
require "tmpdir"
require_relative "../../lib/delta_analysis/work_based_delta_processor"

class DeltaAnalysisTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting
  setup do
    @directory = Dir.mktmpdir("delta-tasks-")
    use_rake_tasks(Rails.root.join("lib/tasks/delta_analysis.rake"))
    @original_root = Rails.root
  end

  teardown do
    restore_rake_tasks
    FileUtils.remove_entry(@directory)
  end

  test "example generation creates distinct growing texts and lists their actual sizes" do
    Rails.stub(:root, Pathname.new(@directory)) do
      run_task("create_test_works")
      files = Dir.glob(File.join(@directory, "tmp/test_works/*.txt")).sort
      assert_equal 3, files.size
      assert files.each_cons(2).all? { |first, last| File.size(first) < File.size(last) }
      output = run_task("list_works", "tmp/test_works/*.txt")
      assert_includes output, "Total: 3 works"
      files.each { |path| assert_includes output, "#{path} (#{File.size(path)} bytes)" }
    end
  end

  test "file based processing passes sorted inputs and typed options to the processor" do
    directory = File.join(@directory, "_txt")
    FileUtils.mkdir_p(directory)
    6.times { |index| File.write(File.join(directory, "work_#{index}.txt"), "text") }
    arguments = nil
    processor = Minitest::Mock.new
    processor.expect(:process, {})
    Rails.stub(:root, Pathname.new(@directory)) do
      DeltaOfDeltaProcessor.stub(:new, ->(**options) {
                                         arguments = options
                                         processor
                                       }) do
        assert_includes run_task("process", "_txt/*.txt", @directory, "0.05", "term_weight"), "and 1 more"
      end
    end
    assert_equal Dir.glob(File.join(directory, "*.txt")).sort, arguments[:works]
    assert_equal 0.05, arguments[:threshold]
    assert_equal :term_weight, arguments[:diff_strategy]
    processor.verify
  end

  test "file processing rejects empty selections and reports execution errors" do
    Rails.stub(:root, Pathname.new(@directory)) do
      assert_equal 1, assert_raises(SystemExit) { run_task("process") }.status
      FileUtils.mkdir_p(File.join(@directory, "_txt"))
      File.write(File.join(@directory, "_txt/work.txt"), "text")
      processor = Object.new
      processor.define_singleton_method(:process) { raise IOError, "Saffron unavailable" }
      DeltaOfDeltaProcessor.stub(:new, processor) do
        assert_equal 1, assert_raises(SystemExit) { run_task("process") }.status
      end
    end
  end

  test "Saffron installation check distinguishes missing successful and failed execution" do
    task = Rake::Task["delta_analysis:test_saffron"]
    receiver = task.actions.first.binding.receiver
    original_exist = File.method(:exist?)
    [false, true].each do |installed|
      File.stub(:exist?, ->(path) { (path == DeltaOfDeltaProcessor::SAFFRON_SCRIPT) ? installed : original_exist.call(path) }) do
        if installed
          [true, false].each do |success|
            receiver.stub(:system, success) do
              output = run_task("test_saffron")
              assert_includes output, success ? "appears to be working" : "test failed"
            end
          end
        else
          assert_includes run_task("test_saffron"), "script not found"
        end
      end
    end
  end

  test "work processing and the canonical shortcut preserve arguments" do
    settings = []
    processor = Minitest::Mock.new
    2.times { processor.expect(:process, {}) }
    WorkBasedDeltaProcessor.stub(:new, ->(**options) {
                                         settings << options
                                         processor
                                       }) do
      run_task("process_works", "linkcount", @directory, "0.02", "semantic", "5", "3.5")
      Rake::Task["delta_analysis:process_works"].reenable
      run_task("process_canonical_works", "7", "4.5")
    end
    assert_equal({work_selection_strategy: :linkcount, max_works: 5, min_canonicity: 3.5,
      output_dir: @directory, threshold: 0.02, diff_strategy: :semantic}, settings.first)
    assert_equal :canonicity, settings.last[:work_selection_strategy]
    assert_equal 7, settings.last[:max_works]
    assert_equal 4.5, settings.last[:min_canonicity]
    processor.verify
  end

  test "work processing reports execution failures" do
    processor = Object.new
    processor.define_singleton_method(:process) { raise IOError, "Saffron unavailable" }
    WorkBasedDeltaProcessor.stub(:new, processor) do
      assert_equal 1, assert_raises(SystemExit) { run_task("process_works") }.status
    end
  end

  test "available work listing uses delegated obsolete flags and rejects unknown strategies" do
    work = create_test_work(measure: 4.0, obsolete: false)
    work.names.create!(lang: "en", label: "Visible Work")
    obsolete = create_test_work(measure: 10.0, obsolete: true)
    obsolete.names.create!(lang: "en", label: "Obsolete Work")

    %w[canonicity linkcount].each do |strategy|
      output = run_task("show_available_works", strategy, "100")
      assert_includes output, "Visible Work"
      refute_includes output, "Obsolete Work"
      assert_includes output, "No text file found"
    end
    assert_equal 1, assert_raises(SystemExit) { run_task("show_available_works", "unknown") }.status
  end

  private

  def run_task(name, *arguments)
    task = Rake::Task["delta_analysis:#{name}"]
    task.reenable
    capture_io { task.invoke(*arguments) }.first
  end
end

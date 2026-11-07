# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require_relative "../../../lib/corpus_cli/state_tracker"

class StateTrackerTest < ActiveSupport::TestCase
  def setup
    @tmpdir = Dir.mktmpdir
    @log_path = File.join(@tmpdir, "test_workflow.log")
    @tracker = CorpusCli::StateTracker.new(@log_path)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  test "records start events" do
    @tracker.record_start("my_wf", "step_1")
    events = @tracker.history
    assert_equal 1, events.size
    assert_equal "step_start", events.first["event"]
    assert_equal "my_wf", events.first["workflow"]
    assert_equal "step_1", events.first["step"]
  end

  test "records finish events" do
    @tracker.record_finish("my_wf", "step_1", success: true, duration: 5.2)
    events = @tracker.history
    assert_equal 1, events.size
    assert_equal "step_finish", events.first["event"]
    assert_equal true, events.first["success"]
    assert_equal 5.2, events.first["duration_seconds"]
  end

  test "completed_steps returns set of successful step ids" do
    @tracker.record_finish("my_wf", "step_1", success: true)
    @tracker.record_finish("my_wf", "step_2", success: false)
    @tracker.record_finish("my_wf", "step_3", success: true)

    completed = @tracker.completed_steps("my_wf")
    assert_includes completed, "step_1"
    refute_includes completed, "step_2"
    assert_includes completed, "step_3"
  end

  test "completed_steps scoped to workflow" do
    @tracker.record_finish("wf_a", "step_1", success: true)
    @tracker.record_finish("wf_b", "step_1", success: true)

    completed_a = @tracker.completed_steps("wf_a")
    assert_includes completed_a, "step_1"

    completed_b = @tracker.completed_steps("wf_b")
    assert_includes completed_b, "step_1"
  end

  test "failed rerun invalidates a previous success" do
    @tracker.record_finish("my_wf", "step_1", success: true)
    @tracker.record_start("my_wf", "step_1")
    @tracker.record_finish("my_wf", "step_1", success: false)

    refute_includes @tracker.completed_steps("my_wf"), "step_1"
  end

  test "interrupted rerun is not considered completed" do
    @tracker.record_finish("my_wf", "step_1", success: true)
    @tracker.record_start("my_wf", "step_1")

    refute_includes @tracker.completed_steps("my_wf"), "step_1"
  end

  test "corrupted history is not silently treated as an empty workflow" do
    @tracker.record_finish("my_wf", "step_1", success: true)
    File.open(@log_path, "a") { |file| file.puts("{invalid json") }

    assert_raises(JSON::ParserError) { @tracker.completed_steps("my_wf") }
  end

  test "reset clears completed steps for workflow" do
    @tracker.record_finish("my_wf", "step_1", success: true)
    @tracker.record_reset("my_wf")

    completed = @tracker.completed_steps("my_wf")
    assert_empty completed
  end

  test "reset only affects specified workflow" do
    @tracker.record_finish("wf_a", "step_1", success: true)
    @tracker.record_finish("wf_b", "step_1", success: true)
    @tracker.record_reset("wf_a")

    assert_empty @tracker.completed_steps("wf_a")
    assert_includes @tracker.completed_steps("wf_b"), "step_1"
  end

  test "last_run returns most recent finish for step" do
    @tracker.record_finish("my_wf", "step_1", success: false, duration: 1.0)
    @tracker.record_finish("my_wf", "step_1", success: true, duration: 2.0)

    last = @tracker.last_run("my_wf", "step_1")
    assert_equal true, last["success"]
    assert_equal 2.0, last["duration_seconds"]
  end

  test "last_run returns nil for unrun step" do
    assert_nil @tracker.last_run("my_wf", "nonexistent")
  end

  test "history filters by workflow" do
    @tracker.record_start("wf_a", "step_1")
    @tracker.record_start("wf_b", "step_1")

    history_a = @tracker.history("wf_a")
    assert_equal 1, history_a.size
    assert_equal "wf_a", history_a.first["workflow"]
  end

  test "history returns all events without filter" do
    @tracker.record_start("wf_a", "step_1")
    @tracker.record_start("wf_b", "step_1")

    assert_equal 2, @tracker.history.size
  end

  test "clear removes all events" do
    @tracker.record_start("my_wf", "step_1")
    @tracker.clear!

    assert_equal 0, @tracker.history.size
  end

  test "handles missing log file" do
    fresh_tracker = CorpusCli::StateTracker.new(File.join(@tmpdir, "nonexistent.log"))
    assert_equal 0, fresh_tracker.history.size
    assert_empty fresh_tracker.completed_steps("any")
  end

  test "output excerpt is truncated" do
    long_output = "x" * 1000
    @tracker.record_finish("my_wf", "step_1", success: true, output: long_output)

    events = @tracker.history
    assert events.first["output_excerpt"].length <= 500
  end
end

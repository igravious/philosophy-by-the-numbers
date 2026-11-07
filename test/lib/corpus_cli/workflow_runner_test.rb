# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "yaml"
require_relative "../../../lib/corpus_cli/workflow_definition"
require_relative "../../../lib/corpus_cli/workflow_runner"

class WorkflowRunnerTest < ActiveSupport::TestCase
  def setup
    @tmpdir = Dir.mktmpdir
    @log_path = File.join(@tmpdir, "test.log")
    @tracker = CorpusCli::StateTracker.new(@log_path)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def build_workflow(steps = nil)
    data = {
      "workflow" => {
        "name" => "test_wf",
        "steps" => steps || [
          {"id" => "a", "task" => "test:a", "type" => "shell", "safety" => "read_only", "prerequisites" => []},
          {"id" => "b", "task" => "test:b", "type" => "shell", "safety" => "mutating", "prerequisites" => ["a"]}
        ]
      }
    }
    file = Tempfile.new(["wf", ".yml"])
    file.write(YAML.dump(data))
    file.close
    CorpusCli::WorkflowDefinition.new(file.path)
  ensure
    file&.unlink
  end

  test "dry run does not execute commands" do
    wf = build_workflow([
      {"id" => "a", "task" => "echo should_not_run", "type" => "shell", "safety" => "read_only", "prerequisites" => []}
    ])
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, dry_run: true, quiet: true)

    result = runner.run_step(wf, wf.steps.first, skip_confirmation: true)
    assert_equal :dry_run, result
    assert_empty @tracker.completed_steps("test_wf")
  end

  test "dry_run? predicate" do
    runner = CorpusCli::WorkflowRunner.new(dry_run: true)
    assert runner.dry_run?

    runner2 = CorpusCli::WorkflowRunner.new(dry_run: false)
    refute runner2.dry_run?
  end

  test "run_step executes command and records success" do
    wf = build_workflow([
      {"id" => "a", "task" => "true", "type" => "shell", "safety" => "read_only", "prerequisites" => []}
    ])
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, quiet: true)

    result = runner.run_step(wf, wf.steps.first, skip_confirmation: true)
    assert_equal :success, result
    assert_includes @tracker.completed_steps("test_wf"), "a"
  end

  test "run_step records failure" do
    wf = build_workflow([
      {"id" => "a", "task" => "false", "type" => "shell", "safety" => "read_only", "prerequisites" => []}
    ])
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, quiet: true)

    result = runner.run_step(wf, wf.steps.first, skip_confirmation: true)
    assert_equal :failure, result
    refute_includes @tracker.completed_steps("test_wf"), "a"
  end

  test "run_step skips confirmation for read_only steps" do
    wf = build_workflow([
      {"id" => "a", "task" => "true", "type" => "shell", "safety" => "read_only", "prerequisites" => []}
    ])
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, quiet: true)

    result = runner.run_step(wf, wf.steps.first)
    assert_equal :success, result
  end

  test "run_workflow skips already completed steps" do
    wf = build_workflow([
      {"id" => "a", "task" => "true", "type" => "shell", "safety" => "read_only", "prerequisites" => []},
      {"id" => "b", "task" => "true", "type" => "shell", "safety" => "read_only", "prerequisites" => ["a"]}
    ])

    @tracker.record_finish("test_wf", "a", success: true)

    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, quiet: true)
    results = runner.run_workflow(wf, skip_confirmation: true)

    assert_equal :already_done, results["a"]
    assert_equal :success, results["b"]
  end

  test "workflow halts after a failed step" do
    wf = build_workflow([
      {"id" => "a", "task" => "false", "type" => "shell", "safety" => "read_only"},
      {"id" => "b", "task" => "true", "type" => "shell", "safety" => "read_only", "prerequisites" => ["a"]}
    ])
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, quiet: true)

    results = runner.run_workflow(wf)

    assert_equal({"a" => :failure}, results)
    assert_nil @tracker.last_run("test_wf", "b")
  end

  test "continuing after failure runs independent steps but blocks dependants" do
    wf = build_workflow([
      {"id" => "a", "task" => "false", "type" => "shell", "safety" => "read_only"},
      {"id" => "b", "task" => "true", "type" => "shell", "safety" => "read_only", "prerequisites" => ["a"]},
      {"id" => "c", "task" => "true", "type" => "shell", "safety" => "read_only"}
    ])
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, quiet: true)

    results = runner.run_workflow(wf, halt_on_failure: false)

    assert_equal :failure, results["a"]
    assert_equal :blocked, results["b"]
    assert_equal :success, results["c"]
    assert_nil @tracker.last_run("test_wf", "b")
  end

  test "declining a prerequisite prevents its dependants from running" do
    wf = build_workflow([
      {"id" => "a", "task" => "true", "type" => "shell", "safety" => "mutating"},
      {"id" => "b", "task" => "true", "type" => "shell", "safety" => "read_only", "prerequisites" => ["a"]}
    ])
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, quiet: true)
    input = StringIO.new("n\n")
    original_stdin = $stdin
    $stdin = input

    results = runner.run_workflow(wf)

    assert_equal :skipped, results["a"]
    assert_equal :blocked, results["b"]
    assert_empty @tracker.history
  ensure
    $stdin = original_stdin
  end

  test "dry run previews dependent steps without recording completion" do
    wf = build_workflow
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, dry_run: true, quiet: true)

    results = runner.run_workflow(wf)

    assert_equal({"a" => :dry_run, "b" => :dry_run}, results)
    assert_empty @tracker.history
  end

  test "resuming a failed workflow retries the failure and continues" do
    marker = File.join(@tmpdir, "first-attempt")
    wf = build_workflow([
      {"id" => "a", "task" => "test -f #{marker} || { touch #{marker}; exit 1; }", "type" => "shell", "safety" => "read_only"},
      {"id" => "b", "task" => "true", "type" => "shell", "safety" => "read_only", "prerequisites" => ["a"]}
    ])
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, quiet: true)

    assert_equal({"a" => :failure}, runner.run_workflow(wf))
    assert_equal({"a" => :success, "b" => :success}, runner.run_workflow(wf))
    assert_equal Set.new(%w[a b]), @tracker.completed_steps("test_wf")
  end

  test "custom step execution uses the same dependency and resume rules" do
    wf = build_workflow
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, quiet: true)
    executed = []

    results = runner.run_workflow(wf, halt_on_failure: false) do |step|
      executed << step.id
      :skipped
    end

    assert_equal ["a"], executed
    assert_equal({"a" => :skipped, "b" => :blocked}, results)
    assert_empty @tracker.history
  end

  test "rerunning a prerequisite also reruns its previously completed dependant" do
    wf = build_workflow([
      {"id" => "a", "task" => "true", "type" => "shell", "safety" => "read_only"},
      {"id" => "b", "task" => "true", "type" => "shell", "safety" => "read_only", "prerequisites" => ["a"]}
    ])
    @tracker.record_finish("test_wf", "a", success: true)
    @tracker.record_finish("test_wf", "b", success: true)
    @tracker.record_start("test_wf", "a")
    @tracker.record_finish("test_wf", "a", success: false)
    runner = CorpusCli::WorkflowRunner.new(state_tracker: @tracker, quiet: true)

    results = runner.run_workflow(wf)

    assert_equal({"a" => :success, "b" => :success}, results)
    assert_equal 2, @tracker.history.count { |event| event["event"] == "step_finish" && event["step"] == "b" }
  end
end

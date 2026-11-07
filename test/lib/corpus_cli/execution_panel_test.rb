require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../../../lib/corpus_cli/cli"
require_relative "../../../lib/corpus_cli/tui/execution_panel"

class ExecutionPanelTest < ActiveSupport::TestCase
  test "declining a TUI prerequisite blocks its dependent step" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "workflow.yml")
      File.write(path, YAML.dump("workflow" => {"name" => "tui", "steps" => [
        {"id" => "first", "task" => "true", "type" => "shell", "safety" => "mutating"},
        {"id" => "second", "task" => "true", "type" => "shell", "safety" => "read_only", "prerequisites" => ["first"]}
      ]}))
      workflow = CorpusCli::WorkflowDefinition.new(path)
      tracker = CorpusCli::StateTracker.new(File.join(dir, "history.log"))
      prompt = Minitest::Mock.new
      prompt.expect(:yes?, false, [String])
      prompt.expect(:keypress, nil, [String])

      CorpusCli.stub(:state_tracker, tracker) do
        output, = capture_io { CorpusCli::Tui::ExecutionPanel.new(prompt).run_workflow(workflow) }
        assert_includes output, "[blocked] Second"
        assert_empty tracker.history
      end
      prompt.verify
    end
  end

  test "TUI execution records each command once through the shared runner" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "workflow.yml")
      File.write(path, YAML.dump("workflow" => {"name" => "tui", "steps" => [
        {"id" => "first", "task" => "true", "type" => "shell", "safety" => "read_only"}
      ]}))
      workflow = CorpusCli::WorkflowDefinition.new(path)
      tracker = CorpusCli::StateTracker.new(File.join(dir, "history.log"))
      spinner = Minitest::Mock.new
      spinner.expect(:auto_spin, nil)
      spinner.expect(:success, nil)
      spinner.expect(:stop, nil)

      CorpusCli.stub(:state_tracker, tracker) do
        TTY::Spinner.stub(:new, spinner) do
          capture_io { CorpusCli::Tui::ExecutionPanel.new(nil).run_step(workflow, workflow.steps.first) }
        end
      end

      assert_equal ["step_start", "step_finish"], tracker.history.map { |event| event["event"] }
      assert_includes tracker.completed_steps("tui"), "first"
      spinner.verify
    end
  end
end

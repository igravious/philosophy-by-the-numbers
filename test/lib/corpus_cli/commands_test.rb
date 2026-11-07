require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../../../lib/corpus_cli/cli"

class CorpusCommandsTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir
    File.write(File.join(@directory, "example.yml"), YAML.dump("workflow" => {
      "name" => "example", "display_name" => "Example pipeline", "description" => "A controlled pipeline", "category" => "testing",
      "steps" => [
        {"id" => "first", "task" => "true", "type" => "shell", "safety" => "read_only", "description" => "First description"},
        {"id" => "second", "task" => "true", "type" => "shell", "prerequisites" => ["first"], "estimated_duration" => "1s",
         "params" => [{"name" => "source", "default" => "stanford", "description" => "Reference work"}],
         "postconditions" => [{"description" => "Recorded", "check" => "true"}]}
      ], "auxiliary_steps" => [{"id" => "report", "task" => "true", "type" => "shell", "description" => "Report description"}]
    }))
    @registry = CorpusCli::WorkflowRegistry.new(@directory)
    @tracker = CorpusCli::StateTracker.new(File.join(@directory, "history.log"))
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "workflow listing and inspection expose task and completion information" do
    @tracker.record_finish("example", "first", success: true)
    @tracker.record_finish("example", "report", success: true)
    output = invoke(%w[workflows list]) + invoke(%w[workflows show example --verbose])

    assert_includes output, "TESTING"
    assert_includes output, "1 auxiliary"
    assert_includes output, "[x] First"
    assert_includes output, "requires: first"
    assert_includes output, "task: true"
    assert_includes output, "1/2 steps completed"
  end

  test "workflow inspection explains unknown and empty registries" do
    assert_includes invoke(%w[workflows show missing]), "Unknown workflow: missing"
    @registry.workflows.clear
    assert_includes invoke(%w[workflows list]), "No workflows found"
  end

  test "status shows next steps completion and unknown workflows" do
    assert_includes invoke(%w[status show example]), "Next: First"
    @tracker.record_finish("example", "first", success: true)
    @tracker.record_finish("example", "second", success: true)
    assert_includes invoke(%w[status show]), "Status: Complete"
    assert_includes invoke(%w[status show missing]), "Unknown workflow: missing"
  end

  test "history renders starts successes failures resets and empty results" do
    assert_includes invoke(%w[status history example]), "No history found"
    @tracker.record_start("example", "first")
    @tracker.record_finish("example", "first", success: true, duration: 1.2)
    @tracker.record_finish("example", "second", success: false)
    @tracker.record_reset("example")
    output = invoke(%w[status history example])

    assert_includes output, "START"
    assert_includes output, "OK"
    assert_includes output, "FAIL"
    assert_includes output, "RESET"
    assert_includes output, "1.2s"
  end

  test "workflow reset preserves other histories and global reset needs confirmation" do
    @tracker.record_finish("example", "first", success: true)
    @tracker.record_finish("other", "first", success: true)
    invoke(%w[status reset example])
    assert_empty @tracker.completed_steps("example")
    assert_includes @tracker.completed_steps("other"), "first"

    with_input("n\n") { invoke(%w[status reset]) }
    refute_empty @tracker.history
    with_input("y\n") { assert_includes invoke(%w[status reset]), "All workflow history cleared" }
    assert_empty @tracker.history
  end

  test "ASCII and Mermaid commands render diagrams and report unknown workflows" do
    assert_includes invoke(%w[diagram ascii example]), "First"
    assert_includes invoke(%w[diagram ascii missing]), "Unknown workflow: missing"
    assert_includes invoke(%w[diagram mermaid example]), "flowchart"
    assert_includes invoke(%w[diagram mermaid missing]), "Unknown workflow: missing"
    output = File.join(@directory, "diagrams")
    assert_includes invoke(["diagram", "mermaid", "--all", "--output-dir", output]), "Generated Mermaid docs"
    assert_includes File.read(File.join(output, "example.md")), "Example pipeline"
  end

  test "manual shows workflow details and executable parameter documentation" do
    workflow = invoke(%w[man example])
    step = invoke(%w[man example second])

    assert_includes workflow, "A controlled pipeline"
    assert_includes workflow, "Requires: first"
    assert_includes workflow, "Report description"
    assert_includes step, "PARAMETERS"
    assert_includes step, "Reference work"
    assert_includes step, "POSTCONDITIONS"
    assert_includes step, "Recorded"
    assert_includes invoke(%w[man example missing]), "Unknown step: missing"
    assert_includes invoke(%w[man missing]), "Unknown workflow: missing"
  end

  test "tui command launches the interactive menu" do
    require_relative "../../../lib/corpus_cli/tui/main_menu"
    menu = Minitest::Mock.new
    menu.expect(:run, nil)
    CorpusCli::Tui::MainMenu.stub(:new, menu) { invoke(%w[tui]) }
    menu.verify
  end

  private

  def invoke(arguments)
    CorpusCli.stub(:registry, @registry) do
      CorpusCli.stub(:state_tracker, @tracker) do
        capture_io { CorpusCli::CLI.start(arguments) }.first
      end
    end
  end

  def with_input(text)
    previous = $stdin
    $stdin = StringIO.new(text)
    yield
  ensure
    $stdin = previous
  end
end

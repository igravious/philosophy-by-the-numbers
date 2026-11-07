require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../../../lib/corpus_cli/cli"
require_relative "../../../lib/corpus_cli/tui/main_menu"
require_relative "../../support/scripted_prompt"

class CorpusTuiTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir
    definition = {"workflow" => {"name" => "example", "display_name" => "Example workflow",
      "description" => "A controlled example", "steps" => [
        {"id" => "first", "task" => "true", "type" => "shell", "safety" => "read_only"},
        {"id" => "second", "task" => "true", "type" => "shell", "prerequisites" => ["first"],
         "description" => "Dependent step", "estimated_duration" => "one second",
         "params" => [{"name" => "source", "default" => "stanford"}],
         "postconditions" => [{"description" => "A completed example"}]}
      ], "auxiliary_steps" => [
        {"id" => "report", "task" => "true", "type" => "shell", "safety" => "read_only"}
      ]}}
    File.write(File.join(@directory, "example.yml"), YAML.dump(definition))
    @registry = CorpusCli::WorkflowRegistry.new(@directory)
    @workflow = @registry.find("example")
    @tracker = CorpusCli::StateTracker.new(File.join(@directory, "history.log"))
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "main menu presents its actions and exits on quit" do
    prompt = ScriptedPrompt.new(:quit)
    output = with_cli { capture_io { menu(prompt).run }.first }

    assert_includes output, "CorpusBuilder"
    assert_equal [:browse, :status, :run_step, :run_workflow, :diagram, :quit], prompt.menus.first.map(&:last)
    assert_empty prompt.answers
  end

  test "main menu dispatches every action and returns after cancelled selections" do
    prompt = ScriptedPrompt.new(:browse, nil, :status, :run_step, nil, :run_workflow, nil, :diagram, nil, :quit)
    output = with_cli { capture_io { menu(prompt).run }.first }

    assert_includes output, "Example workflow"
    assert_empty prompt.answers
    assert_equal 6, prompt.menus.length
  end

  test "workflow execution from the main menu reaches the dry run" do
    prompt = ScriptedPrompt.new(@workflow, true)
    output = with_cli { capture_io { menu(prompt).send(:run_workflow_interactive) }.first }

    assert_includes output, "[DRY RUN] Workflow: Example workflow"
    assert_empty prompt.answers
    assert_empty @tracker.history
  end

  test "cancelling workflow and step selection returns to the menu" do
    with_cli do
      [:run_step_interactive, :run_workflow_interactive, :show_diagram].each do |action|
        prompt = ScriptedPrompt.new(nil)
        menu(prompt).send(action)
        assert_empty prompt.answers
      end
      prompt = ScriptedPrompt.new(@workflow, nil)
      menu(prompt).send(:run_step_interactive)
      assert_empty prompt.answers
    end
  end

  test "workflows with only auxiliary steps explain why the pipeline cannot run" do
    File.write(File.join(@directory, "auxiliary.yml"), YAML.dump("workflow" => {"name" => "auxiliary", "steps" => []}))
    @registry.reload!
    prompt = ScriptedPrompt.new(@registry.find("auxiliary"))

    with_cli { menu(prompt).send(:run_workflow_interactive) }

    assert_includes prompt.messages, "  This workflow has no pipeline steps."
  end

  test "step execution reports unmet prerequisites and allows cancellation" do
    prompt = ScriptedPrompt.new(@workflow, @workflow.steps.last, false)
    output = with_cli { capture_io { menu(prompt).send(:run_step_interactive) }.first }

    assert_includes output, "unmet prerequisites: first"
    assert_empty @tracker.history
    assert_empty prompt.answers
  end

  test "step execution collects parameters before previewing a command" do
    prompt = ScriptedPrompt.new(@workflow, @workflow.steps.last, true, true, "ox_3rd")
    output = with_cli { capture_io { menu(prompt).send(:run_step_interactive) }.first }

    assert_includes output, "[DRY RUN] Would execute: true"
    assert_empty prompt.answers
    assert_empty @tracker.history
  end

  test "status shows progress and the next runnable step" do
    @tracker.record_finish("example", "first", success: true)
    prompt = ScriptedPrompt.new
    output = with_cli { capture_io { menu(prompt).send(:show_status) }.first }

    assert_includes output, "1/2"
    assert_includes output, "next: Second"
    assert_equal 1, prompt.messages.length
  end

  test "status recognises a complete workflow and auxiliary-only definitions" do
    @workflow.steps.each { |step| @tracker.record_finish("example", step.id, success: true) }
    File.write(File.join(@directory, "auxiliary.yml"), YAML.dump("workflow" => {"name" => "auxiliary", "steps" => []}))
    @registry.reload!
    output = with_cli { capture_io { menu(ScriptedPrompt.new).send(:show_status) }.first }

    assert_includes output, "complete"
    assert_includes output, "auxiliary only"
  end

  test "diagram selection renders the chosen workflow" do
    prompt = ScriptedPrompt.new(@workflow)
    output = with_cli { capture_io { menu(prompt).send(:show_diagram) }.first }

    assert_includes output, "First"
    assert_includes output, "Second"
  end

  test "workflow browser lists progress and allows inspection before returning" do
    @tracker.record_finish("example", "first", success: true)
    @tracker.record_finish("example", "second", success: false, duration: 1.2)
    prompt = ScriptedPrompt.new(@workflow, :inspect, @workflow.steps.last, :back, nil)
    output = with_cli { capture_io { CorpusCli::Tui::WorkflowBrowser.new(prompt).run }.first }

    assert_includes output, "Example workflow"
    assert_includes output, "Prerequisites:"
    assert_includes output, "first (done)"
    assert_includes output, "Result: Failed"
    assert_includes output, "A completed example"
    assert_empty prompt.answers
  end

  test "workflow browser handles cancelled inspection" do
    prompt = ScriptedPrompt.new(@workflow, :inspect, nil, :back, nil)

    with_cli { capture_io { CorpusCli::Tui::WorkflowBrowser.new(prompt).run } }

    assert_empty prompt.answers
  end

  test "workflow browser displays auxiliary-only workflows" do
    File.write(File.join(@directory, "auxiliary.yml"), YAML.dump("workflow" => {"name" => "auxiliary", "steps" => [],
      "auxiliary_steps" => [{"id" => "report", "task" => "true", "type" => "shell", "safety" => "read_only"}]}))
    @registry.reload!
    prompt = ScriptedPrompt.new(@registry.find("auxiliary"), :back, nil)
    output = with_cli { capture_io { CorpusCli::Tui::WorkflowBrowser.new(prompt).run }.first }

    assert_includes output, "Auxiliary:"
    assert_includes output, "Report"
    assert_empty prompt.answers
  end

  test "step inspector renders a successful execution with no optional fields" do
    @tracker.record_finish("example", "first", success: true)
    output = with_cli do
      capture_io { CorpusCli::Tui::StepInspector.new(ScriptedPrompt.new).show(@workflow, @workflow.steps.first) }.first
    end

    assert_includes output, "Completed"
    assert_includes output, "Success"
    assert_includes output, "Command: true"
  end

  private

  def menu(prompt)
    TTY::Prompt.stub(:new, prompt) { CorpusCli::Tui::MainMenu.new }
  end

  def with_cli(&block)
    CorpusCli.stub(:registry, @registry) do
      CorpusCli.stub(:state_tracker, @tracker) do
        TTY::Screen.stub(:width, 100, &block)
      end
    end
  end
end

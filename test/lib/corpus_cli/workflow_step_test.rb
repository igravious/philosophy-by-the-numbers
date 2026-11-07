# frozen_string_literal: true

require "test_helper"
require "shellwords"
require_relative "../../../lib/corpus_cli/workflow_step"

class WorkflowStepTest < ActiveSupport::TestCase
  def build_step(overrides = {})
    defaults = {
      "id" => "test_step",
      "task" => "shadow:philosopher:populate",
      "type" => "rake",
      "display_name" => "Test Step",
      "description" => "A test step",
      "safety" => "mutating",
      "prerequisites" => [],
      "params" => []
    }
    CorpusCli::WorkflowStep.new(defaults.merge(overrides))
  end

  test "parses basic step attributes" do
    step = build_step
    assert_equal "test_step", step.id
    assert_equal "shadow:philosopher:populate", step.task
    assert_equal "rake", step.type
    assert_equal "Test Step", step.display_name
    assert_equal "mutating", step.safety
  end

  test "defaults type to rake" do
    step = CorpusCli::WorkflowStep.new("id" => "s", "task" => "t")
    assert_equal "rake", step.type
  end

  test "defaults safety to mutating" do
    step = CorpusCli::WorkflowStep.new("id" => "s", "task" => "t")
    assert_equal "mutating", step.safety
  end

  test "rejects invalid type" do
    assert_raises(ArgumentError) { build_step("type" => "invalid") }
  end

  test "rejects invalid safety level" do
    assert_raises(ArgumentError) { build_step("safety" => "invalid") }
  end

  test "builds rake command without params" do
    step = build_step
    assert_equal "bin/rake shadow:philosopher:populate", step.build_command
  end

  test "builds rake command with params" do
    step = build_step(
      "params" => [{"name" => "force", "type" => "boolean", "default" => false}]
    )
    assert_equal ["bin/rake", "shadow:philosopher:populate[true]"],
      Shellwords.split(step.build_command("force" => true))
  end

  test "rake arguments follow the declared parameter order" do
    step = build_step("params" => [{"name" => "url"}, {"name" => "year"}])

    assert_equal ["bin/rake", "shadow:philosopher:populate[https://example.com,2026]"],
      Shellwords.split(step.build_command("year" => 2026, "url" => "https://example.com"))
  end

  test "parameter defaults are used without dropping false" do
    step = build_step("params" => [{"name" => "force", "default" => false}])

    assert_equal ["bin/rake", "shadow:philosopher:populate[false]"],
      Shellwords.split(step.build_command)
    assert_equal ["bin/rake", "shadow:philosopher:populate[false]"],
      Shellwords.split(step.build_command(force: false))
  end

  test "omitted positional parameters keep their place" do
    step = build_step("params" => [{"name" => "url"}, {"name" => "year"}])

    assert_equal ["bin/rake", "shadow:philosopher:populate[,2026]"],
      Shellwords.split(step.build_command(year: 2026))
  end

  test "parameter values remain one shell argument" do
    step = build_step("params" => [{"name" => "query"}])
    value = "being and nothingness; $(touch /tmp/should-not-exist)"

    assert_equal ["bin/rake", "shadow:philosopher:populate[#{value}]"],
      Shellwords.split(step.build_command(query: value))
  end

  test "rake escapes commas inside a parameter" do
    step = build_step("params" => [{"name" => "query"}])

    assert_equal ["bin/rake", 'shadow:philosopher:populate[being\\, nothingness]'],
      Shellwords.split(step.build_command(query: "being, nothingness"))
  end

  test "rails runner receives positional arguments and defaults" do
    step = build_step("type" => "rails_runner", "task" => "import/sauce.rb",
      "params" => [{"name" => "source", "default" => "stanford"}])

    assert_equal ["bin/rails", "runner", "import/sauce.rb", "stanford"],
      Shellwords.split(step.build_command)
    assert_equal ["bin/rails", "runner", "import/sauce.rb", "ox_3rd"],
      Shellwords.split(step.build_command(source: "ox_3rd"))
  end

  test "builds rails runner command" do
    step = build_step("type" => "rails_runner", "task" => "import/sauce.rb")
    assert_equal "bin/rails runner import/sauce.rb", step.build_command
  end

  test "builds shell command" do
    step = build_step("type" => "shell", "task" => "echo hello")
    assert_equal "echo hello", step.build_command
  end

  test "safety predicates" do
    assert build_step("safety" => "read_only").read_only?
    assert build_step("safety" => "mutating").mutating?
    assert build_step("safety" => "destructive").destructive?
  end

  test "safety labels" do
    assert_equal "(R)", build_step("safety" => "read_only").safety_label
    assert_equal "(M)", build_step("safety" => "mutating").safety_label
    assert_equal "(D)", build_step("safety" => "destructive").safety_label
  end

  test "safety colours" do
    assert_equal :green, build_step("safety" => "read_only").safety_colour
    assert_equal :yellow, build_step("safety" => "mutating").safety_colour
    assert_equal :red, build_step("safety" => "destructive").safety_colour
  end

  test "parses params" do
    step = build_step(
      "params" => [
        {"name" => "force", "type" => "boolean", "default" => false, "description" => "Force it"}
      ]
    )
    assert_equal 1, step.params.size
    param = step.params.first
    assert_equal "force", param.name
    assert_equal "boolean", param.type
    assert_equal false, param.default
    assert param.boolean?
    refute param.enum?
  end

  test "generates display_name from id when not provided" do
    step = CorpusCli::WorkflowStep.new("id" => "my_cool_step", "task" => "t")
    assert_equal "My cool step", step.display_name
  end
end

class StepParamTest < ActiveSupport::TestCase
  test "prompt label includes description" do
    param = CorpusCli::StepParam.new(
      "name" => "force", "type" => "boolean", "description" => "Actually do it"
    )
    assert_includes param.prompt_label, "Actually do it"
    assert_includes param.prompt_label, "Force"
  end

  test "enum detection" do
    param = CorpusCli::StepParam.new(
      "name" => "source", "type" => "enum", "options" => %w[a b]
    )
    assert param.enum?
    refute param.boolean?
  end
end

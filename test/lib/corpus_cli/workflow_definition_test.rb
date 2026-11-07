# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "yaml"
require_relative "../../../lib/corpus_cli/workflow_definition"

class WorkflowDefinitionTest < ActiveSupport::TestCase
  def write_yaml(data)
    file = Tempfile.new(["workflow", ".yml"])
    file.write(YAML.dump(data))
    file.close
    file
  end

  def minimal_workflow
    {
      "workflow" => {
        "name" => "test_wf",
        "display_name" => "Test Workflow",
        "description" => "A test workflow",
        "category" => "testing",
        "steps" => [
          {"id" => "step_a", "task" => "test:a", "prerequisites" => []},
          {"id" => "step_b", "task" => "test:b", "prerequisites" => ["step_a"]},
          {"id" => "step_c", "task" => "test:c", "prerequisites" => ["step_b"]}
        ],
        "auxiliary_steps" => [
          {"id" => "aux_1", "task" => "test:aux", "safety" => "read_only"}
        ]
      }
    }
  end

  test "parses workflow from YAML file" do
    file = write_yaml(minimal_workflow)
    wf = CorpusCli::WorkflowDefinition.new(file.path)

    assert_equal "test_wf", wf.name
    assert_equal "Test Workflow", wf.display_name
    assert_equal "A test workflow", wf.description
    assert_equal "testing", wf.category
    assert_equal 3, wf.steps.size
    assert_equal 1, wf.auxiliary_steps.size
  ensure
    file.unlink
  end

  test "all_steps includes both pipeline and auxiliary" do
    file = write_yaml(minimal_workflow)
    wf = CorpusCli::WorkflowDefinition.new(file.path)

    assert_equal 4, wf.all_steps.size
  ensure
    file.unlink
  end

  test "find_step by id" do
    file = write_yaml(minimal_workflow)
    wf = CorpusCli::WorkflowDefinition.new(file.path)

    step = wf.find_step("step_b")
    assert_equal "step_b", step.id

    aux = wf.find_step("aux_1")
    assert_equal "aux_1", aux.id

    assert_nil wf.find_step("nonexistent")
  ensure
    file.unlink
  end

  test "pipeline_order returns topologically sorted steps" do
    file = write_yaml(minimal_workflow)
    wf = CorpusCli::WorkflowDefinition.new(file.path)

    order = wf.pipeline_order
    ids = order.map(&:id)

    assert_equal %w[step_a step_b step_c], ids
  ensure
    file.unlink
  end

  test "runnable_steps returns steps with met prerequisites" do
    file = write_yaml(minimal_workflow)
    wf = CorpusCli::WorkflowDefinition.new(file.path)

    runnable = wf.runnable_steps(Set.new)
    assert_equal ["step_a"], runnable.map(&:id)

    runnable = wf.runnable_steps(Set.new(["step_a"]))
    assert_equal ["step_b"], runnable.map(&:id)

    runnable = wf.runnable_steps(Set.new(%w[step_a step_b]))
    assert_equal ["step_c"], runnable.map(&:id)
  ensure
    file.unlink
  end

  test "next_step returns first runnable step" do
    file = write_yaml(minimal_workflow)
    wf = CorpusCli::WorkflowDefinition.new(file.path)

    assert_equal "step_a", wf.next_step(Set.new).id
    assert_equal "step_b", wf.next_step(Set.new(["step_a"])).id
    assert_nil wf.next_step(Set.new(%w[step_a step_b step_c]))
  ensure
    file.unlink
  end

  test "raises on unknown prerequisite" do
    data = minimal_workflow
    data["workflow"]["steps"] << {
      "id" => "bad_step", "task" => "test:bad", "prerequisites" => ["nonexistent"]
    }

    file = write_yaml(data)
    assert_raises(ArgumentError) do
      CorpusCli::WorkflowDefinition.new(file.path)
    end
  ensure
    file.unlink
  end

  test "rejects duplicate step identities across pipeline and auxiliary steps" do
    data = minimal_workflow
    data["workflow"]["auxiliary_steps"].first["id"] = "step_a"
    file = write_yaml(data)

    assert_raises(ArgumentError) { CorpusCli::WorkflowDefinition.new(file.path) }
  ensure
    file.unlink
  end

  test "pipeline cannot depend on an auxiliary step that it never executes" do
    data = minimal_workflow
    data["workflow"]["steps"].first["prerequisites"] = ["aux_1"]
    file = write_yaml(data)

    assert_raises(ArgumentError) { CorpusCli::WorkflowDefinition.new(file.path) }
  ensure
    file.unlink
  end

  test "reports circular dependencies when ordering a pipeline" do
    data = minimal_workflow
    data["workflow"]["steps"].first["prerequisites"] = ["step_c"]
    file = write_yaml(data)
    wf = CorpusCli::WorkflowDefinition.new(file.path)

    error = assert_raises(ArgumentError) { wf.pipeline_order }
    assert_includes error.message, "Circular dependency"
  ensure
    file.unlink
  end

  test "handles parallel prerequisites" do
    data = {
      "workflow" => {
        "name" => "parallel_wf",
        "steps" => [
          {"id" => "a", "task" => "test:a", "prerequisites" => []},
          {"id" => "b", "task" => "test:b", "prerequisites" => []},
          {"id" => "c", "task" => "test:c", "prerequisites" => %w[a b]}
        ]
      }
    }
    file = write_yaml(data)
    wf = CorpusCli::WorkflowDefinition.new(file.path)

    order = wf.pipeline_order.map(&:id)
    assert_includes order[0..1], "a"
    assert_includes order[0..1], "b"
    assert_equal "c", order.last
  ensure
    file.unlink
  end

  test "handles empty steps" do
    data = {
      "workflow" => {
        "name" => "empty_wf",
        "steps" => [],
        "auxiliary_steps" => [
          {"id" => "aux", "task" => "test:aux", "safety" => "read_only"}
        ]
      }
    }
    file = write_yaml(data)
    wf = CorpusCli::WorkflowDefinition.new(file.path)

    assert_equal 0, wf.steps.size
    assert_equal 1, wf.auxiliary_steps.size
    assert_equal [], wf.pipeline_order
  ensure
    file.unlink
  end
end

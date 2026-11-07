# frozen_string_literal: true

require "test_helper"
require "rake"
require_relative "../../../lib/corpus_cli/workflow_registry"

class YamlWorkflowsTest < ActiveSupport::TestCase
  def setup
    @config_dir = File.expand_path("../../../config/workflows", __dir__)
    @registry = CorpusCli::WorkflowRegistry.new(@config_dir)
  end

  test "all YAML files load without errors" do
    assert @registry.workflows.size > 0, "No workflows loaded"
  end

  test "expected workflow count" do
    assert_equal 9, @registry.workflows.size,
      "Expected 9 workflows, got #{@registry.workflows.size}: #{@registry.names.join(", ")}"
  end

  test "all expected workflows present" do
    expected = %w[
      philosopher_population
      danker_pagerank
      work_discovery
      reference_integration
      corpus_elasticsearch
      corpus_git
      delta_analysis
      dictionary_cleanup
      utilities
    ]
    expected.each do |name|
      assert @registry.find(name), "Missing workflow: #{name}"
    end
  end

  test "all workflows have valid categories" do
    @registry.workflows.each_value do |wf|
      assert wf.category, "Workflow #{wf.name} has no category"
      refute wf.category.empty?, "Workflow #{wf.name} has empty category"
    end
  end

  test "all steps have valid task names" do
    @registry.workflows.each_value do |wf|
      wf.all_steps.each do |step|
        refute step.task.nil?, "Step #{step.id} in #{wf.name} has nil task"
        refute step.task.empty?, "Step #{step.id} in #{wf.name} has empty task"
      end
    end
  end

  test "rake steps reference registered application tasks" do
    Rails.application.load_tasks unless Rake::Task.task_defined?("shadow:philosopher:populate")

    @registry.workflows.each_value do |wf|
      wf.all_steps.select { |step| step.type == "rake" }.each do |step|
        assert Rake::Task.task_defined?(step.task),
          "#{wf.name}/#{step.id} references missing task #{step.task}"
      end
    end
  end

  test "rake parameters follow the task argument contract" do
    Rails.application.load_tasks unless Rake::Task.task_defined?("shadow:philosopher:populate")

    @registry.workflows.each_value do |wf|
      wf.all_steps.select { |step| step.type == "rake" }.each do |step|
        next unless Rake::Task.task_defined?(step.task)
        declared = step.params.map(&:name)
        actual = Rake::Task[step.task].arg_names.map(&:to_s)

        assert_equal actual.take(declared.size), declared,
          "#{wf.name}/#{step.id} parameter order differs from #{step.task}"
      end
    end
  end

  test "all prerequisites reference existing steps" do
    @registry.workflows.each_value do |wf|
      all_ids = wf.all_steps.map(&:id)
      wf.all_steps.each do |step|
        step.prerequisites.each do |pre_id|
          assert_includes all_ids, pre_id,
            "Step '#{step.id}' in '#{wf.name}' references unknown prerequisite '#{pre_id}'"
        end
      end
    end
  end

  test "no circular dependencies in any workflow" do
    @registry.workflows.each_value do |wf|
      assert_nothing_raised("Circular dependency in #{wf.name}") do
        wf.pipeline_order
      end
    end
  end

  test "philosopher_population has expected key steps" do
    wf = @registry.find("philosopher_population")
    step_ids = wf.steps.map(&:id)
    assert_includes step_ids, "populate"
    assert_includes step_ids, "flesh"
    assert_includes step_ids, "metric"
    assert_includes step_ids, "order"
  end

  test "danker_pagerank pipeline order is correct" do
    wf = @registry.find("danker_pagerank")
    order = wf.pipeline_order.map(&:id)
    assert_equal %w[update process_files import], order
  end
end

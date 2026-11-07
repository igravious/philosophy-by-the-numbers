# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'yaml'
require_relative '../../../lib/corpus_cli/workflow_registry'

class WorkflowRegistryTest < ActiveSupport::TestCase
  def setup
    @tmpdir = Dir.mktmpdir
    write_workflow('alpha', category: 'data_population', steps: 2)
    write_workflow('beta', category: 'corpus_management', steps: 1)
    write_workflow('gamma', category: 'data_population', steps: 3)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def write_workflow(name, category: 'testing', steps: 1)
    data = {
      'workflow' => {
        'name' => name,
        'display_name' => name.capitalize,
        'category' => category,
        'steps' => (1..steps).map { |i|
          { 'id' => "step_#{i}", 'task' => "test:#{name}:#{i}", 'prerequisites' => i > 1 ? ["step_#{i - 1}"] : [] }
        }
      }
    }
    File.write(File.join(@tmpdir, "#{name}.yml"), YAML.dump(data))
  end

  test "loads all YAML files from directory" do
    registry = CorpusCli::WorkflowRegistry.new(@tmpdir)
    assert_equal 3, registry.workflows.size
  end

  test "finds workflow by name" do
    registry = CorpusCli::WorkflowRegistry.new(@tmpdir)
    wf = registry.find('alpha')
    assert_equal 'alpha', wf.name
  end

  test "returns nil for unknown workflow" do
    registry = CorpusCli::WorkflowRegistry.new(@tmpdir)
    assert_nil registry.find('nonexistent')
  end

  test "names returns sorted list" do
    registry = CorpusCli::WorkflowRegistry.new(@tmpdir)
    assert_equal %w[alpha beta gamma], registry.names
  end

  test "by_category groups workflows" do
    registry = CorpusCli::WorkflowRegistry.new(@tmpdir)
    grouped = registry.by_category

    assert_equal 2, grouped.size
    assert_equal 1, grouped['corpus_management'].size
    assert_equal 2, grouped['data_population'].size
  end

  test "categories returns sorted category list" do
    registry = CorpusCli::WorkflowRegistry.new(@tmpdir)
    assert_equal %w[corpus_management data_population], registry.categories
  end

  test "reload clears and reloads workflows" do
    registry = CorpusCli::WorkflowRegistry.new(@tmpdir)
    assert_equal 3, registry.workflows.size

    write_workflow('delta', category: 'utilities')
    registry.reload!
    assert_equal 4, registry.workflows.size
  end

  test "handles empty directory" do
    empty_dir = Dir.mktmpdir
    registry = CorpusCli::WorkflowRegistry.new(empty_dir)
    assert_equal 0, registry.workflows.size
    assert_equal [], registry.names
  ensure
    FileUtils.remove_entry(empty_dir)
  end
end

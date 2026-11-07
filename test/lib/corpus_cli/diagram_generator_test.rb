# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'yaml'
require_relative '../../../lib/corpus_cli/workflow_definition'
require_relative '../../../lib/corpus_cli/diagram_generator'

class DiagramGeneratorTest < ActiveSupport::TestCase
  def setup
    @tmpdir = Dir.mktmpdir
    @generator = CorpusCli::DiagramGenerator.new
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def build_workflow(steps: nil, aux: nil)
    data = {
      'workflow' => {
        'name' => 'test_wf',
        'display_name' => 'Test Workflow',
        'description' => 'A test workflow',
        'category' => 'testing',
        'steps' => steps || [
          { 'id' => 'a', 'task' => 'test:a', 'safety' => 'read_only', 'display_name' => 'Step A', 'prerequisites' => [] },
          { 'id' => 'b', 'task' => 'test:b', 'safety' => 'mutating', 'display_name' => 'Step B', 'prerequisites' => ['a'] },
          { 'id' => 'c', 'task' => 'test:c', 'safety' => 'destructive', 'display_name' => 'Step C', 'prerequisites' => ['b'], 'estimated_duration' => '5 min' }
        ],
        'auxiliary_steps' => aux || [
          { 'id' => 'aux1', 'task' => 'test:aux1', 'safety' => 'read_only', 'display_name' => 'Auxiliary' }
        ]
      }
    }
    file = Tempfile.new(['wf', '.yml'])
    file.write(YAML.dump(data))
    file.close
    CorpusCli::WorkflowDefinition.new(file.path)
  ensure
    file&.unlink if file
  end

  test "ascii diagram contains workflow name" do
    wf = build_workflow
    output = @generator.ascii(wf)
    assert_includes output, 'Test Workflow'
  end

  test "ascii diagram shows all pipeline steps" do
    wf = build_workflow
    output = @generator.ascii(wf)
    assert_includes output, 'Step A'
    assert_includes output, 'Step B'
    assert_includes output, 'Step C'
  end

  test "ascii diagram shows safety labels" do
    wf = build_workflow
    output = @generator.ascii(wf)
    assert_includes output, '(R)'
    assert_includes output, '(M)'
    assert_includes output, '(D)'
  end

  test "ascii diagram shows estimated duration" do
    wf = build_workflow
    output = @generator.ascii(wf)
    assert_includes output, '~5 min'
  end

  test "ascii diagram shows completed markers" do
    wf = build_workflow
    completed = Set.new(['a'])
    output = @generator.ascii(wf, completed)
    assert_includes output, '[x]'
    assert_includes output, '[ ]'
  end

  test "ascii diagram shows auxiliary steps" do
    wf = build_workflow
    output = @generator.ascii(wf)
    assert_includes output, 'Auxiliary'
    assert_includes output, 'independently'
  end

  test "ascii diagram includes legend" do
    wf = build_workflow
    output = @generator.ascii(wf)
    assert_includes output, 'Legend'
  end

  test "mermaid output contains flowchart" do
    wf = build_workflow
    output = @generator.mermaid(wf)
    assert_includes output, 'flowchart TD'
    assert_includes output, '```mermaid'
  end

  test "mermaid shows edges for prerequisites" do
    wf = build_workflow
    output = @generator.mermaid(wf)
    assert_includes output, 'a --> b'
    assert_includes output, 'b --> c'
  end

  test "mermaid includes classDefs for safety levels" do
    wf = build_workflow
    output = @generator.mermaid(wf)
    assert_includes output, 'classDef read_only'
    assert_includes output, 'classDef mutating'
    assert_includes output, 'classDef destructive'
  end

  test "mermaid_doc includes step details" do
    wf = build_workflow
    output = @generator.mermaid_doc(wf)
    assert_includes output, '# Test Workflow'
    assert_includes output, '## Steps'
    assert_includes output, '### Step A'
    assert_includes output, '`test:a`'
  end

  test "generate_all_docs creates files" do
    wf = build_workflow
    output_dir = File.join(@tmpdir, 'docs')

    registry = Object.new
    def registry.workflows
      @wf_map
    end

    registry.instance_variable_set(:@wf_map, { 'test_wf' => wf })
    @generator.generate_all_docs(registry, output_dir)

    assert File.exist?(File.join(output_dir, 'test_wf.md'))
    content = File.read(File.join(output_dir, 'test_wf.md'))
    assert_includes content, 'Test Workflow'
  end
end

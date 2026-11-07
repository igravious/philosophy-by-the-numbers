# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../../../lib/corpus_cli/cli"

class CliLoadTest < ActiveSupport::TestCase
  test "CLI class loads without error" do
    assert defined?(CorpusCli::CLI), "CorpusCli::CLI should be defined"
    assert CorpusCli::CLI < Thor, "CLI should be a Thor subclass"
  end

  test "all subcommands are registered" do
    commands = CorpusCli::CLI.commands.keys
    assert_includes commands, "workflows"
    assert_includes commands, "exec"
    assert_includes commands, "status"
    assert_includes commands, "diagram"
    assert_includes commands, "tui"
    assert_includes commands, "man"
  end

  test "no Thor reserved words used as subcommands" do
    reserved = begin
      Thor::THOR_RESERVED_WORDS
    rescue
      %w[invoke shell run]
    end
    commands = CorpusCli::CLI.commands.keys
    conflicts = commands & reserved
    assert_empty conflicts, "Subcommands conflict with Thor reserved words: #{conflicts.join(", ")}"
  end

  test "module-level registry and state_tracker accessors work" do
    CorpusCli.reset!
    assert_kind_of CorpusCli::WorkflowRegistry, CorpusCli.registry
    assert_kind_of CorpusCli::StateTracker, CorpusCli.state_tracker
  ensure
    CorpusCli.reset!
  end

  test "failed workflows return a failing exit status" do
    definition = {
      "workflow" => {"name" => "failing", "steps" => [
        {"id" => "failure", "task" => "false", "type" => "shell", "safety" => "read_only"}
      ]}
    }

    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "failing.yml"), YAML.dump(definition))
      registry = CorpusCli::WorkflowRegistry.new(dir)
      tracker = CorpusCli::StateTracker.new(File.join(dir, "history.log"))
      CorpusCli.stub(:registry, registry) do
        CorpusCli.stub(:state_tracker, tracker) do
          error = assert_raises(SystemExit) do
            capture_io { CorpusCli::CLI.start(%w[exec workflow failing --yes]) }
          end
          assert_equal 1, error.status
        end
      end
    end
  end

  test "unknown execution targets return a failing exit status" do
    error = assert_raises(SystemExit) do
      capture_io { CorpusCli::CLI.start(%w[exec workflow nonexistent]) }
    end

    assert_equal 1, error.status
  end

  test "numbered parameter choices resolve to their declared values" do
    step = CorpusCli::WorkflowStep.new("id" => "import", "task" => "import/sauce.rb",
      "type" => "rails_runner", "params" => [
        {"name" => "source", "type" => "enum", "default" => "stanford", "options" => ["stanford", "ox_3rd"]}
      ])
    original_stdin = $stdin
    $stdin = StringIO.new("2\n")
    values = nil

    capture_io { values = CorpusCli::Commands::Exec.new.send(:collect_params, step) }

    assert_equal({"source" => "ox_3rd"}, values)
  ensure
    $stdin = original_stdin
  end

  test "end of input uses parameter defaults" do
    step = CorpusCli::WorkflowStep.new("id" => "import", "task" => "test", "params" => [
      {"name" => "force", "type" => "boolean", "default" => false},
      {"name" => "source", "type" => "enum", "default" => "stanford", "options" => ["stanford"]},
      {"name" => "label", "default" => "Default label"}
    ])
    original_stdin = $stdin
    $stdin = StringIO.new("")
    values = nil

    capture_io { values = CorpusCli::Commands::Exec.new.send(:collect_params, step) }

    assert_equal({"force" => false, "source" => "stanford", "label" => "Default label"}, values)
  ensure
    $stdin = original_stdin
  end
end

require "test_helper"
require "minitest/mock"
require "open3"
require_relative "../support/script_runner"

class MaintenanceScriptsTest < ActiveSupport::TestCase
  include ScriptRunner
  test "task categorization separates Rails tasks and preserves descriptions" do
    listing = "rake db:migrate # Migrate database\nrake shadow:work:populate[limit] # Populate works\nrake corpus:check\nnot a task\n\n"
    Open3.stub(:capture3, [listing, "", Struct.new(:success?).new(true)]) do
      output = capture_io { load_script(Rails.root.join("scripts/categorize_rake_tasks.rb")) }.first
      assert_includes output, "BUILT-IN TASKS (1)"
      assert_includes output, "USER-CREATED TASKS (2)"
      assert_includes output, "shadow:work:populate - Populate works"
      assert_includes output, "corpus:check - ..."
      assert_includes output, "SUMMARY: 3 total tasks"
    end
  end

  test "task categorization reports command failures" do
    Open3.stub(:capture3, ["", "Rake failed", Struct.new(:success?).new(false)]) do
      assert_includes capture_io { load_script(Rails.root.join("scripts/categorize_rake_tasks.rb")) }.first, "Error running rake -T: Rake failed"
    end
  end

  test "gem audit reports the sorted set absent from outdated output" do
    responses = ["rails\nrake\njson\n\n", "* rails (newest 8)\nheader\n  * json (newest 2)\n"]
    calls = []
    execute = ->(*command) {
      calls << command
      [responses.shift, "", Struct.new(:success?).new(true)]
    }
    Open3.stub(:capture3, execute) do
      output = capture_io { load_script(Rails.root.join("scripts/check_gems.rb")) }.first
      assert_includes output, "  - rake"
      refute_includes output, "  - rails"
      refute_includes output, "  - json"
    end
    assert_equal [["bin/bundle", "list", "--name-only"], ["bin/bundle", "outdated"]], calls
  end

  test "gem audit reports when every listed gem appears in outdated output" do
    responses = ["rails\n", "* rails (newest 8)\n"]
    Open3.stub(:capture3, ->(*) { [responses.shift, "", Struct.new(:success?).new(true)] }) do
      assert_includes capture_io { load_script(Rails.root.join("scripts/check_gems.rb")) }.first, "Every gem"
    end
  end
end

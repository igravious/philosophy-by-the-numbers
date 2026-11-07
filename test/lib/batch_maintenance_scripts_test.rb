require "test_helper"
require "minitest/mock"
require_relative "../support/script_runner"
require_relative "../support/kernel_methods"

class BatchMaintenanceScriptsTest < ActiveSupport::TestCase
  include ScriptRunner
  include KernelMethods

  test "work batch output follows current canonicity order and includes English labels" do
    figures = [1.0, 9.0, 5.0].map.with_index do |measure, index|
      figure = create_test_philosopher(measure: measure)
      figure.names.create!(lang: "en", label: "Batch Figure #{index}")
      figure
    end
    population = Philosopher.where(id: figures.map(&:id))
    Philosopher.stub(:order, ->(ordering) { population.order(ordering) }) do
      output = with_script_arguments("1") { capture_io { load_script(Rails.root.join("scripts/works.rb")) }.first }
      commands = output.lines.select { |line| line.start_with?("bin/rake") }
      expected = figures.sort_by { |figure| -figure.measure }.map { |figure| "bin/rake shadow:work:snarf[#{figure.id}]\n" }
      assert_equal expected, commands
      assert_includes output, "Batch Figure 1"
      assert_includes output, "Batch Figure 2"
    end
  end

  test "work batching rejects missing extra nonnumeric and out-of-range parameters" do
    [[], ["1", "2"], ["0"], ["-1"], ["53"], ["invalid"]].each do |arguments|
      output = with_script_arguments(*arguments) do
        capture_io { assert_equal 1, assert_raises(SystemExit) { load_script(Rails.root.join("scripts/works.rb")) }.status }.first
      end
      assert_includes output, "number between 1 and 52"
    end
  end

  test "VIAF diagnostics count missing identifiers in the ranked prefix" do
    figures = 52.times.map do |index|
      create_test_philosopher(measure: 100.0 - index, viaf: index.even? ? nil : index.to_s)
    end
    population = Philosopher.where(id: figures.map(&:id))
    Philosopher.stub(:count, population.count) do
      Philosopher.stub(:order, ->(ordering) { population.order(ordering) }) do
        output = capture_io { load_script(Rails.root.join("scripts/viaf.rb")) }.first
        assert_equal ["1 . 1", "51 . 26"], output.lines.map(&:strip)
      end
    end
  end

  test "role metadata creates missing capacities once and preserves established labels" do
    figure = create_test_philosopher
    existing = Capacity.create!(entity_id: 7_654_320, label: "Established")
    roles = [Role.create!(shadow: figure, entity_id: 7_654_321, label: "Copied Role"),
      Role.create!(shadow: figure, entity_id: 7_654_321, label: "Duplicate Role"),
      Role.create!(shadow: figure, entity_id: existing.entity_id, label: "Should not replace")]
    population = Role.where(id: roles.map(&:id))
    Role.stub(:all, population) do
      assert_difference("Capacity.count", 1) do
        assert_includes capture_io { load_script(Rails.root.join("scripts/set_relevant.rb")) }.first, "1 roles added"
      end
      assert_no_difference("Capacity.count") do
        assert_includes capture_io { load_script(Rails.root.join("scripts/set_relevant.rb")) }.first, "0 roles added"
      end
    end
    assert_equal "Copied Role", Capacity.find_by!(entity_id: 7_654_321).label
    assert_equal "Established", existing.reload.label
  end
end

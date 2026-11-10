require "test_helper"
require "json"
require_relative "../support/rake_task_testing"
require_relative "../support/canonicity_run_helpers"

class MetricTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting
  include CanonicityRunHelpers

  setup do
    use_rake_tasks(Rails.root.join("lib/tasks/metric.rake"))
    @first = create_test_philosopher(entity_id: 42, measure: -1.0)
    @second = create_test_philosopher(entity_id: 43, measure: -2.0)
    @run = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@first, @second],
      measures: {@first.id => 200.0, @second.id => 100.0}
    )
  end

  teardown do
    restore_rake_tasks
  end

  test "metric publish promotes an eligible run by subject and version" do
    output = run_task("publish", "Philosopher", "0.7.0")

    assert_includes output, "Published Philosopher run 0.7.0"
    assert_equal 200.0, @first.reload.measure
    assert_equal 100.0, @second.reload.measure
    assert_equal @run, Publication.current_for("Philosopher").metric_run
  end

  test "metric compare prints a JSON comparison for two runs of one subject" do
    other = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@first, @second],
      measures: {@first.id => 50.0, @second.id => 300.0},
      version: "0.7.1"
    )

    output = run_task("compare", "Philosopher", "0.7.0", "0.7.1")
    report = JSON.parse(output)

    assert_equal @run.id, report.fetch("from_run").fetch("id")
    assert_equal other.id, report.fetch("to_run").fetch("id")
    assert_equal 2, report.fetch("changes").length
    assert_equal true, report.fetch("configuration").fetch("changed")
  end

  test "metric publish prints a Work dependency mismatch warning" do
    Canonicity::Publication.new(run: @run).call
    dependency = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@first, @second],
      measures: {@first.id => 200.0, @second.id => 100.0},
      version: "0.7.1"
    )
    works = Work.order(:id).to_a
    measures = works.each_with_object({}) { |work, result| result[work.id] = 10.0 }
    work_run = create_completed_metric_run(
      subject_type: "Work", shadows: works, measures: measures, input_run: dependency
    )

    output = run_task("publish", "Work", work_run.version)

    assert_includes output, "WARNING: Work run depends on Philosopher run 0.7.1"
    assert_includes output, "currently published Philosopher run 0.7.0"
    assert_includes output, "Published Work run #{work_run.version}"
    assert_equal work_run, Publication.current_for("Work").metric_run
  end

  private

  def run_task(name, *arguments)
    task = Rake::Task["metric:#{name}"]
    task.reenable
    capture_io { task.invoke(*arguments) }.first
  end
end

require "test_helper"
require "rake"
require "minitest/mock"
require "tmpdir"
require_relative "../support/rake_task_testing"

class ShadowRakeTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting
  # Create our own test data to avoid fixture conflicts
  # Fixtures are loaded but we use high entity_ids (> 9000) to avoid conflicts

  def setup
    # Clean up any existing test data (9100-9199 range for this test file)
    philosophers_to_cleanup = Philosopher.where("entity_id >= 9100 AND entity_id < 9200")
    MetricSnapshot.where(shadow_id: philosophers_to_cleanup.pluck(:id), shadow_type: "Philosopher").delete_all
    philosophers_to_cleanup.delete_all

    # Ensure we have the algorithm weights for testing
    unless CanonicityWeights.exists?(algorithm_version: "2.1")
      seed_canonicity_weights
    end

    # Load rake tasks
    use_rake_tasks(Rails.root.join("lib/tasks/shadow.rake"))
  end

  def teardown
    # Clean up test data (9100-9199 range for this test file)
    philosophers_to_cleanup = Philosopher.where("entity_id >= 9100 AND entity_id < 9200")
    MetricSnapshot.where(shadow_id: philosophers_to_cleanup.pluck(:id), shadow_type: "Philosopher").delete_all
    philosophers_to_cleanup.delete_all
  ensure
    restore_rake_tasks
  end

  test "shadow:metric task calculates canonicity for test philosophers" do
    high = Philosopher.create!(entity_id: 9100, mention: 200, danker: 0.8,
      stanford: true, cambridge: true, routledge: true, oxford3: true)
    low = Philosopher.create!(entity_id: 9101, mention: 50, danker: 0.2,
      stanford: false, cambridge: false, routledge: false, oxford3: false)
    ids = [high.id, low.id]
    task = Rake::Task["shadow:philosopher:metric"]
    task.reenable

    capture_io { task.invoke }

    run = MetricRun.order(:id).last
    assert run.completed?
    snapshots = run.metric_snapshots.where(shadow_id: ids, shadow_type: "Philosopher")
    assert_equal ids.sort, snapshots.pluck(:shadow_id).sort
    assert_operator snapshots.find_by(shadow_id: high.id).measure, :>, snapshots.find_by(shadow_id: low.id).measure
  ensure
    task&.reenable
  end

  test "danker imports update current values and source events without snapshots" do
    test_phil = Philosopher.create!(entity_id: 9102, mention: 100, danker: 0.5)
    file = Tempfile.new(["danker", ".csv"], Rails.root.join("tmp").to_s)
    file.write("Q9102,0.75\n")
    file.close

    Canonicity::DankerImport.new(file.path, subject_type: "Philosopher", source_version: "2024-10-04").call

    assert_equal 0.75, test_phil.reload.danker
    event = SourceEvent.find_by!(shadow_id: test_phil.id, attribute_name: "danker")
    assert_equal 0.5, event.old_value
    assert_equal 0.75, event.new_value
    assert_equal "2024-10-04", event.source_version
    assert_empty test_phil.metric_snapshots
  ensure
    file&.unlink
  end

  private

  def seed_canonicity_weights
    weights_v2 = [
      {source_name: "runes", weight_value: nil, description: "Runes (inactive legacy source)", active: false},
      {source_name: "inphobool", weight_value: 0.10, description: "Internet Encyclopedia of Philosophy"},
      {source_name: "borchert", weight_value: 0.17, description: "Macmillan Encyclopedia (Borchert)"},
      {source_name: "internet", weight_value: 0.03, description: "Internet sources"},
      {source_name: "cambridge", weight_value: 0.13, description: "Cambridge Dictionary of Philosophy"},
      {source_name: "kemerling", weight_value: 0.07, description: "Kemerling Philosophy Pages"},
      {source_name: "populate", weight_value: 0.01, description: "Wikipedia (as philosopher)"},
      {source_name: "oxford2", weight_value: nil, description: "Oxford Dictionary of Philosophy, 2nd ed. (inactive legacy source)", active: false},
      {source_name: "oxford3", weight_value: 0.13, description: "Oxford Dictionary of Philosophy, 3rd ed."},
      {source_name: "routledge", weight_value: 0.17, description: "Routledge Encyclopedia of Philosophy"},
      {source_name: "dbpedia", weight_value: 0.01, description: "DBpedia (as philosopher)"},
      {source_name: "stanford", weight_value: 0.10, description: "Stanford Encyclopedia of Philosophy"},
      {source_name: "all_bonus", weight_value: 0.08, description: "Bonus for having any authoritative sources"}
    ]

    weights_v2.each do |weight|
      CanonicityWeights.create!(
        algorithm_version: "2.1",
        source_name: weight[:source_name],
        weight_value: weight[:weight_value],
        description: weight[:description],
        active: weight.fetch(:active, true)
      )
    end
  end

  def capture_io
    old_stdout, old_stderr = $stdout, $stderr
    $stdout, $stderr = StringIO.new, StringIO.new
    yield
    [$stdout.string, $stderr.string]
  ensure
    $stdout, $stderr = old_stdout, old_stderr
  end
end

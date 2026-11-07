require 'test_helper'
require 'rake'
require_relative '../support/rake_task_testing'

class NamesRakeTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting
  def setup
    use_rake_tasks(Rails.root.join('lib/tasks/names.rake'))

    # Create test philosophers with names (entity_ids 9200-9299 for this test)
    @phil1 = create_test_philosopher(entity_id: 9200, mention: 10)
    @phil2 = create_test_philosopher(entity_id: 9201, mention: 5)

    Name.create!(shadow_id: @phil1.id, label: 'Socrates', lang: 'en')
    Name.create!(shadow_id: @phil1.id, label: 'Σωκράτης', lang: 'el')
    Name.create!(shadow_id: @phil2.id, label: 'René Descartes', lang: 'en')
    Name.create!(shadow_id: @phil2.id, label: 'René Descartes', lang: 'fr')
  end

  def teardown
    Name.where(shadow_id: [@phil1&.id, @phil2&.id].compact).delete_all
    Philosopher.where("entity_id >= 9200 AND entity_id < 9300").each do |p|
      p.attrs.delete if p.attrs
      p.delete
    end
  ensure
    restore_rake_tasks
  end

  test "names:demo greets anto specially" do
    Rake::Task['names:demo'].reenable
    output = capture_io { Rake::Task['names:demo'].invoke('anto') }
    assert_includes output[0], 'Oh hai Anto!'
  end

  test "names:demo greets other names generically" do
    Rake::Task['names:demo'].reenable
    output = capture_io { Rake::Task['names:demo'].invoke('world') }
    assert_includes output[0], 'Hello world'
  end

  test "names:languages reports language counts for philosophers" do
    Rake::Task['names:languages'].reenable
    output = capture_io { Rake::Task['names:languages'].invoke }
    assert_includes output[0], 'Philosophical Figures'
    assert_includes output[0], 'And Their Works'
  end

  test "names:funny reports non-ASCII characters in English names" do
    Rake::Task['names:funny'].reenable
    output = capture_io { Rake::Task['names:funny'].invoke }
    # René has an accent — should be flagged
    assert_includes output[0], 'René Descartes'
  end

  private

  def capture_io
    old_stdout, old_stderr = $stdout, $stderr
    $stdout, $stderr = StringIO.new, StringIO.new
    yield
    [$stdout.string, $stderr.string]
  ensure
    $stdout, $stderr = old_stdout, old_stderr
  end
end

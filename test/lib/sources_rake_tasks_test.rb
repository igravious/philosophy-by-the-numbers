require 'test_helper'
require 'rake'

class SourcesRakeTasksTest < ActiveSupport::TestCase
  def setup
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test "sources:report runs without error on fixture data" do
    Rake::Task['sources:report'].reenable
    output = capture_io { Rake::Task['sources:report'].invoke }
    # Task prints an array of unique URL patterns
    assert_kind_of String, output[0]
  end

  test "sources:clear recognises pdf type without error" do
    Rake::Task['sources:clear'].reenable
    output = capture_io { Rake::Task['sources:clear'].invoke('pdf') }
  end

  test "sources:clear recognises html type without error" do
    Rake::Task['sources:clear'].reenable
    output = capture_io { Rake::Task['sources:clear'].invoke('html') }
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

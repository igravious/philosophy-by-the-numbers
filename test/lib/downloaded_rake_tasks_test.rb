require 'test_helper'
require 'rake'

class DownloadedRakeTasksTest < ActiveSupport::TestCase
  def setup
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test "downloaded:report counts cached vs uncached fyles" do
    # Ensure we have known fixture data
    cached_count = Fyle.where.not(cache_file: [nil, '']).count
    uncached_count = Fyle.where(cache_file: [nil, '']).count

    Rake::Task['downloaded:report'].reenable
    output = capture_io { Rake::Task['downloaded:report'].invoke }

    assert_includes output[0], "cached: #{cached_count}"
    assert_includes output[0], "not cached: #{uncached_count}"
  end

  test "downloaded:uncached lists files without cache" do
    uncached_count = Fyle.where(cache_file: [nil, '']).count

    Rake::Task['downloaded:uncached'].reenable
    output = capture_io { Rake::Task['downloaded:uncached'].invoke }

    assert_includes output[0], "Found #{uncached_count} uncached files:"
  end

  test "downloaded:clear recognises pdf type without error" do
    Rake::Task['downloaded:clear'].reenable
    output = capture_io { Rake::Task['downloaded:clear'].invoke('pdf') }
    # Task iterates fyles and prints matches — should not raise
  end

  test "downloaded:clear recognises text type without error" do
    Rake::Task['downloaded:clear'].reenable
    output = capture_io { Rake::Task['downloaded:clear'].invoke('text') }
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

require 'test_helper'
require 'rake'
require 'tempfile'

class ReferenceRakeTasksTest < ActiveSupport::TestCase
  fixtures :dictionaries

  def setup
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test "reference:load creates units from file for matching dictionary" do
    # Fixture dictionary 'one' has URI http://example.com/dict1
    # find_dictionary_by_domain_name splits on '/' and matches [2] = "example.com"
    dict = dictionaries(:one)

    # Clean out any existing units for this dictionary
    Unit.where(dictionary_id: dict.id).delete_all

    # Create a temp file with dictionary entries
    tmpfile = Tempfile.new(['reference_test', '.txt'])
    tmpfile.puts "adiaphora"
    tmpfile.puts "epistemology"
    tmpfile.puts "metaphysics"
    tmpfile.close

    Rake::Task['reference:load'].reenable
    capture_io do
      Rake::Task['reference:load'].invoke(tmpfile.path, 'example.com')
    end

    units = Unit.where(dictionary_id: dict.id)
    assert_equal 3, units.count, "Should create 3 units"
    assert_includes units.pluck(:entry), 'adiaphora'
    assert_includes units.pluck(:entry), 'epistemology'
    assert_includes units.pluck(:entry), 'metaphysics'
  ensure
    tmpfile&.unlink
    Unit.where(dictionary_id: dict.id).delete_all
  end

  test "reference:load does nothing for unrecognised domain" do
    initial_count = Unit.count

    tmpfile = Tempfile.new(['reference_test', '.txt'])
    tmpfile.puts "test_entry"
    tmpfile.close

    Rake::Task['reference:load'].reenable
    capture_io do
      Rake::Task['reference:load'].invoke(tmpfile.path, 'nonexistent.example.org')
    end

    assert_equal initial_count, Unit.count, "Should not create any units"
  ensure
    tmpfile&.unlink
  end

  test "reference:load replaces existing units for same dictionary" do
    dict = dictionaries(:one)
    Unit.where(dictionary_id: dict.id).delete_all

    # First load
    tmpfile1 = Tempfile.new(['reference_test1', '.txt'])
    tmpfile1.puts "old_entry_1"
    tmpfile1.puts "old_entry_2"
    tmpfile1.close

    Rake::Task['reference:load'].reenable
    capture_io do
      Rake::Task['reference:load'].invoke(tmpfile1.path, 'example.com')
    end
    assert_equal 2, Unit.where(dictionary_id: dict.id).count

    # Second load should replace
    tmpfile2 = Tempfile.new(['reference_test2', '.txt'])
    tmpfile2.puts "new_entry_1"
    tmpfile2.close

    Rake::Task['reference:load'].reenable
    capture_io do
      Rake::Task['reference:load'].invoke(tmpfile2.path, 'example.com')
    end

    units = Unit.where(dictionary_id: dict.id)
    assert_equal 1, units.count, "Should have replaced old entries"
    assert_equal 'new_entry_1', units.first.entry
  ensure
    tmpfile1&.unlink
    tmpfile2&.unlink
    Unit.where(dictionary_id: dict.id).delete_all
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

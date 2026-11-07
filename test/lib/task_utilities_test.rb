require "test_helper"
require "minitest/mock"
require "progress_bar"
require_relative "../../lib/tasks/utilities"

class TaskUtilitiesTest < ActiveSupport::TestCase
  setup do
    @helper = Object.new.extend(TaskUtilities)
  end

  test "error reports retain the caller backtrace while omitting internal logging frames" do
    error = IOError.new("failed operation")
    error.set_backtrace(["lib/tasks/utilities.rb:30:in barf", "app/application.rb:42:in import"])
    output = capture_subprocess_io { TaskUtilities.instance_method(:barf).bind(@helper).call(error, "Import") }.last

    assert_includes output, "Import: #<IOError: failed operation>"
    assert_includes output, "app/application.rb:42"
    refute_includes output, "lib/tasks/utilities.rb:30"
  end

  test "progress bars increment when the terminal adapter is available" do
    bar = Struct.new(:count) do
      def increment!
        self.count += 1
      end
    end.new(0)
    @helper.stub(:system, false) do
      ProgressBar.stub(:new, ->(total, *_) {
                               assert_equal 3, total
                               bar
                             }) do
        actual = @helper.progress_bar(3)
        assert_same bar, actual
        assert @helper.update_progress(actual)
      end
    end
    assert_equal 1, bar.count
  end

  test "text progress tracks counts and supports an optional operation label" do
    @helper.stub(:system, true) do
      assert_nil @helper.progress_bar(2)
      output = capture_subprocess_io do
        @helper.update_progress(nil)
        @helper.update_progress(nil, "Metadata")
      end.last
      assert_includes output, "Processing 1 of 2"
      assert_includes output, "Metadata – processing 2 of 2"
    end
  end

  test "development progress displays both terminal and text startup messages" do
    environment = ActiveSupport::StringInquirer.new("development")
    Rails.stub(:env, environment) do
      @helper.stub(:system, true) do
        assert_includes capture_io { @helper.progress_bar(2, false, "figures", "with metadata") }.first, "About to process 2 figures with metadata"
        ProgressBar.stub(:new, Object.new) do
          assert_includes capture_subprocess_io { @helper.progress_bar(2, true, "works") }.last, "About to process 2 works"
        end
      end
    end
  end
end

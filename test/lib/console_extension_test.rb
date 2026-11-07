require "test_helper"
require "minitest/mock"
require_relative "../../lib/console_extension"

class ConsoleExtensionTest < ActiveSupport::TestCase
  test "console startup initialises STI classes and establishes the connection" do
    refute ConsoleExtension::ConsoleRunner.new.start_up
    assert Shadow.descendants.include?(Philosopher)
    assert Shadow.descendants.include?(Work)
  end

  test "including the console methods triggers startup" do
    runner = Minitest::Mock.new
    runner.expect(:start_up, nil)
    extension = Module.new.extend(ConsoleExtension::ConsoleMethods)

    ConsoleExtension::ConsoleRunner.stub(:new, runner) { Class.new.include(extension) }

    runner.verify
  end
end

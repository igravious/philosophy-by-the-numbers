require "test_helper"
require "minitest/mock"
require "stringio"
require "tilt"
require_relative "../support/loaded_helpers"

class TexifyTest < ActiveSupport::TestCase
  include LoadedHelpers
  test "renders both delivery templates and returns the typesetting command result" do
    helper = load_helpers("lib/texify.rb")
    outputs = {}
    template = Object.new
    template.define_singleton_method(:render) { |context| "Delivery: #{context.instance_variable_get(:@delivery)}" }
    open_file = ->(path, mode) {
      assert_equal "w", mode
      outputs[path] = StringIO.new
    }
    directories = []
    original_path = ENV["PATH"]
    commands = []

    [true, false].each do |success|
      helper.stub(:system, ->(command) {
                             commands << command
                             success
                           }) do
        Tilt.stub(:new, template) do
          File.stub(:new, open_file) do
            Dir.stub(:chdir, ->(path) { directories << path }) do
              assert_equal success, helper.texify("test delivery")
            end
          end
        end
      end
    end

    assert_equal 2, outputs.size
    outputs.each_value { |output| assert_equal "Delivery: test delivery", output.string }
    assert_equal ["/home/anthony/LaTeX", Dir.pwd] * 2, directories
    assert commands.all? { |command| command.start_with?("make -f ") }
  ensure
    ENV["PATH"] = original_path
  end
end

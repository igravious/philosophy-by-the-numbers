require "test_helper"
require "minitest/mock"
require "tmpdir"
require "rake"
require_relative "../../lib/corpus_cli/cli"
require_relative "../support/kernel_methods"
require_relative "../support/script_runner"

class EntrypointsTest < ActiveSupport::TestCase
  include KernelMethods
  include ScriptRunner
  test "setup runs dependency database cleanup and restart commands in the project directory" do
    calls = []
    replacement = ->(command) {
      calls << [Dir.pwd, command]
      true
    }
    with_kernel_method(:system, replacement) do
      capture_io { load Rails.root.join("bin/setup"), true }
    end
    assert_equal [Rails.root.to_s], calls.map(&:first).uniq
    assert_equal ["gem install bundler --conservative", "bundle check || bundle install", "bin/rake db:setup",
      "rm -f log/*", "rm -rf tmp/cache", "touch tmp/restart.txt"], calls.map(&:last)
  end

  test "Bundler entrypoint loads the executable selected by RubyGems" do
    Dir.mktmpdir do |directory|
      executable = File.join(directory, "bundle.rb")
      File.write(executable, 'puts "Selected Bundler executable"')
      Gem.stub(:bin_path, ->(gem, name) {
                            assert_equal ["bundler", "bundle"], [gem, name]
                            executable
                          }) do
        assert_includes capture_io { load Rails.root.join("bin/bundle"), true }.first, "Selected Bundler executable"
      end
    end
  end

  test "Rake entrypoint delegates to the current Rake application" do
    application = Minitest::Mock.new
    application.expect(:run, true)
    Rake.stub(:application, application) { load Rails.root.join("bin/rake"), true }
    application.verify
  end

  test "Rails entrypoint loads the command dispatcher after boot" do
    requested = []
    original = Kernel.instance_method(:require)
    with_kernel_method(:require, ->(feature) {
                                   requested << feature
                                   (feature == "rails/commands") ? true : original.bind_call(self, feature)
                                 }) do
      load Rails.root.join("bin/rails"), true
    end
    assert_includes requested, "rails/commands"
  end

  test "corpus entrypoint passes command line arguments to the CLI" do
    arguments = ARGV.dup
    ARGV.replace(["workflows", "list"])
    passed = nil
    CorpusCli::CLI.stub(:start, ->(args) { passed = args.dup }) { load Rails.root.join("bin/corpus"), true }
    assert_equal ["workflows", "list"], passed
  ensure
    ARGV.replace(arguments)
  end

  test "Rakefile registers application tasks" do
    calls = 0
    CorpusBuilder::Application.stub(:load_tasks, -> { calls += 1 }) { load Rails.root.join("Rakefile"), true }
    assert_equal 1, calls
  end

  test "Rack entrypoint runs the Rails application and records newly required files once" do
    original_requests = $_REQ
    application = nil
    context = nil
    with_kernel_method(:run, ->(app) {
                               application = app
                               context = self
                             }) do
      load Rails.root.join("config.ru"), true
    end
    assert_same Rails.application, application
    Dir.mktmpdir do |directory|
      feature = File.join(directory, "rack_feature.rb")
      File.write(feature, "42\n")
      context.send(:require, feature)
      context.send(:require, feature)
      assert_equal [feature], $_REQ
    end
    features = ["/opt/gems/rake-10/lib/rake.rb", "/opt/gems/json-2/lib/json.rb", "/opt/gems/rake-10/lib/task.rb", "/project/app/model.rb"]
    wrapper = context.singleton_class.ancestors.find { |ancestor| ancestor.const_defined?(:Kernel, false) }
    assert_equal ["json-2", "rake-10"], wrapper.const_get(:Kernel).required(features)
  ensure
    $_REQ = original_requests
  end

  test "legacy task listing categorizes namespaces and bare commands" do
    listing = "rake db:migrate # Migrate\nrake custom:work # Custom\nrake about # About\n"
    commands = []
    with_kernel_method(:`, ->(command) {
                             commands << command
                             listing
                           }) do
      output = capture_io { load Rails.root.join("scripts/list_and_categorize_rake_tasks.rb"), true }.first
      assert_includes output, "BUILT-IN TASKS (2)"
      assert_includes output, "USER-CREATED TASKS (1)"
      assert_includes output, "SUMMARY: 3 total tasks"
    end
    assert_equal ["bin/rake -T"], commands
  end

  test "terminal diagnostics print the actual terminal-probe result" do
    commands = []
    [true, false].each do |available|
      with_kernel_method(:system, ->(command) { commands << command; available }) do
        assert_equal "#{available}\n", capture_io { load_script(Rails.root.join("scripts/term.rb")) }.first
      end
    end
    assert_equal ["[ -t 1 ]"] * 2, commands
  end
end

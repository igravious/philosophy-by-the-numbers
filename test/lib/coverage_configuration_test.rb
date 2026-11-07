require "test_helper"
require "tmpdir"
require "open3"
require "json"

class CoverageConfigurationTest < ActiveSupport::TestCase
  test "repeated script execution retains the actual coverage from both branches" do
    Dir.mktmpdir do |directory|
      target = File.join(directory, "branches.rb")
      File.write(target, "if ARGV.first == 'first'\n  puts 'first branch'\nelse\n  puts 'second branch'\nend\n")
      output = File.join(directory, "branches.json")
      runner = File.join(directory, "runner.rb")
      File.write(runner, <<~RUBY)
        require "json"
        require #{Rails.root.join("test/support/script_runner.rb").to_s.inspect}
        SimpleCov.root(#{directory.inspect})
        helper = Object.new.extend(ScriptRunner)
        ARGV.replace(["first"])
        helper.load_script(#{target.inspect})
        ARGV.replace(["second"])
        helper.load_script(#{target.inspect})
        file = SimpleCov.result.files.find { |entry| entry.filename == #{target.inspect} }
        File.write(#{output.inspect}, JSON.generate(missed: file.missed_lines.map(&:number)))
      RUBY
      stdout, stderr, = Open3.capture3(Rails.root.join("bin/bundle").to_s, "exec", "ruby",
        Rails.root.join("test/support/subprocess_coverage.rb").to_s, runner, chdir: Rails.root.to_s)
      assert File.file?(output), stderr
      assert_empty JSON.parse(File.read(output)).fetch("missed")
      assert_includes stdout, "first branch"
      assert_includes stdout, "second branch"
    end
  end

  test "isolated Rake task suites preserve coverage across test setup cycles" do
    Dir.mktmpdir do |directory|
      tasks_path = File.join(directory, "sample.rake")
      result_path = File.join(directory, "rake.json")
      File.write(tasks_path, "task :first do\n  puts 'first ran'\nend\ntask :second do\n  puts 'second ran'\nend\n")
      script_path = File.join(directory, "runner.rb")
      File.write(script_path, <<~RUBY)
        require "json"
        require #{Rails.root.join("test/support/rake_task_testing.rb").to_s.inspect}
        helper = Object.new.extend(RakeTaskTesting)
        helper.use_rake_tasks(ARGV.fetch(0))
        first_application = Rake.application
        Rake::Task[:first].invoke
        helper.restore_rake_tasks
        helper.use_rake_tasks(ARGV.fetch(0))
        Rake::Task[:second].invoke
        lines = Coverage.peek_result.fetch(File.expand_path(ARGV.fetch(0)))
        File.write(ARGV.fetch(1), JSON.generate(same_application: first_application.equal?(Rake.application), lines: lines))
      RUBY
      stdout, stderr, = Open3.capture3(Rails.root.join("bin/bundle").to_s, "exec", "ruby",
        Rails.root.join("test/support/subprocess_coverage.rb").to_s,
        script_path, tasks_path, result_path, chdir: Rails.root.to_s)
      assert File.file?(result_path), stderr
      result = JSON.parse(File.read(result_path))
      assert result.fetch("same_application")
      assert result.fetch("lines").compact.all? { |count| count > 0 }
      assert_includes stdout, "first ran"
      assert_includes stdout, "second ran"
    end
  end

  test "subprocess collection preserves exit status and records real application code" do
    Dir.mktmpdir do |directory|
      result_path = File.join(directory, "child.json")
      code = <<~RUBY
        require "json"
        require "active_model"
        require "delivery"
        Delivery.new(identifier: "covered child", location: "test", date: "2026-11-06").consistent
        SimpleCov.at_exit do
          main_lines = Coverage.peek_result[File.expand_path(__FILE__)]
          file = SimpleCov.result.files.find { |entry| entry.filename.end_with?("/lib/delivery.rb") }
          File.write(ARGV.fetch(0), JSON.generate(name: SimpleCov.command_name,
            covered: file.covered_lines.size, minimum: SimpleCov.minimum_coverage,
            main_covered: main_lines && main_lines.compact.any? { |count| count > 0 }))
        end
        exit 7
      RUBY
      script_path = File.join(directory, "child.rb")
      File.write(script_path, code)
      _stdout, stderr, status = Open3.capture3(
        Rails.root.join("bin/bundle").to_s, "exec", "ruby",
        "-I", Rails.root.join("lib").to_s,
        Rails.root.join("test/support/subprocess_coverage.rb").to_s,
        script_path, result_path, chdir: Rails.root.to_s
      )
      assert File.file?(result_path), stderr
      result = JSON.parse(File.read(result_path))
      assert_equal 7, status.exitstatus
      assert_match(/\ASubprocess \d+\z/, result.fetch("name"))
      assert_operator result.fetch("covered"), :>, 0
      assert result.fetch("main_covered")
      assert_equal 0, result.fetch("minimum")
      assert_equal 100, SimpleCov.minimum_coverage if defined?(SimpleCov)
    end
  end

  test "coverage includes unloaded application code and requires every file to reach 100 percent" do
    configuration = Rails.root.join(".simplecov").to_s
    assert File.file?(configuration), "Expected an explicit project coverage configuration"

    Dir.mktmpdir do |directory|
      paths = %w[app/models/p/unloaded.rb lib/unloaded.rb lib/tasks/unloaded.rake scripts/unloaded.rb config/unloaded.rb bin/setup Rakefile config.ru]
      paths.each do |path|
        target = File.join(directory, path)
        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, "class Unloaded; def value; 42; end; end\n")
      end
      code = <<~RUBY
        require "simplecov"
        require "json"
        SimpleCov.root(Dir.pwd)
        load ARGV.fetch(0)
        SimpleCov.at_exit do
          result = SimpleCov.result
          payload = {
            files: result.files.map { |file| [file.filename.delete_prefix(Dir.pwd + "/"), file.missed_lines.size] }.to_h,
            minimum: SimpleCov.minimum_coverage,
            per_file: SimpleCov.minimum_coverage_by_file
          }
          File.write("result.json", JSON.generate(payload))
        end
      RUBY
      _stdout, stderr, = Open3.capture3(
        {"BUNDLE_GEMFILE" => Rails.root.join("Gemfile").to_s},
        Rails.root.join("bin/bundle").to_s, "exec", "ruby", "-e", code, configuration,
        chdir: directory
      )
      result_path = File.join(directory, "result.json")
      assert File.exist?(result_path), stderr
      result = JSON.parse(File.read(result_path))

      paths.each { |path| assert_operator result.fetch("files").fetch(path), :>, 0 }
      assert_equal 100, result.fetch("minimum")
      assert_equal 100, result.fetch("per_file")
    end
  end
end

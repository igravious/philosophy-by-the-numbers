require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../../lib/app_config"

class AppConfigTest < ActiveSupport::TestCase
  setup do
    AppConfig.reload!
  end

  teardown do
    AppConfig.reload!
  end

  test "extracts application constants and caches them until reload" do
    with_configuration("name: CorpusBuilder\ncount: 3") do |path|
      assert_equal({"name" => "CorpusBuilder", "count" => 3}, AppConfig.load_constants)
      assert_equal "CorpusBuilder", AppConfig.get(:name)
      assert_equal :fallback, AppConfig.get(:missing, :fallback)
      File.write(path, "no configuration")
      assert_equal "CorpusBuilder", AppConfig.get("name")
      AppConfig.reload!
      assert_equal :fallback, AppConfig.get(:name, :fallback)
    end
  end

  test "empty and invalid YAML produce an empty configuration" do
    ["", "values: [unterminated"].each do |yaml|
      with_configuration(yaml) { assert_equal({}, AppConfig.load_constants) }
    end
  end

  test "missing config file and absent block produce an empty configuration" do
    Dir.mktmpdir do |directory|
      Rails.stub(:root, Pathname.new(directory)) do
        assert_equal({}, AppConfig.load_constants)
        File.write(File.join(directory, "config.ru"), "run Application")
        assert_equal({}, AppConfig.load_constants)
      end
    end
  end

  private

  def with_configuration(yaml)
    Dir.mktmpdir do |directory|
      path = File.join(directory, "config.ru")
      File.write(path, "=begin\nApp Configuration Constants (YAML format):\n---\n#{yaml}\n=end\n")
      Rails.stub(:root, Pathname.new(directory)) { yield path }
    end
  end
end

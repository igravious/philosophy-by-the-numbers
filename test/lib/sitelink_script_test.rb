require "test_helper"
require "minitest/mock"
require "tmpdir"
require "open-uri"
require_relative "../support/kernel_methods"
require_relative "../support/loaded_helpers"
require_relative "../support/script_runner"

class SitelinkScriptTest < ActiveSupport::TestCase
  include KernelMethods
  include LoadedHelpers
  include ScriptRunner
  Reply = Struct.new(:status, :content) do
    def read
      content
    end
  end

  test "sitelink diagnostics format real plots validate API replies and handle CLI input errors" do
    source = Rails.root.join("scripts/sitelink.rb")
    helper = nil
    with_script_arguments do
      assert_includes capture_subprocess_io { helper = load_helpers("scripts/sitelink.rb") }.last, "arg?"
    end
    reply = Reply.new(["200"], JSON.generate("success" => 1, "message" => "Test metadata"))
    helper.stub(:open, reply) { assert_equal "Test metadata", helper.wiki_info("Q42")["message"] }
    helper.stub(:open, Reply.new(["503"], "offline")) do
      assert_includes assert_raises(RuntimeError) { helper.wiki_info("Q42") }.message, "503"
    end
    helper.stub(:open, Reply.new(["200"], JSON.generate("success" => 0, "error" => "blocked"))) do
      assert_includes assert_raises(RuntimeError) { helper.wiki_info("Q42") }.message, "unsuccessful blocked"
    end

    Dir.mktmpdir do |directory|
      Dir.chdir(directory) { helper.links([2, nil, 1], [8, nil, 2]) }
      rows = File.readlines(File.join(directory, "links.txt")).map(&:split)
      assert_equal [["002", ".", "1", "2.000000"], ["001", ".", "0", "0"], ["000", ".", "2", "4.000000"]], rows

      input = File.join(directory, "input.txt")
      File.write(input, "12138 [001] Q42 | ##| enwiki: (First)\n12139 [001] Q43 | #| enwiki: (Second)\n12140 [003] Q44 | ###| commonswiki: (Third)\n")
      requests = []
      with_kernel_method(:open, ->(url, *_) {
                                  requests << url
                                  reply
                                }) do
        output = with_script_arguments(input) { capture_io { load_script(source) }.first }
        assert_includes output, "commonswiki"
        assert_includes output, "Test metadata"
      end
      assert_equal 1, requests.size
      assert_includes requests.first, "ids=Q44"

      output = with_script_arguments(File.join(directory, "absent.txt")) { capture_subprocess_io { load_script(source) }.last }
      assert_includes output, "file?"
      File.write(input, "Malformed input\n")
      output = with_script_arguments(input) { capture_subprocess_io { load_script(source) }.last }
      assert_includes output, "urk?"
      output = with_script_arguments { capture_subprocess_io { load_script(source) }.last }
      assert_includes output, "arg?"
    end
  end
end

require "test_helper"
require "minitest/mock"
require "socket"
require "digest"
require_relative "../../lib/zotero/client"
require_relative "../support/loaded_helpers"
require_relative "../support/script_runner"

class LegacyMaintenanceScriptsTest < ActiveSupport::TestCase
  include LoadedHelpers
  include ScriptRunner

  test "schema presentation renders highlighted Ruby and its stylesheet" do
    output = capture_io { load_script(Rails.root.join("scripts/prep_schema.rb")) }.first
    assert_includes output, "<style>"
    assert_includes output, "<pre class='highlight'>"
    assert_includes output, "ActiveRecord"
    assert_includes output, "shadows"
  end

  test "labeling inspection groups repeated tag and text identifiers" do
    Labeling.stub(:all, Labeling.where(id: labelings(:one).id)) do
      output = capture_io { load_script(Rails.root.join("scripts/compress_array.rb")) }.first
      assert_includes output, labelings(:one).tag_id.to_s
      assert_includes output, labelings(:one).text_id.to_s
    end
    relation = Object.new
    relation.define_singleton_method(:pluck) { |*_| [[1, 2], [1, 3], [4, 2]] }
    Labeling.stub(:all, relation) do
      output = capture_io { load_script(Rails.root.join("scripts/compress_array.rb")) }.first
      assert_includes output, "{1=>[2, 3], 4=>[2]}"
      assert_includes output, "{2=>[1, 4], 3=>[1]}"
    end
  end

  test "memcache inventory parses slab contents and closes its connection" do
    client = Minitest::Mock.new
    client.expect(:write, 13, ["stats items\r\n"])
    ["STAT items:1:number 2\r\n", "END\r\n"].each { |line| client.expect(:gets, line) }
    client.expect(:write, 20, ["stats cachedump 1 2\r\n"])
    ["ITEM philosopher,Plato [24 b; 100 s]\n", "ITEM philosopher,Aristotle [48 b; 200 s]\n", "END\r\n"].each { |line| client.expect(:gets, line) }
    client.expect(:close, nil)
    TCPSocket.stub(:new, client) do
      output = capture_io { load_script(Rails.root.join("scripts/ls_memcache.rb")) }.first
      assert_includes output, "philosopher,Plato"
      assert_includes output, "philosopher,Aristotle"
      assert_includes output, "cache_key"
    end
    client.verify
  end

  test "file health update hashes content skips absent caches and continues after errors" do
    files = 3.times.map { Fyle.create!(what: "Health Check") }
    files[0].define_singleton_method(:snarf) { "Philosophical text" }
    files[1].define_singleton_method(:snarf) { "#<RuntimeError: Not cached!>" }
    files[2].define_singleton_method(:snarf) { raise IOError, "unreadable cache" }
    Fyle.stub(:all, files) { capture_io { load_script(Rails.root.join("scripts/set_health.rb")) } }
    assert_equal Digest::SHA256.hexdigest("Philosophical text"), files[0].reload.health_hash
    assert_nil files[1].reload.health_hash
    assert_nil files[2].reload.health_hash
  end

  test "Zotero script delegates live work to the client boundary" do
    calls = 0
    Zotero.stub(:sync_report, -> { calls += 1 }) { load_script(Rails.root.join("lib/zotero.rb")) }
    assert_equal 1, calls
  end

  test "sample delivery sends the configured delivery to the renderer" do
    helper = load_helpers("lib/test_delivery.rb")
    rendered = nil
    helper.define_singleton_method(:texify) { |delivery|
      rendered = delivery
      :rendered
    }
    assert_equal :rendered, helper.test_delivery
    assert_equal "Test Delivery", rendered.identifier
    assert_equal "Utopia", rendered.location
    assert_equal 13, rendered.numbered
    assert_equal 256, rendered.amount
  end
end

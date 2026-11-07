require "test_helper"
require "tmpdir"
require_relative "../../scripts/zotero_singleton_ids"

class ZoteroSingletonIdsTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir
    @path = File.join(@directory, "singleton-ids.json")
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "allocates stable IDs and retains dormant mappings" do
    ids = ZoteroSingletonIds.reconcile(@path, %w[A B], ["EP-027"])
    assert_equal({"A" => "EP-028", "B" => "EP-029"}, ids)

    original = File.read(@path)
    assert_equal ids, ZoteroSingletonIds.reconcile(@path, %w[B A], ["EP-027"])
    assert_equal original, File.read(@path)

    ZoteroSingletonIds.reconcile(@path, [], ["EP-027"])
    assert_equal original, File.read(@path)
    assert_equal ids, ZoteroSingletonIds.reconcile(@path, %w[A], ["EP-027"])
    assert_equal original, File.read(@path)
  end

  test "never reuses active retired or dormant IDs" do
    ZoteroSingletonIds.reconcile(@path, ["A"], ["EP-027", "EP-140"])
    assert_equal({"A" => "EP-141"}, ZoteroSingletonIds.reconcile(@path, ["A"], ["EP-027"]))
    assert_equal "EP-142", ZoteroSingletonIds.reconcile(@path, ["B"], ["EP-027"])["B"]
  end

  test "rejects duplicate keys and IDs" do
    File.write(@path, JSON.generate([
      {"key" => "A", "id" => "EP-028"},
      {"key" => "A", "id" => "EP-029"}
    ]))
    assert_raises(RuntimeError) { ZoteroSingletonIds.load(@path) }

    File.write(@path, JSON.generate([
      {"key" => "A", "id" => "EP-028"},
      {"key" => "B", "id" => "EP-028"}
    ]))
    assert_raises(RuntimeError) { ZoteroSingletonIds.load(@path) }
  end

  test "rejects collisions with previously assigned IDs" do
    File.write(@path, JSON.generate([{"key" => "A", "id" => "EP-027"}]))
    error = assert_raises(RuntimeError) { ZoteroSingletonIds.reconcile(@path, ["A"], ["EP-027"]) }
    assert_match(/collide/, error.message)
  end

  test "supports allocation beyond EP 999" do
    assert_equal({"A" => "EP-1000"}, ZoteroSingletonIds.reconcile(@path, ["A"], ["EP-999"]))
    assert_equal [{"key" => "A", "id" => "EP-1000"}], ZoteroSingletonIds.load(@path)
  end
end

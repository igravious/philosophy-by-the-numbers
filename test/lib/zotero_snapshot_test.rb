require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../../scripts/zotero_snapshot"

class ZoteroSnapshotTest < ActiveSupport::TestCase
  Response = Struct.new(:status, :body, :headers) do
    def success?
      status == 200
    end
  end

  setup do
    @directory = Dir.mktmpdir("zotero-snapshot-")
    @constants = {}
    {DUMP_DIR: @directory, BASELINE_FILE: File.join(@directory, "baseline.json")}.each do |name, value|
      @constants[name] = ZoteroSnapshot.const_get(name)
      ZoteroSnapshot.send(:remove_const, name)
      ZoteroSnapshot.const_set(name, value)
    end
    @credentials = %w[ZOTERO_USER_ID ZOTERO_API_KEY].map { |key| [key, ENV[key]] }.to_h
    ENV["ZOTERO_USER_ID"] = "42"
    ENV["ZOTERO_API_KEY"] = "test-key"
    @versions = [12, 12]
    @items = [item("A", "book", "collections" => [ZoteroSnapshot::ROOT_KEY, "LEAF"]),
      item("B", "book", "collections" => [ZoteroSnapshot::ROOT_KEY]),
      item("C", "attachment", "parentItem" => "A"), item("D", "note", "title" => "", "note" => "<p>A note</p>"),
      item("E", "attachment", "parentItem" => "MISSING")]
    File.write(ZoteroSnapshot::BASELINE_FILE, JSON.generate([@items.first, item("REMOVED", "book")]))
    @requests = []
    handler = method(:response_for)
    @connection = Object.new
    @connection.define_singleton_method(:get) { |path| handler.call(path) }
  end

  teardown do
    @credentials.each { |key, value| ENV[key] = value }
    @constants.each do |name, value|
      ZoteroSnapshot.send(:remove_const, name)
      ZoteroSnapshot.const_set(name, value)
    end
    FileUtils.remove_entry(@directory)
  end

  test "snapshot walks and deduplicates collection contents and records verification evidence" do
    output = run_snapshot
    path = Dir.glob(File.join(@directory, "snapshot-*.json")).fetch(0)
    snapshot = JSON.parse(File.read(path))
    metadata = snapshot.fetch("metadata")

    assert_equal %w[A B C D E], snapshot.fetch("items").map { |entry| entry["key"] }
    assert_equal 5, metadata["counts"]["duplicates_dropped"]
    assert_equal 10, metadata["counts"]["listings_seen"]
    assert metadata["verification"]["version_stability"]["stable"]
    assert metadata["verification"]["object_accounting"]["balanced"]
    assert_equal 1, metadata["verification"]["membership_invariant"]["exception_count"]
    integrity = metadata["verification"]["child_parent_integrity"]
    assert_equal 1, integrity["resolved"]
    assert_equal 1, integrity["orphans"]["standalone_count"]
    assert_equal 1, integrity["orphans"]["broken_ref_count"]
    assert_includes output, "REMOVED"
    assert_includes output, Digest::SHA256.file(path).hexdigest
    assert @requests.all? { |path| path.start_with?("/users/42/collections/") }
  end

  test "a changed library version discards its first traversal and retries" do
    @versions = [10, 11, 12, 12]
    delays = []
    ZoteroSnapshot.stub(:sleep, ->(seconds) { delays << seconds }) { run_snapshot }
    snapshot = JSON.parse(File.read(Dir.glob(File.join(@directory, "snapshot-*.json")).first))
    assert_equal 2, snapshot["metadata"]["verification"]["version_stability"]["attempts"]
    assert_equal [2], delays
    assert_equal 5, snapshot["items"].length
  end

  test "repeated version changes abort without writing a snapshot" do
    @versions = [1, 2, 3, 4, 5, 6]
    ZoteroSnapshot.stub(:sleep, nil) do
      assert_equal 1, assert_raises(SystemExit) { run_snapshot }.status
    end
    assert_empty Dir.glob(File.join(@directory, "snapshot-*.json"))
  end

  test "missing credentials and missing root collections abort before writing" do
    ENV["ZOTERO_API_KEY"] = ""
    assert_equal 1, assert_raises(SystemExit) { run_snapshot }.status
    ENV["ZOTERO_API_KEY"] = "test-key"
    @missing_root = true
    assert_equal 1, assert_raises(SystemExit) { run_snapshot }.status
    assert_empty Dir.glob(File.join(@directory, "snapshot-*.json"))
  end

  test "library version requests reject HTTP failures and missing consistency headers" do
    [Response.new(503, "offline", {}), Response.new(200, "[]", {})].each do |response|
      @connection.stub(:get, response) do
        assert_raises(RuntimeError) { ZoteroSnapshot.library_version(@connection, "/collections") }
      end
    end
  end

  test "missing baselines are recorded without preventing the snapshot" do
    FileUtils.rm(ZoteroSnapshot::BASELINE_FILE)
    assert_includes run_snapshot, "UNAVAILABLE"
  end

  test "report labels normalize note markup and truncate long item lists" do
    assert_equal "(note) A note", ZoteroSnapshot.label(@items[3])
    assert_equal "(untitled attachment)", ZoteroSnapshot.label(item("X", "attachment", "title" => ""))
    label = ZoteroSnapshot.label(item("X", "book", "title" => "x" * 80))
    assert_equal 60, label.length
    assert label.end_with?("…")
    assert_equal "-2", ZoteroSnapshot.fmt_diff(-2)
    output = capture_io { ZoteroSnapshot.print_key_list("added", 31.times.map { |i| {"key" => i, "title" => "title"} }) }.first
    assert_includes output, "1 more"
  end

  private

  def item(key, type, attributes = {})
    {"key" => key, "data" => {"itemType" => type, "title" => "Title #{key}"}.merge(attributes)}
  end

  def run_snapshot
    Zotero.stub(:load_env_file, nil) do
      Zotero.stub(:connection, @connection) { capture_io { ZoteroSnapshot.run }.first }
    end
  end

  def response_for(path)
    @requests << path
    if path.include?("/collections/top?")
      version = @versions.shift || 12
      collections = @missing_root ? [] : [{"key" => ZoteroSnapshot::ROOT_KEY, "data" => {"name" => "Emerging philosophy"}}]
      return Response.new(200, JSON.generate(collections), {"Last-Modified-Version" => version.to_s})
    end
    body = if path.include?("/items?")
      @items
    elsif path.include?("/#{ZoteroSnapshot::ROOT_KEY}/collections?")
      [{"key" => "LEAF", "data" => {"name" => "2020s"}}]
    elsif path.include?("/LEAF/collections?")
      []
    else
      raise "Unexpected request #{path}"
    end
    Response.new(200, JSON.generate(body), {})
  end
end

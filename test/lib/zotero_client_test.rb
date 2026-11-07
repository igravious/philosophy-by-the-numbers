require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../../lib/zotero/client"

class ZoteroClientTest < ActiveSupport::TestCase
  Response = Struct.new(:status, :body, :headers) do
    def success?
      status == 200
    end
  end

  test "environment loader ignores comments and malformed lines and preserves existing values" do
    keys = %w[CORPUS_TEST_ENV_ONE CORPUS_TEST_ENV_TWO CORPUS_TEST_ENV_THREE]
    original = keys.map { |key| [key, ENV[key]] }.to_h
    keys.each { |key| ENV.delete(key) }
    ENV[keys.first] = "existing"
    Dir.mktmpdir do |directory|
      path = File.join(directory, ".env")
      File.write(path, "# comment\n\ninvalid line\nCORPUS_TEST_ENV_ONE=replaced\nCORPUS_TEST_ENV_TWO='two words'\nCORPUS_TEST_ENV_THREE=\"three\"\n")
      Zotero.load_env_file(path)
      assert_equal ["existing", "two words", "three"], keys.map { |key| ENV[key] }
      assert_nil Zotero.load_env_file(File.join(directory, "absent"))
    end
  ensure
    original.each { |key, value| ENV[key] = value }
  end

  test "credential and connection boundaries use configured API credentials" do
    SecurityConfig.stub(:load_credential, ->(name) { (name == "ZOTERO_USER_ID") ? "42" : "test-key" }) do
      assert_equal({user_id: "42", api_key: "test-key"}, Zotero.credentials)
    end
    connection = Zotero.connection("test-key")
    assert_equal "Bearer test-key", connection.headers["Authorization"]
    assert_equal "3", connection.headers["Zotero-API-Version"]
    assert_equal "https://api.zotero.org/", connection.url_prefix.to_s
  end

  test "pagination follows next links and collection matching ignores case" do
    paths = []
    pages = [Response.new(200, "[]", {"link" => '<https://api.zotero.org/next>; rel="next"'}),
      Response.new(200, JSON.generate([{key: "ROOT", data: {name: "Emerging Philosophy"}}]), {})]
    connection = Object.new
    connection.define_singleton_method(:get) { |path|
      paths << path
      pages.shift
    }
    assert_equal "ROOT", Zotero.find_collection(connection, "42", "emerging philosophy")["key"]
    assert_equal ["/users/42/collections/top?limit=100", "https://api.zotero.org/next"], paths
    connection.define_singleton_method(:get) { |_| Response.new(503, "offline", {}) }
    assert_raises(RuntimeError) { Zotero.paged_get(connection, "/items") { flunk "Failed responses must not be yielded" } }
  end

  test "sync deduplicates collection listings and compares corpus and Zotero URL sets" do
    files = 3.times.map { |index| Fyle.create!(URL: "https://corpus.test/#{index}") }
    root = {"key" => "ROOT", "data" => {"name" => "Emerging Philosophy"}}
    items = [{"key" => "A", "data" => {"itemType" => "book", "url" => files[0].URL}},
      {"key" => "B", "data" => {"itemType" => "book", "url" => files[1].URL}},
      {"key" => "C", "data" => {"itemType" => "book", "url" => "https://new.test/book"}, "bib" => "New Book"},
      {"key" => "D", "data" => {"itemType" => "note"}, "bib" => "A note"},
      {"key" => "E", "data" => {"itemType" => "attachment"}}]
    pages = ->(*_, &block) {
      block.call(items)
      block.call([items.first])
    }
    [1, 2, 3].each do |linked_count|
      relation = Fyle.where(id: files.take(linked_count).map(&:id))
      comparison = ["corpus < zotero", "Same quantity", "corpus > zotero"][linked_count - 1]
      Zotero.stub(:load_env_file, nil) do
        Zotero.stub(:credentials, {user_id: "42", api_key: "test-key"}) do
          Zotero.stub(:connection, Object.new) do
            Zotero.stub(:find_collection, root) do
              Zotero.stub(:each_items_page, pages) do
                Fyle.stub(:linked, relation) do
                  output = capture_io { Zotero.sync_report("Emerging Philosophy") }.first
                  assert_includes output, "4 non-attachment items"
                  assert_includes output, "1 without URL, 2 already in corpus"
                  assert_includes output, "https://new.test/book"
                  assert_includes output, comparison
                end
              end
            end
          end
        end
      end
    end
  end

  test "sync fails explicitly when the selected collection does not exist" do
    Zotero.stub(:load_env_file, nil) do
      Zotero.stub(:credentials, {user_id: "42", api_key: "test-key"}) do
        Zotero.stub(:connection, Object.new) do
          Zotero.stub(:find_collection, nil) do
            assert_includes assert_raises(RuntimeError) { Zotero.sync_report("Missing") }.message, "not found"
          end
        end
      end
    end
  end
end

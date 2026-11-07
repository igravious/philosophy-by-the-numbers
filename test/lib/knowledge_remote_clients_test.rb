require "test_helper"
require "minitest/mock"
require "knowledge"
require "dalli"
require "sparql/client"

class KnowledgeRemoteClientsTest < ActiveSupport::TestCase
  Reply = Struct.new(:status, :content) do
    def read
      content
    end
  end

  Cache = Struct.new(:value, :writes) do
    def get(_key)
      value
    end

    def set(key, result)
      writes << [key, result]
      true
    end
  end

  test "DBpedia cached classifications return the cached result" do
    cache = Cache.new(["cached"], [])
    Dalli::Client.stub(:new, cache) do
      assert_equal ["cached"], Knowledge::DBpedia.is_a_person?("Plato")
      assert_equal ["cached"], Knowledge::DBpedia.is_a_philosopher?("Plato")
    end
    assert_empty cache.writes
  end

  test "DBpedia cache misses execute and store the subject query" do
    cache = Cache.new(nil, [])
    Knowledge::DBpedia.stub(:is_in_a_specific_subject?, ->(subject, name) { [subject, name] }) do
      Dalli::Client.stub(:new, cache) do
        assert_equal ["people", "Plato"], Knowledge::DBpedia.is_a_person?("Plato")
        assert_equal ["philosophers", "Plato"], Knowledge::DBpedia.is_a_philosopher?("Plato")
      end
    end
    assert_equal ["people,Plato", "philosophers,Plato"], cache.writes.map(&:first)
  end

  test "DBpedia executes entity subject and PageRank queries" do
    queries = []
    client = Object.new
    client.define_singleton_method(:query) { |query| queries << query; ["result"] }

    ::SPARQL::Client.stub(:new, client) do
      assert_equal ["result"], Knowledge::DBpedia.entity_property_values("Q42")
      assert_includes queries.last, "Q42"
      assert_equal ["result"], Knowledge::DBpedia.is_in_a_specific_subject?("people", "Plato")
      assert_includes queries.last, "Plato"
      capture_io { assert_equal ["result"], Knowledge::DBpedia.pagerank_of_one_resource("Plato of Athens") }
      assert_includes queries.last, "Plato_of_Athens"
      begin
        capture_io { assert_equal ["result"], Knowledge::DBpedia.pagerank_of_philosophers }
      rescue SystemExit
        flunk "A library query must return its result rather than terminating its caller"
      end
    end
  end

  test "Wikipedia uses cached Wikidata identities" do
    cache = Cache.new("Q42", [])
    Dalli::Client.stub(:new, cache) do
      assert_equal "Q42", Knowledge::Wikipedia::API.wikibase_item(titles: "Douglas Adams")
    end
    assert_empty cache.writes
  end

  test "Wikipedia resolves and caches page properties with and without a language prefix" do
    ["en", ""].each do |language|
      cache = Cache.new(nil, [])
      reply = Reply.new(["200"], JSON.generate("query" => {"pages" => {"1" => {"pageprops" => {"wikibase_item" => "Q42"}}}}))
      Dalli::Client.stub(:new, cache) do
        Knowledge::Wikipedia::API.stub(:open, reply) do
          assert_equal "Q42", Knowledge::Wikipedia::API.wikibase_item({titles: "Douglas Adams"}, language)
        end
      end
      assert_equal [["WB,Douglas Adams", "Q42"]], cache.writes
    end
  end

  test "Wikipedia malformed responses return nil and are not cached" do
    ["not JSON", JSON.generate("warnings" => {"main" => "invalid query"}), JSON.generate("query" => {"pages" => {"-1" => {}}})].each do |body|
      cache = Cache.new(nil, [])
      Dalli::Client.stub(:new, cache) do
        Knowledge::Wikipedia::API.stub(:open, Reply.new(["200"], body)) do
          capture_io { assert_nil Knowledge::Wikipedia::API.wikibase_item(titles: "Missing") }
        end
      end
      assert_empty cache.writes
    end
  end

  test "Wikipedia reports HTTP failures" do
    Dalli::Client.stub(:new, Cache.new(nil, [])) do
      Knowledge::Wikipedia::API.stub(:open, Reply.new(["503"], "")) do
        assert_raises(RuntimeError) { Knowledge::Wikipedia::API.wikibase_item(titles: "Missing") }
      end
    end
  end

  test "Wikidata sitelinks prefer English then fall back to another language" do
    [
      [{"enwiki" => {"title" => "Plato", "site" => "enwiki"}}, ["enwiki", "Plato"]],
      [{"frwiki" => {"title" => "Platon", "site" => "frwiki"}}, ["frwiki", "Platon"]],
      [{}, ["", ""]]
    ].each do |links, expected|
      reply = Reply.new(["200"], JSON.generate("success" => 1, "entities" => {"Q859" => {"sitelinks" => links}}))
      Knowledge::Wikidata::API.stub(:open, reply) do
        capture_io { assert_equal expected, Knowledge::Wikidata::API.wiki_title("Q859") }
      end
    end
  end

  test "Wikidata sitelinks report HTTP and API failures" do
    [Reply.new(["503"], ""), Reply.new(["200"], JSON.generate("success" => 0, "error" => "invalid query"))].each do |reply|
      Knowledge::Wikidata::API.stub(:open, reply) do
        assert_raises(RuntimeError) { Knowledge::Wikidata::API.wiki_title("Q859") }
      end
    end
  end
end

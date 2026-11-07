require "test_helper"
require "minitest/mock"
require "knowledge"
require "dalli"

class KnowledgeTest < ActiveSupport::TestCase
  Cache = Struct.new(:data, :writes) do
    def get(key)
      data[key]
    end

    def set(key, value)
      data[key] = value
      writes << [key, value]
      true
    end
  end

  Reply = Struct.new(:status, :content) do
    def read
      content
    end
  end

  test "language metadata preserves native names and script variants" do
    names = Knowledge::MediaWiki::Languages::NAMES

    assert_equal "English", names.fetch("en")
    assert_equal "Gaeilge", names.fetch("ga")
    assert_equal "العربية", names.fetch("ar")
    assert names.fetch("zh-hant").include?("繁體")
    assert names.values.all?(&:valid_encoding?)
  end

  test "name corrections preserve canonical philosophical labels" do
    assert_equal "Abelard", Knowledge::Wikidata::MAP_NAME.fetch("Abailard")
    assert_equal "Al-Farabi", Knowledge::Wikidata::MAP_NAME.fetch("al-Fārābi")
  end

  test "WordNet distinguishes common nouns from proper and absent lemmas" do
    synset = Struct.new(:word_counts).new({"being" => 2})
    common = Struct.new(:word, :synsets).new("being", [synset])
    proper = Struct.new(:word, :synsets).new("plato", [Struct.new(:word_counts).new({"Plato" => 1})])
    peculiar = Struct.new(:word, :synsets).new("different", [])

    capture_io do
      ::WordNet::Lemma.stub(:find, common) { assert Knowledge::WordNet.is_common_noun?("Being") }
      ::WordNet::Lemma.stub(:find, proper) { refute Knowledge::WordNet.is_common_noun?("Plato") }
      ::WordNet::Lemma.stub(:find, nil) { assert_raises(Knowledge::WordNet::LemmaNotFound) { Knowledge::WordNet.is_common_noun?("Unknown") } }
      ::WordNet::Lemma.stub(:find, peculiar) { assert_raises(Knowledge::WordNet::LemmaPeculiar) { Knowledge::WordNet.is_common_noun?("Unknown") } }
    end
  end

  test "WordNet lexical lookup inspects all senses and reports invalid lemmas" do
    lemma = Struct.new(:word, :synsets).new("being", [Struct.new(:word_counts).new({"other" => 1}), Struct.new(:word_counts).new({"being" => 2})])
    ::WordNet::Lemma.stub(:find_all, [lemma]) { assert Knowledge::WordNet.is_lexical?("Being") }
    lemma.synsets = [Struct.new(:word_counts).new({"other" => 1})]
    ::WordNet::Lemma.stub(:find_all, [lemma]) { refute Knowledge::WordNet.is_lexical?("Being") }
    ::WordNet::Lemma.stub(:find_all, []) { assert_raises(RuntimeError) { Knowledge::WordNet.is_lexical?("Unknown") } }
    lemma.word = "different"
    ::WordNet::Lemma.stub(:find_all, [lemma]) { assert_raises(RuntimeError) { Knowledge::WordNet.is_lexical?("Being") } }
  end

  test "name verification counts common nouns while accepting initials and unknown names" do
    lookup = ->(term) do
      raise Knowledge::WordNet::LemmaNotFound if term == "Unknown"
      raise Knowledge::WordNet::LemmaPeculiar, "unexpected lemma" if term == "Peculiar"
      term == "Being"
    end
    Knowledge::WordNet.stub(:is_common_noun?, lookup) do
      capture_io do
        assert_equal [["J.", "Being", "Unknown", "Peculiar"], 1], Knowledge::Format.verify("J. Being Unknown Peculiar")
        assert_equal [["d'Holbach"], 0], Knowledge::Format.verify("d'Holbach")
        assert_equal [[], nil], Knowledge::Format.verify("unrecognised lower case")
      end
    end
  end

  test "Google entity search uses cached results without requesting credentials" do
    cache = Cache.new({"KG,Plato" => {"name" => "Plato"}}, [])

    Dalli::Client.stub(:new, cache) do
      SecurityConfig.stub(:load_credential, ->(*) { flunk "Cache hits do not need credentials" }) do
        assert_equal({"name" => "Plato"}, Knowledge::Google.entity_search("Plato"))
      end
    end
    assert_empty cache.writes
  end

  test "Google entity search requests and caches present and absent results" do
    [[], [{"result" => {"name" => "Plato"}}]].each do |items|
      cache = Cache.new({}, [])
      reply = Reply.new(["200"], JSON.generate("itemListElement" => items))
      Dalli::Client.stub(:new, cache) do
        SecurityConfig.stub(:load_credential, "test-key") do
          Knowledge::Google.stub(:open, reply) do
            expected = items.empty? ? "" : {"name" => "Plato"}
            assert_equal expected, Knowledge::Google.entity_search("Plato")
            assert_equal [["KG,Plato", expected]], cache.writes
          end
        end
      end
    end
  end

  test "Google entity search reports an unsuccessful HTTP response" do
    with_service(Knowledge::Google, Reply.new(["503"], "")) do
      assert_raises(RuntimeError) { Knowledge::Google.entity_search("Plato") }
    end
  end

  test "Google philosopher search honours cached results and forced refresh" do
    cache = Cache.new({"KG,philosopher_person" => ["old"]}, [])
    reply = Reply.new(["200"], JSON.generate("itemListElement" => ["new"]))
    Dalli::Client.stub(:new, cache) do
      assert_equal ["old"], Knowledge::Google.philosopher_search(false)
      SecurityConfig.stub(:load_credential, "test-key") do
        Knowledge::Google.stub(:open, reply) { assert_equal ["new"], Knowledge::Google.philosopher_search(true) }
      end
    end
    assert_equal [["KG,philosopher_person", ["new"]]], cache.writes
    with_service(Knowledge::Google, Reply.new(["500"], "")) do
      assert_raises(RuntimeError) { Knowledge::Google.philosopher_search(true) }
    end
  end

  test "language detection uses the cache and records successful detections" do
    cache = Cache.new({"LL,hello" => ["cached"]}, [])
    Dalli::Client.stub(:new, cache) { assert_equal ["cached"], Knowledge::LanguageLayer.detect("hello") }
    with_service(Knowledge::LanguageLayer, Reply.new(["200"], JSON.generate("success" => true, "results" => ["en"]))) do |service_cache|
      assert_equal ["en"], Knowledge::LanguageLayer.detect("hello")
      assert_equal [["LL,hello", ["en"]]], service_cache.writes
    end
  end

  test "language detection reports service and transport errors" do
    [Reply.new(["503"], ""), Reply.new(["200"], JSON.generate("success" => false, "error" => "invalid key"))].each do |reply|
      with_service(Knowledge::LanguageLayer, reply) do
        assert_raises(RuntimeError) { Knowledge::LanguageLayer.detect("hello") }
      end
    end
  end

  test "VIAF lookup distinguishes cached and absent records" do
    cache = Cache.new({"VIAF,123" => {"name" => "Plato"}}, [])
    Dalli::Client.stub(:new, cache) do
      assert_equal({"name" => "Plato"}, Knowledge::Viaf.lookup(123))
      assert_nil Knowledge::Viaf.lookup(456)
    end
  end

  private

  def with_service(service, reply)
    cache = Cache.new({}, [])
    Dalli::Client.stub(:new, cache) do
      SecurityConfig.stub(:load_credential, "test-key") do
        service.stub(:open, reply) { yield cache }
      end
    end
  end
end

require "test_helper"
require "minitest/mock"
require "stringio"
require "open-uri"
require "moneta"
require "api_cache"
require_relative "../../lib/philosoraptor"

class PhilosoraptorTest < ActiveSupport::TestCase
  test "creates an image using configured credentials and encoded text" do
    reply = StringIO.new(JSON.generate("result" => {"instanceImageUrl" => "https://example.com/image.jpg"}))
    urls = []
    request = ->(url) { urls << url; reply }

    SecurityConfig.stub(:load_credential, "test-value") do
      Philosoraptor.stub(:open, request) do
        assert_equal "https://example.com/image.jpg", Philosoraptor.create("Being & time", "Nothingness?")
      end
    end
    parameters = CGI.parse(URI.parse(urls.first).query)
    assert_equal ["Being & time"], parameters.fetch("text0")
    assert_equal ["Nothingness?"], parameters.fetch("text1")
    assert_equal ["test-value"], parameters.fetch("username")
  end

  test "HTTP JSON and unexpected service errors return the fallback image" do
    failures = [
      ->(*) { raise OpenURI::HTTPError.new("unavailable", StringIO.new) },
      ->(*) { StringIO.new("not JSON") },
      ->(*) { raise IOError, "unavailable" }
    ]
    SecurityConfig.stub(:load_credential, "test-value") do
      failures.each do |failure|
        Philosoraptor.stub(:open, failure) do
          assert_equal "images/onwards.jpg", Philosoraptor.create("top", "bottom")
        end
      end
    end
  end

  test "cached creation stores the result under a text-specific key" do
    original_store = APICache.store
    store = Moneta.new(:Memory)
    keys = []
    cached = ->(key, &block) { keys << key; block.call }

    Moneta.stub(:new, store) do
      APICache.stub(:get, cached) do
        Philosoraptor.stub(:create, "generated.jpg") do
          assert_equal "generated.jpg", Philosoraptor.cache_create("top", "bottom")
        end
      end
    end
    assert_equal ["philosoraptor_create:top:bottom"], keys
    assert_kind_of APICache::MonetaStore, APICache.store
  ensure
    APICache.store = original_store
  end

  test "cached creation records generation failures as an empty result" do
    original_store = APICache.store
    Moneta.stub(:new, Moneta.new(:Memory)) do
      APICache.stub(:get, ->(_key, &block) { block.call }) do
        Philosoraptor.stub(:create, ->(*) { raise IOError, "generation failed" }) do
          assert_equal "", Philosoraptor.cache_create("top", "bottom")
        end
      end
    end
  ensure
    APICache.store = original_store
  end
end

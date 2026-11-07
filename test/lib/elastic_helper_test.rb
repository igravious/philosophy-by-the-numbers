require "test_helper"
require "minitest/mock"
require "elasticsearch"
require_relative "../support/loaded_helpers"

class ElasticHelperTest < ActiveSupport::TestCase
  include LoadedHelpers
  setup do
    @helper = load_helpers("lib/elastic_helper.rb")
  end

  test "yields an Elasticsearch client with the requested logging setting" do
    client = Object.new
    constructor = ->(options) {
      assert_equal({log: true}, options)
      client
    }

    result = Elasticsearch::Client.stub(:new, constructor) {
      @helper.elastic(true) { |actual|
        assert_same client, actual
        :result
      }
    }

    assert_equal :result, result
  end

  test "unavailable Elasticsearch yields nil so the caller can handle it" do
    constructor = ->(*) { raise IOError, "service unavailable" }

    assert_equal :unavailable, Elasticsearch::Client.stub(:new, constructor) { @helper.elastic(false) { |client| client.nil? ? :unavailable : :unexpected } }
  end

  test "reads snapshot count and derives the latest snapshot name" do
    client = Minitest::Mock.new
    2.times { client.expect(:get, {"_source" => {"counter" => "12"}}, [], index: "corpus", type: "snapshots", id: 0) }

    Elasticsearch::Client.stub(:new, client) do
      assert_equal 12, @helper.count_snaps
      assert_equal "snapshot12", @helper.latest_snap
    end
    client.verify
  end

  test "missing snapshot metadata represents an empty corpus" do
    client = Object.new
    client.define_singleton_method(:get) { |*| raise Elasticsearch::Transport::Transport::Errors::NotFound }

    assert_equal 0, Elasticsearch::Client.stub(:new, client) { @helper.count_snaps }
  end
end

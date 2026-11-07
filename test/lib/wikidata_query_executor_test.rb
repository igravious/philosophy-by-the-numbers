require "test_helper"
require "minitest/mock"
require "tmpdir"
require "net/http"
require_relative "../../lib/wikidata/query_executor"

class WikidataQueryExecutorTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir
    @client = Object.new
    @queries = []
    queries = @queries
    @client.define_singleton_method(:query) { |query| queries << query; ["result"] }
    @executor = Wikidata::QueryExecutor
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "executes a query and records its results and duration" do
    output = with_client do
      capture_io { assert_equal ["result"], @executor.execute("SELECT ?s WHERE {}", "example", show_spinner: false) }.first
    end

    assert_equal ["SELECT ?s WHERE {}"], @queries
    assert_includes output, "1 results"
    assert_includes File.read(File.join(@directory, "log/task_output.log")), "example query completed successfully"
  end

  test "retries read timeouts with bounded backoff before succeeding" do
    calls = 0
    @client.define_singleton_method(:query) do |_query|
      calls += 1
      raise Net::ReadTimeout, "timed out" if calls < 3
      ["recovered"]
    end
    delays = []

    with_client do
      @executor.stub(:sleep, ->(seconds) { delays << seconds }) do
        capture_io { assert_equal ["recovered"], @executor.execute("SELECT", "retry_example", show_spinner: false) }
      end
    end

    assert_equal 3, calls
    assert_equal [5, 10], delays
  end

  test "exhausted retries raise the original timeout" do
    @client.define_singleton_method(:query) { |_| raise Net::ReadTimeout, "still unavailable" }
    with_client do
      @executor.stub(:sleep, nil) do
        error = assert_raises(Net::ReadTimeout) do
          capture_io { @executor.execute("SELECT", "timeout", max_retries: 2, show_spinner: false) }
        end
        assert_includes error.message, "still unavailable"
      end
    end
    assert_includes File.read(File.join(@directory, "log/task_output.log")), "failed after all retry attempts"
  end

  test "ordinary query errors are recorded and raised" do
    @client.define_singleton_method(:query) { |_| raise ArgumentError, "invalid query" }

    with_client do
      error = assert_raises(ArgumentError) do
        capture_io { @executor.execute("SELECT", "invalid", show_spinner: false) }
      end
      assert_equal "invalid query", error.message
    end
    assert_includes File.read(File.join(@directory, "log/task_output.log")), "failed with error"
  end

  test "spinner is started and stopped for successful and failed queries" do
    spinner = Object.new
    messages = []
    spinner.define_singleton_method(:start) { messages << :started }
    spinner.define_singleton_method(:stop) { |message| messages << message }

    with_client do
      ProgressSpinner.stub(:new, spinner) do
        capture_io { assert_equal ["result"], @executor.execute("SELECT", "spinning") }
        @client.define_singleton_method(:query) { |_| raise IOError, "failed" }
        assert_raises(IOError) { capture_io { @executor.execute("SELECT", "spinning") } }
        @client.define_singleton_method(:query) { |_| raise Net::ReadTimeout }
        assert_raises(Net::ReadTimeout) { capture_io { @executor.execute("SELECT", "spinning", max_retries: 1) } }
      end
    end
    assert_equal 3, messages.count(:started)
    assert messages.any? { |message| message.to_s.include?("completed") }
    assert messages.any? { |message| message.to_s.include?("failed") }
    assert messages.any? { |message| message.to_s.include?("timed out") }
  end

  test "simple queries can log their query text and debug result count" do
    old_debug = ENV["SPARQL_DEBUG"]
    ENV["SPARQL_DEBUG"] = "true"
    output = with_client { capture_io { assert_equal ["result"], @executor.execute_simple("SELECT ?s", "simple", log_query: true) }.first }

    assert_includes output, "SELECT ?s"
    assert_includes output, "simple completed"
    assert_includes output, "query_type"
  ensure
    ENV["SPARQL_DEBUG"] = old_debug
  end

  test "convenience queries interpolate identifiers and preserve requested options" do
    with_client do
      capture_io do
        assert_equal ["result"], @executor.execute_philosopher_query(show_spinner: false)
        assert_equal ["result"], @executor.execute_philosophical_works_query(show_spinner: false)
        assert_equal ["result"], @executor.execute_works_by_philosophers_query(show_spinner: false)
      end
      assert_equal ["result"], @executor.find_philosopher_by_id("Q42")
      assert_includes @queries.last, "Q42"
      assert_equal ["result"], @executor.find_philosopher_by_name("Plato")
      assert_includes @queries.last, "Plato"
      assert_equal ["result"], @executor.execute_entity_attributes_query("Q42")
      assert_includes @queries.last, "Q42"
      assert_equal ["result"], @executor.execute_hits_query("Q42", "FILTER(?s = ?p)")
      assert_includes @queries.last, "FILTER(?s = ?p)"
    end
  end

  test "performance statistics handle absent logs and aggregate recorded query timings" do
    Rails.stub(:root, Pathname.new(@directory)) do
      assert_equal({}, @executor.performance_stats)
      FileUtils.mkdir_p(File.join(@directory, "log"))
      path = File.join(@directory, "log/task_output.log")
      File.write(path, "unrelated output\n")
      assert_equal 0, @executor.performance_stats[:avg_duration]
      File.write(path, "✓ first query completed successfully: 2 results in 4.0ms\n" \
        "✓ second query completed successfully: 3 results in 8.0ms\n" \
        "✓ first query completed successfully: 1 results in 6.0ms\n")

      stats = @executor.performance_stats

      assert_equal 3, stats[:total_queries]
      assert_equal 6, stats[:total_results]
      assert_equal 6.0, stats[:avg_duration]
      assert_equal({duration: 4.0, name: "first"}, stats[:fastest_query])
      assert_equal({duration: 8.0, name: "second"}, stats[:slowest_query])
      assert_equal 2, stats[:query_counts]["first"]
    end
  end

  private

  def with_client(&block)
    Rails.stub(:root, Pathname.new(@directory)) do
      Knowledge::Wikidata::Client.stub(:new, @client, &block)
    end
  end
end

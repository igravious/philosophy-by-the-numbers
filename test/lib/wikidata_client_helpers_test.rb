require "test_helper"
require "minitest/mock"
require "tmpdir"
require "rdf"
require_relative "../../lib/wikidata/client_helpers"
require_relative "../../lib/wikidata/query_executor"

class WikidataClientHelpersTest < ActiveSupport::TestCase
  setup do
    @helper = Object.new.extend(Wikidata::ClientHelpers)
    @directory = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@directory, "log"))
    @old_debug = ENV["SPARQL_DEBUG"]
    @old_log = ENV["SPARQL_LOG"]
    ENV["SPARQL_DEBUG"] = ENV["SPARQL_LOG"] = nil
  end

  teardown do
    ENV["SPARQL_DEBUG"] = @old_debug
    ENV["SPARQL_LOG"] = @old_log
    FileUtils.remove_entry(@directory) if @directory
  end

  test "shared query logging works through both module and mixed-in interfaces" do
    ENV["SPARQL_DEBUG"] = ENV["SPARQL_LOG"] = "true"
    Rails.stub(:root, Pathname.new(@directory)) do
      output = capture_io do
        Wikidata::ClientHelpers.log_sparql_query("SELECT\t?s", "module_query", task: "test")
        @helper.send(:log_sparql_query, "SELECT ?p", "instance_query")
      end.first

      assert_includes output, "SELECT  ?s"
      assert_includes output, "instance_query"
      assert_includes File.read(File.join(@directory, "log/sparql_queries.log")), "module_query"
    end
  end

  test "logging failures do not prevent queries from proceeding" do
    ENV["SPARQL_DEBUG"] = ENV["SPARQL_LOG"] = "true"
    Rails.stub(:root, Pathname.new(File.join(@directory, "missing"))) do
      assert_includes capture_io { Wikidata::ClientHelpers.log_sparql_query("SELECT", "unwritable") }.first, "logging failed"
    end
  end

  test "interpolated queries follow Wikidata redirects" do
    responses = [solutions(same: RDF::URI("http://www.wikidata.org/entity/Q84")), solutions(label: RDF::Literal.new("London"))]
    queries = []
    executor = ->(query, *_) {
      queries << query
      responses.shift
    }
    ENV["SPARQL_DEBUG"] = "true"

    Rails.stub(:root, Pathname.new(@directory)) do
      Wikidata::QueryExecutor.stub(:execute_simple, executor) do
        capture_io do
          result = @helper.interpolated_entity("SELECT %{interpolated_entity}", interpolated_entity: "Q42")
          assert_equal "London", result.first.bindings[:label].to_s
        end
      end
    end
    assert_equal ["SELECT Q42", "SELECT Q84"], queries
  end

  test "labels preserve language and shadow identity" do
    rows = solutions(label: RDF::Literal.new("Plato", language: :en), linkcount: RDF::Literal.new(8))
    @helper.stub(:interpolated_entity, rows) do
      attributes = @helper.labels(42, "Q859")
      assert_equal 8, attributes[:linkcount]
      assert_equal "Plato", attributes[:names_attributes].first.fetch("label")
      assert_equal "en", attributes[:names_attributes].first.fetch("lang")
      assert_equal 42, attributes[:names_attributes].first.fetch("shadow_id")
    end
    @helper.stub(:interpolated_entity, solutions) do
      assert_equal({linkcount: 0, names_attributes: []}, @helper.labels(42, "Q859"))
    end
  end

  test "datum queries interpolate both entity and property" do
    arguments = []
    @helper.stub(:interpolated_entity, ->(query, substitutions) {
                                         arguments << [query, substitutions]
                                         solutions
                                       }) do
      assert_empty @helper.datum_instance("Q42", "P27")
    end
    assert_equal({interpolated_entity: "Q42", interpolated_property: "P27"}, arguments.first.last)
  end

  test "object queries follow redirects and yield multiple values" do
    responses = [solutions(same: RDF::URI("http://www.wikidata.org/entity/Q84")), solutions({datum: RDF::Literal.new("first")}, {datum: RDF::Literal.new("second")})]
    yielded = []
    Wikidata::QueryExecutor.stub(:execute_simple, ->(*) { responses.shift }) do
      capture_io { assert_equal 2, @helper.object(42, 27) { |row| yielded << row.bindings[:datum].to_s } }
    end
    assert_equal ["first", "second"], yielded
  end

  test "object queries distinguish missing values from present single values" do
    [solutions, solutions(other: RDF::Literal.new("missing")), solutions(datum: RDF::Literal.new("present"))].each do |response|
      yielded = []
      Wikidata::QueryExecutor.stub(:execute_simple, response) do
        assert_equal response.length, @helper.object(42, 27) { |row| yielded << row.bindings[:datum].to_s }
      end
      assert_equal response.first&.bindings&.key?(:datum) ? ["present"] : [], yielded
    end
  end

  test "object query errors are reported with their context" do
    [Net::OpenTimeout.new, Net::ReadTimeout.new, IOError.new("unavailable")].each do |error|
      Wikidata::QueryExecutor.stub(:execute_simple, ->(*) { raise error }) do
        output = capture_io { assert_nil @helper.object(42, 27) { flunk "No result should be yielded" } }.first
        assert_includes output, "datum(42, 27)"
      end
    end
    Wikidata::QueryExecutor.stub(:execute_simple, solutions(datum: RDF::Literal.new("duplicate"))) do
      output = capture_io { @helper.object(42, 27) { raise ActiveRecord::RecordNotUnique, "duplicate" } }.first
      assert_includes output, "Record collision"
    end
  end

  test "properties preserve identifiers and optional metadata" do
    row = {linkcount: RDF::Literal.new(12), floruit: RDF::Literal.new("400 BCE"), births: RDF::Literal.new("-0427"),
           gender: RDF::URI("http://www.wikidata.org/entity/Q6581097"), work_lang: RDF::URI("http://www.wikidata.org/entity/Q1860"),
           country: RDF::URI("http://www.wikidata.org/entity/Q145"), copyright: RDF::URI("http://www.wikidata.org/entity/Q19652")}
    @helper.stub(:interpolated_entity, solutions(row, row.merge(title: RDF::Literal.new("A work")))) do
      properties = @helper.properties("Q859")
      assert_equal 12, properties[:linkcount]
      assert_equal "Q6581097", properties[:gender]
      assert_equal "Q1860", properties[:work_lang]
      assert_equal "Q145", properties[:country]
      assert_equal "Q19652", properties[:copyright]
      assert_nil properties[:deaths]
    end
    @helper.stub(:interpolated_entity, solutions) { assert_equal({linkcount: 0}, @helper.properties("Q859")) }
  end

  test "role queries preserve multiple roles and return empty results" do
    role = RDF::URI("http://www.wikidata.org/entity/Q4964182")
    rows = solutions({role: role, roleLabel: RDF::Literal.new("philosopher")}, {role: role})
    @helper.stub(:interpolated_entity, rows) do
      assert_equal 2, @helper.roles("Q859")[:role].length
    end
    @helper.stub(:interpolated_entity, solutions) { assert_equal({}, @helper.roles("Q859")) }
    @helper.stub(:interpolated_entity, ->(*) { raise IOError, "failed query" }) do
      @helper.properties("Q859")
      @helper.roles("Q859")
    end
  end

  private

  def solutions(*rows)
    RDF::Query::Solutions.new(rows.map { |bindings| RDF::Query::Solution.new(bindings) })
  end
end

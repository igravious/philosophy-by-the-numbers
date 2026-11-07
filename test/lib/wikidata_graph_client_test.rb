require "test_helper"
require "minitest/mock"
require "knowledge"
require "sparql/client"

class WikidataGraphClientTest < ActiveSupport::TestCase
  setup do
    @queries = []
    @responses = []
    @transport = Object.new
    @transport.define_singleton_method(:query) do |query|
      @query_handler.call(query)
    end
    @transport.instance_variable_set(:@query_handler, ->(query) {
                                                        @queries << query
                                                        @responses.shift || solutions
                                                      })
    SPARQL::Client.stub(:new, @transport) { @client = Knowledge::Wikidata::Client.new }
    @client.reset
  end

  test "direct queries return the transport result" do
    @responses << solutions(v: RDF::Literal.new("answer"))
    assert_equal "answer", @client.query("SELECT ?v").first.v.to_s
    assert_equal ["SELECT ?v"], @queries
  end

  test "relationship traversal records a graph edge and stops at repeated entities" do
    edge = {x: entity("Q859"), y: RDF::URI("http://www.wikidata.org/prop/P31"), s: entity("Q5"), sLabel: RDF::Literal.new("human")}
    @responses << solutions(edge, edge.merge(s: entity("Q215627")))
    assert_equal({"Q5" => "human"}, @client.send(:instance_of, 0, "Q859"))
    @responses << solutions(edge)
    assert_nil @client.send(:instance_of, 1, "Q859")
    graph = @client.instance_variable_get(:@meros)
    assert_equal 1, graph.count
    assert graph.has_statement?(RDF::Statement.new(edge[:x], edge[:y], edge[:s]))
    assert_nil @client.send(:part_of, 1, "Q5")
  end

  test "descriptions select an English description or alternate label" do
    @responses << solutions({p: RDF::RDFS.label, v: RDF::Literal.new("Plato")},
      {p: RDF::URI("http://schema.org/description"), v: RDF::Literal.new("Greek philosopher")})
    assert_equal "Greek philosopher", @client.send(:description, "Q859")
    @responses << solutions(p: RDF::URI("http://www.w3.org/2004/02/skos/core#altLabel"), v: RDF::Literal.new("Platon"))
    assert_equal "Platon", @client.send(:description, "Q859")
    assert_equal "", @client.send(:description, "Q859")
  end

  test "recursive traversal tries part subclass and instance relationships" do
    calls = []
    @client.stub(:part_of, ->(depth, id) {
                             calls << [:part, depth, id]
                             nil
                           }) do
      @client.stub(:subclass_of, ->(depth, id) {
                                   calls << [:subclass, depth, id]
                                   nil
                                 }) do
        @client.stub(:instance_of, ->(depth, id) {
                                     calls << [:instance, depth, id]
                                     nil
                                   }) do
          assert @client.send(:recurse_grep, 0, {"Q859" => "Plato"})
          refute @client.send(:recurse_grep, 0, nil)
        end
      end
    end
    assert_equal [[:part, 0, "Q859"], [:subclass, 0, "Q859"], [:instance, 0, "Q859"]], calls
  end

  test "label lookup returns the resulting graph and excludes avoided or repeated identities" do
    @responses << solutions({s: entity("Q859")}, {s: entity("Q859")}, {s: entity("Q1078867")})
    @client.stub(:description, "Greek philosopher") do
      @client.stub(:recurse_grep, true) do
        result = nil
        capture_io { result = @client.recurse_query("Plato") }
        assert_instance_of RDF::Graph, result.first
        assert_equal({"Q859" => "Plato"}, result.last)
      end
    end
    assert_includes @queries.first, "'Plato'@en"
  end

  test "accumulating clients retain previous labels between queries" do
    SPARQL::Client.stub(:new, @transport) { @client = Knowledge::Wikidata::Client.new(true) }
    @client.stub(:description, "description") do
      @client.stub(:recurse_grep, true) do
        capture_io do
          @responses << solutions(s: entity("Q859"))
          @client.recurse_query("Plato")
          @responses << solutions(s: entity("Q868"))
          assert_equal({"Q859" => "Plato", "Q868" => "Aristotle"}, @client.recurse_query("Aristotle").last)
        end
      end
    end
  end

  private

  def entity(id)
    RDF::URI("http://www.wikidata.org/entity/#{id}")
  end

  def solutions(*rows)
    RDF::Query::Solutions.new(rows.map { |bindings| RDF::Query::Solution.new(bindings) })
  end
end

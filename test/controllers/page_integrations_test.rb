require "test_helper"
require "minitest/mock"
require "tmpdir"
require "elasticsearch"
require "philosoraptor"
require "knowledge"
require "texify"

class PageIntegrationsTest < ActionController::TestCase
  tests PagesController

  setup do
    @directory = Dir.mktmpdir("page-integrations-")
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "search resolves returned hits to local texts and files with pagination" do
    text = texts(:one)
    file = Fyle.create!(what: "Search Source")
    text.update!(fyle: file)
    queries = []
    client = Object.new
    client.define_singleton_method(:get) { |**_| {"_source" => {"counter" => 3}} }
    client.define_singleton_method(:search) do |**options|
      queries << options
      {"hits" => {"total" => 10, "hits" => [
        {"_source" => {"title" => text.name_in_english, "year" => 1900}, "highlight" => {"content" => ["A <em>term</em>"]}},
        {"_source" => {"title" => "Missing local text", "year" => 1900}, "highlight" => {"content" => ["Another term"]}}
      ]}}
    end
    Elasticsearch::Client.stub(:new, client) do
      get :search, q: "term"
      assert_equal 0, assigns(:from)
      get :search, q: "term", f: "5"
    end
    assert_response :success
    assert_equal 10, assigns(:total)
    assert_equal 5, assigns(:from)
    assert_equal text, assigns(:hits).first["text"]
    assert_equal file, assigns(:hits).first["fyle"]
    assert_nil assigns(:hits).last["fyle"]
    assert_equal "snapshot3", queries.last[:index]
    assert_equal({content: "term"}, queries.last[:body][:query][:match_phrase])
  end

  test "search reports unavailable services and invalid query parameters" do
    Elasticsearch::Client.stub(:new, ->(*) { raise IOError, "offline" }) { get :search, q: "term" }
    assert_response :success
    assert_equal(-1, assigns(:total))
    assert flash[:alert]
    get :search, wrong_parameter: "term"
    assert_equal "Bad search query parameter.", flash[:alert]
  end

  test "illustration pages pass submitted text to their service boundary" do
    arguments = []
    Philosoraptor.stub(:create, ->(*args) {
                                  arguments << args
                                  "https://images.test/meme.png"
                                }) do
      get :philosoraptor, top: "Reason", bottom: "and experience"
    end
    assert_response :success
    assert_equal [["Reason", "and experience"]], arguments
    assert_select "img[src=?]", "https://images.test/meme.png"
    Philosoraptor.stub(:cache_create, "https://images.test/landing.png") { get :landing }
    assert_response :success
    assert assigns(:launch_url).end_with?("/inquiry")
  end

  test "stored RDF graphs produce unique labeled nodes and typed edges" do
    write_graph
    Dir.chdir(@directory) { get :springy, term: "reason,concept" }

    assert_response :success
    assert_equal %w[Q1 Q2 Q3], assigns(:nodes).map(&:entity).sort
    assert_equal 2, assigns(:nodes).count { |node| node.color == "CC3344" }
    assert_equal({"P279" => "CCBBAA", "P361" => "33BB77"}, assigns(:edges).map { |edge| [edge.label, edge.color] }.to_h)
    Dir.chdir(@directory) { get :semantic_web, term: "reason" }
    assert_response :success
    assert_equal 3, assigns(:nodes).size
  end

  test "semantic graph loading reports I/O and unexpected failures without exposing internals" do
    RDF::Graph.stub(:load, ->(*) { raise IOError, "missing graph" }) do
      get :semantic_web, term: "unknown"
      assert_includes Nokogiri::HTML(response.body).text, "I don't know"
    end
    RDF::Graph.stub(:load, ->(*) { raise ArgumentError, "bad graph" }) do
      get :semantic_web, term: "unknown"
      assert_includes response.body, "Something went wrong"
    end
  end

  test "live graph traversal uses the configured Wikidata client" do
    graph = example_graph
    labels = {"Q1" => "reason", "Q2" => "concept", "Q3" => "thing"}
    client = Object.new
    client.define_singleton_method(:recurse_query) { |_| [graph, labels] }
    @controller.params = ActionController::Parameters.new(term: "reason")
    Knowledge::Wikidata::Client.stub(:new, client) { @controller.springy_from_wiki }
    assert_equal %w[Q1 Q2 Q3], @controller.instance_variable_get(:@nodes).map(&:entity).sort
  end

  test "poetry lookup flattens WordNet senses and renders their words" do
    synset = Struct.new(:words).new(%w[reason understanding])
    lemma = Struct.new(:synsets).new([synset])
    WordNet::Lemma.stub(:find_all, [lemma]) { post :do_pome, q: "reason" }
    assert_response :success
    assert_equal [synset], assigns(:words)
    assert_includes response.body, "understanding"
  end

  test "paper delivery reports typesetting failure and streams successful output" do
    submitted = []
    @controller.stub(:texify, ->(delivery) {
                                submitted << delivery
                                false
                              }) do
      post :do_paper, delivery: {identifier: "Conference", location: "Dublin", date: "2026-11-06"}
    end
    assert_response :success
    assert_equal "Conference", submitted.first.identifier
    assert_equal "Dublin", submitted.first.location
    assert_equal 9, submitted.first.numbered
    sent = []
    @controller.stub(:texify, true) do
      @controller.stub(:send_file, ->(path, options) {
                                     sent << [path, options]
                                     @controller.head(:ok)
                                   }) do
        post :do_paper, delivery: {identifier: "Conference", location: "Dublin", date: "2026-11-06"}
      end
    end
    assert_equal "application/pdf", sent.first.last[:type]
    assert sent.first.first.end_with?("fragments.pdf")
  end

  private

  def example_graph
    graph = RDF::Graph.new
    graph << [RDF::URI("http://example.test/Q1"), RDF::URI("http://example.test/P279"), RDF::URI("http://example.test/Q2")]
    graph << [RDF::URI("http://example.test/Q2"), RDF::URI("http://example.test/P361"), RDF::URI("http://example.test/Q3")]
    graph
  end

  def write_graph
    directory = File.join(@directory, "db/wikidata")
    FileUtils.mkdir_p(directory)
    %w[reason concept].each do |term|
      File.write(File.join(directory, "meros_#{term}.nt"), example_graph.dump(:ntriples))
      File.binwrite(File.join(directory, "labels_#{term}.bin"), Marshal.dump({"Q1" => "reason", "Q2" => "concept", "Q3" => "thing"}))
    end
  end
end

require "test_helper"
require "minitest/mock"
require "tmpdir"
require "elasticsearch"

class TextExportsTest < ActionController::TestCase
  tests TextsController

  setup do
    @directory = Dir.mktmpdir("text-exports-")
    @path = File.join(@directory, "philosophy.txt")
    File.write(@path, "Corpus content")
    @file = Fyle.create!(what: "Corpus Text", cache_file: @path, local_file: @path, encoding: "UTF-8", health: 1.0)
    @text = Text.create!(name: "Corpus Text", name_in_english: "Corpus Text", include: true, original_year: 1781, fyle: @file)
    @author = Author.create!(name: "Corpus Author", english_name: "Corpus Author")
    @translator = Author.create!(name: "Corpus Translator", english_name: "Corpus Translator")
    Writing.create!(author: @author, text: @text, role: Writing::AUTHOR)
    Writing.create!(author: @translator, text: @text, role: Writing::TRANSLATOR)
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "XML exports actual corpus titles dates URLs and author roles" do
    get :index, format: :xml

    assert_response :success
    document = Nokogiri::XML(response.body)
    paper = document.at_xpath("//paper[title='Corpus Text']")
    assert paper
    assert_equal "1781", paper["year"]
    assert_equal ["Corpus Author"], paper.xpath("authors/author").map(&:text)
    assert_equal @file.plain_path, paper["url"]
  end

  test "parts exports divide large texts without inventing an empty final part" do
    File.write(@path, "a" * 2.megabytes)
    get :index, format: :xml, parts: "true"

    assert_response :success
    papers = assigns(:papers).select { |paper| paper.title.start_with?("Corpus Text") }
    assert_equal ["Corpus Text (Part 1)", "Corpus Text (Part 2)"], papers.map(&:title)
    assert_equal [1.megabyte, 1.megabyte], papers.map(&:size)
    assert papers.all? { |paper| paper.authors.map(&:name) == ["Corpus Author"] }
  end

  test "parts exports include a nonempty remainder and skip excluded texts" do
    File.write(@path, "a" * (1.megabyte + 5))
    get :index, format: :xml, parts: "true"
    papers = assigns(:papers).select { |paper| paper.title.start_with?("Corpus Text") }
    assert_equal [1.megabyte, 5], papers.map(&:size)

    @text.update!(include: false)
    get :index, format: :xml, parts: "true"
    refute assigns(:papers).any? { |paper| paper.title.start_with?("Corpus Text") }
  end

  test "chunked exports use file routes and preserve the final partial chunk" do
    File.write(@path, "a" * (1.megabyte + 5))
    get :index, format: :xml, chunked: "true"

    assert_response :success
    paper = assigns(:papers).find { |entry| entry.title == "Corpus Text" }
    assert_equal [1.megabyte, 5], paper.contents.map(&:size)
    assert_equal ["Corpus Author"], paper.authors.map(&:name)
    assert paper.contents.all? { |content| content.url.include?("chunk=") }
  end

  test "chunked exports retain a small document as one file" do
    get :index, format: :xml, chunked: "true"
    paper = assigns(:papers).find { |entry| entry.title == "Corpus Text" }
    assert_equal "Corpus content".length, paper.size
    assert_nil paper.contents
  end

  test "CSV and Voyant exports use only the selected reference tag" do
    tag = Tag.find_by(id: 6) || Tag.create!(id: 6, name: "Export Tag")
    Labeling.create!(tag: tag, text: @text)
    %i[csv voyant].each do |format|
      get :index, format: format
      assert_response :success
      assert_equal ["Corpus Text"], assigns(:papers).map(&:title)
    end
  end

  test "snapshot XML uses stored Elasticsearch metadata documents and authors" do
    client = Object.new
    client.define_singleton_method(:search) { |**_| {"hits" => {"total" => 1}} }
    client.define_singleton_method(:get) do |**options|
      source = if options[:type] == GlobalConstants::METADATA
        {"url" => "https://conference.test", "year" => 2026}
      else
        {"uid" => 42, "year" => 1781, "title" => "Snapshot Work", "authors" => {"array" => [{"author" => "Snapshot Author"}]}}
      end
      {"_source" => source}
    end
    Elasticsearch::Client.stub(:new, client) { get :index, format: :xml, snapshot: "7" }

    assert_response :success
    assert_includes response.body, "Snapshot Work"
    assert_includes response.body, "Snapshot Author"
    assert_equal "https://conference.test", assigns(:event).url
    assert_equal Fyle.snapshot_url("7", 42), assigns(:papers).first.paper_url
  end

  test "snapshot exports tolerate missing indices and service failures" do
    [Elasticsearch::Transport::Transport::Errors::NotFound.new("missing"), IOError.new("offline")].each do |error|
      client = Object.new
      client.define_singleton_method(:get) { |**_| raise error }
      Elasticsearch::Client.stub(:new, client) { get :index, format: :xml, snapshot: "7" }
      assert_response :success
      assert_empty assigns(:papers)
    end
  end

  test "missing Elasticsearch counts return zero and boolean parameters reject absent values" do
    client = Object.new
    client.define_singleton_method(:search) { |**_| raise Elasticsearch::Transport::Transport::Errors::NotFound }
    Elasticsearch::Client.stub(:new, client) { assert_equal 0, @controller.count_docs("missing") }
    assert @controller.to_boolean("TRUE")
    refute @controller.to_boolean(nil)
    refute @controller.to_boolean("false")
  end
end
